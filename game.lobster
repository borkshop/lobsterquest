import color
import imgui
import std
import vec

/* TODO

- discrete movement; maybe animated
- energy based action system
- intent based movement system
  - using body information to bound what's possible
- collision system works by joint conflict resolution
  - damages resolved out of collisions
- player control system
- ai control system
  - threat table based on past damage
  - modal goal system, informed by things like health / capability
  - later on, derive relations, reputation, etc from past data
- graph-oriented body system
  - with equipment attachment
- maybe expand to 2-glyphs
- maybe blending with pixel/grid art

*/

// font for imgui
let im_font = "data/fonts/Inconsolata/Inconsolata-Bold.ttf"
let im_fontsize = 32

let color_zero = color { 0, 0, 0, 0 }

let gl_font_names = [
    "data/fonts/US101/US101.TTF",
    "data/fonts/Square/square.ttf",
    "data/fonts/unifont.ttf",
    "data/fonts/Twemoji/TwitterColorEmoji-SVGinOT.ttf",
]

struct glyph:
    font:int
    code:int
    stretch:bool
    // TODO support moar codes for combining characters (e.g. emoji skin tone and gender)

    def draw(size):
        gl_set_font_name(gl_font_names[font]) // TODO worth it to cur-check?
        gl_set_font_size(size.y)              // TODO or just leave that up to font.cpp?
        let txt = unicode_to_string([code])
        let tsz = clamp(gl_text_size(txt), xy_0i, size )
        if stretch:
            gl_scale(xyz_f {
                if tsz.x < size.x: size.x / tsz.x else: 1,
                if tsz.y < size.y: size.y / tsz.y else: 1,
                1,
            }):
                gl_text(txt)
        else:
            gl_translate(float(size - tsz) / 2):
                gl_text(txt)

def ascii(code:int):    return glyph { 0, code, false }
def sqascii(code:int):  return glyph { 1, code, false }
def unicode(code:int):  return glyph { 2, code, false }
def uniblock(code:int): return glyph { 2, code, true  }
def emoji(code:int):    return glyph { 3, code, false }

struct render:
    bg:color
    fg:color
    ch:glyph

    def draw(size):
        if bg != color_zero:
            gl_color(bg): gl_scale(size): gl_unit_square()
        if fg != color_zero and ch.code != 0:
            gl_color(fg): ch.draw(xy_i { size, size })

struct spatial:
    cell:xyz_i  // 2d cell + stacking order
    // TODO shift to xyz_f to support intra-cell positioning

    // TODO support size, maybe shape
    // size:float  // unit scale

    def transform(cell_size, body):
        let loc = float(cell.xy) * cell_size
        gl_translate(xyz { loc.x, loc.y, float(cell.z) }):
            body()

enum_flags entype:
    ent_none = 0
    ent_input = 1
    ent_visible

class ent_ids:
    mask:entype
    ids:[int] = []

    def clear():
        ids.remove(0, ids.length())

    def update(id:int, old:entype, new:entype):
        let diff = old ^ new
        if diff & mask:
            if new & mask:
                ids.push(id)
            else: if old & mask:
                ids.remove_obj(id)

var type = []::entype
var pos = []::spatial
var ren = []::render

// visible entities get drawn
let scene = ent_ids { mask: ent_visible } // TODO some assist for back-to-front drawing

// type based entity observation
let watchers = []
watchers.push(scene)

def scene_bounds():
    // TODO assist this with pre-computation by observing position changes
    var minp = xyz_0i
    var maxp = xyz_0i
    var first = true
    for(scene.ids) id:
        let p = pos[id]
        if first:
            first = false
            minp = maxp = p.cell
        else:
            minp = min(minp, p.cell)
            maxp = max(maxp, p.cell)
    return minp, maxp

def clear_ents():
    type = []
    pos = []
    ren = []
    for(watchers): _.clear()

def create_ent(t, p, r):
    // TODO re-use from freelist
    let id = type.length()
    type.push(t)
    pos.push(p)
    ren.push(r)
    for(watchers): _.update(id, ent_none, t)
    return id

def ent_set_type(id:int, t:entype):
    let old = type[id]
    type[id] = t
    for(watchers): _.update(id, old, t)
    // TODO if t == 0: add to freelist

def create_char(et:entype, loc:xy_i, c:color, g:glyph):
    let t = ent_visible | et
    let r = render { color_zero, c, g }
    let p = spatial { cell: xyz_i { loc.x, loc.y, 1 } }
    return create_ent(t, p, r)

def create_obj(et:entype, loc:xy_i, c:color, g:glyph):
    let t = ent_visible | et
    let r = render { color_zero, c, g }
    let p = spatial { cell: xyz_i { loc.x, loc.y, 1 } }
    return create_ent(t, p, r)

def create_floor(loc:xy_i, b:color, f:color, g:glyph):
    let t = ent_visible
    let r = render { b, f, g }
    let p = spatial { cell: xyz_i { loc.x, loc.y, 0 } }
    return create_ent(t, p, r)

var build_loc = xy_0i

