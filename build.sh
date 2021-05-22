#!/bin/bash

# any error will halt the execution
set -e

(cd demo/bootblock; ./make.sh)
(cd demo/copper; ./make.sh)
(cd demo/driver; ./make.sh)

echo "Creating ADF File"
./tools/adftrack/adftrack \
    ./demo/bootblock/bootblock \
    demo.adf \
    map.i \
   ./demo/driver/driver \
   ./demo/copper/copper

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
