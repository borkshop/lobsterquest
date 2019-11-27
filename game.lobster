import color
import imgui
import std
import vec

import sprites
import sheets

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

def for_from(xs, i, body):
    while i < xs.length():
        body(xs[i], i)
        i++

/* TODO
- viewport control (zoom and pan)

- action
  - item usage: in hand, in cell, neighbor cell...
  - support resolving "far moves" ( affecting other than adjacent cell )

- minds
  - tracks progress and abilities, e.g. elemental essences, status of mojick
  - quest tracking

- spatial
  - super-cell entities
  - shape control
  - better collision processing, either using a spatial index, or circle collision

- ECS
  - entity freelist and re-use
  - is it useful to leave a hole in a sparse system rather than removing on type exit?

- input
  - alternate key bindings
  - help overlay
  - maybe naturalize the menu overlay ( rather than use imgui )
  - click to move; touchscreen?  on-screen D-pad?
  - inspection system for users?

- interaction
  - what to do on hit?
  - solutions for multiple actors
- log hud?
- imgui
  - closable windows would be nice
  - use imgui more like the overlay demo example
- ai system based on behavior trees
- relations to other entities (threats, assists, respects, etc)

*/

let glyph_atlases = []::tile_atlas

def add_glyph_tile_atlas(atlas:tile_atlas):
    let atlas_id = glyph_atlases.length()
    glyph_atlases.push(atlas)
    return atlas_id

def add_glyph_font_atlas(font_name:string, res:xy_i, stretch:bool):
    return add_glyph_tile_atlas(text_atlas { res, stretch, font_name })

struct glyph:
    mode : int
    code : int

    def tile_texture():
        return glyph_atlases[mode].tile_texture(code)

struct render:
    bg   : color
    fg   : color
    glyf : glyph

    def draw():
        if bg != color_clear:
            gl_set_shader("color")
            gl_color(bg):
                gl_unit_square()
        if glyf.code != 0:
            gl_set_shader("textured")
            gl_set_primitive_texture(0, glyf.tile_texture())
            gl_color(fg):
                gl_unit_square()

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

class system:
    def ent_reset():
        nil

    def ent_changed(shard, id:int, old:entype, new:entype):
        return new

class shard:
    type = []::entype
    pos  = []::spatial
    ren  = []::render
    tex  = []::resource?

    systems = []::system

    def create(t:entype, p:spatial, r:render):
        let id = type.length()
        type.push(t)
        pos.push(p)
        ren.push(r)
        tex.push(nil)
        notify_type(id, ent_none, t)
        return id

    def set_type(id:int, t:entype):
        let old = type[id]
        if old != t:
            type[id] = t
            notify_type(id, old, t)

    def notify_type(id, old, new):
        for(systems):
            let prior = new
            new = _.ent_changed(this, id, old, new)
            if new != prior:
                type[id] = new

    def reset():
        for(systems): _.ent_reset()
        type = []
        pos  = []
        ren  = []

def input_fun() -> action

class mind:
    // TODO partial information sensed in, rather than direct world access
    id    : int
    state : int = 0

    def think(chunk):
        let m = state % 2
        let d = state / 2
        let x = m ^ d
        state = ++state % 4
        return if x & d: move_dir(xy {  0.0,  1.0 }) // down
        else: if  x & m: move_dir(xy {  1.0,  0.0 }) // right
        else: if  d:     move_dir(xy { -1.0,  0.0 }) // left
        else:            move_dir(xy {  0.0, -1.0 }) // up

class minds : system
    ids   = []::int
    types = []::entype
    minds = []::mind

    def enter(id, type):
        ids.push(id)
        types.push(type)
        minds.push(mind { id: id })

    def exit(id): while_first_index(ids, id) mind_id:
        ids.remove(mind_id, 1)
        types.remove(mind_id, 1)
        minds.remove(mind_id, 1)

    def ent_changed(shard, id:int, old:entype, new:entype):
        if (old ^ new) & ent_mind:
            if       new & ent_mind: this.enter(id, new)
            else: if old & ent_mind: this.exit(id)
        return new

    def ent_reset():
        ids   = []
        types = []
        minds = []

    def thoughts(chunk, input:input_fun):
        return map(types) t, mind_id:
            if t & ent_input: input()
            else:             minds[mind_id].think(chunk)

class bodys : system
    ids:[int] = []

    def enter(id):
        ids.push(id)

    def exit(id): while_first_index(ids, id) body_id:
        ids.remove(body_id, 1)

    def ent_changed(shard, id:int, old:entype, new:entype):
        if (old ^ new) & ent_body:
            if       new & ent_body: this.enter(id)
            else: if old & ent_body: this.exit(id)
        return new

    def ent_reset():
        ids = []

