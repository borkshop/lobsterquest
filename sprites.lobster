import sheets
import color
import util3d

var sprite_textures = []::resource

private def load_sprites():
    let spritesmap = gl_load_texture("sprites.png")
    assert spritesmap
    return map(sprite_count) i:
        let width = sprite_map_size.x
        let at = xy{ i % width, i / width }
        let size = xy_1i * sprite_resolution
        let tex = gl_create_blank_texture(size, color{ 0, 0, 0, 0 }, 0)
        render_to_texture(tex, size, false, nil, 0):
            gl_set_shader("textured")
            gl_set_primitive_texture(0, spritesmap)
            gl_color(color_white)
            gl_scale(xy_1 * sprite_resolution)
            gl_translate(-float(at))
            gl_rect(float(sprite_map_size), 0)

def entity_texture(entity):
    return sprite_texture(entity_sprite_indicies[entity])

def sprite_texture(sprite):
    if length(sprite_textures) == 0:
        sprite_textures = load_sprites()
    return sprite_textures[sprite]
