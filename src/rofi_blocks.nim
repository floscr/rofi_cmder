import std/json
import std/strutils
import std/sequtils
import std/os
import std/sugar
import std/logging
import std/osproc

import fp/either
import fp/list
import fp/option

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

    let response = onStdinJson(state.stdinJsonState)
    .concat(
      commands
      .getCommandDescriptions(state.inputText)
    )

    if state.stdinJsonState["name"].getStr() == "select entry":
      var value: string = state.stdinJsonState["value"].getStr()
      let command = commands
      .asList
      .find((x: ConfigItem) => x.description == value)
      .flatMap((x: ConfigItem) => x.command)
      .getOrElse("")

      fileLogger.log(lvlInfo, command)

      let p = startProcess(command, options={poStdErrToStdOut, poEvalCommand})
      discard waitForExit(p)
      quit(1)

    echo sendJson(response)

    sleep 1

when isMainModule:
  main()
