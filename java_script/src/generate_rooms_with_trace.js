const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

// --- CONSTANTS ---
const SCREEN_OFFSET_X = 32;
const SCREEN_WIDTH = 320;
const SCREEN_HEIGHT = 200;
const BACKGROUND_COLOR_DAY = { r: 0x00, g: 0x80, b: 0x80 }; // Teal

// Paths - Assets from ~/GitHub/abadia repo, output to local resources
const ABADIA_REPO = path.join(process.env.HOME, 'GitHub', 'abadia');
const PATH_ROOMS = path.join(ABADIA_REPO, 'public/assets/abadia/rooms.json');
const PATH_FLOORS = path.join(ABADIA_REPO, 'public/assets/abadia/floors.json');
const PATH_SCRIPTS = path.join(ABADIA_REPO, 'public/assets/abadia/scripts.abs');
const PATH_TILES = path.join(ABADIA_REPO, 'public/assets/gfx/tiles/tiles_day.png');
const OUTPUT_DIR = path.join(__dirname, '..', 'resources', 'generated_rooms');

// --- TILE HACKS ---
const TILE_HACKS = [
    { type: 0, roomId: 38, posX: 9, posY: 11, priority: 0, depthX: 21, depthY: 19 }, 
    { type: 0, roomId:  8, posX: 9, posY: 10, priority: 0, depthX: 19, depthY: 16 }, 
    { type: 0, roomId: 72, posX: 2, posY:  5, priority: 0, depthX: 15, depthY: 20 },
    { type: 0, roomId: 72, posX: 2, posY:  5, priority: 1, depthX: 15, depthY: 20 }, 
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
    { type: 0, roomId: 116, posX: 9,posY:  1, priority: 2, depthX: 19, depthY: 21 }, 
    { type: 0, roomId: 116,posX: 9,posY:  0, priority: 2, depthX: 19, depthY: 21 },
    { type: 0, roomId: 116,posX: 9,posY:  0, priority: 3, depthX: 19, depthY: 21 }, 
    { type: 1, roomId: 116, posX: 1, posY: 0, tile: 172, depthX: 0, depthY: 0 },
    { type: 1, roomId: 116, posX: 1, posY: 1, tile: 171, depthX: 0, depthY: 0 }, 
    { type: 1, roomId: 116, posX: 0, posY: 1, tile: 172, depthX: 0, depthY: 0 },
    { type: 1, roomId: 116, posX: 0, posY: 2, tile: 171, depthX: 0, depthY: 0 }, 
    { type: 0, roomId: 78, posX: 13,posY: 4, priority: 0, depthX: 14, depthY: 10}
];

// --- SCRIPT INTERPRETER CLASS ---
class ScriptInterpreter {
  
