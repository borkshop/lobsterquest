
import sprites
import vec

var sheet_sprites = []::resource

def load_sheet():
    sheet_sprites = load_sprites("sheets.png", 72, xy { 12, 11 }, 132)

enum tile_entity_id:
    tile_none

    // notes: Euia is the nice side of the world. It is forested and has six
    //        mountains, in two ranges, along the northern and southern fringes.
    //        There is a castle in the middle, forests to the west and a fluvial
    //        plain to the east. The player begins their journey in the forest
    //        and must find their way to the north and to the west.
    tile_euia // ⚅

    // capacity: 1
    // notes: Apple trees bear apples, introducing the player to the health
    //        mechanic. The apples restore one empty health container.
    // renew: 1
    tile_apple_tree // 🌳

    // capacity: 1
    // notes: Pine trees exist only in the high mountains. The player must have
    //        one stamina and three hearts to reach them from the outset. They
    //        produce *pine apples* (natch), which restore two hearts of health
    //        instead of one. If the player only has one heart container, the
    //        pine apple gives them their second, extending their range of
    //        travel deeper into the mountains.  Pine trees can also be cut for
    //        their softwood lumber. This is materially necessary to build a
    //        canoe, granting access to Occia and the quest for the Essence of
    //        Water.
    // renew: 1
    tile_pine_tree // 🌲

    // capacity: 1
    // notes: The pear tree is unique and exists only in the forest due west of
    //        Castle Euia. The pear tree drops pears, which are necessary to
    //        extend the player’s stamina so they can travel over mountainous
    //        terrain and survive. This allows the player to find *a flat miner*
    //        and obtain a *pick axe*.
    // renew: 1
    tile_pear_tree // 🌳

    // notes: Clover exist on the plains to the east of Castle Euia. They become
    //        useful in the quest for Occia, where it transpires that they can
    //        be gilded to make a fleur de lis, and then reshaped to make a
    //        trident. This enables the player to restore Herman the Merman and
    //        gain the Essence of Water. This in turn is one of the two
    //        requirements to be granted access to the naughty side of the
    //        world.
    tile_clover // ☘️

    // breed: ram/sheep
    // capacity: 1
    // health: 2
    // notes: Sheep, in general, provide wool which is material necessary for
    //        creating coats, which in turn give access to the north face of the
    //        world.  Sheep may in turn produce mutton if they are killed with a
    //        sword or worse. Meat can extend the health bar to three heart
    //        containers.
    // renew: 1
    // wander: grass
    tile_ewe // 🐑

    // capacity: 1
    // health: 2
    // notes: Rams, however rare, can drop horns. These do not yet figure into
    //        any designed quests but will likely be useful for all kinds of
    //        horn related crafting, especially the restoration of mojical
    //        creatures that require horns, and the creation of mojical
    //        instruments, as well as the post office horn and post offices.
    // renew: 1
    // wander: grass
    tile_ram // 🐏

    // indoor: 1
    // notes: Castle Euia is the seat of Princess Dice, who provides the
    //        exposition for the broadest quest arc: restoring mojick. Her
    //        lieutenants, the guards provide more tangible advice for the early
    //        quest arcs to get access to the north and south.
    tile_castle // 🏰

    // indoor: 1
    // notes: Once the player has obtained precious medals in the mountains,
    //        they need the bank to get the right denominations for various
    //        kinds of metal crafts at the forge. The bannk and forge are
    //        therefore close together.  The bank also foreshadows the quest of
    //        Dysia, where the player will need to get a loan so they can fuel a
    //        rocket and seek the Essences of Power and Fire in the heavens.
    tile_euia_bank // 🏦

    // indoor: 1
    // notes: The forge is a crafting site for changing precious medals into
    //        parts the player can use to make all the various kinds of tools.
    tile_euia_forge // 🏭

    // notes: The player finds Glub along the edge of the Euia River, flowing
    //        east to Occia. Glub provides the clue that the player needs to
    //        build a canoe to go over the east edge of Euia.
    tile_glub // 🐟

    // notes: The major provides a clue that the player must hike into the
    //        mountains to get a pick axe. This in turn unlocks the ability to
    //        use precious medals and create more tools.
    tile_major // 💂‍♂️

    // notes: The captain provides a clue about finding the pear tree so the
    //        player can travel in the mountains. This is necessary to craft
    //        with precious medals.
    tile_captain // 💂‍♀️

    // notes: The player finds a miner in the mountains. The miner gives the
    //        player a clue that they can bump into an adjacent mountain to find
    //        their first pick axe.
    tile_miner // 👨‍🔧

    // notes: Harriet gives the clues that sheep can be shorn with scissors, and
    //        that scissors are made of knives.
    tile_harriet // 🏠

    // notes: Jack introduces the knitting mechanic so you can craft a coat.
    tile_jack // 🏡

    // notes: The boulder fell on a flat miner. Bumping into it frees the miner
    //        and produces the pick axe for the player’s use. This unlocks the
    //        ability to mine for precious medals.
    tile_boulder // ⛰

    // capacity: 10
    // notes: Mountains produce copper. The player may encounter other kinds of
    //        mountains for higher denominations of precious medals later in the
    //        game, but for now they must trade copper up at the bank to get
    //        exact medals necessary for crafting various components at the
    //        forge.
    tile_mountain // ⛰

    // breed: horse
    // notes: The horse exists to fulfill a later stage quest, where the player
    //        has all the five essences and can transmutate the horse into a
    //        unicorn.
    // wander: 1
    tile_horse // 🐴

    // notes: Restoring the unicorn is one of the many mojical creatures that
    //        satisfy the end game condition of restoring all the mojical
    //        creatures.
    tile_unicorn // 🦄

    // notes: Occia is the west face of the world, in the nice hemicube. Occia
    //        is an ocean world, ruled by the merfolk. There are five islands.
    tile_occia // ⚄

    tile_mermaid // 🧜‍♀️

    // notes: The Herman quest is to restore this merman (bottom half obscured)
    //        by reproducing his lost trident. He will then teach you about the
    //        essence of water.
    tile_herman // 🏊‍♂️

    tile_merman // 🧜‍♂️

    // wander: water
    tile_marco // 🤽‍♂️

    tile_octopus // 🐙

    // breed: fish
    // health: 1
    // wander: water
    tile_fish // 🐟

    // breed: puffer fish
    tile_puffer_fish // 🐡

    tile_turtle // 🐢

    // capacity: 100
    // renew: 1
    tile_island // 🏝

    // capacity: 1
    // renew: 1
    tile_date_palm_tree // 🌴

    // capacity: 1
    // renew: 1
    tile_banana_tree // 🌴

    // capacity: 1
    // renew: 1
    tile_coconut_tree // 🌴

    tile_sponge // 🧽

    tile_parrot // 🦜

    tile_occia_bank // 🏦

    tile_borea // ⚃

    // notes: The steam train is the vehicle to carry you on the railway through
    //        the center of the world, spiraling around the inner loop of The
    //        Pole. To bring the train to life, you will need to master the
    //        essence of wind and water.
    tile_steamer // 🚂

    // notes: The north pole is the home of Magie and Magus. They will teach you
    //        the essence of wind, but you must obtain for them an umbrella.
    //        They promise that it’s relevant.
    tile_north_pole // 💈

    // notes: The great pine of Borea was once mojical and glimmered with a
    //        thousand shining lights.
    tile_unlit_tree // 🌲

    tile_lit_tree // 🎄

    // notes: The polar bear has lost its mogical cloak of invisibility.
    tile_bear // 🐻

    tile_polar_bear // ⸪

    // notes: The abdominal snowman is not much of a snowman. It needs some help
    //        to restore its mogical splendor. That may involve fetching a few
    //        items to restore it to its senses.
    tile_abdominal_snowman // ⚪️

    tile_abominable_snowman // ⛄️

    // notes: Caribou used to be able to fly. They were the preferred mode of
    //        boreal transportation before mojick faded.
    tile_caribou // 🦌

    // notes: The whale was once the unicorn of the sea. Leaving its bay might
    //        set him on his journey to mojical restoration. As there is no
    //        Narwhal emoji, the creature just disappears in search of mojick,
    //        thereby completing the quest.
    tile_whale // 🐋

    tile_sal_the_snake // 🐍

    tile_sal_the_mander // 🦎

    tile_infernia // ⚂

    tile_cheese_wizard // 🧙‍♂️

    tile_sand_witch // 🧙‍♀️

    tile_south_pole // 🗼

    tile_oria // ⚁

    tile_jennie // 🧞‍♀️

    tile_gene // 🧞‍♂️

    tile_cactus // 🌵

    tile_bamboo // 🎍

    tile_panda // 🐼

    tile_dysia // ⚀

    tile_sun // ☀️

    tile_sol // 🌞

    tile_moon // 🌙

    tile_lune // 🌝

    // wander: sky
    tile_asteroid // ☄️

    tile_dumbledore // 🐝

    // capacity: 10
    tile_high_mountain // 🏔

    // capacity: 10
    tile_volcano // 🗻

    // indoor: 1
    tile_gym // 🏥

    // indoor: 1
    tile_observatory // 🔭

    // indoor: 1
    tile_justin // 🕰

    tile_nick // ⏰

    // indoor: 1
    tile_bakery // 🏭

    tile_plumber // 👨🏻‍🔧

    tile_genome // 👨🏼‍🌾

    tile_pat // 👨🏻‍🦰

    tile_kris_and_lydia // 🏡

    tile_kitty // 🐈

    tile_tiger // 🐅

    tile_infernia_warning_sign // 🚧

    tile_asia // 🌏

    tile_africa // 🌍

    tile_america // 🌎

