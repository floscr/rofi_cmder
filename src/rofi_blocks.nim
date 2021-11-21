import std/json
import os
import strutils

import lib/rofi_blocks_lib as rofiBlocks
import lib/input_match

# StdinState
var stdinState: rofiBlocks.consoleInputState
var stdinJsonState: JsonNode = %* { "name": "noop", "value": "", }

proc main(): auto =
  while true:
    var command = readStdinNonBlocking(stdinState)

    # writeFile("/tmp/rof_blocks_logs", command)

    if not command.isEmptyOrWhitespace:
      stdinJsonState = parseJson(command)

    let response = case stdinJsonState["name"].getStr():
    of "input change":
      var value = stdinJsonState["value"].getStr()
      matchInput(value)
    of "select entry":
      var value = stdinJsonState["value"].getStr()
      matchInput(value)
    else:
      @[]

    echo sendJson(response)

    sleep 1

when isMainModule:
  main()
