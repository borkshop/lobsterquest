import vec
namespace sheets

enum names:
    tile_euia
    tile_apple_tree
    tile_pine_tree
    tile_pear_tree
    tile_clover
    tile_ewe
    tile_ram
    tile_castle
    tile_euia_bank
    tile_euia_forge
    tile_glub
    tile_major
    tile_captain
    tile_miner
    tile_harriet
    tile_jack
    tile_boulder
    tile_mountain
    tile_horse
    tile_unicorn
    tile_occia
    tile_mermaid
    tile_herman
    tile_merman
    tile_marco
    tile_octopus
    tile_fish
    tile_puffer_fish
    tile_turtle
    tile_island
    tile_date_palm_tree
    tile_banana_tree
    tile_coconut_tree
    tile_sponge
    tile_parrot
    tile_occia_bank
    tile_borea
    tile_steamer
    tile_north_pole
    tile_unlit_tree
    tile_lit_tree
    tile_bear
    tile_polar_bear
    tile_abdominal_snowman
    tile_abominable_snowman
    tile_caribou
    tile_whale
    tile_sal_the_snake
    tile_sal_the_mander
    tile_infernia
    tile_cheese_wizard
    tile_sand_witch
    tile_south_pole
    tile_oria
    tile_jennie
    tile_gene
    tile_cactus
    tile_bamboo
    tile_panda
    tile_dysia
    tile_sun
    tile_sol
    tile_moon
    tile_lune
    tile_asteroid
    tile_dumbledore
    tile_high_mountain
    tile_volcano
    tile_gym
    tile_observatory
    tile_justin
    tile_nick
    tile_bakery
    tile_plumber
    tile_genome
    tile_pat
    tile_kris_and_lydia
    tile_kitty
    tile_tiger
    tile_infernia_warning_sign
    tile_asia
    tile_africa
    tile_america
    item_apple
    item_pine_apple
    item_pear
    item_hardwood
    item_softwood
    item_clover
    item_mutton
    item_yarn
    item_copper
    item_silver
    item_gold
    item_link
    item_bolt
    item_gear
    item_knife
    item_shovel
    item_wrench
    item_pick_axe
    item_bicycle
    item_hook
    item_hammer
    item_shield
    item_chain
    item_scissors
    item_hammer_and_pick
    item_hammer_and_wrench
    item_sword
    item_zweihander
    item_basket
    item_cart
    item_fishing_rod
    item_barrel
    item_knitting_needles
    item_canoe
    item_coat
    item_fleur
    item_trident
    item_water
    item_coconut
    item_banana
    item_date
    item_fish
    item_sand
    item_alembic
    item_turtle
    item_snail
    item_wind
    item_light_bulb
    item_lab_coat
    item_carrot
    item_rocket
    item_fuel
    item_cactus
    item_key_to_dysia
    item_loan
    item_fire
    item_power
    item_left_lune
    item_right_lune
    item_lune
    item_mojick
    item_mushroom
    item_cake
    item_horn
    item_unicorn
    item_bay_leaves
    item_invisibility_cloak
    item_pen
    item_needle
    item_broom

