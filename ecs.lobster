import color
import vec

import sprites
import sheets // TODO invert ecs -> sheets dep

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

//// entity

enum_flags entype:
    ent_none = 0    // free entity slot (if no other bits)
    ent_visible = 1 // scene draw-ables
    ent_cell        // defines "A space"; e.g. floor entities have this
    ent_body        // has a collide-able body
    ent_mind        // participates in the action system
    ent_input       // receives player input
    ent_avatar      // has avatar

def entype_str(t:entype):
    var s = ""
    if t & ent_visible: s += " ent_visible"
    if t & ent_cell:    s += " ent_cell"
    if t & ent_body:    s += " ent_body"
    if t & ent_mind:    s += " ent_mind"
    if t & ent_input:   s += " ent_input"
    if t & ent_avatar:  s += " ent_avatar"
    return s

//// systems

class system:
    def ent_changed(shard, id:int, old:entype, new:entype):
        return new

//// toplevel components

struct spatial : xyzw_f
    // x, y are location   : integer part is the cell, fraction part is sub-cell offset
    // z is stacking order : drawn back-to-front, lowest z first
    // w is the size       : in terms of a cell-sized unit, so 1.0 is usual, 0.5 is half-cell

    def cell():
        return xy_i { int(x), int(y) }

    def cell_rel(off:xyz_f, size:float):
        return spatial { int(x) + off.x, int(y) + off.y, z + off.z, size }

let spatial_0 = spatial { 0, 0, 0, 0 }

let glyph_atlases = []::texture_atlas

def font_string(mode:int, s:string) -> int:
    return glyph_atlases[mode].symbolicate(s)

def font_rune(mode:int, code:int) -> int:
    return glyph_atlases[mode].symbolicate(unicode_to_string([code]))

def add_glyph_tile_atlas(atlas:texture_atlas):
    let atlas_id = glyph_atlases.length()
    glyph_atlases.push(atlas)
    return atlas_id

def add_glyph_font_atlas(font_name:string, res:xy_i, stretch:bool):
    return add_glyph_tile_atlas(text_atlas { res, stretch, font_name })

struct glyph:
    mode : int
    code : int

    def get_texture():
        return glyph_atlases[mode].get_texture(code)

let glyph_0 = glyph { 0, 0 }

struct render:
    bg   : color
    fg   : color
    glyf : glyph

    def draw():
        if bg != color_clear:
            gl_set_shader("color")
            gl_color(bg): gl_unit_square()
        if glyf.code != 0:
            gl_set_shader("textured")
            gl_set_primitive_texture(0, glyf.get_texture())
            gl_color(fg): gl_unit_square()

    def with_fg_color(c:color, g:glyph):
        if c == color_clear: c = color_white
        return render { bg, c, g }
    def with_fg(c:color): return with_fg_color(c, glyf)
    def with_glyph(g:glyph): return with_fg_color(fg, g)

let render_0 = render { color_clear, color_clear, glyph_0 }

//// entity allocation arenas ( shards )

class shard:
    type = []::entype
    pos  = []::spatial
    ren  = []::render
    tex  = []::resource?
    tile = []::tile_entity_id
    item = []::item_entity_id

    systems = []::system

    free_ids = []::int

    def alloc() -> int:
        if free_ids.length:
            let id = free_ids.pop()
            type[id] = ent_none
            pos[id] = spatial_0
            ren[id] = render_0
            tex[id] = nil
            tile[id] = tile_none
            item[id] = item_none
            return id
        else:
            let id = type.length()
            type.push(ent_none)
            pos.push(spatial_0)
            ren.push(render_0)
            tex.push(nil)
            tile.push(tile_none)
            item.push(item_none)
            return id

    def create(t:entype, init, post):
        let id = alloc()
        type[id] = t
        init(id)
        t = notify_type(id, ent_none, t)
        if post: post(id)
        let r = ren[id]
        if r.glyf == glyph_0:
            let tile_id = tile[id]
            let item_id = item[id]
            if       tile_id != tile_none: ren[id] = r.with_glyph(tile_sprite(tile_id))
            else: if item_id != item_none: ren[id] = r.with_glyph(item_sprite(item_id))
        return id

    def add_type(id:int, t:entype): set_type(id, type[id] |  t)
    def del_type(id:int, t:entype): set_type(id, type[id] & ~t)

    def set_type(id:int, t:entype):
        let old = type[id]
        if old != t:
            type[id] = t
            t = notify_type(id, old, t)
        if t == ent_none:
            free_ids.push(id)

    def notify_type(id:int, old:entype, new:entype) -> entype:
        for(systems):
            let prior = new
            new = _.ent_changed(this, id, old, new)
            if new != prior:
                type[id] = new
        return new

