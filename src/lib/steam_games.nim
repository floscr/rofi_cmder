import std/parseutils
import std/strutils
import std/streams
import std/sugar
import std/re
import std/os
import std/sequtils
import std/collections/sequtils
import std/options
import std/strformat
import fusion/matching
import zero_functional
import types

{.experimental: "caseStmtMacros".}

proc parseConfigFile(path: string): types.Command =
  var strm = newFileStream(path, fmRead)

  var
    line: string = ""
    id = string.none
    name = string.none

  while strm.readLine(line):
    # Found results, early exit
    if id.isSome and name.isSome:
      break

    # Hacky key value pair parsing
    # Remove indentation and split to first group of whitespace
    let parts = line
      .strip
      .split(sep=re"\s+", maxsplit=1)

    case parts:
      of ["\"appid\"", @a]:
        id = a.some
        continue
      of ["\"name\"", @b]:
        name = b.some
        continue

  strm.close()

  [@idValue, @nameValue] := @[id, name]
  .map(x => x.map(y => y.captureBetween(first='\"', second='\"')))

  types.Command(
    kind: types.configItem,
    name: &"Steam: {nameValue.unsafeGet}",
    command: idValue.map(x => &"steam steam://rungameid/{x}",)
  )

proc getSteamAppsDir(): string =
  getEnv("XDG_DATA_HOME").joinPath("/Steam/steamapps")

proc findConfigFiles(dir: string): seq[string] =
  let files = toSeq(walkDir(dir, true))

  files --> filter(it.path.endsWith(".acf"))
  .map(dir.joinPath(it.path))

proc getSteamGames*(path: string = getSteamAppsDir()): auto =
  let configFiles = findConfigFiles(path)

  configFiles  --> map(parseConfigFile)

when isMainModule:
  # echo getDesktopApplications()
  echo getSteamApps()
