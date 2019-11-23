import color

// Brand colors from https://openmoji.org/styleguide/

private def itoc(rgba):
    let dividend = float(0xff)
    def ff(n, s): return float((n >> s) & 0xff) / dividend
    return color{ ff(rgba, 24), ff(rgba, 16), ff(rgba, 8), ff(rgba, 0) }

let light_brown = itoc(0x6A462FFF)
let dark_green = itoc(0x5C9E31FF)
