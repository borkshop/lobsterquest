// A square tesselation topology repeats laterally and longitudinally.
// There are no necessary turns to reorient the cardinal directions when moving
// from cell to cell.

def new_tessel_square_topology(size):
    let grid = xy_1i * size
    let points = flatten(mapxy(grid) v: v)
    def index_of_point(v): return v.y * size + v.x
    let neighborhoods = map(points) v: map(cardinal_directions) d: index_of_point((v + d + grid) % grid)
    let turns = map(points): map(cardinal_directions): 0
    return neighborhoods, turns
