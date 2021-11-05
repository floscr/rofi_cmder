import cligen
import lib/main

{.experimental.}

const AppName* = "rofi_cmder"

proc cli(): int =
  main()
  1

dispatch(cli, help = {})
