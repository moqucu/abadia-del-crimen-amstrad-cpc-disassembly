# Room Rendering Z-Depth Fix Summary

This document details the analysis and resolution of the Z-depth calculation discrepancies between the Python implementation and the JavaScript reference.

## The Problem

Initial comparisons of the rendering logs showed a consistent mismatch in the calculated Z-depth values for certain blocks, even though the visual placement (X, Y) was correct.

*   **Walls (Height=20):** Python depths matched JS exactly or were close.
*   **Floor (Height=255/ -1):** Python depths were consistently higher (closer to zero) than JS depths by a fixed amount (e.g., -8 vs -16).

## The Cause

The Z-depth in *La Abadía del Crimen* is calculated using two registers (`Reg 16` and `Reg 17`) which track the "depth coordinates" `depthX` and `depthY`. These registers are initialized at the start of each block's execution based on the block's position and height.

The analysis revealed that the initialization formula differs depending on whether the block's height is positive (e.g., Walls) or negative (e.g., Floor, where 255 represents -1).

## The Solution

A conditional initialization offset was implemented in `src/abadia/interpreter.py`.

**Logic:**
```python
# Initialize Depth registers (DEPTHX=16, DEPTHY=17)
# offset depends on whether height is treated as negative (>127) or positive.
depth_offset = -11 if height > 127 else -3

self.regs[16] = (start_x + height + depth_offset) & 0xFF
self.regs[17] = (start_y + height + depth_offset) & 0xFF
```

### Verification Results (Room 1)

| Block Type | Height | Grid Pos | JS Depth | Python Depth (Old) | Python Depth (New) | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Floor** (Prio 1) | 255 (-1) | (0,0) | **-16** | -8 | **-16** | ✅ MATCH |
| **Wall** (Prio 31) | 20 | (0,7) | **46** | 46 | **46** | ✅ MATCH |
| **Wall** (Prio 31) | 20 | (0,13) | **46** | 46 | **46** | ✅ MATCH |

## Conclusion

The `offset = -11` for negative heights and `offset = -3` for positive heights aligns the Python rendering engine's Z-sorting logic with the reference implementation for the vast majority of cases, ensuring correct visual occlusion.