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
	"text/template"
)

func main() {
	if err := run(); err != nil {
		log.Fatalf("%s\n", err)
	}
}

const (
	dir = "openmoji"
	res = 72
)

const sheetsTemplate = `
import vec
{{with .Size}}
let sprite_map_size = xy{ {{.X}}, {{.Y}} }
{{end}}
let sprite_count = {{.Paths | len}}
let sprite_resolution = {{.Resolution}}

enum entity_type_ids:
{{range .Names}}    {{.}}
{{end}}
let entity_sprite_indicies = [
{{range .NameIndexToSpriteIndex}}    {{.}},
{{end}}]
`

type Sheets struct {
	Size                   image.Point
	Resolution             int
	Count                  int
	Names                  []string
	NameIndexToSpriteIndex []int
	Paths                  []string
	PathToSpriteIndex      map[string]int
}

func run() error {
	sheets := Sheets{
		Resolution:        res,
		PathToSpriteIndex: make(map[string]int),
	}
	if err := sheets.Collect("sheets/Emoji Quest - Tiles.tsv", "tile"); err != nil {
		return err
	}
	if err := sheets.Collect("sheets/Emoji Quest - Items.tsv", "item"); err != nil {
		return err
	}

	var x, y int
	for x*x < len(sheets.Paths) {
		x++
	}
	for x*y < len(sheets.Paths) {
		y++
	}
	sheets.Size = image.Pt(x, y)

	rect := image.Rectangle{image.ZP, image.Pt(x*res, y*res)}
	sprites := image.NewRGBA(rect)

	for i, loc := range sheets.Paths {
		file, err := os.Open(loc)
		if err != nil {
			return err
		}
		sprite, err := png.Decode(file)
		if err != nil {
			return err
		}
		rect := image.Rectangle{image.ZP, image.Pt(res, res)}.Add(image.Pt((i%x)*res, (i/x)*res))
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

	t, err := template.New("sheets").Parse(sheetsTemplate)
	if err != nil {
		return err
	}
	err = t.Execute(sheetsfile, sheets)
	if err != nil {
		return err
	}

	sheetsfile.Close()

	return nil
}

func (sheets *Sheets) Collect(path string, prefix string) error {
	file, err := os.Open(path)
	if err != nil {
		return err
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
			sheets.Names = append(sheets.Names, name)
			spriteIndex, ok := sheets.PathToSpriteIndex[found]
			if !ok {
				spriteIndex = len(sheets.Paths)
				sheets.PathToSpriteIndex[found] = spriteIndex
				sheets.Paths = append(sheets.Paths, found)
			}
			sheets.NameIndexToSpriteIndex = append(sheets.NameIndexToSpriteIndex, spriteIndex)
		}
	}

	return scanner.Err()
}