  constructor(parsedScripts) {
    this.scripts = parsedScripts;
    this.tileBuffer = this.createEmptyTileBuffer();
    this.drawEvents = []; // Section 2 Log
    this.currentPrio = 0;
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

  executeBlock(block, prio) {
    this.block = {...block, depthx: 0, depthy: 0};
    this.scriptId = 'SCRIPT' + (block.type >> 1);
    this.line = 0;
    this.flipX = false;
    this.stack = [];
    this.tiles = [];
    this.currentPrio = prio;

    this.executeScript(true);
  }

  executeScript(modifyTiles) {
    if (modifyTiles) {
      if (!this.scripts[this.scriptId]) return;
      this.tiles = this.scripts[this.scriptId].tiles;
    }

    if (this.block.height != 0xff) {
      this.block.depthx = (this.block.y + this.block.height / 2) + this.block.x - 15;
      this.block.depthy = (this.block.y + this.block.height / 2) - this.block.x + 16;
    }

    let end = false;
    let loopGuard = 0;
  
    while (!end && loopGuard < 10000) {
      loopGuard++;
      if (!this.scripts[this.scriptId] || !this.scripts[this.scriptId].lines[this.line]) {
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
          else if (this.flipX && (params[0] == "DEPTHY")) p = "DEPTHX";
          
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
        if (!this.scripts[this.scriptId] || !this.scripts[this.scriptId].lines[this.line]) break;
        const opcode = this.scripts[this.scriptId].lines[this.line].opcode;
        if (opcode == 'WHILE') whileDepth++;
        if (opcode == 'ENDWHILE') whileDepth--;
        this.line++;
      }
    }
  }

  drawTileHandler(tile) {
    let tileId;
    if (tile.startsWith('T')) {
        tileId = this.tiles[parseInt(tile.slice(1))];
    } else {
        tileId = tile;
    }

    const pX = this.block.x - 8;
    const pY = this.block.y - 8;
    let dx = this.block.depthx;
    let dy = this.block.depthy;

    // SECTION 2 LOGGING
    // Event: Block #{PRIO:02d} -> DrawTile({TILE_ID}) @ ({X},{Y}) | RawRegs: ({RAW_DX}, {RAW_DY})
    this.drawEvents.push(
        `  Event: Block #${this.currentPrio.toString().padStart(2, '0')} -> DrawTile(${tileId}) @ (${this.block.x},${this.block.y}) | RawRegs: (${dx}, ${dy})`
    );

    if (pX >= 0 && pX < 16 && pY >= 0 && pY < 20) {
        this.tileBuffer[pX][pY].push({
            tile: Number(tileId) + 1,
            depthX: dx,
            depthY: dy,
            prio: this.currentPrio
        });

        // In-Cell Depth Correction
        for (let i = this.tileBuffer[pX][pY].length - 2; i >= 0; i--) {
            const tOld = this.tileBuffer[pX][pY][i];
            const tNew = this.tileBuffer[pX][pY][i+1];
            if ((tOld.depthX + tOld.depthY ) > ( tNew.depthX + tNew.depthY)) {
                if (tOld.depthX > tNew.depthX) tOld.depthX = tNew.depthX;
                if (tOld.depthY > tNew.depthY) tOld.depthY = tNew.depthY;
            }
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
    try { return eval(exp); } catch(e) { return 0; }
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

  getDrawEvents() {
    return this.drawEvents;
  }

  clearAll() {
    this.tileBuffer = this.createEmptyTileBuffer();
    this.drawEvents = [];
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
      const script = { id: id, tiles: [], lines: [] }
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
            if (tileBuffer[hack.posX] && tileBuffer[hack.posX][hack.posY] && tileBuffer[hack.posX][hack.posY][hack.priority]) {
                tileBuffer[hack.posX][hack.posY][hack.priority].depthX = hack.depthX;
                tileBuffer[hack.posX][hack.posY][hack.priority].depthY = hack.depthY;
            }
        } else {
             if (tileBuffer[hack.posX] && tileBuffer[hack.posX][hack.posY]) {
                // Hack tiles always appended with logic of AbadiaBuilder
                tileBuffer[hack.posX][hack.posY].push({ tile: hack.tile, depthX: hack.depthX, depthY: hack.depthY, prio: 99}); 
             }
        }
      }
    }
}

// --- MAIN EXECUTION ---

async function main() {
    const rooms = JSON.parse(fs.readFileSync(PATH_ROOMS, 'utf8'));
    const scriptsRaw = fs.readFileSync(PATH_SCRIPTS, 'utf8');
    const parsedScripts = parseScripts(scriptsRaw);

    const tilesPng = await new Promise((resolve, reject) => {
        const stream = fs.createReadStream(PATH_TILES)
            .pipe(new PNG())
            .on('parsed', function() { resolve(this); })
            .on('error', reject);
    });

    const interpreter = new ScriptInterpreter(parsedScripts);

    if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR);

    for (let i = 0; i < rooms.length; i++) {
        const roomId = i + 1; // JS_ID
        const pythonId = i;   // PYTHON_ID
        const roomData = rooms[i];
        const blocks = roomData.blocks || [];
        const palette = "day";

        interpreter.clearAll();

        // 1. EXECUTE BLOCKS (Generate Section 1 & 2 data)
        let blockManifest = [];
        const uniqueBlocks = new Set();
        let renderedCount = 0;

        for (let bIdx = 0; bIdx < blocks.length; bIdx++) {
            const block = blocks[bIdx];
            const rawBlockId = '0x' + (block.type).toString(16).padStart(2, '0').toUpperCase();
            uniqueBlocks.add(rawBlockId);
            
            try {
                interpreter.executeBlock(block, bIdx);
                blockManifest.push(`  Block #${bIdx.toString().padStart(2, '0')}: ID ${rawBlockId} | Pos: (${block.x},${block.y}) | Size: (${block.param1},${block.param2}) | H: ${block.height} [OK]`);
                renderedCount++;
            } catch (e) {
                blockManifest.push(`  Block #${bIdx.toString().padStart(2, '0')}: ID ${rawBlockId} | Pos: (${block.x},${block.y}) | Size: (${block.param1},${block.param2}) | H: ${block.height} [ERROR: ${e.message}]`);
            }
        }

        const tileBuffer = interpreter.getTileBuffer();
        fixTiles(tileBuffer, roomId, TILE_HACKS);

        // 2. FLATTEN & SORT (Generate Section 3 data)
        let renderList = [];
        
        for (let x = 0; x < 16; x++) {
            for (let y = 0; y < 20; y++) {
                const cellTiles = tileBuffer[x][y];
                cellTiles.forEach((t, index) => {
                    renderList.push({
                        tileId: t.tile - 1, // Store 0-based for log/render
                        depthX: t.depthX,
                        depthY: t.depthY,
                        depth: t.depthX + t.depthY - 16,
                        scrX: x * 16 + 32,
                        scrY: y * 8,
                        prio: t.prio
                    });
                });
            }
        }

        renderList.sort((a, b) => {
            if (a.depth !== b.depth) return a.depth - b.depth;
            return a.prio - b.prio;
        });

        // 3. WRITE LOG FILE
        const logContent = [];
        
        // Header
        logContent.push(`Room Index: ${pythonId} (JS ID: ${roomId}) - Palette: ${palette}`);
        logContent.push(`================================================================================`);
        
        // Section 1: Block Manifest
        logContent.push(`SECTION 1: BLOCK MANIFEST`);
        logContent.push(`Summary: ${renderedCount} rendered, 0 skipped`);
        const sortedUnique = Array.from(uniqueBlocks).sort();
        logContent.push(`Unique Block Types: ${sortedUnique.join(', ')}`);
        logContent.push(`--------------------------------------------------------------------------------`);
        logContent.push(...blockManifest);
        logContent.push(`--------------------------------------------------------------------------------`);

        // Section 2: Chronological Draw Events
        logContent.push(`SECTION 2: CHRONOLOGICAL DRAW EVENTS (Interpreter Output)`);
        logContent.push(...interpreter.getDrawEvents());
        logContent.push(`--------------------------------------------------------------------------------`);

        // Section 3: Final Render List
        logContent.push(`SECTION 3: FINAL RENDER LIST (Graphics Output)`);
        
        const finalRenderLines = renderList.map((t, idx) => {
            // Order #{IDX:03d} | Depth: {DEPTH:>3} | Prio: {PRIO:02d} | Tile: {TILE_ID:<3} | Screen: (${scrX}, ${scrY})
            const idxStr = idx.toString().padStart(3, '0');
            const depthStr = t.depth.toString().padStart(3);
            const prioStr = t.prio.toString().padStart(2, '0');
            const tileStr = t.tileId.toString().padEnd(3);
            return `  Order #${idxStr} | Depth: ${depthStr} | Prio: ${prioStr} | Tile: ${tileStr} | Screen: (${t.scrX}, ${t.scrY})`;
        });
        
        logContent.push(...finalRenderLines);
        
        const logPath = `${OUTPUT_DIR}/room_${roomId}_day.log`;
        fs.writeFileSync(logPath, logContent.join('\n') + '\n');

        // 4. RENDER PNG
        const output = new PNG({ width: SCREEN_WIDTH, height: SCREEN_HEIGHT });
        for (let y = 0; y < output.height; y++) {
            for (let x = 0; x < output.width; x++) {
                const idx = (output.width * y + x) << 2;
                output.data[idx] = BACKGROUND_COLOR_DAY.r;
                output.data[idx+1] = BACKGROUND_COLOR_DAY.g;
                output.data[idx+2] = BACKGROUND_COLOR_DAY.b;
                output.data[idx+3] = 255;
            }
        }

        for (const sprite of renderList) {
            const tileIdx = sprite.tileId + 1; // back to 1-based for png source calc
            const srcX = ((tileIdx - 1) % 16) * 16;
            const srcY = Math.floor((tileIdx - 1) / 16) * 8;
            for (let py = 0; py < 8; py++) {
                for (let px = 0; px < 16; px++) {
                    const srcIdx = (tilesPng.width * (srcY + py) + (srcX + px)) << 2;
                    const destX = sprite.scrX + px;
                    const destY = sprite.scrY + py;
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

        const pngPath = `${OUTPUT_DIR}/room_${roomId}_day.png`;
        output.pack().pipe(fs.createWriteStream(pngPath));
        process.stdout.write(`\rGenerated Room ${roomId} spec logs...`);
    }
    console.log("\nDone.");
}

main().catch(err => console.error(err));