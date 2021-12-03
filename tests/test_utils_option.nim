import std/unittest
import std/options
import std/sugar
import fp/option

import ../src/lib/utils_option

suite "utils_option":
  test "fpOptionToStdOption":
    let stdOption = option.some(true)
    let fpOption = options.some(true)

    check: convertOption(stdOption) == fpOption
    check: convertOption(fpOption) == stdOption
