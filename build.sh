#!/bin/bash

# any error will halt the execution
set -e

(cd demo/bootblock; ./make.sh)
(cd demo/copper; ./make.sh)
(cd demo/driver; ./make.sh)

./tools/adftrack/adftrack \
    ./demo/bootblock/bootblock \  # bootblock
    demo.adf \                    # target ADF file
    map.i \                       # maping files -> (start_block, size_in_block)
   ./demo/driver/driver \         # first block of data/code
    ./demo/copper/copper          # second block of data/code

[ $? -ne 0 ] && exit

FS_EXEC=/bin/fs-uae
SYSTEM=$(uname -s)
if [ "${SYSTEM}x" = "Darwinx" ]; then
  FS_EXEC="/Applications/FS-UAE Launcher.app/Contents/FS-UAE.app/Contents/MacOS/fs-uae"
fi

"${FS_EXEC}" --chip_memory=4096 \
  --joystick_port_1=none \
  --amiga_model=A500 \
  --floppy_drive_0_sounds=off \
  --console_debugger=1 \
  demo.adf
