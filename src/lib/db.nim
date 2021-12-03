import std/tables
import std/os
import std/tempfiles
import std/sugar
import std/strutils
import std/strformat
import std/sequtils
import std/streams
import std/times
import std/options
import std/algorithm
import fp/tryM
import fp/either
import fp/maybe
import fp/list
import fp/map
import fusion/matching
import env
import zero_functional
import cascade
import ./utils/fp
import ./types
import print

{.experimental: "caseStmtMacros".}

# Data Types

type dataT* = string

type
  DbItem* = object
    data*: dataT
    time*: timeT
    count*: countT

proc `$`*(x: DbItem): string =
  &"""DbItem(
    count: {x.count},
    time: {x.time},
    data: {x.data},
)"""

type
  DbTransactionKind* = enum
    Insert, Increment
  DbTransaction* = ref object
    dbItem*: DbItem
    kind*: DbTransactionKind

proc `$`*(x: DbTransaction): string =
  case x:
    of Insert(dbItem: @dbItem):
       return &"""DbTransaction.Insert(
    DbItem: {dbItem},
)"""
    of Increment(dbItem: @dbItem):
       return &"""DbTransaction.Increment(
    DbItem: {dbItem},
)"""

# Utility Functions

proc dbDate*(x: DateTime): string =
  x.format(DB_TIME_FORMAT)

proc dbDate*(): string {.inline.} =
  utc(now()).dbDate()

proc increment(x: DbItem): DbItem =
  cascade x:
    count = x.count + 1

proc createDbItem*(
  data: dataT,
  time = dbDate(),
  count = 0,
): DbItem =
  DbItem(
    data: data,
    time: time,
    count: count,
  )

proc toCsvRowString(x: DbItem): string =
  (count: @count, time: @time, data: @data) := x
  &"{count},{time},{data}"

proc toCsvRowStrings*(xs: seq[DbItem]): string =
  xs -->
  map(toCsvRowString) -->
  fold("", a & it & "\n")

proc fromCsvRowString(x: string): DbItem =
  [@count, @time, @data] := x.split(",", maxsplit = 2)
  DbItem(
    count: count.parseInt,
    time: time,
    data: data,
  )

proc fromString*(x: string): seq[DbItem] =
  x
  .dup(stripLineEnd)
  .split("\n")
  .map(fromCsvRowString)

proc cmpByCount(x: DbItem, y: DbItem): int =
  cmp(y.count, x.count)

proc dbDataKeyFromCommand*(x: types.Command): dataT =
  x.name &
    DB_HASH_DATA_SPLIT_CHAR &
    x.command.get("")

proc openCreateDbStream(path: string): Stream =
  if fileExists(path):
    openFileStream(path, fmRead)
  else:
    newStringStream("")

proc dbUpdateFile(data: string, dbPath: string): Result =
  ## Update the db file with new data
  let (cfile, path) = createTempFile("tmpprefix_", "_end.tmp")
  cfile.write(data)
  cfile.setFilePos(0)
  close cfile

  removeFile(dbPath)
  moveFile(path, dbPath)

  Ok

proc incrementDbRow*(
  key: string,
  dbStream: Stream,
  createDbItem = createDbItem,
): (string, DbTransaction) =
  ## Update (if exists) or inserts a row in the db Stream with the matching data key.
  ## Returns the db output as string with the updates applied.
  var output = ""
  var line = ""
  var transaction = Nothing[DbTransaction]()

  while dbStream.readLine(line):
    let item = fromCsvRowString(line)

    if transaction.isEmpty() and item.data == key:
      let newItem = item.increment()
      output &= newItem.toCsvRowString() & "\n"
      transaction = Just(DbTransaction(kind: Increment, dbItem: newItem))
      continue

    output &= line & "\n"

  if transaction.isEmpty():
    let newItem = createDbItem(key)
    output &= newitem.toCsvRowString()
    transaction = Just(DbTransaction(kind: Insert, dbItem: newItem))

  (output, transaction.get())

# Implementation Methods

proc dbUpdateInsertRow*(data: string, dbPath = env.dbPath()): EitherE[DbTransaction] =
  openCreateDbStream(dbPath)
  .tryET()
  .flatMap((stream: Stream) =>
           incrementDbRow(key = data, dbStream = stream)
           .tryET()
  )
  .flatMap((xs: (string, DbTransaction)) =>
           dbUpdateFile(xs[0], dbPath)
           .tryET()
           .map(_ => xs[1])
  )


proc toPair*(x: DbItem): tuple[k: dataT, v: DbItem] =
  (x.data, x)

type DbMap* = Map[string, DbItem]

proc dbRead*(dbPath = env.dbPath()): DbMap =
  var element = readFile(dbPath)
  stripLineEnd(element)

  element
  .split("\n")
  .asList
  .map(x => fromCsvRowString(x).toPair())
  .asMap()

proc sortCommandsByDbMap*(dbMap: DbMap, cmds: seq[types.Command]): seq[types.Command] =
  let elements = cmds --> map((cmd: types.Command) =>
                                dbMap
                                .get(cmd.dbHash())
                                .map((y: DbItem) => cmd.setCount(y.count))
                                .getOrElse(cmd)
  )
  .partition(it.count.isSome())

  elements[0]
  .sorted(cmpByCount)
  .concat(elements[1])

when isMainModule:
  echo dbRead()
  # echo assignDbRows()