//// ancillary component: spatial animation

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

    def drop(live, dead): if dead.length:
        ids     = map(live): ids[_]
        flags   = map(live): flags[_]
        blocked = flags.fold(false): if (_a | _b) & anim_block: true else: false
        time    = map(live): time[_]
        elapsed = map(live): elapsed[_]
        as      = map(live): as[_]
        bs      = map(live): bs[_]

    def update(shard:shard, update_dt:float):
        let left = map(shard.type.length()): update_dt

        let resets = []::int

        // TODO maybe decompose loop into stages
        for(ids) id, anim_id:
            def anims_advance(dt):
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
            left[id] = anims_advance(left[id])

        // prune all expired animations (that aren't flagged to keep)
        let live, dead = elapsed.partition_indices() t, anim_id:
            t < time[anim_id] || flags[anim_id] & anim_keep

        // reset all looped animations
        if resets.length:
            for(ids) id, anim_id:
                if resets.first_index(id) >= 0:
                    elapsed[anim_id] = 0

        this.drop(live, dead)

    def has_any(id):
        let anim_id = ids.first_index(id)
        return anim_id >= 0

    def clear(shard:shard, id):
        let prior, rest = ids.partition_indices(): _ == id
        if prior.length:
            let anim_id = prior[prior.length - 1]
            shard.pos[id] = bs[anim_id]
        this.drop(rest, prior)

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

def animate(this::anims, id:int, over:float, body):
    anim_scaffold {
        anims: this,
        id:    id,
        time:  over,
    }.with(body)

//// ancillary component: bodys collide

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

//// ancillary component: minds take action

enum_flags actiontype:
    action_none = 0
    action_move = 1
    action_hand_drop
    action_hand_swap
    action_hand_use
    action_hand_combine

struct action:
    act:actiontype
    dir:xy_f

    def target(p:spatial):
        var l = p.xy
        if act & action_move:
            l += dir
        return int(l)

let action_0 = action { action_none, xy_0 }

def move_dir(d:xy_f):   return action { action_move, d }
def act(at:actiontype): return action { at, xy_0 }

def input_fun() -> action

class mind:
    // TODO partial information sensed in, rather than direct world access
    id    : int
    state : int = 0

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
    ids   = []::int
    types = []::entype
    minds = []::mind

    def enter(id, type):
        let n, i = ids.binary_search(id)
        ids.insert(i, id)
        types.insert(i, type)
        minds.insert(i, mind { id: id })

    def exit(id):
        let n, i = ids.binary_search(id)
        ids.remove(i, n)
        types.remove(i, n)
        minds.remove(i, n)

    def ent_changed(shard, id:int, old:entype, new:entype):
        if (old ^ new) & ent_mind:
            if       new & ent_mind: this.enter(id, new)
            else: if old & ent_mind: this.exit(id)
        else:
            let n, i = ids.binary_search(id)
            for(n) j: types[i + j] = new
        return new

    def intents(input:input_fun):
        let intents = map(types) t, mind_id:
            if t & ent_input: input()
            else:             minds[mind_id].think()
        let actor_ids = vector_reserve(typeof [int], intents.length)
        let actions   = vector_reserve(typeof [action], intents.length)
        for(intents) act, mind_id: if act.act != action_none:
            actor_ids.push(ids[mind_id])
            actions.push(act)
        return actor_ids, actions

//// ancillary component: avatars represent character state

