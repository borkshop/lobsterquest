package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestOpenmojiData(t *testing.T) {
	md, err := readMojis("../art/openmoji/data/openmoji.csv")
	require.NoError(t, err)

	{
		c, _ := md.Match("a")
		assert.Equal(t, 0, c)
	}
	{
		c, hex := md.Match("😬")
		assert.Equal(t, 4, c)
		assert.Equal(t, "1F62C", hex)
	}
	{
		c, hex := md.Match("🐈️")
		assert.Equal(t, 4, c)
		assert.Equal(t, "1F408", hex)
	}
	{
		c, hex := md.Match("🐈️ ")
		assert.Equal(t, 4, c)
		assert.Equal(t, "1F408", hex)
	}
	{
		c, hex := md.Match("🐟️")
		assert.Equal(t, 4, c)
		assert.Equal(t, "1F41F", hex)
	}
	{
		c, hex := md.Match("🐟")
		assert.Equal(t, 4, c)
		assert.Equal(t, "1F41F", hex)
	}
	t.Logf("---\n")
	for i, r := range "🐟️ " {
		t.Logf("%x %d\n", r, i)
	}
	t.Logf("---\n")
	for i, r := range "🐟 " {
		t.Logf("%x %d\n", r, i)
	}
}