class avatar:
    state      = avatar_state_content
    sprite_id  = 0
    helf       = xy { 3, 3 } // ❤️
    stam       = xy { 0, 0 } // 💛
    left_hand  = item_none
    right_hand = item_none
    // TODO worn item
    // TODO back item

    def faces(each):
        var i = 0
        if sprite_id != 0:
            each(sprite(sprite_id), i++)
        if state == avatar_state_content:
            each(avatar_sprite(avatar_state_entity_ids[0]), i++) // 🙂
            return
        for(avatar_state_entity_ids) aeid, j: if j:
            let q_state = avatar_state(1 << (j - 1))
            if state & q_state:
                each(avatar_sprite(aeid), i++)

    def hearts(each):
        let e = ui_sprite(ui_empty_heart)
        let h = ui_sprite(ui_health_heart)
        let s = ui_sprite(ui_stamina_heart)
        var i = 0
        for(         helf.x): each(h, i++, 0)
        for(helf.y - helf.x): each(e, i++, 0)
        i = 0
        for(         stam.x): each(h, i++, 1)
        for(stam.y - stam.x): each(e, i++, 1)

    def draw_tile():
        let face = xy_1 * 2.0 / 3.0
        let icon = xy_1 * 1.0 / 5.0
        let hand = xy_1 * 1.0 / 3.0

        gl_set_shader("textured")
        def unit(glyf):
            gl_set_primitive_texture(0, glyf.tile_texture())
            gl_unit_square()
        faces() moji, i:
            if i == 0:
                // face
                gl_translate(xy_1 / 6): gl_scale(face):
                    unit(moji)
            else:
                // status
                gl_scale(icon):
                    gl_translate(xy_f { 4 - (i - 1) / 3, (i - 1) % 3 }):
                        unit(moji)

        // hearts
        hearts() heart, x, y:
            gl_scale(icon):
                gl_translate(xy_f { y, x }):
                    unit(heart)

        // hands
        gl_scale(hand): gl_translate(xy_f { 0, 2 }):
            unit(if left_hand: item_sprite(left_hand)
                 else:         ui_sprite(ui_left_hand))
        gl_scale(hand): gl_translate(xy_f { 2, 2 }):
            unit(if right_hand: item_sprite(right_hand)
                 else:          ui_sprite(ui_right_hand))

class avatars : system
    ids     = []::int
    avatars = []::avatar

    res = xy_i { 144, 144 }

    def with(shard, id:int, body):
        let n, avatar_id = ids.binary_search(id)
        if not n:
            let av = avatar {}
            ids.insert(avatar_id, id)
            avatars.insert(avatar_id, av)
        else: assert n == 1
        let av = avatars[avatar_id]
        body(av)
        shard.tex[id] = sprite_render(res):
            gl_scale(float(res)):
                av.draw_tile()

    def clear(id:int):
        let n, avatar_id = ids.binary_search(id)
        if n:
            ids.remove(avatar_id, n)
            avatars.remove(avatar_id, n)

    def ent_reset():
        ids     = []
        avatars = []

enum_flags anim_flags:
    anim_base  = 0
    anim_block = 1
    anim_keep
    anim_loop

class anims : system
    blocked = false
    ids     = []::int
    flags   = []::anim_flags
    time    = []::float
    elapsed = []::float
    as      = []::spatial
    bs      = []::spatial
    // TODO size animation
    // TODO animation of other spatial attributes as added, e.g. heading or other transforms

    def update(shard:shard, update_dt:float):
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
        ids     = map(live): ids[_]
        flags   = map(live): flags[_]
        blocked = flags.fold(false): if (_a | _b) & anim_block: true else: false
        time    = map(live): time[_]
        elapsed = map(live): elapsed[_]
        as      = map(live): as[_]
        bs      = map(live): bs[_]

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

    def clear(shard:shard, id):
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

    def clear(shard): anims.clear(shard, id)
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

