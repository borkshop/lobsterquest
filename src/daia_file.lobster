import sheets

def write_daia_file(tiles, flags):
    let content = "import sheets\nlet daia_map_tiles = " + tiles + "\nlet daia_map_flags = " + flags + "\n"
    write_file("daia_map.lobster", content, 0)

