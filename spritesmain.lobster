import sheets
import sprites
import gui
import texture

fatal(gl_window("Such Sprites", 400, 400))

var last_input = gl_time()
def read_input(body):
    if gl_time() - last_input > 0.2:
        if gl_button("right") > 0:
            body(1)
            last_input = gl_time()
        else: if gl_button("left") > 0:
            body(-1)
            last_input = gl_time()

var tile_id = 0
var tex = sprite_texture(tile_id)

let max_tile = 128

while gl_frame() and gl_button("escape") != -1:
    read_input() d:
        tile_id = (tile_id + d + max_tile) % max_tile
        tex = sprite_texture(tile_id)

    var size = float(gl_window_size())

    gl_clear(color{ 0.75, 0.75, 0.5, 1.0 })
    gl_set_shader("textured")
    gl_set_primitive_texture(0, tex)
    gl_color(color_white)
    gl_scale(if size.x > size.y:
        xy { size.y, size.y }
    else:
        xy { size.x, size.x })

    gl_unit_square()
