import color
import brand
import sheets

enum command:
    command_usus
    command_borealis
    command_dorsum
    command_occidens
    command_requiem
    command_orientem
    command_sinister
    command_auster
    command_dexter
    command_nulla
    commands_count

class kc:
    key:string
    command:command

let key_commands = [
    kc{ "escape", command_nulla },
    kc{ "0", command_nulla },

    kc{ "up", command_borealis },
    kc{ "k", command_borealis },
    kc{ "w", command_borealis },
    kc{ "8", command_borealis },

    kc{ "right", command_orientem },
    kc{ "l", command_orientem },
    kc{ "d", command_orientem },
    kc{ "6", command_orientem },

    kc{ "o", command_dorsum },
    kc{ "r", command_dorsum },
    kc{ "9", command_dorsum },

    kc{ "down", command_auster },
    kc{ "j", command_auster },
    kc{ "s", command_auster },
    kc{ "2", command_auster },

    kc{ "left", command_occidens },
    kc{ "h", command_occidens },
    kc{ "a", command_occidens },
    kc{ "4", command_occidens },

    kc{ "u", command_sinister },
    kc{ "q", command_sinister },
    kc{ "1", command_sinister },

    kc{ "i", command_dexter },
    kc{ "e", command_dexter },
    kc{ "3", command_dexter },

    kc{ "space", command_requiem },
    kc{ ".", command_requiem },
    kc{ "5", command_requiem },

    kc{ "return", command_usus },
    kc{ "7", command_usus },
]

fatal(gl_window("Command input HUD", 400, 400))

let sprite_atlas = load_sheet_sprites()

def invoke_command(command):
    switch command:
        case command_nulla:
            return from program
        case command_sinister:
            nil
        case command_auster:
            nil
        case command_dexter:
            nil
        case command_occidens:
            nil
        case command_requiem:
            nil
        case command_orientem:
            nil
        case command_usus:
            nil
        case command_borealis:
            nil
        case command_dorsum:
            nil
        default:
            nil

let pressure = map(commands_count): 1.0
let keydown = map(commands_count): false
let dpad = [
    ui_sprite_id[ui_discard],
    ui_sprite_id[ui_north],
    item_sprite_id[item_shield],
    ui_sprite_id[ui_west],
    ui_sprite_id[ui_rest],
    ui_sprite_id[ui_east],
    ui_sprite_id[ui_left_hand],
    ui_sprite_id[ui_south],
    ui_sprite_id[ui_right_hand],
]

while gl_frame():

    for(commands_count) command:
        keydown[command] = false
    for(key_commands) kc:
        let state = gl_button(kc.key)
        if state >= 1: // isdown
            keydown[kc.command] = true
        if state == 0: // wentup
            invoke_command(kc.command)
    for(commands_count) command:
        if keydown[command]:
            pressure[command] = 1.0 + (1.5 - pressure[command]) * pow(0.75, 1 + gl_delta_time()/2)
        else:
            pressure[command] = 1.0 + (pressure[command] - 1.0) * pow(0.75, 1 + gl_delta_time()/2)

    let padding_size = xy_1 * 5
    let icon_size = xy_1 * 100
    let window_size = float(gl_window_size())
    let dpad_size = padding_size * 4 + icon_size * 3
    gl_translate(window_size - dpad_size):
        gl_clear(color_white * 0.8)

        // gl_scale(dpad_size):
        //     gl_color(color_white * 0.6)
        //     gl_set_shader("color")
        //     gl_unit_square()

        gl_set_shader("textured")
        gl_color(color_white)
        forxy(xy_1i * 3) v:
            gl_translate(padding_size + (icon_size + padding_size) * float(v)):
                let index = v.y * 3 + v.x
                let sprite_id = dpad[index]
                let tex = sprite_atlas.tile_texture(sprite_id)
                gl_set_primitive_texture(0, tex)
                gl_translate(xy_1/2)
                gl_scale(icon_size*pressure[index])
                gl_translate(-xy_1/2)
                gl_unit_square()

    // gl_translate((window_size - icon_size - padding_size) * xy_y + padding_size * xy_x):
    //     let sprite_id = ui_sprite_id[ui_north]
    //     let tex = sprite_atlas.tile_texture(sprite_id)
    //     gl_set_primitive_texture(0, tex)
    //     gl_scale(icon_size)
    //     gl_unit_square()
