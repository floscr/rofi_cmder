import std/times
import std/os
import std/sugar
import std/sequtils
import std/strutils
import fp/tryM
import fp/either
import unpack
import constants
import print

type
  DbItem* = ref object
    count*: int
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

proc prepareText(x: string): seq[string] =
  var y = x
  y.stripLineEnd()
  y.splitLines()

proc readDb*(dbPath: string = getDbPath()): EitherE[seq[DbItem]] =
  tryET(readFile(dbPath))
  .map(prepareText)
  .flatMap((xs: seq[string]) => tryET(
    xs.map((x: string) => parseLine(x))
  ))

print readDb("/home/floscr/.cache/cmder_history.db")
