import std/osproc
import std/strutils
import fp/either
import print

proc log*(x: auto): auto =
  print(x)
  x

proc sh*(cmd: string, opts = {poStdErrToStdOut}): Either[string, string] =
  let (res, exitCode) = execCmdEx(cmd, opts)
  if exitCode == 0:
    return res
        .strip
        .right(string)
  return res
    .strip
    .left(string)
