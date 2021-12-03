import std/json
import std/re
import std/options
import std/os
import std/sugar
import std/strutils
import std/sequtils
import fp/tryM
import fp/either
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

proc getCommandsConfigDir(): string =
  getConfigDir()
  .joinPath(constants.CONFIG_DIRNAME)
  .joinPath(constants.COMMANDS_CONFIG_FILENAME)

proc hasTestStr(testStr: string, matches: seq[string]): bool =
  matches.all(x => testStr.contains(x))

proc fromJson(xs: seq[JsonNode]): seq[ConfigItem] =
  xs --> map((x: JsonNode) => to(x, ConfigItem))
  .filter(not it.description.isEmptyOrWhitespace())

proc getCommands*(path: string = getCommandsConfigDir()): EitherE[seq[ConfigItem]] =
  tryET(readFile(path))
  .flatMap((x: string) => tryET(
    parseJson(x).getElems()
  ))
  .flatMap((xs: seq[JsonNode]) => tryET(xs.fromJson))

# Returns the filtered command descriptions
proc getCommandDescriptions*(xs: seq[ConfigItem], testString: string): seq[string] =
  let testString = testString
  .toLowerAscii
  .split(re"\s+")

  xs --> map(it.description)
  .filter(it.toLowerAscii.hasTestStr(testString))
