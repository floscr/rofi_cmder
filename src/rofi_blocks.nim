import std/json
import std/strutils
import std/sequtils
import std/os
import std/sugar
import fp/either
import lib/rofi_blocks_lib as rofiBlocks
import lib/input_match
import lib/commands

# State
var stdinState: rofiBlocks.consoleInputState
var stdinJsonState: JsonNode = %* {"name": "noop", "value": "", }

# Main
proc main(): auto =
  let commands: seq[ConfigItem] = getCommands()
  .getOrElse(@[])

  while true:
    var command = readStdinNonBlocking(stdinState)

    if not command.isEmptyOrWhitespace:
      stdinJsonState = parseJson(command)

    let response = onStdinJson(stdinJsonState)
    .concat(
      commands
      .getCommandDescriptions(stdinJsonState["value"].getStr(""))
    )

    echo sendJson(response)

    sleep 1

when isMainModule:
  main()
