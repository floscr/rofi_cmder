import threadpool
import std/json
import strformat, strutils
import os, osproc
import std/[times, os]
import fp/std/jsonops
import fp/either
import std/re

type consoleInputState* = FlowVar[string]

proc readStdinNonBlocking* (state: var consoleInputState): string =
  if state == nil:
    result = ""
    state = spawn readLine stdin
  elif state.isReady:
    result = ^state
    state = spawn readLine stdin
  else:
    result = ""

var state: consoleInputState

var inputState: JsonNode = %* { "name": "noop", "value": "", }

proc sendJson(lines: seq[string]): JsonNode =
  %* {
    "input action": "send",
    "prompt": "search youtube",
    "lines": lines
  }

proc matchInput(value: string): seq[string] =
  if value =~ re"\d":
    @[
      execProcess(&"""echo "{value}" | bc""")
    ]
  else:
    @[]

while true:

  var command = state.readStdinNonBlocking()

  if not command.isEmptyOrWhitespace:
    inputState = parseJson(command)

  let response = case inputState["name"].getStr():
  of "input change":
    var value = inputState["value"].getStr()
    matchInput(value)
  else:
    @[]

  echo sendJson(response)


  # if inputState["name"].getStr() == "input change":
  #   var value = inputState["value"].getStr()


  # if not command.isEmptyOrWhitespace:
  #   # writeFile("/tmp/rof_blocks_logs/command-" & (now().format("yyyy-MM-dd HH:mm:ss")), command)
  #   inputState =


  #   if value.startsWith("m:"):
  #     value.removePrefix("m:")
  #     echo sendJson(@[
  #       execProcess(&"""echo "{value}" | bc""")
  #     ])
  #   else:
  #     echo sendJson(@[])
  # else:
  #   echo sendJson(@[])

  sleep 1
