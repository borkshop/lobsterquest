import color
import imgui
import std
import vec

import ecs

/* TODO
- better trace logging facility

- viewport control (zoom and pan)

- minds
  - tracks progress and abilities, e.g. elemental essences, status of mojick
  - quest tracking

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

- log hud?
- imgui
  - closable windows would be nice
  - use imgui more like the overlay demo example
- ai system based on behavior trees
- relations to other entities (threats, assists, respects, etc)

*/

// TODO eject data templates into separate module
let templates = ent_templates {}

class timers:
    labels = []::string
    values = []::[float]
    capn   = []::int

    def im_show():
        for(labels) label, id:
            im_graph(label, values[id], false)

    def add(label:string, cap:int) -> int:
        let id = labels.length
        labels.push(label)
        values.push([])
        capn.push(cap)
        return id

    def record(id:int, value:float):
        let vals = values[id]
        vals.push(value)
        let over = vals.length - capn[id]
        if over > 0: vals.remove(0, over)

    def record_time(id:int, fun):
        let t0 = seconds_elapsed()
        fun()
        let t1 = seconds_elapsed()
        record(id, t1 - t0)

def for_from(xs, i, body):
    while i < xs.length():
        body(xs[i], i)
        i++

//// ancillary component: avatars represent character state

class avatar:
    retex      = false
    state      = avatar_state_content
    moji       = glyph_0
    helf       = xy { 3, 3 } // ❤️
    stam       = xy { 0, 0 } // 💛
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
        shard.invalidate(id)

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
            shard.invalidate(id)

    def ent_changed(shard, id:int, new:entype, old:entype):
        if (old ^ new) & ent_avatar:
            if       new & ent_avatar: this.enter(shard, id, new)
            else: if old & ent_avatar: this.exit(shard, id)
        else: if (old ^ new) & ent_input:
            let show = if new & ent_input: true else: false
            this.with(shard, id) av:
                av.show_hearts = show
                av.show_status = show
        return new

//// shard integration

