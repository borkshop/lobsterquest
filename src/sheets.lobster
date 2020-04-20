
import sprites
import vec

def load_sheet_sprites():
    let tex = gl_load_texture(pakfile "../assets/sprites.png")
    assert tex
    return sprite_new_atlas(tex, xy_1i * 72, xy { 13, 12 })

enum avatar_entity_id:
    avatar_none

    avatar_content // 🙂

    avatar_rocket // 🚀

    avatar_boating // 🚣‍♀️

    avatar_climbing // 🧗‍♀️

    avatar_swimming // 🏊‍♀️

    avatar_poisoned // 🤢

    avatar_injured // 🤕

    avatar_weary // 😩

    avatar_cold // 🥶

    avatar_hot // 🥵

    avatar_dizzy // 😵

    avatar_woozy // 🥴

enum_flags avatar_state:
    avatar_state_content = 0
    avatar_state_rocket = 1
    avatar_state_boating
    avatar_state_climbing
    avatar_state_swimming
    avatar_state_poisoned
    avatar_state_injured
    avatar_state_weary
    avatar_state_cold
    avatar_state_hot
    avatar_state_dizzy
    avatar_state_woozy

let avatar_state_entity_ids = [
    avatar_content,
    avatar_rocket,
    avatar_boating,
    avatar_climbing,
    avatar_swimming,
    avatar_poisoned,
    avatar_injured,
    avatar_weary,
    avatar_cold,
    avatar_hot,
    avatar_dizzy,
    avatar_woozy,
]

let avatar_sprite_id = [
    -1, // avatar_none
    1, // avatar_content
    2, // avatar_rocket
    3, // avatar_boating
    4, // avatar_climbing
    5, // avatar_swimming
    6, // avatar_poisoned
    7, // avatar_injured
    8, // avatar_weary
    9, // avatar_cold
    10, // avatar_hot
    11, // avatar_dizzy
    12, // avatar_woozy
]

let avatar_names = [
    "empty tile",
    "content",
    "rocket",
    "boating",
    "climbing",
    "swimming",
    "poisoned",
    "injured",
    "weary",
    "cold",
    "hot",
    "dizzy",
    "woozy",
]


