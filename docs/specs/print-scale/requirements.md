# Print scale: requirements

Mapsmith prints a map at 1 inch per grid square. It detects the grid; the user
can override the scale when detection is wrong or fails.

## R1 Showing the scale
- R1.1 The inspector's Scale section says where the scale came from: the
  detected grid, the file's own resolution, or nothing found.
- R1.2 It shows the selected map's size in pixels.

## R2 Entering the scale
- R2.1 The user can enter the scale as pixels per square, or as the number of
  1-inch squares across or down the map. Each field shows the detected value
  as its placeholder and, once a scale is entered, the value that scale gives.
- R2.2 What is typed is used once typing pauses (0.6 s) or on Return, so typing
  150 doesn't recalculate the pages at 1 and 15 along the way.
- R2.3 An entry that gives no usable scale (zero, negative, empty squares) is
  ignored. Clearing the field, or Use Detected Scale, goes back to the detected
  scale.
