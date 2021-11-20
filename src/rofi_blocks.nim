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

proc main(): auto =
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

    sleep 1

when isMainModule:
  main()
