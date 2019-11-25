import color
import texture
import vec

class tile_atlas:
    res : xy_i

    kash = []::resource

    def symbolicate(s:string) -> int:
        fatal_exit("unimplemented: " + this + ".symbolicate()")
        return -1

    def draw_tile(id:int, c:color):
        fatal_exit("unimplemented: " + this + ".draw_tile()")

    def render_tile(id:int, c:color) -> resource:
        return sprite_render(xy_1i * res): draw_tile(id, c)

    def tile_texture(id:int) -> resource:
        assert id >= 0 and id < kash.length
        return kash[id]

class text_atlas : tile_atlas
    stretch   : bool
    font_name : string

    text = []::string

    biText = []::string
    ids    = []::int

    def symbolicate(s:string) -> int:
        if not text.length():
            kash.push(sprite_render(xy_1i * res): nil) // TODO error pattern?
            text.push("")
            biText.push("")
            ids.push(0)
        let n, i = biText.binary_search(s)
        if n:
            return ids[i]
        let id = text.length()
        text.push(s)
        kash.push(this.render_tile(id, color_white))
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
            if box.y == 0 or box.x == 0:
                fatal_exit("empty box:" + box + " for codes:" + string_to_unicode(t) + " in font:" + font_name)
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

def sprite_new_atlas(tex, res:xy_i, size:xy_i):
    let kash = map(size.x * size.y) id: sprite_render(res): if id != 0:
        let i = id - 1
        let at = xy { i % size.x, i / size.x }
        gl_set_shader("textured")
        gl_set_primitive_texture(0, tex)
        gl_color(color_white):
            gl_scale(float(res)):
                gl_translate(-float(at)):
                    gl_rect(float(size), 0)
    return sprite_atlas {
        size: size,
        res:  res,
        tex:  tex,
        kash: kash,
    }

def with_framebuffer(size:xy_i, fmt:texture_format, body):
    let tex = gl_create_blank_texture(size, color_clear, fmt)
    assert gl_switch_to_framebuffer(tex, false, fmt, nil, nil)
    body(size)
    assert gl_switch_to_framebuffer(nil)
    return tex

def sprite_render(size:xy_i, body):
    return with_framebuffer(size, texture_format_clamp | texture_format_nomipmap, body)
