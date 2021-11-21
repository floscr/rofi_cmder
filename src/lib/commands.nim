import std/json,
       std/options,
       std/os,
       std/sugar,
       std/sequtils
import fp/tryM,
       fp/either

import constants

type
  ConfigItem* = ref object
    description*: string
    command*: Option[string]
    binding*: Option[string]
    exclude*: Option[bool]

proc getCommandsConfigDir(): string =
  getConfigDir()
  .joinPath(constants.CONFIG_DIRNAME)
  .joinPath(constants.COMMANDS_CONFIG_FILENAME)

proc getCommands*(path: string = getCommandsConfigDir()): EitherS[seq[ConfigItem]] =
  trySt(readFile(path))
  .flatMap((x: string) => trySt(
    parseJson(x)
    .getElems()
  ))
  .flatMap((xs: seq[JsonNode]) => trySt(
    xs.map((x: JsonNode) => to(x, ConfigItem)))
  )
