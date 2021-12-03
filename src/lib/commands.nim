import std/json
import std/re
import std/os
import std/sugar
import std/strutils
import std/sequtils
import fp/tryM
import fp/std/jsonops
import fp/either
import fp/option
import zero_functional
import constants
import ./types
import ./utils_option.nim

proc fromJsonNode(json: JsonNode): types.Command =
  let description = json.mget("description").flatMap(mvalue(string)).asOption().join()
  let binding = json.mget("binding").flatMap(mvalue(string)).asOption().join()
  let command = json.mget("command").flatMap(mvalue(string)).asOption().join()
  let exclude = json.mget("exclude ").flatMap(mvalue(bool)).asOption().join()

  types.Command(
    kind: types.configItem,
    name: description.getOrElse(""),
    command: command.convertOption(),
    binding: binding.convertOption(),
    exclude: exclude.convertOption(),
  )

proc getCommandsConfigDir(): string =
  getConfigDir()
  .joinPath(constants.CONFIG_DIRNAME)
  .joinPath(constants.COMMANDS_CONFIG_FILENAME)

proc fromJsonSeq(xs: seq[JsonNode]): seq[types.Command] =
  xs --> map((x: JsonNode) => fromJsonNode(x))
  .filter(not it.name.isEmptyOrWhitespace())

proc getCommands*(path: string = getCommandsConfigDir()): auto =
  tryET(readFile(path))
  .flatMap((x: string) => tryET(
    parseJson(x).getElems()
  ))
  .flatMap((xs: seq[JsonNode]) => tryET(xs.fromJsonSeq))
