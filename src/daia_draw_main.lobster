// Demonstrates rendering the faces of a Daia cube, numbered and colored
// according to the corresponding pips on right handed dice, oriented and
// colored according to the Daia aesthetic.

import vec
import color
import texture
import util3d
import daia_draw

fatal(gl_window("Daia Cube", 515, 515))
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

// Use the frame buffer to render a unique texture for each face of the cube,
// with its number.
// We use white on grey since we can use these as color multipliers where we
// render the mesh.
let detail = 256
let face_textures = map(6):
    gl_create_blank_texture(xy_1i * detail, color_black, texture_format_none)
for(6) i:
    render_to_texture(face_textures[i], xy_1i * detail, false, nil, 0):
        let label = string(i+1)
        gl_set_font_size(detail/2)
        let size = gl_text_size(label)
        gl_translate(xy_1 * float(detail) / 2 - float(size) / 2)
        gl_clear(color_grey)
        gl_color(color_white)
        gl_text(label)

let face_meshes = new_daia_face_meshes(new_daia_face_vertices())

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
    gl_clear(color_dark_grey)
    gl_cursor(false)
    gl_perspective(60, 0.1, 1000)

    camera_GPS_update("w", "a", "s", "d", 2.0, 4.0, 4.0)
    camera_FPS_view()

    gl_light(camera_position, xy { 128.0, 0.1 })

    draw_daia(face_meshes, face_colors, face_textures)