class chunk : shard
    minds   = minds {}
    bodys   = bodys {}
    avatars = avatars {}
    anims   = anims {}

    movement_time = 1.0 / 6

    def can_step():
        return !anims.blocked

    def update(dt:float):
        anims.update(this, dt)

    def step(input:input_fun):
        // clear all prior action animations
        for(minds.ids): anims.clear(this, _) // TODO batch method

        // choose action intents
        let intents = minds.thoughts(this, input)

        // subset of minds with intent
        let actor_mind_ids = filter_indices(minds.ids) id, mind_id:
            intents[mind_id].act != action_none
        let actor_ids = map(actor_mind_ids): minds.ids[_]
        let actions = filter(intents): _.act != action_none

        // track current actor location
        let actor_locs = map(actor_ids): pos[_]
        def actor_loc(mind_id):
            let n_minds, actor_id = actor_mind_ids.binary_search(mind_id)
            if n_minds > 0:
                return actor_locs[actor_id]
            else:
                let id = minds.ids[mind_id]
                return pos[id]

        // compute action targets
        let targets = map(actions) a, actor_id:
            a.target(actor_locs[actor_id])

        // compute hit bodies, grouping actions by shared interest
        let group_ids = map(targets): -1
        let groups    = vector_reserve(typeof [[int]], targets.length())
        let hits      = vector_reserve(typeof [[int]], targets.length())
        for(targets) t, actor_id:
            if group_ids[actor_id] < 0:
                let group_id = groups.length()
                let actors = [actor_id]
                let at = filter(bodys.ids) id: pos[id].cell() == t
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

        // animate actor movement, updating actor_locs if full
        def move_actor(actor_id, full):
            let id = actor_ids[actor_id]
            let a = pos[id]
            let t = targets[actor_id]
            let d = t - a.cell()
            let b = spatial {
                x: a.x + float(d.x),
                y: a.y + float(d.y),
                z: a.z,
                w: a.w,
            }
            anims.animate(id, movement_time) anim:
                anim.blocking = true
                anim.after(0): anim.pos = a
                if full:
                    anim.after(1): anim.pos = b
                    actor_locs[actor_id] = b
                else:
                    anim.after(1): anim.pos = lerp(a, b, 0.5)
                    anim.after(1): anim.pos = a

        // resolve action groups
        for(groups) actors, group_id:
            let at = hits[group_id]
            if actors.length() > 1:
                for(actors): move_actor(_, false) // half-animate all conflicts
            else: if at.length() > 0:
                move_actor(actors[0], false) // half-animate hits
            else:
                move_actor(actors[0], true) // full animate unfettered move

def new_chunk():
    let ch = chunk {}
    ch.systems.push(ch.minds)
    ch.systems.push(ch.bodys)
    ch.systems.push(ch.avatars)
    return ch

class stacked_scene : system
    ids = []::int
    zs  = []::float
    // TODO maybe bucket-by-z rather than full sorting
    // TODO pre-computed tile

    def enter(shard, id):
        let z = shard.pos[id].z
        let n, scene_id = zs.binary_search(z)
        ids.insert(scene_id, id)
        zs.insert(scene_id, z)

    def exit(id): while_first_index(ids, id) scene_id:
        ids.remove(scene_id, 1)
        zs.remove(scene_id, 1)

    def ent_changed(shard, id:int, old:entype, new:entype):
        if (old ^ new) & ent_visible:
            if       new & ent_visible: this.enter(shard, id)
            else: if old & ent_visible: this.exit(id)
        return new

    def ent_reset():
        ids = []
        zs  = []

    // TODO update_z

    def bounds(shard):
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

    def draw(shard, screen_size, dt):
        shard.update(dt)
        let minc, maxc = bounds(shard)
        let space_size = float(maxc - minc + 1)
        let side_size  = float(max(1, min(floor(screen_size / space_size))))
        let cell_size  = xy_f { side_size, side_size }
        let view_rem   = screen_size - space_size * side_size
        gl_translate(float(-minc.xy) * side_size + view_rem / 2):
            for(ids) id:
                // TODO precomputed translation
                // TODO prerendered tile textures
                let p = shard.pos[id]
                let c = p.xy - p.w / 2
                gl_translate(c * cell_size):
                    let size = cell_size * p.w
                    gl_scale(size):
                        let tex = shard.tex[id]
                        if tex:
                            gl_set_shader("textured")
                            gl_set_primitive_texture(0, tex)
                            gl_color(color_white):
                                gl_unit_square()
                        else:
                            shard.ren[id].draw()

class ent_scaffold:
    type  : entype
    bg    = color_clear
    fg    = color_clear
    glyph = glyph { 0, 0 }
    z     = 0.0
    size  = 1.0

    def with(body):
        let co = copy(this)
        body(co)
        return co

    def create(shard:shard, loc:xy_f):
        loc = loc + xy { 0.5, 0.5 }
        let pos = spatial { loc.x, loc.y, z, size }
        let ren = render { bg, fg, glyph }
        return shard.create(type, pos, ren)

