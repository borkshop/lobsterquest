import color
import vec
import sheets
import sprites

def mod(n, m):
    // if m & (m - 1) != 0: return n & m
    return (n % m + m) % m

let corners = [xy_0, xy_x, xy_1, xy_y]
def unit_box(thickness):
    for(4) start:
        let end = (start + 1) & 3
        gl_line(corners[start], corners[end], thickness)

class point_of_view:
    cursor: xy_i
    retical: xy_f
    camera: xy_f
    tile_size: int

    def update():
        retical = lerp(retical, float(cursor), pow(0.30, 1 + gl_delta_time()/10))
        camera = lerp(camera, retical, pow(0.05, 1 + gl_delta_time()/20))

    def gl_translate_for_visible_cells(fun):
        gl_translate(-xy_1/2 - camera):
            let quadrant = gl_window_size()/tile_size/2 + xy_1i*2
            let center = floor(camera)
            forxy(quadrant*2) v:
                let o = v - quadrant + center
                gl_translate(float(o)):
                    fun(o)

class world:
    size: int
    colors: [color]
    tiles: [tile_entity_id]

    def index(v):
        return mod(v.x, size) + size * mod(v.y, size)
    def neighbor(v, d):
        return v + cardinal_directions[d]
    def color(i):
        return colors[i]
    def set_color(i, c):
        colors[i] = c
    def tile(i):
        return tiles[i]
    def set_tile(i, t):
        tiles[i] = t
    def label(i):
        return ""

def new_world(size):
    let area = size * size
    return world{
        size: size,
        colors: map(area): color_clear,
        tiles: map(area): tile_none,
    }

class tile_menu_world:
    size: int

    def index(v):
        if v.x != 0: return 0
        if v.y < 0: return 0
        if v.y >= size: return 0
        return v.y
    def neighbor(v, d):
        return v + cardinal_directions[d]
    def color(i):
        return color_white
    def set_color(i, c):
        nil
    def tile(i):
        return i
    def set_tile(i, t):
        nil
    def label(i):
        return string(tile_entity_id(i))

enum map_command:
    map_command_escape
    map_command_enter
    map_command_exit
    map_command_north
    map_command_west
    map_command_east
    map_command_south
    map_command_origin
    map_command_fill
    map_command_raze

class map_key_command:
    key:string
    command:map_command

let map_commands = [
    map_key_command{ "escape", map_command_escape },
    map_key_command{ "return", map_command_enter },
    map_key_command{ "up", map_command_north },
    map_key_command{ "k", map_command_north },
    map_key_command{ "right", map_command_east },
    map_key_command{ "l", map_command_east },
    map_key_command{ "down", map_command_south },
    map_key_command{ "j", map_command_south },
    map_key_command{ "left", map_command_west },
    map_key_command{ "h", map_command_west },
    map_key_command{ "0", map_command_origin },
    map_key_command{ "f", map_command_fill },
    map_key_command{ "d", map_command_raze },
    map_key_command{ "q", map_command_exit },
]

enum cursor_style:
    cursor_style_hand
    cursor_style_box

