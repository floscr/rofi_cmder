import std/logging

var fileLogger* = newFileLogger("errors.log")

proc log*(x: auto): auto =
  fileLogger.log(lvlInfo, x)
