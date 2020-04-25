
import sprites
import vec

def load_sheet_sprites():
    let tex = gl_load_texture(pakfile "../assets/sprites.png")
    assert tex
    return sprite_new_atlas(tex, xy_1i * 72, xy { 14, 13 })

enum avatar_entity_id:
    avatar_none

    avatar_content // 🙂

    avatar_rocket // 🚀

    avatar_boating // 🚣‍♀️

    avatar_climbing // 🧗‍♀️

    avatar_swimming // 🏊‍♀️

    avatar_poisoned // 🤢

    avatar_injured // 🤕

    avatar_sick // 🤒

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
    avatar_state_sick
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
    avatar_sick,
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
    8, // avatar_sick
    9, // avatar_weary
    10, // avatar_cold
    11, // avatar_hot
    12, // avatar_dizzy
    13, // avatar_woozy
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
    "sick",
    "weary",
    "cold",
    "hot",
    "dizzy",
    "woozy",
]


enum item_entity_id:
    item_none

    item_apple // 🍎
    // consumed: 0
    // produced: 1
    // quantity: 1
    // tip: A delicious red apple.
    // use: health

    item_pine_apple // 🍍
    // consumed: 0
    // produced: 1
    // quantity: 2
    // tip: A delicious pine apple.
    // use: health

    item_pear // 🍐
    // consumed: 0
    // produced: 1
    // quantity: 1
    // tip: The fruit that comes in pears.
    // use: stamina

    item_hardwood // 🌳
    // consumed: 0
    // produced: 1
    // tip: The lumber of a hardwood tree.

    item_softwood // 🌲
    // consumed: 5
    // produced: 1
    // tip: The lumber of a softwood tree.

    item_clover // ☘️
    // consumed: 1
    // produced: 1
    // tip: Just shy of lucky.

    item_mutton // 🍖
    // consumed: 0
    // produced: 1
    // tip: Mutton for dinner. Mutton for breakfast.
    // use: health

    item_yarn // 🧶
    // consumed: 3
    // produced: 2
    // tip: Tell a yarn. Spin a tale.

    item_copper // 🥉
    // consumed: 4
    // produced: 4
    // tip: Copper is a precious medal.

    item_silver // 🥈
    // consumed: 3
    // produced: 3
    // tip: Silver is a precious medal.

    item_gold // 🥇
    // consumed: 3
    // produced: 2
    // tip: Gold is a precious medal.

    item_link // 🔗
    // consumed: 6
    // produced: 1
    // tip: Links pair well with 🔩 *bolts* and ⚙️ *gears*.

    item_bolt // 🔩
    // consumed: 8
    // produced: 2
    // tip: Bolts pair well with ⚙️ *gears* 🔗 *links*.

    item_gear // ⚙️
    // consumed: 7
    // produced: 1
    // tip: Gears pair well with  🔗 *links* and 🔩 *bolts*.

    item_knife // 🔪
    // Flags: [weapon]
    // consumed: 0
    // produced: 0
    // quantity: 1
    // tip: It slices. It dices.
    // use: damage

    item_shovel // 🥄
    // consumed: 1
    // produced: 2
    // tip: A spoon will suffice if you can’t find a shovel emoji.

    item_wrench // 🔧
    // Flags: [wrench]
    // consumed: 0
    // produced: 0
    // tip: To turn, to twist, to spindle.

    item_pick_axe // ⛏
    // Flags: [pick axe]
    // consumed: 0
    // produced: 0
    // tip: Pick your battles wisely.

    item_bicycle // 🚲
    // consumed: 1
    // produced: 1
    // tip: Ridden by cyclists. Not bikers.

    item_hook // ⚓️
    // consumed: 1
    // produced: 1
    // tip: There is no hook emoji. This will have to do.

    item_hammer // 🔨
    // Flags: [hammer]
    // consumed: 0
    // produced: 0
    // tip: Smash it with a hammer.

    item_axe // 🪓
    // consumed: 0
    // produced: 1
    // quantity: 1
    // tip: Did you know that axe, acid, and oxygen are all related words?
    // use: damage

    item_shield // 🛡
    // consumed: 1
    // produced: 1
    // tip: A sheet of metal *can* serve many functions.

    item_chain // ⛓
    // consumed: 1
    // produced: 1
    // tip: Follow the links.

    item_scissors // ✂️
    // consumed: 0
    // produced: 1
    // tip: Cut it out.

    item_hammer_and_pick // ⚒️
    // Flags: [hammer pick]
    // consumed: 0
    // produced: 0
    // tip: Why pick when you can pick *and* hammer.

    item_hammer_and_wrench // 🛠
    // Flags: [hammer wrench]
    // consumed: 0
    // produced: 0
    // tip: Smash and grab.

    item_sword // 🗡
    // Flags: [weapon]
    // consumed: 0
    // produced: 0
    // quantity: 2
    // tip: Dagger emoji looks like a sword to me.
    // use: damage

    item_zweihander // ⚔️
    // Flags: [weapon]
    // consumed: 0
    // produced: 0
    // quantity: 4
    // tip: Zweihander means two hands in German. You will need both.
    // use: damage

    item_basket // 🗑
    // consumed: 1
    // produced: 1
    // tip: Sometimes called the “round file”.

    item_cart // 🛒
    // consumed: 0
    // persists: 1
    // produced: 1
    // quantity: 20
    // tip: Adventure with everything *and* the kitchen sink.
    // use: carry

    item_fishing_rod // 🎣
    // consumed: 0
    // produced: 1
    // tip: Not just a boring side quest.

    item_barrel // 🛢
    // consumed: 0
    // produced: 0
    // tip: Never look down the barrel.

    item_knitting_needles // 🥢
    // consumed: 5
    // produced: 6
    // tip: There is no emoji for knitting needles.

    item_canoe // 🛶
    // consumed: 0
    // persists: 1
    // produced: 1
    // quantity: 1
    // tip: Row row row your boat.
    // use: float

    item_coat // 🧥
    // consumed: 1
    // persists: 1
    // produced: 2
    // quantity: 1
    // tip: It’s a coat! It’s a jacket! No, it’s super warm!
    // use: warm

    item_candy // 🍬
    // consumed: 0
    // notes: This is a throat drop that relieves a sore throat. It must be
    //        constructed with mojick since it’s a requirement to resolve the
    //        unicorn restoration quest. There is no recipe yet.
    // produced: 0
    // tip: Candy, the preferred cure for a sore throat.

    item_fleur // ⚜️
    // consumed: 1
    // produced: 1
    // tip: Gilded lily.

    item_trident // 🔱
    // consumed: 0
    // produced: 1
    // quantity: 3
    // tip: Three gold teeth.
    // use: weapon

    item_water // 💧
    // consumed: 0
    // persists: 1
    // produced: 0
    // tip: Drip drop.
    // use: hydration

    item_coconut // 🥥
    // consumed: 0
    // notes: I’m underdeveloped.
    // produced: 1
    // quantity: 1
    // tip: Nut of the coco.
    // use: health

    item_banana // 🍌
    // consumed: 0
    // notes: I’m underdeveloped.
    // produced: 1
    // quantity: 1
    // tip: I am a banana.
    // use: health

    item_date // 📆
    // consumed: 0
    // notes: I’m underdeveloped.
    // produced: 1
    // quantity: 1
    // tip: Food time.
    // use: health

    item_fish // 🐟
    // consumed: 0
    // notes: I’m underdeveloped.
    // produced: 0
    // quantity: 2
    // tip: There are many ways to spell my name.
    // use: health

    item_sand // 🏝
    // consumed: 1
    // notes: I’m underdeveloped.
    // produced: 1
    // tip: True grit.

    item_alembic // ⚗️
    // consumed: 0
    // notes: I’m underdeveloped.
    // produced: 1
    // tip: Bubble bubble, toil and trouble.

    item_turtle // 🐢
    // consumed: 0
    // notes: I’m underdeveloped.
    // produced: 0
    // tip: Slow and steady wins the race.

    item_snail // 🐌
    // consumed: 0
    // notes: I’m underdeveloped.
    // produced: 0
    // tip: Slower and steadier wins the race.

    item_wind // 💨
    // consumed: 0
    // persists: 1
    // produced: 0
    // tip: Woosh.
    // use: wind

    item_light_bulb // 💡
    // consumed: 0
    // notes: No recipe. Needed to restore the Boreal Tree.
    // produced: 0
    // tip: I have an idea.

    item_lab_coat // 🥼
    // consumed: 0
    // notes: No recipe. Needed to restore the polar bear.
    // produced: 0
    // tip: I’m all white.

    item_carrot // 🥕
    // consumed: 0
    // notes: No recipe. Needed to restore the snowman.
    // produced: 1
    // tip: Orange but not an orange. The name was taken, and I was purple at
    //      the time.

    item_pill // 💊
    // consumed: 0
    // notes: No recipe. Needed to help the sick emoji.
    // produced: 0
    // tip: Side-effects may include wellness.

    item_thermometer // 🌡
    // consumed: 0
    // notes: Obtained from the sick emoji. Needs a further purpose.
    // produced: 0
    // tip: Terry Pratchett would have called this a mojical thaumometer.

    item_bay_leavs // 🍃
    // consumed: 0
    // notes: Used to convince the whale to leave the bay.
    // produced: 0
    // tip: Bay leaves. Get it?

    item_rocket // 🚀
    // consumed: 0
    // persists: 1
    // produced: 0
    // tip: To the sky box…and beyond!
    // use: space flight

    item_fuel // ⛽️
    // consumed: 0
    // produced: 0
    // tip: Benzene!

    item_prickly_pear // 🌵
    // consumed: 0
    // produced: 1
    // tip: Some pears are prickly.

    item_key_to_dysia // 🗝
    // consumed: 0
    // notes: Underdeveloped.
    // persists: 1
    // produced: 0
    // tip: The keys to the city of Dis.
    // use: zoning

    item_loan // 💰
    // consumed: 0
    // notes: Underdeveloped.
    // produced: 0
    // tip: From what might be called a “fallen angel investor”.

    item_fire // 🔥
    // consumed: 0
    // persists: 1
    // produced: 0
    // tip: Fire!
    // use: flame

    item_power // ⚡️
    // consumed: 0
    // persists: 1
    // produced: 0
    // tip: Power!
    // use: charge

    item_left_lune // 🌜
    // consumed: 1
    // produced: 0
    // tip: The left side of the Lune.

    item_right_lune // 🌛
    // consumed: 1
    // produced: 0
    // tip: Where is my better half?

    item_lune // 🌝
    // consumed: 0
    // produced: 1
    // tip: I am the Lune.

    item_mojick // 🌈
    // consumed: 1
    // persists: 1
    // produced: 1
    // tip: Mojick!
    // use: mojick

    item_mushroom // 🍄
    // consumed: 0
    // produced: 0
    // use: grow

    item_cake // 🍰
    // consumed: 0
    // produced: 0
    // use: shrink

    item_horn // 🎉
    // consumed: 0
    // notes: Unsure how this can be made.
    // produced: 0

    item_unicorn // 🦄
    // consumed: 0
    // notes: Is this really an item?
    // produced: 1

    item_bay_leaves // 🍃
    // consumed: 0
    // notes: Bay leaves are instrumental in the quest to turn the restore the
    //        whale to a narwhal, the unicorn of the sea.
    // produced: 0
    // tip: What does the bay leave?

    item_pen // 🖋
    // consumed: 0
    // produced: 1

    item_needle // 💉
    // consumed: 1
    // produced: 2

    item_broom // 🧹
    // consumed: 0
    // produced: 1

    item_glove // 🧤
    // consumed: 3
    // produced: 1

    item_sock // 🧦
    // consumed: 1
    // produced: 1

    item_boxing_glove // 🥊
    // consumed: 1
    // produced: 2

    item_box // 📦
    // consumed: 1
    // produced: 1

    item_ribbon // 🎗
    // consumed: 1
    // produced: 1

    item_pack // 🎒
    // consumed: 0
    // produced: 1

    item_paper // 📄
    // consumed: 1
    // produced: 0

    item_reeds // 🎍
    // consumed: 0
    // produced: 0

    item_thread // 🧵
    // consumed: 1
    // produced: 1

