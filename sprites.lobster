import color
import texture
import vec

class tile_atlas:
    res : xy_i

    kash = []::resource?

    def symbolicate(s:string) -> int:
        fatal_exit("unimplemented: " + this + ".symbolicate()")
        return -1

    def draw_tile(id:int, c:color):
        fatal_exit("unimplemented: " + this + ".draw_tile()")

    def tile_texture(id:int) -> resource:
        assert id >= 0 and id < kash.length
        var tile = kash[id]
        if tile:
            return tile
        tile = sprite_render(xy_1i * res):
            draw_tile(id, color_white)
        kash[id] = tile
        return tile

class text_atlas : tile_atlas
    stretch   : bool
    font_name : string

    text = []::string

    biText = []::string
    ids    = []::int

    def symbolicate(s:string) -> int:
        if not text.length():
            kash.push(nil)
            text.push("")
            biText.push("")
            ids.push(0)
        let n, i = biText.binary_search(s)
        if n:
            return ids[i]
        let id = text.length()
        kash.push(nil) // TODO pre-kash
        text.push(s)
        biText.insert(i, s)
        ids.insert(i, id)
        return id

    def draw_tile(id:int, c:color):
        gl_set_shader("color")
        gl_set_font_name(font_name)
        gl_set_font_size(res.y)
        gl_color(c):
            let t = text[id]
            let box = float(gl_text_size(t))
            if stretch:
                gl_scale(float(res) / box):
                    gl_text(t)
            else: if box.y > box.x:
                gl_scale(res.y / box.y):
                    gl_translate(xy { box.x / 4, 0.0 }):
                        gl_text(t)
            else:
                gl_scale(res.x / box.x):
                    gl_translate(xy { 0.0, box.y / 4 }):
                        gl_text(t)

class sprite_atlas : tile_atlas
    size : xy_i
    tex  : resource

    def coord(id:int):
        let i = id - 1
        return xy { i % size.x, i / size.x }

    def draw_tile(id:int, c:color):
        gl_set_shader("textured")
        gl_set_primitive_texture(0, tex)
        gl_color(c):
            gl_scale(float(res)):
                gl_translate(-float(coord(id))):
                    gl_rect(float(size), 0)

    // TODO implement symbolicate, here or in a subclass

def sprite_new_atlas(tex, res:xy_i, size:xy_i): return sprite_atlas {
    size: size,
    res:  res,
    tex:  tex,
    kash: map(size.x * size.y): nil, // TODO pre-kash
}

// similar to modules/util3d.lobster's, but different choices on API, and
// without the rest of the "util3d" jungle.
def sprite_render(size:xy_i, body):
    return render_into(gl_create_blank_texture(size, color_clear, 0), body)

def render_into(tex, body):
    assert gl_switch_to_framebuffer(tex, false, texture_format_none, nil, nil)
    body()
    assert gl_switch_to_framebuffer(nil)
    return tex
