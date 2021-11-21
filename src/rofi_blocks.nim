import std/json,
       std/strutils,
       std/sequtils

import os

import fp/either

import lib/rofi_blocks_lib as rofiBlocks
import lib/input_match
import lib/commands

# State
var stdinState: rofiBlocks.consoleInputState
var stdinJsonState: JsonNode = %* { "name": "noop", "value": "", }

proc main(): auto =
  let commands: seq[ConfigItem] = getCommands().getOrElse(@[])
  let descriptions: seq[string] = commands.mapIt(it.description)


  while true:
    var command = readStdinNonBlocking(stdinState)

    # writeFile("/tmp/rof_blocks_logs", command)

    if not command.isEmptyOrWhitespace:
      stdinJsonState = parseJson(command)

    let response = case stdinJsonState["name"].getStr():
    of "input change":
      var value = stdinJsonState["value"].getStr()
      matchInput(value)
      .concat(descriptions)
    of "select entry":
      var value = stdinJsonState["value"].getStr()
      matchInput(value)
      .concat(descriptions)
    else:
      descriptions

    echo sendJson(response)

    sleep 1

when isMainModule:
  main()
