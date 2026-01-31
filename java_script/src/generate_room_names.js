const fs = require('fs');
const path = require('path');

// Paths - Assets from ~/GitHub/abadia repo, output to local resources
const ABADIA_REPO = path.join(process.env.HOME, 'GitHub', 'abadia');
const PATH_ROOMS = path.join(ABADIA_REPO, 'public/assets/abadia/rooms.json');
const PATH_FLOORS = path.join(ABADIA_REPO, 'public/assets/abadia/floors.json');
const OUTPUT_FILE = path.join(__dirname, '..', 'ROOM_NAMES.md');

const SPECIAL_ROOMS = {
    115: "Mirror Room (Close)",
    116: "Mirror Room (Open)",
    8: "Staircase to Library",
    38: "Staircase to Hospital",
    72: "Abbot's Quarters Entrance",
    78: "Library Entrance",
    77: "Refectory (Bench)",
};

// Heuristics derived from code/comments
// AbadiaBuilder.js DOOR_CONNECTIONS (Floor 0)
// [ { x: 5, y:  3, v: 1}, { x: 6, y:  3, v: 4 } ], // abad cell
// [ { x: 11, y: 1, v: 8}, { x: 11, y: 2, v: 2 } ], // monks cell
// [ { x: 6, y:  5, v: 8}, { x: 6, y:  6, v: 2 } ], // severino cell
// [ { x: 9, y:  2, v: 1}, { x: 10, y: 2, v: 4 } ], // chruch - cells
// [ { x: 7, y:  2, v: 1}, { x: 8, y:  2, v: 4 } ], // passage
// [ { x: 5, y:  7, v: 1}, { x: 6, y:  7, v: 4 } ]  // big door

const LOCATION_HINTS = {
    "0,5,3": "Abbot's Cell",
    "0,6,3": "Abbot's Antechamber",
    "0,11,1": "Monk's Cell (North)",
    "0,11,2": "Monk's Cell (South)",
    "0,6,5": "Severino's Herbal Store",
    "0,6,6": "Severino's Cell",
    "0,9,2": "Church Transept (Left)",
    "0,10,2": "Church Transept (Right)",
    "0,7,2": "Passage to Cloister",
    "0,8,2": "Passage",
    "0,5,7": "Main Entrance (Left)",
    "0,6,7": "Main Entrance (Right)"
};

function main() {
    const rooms = JSON.parse(fs.readFileSync(PATH_ROOMS, 'utf8'));
    const floors = JSON.parse(fs.readFileSync(PATH_FLOORS, 'utf8'));

    const roomMap = new Map(); // ID -> { floor, x, y }

    // Map Room IDs to coordinates
    floors.forEach((floorObj, floorIndex) => {
        const grid = floorObj.room;
        for (let y = 0; y < grid.length; y++) {
            for (let x = 0; x < grid[y].length; x++) {
                const roomId = grid[y][x];
                if (roomId > 0) {
                    if (!roomMap.has(roomId)) {
                        roomMap.set(roomId, []);
                    }
                    roomMap.get(roomId).push({ floor: floorIndex, x, y });
                }
            }
        }
    });

    let output = "# Abadía del Crimen - Room Directory\n\n";
    output += "| Room ID | Location (Floor, X, Y) | Suggested Name | Notes |\n";
    output += "|---|---|---|---|";

    for (let i = 0; i < rooms.length; i++) {
        const roomId = i + 1;
        const roomData = rooms[i];
        const locations = roomMap.get(roomId);

        let locationStr = "Unknown";
        let floor = -1;
        let rx = -1; 
        let ry = -1;

        if (locations && locations.length > 0) {
            locationStr = locations.map(l => `[${l.floor}] ${l.x},${l.y}`).join('; ');
            floor = locations[0].floor;
            rx = locations[0].x;
            ry = locations[0].y;
        }

        let name = "Chamber";
        let note = "";

        // 1. Check Special Rooms
        if (SPECIAL_ROOMS[roomId]) {
            name = SPECIAL_ROOMS[roomId];
            note = "Special ID";
        }
        // 2. Check Location Hints
        else if (locations) {
            for (const loc of locations) {
                const key = `${loc.floor},${loc.x},${loc.y}`;
                if (LOCATION_HINTS[key]) {
                    name = LOCATION_HINTS[key];
                    note = "Location Hint";
                    break;
                }
            }
        }

        // 3. Inference based on floor/position if still generic
        if (name === "Chamber" && floor !== -1) {
            if (floor === 0) {
                // Main Floor
                if (ry >= 10) name = "Church Nave";
                else if (ry < 4 && rx > 10) name = "Monk's Dormitory";
                else if (rx < 6 && ry < 8) name = "Hospital Wing";
                else if (rx > 5 && rx < 10 && ry > 3 && ry < 8) name = "Cloister Walkway";
                else name = "Main Floor Hall";
            } else if (floor === 1) {
                // Library Floor
                name = "Library Section";
                if (roomId === 78) name = "Scriptorium Entrance"; // Override
            } else if (floor === 2) {
                name = "Labyrinth";
            }
        }

        // 4. Block Analysis for Flavor
        const blockCount = roomData.blocks ? roomData.blocks.length : 0;
        if (name.includes("Chamber") || name.includes("Hall") || name.includes("Section")) {
             if (blockCount > 20) name += " (Complex)";
             else if (blockCount < 5) name += " (Empty)";
        }
        
        output += `| **${roomId}** | ${locationStr} | **${name}** | ${note} (Blocks: ${blockCount}) |\n`;
    }

    fs.writeFileSync(OUTPUT_FILE, output);
    console.log(`Generated ${OUTPUT_FILE}`);
}

main();