let sprites = [
    xy{ 0, 0 },
    xy{ 72, 0 },
    xy{ 144, 0 },
    xy{ 72, 0 },
    xy{ 216, 0 },
    xy{ 288, 0 },
    xy{ 360, 0 },
    xy{ 432, 0 },
    xy{ 504, 0 },
    xy{ 576, 0 },
    xy{ 648, 0 },
    xy{ 720, 0 },
    xy{ 792, 0 },
    xy{ 0, 72 },
    xy{ 72, 72 },
    xy{ 144, 72 },
    xy{ 216, 72 },
    xy{ 216, 72 },
    xy{ 288, 72 },
    xy{ 360, 72 },
    xy{ 0, 0 },
    xy{ 432, 72 },
    xy{ 504, 72 },
    xy{ 576, 72 },
    xy{ 648, 72 },
    xy{ 720, 72 },
    xy{ 648, 0 },
    xy{ 792, 72 },
    xy{ 0, 144 },
    xy{ 72, 144 },
    xy{ 144, 144 },
    xy{ 144, 144 },
    xy{ 144, 144 },
    xy{ 216, 144 },
    xy{ 288, 144 },
    xy{ 504, 0 },
    xy{ 0, 0 },
    xy{ 360, 144 },
    xy{ 432, 144 },
    xy{ 144, 0 },
    xy{ 504, 144 },
    xy{ 576, 144 },
    xy{ 0, 0 },
    xy{ 648, 144 },
    xy{ 720, 144 },
    xy{ 792, 144 },
    xy{ 0, 216 },
    xy{ 72, 216 },
    xy{ 144, 216 },
    xy{ 0, 0 },
    xy{ 216, 216 },
    xy{ 288, 216 },
    xy{ 360, 216 },
    xy{ 0, 0 },
    xy{ 432, 216 },
    xy{ 504, 216 },
    xy{ 576, 216 },
    xy{ 648, 216 },
    xy{ 720, 216 },
    xy{ 0, 0 },
    xy{ 792, 216 },
    xy{ 0, 288 },
    xy{ 72, 288 },
    xy{ 144, 288 },
    xy{ 216, 288 },
    xy{ 288, 288 },
    xy{ 360, 288 },
    xy{ 432, 288 },
    xy{ 504, 288 },
    xy{ 576, 288 },
    xy{ 648, 288 },
    xy{ 720, 288 },
    xy{ 576, 0 },
    xy{ 792, 288 },
    xy{ 0, 360 },
    xy{ 72, 360 },
    xy{ 144, 72 },
    xy{ 144, 360 },
    xy{ 216, 360 },
    xy{ 288, 360 },
    xy{ 360, 360 },
    xy{ 432, 360 },
    xy{ 504, 360 },
    xy{ 576, 360 },
    xy{ 648, 360 },
    xy{ 720, 360 },
    xy{ 72, 0 },
    xy{ 144, 0 },
    xy{ 216, 0 },
    xy{ 792, 360 },
    xy{ 0, 432 },
    xy{ 72, 432 },
    xy{ 144, 432 },
    xy{ 216, 432 },
    xy{ 288, 432 },
    xy{ 360, 432 },
    xy{ 432, 432 },
    xy{ 504, 432 },
    xy{ 576, 432 },
    xy{ 648, 432 },
    xy{ 720, 432 },
    xy{ 792, 432 },
    xy{ 0, 504 },
    xy{ 72, 504 },
    xy{ 144, 504 },
    xy{ 216, 504 },
    xy{ 288, 504 },
    xy{ 360, 504 },
    xy{ 432, 504 },
    xy{ 504, 504 },
    xy{ 576, 504 },
    xy{ 648, 504 },
    xy{ 720, 504 },
    xy{ 792, 504 },
    xy{ 0, 576 },
    xy{ 72, 576 },
    xy{ 144, 576 },
    xy{ 216, 576 },
    xy{ 288, 576 },
    xy{ 360, 576 },
    xy{ 432, 576 },
    xy{ 504, 576 },
    xy{ 576, 576 },
    xy{ 648, 576 },
    xy{ 648, 0 },
    xy{ 72, 144 },
    xy{ 720, 576 },
    xy{ 0, 144 },
    xy{ 792, 576 },
    xy{ 0, 648 },
    xy{ 72, 648 },
    xy{ 144, 648 },
    xy{ 216, 648 },
    xy{ 288, 648 },
    xy{ 360, 648 },
    xy{ 576, 216 },
    xy{ 432, 648 },
    xy{ 504, 648 },
    xy{ 576, 648 },
    xy{ 648, 648 },
    xy{ 720, 648 },
    xy{ 792, 648 },
    xy{ 144, 288 },
    xy{ 0, 720 },
    xy{ 72, 720 },
    xy{ 144, 720 },
    xy{ 216, 720 },
    xy{ 360, 72 },
    xy{ 288, 720 },
    xy{ 144, 648 },
    xy{ 360, 720 },
    xy{ 432, 720 },
    xy{ 504, 720 },
]
