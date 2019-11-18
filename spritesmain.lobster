import sheets
import sprites
import gui
import texture

fatal(gl_window("Pining fir Sprites", 400, 400))

let tex = sprite_texture(tile_pine_tree)

while gl_frame() and gl_button("escape") != -1:
    gl_clear(color{ 0.75, 0.75, 0.5, 1.0 })
    gl_set_shader("textured")
    gl_set_primitive_texture(0, tex)
    gl_color(color_white)
    gl_scale(float(gl_window_size()))
    gl_unit_square()
