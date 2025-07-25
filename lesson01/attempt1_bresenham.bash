#!/bin/bash

# https://haqr.eu/tinyrenderer/bresenham/

# For more colors, see:
# https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
declare -r RED=9 YELLOW=11 GREEN=10 BLUE=12 PINK=13 BLACK=0 WHITE=15

# draw_line <x1> <y1> <x2> <y2> <color>
draw_line(){
    local \
        x1="${1:?}" \
        y1="${2:?}" \
        x2="${3:?}" \
        y2="${4:?}" \
        color="${5:?}"
    local x_dist="$((x2 - x1))"
    local y_dist="$((y2 - y1))"

    for t in {2..100..2}; do
        # artificial delay bc it looks cool
        sleep 0.01
        draw_pixel "$((x1 + (t*x_dist/100)))" "$((y1 + (t*y_dist/100)))" "$color"
    done
}

source "$(dirname "$0")"/../bash-graphics/graphics.bash

init_canvas 100 100 $BLACK
text "Approach 1"
sleep 3

declare -r ax=7 ay=3 \
           bx=12 by=37 \
           cx=62 cy=53 \

draw_line $ax $ay $bx $by $BLUE
draw_line $cx $cy $bx $by $GREEN
draw_line $cx $cy $ax $ay $YELLOW
draw_line $ax $ay $cx $cy $RED

draw_pixel $ax $ay $WHITE
draw_pixel $bx $by $WHITE
draw_pixel $cx $cy $WHITE

wait_then_exit_canvas
