// Generates sprites.png and sheets.lobster from the spreadsheets in sheets/
// and the OpenMoji 72x72 assets in the openmoji directory from openmoji.org
// (not checked in)

package main

import (
	"bufio"
	"fmt"
	"image"
	"image/draw"
	"image/png"
	"log"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	if err := run(); err != nil {
		log.Fatalf("%s\n", err)
	}
}

const dir = "openmoji"

func run() error {
	id := 0
	var names []string
	var locs []string
	pathToSpriteIndex := make(map[string]int)
	nameIndexToSpriteIndex := make(map[int]int)
	var err error

	id, names, locs, err = collect("sheets/Emoji Quest - Tiles.tsv", "tile", id, names, locs, pathToSpriteIndex, nameIndexToSpriteIndex)
	if err != nil {
		return err
	}
	id, names, locs, err = collect("sheets/Emoji Quest - Items.tsv", "item", id, names, locs, pathToSpriteIndex, nameIndexToSpriteIndex)
	if err != nil {
		return err
	}

	var x, y int
	for x*x < len(locs) {
		x++
	}
	for x*y < len(locs) {
		y++
	}

	rect := image.Rectangle{image.ZP, image.Pt(x*72, y*72)}
	sprites := image.NewRGBA(rect)

	for i, loc := range locs {
		file, err := os.Open(loc)
		if err != nil {
			return err
		}
		sprite, err := png.Decode(file)
		if err != nil {
			return err
		}
		rect := image.Rectangle{image.ZP, image.Pt(72, 72)}.Add(image.Pt((i%x)*72, (i/x)*72))
		draw.Draw(sprites, rect, sprite, image.ZP, draw.Src)
	}

	spritesfile, err := os.Create("sprites.png")
	if err != nil {
		return err
	}
	png.Encode(spritesfile, sprites)
	spritesfile.Close()

	sheetsfile, err := os.Create("sheets.lobster")
	if err != nil {
		return err
	}
	fmt.Fprintf(sheetsfile, "import vec\n")
	fmt.Fprintf(sheetsfile, "namespace sheets\n")
	fmt.Fprintf(sheetsfile, "\n")
	fmt.Fprintf(sheetsfile, "enum names:\n")
	for _, name := range names {
		fmt.Fprintf(sheetsfile, "    %s\n", name)
	}
	fmt.Fprintf(sheetsfile, "\n")
	fmt.Fprintf(sheetsfile, "let sprites = [\n")
	for i := range names {
		j := nameIndexToSpriteIndex[i]
		fmt.Fprintf(sheetsfile, "    xy{ %d, %d },\n", (j%x)*72, (j/x)*72)
	}
	fmt.Fprintf(sheetsfile, "]\n")
	sheetsfile.Close()

	return nil
}

func collect(path string, prefix string, id int, names, locs []string, pathToSpriteIndex map[string]int, nameIndexToSpriteIndex map[int]int) (int, []string, []string, error) {
	file, err := os.Open(path)
	if err != nil {
		return id, names, locs, err
	}

	scanner := bufio.NewScanner(file)
	scanner.Scan()
	for scanner.Scan() {
		columns := strings.Split(scanner.Text(), "\t")
		if len(columns) < 2 {
			continue
		}

		name, emoji := columns[0], columns[1]
		if name == "" || emoji == "" {
			continue
		}

		loc := ""
		del := ""
		found := filepath.Join(dir, "25A1.png")
		for _, c := range emoji {
			loc += del + fmt.Sprintf("%x", c)
			del = "-"
			path := filepath.Join(dir, loc+".png")
			_, err := os.Stat(path)
			if err == nil {
				found = filepath.Join(dir, loc+".png")
			}
		}

		name = prefix + "_" + strings.Join(strings.Split(strings.Split(name, "/")[0], " "), "_")

		if found != "" {
			nameIndex := len(names)
			names = append(names, name)
			stencilIndex, ok := pathToSpriteIndex[found]
			if !ok {
				stencilIndex = len(locs)
				pathToSpriteIndex[found] = stencilIndex
				locs = append(locs, found)
			}
			nameIndexToSpriteIndex[nameIndex] = stencilIndex
		}
	}

	return id, names, locs, scanner.Err()
}
