import sheets
import gui
import texture

fatal(gl_window("Such Sprites", 400, 400))

let sheet_sprites = load_sheet_sprites()

var last_input = gl_time()
def read_input(body):
    if gl_time() - last_input > 0.2:
        if gl_button("right") > 0:
            body(1)
            last_input = gl_time()
        else: if gl_button("left") > 0:
            body(-1)
            last_input = gl_time()

var sprite_id = 0

gl_set_font_name("data/fonts/US101/US101.TTF")
gl_set_font_size(10)

while gl_frame() and gl_button("escape") != -1:
    read_input() d:
        let n = sheet_sprites.size.x * sheet_sprites.size.y
        sprite_id = (sprite_id + d + n) % n
        var s = "sprite_id:" + sprite_id
        for(tile_sprite_id) sid, id: if sid == sprite_id: s += " " + tile_entity_id(id)
        for(item_sprite_id) sid, id: if sid == sprite_id: s += " " + item_entity_id(id)
        print(s)

    let size = float(gl_window_size())

    gl_clear(color{ 0.75, 0.75, 0.5, 1.0 })
    gl_set_shader("textured")
    gl_set_primitive_texture(0, sheet_sprites.tile_texture(sprite_id))
    gl_color(color_white)
    gl_scale(if size.x > size.y:
        xy { size.y, size.y }
    else:
        xy { size.x, size.x })

    gl_unit_square()
