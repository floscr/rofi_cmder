import std/json
import os
import strutils

import lib/rofi_blocks_lib as rofiBlocks
import lib/input_match

# State
var state: rofiBlocks.consoleInputState
var stdinState: JsonNode = %* { "name": "noop", "value": "", }

proc main(): auto =
  while true:
    var command = readStdinNonBlocking(state)

    # writeFile("/tmp/rof_blocks_logs", command)

    if not command.isEmptyOrWhitespace:
      stdinState = parseJson(command)

    let response = case stdinState["name"].getStr():
    of "input change":
      var value = stdinState["value"].getStr()
      matchInput(value)
    of "select entry":
      var value = stdinState["value"].getStr()
      matchInput(value)
    else:
      @[]

    echo sendJson(response)

    sleep 1

when isMainModule:
  main()
