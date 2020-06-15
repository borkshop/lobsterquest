package main

import (
	"io"
	"strings"
)

type EntityDialog struct {
	Entity  string
	Dialogs []Dialog
}

type Dialog struct {
	First    int
	Second   int
	Segments []DialogSegment
}

type DialogSegment struct {
	Text   string
	Sprite int
	Bold   bool
	Italic bool
}

func ReadDialogs(r io.Reader, md *openmojiData, sprites *Sprites) ([]EntityDialog, error) {
	var previousEntity string
	var entityDialogs []EntityDialog
	var dialogs []Dialog

	flush := func() {
		if previousEntity == "" {
			return
		}
		entityDialogs = append(entityDialogs, EntityDialog{
			Entity:  strings.ReplaceAll(previousEntity, " ", "_"),
			Dialogs: dialogs,
		})
		dialogs = nil
	}

	sc := newTableScanner(r, "\t")
	for sc.Expect(1) {
		if dialogField := sc.HeaderIndex("dialog"); dialogField >= 0 {
			for sc.Expect(1) {
				if dialogField >= len(sc.Fields) {
					continue
				}
				entity := sc.Fields[0]
				if strings.HasPrefix(entity, "#") {
					continue
				}
				if entity == "" {
					entity = previousEntity
				} else {
					entity = strings.Split(entity, "/")[0]
					if previousEntity != entity {
						flush()
						previousEntity = entity
					}
				}
				segments := DialogSegments(sc.Fields[dialogField], md, spriteForCode)
				dialogs = append(dialogs, Dialog{
					First:    -1,
					Second:   -1,
					Segments: segments,
				})
			}
		}
	}

	flush()

	return entityDialogs, nil
}

func spriteForCode(code string) int {
	return sprites.PathSprite(mojiDir + "/" + code + ".png")
}

func DialogSegments(text string, mojis *openmojiData, sprite func(code string) int) (segments []DialogSegment) {
	follow := 0
	bold := false
	italic := false
	flush := func(lead int) {
		if follow < lead {
			segments = append(segments, DialogSegment{
				Text:   text[follow:lead],
				Bold:   bold,
				Italic: italic,
			})
			follow = lead
		}
	}
	for lead, r := range text {
		if count, code := mojis.Match(text[lead:]); count > 0 {
			flush(lead)
			segments = append(segments, DialogSegment{
				Sprite: sprite(code),
			})
			follow += count
		} else if r == '/' {
			flush(lead)
			italic = !italic
			follow = lead + 1
		} else if r == '*' {
			flush(lead)
			bold = !bold
			follow = lead + 1
		}
	}
	flush(len(text))
	return
}
