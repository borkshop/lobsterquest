import color
import imgui
import std
import vec

def first_index(xs, x):
    for(xs) _, i: if _ == x:
        return i
    return -1

def while_first_index(xs, x, body):
    forever():
        let i = xs.first_index(x)
        if i < 0:
            return
        body(i)

/* TODO

- rendering
  - optimize glyph draw: group by mode; cache strings, meshes, or use textures
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
- ECS
  - entity freelist and re-use
  - is it useful to leave a hole in a sparse system rather than removing on type exit?
- ai system based on behavior trees
- relations to other entities (threats, assists, respects, etc)
- graph-oriented body system item holding and with equipment

*/

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

let spatial_0 = spatial { 0, 0, 0, 0 }

enum_flags actiontype:
    action_none = 0
    action_move = 1

struct action:
    act:actiontype
    dir:xy_f

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

class shard:
    type = []::entype
    pos  = []::spatial
    ren  = []::render
    enrg = []::float

class system:
    def ent_reset():
        nil

    def ent_changed(id:int, old:entype, new:entype):
        return new

class shard_system:
    data    = shard{}
    systems = []::system

    def create(t, p, r, e):
        let id = data.type.length()
        data.type.push(t)
        data.pos.push(p)
        data.ren.push(r)
        data.enrg.push(e)
        notify_type(id, ent_none, t)
        return id

    def set_type(id:int, t:entype):
        let old = data.type[id]
        data.type[id] = t
        notify_type(id, old, t)

    def notify_type(id, old, new):
        for(systems):
            let prior = new
            new = _.ent_changed(id, old, new)
            if new != prior:
                data.type[id] = new

    def reset():
        for(systems): _.ent_reset()
        data.type = []
        data.pos  = []
        data.ren  = []
        data.enrg = []

def input_fun() -> action

class mind:
    // TODO partial information sensed in, rather than direct world access
    shard:shard
    id:int
    state:int = 0

    def think():
        let m = state % 2
        let d = state / 2
        let x = m ^ d
        state = ++state % 4
        return if x & d: move_dir(xy {  0.0,  1.0 }) // down
        else: if  x & m: move_dir(xy {  1.0,  0.0 }) // right
        else: if  d:     move_dir(xy { -1.0,  0.0 }) // left
        else:            move_dir(xy {  0.0, -1.0 }) // up

class minds : system
    shard:shard
    input:input_fun

    ids   = []::int
    types = []::entype
    minds = []::mind

    def enter(id, t):
        ids.push(id)
        types.push(t)
        minds.push(mind { shard: shard, id: id })

    def exit(id): while_first_index(ids, id) mind_id:
        ids.remove(mind_id, 1)
        types.remove(mind_id, 1)
        minds.remove(mind_id, 1)

    def ent_changed(id:int, old:entype, new:entype):
        if (old ^ new) & ent_mind:
            if       new & ent_mind: this.enter(id, new)
            else: if old & ent_mind: this.exit(id)
        return new

    def ent_reset():
        ids   = []
        types = []
        minds = []

    def thoughts():
        let input_fun = input
        return map(types) t, mind_id:
            if t & ent_input: input_fun()
            else:             minds[mind_id].think()

class bodys : system
    ids:[int] = []

    def enter(id):
        ids.push(id)

    def exit(id): while_first_index(ids, id) body_id:
        ids.remove(body_id, 1)

    def ent_changed(id:int, old:entype, new:entype):
        if (old ^ new) & ent_body:
            if       new & ent_body: this.enter(id)
            else: if old & ent_body: this.exit(id)
        return new

    def ent_reset():
        ids = []

enum_flags anim_flags:
    anim_base  = 0
    anim_block = 1
    anim_keep
    anim_loop