class chunk : shard
    // carries game-specific entity templates
    templates = templates 

    // performance timers
    timers = timers{}

    // game-specific entity systems
    spawner = spawner {}
    minds   = minds {}
    bodys   = bodys {}
    avatars = avatars {}
    anims   = anims {}

    movement_time = 1.0 / 4

    // scratch data used for action stepping
    actor_ids = []::int
    actions   = []::action
    targets   = []::xy_i
    group_ids = []::int
    groups    = []::[int]
    hits      = []::[int]

    def render_ent(id):
        let tx = tex[id]
        if tx:
            gl_set_shader("textured")
            gl_set_primitive_texture(0, tx)
            gl_color(color_white): gl_unit_square()
        else:
            ren[id].draw()

    def transform_ent(id, size, body):
        let p = pos[id]
        let c = p.xy - p.w / 2
        gl_translate(c * size): gl_scale(size * p.w): body()

    def draw_ent(id, size): transform_ent(id, size):
        var tx = ksh[id]
        let tx_size = xy_i { int(size.x), int(size.y) }
        if !tx or gl_texture_size(tx) != tx_size:
            tx = render_to_texture(nil, tx_size, false, nil, texture_format_clamp | texture_format_nomipmap):
                gl_scale(size): render_ent(id)
            ksh[id] = tx
        assert tx // FIXME
        gl_set_shader("textured")
        gl_set_primitive_texture(0, tx)
        gl_color(color_white): gl_unit_square()

    def can_step():
        return !anims.blocked

    def update(dt:float):
        anims.update(this, dt)
        avatars.update_any(this)

    def actor_move(id, actor_id):
        // animate actor movement, adding to hit group if successful
        let group_id = group_ids[actor_id]
        let at = hits[group_id]
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
            if at.length: // blocked, half-animate
                anim.after(1): anim.pos = lerp(a, b, 0.5)
                anim.after(1): anim.pos = a
            else: // unblocked, full-animate
                anim.after(1): anim.pos = b
        if not at.length: // unblocked, update actor state
            at.push(id) // ...am here now, have at me!

    def actor_find_at(actor_id, want):
        let group_id = group_ids[actor_id]
        let at = hits[group_id]
        for(at) id, i: if want(id):
            if type[id] == ent_none:
                at.remove(i, 1)
                return

    def bodys_at(loc):
        // TODO spatial query
        return filter(bodys.ids) id: pos[id].cell() == loc

    def step(input:input_fun):
        timers.record_time(0):
            timers.record_time(1): for(minds.ids): anims.clear(this, _)
            timers.record_time(2): run_minds(input)
            timers.record_time(6): spawn_items()

    def run_minds(input:input_fun):
        timers.record_time(3):
            actor_ids, actions = minds.intents(input)
            targets = map(actions) a, actor_id: a.target(pos[actor_ids[actor_id]])

        timers.record_time(4):
            group_ids = map(targets): -1
            groups    = vector_reserve(typeof [[int]], targets.length())
            hits      = vector_reserve(typeof [[int]], targets.length())

            // compute hit, resolving in groups of shared interest
            for(targets) t, actor_id:
                if group_ids[actor_id] < 0:
                    let group_id = groups.length()
                    let actors = [actor_id]
                    let at = bodys_at(t)
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

        timers.record_time(5):
            for(groups) actors:
                for(actors) actor_id:
                    let id = actor_ids[actor_id]
                    if type[id] & ent_avatar:
                        avatar_move(id, actor_id)
                    else:
                        actor_move(id, actor_id)

    def avatar_move(id, actor_id):
        avatars.with(this, id) av:
            let act = actions[actor_id]
            def boop(object_id) -> bool:
                // TODO take av.right_hand into account? combat? digging? crafting-at?
                let t = type[object_id]
                if t & ent_avatar: avatars.with(this, object_id) other_av:
                    let offered = other_av.offer()
                    if offered:
                        // TODO could open offered modal
                        if av.take(offered):
                            other_av.offer_taken()
                            print("#" + id + " took offered " + offered + " from #" + object_id)
                            return true
                        else:
                            print("#" + id + " decline offered " + offered + " from #" + object_id)
                    else:
                        print("#" + id + " shrug at #" + object_id)
                    return false
                let tile_id = tile[object_id]
                let item_id = item[object_id]
                if item_id != item_none:
                    if av.take(item_id):
                        this.set_type(object_id, ent_none)
                        print("#" + id + " took " + item_id + " from #" + object_id)
                        return true
                    else:
                        print("#" + id + " pass " + item_id + " from #" + object_id)
                else: if tile_id != tile_none:
                    // TODO gathering from tiles, climbing onto tiles, entering
                    // vehicle tiles, enter any inner space, ...
                    print("#" + id + " TODO " + tile_id + " from #" + object_id)
                else:
                    // TODO avatar state (hand items) X object
                    print("#" + id + " booped an unknown type:" + entype_str(t) + " from #" + object_id)
                return false

            switch act.act:
                case action_none:         nil
                case action_hand_drop:    av.drop()
                case action_hand_swap:    av.swap()
                case action_hand_use:     av.use_hand()
                case action_hand_combine: av.combine_hands()
                case action_move:
                    if act.dir == xy_0:
                        print("#" + id + " rest...") // TODO and then...
                    else:
                        actor_find_at(actor_id) object_id: boop(object_id)
                        actor_move(id, actor_id)

def new_chunk():
    let ch = chunk {}
    ch.systems.push(ch.minds)
    ch.systems.push(ch.bodys)
    ch.systems.push(ch.avatars)
    ch.systems.push(ch.spawner)

    ch.timers.add("step", 64)             // 0
    ch.timers.add("step.prep", 64)        // 1
    ch.timers.add("step.minds", 64)       // 2
    ch.timers.add("...minds.think", 64)   // 3
    ch.timers.add("...minds.hits", 64)    // 4
    ch.timers.add("...minds.resolve", 64) // 5
    ch.timers.add("step.spawn", 64)       // 6

    return ch

