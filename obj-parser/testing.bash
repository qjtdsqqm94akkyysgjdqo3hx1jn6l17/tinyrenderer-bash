source "$(dirname "$0")"/parser.bash


declare -a radio_vertexes radio_triangles
load_obj "test/objs/radio/radio.obj" radio_vertexes radio_triangles

declare -p radio_vertexes radio_triangles
