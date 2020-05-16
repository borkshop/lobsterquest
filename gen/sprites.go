package main

import (
	"fmt"
	"image"
	"image/draw"
	"image/png"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

// Sprites is the global sprite sheet, containing glyph renderings for all entities.
type Sprites struct {
	Resolution int
	Size       image.Point    // grid size
	Paths      []string       // glyph file path
	PathID     map[string]int // path to spriteID
}

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

func (sprites *Sprites) BuildFile(filename string) error {
	img, err := sprites.Build()
	if err == nil {
		err = writePNGFile(filename, img)
	}
	return err
}

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

func findGlyph(dir, glyph string) string {
	codes := []rune(glyph)
	hexCodes := make([]string, len(codes))
	for i, code := range codes {
		hexCodes[i] = strconv.FormatUint(uint64(code), 16)
	}
	for i := len(hexCodes); i > 0; i-- {
		path := filepath.Join(dir, strings.Join(hexCodes[:i], "-")+".png")
		if _, err := os.Stat(path); err == nil {
			return path
		}
	}
	return filepath.Join(dir, "25A1.png")
}

func gridSize(n int) image.Point {
	var x, y int
	for x*x < n {
		x++
	}
	for x*y < n {
		y++
	}
	return image.Pt(x, y)
}