class anims : system
    shard:shard

    blocked = false
    ids     = []::int
    flags   = []::anim_flags
    time    = []::float
    elapsed = []::float
    as      = []::spatial
    bs      = []::spatial
    // TODO size animation
    // TODO animation of other spatial attributes as added, e.g. heading or other transforms

    def update(update_dt:float):
        let left = map(shard.type.length()): update_dt

        let resets = []::int

        // TODO maybe decompose loop into stages
        for(ids) id, anim_id:
            def advance(dt):
                if dt <= 0:
                    return 0.0

                let prior = elapsed[anim_id]
                let total = time[anim_id]
                if prior >= total:
                    return dt

                let t = clamp(prior + dt, 0, total)
                let spent = t - prior

                let f = t / total
                let a = as[anim_id]
                let b = bs[anim_id]
                shard.pos[id] = lerp(a, b, f)

                if t >= total and flags[anim_id] & anim_loop:
                    resets.push(id)

                elapsed[anim_id] = t
                return dt - spent
            left[id] = advance(left[id])

        // prune all expired animations (that aren't flagged to keep)
        let live, dead = elapsed.partition_indices() t, anim_id:
            t < time[anim_id] || flags[anim_id] & anim_keep

        // reset all looped animations
        if resets.length:
            for(ids) id, anim_id:
                if resets.first_index(id) >= 0:
                    elapsed[anim_id] = 0

        drop(live, dead)

    def drop(live, dead): if dead.length:
        let dead_ids = map(dead): ids[_]
        ids          = map(live): ids[_]
        flags        = map(live): flags[_]
        blocked      = flags.fold(false): if (_a | _b) & anim_block: true else: false
        time         = map(live): time[_]
        elapsed      = map(live): elapsed[_]
        as           = map(live): as[_]
        bs           = map(live): bs[_]

    def has_any(id):
        let anim_id = ids.first_index(id)
        return anim_id >= 0

    def ent_reset():
        ids     = []
        flags   = []
        time    = []
        elapsed = []
        as      = []
        bs      = []

    def clear(id):
        let prior, rest = ids.partition_indices(): _ == id
        if prior.length:
            let anim_id = prior[prior.length - 1]
            shard.pos[id] = bs[anim_id]
        drop(rest, prior)

    def add(
        id : int,
        f  : anim_flags,
        t  : float,
        a  : spatial,
        b  : spatial
    ): if a == b: return -1 else:
        let anim_id = ids.length()
        ids.push(id)
        flags.push(f)
        time.push(t)
        elapsed.push(0)
        as.push(a)
        bs.push(b)
        blocked = blocked || f & anim_block
        return anim_id

class anim_scaffold:
    anims : anims
    id    : int
    time  : float

    looped   = false
    blocking = false
    pos      = spatial_0
    last_t   = 0.0

    q_pos   = []::spatial
    q_flags = []::anim_flags
    q_time  = []::float

    def clear():   anims.clear(id)
    def has_any(): return anims.has_any(id)

    def with(body):
        if last_t > 0:
            last_t  = 0.0
            q_pos   = []
            q_flags = []
            q_time  = []
        body(this)
        if last_t > 0:
            var a = spatial_0
            for(q_pos) b, i:
                if i > 0:
                    var f = q_flags[i]
                    if looped:
                        f = f | anim_keep
                        if i == q_pos.length - 1:
                            f = f | anim_loop
                    let t = q_time[i] / last_t * time
                    anims.add(id, f, t, a, b)
                a = b

    def after(t:float, body):
        let prior_t = last_t
        if q_pos.length > 0:
            last_t += t
        body(this)
        q_pos.push(pos)
        q_flags.push(if blocking: anim_block else: anim_base)
        q_time.push(last_t - prior_t)

def animate(anims::anims, id:int, over:float, body):
    anim_scaffold {
        anims: anims,
        id:    id,
        time:  over,
    }.with(body)

class stacked_scene : system
    shard:shard

    ids = []::int
    zs  = []::float
    // TODO maybe bucket-by-z rather than full sorting
    // TODO maybe own and pre-compute all rendering data

    def enter(id):
        let z = shard.pos[id].z
        let n, scene_id = zs.binary_search(z)
        ids.insert(scene_id, id)
        zs.insert(scene_id, z)

    def exit(id): while_first_index(ids, id) scene_id:
        ids.remove(scene_id, 1)
        zs.remove(scene_id, 1)

    def ent_changed(id:int, old:entype, new:entype):
        if (old ^ new) & ent_visible:
            if       new & ent_visible: this.enter(id)
            else: if old & ent_visible: this.exit(id)
        return new

    def ent_reset():
        ids = []
        zs  = []

    // TODO update_z

    def bounds():
        var minc = xy_0i
        var maxc = xy_0i
        var first = true
        for(ids) id:
            let c = shard.pos[id].cell()
            if first:
                first = false
                minc = maxc = c
            else:
                minc = min(minc, c)
                maxc = max(maxc, c)
        return minc, maxc

