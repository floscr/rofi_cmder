import std/collections/sequtils
import std/sugar
import std/options
import std/algorithm
import fp/maybe
import fp/either
import fp/list
import fp/map
import print
import ./types
import ./db
import ./modules/module_commands
import ./modules/module_desktop_entries
import ./modules/module_steam_games
import zero_functional
import cascade
# import ./types

let mainCommands = getCommands().getOrElse(@[])

let commands = mainCommands
.concat(getDesktopApplications())
.concat(getSteamGames())

let dbEntries = dbRead()

proc cmpByCount(x: types.Command, y: types.Command): int =
  cmp(y.count.get(0), x.count.get(0))

proc transferCount*(cmd: types.Command, dbItem: DbItem): types.Command =
  cascade cmd:
    count = some(dbItem.count)

let foo = commands --> map((x: types.Command) => dbEntries
                           .get(x.dbHash())
                           .map((y: DbItem) => transferCount(x, y))
                           .getOrElse(x)
)
.partition(it.count.isSome())



echo foo[0]
.asList()
.sortBy(cmpByCount)
.append(foo[1].asList())
