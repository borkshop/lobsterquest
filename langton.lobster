// With one ent, this is a faithful representation of Langton’s Ant,
// implemented as a cellular automaton instead of a single-agent automaton.
// However, there are additional rules that dictate the behavior of collisions.
// Each ent has a unique priority.
// Each ent makes a bid to follow the course set out for them by the
// langton rule number beneath them.
// For each tile, the neighboring ent with the highest priority that has
// bid to move onto that tile advances.
// All ents that fail their bid turn in place instead.

import gui
import texture

namespace langton

// scatter copies the values from the source array into their respective places
// in an array of all the neighborhoods around their position.
// The neighborhoods array must contain an array with the indices of each neighbor.
// So, for an array representing a 3x3 grid in row-major-order:
//   [ 0, 1, 2,
//     3, 4, 5,
//     6, 7, 8 ]
// the neighborhoods of indices in cardinal directions [north, west, south, east]
// would be:
//   [ [ 6, 2, 3, 1 ], [ 7, 0, 4, 2], ... ]
def scatter(dst, src, neighborhoods):
    for(neighborhoods) neighborhood, i:
        for(neighborhood) j, k:
            dst[i][k] = src[j]

// gather_bids visits each cell and determines the direction the ent in
// that cell would like to move, based on its heading.
// headings are indexes into cardinal_directions, for the direction each
// ent is currently heading.
def gather_bids(bids, neighborhoods, ents, headings):
    for(neighborhoods) neighbors, i:
        bids[i] = if ents[i]:
            let heading = headings[i]
            let neighbor = neighbors[heading]
            if !ents[neighbor]: neighbor
            else: -1
        else: -1

// The tick method then scatters bids and each ent’s priority into
// bid_neighborhoods and weight_neighborhoods.

def find_winner(i, neighborhood, bid_neighborhood, weight_neighborhood):
    var best = -1
    var winner = -1
    for(length(neighborhood)) j:
        if bid_neighborhood[j] == i and (best < 0 or weight_neighborhood[j] > best):
            best = weight_neighborhood[j]
            winner = neighborhood[j]
    return winner

// gather_winners (through find_winner) examines the bids in each neighborhood
// and records the bidder with the highest weight to move onto each cell.
def gather_winners(len, winners, neighborhoods, bid_neighborhoods, weight_neighborhoods):
    for(len) i:
        winners[i] = find_winner(i, neighborhoods[i], bid_neighborhoods[i], weight_neighborhoods[i])

// The tick method then builds a transition matrix.
// The transition matrix contains the index of every cell in the source array,
// ordered according to where its data were stored in the previous generation.

// transit applies the results of a transition, effectively swapping every
// cell’s data with that data in its prior location, from the previous
// generation.
// The tick function uses transit to move all mobile data from one generation
// to the next.
def transit(len, dst, src, transitions):
    for(len) i: dst[i] = src[transitions[i]]

// move copies one array to another, given the length of both.
// This is necessary at the beginning of each tick, to overwrite columns of
// data from the previous generation.
def move(len, dst, src):
    for(len) i:
        dst[i] = src[i]

// move with a function additionally applies a relation on the data
// being moved.
// The tick function uses the transform to normalize headings.
// The -1 and 4 headings are otherwise valid for the purposes of animating
// transitions after the 0 and 3 headings.
def move(len, dst, src, fun):
    for(len) i:
        dst[i] = fun(src[i])

def index_of_point(v, size): return v.y * size + v.x

// world captures all allocations necessary to run the langton’s ents
// cellular automaton.
// The automaton uses columns of data organized by their respective point in
// the world in row-major-order, but is flexible enough to use other orders
// like z-order or hilbert-order with slight adaptation if these were to
// provide better cache locality, and if that were to matter.
//
// The columns on the leading edge are inputs from the prior generation.
// The columns on the following edge are copied from the leading edge at the
// beginning of each tick.
// Otherwise, information flows strictly from input to output.
class world:
    rules:[int]
    len:int

    // leading edge
    ents_next:[int]
    weights_next:[int]
    headings_next:[int]
    langtons_next:[int]
    directions_next:[xy_i]
    rotations_next:[int]
    // following edge
    ents:[int]
    weights:[int]
    headings:[int]
    trailings:[int]
    langtons:[int]
    directions:[xy_i]
    rotations:[int]

    // intermediate
    neighborhoods:[[int]]
    turns:[[int]]
    bids:[int]
    bid_neighborhoods:[[int]]
    weight_neighborhoods:[[int]]
    winners:[int]
    winner_neighborhoods:[[int]]
    transitions:[int]
    headings_rotated:[int]

    def tick():
        move(len, ents, ents_next)
        move(len, weights, weights_next)
        move(len, langtons, langtons_next)
        move(len, headings, headings_next) n: (4 + n) % 4

        gather_bids(bids, neighborhoods, ents, headings)
        scatter(bid_neighborhoods, bids, neighborhoods)
        scatter(weight_neighborhoods, weights, neighborhoods)
        gather_winners(len, winners, neighborhoods, bid_neighborhoods, weight_neighborhoods)
        scatter(winner_neighborhoods, winners, neighborhoods)
        gather_transitions()

        transit(len, ents_next, ents, transitions)
        transit(len, directions_next, directions, transitions)
        transit(len, weights_next, weights, transitions)
        transit(len, headings_next, headings_rotated, transitions)
        transit(len, trailings, headings, transitions)

    def gather_transitions():
        for(len) i:
            let transition,
                direction,
                rotation,
                langton,
                turn = find_transition(i, neighborhoods[i], winners[i], winner_neighborhoods[i], langtons[i], turns[i])
            transitions[i] = transition
            directions[i] = direction
            rotations[i] = rotation
            headings_rotated[i] = headings[i] + rotation + turn
            langtons_next[i] = langton

    def find_transition(i, neighbors, winner, winner_neighbors, langton, turn):
        // A neighbor moves here.
        if winner >= 0:
            return winner, xy_0i, 0, langton, 0
        let found = find(winner_neighbors) j: i == j
        // We move to a neighbor.
        if found >= 0:
            return neighbors[found],
                cardinal_directions[found],
                rules[langton],
                (length(rules) + langton + 1) % length(rules),
                turn[found]
        // Rotate in place if cannot proceed.
        return i, xy_0i, 1, langton, 0

