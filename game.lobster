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
  - shift to floating point to support sub-cell positioning...
  - ...likely useful for animating movement
  - ...and super-cell constructs
  - support sub-cell size; maybe super-cell
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

    def draw(size, c:color):
        // TODO support textured sprites
        let txt = unicode_to_string([code])
        gl_set_font_name(gl_font_names[font])
        gl_set_font_size(size.y)
        let bounds = clamp(gl_text_size(txt), xy_0i, size )
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

    def with_transform(size, bounds, body):
        if stretch:
            gl_scale(xyz_f {
                if bounds.x < size.x: size.x / bounds.x else: 1,
                if bounds.y < size.y: size.y / bounds.y else: 1,
                1,
            }):
                body()
        else:
            gl_translate(float(size - bounds) / 2):
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

    def draw(size):
        if bg != color_zero:
            gl_color(bg): gl_scale(size): gl_unit_square()
        if ch.code != 0:
            ch.draw(xy_i { size, size }, fg)

struct spatial:
    cell:xyz_i  // 2d cell + stacking order

    def transform(cell_size, body):
        let loc = float(cell.xy) * cell_size
        gl_translate(xyz { loc.x, loc.y, float(cell.z) }):
            body()

    def move_to(p:xyz_i):
        return spatial { cell: p }

enum_flags actiontype:
    action_none = 0
    action_move = 1

struct action:
    act:actiontype
    dir:xy_i

    def isactive():
        return act != action_none

    def limit(n:int):
        return action {
            act: act,
            dir: limit_dir(n),
        }

    def limit_dir(n:int):
        let s = sign(dir)
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
        return s * xy_i { x, y }, 0

    def target(cur:xyz_i):
        var p = cur.xy
        if act & action_move:
            p += dir
        return xyz_i { p.x, p.y, cur.z }

let action_0 = action { action_none, xy_0i }

def move_dir(d:xy_i): return action { action_move, d }

enum_flags entype:
    ent_none = 0  // free entity slot (if no other bits)
    ent_input = 1 // receives player input
    ent_visible   // scene draw-ables
    ent_cell      // defines "A space"; e.g. floor entities have this
    ent_body      // has a collide-able body
    ent_mind      // participates in the action system

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
var enrg = []::int

class scene_ids:
    mask:entype
    ids:[int] = []
    zs:[int] = []

    def clear():
        ids.remove(0, ids.length())
        zs.remove(0, zs.length())

    // TODO update_z

    def update(id:int, old:entype, new:entype):
        if new & ent_visible:
            let z = pos[id].cell.z
            let n, i = binary_search(zs, z)
            ids.insert(i, id)
            zs.insert(i, z)
        else: if old & ent_visible:
            let i = ids.first_index(id)
            if i >= 0:
                ids.remove(i, 1)
                zs.remove(i, 1)

// visible entities get drawn
let scene = scene_ids { mask: ent_visible }

// minds make moves
let minds = ent_typed_ids { mask: ent_mind }

// solid bodies for collision
let bodys = ent_ids { mask: ent_body }

def scene_bounds():
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

def create_char(et:entype, loc:xy_i, c:color, g:glyph):
    let t = ent_body | ent_mind | ent_visible | et
    let r = render { color_zero, c, g }
    let p = spatial { cell: xyz_i { loc.x, loc.y, 1 } }
    return create_ent(t, p, r, 0)

def create_obj(et:entype, loc:xy_i, c:color, g:glyph):
    let t = ent_body | ent_visible | et
    let r = render { color_zero, c, g }
    let p = spatial { cell: xyz_i { loc.x, loc.y, 1 } }
    return create_ent(t, p, r, 0)

def create_floor(loc:xy_i, b:color, f:color, g:glyph):
    let t = ent_visible | ent_cell
    let r = render { b, f, g }
    let p = spatial { cell: xyz_i { loc.x, loc.y, 0 } }
    return create_ent(t, p, r, 0)

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

// arrow keys with "." to stay idiom
let buttons = [
    "up",
    "down",
    "left",
    "right",
    ".",
]

let button_moves = [
    move_dir(xy {  0, -1 }),
    move_dir(xy {  0,  1 }),
    move_dir(xy { -1,  0 }),
    move_dir(xy {  1,  0 }),
    move_dir(xy_0i),
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
        moves[mind_id].target(pos[id].cell)

    // compute hit bodies, grouping moves by shared interest
    let group_ids = map(moves): -1
    let groups = vector_reserve(typeof [[int]], moves.length())
    let hits = vector_reserve(typeof [[int]], moves.length())
    for(targets) t, mind_id:
        if moves[mind_id].isactive() and group_ids[mind_id] < 0:
            let group_id = groups.length()
            let actors = [mind_id]
            let at = filter(bodys.ids) id: pos[id].cell == t
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
                let d = abs(t - p.cell)
                pos[id] = p.move_to(t)
                enrg[id] -= d.x + d.y

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

        let minp, maxp = scene_bounds()
        let space_size = maxp.xy - minp.xy + 1
        let cell_size = min(gl_window_size() / space_size)
        let view_rem = gl_window_size() - space_size * cell_size
        gl_translate(float(-minp.xy) * cell_size + float(view_rem) / 2):
            for(scene.ids) id:
                pos[id].transform(cell_size):
                    ren[id].draw(cell_size)

        if show_ui: do():
            im_frame():
                ui.resume(nil)