enum item_entity_id:
    item_none

    //// euia

    item_apple // 🍎
    // quantity: 1
    // tip: A delicious red apple.
    // use: health

    item_pine_apple // 🍍
    // quantity: 2
    // tip: A delicious pine apple.
    // use: health

    item_pear // 🍐
    // quantity: 1
    // tip: The fruit that comes in pears.
    // use: stamina

    item_hardwood // 🌳
    // tip: The lumber of a hardwood tree.

    item_softwood // 🌲
    // tip: The lumber of a softwood tree.

    item_clover // ☘️
    // tip: Just shy of lucky.

    item_mutton // 🍖
    // tip: Mutton for dinner. Mutton for breakfast.
    // use: health

    item_yarn // 🧶
    // tip: Tell a yarn. Spin a tale.

    item_copper // 🥉
    // tip: Copper is a precious medal.

    item_silver // 🥈
    // tip: Silver is a precious medal.

    item_gold // 🥇
    // tip: Gold is a precious medal.

    item_link // 🔗

    item_bolt // 🔩

    item_gear // ⚙️

    item_knife // 🔪
    // Flags: [weapon]
    // quantity: 1
    // use: damage

    item_shovel // 🥄

    item_wrench // 🔧
    // Flags: [wrench]

    item_pick_axe // ⛏
    // Flags: [pick axe]

    item_bicycle // 🚲

    item_hook // ⚓️

    item_hammer // 🔨
    // Flags: [hammer]

    item_shield // 🛡

    item_chain // ⛓

    item_scissors // ✂️

    item_hammer_and_pick // ⚒
    // Flags: [hammer pick]

    item_hammer_and_wrench // 🛠
    // Flags: [hammer wrench]

    item_sword // 🗡
    // Flags: [weapon]
    // quantity: 2
    // use: damage

    item_zweihander // ⚔️
    // Flags: [weapon]
    // quantity: 4
    // use: damage

    item_basket // 🗑

    item_cart // 🛒
    // persists: 1
    // quantity: 20
    // use: carry

    item_fishing_rod // 🎣

    item_barrel // 🛢

    item_knitting_needles // 🥢

    item_canoe // 🛶
    // persists: 1
    // quantity: 1
    // use: float

    item_coat // 🧥
    // persists: 1
    // quantity: 1
    // use: warm

    //// occia

    item_fleur // ⚜️

    item_trident // 🔱
    // quantity: 3
    // use: weapon

    item_water // 💧
    // persists: 1
    // use: hydration

    item_coconut // 🥥
    // quantity: 1
    // tip: I’m underdeveloped.
    // use: health

    item_banana // 🍌
    // quantity: 1
    // tip: I’m underdeveloped.
    // use: health

    item_date // 📆
    // quantity: 1
    // tip: I’m underdeveloped.
    // use: health

    item_fish // 🐟
    // quantity: 2
    // tip: I’m underdeveloped.
    // use: health

    item_sand // 🏝
    // tip: I’m underdeveloped.

    item_alembic // ⚗️
    // tip: I’m underdeveloped.

    item_turtle // 🐢
    // tip: I’m underdeveloped.

    item_snail // 🐌
    // tip: I’m underdeveloped.

    //// borea

    item_wind // 💨
    // persists: 1
    // use: wind

    item_light_bulb // 💡
    // notes: No recipe. Needed to restore the Boreal Tree.

    item_lab_coat // 🥼
    // notes: No recipe. Needed to restore the polar bear.

    item_carrot // 🥕
    // notes: No recipe. Needed to restore the snowman.

    //// midia

    //// infernia

    item_rocket // 🚀
    // persists: 1
    // use: space flight

    //// oria

    item_fuel // ⛽️

    item_cactus // 🌵

    //// dysia

    item_key_to_dysia // 🗝
    // persists: 1
    // use: zoning

    item_loan // 💰
    // tip: Underdeveloped.

    //// ethyria

    item_fire // 🔥
    // persists: 1
    // use: flame

    item_power // ⚡️
    // persists: 1
    // use: charge

    item_left_lune // 🌜

    item_right_lune // 🌛

    item_lune // 🌝

    //// mojicka

    item_mojick // 🌈
    // persists: 1
    // use: mojick

    item_mushroom // 🍄
    // use: grow

    item_cake // 🍰
    // use: shrink

    item_horn // 🎉
    // notes: Unsure how this can be made.

    //// return to euia

    item_unicorn // 🦄

    //// return to occia

    item_bay_leaves // 🍃
    // notes: Bay leaves are instrumental in the quest to turn the restore the
    //        whale to a narwhal, the unicorn of the sea.

    //// return to borea

    item_invisibility_cloak // 🥼

    //// return to midia

    //// return to infernia

    //// return to oria

    //// return to dysia

    //// unplanned

    item_pen // 🖋

    item_needle // 💉

    item_broom // 🧹

let item_sprite_id = [
    -1, // item_none
    13, // item_apple
    14, // item_pine_apple
    15, // item_pear
    16, // item_hardwood
    17, // item_softwood
    18, // item_clover
    19, // item_mutton
    20, // item_yarn
    21, // item_copper
    22, // item_silver
    23, // item_gold
    24, // item_link
    25, // item_bolt
    26, // item_gear
    27, // item_knife
    28, // item_shovel
    29, // item_wrench
    30, // item_pick_axe
    31, // item_bicycle
    32, // item_hook
    33, // item_hammer
    34, // item_shield
    35, // item_chain
    36, // item_scissors
    37, // item_hammer_and_pick
    38, // item_hammer_and_wrench
    39, // item_sword
    40, // item_zweihander
    41, // item_basket
    42, // item_cart
    43, // item_fishing_rod
    44, // item_barrel
    45, // item_knitting_needles
    46, // item_canoe
    47, // item_coat
    48, // item_fleur
    49, // item_trident
    50, // item_water
    51, // item_coconut
    52, // item_banana
    53, // item_date
    54, // item_fish
    55, // item_sand
    56, // item_alembic
    57, // item_turtle
    58, // item_snail
    59, // item_wind
    60, // item_light_bulb
    61, // item_lab_coat
    62, // item_carrot
    2, // item_rocket
    63, // item_fuel
    64, // item_cactus
    65, // item_key_to_dysia
    66, // item_loan
    67, // item_fire
    68, // item_power
    69, // item_left_lune
    70, // item_right_lune
    71, // item_lune
    72, // item_mojick
    73, // item_mushroom
    74, // item_cake
    75, // item_horn
    76, // item_unicorn
    77, // item_bay_leaves
    61, // item_invisibility_cloak
    78, // item_pen
    79, // item_needle
    80, // item_broom
]