let tile_sprite_id = [
    -1, // tile_none
    0, // tile_euia
    1, // tile_apple_tree
    2, // tile_pine_tree
    1, // tile_pear_tree
    3, // tile_clover
    4, // tile_ewe
    5, // tile_ram
    6, // tile_castle
    7, // tile_euia_bank
    8, // tile_euia_forge
    9, // tile_glub
    10, // tile_major
    11, // tile_captain
    12, // tile_miner
    13, // tile_harriet
    14, // tile_jack
    15, // tile_boulder
    15, // tile_mountain
    16, // tile_horse
    17, // tile_unicorn
    0, // tile_occia
    18, // tile_mermaid
    19, // tile_herman
    20, // tile_merman
    21, // tile_marco
    22, // tile_octopus
    9, // tile_fish
    23, // tile_puffer_fish
    24, // tile_turtle
    25, // tile_island
    26, // tile_date_palm_tree
    26, // tile_banana_tree
    26, // tile_coconut_tree
    27, // tile_sponge
    28, // tile_parrot
    7, // tile_occia_bank
    0, // tile_borea
    29, // tile_steamer
    30, // tile_north_pole
    2, // tile_unlit_tree
    31, // tile_lit_tree
    32, // tile_bear
    0, // tile_polar_bear
    33, // tile_abdominal_snowman
    34, // tile_abominable_snowman
    35, // tile_caribou
    36, // tile_whale
    37, // tile_sal_the_snake
    38, // tile_sal_the_mander
    0, // tile_infernia
    39, // tile_cheese_wizard
    40, // tile_sand_witch
    41, // tile_south_pole
    0, // tile_oria
    42, // tile_jennie
    43, // tile_gene
    44, // tile_cactus
    45, // tile_bamboo
    46, // tile_panda
    0, // tile_dysia
    47, // tile_sun
    48, // tile_sol
    49, // tile_moon
    50, // tile_lune
    51, // tile_asteroid
    52, // tile_dumbledore
    53, // tile_high_mountain
    54, // tile_volcano
    55, // tile_gym
    56, // tile_observatory
    57, // tile_justin
    58, // tile_nick
    8, // tile_bakery
    59, // tile_plumber
    60, // tile_genome
    61, // tile_pat
    14, // tile_kris_and_lydia
    62, // tile_kitty
    63, // tile_tiger
    64, // tile_infernia_warning_sign
    65, // tile_asia
    66, // tile_africa
    67, // tile_america
]

