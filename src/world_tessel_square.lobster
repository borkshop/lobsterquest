// square_tessel_world stores a square tesselation world, a world that repeats
// laterally and longitudinally.
// It implements a common interface for 2d map views with cell color, tile, and
// label layers.
// At time of writing, menus also implement this interface.
// We can specialize a map_mode<world_type> for either of these.

import color
import math_anex

class square_tessel_world:
    size: int
    colors: [color]
    tiles: [tile_entity_id]

    // index returns the storage index for a 2d coordinate.
    // all other methods refer to cells by index.
    def index(v):
        return mod(v.x, size) + size * mod(v.y, size)

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

def new_square_tessel_world(size):
    let area = size * size
    return square_tessel_world{
        size: size,
        colors: map(area): color_clear,
        tiles: map(area): tile_none,
    }
