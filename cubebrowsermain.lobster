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

let face_meshes = cube_new_face_meshes(cube_new_face_vertices())

let detail = 500
let size = 7
let sprites = load_sheet_sprites()
let mode = new_daia_mode(detail, size, 0, 1, sprites, face_meshes, face_colors, face_highlight_colors)
mode.fill_tile = tile_pine_tree

while gl_frame():
    mode.daia_input()
    mode.daia_draw()

