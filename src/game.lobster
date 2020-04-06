import color
import imgui
import std
import vec

import ecs

/* TODO

- viewport control (zoom and pan)

- ecs
  - weak cross-entity relations outside of the strong intrinsic tree/graph ones

- spawner seems to have a bug where trees can't spawn more than one fruit; was
  supposed to be able to spawn 1 in each spot

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

*/

def print_list(title, level, body):
    var first = true
    var last_item = ""
    var last = ""
    if level: title = repeat_string(" ", 2*(level-1)) + "- " + title
    body(level+1) sublevel, item:
        if last_item != "":
            if first:
                first = false
                print(title + ":")
            print(last)
        last_item = item
        last = repeat_string(" ", 2*(sublevel-1)) + "- " + item
    if first:
        if last_item == "":
            print(title + ": --none--")
        else:
            print(title + ": " + last_item)
    else: if last_item != "": print(last)

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

//// shard integration

let neighbor_cell_offsets = [
    xy_i {  0, -1 }, // up
    xy_i {  1, -1 }, // up-right
    xy_i {  1,  0 }, // right
    xy_i {  1,  1 }, // down-right
    xy_i {  0,  1 }, // down
    xy_i { -1,  1 }, // down-left
    xy_i { -1,  0 }, // left
    xy_i { -1, -1 }, // up-left
]

enum_flags trace:
    trace_spawn
    trace_action
    trace_render
    trace_all // all entities, not just ones with ent_debug set

