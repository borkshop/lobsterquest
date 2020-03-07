import ecs
import testing

let templates = ent_templates {}

let t_a = templates.define(ent_visible): nil
let t_b = templates.define(ent_visible): nil
let t_place = templates.define(ent_visible):
    _.z    = 1.0
    _.size = 1.0
    _.fg   = color_white

run_test("ecs/templates/spawn"):
    // data should not leak
    let t_stuff_a = templates.extend(t_place): _.add_spawn_sibling(t_a, xy_i { 1, 2 })
    let t_stuff_b = templates.extend(t_place): _.add_spawn_sibling(t_b, xy_i { 1, 3 })
    assert templates.defs[t_stuff_a].spawn_template.length == 1
    assert templates.defs[t_stuff_b].spawn_template.length == 1
    assert templates.defs[t_a].spawn_template.length == 0
    assert templates.defs[t_b].spawn_template.length == 0
    assert templates.defs[t_place].spawn_template.length == 0
