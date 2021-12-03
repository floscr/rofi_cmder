import std/tables
import std/asyncdispatch
import std/os
import std/tempfiles
import std/sugar
import std/strutils
import std/strformat
import std/sequtils
import std/strutils
import std/streams
import std/strformat
import std/os
import std/times
import fp/tryM
import fp/either
import fusion/matching
import env
import print
import zero_functional
import cascade

{. experimental: "caseStmtMacros" .}

const DB_TIME_FORMAT = "yyyy-MM-dd'T'HH:mm:sszzz"

proc dbDate*(x: DateTime): string =
  x.format(DB_TIME_FORMAT)

proc dbDate*(): string {.inline.} =
  utc(now()).dbDate()

type countT* = int
type timeT* = string
type dataT* = string
type
  DbItem* = object
    count*: countT
    time*: timeT
    data*: dataT

proc `$`*(x: DbItem): string =
     &"""DbItem(
    count: {x.count},
    time: {x.time},
    data: {x.data},
)"""

proc increment(x: DbItem): DbItem =
  cascade x:
    count = x.count + 1

proc createDbItem(data: dataT): DbItem =
  DbItem(
    count: 0,
    time: dbDate(),
    data: data,
  )

proc toCsvRowString(x: DbItem): string =
  (count: @count, time: @time, data: @data) := x
  &"{count},{time},{data}"

proc fromCsvRowString(x: string): DbItem =
  [@count, @time, @data] := x.split(",", maxsplit = 2)
  DbItem(
    count: count.parseInt,
    time: time,
    data: data,
  )

proc parseLinesAsMap(xs: seq[string]): OrderedTable[countT, seq[DbItem]] =
  xs --> map(fromCsvRowString)
  .group(it.count)

proc prepareText(x: string): seq[string] =
  var y = x
  y.stripLineEnd()
  y.splitLines()

when isMainModule:
  proc updateFile(data: string): auto =
    let dbPath = "/tmp/foo"
    let db = openFileStream(dbPath, fmRead)

    var output = ""
    var line = ""
    var hasUpdateRow = false

    while db.readLine(line):
      let item = fromCsvRowString(line)

      if item.data == data:
        output &= item.increment().toCsvRowString() & "\n"
        hasUpdateRow = true
        continue

      output &= line & "\n"

    if not hasUpdateRow:
      output &= createDbItem(data).toCsvRowString()

    db.close()

    let (cfile, path) = createTempFile("tmpprefix_", "_end.tmp")
    cfile.write(output)
    cfile.setFilePos(0)
    close cfile

    removeFile(dbPath)
    moveFile(path, dbPath)

  updateFile("<span>d​ddrun​</span>")

  # "/home/floscr/.cache/cmder_history.db".lines --> filter(not it.isEmptyOrWhitespace)
  # .map(fromCsvRowString)
  # .createIter(errorLines)
  # errorLines() --> foreach(echo it)
