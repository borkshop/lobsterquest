package main

import (
	"fmt"
	"image"
	"image/draw"
	"image/png"
	"os"
)

// Sprites is the global sprite sheet, containing glyph renderings for all
// entities.
type Sprites struct {
	Resolution int
	Size       image.Point    // grid size
	Paths      []string       // glyph file path
	PathID     map[string]int // path to spriteID
}

// Allocates or retrieves a sprite for the given path and returns the
// corresponding sprite index.
func (sprites *Sprites) PathSprite(path string) int {
	id, ok := sprites.PathID[path]
	if !ok {
		id = len(sprites.Paths) + 1
		if sprites.PathID == nil {
			sprites.PathID = make(map[string]int)
		}
		sprites.PathID[path] = id
		sprites.Paths = append(sprites.Paths, path)
	}
	return id
}

// BuildFile writes a sprite map.
func (sprites *Sprites) BuildFile(filename string) error {
	img, err := sprites.Build()
	if err == nil {
		err = writePNGFile(filename, img)
	}
	return err
}

// Build constructs a sprite map image from the reserved sprites.
func (sprites *Sprites) Build() (image.Image, error) {
	sprites.Size = gridSize(len(sprites.Paths))
	tile := image.Rectangle{image.ZP, image.Pt(sprites.Resolution, sprites.Resolution)}
	stride := sprites.Size.X
	img := image.NewRGBA(image.Rectangle{image.ZP, sprites.Size.Mul(sprites.Resolution)})
	for i, path := range sprites.Paths {
		sprite, err := readPNGFile(path)
		if err != nil {
			return nil, err
		}
		slot := tile.Add(image.Pt(i%stride, i/stride).Mul(sprites.Resolution))
		draw.Draw(img, slot, sprite, image.ZP, draw.Src)
	}
	return img, nil
}

func writePNGFile(filename string, img image.Image) error {
	f, err := os.Create(filename)
	if err != nil {
		return err
	}
	err = png.Encode(f, img)
	if cerr := f.Close(); err == nil {
		err = cerr
	}
	if err != nil {
		return fmt.Errorf("failed to write png into %q: %w", filename, err)
	}
	return nil
}

// Returns the dimensions of the most square-like rectangle that fits at least
// the given area.
func gridSize(area int) image.Point {
	var x, y int
	for x*x < area {
		x++
	}
	for x*y < area {
		y++
	}
	return image.Pt(x, y)
}
