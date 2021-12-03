import osproc
import std/json
import std/re
import std/strformat
import fp/maybe
import ./env

proc matchInput(value: string): seq[string] =
  let unitMatch = value.split(re" in ")
  if unitsBinPath.isDefined() and unitMatch.len == 2:
    @[
      execProcess(&"""{unitsBinPath.get()} "{unitMatch[0]}" {unitMatch[1]}""")
    ]

  elif value =~ re"\d":
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
