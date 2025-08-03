#!/bin/bash

# https://haqr.eu/tinyrenderer/bresenham/

# For more colors, see:
# https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
declare -r RED=9 YELLOW=11 GREEN=10 BLUE=12 PINK=13 BLACK=0 WHITE=15

# basically to work around integer math we scale the numbers up by
# `ACCURACY_FACTOR` when we do division then `scale_and_round` them down
# Is this what people called "oversampling"?
declare ACCURACY_FACTOR=50

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

    if ((a_dist<0)); then
        step=-1
    fi

    # prevent division by 0
    if ((a_dist == 0)); then
        # draw_pixel "$x1" "$y1" "$color"
        return 0
    fi

    for a in $(seq "$a1" "$step" "$a2"); do
        # artificial delay bc it looks cool
        # sleep 0.01
        local a_offset="$((a-a1))"
        local b_scaled="$((ACCURACY_FACTOR*b1 + (ACCURACY_FACTOR*a_offset*b_dist/a_dist)))"
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
    if ((($1*$2)>0)); then
        printf '%d' "$((($1+$2/2)/$2))"
    else
        printf '%d' "$((($1-$2/2)/$2))"
    fi
}


source "$(dirname "$0")"/../bash-graphics/graphics.bash

source "$(dirname "$0")"/../obj-parser/parser.bash

declare -a whale_vertexes whale_triangles
load_obj "test/objs/whale/Whale_pose_normalized.obj" whale_vertexes whale_triangles


init_canvas 402 402 $BLACK

TWO_OBJ_AF=$(((OBJ_AF << 1)+1)) # technically it's + 1 (since the rang is in [0, 2*OBJ_AF]) but
# CANVAS_HEIGHT=100
SCALER=$((CANVAS_HEIGHT-1))

# obv this would break if the model is using quads
for triangle in "${whale_triangles[@]}"; do
    read p1_idx p2_idx p3_idx <<< "$triangle"
    # declare -p triangle
    # (Ab)using numfmt to properly scale and round numbers
    # also f*ck it, copy-paste time
    # sleep 0.3
    # set -x
    read -d $'\n' x1 y1 _ <<< \
        "$(numfmt ${whale_vertexes[$p1_idx]} --from-unit=$SCALER --to-unit=${TWO_OBJ_AF} --format='%.0f' | tr $'\n' ' ')" || return 1
    vertex_coords+=("$x1 $((++y1))")
    read -d $'\n' x2 y2 _ <<< \
        "$(numfmt ${whale_vertexes[$p2_idx]} --from-unit=$SCALER --to-unit=${TWO_OBJ_AF} --format='%.0f' | tr $'\n' ' ')" || return 1
    vertex_coords+=("$x2 $((++y2))")
    read -d $'\n' x3 y3 _ <<< \
        "$(numfmt ${whale_vertexes[$p3_idx]} --from-unit=$SCALER --to-unit=${TWO_OBJ_AF} --format='%.0f' | tr $'\n' ' ')" || return 1
    vertex_coords+=("$x3 $((++y3))")

    # set +x

    # text

    # declare -p x1 y1
    # sleep 0.5
    # draw the bloody triangle
    draw_line $x1 $y1 $x2 $y2 $RED
    draw_line $x2 $y2 $x3 $y3 $GREEN
    draw_line $x3 $y3 $x1 $y1 $BLUE

done

for point in "${vertex_coords[@]}"; do
    read x y <<< "$point"
    # sleep 0.15
    draw_pixel $x $y $PINK
    # declare -p x y
done

text "Wireframe Rendering Homework"


wait_then_exit_canvas
