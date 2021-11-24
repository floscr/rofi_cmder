import std/json
import std/options
import std/os
import std/sugar
import std/strutils
import std/sequtils
import fp/tryM
import fp/either
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

proc getCommands*(path: string = getCommandsConfigDir()): EitherE[seq[ConfigItem]] =
  tryET(readFile(path))
  .flatMap((x: string) => tryET(
    parseJson(x).getElems()
  ))
  .flatMap((xs: seq[JsonNode]) => tryET(
    xs
    .map((x: JsonNode) => to(x, ConfigItem))
    .filterIt(not it.description.isEmptyOrWhitespace())
  ))