class builder:
    loc = xy_0

    def create(shard, es:ent_scaffold):
        return es.create(shard, loc)

    def create_with(shard, es:ent_scaffold, body):
        return this.create(shard, es.with(body))

    def at(l:xy_f, body):
        let base = loc
        loc = l
        if body:
            body()
            loc = base

    def translate(by:xy_f, body):
        at(loc + by, body)

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

//// specialization

fatal(gl_window("Mojick PoC", 1024, 768))

// TODO ever change sprite resolution?

for([
    "data/fonts/Square/square.ttf",
    "data/fonts/Twemoji/TwitterColorEmoji-SVGinOT.ttf",
    "data/fonts/US101/US101.TTF",
    "data/fonts/unifont.ttf",
]): check(gl_set_font_name(_), "cannot load gl font " + _)

let sheet_sprites = load_sheet_sprites()

let sheet_sprite_mode   = add_glyph_tile_atlas(sheet_sprites)
let ascii_glyph_mode    = add_glyph_font_atlas("data/fonts/US101/US101.TTF",                       sheet_sprites.res, false)
let sqascii_glyph_mode  = add_glyph_font_atlas("data/fonts/Square/square.ttf",                     sheet_sprites.res, true)
let unicode_glyph_mode  = add_glyph_font_atlas("data/fonts/unifont.ttf",                           sheet_sprites.res, false)
let uniblock_glyph_mode = add_glyph_font_atlas("data/fonts/unifont.ttf",                           sheet_sprites.res, true)
let twemoji_glyph_mode  = add_glyph_font_atlas("data/fonts/Twemoji/TwitterColorEmoji-SVGinOT.ttf", sheet_sprites.res, false)

def sprite(id:int):                     return glyph { sheet_sprite_mode, id }
def ui_sprite(id:ui_entity_id):         return sprite(    ui_sprite_id[id])
def tile_sprite(id:tile_entity_id):     return sprite(  tile_sprite_id[id])
def item_sprite(id:item_entity_id):     return sprite(  item_sprite_id[id])
def avatar_sprite(id:avatar_entity_id): return sprite(avatar_sprite_id[id])

def font_string(mode:int, s:string) -> int: return glyph_atlases[mode].symbolicate(s)
def font_rune(  mode:int, code:int) -> int: return font_string(mode, unicode_to_string([code]))

def ascii(code:int):    return glyph { ascii_glyph_mode,    font_rune(ascii_glyph_mode,    code) }
def sqascii(code:int):  return glyph { sqascii_glyph_mode,  font_rune(sqascii_glyph_mode,  code) }
def unicode(code:int):  return glyph { unicode_glyph_mode,  font_rune(unicode_glyph_mode,  code) }
def uniblock(code:int): return glyph { uniblock_glyph_mode, font_rune(uniblock_glyph_mode, code) }
def twemoji(code:int):  return glyph { twemoji_glyph_mode,  font_rune(twemoji_glyph_mode,  code) }

enum scaffold_index:
    floor_scaffold
    object_scaffold
    char_scaffold
    tree_evergreen
    tree_deciduous
    dirt_1
    dirt_2
    dirt_3
    element_earth
    element_water
    element_fire
    element_air
    player

let scaffolds = []::ent_scaffold

// floor_scaffold
scaffolds.push(ent_scaffold {
    type : ent_cell | ent_visible,
    z    : 0.0,
    size : 1.0,
})

// object_scaffold
scaffolds.push(ent_scaffold {
    type : ent_body | ent_visible,
    z    : 0.5,
    size : 1.0,
})

// char_scaffold
scaffolds.push(ent_scaffold {
    type : ent_body | ent_mind | ent_visible,
    z    : 1.0,
    size : 1.0,
})

// tree_evergreen
scaffolds[object_scaffold].with():
    _.glyph = tile_sprite(tile_pine_tree)
    scaffolds.push(_)

// tree_deciduous
scaffolds[object_scaffold].with():
    _.glyph = tile_sprite(tile_apple_tree)
    scaffolds.push(_)

// dirt_1
scaffolds[floor_scaffold].with():
    _.glyph = uniblock(0x2591) // ░
    scaffolds.push(_)

// dirt_2
scaffolds[floor_scaffold].with():
    _.glyph = uniblock(0x2592) // ▒
    scaffolds.push(_)

// dirt_3
scaffolds[floor_scaffold].with():
    _.glyph = uniblock(0x2593) // ▓
    scaffolds.push(_)

// element_earth
scaffolds[char_scaffold].with():
    _.glyph = item_sprite(item_clover)
    _.fg = color_dark_green
    scaffolds.push(_)

