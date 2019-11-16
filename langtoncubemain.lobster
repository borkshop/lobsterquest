import langton
import vec
import color
import cube
import util3d
import texture
import std

let hz = 3
let size = 13
let count = 5
let rules = [1, -1, 0]
let neighborhoods, points = langton_new_round_square_topology(size)
let w = langton_new_world(neighborhoods, count, rules)
let v = langton_new_square_view(size, points, color_dark_grey, color_grey)

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

let tex = gl_load_texture("data/textures/lobster.jpg")
assert tex

// Use the frame buffer to render a unique texture for each face of the cube,
// with its number.
// We use white on grey since we can use these as color multipliers where we
// render the mesh.
let detail = 256
let face_textures = map(6):
    gl_create_blank_texture(xy_1i * detail, color_black, texture_format_none)

let face_meshes = cube_new_face_meshes(cube_new_face_vertices())

// Rotate the camera to place the origin vertex of the cube in the center of
// the view.
camera_pitch = 45
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

    for(6) i:
        render_to_texture(face_textures[i], xy_1i * detail, false, nil, 0):
            gl_scale(xy_1 * detail)
            v.draw(w, tween, tex)

    gl_clear(color_dark_grey / 2)
    gl_cursor(false)
    gl_perspective(60, 0.1, 1000)

    camera_GPS_update("w", "a", "s", "d", 2.0, 4.0, 4.0)
    camera_FPS_view()

    gl_light(camera_position, xy { 128.0, 0.1 })

    cube_draw(face_meshes, map(6): color_white, face_textures)
