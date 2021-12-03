import std/unittest
import std/options
import std/sugar
import fp/maybe

import ../src/lib/utils_option

suite "utils_option":
  test "fpOptionToStdOption":
    let stdOption = some(true)
    let fpOption = just(true)

    check: convertMaybe(stdOption) == fpOption
    check: convertMaybe(fpOption) == stdOption
