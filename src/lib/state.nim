from commands import ConfigItem
import std/json
import redux

# State
type
  State* = ref object
    stdinJsonState*: JsonNode
    inputText*: string
    itemsCache*: seq[ConfigItem]

# Actions
type
  UpdateStdinJsonState* = ref object of Action
    text*: string

using
  state: State
  action: Action

# Reducer
proc reducer(state, action): State =
  if state == nil:
    return State(
      stdinJsonState: %* {"name": "noop", "value": "", },

      inputText: "",
      itemsCache: @[],
    )
  new(result); result[] = state[]

  if action of UpdateStdinJsonState:
    let json = UpdateStdinJsonState(action).text.parseJson
    result.stdinJsonState = json

    case json["name"].getStr():
      of "input change":
        result.inputText = json["value"].getStr()

  else:
    result = state

# Main
var store* = newStore(reducer)
