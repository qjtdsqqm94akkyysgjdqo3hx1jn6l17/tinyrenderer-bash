#!/bin/bash

# https://haqr.eu/tinyrenderer/bresenham/

# For more colors, see:
# https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
declare -r RED=9 YELLOW=11 GREEN=10 BLUE=12 PINK=13 BLACK=0 WHITE=15 \
    OBJ_PATH="${1:-test/objs/whale/Whale_pose_normalized.obj}" \
    CANVAS_SIZE="${2:-120x120}" \
    BG_COLOR="${3:-0}"

# basically to work around integer math we scale the numbers up by
# `ACCURACY_FACTOR` when we do division then `scale_and_round` them down
# Is this what people called "oversampling"?
declare ACCURACY_FACTOR=50 # deprecated

# draw_line <x1> <y1> <x2> <y2> <color>
draw_line(){
    local \
        x1="${1:?}" \
        y1="${2:?}" \
        x2="${3:?}" \
        y2="${4:?}" \
        color="${5:?}"
    let '
        delta_x=x2 - x1,
        delta_y=y2 - y1,
        steep=(delta_x**2) < (delta_y**2)
    '

    if ((steep)); then
        # swap x and y
        declare -n \
            a1=y1 \
            b1=x1 \
            a2=y2 \
            b2=x2 \
            delta_a=delta_y \
            delta_b=delta_x
    else
        declare -n \
            a1=x1 \
            b1=y1 \
            a2=x2 \
            b2=y2 \
            delta_a=delta_x \
            delta_b=delta_y
    fi

    step=$((delta_a<0 ? -1 : 1))

    # # prevent division by 0
    # if ((delta_a == 0)); then
    #     # draw_pixel "$x1" "$y1" "$color"
    #     return 0
    # fi

    # it might be ugly but it cuts down on the calls quite a bit
    # `round_direction` originally depending on delta_b*delta_a*a_offset
    # but since a_offset shares sign with delta_a (or be 0, since a_offset in [0..delta_a])
    # they both can be eliminated
    for ((
            a=a1,
            a_offset=0,
            b=b1
            ;
            a_offset!=delta_a
            ;
            a_offset+=step,
            a=a1+a_offset,
            round_direction=(delta_b) < 0 ? -1 : 1,
            b_offset=(a_offset*delta_b + round_direction*(delta_a>>1))/delta_a,
            b=b1 + b_offset
        ))
    do
        # artificial delay bc it looks cool
        # sleep 0.01
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


source "$(dirname "$0")"/../bash-graphics/graphics.bash

source "$(dirname "$0")"/../obj-parser/parser.bash

echo loading obj: "$OBJ_PATH"

declare -a obj_vertexes obj_faces
load_obj "$OBJ_PATH" obj_vertexes obj_faces

echo "init canvas with size ${CANVAS_SIZE}"

init_canvas ${CANVAS_SIZE/x/ } $BG_COLOR

TWO_OBJ_AF=$(((OBJ_AF << 1)+1)) # technically it's + 1 (since the rang is in [0, 2*OBJ_AF]) but
# CANVAS_HEIGHT=100
SCALER=$((CANVAS_HEIGHT-1))

# obv this would break if the model is using quads
for face in "${obj_faces[@]}"; do
    read p1_idx p2_idx p3_idx _ <<< "$face"
    # declare -p triangle
    # (Ab)using numfmt to properly scale and round numbers
    # also f*ck it, copy-paste time
    # sleep 0.3
    # set -x
    read -a xy1 <<< "${obj_vertexes[$p1_idx]}"
    read -a xy2 <<< "${obj_vertexes[$p2_idx]}"
    read -a xy3 <<< "${obj_vertexes[$p3_idx]}"
    let '
        x1=1 + (xy1[0]*SCALER + (TWO_OBJ_AF>>1))/TWO_OBJ_AF,
        y1=1 + (xy1[1]*SCALER + (TWO_OBJ_AF>>1))/TWO_OBJ_AF,
        x2=1 + (xy2[0]*SCALER + (TWO_OBJ_AF>>1))/TWO_OBJ_AF,
        y2=1 + (xy2[1]*SCALER + (TWO_OBJ_AF>>1))/TWO_OBJ_AF,
        x3=1 + (xy3[0]*SCALER + (TWO_OBJ_AF>>1))/TWO_OBJ_AF,
        y3=1 + (xy3[1]*SCALER + (TWO_OBJ_AF>>1))/TWO_OBJ_AF
    '

    # declare -p x1 y1
    # sleep 0.5
    # draw the bloody face
    draw_line $x1 $y1 $x2 $y2 $RED
    draw_line $x2 $y2 $x3 $y3 $GREEN
    draw_line $x3 $y3 $x1 $y1 $BLUE

done

for point in "${obj_vertexes[@]}"; do
    read x_comp y_comp _ <<< "$point"
    if [[ -z "$x_comp" ]]; then continue; fi
    let '
        x=1 + (x_comp*SCALER + (TWO_OBJ_AF>>1))/TWO_OBJ_AF,
        y=1 + (y_comp*SCALER + (TWO_OBJ_AF>>1))/TWO_OBJ_AF
    '

    # sleep 0.15
    draw_pixel $x $y $WHITE
    # declare -p x y
done

text "Wireframe Rendering Homework"


wait_then_exit_canvas
