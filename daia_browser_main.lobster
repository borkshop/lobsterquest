// This program demonstrates the daia_browser module,
// allowing the viwer to walk around on the surface of a 7x7x7 cube, planting
// trees.
// The camera hovers directly overhead as the player wanders the surface of the
// cube, with an exponential animated pivot when transitioning between faces.
//
// H,J,K,L to move.
// F to fill.
// D to dig.
// Q to quit.

import vec
import color
import texture
import daia_draw
import daia_browser
import daia_topology
import util3d
import brand
import sheets

fatal(gl_window("Cube Surface Browser", 515, 515))

let face_meshes = new_daia_face_meshes(new_daia_face_vertices())

let detail = 500
let size = 7
let sprites = load_sheet_sprites()
let mode = new_daia_mode(detail, size, 0, 1, sprites, face_meshes, face_colors, face_highlight_colors)
mode.fill_tile = tile_pine_tree

while gl_frame():
    if gl_button("q") == 0 or gl_button("escape") == 0:
        return from program
    mode.daia_input()
    mode.daia_draw()
