// brand provides branded colors for the game.

import color

// Brand colors from https://openmoji.org/styleguide/

private def itoc(rgba):
    let dividend = float(0xff)
    def ff(n, s): return float((n >> s) & 0xff) / dividend
    return color{ ff(rgba, 24), ff(rgba, 16), ff(rgba, 8), ff(rgba, 0) }

let light_blue   = itoc(0x92D3F5FF)
let dark_blue    = itoc(0x61B2E4FF)
let light_red    = itoc(0xEA5A47FF)
let dark_red     = itoc(0xD22F27FF)
let light_green  = itoc(0xB14CC3FF)
let dark_green   = itoc(0x5C9E31FF)
let light_yellow = itoc(0xFCEA2BFF)
let dark_yellow  = itoc(0xF1B31CFF)
let light_grey   = itoc(0xD0CFCEFF)
let grey         = itoc(0x9B9B9AFF)
let dark_grey    = itoc(0x3F3F3FFF)
let light_pink   = itoc(0xFFA7C0FF)
let dark_pink    = itoc(0xE67A94FF)
let light_purple = itoc(0xB399C8FF)
let dark_purple  = itoc(0x8967AAFF)
let light_orange = itoc(0xF4AA41FF)
let dark_orange  = itoc(0xE27022FF)
let light_brown  = itoc(0xA57939FF)
let dark_brown   = itoc(0x6A462FFF)

let palette = [
    light_blue,
    light_red,
    light_green,
    light_yellow,

    dark_blue,
    dark_red,
    dark_green,
    dark_yellow,

    light_grey,
    grey,
    dark_grey,

    light_pink,
    light_purple,
    light_orange,
    light_brown,

    dark_pink,
    dark_purple,
    dark_orange,
    dark_brown,
]

// Colors are arranged such that CMY are about the origin and RGB on the polar
// opposites.
// Colors on opposite faces are also opposite hues.
let face_colors = [
    light_purple,    // 1: M
    light_orange,    // 2: Y
    color_white*0.8, // 3: C (water is primary)
    color_white*0.8, // 4: R
    light_orange,    // 5: B (water is primary)
    dark_green,      // 6: G
]

let face_water_colors = [
    dark_blue,
    dark_blue,
    light_blue,
    light_blue,
    dark_blue,
    dark_blue,
]

let face_highlight_colors = [
    dark_purple,
    light_brown,
    dark_blue,
    light_red,
    light_blue,
    light_brown,
]

let magma_color = dark_red
