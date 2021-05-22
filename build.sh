#!/bin/bash

# any error will halt the execution
set -e

(cd demo/bootblock; ./make.sh)
(cd demo/copper; ./make.sh)
(cd demo/driver; ./make.sh)

echo "Pre-creating ADF File"
./tools/adftrack/adftrack \
    ./demo/bootblock/bootblock \
    demo.adf \
    map.i \
   ./demo/driver/driver \
   ./demo/tunnel/tunnel \
   ./demo/copper/copper

echo "Generating parts mapfile and regenerate driver"
cat map.i | awk -F/ '{print $4}' > demo/includes/parts_map.i
(cd demo/driver; ./make.sh)

echo "Creating ADF File"
./tools/adftrack/adftrack \
    ./demo/bootblock/bootblock \
    demo.adf \
    map.i \
   ./demo/driver/driver \
   ./demo/tunnel/tunnel \
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
