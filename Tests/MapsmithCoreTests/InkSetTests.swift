import Foundation
import Testing
@testable import MapsmithCore

@Suite struct InkSetTests {
    /// The Canon TS9550's XL cartridges, as its spec sheet rates them.
    static let canonXL = InkSet(price: 868, cartridges: [
        InkCartridge(name: "Magenta", ink: .magenta, ratedPages: 474),
        InkCartridge(name: "Black(BK)", ink: .unused, ratedPages: 3120),
        InkCartridge(name: "Yellow", ink: .yellow, ratedPages: 514),
        InkCartridge(name: "Black(PGBK)", ink: .black, ratedPages: 400),
        InkCartridge(name: "Cyan", ink: .cyan, ratedPages: 515)
    ])

    @Test func aPageAtRatedCoverageCostsEachCartridgesShareOverItsYield() {
        let set = InkSet(price: 100, cartridges: [
            InkCartridge(name: "Cyan", ink: .cyan, ratedPages: 200),
            InkCartridge(name: "Black", ink: .black, ratedPages: 400)
        ])
        let cost = set.cost(of: InkCoverage(cyan: 0.05, black: 0.05))
        // 50 / 200 + 50 / 400
        #expect(abs(NSDecimalNumber(decimal: cost).doubleValue - 0.375) < 1e-9)
    }

    @Test func unusedCartridgesTakeTheirShareOfThePriceButAreNotCharged() {
        let cost = Self.canonXL.cost(of: InkCoverage(black: 0.05))
        // 868 over all 5 cartridges, one rated page of pigment black out of 400; the dye black isn't charged.
        #expect(abs(NSDecimalNumber(decimal: cost).doubleValue - 868.0 / 5 / 400) < 1e-9)
    }

    @Test func whitePaperCostsNothing() {
        #expect(Self.canonXL.cost(of: .zero) == 0)
    }

    @Test func aSetWithoutUsedCartridgesCostsNothing() {
        let set = InkSet(price: 100, cartridges: [InkCartridge(name: "Black", ink: .unused, ratedPages: 100)])
        #expect(set.cost(of: InkCoverage(black: 1)) == 0)
        #expect(!set.isComplete)
        #expect(InkSet(price: 100, cartridges: []).cost(of: InkCoverage(black: 1)) == 0)
    }

    @Test func aCartridgeWithoutAYieldAddsNothing() {
        let set = InkSet(price: 100, cartridges: [
            InkCartridge(name: "Cyan", ink: .cyan, ratedPages: 0),
            InkCartridge(name: "Black", ink: .black, ratedPages: 100)
        ])
        #expect(set.cost(of: InkCoverage(cyan: 1)) == 0)
    }

    @Test func isCompleteNeedsAPriceAndEveryUsedYield() {
        #expect(Self.canonXL.isComplete)
        var noPrice = Self.canonXL
        noPrice.price = 0
        #expect(!noPrice.isComplete)
        var missingYield = Self.canonXL
        missingYield.cartridges[0].ratedPages = 0
        #expect(!missingYield.isComplete)
        var unusedWithoutYield = Self.canonXL
        unusedWithoutYield.cartridges[1].ratedPages = 0
        #expect(unusedWithoutYield.isComplete)
    }

    @Test func defaultsKeepThePigmentBlack() {
        let supplies = PrinterSupply.list(names: "Magenta,Black(BK),Yellow,Black(PGBK),Cyan",
                                          colors: "#F200FF,#000000,#FFDA00,#000000,#00CFFF",
                                          types: Array(repeating: "ink-cartridge", count: 5).joined(separator: ","))
        let set = InkSet.defaults(from: supplies)
        #expect(set.cartridges.map(\.ink) == [.magenta, .unused, .yellow, .black, .cyan])
        #expect(set.price == 0 && set.cartridges.allSatisfy { $0.ratedPages == 0 })
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
