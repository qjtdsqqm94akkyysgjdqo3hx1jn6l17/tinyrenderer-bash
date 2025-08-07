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

    # sorting points by y, based on an answer on stackoverflow
    # looks ugly, but hey, 2, sometimes 3 comparisons ops on avg is kinda
    # better than always having to do 3 ops in an exploded bubble sort, right?
    # r-right??
    let '
        y1 < y2 ? (
            y2 < y3 ? (
                xa=x1,
                ya=y1,
                xb=x2,
                yb=y2,
                xc=x3,
                yc=y3
            ) : (
                y1 < y3 ? (
                    xa=x1,
                    ya=y1,
                    xb=x3,
                    yb=y3,
                    xc=x2,
                    yc=y2
                ) : (
                    xa=x3,
                    ya=y3,
                    xb=x1,
                    yb=y1,
                    xc=x2,
                    yc=y2
                )
            )
        ) : (
            y1 < y3 ? (
                xa=x2,
                ya=y2,
                xb=x1,
                yb=y1,
                xc=x3,
                yc=y3
            ) : (
                y2 < y3 ? (
                    xa=x2,
                    ya=y2,
                    xb=x3,
                    yb=y3,
                    xc=x1,
                    yc=y1
                ) : (
                    xa=x3,
                    ya=y3,
                    xb=x2,
                    yb=y2,
                    xc=x1,
                    yc=y1
                )
            )
        ),
        step=xb < xc ? 1 : -1
    '

    # stuff everything inside a bash arithmetic... thing seems to be the
    # way to go for better performance
    for ((
            y=ya,
            x_delta_ba=xb-xa,
            y_delta_ba=yb-ya,
            ba_sign=(x_delta_ba*y_delta_ba > 0 ? 1 : -1),
            x_delta_ca=xc-xa,
            y_delta_ca=yc-ya,
            ca_sign=(x_delta_ca*y_delta_ca > 0 ? 1 : -1),
            x_edge_1=x_edge_2=xa
            ;
            y < yb
            ;
            (y++),
            x_edge_1=xa+((y-ya)*x_delta_ba + ba_sign*y_delta_ba/2)/y_delta_ba,
            x_edge_2=xa+((y-ya)*x_delta_ca + ca_sign*y_delta_ca/2)/y_delta_ca
        )); do
        # rasterized the 2 sides
        # we don't have to worry about 0 division with the for cond there
        text top
        for ((x=x_edge_1; x!=x_edge_2+step; x+=step)); do
            draw_pixel "$x" "$y" "$color"
        done
    done

        # local x_edge_1=$((yc == yb ? xb : xb+(y-yb)*(xc-xb)/(yc-yb)))
    for ((
            y=yb,
            x_delta_cb=xc-xb,
            y_delta_cb=yc-yb,
            cb_sign=(x_delta_cb * y_delta_cb > 0 ? 1 : -1),
            x_edge_1=xb,
            x_edge_2=xa+((y-ya)*x_delta_ca + ca_sign*y_delta_ca/2)/y_delta_ca
            ;
            y <= yc
            ;
            (y++),
            x_edge_1=xb+((y-yb)*x_delta_cb + cb_sign*y_delta_cb/2)/y_delta_cb,
            x_edge_2=xa+((y-ya)*x_delta_ca + ca_sign*y_delta_ca/2)/y_delta_ca
        )); do
            text bottom

        for ((x=x_edge_1; x!=x_edge_2+step; x+=step)); do
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
