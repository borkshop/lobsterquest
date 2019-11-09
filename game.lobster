import color
import imgui
import std
import vec

/* TODO

- rendering
  - optimize glyph draw: group by mode; cache strings, meshes, or use textures
  - animated movement and other actions
  - viewport control (zoom and pan)
  - more moji coverage, like skin and gender
  - maybe expand to 2-glyphs
  - maybe blending with pixel/grid art
  - maybe tiled sprite sheet
- spatial
  - super-cell entities
  - shape control
  - better collision processing, either using a spatial index, or circle collision
- input
  - alternate key bindings
  - help overlay
  - maybe naturalize the menu overlay ( rather than use imgui )
  - click to move; touchscreen?  on-screen D-pad?
  - inspection system for users?
- movement
  - support resolving "far moves" ( affecting other than adjacent cell )
  - actions other than movement
- interaction
  - what to do on hit?
  - solutions for multiple actors
- log hud?
- imgui
  - closable windows would be nice
  - use imgui more like the overlay demo example
- entities
  - freelist and re-use
- ai system based on behavior trees
- relations to other entities (threats, assists, respects, etc)
- graph-oriented body system item holding and with equipment

*/

def first_index(xs, x):
    for(xs) _, i: if _ == x:
        return i
    return -1

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

    def draw(size:xy_f, c:color):
        // TODO support textured sprites
        let txt = unicode_to_string([code])
        gl_set_font_name(gl_font_names[font])
        gl_set_font_size(int(size.y))
        let bounds = clamp(float(gl_text_size(txt)), xy_0, size)
        with_mode(c):
            with_transform(size, bounds):
                gl_text(txt)

    def with_mode(c:color, body):
        // TODO any necessary shader control needed for sprites
        // TODO work with scene to group by mode
        if c != color_zero:
            gl_color(c): body()
        else:
            body()

    def with_transform(size:xy_f, bounds:xy_f, body):
        // TODO work with scene to pre-compute these
        if stretch:
            gl_scale(xyz_f {
                if bounds.x < size.x: size.x / bounds.x else: 1,
                if bounds.y < size.y: size.y / bounds.y else: 1,
                1,
            }):
                body()
        else:
            gl_translate((size - bounds) / 2):
                body()

def ascii(code:int):    return glyph { 0, code, false }
def sqascii(code:int):  return glyph { 1, code, true  }
def unicode(code:int):  return glyph { 2, code, false }
def uniblock(code:int): return glyph { 2, code, true  }
def emoji(code:int):    return glyph { 3, code, false }

struct render:
    bg:color
    fg:color
    ch:glyph

    def draw(cell_size:xy_f, size:xy_f):
        if bg != color_zero:
            gl_color(bg): gl_scale(cell_size): gl_unit_square()
        if ch.code != 0:
            ch.draw(size, fg)

struct spatial : xyzw_f
    // x, y are location   : integer part is the cell, fraction part is sub-cell offset
    // z is stacking order : drawn back-to-front, lowest z first
    // w is the size       : in terms of a cell-sized unit, so 1.0 is usual, 0.5 is half-cell

    def cell():
        return xy_i { int(x), int(y) }

enum_flags actiontype:
    action_none = 0
    action_move = 1

struct action:
    act:actiontype
    dir:xy_f

    def isactive():
        return act != action_none

    def limit(n:float):
        return action {
            act: act,
            dir: limit_dir(n),
        }

    def limit_dir(n:float):
        let s = float(sign(dir))
        let d = abs(dir)
        let t = d.x + d.y
        if t <= n:
            return dir, n - t
        var o = t - n
        var x, y = d.x, d.y
        while o > 0:
            if x > 0:
                x--
            else: if y > 0:
                y--
            o--
        return s * xy_f { x, y }, 0

    def target(p:spatial):
        var l = p.xy
        if act & action_move:
            l += dir
        return int(l)

let action_0 = action { action_none, xy_0 }

def move_dir(d:xy_f): return action { action_move, d }

enum_flags entype:
    ent_none = 0    // free entity slot (if no other bits)
    ent_visible = 1 // scene draw-ables
    ent_cell        // defines "A space"; e.g. floor entities have this
    ent_body        // has a collide-able body
    ent_mind        // participates in the action system
    ent_input       // receives player input

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

