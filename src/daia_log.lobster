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
    line_height: float
    // Position of cursor within a line, including any advanced spaces and all
    // the material that might be on this line or the next if it must wrap
    // at the last seen space.
    cursor: float
    // Cursor position before the last seen space, or 0 immediately after a
    // line wrap.
    // This will be the final break if the flow stops.
    last_space: float
    // How far the cursor has advanced since *before* the last seen space.
    after_space: float
    // How far the cursor has advanced since *after* the last seen space.
    before_space: float
    breaks: [float]
    longest_line: float

    def flow_sp():
        if cursor >= max_width:
            // wrap.
            breaks.push(last_space)
            longest_line = max(longest_line, last_space)
            // carry.
            cursor = before_space
            last_space = after_space
            after_space = cursor // was before_space
            before_space = last_space // was after_space
        else: if before_space > 0.0:
            // begin speculating about next block after a space.
            last_space = cursor
            before_space = 0.0
            after_space = float(gl_text_size(" ")).x
            cursor += after_space

    def flow_word(w):
        let width = float(gl_text_size(w)).x
        cursor += width
        after_space += width
        before_space += width

    def flow_texture(tex):
        let width = float(gl_get_font_size())
        cursor += width
        after_space += width
        before_space += width

    def flow_text(str):
        if substring(str, 0, 1) == " ":
            flow_sp()
        let words = tokenize(str, " ", " ")
        for(words) w, i:
            if i > 0: flow_sp()
            flow_word(w)
        if substring(str, str.length - 1, 1) == " ":
            flow_sp()

    def flow_close():
        if cursor > 0.0:
            breaks.push(cursor)
            longest_line = max(longest_line, cursor)

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
        if substring(str, 0, 1) == " ":
            flow_sp()
        let words = tokenize(str, " ", " ")
        for(words) w, i:
            if i > 0: flow_sp()
            flow_word(w)
        if substring(str, str.length - 1, 1) == " ":
            flow_sp()

def flow(max_size, line_height, fun, backdrop):
    let meter = flow_meter{
        max_width: max_size.x,
        line_height: line_height,
        cursor: 0.0,
        last_space: 0.0,
        after_space: 0.0,
        before_space: 0.0,
        breaks: [],
        longest_line: 0.0,
    }
    fun(meter)
    meter.flow_close()

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

    backdrop(xy{meter.longest_line, meter.breaks.length * line_height}):
        fun(writer)
