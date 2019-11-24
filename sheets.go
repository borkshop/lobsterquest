// Generates sheets.png and sheets.lobster from the spreadsheets in sheets/
// and the OpenMoji 72x72 assets in the openmoji directory from openmoji.org
// (not checked in)

package main

//go:generate go run sheets.go

import (
	"bufio"
	"flag"
	"fmt"
	"image"
	"image/draw"
	"image/png"
	"io"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"text/template"
	"unicode"
)

var tmplFuncs = template.FuncMap{
	"wrap": wrapLines,
	"special": func(key string) bool {
		switch key {
		case "moji", "SpriteID":
			return true
		default:
			return false
		}
	},
}

var sheetsTemplate = template.Must(template.New("sheetsTemplate").Funcs(tmplFuncs).Parse(`
import sprites
import vec

def load_sheet_sprites():
    let tex = gl_load_texture("{{ .ImageOut }}")
    assert tex
    return sprite_new_atlas(tex, xy_1i * {{ .Sprites.Resolution }}, xy { {{ .Sprites.Size.X }}, {{ .Sprites.Size.Y }} })

{{- range .Sheets }}{{ template "sheet" . }}
{{ end }}

{{- define "sheet" }}
{{- $sheet := . -}}
{{- $hasMoji := $sheet.HasField "moji" }}

enum {{ $sheet.EntityType }}_entity_id:
    {{ $sheet.EntityType }}_none
{{- range $id, $name := $sheet.Name }}
{{-   $info := index $sheet.Info $id }}
{{    if $info.Comment }}
    //// {{ $name }}
{{-   else }}
    {{ $sheet.EntityType }}_{{ $name }}{{ if $hasMoji }} // {{ $info.moji }}{{ end }}
{{-     range $key, $val := $info }}{{ if not (special $key) }}{{ with $val }}
{{        wrap 80 $key "    // " (print .) }}
{{-     end }}{{ end }}{{ end }}
{{-   end }}
{{- end }}

{{-    if $hasMoji }}

let {{ $sheet.EntityType }}_sprite_id = [
    -1, // {{ $sheet.EntityType }}_none
{{-   range $id, $name := $sheet.Name }}
{{-     $info := index $sheet.Info $id }}
{{-     if not $info.Comment }}
    {{ $info.SpriteID }}, // {{ $sheet.EntityType }}_{{ $name }}
{{-     end }}
{{-   end }}
]
{{- end }}

{{- end }}
`))

var (
	verbose bool
	mojiDir string
	sprites Sprites
)

func main() {
	log.SetFlags(0)

	flag.BoolVar(&verbose, "v", false, "enable verbose loggging")
	flag.StringVar(&mojiDir, "moji-dir", "openmoji", "source glyph directory")
	flag.IntVar(&sprites.Resolution, "res", 72, "sprite resolution")
	flag.Parse()

	baseName := flag.Arg(0)
	if baseName == "" {
		progName := os.Args[0]
		baseName = filepath.Base(progName)
		baseName = strings.TrimSuffix(baseName, filepath.Ext(baseName))
		if verbose {
			log.Printf("INFO: inferred baseName %q from program name %q", baseName, progName)
		}
	}

	ents, err := ioutil.ReadDir(baseName)
	if err != nil {
		log.Fatalf("failed to read sheets directory: %v", err)
	}
	log.Printf("processing %v entries found in %q", len(ents), baseName)

	sheets := make([]Sheet, 0, len(ents))
	for _, ent := range ents {
		filename := filepath.Join(baseName, ent.Name())
		if verbose {
			log.Printf("")
			log.Printf("INFO: processing %q", filename)
		}
		if sheet, err := loadSheet(filename); isWarning(err) {
			log.Printf("WARNING: skipping %q: %v", filename, err)
			continue
		} else if err != nil {
			log.Fatalf("FATAL: failed to load %q: %v", filename, err)
		} else {
			sheets = append(sheets, sheet)
		}
	}
	sort.Slice(sheets, func(i, j int) bool {
		return sheets[i].EntityType < sheets[j].EntityType
	})

	atlasFile := baseName + ".png"
	{
		if verbose {
			log.Printf("")
		}
		if err := sprites.BuildFile(atlasFile); err != nil {
			log.Fatalf("FATAL: failed to assemble sprite atlas: %v", err)
		}
		if verbose {
			log.Printf("INFO: assembled sprite atlas in %q", atlasFile)
		}
	}

	codeFile := baseName + ".lobster"
	{
		if verbose {
			log.Printf("")
		}

		if err := writeTemplateFile(codeFile, sheetsTemplate, struct {
			ImageOut string
			Sheets   []Sheet
			Sprites  Sprites
		}{atlasFile, sheets, sprites}); err != nil {
			log.Fatalf("FATAL: failed to compile sheet code: %v", err)
		}
		if verbose {
			log.Printf("INFO: compiled sheet code in %q", codeFile)
		}
	}
}

