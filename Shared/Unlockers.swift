// Swift ports of the Python scripts in each game's folder (e.g. worldcon/worldcon_unlock.py).
// Each function must give exactly the same result as its Python original.

import Foundation

struct UnlockError: LocalizedError {
    let errorDescription: String?
    init(_ message: String) { errorDescription = message }
}

/// Unicode code points of a string, matching Python's ord() over a str.
private func codePoints(_ s: String) -> [Int] { s.unicodeScalars.map { Int($0.value) } }

private func string(from codes: [Int]) -> String {
    String(String.UnicodeScalarView(codes.compactMap { Unicode.Scalar(UInt32($0)) }))
}

private func parseRegCode(_ text: String) throws -> Int {
    let t = text.trimmingCharacters(in: .whitespaces)
    guard !t.isEmpty, t.count <= 18, t.allSatisfy({ $0.isASCII && $0.isNumber }), let n = Int(t) else {
        throw UnlockError("The registration code should be digits only.")
    }
    return n
}

/// Shared tail of Tactile's scheme: digit pairs from the right become letters and a sum.
private func tactileBody(_ n: Int) throws -> (letters: String, total: Int) {
    guard n >= 0 else { throw UnlockError("That registration code is too small to be valid.") }
    let digits = String(n).map { Int(String($0))! }
    var total = 0
    var letters: [Int] = []
    var i = digits.count - 1
    while i >= 1 {
        total += 48 + digits[i]                 // ord() of the digit character
        letters.append(65 + digits[i] + digits[i - 1])
        i -= 2
    }
    return (string(from: letters), total)
}

// MARK: - Tactile Systems (salted) — worldcon_unlock.py and friends

func tactileUnlock(_ regCode: String, salt: String) throws -> String {
    let s = codePoints(salt)
    let n = try parseRegCode(regCode) - (s[0] * 100 + s[1])
    let (letters, total) = try tactileBody(n)
    return "X" + letters.prefix(2) + String(total) + letters.suffix(2) + "X"
}

// MARK: - MineField II — minefieldii_unlock.py

func mineFieldUnlock(_ regCode: String, first: Character = "X", last: Character = "X") throws -> String {
    let f = codePoints(String(first).uppercased())[0]
    let l = codePoints(String(last).uppercased())[0]
    let a = 90 - (f - 65)
    let b = 90 - (l - 65)
    let n = try parseRegCode(regCode) - (a * 100 + b)
    let (letters, total) = try tactileBody(n)
    return String(first).uppercased() + letters.prefix(2) + String(total) + letters.suffix(2)
        + String(last).uppercased()
}

// MARK: - Newtopoly — newtopoly_unlock.py

private let md2S: [Int] = [
    41, 46, 67, 201, 162, 216, 124, 1, 61, 54, 84, 161, 236, 240, 6, 19,
    98, 167, 5, 243, 192, 199, 115, 140, 152, 147, 43, 217, 188, 76, 130, 202,
    30, 155, 87, 60, 253, 212, 224, 22, 103, 66, 111, 24, 138, 23, 229, 18,
    190, 78, 196, 214, 218, 158, 222, 73, 160, 251, 245, 142, 187, 47, 238, 122,
    169, 104, 121, 145, 21, 178, 7, 63, 148, 194, 16, 137, 11, 34, 95, 33,
    128, 127, 93, 154, 90, 144, 50, 39, 53, 62, 204, 231, 191, 247, 151, 3,
    255, 25, 48, 179, 72, 165, 181, 209, 215, 94, 146, 42, 172, 86, 170, 198,
    79, 184, 56, 210, 150, 164, 125, 182, 118, 252, 107, 226, 156, 116, 4, 241,
    69, 157, 112, 89, 100, 113, 135, 32, 134, 91, 207, 101, 230, 45, 168, 2,
    27, 96, 37, 173, 174, 176, 185, 246, 28, 70, 97, 105, 52, 64, 126, 15,
    85, 71, 163, 35, 221, 81, 175, 58, 195, 92, 249, 206, 186, 197, 234, 38,
    44, 83, 13, 110, 133, 40, 132, 9, 211, 223, 205, 244, 65, 129, 77, 82,
    106, 220, 55, 200, 108, 193, 171, 250, 36, 225, 123, 8, 12, 189, 177, 74,
    120, 136, 149, 139, 227, 99, 232, 109, 233, 203, 213, 254, 59, 0, 29, 57,
    242, 239, 183, 14, 102, 88, 208, 228, 166, 119, 114, 248, 235, 117, 75, 10,
    49, 68, 80, 180, 143, 237, 31, 26, 219, 153, 141, 51, 159, 17, 131, 20,
]

