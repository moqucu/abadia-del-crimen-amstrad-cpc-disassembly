const fs = require('fs');
const { PNG } = require('pngjs');

// --- CONSTANTS ---
const SCREEN_OFFSET_X = 32;
const SCREEN_WIDTH = 320;
const SCREEN_HEIGHT = 200;
const BACKGROUND_COLOR_DAY = { r: 0x00, g: 0x80, b: 0x80 }; // Teal

// Paths
const PATH_ROOMS = 'public/assets/abadia/rooms.json';
const PATH_SCRIPTS = 'public/assets/abadia/scripts.abs';
const PATH_TILES = 'public/assets/gfx/tiles/tiles_day.png';
const OUTPUT_DIR = 'generated_rooms';

const TILE_HACKS = [
    // fix stair in room 38
    { type: 0, roomId: 38, posX: 9, posY: 11, priority: 0, depthX: 21, depthY: 19 }, 
    
    // fix stair in room 8
    { type: 0, roomId:  8, posX: 9, posY: 10, priority: 0, depthX: 19, depthY: 16 }, 
    
    // fix door in room 72
    { type: 0, roomId: 72, posX: 2, posY:  5, priority: 0, depthX: 15, depthY: 20 },
    { type: 0, roomId: 72, posX: 2, posY:  5, priority: 1, depthX: 15, depthY: 20 }, 
    
    // fix portico in mirror room
    { type: 0, roomId: 116, posX: 6, posY:  4, priority: 1, depthX: 19, depthY: 21 }, 
    { type: 0, roomId: 116, posX: 6, posY:  4, priority: 2, depthX: 19, depthY: 21 },
    { type: 0, roomId: 116, posX: 5, posY:  4, priority: 1, depthX: 19, depthY: 21 },
    { type: 0, roomId: 116, posX: 5, posY:  3, priority: 1, depthX: 19, depthY: 21 },
    { type: 0, roomId: 116, posX: 6, posY:  3, priority: 2, depthX: 19, depthY: 21 },
    { type: 0, roomId: 116, posX: 6, posY:  3, priority: 3, depthX: 19, depthY: 21 },
    { type: 0, roomId: 116, posX: 7,posY:  3, priority: 1, depthX: 19, depthY: 21 },
    { type: 0, roomId: 116, posX: 7,posY:  2, priority: 1, depthX: 19, depthY: 21 },
    { type: 0, roomId: 116, posX: 8,posY:  2, priority: 1, depthX: 19, depthY: 21 },
    { type: 0, roomId: 116, posX: 8,posY:  1, priority: 1, depthX: 19, depthY: 21 },
    { type: 0, roomId: 116, posX: 9,posY:  1, priority: 1, depthX: 19, depthY: 21 },
    { type: 0, roomId: 116,posX: 9,posY:  1, priority: 2, depthX: 19, depthY: 21 },
    { type: 0, roomId: 116,posX: 9,posY:  0, priority: 2, depthX: 19, depthY: 21 },
    { type: 0, roomId: 116,posX: 9,posY:  0, priority: 3, depthX: 19, depthY: 21 },

    // fix library in mirror room
    { type: 1, roomId: 116, posX: 1, posY: 0, tile: 172, depthX: 0, depthY: 0 },
    { type: 1, roomId: 116, posX: 1, posY: 1, tile: 171, depthX: 0, depthY: 0 },
    { type: 1, roomId: 116, posX: 0, posY: 1, tile: 172, depthX: 0, depthY: 0 },
    { type: 1, roomId: 116, posX: 0, posY: 2, tile: 171, depthX: 0, depthY: 0 },

    // fix door in room 78
    { type: 0, roomId: 78, posX: 13,posY: 4, priority: 0, depthX: 14, depthY: 10}
];

// --- SCRIPT INTERPRETER CLASS ---
class ScriptInterpreter {
  
  constructor(parsedScripts) {
    this.scripts = parsedScripts;
    this.tileBuffer = this.createEmptyTileBuffer();
  }

  createEmptyTileBuffer() {
    const buffer = [];
    for (let x = 0; x < 16; x++) {
      buffer[x] = [];
      for (let y = 0; y < 20; y++) {
        buffer[x][y] = [];
      }
    }
    return buffer;
  }

