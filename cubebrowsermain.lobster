import vec
import color
import texture
import topology
import cube
import util3d
import cubebrowser
import brand
import sheets

fatal(gl_window("Lobster Cube", 515, 515))
check(gl_set_font_name("data/fonts/Droid_Sans/DroidSans.ttf"), "can\'t load font")

// Colors are arranged such that CMY are about the origin and RGB on the polar
// opposites.
// Colors on opposite faces are also opposite hues.
let face_colors = [
    light_purple,    // M
    light_orange,    // Y
    light_blue,      // C
    color_white*0.8, // R
    dark_blue,       // B
    dark_green,      // G
]

let face_highlight_colors = [
    dark_purple,
    light_brown,
    dark_blue,
    light_red,
    light_blue,
    light_brown,
]

let detail = 500
let face_textures = map(6):
    gl_create_blank_texture(xy_1i * detail, color_grey, texture_format_none)

let face_meshes = cube_new_face_meshes(cube_new_face_vertices())

let size = 7
let area = size * size
let elevation = 1
let neighbors = new_daia_topology(size)
let pov = new_daia_vantage(size, neighbors, 0, 1)

let tiles = map(6*area): tile_none
let sprites = load_sheet_sprites()
let fill_tile = tile_pine_tree

while gl_frame():
    def go(dir):
        pov.camera_go(dir, elevation)

    if gl_button("k") == 1: go(0)
    if gl_button("l") == 1: go(1)
    if gl_button("j") == 1: go(2)
    if gl_button("h") == 1: go(3)
    if gl_button("f") == 1:
        tiles[pov.index] = fill_tile
    if gl_button("d") == 1:
        tiles[pov.index] = tile_none
    if gl_button("escape") == 1: return from program
    if gl_button("q") == 1: return from program

    for(6) face:
        render_to_texture(face_textures[face], xy_1i * detail, false, nil, 0):
            gl_scale(xy_1 * detail)
            gl_clear(face_colors[face])

            gl_set_shader("textured")
            gl_scale(xy_1 / size):
                let face_offset = area * face
                for(area) index_within_face:
                    let index = face_offset + index_within_face
                    let tile_id = tiles[index]
                    if tile_id > 0:
                        let sprite_id = tile_sprite_id[tile_id]
                        gl_set_primitive_texture(0, sprites.get_texture(sprite_id))
                        gl_color(color_white)
                        let v = float(xy{ index_within_face % size, index_within_face / size })
                        gl_translate(v):
                            gl_unit_square()

            gl_set_shader("color")
            pov.draw_cursor_on_face(face):
                gl_color(face_highlight_colors[face])
                gl_translate(xy_1/2)
                gl_scale(1.25)
                gl_translate(xy_1/-2)
                unit_box(0.05)

    gl_clear(color_dark_grey)
    gl_cursor(false)
    gl_perspective(60, 0.1, 1000)

    pov.update()
    camera_FPS_view()

    gl_light(camera_position, xy { 128.0, 0.1 })

    gl_translate(-xyz_1/2)
    gl_set_shader("textured")
    for(6) face:
        // The texture colors are multiplied by the color in context.
        // Since the texture on our mesh is white on black, we can change the
        // white to a unique color for each face of the world.
        gl_color(color_white)
        gl_set_primitive_texture(0, face_textures[face])
        gl_render_mesh(face_meshes[face])
