import std/strformat
import fusion/matching
import std/options
import std/re
import std/strutils
import std/sequtils
import std/sugar
import std/times
import zero_functional
import cascade

{.experimental: "caseStmtMacros".}

const DB_TIME_FORMAT* = "yyyy-MM-dd'T'HH:mm:sszzz"
const DB_HASH_DATA_SPLIT_CHAR* = "​" # Zero Width Space

type timeT* = string
type countT* = int

type
  CommandKind* = enum
    desktopItem, configItem
  Command* = ref object
    name*: string
    command*: Option[string]

    preventDbPersist*: bool

    count*: Option[countT]
    time*: Option[timeT]

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
    count: {x.count},
    desktopFilePath: {x.desktopFilePath},
    desktopEntryHeader: {x.desktopEntryHeader},
)"""
    of configItem(name: @a):
       return &"""Command(
    kind: configItem,
    name: {x.name},
    command: {x.command},
    count: {x.count},
)"""

proc hasTestStr(testStr: string, matches: seq[string]): bool =
  matches.all(x => testStr.contains(x))

proc filterByNames*(xs: seq[Command], testString: string): seq[Command] =
  let testString = testString
  .toLowerAscii()
  .split(re"\s+")

  xs --> filter(it.name.toLowerAscii().hasTestStr(testString))

proc dbHash*(x: Command): string =
  x.name &
    DB_HASH_DATA_SPLIT_CHAR &
    x.command.get("")

proc cmpByCount*(x: Command, y: Command): int =
  cmp(y.count.get(0), x.count.get(0))

proc increment*(x: Command): Command =
  cascade x:
    count = x.count.map(y => y + 1)

proc setCount*(x: Command, val: countT): Command =
  cascade x:
    count = val.some()

proc asClipboardCopyCommand*(name: string): Command =
  Command(
    name: name,
    command: some(fmt"""echo "{name.quoteShell()}" | xclip -selection clipboard -in"""),
    preventDbPersist: true,
  )
