import std/strformat
import fusion/matching
import std/options
import std/strformat
import std/re
import std/strutils
import std/sequtils
import std/sugar
import zero_functional

{.experimental: "caseStmtMacros".}

type
  CommandKind* = enum
    desktopItem, configItem
  Command* = ref object
    name*: string
    command*: options.Option[string]

    case kind*: CommandKind

    of desktopItem:
      desktopFilePath*: string
      desktopEntryHeader*: string

    of configItem:
      exclude*: options.Option[bool]
      binding*: options.Option[string]

proc `$`*(x: Command): string =
  case x:
    of desktopItem(name: @a):
       return &"""Command(
    kind: desktopItem,
    name: {x.name},
    command: {x.command},
    desktopFilePath: {x.desktopFilePath},
    desktopEntryHeader: {x.desktopEntryHeader},
)"""
    of configItem(name: @a):
       return &"""Command(
    kind: configItem,
    name: {x.name},
    command: {x.command},
)"""

proc hasTestStr(testStr: string, matches: seq[string]): bool =
  matches.all(x => testStr.contains(x))

proc filterByNames*(xs: seq[Command], testString: string): seq[Command] =
  let testString = testString
  .toLowerAscii()
  .split(re"\s+")

  xs --> filter(it.name.toLowerAscii().hasTestStr(testString))
