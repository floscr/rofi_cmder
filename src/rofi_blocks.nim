import std/json
import std/strutils
import std/sequtils
import std/os
import fp/either
import lib/rofi_blocks_lib as rofiBlocks
import lib/input_match
import lib/commands

# State
var stdinState: rofiBlocks.consoleInputState
var stdinJsonState: JsonNode = %* {"name": "noop", "value": "", }

# Main
proc main(): auto =
  let commands: seq[ConfigItem] = getCommands().getOrElse(@[])
  let descriptions: seq[string] = commands.mapIt(it.description)
  
  while true:
    var command = readStdinNonBlocking(stdinState)

    # writeFile("/tmp/rof_blocks_logs", command)

    if not command.isEmptyOrWhitespace:
      stdinJsonState = parseJson(command)

    let response = onStdinJson(stdinJsonState)
    .concat(descriptions)

    echo sendJson(response)

    sleep 1

when isMainModule:
  main()