// element_water
scaffolds[char_scaffold].with():
    _.glyph = item_sprite(item_water)
    _.fg = color_teal
    scaffolds.push(_)

// element_fire
scaffolds[char_scaffold].with():
    _.glyph = item_sprite(item_fire)
    _.fg = color_orange
    scaffolds.push(_)

// element_air
scaffolds[char_scaffold].with():
    _.glyph = item_sprite(item_wind)
    _.fg = color_cyan
    scaffolds.push(_)

// player
scaffolds[char_scaffold].with():
    _.type = _.type | ent_input
    _.glyph = tile_sprite(tile_cheese_wizard)
    _.fg = color_white
    scaffolds.push(_)

def build_moji_grove(shard, build:builder, size):
    let dirt = [
        floor_scaffold, floor_scaffold, dirt_1,
        floor_scaffold, floor_scaffold, dirt_2,
        floor_scaffold, floor_scaffold, dirt_3,
        floor_scaffold, floor_scaffold,
    ]

    let trees = [
        tree_deciduous,
        tree_evergreen,
    ]

    let elements = [
        element_earth,
        element_water,
        element_fire,
        element_air,
    ]

    let floor_bg_base     = color { 0.05, 0.05, 0.05, 1 }
    let floor_bg_variance = color { 0.05, 0.05, 0,    0 }
    let floor_fg_lift     = color { 0.05, 0,    0,    0 }

    let tree_fg_base      = color { 0.2,  0.25, 0.1,  1 }
    let tree_fg_variance  = color { 0,    0.5,  0,    0 }

    build.fill_rect(size) x, y:
        build.create_with(shard, scaffolds[dirt.rnd_pick()]) tile:
            tile.bg = floor_bg_base + floor_bg_variance * rnd_float()
            if tile.glyph.code != 0: tile.fg = tile.bg + floor_fg_lift
        if x == 0 || y == 0 || x == size-1 || y == size-1:
            build.create_with(shard, scaffolds[trees.rnd_pick()]) tree:
                tree.fg = tree_fg_base + tree_fg_variance * rnd_float()
    let mid = float(floor(size / 2))
    build.translate(xy_f { mid, mid }):
        let l = size / 4
        build.each([
            xy_f { -l,  l },
            xy_f {  l,  l },
            xy_f {  l, -l },
            xy_f { -l, -l },
        ]): build.create(shard, scaffolds[elements[_]])
        let player_id = build.create(shard, scaffolds[player])
        shard.avatars.with(shard, player_id) avatar:
            avatar.state = avatar_state_rocket | avatar_state_cold | avatar_state_hot | avatar_state_dizzy
            avatar.helf = xy { 2, 3 }
            avatar.stam = xy { 1, 2 }
            avatar.left_hand = item_apple // 🍎
            // avatar.right_hand = item_knife // 🔪

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

class ui:
    paused      = false
    show_menu   = false
    show_engine = false
    show_editor = false
    build_size  = 13

    def run_forever(draw, step, edit):
        var done = false
        forever():
            if done: return

            if not gl_frame(): return from program

            im_frame():
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

                    im_separator()
                    show_engine = im_checkbox("Engine Info", show_engine)
                    if show_engine: im_show_engine_stats()

                    im_separator()
                    show_editor = im_checkbox("Edit Everything", show_editor)
                    if show_editor: edit()

                    im_separator()
                    im_button("Reboot"): done = true

                    im_separator()
                    im_button("Halt"): return from program

def run_a_world():
    // TODO one for each face / level / etc
    var world = new_chunk()

    // TODO one for each visible chunk
    // TODO support dynamic attach/detach
    var scene = stacked_scene {}
    world.systems.push(scene)

    let build = builder {}
    build_moji_grove(world, build, 12)

    let ui = ui {}
    ui.run_forever():
        gl_clear(color_black)
        scene.draw(world, float(gl_window_size()), gl_delta_time())
        // TODO draw player overlay
    step:
        if world.can_step() and play_reader.read_input():
            world.step(): play_reader.action()
    edit:
        im_edit_anything(world, "World")
        im_edit_anything(scene, "Scene")
        im_edit_anything(build, "Build")
        im_edit_anything(ui, "UI")

do():
    // setup imgui for menu and debug overlay
    let im_font = "data/fonts/Inconsolata/Inconsolata-Bold.ttf"
    let im_fontsize = 32
    im_init(true)
    check(im_add_font(im_font, im_fontsize), "cannot load imgui font")

    forever():
        run_a_world()
