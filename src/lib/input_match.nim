import osproc
import std/re
import strformat

proc matchInput*(value: string): seq[string] =
  if value =~ re"\d":
    @[
      execProcess(&"""echo "{value}" | bc""")
    ]
  else:
    @[]
