import std/json
import std/strutils
import std/sequtils
import std/os
import std/sugar
import std/osproc

import fp/either
import fp/maybe

import lib/rofi_blocks_lib as rofiBlocks
import lib/input_match
import lib/commands
import lib/state
import lib/redux
import lib/desktop_entries
import lib/steam_games
import lib/types
import lib/utils_option

# State
var stdinState: rofiBlocks.consoleInputState

# Main
proc main(): auto =

  let mainCommands = getCommands().getOrElse(@[])

  let commands = mainCommands
  .concat(getDesktopApplications())
  .concat(getSteamGames())

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
      .asMaybe
      .flatMap((x: types.Command) => x.command.convertMaybe())

      if (command.isEmpty()): quit(0)

      discard startProcess(command.get(), options={poStdErrToStdOut, poEvalCommand})

      quit(1)

    echo sendJson(response)

    sleep 1

when isMainModule:
  main()
