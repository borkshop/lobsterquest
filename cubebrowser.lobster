import vec
import util3d
import game_draw
import topology

let cube_vertices = map(8) c: xyz_v(map(3) i: float(c & (1 << (2 - i)) != 0))

def cube_vertex(i):
    if i < 0: return -cube_vertices[-i]
    return cube_vertices[i]

let camera_pitches = [0, 0, 90, -90, 0, 0]
let camera_yaws = [-90, 0, 0, 180, 180, 90]
let camera_origins = map([3, 1, 0, 5, 7, 5]): cube_vertex(_)
let camera_majors = map([-2, 4, 4, -4, -4, 2]): cube_vertex(_)
let camera_minors = map([-1, -1, 2, 2, -1, -1]): cube_vertex(_)

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

class daia_vantage:
    size:int
    area:int
    neighbors:[[int]]

    index:int
    prev:camera_location
    next:camera_location

    cursor_prev:xy_f
    cursor_next:xy_f
    cursor_face:int

    def camera_go(dir, elevation):
        let index1 = index
        let index2 = neighbors[index1][dir]
        index = index2

        let face1 = index1 / area
        let face2 = index2 / area
        let pivot = face1 != face2

        let yaw = next.yaw + yaw_transitions[face1][dir] * pivot
        let pitch = next.pitch + pitch_transitions[face1][dir] * pivot

        let within = index2 % area
        let cursor = float(xy_i{ within % size, within / size })
        let center = cursor + xy_1/2
        let major = camera_majors[face2]
        let minor = camera_minors[face2]
        let position = camera_origins[face2] - xyz_1/2 +
            (major * center.x + minor * center.y) / size

        cursor_next = cursor
        if pivot:
            let neighbor = daia_unit_neighborhoods[face2].find() face: face == face1
            let offset = float(cardinal_directions[neighbor])
            let turn = daia_unit_turns[face2][neighbor]
            cursor_prev = offset * size +
                rotate2D(cursor_prev - size/2, turn * -90) + size/2
            cursor_face = face2

        next = camera_location{
            position: position,
            elevation: elevation,
            yaw: yaw,
            pitch: pitch,
        }

    def camera_position(location):
        return location.position + vecfromyawpitch(location.yaw, location.pitch, -location.elevation, 0.0)

    def update():
        prev = camera_lerp(prev, next, 1 - pow(0.1, gl_delta_time()))
        cursor_prev = lerp(cursor_prev, cursor_next, 1 - pow(0.01, gl_delta_time()))
        camera_position = camera_position(prev)
        camera_yaw = prev.yaw
        camera_pitch = prev.pitch

    def draw_cursor_on_face(face, fun):
        if face == cursor_face:
            gl_scale(xy_1 / size)
            gl_translate(cursor_prev)
            fun()
        else: if face + cursor_face != 5:
            let neighbor = daia_unit_neighborhoods[cursor_face].find(): face == _
            let offset = float(cardinal_directions[neighbor])
            let turn = daia_unit_turns[cursor_face][neighbor]
            gl_scale(xy_1 / size)
            gl_translate(rotate2D(cursor_prev - xy_1/2 - size/2, turn * 90) + xy_1/2 + size/2 - offset * size)
            fun()

def init_daia_camera_location(size, area, index, elevation):
    let face = index / area
    let within = index % area
    let cursor = float(xy_i{ within % size, within / size })
    let center = cursor + xy_1/2
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
    }, cursor, face

def new_daia_vantage(size, neighbors, index, elevation):
    let area = size * size
    let camera, cursor, face = init_daia_camera_location(size, area, index, elevation)
    return daia_vantage{
        size: size,
        area: area,
        index: index,
        prev: camera,
        next: camera,
        cursor_prev: cursor,
        cursor_next: cursor,
        cursor_face: face,
        neighbors: neighbors,
    }

