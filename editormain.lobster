import cube
import cubebrowser
import editor
import brand
import sheets

class world_map_mode : map_mode<world>
class tile_menu_mode : map_mode<tile_menu_world>

enum mode:
    mode_daia
    mode_map_unbounded_flat_world
    mode_selecting_tile

class root_mode:
    mode: mode
    return_mode: mode
    daia_mode: daia_mode
    map_mode: world_map_mode
    tile_menu_mode: tile_menu_mode

    def root_input(exit):
        if gl_button("q") == 0:
            exit()
        switch mode:
            case mode_daia:
                daia_mode.daia_input()
                if gl_button("return") == 0:
                    return_mode = mode_daia
                    mode = mode_selecting_tile
            case mode_map_unbounded_flat_world:
                map_mode.map_input()
                if gl_button("return") == 0:
                    return_mode = mode_map_unbounded_flat_world
                    mode = mode_selecting_tile
            case mode_selecting_tile:
                tile_menu_mode.map_input()
                if gl_button("return") == 0:
                    let tile_id = tile_entity_id(mod(tile_menu_mode.pov.cursor.y, length(tile_sprite_id)))
                    map_mode.fill_tile = tile_id
                    daia_mode.fill_tile = tile_id
                    mode = return_mode

    def root_draw():
        switch mode:
            case mode_daia:
                daia_mode.daia_draw()
            case mode_map_unbounded_flat_world:
                map_mode.map_draw()
            case mode_selecting_tile:
                tile_menu_mode.map_draw()

def new_root_mode(face_meshes):
    let sprites = load_sheet_sprites()
    let map_mode = world_map_mode{
        pov: map_vantage{ xy_0i, xy_0, xy_0, 100 },
        world: new_world(81),
        sprites: sprites,
        cursor_style: cursor_style_box,
        fill_tile: tile_none,
        fill_color: color_clear,
    }
    let tile_mode = tile_menu_mode{
        pov: map_vantage{ xy_0i, xy_0, xy_0, 100 },
        world: tile_menu_world{tile_sprite_id.length},
        sprites: sprites,
        cursor_style: cursor_style_hand,
        fill_tile: tile_none,
        fill_color: color_clear,
    }

    let daia_mode = new_daia_mode(500, 7, 0, 1, sprites, face_meshes, face_colors, face_highlight_colors)
    daia_mode.fill_tile = tile_pine_tree

    return root_mode{
        mode: mode_daia,
        return_mode: mode_map_unbounded_flat_world,
        daia_mode: daia_mode,
        map_mode: map_mode,
        tile_menu_mode: tile_mode,
    }

fatal(gl_window("Editor", 400, 400))
check(gl_set_font_name("data/fonts/Droid_Sans/DroidSans.ttf"), "can\'t load font")

let face_meshes = cube_new_face_meshes(cube_new_face_vertices())

let mode = new_root_mode(face_meshes)

while gl_frame():
    mode.root_input():
        return from program
    mode.root_draw()

