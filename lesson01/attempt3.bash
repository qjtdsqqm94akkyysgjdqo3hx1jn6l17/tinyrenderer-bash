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
    local x_dist="$((x2 - x1))" || return 1 # return early if
    local y_dist="$((y2 - y1))" || return 1 # something breaks here
    local step=1

    if ((x_dist<0)); then
        step=-1
    fi

    local steep="$(((x_dist*x_dist) < (y_dist*y_dist)))"
    local A0 B0 A1 B1 A_dist B_dist
    if ((steep)); then
        # swap x and y
        a1="$y1"
        b1="$x1"
        a2="$y2"
        b2="$x2"
        a_dist="$y_dist"
        b_dist="$x_dist"
    else
        a1="$x1"
        b1="$y1"
        a2="$x2"
        b2="$y2"
        a_dist="$x_dist"
        b_dist="$y_dist"
    fi

    for a in $(seq "$a1" "$step" "$a2"); do
        # artificial delay bc it looks cool
        sleep 0.01
        local a_offset="$((a-a1))"
        local b="$((b1 + (a_offset*b_dist/a_dist)))"
        if ((steep)); then    # swap them back
            draw_pixel "$b" "$a" "$color"
        else
            draw_pixel "$a" "$b" "$color"
        fi
    done
}

source "$(dirname "$0")"/../bash-graphics/graphics.bash

init_canvas 100 100 $BLACK

text "Final Solution"
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
