// This program shows the texture map produced
// by the rounded_corners module.
//
//       00     01     10     11
//    +------+------+------+------+
// 00 | "  " | " ▄" | "▄ " | "▄▄" |
//    +------+------+------+------+
// 01 | " ▀" | " █" | "▄▀" | "▄█" |
//    +------+------+------+------+
// 10 | "▀ " | "▀▄" | "█ " | "█▄" |
//    +------+------+------+------+
// 11 | "▀▀" | "▀█" | "█▀" | "██" |
//    +------+------+------+------+
//
import rounded_corners

fatal(gl_window("Rounded Corners", 300, 300))
let rounded_corners = articulate_rounded_corners()
while gl_frame() and gl_button("escape") != -1 and gl_button("q") != 1:
    gl_clear(dark_green)
    gl_set_shader("textured")
    gl_color(dark_blue)
    gl_scale(float(gl_window_size()) / 4)
    for(rounded_corners) corner, i:
        gl_translate(xy_f{ i % 4, i / 4 }):
            gl_set_primitive_texture(0, corner)
            gl_rect(xy_1)