class chunk : shard
    // debug tracing
    trace = trace(0)

    // performance timers
    timers = timers{}

    // game-specific entity systems
    spawner = spawner {}
    minds   = minds {}
    bodys   = bodys {}
    anims   = anims {}

    movement_time = 1.0 / 4

    // scratch data used for action stepping
    actor_ids = []::int
    actions   = []::action
    targets   = []::xy_i
    group_ids = []::int
    groups    = []::[int]
    hits      = []::[int]

    def should_trace(id, mask):
        if trace & mask:
            if trace & trace_all: return true
            if type[id] & ent_debug: return true
        return false

    def render_ent_graph(id):
        let debug = should_trace(id, trace_render)
        if debug:
            print("render " + this.tag(id))
        this.walk_rec(id) nid, depth, descend: if type[nid] & ent_visible:
            if debug:
                print("... " + this.describe(nid))
            nest_if(depth > 0) body:
                let c = cap[par[nid]]
                let child_size = if c == xy_0: xy_1 else: xy_1 / c
                transform_ent(nid, child_size, body)
            with:
                render_ent(nid)
                descend() // TODO z-ordering?

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
                gl_scale(size): render_ent_graph(id)
            ksh[id] = tx
        assert tx // FIXME
        gl_set_shader("textured")
        gl_set_primitive_texture(0, tx)
        gl_color(color_white): gl_unit_square()

    def can_step():
        return !anims.blocked

    def update(dt:float):
        anims.update(this, dt)

    def walk_rec_sizes(id, body):
        var size = xy_1
        this.walk_rec(id) nid, depth, descend:
            body(nid, size):
                let c = cap[nid]
                if c.x != 0 and c.y != 0:
                    let scale = xy_1 / c * pos[nid].w
                    size *= scale
                    descend()
                    size /= scale

    def actor_at(id, at):
        let debug = should_trace(id, trace_action)
        if debug: print_list(this.tag(id) + " interacts with", 0) level, print_item:
            for(at) at_id:
                let item = build_string() emit:
                    emit(this.tag(at_id))
                    this.describe_intrinsics(at_id, emit)
                print_item(level, item)

        /*

        take rule:
            WHEN ( # acts:size=act ) + ( # holds>_:size ) + ( @ holds>X:size )
             AND size <= act
             AND size.sq <= avail
            THEN holds>X
             MAX size
             MIN avail
            WITH avail = holds:cap.sq - sum( holds>*:size.sq )

        */

        let acts = []::int
        let acts_size = []::xy_f
        this.walk_rec_sizes(id) nid, size, descend:
            if type[nid] & ent_acts:
                acts.push(nid)
                acts_size.push(size)
            else:
                descend()

        // TODO further capability evaluation; especially abilities conferred from held items
        if !acts.length:
            return
        if debug: print_list("acts with one of", 1) level, print_item:
            for(acts) act_id, i: print_item(level, this.tag(act_id) +
                " size:" + acts_size[i])

        var max_act = xy_0
        for(acts_size) size:
            if max_act.x * max_act.y < size.x * size.y:
                max_act = size

        let at_held = []::int
        let at_held_size = []::xy_f
        for(at) atid: this.walk_rec_sizes(atid) nid, size, descend:
            if type[nid] & ent_holds:
                let child_size = size / cap[nid] * pos[nid].w
                this.walk_next(first[nid]) cid: if rel[cid] == entrel_held:
                    let sz = child_size * pos[cid].w
                    // TODO further capability evaluation
                    if max(max_act) >= min(sz):
                        at_held.push(cid)
                        at_held_size.push(sz)
            else:
                descend()

        // TODO further capability evaluation
        if !at_held.length:
            return
        if debug: print_list("at held items", 1) level, print_item:
            for(at_held) held_id, i: print_item(level, this.tag(held_id) +
                " size:" + at_held_size[i] +
                " in:" + this.tag(this.par[held_id]))

        let holds = []::int
        let holds_cell = []::xy_f
        let holds_size = []::xy_f
        let holds_avail = []::float
        this.walk_rec_sizes(id) nid, size, descend:
            if type[nid] & ent_holds:
                let c = cap[nid]
                let child_size = size / c * pos[nid].w
                var avail = size.x * size.y
                this.walk_next(first[nid]) cid: if rel[cid] == entrel_held:
                    let sz = child_size * pos[cid].w
                    avail -= sz.x * sz.y
                if avail > 0:
                    holds.push(nid)
                    holds_cell.push(child_size)
                    holds_size.push(size)
                    holds_avail.push(avail)
            else:
                descend()

        // TODO further capability evaluation
        if !holds.length:
            return
        if debug: print_list("take into one of", 1) level, print_item:
            for(holds) hold_id, i: print_item(level, this.tag(hold_id) +
                " holds_cell:" + holds_cell[i] +
                " holds_avail:" + holds_avail[i] +
                " holds_size:" + holds_size[i])

        var take_id = -1
        var into_id = -1
        var take_size = xy_0
        for(at_held_size) size, i: if take_size.x * take_size.y < size.x * size.y:
            var into_avail = 0.0
            for(holds_avail) avail, j:
                if into_avail == 0 or into_avail < avail:
                    into_avail = avail
                    into_id = j
            if into_avail > 0:
                take_id = i
                take_size = size

        if take_id >= 0 and into_id >= 0:
            take_id = at_held[take_id]
            let root_id = this.root_of(take_id)
            if debug: print("  -" +
                " take:" + this.tag(take_id) +
                " from:" + this.tag(root_id) +
                " size:" + take_size)

            into_id = holds[into_id]
            if debug: print("  -" +
                " into:" + this.tag(into_id) +
                " of:" + this.tag(this.root_of(into_id)) +
                " avail:" + holds_avail[into_id])

            this.add_child(into_id, entrel_held, take_id)
            let p = pos[take_id]
            let loc = xy_0 // TODO place in a free cell
            pos[take_id] = spatial { loc.x + 0.5, loc.y + 0.5, p.z, p.w }

            if debug: print("  -" +
                " beheld:" + this.tag(take_id))
            else:
                print(this.tag(id) + " took " + this.tag(take_id) + " from " + this.tag(root_id))

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

        if at.length == 1 and at[0] == id:
            // TODO special case self action?
            return

        if at.length: // have at!
            actor_at(id, at)

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
        return filter(bodys.ids) id: par[id] == 0 and pos[id].cell() == loc

    def gather_bodys(locs):
        let ats = locs.map(): []
        // TODO spatial query
        for(bodys.ids) id: if par[id] == 0:
            let pc = pos[id].cell()
            for(locs) loc, i:
                if loc == pc: ats[i].push(id)
        return ats

    def bodys_under(id:int):
        return collect() each: this.walk_next(first[id]) cid:
            if type[cid] & ent_body: each(cid)

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
                    // XXX
                    // switch act.act:
                    //     case action_none:         nil
                    //     case action_hand_drop:    av.drop()
                    //     case action_hand_swap:    av.swap()
                    //     case action_hand_use:     av.use_hand()
                    //     case action_hand_combine: av.combine_hands()
                    //     case action_move:
                    actor_move(id, actor_id)

def new_chunk():
    let ch = chunk {}
    ch.systems.push(ch.minds)
    ch.systems.push(ch.bodys)
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
        if shard.par[id] == 0 and (old ^ new) & ent_visible:
            if       new & ent_visible: this.enter(shard, id)
            else: if old & ent_visible: this.exit(id)
        return new

    def ent_linked(shard, id:int, pid:int, ex_pid:int):
        if pid == 0:
            if shard.type[id] & ent_visible: this.enter(shard, id)
        else: if ex_pid == 0:
            if shard.type[id] & ent_visible: this.exit(id)

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

def build_entity(this::ent_scaffold, chunk:chunk, id:int):
    if tmpl.type & ent_mind:
        chunk.minds.set_init(id, tmpl.initiative)
    if tmpl.spawn.length:
        chunk.spawner.add_spawns(id, this)

