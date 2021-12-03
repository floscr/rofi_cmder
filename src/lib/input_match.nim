import osproc
import std/json
import std/re
import strformat


proc matchInput(value: string): seq[string] =
  if value =~ re"\d":
    @[
      execProcess(&"""echo "{value}" | bc""")
    ]
  else:
    @[]

proc onStdinJson*(stdinJson: JsonNode): seq[string] =
  case stdinJson["name"].getStr():
    of "input change":
      var value = stdinJson["value"].getStr()
      matchInput(value)

    of "select entry":
      var value = stdinJson["value"].getStr()
      matchInput(value)

    else:
      @[]
