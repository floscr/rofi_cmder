import std/json
import std/strutils
import std/sequtils
import std/os
import std/sugar
import std/osproc

import fp/either
import fp/list
import fp/option
import fp/std/jsonops

import lib/rofi_blocks_lib as rofiBlocks
import lib/input_match
import lib/commands
import lib/state
import lib/redux
import lib/debug

# State
var stdinState: rofiBlocks.consoleInputState

# Main
proc main(): auto =
  let commands: seq[ConfigItem] = getCommands()
  .getOrElse(@[])

  while true:
    var command = readStdinNonBlocking(stdinState)

    # Update the state from stdin
    if not command.isEmptyOrWhitespace:
      store.dispatch(UpdateStdinJsonState(text: command))

    let state = store.getState

    let filteredCommands = commands.getFilteredCommands(state.inputText)

    let response = onStdinJson(state.stdinJsonState)
    .concat(
      filteredCommands.map((x: ConfigItem) => x.description)
    )

    if state.stdinJsonState["name"].getStr() == "select entry":
      let command = tryET(
        state.stdinJsonState["data"].getStr().parseInt
      )
      .flatMap((x: int) => tryET(
        filteredCommands[x]
      ))
      .asOption
      .flatMap((x: ConfigItem) => x.command)

      if (command.isEmpty()): quit(0)

      let p = startProcess(command.get(), options={poStdErrToStdOut, poEvalCommand})

      quit(1)

    echo sendJson(response)

    sleep 1

when isMainModule:
  main()