let item_names = [
    "empty tile",
    "apple",
    "pine apple",
    "pear",
    "hardwood",
    "softwood",
    "clover",
    "mutton",
    "yarn",
    "copper",
    "silver",
    "gold",
    "link",
    "bolt",
    "gear",
    "knife/weapon",
    "shovel",
    "wrench/wrench/",
    "pick axe/pick/axe/",
    "bicycle",
    "hook",
    "hammer/hammer/",
    "shield",
    "chain",
    "scissors",
    "hammer and pick/hammer/pick/",
    "hammer and wrench/hammer/wrench/",
    "sword/weapon",
    "zweihander/weapon",
    "basket",
    "cart",
    "fishing rod",
    "barrel",
    "knitting needles",
    "canoe",
    "coat",
    "fleur",
    "trident",
    "water",
    "coconut",
    "banana",
    "date",
    "fish",
    "sand",
    "alembic",
    "turtle",
    "snail",
    "wind",
    "light bulb",
    "lab coat",
    "carrot",
    "rocket",
    "fuel",
    "cactus",
    "key to dysia",
    "loan",
    "fire",
    "power",
    "left lune",
    "right lune",
    "lune",
    "mojick",
    "mushroom",
    "cake",
    "horn",
    "unicorn",
    "bay leaves",
    "invisibility cloak",
    "pen",
    "needle",
    "broom",
]


