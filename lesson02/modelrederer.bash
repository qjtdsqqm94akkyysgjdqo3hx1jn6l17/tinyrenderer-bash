#!/bin/bash

# For more colors, see:
# https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
declare -r RED=9 YELLOW=11 GREEN=10 BLUE=12 PINK=13 BLACK=0 WHITE=15 \
    OBJ_PATH="${1:-test/objs/whale/Whale_pose_normalized.obj}" \
    CANVAS_SIZE="${2:-120x120}" \
    BG_COLOR="${3:-0}"

trap 'close_canvas; exit 0;' INT
trap 'sleep 2; wait_then_exit_canvas; exit 0;' QUIT


# trigger warning for BOGUS schizo code
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
        )
        '
    # I thought I was OH SO CLEVER, straight up not caring if a side is on the left or right by calculate the step once up here.
    # alas I didn't account for cases where

    # Welp, we gonna abuse the cross product again
    # vec(AB)⨯vec(AC)>0 if AC (the longer side) is to the left of AB, which mean we need to go right to left (step = -1)
    let '
        cross_product_ab_ac=((xb-xa)*(yc-ya) - (yb-ya)*(xc-xa)),
        step=(cross_product_ab_ac < 0) ? 1 : -1
    '

    if ((ya == yb && yb == yc)); then
        return 0
    fi
    # echo "A=($xa, $ya);B=($xb, $yb);C=($xc, $yc);"  >&2

    local x_delta_ba y_delta_ba ba_sign x_delta_ca y_delta_ca ca_sign x_edge_1 x_edge_2
    # stuff everything inside a bash arithmetic... thing seems to be the
    # way to go for better performance
    for ((
            y=ya,
            x_delta_ba=xb-xa,
            y_delta_ba=yb-ya,
            ba_sign=(x_delta_ba*y_delta_ba < 0 ? -1 : 1),
            x_delta_ca=xc-xa,
            y_delta_ca=yc-ya,
            ca_sign=(x_delta_ca*y_delta_ca < 0 ? -1 : 1),
            x_edge_1=x_edge_2=xa
            ;
            y < yb
            ;
            (++y),
            x_edge_1=xa+((y-ya)*x_delta_ba + ba_sign*y_delta_ba/2)/y_delta_ba,
            x_edge_2=xa+((y-ya)*x_delta_ca + ca_sign*y_delta_ca/2)/y_delta_ca
        )); do
        # rasterized the 2 sides
        # we don't have to worry about 0 division with the for cond there
        # declare -p x_edge_1 x_edge_2 step >&2
        for ((x=x_edge_1; ((x_edge_2-x)*step) >= 0; x+=step)); do
            draw_pixel "$x" "$y" "$color"
        done
    done

        # local x_edge_1=$((yc == yb ? xb : xb+(y-yb)*(xc-xb)/(yc-yb)))
    for ((
            y=yb,
            x_delta_cb=xc-xb,
            y_delta_cb=yc!=yb ? yc-yb : 999999999,
            cb_sign=(x_delta_cb * y_delta_cb < 0 ? -1 : 1),
            x_edge_1=xb,
            x_edge_2=xa+((y-ya)*x_delta_ca + ca_sign*y_delta_ca/2)/y_delta_ca
            ;
            y <= yc
            ;
            (y++),
            x_edge_1=xb+((y-yb)*x_delta_cb + cb_sign*y_delta_cb/2)/y_delta_cb,
            x_edge_2=xa+((y-ya)*x_delta_ca + ca_sign*y_delta_ca/2)/y_delta_ca
        )); do

        # declare -p x_edge_1 x_edge_2 step >&2
        for ((x=x_edge_1; ((x_edge_2-x)*step) >= 0; x+=step)); do
            draw_pixel "$x" "$y" "$color"
        done
    done

    # sleep 2
    # draw_line "$x1" "$y1" "$x2" "$y2" "$color"
    # draw_line "$x2" "$y2" "$x3" "$y3" "$color"
    # draw_line "$x3" "$y3" "$x1" "$y1" "$color"
}

