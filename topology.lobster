import std
import vec

enum direction_index:
    northward
    eastward
    southward
    westward

def new_daia_topology(size):
    // $ for(new_daia_topology(1)): print _
    // [3, 5, 2, 1]
    // [3, 0, 2, 4]
    // [0, 5, 4, 1]
    // [0, 1, 4, 5]
    // [3, 1, 2, 5]
    // [3, 4, 2, 0]

    let area = size * size
    let grid = xy_1i * size
    let points = flatten(mapxy(grid) v: v)

    let neighborhoods = map(area * 6): map(cardinal_directions): -1

    def weave(start):
        def index_of_point(v):
            return start + v.y * size + v.x

        for(area) i: for(length(cardinal_directions)) j:
            let p = points[i]
            let d = cardinal_directions[j]
            let n = (p + d + grid) % grid
            neighborhoods[start + i][j] = index_of_point(n)

    def stitch(a, b, as, bs, dab, dba):
        for(size) i:
            let ai = a + as * i
            let bi = b + bs * i
            neighborhoods[ai][dab] = bi
            neighborhoods[bi][dba] = ai

    for(6) face: weave(area * face)

    //      +--L-+
    //      I 3  |
    //      |    K
    // +-I--+-J--+-K--+-L--+
    // B 5  C 4  D 1  A 0  B
    // |    |    |    |    |
    // +-E--*-F--*-G--*-H--*
    //                | 2  E
    //                G    |
    //                *--F-*

    stitch(area*6-size, area*2+size-1, 1, size, southward, eastward) // E 5-2
    stitch(area*5-size, area*3-1, 1, -1, southward, southward) // F 4-2
    stitch(area*2-size, area*3-size, 1, -size, southward, westward) // G 1-2
    stitch(area*1-size, area*2, 1, 1, southward, northward) // H 0-2

    stitch(area*1+size-1, area*0, size, size, eastward, westward) // A 1-0
    stitch(area*0+size-1, area*5, size, size, eastward, westward) // B 0-5
    stitch(area*5+size-1, area*4, size, size, eastward, westward) // C 5-4
    stitch(area*4+size-1, area*1, size, size, eastward, westward) // D 4-1

    stitch(area*5, area*3, 1, size, northward, westward) // I 5-3
    stitch(area*4, area*4-size, 1, 1, northward, southward) // J 4-3
    stitch(area*1, area*4-1, 1, -size, northward, eastward) // K 1-3
    stitch(area*0, area*3+size-1, 1, -1, northward, northward) // L 0-3

    return neighborhoods