  executeBlock(block) {
    this.block = {...block, depthx: 0, depthy: 0};
    this.scriptId = 'SCRIPT' + (block.type >> 1);
    this.line = 0;
    this.flipX = false;
    this.stack = [];
    this.tiles = [];

    this.executeScript(true);
  }

  executeScript(modifyTiles) {
    if (modifyTiles) {
      this.tiles = this.scripts[this.scriptId].tiles;
    }

    if (this.block.height != 0xff) {
      this.block.depthx = (this.block.y + this.block.height / 2) + this.block.x - 15;
      this.block.depthy = (this.block.y + this.block.height / 2) - this.block.x + 16;
    }

    let end = false;
  
    while (!end) {
      if (!this.scripts[this.scriptId] || !this.scripts[this.scriptId].lines[this.line]) {
          // console.error(`Script Error: ${this.scriptId} Line: ${this.line}`);
          end = true;
          break;
      }
      
      const { opcode, params } = this.scripts[this.scriptId].lines[this.line];
      this.line++;
      switch (opcode) {
        case 'JMP':
          this.scriptId = params[0];
          this.line = parseInt(params[1]);
          break;
        case 'LD':
          let res = this.evalExpression(params[1]);
          
          let p = params[0];
          if (this.flipX && (params[0] == "DEPTHX")) p = "DEPTHY";
          if (this.flipX && (params[0] == "DEPTHY")) p = "DEPTHX";

          if ((p == "DEPTHX") && (this.block.depthx == 0)) break;
          if ((p == "DEPTHY") && (this.block.depthy == 0)) break;
          if (p.startsWith("DEPTH") && (res > 100)) res = 0;

          this.block[p.toLowerCase()] = res;
          break;
        case 'ADD':
          const addRes = this.evalExpression(params[1]);
          this.block[params[0].toLowerCase()] += addRes;
          break;
        case 'WHILE':
          this.whileHandler(this.block[params[0].toLowerCase()]);
          break;
        case 'ENDWHILE':
          this.endWhileHandler();
          break;
        case 'PUSH':
          this.stack.push(this.block[params[0].toLowerCase()]);
          break;
        case 'POP':
          this.block[params[0].toLowerCase()] = this.stack.pop();
          break;
        case 'DRAWTILE':
          this.drawTileHandler(params[0]);
          break;
        case 'DEC':
          let decOffset = 1;
          if ((params[0] == 'X') && this.flipX) decOffset = -1;
          this.block[params[0].toLowerCase()] -= decOffset;
          break;
        case 'INC':
          let incOffset = 1;
          if ((params[0] == 'X') && this.flipX) incOffset = -1;
          this.block[params[0].toLowerCase()] += incOffset;
          break;
        case 'END':
          end = true;
          if (modifyTiles) this.flipX = false;
          break;
        case 'CALL':
          this.callHandler(params[0], true);
          break;
        case 'CALLP':
          this.callHandler(params[0], false);
          break;
        case 'FLIP':
          this.flipX = !this.flipX;
          break;
        default:
          throw new Error(`Opcode ${opcode} NOT FOUND`);
      }
    }
  }

  endWhileHandler() {
    let v = this.stack.pop();
    v--;

    if ( v > 0 ) {
      this.scriptId = this.stack.pop();
      this.line = this.stack.pop();
    
      this.stack.push(this.line);
      this.stack.push(this.scriptId);
      this.stack.push(v);
    } else{
      this.stack.pop();
      this.stack.pop();
    }
  }

  whileHandler(v) {
    if (v > 0) {
      this.stack.push(this.line);
      this.stack.push(this.scriptId);
      this.stack.push(v);
    } else {
      let whileDepth = 1;

      while (whileDepth > 0) {
        const opcode = this.scripts[this.scriptId].lines[this.line].opcode;
        
        if (opcode == 'WHILE') whileDepth++;
        if (opcode == 'ENDWHILE') whileDepth--;
        this.line++;
      }
    }
  }

  drawTileHandler(tile) {
    if (tile.startsWith('T')) tile = this.tiles[parseInt(tile.slice(1))];

    const pX = this.block.x - 8;
    const pY = this.block.y - 8;
    if (pX < 0 || pX >= 16) return;
    if (pY < 0 || pY >= 20) return;

    let dx = this.block.depthx;
    let dy = this.block.depthy;

    this.tileBuffer[pX][pY].push({
      tile: Number(tile) + 1,
      depthX: dx,
      depthY: dy
    });

    for (let i = this.tileBuffer[pX][pY].length - 2; i >= 0; i--) {
      const tOld = this.tileBuffer[pX][pY][i];
      const tNew = this.tileBuffer[pX][pY][i+1];
      
      if ((tOld.depthX + tOld.depthY ) > ( tNew.depthX + tNew.depthY)) {
        if (tOld.depthX > tNew.depthX) tOld.depthX = tNew.depthX;
        if (tOld.depthY > tNew.depthY) tOld.depthY = tNew.depthY;
      }
    }
  }