let item_sprite_id = [
    -1, // item_none
    14, // item_apple
    15, // item_pine_apple
    16, // item_pear
    17, // item_hardwood
    18, // item_softwood
    19, // item_clover
    20, // item_mutton
    21, // item_yarn
    22, // item_copper
    23, // item_silver
    24, // item_gold
    25, // item_link
    26, // item_bolt
    27, // item_gear
    28, // item_knife
    29, // item_shovel
    30, // item_wrench
    31, // item_pick_axe
    32, // item_bicycle
    33, // item_hook
    34, // item_hammer
    35, // item_axe
    36, // item_shield
    37, // item_chain
    38, // item_scissors
    39, // item_hammer_and_pick
    40, // item_hammer_and_wrench
    41, // item_sword
    42, // item_zweihander
    43, // item_basket
    44, // item_cart
    45, // item_fishing_rod
    46, // item_barrel
    47, // item_knitting_needles
    48, // item_canoe
    49, // item_coat
    50, // item_candy
    51, // item_fleur
    52, // item_trident
    53, // item_water
    54, // item_coconut
    55, // item_banana
    56, // item_date
    57, // item_fish
    58, // item_sand
    59, // item_alembic
    60, // item_turtle
    61, // item_snail
    62, // item_wind
    63, // item_light_bulb
    64, // item_lab_coat
    65, // item_carrot
    66, // item_pill
    67, // item_thermometer
    68, // item_bay_leavs
    2, // item_rocket
    69, // item_fuel
    70, // item_prickly_pear
    71, // item_key_to_dysia
    72, // item_loan
    73, // item_fire
    74, // item_power
    75, // item_left_lune
    76, // item_right_lune
    77, // item_lune
    78, // item_mojick
    79, // item_mushroom
    80, // item_cake
    81, // item_horn
    82, // item_unicorn
    68, // item_bay_leaves
    83, // item_pen
    84, // item_needle
    85, // item_broom
    86, // item_glove
    87, // item_sock
    88, // item_boxing_glove
    89, // item_box
    90, // item_ribbon
    91, // item_pack
    92, // item_paper
    93, // item_reeds
    94, // item_thread
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
    "axe",
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
    "candy",
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
    "pill",
    "thermometer",
    "bay leavs",
    "rocket",
    "fuel",
    "prickly pear",
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
    "pen",
    "needle",
    "broom",
    "glove",
    "sock",
    "boxing glove",
    "box",
    "ribbon",
    "pack",
    "paper",
    "reeds",
    "thread",
]