class stacked_scene : system
    ids = []::int
    zs  = []::float
    // TODO maybe bucket-by-z rather than full sorting

    def enter(shard, id):
        let z = shard.pos[id].z
        let n, scene_id = zs.binary_search(z)
        ids.insert(scene_id, id)
        zs.insert(scene_id, z)

    def exit(id): while_first_index(ids, id) scene_id:
        ids.remove(scene_id, 1)
        zs.remove(scene_id, 1)

    def ent_changed(shard, id:int, new:entype, old:entype):
        if (old ^ new) & ent_visible:
            if       new & ent_visible: this.enter(shard, id)
            else: if old & ent_visible: this.exit(id)
        return new

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

    def draw(chunk, screen_size, dt):
        chunk.update(dt)
        let minc, maxc = bounds(chunk)
        let space_size = float(maxc - minc + 1)
        let side_size  = float(max(1, min(floor(screen_size / space_size))))
        let view_rem   = screen_size - space_size * side_size
        gl_translate(float(-minc.xy) * side_size + view_rem / 2):
            let cell_size = xy_f { side_size, side_size }
            for(ids): chunk.draw_ent(_, cell_size)

def place_at(this::ent_template, chunk:chunk, id:int, pos:xyz_f):
    var r = render { bg, fg, glyph }
    if r.glyf == glyph_0:
        if       tile != tile_none: r = r.with_glyph(tile_sprite(tile))
        else: if item != item_none: r = r.with_glyph(item_sprite(item))
    chunk.pos[id] = spatial { pos.x, pos.y, pos.z, size }
    chunk.ren[id] = r
    if tile != tile_none: chunk.tile[id] = tile
    if item != item_none: chunk.item[id] = item

def elaborate(this::ent_template, chunk:chunk, id:int):
    if type & ent_mind:
        chunk.minds.set_init(id, initiative)
    if type & ent_avatar: chunk.avatars.with(chunk, id) av:
        if avatar_helf.y     != 0:         av.helf       = avatar_helf
        if avatar_stam.y     != 0:         av.stam       = avatar_stam
        if avatar_gives:                   av.gives      = avatar_gives
        if avatar_left_hand  != item_none: av.left_hand  = avatar_left_hand
        if avatar_right_hand != item_none: av.right_hand = avatar_right_hand
    if this.spawn_prob != xy_0i:
        chunk.spawner.add_spawn(id) sp:
            sp.prob(spawn_prob.x, spawn_prob.y)
            sp.add_spawn(this.spawn_template)

def create_with(this::ent_scaffold, chunk:chunk, body):
    if not tmpl.type:
        return 0
    assert tmpl.tile == tile_none or tmpl.item == item_none // may have associated tile or item sheet data, but not both
    return chunk.create(tmpl.type) id:
        tmpl.place_at(chunk, id, xyz { loc.x + off.x, loc.y + off.x, tmpl.z })
    post id:
        tmpl.elaborate(chunk, id)
        body(id, this)

def create(this::ent_scaffold, chunk:chunk):
    return this.create_with(chunk): nil

def spawn(this::spawner, chunk):
    var last_id = -1
    var at = spatial_0
    var did = false

    def once_each(when, then):
        for(ids) id, spawn_id:
            if id != last_id:
                last_id = id
                at = chunk.pos[id]
                did = false
            if not did and when(id, spawn_id):
                then(id, spawn_id)
                did = true

    def can_spawn(spawn_id) -> bool:
        // TODO other constraints
        let tmpl = chunk.templates.defs[tid[spawn_id]]
        let there = chunk.bodys_at(at.cell())
        // tiles are exclusive, items are unique, bodys are exclusive, otherwise ... sure?
        if tmpl.tile != tile_none: return !exists(there): chunk.tile[_] != tile_none
        if tmpl.item != item_none: return !exists(there): chunk.item[_] == tmpl.item
        if tmpl.type & ent_body: return !exists(there): chunk.type[_] & ent_body
        return true

    def should_spawn(spawn_id) -> bool:
        // TODO other trigger modes or distributions?
        let p = prob[spawn_id]
        return rnd(p.y) <= p.x

    once_each() id, spawn_id: can_spawn(spawn_id) and should_spawn(spawn_id)
    then id, spawn_id:
        let ctx = ent_scaffold {
            templates: chunk.templates,
            loc: float(at.cell()),
        }
        ctx.use(tid[spawn_id]):
            let new_id = ctx.create(chunk)
            print("#" + id + " spawn_id:" + spawn_id + " spawned #" + new_id + " template:" + tid[spawn_id])