def build_translate(by:xy_i, body):
    let old_loc = build_loc
    build_loc += by
    body()
    build_loc = old_loc

def build_rect(sz, body): for(sz) x: for(sz) y:
    let loc = build_loc + xy_i { x, y }
    body(loc, x, y)

def build_each(locs, body): for(locs) loc, i:
    body(loc + build_loc, i)

def build_at(loc, body): body(loc + build_loc)

def build_grove(sz, body):
    let tree_evergreen = emoji(0x1f322) // 🌲
    let tree_deciduous = emoji(0x1f333) // 🌳
    let tiles = [
        ascii(0), ascii(0), uniblock(0x2591), // ░
        ascii(0), ascii(0), uniblock(0x2592), // ▒
        ascii(0), ascii(0), uniblock(0x2593), // ▓
        ascii(0), ascii(0),
    ]
    let floor_bg_base     = color { 0.05, 0.05, 0.05, 1 }
    let floor_bg_variance = color { 0.05, 0.05, 0,    0 }
    let floor_fg_lift     = color { 0.05, 0,    0,    0 }
    let tree_fg_base      = color { 0.2,  0.25, 0.1,  1 }
    let tree_fg_variance  = color { 0,    0.5,  0,    0 }
    build_rect(sz) loc, x, y:
        let tile = tiles[rnd(length(tiles))]
        let bg = floor_bg_base + floor_bg_variance * rnd_float()
        let fg = if tile.code != 0: bg + floor_fg_lift else: color_zero
        create_floor(loc, bg, fg, tile)
        if x == 0 || y == 0 || x == sz-1 || y == sz-1:
            let tree_fg = tree_fg_base + tree_fg_variance * rnd_float()
            create_obj(ent_none, loc, tree_fg, tree_deciduous)
    build_translate(xy_i { sz/2, sz/2 }):
        body()

def place_elementals():
    let elements = [
        0x1f30d, // 🌍
        0x1f4a7, // 💧
        0x1f525, // 🔥
        // 0x1f32c, // 🌬️
        0x1f32a, // 🌪
    ]
    let colors = [
        color_dark_green,
        color_teal,
        color_orange,
        color_cyan,
    ]
    build_each([
        xy_i { -2, 2 },
        xy_i { 2, 2 },
        xy_i { 2, -2 },
        xy_i { -2, -2 },
    ]) loc, i:
        create_char(ent_none, loc, colors[i], emoji(elements[i]))

def build_twemoji(size):
    build_grove(size):
        place_elementals()
        build_at(xy_0i) loc: create_char(ent_input, loc, color_blue_violet, emoji(0x1f9d9)) // 🧙 mage

do():
    build_twemoji(9)

    fatal(gl_window("Twemoji PoC", 1024, 768))
    for(gl_font_names) name, i:
        check(gl_set_font_name(name), "cannot load gl font " + i)

    im_init(true)
    check(im_add_font(im_font, im_fontsize), "cannot load imgui font")

    var paused = false
    var show_ui = false

    def run_ui(next):
        var show_engine = false
        var show_imgui_demo = false
        var show_editor = false

        var build_size = 13

        def update_ui():
            if show_imgui_demo:
                show_imgui_demo = im_window_demo()
                return

            // TODO would prefer to do these more like the imgui overlay example

            // TODO wish that we could make the menu window closable
            im_window("Menu", im_window_always_autoresize):
                paused = im_checkbox("World Paused", paused)
                show_engine = im_checkbox("Engine Info", show_engine)

                im_separator()
                im_text("Build")
                build_size = im_sliderint("Size", build_size, 3, 100)
                im_button("Grove"):
                    clear_ents()
                    build_twemoji(build_size)

                im_separator()
                im_button("ImGui Demo"):
                    show_imgui_demo = true
                    return

                im_separator()
                im_button("Quit"):
                    return from program

            if show_engine: im_window("engine", im_window_always_autoresize):
                im_show_engine_stats()
                im_separator()
                // TODO prefer to do this as a collapsible header (rather than a checkbox)
                show_editor = im_checkbox("Edit Everything", show_editor)
                if show_editor:
                    im_show_vars()

        forever():
            next(nil)
            update_ui()
        return nil

    let ui = coroutine run_ui()

    while gl_frame():
        gl_clear(color_black)
        gl_color(color_white)

        if gl_button("escape") == 1:
            show_ui = !show_ui
            paused = show_ui

        // TODO zoom & pan more like utilui

        // if not paused: TODO read_input

        let minp, maxp = scene_bounds()
        let space_size = maxp.xy - minp.xy + 1
        let cell_size = min(gl_window_size() / space_size)
        let view_rem = gl_window_size() - space_size * cell_size
        gl_translate(float(-minp.xy) * cell_size + float(view_rem) / 2):
            // TODO do our own viewport culling here; TODO using a spatial index range query?
            // TODO must we draw back-to-front, or does the graphics module abstract that from us?
            for(scene.ids) id:
                pos[id].transform(cell_size):
                    ren[id].draw(cell_size)

        if show_ui: do():
            im_frame():
                ui.resume(nil)