def create_with(this::ent_scaffold, chunk:chunk, body):
    if tmpl.type: with_rel(tmpl.rel_in):
        let id = chunk.create(tmpl.type): this.init_entity(chunk, _)
        build_entity(chunk, id)
        under(id): with_rel(tmpl.rel_out):
            at_each(tmpl.child_at) child_id:
                let childrel = tmpl.childrel[child_id]
                nest_if(childrel) _: with_rel(childrel): _()
                with: use(tmpl.children[child_id]): this.create_with(chunk): nil
            body(id, this)

def create(this::ent_scaffold, chunk:chunk):
    var id = 0
    this.create_with(chunk) _: id = _
    return id

def entity_exists(this::ent_scaffold, chunk:chunk, l:xy_f):
    if not tmpl.type & ent_body: return false
    let there =
        if par: chunk.bodys_under(par)
        else:   chunk.bodys_at(int(l))
    return exists(there): chunk.type[_] & ent_body

def do_spawn(this::ent_scaffold, chunk:chunk, l:xy_f, body):
    nest_if(!par): at(l, _)
    with: create_with(chunk, body)

def spawn(this::spawner, chunk):
    var last_id = -1
    var loc = xy_0
    var did = false

    def once_each(when, then):
        for(ids) id, spawn_id:
            if id != last_id:
                last_id = id
                loc = float(chunk.pos[id].cell())
                did = false
            if not did and when(id, spawn_id):
                then(id, spawn_id)
                did = true

    def can_spawn(spawn_id) -> bool:
        let ctx = scaf[spawn_id]
        return !ctx.entity_exists(chunk, loc)

    def should_spawn(spawn_id) -> bool:
        // TODO other trigger modes or distributions?
        let p = prob[spawn_id]
        return rnd(p.y) <= p.x

    once_each() id, spawn_id: can_spawn(spawn_id) and should_spawn(spawn_id)
    then id, spawn_id:
        let ctx = scaf[spawn_id]
        ctx.do_spawn(chunk, loc) new_id:
            if chunk.should_trace(id, trace_spawn):
                print(chunk.tag(id) + " spawn_id:" + spawn_id + " spawned " + chunk.tag(new_id) + " template:" + ctx.tmpl)

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

let floor_template = new_template(ent_cell | ent_visible):
    _.z    = 0.0
    _.size = 1.0

let pine_apple_template = new_template(ent_body | ent_visible):
    _.name = "pineapple"
    _.z    = 0.75
    _.size = 1.0
    _.fg   = color_white
    _.glyph = item_sprite(item_pine_apple)

let apple_template = new_template(ent_body | ent_visible):
    _.name = "apple"
    _.z    = 0.75
    _.size = 1.0
    _.fg   = color_white
    _.glyph = item_sprite(item_apple)

let tree_evergreen = new_template(ent_body | ent_visible | ent_holds):
    let fruit = pine_apple_template
    _.name = "evergreen tree"
    _.z    = 0.5
    _.size = 1.0
    _.fg   = color_white
    _.glyph = tile_sprite(tile_pine_tree)
    _.cap = xy_f { 3, 4 }
    _.add_spawn_child(fruit, xy_i { 5, 1000 }, entrel_held, xy_f { 1, 0 })
    _.add_spawn_child(fruit, xy_i { 5, 1000 }, entrel_held, xy_f { 1, 1 })
    _.add_spawn_child(fruit, xy_i { 5, 1000 }, entrel_held, xy_f { 1, 2 })

let tree_deciduous = new_template(ent_body | ent_visible | ent_holds):
    let fruit = apple_template
    _.name = "deciduous tree"
    _.z    = 0.5
    _.size = 1.0
    _.fg   = color_white
    _.glyph = tile_sprite(tile_apple_tree)
    _.cap = xy_f { 6, 6 }
    _.add_spawn_child(fruit, xy_i { 5, 1000 }, entrel_held, xy_f { 1, 2 })
    _.add_spawn_child(fruit, xy_i { 5, 1000 }, entrel_held, xy_f { 2, 2 })
    _.add_spawn_child(fruit, xy_i { 5, 1000 }, entrel_held, xy_f { 3, 2 })
    _.add_spawn_child(fruit, xy_i { 5, 1000 }, entrel_held, xy_f { 4, 2 })
    _.add_spawn_child(fruit, xy_i { 5, 1000 }, entrel_held, xy_f { 2, 3 })
    _.add_spawn_child(fruit, xy_i { 5, 1000 }, entrel_held, xy_f { 3, 3 })

let left_hand_template = new_template(ent_body | ent_visible | ent_holds | ent_acts):
    _.name = "left hand"
    _.z    = 1.0
    _.size = 1.0
    _.fg   = color_white
    _.glyph = ui_sprite(ui_left_hand)
    _.cap = xy_f { 1, 1 }

