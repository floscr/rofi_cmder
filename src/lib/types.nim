import std/strformat
import fusion/matching
import std/options

{.experimental: "caseStmtMacros".}

type
  CommandKind* = enum
    desktopItem, configItem
  Command* = ref object
    name*: string
    command*: string

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
    name: {x.name},
)"""
    of configItem(name: @a):
       return &"""Command(
    name: {x.name},
)"""
