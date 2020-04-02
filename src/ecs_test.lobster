import ecs
import testing

let t_a = new_template(ent_visible): nil
let t_b = new_template(ent_visible): nil

def make_place(body): return new_template(ent_visible):
    _.z    = 1.0
    _.size = 1.0
    _.fg   = color_white
    body(_)

def make_body(body): return new_template(ent_visible | ent_body):
    _.z    = 1.0
    _.size = 1.0
    _.fg   = color_white
    body(_)

run_test("ecs/templates/spawn"):
    // data should not leak
    let t_stuff_a = make_place(): _.add_spawn_sibling(t_a, xy_i { 1, 2 })
    let t_stuff_b = make_place(): _.add_spawn_sibling(t_b, xy_i { 1, 3 })

    assert t_stuff_a.spawn.length == 1
    assert t_stuff_b.spawn.length == 1
    assert t_a.spawn.length == 0
    assert t_b.spawn.length == 0

run_test("ecs/templates/graph"):
    // data should not leak
    let t_part1 = make_body(): _.glyph = ascii('a')
    let t_part2 = make_body(): _.glyph = ascii('b')

    def make_thing(body): return make_body(): body(_) // XXX  _.cap = xy_f { 2, 2 }
    let thing1 = make_thing(): _.add_child(entrel_body, xy_f { 0, 0 }, t_part1)
    let thing2 = make_thing(): _.add_child(entrel_body, xy_f { 0, 0 }, t_part2)
    let thing3 = make_thing(): nil

    assert t_part1.children.length == 0
    assert t_part2.children.length == 0
    assert thing1.children.length == 1
    assert thing1.children[0].glyph == ascii('a')
    assert thing2.children.length == 1
    assert thing2.children[0].glyph == ascii('b')
    assert thing3.children.length == 0

def ascii(code:int): return glyph { 0, code }

let sh = shard {}

def print_forest():
    for(sh.type) t, id:
        if t and !sh.par[id]:
            print_tree(id)

def print_tree(id):
    sh.walk_rec(id) nid, depth, descend:
        let p = sh.par[nid]
        let ts = entype_str(sh.type[nid])
        if p:
            print("... #" + nid + "(" + ts + ") <- #" + p)
        else:
            print("#" + nid + "(" + ts + ")")
        descend()

def collect_dfs_ids(id): return collect() que: sh.walk_rec(id) nid, depth, descend:
    que(nid)
    descend()

run_test("ecs/graph/manual/link_and_unlink"):
    let ids = map(4) i: sh.create(ent_visible):
        sh.ren[_] = render { color_clear, color_white, ascii('a' + i) }

    // add 1
    sh.link_after(ids[0], entrel_shrug, ids[1], 0)
    assert sh.par[ids[1]] == ids[0]   // parent
    assert sh.first[ids[0]] == ids[1] // should link 1st
    assert sh.next[ids[0]] == 0       // no...
    assert sh.prev[ids[0]] == 0       // ...peers
    // singleton loop (1)
    assert sh.next[ids[1]] == ids[1]
    assert sh.prev[ids[1]] == ids[1]

    // add 2
    sh.link_after(ids[0], entrel_shrug, ids[2], ids[1])
    assert sh.par[ids[1]] == ids[0]   // parent
    assert sh.first[ids[0]] == ids[1] // should link 1st
    assert sh.next[ids[0]] == 0       // no...
    assert sh.prev[ids[0]] == 0       // ...peers
    // now doubleton loop (1 2)
    assert sh.next[ids[1]] == ids[2]
    assert sh.next[ids[2]] == ids[1]
    assert sh.prev[ids[1]] == ids[2]
    assert sh.prev[ids[2]] == ids[1]

    // add 3
    sh.link_before(ids[0], entrel_shrug, ids[3], ids[1])
    assert sh.par[ids[1]] == ids[0]    // parent
    assert sh.first[ids[0]] == ids[1]  // should link 1st
    assert sh.next[ids[0]] == 0        // no...
    assert sh.prev[ids[0]] == 0        // ...peers
    // tripleton loop (1 2 3)
    assert sh.next[ids[1]] == ids[2]
    assert sh.next[ids[2]] == ids[3]
    assert sh.next[ids[3]] == ids[1]
    assert sh.prev[ids[1]] == ids[3]
    assert sh.prev[ids[2]] == ids[1]
    assert sh.prev[ids[3]] == ids[2]

    // unlink 1
    sh.unlink(ids[1])
    assert sh.par[ids[1]] == 0        // child
    assert sh.next[ids[1]] == 0       // ...now
    assert sh.prev[ids[1]] == 0       // ...unlinked
    assert sh.first[ids[0]] == ids[2] // parent should link 2
    // now doubleton loop (2 3)
    assert sh.next[ids[3]] == ids[2]
    assert sh.next[ids[2]] == ids[3]
    assert sh.prev[ids[3]] == ids[2]
    assert sh.prev[ids[2]] == ids[3]

    // unlink 3
    sh.unlink(ids[3])
    assert sh.par[ids[3]] == 0        // child
    assert sh.next[ids[3]] == 0       // ...now
    assert sh.prev[ids[3]] == 0       // ...unlinked
    assert sh.first[ids[0]] == ids[2] // parent should link 2
    // now singleton loop (2)
    assert sh.next[ids[2]] == ids[2]
    assert sh.prev[ids[2]] == ids[2]

    // unlink 2
    sh.unlink(ids[2])
    assert sh.par[ids[2]] == 0   // child
    assert sh.next[ids[2]] == 0  // ...now
    assert sh.prev[ids[2]] == 0  // ...unlinked
    assert sh.first[ids[0]] == 0 // parent should have no link

    // destroy all sub-test entities
    for(ids) id: sh.set_type(id, ent_none)

