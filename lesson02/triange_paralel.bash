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

clone_array(){
    declare -n array_input="$1" \
        array_output="$2"

    # echo "clone_array: array_input ${!array_input[@]}" >&2
    for index in "${!array_input[@]}"; do
        array_output[$index]="${array_input[$index]}"
    done

}

draw_triangle(){
    # echo "Start draw_triangle" >&2
    declare -i \
        x1="${1:?}" \
        y1="${2:?}" \
        x2="${3:?}" \
        y2="${4:?}" \
        x3="${5:?}" \
        y3="${6:?}" \
        color="${7:?}"
    declare -n buffer="${8:-CANVAS_BUFFER}"
    # local buffer_clone=()
    # clone_array buffer buffer_clone
    let '
        x_ab=x2-x1, y_ab=y2-y1,
        x_bc=x3-x2, y_bc=y3-y2,
        x_ca=x1-x3, y_ca=y1-y3,

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
        ),

        bb_upper_line=(bb_upper_y+1)>>1,
        bb_lower_line=(bb_lower_y+1)>>1
    '
    # our bounding box is gonna get quantized into lines
    # set up stuff to do this stuff parallel-ly
    # pointer by claude and https://unix.stackexchange.com/a/216475
    #
    # honestly had we just use graphics-1ppc.bash we could've eschewed these entire things

    # mktemp -u should returns an unused file name we can use
    local pipe=$(mktemp -u --suffix='.tinyrenderer.buffer_pipe')
    mkfifo "$pipe"
    # local pipe=$(mktemp -u --suffix='.tinyrenderer.buffer_pipe')

    exec 3<>"$pipe" # TODO: maybe NOT link the unique file to a not-so-unique FD?
    rm "$pipe"

    # local seats=$(mktemp -u --suffix='.tinyrenderer.semaphore')
    # mkfifo "$seats"
    # exec 4<>"$seats"
    # printf '\n\n\n\n\n\n\n\n\n\n\n' >&4 # maximum of 12 concurrent jobs

    # to calculate whether or not point P ϵ triangle ABC, we can (ab)use the
    # cross product of our "3D" vectors where the ("z" component of the) cross product vec(AB)⨯vec(AP)
    # should be >0 if vec(AP) is on the left side from the perspective of vec(AB)
    # More importantly if P ϵ ABC then vec(AB)⨯vec(AP), vec(BC)⨯vec(BP), vec(CA)⨯vec(CP)
    # is either ALL positive or ALL negative
    # pointers: Claude,
    # algorithm from: https://www.baeldung.com/cs/check-if-point-is-in-2d-triangle
    {
        for ((column=x=bb_lower_x; x<=bb_upper_x; column=++x)); do
            for ((line=bb_lower_line; line<=bb_upper_line; line++)); do
                # here we process 2 points P1=(x, (line<<1)-1) and P2=(x, line<<1) at once
                # read -u 4 seat;
                :
                {
                    let '
                        x_p1=x_p2=x,
                        y_p1=(line<<1)-1,
                        y_p2=(line<<1),

                        p1_idx=(CANVAS_HEIGHT*x_p1 + y_p1),
                        p2_idx=(CANVAS_HEIGHT*x_p2 + y_p2),

                        x_ap1=x_p1-x1, y_ap1=y_p1-y1,
                        x_bp1=x_p1-x2, y_bp1=y_p1-y2,
                        x_cp1=x_p1-x3, y_cp1=y_p1-y3,

                        x_ap2=x_p2-x1, y_ap2=y_p2-y1,
                        x_bp2=x_p2-x2, y_bp2=y_p2-y2,
                        x_cp2=x_p2-x3, y_cp2=y_p2-y3,

                        orient_ab_ap1=(x_ab * y_ap1) - (y_ab * x_ap1) > 0 ? 1 : -1,
                        orient_bc_bp1=(x_bc * y_bp1) - (y_bc * x_bp1) > 0 ? 1 : -1,
                        orient_ca_cp1=(x_ca * y_cp1) - (y_ca * x_cp1) > 0 ? 1 : -1,
                        p1_in_triangle=((orient_ab_ap1+orient_bc_bp1+orient_ca_cp1)**2) == 9,

                        orient_ab_ap2=(x_ab * y_ap2) - (y_ab * x_ap2) > 0 ? 1 : -1,
                        orient_bc_bp2=(x_bc * y_bp2) - (y_bc * x_bp2) > 0 ? 1 : -1,
                        orient_ca_cp2=(x_ca * y_cp2) - (y_ca * x_cp2) > 0 ? 1 : -1,
                        p2_in_triangle=((orient_ab_ap2+orient_bc_bp2+orient_ca_cp2)**2) == 9,

                        has_change=(p2_in_triangle|p1_in_triangle)
                    '
                    if ((has_change)); then
                        let "
                            p1_color=p1_in_triangle ? color : ${buffer[$p1_idx]:-$DEFAULT_COLOR},
                            p2_color=p2_in_triangle ? color : ${buffer[$p2_idx]:-$DEFAULT_COLOR}
                        "
                        if ((p1_in_triangle)); then
                            echo "$p1_idx $p1_color" >&3
                        fi
                        if ((p2_in_triangle)); then
                            echo "$p2_idx $p2_color" >&3
                        fi

                        printf '\033[%b;%bH\033[38:5:%bm\033[48:5:%bm%s\033[0m' "$line" "$column" "$p1_color" "$p2_color" "$DRAW_CHAR"
                    fi

                    # unset x_p1 \
                    #     y_p1 \
                    #     y_p2 \
                    #     p1_idx \
                    #     p2_idx \
                    #     x_ap1 \
                    #     x_bp1 \
                    #     x_cp1 \
                    #     x_ap2 \
                    #     x_bp2 \
                    #     x_cp2 \
                    #     orient_ab_ap1 \
                    #     orient_bc_bp1 \
                    #     orient_ca_cp1 \
                    #     p1_in_triangle \
                    #     orient_ab_ap2 \
                    #     orient_bc_bp2 \
                    #     orient_ca_cp2 \
                    #     p2_in_triangle \
                    #     p1_color \
                    #     p2_color
                    # # sleep 0.5
                    # # echo "End draw" >&2
                    # # returns the seat
                    # echo >&4
                } &
            done
        # text "Jobs running: $(jobs -p | wc -l)"
        done
        # text "Jobs running: $(jobs -p | wc -l)"

        #
        wait; echo "" >&3
    } &
    # update the buffer
    # echo "Collect buffer update" >&2
    while read -u 3 index color && [[ -n "$color" ]]; do
        if [[ "$color" -eq "$DEFAULT_COLOR" ]]; then
            unset buffer[$index];
        else
            buffer[$index]=$color
        fi
        unset index color
    done
    # close the fd
    # echo "Close FD" >&2
    exec 3>&-
    # echo "Function is Done!" >&2
    # sleep 2
    # draw_line "$x1" "$y1" "$x2" "$y2" "$color"
    # draw_line "$x2" "$y2" "$x3" "$y3" "$color"
    # draw_line "$x3" "$y3" "$x1" "$y1" "$color"
}

source "$(dirname "$0")"/../bash-graphics/graphics.bash

init_canvas 120 120 $BLACK

draw_triangle   7 45 35 100 45  60 $RED
draw_triangle 120 35 90   5 45 110 $WHITE
draw_line 1 75 120 75 $GREEN
draw_triangle 115 83 80  90 85 120 $GREEN
draw_triangle 10 20 120  90 88 120 $PINK
draw_line 1 80 120 80 $GREEN

wait_then_exit_canvas