func newtopolyCode(_ name: String) throws -> String {
    var msg = codePoints(name + "    ")
    guard msg.count >= 6 else { throw UnlockError("The name must be at least 2 characters.") }
    msg[0] ^= Int(Character("Q").asciiValue!)
    msg[1] ^= Int(Character("X").asciiValue!)
    guard msg.allSatisfy({ $0 < 256 }) else {
        throw UnlockError("The name contains a character the Newton can't hash.")
    }

    // MD2 padding
    let pad = 16 - msg.count % 16
    msg += Array(repeating: pad, count: pad)

    // Checksum, with Newtopoly's quirk: C[j] = S[c ^ L] (standard MD2 uses ^=)
    var c = Array(repeating: 0, count: 16), l = 0
    for i in stride(from: 0, to: msg.count, by: 16) {
        for j in 0..<16 {
            c[j] = md2S[msg[i + j] ^ l]
            l = c[j]
        }
    }
    msg += c

    // MD2 compression
    var x = Array(repeating: 0, count: 48)
    for i in stride(from: 0, to: msg.count, by: 16) {
        for j in 0..<16 {
            x[16 + j] = msg[i + j]
            x[32 + j] = x[16 + j] ^ x[j]
        }
        var t = 0
        for j in 0..<18 {
            for k in 0..<48 {
                t = x[k] ^ md2S[t]
                x[k] = t
            }
            t = (t + j) % 256
        }
    }

    // First 8 bytes as hex, with the quirk: high nibble is (b - 1) div 16,
    // where div truncates toward zero (so b = 0 gives 0, not -1)
    let hex = Array("0123456789abcdef")
    return String(x[..<8].flatMap { b in [hex[(b - 1) / 16], hex[b % 16]] })
}

// MARK: - NewtHack — newthack_unlock.py

func newtHackNumber(_ ownerName: String) throws -> String {
    let key = codePoints("NewtHack:ChrisDopp")
    var name = codePoints(ownerName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
    if name.count < 7 { name += key }
    guard name.count >= 8 else {
        throw UnlockError("NewtHack can't register a name that is exactly 7 characters long.")
    }
    // Even positions come from the app symbol, odd positions from the name
    var digits = ""
    for i in 0..<8 {
        let c = i % 2 == 1 ? name[i] : key[i]
        digits += String(c % 10)
    }
    return String(Int(digits)!)   // drop leading zeros, as StringToNumber does
}

// MARK: - YAZI and Mahjongg (Scrawl) — yazi_unlock.py, mahjongg_unlock.py

func scrawlString(_ name: String, suffix: String) -> String {
    var s = codePoints(name + suffix)
    while s.count < 20 { s += s }

    var h = 0
    for c in s {
        h = ((h << 4) & 0x1FFF_FFFF) + c
        h &= 0x1FFF_FFFF
        let g = h & 0x1E00_0000
        if g != 0 { h = (h ^ (g >> 22)) & 0x01FF_FFFF }
    }
    return string(from: stride(from: 0, to: 27, by: 3).map { ((h >> $0) & 0xF) + 0x61 })
}

// MARK: - DeepSpaceNewt — deepspacenewt_unlock.py

func deepSpaceNewtCode(_ ownerName: String) throws -> String {
    let name = codePoints(ownerName)
    let key = codePoints("DeepSpaceNewt")
    guard !name.isEmpty else { throw UnlockError("Enter the owner name.") }
    let count = (name.count + key.count) % 7 + 7      // loop runs 0...count inclusive
    var i = 0, j = 0
    var out: [Int] = []
    for _ in 0...count {
        let a = name[i] + key[j]
        i = (i + 1) % name.count; j = (j + 1) % key.count
        let b = name[i] + key[j]
        i = (i + 1) % name.count; j = (j + 1) % key.count
        var v = ((a & 85) | (b & 170)) % 36 + 48
        if v >= 58 { v = v - 58 + 97 }                 // past '9' -> 'a'...'z'
        out.append(v)
    }
    return string(from: out)
}
