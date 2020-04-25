// This module generates a sprite map to overlay over intersections where any
// quadrant about that intersection may be water or lava.
// The texture is the same but parameterized by the color.
//
// The texture array is indexed by a bit vector representing whether each
// corner around the intersection is filled.
//
//       0 | 1
//      ---+---
//       2 | 3
//
// The texture file contains only three shapes from which all other
// intersections are rotations and composites.
//
// The following table illustrates the index number, index bit vector,
// block art representation, description of the composition in
// terms of the primitive textures A, B, and C and the rotations
// clockwise (cw), counter-clockwise (ccw), and about-face (af).
// Two of these require duplication of the primitive texture A,
// but the second is a rotation of the first.
//
//        0123
// +----+------+------+--------------+-----------+
// |  0 | 0000 | "  " | clear        |           |
// +----+------+------+--------------+-----------+
// |  1 | 0001 | " ▄" | Aaf          | 8af       |
// +----+------+------+--------------+-----------+
// |  2 | 0010 | "▄ " | Accw         | 8ccw      |
// +----+------+------+--------------+-----------+
// |  3 | 0011 | "▄▄" | Baf          | 12af      |
// +----+------+------+--------------+-----------+
// |  4 | 0100 | " ▀" | Acw          | 8cw       |
// +----+------+------+--------------+-----------+
// |  5 | 0101 | " █" | Bcw          | 12cw      |
// +----+------+------+--------------+-----------+
// |  6 | 0110 | "▄▀" | Acw and Accw | 9cw       |
// +----+------+------+--------------+-----------+
// |  7 | 0111 | "▄█" | Ccw          | 13cw      |
// +----+------+------+--------------+-----------+
// |  8 | 1000 | "▀ " | A            |           |
// +----+------+------+--------------+-----------+
// |  9 | 1001 | "▀▄" | A and Aaf    | 8 and 8af |
// +----+------+------+--------------+-----------+
// | 10 | 1010 | "█ " | Bccw         | 12ccw     |
// +----+------+------+--------------+-----------+
// | 11 | 1011 | "█▄" | Caf          | 13af      |
// +----+------+------+--------------+-----------+
// | 12 | 1100 | "▀▀" | B            |           |
// +----+------+------+--------------+-----------+
// | 13 | 1101 | "▀█" | C            |           |
// +----+------+------+--------------+-----------+
// | 14 | 1110 | "█▀" | Cccw         | 12ccw     |
// +----+------+------+--------------+-----------+
// | 15 | 1111 | "██" | fill         |           |
// +----+------+------+--------------+-----------+
//
// From this table we can construct a build plan, where
// we first produce the primitive textures then each of the
// composites from textures previously produced.
//
//   0 = clear
//   15 = fill
//   8 = A
//   12 = B
//   13 = C
//   4 = 8cw = Acw
//   1 = 8af = Aaf
//   2 = 8ccw = Accw
//   9 = 4 + 1 = A and Aaf
//   6 = 9cw or 4 + 2 = Acw and Accw
//   5 = 12cw = Bcw
//   3 = 12af = Baf
//   10 = 12ccw = Bccw
//   7 = 13cw = Ccw
//   11 = 13af = Caf
//   14 = 13ccw = Cccw

import vec
import color
import brand
import texture

