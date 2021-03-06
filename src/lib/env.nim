import std/os
import std/sugar
import fp/maybe

const APP_NAME* = "rofi_cmder"

const COMMANDS_FILE_NAME* = "commands.json"
const DB_FILE_NAME* = "rofi_cmder.db"

proc configDir*(): string =
  getConfigDir()
  .joinPath(APP_NAME)

proc dbPath*(): string =
  getCacheDir()
  .joinPath(DB_FILE_NAME)

proc commandsPath*(): string =
  configDir()
  .joinPath(COMMANDS_FILE_NAME)

proc strDefineToMaybe(x: string): Maybe[string] =
  x.just()
  .notEmpty()
  .filter(x => not x.defined())

const UNITS_BIN_PATH {.strdefine.} = ""
let unitsBinPath* = UNITS_BIN_PATH.strDefineToMaybe()

const GOOGLER_BIN_PATH {.strdefine.} = ""
let googlerBinPath* = GOOGLER_BIN_PATH
.strDefineToMaybe()
.getOrElse("googler")

const DDGR_BIN_PATH {.strdefine.} = ""
let ddgrBinPath* = DDGR_BIN_PATH
.strDefineToMaybe()
.getOrElse("ddgr")
