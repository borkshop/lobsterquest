import vec
import util3d
import color
import game_draw
import daia_topology
import sheets

let cube_vertices = map(8) c:
    xyz_v(map(3) i: float(c & (1 << (2 - i)) != 0))

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

class daia_mode:
    detail: int
    face_meshes: [resource]
    face_textures: [resource]
    face_colors: [color]
    face_highlight_colors: [color]
    pov: daia_vantage
    tiles: [tile_entity_id]
    sprites: sprite_atlas
    fill_tile: tile_entity_id

    def daia_input():
        def go(dir):
            pov.camera_go(dir, pov.next.elevation)

        if gl_button("k") == 1: go(0)
        if gl_button("l") == 1: go(1)
        if gl_button("j") == 1: go(2)
        if gl_button("h") == 1: go(3)
        if gl_button("f") == 1:
            tiles[pov.index] = fill_tile
        if gl_button("d") == 1:
            tiles[pov.index] = tile_none

    def daia_draw():
        for(6) face:
            render_to_texture(face_textures[face], xy_1i * detail, false, nil, 0):
                gl_scale(xy_1 * detail)
                gl_clear(face_colors[face])

                gl_set_shader("textured")
                gl_scale(xy_1 / pov.size):
                    let face_offset = pov.area * face
                    for(pov.area) index_within_face:
                        let index = face_offset + index_within_face
                        let tile_id = tiles[index]
                        if tile_id > 0:
                            let sprite_id = tile_sprite_id[tile_id]
                            gl_set_primitive_texture(0, sprites.get_texture(sprite_id))
                            gl_color(color_white)
                            let v = float(xy{ index_within_face % pov.size, index_within_face / pov.size })
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

def new_daia_mode(detail, size, index, elevation, sprites, face_meshes, face_colors, face_highlight_colors):
    let area = size * size
    let neighbors = new_daia_topology(size)
    let face_textures = map(6):
        gl_create_blank_texture(xy_1i * detail, color_clear, texture_format_none)
    return daia_mode{
        detail: detail,
        face_meshes: face_meshes,
        face_textures: face_textures,
        face_colors: face_colors,
        face_highlight_colors: face_highlight_colors,
        pov: new_daia_vantage(size, neighbors, index, elevation),
        tiles: map(6*area): tile_none,
        sprites: sprites,
        fill_tile: tile_none,
    }