func loadSheet(filename string) (sheet Sheet, _ error) {
	if strings.ToLower(filepath.Ext(filename)) != ".tsv" {
		return sheet, warn("non tsv file")
	}

	sheetName := parseSheetName(filepath.Base(filename))
	if sheetName == "" {
		return sheet, fmt.Errorf("unable to parse sheet name from file name")
	}

	if err := sheet.ReadFile(filename); err != nil {
		return sheet, err
	}

	if sheet.EntityType != sheetName {
		return sheet, warn("file sheet name %q and first header cell type name %q mismatch", sheetName, sheet.EntityType)
	}

	if verbose {
		log.Printf("INFO: read %q sheet with %v entries", sheetName, len(sheet.Name))
	}

	if sheet.HasField("moji") {
		m := len(sheet.Name)
		n := sheet.FindGlyphs(&sprites, mojiDir)
		if n == 0 {
			return sheet, fmt.Errorf("FATAL: found no %q moji glyphs, missing glyph directory in %q?", sheet.EntityType, mojiDir)
		}

		if verbose {
			log.Printf("INFO: found %v / %v %q moji glyphs", n, m, sheet.EntityType)
		}
	}

	return sheet, nil
}

// Sheet represents one data sheet of entity information, with reference into
// the global sprite table, and associated info.
type Sheet struct {
	EntityType string
	Fields     []string
	Name       []string
	Info       []map[string]interface{}
}

func (sheet Sheet) HasField(name string) bool {
	for _, field := range sheet.Fields {
		if field == name {
			return true
		}
	}
	return false
}

func (sheet *Sheet) ReadFile(path string) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	err = sheet.Read(file)
	if cerr := file.Close(); err == nil {
		err = cerr
	}
	return err
}

func (sheet *Sheet) Read(r io.Reader) error {
	const flagsField = "Flags"

	sc := newTSVScanner(r)

	entityType, hasFlags, err := parseEntityType(sc.Header[0])
	if err != nil {
		return err
	}
	sheet.EntityType = entityType

	fields := sc.Header[1:]

	if hasFlags {
		sheet.Fields = []string{flagsField}
	} else {
		sheet.Fields = []string{}
	}
	sheet.Fields = append(sheet.Fields, fields...)

	for sc.Expect(1) {
		name, _ := sc.Field(0)

		if len(sc.Fields) == 1 {
			sheet.Name = append(sheet.Name, name)
			sheet.Info = append(sheet.Info, map[string]interface{}{
				"Comment": true,
			})
			continue
		}

		var flags []string
		if hasFlags {
			nameParts := strings.Split(name, "/")
			name = nameParts[0]
			flags = nameParts[:0]
			for _, part := range nameParts[1:] {
				if part = symbolize(part); part != "" {
					flags = append(flags, part)
				}
			}
		}

		name = symbolize(name)
		if name == "" {
			continue
		}

		info := make(map[string]interface{}, 2*len(sc.Fields))
		if flags != nil {
			info[flagsField] = flags
		}
		for i, field := range fields {
			if val, defined := sc.Field(i + 1); defined {
				info[field] = val
			}
		}

		sheet.Name = append(sheet.Name, name)
		sheet.Info = append(sheet.Info, info)
	}
	return sc.Err()
}

func parseSheetName(baseFilename string) string {
	parts := strings.SplitN(baseFilename, " - ", 2)
	if len(parts) != 2 {
		return ""
	}
	sheetName := parts[1]
	sheetName = strings.TrimSuffix(sheetName, filepath.Ext(sheetName))
	sheetName = strings.TrimSuffix(sheetName, "s")
	sheetName = symbolize(sheetName)
	return sheetName
}

func parseEntityType(entityType string) (_ string, hasFlags bool, _ error) {
	const flagsSuffix = "/flags..."

	if entityType == "" {
		return "", false, warn(`missing entity type header; first header cell must contain entity type name`)
	}

	if hasFlags = strings.HasSuffix(entityType, flagsSuffix); hasFlags {
		entityType = entityType[:len(entityType)-len(flagsSuffix)]
	}

	if !strings.HasSuffix(entityType, " name") {
		return "", false, warn(`first header cell starts with %q, expected ENTITY_TYPE + " name"`, entityType)
	}

	entityType = entityType[:len(entityType)-4]
	entityType = symbolize(entityType)

	return entityType, hasFlags, nil
}

func (sheet *Sheet) FindGlyphs(sprites *Sprites, dir string) (n int) {
	for id := range sheet.Name {
		info := sheet.Info[id]
		mojiVal, hasMoji := info["moji"]
		if !hasMoji {
			continue
		}
		moji, _ := mojiVal.(string)
		if moji == "" {
			continue
		}
		if _, defined := info["SpriteID"]; defined {
			n++
		} else if path := findGlyph(dir, moji); path != "" {
			info["SpriteID"] = sprites.PathSprite(path)
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
	s = strings.TrimSpace(s)
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

func wrapLines(n int, name, prefix, s string) string {
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
}

type warning struct{ error }

func isWarning(err error) bool {
	_, is := err.(warning)
	return is
}

func warn(mess string, args ...interface{}) error {
	return warning{fmt.Errorf(mess, args...)}
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
	fields := strings.Split(sc.Text(), "\t")

	for i := len(fields) - 1; i >= 0 && fields[i] == ""; i-- {
		fields = fields[:i]
	}

	sc.Fields = fields
	return true
}
