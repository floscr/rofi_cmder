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

proc getDefaultEntries(): seq[types.Command] =
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

  let defaultEntries = getDefaultEntries()

  while true:
    # Update the state from stdin
    let stdinCommand = readStdinNonBlocking(stdinState)
    if not stdinCommand.isEmptyOrWhitespace():
      store.dispatch(UpdateStdinJsonState(text: stdinCommand))

    let state = store.getState

    let filteredEntries = defaultEntries.filterByNames(state.inputText)

    case state.stdinJsonState["name"].getStr():
      of ROFI_BLOCKS_EVENT_SUBMIT:
        let command = tryET(
          state.stdinJsonState["data"].getStr().parseInt
        )
        .flatMap((x: int) => tryET(
          filteredEntries[x]
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
      else:
        let response = onStdinJson(state.stdinJsonState)
        .concat(
          filteredEntries.map((x: types.Command) => x.name)
        )
        echo sendJson(response)

    sleep 1

when isMainModule:
  main()
