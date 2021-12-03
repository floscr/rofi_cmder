import std/osproc
import std/strutils
import std/sugar
import fp/either
import print

type Result* = enum Ok, Error

proc sh*(cmd: string, opts = {poStdErrToStdOut}): Either[string, string] =
  ## Execute a shell command and wrap it in an Either
  ## Right for a successful command (exit code: 0)
  ## Left for a failing command (any other exit code, so 1)
  let (res, exitCode) = execCmdEx(cmd, opts)
  if exitCode == 0:
    return res
        .strip
        .right(string)
  return res
    .strip
    .left(string)

proc asSeq*[E,A](e: Either[E,A]): seq[A] =
  ## Converts Either to seq
  if e.isLeft:
    @[]
  else:
    @[e.get()]

proc filter*[E,A](v: Either[E, A], cond: A -> bool): Either[A,A] =
  ## Convert Right to Left when the `cond` is not met
  if v.isRight() and cond(v.get()):
    v
  elif v.isRight():
    v.get().left(E)
  else:
    v
