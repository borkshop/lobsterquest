import vec
import std
import color
import sprites
import sheets
import daia_log
import embox
import rounded_corners
import brand

def main():
    fatal(gl_window("Daia Log", 500, 500))
    let size = xy{ 1000.0, 1000.0 }
    let pad = rounded_corner_size
    let sprites = load_sheet_sprites()
    let rounded_corners = articulate_rounded_corners()
    while gl_frame() and gl_button("escape") != -1 and gl_button("q") != 1:
        gl_clear(color_white)
        gl_color(color_black)
        let window_size = float(gl_window_size())
        let scale = xy_1 * min(window_size)

        // // debug wrap line:
        // gl_line(xy{ wrap, 0.0 }, xy{ wrap, size.y }, 1.0)

        def bold():
            check(gl_set_font_name("data/fonts/Fontin_Sans/Fontin_Sans_B_45b.otf"), "could not load font")
            gl_set_font_size(50)
        def normal():
            check(gl_set_font_name("data/fonts/Fontin_Sans/Fontin_Sans_R_45b.otf"), "could not load font")
            gl_set_font_size(50)

        def intro(f):
            gl_color(color_black)

            // 🌈 Mojick has faded from the world.
            f.texture(sprites.get_texture(item_sprite_id[item_mojick]))
            bold()
            f.text("Mojick")
            normal()
            f.sp()
            f.text("has faded from the world.")
            f.sp()

            // 🐉 Mojical creatures 🦄 have been lost for an age 🕰.
            bold()
            f.texture(sprites.get_texture(tile_sprite_id[tile_fire_drake]))
            f.text("Mojical creatures")
            f.texture(sprites.get_texture(tile_sprite_id[tile_unicorn]))
            f.sp()
            normal()
            f.text("have been lost for an age.")
            f.texture(sprites.get_texture(tile_sprite_id[tile_justin]))
            f.sp()

            // You, 😬 Adventurer 😲, are charged to
            // wander the 🎲 Faces of Daia 🎲 to find and restore the 💨
            // essences 💦 of 🔥 mojick ⚡️, ❓ interrogating, 🪓 harvesting, ✂️
            // crafting, and, where the cause is just, ⚔️ fighting emojis to
            // restore mojick to all the lands.

        flow(size - pad * 2, 50) f:
            intro(f)
        fn backdrop, draw:
            gl_translate((window_size - scale)/2)
            gl_scale(scale / size)
            gl_translate(max(pad, size - backdrop - pad))
            gl_color(light_blue)
            embox(backdrop, rounded_corner_size, rounded_corners)
            draw()

main()
