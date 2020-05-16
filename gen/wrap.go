package main

import (
	"strings"
	"unicode"
)

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