def new_round_square_topology(size):
    let grid = xy_1i * size
    let points = flatten(mapxy(grid) v: v)
    let neighborhoods = map(points) v: map(cardinal_directions) d: index_of_point((v + d + grid) % grid, size)
    return neighborhoods

def new_world(neighborhoods, turns, count, rules):
    let len = length(neighborhoods)
    let headings = map(len): rnd(4)

    // // just one ent:
    // let ents_next = map(len): 0
    // ents_next[length(len)/2] = 1
    // // random ents
    // let ents_next = map(len): if rnd(len) <= count: 1 else: 0
    // count ents randomly distributed
    count = min(len, count)
    let ents_next = map(len): 0
    move(length(count), ents_next, map(count): 1)
    randomize(ents_next)

    return world{
        len: len,
        rules: rules,
        neighborhoods: neighborhoods,
        turns: turns,
        weights_next: randomize(map(len) n: n),
        weights: map(len): 0,
        ents_next: ents_next,
        ents: map(len): 0,
        bids: map(len): 0,
        bid_neighborhoods: map(len): map(cardinal_directions): 0,
        weight_neighborhoods: map(len): map(cardinal_directions): 0,
        winners: map(len): 0,
        winner_neighborhoods: map(len): map(cardinal_directions): 0,
        transitions: map(len): 0,
        directions: map(len): xy_0i,
        directions_next: map(len): xy_0i,
        headings: headings,
        headings_next: map(len): headings[_],
        trailings: map(len): headings[_],
        rotations: map(len): 0,
        rotations_next: map(len): 0,
        headings_rotated: map(len): 0,
        langtons: map(len): 0,
        langtons_next: map(len): 0
    }

def spectrum(first, last, count):
    return map(count) i: lerp(first, last, float(i) / float(count-1))

def for_grid(grid, fun):
    forxy(grid) point:
        fun(point, point.x + point.y * grid.x)

def for_translate_grid(grid, fun):
    for_grid(grid) point, i:
        gl_translate float(point) / float(grid):
            fun(point, i)

def draw_tween_color_grid(grid, next, prev, offset, palette, tween):
    // draw background color according to langton rule number.
    gl_set_shader("color")
    for_translate_grid(grid) point, i:
        let v = float(point)
        let c1 = palette[prev[i + offset]]
        let c2 = palette[next[i + offset]]
        let c = lerp(c1, c2, tween)
        gl_color(c)
        gl_scale(xy_1 / float(grid))
        gl_rect(xy_1, 0)

class view:
    size: int
    neighborhoods:[[int]]
    first_rule_color:color
    last_rule_color:color

    def draw(w, offset, tween, tex):
        let palette = spectrum(first_rule_color, last_rule_color, length(w.rules))
        draw_tween_color_grid(xy_1i * size, w.langtons_next, w.langtons, offset, palette, tween)

        // draw foreground according to presence and heading of ents,
        // tweened along their translation and rotation vectors.
        gl_set_shader("textured")
        gl_set_primitive_texture(0, tex)
        gl_color(color_white)

        // Each ent, including duplicate ents when a ent exits off
        // an edge and returns through another.
        for_ents(
            w.ents, w.ents_next,
            w.directions, w.directions_next,
            w.headings, w.headings_next,
            w.trailings, w.rotations,
            offset
        ) i, v1, v2, a1, a2:
            let v = lerp(v1, v2, tween)
            let a = lerp(a1, a2, tween)

            gl_translate v / size:
                gl_scale(xy_1 / size)
                gl_translate(xy_1 / 2)
                gl_rotate_z(rotate2D(xy_x, a))
                gl_scale(0.75)
                gl_translate(xy_1 / -2)
                gl_rect(xy_1, 0)

    def for_ents(
        ents, ents_next,
        directions, directions_next,
        headings, headings_next,
        trailings, rotations,
        offset, func
    ):
        for_grid(xy_1i * size) point, i:
            if ents[i + offset]:
                let index = i + offset
                let v1 = float(point)
                let v2 = v1 + float(directions[index])
                let a1 = float(headings[index]) * 90.0
                let a2 = a1 + float(rotations[index]) * 90.0
                func(index, v1, v2, a1, a2)

def new_square_view(size, neighborhoods, first_rule_color, last_rule_color):
    return view{
        size: size,
        neighborhoods: neighborhoods,
        first_rule_color: first_rule_color,
        last_rule_color: last_rule_color,
    }
