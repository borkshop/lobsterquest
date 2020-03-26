import vec

let corners = [xy_0, xy_x, xy_1, xy_y]
def unit_box(thickness):
    for(4) start:
        let end = (start + 1) & 3
        gl_line(corners[start], corners[end], thickness)
