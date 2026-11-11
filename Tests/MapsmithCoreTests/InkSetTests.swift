import Foundation
import Testing
@testable import MapsmithCore

@Suite struct InkSetTests {
    /// The Canon TS9550's XL cartridges, as its spec sheet rates them, each with its own price.
    static let canonXL = InkSet(cartridges: [
        InkCartridge(name: "Magenta", ink: .magenta, ratedPages: 474, price: 180),
        InkCartridge(name: "Black(BK)", ink: .unused, ratedPages: 3120, price: 220),
        InkCartridge(name: "Yellow", ink: .yellow, ratedPages: 514, price: 170),
        InkCartridge(name: "Black(PGBK)", ink: .black, ratedPages: 400, price: 190),
        InkCartridge(name: "Cyan", ink: .cyan, ratedPages: 515, price: 108)
    ])

    private func value(_ cost: Decimal) -> Double { NSDecimalNumber(decimal: cost).doubleValue }

    @Test func aPageAtRatedCoverageCostsEachCartridgesPriceOverItsYield() {
        let set = InkSet(cartridges: [
            InkCartridge(name: "Cyan", ink: .cyan, ratedPages: 200, price: 50),
            InkCartridge(name: "Black", ink: .black, ratedPages: 400, price: 80)
        ])
        let cost = set.cost(of: InkCoverage(cyan: 0.05, black: 0.05))
        // 50 / 200 + 80 / 400
        #expect(abs(value(cost) - 0.45) < 1e-9)
    }

    @Test func eachCartridgeIsPricedOnItsOwn() {
        let cost = Self.canonXL.cost(of: InkCoverage(cyan: 0.05, magenta: 0.05, yellow: 0.05, black: 0.05))
        #expect(abs(value(cost) - (180.0 / 474 + 170.0 / 514 + 190.0 / 400 + 108.0 / 515)) < 1e-9)
    }

    @Test func unusedCartridgesAreNotCharged() {
        let cost = Self.canonXL.cost(of: InkCoverage(black: 0.05))
        // Only the pigment black is charged; the dye black's price doesn't matter.
        #expect(abs(value(cost) - 190.0 / 400) < 1e-9)
    }

    @Test func whitePaperCostsNothing() {
        #expect(Self.canonXL.cost(of: .zero) == 0)
    }

    @Test func aSetWithoutUsedCartridgesCostsNothing() {
        let set = InkSet(cartridges: [InkCartridge(name: "Black", ink: .unused, ratedPages: 100, price: 20)])
        #expect(set.cost(of: InkCoverage(black: 1)) == 0)
        #expect(!set.isComplete)
        #expect(InkSet(cartridges: []).cost(of: InkCoverage(black: 1)) == 0)
    }

    @Test func aCartridgeWithoutAYieldAddsNothing() {
        let set = InkSet(cartridges: [
            InkCartridge(name: "Cyan", ink: .cyan, ratedPages: 0, price: 20),
            InkCartridge(name: "Black", ink: .black, ratedPages: 100, price: 20)
        ])
        #expect(set.cost(of: InkCoverage(cyan: 1)) == 0)
    }

    @Test func isCompleteNeedsAPriceAndAYieldForEveryUsedCartridge() {
        #expect(Self.canonXL.isComplete)
        var noPrice = Self.canonXL
        noPrice.cartridges[0].price = 0
        #expect(!noPrice.isComplete)
        var missingYield = Self.canonXL
        missingYield.cartridges[0].ratedPages = 0
        #expect(!missingYield.isComplete)
        var unusedWithoutDetails = Self.canonXL
        unusedWithoutDetails.cartridges[1].ratedPages = 0
        unusedWithoutDetails.cartridges[1].price = 0
        #expect(unusedWithoutDetails.isComplete)
    }

    @Test func defaultsKeepThePigmentBlack() {
        let supplies = PrinterSupply.list(names: "Magenta,Black(BK),Yellow,Black(PGBK),Cyan",
                                          colors: "#F200FF,#000000,#FFDA00,#000000,#00CFFF",
                                          types: Array(repeating: "ink-cartridge", count: 5).joined(separator: ","))
        let set = InkSet.defaults(from: supplies)
        #expect(set.cartridges.map(\.ink) == [.magenta, .unused, .yellow, .black, .cyan])
        #expect(set.cartridges.allSatisfy { $0.price == 0 && $0.ratedPages == 0 })
    }

    @Test func defaultsKeepTheFirstBlackWithoutPigmentBlack() {
        let supplies = [PrinterSupply(name: "Black", color: "#000000", type: "toner"),
                        PrinterSupply(name: "Photo Black", color: "#000000", type: "toner")]
        #expect(InkSet.defaults(from: supplies).cartridges.map(\.ink) == [.black, .unused])
    }

    @Test func defaultsLeaveOutDrumsAndWaste() {
        let supplies = [PrinterSupply(name: "Toner", color: "#000000", type: "toner"),
                        PrinterSupply(name: "Waste", color: "none", type: "waste-toner")]
        #expect(InkSet.defaults(from: supplies).cartridges.map(\.name) == ["Toner"])
    }

    @Test func aPrinterReportingNothingGetsFourInks() {
        #expect(InkSet.defaults(from: []).cartridges.map(\.ink) == [.cyan, .magenta, .yellow, .black])
    }
}
