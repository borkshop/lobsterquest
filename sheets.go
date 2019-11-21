// Generates sheets.png and sheets.lobster from the spreadsheets in sheets/
// and the OpenMoji 72x72 assets in the openmoji directory from openmoji.org
// (not checked in)

package main

import (
	"bufio"
	"flag"
	"fmt"
	"image"
	"image/draw"
	"image/png"
	"io"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"text/template"
	"unicode"
)

var sheetsTemplate = template.Must(template.New("sheetsTemplate").Funcs(template.FuncMap{
	"wrap": func(n int, name, prefix, s string) string {
		r := []rune(s)

		var sb strings.Builder
		i := 0
		seek := func(j int) int {
			if j > len(r) {
				return len(r)
			}
			k := j
			for ; j > i; j-- {
				if unicode.IsSpace(r[j]) {
					return j
				}
			}
			for ; k < len(r); k++ {
				if unicode.IsSpace(r[k]) {
					return k
				}
			}
			return len(r)
		}
		skip := func(j int) int {
			for ; j < len(r); j++ {
				if !unicode.IsSpace(r[j]) {
					return j
				}
			}
			return len(r)
		}

		first := prefix + name + ": "
		cont := prefix + strings.Repeat(" ", len(name)+2)

		{
			j := seek(i + n - len(first))
			_, _ = sb.WriteString(first)
			_, _ = sb.WriteString(strings.TrimRightFunc(string(r[i:j]), unicode.IsSpace))
			i = skip(j)
		}

		for i < len(r) {
			_ = sb.WriteByte('\n')
			j := seek(i + n - len(cont))
			_, _ = sb.WriteString(cont)
			_, _ = sb.WriteString(strings.TrimRightFunc(string(r[i:j]), unicode.IsSpace))
			i = skip(j)
		}

		return sb.String()
	},
}).Parse(`
import sprites
import vec

var sheet_sprites = []::resource

def load_sheet():
    sheet_sprites = load_sprites("{{ .ImageOut }}", {{ .Sprites.Resolution }}, xy { {{ .Sprites.Size.X }}, {{ .Sprites.Size.Y }} }, {{ .Sprites.Paths | len }})

{{ template "sheet" .Tiles }}
{{ template "sheet" .Items }}
{{ template "sheet" .Avatars }}

{{ define "sheet" }}{{ $sheet := . -}}

enum {{ $sheet.EntityType }}_entity_id:
    {{ $sheet.EntityType }}_none

{{- range $id, $name := $sheet.Names }}
{{ range $key := $sheet.InfoKeys $id }}{{ with $sheet.Info $id $key }}
{{ wrap 80 $key "    // " . }}
{{- end }}{{ end }}
    {{ $sheet.Symbol $id }} // {{ $sheet.Moji $id }}
{{-   end }}

let {{ $sheet.EntityType }}_sprite_id = [
    -1, // {{ $sheet.EntityType }}_none
{{ range $id, $name := $sheet.Names }}    {{ $sheet.SpriteID $id }}, // {{ $sheet.Symbol $id }}
{{ end }}]
{{ end }}
`))

func main() {
	var (
		sourceDir string
		outBase   string
		sprites   Sprites
	)
	flag.IntVar(&sprites.Resolution, "res", 72, "sprite resolution")
	flag.StringVar(&sourceDir, "dir", "openmoji", "source glyph directory")
	flag.StringVar(&outBase, "out", "sheets", "output basename")
	flag.Parse()

	var (
		tiles   = Sheet{EntityType: "tile"}
		items   = Sheet{EntityType: "item"}
		avatars = Sheet{EntityType: "avatar"}
	)

	for _, sh := range []struct {
		*Sheet
		filename string
	}{
		{&tiles, "sheets/Emoji Quest - Tiles.tsv"},
		{&items, "sheets/Emoji Quest - Items.tsv"},
		{&avatars, "sheets/Emoji Quest - Avatars.tsv"},
	} {
		fmt.Printf("collecting %v moji from %v\n", sh.EntityType, sh.filename)
		if err := sh.CollectFile(sh.filename); err != nil {
			log.Fatalf("failed to collect %v entities from %v: %v", sh.EntityType, sh.filename, err)
		}
		if len(sh.moji) == 0 {
			log.Printf("no moji found in %v", sh.filename)
			continue
		}
		n := sh.FindGlyphs(&sprites, sourceDir)
		if n == 0 {
			log.Fatalf("found no glyphs for %v, missing glyph directory in %q?", sh.filename, sourceDir)
		}
		fmt.Printf("Found %v / %v %v moji glyphs\n", n, len(sh.moji), sh.EntityType)
	}

	if err := sprites.BuildFile(outBase + ".png"); err != nil {
		log.Fatalf("failed to assemble sprites: %v", err)
	}

	if err := writeTemplateFile(outBase+".lobster", sheetsTemplate, struct {
		ImageOut string
		Tiles    *Sheet
		Items    *Sheet
		Avatars  *Sheet
		Sprites  *Sprites
	}{
		outBase + ".png",
		&tiles,
		&items,
		&avatars,
		&sprites,
	}); err != nil {
		log.Fatalf("failed to write entity code: %v", err)
	}
}