class builder:
    shard:shard_system
    loc = xy_0

    def translate(by:xy_f, body):
        let base = loc
        loc += by
        if body:
            body()
            loc = base

    def each(offsets, body):
        let base = loc
        for(offsets) offset, i:
            loc = base + offset
            body(i)
        loc = base

    def fill_rect(n, body):
        let base = loc
        for(n) x: for(n) y:
            loc = base + xy_f { x, y }
            body(x, y)
        loc = base

    // TODO decompose into builder state? or factor out into "struct spec" data?

    def create_char(et:entype, c:color, g:glyph):
        let t = ent_body | ent_mind | ent_visible | et
        let r = render { color_zero, c, g }
        let p = spatial { loc.x + 0.5, loc.y + 0.5, 1.0, 1.0 }
        return shard.create(t, p, r, 0)

    def create_object(et:entype, c:color, g:glyph):
        let t = ent_body | ent_visible | et
        let r = render { color_zero, c, g }
        let p = spatial { loc.x + 0.5, loc.y + 0.5, 0.5, 1.0 }
        return shard.create(t, p, r, 0)

    def create_floor(b:color, f:color, g:glyph):
        let t = ent_visible | ent_cell
        let r = render { b, f, g }
        let p = spatial { loc.x + 0.5, loc.y + 0.5, 0.0, 1.0 }
        return shard.create(t, p, r, 0)

//// specialization

class twemoji_builder:
    build:builder

    tree_evergreen = emoji(0x1f322) // 🌲
    tree_deciduous = emoji(0x1f333) // 🌳
    dirt = [
        ascii(0), ascii(0), uniblock(0x2591), // ░
        ascii(0), ascii(0), uniblock(0x2592), // ▒
        ascii(0), ascii(0), uniblock(0x2593), // ▓
        ascii(0), ascii(0),
    ]

    elements = [
        0x1f30d, // 🌍
        0x1f4a7, // 💧
        0x1f525, // 🔥
        // 0x1f32c, // 🌬️
        0x1f32a, // 🌪
    ]

    element_colors = [
        color_dark_green,
        color_teal,
        color_orange,
        color_cyan,
    ]

    floor_bg_base     = color { 0.05, 0.05, 0.05, 1 }
    floor_bg_variance = color { 0.05, 0.05, 0,    0 }
    floor_fg_lift     = color { 0.05, 0,    0,    0 }

    tree_fg_base      = color { 0.2,  0.25, 0.1,  1 }
    tree_fg_variance  = color { 0,    0.5,  0,    0 }

    def grove(sz, body):
        build.fill_rect(sz) x, y:
            let tile = dirt[rnd(length(dirt))]
            let bg = floor_bg_base + floor_bg_variance * rnd_float()
            let fg = if tile.code != 0: bg + floor_fg_lift else: color_zero
            build.create_floor(bg, fg, tile)
            if x == 0 || y == 0 || x == sz-1 || y == sz-1:
                let tree_fg = tree_fg_base + tree_fg_variance * rnd_float()
                build.create_object(ent_none, tree_fg, tree_deciduous)
        if body:
            let mid = float(floor(sz / 2))
            build.translate(xy_f { mid, mid }):
                body()

    def scene(size):
        grove(size):
            let l = size / 4
            build.each([
                xy_f { -l,  l },
                xy_f {  l,  l },
                xy_f {  l, -l },
                xy_f { -l, -l },
            ]) i:
                build.create_char(ent_none, element_colors[i], emoji(elements[i]))
            build.create_char(ent_input, color_blue_violet, emoji(0x1f9d9)) // 🧙 mage

class button_action_reader:
    buttons:[string] = []
    actions:[action] = []

    have = false
    input = action_0

    def action():
        return if have: input else: action_0

    def read_input():
        have = false
        for(buttons) button, i:
            if gl_button(button) > 0:
                have = true
                input = actions[i]
        return have

//// usage

let movement_time = 1.0 / 6

let play_reader = button_action_reader {
    // arrow keys with "." to stay idiom
    buttons: [
        "up",
        "down",
        "left",
        "right",
        ".",
    ],
    actions: [
        move_dir(xy {  0.0, -1.0 }),
        move_dir(xy {  0.0,  1.0 }),
        move_dir(xy { -1.0,  0.0 }),
        move_dir(xy {  1.0,  0.0 }),
        move_dir(xy_0),
    ],
}

// TODO one for each face / level / etc
var world = shard_system {}
var minds = minds {
    shard: world.data,
    input: def(): play_reader.action(),
}
var bodys = bodys {}
var anims = anims { shard: world.data }
world.systems.push(minds)
world.systems.push(bodys)

// TODO for each visible shard
var scene = stacked_scene { shard: world.data }
world.systems.push(scene)

// TODO make ephemeral ... or attach it to an area
let build = builder {
    shard: world,
}
let moji_build = twemoji_builder {
    build: build,
}