def articulate_rounded_corners():
    let vec_cw = xy_y // clockwise
    let vec_af = -xy_x // about face
    let vec_ccw = -xy_y // counter-clockwise

    let res_i = xy_1i * 72
    let res = float(res_i)

    let rc = gl_load_texture(pakfile "../art/png/72x72/rounded-corners.png")
    assert(rc)

    let rounded_corner_textures = map(16):
        gl_create_blank_texture(
            res_i,
            color_clear,
            texture_format_clamp|texture_format_nomipmap
        )

    // +----+------+------+--------------+-----------+
    // | 15 | 1111 | "██" | fill         |           |
    // +----+------+------+--------------+-----------+
    render_to_texture(rounded_corner_textures[15], res_i, false, nil, 0):
        gl_set_shader("color")
        gl_color(color_white)
        gl_scale(res)
        gl_rect(xy_1)

    // +----+------+------+--------------+-----------+
    // |  8 | 1000 | "▀ " | A            |           |
    // +----+------+------+--------------+-----------+
    render_to_texture(rounded_corner_textures[8], res_i, false, nil, 0):
        gl_set_shader("textured")
        gl_set_primitive_texture(0, rc)
        gl_scale(res)
        gl_rect(xy{ 3.0, 1.0 })

    // +----+------+------+--------------+-----------+
    // | 12 | 1100 | "▀▀" | B            |           |
    // +----+------+------+--------------+-----------+
    render_to_texture(rounded_corner_textures[12], res_i, false, nil, 0):
        gl_set_shader("textured")
        gl_set_primitive_texture(0, rc)
        gl_scale(res)
        gl_translate(xy{ -1.0, 0.0 })
        gl_rect(xy{ 3.0, 1.0 })

    // +----+------+------+--------------+-----------+
    // | 13 | 1101 | "▀█" | C            |           |
    // +----+------+------+--------------+-----------+
    render_to_texture(rounded_corner_textures[13], res_i, false, nil, 0):
        gl_set_shader("textured")
        gl_set_primitive_texture(0, rc)
        gl_scale(res)
        gl_translate(xy{ -2.0, 0.0 })
        gl_rect(xy{ 3.0, 1.0 })

    // +----+------+------+--------------+-----------+
    // |  4 | 0100 | " ▀" | Acw          | 8cw       |
    // +----+------+------+--------------+-----------+

    def copy_rot(dst, src, rot, dup):
        render_to_texture(rounded_corner_textures[dst], res_i, false, nil, 0):
            gl_set_shader("textured")
            gl_set_primitive_texture(0, rounded_corner_textures[src])
            gl_scale(res)
            if dup:
                gl_rect(xy_1)
            gl_translate(xy_1/2)
            gl_rotate_z(rot)
            gl_translate(-xy_1/2)
            gl_rect(xy_1)

    def copy_rot(dst, src, rot):
        copy_rot(dst, src, rot, false)

    copy_rot(4, 8, vec_cw)

    // +----+------+------+--------------+-----------+
    // |  1 | 0001 | " ▄" | Aaf          | 8af       |
    // +----+------+------+--------------+-----------+
    copy_rot(1, 8, vec_af)

    // +----+------+------+--------------+-----------+
    // |  2 | 0010 | "▄ " | Accw         | 8ccw      |
    // +----+------+------+--------------+-----------+
    copy_rot(2, 8, vec_ccw)

    // +----+------+------+--------------+-----------+
    // |  9 | 1001 | "▀▄" | A and Aaf    | 8 and 8af |
    // +----+------+------+--------------+-----------+
    copy_rot(9, 8, vec_af, true)

    // +----+------+------+--------------+-----------+
    // |  6 | 0110 | "▄▀" | Acw and Accw | 9cw       |
    // +----+------+------+--------------+-----------+
    copy_rot(6, 9, vec_cw)

    // +----+------+------+--------------+-----------+
    // |  5 | 0101 | " █" | Bcw          | 12cw      |
    // +----+------+------+--------------+-----------+
    copy_rot(5, 12, vec_cw)

    // +----+------+------+--------------+-----------+
    // |  3 | 0011 | "▄▄" | Baf          | 12af      |
    // +----+------+------+--------------+-----------+
    copy_rot(3, 12, vec_af)

    // +----+------+------+--------------+-----------+
    // | 10 | 1010 | "█ " | Bccw         | 12ccw     |
    // +----+------+------+--------------+-----------+
    copy_rot(10, 12, vec_ccw)

    // +----+------+------+--------------+-----------+
    // |  7 | 0111 | "▄█" | vec_ccw          | 13cw      |
    // +----+------+------+--------------+-----------+
    copy_rot(7, 13, vec_cw)

    // +----+------+------+--------------+-----------+
    // | 11 | 1011 | "█▄" | Caf          | 13af      |
    // +----+------+------+--------------+-----------+
    copy_rot(11, 13, vec_af)

    // +----+------+------+--------------+-----------+
    // | 14 | 1110 | "█▀" | Cccw         | 12ccw     |
    // +----+------+------+--------------+-----------+
    copy_rot(14, 13, vec_ccw)

    return rounded_corner_textures
