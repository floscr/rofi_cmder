import std/json
import std/strutils
import std/sequtils
import std/os
import std/sugar
import std/logging

import fp/either

import lib/rofi_blocks_lib as rofiBlocks
import lib/input_match
import lib/commands
import lib/state
import lib/redux

# State
var stdinState: rofiBlocks.consoleInputState

var fileLogger = newFileLogger("errors.log")

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

    fileLogger.log(lvlInfo, state.stdinJsonState)

    let response = onStdinJson(state.stdinJsonState)
    .concat(
      commands
      .getCommandDescriptions(state.inputText)
    )

    echo sendJson(response)

    sleep 1

when isMainModule:
  main()
