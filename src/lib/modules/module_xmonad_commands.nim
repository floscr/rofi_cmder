import std/strformat
import std/strutils
import std/collections/sequtils
import std/sugar
import std/options
import fp/either
import fp/maybe
import ../types

proc prettyPrint(x: string): string =
  x
  .split("-")
  .map(capitalizeAscii)
  .join(" ")

proc getXmonadCommands*(): seq[types.Command] =
  readFile("/tmp/xmonad-commands")
  .tryET()
  .map(x => x
       .strip(trailing = true)
       .splitLines()
  )
  .getOrElse(@[])
  .map((x: string) => types.Command(
    kind: types.configItem,
    name: &"Xmonad: {x.prettyPrint()}",
    command: fmt"xmonadctl {x}".some(),
  ))

when isMainModule:
  echo getXmonadCommands()