  evalExpression(exp) {
    if (this.flipX) {
      exp = exp.replaceAll('X', 'Z');
      exp = exp.replaceAll('Y', 'X');
      exp = exp.replaceAll('Z', 'Y');
    }

    ['DEPTHX','DEPTHY','PARAM1','PARAM2','HEIGHT'].forEach((r) => {
      exp = exp.replaceAll(r, this.block[r.toLowerCase()]);
    });
    
    return eval(exp);
  }

  callHandler(s, modifyTiles) {
    this.stack.push({...this.block});
    this.stack.push(this.flipX);
    this.stack.push(this.line);
    this.stack.push(this.scriptId);

    this.scriptId = s;
    this.line = 0;
    this.executeScript(modifyTiles);

    this.scriptId = this.stack.pop();
    this.line = this.stack.pop();
    this.flipX = this.stack.pop();
    this.block = this.stack.pop();
  }

  getTileBuffer() {
    return this.tileBuffer;
  }

  clearTileBuffer() {
    this.tileBuffer = this.createEmptyTileBuffer();
  }
}

// --- HELPER FUNCTIONS ---

function parseScripts(scriptFile) {
    const scripts = {}; 
    const scriptText = scriptFile.split(/\n\s*\n/);

    for (let i = 0; i < scriptText.length; i++) {
      const scriptLines = scriptText[i].split('\n');
      if (scriptLines.length === 0 || !scriptLines[0].trim()) continue;

      const id = scriptLines[0].slice(1, -1);
      
      const script = {
        id: id,
        tiles: [],
        lines: []
      }

      for (let j = 1; j < scriptLines.length; j++) {
        const lineContent = scriptLines[j];
        if (!lineContent.trim()) continue;

        const line = lineContent.split(/ (.*)/s);

        if (line[0] == 'TILES') {
          script.tiles = line[1].split(',');
        } else {
          script.lines.push({
            opcode: line[0],
            params: line[1] ? line[1].replaceAll(' ', '').split(',') : []
          })
        }
      }

      scripts[id] = script;
    }

    return scripts;
}

function fixTiles(tileBuffer, roomId, hacks) {
    for (const hack of hacks) {
      if (hack.roomId == roomId) {
        if (hack.type == 0) {
            // Modify existing tile in buffer
            // hack.posX/Y is block coordinate (0-15) ??
            // AbadiaBuilder: roomData[hack.posX][hack.posY][hack.priority]
            // AbadiaBuilder calls interpretRoom, which returns tileBuffer[x][y]
            // So hack.posX is x, hack.posY is y
            if (tileBuffer[hack.posX] && tileBuffer[hack.posX][hack.posY] && tileBuffer[hack.posX][hack.posY][hack.priority]) {
                tileBuffer[hack.posX][hack.posY][hack.priority].depthX = hack.depthX;
                tileBuffer[hack.posX][hack.posY][hack.priority].depthY = hack.depthY;
            }
        } else {
            // Add new tile
             if (tileBuffer[hack.posX] && tileBuffer[hack.posX][hack.posY]) {
                tileBuffer[hack.posX][hack.posY].push({ tile: hack.tile, depthX: hack.depthX, depthY: hack.depthY});
             }
        }
      }
    }
}

// --- MAIN EXECUTION ---

