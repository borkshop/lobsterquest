// tile_menu_world is a view into a 2d world that contains a menu
// for all of the tile entities in our spreadsheets.
// We specialize map_mode<tile_menu_world> to handle rendering and navigation
// of this world.

class tile_menu_world:
    size: int

    def index(v):
        if v.x != 0: return 0
        if v.y < 0: return 0
        if v.y >= size: return 0
        return v.y
    def color(i):
        return color_white
    def set_color(i, c):
        nil
    def tile(i):
        return i
    def set_tile(i, t):
        nil
    def label(i):
        return tile_names[i]
