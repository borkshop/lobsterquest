import color
import std
import vec

import sheets
import sprites

// TODO
// - optimize glyph draw: group by mode
// - more moji coverage, like skin and gender
// - maybe expand to 2-glyphs
// - maybe blend with pixel/grid art

let glyph_fonts = [
    "data/fonts/US101/US101.TTF",
    "data/fonts/Square/square.ttf",
    "data/fonts/unifont.ttf",
    "data/fonts/Twemoji/TwitterColorEmoji-SVGinOT.ttf",
    "",
]

let glyph_shaders = [
    "color",
    "color",
    "color",
    "color",
    "textured",
]

struct glyph:
    mode:int
    code:int
    stretch:bool

    def font_name(): return glyph_fonts[mode]

    def text():
        if font_name() != "":
            return unicode_to_string([code])
        return ""

    def draw(size:xy_f, c:color):
        with_mode(c, size):
            if font_name() != "":
                with_transform(size):
                    gl_text(text())
            else:
                gl_scale(size):
                    gl_unit_square()

    def bounds(size:xy_f):
        if font_name() != "":
            return clamp(float(gl_text_size(text())), xy_0, size)
        else: if size.x > size.y:
            return xy { size.y, size.y }
        else:
            return xy { size.x, size.x }

    def with_mode(c:color, size:xy_f, body):
        // TODO work with scene to group by mode
        gl_set_shader(glyph_shaders[mode])
        if font_name() != "":
            gl_set_font_name(font_name())
            gl_set_font_size(int(size.y))
        else:
            gl_set_primitive_texture(0, entity_texture(code))
        if c != color_clear:
            gl_color(c): body()
        else:
            body()

    def with_transform(size:xy_f, body):
        // TODO work with scene to pre-compute these
        let box = bounds(size)
        if stretch:
            gl_scale(xyz_f {
                if box.x < size.x: size.x / box.x else: 1,
                if box.y < size.y: size.y / box.y else: 1,
                1,
            }):
                body()
        else:
            gl_translate((size - box) / 2):
                body()

def ascii(code:int):    return glyph { 0, code, false }
def sqascii(code:int):  return glyph { 1, code, true  }
def unicode(code:int):  return glyph { 2, code, false }
def uniblock(code:int): return glyph { 2, code, true  }
def emoji(code:int):    return glyph { 3, code, false }
def sprite(code:int):   return glyph { 4, code, true  }
