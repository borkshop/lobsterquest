import vec
import color
import texture
import topology
import cube
import util3d

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

// cube vertices
let cv = map(8) c: xyz_v(map(3) i: float(c & (1 << (2 - i)) != 0))
let camera_pitches = [0, 0, 90, -90, 0, 0]
let camera_yaws = [-90, 0, 0, 180, 180, 90]
let camera_origins = [cv[3], cv[1], cv[0], cv[5], cv[7], cv[5]]
let camera_majors = [-cv[2], cv[4], cv[4], -cv[4], -cv[4], cv[2]]
let camera_minors = [-cv[1], -cv[1], cv[2], cv[2], -cv[1], -cv[1]]

let pitch_transitions = [
    [-90, 0, 90, 0],
    [-90, 0, 90, 0],
    [-90, -90, -90, -90],
    [90, 90, 90, 90],
    [-90, 0, 90, 0],
    [-90, 0, 90, 0],
]

let yaw_transitions = [
    [-90, 90, 90, -90],
    [180, 90, 0, -90],
    [0, 90, 180, -90],
    [180, 90, 0, -90],
    [0, 90, 180, -90],
    [90, 90, -90, -90],
]

struct camera_location:
    position:xyz_f
    elevation:float
    yaw:float
    pitch:float

    def camera_lerp(that:camera_location, ratio:float):
        return camera_location{
            position: lerp(this.position, that.position, ratio),
            elevation: lerp(this.elevation, that.elevation, ratio),
            yaw: lerp(this.yaw, that.yaw, ratio),
            pitch: lerp(this.pitch, that.pitch, ratio),
        }

class point_of_view:
    size:int
    area:int
    neighbors:[[int]]

    index:int
    prev:camera_location
    next:camera_location

    def camera_go(dir, elevation):
        let index1 = index
        let index2 = neighbors[index1][dir]
        index = index2

        let face1 = index1 / area
        let face2 = index2 / area

        let yaw = next.yaw + if face1 == face2: 0
        else: yaw_transitions[face1][dir]

        let pitch = next.pitch + if face1 == face2: 0
        else: pitch_transitions[face1][dir]

        let within = index2 % area
        let center = float(xy_i{ within % size, within / size }) + xy_1/2
        let major = camera_majors[face2]
        let minor = camera_minors[face2]
        let position = camera_origins[face2] -
            xyz_1/2 +
            (major * center.x + minor * center.y) / size

        next = camera_location{
            position: position,
            elevation: elevation,
            yaw: yaw,
            pitch: pitch,
        }

    def camera_position(location):
        return location.position + vecfromyawpitch(location.yaw, location.pitch, -location.elevation, 0.0)

    def update_camera():
        prev = camera_lerp(prev, next, 1 - pow(0.05, gl_delta_time()))
        camera_position = camera_position(prev)
        camera_yaw = prev.yaw
        camera_pitch = prev.pitch

def camera_init(size, area, index, elevation):
    let face = index / area
    let within = index % area
    let center = float(xy_i{ within % size, within / size }) + xy_1/2
    let pitch = camera_pitches[face]
    let yaw = camera_yaws[face]
    let major = camera_majors[face]
    let minor = camera_minors[face]
    let position = camera_origins[face] -
        xyz_1/2 +
        (major * center.x + minor * center.y) / size
    return camera_location{
        position: position,
        elevation: elevation,
        yaw: yaw,
        pitch: pitch,
    }

def new_pov(size, neighbors, index, elevation):
    let area = size * size
    let at = camera_init(size, area, index, elevation)
    let p = point_of_view{
        size: size,
        area: area,
        index: index,
        prev: at,
        next: at,
        neighbors: neighbors,
    }
    return p

do():
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