let N = 16
let D = 3

run_test("ecs/graph/create"):
    let debug = false
    for(N) i:
        let id = sh.create(ent_visible):
            sh.ren[_] = render { color_clear, color_white, ascii('a' + i) }
        if id >= D:
            if debug: print("link " + (id / D) + " -> " + id)
            sh.add_child(id / D, entrel_shrug, id)
        if debug: print("created " + sh.describe(id))
    for ([3, 9, 10, 11, 4, 12, 13, 14, 5, 15, 16]) id: assert sh.root_of(id) == 1
    for ([6, 7, 8]) id: assert sh.root_of(id) == 2

for([
    [1, 3, 9, 10, 11, 4, 12, 13, 14, 5, 15, 16],
    [2, 6, 7, 8],
]) expect:
    let debug = false
    let root = expect[0]
    run_test("ecs/graph/dfs/enter/#" + root):
        let ids = collect() que: sh.walk_rec(root) id, depth, descend:
            if debug: print("dfs_enter depth:" + depth + "\t" + sh.describe(id))
            que(id)
            descend()
        assert ids.equal(expect)

for([
    [9, 10, 11, 3, 12, 13, 14, 4, 15, 16, 5, 1],
    [6, 7, 8, 2],
]) expect:
    let debug = false
    let root = expect[expect.length-1]
    run_test("ecs/graph/dfs/exit/#" + root):
        let ids = collect() que: sh.walk_rec(root) id, depth, descend:
            descend()
            if debug: print("dfs_exit depth:" + depth + "\t" + sh.describe(id))
            que(id)
        assert ids.equal(expect)

for([
    [1, 3, 4, 5, 9, 10, 11, 12, 13, 14, 15, 16],
    [2, 6, 7, 8],
]) expect:
    let debug = false
    let root = expect[0]
    run_test("ecs/graph/bfs/enter/#" + root):
        let ids = collect() que:
            que(root)
            sh.walk_rec(root) id, depth, descend:
                sh.walk_next(sh.first[id]) nid:
                    if debug: print("bfs_enter depth:" + depth + "\t" + sh.describe(nid))
                    que(nid)
                descend()
        assert ids.equal(expect)

for([
    [9, 10, 11, 12, 13, 14, 15, 16, 3, 4, 5, 1],
    [6, 7, 8, 2],
]) expect:
    let debug = false
    let root = expect[expect.length-1]
    run_test("ecs/graph/bfs/exit/#" + root):
        let ids = collect() que:
            sh.walk_rec(root) id, depth, descend:
                descend()
                sh.walk_next(sh.first[id]) nid:
                    if debug: print("bfs_exit depth:" + depth + "\t" + sh.describe(nid))
                    que(nid)
            que(root)
        assert ids.equal(expect)

run_test("ecs/graph/destroy/unlink/siblings"):
    let pre_ids = collect(): sh.walk_next(sh.first[3], _)
    assert pre_ids.equal([9, 10, 11])
    sh.set_type(10, ent_none)
    let post_ids = collect(): sh.walk_next(sh.first[3], _)
    assert post_ids.equal([9, 11])

run_test("ecs/graph/destroy/unlink/cascades"):
    // setup
    sh.set_type(4, sh.type[4] | ent_cascade)
    // root node children...
    assert sh.type[1] != 0 // exists
    assert sh.type[3] != 0 // exists
    assert sh.type[4] != 0 // exists
    assert sh.type[5] != 0 // exists
    assert sh.par[3] == 1
    assert sh.par[4] == 1
    assert sh.par[5] == 1
    // ...and their sibling links
    assert sh.next[3] == 4
    assert sh.next[4] == 5
    assert sh.next[5] == 3
    // the cascade's children
    assert sh.type[12] != 0 // exists
    assert sh.type[13] != 0 // exists
    assert sh.type[14] != 0 // exists
    assert sh.par[12] == 4
    assert sh.par[13] == 4
    assert sh.par[14] == 4

    // delete
    sh.set_type(1, ent_none)
    // should walk alone
    assert collect_dfs_ids(1).equal([1])
    // root node children...
    assert sh.type[1] == 0 // gone
    assert sh.type[3] != 0 // exists
    assert sh.type[4] == 0 // gone
    assert sh.type[5] != 0 // exists
    assert sh.par[3] == 0
    assert sh.par[4] == 0
    assert sh.par[5] == 0
    // ...and their sibling links
    assert sh.next[3] == 0
    assert sh.next[4] == 0
    assert sh.next[5] == 0
    // the cascade's children
    assert sh.type[12] != 0 // exists
    assert sh.type[13] != 0 // exists
    assert sh.type[14] != 0 // exists
    assert sh.par[12] == 0
    assert sh.par[13] == 0
    assert sh.par[14] == 0

run_test("ecs/graph/movement"):
    let debug = false
    if debug:
        print("post unlink cascade")
        print_forest()
    assert collect_dfs_ids(2).equal([2, 6, 7, 8])
    assert collect_dfs_ids(3).equal([3, 9, 11])
    sh.add_child(8, entrel_shrug, 9)
    assert collect_dfs_ids(2).equal([2, 6, 7, 8, 9])
    assert collect_dfs_ids(3).equal([3, 11])
    if debug:
        print("post move")
        print_forest()
