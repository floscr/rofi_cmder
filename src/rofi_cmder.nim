import std/json
import std/os
import std/sequtils
import std/strutils
import std/sugar
import fp/either
import fp/maybe
import ./lib/db
import ./lib/input_match
import ./lib/modules/module_commands
import ./lib/modules/module_desktop_entries
import ./lib/modules/module_steam_games
import ./lib/modules/module_xmonad_commands
import ./lib/redux
import ./lib/rofi_blocks_lib as rofiBlocks
import ./lib/state
import ./lib/types
import ./lib/utils_option

proc getCommandItems(): seq[types.Command] =
  let commands = concat(
    getCommands().getOrElse(@[]),
    getDesktopApplications(),
    getXmonadCommands(),
    getSteamGames()
  )

  let sortedCommands = dbRead()
  .sortCommandsByDbMap(commands)

  sortedCommands

proc main(): auto =
  var stdinState: rofiBlocks.consoleInputState

  let commands = getCommandItems()

  while true:
    var command = readStdinNonBlocking(stdinState)

    # Update the state from stdin
    if not command.isEmptyOrWhitespace:
      store.dispatch(UpdateStdinJsonState(text: command))

    let state = store.getState

    let filteredCommands = commands.filterByNames(state.inputText)

    let response = onStdinJson(state.stdinJsonState)
    .concat(
      filteredCommands.map((x: types.Command) => x.name)
    )

    if state.stdinJsonState["name"].getStr() == "select entry":
      let command = tryET(
        state.stdinJsonState["data"].getStr().parseInt
      )
      .flatMap((x: int) => tryET(
        filteredCommands[x]
      ))

      let commandString = command
      .asMaybe
      .flatMap((x: types.Command) => x.command.convertMaybe())

      if (commandString.isEmpty()): quit(0)

      discard execShellCmd(
        commandString
        .map((x: string) => (
          if x.endsWith("&"): x
          else: x & "&"
        ))
        .get()
      )

      discard dbUpdateInsertRow(
        command
        .get()
        .dbHash()
      )

      quit(1)

    echo sendJson(response)

    sleep 1

when isMainModule:
  main()
