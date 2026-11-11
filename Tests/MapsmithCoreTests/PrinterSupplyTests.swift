import Foundation
import Testing
@testable import MapsmithCore

@Suite struct PrinterSupplyTests {
    @Test func listsSuppliesFromCUPSValues() {
        let supplies = PrinterSupply.list(names: "Cyan,Black(PGBK)", colors: "#00CFFF,#000000",
                                          types: "ink-cartridge,ink-cartridge")
        #expect(supplies == [PrinterSupply(name: "Cyan", color: "#00CFFF", type: "ink-cartridge"),
                             PrinterSupply(name: "Black(PGBK)", color: "#000000", type: "ink-cartridge")])
    }

    @Test func namesWithUnescapedCommasStayWholeWithoutTheSerialNumber() {
        let names = #"Färgpulverkassett\ svart,\ PN\ 106R03757;SN80A9,Överskottsbehållare,\ PN\ 115R00129"#
        let supplies = PrinterSupply.list(names: names, colors: "#000000,none", types: "toner,waste-toner")
        #expect(supplies.map(\.name) == ["Färgpulverkassett svart, PN 106R03757",
                                          "Överskottsbehållare, PN 115R00129"])
    }

    @Test func valuesThatDontLineUpGiveNothing() {
        #expect(PrinterSupply.list(names: "Cyan,Magenta", colors: "#00FFFF", types: "toner").isEmpty)
        #expect(PrinterSupply.list(names: "", colors: "", types: "").isEmpty)
    }

    @Test func splittingHonorsEscapesAndQuotes() {
        #expect(PrinterSupply.splitList(#"Toner\ black,\ PN\ 1,Drum"#) == ["Toner black, PN 1", "Drum"])
        #expect(PrinterSupply.splitList(#""Toner, black",'Drum, cyan'"#) == ["Toner, black", "Drum, cyan"])
    }

    @Test(arguments: [("#00CFFF", InkColor.cyan), ("#F200FF", .magenta), ("#FFDA00", .yellow), ("#000000", .black)])
    func inkComesFromTheColor(hex: String, ink: InkColor) {
        #expect(PrinterSupply(name: "Ink", color: hex, type: "ink-cartridge").ink == ink)
    }

    @Test(arguments: [("Färgpulverkassett gul", InkColor.yellow), ("Toner Schwarz", .black),
                      ("Light Cyan", .cyan), ("Magenta", .magenta), ("Gloss Optimizer", .unused)])
    func inkFallsBackToTheName(name: String, ink: InkColor) {
        #expect(PrinterSupply(name: name, color: "none", type: "toner").ink == ink)
    }

    @Test func aColorThatIsNoInkFallsBackToTheName() {
        #expect(PrinterSupply(name: "Photo Gray", color: "#808080", type: "ink-cartridge").ink == .unused)
        #expect(PrinterSupply(name: "Red", color: "#FF0000", type: "ink-cartridge").ink == .unused)
    }

    @Test func onlyInkAndTonerAreInk() {
        #expect(PrinterSupply(name: "", color: "", type: "toner").isInk)
        #expect(PrinterSupply(name: "", color: "", type: "ink-cartridge").isInk)
        #expect(!PrinterSupply(name: "", color: "", type: "opc").isInk)
    }
}