def spawn_items(this::chunk): spawner.spawn(this)

//// specialization

let preload_fonts = [
    "data/fonts/Square/square.ttf",
    "data/fonts/Twemoji/TwitterColorEmoji-SVGinOT.ttf",
    "data/fonts/US101/US101.TTF",
    "data/fonts/unifont.ttf",
]

// TODO refactor sheet loading to further defer gl_window call
fatal(gl_window("Mojick PoC", 768, 768))

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

def ascii(code:int):    return glyph { ascii_glyph_mode,    font_rune(ascii_glyph_mode,    code) }
def sqascii(code:int):  return glyph { sqascii_glyph_mode,  font_rune(sqascii_glyph_mode,  code) }
def unicode(code:int):  return glyph { unicode_glyph_mode,  font_rune(unicode_glyph_mode,  code) }
def uniblock(code:int): return glyph { uniblock_glyph_mode, font_rune(uniblock_glyph_mode, code) }
def twemoji(code:int):  return glyph { twemoji_glyph_mode,  font_rune(twemoji_glyph_mode,  code) }

let floor_template = templates.define(ent_cell | ent_visible):
    _.z    = 0.0
    _.size = 1.0

let tile_template = templates.define(ent_body | ent_visible):
    _.z    = 0.5
    _.size = 1.0

let item_template = templates.define(ent_body | ent_visible):
    _.z    = 0.75
    _.size = 1.0 / 3.0

let char_template = templates.define(ent_body | ent_visible | ent_avatar | ent_mind):
    _.z    = 1.0
    _.size = 1.0

let player_template = templates.extend(char_template):
    _.type = _.type | ent_input
    _.initiative = 10

let tmpl_item_pine_apple = templates.extend(item_template):
    _.item = item_pine_apple

let tmpl_item_apple = templates.extend(item_template):
    _.item = item_apple

let tree_evergreen = templates.extend(tile_template):
    _.tile = tile_pine_tree
    _.spawn_prob = xy_i { 5, 1000 }
    _.spawn_template = tmpl_item_pine_apple

let tree_deciduous = templates.extend(tile_template):
    _.tile = tile_apple_tree
    _.spawn_prob = xy_i { 5, 1000 }
    _.spawn_template = tmpl_item_apple

let element_earth = templates.extend(char_template):
    _.glyph = item_sprite(item_clover)
    _.fg = color_dark_green
    _.initiative = 3
    _.avatar_gives = true
    _.avatar_left_hand = item_clover
    _.avatar_right_hand = item_clover

let element_water = templates.extend(char_template):
    _.glyph = item_sprite(item_water)
    _.fg = color_teal
    _.initiative = 4
    _.avatar_gives = true
    _.avatar_left_hand = item_water
    _.avatar_right_hand = item_water

let element_fire = templates.extend(char_template):
    _.glyph = item_sprite(item_fire)
    _.fg = color_orange
    _.initiative = 6
    _.avatar_gives = true
    _.avatar_left_hand = item_fire
    _.avatar_right_hand = item_fire

let element_air = templates.extend(char_template):
    _.glyph = item_sprite(item_wind)
    _.fg = color_cyan
    _.initiative = 5
    _.avatar_gives = true
    _.avatar_left_hand = item_wind
    _.avatar_right_hand = item_wind

