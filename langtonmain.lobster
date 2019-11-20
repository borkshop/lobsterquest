import langton
import color
import vec
import std
import sprites
import sheets

fatal(gl_window("Langton\'s Ents", 512, 512, 0))

let tex = entity_texture(tile_pine_tree)

// center_unit_square projects a unit square coordinate system over
// the center of the window, regardless of its aspect ratio.
def center_unit_square():
    let size = float(gl_window_size())
    let scale = xy_1 * min(size)
    gl_translate((size - scale) / 2)
    gl_scale(scale)

do():
    let hz = 1
    let size = 10
    let count = 10
    let rules = [1, -1, 0]
    let neighborhoods, turns = langton_new_round_square_topology(size)
    let w = langton_new_world(neighborhoods, turns, count, rules)
    let first_rule_color = color{ 0.75, 0.75, 0.5, 1.0 }
    let last_rule_color = color{ 0.5, 0.3, 0.2, 1.0 }
    let v = langton_new_square_view(size, neighborhoods, first_rule_color, last_rule_color)

    w.tick()
    var start = gl_time()
    def next():
        let now = gl_time()
        let tween = (now - start) * hz
        if tween < 1.0:
            return tween
        start = now
        w.tick()
        return 0.0

    while gl_frame() and gl_button("escape") != -1:
        let tween = next()
        gl_clear(first_rule_color)
        center_unit_square()
        v.draw(w, 0, tween, tex)
