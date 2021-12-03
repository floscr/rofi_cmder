import std/unittest
import std/streams
import ../src/lib/db

suite "db":
  let db = @[
    createDbItem("1"),
    createDbItem("2", count = 3),
    createDbItem("3"),
  ]
  let dbStream = db
  .toCsvRowStrings()
  .newStringStream()

  test "toCsvRowString conversion equals fromString":
    let result = db
    .toCsvRowStrings()
    .fromString()

    check: result == db

  test "increment: existing key should be incremented":
    let result = incrementDbRow(
      key = "2",
      dbStream = dbStream,
    )
    let transaction = result[1]

    check: transaction.kind == Increment
    check: transaction.dbItem.count == 4

  test "increment: new key should be inserted":
    let result = incrementDbRow(
      key = "invalid",
      dbStream = dbStream,
    )
    let transaction = result[1]

    check: transaction.kind == Insert
    check: transaction.dbItem.count == 0