class avatar:
    retex      = false
    state      = avatar_state_content
    moji       = glyph_0
    helf       = xy { 3, 3 } // ❤️
    stam       = xy { 0, 0 } // 💛
    initiative = 0
    gives      = false
    left_hand  = item_none
    right_hand = item_none
    // TODO worn item
    // TODO back item

    show_hearts = false
    show_status = false

    def offer() -> item_entity_id:
        if not gives:
            return item_none
        if right_hand != item_none: return right_hand
        if  left_hand != item_none: return left_hand
        return item_none

    def offer_taken():
        if gives:
            if right_hand != item_none:
                right_hand = left_hand
                left_hand = item_none
            else: if  left_hand != item_none:
                left_hand = item_none

    def take(id:item_entity_id) -> bool:
        if id == item_none:
            return false
        if right_hand != item_none:
            if left_hand != item_none:
                return false
            left_hand = right_hand
        right_hand = id
        return true

    def drop() -> item_entity_id:
        if right_hand != item_none:
            let r = right_hand
            right_hand = item_none
            print("dropped right hand " + r)
            return r
        if left_hand != item_none:
            let r = left_hand
            left_hand = item_none
            print("dropped left hand " + r)
            return r
        return item_none

    def swap():
        let tmp = right_hand
        right_hand = left_hand
        left_hand = tmp

    def use_hand():
        if right_hand != item_none:
            print("TODO use " + right_hand) // TODO implement
            return
        if left_hand != item_none:
            right_hand = left_hand
            left_hand = item_none
            print("use fault swap")
            return

    def combine_hands():
        if right_hand == item_none: return
        if  left_hand == item_none: return
        print("TODO combine " + right_hand + " + " + left_hand) // TODO implement

    def faces(each):
        var i = 0
        if moji.code != 0:
            each(moji, i++)
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
            gl_set_primitive_texture(0, glyf.get_texture())
            gl_unit_square()
        faces() glyf, i:
            if i == 0:
                gl_translate(xy_1 / 6): gl_scale(face):
                    unit(glyf)
            else: if show_status:
                gl_scale(icon):
                    gl_translate(xy_f { 4 - (i - 1) / 3, (i - 1) % 3 }):
                        unit(glyf)
        if show_hearts:
            hearts() heart, x, y:
                gl_scale(icon):
                    gl_translate(xy_f { y, x }):
                        unit(heart)
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

    def update_tex(shard, av, id):
        shard.tex[id] = sprite_render(res):
            gl_scale(float(res)):
                av.draw_tile()
        av.retex = false

    def update_any(shard):
        for(avatars) av, avatar_id: if av.retex:
            update_tex(shard, av, ids[avatar_id])

    def get(id:int) -> avatar?:
        let n, avatar_id = ids.binary_search(id)
        return if n: avatars[avatar_id] else: nil

    def with(shard, id:int, body):
        shard.add_type(id, ent_avatar)
        let n, avatar_id = ids.binary_search(id)
        assert n
        let av = avatars[avatar_id]
        body(av)
        av.retex = true

    def enter(shard, id, type):
        let n, avatar_id = ids.binary_search(id)
        if not n:
            let show = if shard.type[id] & ent_input: true else: false
            ids.insert(avatar_id, id)
            avatars.insert(avatar_id, avatar {
                moji:        shard.ren[id].glyf,
                retex:       true,
                show_hearts: show,
                show_status: show,
            })

    def exit(shard, id):
        let n, avatar_id = ids.binary_search(id)
        if n:
            ids.remove(avatar_id, n)
            avatars.remove(avatar_id, n)
            shard.tex[id] = nil

    def ent_changed(shard, id:int, old:entype, new:entype):
        if (old ^ new) & ent_avatar:
            if       new & ent_avatar: this.enter(shard, id, new)
            else: if old & ent_avatar: this.exit(shard, id)
        else: if (old ^ new) & ent_input:
            let show = if new & ent_input: true else: false
            this.with(shard, id) av:
                av.show_hearts = show
                av.show_status = show
        return new

//// entity building

class ent_template:
    type  : entype
    bg    = color_clear
    fg    = color_clear
    glyph = glyph_0
    z     = 0.0
    size  = 1.0

    tile = tile_none
    item = item_none

    spawn_prob = xy_0i
    spawn_template = 0

    avatar_helf       = xy_0i
    avatar_stam       = xy_0i
    avatar_initiative = 0
    avatar_gives      = false
    avatar_left_hand  = item_none
    avatar_right_hand = item_none

let ent_0 = ent_template { type: ent_none }

class ent_templates:
    defs = []::ent_template

    def register(tmpl):
        if not defs.length: defs.push(ent_0)
        let id = defs.length
        defs.push(tmpl)
        return id

    def define(t:entype, body):
        let tmpl = ent_template { type: t }
        body(tmpl)
        return register(tmpl)

    def extend(base_id, body):
        let tmpl = copy(defs[base_id])
        body(tmpl)
        return register(tmpl)

class ent_scaffold:
    loc = xy_0

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

//// ancillary component: entities spawn other entities

class spawner : system
    ids  = []::int
    prob = []::xy_i
    tid  = []::int

    def ent_changed(shard, id:int, old:entype, new:entype):
        if new == ent_none:
            let n, i = ids.binary_search(id)
            if n:
                ids.remove(i, n)
                prob.remove(i, n)
                tid.remove(i, n)
        return new

    def clear_spawn(id:int):
        let n, i = ids.binary_search(id)
        if n:
            ids.remove(i, n)
            prob.remove(i, n)
            tid.remove(i, n)

class spawn_scaffold:
    spawner:spawner
    id: int
    next_spawn_id: int

    p = xy_0i

    def prob(x:int, y:int): p = xy_i { x,     y }
    def odds(x:int, y:int): p = xy_i { x, x + y }

    def add_spawn(template_id:int):
        if template_id != 0 and p.x and p.y:
            spawner.ids.insert(next_spawn_id, id)
            spawner.prob.insert(next_spawn_id, p)
            spawner.tid.insert(next_spawn_id, template_id)
            next_spawn_id++

def add_spawn(this::spawner, id:int, body):
    let n, spawn_id = ids.binary_search(id)
    body(spawn_scaffold {
        spawner: this,
        id: id,
        next_spawn_id: spawn_id,
    })
