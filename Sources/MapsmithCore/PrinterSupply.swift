import Foundation

/// A supply a printer reports through CUPS (`marker-names`, `marker-colors`, `marker-types`).
public struct PrinterSupply: Equatable, Sendable {
    public var name: String
    /// The reported color, such as `#00CFFF`, or `none`.
    public var color: String
    /// The reported type, such as `ink-cartridge`, `toner` or `waste-toner`.
    public var type: String

    public init(name: String, color: String, type: String) {
        self.name = name
        self.color = color
        self.type = type
    }

    /// Ink cartridges and toner; not drums, waste containers or fusers.
    public var isInk: Bool { type == "ink-cartridge" || type == "toner" }

    /// The ink this supply prints, from its color, else its name.
    public var ink: InkColor { Self.ink(ofHex: color) ?? Self.ink(ofName: name) }

    /// The supplies in CUPS's comma-separated option values; empty when they don't line up. A serial
    /// number after a semicolon ("Toner, PN 106R03757;SN80A9") is left out of the name.
    public static func list(names: String, colors: String, types: String) -> [PrinterSupply] {
        let names = splitList(names).map { String($0.prefix { $0 != ";" }) }
        let colors = splitList(colors), types = splitList(types)
        guard !names.isEmpty, names.count == colors.count, names.count == types.count else { return [] }
        return names.indices.map { PrinterSupply(name: names[$0], color: colors[$0], type: types[$0]) }
    }

    /// Splits a CUPS list value at its commas, honoring backslash escapes and quotes. Some printers leave
    /// a comma inside a name unescaped ("Toner\ black,\ PN\ 1"); a piece starting with a space is
    /// the rest of the name before it.
    static func splitList(_ value: String) -> [String] {
        splitAtCommas(value).reduce(into: []) { items, piece in
            if piece.hasPrefix(" "), let last = items.popLast() {
                items.append(last + "," + piece)
            } else {
                items.append(piece)
            }
        }
    }

    private static func splitAtCommas(_ value: String) -> [String] {
        guard !value.isEmpty else { return [] }
        var items: [String] = [], current = "", quote: Character?, escaped = false
        for character in value {
            if escaped {
                current.append(character)
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if let open = quote {
                if character == open { quote = nil } else { current.append(character) }
            } else if character == "\"" || character == "'" {
                quote = character
            } else if character == "," {
                items.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }
        items.append(current)
        return items
    }

    static func ink(ofHex hex: String) -> InkColor? {
        guard hex.hasPrefix("#"), hex.count == 7, let value = Int(hex.dropFirst(), radix: 16) else { return nil }
        let isHigh = [(value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF].map { $0 >= 0x80 }
        switch (isHigh[0], isHigh[1], isHigh[2]) {
        case (false, false, false): return .black
        case (false, true, true): return .cyan
        case (true, false, true): return .magenta
        case (true, true, false): return .yellow
        default: return nil
        }
    }

    static func ink(ofName name: String) -> InkColor {
        let lowered = name.lowercased()
        let keywords: [(InkColor, [String])] = [
            (.cyan, ["cyan"]), (.magenta, ["magenta"]), (.yellow, ["yellow", "gul", "gelb", "jaune"]),
            (.black, ["black", "svart", "schwarz", "noir"])
        ]
        return keywords.first { $0.1.contains(where: lowered.contains) }?.0 ?? .unused
    }
}
