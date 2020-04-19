
# 🧙‍♀️ Emoji Quest 🧝‍♂️

<nobr>🌈 <b>Mojick</b></nobr> has faded from the world.
<nobr>🐉 <b>Mojical creatures</b> 🦄</nobr> have been lost for an <nobr>age 🕰</nobr>.
You, <nobr>😬 <b>Adventurer</b> 😲</nobr>, are charged to wander the
<nobr>🎲 <b>Faces of Daia</b> 🎲</nobr> to find and restore the
<nobr><b>💨 essences 💦 of 🔥 mojick ⚡️</b></nobr>,
<nobr>❓ interrogating</nobr>,
<nobr>🪓 harvesting</nobr>,
<nobr>✂️ crafting</nobr>, and,
where the cause is just,
<nobr>⚔️ fighting</nobr>
<b>emojis</b> to restore mojick to all the lands.

![Editor Preview](editor.png)

Emoji Quest is in development and brought to you by the makers of [Escape
Peruácru Island][peruacru], [BØRK: Escape the Scandinavian Home Furnishings
Labyrinth][bork], a [weird color picker][color], an [Elvish][elvish]
transcriber, an Elvish interactive [Map of Middle-Earth][elfmap], and some
[influential][q] JavaScript [stuff][commonjs].
⚠️&nbsp;May contain puns&nbsp;⚠️.

* 🎮 [Discord Chat][discord]
* 📈 [Spreadsheets][spreadsheets]
* 🕷 [Web Page][web]
* 🦞 [Lobster Language][lobster]
* 🧛‍♂️ [Patreon Donations][patreon]

# 🏗👷‍♀️ Contributing 👷‍♂️🚧

Use [direnv](https://direnv.net/) to automatically set up your PATH when
working within the EmojiQuest repository.
All further instructions assume `scripts` and `lobster/bin` are on your
executable path.

Build a lobster executable.
Detailed instructions are in `lobster/docs/getting_started.html`.

```sh
cd lobster/dev
cmake -DCMAKE_BUILD_TYPE=Release
make -j8
```

Run `go generate ./gen` to build the sprite atlas and other game code from game
data.

To run the Emoji Quest world editor, there is an `edice` script for
convenience on Linux systems.
Otherwise, the program starts at `src/editor.lobster`.

```sh
lobster/bin/lobster src/editor.lobster
```

The editor key bindings are:

* q to quit
* hjkl to navigate
* return to toggle tile picker mode
* f to fill with picked tile
* d to delete the picked tile
* c to copy the tile under the cursor
* x to cut (copy and delete) the tile under the cursor
* s to toggle sea/water
* a to flood/drain entire face with/of water
* v to toggle volcanic magma
* w to write out map file

To update the lobster version, use `git subtree` and rebuild the executable.

```sh
git subtree pull --prefix=lobster https://github.com/aardappel/lobster master
```

[Lobster][lobster], [OpenMoji][openmoji], and game data [spreadsheets] are
checked in.

To update Openmoji, run `update-openmoji [ref]` and then run `go generate
./gen` to update the generated assets.

To update spreadsheets, download the [spreadsheets] into the `data` directory
and again run `go generate ./gen` to update the generated assets.

  [peruacru]: https://peruacru.then.land
  [bork]: http://børk.com
  [color]: http://color.codi.sh
  [elvish]: https://tengwar.3rin.gs
  [elfmap]: http://3rin.gs
  [q]: https://www.npmjs.com/package/q
  [commonjs]: http://wiki.commonjs.org/wiki/Modules/1.1

  [discord]: https://discordapp.com/channels/692076552514699426/692076553017884723
  [spreadsheets]: https://docs.google.com/spreadsheets/d/1U8JJM-g7Br0ePrjH7kg7tJ3N2eb0Mab2y5GDiJo1Tx8/edit#gid=97282066
  [web]: https://github.com/borkshop/emojiquest.app
  [lobster]: http://strlen.com/lobster/
  [patreon]: https://www.patreon.com/kriskowal
  [openmoji]: https://openmoji.org
