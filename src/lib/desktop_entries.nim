import std/parseutils
import std/strutils
import std/streams
import std/sugar
import std/strformat
import std/os
import std/osproc
import std/collections/sequtils
import zero_functional

import fusion/matching

import fp/option
import zero_functional

{.experimental: "caseStmtMacros".}

type DesktopEntry = ref object
  filePath: string
  entryName: string
  name: string
  exec: string

proc `$`*(x: DesktopEntry): string =
  &"""DesktopEntry(
filePath: {x.filePath},
entryName: {x.entryName},
name: {x.name},
exec: {x.exec},
)"""

proc parseDesktopFile(path: string): seq[DesktopEntry] =
  var strm = newFileStream(path, fmRead)

  var
    line: string = ""
    entries: seq[DesktopEntry]
    currentEntr: DesktopEntry

  while strm.readLine(line):
    # Read lines until desktop section is found
    if line.startsWith("["):
      if currentEntr != nil:
        entries.add(currentEntr)

      currentEntr = DesktopEntry(
        filePath: path,
        entryName: captureBetween(line, '[', ']')
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
        currentEntr.exec = value
        continue

  # Push the last parsed entry to the captured entries
  if currentEntr != nil:
    entries.add(currentEntr)

  entries

proc getDesktopApplicationsDirs(): seq[string] =
  getEnv("XDG_DATA_DIRS").split(sep=":")

proc findDesktopFiles(dir: string): seq[string] =
  let files = toSeq(walkDir(dir, true))

  files --> filter(it.path.endsWith("desktop"))
  .map(dir.joinPath(it.path))

proc getDesktopApplications*(dirs: seq[string] = getDesktopApplicationsDirs()): seq[DesktopEntry] =
  let desktopFiles = dirs --> map(it.joinPath("/applications"))
  .map((x: string) => findDesktopFiles(x))
  .flatten()

  desktopFiles --> map(parseDesktopFile)
  .flatten()

# echo getDesktopApplicationsDirs()
# echo getDesktopApplications()
echo getDesktopApplications(@[ "/etc/profiles/per-user/floscr/share" ])
