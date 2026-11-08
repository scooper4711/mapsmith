# Ink cost: requirements

Mapsmith tells the user roughly what printing a map costs in ink, so they can
weigh printing a large map at home against other options. It is an estimate
worked out from the map and the ink's rated yield. Mapsmith doesn't measure the
ink the printer actually uses: the levels printers report are too coarse for a
single map, and they also drop for everything else the user prints.

## R1 Ink prices
- R1.1 In Mapsmith's Settings (⌘,), the user enters, for each printer, what a
  complete set of its ink costs and how many pages each cartridge is rated
  for. The rated yield is on the cartridge's box and on the maker's product
  page, measured to ISO/IEC 24711 at 5% coverage of an A4 page.
- R1.2 Mapsmith lists the printer's cartridges by name (for example Cyan,
  Magenta, Yellow, Black(PGBK)) when the printer reports them, and otherwise
  offers cyan, magenta, yellow and black.
- R1.3 Each cartridge is set to the ink it supplies for a map: cyan, magenta,
  yellow, black, or not used for maps. When a printer has several black
  cartridges, only one is charged for a map's black; on Canon printers the
  default is the pigment black (PGBK), which prints black on plain paper.
- R1.4 The price is a plain amount in the user's currency, shown with the
  currency of the user's region (868 kr, $59.99).
- R1.5 Prices are kept for each printer separately and are remembered after
  Mapsmith is relaunched.

## R2 Estimate
- R2.1 With ink prices set for the selected printer, the inspector's Result
  section shows the estimated ink cost of the whole map and of one page, for
  example "Ink: about 42 kr (5.20 kr a page)".
- R2.2 The estimate updates when the map, the scale, the page setup or the
  printer changes, without holding up the rest of the inspector.
- R2.3 A note says that it is an estimate from the ink's rated yield, and that
  printers also use ink for cleaning.
- R2.4 Without both a price and the rated yields for the selected printer,
  Mapsmith shows no estimate and says nothing about ink.

## R3 How the estimate is worked out
- R3.1 The ink a page needs is the share of the paper that each ink covers
  when the printed tile is separated into cyan, magenta, yellow and black.
  White paper costs nothing.
- R3.2 A cartridge's cost for a page is its share of the set's price, times the
  page's coverage of its ink divided by 5%, divided by its rated yield. The
  set's price is shared equally among all its cartridges, including those not
  used for maps: the set buys them all, so a cartridge's worth doesn't depend
  on whether maps use it.
- R3.3 The map's cost is the sum over its pages and cartridges.
