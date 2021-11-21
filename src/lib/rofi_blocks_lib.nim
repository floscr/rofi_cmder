import threadpool
import std/json

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

proc sendJson*(lines: seq[string]): JsonNode =
  %* {
    "input action": "send",
    "prompt": "Search",
    "lines": lines
  }
