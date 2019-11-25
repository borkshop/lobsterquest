import vec
import color
import texture
import topology
import cube

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

// Rotate the camera to place the origin vertex of the cube in the center of
// the view.
camera_pitch = 0
camera_yaw = -90

struct loc:
    index:int
    elevation:float
    yaw:float
    pitch:float

class pov:
    size:int
    area:int
    neighbors:[[int]]
    start:float
    duration:float
    prev:loc
    next:loc

    def camera_go(dir, elevation, dur):
        let index1 = next.index
        let index2 = neighbors[next.index][dir]

        let face1 = index1 / area
        let face2 = index2 / area

        let yaw = next.yaw + if face1 == face2: 0
        else: yaw_transitions[face1][dir]

        let pitch = next.pitch + if face1 == face2: 0
        else: pitch_transitions[face1][dir]

        let temp = loc{
            index: index2,
            elevation: elevation,
            yaw: yaw,
            pitch: pitch,
        }
        prev = next
        next = temp
        start = gl_time()
        duration = dur

    def in_transit():
        return start + duration > gl_time()

    def camera_position(location):
        let face = location.index / area
        let within = location.index % area
        let at = float(xy_i{ within % size, within / size }) + xy_1/2
        let major = camera_majors[face]
        let minor = camera_minors[face]
        let origin = camera_origins[face] - xyz_1/2 + (major * at.x + minor * at.y) / size
        return origin + vecfromyawpitch(location.yaw, location.pitch, -location.elevation, 0.0)

    def update_camera():
        let tween = clamp(0, 1, (gl_time() - start)/duration)
        let position1 = camera_position(prev)
        let position2 = camera_position(next)
        camera_position = lerp(position1, position2, tween)
        camera_yaw = lerp(prev.yaw, next.yaw, tween)
        camera_pitch = lerp(prev.pitch, next.pitch, tween)

def camera_init(size, area, index, elevation):
    let face = index / area
    let within = index % area
    let at = float(xy_i{ within % size, within / size }) + xy_1/2
    let pitch = camera_pitches[face]
    let yaw = camera_yaws[face]
    return loc{
        index: index,
        elevation: elevation,
        yaw: yaw,
        pitch: pitch,
    }

def new_pov(size, neighbors, index, elevation):
    let area = size * size
    let at = camera_init(size, area, index, elevation)
    return pov{
        size: size,
        area: area,
        prev: at,
        next: at,
        start: gl_time(),
        duration: 1,
        neighbors: neighbors,
    }

do():
    let size = 3
    let neighbors = new_daia_topology(size)
    let camera_pov = new_pov(size, neighbors, 0, 1)

    while gl_frame() and gl_button("escape") != -1:
        gl_clear(color_dark_grey)
        gl_cursor(false)
        gl_perspective(60, 0.1, 1000)

        def go(dir):
            if camera_pov.in_transit():
                return
            camera_pov.camera_go(dir, 1, 0.5)

        if gl_button("k") >= 1: go(0)
        if gl_button("l") >= 1: go(1)
        if gl_button("j") >= 1: go(2)
        if gl_button("h") >= 1: go(3)

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
