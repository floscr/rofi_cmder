import std/json
import std/re
import std/strformat
import std/strutils
import std/sugar
import fp/maybe
import fp/either
import ../env
import ../utils/fp
import ../types
import ../state

{.experimental: "caseStmtMacros".}

let empty = nothing(seq[types.Command])

proc convertUnitModule(value: string): Maybe[seq[types.Command]] =
  let unitMatch = value.split(re" in ")

  if unitsBinPath.isDefined() and unitMatch.len == 2:
    sh(&"""{unitsBinPath.get()} "{unitMatch[0]}" {unitMatch[1]}""")
    .map(asClipboardCopyCommand)
    .asMaybe()
    .map(xs => @[xs])
  else:
    empty

proc calcModule(value: string): Maybe[seq[types.Command]] =
  if value =~ re"\d":
    sh(&"""echo "{value}" | bc""")
    .filter(x => not x.startsWith("(standard_in)"))
    .map(asClipboardCopyCommand)
    .asMaybe()
    .map(xs => @[xs])
  else:
    empty

proc matchInput(value: string): seq[types.Command] =
  let words = value.split(re"\s+")

  @[
    convertUnitModule,
    calcModule,
  ]
  .firstJust(value)
  .getOrElse(@[])

proc getDynamicCommands*(state: State): seq[types.Command] =
  case state.stdinJsonState["name"].getStr():
    of "input change":
      matchInput(state.inputText)

    of "select entry":
      matchInput(state.inputText)

    else:
      @[]