enum item_entity_id:
    item_none

    // quantity: 1
    // tip: A delicious red apple.
    // use: health
    item_apple // 🍎

    // quantity: 2
    // tip: A delicious pine apple.
    // use: health
    item_pine_apple // 🍍

    // quantity: 1
    // tip: The fruit that comes in pears.
    // use: stamina
    item_pear // 🍐

    // tip: The lumber of a hardwood tree.
    item_hardwood // 🌳

    // tip: The lumber of a softwood tree.
    item_softwood // 🌲

    // tip: Just shy of lucky.
    item_clover // ☘️

    // tip: Mutton for dinner. Mutton for breakfast.
    // use: health
    item_mutton // 🍖

    // tip: Tell a yarn. Spin a tale.
    item_yarn // 🧶

    // tip: Copper is a precious medal.
    item_copper // 🥉

    // tip: Silver is a precious medal.
    item_silver // 🥈

    // tip: Gold is a precious medal.
    item_gold // 🥇

    item_link // 🔗

    item_bolt // 🔩

    item_gear // ⚙️

    // quantity: 1
    // use: damage
    item_knife // 🔪

    item_shovel // 🥄

    item_wrench // 🔧

    item_pick_axe // ⛏

    item_bicycle // 🚲

    item_hook // ⚓️

    item_hammer // 🔨

    item_shield // 🛡

    item_chain // ⛓

    item_scissors // ✂️

    item_hammer_and_pick // ⚒

    item_hammer_and_wrench // 🛠

    // quantity: 2
    // use: damage
    item_sword // 🗡

    // quantity: 4
    // use: damage
    item_zweihander // ⚔️

    item_basket // 🗑

    // persists: 1
    // quantity: 20
    // use: carry
    item_cart // 🛒

    item_fishing_rod // 🎣

    item_barrel // 🛢

    item_knitting_needles // 🥢

    // persists: 1
    // quantity: 1
    // use: float
    item_canoe // 🛶

    // persists: 1
    // quantity: 1
    // use: warm
    item_coat // 🧥

    item_fleur // ⚜️

    // quantity: 3
    // use: weapon
    item_trident // 🔱

    // persists: 1
    // use: hydration
    item_water // 💧

    // quantity: 1
    // tip: I’m underdeveloped.
    // use: health
    item_coconut // 🥥

    // quantity: 1
    // tip: I’m underdeveloped.
    // use: health
    item_banana // 🍌

    // quantity: 1
    // tip: I’m underdeveloped.
    // use: health
    item_date // 📆

    // quantity: 2
    // tip: I’m underdeveloped.
    // use: health
    item_fish // 🐟

    // tip: I’m underdeveloped.
    item_sand // 🏝

    // tip: I’m underdeveloped.
    item_alembic // ⚗️

    // tip: I’m underdeveloped.
    item_turtle // 🐢

    // tip: I’m underdeveloped.
    item_snail // 🐌

    // persists: 1
    // use: wind
    item_wind // 💨

    // notes: No recipe. Needed to restore the Boreal Tree.
    item_light_bulb // 💡

    // notes: No recipe. Needed to restore the polar bear.
    item_lab_coat // 🥼

    // notes: No recipe. Needed to restore the snowman.
    item_carrot // 🥕

    // persists: 1
    // use: space flight
    item_rocket // 🚀

    item_fuel // ⛽️

    item_cactus // 🌵

    // persists: 1
    // use: zoning
    item_key_to_dysia // 🗝

    // tip: Underdeveloped.
    item_loan // 💰

    // persists: 1
    // use: flame
    item_fire // 🔥

    // persists: 1
    // use: charge
    item_power // ⚡️

    item_left_lune // 🌜

    item_right_lune // 🌛

    item_lune // 🌝

    // persists: 1
    // use: mojick
    item_mojick // 🌈

    // use: grow
    item_mushroom // 🍄

    // use: shrink
    item_cake // 🍰

    // notes: Unsure how this can be made.
    item_horn // 🎉

    item_unicorn // 🦄

    // notes: Bay leaves are instrumental in the quest to turn the restore the
    //        whale to a narwhal, the unicorn of the sea.
    item_bay_leaves // 🍃

    item_invisibility_cloak // 🥼

    item_pen // 🖋

    item_needle // 💉

    item_broom // 🧹

