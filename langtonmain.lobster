import langton
import color
import vec
import std

fatal(gl_window("Langosta de Langton", 512, 512, 0))

let tex = gl_load_texture("data/textures/lobster.jpg")
assert tex

// center_unit_square projects a unit square coordinate system over
// the center of the window, regardless of its aspect ratio.
def center_unit_square():
    let size = float(gl_window_size())
    let scale = xy_1 * min(size)
    gl_translate((size - scale) / 2)
    gl_scale(scale)

do():
    let hz = 3
    let size = 9
    let count = 5
    let rules = [1, -1, 0]
    let neighborhoods, points = langton_new_round_square_topology(size)
    let w = langton_new_world(neighborhoods, count, rules)
    let first_rule_color = color_dark_grey
    let last_rule_color = color_grey
    let v = langton_new_square_view(size, points, first_rule_color, last_rule_color)

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
        v.draw(w, tween, tex)