class ent_typed_ids : ent_ids
    types:[entype] = []

    def clear():
        ids.remove(0, ids.length())
        types.remove(0, types.length())

    def update(id:int, old:entype, new:entype):
        let diff = old ^ new
        if diff & mask:
            if new & mask:
                ids.push(id)
                types.push(new)
            else: if old & mask:
                let i = ids.first_index(id)
                if i >= 0:
                    ids.remove(i, 1)
                    types.remove(i, 1)

var type = []::entype
var pos = []::spatial
var ren = []::render
var enrg = []::float

class scene_ids:
    mask:entype
    ids:[int] = []
    zs:[float] = []

    def clear():
        ids.remove(0, ids.length())
        zs.remove(0, zs.length())

    // TODO update_z

    def update(id:int, old:entype, new:entype):
        if new & ent_visible:
            let z = pos[id].z
            let n, i = binary_search(zs, z)
            ids.insert(i, id)
            zs.insert(i, z)
        else: if old & ent_visible:
            let i = ids.first_index(id)
            if i >= 0:
                ids.remove(i, 1)
                zs.remove(i, 1)

    def bounds():
        var minc = xy_0i
        var maxc = xy_0i
        var first = true
        for(ids) id:
            let c = pos[id].cell()
            if first:
                first = false
                minc = maxc = c
            else:
                minc = min(minc, c)
                maxc = max(maxc, c)
        return minc, maxc

// ent_visible gets drawn in back-to-front (by spatial Z) order
var scene = scene_ids { mask: ent_visible }

// ent_mind participates in the action system
var minds = ent_typed_ids { mask: ent_mind }

// ent_body is "solid" and participates in collision
var bodys = ent_ids { mask: ent_body }

def clear_ents():
    type = []
    pos = []
    ren = []
    enrg = []
    scene.clear()
    minds.clear()
    bodys.clear()

def watch_ent(id:int, old:entype, new:entype):
    scene.update(id, old, new)
    minds.update(id, old, new)
    bodys.update(id, old, new)

def create_ent(t, p, r, e):
    let id = type.length()
    type.push(t)
    pos.push(p)
    ren.push(r)
    enrg.push(e)
    watch_ent(id, ent_none, t)
    return id

def ent_set_type(id:int, t:entype):
    let old = type[id]
    type[id] = t
    watch_ent(id, old, t)

def create_char(et:entype, loc:xy_f, c:color, g:glyph):
    let t = ent_body | ent_mind | ent_visible | et
    let r = render { color_zero, c, g }
    let p = spatial { loc.x + 0.5, loc.y + 0.5, 1.0, 1.0 }
    return create_ent(t, p, r, 0)

def create_obj(et:entype, loc:xy_f, c:color, g:glyph):
    let t = ent_body | ent_visible | et
    let r = render { color_zero, c, g }
    let p = spatial { loc.x + 0.5, loc.y + 0.5, 0.5, 1.0 }
    return create_ent(t, p, r, 0)

def create_floor(loc:xy_f, b:color, f:color, g:glyph):
    let t = ent_visible | ent_cell
    let r = render { b, f, g }
    let p = spatial { loc.x + 0.5, loc.y + 0.5, 0.0, 1.0 }
    return create_ent(t, p, r, 0)

var build_loc = xy_0

def build_translate(by:xy_f, body):
    let old_loc = build_loc
    build_loc += by
    body()
    build_loc = old_loc

def build_rect(sz, body): for(sz) x: for(sz) y:
    let loc = build_loc + xy_f { x, y }
    body(loc, x, y)

def build_each(locs, body): for(locs) loc, i:
    body(loc + build_loc, i)

def build_at(loc:xy_f, body): body(loc + build_loc)

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
    let mid = float(floor(sz / 2))
    build_translate(xy_f { mid, mid }):
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
        xy_f { -2.0,  2.0 },
        xy_f {  2.0,  2.0 },
        xy_f {  2.0, -2.0 },
        xy_f { -2.0, -2.0 },
    ]) loc, i:
        create_char(ent_none, loc, colors[i], emoji(elements[i]))