enum tile_entity_id:
    tile_none

    tile_apple_tree // 🌳
    // Flags: [hardwood]
    // bumps: 0
    // capacity: 1
    // dialog: 1
    // introduced: 481
    // mapped: 481
    // morphed: 0
    // morphee: 0
    // notes: Apple trees bear apples, introducing the player to the health
    //        mechanic. The apples restore one empty health container.
    // renew: 1

    tile_pine_tree // 🌲
    // Flags: [softwood]
    // bumps: 0
    // capacity: 1
    // dialog: 1
    // introduced: 371
    // mapped: 371
    // morphed: 0
    // morphee: 0
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
    // bumps: 0
    // capacity: 1
    // dialog: 4
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
    // notes: The pear tree is unique and exists only in the forest due west of
    //        Castle Euia. The pear tree drops pears, which are necessary to
    //        extend the player’s stamina so they can travel over mountainous
    //        terrain and survive. This allows the player to find *a flat miner*
    //        and obtain a *pick axe*.
    // renew: 1

    tile_clover // ☘️
    // bumps: 1
    // dialog: 0
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
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
    // bumps: 0
    // capacity: 1
    // dialog: 3
    // health: 2
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
    // notes: Sheep, in general, provide wool which is material necessary for
    //        creating coats, which in turn give access to the north face of the
    //        world.  Sheep may in turn produce mutton if they are killed with a
    //        sword or worse. Meat can extend the health bar to three heart
    //        containers.
    // renew: 1
    // wander: grass

    tile_ram // 🐏
    // Flags: [sheep]
    // bumps: 0
    // capacity: 1
    // dialog: 3
    // health: 2
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
    // notes: Rams, however rare, can drop horns. These do not yet figure into
    //        any designed quests but will likely be useful for all kinds of
    //        horn related crafting, especially the restoration of mojical
    //        creatures that require horns, and the creation of mojical
    //        instruments, as well as the post office horn and post offices.
    // renew: 1
    // wander: grass

    tile_cow // 🐄
    // Flags: [cow coat]
    // bumps: 0
    // dialog: 0
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 1

    tile_ox // 🐂
    // Flags: [cow nude]
    // bumps: 0
    // dialog: 0
    // introduced: 1
    // mapped: 0
    // morphed: 1
    // morphee: 0

    tile_castle // 🏰
    // bumps: 0
    // dialog: 6
    // indoor: 1
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
    // notes: Castle Euia is the seat of Princess Dice, who provides the
    //        exposition for the broadest quest arc: restoring mojick. Her
    //        lieutenants, the guards provide more tangible advice for the early
    //        quest arcs to get access to the north and south.

    tile_euia_bank // 🏦
    // Flags: [bank]
    // bumps: 0
    // dialog: 5
    // indoor: 1
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
    // notes: Once the player has obtained precious medals in the mountains,
    //        they need the bank to get the right denominations for various
    //        kinds of metal crafts at the forge. The bannk and forge are
    //        therefore close together.  The bank also foreshadows the quest of
    //        Dysia, where the player will need to get a loan so they can fuel a
    //        rocket and seek the Essences of Power and Fire in the heavens.

    tile_euia_forge // 🏭
    // Flags: [forge]
    // bumps: 0
    // dialog: 5
    // indoor: 1
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
    // notes: The forge is a crafting site for changing precious medals into
    //        parts the player can use to make all the various kinds of tools.

    tile_glub // 🐟
    // bumps: 0
    // dialog: 5
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
    // notes: The player finds Glub along the edge of the Euia River, flowing
    //        east to Occia. Glub provides the clue that the player needs to
    //        build a canoe to go over the east edge of Euia.

    tile_major // 💂‍♂️
    // bumps: 0
    // dialog: 4
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
    // notes: The major provides a clue that the player must hike into the
    //        mountains to get a pick axe. This in turn unlocks the ability to
    //        use precious medals and create more tools.

    tile_captain // 💂‍♀️
    // bumps: 0
    // dialog: 3
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
    // notes: The captain provides a clue about finding the pear tree so the
    //        player can travel in the mountains. This is necessary to craft
    //        with precious medals.

    tile_miner // 👨‍🔧
    // bumps: 0
    // dialog: 3
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
    // notes: The player finds a miner in the mountains. The miner gives the
    //        player a clue that they can bump into an adjacent mountain to find
    //        their first pick axe.

    tile_harriet // 🏠
    // bumps: 0
    // dialog: 2
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0
    // notes: Harriet gives the clues that sheep can be shorn with scissors, and
    //        that scissors are made of knives.

    tile_jack // 🏡
    // bumps: 0
    // dialog: 5
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0
    // notes: Jack introduces the knitting mechanic so you can craft a coat.

    tile_boulder // ⛰
    // bumps: 1
    // dialog: 0
    // introduced: 2
    // mapped: 2
    // morphed: 0
    // morphee: 0
    // notes: The boulder fell on a flat miner. Bumping into it frees the miner
    //        and produces the pick axe for the player’s use. This unlocks the
    //        ability to mine for precious medals.

    tile_mountain // ⛰
    // bumps: 1
    // capacity: 10
    // dialog: 0
    // introduced: 77
    // mapped: 77
    // morphed: 0
    // morphee: 0
    // notes: Mountains produce copper. The player may encounter other kinds of
    //        mountains for higher denominations of precious medals later in the
    //        game, but for now they must trade copper up at the bank to get
    //        exact medals necessary for crafting various components at the
    //        forge.

    tile_owl // 🦉
    // bumps: 0
    // dialog: 3
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0
    // notes: The owl exists to hint thaat the player should find a way into the
    //        center of the world. Who are we kidding? The owl exists to tell a
    //        joke.

    tile_horse // 🐴
    // breed: horse
    // bumps: 1
    // dialog: 4
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 1
    // notes: The horse exists to fulfill a later stage quest, where the player
    //        has all the five essences and can transmutate the horse into a
    //        unicorn.
    // wander: 1

    tile_unicorn // 🦄
    // bumps: 0
    // dialog: 3
    // introduced: 1
    // mapped: 0
    // morphed: 1
    // morphee: 0
    // notes: Restoring the unicorn is one of the many mojical creatures that
    //        satisfy the end game condition of restoring all the mojical
    //        creatures.

    tile_wilted_rose // 🥀
    // bumps: 0
    // dialog: 3
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 1
    // notes: Restoring the wilted rose requires the power of water.

    tile_rose // 🌹
    // bumps: 0
    // dialog: 0
    // introduced: 1
    // mapped: 0
    // morphed: 1
    // morphee: 0
    // notes: Decoration and greeting joke.

    tile_carrot // 🥕
    // bumps: 1
    // dialog: 6
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0
    // notes: There might be a vision pun in here. Also the Warren Buffet pun.
    //        Also provides a material necessary to restore the abdominal
    //        snowman.

    tile_mermaid // 🧜‍♀️
    // bumps: 0
    // dialog: 1
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0

    tile_herman // 🏊‍♂️
    // bumps: 0
    // dialog: 5
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 1
    // notes: The Herman quest is to restore this merman (bottom half obscured)
    //        by reproducing his lost trident. He will then teach you about the
    //        essence of water.

    tile_merman // 🧜‍♂️
    // bumps: 0
    // dialog: 1
    // introduced: 1
    // mapped: 0
    // morphed: 1
    // morphee: 0

    tile_marco // 🤽‍♂️
    // bumps: 0
    // dialog: 4
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
    // wander: water

    tile_octopus // 🐙
    // bumps: 1
    // dialog: 0
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0

    tile_fish // 🐟
    // breed: fish
    // bumps: 0
    // dialog: 0
    // health: 1
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 1
    // wander: water

    tile_puffer_fish // 🐡
    // breed: puffer fish
    // bumps: 0
    // dialog: 0
    // introduced: 1
    // mapped: 0
    // morphed: 1
    // morphee: 0

    tile_turtle // 🐢
    // bumps: 0
    // dialog: 0
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0

    tile_island // 🏝
    // bumps: 1
    // capacity: 100
    // dialog: 0
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
    // renew: 1

    tile_date_palm_tree // 🌴
    // Flags: [palm_tree softwood]
    // bumps: 0
    // capacity: 1
    // dialog: 0
    // introduced: 6
    // mapped: 6
    // morphed: 0
    // morphee: 0
    // renew: 1

    tile_banana_tree // 🌴
    // Flags: [palm_tree softwood]
    // bumps: 0
    // capacity: 1
    // dialog: 0
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
    // renew: 1

    tile_coconut_tree // 🌴
    // Flags: [palm_tree softwood]
    // bumps: 0
    // capacity: 1
    // dialog: 0
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
    // renew: 1

    tile_sponge // 🧽
    // bumps: 0
    // dialog: 4
    // introduced: 213
    // mapped: 213
    // morphed: 0
    // morphee: 0

    tile_parrot // 🦜
    // bumps: 0
    // dialog: 0
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0

    tile_bank_of_occia // 🏦
    // Flags: [bank]
    // bumps: 0
    // dialog: 6
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0
    // notes: Wherein the emoji can exchange precious medals.

    tile_hibiscus // 🌺
    // bumps: 0
    // dialog: 2
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0
    // notes: Decoration and greeting joke.

    tile_drake // 🦆
    // bumps: 0
    // dialog: 3
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 1
    // notes: There’s male duck pun here. He becomes a fire drake with fire
    //        mojick.

    tile_fire_drake // 🐉
    // bumps: 0
    // dialog: 3
    // introduced: 1
    // mapped: 0
    // morphed: 1
    // morphee: 0
    // notes: Dragon is a fire drake. Also a Francis pun.

    tile_steamer // 🚂
    // bumps: 0
    // dialog: 0
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
    // notes: The steam train is the vehicle to carry you on the railway through
    //        the center of the world, spiraling around the inner loop of The
    //        Pole. To bring the train to life, you will need to master the
    //        essence of wind and water.

    tile_north_pole // 💈
    // bumps: 0
    // dialog: 8
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0
    // notes: The north pole is the home of Magie and Magus. They will teach you
    //        the essence of wind, but you must obtain for them an umbrella.
    //        They promise that it’s relevant.

    tile_sicko // 🤒
    // bumps: 0
    // dialog: 3
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0
    // notes: Needs a pill, gives a thermometer.

    tile_fist // 👊
    // bumps: 0
    // dialog: 3
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0
    // notes: Exists only for the punch line.

    tile_unlit_tree // 🌲
    // bumps: 0
    // dialog: 0
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 1
    // notes: The great pine of Borea was once mojical and glimmered with a
    //        thousand shining lights.

    tile_lit_tree // 🎄
    // bumps: 0
    // dialog: 0
    // introduced: 1
    // mapped: 0
    // morphed: 1
    // morphee: 0

    tile_bear // 🐻
    // bumps: 0
    // dialog: 3
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 2
    // notes: The polar bear has lost its mogical cloak of invisibility.

    tile_polar_bear // ⸪
    // bumps: 0
    // dialog: 1
    // introduced: 2
    // mapped: 0
    // morphed: 2
    // morphee: 0

    tile_abdominal_snowman // ⚪️
    // bumps: 0
    // dialog: 3
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 2
    // notes: The abdominal snowman is not much of a snowman. It needs some help
    //        to restore its mogical splendor. That may involve fetching a few
    //        items to restore it to its senses.

    tile_abominable_snowman // ⛄️
    // bumps: 0
    // dialog: 3
    // introduced: 2
    // mapped: 0
    // morphed: 2
    // morphee: 0

    tile_caribou // 🦌
    // bumps: 0
    // dialog: 1
    // introduced: 7
    // mapped: 7
    // morphed: 0
    // morphee: 1
    // notes: Caribou used to be able to fly. They were the preferred mode of
    //        boreal transportation before mojick faded.

    tile_whale // 🐋
    // bumps: 0
    // dialog: 4
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 1
    // notes: The whale was once the unicorn of the sea. Leaving its bay might
    //        set him on his journey to mojical restoration. As there is no
    //        Narwhal emoji, the creature just disappears in search of mojick,
    //        thereby completing the quest.

    tile_leaf // 🍃
    // bumps: 0
    // dialog: 1
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0
    // notes: For the leave me alone pun. Also, how you get bay leaves.

    tile_sal_the_snake // 🐍
    // bumps: 0
    // dialog: 1
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 1

    tile_sal_the_mander // 🦎
    // bumps: 0
    // dialog: 1
    // introduced: 69
    // mapped: 68
    // morphed: 1
    // morphee: 0

    tile_cheese_wizard // 🧙‍♂️
    // bumps: 0
    // dialog: 1
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0

    tile_sand_witch // 🧙‍♀️
    // bumps: 0
    // dialog: 1
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0

    tile_south_pole // 🗼
    // bumps: 0
    // dialog: 1
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0

    tile_jennie // 🧞‍♀️
    // bumps: 0
    // dialog: 1
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0

    tile_gene // 🧞‍♂️
    // bumps: 0
    // dialog: 1
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0

    tile_cactus // 🌵
    // bumps: 1
    // dialog: 3
    // introduced: 239
    // mapped: 239
    // morphed: 0
    // morphee: 0

    tile_bamboo // 🎍
    // bumps: 0
    // dialog: 0
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0

    tile_prepanda // 🐻
    // bumps: 0
    // dialog: 6
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0
    // notes: Becomes a panda. Needs a mogical recipe.

    tile_panda // 🐼
    // bumps: 0
    // dialog: 0
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0

    tile_craft_guild // 🏬
    // bumps: 0
    // dialog: 2
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0
    // notes: So far, the craft guild’s sole purpose is to recite puns about
    //        crafts.

    tile_eagle // 🦅
    // bumps: 0
    // dialog: 3
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0

    tile_lettuce // 🥬
    // bumps: 0
    // dialog: 9
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0
    // notes: Just puns, as yet.

    tile_sun // ☀️
    // bumps: 0
    // dialog: 1
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0

    tile_sol // 🌞
    // bumps: 0
    // dialog: 1
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0

    tile_moon // 🌙
    // bumps: 0
    // dialog: 1
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 1

    tile_lune // 🌝
    // bumps: 0
    // dialog: 1
    // introduced: 1
    // mapped: 0
    // morphed: 1
    // morphee: 0

    tile_asteroid // ☄️
    // bumps: 0
    // dialog: 1
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0
    // wander: sky

    tile_dumbledore // 🐝
    // bumps: 0
    // dialog: 1
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0

    tile_high_mountain // 🏔
    // bumps: 1
    // capacity: 10
    // dialog: 1
    // introduced: 267
    // mapped: 267
    // morphed: 0
    // morphee: 0

    tile_volcano // 🗻
    // bumps: 1
    // capacity: 10
    // dialog: 1
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0

    tile_gym // 🏥
    // bumps: 0
    // dialog: 3
    // indoor: 1
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0

    tile_observatory // 🔭
    // bumps: 0
    // dialog: 1
    // indoor: 1
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0

    tile_justin // 🕰
    // Flags: [clock]
    // bumps: 0
    // dialog: 1
    // indoor: 1
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0

    tile_nick // ⏰
    // Flags: [clock]
    // bumps: 0
    // dialog: 1
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0

    tile_bakery // 🏭
    // bumps: 0
    // dialog: 4
    // indoor: 1
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0

    tile_plumber // 👨🏻‍🔧
    // bumps: 0
    // dialog: 1
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0

    tile_genome // 👨🏼‍🌾
    // bumps: 0
    // dialog: 1
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0

    tile_pat // 👨🏻‍🦰
    // bumps: 0
    // dialog: 1
    // introduced: 0
    // mapped: 0
    // morphed: 0
    // morphee: 0

    tile_kris_and_lydia // 🏡
    // bumps: 0
    // dialog: 4
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 0

    tile_kitty // 🐈
    // bumps: 0
    // dialog: 1
    // introduced: 1
    // mapped: 1
    // morphed: 0
    // morphee: 1

    tile_tiger // 🐅
    // bumps: 0
    // dialog: 1
    // introduced: 1
    // mapped: 0
    // morphed: 1
    // morphee: 0

    tile_infernia_warning_sign // 🚧
    // bumps: 0
    // dialog: 5
    // introduced: 26
    // mapped: 26
    // morphed: 0
    // morphee: 0

    tile_asia // 🌏
    // bumps: 0
    // dialog: 1
    // introduced: 1
    // mapped: 0
    // morphed: 1
    // morphee: 1

    tile_africa // 🌍
    // bumps: 0
    // dialog: 1
    // introduced: 1
    // mapped: 0
    // morphed: 1
    // morphee: 1

    tile_america // 🌎
    // bumps: 0
    // dialog: 1
    // introduced: 1
    // mapped: 0
    // morphed: 1
    // morphee: 1