// TODO attach to world area
def step_world(input:action):
    // clear all prior action animations
    for(minds.ids): anims.clear(_) // TODO batch method

    // energize all minds
    for(minds.ids) id: world.data.enrg[id]++

    // choose action intents
    let intents = minds.thoughts()

    // subset of minds with intent
    let actor_ids = filter(minds.ids) id, mind_id:
        intents[mind_id].act != action_none
    let actions = filter(intents): _.act != action_none

    // enforce action energy limits
    for(actions) a, actor_id:
        let id = actor_ids[actor_id]
        actions[actor_id] = a.limit(world.data.enrg[id])

    // compute action targets
    let targets = map(actions) a, actor_id:
        let id = actor_ids[actor_id]
        a.target(world.data.pos[id])

    // compute hit bodies, grouping actions by shared interest
    let group_ids = map(targets): -1
    let groups    = vector_reserve(typeof [[int]], targets.length())
    let hits      = vector_reserve(typeof [[int]], targets.length())
    for(targets) t, actor_id:
        if group_ids[actor_id] < 0:
            let group_id = groups.length()
            let actors = [actor_id]
            let at = filter(bodys.ids) id: world.data.pos[id].cell() == t
            for_from(targets, actor_id + 1) ot, other_actor_id:
                if targets[other_actor_id] == t:
                    if group_ids[other_actor_id] < 0:
                        group_ids[other_actor_id] = group_id
                        actors.push(other_actor_id)
                    // NOTE should not be possible unless we introduce
                    // second-order consequences (e.g. pushing):
                    // else: if other_actor_id != group_id:
            hits.push(at)
            groups.push(actors)
            group_ids[actor_id] = group_id

    def move_actor(actor_id, full):
        let id = actor_ids[actor_id]
        let a = world.data.pos[id]
        let t = targets[actor_id]
        let d = t - a.cell()
        let b = spatial {
            x: a.x + float(d.x),
            y: a.y + float(d.y),
            z: a.z,
            w: a.w,
        }
        var cost = abs(d.x) + abs(d.y)
        anims.animate(id, movement_time) anim:
            anim.blocking = true
            anim.after(0): anim.pos = a
            if full:
                anim.after(1): anim.pos = b
            else:
                anim.after(1): anim.pos = lerp(a, b, 0.5)
                anim.after(1): anim.pos = a
                cost = cost / 2
        if cost > 0:
            world.data.enrg[id] -= cost

    // resolve action groups
    for(groups) actors, group_id:
        let at = hits[group_id]
        if actors.length() > 1:
            for(actors): move_actor(_, false) // half-animate all conflicts
        else: if at.length() > 0:
            move_actor(actors[0], false) // half-animate hits
        else:
            move_actor(actors[0], true) // full animate unfettered move

class ui:
    paused      = false
    show_menu   = false
    show_engine = false
    show_editor = false
    build_size  = 13

    def run_forever(draw, step):
        while gl_frame(): im_frame():
            if gl_button("escape") == 1:
                show_menu = !show_menu
                paused = show_menu
            if not paused:
                step()
            draw()

            if show_menu: im_window("Menu", im_window_always_autoresize):
                im_button("Hide Menu"):
                    show_menu = false
                    paused = false

                show_engine = im_checkbox("Engine Info", show_engine)
                show_editor = im_checkbox("Edit Everything", show_editor)

                im_separator()
                im_text("Build")
                build_size = im_sliderint("Size", build_size, 3, 100)
                im_button("Grove"):
                    world.reset()
                    moji_build.scene(build_size)

                im_separator()
                im_button("Quit"):
                    return

            if show_engine: im_window("engine", im_window_always_autoresize):
                im_show_engine_stats()

            if show_editor: im_window("editor", im_window_always_autoresize):
                im_show_vars()

do():
    moji_build.scene(12)

    fatal(gl_window("Twemoji PoC", 1024, 768))
    for(gl_font_names) name, i:
        check(gl_set_font_name(name), "cannot load gl font " + i)

    // setup imgui for menu and debug overlay
    let im_font = "data/fonts/Inconsolata/Inconsolata-Bold.ttf"
    let im_fontsize = 32
    im_init(true)
    check(im_add_font(im_font, im_fontsize), "cannot load imgui font")

    let ui = ui {}
    ui.run_forever():
        gl_clear(color_black)
        anims.update(gl_delta_time())
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
                let p = world.data.pos[id]
                let c = p.xy - p.w / 2
                gl_translate(c * cell_size):
                    world.data.ren[id].draw(cell_size, cell_size * p.w)
        // TODO draw player overlay
    step:
        if not anims.blocked and play_reader.read_input():
            step_world(play_reader.input)

def for_from(xs, i, body):
    while i < xs.length():
        body(xs[i], i)
        i++