enum tile_entity_id:
    tile_none

    tile_euia // ⚅
    // notes: Euia is the nice side of the world. It is forested and has six
    //        mountains, in two ranges, along the northern and southern fringes.
    //        There is a castle in the middle, forests to the west and a fluvial
    //        plain to the east. The player begins their journey in the forest
    //        and must find their way to the north and to the west.

    tile_apple_tree // 🌳
    // Flags: [hardwood]
    // capacity: 1
    // notes: Apple trees bear apples, introducing the player to the health
    //        mechanic. The apples restore one empty health container.
    // renew: 1

    tile_pine_tree // 🌲
    // Flags: [softwood]
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

    tile_pear_tree // 🌳
    // Flags: [hardwood]
    // capacity: 1
    // notes: The pear tree is unique and exists only in the forest due west of
    //        Castle Euia. The pear tree drops pears, which are necessary to
    //        extend the player’s stamina so they can travel over mountainous
    //        terrain and survive. This allows the player to find *a flat miner*
    //        and obtain a *pick axe*.
    // renew: 1

    tile_clover // ☘️
    // notes: Clover exist on the plains to the east of Castle Euia. They become
    //        useful in the quest for Occia, where it transpires that they can
    //        be gilded to make a fleur de lis, and then reshaped to make a
    //        trident. This enables the player to restore Herman the Merman and
    //        gain the Essence of Water. This in turn is one of the two
    //        requirements to be granted access to the naughty side of the
    //        world.

    tile_ewe // 🐑
    // Flags: [sheep]
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

    tile_ram // 🐏
    // Flags: [sheep]
    // capacity: 1
    // health: 2
    // notes: Rams, however rare, can drop horns. These do not yet figure into
    //        any designed quests but will likely be useful for all kinds of
    //        horn related crafting, especially the restoration of mojical
    //        creatures that require horns, and the creation of mojical
    //        instruments, as well as the post office horn and post offices.
    // renew: 1
    // wander: grass

    tile_castle // 🏰
    // indoor: 1
    // notes: Castle Euia is the seat of Princess Dice, who provides the
    //        exposition for the broadest quest arc: restoring mojick. Her
    //        lieutenants, the guards provide more tangible advice for the early
    //        quest arcs to get access to the north and south.

    tile_euia_bank // 🏦
    // Flags: [bank]
    // indoor: 1
    // notes: Once the player has obtained precious medals in the mountains,
    //        they need the bank to get the right denominations for various
    //        kinds of metal crafts at the forge. The bannk and forge are
    //        therefore close together.  The bank also foreshadows the quest of
    //        Dysia, where the player will need to get a loan so they can fuel a
    //        rocket and seek the Essences of Power and Fire in the heavens.

    tile_euia_forge // 🏭
    // Flags: [forge]
    // indoor: 1
    // notes: The forge is a crafting site for changing precious medals into
    //        parts the player can use to make all the various kinds of tools.

    tile_glub // 🐟
    // notes: The player finds Glub along the edge of the Euia River, flowing
    //        east to Occia. Glub provides the clue that the player needs to
    //        build a canoe to go over the east edge of Euia.

    tile_major // 💂‍♂️
    // notes: The major provides a clue that the player must hike into the
    //        mountains to get a pick axe. This in turn unlocks the ability to
    //        use precious medals and create more tools.

    tile_captain // 💂‍♀️
    // notes: The captain provides a clue about finding the pear tree so the
    //        player can travel in the mountains. This is necessary to craft
    //        with precious medals.

    tile_miner // 👨‍🔧
    // notes: The player finds a miner in the mountains. The miner gives the
    //        player a clue that they can bump into an adjacent mountain to find
    //        their first pick axe.

    tile_harriet // 🏠
    // notes: Harriet gives the clues that sheep can be shorn with scissors, and
    //        that scissors are made of knives.

    tile_jack // 🏡
    // notes: Jack introduces the knitting mechanic so you can craft a coat.

    tile_boulder // ⛰
    // notes: The boulder fell on a flat miner. Bumping into it frees the miner
    //        and produces the pick axe for the player’s use. This unlocks the
    //        ability to mine for precious medals.

    tile_mountain // ⛰
    // capacity: 10
    // notes: Mountains produce copper. The player may encounter other kinds of
    //        mountains for higher denominations of precious medals later in the
    //        game, but for now they must trade copper up at the bank to get
    //        exact medals necessary for crafting various components at the
    //        forge.

    tile_horse // 🐴
    // breed: horse
    // notes: The horse exists to fulfill a later stage quest, where the player
    //        has all the five essences and can transmutate the horse into a
    //        unicorn.
    // wander: 1

    tile_unicorn // 🦄
    // notes: Restoring the unicorn is one of the many mojical creatures that
    //        satisfy the end game condition of restoring all the mojical
    //        creatures.

    tile_occia // ⚄
    // notes: Occia is the west face of the world, in the nice hemicube. Occia
    //        is an ocean world, ruled by the merfolk. There are five islands.

    tile_mermaid // 🧜‍♀️

    tile_herman // 🏊‍♂️
    // notes: The Herman quest is to restore this merman (bottom half obscured)
    //        by reproducing his lost trident. He will then teach you about the
    //        essence of water.

    tile_merman // 🧜‍♂️

    tile_marco // 🤽‍♂️
    // wander: water

    tile_octopus // 🐙

    tile_fish // 🐟
    // breed: fish
    // health: 1
    // wander: water

    tile_puffer_fish // 🐡
    // breed: puffer fish

    tile_turtle // 🐢

    tile_island // 🏝
    // capacity: 100
    // renew: 1

    tile_date_palm_tree // 🌴
    // Flags: [palm_tree softwood]
    // capacity: 1
    // renew: 1

    tile_banana_tree // 🌴
    // Flags: [palm_tree softwood]
    // capacity: 1
    // renew: 1

    tile_coconut_tree // 🌴
    // Flags: [palm_tree softwood]
    // capacity: 1
    // renew: 1

    tile_sponge // 🧽

    tile_parrot // 🦜

    tile_occia_bank // 🏦
    // Flags: [bank]

    tile_borea // ⚃

    tile_steamer // 🚂
    // notes: The steam train is the vehicle to carry you on the railway through
    //        the center of the world, spiraling around the inner loop of The
    //        Pole. To bring the train to life, you will need to master the
    //        essence of wind and water.

    tile_north_pole // 💈
    // notes: The north pole is the home of Magie and Magus. They will teach you
    //        the essence of wind, but you must obtain for them an umbrella.
    //        They promise that it’s relevant.

    //// mojick of borea

    tile_unlit_tree // 🌲
    // notes: The great pine of Borea was once mojical and glimmered with a
    //        thousand shining lights.

    tile_lit_tree // 🎄

    tile_bear // 🐻
    // notes: The polar bear has lost its mogical cloak of invisibility.

    tile_polar_bear // ⸪

    tile_abdominal_snowman // ⚪️
    // notes: The abdominal snowman is not much of a snowman. It needs some help
    //        to restore its mogical splendor. That may involve fetching a few
    //        items to restore it to its senses.

    tile_abominable_snowman // ⛄️

    tile_caribou // 🦌
    // notes: Caribou used to be able to fly. They were the preferred mode of
    //        boreal transportation before mojick faded.

    tile_whale // 🐋
    // notes: The whale was once the unicorn of the sea. Leaving its bay might
    //        set him on his journey to mojical restoration. As there is no
    //        Narwhal emoji, the creature just disappears in search of mojick,
    //        thereby completing the quest.

    //// midia

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

    //// ethyria

    tile_sun // ☀️

    tile_sol // 🌞

    tile_moon // 🌙

    tile_lune // 🌝

    tile_asteroid // ☄️
    // wander: sky

    //// unplanned

    tile_dumbledore // 🐝

    tile_high_mountain // 🏔
    // capacity: 10

    tile_volcano // 🗻
    // capacity: 10

    tile_gym // 🏥
    // indoor: 1

    tile_observatory // 🔭
    // indoor: 1

    tile_justin // 🕰
    // Flags: [clock]
    // indoor: 1

    tile_nick // ⏰
    // Flags: [clock]

    tile_bakery // 🏭
    // indoor: 1

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
    81, // tile_euia
    16, // tile_apple_tree
    17, // tile_pine_tree
    16, // tile_pear_tree
    18, // tile_clover
    82, // tile_ewe
    83, // tile_ram
    84, // tile_castle
    85, // tile_euia_bank
    86, // tile_euia_forge
    54, // tile_glub
    87, // tile_major
    88, // tile_captain
    89, // tile_miner
    90, // tile_harriet
    91, // tile_jack
    92, // tile_boulder
    92, // tile_mountain
    93, // tile_horse
    76, // tile_unicorn
    81, // tile_occia
    94, // tile_mermaid
    95, // tile_herman
    96, // tile_merman
    97, // tile_marco
    98, // tile_octopus
    54, // tile_fish
    99, // tile_puffer_fish
    57, // tile_turtle
    55, // tile_island
    100, // tile_date_palm_tree
    100, // tile_banana_tree
    100, // tile_coconut_tree
    101, // tile_sponge
    102, // tile_parrot
    85, // tile_occia_bank
    81, // tile_borea
    103, // tile_steamer
    104, // tile_north_pole
    17, // tile_unlit_tree
    105, // tile_lit_tree
    106, // tile_bear
    81, // tile_polar_bear
    107, // tile_abdominal_snowman
    108, // tile_abominable_snowman
    109, // tile_caribou
    110, // tile_whale
    111, // tile_sal_the_snake
    112, // tile_sal_the_mander
    81, // tile_infernia
    113, // tile_cheese_wizard
    114, // tile_sand_witch
    115, // tile_south_pole
    81, // tile_oria
    116, // tile_jennie
    117, // tile_gene
    64, // tile_cactus
    118, // tile_bamboo
    119, // tile_panda
    81, // tile_dysia
    120, // tile_sun
    121, // tile_sol
    122, // tile_moon
    71, // tile_lune
    123, // tile_asteroid
    124, // tile_dumbledore
    125, // tile_high_mountain
    126, // tile_volcano
    127, // tile_gym
    128, // tile_observatory
    129, // tile_justin
    130, // tile_nick
    86, // tile_bakery
    131, // tile_plumber
    132, // tile_genome
    133, // tile_pat
    91, // tile_kris_and_lydia
    134, // tile_kitty
    135, // tile_tiger
    136, // tile_infernia_warning_sign
    137, // tile_asia
    138, // tile_africa
    139, // tile_america
]

