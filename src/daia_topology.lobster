// The Daia world is a cube.
// Each face of Daia is a square.
// Within each face, the Daia world has a grid of cells.
// Each cell corresponds to an index in a flat array.
// Within each face, the indicies of the array correspond to row-major order.
// The faces are ordered according to the conventional pips of right handed
// dice.
// All of the cells on the same face of the world have the same orientation.
// Each cell is adjacent to four neighboring cells: north, east, south, and
// west.
// Sometimes these neighbors are on adjacent faces of the cube.
//
// The remaining details of the Daia world topology are arbitrary
// but designed for its particular aesthetic.
// All of the cells along the equatorial faces have the same orientation.
// According to the pip numbers on dice, these are faces 1, 2, 6, and 5 from
// west to east around the equator of Daia.
// Having the same orientation means that travelling from cell to cell,
// the observer does not need to turn to remain aligned with the latter cell's
// cardinal directions.
// According to the pip numbers on dice, the first triad and second
// triad (faces 1, 2, 3 and faces 4, 5, 6) are thematically related, so
// travelling among them in order does not require reorientation.
// This rule dictates the orientation of the top and bottom of the cube,
// face 4 being north of the equatorial faces and face 3 being south.
//
// This module computes the adjacency matrix and the turn vectors for every
// cell in a Daia representation of a given size.
// The adjacency matrix is an array of the neighboring cell indicies
// for every cell, in order from north, east, south, and west.
// The turn matrix has the same shape and tells whether the heading
// of a viewer must turn to reorient itself with the cell when moving
// to each neighbor cell, with a bias for turning clockwise when
// the viewer needs to turn fully about.

import std
import vec
import topology

def new_daia_topology(size):
    // $ for(new_daia_topology(1)): print _
    // [3, 1, 2, 4]
    // [3, 5, 2, 0]
    // [1, 5, 4, 0]
    // [1, 0, 4, 5]
    // [3, 0, 2, 5]
    // [3, 4, 2, 1]

    let area = size * size
    let grid = xy_1i * size
    let points = flatten(mapxy(grid) v: v)

    let neighborhoods = map(area * 6): map(cardinal_directions): -1
    let turns = map(area * 6): map(cardinal_directions): 0

    def weave(start):
        def index_of_point(v):
            return start + v.y * size + v.x

        for(area) i: for(length(cardinal_directions)) j:
            let p = points[i]
            let d = cardinal_directions[j]
            let n = (p + d + grid) % grid
            neighborhoods[start + i][j] = index_of_point(n)

    def stitch(a, b, as, bs, dab, dba, turn):
        for(size) i:
            let ai = a + as * i
            let bi = b + bs * i
            neighborhoods[ai][dab] = bi
            neighborhoods[bi][dba] = ai
            turns[ai][dab] = turn
            turns[bi][dba] = -turn

    for(6) face: weave(area * face)

    //      + ←L +
    //      I 3  ↑
    //      ↓    K
    // + I→ + J→ + K→ + L→ +
    // B 5  C 4  D 0  A 1  B
    // ↓    ↓    ↓    ↓    ↓
    // + E→ + F→ + G→ + H→ +
    //                ↑ 2  E
    //                G    ↓
    //                + ←F +

    stitch(area*6-size, area*2+size-1, 1, size, southward, eastward, cw) // E 5-2
    stitch(area*5-size, area*3-1, 1, -1, southward, southward, about) // F 4-2
    stitch(area*1-size, area*3-size, 1, -size, southward, westward, ccw) // G 0-2
    stitch(area*2-size, area*2, 1, 1, southward, northward, steady) // H 1-2

    stitch(area*0+size-1, area*1, size, size, eastward, westward, steady) // A 0-1
    stitch(area*1+size-1, area*5, size, size, eastward, westward, steady) // B 1-5
    stitch(area*5+size-1, area*4, size, size, eastward, westward, steady) // C 5-4
    stitch(area*4+size-1, area*0, size, size, eastward, westward, steady) // D 4-0

    stitch(area*5, area*3, 1, size, northward, westward, cw) // I 5-3
    stitch(area*4, area*4-size, 1, 1, northward, southward, steady) // J 4-3
    stitch(area*0, area*4-1, 1, -size, northward, eastward, ccw) // K 0-3
    stitch(area*1, area*3+size-1, 1, -1, northward, northward, about) // L 1-3

    return neighborhoods, turns

let daia_unit_neighborhoods, daia_unit_turns = new_daia_topology(1)
