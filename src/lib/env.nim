import std/os

const APP_NAME* = "rofi_cmder"

const COMMANDS_FILE_NAME* = "commands.json"
const DB_FILE_NAME* = "rofi_cmder.db"

proc configDir*(): string =
  getCacheDir()
  .joinPath(APP_NAME)

proc dbPath*(): string =
  configDir()
  .joinPath(DB_FILE_NAME)

proc commandsPath*(): string =
  configDir()
  .joinPath(COMMANDS_FILE_NAME)