// Sheet represents one data sheet of entity information, with reference into
// the global sprite table, and associated info.
type Sheet struct {
	EntityType string
	Names      []string
	flags      [][]string
	moji       []string
	info       []map[string]string
	spriteID   []int
}

func (sheet Sheet) Name(id int) string             { return sheet.Names[id] }
func (sheet Sheet) Flags(id int) []string          { return sheet.flags[id] }
func (sheet Sheet) Moji(id int) string             { return sheet.moji[id] }
func (sheet Sheet) Info(id int, key string) string { return sheet.info[id][key] }
func (sheet Sheet) SpriteID(id int) int            { return sheet.spriteID[id] }
func (sheet Sheet) Symbol(id int) string {
	return fmt.Sprintf("%v_%v", sheet.EntityType, symbolize(sheet.Names[id]))
}
func (sheet Sheet) InfoKeys(id int) []string {
	info := sheet.info[id]
	keys := make([]string, 0, len(info))
	for key := range info {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

func (sheet *Sheet) CollectFile(path string) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	err = sheet.Collect(file)
	if cerr := file.Close(); err == nil {
		err = cerr
	}
	return err
}

func (sheet *Sheet) Collect(r io.Reader) error {
	sc := newTSVScanner(r)
	for sc.Expect(2) {

		name, _ := sc.Field(0)
		moji, _ := sc.Field(1)
		if name == "" || moji == "" {
			continue
		}

		info := make(map[string]string, len(sc.Fields)-2)
		for i := 2; i < len(sc.Fields); i++ {
			if i < len(sc.Header) {
				key := sc.Header[i]
				val := sc.Fields[i]
				info[key] = val
			}
		}

		// name strings may be of the form "specific/general" as in "car/vehicle"
		// split the specific from the general categor{y,ies}
		nameParts := strings.Split(name, "/")

		sheet.Names = append(sheet.Names, nameParts[0])
		sheet.flags = append(sheet.flags, nameParts[1:])
		sheet.info = append(sheet.info, info)
		sheet.moji = append(sheet.moji, moji)
		sheet.spriteID = append(sheet.spriteID, -1)
	}
	return sc.Err()
}

func (sheet *Sheet) FindGlyphs(sprites *Sprites, dir string) (n int) {
	for id, moji := range sheet.moji {
		if sheet.spriteID[id] >= 0 {
			n++
		} else if path := findGlyph(dir, moji); path != "" {
			sheet.spriteID[id] = sprites.PathSprite(path)
			n++
		}
	}
	return n
}

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
		id = len(sprites.Paths)
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

//// utilities

func writeTemplateFile(filename string, t *template.Template, data interface{}) error {
	f, err := os.Create(filename)
	if err == nil {
		err = t.Execute(f, data)
		if cerr := f.Close(); err == nil {
			err = cerr
		}
	}
	return err
}

func readPNGFile(filename string) (image.Image, error) {
	f, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	img, err := png.Decode(f)
	if cerr := f.Close(); err == nil {
		err = cerr
	}
	if err != nil {
		return nil, fmt.Errorf("failed to read png from %q: %w", filename, err)
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

func symbolize(s string) string {
	s = strings.ToLower(s)
	// TODO coalese any non-alphanumerics?
	return strings.Join(strings.Split(s, " "), "_")
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

func newTSVScanner(r io.Reader) tsvScanner {
	sc := tsvScanner{
		Scanner: bufio.NewScanner(r),
	}
	if sc.Scan() {
		sc.Header = sc.Fields
	}
	return sc
}

type tsvScanner struct {
	*bufio.Scanner
	Header []string
	Fields []string
}

func (sc tsvScanner) Field(n int) (string, bool) {
	if n >= len(sc.Fields) {
		return "", false
	}
	return sc.Fields[n], true
}

func (sc *tsvScanner) Expect(numFields int) bool {
	for sc.Scan() {
		if len(sc.Fields) >= numFields {
			return true
		}
	}
	return false
}

func (sc *tsvScanner) Scan() bool {
	if !sc.Scanner.Scan() {
		sc.Fields = nil
		return false
	}
	sc.Fields = strings.Split(sc.Text(), "\t")
	return true
}
