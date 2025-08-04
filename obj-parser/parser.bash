#!/bin/bash
#
#

readonly OBJ_AF=100000

# declare -a object_vertexes object_triangles
# load_obj <obj_file> object_vertexes object_triangles
load_obj(){
    # This assume a "Normalized" object (vertex coords are in [-1, 1])
    local obj_file="$1"
    # forgot the bash has var reference of sort
    declare -n \
        obj_verts="$2" \
        obj_triags="$3" #\
        # obj_faces="$4"

    # shim the vertex arrays so that their index starts @ 1
    obj_verts[0]=''


    while read type data; do
        case "$type" in
            ("v")
                read -a vert <<< "$data" || return 1
                # here we normalized the coordinate info to integer...
                # for component in "${vert[@]}"; do
                #     component_norm="$(bc <<< "( (-1 * $component) + 1) * $OBJ_AF")"
                #     vert_norm+=("${component_norm%.*}")
                # done

                x="$(bc <<< "( (${vert[0]}) + 1) * $OBJ_AF")"
                y="$(bc <<< "( (-1 * ${vert[1]}) + 1) * $OBJ_AF")"
                z="$(bc <<< "( (${vert[2]}) + 1) * $OBJ_AF")"

                obj_verts+=("${x%.*} ${y%.*} ${z%.*}")
                # unset vert_norm
                ;;
            (f)
                read -a points <<< "$data" || return 1
                # ${var%%/*} would greedily glomp :3 suffixes starting with a `/`
                # like: "a/v/b/f" => "a"
                # but this is applied over the whole `points' array
                # ... which I didn't know bash can do til today :O
                obj_triags+=("${points[*]%%/*}")
                ;;
            (*)
                # echo "Currently unsupported '$type' :(" >&2
                ;;
        esac
    done < "$obj_file"


}