let tile_sprite_id = [
    -1, // tile_none
    17, // tile_apple_tree
    18, // tile_pine_tree
    17, // tile_pear_tree
    19, // tile_clover
    95, // tile_ewe
    96, // tile_ram
    97, // tile_cow
    98, // tile_ox
    99, // tile_castle
    100, // tile_euia_bank
    101, // tile_euia_forge
    57, // tile_glub
    102, // tile_major
    103, // tile_captain
    104, // tile_miner
    105, // tile_harriet
    106, // tile_jack
    107, // tile_boulder
    107, // tile_mountain
    108, // tile_owl
    109, // tile_horse
    82, // tile_unicorn
    110, // tile_wilted_rose
    111, // tile_rose
    65, // tile_carrot
    112, // tile_mermaid
    113, // tile_herman
    114, // tile_merman
    115, // tile_marco
    116, // tile_octopus
    57, // tile_fish
    117, // tile_puffer_fish
    60, // tile_turtle
    58, // tile_island
    118, // tile_date_palm_tree
    118, // tile_banana_tree
    118, // tile_coconut_tree
    119, // tile_sponge
    120, // tile_parrot
    100, // tile_bank_of_occia
    121, // tile_hibiscus
    122, // tile_drake
    123, // tile_fire_drake
    124, // tile_steamer
    125, // tile_north_pole
    8, // tile_sicko
    126, // tile_fist
    18, // tile_unlit_tree
    127, // tile_lit_tree
    128, // tile_bear
    129, // tile_polar_bear
    130, // tile_abdominal_snowman
    131, // tile_abominable_snowman
    132, // tile_caribou
    133, // tile_whale
    68, // tile_leaf
    134, // tile_sal_the_snake
    135, // tile_sal_the_mander
    136, // tile_cheese_wizard
    137, // tile_sand_witch
    138, // tile_south_pole
    139, // tile_jennie
    140, // tile_gene
    70, // tile_cactus
    93, // tile_bamboo
    128, // tile_prepanda
    141, // tile_panda
    142, // tile_craft_guild
    143, // tile_eagle
    144, // tile_lettuce
    145, // tile_sun
    146, // tile_sol
    147, // tile_moon
    77, // tile_lune
    148, // tile_asteroid
    149, // tile_dumbledore
    150, // tile_high_mountain
    151, // tile_volcano
    152, // tile_gym
    153, // tile_observatory
    154, // tile_justin
    155, // tile_nick
    101, // tile_bakery
    156, // tile_plumber
    157, // tile_genome
    158, // tile_pat
    106, // tile_kris_and_lydia
    159, // tile_kitty
    160, // tile_tiger
    161, // tile_infernia_warning_sign
    162, // tile_asia
    163, // tile_africa
    164, // tile_america
]

