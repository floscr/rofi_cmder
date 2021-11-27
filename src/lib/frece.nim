import std/times
import std/tables
import std/os
import std/sugar
import std/sequtils
import std/strutils
import fp/tryM
import fp/either
import fp/map
import unpack
import constants
import print
import zero_functional

type count* = int

type
  DbItem* = ref object
    count*: count
    time*: string
    data*: string

proc getDbPath(): string =
  getCacheDir()
  .joinPath(constants.CACHE_DIRNAME)
  .joinPath(constants.CACHE_FREECE_DB_FILENAME)

proc parseLine(x: string): DbItem =
  [count, time, data] <- x.split(",", maxsplit = 2)
  DbItem(
    count: count.parseInt,
    time: time,
    data: data,
  )

proc parseLinesAsMap(xs: seq[string]): OrderedTable[count, seq[DbItem]] =
  xs --> map(parseLine)
  .group(it.count)

proc prepareText(x: string): seq[string] =
  var y = x
  y.stripLineEnd()
  y.splitLines()

proc readDb*(dbPath: string = getDbPath()): auto =
  tryET(readFile(dbPath))
  .map(prepareText)
  .flatMap((xs: seq[string]) => tryET(
    parseLinesAsMap(xs)
  ))



# echo @[-3, 1, 2, 3] --> filter(it > 0)


print readDb("/home/floscr/.cache/cmder_history.db")
