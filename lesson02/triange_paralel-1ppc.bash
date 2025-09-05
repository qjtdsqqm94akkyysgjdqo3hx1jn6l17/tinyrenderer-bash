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
        x_a="${1:?}" \
        y_a="${2:?}" \
        x_b="${3:?}" \
        y_b="${4:?}" \
        x_c="${5:?}" \
        y_c="${6:?}" \
        color="${7:?}"
    # local buffer_clone=()
    # clone_array buffer buffer_clone
    let '
        x_Vec_ab=x_b-x_a, y_Vec_ab=y_b-y_a,
        x_Vec_bc=x_c-x_b, y_Vec_bc=y_c-y_b,
        x_Vec_ca=x_a-x_c, y_Vec_ca=y_a-y_c,

        bb_lower_x=x_a<x_b ? (
            x_a<x_c ? x_a : x_c
        ) : (
            x_b<x_c ? x_b : x_c
        ),
        bb_lower_y=y_a<y_b ? (
            y_a<y_c ? y_a : y_c
        ) : (
            y_b<y_c ? y_b : y_c
        ),

        bb_upper_x=x_a>x_b ? (
            x_a>x_c ? x_a : x_c
        ) : (
            x_b>x_c ? x_b : x_c
        ),
        bb_upper_y=y_a>y_b ? (
            y_a>y_c ? y_a : y_c
        ) : (
            y_b>y_c ? y_b : y_c
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
        for ((x=bb_lower_x; x<=bb_upper_x; x++)); do
            for ((y=bb_lower_y; y<=bb_upper_y; y++)); do
                 echo $x $y
            done
        done | xargs -I {} -P 0 bash -c \
        "
            point_p=({})
            let '
                x_p=point_p[0],
                y_p=point_p[1],
                x_Vec_ap=x_p-$x_a, y_Vec_ap=y_p-$y_a,
                x_Vec_bp=x_p-$x_b, y_Vec_bp=y_p-$y_b,
                x_Vec_cp=x_p-$x_c, y_Vec_cp=y_p-$y_c,

                orient_ab_ap1=($x_Vec_ab * y_Vec_ap) - ($y_Vec_ab * x_Vec_ap) > 0 ? 1 : -1,
                orient_bc_bp1=($x_Vec_bc * y_Vec_bp) - ($y_Vec_bc * x_Vec_bp) > 0 ? 1 : -1,
                orient_ca_cp1=($x_Vec_ca * y_Vec_cp) - ($y_Vec_ca * x_Vec_cp) > 0 ? 1 : -1,
                p_in_triangle=((orient_ab_ap1+orient_bc_bp1+orient_ca_cp1)**2) == 9
            '
            if ((
                    p_in_triangle &&
                    ! (
                        1 > x_p || x_p > $CANVAS_WIDTH ||
                        1 > y_p || y_p > $CANVAS_HEIGHT
                    )
                ))
            then
                printf '\\033[%b;%bH\\033[48:5:%bm \\033[0m' \${y_p} \${x_p} ${color}
            fi
        "

}

source "$(dirname "$0")"/../bash-graphics/graphics-1ppc.bash

init_canvas 120 120 $BLACK

draw_triangle   7 45 35 100 45  60 $RED
draw_triangle 120 35 90   5 45 110 $WHITE
draw_line 1 75 120 75 $GREEN
draw_triangle 115 83 80  90 85 120 $GREEN
draw_triangle 10 20 120  90 88 120 $PINK
draw_line 1 80 120 80 $GREEN

wait_then_exit_canvas
