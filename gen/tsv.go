package main

import (
	"bufio"
	"io"
	"strings"
)

func newTSVScanner(r io.Reader) tsvScanner {
	sc := tsvScanner{
		Scanner: bufio.NewScanner(r),
	}
	for sc.Scan() {
		if len(sc.Fields) > 1 && sc.Fields[0] == "#meta" {
			sc.Meta = append(sc.Meta, sc.Fields[1:])
		} else {
			sc.Header = sc.Fields
			break
		}
	}
	return sc
}

type tsvScanner struct {
	*bufio.Scanner
	Meta   [][]string
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
