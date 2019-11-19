import color
import sheets
import texture

var sprite_textures = []::resource

private def load_sprites(filename, resolution, map_size, count):
    let spritesmap = gl_load_texture(filename)
    assert spritesmap
    let stride = map_size.x
    let size   = xy_1i * resolution
    // derived from render_to_texture in util3d
    return map(count) i:
        let at  = xy { i % stride, i / stride }
        let tex = gl_create_blank_texture(size, color_clear, 0)
        assert gl_switch_to_framebuffer(tex, false, texture_format_none, nil, nil)
        gl_set_shader("textured")
        gl_set_primitive_texture(0, spritesmap)
        gl_color(color_white)
        gl_scale(xy_1 * resolution)
        gl_translate(-float(at))
        gl_rect(float(map_size), 0)
        assert gl_switch_to_framebuffer(nil)
        tex

def entity_texture(entity):
    return sprite_texture(entity_sprite_indicies[entity])

def sprite_texture(sprite):
    if length(sprite_textures) == 0:
        sprite_textures = load_sprites("sprites.png", sprite_resolution, sprite_map_size, sprite_count)
    return sprite_textures[sprite]
