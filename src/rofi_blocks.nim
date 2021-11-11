import threadpool
import std/json
import strformat, strutils
import os, osproc
import std/[times, os]

type consoleInputState* = FlowVar[string]

proc readStdinNonBlocking* (state: var consoleInputState): string =
  if state == nil:
    result = ""
    state = spawn readLine stdin
  elif state.isReady:
    # echo ^state
    # echo typeof ^state
    # echo "Is not there: " & ^state == ""
    # writeFile("/tmp/rof_blocks_logs/" & (now().format("yyyy-MM-dd HH:mm:ss")), ^state)
    result = ^state
    state = spawn readLine stdin
  else:
    result = ""

var state: consoleInputState

var inputState: JsonNode = %* { "name": "noop", "value": "", }

while true:

  var command = state.readStdinNonBlocking()

  if not command.isEmptyOrWhitespace:
    # writeFile("/tmp/rof_blocks_logs/command-" & (now().format("yyyy-MM-dd HH:mm:ss")), command)
    inputState = parseJson(command)

  if inputState["name"].getStr() == "input change":
    var value = inputState["value"].getStr()
    if value.startsWith("m:"):
      value.removePrefix("m:")
      echo (%* {"input action": "send", "prompt": "search youtube", "lines": [
        execProcess(&"""echo "{value}" | bc"""),
      ]})
    else:
      echo (%* {"input action": "send", "prompt": "search youtube", "lines": []})
  else:
    echo (%* {"input action": "send", "prompt": "search youtube", "lines": []})

  # sleep 1