def build_world(chunk):
    let size = 12
    let build = ent_scaffold {
        templates : templates
    }

    let dirt = [
        glyph_0, glyph_0, uniblock(0x2591), // ░
        glyph_0, glyph_0, uniblock(0x2592), // ▒
        glyph_0, glyph_0, uniblock(0x2593), // ▓
        glyph_0, glyph_0,
    ]
    let trees = [ tree_deciduous, tree_evergreen ]
    let elements = [ element_earth, element_water, element_fire, element_air ]

    let floor_bg_base     = color { 0.05, 0.05, 0.05, 1 }
    let floor_bg_variance = color { 0.05, 0.05, 0,    0 }
    let floor_fg_lift     = color { 0.05, 0,    0,    0 }

    let tree_fg_base      = color { 0.2,  0.25, 0.1,  1 }
    let tree_fg_variance  = color { 0,    0.5,  0,    0 }

    build.use(floor_template):
        build.fill_rect(size) x, y:
            build.create_with(chunk) id:
                let glyph = dirt.rnd_pick()
                let bg = floor_bg_base + floor_bg_variance * rnd_float()
                let fg = if glyph == glyph_0: color_clear else: bg + floor_fg_lift
                chunk.ren[id] = render { bg, fg, glyph }
            if x == 0 || y == 0 || x == size-1 || y == size-1:
                build.use(trees.rnd_pick()): build.create_with(chunk) id:
                    chunk.ren[id] = chunk.ren[id].with_fg(tree_fg_base + tree_fg_variance * rnd_float())

    let mid = float(floor(size / 2))
    build.translate(xy_f { mid, mid }):
        let l = size / 4
        build.translate_each([
            xy_f { -l,  l },
            xy_f {  l,  l },
            xy_f {  l, -l },
            xy_f { -l, -l },
        ]): build.use(elements[_]): build.create(chunk)
        build.use(player_template): build.create(chunk)

//// usage

class ui:
    paused      = false
    show_menu   = false
    show_engine = false
    show_editor = false
    build_size  = 13

    def run_forever(draw, step, stats, edit):
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
                    paused = im_checkbox("Paused", paused)

                    im_separator()
                    show_engine = im_checkbox("Engine Info", show_engine)
                    if show_engine:
                        im_show_engine_stats()
                        stats()

                    im_separator()
                    show_editor = im_checkbox("Edit Everything", show_editor)
                    if show_editor: edit()

                    im_separator()
                    im_button("Reboot"): done = true

                    im_separator()
                    im_button("Halt"): return from program

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

for(preload_fonts): check(gl_set_font_name(_), "cannot load gl font " + _)

let play_reader = button_action_reader {
    // arrow keys with "." to stay idiom
    buttons: [
        "w",
        "s",
        "a",
        "d",
        "z",
        "x",
        "q",
        "e",
        "c",
    ],
    actions: [
        move_dir(xy {  0.0, -1.0 }),
        move_dir(xy {  0.0,  1.0 }),
        move_dir(xy { -1.0,  0.0 }),
        move_dir(xy {  1.0,  0.0 }),
        move_dir(xy_0),
        act(action_hand_drop),
        act(action_hand_swap),
        act(action_hand_use),
        act(action_hand_combine),
    ],
}

def run_a_world():
    // TODO one for each face / level / etc
    var world = new_chunk()

    // TODO one for each visible chunk
    // TODO support dynamic attach/detach
    var scene = stacked_scene {}
    world.systems.push(scene)

    build_world(world)

    world.spawn_items()

    let ui = ui {}
    ui.run_forever():
        gl_clear(color_black)
        scene.draw(world, float(gl_window_size()), gl_delta_time())
        // TODO draw player overlay
    step:
        if world.can_step() and play_reader.read_input():
            world.step(): play_reader.action()
    stats:
        world.timers.im_show()
    edit:
        im_edit_anything(world, "World")
        im_edit_anything(scene, "Scene")
        im_edit_anything(ui, "UI")

do():
    // setup imgui for menu and debug overlay
    let im_font = "data/fonts/Inconsolata/Inconsolata-Bold.ttf"
    let im_fontsize = 32
    im_init(true)
    check(im_add_font(im_font, im_fontsize), "cannot load imgui font")

    forever():
        run_a_world()
