#!/bin/bash

trap 'close_canvas; exit 0;' INT
trap 'sleep 2; wait_then_exit_canvas; exit 0;' QUIT

# From: attempt3_v2.bash
# For more colors, see:
# https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
declare -r RED=9 YELLOW=11 GREEN=10 BLUE=12 PINK=13 BLACK=0 WHITE=15

# basically to work around integer math we scale the numbers up by
# `ACCURACY_FACTOR` when we do division then `scale_and_round` them down
# Is this what people called "oversampling"?
declare ACCURACY_FACTOR=30

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

    local steep="$(((x_dist*x_dist) < (y_dist*y_dist)))"
    local a0 b0 a1 b1 a_dist b_dist

    if ((steep)); then
        # swap x and y
        declare -n \
            a1=y1 \
            b1=x1 \
            a2=y2 \
            b2=x2 \
            a_dist=y_dist \
            b_dist=x_dist
    else
        declare -n \
            a1=x1 \
            b1=y1 \
            a2=x2 \
            b2=y2 \
            a_dist=x_dist \
            b_dist=y_dist
    fi

    step=$((a_dist<0 ? -1 : 1))

    # it might be ugly but it cuts down on the calls quite a bit
    for ((
            a=a1,
            a_offset=0,
            b_scaled=ACCURACY_FACTOR*b1
            ;
            a_offset!=a_dist
            ;
            a_offset+=step,
            a=a1+a_offset,
            b_scaled=ACCURACY_FACTOR*b1 + ACCURACY_FACTOR*a_offset*b_dist/a_dist
        ))
    do
        # artificial delay bc it looks cool
        # sleep 0.01

        local b="$(scale_and_round "$b_scaled" $ACCURACY_FACTOR)"
        if ((steep)); then    # swap them back
            draw_pixel "$b" "$a" "$color"
        else
            draw_pixel "$a" "$b" "$color"
        fi
    done
}

scale_and_round(){
    # based on https://stackoverflow.com/a/24253318
    printf '%d' "$((sign=($1*$2)>0 ?1:-1, ($1 + sign*$2/2)/$2))"
}



draw_triangle(){
    declare -i \
        x1="${1:?}" \
        y1="${2:?}" \
        x2="${3:?}" \
        y2="${4:?}" \
        x3="${5:?}" \
        y3="${6:?}" \
        color="${7:?}"

    let '
        bb_lower_x=x1<x2 ? (
            x1<x3 ? x1 : x3
        ) : (
            x2<x3 ? x2 : x3
        ),
        bb_lower_y=y1<y2 ? (
            y1<y3 ? y1 : y3
        ) : (
            y2<y3 ? y2 : y3
        ),

        bb_upper_x=x1>x2 ? (
            x1>x3 ? x1 : x3
        ) : (
            x2>x3 ? x2 : x3
        ),
        bb_upper_y=y1>y2 ? (
            y1>y3 ? y1 : y3
        ) : (
            y2>y3 ? y2 : y3
        )
    '

    for ((x=bb_lower_x; x<=bb_upper_x; x++)); do
        # to do: increment y by 2 or the actual terminal lines
        for ((y=bb_lower_y; y<=bb_upper_y; y++)); do
            draw_pixel "$x" "$y" "$color"
        done
    done

    # sleep 2
    # draw_line "$x1" "$y1" "$x2" "$y2" "$color"
    # draw_line "$x2" "$y2" "$x3" "$y3" "$color"
    # draw_line "$x3" "$y3" "$x1" "$y1" "$color"
}

source "$(dirname "$0")"/../bash-graphics/graphics.bash

init_canvas 120 120 $BLACK

draw_triangle   7 45 35 100 45  60 $RED
draw_triangle 120 35 90   5 45 110 $WHITE
draw_triangle 115 83 80  90 85 120 $GREEN

wait_then_exit_canvas
