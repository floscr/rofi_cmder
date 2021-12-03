import std/json
import std/re
import std/os
import std/sugar
import std/strutils
import std/strformat
import std/sequtils
import fp/tryM
import fp/std/jsonops
import fp/either
import fp/option
import zero_functional
import constants
import std/logging

import print

type
  ConfigItem* = ref object
    description*: string
    command*: Option[string]
    binding*: Option[string]
    exclude*: Option[bool]

proc `$`*(x: ConfigItem): string =
  &"""ConfigItem(description: {x.description})"""

proc serialize(json: JsonNode): ConfigItem =
  # let description = json.mget("description") >>= mvalue(string)

  # if (description.isLeft):
  #   raise newException(Exception, &"No description given for item: \n{json}")

  # if (description.get().isEmpty):
  #   raise newException(Exception, &"No description given for item: \n{json}")

  let description = json.mget("description").flatMap(mvalue(string)).asOption().join()
  let binding = json.mget("binding").flatMap(mvalue(string)).asOption().join()
  let command = json.mget("command").flatMap(mvalue(string)).asOption().join()
  let exclude = json.mget("exclude ").flatMap(mvalue(bool)).asOption().join()


  ConfigItem(
    description: description.getOrElse(""),
    command: command,
    binding: binding,
    exclude: exclude,
  )

proc getCommandsConfigDir(): string =
  getConfigDir()
  .joinPath(constants.CONFIG_DIRNAME)
  .joinPath(constants.COMMANDS_CONFIG_FILENAME)

proc hasTestStr(testStr: string, matches: seq[string]): bool =
  matches.all(x => testStr.contains(x))

proc serializeJson(xs: seq[JsonNode]): seq[ConfigItem] =
  xs --> map((x: JsonNode) => serialize(x))
  .filter(not it.description.isEmptyOrWhitespace())

proc getCommands*(path: string = getCommandsConfigDir()): auto =
  tryET(readFile(path))
  .flatMap((x: string) => tryET(
    parseJson(x).getElems()
  ))
  .flatMap((xs: seq[JsonNode]) => tryET(xs.serializeJson))

# Returns the filtered command descriptions
proc getCommandDescriptions*(xs: seq[ConfigItem], testString: string): seq[string] =
  let testString = testString
  .toLowerAscii
  .split(re"\s+")

  xs --> map(it.description)
  .filter(it.toLowerAscii.hasTestStr(testString))
