import sheets

def write_daia_file(tiles):
    let content = "import sheets\nlet daia_map_tiles = " + tiles
    write_file("daia_map.lobster", content, 0)