let tile_names = [
    "empty tile",
    "euia",
    "apple tree/hardwood",
    "pine tree/softwood",
    "pear tree/hardwood",
    "clover",
    "ewe/sheep",
    "ram/sheep",
    "castle",
    "euia bank/bank",
    "euia forge/forge",
    "glub",
    "major",
    "captain",
    "miner",
    "harriet",
    "jack",
    "boulder",
    "mountain",
    "horse",
    "unicorn",
    "occia",
    "mermaid",
    "herman",
    "merman",
    "marco",
    "octopus",
    "fish",
    "puffer fish",
    "turtle",
    "island",
    "date palm tree/palm tree/softwood",
    "banana tree/palm tree/softwood",
    "coconut tree/palm tree/softwood",
    "sponge",
    "parrot",
    "occia bank/bank",
    "borea",
    "steamer",
    "north pole",
    "unlit tree",
    "lit tree",
    "bear",
    "polar bear",
    "abdominal snowman",
    "abominable snowman",
    "caribou",
    "whale",
    "sal the snake",
    "sal the mander",
    "infernia",
    "cheese wizard",
    "sand witch",
    "south pole",
    "oria",
    "jennie",
    "gene",
    "cactus",
    "bamboo",
    "panda",
    "dysia",
    "sun",
    "sol",
    "moon",
    "lune",
    "asteroid",
    "dumbledore",
    "high mountain",
    "volcano",
    "gym",
    "observatory",
    "justin/clock",
    "nick/clock",
    "bakery",
    "plumber",
    "genome",
    "pat",
    "kris and lydia",
    "kitty",
    "tiger",
    "infernia warning sign",
    "asia",
    "africa",
    "america",
]