let tile_names = [
    "empty tile",
    "apple tree/hardwood",
    "pine tree/softwood",
    "pear tree/hardwood",
    "clover",
    "ewe/sheep",
    "ram/sheep",
    "cow/cow/coat",
    "ox/cow/nude",
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
    "owl",
    "horse",
    "unicorn",
    "wilted rose",
    "rose",
    "carrot",
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
    "bank of occia/bank",
    "hibiscus",
    "drake",
    "fire drake",
    "steamer",
    "north pole",
    "sicko",
    "fist",
    "unlit tree",
    "lit tree",
    "bear",
    "polar bear",
    "abdominal snowman",
    "abominable snowman",
    "caribou",
    "whale",
    "leaf",
    "sal the snake",
    "sal the mander",
    "cheese wizard",
    "sand witch",
    "south pole",
    "jennie",
    "gene",
    "cactus",
    "bamboo",
    "prepanda",
    "panda",
    "craft guild",
    "eagle",
    "lettuce",
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
    165, // ui_north
    166, // ui_east
    167, // ui_south
    168, // ui_west
    169, // ui_rest
    170, // ui_health_heart
    171, // ui_stamina_heart
    172, // ui_cure_heart
    173, // ui_empty_heart
    174, // ui_discard
    175, // ui_left_hand
    176, // ui_right_hand
    177, // ui_point_north
    178, // ui_point_east
    179, // ui_point_south
    180, // ui_point_west
    181, // ui_spock_hand
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

