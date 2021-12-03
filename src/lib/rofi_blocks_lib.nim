import threadpool
import std/json

const ROFI_BLOCKS_EVENT_SUBMIT* = "select entry"

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

proc sendJson*(xs: seq[string]): JsonNode =
  %* {
    "input action": "send",
    "prompt": "Search",
    "lines": xs,
  }
