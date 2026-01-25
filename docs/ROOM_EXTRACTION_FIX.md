# Room Extraction Fix

**Date:** January 24, 2026

## Issue Description
The `extract_rooms.py` script was previously extracting only 33 rooms (0-32), whereas the game contains 115+ rooms. The process terminated prematurely.

## Analysis
The extraction logic relied on the `length` byte (the first byte of the room data) to determine the size of the room definition.
The script included a "safety check":
```python
if room.length == 0:
    break
```
It was discovered that **Room 32** has a `length` byte of `0x00`. However, the room actually contains valid block definitions ending with the `0xFF` terminator. The zero length byte is either ignored by the original game engine or has a special meaning not previously understood (possibly "unknown length" or just incorrect data).

Because of the safety check, the extractor stopped at Room 32. Additionally, the logic for calculating the start of the next room was:
```python
offset = room.file_offset + room.length + 1
```
For a room with `length=0`, this would incorrectly set the next room's offset to the start of the current room's data block, causing parsing errors or loops if the check wasn't there.

## Fix Implementation
The `src/abadia/extract_rooms.py` script was modified to:

1.  **Ignore the explicit Length byte for traversal.** The parsing logic now relies entirely on finding the `0xFF` terminator to determine the end of a room.
2.  **Return the actual end offset.** `parse_room` now returns the offset immediately following the `0xFF` terminator.
3.  **Remove the premature break.** The `if room.length == 0: break` check was removed.
4.  **Use the actual parsed size.** The main loop now uses the offset returned by `parse_room` to locate the start of the next room.

## Results
The script now successfully extracts **115 rooms** (indices 0 to 114) from `abadia8.bin`.
Validation confirmed that high-numbered rooms (e.g., Room 100) can now be parsed and rendered.