source "$(dirname "$0")"/../bash-graphics/graphics.bash

source "$(dirname "$0")"/../obj-parser/parser.bash

declare -a obj_vertexes obj_faces

echo loading obj: "$OBJ_PATH"
load_obj "$OBJ_PATH" obj_vertexes obj_faces

echo "init canvas with size ${CANVAS_SIZE/x/ } $BG_COLOR"
sleep 1

init_canvas ${CANVAS_SIZE/x/ } $BG_COLOR

let '
    SCALER=CANVAS_HEIGHT-1,
    TWO_OBJ_AF=(OBJ_AF << 1)+1,
    color=0
'

# test decorative triangles for bg
#
# let '
#     xA=(CANVAS_WIDTH*2)/3,
#     yA=CANVAS_HEIGHT/10,
#     xB=(CANVAS_WIDTH*8)/9,
#     yB=(CANVAS_HEIGHT*9)/10,
#     xC=(CANVAS_WIDTH*1)/8,
#     yC=(CANVAS_HEIGHT*5)/10
#     '
# draw_triangle $xA $yA $xB $yB $xC $yC "$((((RANDOM)%3)+234))"
# draw_triangle $xB $yC $xA $yB $xC $yA "$((((RANDOM)%3)+234))"
# draw_triangle $xC $yB $xA $yC $xB $yA "$((((RANDOM)%3)+234))"

# # exit 0
# sleep 3

for face in "${obj_faces[@]}"; do
    read -a vert_idx <<<"$face" && {
        if [[ "${#vert_idx[@]}" -lt 3 ]]; then
            error "Something is broky woky"
        fi

        # project face to canvas xy coords
        points_flat=()
        # sorry quads, you're welcomed but not acknowledged here
        for idx in {0..2}; do
            read x_val y_val _ <<< "${obj_vertexes[${vert_idx[idx]}]}" && \
            let '
                x_idx=idx<<1,
                y_idx=x_idx+1,
                points_flat[x_idx]= ((x_val*SCALER + TWO_OBJ_AF/2)/TWO_OBJ_AF)+1,
                points_flat[y_idx]= ((y_val*SCALER + TWO_OBJ_AF/2)/TWO_OBJ_AF)+1
            '
            # sleep 1.5
            # since TWO_OBJ_AF, SCALER and x_val are always >0 we don't need a check here
        done
        # text "face: ${points_flat[@]}"
        # text
        # echo
        # declare -p face points_flat

        # sleep 3
        [[ "${#points_flat[@]}" -ne 6 ]] && { text 'Something is EXTRA wrong, but well, whatever...'; continue; }

        # some kinda backface culling black magic
        # 2times the `signed_triangle_area`
        # in https://haqr.eu/tinyrenderer/rasterization/#putting-all-together-back-face-culling
        if (( ( (points_flat[3]-points_flat[1])*(points_flat[2]+points_flat[0]) + (points_flat[5]-points_flat[3])*(points_flat[4]+points_flat[2]) + (points_flat[1]-points_flat[5])*(points_flat[0]+points_flat[4]) )<2)); then continue; fi

        # draw_pixel "${points_flat[0]}" "${points_flat[1]}" '196'
        # draw_pixel "${points_flat[2]}" "${points_flat[3]}" '196'
        # draw_pixel "${points_flat[4]}" "${points_flat[5]}" '196'

        # sleep 0.5
        # read

        # text "Last triangle with A=$(( ( (points_flat[3]-points_flat[1])*(points_flat[2]+points_flat[0]) + (points_flat[5]-points_flat[3])*(points_flat[4]+points_flat[2]) + (points_flat[1]-points_flat[5])*(points_flat[0]+points_flat[4]) )))"
        # declare -p points_flat

        draw_triangle "${points_flat[@]}" "$(((RANDOM%215)+17))" || error 'Something is wrong, but well, whatever...'
        # text "drawing done"
    } || { error 'Something is wrong, but well, whatever...'; }
done

wait_then_exit_canvas