class map_mode<world_type>:
    pov: point_of_view
    world: world_type
    sprites: sprite_atlas
    cursor_style: cursor_style
    fill_tile: tile_entity_id
    fill_color: color

    def invoke_map_command(command, exit, enter):
        switch command:
            case map_command_exit:
                exit()
            case map_command_enter:
                enter()
            case map_command_north:
                pov.cursor -= xy_yi
            case map_command_east:
                pov.cursor += xy_xi
            case map_command_south:
                pov.cursor += xy_yi
            case map_command_west:
                pov.cursor -= xy_xi
            case map_command_origin:
                pov.cursor = xy_0i
            case map_command_fill:
                let i = world.index(pov.cursor)
                world.set_color(i, fill_color)
                world.set_tile(i, fill_tile)
            case map_command_raze:
                let i = world.index(pov.cursor)
                world.set_color(i, fill_color)
                world.set_tile(i, tile_none)
            default:
                nil

    def map_input(exit, enter):
        for(map_commands) kc:
            let state = gl_button(kc.key)
            if state == 0: // wentup
                invoke_map_command(kc.command): exit()
                enter: enter()

    def map_draw():
        pov.update()

        gl_clear(color_white)
        gl_translate(float(gl_window_size())/2)
        gl_scale(pov.tile_size)

        pov.gl_translate_for_visible_cells() v:
            // transparency
            gl_color(color_black/15)
            gl_scale(xy_1/2):
                gl_unit_square()
                gl_translate(xy_1)
                gl_unit_square()

            // background color
            let i = world.index(v)
            let c = world.color(i)
            gl_color(c)
            gl_unit_square()

        gl_set_shader("textured")
        pov.gl_translate_for_visible_cells() v:
            // sprite
            let i = world.index(v)
            let tile_id = world.tile(i)
            if tile_id > 0:
                let sprite_id = tile_sprite_id[tile_id]
                gl_set_primitive_texture(0, sprites.tile_texture(sprite_id))
                gl_color(color_white)
                gl_unit_square()

        gl_set_shader("color")
        if gl_button("left shift") >= 1 || gl_button("right shift") >= 1:
            gl_set_font_size(16)
            pov.gl_translate_for_visible_cells() v:
                let text = ""+v.x+","+v.y
                let size = gl_text_size(text)
                gl_color(color_black)
                gl_translate(xy_1/2)
                gl_scale(1.0/50.0)
                gl_translate(float(size)/-2)
                gl_text(text)

        gl_color(color_black)
        gl_set_font_size(25)
        pov.gl_translate_for_visible_cells() v:
            gl_translate(xy_x * 1.5)
            let i = world.index(v)
            if i > 0:
                let text = world.label(i)
                if text != "":
                    let size = gl_text_size(text)
                    gl_scale(1.0/50.0)
                    gl_translate(xy_y * 25 - xy_y * float(size) / 2)
                    gl_text(text)

        switch cursor_style:
            case cursor_style_box:
                gl_translate(pov.retical - pov.camera):
                    gl_color(color_red)
                    gl_scale(1.25)
                    gl_translate(xy_1/-2)
                    unit_box(0.05)
            case cursor_style_hand:
                gl_set_shader("textured")
                gl_set_primitive_texture(0, sprites.tile_texture(ui_sprite_id[ui_point_east]))
                gl_translate(pov.retical - pov.camera):
                    gl_translate(xy_x*-1.5 - xy_y/2)
                    gl_unit_square()

enum mode:
    mode_navigating
    mode_selecting_tile

class world_map_mode : map_mode<world>
class tile_menu_mode : map_mode<tile_menu_world>

class root_mode:
    mode: mode
    map_mode: world_map_mode
    tile_menu_mode: tile_menu_mode

    def root_input(exit):
        switch mode:
            case mode_navigating:
                map_mode.map_input():
                    exit()
                enter:
                    mode = mode_selecting_tile
            case mode_selecting_tile:
                tile_menu_mode.map_input():
                    exit()
                enter:
                    mode = mode_navigating
                    map_mode.fill_tile = tile_entity_id(mod(tile_menu_mode.pov.cursor.y, length(tile_sprite_id)))

    def root_draw():
        switch mode:
            case mode_navigating:
                map_mode.map_draw()
            case mode_selecting_tile:
                tile_menu_mode.map_draw()

def new_root_mode():
    let sprites = load_sheet_sprites()
    let map_mode = world_map_mode{
        pov: point_of_view{ xy_0i, xy_0, xy_0, 100 },
        world: new_world(81),
        sprites: sprites,
        cursor_style: cursor_style_box,
        fill_tile: tile_none,
        fill_color: color_clear,
    }
    let tile_mode = tile_menu_mode{
        pov: point_of_view{ xy_0i, xy_0, xy_0, 100 },
        world: tile_menu_world{tile_sprite_id.length},
        sprites: sprites,
        cursor_style: cursor_style_hand,
        fill_tile: tile_none,
        fill_color: color_clear,
    }
    return root_mode{
        mode: mode_navigating,
        map_mode: map_mode,
        tile_menu_mode: tile_mode,
    }

fatal(gl_window("Editor", 400, 400))
check(gl_set_font_name("data/fonts/Droid_Sans/DroidSans.ttf"), "can\'t load font")

let mode = new_root_mode()

while gl_frame():
    mode.root_input():
        return from program
    mode.root_draw()

