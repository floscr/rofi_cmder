import std/parseutils
import std/strutils
import std/streams
import std/sugar
import std/os
import std/sequtils
import std/collections/sequtils
import fusion/matching
import zero_functional
import types

{.experimental: "caseStmtMacros".}

proc parseDesktopFile(path: string): seq[types.Command] =
  var strm = newFileStream(path, fmRead)

  var
    line: string = ""
    entries: seq[types.Command]
    currentEntr: types.Command

  while strm.readLine(line):
    # Read lines until desktop section is found
    if line.startsWith("["):
      if currentEntr != nil:
        entries.add(currentEntr)

      currentEntr = types.Command(
        kind: desktopItem,
        desktopFilePath: path,
        desktopEntryHeader: captureBetween(line, '[', ']')
      )
      continue

    # Ignore anything not in a desktop section
    if currentEntr == nil: continue

    # Extract only needed key value pairs
    case line.split(sep="=", maxsplit=1):
      of ["Name", @value]:
        currentEntr.name = value
        continue
      of ["Exec", @value]:
        currentEntr.command = value.some
        continue

  # Push the last parsed entry to the captured entries
  if currentEntr != nil:
    entries.add(currentEntr)

  strm.close()

  entries

proc getDesktopApplicationsDirs(): seq[string] =
  let dataDirs = getEnv("XDG_DATA_DIRS").split(sep=":")
  let dataHome = getEnv("XDG_DATA_HOME")

  dataDirs & dataHome

proc findDesktopFiles(dir: string): seq[string] =
  let files = toSeq(walkDir(dir, true))

  files --> filter(it.path.endsWith("desktop"))
  .map(dir.joinPath(it.path))

proc getDesktopApplications*(dirs: seq[string] = getDesktopApplicationsDirs()): seq[types.Command] =
  let desktopFiles = dirs --> map(it.joinPath("/applications"))
  .map((x: string) => findDesktopFiles(x))
  .flatten()

  desktopFiles --> map(parseDesktopFile)
  .flatten()
