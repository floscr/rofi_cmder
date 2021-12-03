import std/osproc
import std/strutils
import std/sugar
import fp/either
import print

type Result* = enum Ok, Error

proc sh*(cmd: string, opts = {poStdErrToStdOut}): Either[string, string] =
  let (res, exitCode) = execCmdEx(cmd, opts)
  if exitCode == 0:
    return res
        .strip
        .right(string)
  return res
    .strip
    .left(string)

proc asSeq*[E,A](e: Either[E,A]): seq[A] =
  ## Converts Either to List
  if e.isLeft:
    @[]
  else:
    @[e.get()]

proc filter*[E,A](v: Either[E, A], cond: A -> bool): Either[A,A] =
  ## Convert to Left unless the `cond` is true
  if v.isRight() and cond(v.get()):
    v
  elif v.isRight():
    v.get().left(E)
  else:
    v
