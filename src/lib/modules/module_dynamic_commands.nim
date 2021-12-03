import std/json
import std/re
import std/strformat
import std/strutils
import std/sugar
import std/collections/sequtils
import std/os
import fusion/matching
import fp/maybe
import fp/either
import ../env
import ../utils/fp
import ../types
import ../state

{.experimental: "caseStmtMacros".}

type ModuleArgT = tuple[value: string, words: seq[string]]
type ModuleResultT = Maybe[seq[types.Command]]

let empty = nothing(seq[types.Command])

proc convertUnitModule(x: ModuleArgT): ModuleResultT =
  let unitMatch = x.value.split(re" in ")

  if unitsBinPath.isDefined() and unitMatch.len == 2:
    sh(&"""{unitsBinPath.get()} "{unitMatch[0]}" {unitMatch[1]}""")
    .map(asClipboardCopyCommand)
    .asMaybe()
    .map(xs => @[xs])
  else:
    empty

proc calcModule(x: ModuleArgT): ModuleResultT =
  if x.value =~ re"\d":
    sh(&"""echo "{x.value}" | bc""")
    .filter(x => not x.startsWith("(standard_in)"))
    .map(asClipboardCopyCommand)
    .asMaybe()
    .map(xs => @[xs])
  else:
    empty

proc googlerModule(x: ModuleArgT): ModuleResultT =
  case x.words:
    of ["g", all @rest]:
      sh(&"""{googlerBinPath} "{rest.join(" ")}" --json""")
      .asMaybe()
      .map((x: string) => parseJson(x)
        .getElems()
        .map(y => types.Command(
          kind: configItem,
          name: y["title"].getStr(),
          command: (&"""xdg-open "{y["url"].getStr().quoteShell()}"""").some(),
          preventDynamicFilter: true,
          preventDbPersist: true,
        ))
      )
    else:
      empty

proc matchInput(value: string): seq[types.Command] =
  let words = value.split(re"\s+")

  @[
    convertUnitModule,
    calcModule,
    # googlerModule,
  ]
  .firstJust((value, words))
  .getOrElse(@[])

proc getDynamicCommands*(state: State): seq[types.Command] =
  case state.stdinJsonState["name"].getStr():
    of "input change":
      matchInput(state.inputText)

    of "select entry":
      matchInput(state.inputText)

    else:
      @[]
      
when isMainModule:
  sh(&"""googler nim sequtils --json""")
  .asMaybe()
  .map((x: string) => parseJson(x)
    .getElems()
    .map(y => types.Command(
      kind: configItem,
      name: y["title"].getStr(),
      command: (&"""xdg-open "{y["url"].getStr().quoteShell()}"""").some(),
    ))
  )
  .echo
