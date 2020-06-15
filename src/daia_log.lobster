// The daia_log module provides a facility for wrapping text with mingled
// textures.
// The `flow` function accepts a viewport size, line height, and a callback.
// It calls the callback once to measure, again to draw.
// The first pass finds all of the wrap points by anchoring the last
// known opportunity to wrap the current line, then accumulates text and
// textures, speculating whether it will surpass the width of the viewport.

import vec
import color

class flow_meter:
    max_width: float
    cursor: float
    last_space: float
    since_space: float
    since_wrap: float
    breaks: [float]

    def flow_sp():
        if cursor >= max_width:
            // wrap.
            breaks.push(last_space)
            cursor = since_space
            since_space = since_wrap
            since_wrap = 0.0
            last_space = 0.0
        else: if since_wrap > 0:
            // begin speculating about next block after a space.
            last_space = cursor
            since_space = float(gl_text_size(" ")).x
            since_wrap = 0.0
            cursor += since_space

    def flow_word(w):
        let width = float(gl_text_size(w)).x
        cursor += width
        since_space += width
        since_wrap += width

    def flow_texture(tex):
        let width = float(gl_get_font_size())
        cursor += width
        since_space += width
        since_wrap += width

    def flow_text(str):
        let words = tokenize(str, " ", " ")
        for(words) w, i:
            if i > 0: flow_sp()
            flow_word(w)

    def close():
        breaks.push(last_space)

class flow_writer:
    breaks: [float]
    break_index: int
    line_height: float
    size: xy_f
    cursor: xy_f
    last_space: xy_f

    def flow_sp():
        if cursor.x >= breaks[break_index] - 1:
            // wrap
            cursor = cursor * xy_y + xy_y * line_height
            last_space = cursor
            break_index++
        else: if cursor != last_space:
            // advance one space
            cursor += float(gl_text_size(" ")) * xy_x
            last_space = cursor

    def flow_word(w):
        let s = float(gl_text_size(w))
        gl_translate(cursor):
            gl_text(w)
        cursor += s * xy_x

    def flow_texture(tex):
        let s= xy_1 * float(gl_get_font_size())
        gl_set_shader("textured")
        gl_set_primitive_texture(0, tex)
        gl_translate(cursor):
            gl_color(color_white):
                gl_rect(s)
        cursor += s * xy_x

    def flow_text(str):
        let words = tokenize(str, " ", " ")
        for(words) w, i:
            if i > 0: flow_sp()
            flow_word(w)

def flow(max_size, line_height, fun, backdrop):
    let meter = flow_meter{
        max_width: max_size.x,
        cursor: 0.0,
        last_space: 0.0,
        since_space: 0.0,
        since_wrap: 0.0,
        breaks: [],
    }
    fun(meter)
    meter.close()

    // // debug break lines:
    // for(meter.breaks) break, i:
    //     gl_color(color_red):
    //         gl_line(xy{ break, line_height * float(i) }, xy{ break, line_height * float(i + 1)}, 1)

    let writer = flow_writer{
        breaks: meter.breaks,
        break_index: 0,
        line_height: line_height,
        size: xy_0,
        cursor: xy_0,
        last_space: xy_0,
    }

    backdrop(xy{ max_size.x, length(meter.breaks) * line_height }):
        fun(writer)
