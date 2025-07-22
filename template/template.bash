#!/bin/bash

# For more colors, see:
# https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
declare -r RED=9 YELLOW=11 GREEN=10 BLUE=12 PINK=13 BLACK=0 WHITE=15

source "$(dirname "$0")"/../bash-graphics/graphics.bash

init_canvas 100 100 $BLACK

text "Hello world! Hit [Enter] to exit."

read

close_canvas
# wait_then_exit_canvas
