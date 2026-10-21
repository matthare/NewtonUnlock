import Foundation

enum GameInput {
    case regCode    // the code shown on the game's registration screen
    case name       // the owner / registration name
    case none       // nothing to enter: the game has one fixed code
}

struct Game: Identifiable {
    let id: String
    let title: String
    let publisher: String
    let input: GameInput
    let hint: String
    let compute: (String) throws -> String
}

private let tactileHint =
    "Enter the registration code shown on the game's registration screen. "
    + "The X at each end of the unlock code can be any letter."

private func tactile(_ id: String, _ title: String, salt: String) -> Game {
    Game(id: id, title: title, publisher: "Tactile Systems", input: .regCode, hint: tactileHint) {
        try tactileUnlock($0, salt: salt)
    }
}

let allGames: [Game] = [
    tactile("columns", "Columns", salt: "MF"),
    Game(id: "deepspacenewt", title: "DeepSpaceNewt", publisher: "DejaVu Software", input: .name,
         hint: "Enter the owner name exactly as it appears on the Newton's owner card.") {
        try deepSpaceNewtCode($0)
    },
    Game(id: "mahjongg", title: "Mahjongg", publisher: "Scrawl", input: .name,
         hint: "Enter the owner name from the Newton's owner card, or the Serial Number shown in Mahjongg's About box.") {
        scrawlString($0, suffix: "Mahjongg")
    },
    Game(id: "minefieldii", title: "MineField II", publisher: "Tactile Systems", input: .regCode,
         hint: "Enter the registration code shown on the game's registration screen. "
             + "Type the unlock code exactly, including the X at each end.") {
        try mineFieldUnlock($0)
    },
    tactile("motile", "Motile", salt: "FK"),
    Game(id: "newthack", title: "NewtHack", publisher: "Chris Dopp", input: .name,
         hint: "Enter the owner name from the Newton's owner card. Enter the number with NewtHack's number picker.") {
        try newtHackNumber($0)
    },
    Game(id: "newtopoly", title: "Newtopoly", publisher: "", input: .name,
         hint: "Enter the name exactly as you will type it on Newtopoly's registration slip.") {
        try newtopolyCode($0)
    },
    tactile("scramble", "Scramble", salt: "OW"),
    tactile("seahunt", "Sea Hunt", salt: "VB"),
    // Fixed code, from siliconcasino/serialnumber.txt
    Game(id: "siliconcasino", title: "Silicon Casino", publisher: "Casady & Greene", input: .none,
         hint: "No input needed: this is your Silicon Casino registration code.") { _ in
        "20837826"
    },
    tactile("solitodx", "Solito DX", salt: "BL"),
    tactile("supernewtris", "Super Newtris", salt: "NS"),
    tactile("worldcon", "World Conquest", salt: "KQ"),
    tactile("xwordbuddy", "xWord Buddy", salt: "UO"),
    tactile("xwordsearch", "xWord Search", salt: "YA"),
    Game(id: "yazi", title: "YAZI", publisher: "Scrawl", input: .name,
         hint: "Enter the owner name from the Newton's owner card (or an owner persona's name).") {
        scrawlString($0, suffix: "YAZI")
    },
]
