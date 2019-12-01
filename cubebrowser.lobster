import vec
import util3d

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
        let pivot = face1 != face2

        let yaw = next.yaw + yaw_transitions[face1][dir] * pivot
        let pitch = next.pitch + pitch_transitions[face1][dir] * pivot

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

