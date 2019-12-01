import editor

class world_map_mode : map_mode<world>
class tile_menu_mode : map_mode<tile_menu_world>

enum mode:
    mode_navigating
    mode_selecting_tile

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

