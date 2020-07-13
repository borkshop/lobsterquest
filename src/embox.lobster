
def embox(size, corner_size, rounded_corners):
    gl_set_shader("textured")

    // body
    gl_set_primitive_texture(0, rounded_corners[15])
    gl_rect(size)

    // northwest
    gl_translate(-corner_size):
        gl_set_primitive_texture(0, rounded_corners[1])
        gl_rect(corner_size)
    // northeast
    gl_translate(size * xy_x - corner_size * xy_y):
        gl_set_primitive_texture(0, rounded_corners[2])
        gl_rect(corner_size)
    // southwest
    gl_translate(size * xy_y - corner_size * xy_x):
        gl_set_primitive_texture(0, rounded_corners[4])
        gl_rect(corner_size)
    // southeast
    gl_translate(size):
        gl_set_primitive_texture(0, rounded_corners[8])
        gl_rect(corner_size)

    // north
    gl_translate(corner_size * -xy_y):
        gl_set_primitive_texture(0, rounded_corners[3])
        gl_rect(size * xy_x + corner_size * xy_y)
    // east
    gl_translate(size * xy_x):
        gl_set_primitive_texture(0, rounded_corners[10])
        gl_rect(size * xy_y + corner_size * xy_x)
    // south
    gl_translate(size * xy_y):
        gl_set_primitive_texture(0, rounded_corners[12])
        gl_rect(size * xy_x + corner_size * xy_y)
    // west
    gl_translate(-corner_size * xy_x):
        gl_set_primitive_texture(0, rounded_corners[5])
        gl_rect(size * xy_y + corner_size * xy_x)

