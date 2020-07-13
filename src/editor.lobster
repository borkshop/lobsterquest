// This is the main program for the Daia world editor.
//
// H,J,K,L to move.
// F to fill.
// D to dig.
// Enter to toggle tile selector view.
// Q or Escape to quit.

import daia_map
import daia_draw
import daia_topology
import daia_browser
import map
import brand
import sheets
import tile_menu
import math_anex
import rounded_corners

class tile_menu_mode : map_mode<tile_menu_world>

enum mode:
    mode_document
    mode_selecting_tile

class root_mode:
    mode: mode
    daia_mode: daia_mode
    tile_menu_mode: tile_menu_mode

    def root_input(exit):
        if gl_button("q") == 0:
            exit()
        switch mode:
            case mode_document:
                daia_mode.daia_input()
                if gl_button("return") == 0:
                    mode = mode_selecting_tile
            case mode_selecting_tile:
                tile_menu_mode.map_input()
                if gl_button("return") == 0:
                    let tile_id = tile_entity_id(mod(tile_menu_mode.pov.cursor.y, length(tile_sprite_id)))
                    daia_mode.fill_tile = tile_id
                    mode = mode_document

    def root_draw():
        switch mode:
            case mode_document:
                daia_mode.daia_draw()
            case mode_selecting_tile:
                tile_menu_mode.map_draw()

def new_root_mode(face_meshes, rounded_corner_textures):
    let sprites = load_sheet_sprites()
    let tile_mode = tile_menu_mode{
        pov: map_vantage{ xy_0i, xy_0, xy_0, 100 },
        world: tile_menu_world{tile_sprite_id.length},
        sprites: sprites,
        cursor_style: cursor_style_hand,
        fill_tile: tile_none,
        fill_color: color_clear,
    }

    let margin = 7
    let size = margin*4+3
    let daia_mode = new_daia_mode(
        72*size,
        size,
        0,
        0.35,
        sprites,
        rounded_corner_textures,
        face_meshes
    )
    daia_mode.tiles = daia_map_tiles
    daia_mode.flags = daia_map_flags
    daia_mode.fill_tile = tile_pine_tree
    daia_mode.pov.init(
        daia_mode.pov.area * 5 +
        daia_mode.pov.area / 2,
        0.5
    )

    return root_mode{
        mode: mode_document,
        daia_mode: daia_mode,
        tile_menu_mode: tile_mode,
    }

def main():
    fatal(gl_window("Editor", 1024, 1024))
    gl_window_min_max(1)
    check(gl_set_font_name(pakfile "data/fonts/Droid_Sans/DroidSans.ttf"), "can\'t load font")

    let face_meshes = new_daia_face_meshes(new_daia_face_vertices())
    let rounded_corner_textures = articulate_rounded_corners()

    let mode = new_root_mode(face_meshes, rounded_corner_textures)

    while gl_frame():
        mode.root_input():
            return from program
        mode.root_draw()

main()
