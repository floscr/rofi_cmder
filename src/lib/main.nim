import fp/list
import fp/option
import fp/trym
import fpUtils
import utils
import os
import osproc
import std/re
import sequtils
import strformat
import strutils
import sugar
import system

{.experimental.}

let desktopApplicationsDir = expandTilde "/etc/profiles/per-user/floscr/share/applications"
let config = expandTilde("~/.config/cmder/cmd.csv")

let splitChar = ",,,"
let commandSplitChar = "​" # Zero Width Space

const DB_FILE_NAME = "cmder_history.db"
const HISTORY_FILE_NAME = "cmder_history.txt"


type
  ConfigItem = ref object
    description: string
    command: string
    binding: Option[string]

proc `$`*(x: ConfigItem): string =
  &"""ConfigItem(description: {x.description}, command: {x.command})"""

proc commands*(xs: seq[ConfigItem]): string =
  xs
    .mapIt(it.description)
    .join("\n")

proc renderBinding(x: Option[string]): string =
  x
    .fold(
      () => "",
      (x) => &"<span gravity=\"east\" size=\"x-small\" font_style=\"italic\" foreground=\"#5c606b\"> {x}</span>",
    )

proc prettyCommands*(xs: seq[ConfigItem]): seq[string] =
  xs.mapIt(&"<span>{commandSplitChar}{it.description}{commandSplitChar}</span>{renderBinding(it.binding)}")

proc parseConfigLine(x:string): ConfigItem =
  let line = x.split(splitChar)
  return ConfigItem(
    description : line[0],
    command : line[1],
    binding : optionIndex(line, 2).filter((x) => x != ""),
  )

proc parseConfig(): seq[ConfigItem] =
  return config
    .readfile
    .strip()
    .splitLines()
    .map(parseConfigLine)

proc exec(x: string, config = parseConfig()) =
  let y = config
    .findIt(it.description == x.split(splitChar, maxsplit = 1)[1])
  echo y.command

proc parseDesktopFile(f: string): ConfigItem =
  var
    exec: string
    name: string

  for line in lines(f):
    if line.startsWith("Exec") and exec.isEmptyOrWhitespace:
      exec = line.split("=", maxsplit = 1)[1]
    if line.startsWith("Name") and name.isEmptyOrWhitespace:
      name = line.split("=", maxsplit = 1)[1]

  ConfigItem(
    description: name,
    command: exec.replace(re"%.", ""),
    binding: none(string),
  )

proc getDesktopApplications(): any =
  toSeq(walkDir(desktopApplicationsDir, true))
    .filter(x => x.path.endsWith("desktop"))
    .map(c => joinPath(desktopApplicationsDir, c.path) |> parseDesktopFile)

proc prettyXmonadCommand(x: string): string =
  x
  .split("-")
  .map(capitalizeAscii)
  .join(" ")

proc getXmonadItems(): seq[ConfigItem] =
  fromEither(tryET do:
    readFile "/tmp/xmonad-commands")
  .map(x => x
       .strip(trailing = true)
       .splitLines()
  )
  .getOrElse(@[])
  .map(command => ConfigItem(
    description: &"XMonad: {prettyXmonadCommand(command)}",
    command: &"xmonadctl {command}",
    binding: none(string)
  ))

proc main*(): any =
  let config = parseConfig()
  let desktopApplications = getDesktopApplications()
  let xmonadItems = getXmonadItems()

  let freceDb = getCacheDir().joinPath(DB_FILE_NAME)
  let freceTxt = getEnv("XDG_CACHE_HOME").joinPath(HISTORY_FILE_NAME)

  let items = config
    .concat(desktopApplications)
    .concat(xmonadItems)

  let printedItems = items.prettyCommands()

  writeFile(freceTxt, printedItems.join("\n"))

  if (fileExists(freceDB)):
    discard execProcess(&"frece update \"{freceDb}\" \"{freceTxt}\" --purge-old")
  else:
    discard execProcess(&"frece init \"{freceDb}\" \"{freceTxt}\"")

  let response = execProcess(&"frece print \"{freceDb}\" | rofi -i -dmenu -p \"\" -markup-rows").replace("\n", "")
  if response != "":
    let index = printedItems.find(response)
    let escaped = response.replace("\"", "\\\"")

    discard execShellCmd(&"frece increment \"{freceDb}\" \"{escaped}\"")
    discard execShellCmd(items[index].command)