async function main() {
    console.log("Loading data...");

    const rooms = JSON.parse(fs.readFileSync(PATH_ROOMS, 'utf8'));
    const scriptsRaw = fs.readFileSync(PATH_SCRIPTS, 'utf8');

    console.log("Parsing scripts...");
    const parsedScripts = parseScripts(scriptsRaw);

    console.log("Loading tileset...");
    const tilesPng = await new Promise((resolve, reject) => {
        const stream = fs.createReadStream(PATH_TILES)
            .pipe(new PNG())
            .on('parsed', function() {
                resolve(this);
            })
            .on('error', reject);
    });

    const interpreter = new ScriptInterpreter(parsedScripts);

    console.log(`Generating ${rooms.length} rooms...`);

    const debugStream = fs.createWriteStream(`${OUTPUT_DIR}/debug_trace.txt`);

    for (let i = 0; i < rooms.length; i++) {
        const roomId = i + 1;
        const roomData = rooms[i];
        const blocks = roomData.blocks;

        // Skip empty rooms if any
        if (!blocks || blocks.length === 0) {
            // console.log(`Skipping Room ${roomId} (empty)`);
            continue;
        }

        // Reset interpreter buffer
        interpreter.clearTileBuffer();

        // Execute blocks
        try {
            for (let block of blocks) {
                interpreter.executeBlock(block);
            }
        } catch (e) {
            console.error(`Error executing blocks for Room ${roomId}:`, e.message);
            continue;
        }

        const tileBuffer = interpreter.getTileBuffer();
        
        // Apply Hacks
        fixTiles(tileBuffer, roomId, TILE_HACKS);

        // Render
        const output = new PNG({ width: SCREEN_WIDTH, height: SCREEN_HEIGHT });

        // Fill background
        for (let y = 0; y < output.height; y++) {
            for (let x = 0; x < output.width; x++) {
                const idx = (output.width * y + x) << 2;
                output.data[idx] = BACKGROUND_COLOR_DAY.r;
                output.data[idx+1] = BACKGROUND_COLOR_DAY.g;
                output.data[idx+2] = BACKGROUND_COLOR_DAY.b;
                output.data[idx+3] = 255;
            }
        }

        let drawList = [];

        for (let x = 0; x < 16; x++) {
            for (let y = 0; y < 20; y++) {
                const cellTiles = tileBuffer[x][y];
                
                cellTiles.forEach((t, index) => {
                    const depth = t.depthX + t.depthY - 16;
                    const screenX = SCREEN_OFFSET_X + x * 16;
                    const screenY = y * 8;
                    
                    drawList.push({
                        tileId: t.tile,
                        gridX: x,
                        gridY: y,
                        screenX,
                        screenY,
                        depth,
                        priority: index
                    });
                });
            }
        }

        drawList.sort((a, b) => {
            if (a.depth !== b.depth) return a.depth - b.depth;
            return a.priority - b.priority;
        });

        debugStream.write(`Room ${roomId}:\n`);
        
        for (const sprite of drawList) {
            const tileIdx = sprite.tileId;
            
            debugStream.write(`  Tile: ${tileIdx.toString().padEnd(3)} | Grid: (${sprite.gridX.toString().padStart(2)}, ${sprite.gridY.toString().padStart(2)}) | Screen: (${sprite.screenX.toString().padStart(3)}, ${sprite.screenY.toString().padStart(3)}) | Depth: ${sprite.depth.toString().padStart(3)} | Prio: ${sprite.priority}\n`);

            // Fix: Subtract 1 because tileId is 1-based
            const srcX = ((tileIdx - 1) % 16) * 16;
            const srcY = Math.floor((tileIdx - 1) / 16) * 8;
            
            for (let py = 0; py < 8; py++) {
                for (let px = 0; px < 16; px++) {
                    const srcIdx = (tilesPng.width * (srcY + py) + (srcX + px)) << 2;
                    const destX = sprite.screenX + px;
                    const destY = sprite.screenY + py;
                    
                    if (destX < 0 || destX >= SCREEN_WIDTH || destY < 0 || destY >= SCREEN_HEIGHT) continue;

                    const destIdx = (output.width * destY + destX) << 2;
                    const alpha = tilesPng.data[srcIdx + 3];

                    if (alpha > 0) {
                        output.data[destIdx] = tilesPng.data[srcIdx];
                        output.data[destIdx+1] = tilesPng.data[srcIdx+1];
                        output.data[destIdx+2] = tilesPng.data[srcIdx+2];
                        output.data[destIdx+3] = alpha;
                    }
                }
            }
        }

        const fileName = `${roomId}_room.png`;
        const filePath = `${OUTPUT_DIR}/${fileName}`;
        output.pack().pipe(fs.createWriteStream(filePath));
        process.stdout.write(`\rGenerated Room ${roomId}`);
    }
    
    debugStream.end();
    console.log("\nAll rooms generated.");
}

main().catch(err => console.error(err));