let right_hand_template = left_hand_template.extend():
    _.name = "right hand"
    _.glyph = ui_sprite(ui_right_hand)

let heart_template = new_template(ent_body | ent_visible):
    _.name = "heart"
    _.z    = 1.0
    _.size = 0.5
    _.fg   = color_white
    _.glyph = ui_sprite(ui_health_heart) // ❤️

let stamina_heart_template = heart_template.extend():
    _.name = "stamheart"
    _.glyph = ui_sprite(ui_stamina_heart) // 💛

let char_template = new_template(ent_body | ent_visible | ent_mind):
    _.name  = "UNKNOWN character"
    _.glyph = avatar_sprite(avatar_content) // 🙂
    _.fg    = color_white
    _.z     = 1.0
    _.size  = 1.0
    _.cap   = xy_f { 3, 3 }
    _.add_child(entrel_body, xy_f { 0, 2 }, left_hand_template)
    _.add_child(entrel_body, xy_f { 2, 2 }, right_hand_template)

let player_template = char_template.extend():
    _.type |= ent_input | ent_debug
    _.name  = "player"
    _.initiative = 10

    // TODO would it be better to have a heart-container?
    let off = xy_f { -0.25, -0.25 }
    _.add_child(entrel_body, xy_f { 0.0, 0 } + off, heart_template)
    _.add_child(entrel_body, xy_f { 0.5, 0 } + off, heart_template)
    _.add_child(entrel_body, xy_f { 1.0, 0 } + off, heart_template)

let gift_earth = new_template(ent_body | ent_visible):
    _.name = "gift of earth"
    _.z     = 0.75
    _.size  = 1.0
    _.glyph = item_sprite(item_clover)
    _.fg    = color_dark_green

let gift_water = new_template(ent_body | ent_visible):
    _.name = "gift of water"
    _.z     = 0.75
    _.size  = 1.0
    _.glyph = item_sprite(item_water)
    _.fg    = color_teal

let gift_fire = new_template(ent_body | ent_visible):
    _.name = "gift of fire"
    _.z     = 0.75
    _.size  = 1.0
    _.glyph = item_sprite(item_fire)
    _.fg    = color_orange

let gift_air = new_template(ent_body | ent_visible):
    _.name = "gift of air"
    _.z     = 0.75
    _.size  = 1.0
    _.glyph = item_sprite(item_wind)
    _.fg    = color_cyan

let element_earth = char_template.extend() e:
    e.name  = "earth elemental"
    e.glyph = item_sprite(item_clover)
    e.fg    = color_dark_green
    e.initiative = 3
    e.children[0] = e.children[0].extend():
        _.glyph = glyph_0 // TODO really we want an "invisible hand"
        _.add_child(entrel_held, xy_0, gift_earth)
    e.children[1] = e.children[1].extend():
        _.glyph = glyph_0 // TODO really we want an "invisible hand"
        _.add_child(entrel_held, xy_0, gift_earth)

let element_water = char_template.extend() e:
    e.name  = "water elemental"
    e.glyph = item_sprite(item_water)
    e.fg    = color_teal
    e.initiative = 4
    e.children[0] = e.children[0].extend():
        _.glyph = glyph_0 // TODO really we want an "invisible hand"
        _.add_child(entrel_held, xy_0, gift_water)
    e.children[1] = e.children[1].extend():
        _.glyph = glyph_0 // TODO really we want an "invisible hand"
        _.add_child(entrel_held, xy_0, gift_water)

let element_fire = char_template.extend() e:
    e.name  = "fire elemental"
    e.glyph = item_sprite(item_fire)
    e.fg    = color_orange
    e.initiative = 5
    e.children[0] = e.children[0].extend():
        _.glyph = glyph_0 // TODO really we want an "invisible hand"
        _.add_child(entrel_held, xy_0, gift_fire)
    e.children[1] = e.children[1].extend():
        _.glyph = glyph_0 // TODO really we want an "invisible hand"
        _.add_child(entrel_held, xy_0, gift_fire)

let element_air = char_template.extend() e:
    e.name  = "air elemental"
    e.glyph = item_sprite(item_wind)
    e.fg    = color_cyan
    e.initiative = 6
    e.children[0] = e.children[0].extend():
        _.glyph = glyph_0 // TODO really we want an "invisible hand"
        _.add_child(entrel_held, xy_0, gift_air)
    e.children[1] = e.children[1].extend():
        _.glyph = glyph_0 // TODO really we want an "invisible hand"
        _.add_child(entrel_held, xy_0, gift_air)

def build_world(chunk):
    let size = 12
    let build = ent_scaffold {}

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
        move_dir(xy {  0.0, -1.0 }), // up
        move_dir(xy {  0.0,  1.0 }), // down
        move_dir(xy { -1.0,  0.0 }), // left
        move_dir(xy {  1.0,  0.0 }), // right
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
