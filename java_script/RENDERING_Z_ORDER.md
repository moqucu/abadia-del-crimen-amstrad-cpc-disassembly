# Abadía del Crimen: Z-Order & Depth Logic

This reference document explains the "Painter's Algorithm" and depth correction logic used to correctly render the isometric building blocks.

## 1. The Depth Formula

The engine calculates a single `depth` value for every tile. This value determines the draw order. The coordinates `depthX` and `depthY` are derived from the block's `x`, `y`, and `height` parameters.

```javascript
// Global depth calculation for a single tile
const depth = tile.depthX + tile.depthY - 16;
```

## 2. In-Cell Depth Correction

This is the most critical and often missed part. When a script draws multiple tiles into the same $16 \times 8$ grid cell, the engine performs a "clamping" correction. If a tile that was drawn *earlier* is mathematically *closer* to the camera than a tile drawn *later* in the same cell, the engine pushes the earlier tile back.

**Logic (from ScriptInterpreter.js):**
```javascript
// This runs every time a DRAWTILE command is executed
function onDrawTile(newTile, cellBuffer) {
    cellBuffer.push(newTile);

    // Iterate backwards through the tiles already in this specific grid cell
    for (let i = cellBuffer.length - 2; i >= 0; i--) {
        const tOld = cellBuffer[i];
        const tNew = cellBuffer[i + 1];
        
        // If the 'older' tile is mathematically "closer" than the 'new' one
        if ((tOld.depthX + tOld.depthY) > (tNew.depthX + tNew.depthY)) {
            // Clamp the older tile's depth coordinates to match the new one
            if (tOld.depthX > tNew.depthX) tOld.depthX = tNew.depthX;
            if (tOld.depthY > tNew.depthY) tOld.depthY = tNew.depthY;
        }
    }
}
```

## 3. The Global Painter's Algorithm

Once all blocks are interpreted, the resulting tiles are flattened into a single list and sorted using two criteria:
1.  **Primary Sort**: Absolute `depth`.
2.  **Secondary Sort**: `priority` (The order the tile was generated within its specific cell).

**Logic (from AbadiaBuilder.js):**
```javascript
// 1. Flatten the 16x20 buffer into a draw list
let drawList = [];
for (let x = 0; x < 16; x++) {
    for (let y = 0; y < 20; y++) {
        const tilesInCell = tileBuffer[x][y];
        tilesInCell.forEach((tile, index) => {
            drawList.push({
                tileId: tile.tile,
                depth: tile.depthX + tile.depthY - 16,
                priority: index // The index in the cell array
            });
        });
    }
}

// 2. Perform the final sort
drawList.sort((a, b) => {
    // Rule 1: Lower depth (further away) draws first
    if (a.depth !== b.depth) {
        return a.depth - b.depth;
    }
    // Rule 2: If depth is identical, use the original drawing order
    return a.priority - b.priority;
});
```

## 4. The "H=255" Special Case (Floor Blocks)
When a block has `height = 255` (0xFF), the JavaScript engine uses a specific shortcut that results in a constant depth of `-16`.

1.  **Skip Initialization**: If `H == 255`, the initial `depthX` and `depthY` are set to `0` instead of using the coordinate formula.
2.  **The LD Guard**: In the interpreter, the `LD` instruction for depth registers has a guard:
    ```javascript
    if ((target == "DEPTHX") && (current_depthX == 0)) return; // Skip update
    if ((target == "DEPTHY") && (current_depthY == 0)) return; // Skip update
    ```
3.  **Constant Depth**: Since floor scripts (like SCRIPT113) start with `LD DEPTHX...`, they are immediately skipped. The registers stay `0` throughout, resulting in:
    `0 (depthX) + 0 (depthY) - 16 = -16`

## 5. Summary for Implementation

- **Step 1**: Calculate `depthX` and `depthY` during script interpretation.
- **Step 2**: Apply the **In-Cell Correction** every time a tile is added to a grid cell.
- **Step 3**: Collect all tiles and sort them by `(depthX + depthY - 16)`.
- **Step 4**: Use the original creation order as the tie-breaker for the sort.
- **Step 5**: Render from the start of the sorted list to the end.

```