def build_twemoji(size):
    build_grove(size):
        place_elementals()
        build_at(xy_0) loc:
            create_char(ent_input, loc, color_blue_violet, emoji(0x1f9d9)) // 🧙 mage

// arrow keys with "." to stay idiom
let buttons = [
    "up",
    "down",
    "left",
    "right",
    ".",
]

let button_moves = [
    move_dir(xy {  0.0, -1.0 }),
    move_dir(xy {  0.0,  1.0 }),
    move_dir(xy { -1.0,  0.0 }),
    move_dir(xy {  1.0,  0.0 }),
    move_dir(xy_0),
]

var last_input = 0.0

def read_input():
    let since_input = gl_time() - last_input
    let until_next_input = 1.0 / 6
    var input, have = action_0, false
    for(buttons) button, i:
        var state = gl_button(button)
        if state > 1 and since_input < until_next_input:
            state = 0
        if state > 0:
            input, have = button_moves[i], true
    if !have:
        return action_0, false
    last_input = gl_time()
    return input, true

def step_world(input:action):
    // energize all minds
    for(minds.ids) id: enrg[id]++

    // choose moves
    let moves = map(minds.ids) id, mind_id:
        let t = minds.types[mind_id]
        if t & ent_input:
            input
        else:
            action_0

    // enforce movement energy limits
    for(minds.ids) id, mind_id:
        moves[mind_id] = moves[mind_id].limit(enrg[id])

    // compute movement targets
    let targets = map(minds.ids) id, mind_id:
        moves[mind_id].target(pos[id])

    // compute hit bodies, grouping moves by shared interest
    let group_ids = map(moves): -1
    let groups = vector_reserve(typeof [[int]], moves.length())
    let hits = vector_reserve(typeof [[int]], moves.length())
    for(targets) t, mind_id:
        if moves[mind_id].isactive() and group_ids[mind_id] < 0:
            let group_id = groups.length()
            let actors = [mind_id]
            let at = filter(bodys.ids) id: pos[id].cell() == t
            var other_mind_id = mind_id + 1
            while other_mind_id < targets.length():
                if moves[mind_id].isactive() and group_ids[other_mind_id] < 0:
                    if targets[other_mind_id] == t:
                        group_ids[other_mind_id] = group_id
                        actors.push(other_mind_id)
                    other_mind_id++
            hits.push(at)
            groups.push(actors)
            group_ids[mind_id] = group_id

    // resolve movement groups
    for(groups) actors, group_id:
        let at = hits[group_id]

        // no conflict
        if actors.length() == 1:
            let mind_id = actors[0]
            let id = minds.ids[mind_id]

            // nothing hit
            if at.length() == 0:
                let p = pos[id]
                let t = targets[mind_id]
                let d = t - p.cell()
                pos[id] = spatial {
                    x: p.x + float(d.x),
                    y: p.y + float(d.y),
                    z: p.z,
                    w: p.w,
                }
                enrg[id] -= abs(d.x) + abs(d.y)

do():
    build_twemoji(9)

    fatal(gl_window("Twemoji PoC", 1024, 768))
    for(gl_font_names) name, i:
        check(gl_set_font_name(name), "cannot load gl font " + i)

    // setup imgui for menu and debug overlay
    let im_font = "data/fonts/Inconsolata/Inconsolata-Bold.ttf"
    let im_fontsize = 32
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

        if gl_button("escape") == 1:
            show_ui = !show_ui
            paused = show_ui

        if not paused:
            let input, have_move = read_input()
            if have_move:
                step_world(input)

        let minc, maxc = scene.bounds()
        let space_size = float(maxc - minc + 1)
        let win_size   = float(gl_window_size())
        let side_size  = float(max(1, min(floor(win_size / space_size))))
        let cell_size  = xy_f { side_size, side_size }
        let view_rem   = win_size - space_size * side_size
        gl_translate(float(-minc.xy) * side_size + view_rem / 2):
            for(scene.ids) id:
                // TODO scene precomputed translation
                // TODO scene precomputed render and glyph drawing data
                let p = pos[id]
                let c = p.xy - p.w / 2
                gl_translate(c * cell_size):
                    ren[id].draw(cell_size, cell_size * p.w)

        // TODO draw player overlay

        if show_ui: do():
            im_frame():
                ui.resume(nil)
