import std/os
import std/unittest
import std/options

import ../src/lib/modules/module_desktop_entries

suite "desktop_entries":
  test "File parsing":
    let entries = getDesktopApplications(@[getCurrentDir().joinPath("./data")])
    check: entries.len == 2

    # First entry
    check: entries[0].desktopEntryHeader == "Desktop Entry"
    check: entries[0].name == "The Desktop Entry Name"
    check: entries[0].command.get == "command "

    # First entry
    check: entries[1].desktopEntryHeader == "Desktop Action new-window"
    check: entries[1].name == "New Window"
    check: entries[1].command.get == """echo Symbol between "" params"""
