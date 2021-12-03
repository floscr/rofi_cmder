import std/osproc
import std/strutils
import std/sugar
import fp/either
import fp/maybe
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

proc firstJust*[A, B](fns: seq[B {.nimcall.} -> Maybe[A]], arg: B): Maybe[A] =
  ## Return the first Just in a list of functions
  ## The function must return a Just
  ## Otherwise returns a Nothing
  var found = Nothing[A]()

  for fn in fns:
    let fnResult = fn(arg)
    if fnResult.isDefined():
      found = fnResult
      break

  found

proc firstRight*[E,A,B](fns: seq[B {.nimcall.} -> Either[E,A]], arg: B): Either[E,A] =
  ## Return the first Just in a list of functions
  ## The function must return a Just
  ## Otherwise returns a Nothing
  var found = Left[E]()

  for fn in fns:
    let fnResult = fn(arg)
    if fnResult.isRight():
      found = fnResult
      break

  found
