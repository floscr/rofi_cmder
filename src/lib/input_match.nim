import std/json
import std/re
import std/strformat
import std/collections/sequtils
import std/strutils
import std/sugar
import fp/maybe
import fp/either
import ./env
import ./utils/fp
import ./state

proc matchInput(value: string): seq[string] =
  let unitMatch = value.split(re" in ")
  if unitsBinPath.isDefined() and unitMatch.len == 2:
    sh(&"""{unitsBinPath.get()} "{unitMatch[0]}" {unitMatch[1]}""")
    .asSeq()

  elif value =~ re"\d":
    sh(&"""echo "{value}" | bc""")
    .filter(x => not x.startsWith("(standard_in)"))
    .asSeq()

  else:
    @[]

proc onStdinJson*(state: State): seq[types.Command] =
  case state.stdinJsonState["name"].getStr():
    of "input change":
      matchInput(state.inputText)

    of "select entry":
      matchInput(state.inputText)

    else:
      @[]
