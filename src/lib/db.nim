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
import ./fpUtils

{.experimental: "caseStmtMacros".}

const DB_TIME_FORMAT = "yyyy-MM-dd'T'HH:mm:sszzz"

type Result = enum Ok, Error
type DbTransaction = enum RowIncrement, RowInsert

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

proc openDbStream(path: string): FileStream =
  openFileStream(path, fmRead)

proc dbUpdateFile(data: string, dbPath: string): Result =
  ## Update the db file with new data
  let (cfile, path) = createTempFile("tmpprefix_", "_end.tmp")
  cfile.write(data)
  cfile.setFilePos(0)
  close cfile

  removeFile(dbPath)
  moveFile(path, dbPath)

  Ok

proc dbStreamIncrementInsertRow*(
  dbStream: FileStream,
  dataField: string
): (string, DbTransaction) =
  ## Update (if exists) or insert a row in the db FileStream with the matching data string.
  ## Returns the db as string with the updates applied.
  var output = ""
  var line = ""
  var transaction = RowInsert

  while dbStream.readLine(line):
    let item = fromCsvRowString(line)

    if item.data == dataField:
      output &= item.increment().toCsvRowString() & "\n"
      transaction = RowIncrement
      continue

    output &= line & "\n"

  if transaction != RowIncrement:
    output &= createDbItem(dataField).toCsvRowString()

  (output, transaction)

proc dbUpdateInsertRow(data: string, dbPath = env.dbPath()): auto =
  openDbStream(dbPath).tryET()
  .flatMap((stream: FileStream) => dbStreamIncrementInsertRow(stream, data).tryET())
  .flatMap((xs: (string, DbTransaction)) =>
           dbUpdateFile(xs[0], dbPath)
           .tryET()
           .map(_ => xs)
  )

proc parseLinesAsMap(xs: seq[string]): OrderedTable[countT, seq[DbItem]] =
  xs --> map(fromCsvRowString)
  .group(it.count)

when isMainModule:
  echo dbUpdateInsertRow("<span>ddsssdd​dddsdsddrun​</span>", "/tmp/foo")
