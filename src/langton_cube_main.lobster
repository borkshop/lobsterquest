// This is a demonstration of the same cellular automaton
// as langton_main.lobster, Langton's Ents, except using the Daia
// world cubic topology instead of a tesselated square topology.
// This shows how we can use the same concept of 2D topologies for the
// simulation, since the simulation operates exclusively in terms of an array
// and adjacency matrix for cardinal directions.

import langton
import vec
import color
import daia_draw
import daia_topology
import texture
import std
import sprites
import sheets
import topology
import brand
import util3d

let hz = 2
let size = 3
let area = size * size
let count = 12
let rules = [1, -1, 0]
let neighborhoods, turns = new_daia_topology(size)
let w = langton_new_world(neighborhoods, turns, count, rules)
let first_rule_color = dark_brown
let last_rule_color = dark_green
let v = langton_new_square_view(size, neighborhoods, turns, first_rule_color, last_rule_color)

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

fatal(gl_window("Langton Cube", 515, 515))

let sheet_sprites = load_sheet_sprites()

let tex = sheet_sprites.get_texture(tile_sprite_id[tile_pine_tree])
assert tex

// Use the frame buffer to render a unique texture for each face of the cube,
// with its number.
// We use white on grey since we can use these as color multipliers where we
// render the mesh.
let detail = 256
let face_textures = map(6):
    gl_create_blank_texture(xy_1i * detail, color_black, texture_format_none)

let face_meshes = new_daia_face_meshes(new_daia_face_vertices())

// Rotate the camera to place the origin vertex of the cube in the center of
// the view.
camera_pitch = 30
camera_yaw = -45

// This demo is able to use camera_FPS_view but uses a different control model
// to move the camera about the origin at a fixed “elevation”.
def camera_GPS_update(upkey, leftkey, downkey, rightkey, elevation:float, mousesens:float, keyspeed:float):
    let long = (gl_button(upkey) >= 1) - (gl_button(downkey) >= 1)
    let lat = (gl_button(rightkey) >= 1) - (gl_button(leftkey) >= 1)
    camera_pitch -= gl_mouse_delta(0).y / mousesens + long * keyspeed
    camera_yaw -= gl_mouse_delta(0).x / mousesens - lat * keyspeed
    camera_pitch = min(85.0, max(-85.0, camera_pitch))
    camera_position = vecfromyawpitch(camera_yaw, camera_pitch, -elevation, 0.0)

while gl_frame() and gl_button("escape") != -1:
    let tween = next()

    // Render each face texture of the cube.
    for(6) i:
        render_to_texture(face_textures[i], xy_1i * detail, false, nil, 0):
            gl_scale(xy_1 * detail)
            v.draw(w, i * area, tween, tex)

    gl_clear(color_dark_grey / 2)
    gl_cursor(false)
    gl_perspective(60, 0.1, 1000)

    camera_GPS_update("w", "a", "s", "d", 2.0, 4.0, 4.0)
    camera_FPS_view()

    draw_daia(face_meshes, map(6): color_white, face_textures)
