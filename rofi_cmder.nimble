# Package

version       = "0.1.0"
author        = "Florian Schroedl"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["rofi_cmder"]
binDir        = "./dst"


# Dependencies

requires "nim >= 1.4.4"
requires "nimfp >= 0.4.5"
requires "cligen >= 1.5.4"
requires "zero_functional"
requires "print"
requires "redux"
requires "fusion"

import distros
if detectOs(NixOS):
  foreignDep "pkgconfig"
