import vec
import color
import texture
import topology
import cube
import util3d
import cubebrowser

fatal(gl_window("Lobster Cube", 515, 515))
check(gl_set_font_name("data/fonts/Droid_Sans/DroidSans.ttf"), "can\'t load font")

// Colors are arranged such that CMY are about the origin and RGB on the polar
// opposites.
// Colors on opposite faces are also opposite hues.
let face_colors = [
    color_purple,     // M
    color_olive,      // Y
    color_teal,       // C
    color_dark_red,   // R
    color_dark_blue,  // G
    color_dark_green, // B
]

let detail = 500
let face_textures = map(6):
    gl_create_blank_texture(xy_1i * detail, color_grey, texture_format_none)

let face_meshes = cube_new_face_meshes(cube_new_face_vertices())

let size = 5
let neighbors = new_daia_topology(size)
let pov = new_daia_vantage(size, neighbors, 0, 1)

while gl_frame():
    def go(dir):
        pov.camera_go(dir, 1.5)

    if gl_button("k") == 1: go(0)
    if gl_button("l") == 1: go(1)
    if gl_button("j") == 1: go(2)
    if gl_button("h") == 1: go(3)
    if gl_button("escape") == 1: return from program
    if gl_button("q") == 1: return from program

    for(6) i:
        render_to_texture(face_textures[i], xy_1i * detail, false, nil, 0):
            gl_clear(color_grey)
            gl_color(color_white)
            gl_scale(xy_1 * detail)
            pov.draw_cursor_on_face(i):
                // gl_translate(xy_1/2)
                // gl_scale(1.25)
                // gl_translate(xy_1/-2)
                unit_box(0.05)

    gl_clear(color_dark_grey)
    gl_cursor(false)
    gl_perspective(60, 0.1, 1000)

    pov.update()
    camera_FPS_view()

    gl_light(camera_position, xy { 128.0, 0.1 })

    gl_translate(-xyz_1/2)
    gl_set_shader("textured")
    for(6) i:
        // The texture colors are multiplied by the color in context.
        // Since the texture on our mesh is white on black, we can change the
        // white to a unique color for each face of the world.
        gl_color(face_colors[i])
        gl_set_primitive_texture(0, face_textures[i])
        gl_render_mesh(face_meshes[i])
