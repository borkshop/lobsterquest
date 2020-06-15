// Generates assets/sheets.png and sheets.lobster from the spreadsheets in
// sheets/ and the OpenMoji 72x72 assets in the openmoji directory from
// openmoji.org
// (not checked in)

package main

//go:generate go run .

import (
	"flag"
	"fmt"
	"image"
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
import daia_log

def load_sheet_sprites():
    let tex = gl_load_texture(pakfile "{{ .ImageOut }}")
    assert tex
    return sprite_new_atlas(tex, xy_1i * {{ .Sprites.Resolution }}, xy { {{ .Sprites.Size.X }}, {{ .Sprites.Size.Y }} })

{{- range .Sheets }}{{ template "sheet" . }}
{{ end }}

def draw_emoji_quest_dialog_(entity, turn, flow, sprites):
    switch entity:
{{- range $id, $entityDialog := .Dialogs }}
        case tile_{{ $entityDialog.Entity }}: switch turn:
{{-   range $ei, $dialog := $entityDialog.Dialogs }}
            case {{ $ei }}:
{{-     range $si, $segment := $dialog.Segments }}
{{-       if $segment.Text }}
{{-         if (and $segment.Bold $segment.Italic) }}
                check(gl_set_font_name("data/fonts/Fontin_Sans/Fontin_Sans_BI_45b.otf"), "could not load font")
{{-         else if $segment.Bold }}
                check(gl_set_font_name("data/fonts/Fontin_Sans/Fontin_Sans_B_45b.otf"), "could not load font")
{{-         else if $segment.Italic }}
                check(gl_set_font_name("data/fonts/Fontin_Sans/Fontin_Sans_I_45b.otf"), "could not load font")
{{-         else }}
                check(gl_set_font_name("data/fonts/Fontin_Sans/Fontin_Sans_R_45b.otf"), "could not load font")
{{-         end }}
                gl_set_font_size(50)
                flow_text(flow, "{{ $segment.Text }}")
{{-       else }}
                flow_texture(flow, sprites.get_texture({{ $segment.Sprite }}))
{{-       end }}
{{-     end }}
{{-   end }}
{{  end }}

def draw_emoji_quest_dialog_next_turn(entity, turn):
    return switch entity:
{{- range $id, $entityDialog := .Dialogs }}
        case tile_{{ $entityDialog.Entity }}: turn % {{ $entityDialog.Dialogs | len }}
{{- end }}

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

{{- with $sheet.Meta.enum_flags }}
{{-   $enum_name := (index . 0) }}

enum_flags {{ $enum_name }}:
    {{ $enum_name }}_{{ (index $sheet.Name 0) }} = 0
    {{ $enum_name }}_{{ (index $sheet.Name 1) }} = 1
{{-   range $id, $name := (slice $sheet.Name 2) }}
    {{ $enum_name }}_{{ $name }}
{{-   end }}

let {{ $enum_name }}_entity_ids = [
{{-   range $id, $name := $sheet.Name }}
    {{ $sheet.EntityType }}_{{ $name }},
{{-   end }}
]

{{- end }}

{{- if $hasMoji }}

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

let {{ $sheet.EntityType }}_names = [
    "empty tile",
{{-   range $id, $name := $sheet.OriginalName }}
    "{{ $name }}",
{{- end }}
]

{{- end }}
`))

var (
	verbose   bool
	mojiDir   string
	mojiData  string
	dataDir   string
	atlasFile string
	codeFile  string
	sprites   Sprites
)

func main() {
	log.SetFlags(0)

	flag.BoolVar(&verbose, "v", false, "enable verbose loggging")
	flag.StringVar(&mojiDir, "moji", "../art/openmoji/color/72x72", "source glyph directory")
	flag.StringVar(&mojiData, "mojidata", "../art/openmoji/data/openmoji.csv", "CSV data for available emojis")
	flag.StringVar(&dataDir, "data", "../data", "source data directory")
	flag.StringVar(&codeFile, "code", "../src/sheets.lobster", "target code gen file")
	flag.StringVar(&atlasFile, "atlas", "../assets/sprites.png", "target sprite map file")
	flag.IntVar(&sprites.Resolution, "res", 72, "sprite resolution")
	flag.Parse()

	md, err := readMojis(mojiData)
	if err != nil {
		log.Fatalf("failed to read openmoji data: %v", err)
	}

	ents, err := ioutil.ReadDir(dataDir)
	if err != nil {
		log.Fatalf("failed to read data directory: %v", err)
	}
	log.Printf("processing %v entries found in %q", len(ents), dataDir)

	sheets := make([]Sheet, 0, len(ents))
	for _, ent := range ents {
		filename := filepath.Join(dataDir, ent.Name())
		if verbose {
			log.Printf("")
			log.Printf("INFO: processing %q", filename)
		}
		if sheet, err := loadSheet(filename, md); isWarning(err) {
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

	var dialogs []EntityDialog
	{
		filename := filepath.Join(dataDir, "Emoji Quest - Dialog.tsv")
		file, err := os.Open(filename)
		if err != nil {
			log.Fatalf("failed to read dialog file: %v", err)
		}
		defer file.Close()
		dialogs, err = ReadDialogs(file, md, &sprites)
		if err != nil {
			log.Fatalf("failed to read dialogs: %v", err)
		}
	}

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

	{
		if verbose {
			log.Printf("")
		}

		if err := writeTemplateFile(codeFile, sheetsTemplate, struct {
			ImageOut string
			Sheets   []Sheet
			Dialogs  []EntityDialog
			Sprites  Sprites
		}{atlasFile, sheets, dialogs, sprites}); err != nil {
			log.Fatalf("FATAL: failed to compile sheet code: %v", err)
		}
		if verbose {
			log.Printf("INFO: compiled sheet code in %q", codeFile)
		}
	}
}

func loadSheet(filename string, md *openmojiData) (sheet Sheet, _ error) {
	if strings.ToLower(filepath.Ext(filename)) != ".tsv" {
		return sheet, warn("non tsv file")
	}

	sheetName := parseSheetName(filepath.Base(filename))
	if sheetName == "" {
		return sheet, fmt.Errorf("unable to parse sheet name from file name")
	}

	file, err := os.Open(filename)
	if err != nil {
		return sheet, err
	}
	defer file.Close()

	if err := sheet.ReadFile(file, md, &sprites); err != nil {
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
	EntityType   string
	Fields       []string
	Meta         map[string][]string
	Name         []string
	OriginalName []string
	Info         []map[string]interface{}
}

func (sheet Sheet) HasField(name string) bool {
	for _, field := range sheet.Fields {
		if field == name {
			return true
		}
	}
	return false
}

func (sheet *Sheet) ReadFile(r io.Reader, md *openmojiData, sprites *Sprites) error {
	const flagsField = "Flags"

	sc := newTableScanner(r, "\t")

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

	if len(sc.Meta) > 0 {
		sheet.Meta = make(map[string][]string, len(sc.Meta))
		for _, meta := range sc.Meta {
			sheet.Meta[meta[0]] = meta[1:]
		}
	}

	for sc.Expect(1) {
		originalName, _ := sc.Field(0)
		name := originalName

		if strings.HasPrefix(name, "#") {
			continue
		}

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
			if field != "" {
				if val, defined := sc.Field(i + 1); defined {
					info[field] = val
				}
			}
		}

		sheet.Name = append(sheet.Name, name)
		sheet.OriginalName = append(sheet.OriginalName, originalName)
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

func symbolize(s string) string {
	s = strings.TrimSpace(s)
	s = strings.ToLower(s)
	// TODO coalese any non-alphanumerics?
	return strings.Join(strings.Split(s, " "), "_")
}
