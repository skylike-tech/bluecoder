version       = "0.1.0"
author        = "BlueCoder"
description   = "One CLI for every AI provider"
license       = "MIT"
srcDir        = "src"
bin           = @["bluecoder"]

task build, "Build the BlueCoder release binary":
  exec "nim c -d:release -d:ssl src/bluecoder.nim && mv src/bluecoder bin/"
