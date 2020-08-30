// daia_draw provides methods for rendering a cube, with each face oriented
// according to the Daia world topology (see daia_topology.lobster).

import vec

//                                 inverted clockwise
//  Z       4---5             .---.   .---.
//   \      |\  |\    1540->1 |\ 1 \  |   |\  5<-5464
//    0--X  | 0---1           | .---. | 5 | .
//    |     | | | |   0462->2 |2|   | |   |3| 3<-5137
//    Y     6-|-7 |           ' | 0 | '---' |
//           \|  \|   3102->0  \|   |  \ 4 \| 4<-7326
//            2---3             '---'   '---'
//                    counter-clockwise

// face_meshes contains the meshes for the six faces of a Daia cube, facing
// outward.

def new_daia_face_vertices(): return [
    "3102", // 1
    "1540", // 2
    "0462", // 3
    "5137", // 4
    "7326", // 5
    "5764", // 6
]

// These are in order from top-right, counter-clockwise.
// I can offer no explanation why the origin is not the top- or bottom-left.
let square_corners = [xy_0, xy_x, xy_1, xy_y]
let square_triangle_indices = [0, 1, 2, 2, 3, 0]

def new_daia_face_meshes(vertices):
    return map(vertices) v:
        let positions = map(v) c: xyz_v(map(3) i: float(c & (1 << (2 - i)) != 0))
        gl_new_mesh(
            "PT",
            positions, // "P"
            [], // colors,
            [], // normals,
            square_corners, // "T" texcoords,
            [], // textcoords2,
            square_triangle_indices
        )

def draw_daia(face_meshes, face_colors, face_textures):
    gl_set_shader("textured")
    gl_translate(-xyz_1/2): for(6) i:
        // The texture colors are multiplied by the color in context.
        // Since the texture on our mesh is white on black, we can change the
        // white to a unique color for each face of the world.
        gl_color(face_colors[i])
        gl_set_primitive_texture(0, face_textures[i])
        gl_render_mesh(face_meshes[i])
