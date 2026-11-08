import Foundation

/// One cartridge of a printer's ink set.
public struct InkCartridge: Codable, Equatable, Hashable, Sendable {
    public var name: String
    public var ink: InkColor
    /// The rated yield in A4 pages at 5% coverage (ISO/IEC 24711); 0 while unknown.
    public var ratedPages: Int

    public init(name: String, ink: InkColor, ratedPages: Int = 0) {
        self.name = name
        self.ink = ink
        self.ratedPages = ratedPages
    }
}

/// What a complete set of one printer's ink costs, and what each cartridge yields.
public struct InkSet: Codable, Equatable, Sendable {
    /// The coverage of each ink that the rated yield is measured at.
    public static let ratedCoverage = 0.05

    public var price: Decimal
    public var cartridges: [InkCartridge]

    public init(price: Decimal = 0, cartridges: [InkCartridge]) {
        self.price = price
        self.cartridges = cartridges
    }

    /// The cartridges charged for maps.
    public var usedCartridges: [InkCartridge] { cartridges.filter { $0.ink != .unused } }

    /// True when there is a price and every cartridge used for maps has a rated yield.
    public var isComplete: Bool {
        price > 0 && !usedCartridges.isEmpty && usedCartridges.allSatisfy { $0.ratedPages > 0 }
    }

    /// The cost of printing `coverage`: each used cartridge's share of the price (the price over all the
    /// set's cartridges, used for maps or not), times its ink's coverage over the rated coverage, over its
    /// rated pages.
    public func cost(of coverage: InkCoverage) -> Decimal {
        guard !cartridges.isEmpty else { return 0 }
        let pagesOfYield = usedCartridges.reduce(0.0) { total, cartridge in
            guard cartridge.ratedPages > 0 else { return total }
            return total + coverage[cartridge.ink] / Self.ratedCoverage / Double(cartridge.ratedPages)
        }
        return price / Decimal(cartridges.count) * Decimal(pagesOfYield)
    }

    /// A set for a printer's reported supplies, with no price or yields yet. Each cartridge's ink comes
    /// from its reported color or name; of several blacks only one is used, preferring pigment black
    /// ("PG"), which prints black on plain paper. A printer that reports nothing gets cyan, magenta,
    /// yellow and black.
    public static func defaults(from supplies: [PrinterSupply]) -> InkSet {
        let cartridges = supplies.filter(\.isInk).map { InkCartridge(name: $0.name, ink: $0.ink) }
        guard !cartridges.isEmpty else { return standard }
        return InkSet(cartridges: keepingOneBlack(cartridges))
    }

    static let standard = InkSet(cartridges: [
        InkCartridge(name: "Cyan", ink: .cyan), InkCartridge(name: "Magenta", ink: .magenta),
        InkCartridge(name: "Yellow", ink: .yellow), InkCartridge(name: "Black", ink: .black)
    ])

    private static func keepingOneBlack(_ cartridges: [InkCartridge]) -> [InkCartridge] {
        let blacks = cartridges.indices.filter { cartridges[$0].ink == .black }
        guard blacks.count > 1 else { return cartridges }
        let kept = blacks.first { cartridges[$0].name.uppercased().contains("PG") } ?? blacks[0]
        var result = cartridges
        for index in blacks where index != kept { result[index].ink = .unused }
        return result
    }
}