let item_sprite_id = [
    -1, // item_none
    68, // item_apple
    69, // item_pine_apple
    70, // item_pear
    1, // item_hardwood
    2, // item_softwood
    3, // item_clover
    71, // item_mutton
    72, // item_yarn
    73, // item_copper
    74, // item_silver
    75, // item_gold
    76, // item_link
    77, // item_bolt
    78, // item_gear
    79, // item_knife
    80, // item_shovel
    81, // item_wrench
    82, // item_pick_axe
    83, // item_bicycle
    84, // item_hook
    85, // item_hammer
    86, // item_shield
    87, // item_chain
    88, // item_scissors
    89, // item_hammer_and_pick
    90, // item_hammer_and_wrench
    91, // item_sword
    92, // item_zweihander
    93, // item_basket
    94, // item_cart
    95, // item_fishing_rod
    96, // item_barrel
    97, // item_knitting_needles
    98, // item_canoe
    99, // item_coat
    100, // item_fleur
    101, // item_trident
    102, // item_water
    103, // item_coconut
    104, // item_banana
    105, // item_date
    9, // item_fish
    25, // item_sand
    106, // item_alembic
    24, // item_turtle
    107, // item_snail
    108, // item_wind
    109, // item_light_bulb
    110, // item_lab_coat
    111, // item_carrot
    112, // item_rocket
    113, // item_fuel
    44, // item_cactus
    114, // item_key_to_dysia
    115, // item_loan
    116, // item_fire
    117, // item_power
    118, // item_left_lune
    119, // item_right_lune
    50, // item_lune
    120, // item_mojick
    121, // item_mushroom
    122, // item_cake
    123, // item_horn
    17, // item_unicorn
    124, // item_bay_leaves
    110, // item_invisibility_cloak
    125, // item_pen
    126, // item_needle
    127, // item_broom
]

enum avatar_entity_id:
    avatar_none

    avatar_toadally_newtral // 🙂

    avatar_cold // 🥶

    avatar_hot // 🥵

    avatar_poisoned // 🤢

let avatar_sprite_id = [
    -1, // avatar_none
    128, // avatar_toadally_newtral
    129, // avatar_cold
    130, // avatar_hot
    131, // avatar_poisoned
]




