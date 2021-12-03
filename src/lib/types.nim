import typetraits
import std/strformat
import fusion/matching
import fp/option
import std/options

{.experimental: "caseStmtMacros".}

type
  CommandKind = enum
    desktopItem, configItem
  Command* = ref object
    name*: string
    command*: string

    case kind: CommandKind
    of desktopItem:
      filePath*: string
    of configItem:
      exclude*: option.Option[bool]
      binding*: option.Option[string]

    
case Command(kind: desktopItem, name: "hey", filePath: "foo"):
of desktopItem(filePath: "foo", name: @a):
  echo a
else:
  echo "no"




# type
#   Foo = enum a, b
#   Option*[T] = object
#     ## An optional type that may or may not contain a value of type `T`.
#     ## When `T` is a a pointer type (`ptr`, `pointer`, `ref` or `proc`),
#     ## `none(T)` is represented as `nil`.
#     when f.kin
#       val: T
#     else:
#       val: T
#       has: bool
