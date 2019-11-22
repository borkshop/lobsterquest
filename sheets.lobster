
import sprites
import vec

var sheet_sprites = []::resource

def load_sheet():
    sheet_sprites = load_sprites("sheets.png", 72, xy { 12, 12 }, 144)

enum avatar_entity_id:
    avatar_none

    avatar_content // 🙂

    avatar_cold // 🥶

    avatar_hot // 🥵

    avatar_poisoned // 🤢

    avatar_injured // 🤕

    avatar_swimming // 🏊‍♀️

    avatar_climbing // 🧗‍♀️

    avatar_boating // 🚣‍♀️

    avatar_woozy // 🥴

    avatar_dizzy // 😵

    avatar_mindblown // 🤯

    avatar_confused // 😕

    avatar_worried // 😟

    avatar_perservering // 😣

    avatar_weary // 😩

    avatar_anxious // 😰

    avatar_rocket // 🚀

let avatar_sprite_id = [
    -1, // avatar_none
    0, // avatar_content
    1, // avatar_cold
    2, // avatar_hot
    3, // avatar_poisoned
    4, // avatar_injured
    5, // avatar_swimming
    6, // avatar_climbing
    7, // avatar_boating
    8, // avatar_woozy
    9, // avatar_dizzy
    10, // avatar_mindblown
    11, // avatar_confused
    12, // avatar_worried
    13, // avatar_perservering
    14, // avatar_weary
    15, // avatar_anxious
    16, // avatar_rocket
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
    17, // item_apple
    18, // item_pine_apple
    19, // item_pear
    20, // item_hardwood
    21, // item_softwood
    22, // item_clover
    23, // item_mutton
    24, // item_yarn
    25, // item_copper
    26, // item_silver
    27, // item_gold
    28, // item_link
    29, // item_bolt
    30, // item_gear
    31, // item_knife
    32, // item_shovel
    33, // item_wrench
    34, // item_pick_axe
    35, // item_bicycle
    36, // item_hook
    37, // item_hammer
    38, // item_shield
    39, // item_chain
    40, // item_scissors
    41, // item_hammer_and_pick
    42, // item_hammer_and_wrench
    43, // item_sword
    44, // item_zweihander
    45, // item_basket
    46, // item_cart
    47, // item_fishing_rod
    48, // item_barrel
    49, // item_knitting_needles
    50, // item_canoe
    51, // item_coat
    52, // item_fleur
    53, // item_trident
    54, // item_water
    55, // item_coconut
    56, // item_banana
    57, // item_date
    58, // item_fish
    59, // item_sand
    60, // item_alembic
    61, // item_turtle
    62, // item_snail
    63, // item_wind
    64, // item_light_bulb
    65, // item_lab_coat
    66, // item_carrot
    16, // item_rocket
    67, // item_fuel
    68, // item_cactus
    69, // item_key_to_dysia
    70, // item_loan
    71, // item_fire
    72, // item_power
    73, // item_left_lune
    74, // item_right_lune
    75, // item_lune
    76, // item_mojick
    77, // item_mushroom
    78, // item_cake
    79, // item_horn
    80, // item_unicorn
    81, // item_bay_leaves
    65, // item_invisibility_cloak
    82, // item_pen
    83, // item_needle
    84, // item_broom
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
    85, // tile_euia
    20, // tile_apple_tree
    21, // tile_pine_tree
    20, // tile_pear_tree
    22, // tile_clover
    86, // tile_ewe
    87, // tile_ram
    88, // tile_castle
    89, // tile_euia_bank
    90, // tile_euia_forge
    58, // tile_glub
    91, // tile_major
    92, // tile_captain
    93, // tile_miner
    94, // tile_harriet
    95, // tile_jack
    96, // tile_boulder
    96, // tile_mountain
    97, // tile_horse
    80, // tile_unicorn
    85, // tile_occia
    98, // tile_mermaid
    99, // tile_herman
    100, // tile_merman
    101, // tile_marco
    102, // tile_octopus
    58, // tile_fish
    103, // tile_puffer_fish
    61, // tile_turtle
    59, // tile_island
    104, // tile_date_palm_tree
    104, // tile_banana_tree
    104, // tile_coconut_tree
    105, // tile_sponge
    106, // tile_parrot
    89, // tile_occia_bank
    85, // tile_borea
    107, // tile_steamer
    108, // tile_north_pole
    21, // tile_unlit_tree
    109, // tile_lit_tree
    110, // tile_bear
    85, // tile_polar_bear
    111, // tile_abdominal_snowman
    112, // tile_abominable_snowman
    113, // tile_caribou
    114, // tile_whale
    115, // tile_sal_the_snake
    116, // tile_sal_the_mander
    85, // tile_infernia
    117, // tile_cheese_wizard
    118, // tile_sand_witch
    119, // tile_south_pole
    85, // tile_oria
    120, // tile_jennie
    121, // tile_gene
    68, // tile_cactus
    122, // tile_bamboo
    123, // tile_panda
    85, // tile_dysia
    124, // tile_sun
    125, // tile_sol
    126, // tile_moon
    75, // tile_lune
    127, // tile_asteroid
    128, // tile_dumbledore
    129, // tile_high_mountain
    130, // tile_volcano
    131, // tile_gym
    132, // tile_observatory
    133, // tile_justin
    134, // tile_nick
    90, // tile_bakery
    135, // tile_plumber
    136, // tile_genome
    137, // tile_pat
    95, // tile_kris_and_lydia
    138, // tile_kitty
    139, // tile_tiger
    140, // tile_infernia_warning_sign
    141, // tile_asia
    142, // tile_africa
    143, // tile_america
]

