package main

import (
	"os"
	"strconv"
	"strings"
)

type openmojiData struct {
	branches map[string]struct{}
	matches  map[string]string // hexcode
}

func readMojis(path string) (*openmojiData, error) {
	file, err := os.Open(path)
	defer file.Close()

	data := &openmojiData{
		branches: make(map[string]struct{}),
		matches:  make(map[string]string),
	}

	if err != nil {
		return nil, err
	}

	sc := newTableScanner(file, ",")
	for sc.Expect(1) {
		hexCode, exists := sc.Field(1)
		if !exists {
			continue
		}
		moji := mojiFromHexCode(hexCode)
		for i := 0; i < len(moji)-1; i++ {
			data.branches[moji[0:i]] = struct{}{}
		}
		data.matches[moji] = hexCode
	}

	return data, sc.Err()
}

// Match attempts to match the beginning of the given byte slice to one of the
// avilable OpenMoji emojis.
// Returns the number of bytes consumed and the hex code of the moji if one is
// present.
// Returns zeroes otherwise.
// This horrible algorithm is ripe for optimization but brrr.
func (md *openmojiData) Match(str string) (count int, hexCode string) {
	consider := func(i int) bool {
		if hc, exists := md.matches[str[0:i]]; exists {
			count = i
			hexCode = hc
		}
		_, exists := md.branches[str[0:i]]
		return !exists
	}
	for i := range str {
		if consider(i) {
			break
		}
	}
	consider(len(str))
	return
}

func mojiFromHexCode(h string) string {
	var bs []rune
	for _, r := range strings.Split(h, "-") {
		ri, _ := strconv.ParseInt(r, 16, 64)
		bs = append(bs, rune(ri))
	}
	return string(bs)
}