enum ui_entity_id:
    ui_none

    ui_north // ⬆️

    ui_east // ➡️

    ui_south // ⬇️

    ui_west // ⬅️

    ui_rest // 💤

    ui_health_heart // ❤️

    ui_stamina_heart // 💛

    ui_cure_heart // 💜

    ui_empty_heart // 🖤

    ui_discard // 🚮

    ui_left_hand // ✋

    ui_right_hand // 🤚

    ui_point_north // ☝️

    ui_point_east // 👉

    ui_point_south // 👇

    ui_point_west // 👈

    ui_spock_hand // 🖖

let ui_sprite_id = [
    -1, // ui_none
    140, // ui_north
    141, // ui_east
    142, // ui_south
    143, // ui_west
    144, // ui_rest
    145, // ui_health_heart
    146, // ui_stamina_heart
    147, // ui_cure_heart
    148, // ui_empty_heart
    149, // ui_discard
    150, // ui_left_hand
    151, // ui_right_hand
    152, // ui_point_north
    153, // ui_point_east
    154, // ui_point_south
    155, // ui_point_west
    156, // ui_spock_hand
]

let ui_names = [
    "empty tile",
    "north",
    "east",
    "south",
    "west",
    "rest",
    "health heart",
    "stamina heart",
    "cure heart",
    "empty heart",
    "discard",
    "left hand",
    "right hand",
    "point north",
    "point east",
    "point south",
    "point west",
    "spock hand",
]

