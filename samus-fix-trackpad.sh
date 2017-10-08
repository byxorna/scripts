#!/bin/bash
# Touchpad occasionally doesn't work after waking from sleep using linux 4.9-1+.
# If this happens, reloading the touchpad driver via sudo modprobe -r atmel_mxt_ts && sudo modprobe atmel_mxt_ts usually restores touchpad functionality.

modprobe -r atmel_mxt_ts && modprobe atmel_mxt_ts
