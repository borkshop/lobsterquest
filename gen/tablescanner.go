package main

import (
	"bufio"
	"io"
	"strings"
)

func newTableScanner(r io.Reader, delimiter string) tableScanner {
	sc := tableScanner{
		Scanner:   bufio.NewScanner(r),
		Delimiter: delimiter,
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

type tableScanner struct {
	*bufio.Scanner
	Delimiter string
	Meta      [][]string
	Header    []string
	Fields    []string
}

func (sc tableScanner) Field(n int) (string, bool) {
	if n >= len(sc.Fields) {
		return "", false
	}
	return sc.Fields[n], true
}

func (sc tableScanner) HeaderIndex(name string) int {
	for i, field := range sc.Header {
		if field == name {
			return i
		}
	}
	return -1
}

func (sc *tableScanner) Expect(numFields int) bool {
	for sc.Scan() {
		if len(sc.Fields) >= numFields {
			return true
		}
	}
	return false
}

func (sc *tableScanner) Scan() bool {
	if !sc.Scanner.Scan() {
		sc.Fields = nil
		return false
	}
	fields := strings.Split(sc.Text(), sc.Delimiter)

	for i := len(fields) - 1; i >= 0 && fields[i] == ""; i-- {
		fields = fields[:i]
	}

	sc.Fields = fields
	return true
}
