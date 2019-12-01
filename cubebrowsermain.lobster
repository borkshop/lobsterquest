import vec
import color
import texture
import topology
import cube
import util3d
import cubebrowser

fatal(gl_window("Lobster Cube", 515, 515))
check(gl_set_font_name("data/fonts/Droid_Sans/DroidSans.ttf"), "can\'t load font")

// Use the frame buffer to render a unique texture for each face of the cube,
// with its number.
// We use white on grey since we can use these as color multipliers where we
// render the mesh.
let detail = 256
let face_textures = map(6) i:
    render_to_texture(nil, xy_1i * detail, false, nil, 0):
        let label = string(i+1)
        gl_set_font_size(detail/2)
        let size = gl_text_size(label)
        gl_translate(xy_1 * float(detail) / 2 - float(size) / 2)
        gl_clear(color_grey)
        gl_color(color_white)
        gl_text(label)

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

let face_meshes = cube_new_face_meshes(cube_new_face_vertices())

let size = 3
let neighbors = new_daia_topology(size)
let camera_pov = new_pov(size, neighbors, 0, 1)

while gl_frame():
    gl_clear(color_dark_grey)
    gl_cursor(false)
    gl_perspective(60, 0.1, 1000)

    def go(dir):
        camera_pov.camera_go(dir, 1)

    if gl_button("k") == 1: go(0)
    if gl_button("l") == 1: go(1)
    if gl_button("j") == 1: go(2)
    if gl_button("h") == 1: go(3)
    if gl_button("escape") == 1: return from program
    if gl_button("q") == 1: return from program

    camera_pov.update_camera()
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
