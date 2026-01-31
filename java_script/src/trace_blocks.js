const fs = require('fs');
const { PNG } = require('pngjs');

// --- CONSTANTS ---
const PATH_ROOMS = 'public/assets/abadia/rooms.json';
const PATH_SCRIPTS = 'public/assets/abadia/scripts.abs';
const PATH_TILES = 'public/assets/gfx/tiles/tiles_day.png';
const OUTPUT_DIR = 'generated_blocks';
const SCREEN_WIDTH = 320;
const SCREEN_HEIGHT = 200;
const SCREEN_OFFSET_X = 32;

// --- SCRIPT INTERPRETER CLASS WITH TRACING ---
class TraceInterpreter {
  
  constructor(parsedScripts, logStream) {
    this.scripts = parsedScripts;
    this.logStream = logStream; // This will be set per block
    this.tileBuffer = this.createEmptyTileBuffer();
  }

  setLogStream(stream) {
    this.logStream = stream;
  }

  log(msg) {
    if (this.logStream) this.logStream.write(msg + '\n');
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

  clearTileBuffer() {
    this.tileBuffer = this.createEmptyTileBuffer();
  }

  executeBlock(block, roomId, scriptIdNum) {
    this.block = {...block, depthx: 0, depthy: 0};
    this.scriptId = 'SCRIPT' + scriptIdNum;
    this.line = 0;
    this.flipX = false;
    this.stack = [];
    this.tiles = [];

    // --- LOG HEADER ---
    this.log(`BLOCK TRACE: #${scriptIdNum}`);
    this.log(`SOURCE ROOM: ${roomId}`);
    this.log(`BLOCK PARAMS: x=${block.x}, y=${block.y}, h=${block.height}, p1=${block.param1}, p2=${block.param2}, type=${block.type}`);
    this.log(`\n--- ORIGINAL SCRIPT (${this.scriptId}) ---
`);
    if (this.scripts[this.scriptId]) {
        this.log(this.scripts[this.scriptId].rawSource.join('\n'));
    } else {
        this.log("Script definition not found.");
    }
    this.log(`-------------------------------\n`);
    this.log(`[EXECUTION LOG]`);

    this.executeScript(true);
  }

  executeScript(modifyTiles) {
    if (modifyTiles) {
      if (!this.scripts[this.scriptId]) {
          this.log(`ERROR: Script ${this.scriptId} not found.`);
          return;
      }
      this.tiles = this.scripts[this.scriptId].tiles;
    }

    if (this.block.height != 0xff) {
      this.block.depthx = (this.block.y + this.block.height / 2) + this.block.x - 15;
      this.block.depthy = (this.block.y + this.block.height / 2) - this.block.x + 16;
    }

    let end = false;
    let steps = 0;
    const MAX_STEPS = 5000;

    while (!end && steps < MAX_STEPS) {
      steps++;
      if (!this.scripts[this.scriptId] || !this.scripts[this.scriptId].lines[this.line]) {
          end = true;
          break;
      }
      
      const instruction = this.scripts[this.scriptId].lines[this.line];
      const { opcode, params } = instruction;
      
      this.log(`[${this.scriptId}:${this.line.toString().padStart(3)}] ${opcode} ${params.join(',')}`);

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

          let skip = false;
          if ((p == "DEPTHX") && (this.block.depthx == 0)) skip = true;
          if ((p == "DEPTHY") && (this.block.depthy == 0)) skip = true;
          
          if (!skip) {
            if (p.startsWith("DEPTH") && (res > 100)) res = 0;
            this.block[p.toLowerCase()] = res;
            this.log(`  -> Set ${p.toLowerCase()} = ${res}`);
          }
          break;
        case 'ADD':
          const addRes = this.evalExpression(params[1]);
          const target = params[0].toLowerCase();
          this.block[target] += addRes;
          this.log(`  -> ADD ${target} now ${this.block[target]}`);
          break;
        case 'WHILE':
          const val = this.block[params[0].toLowerCase()];
          this.whileHandler(val);
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
          this.log(`  -> UNKNOWN OPCODE ${opcode}`);
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
    let tileId = tile;
    if (tile.startsWith('T')) {
        const idx = parseInt(tile.slice(1));
        tileId = this.tiles[idx];
    }
    
    // Logic from original ScriptInterpreter.js
    const pX = this.block.x - 8;
    const pY = this.block.y - 8;
    if (pX < 0 || pX >= 16) return;
    if (pY < 0 || pY >= 20) return;

    let dx = this.block.depthx;
    let dy = this.block.depthy;

    this.log(`  -> DRAWTILE ID ${tileId} @ (${pX}, ${pY}) Depth(${dx}, ${dy})`);

    this.tileBuffer[pX][pY].push({
      tile: Number(tileId) + 1, // original code does +1
      depthX: dx,
      depthY: dy
    });

    // Depth correction logic from original
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
    
    try {
        return eval(exp);
    } catch (e) {
        return 0;
    }
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
}

function parseScripts(scriptFile) {
    const scripts = {}; 
    const scriptText = scriptFile.split(/\n\s*\n/);
    for (let i = 0; i < scriptText.length; i++) {
      const scriptLines = scriptText[i].split('\n');
      if (scriptLines.length === 0 || !scriptLines[0].trim()) continue;
      const id = scriptLines[0].slice(1, -1);
      const script = { id: id, tiles: [], lines: [], rawSource: [] } 
      
      script.rawSource = scriptLines; // Store original lines

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

    const interpreter = new TraceInterpreter(parsedScripts, null);

    // Group blocks by SCRIPT ID (block.type >> 1)
    const blocksByScriptId = new Map();

    rooms.forEach((room) => {
        if (!room.blocks) return;
        room.blocks.forEach(block => {
            const scriptIdNum = block.type >> 1;
            // Only keep the first occurrence of each script ID
            if (!blocksByScriptId.has(scriptIdNum)) {
                blocksByScriptId.set(scriptIdNum, {
                    roomId: room.id,
                    block: block,
                    scriptIdNum: scriptIdNum
                });
            }
        });
    });

    // Convert map to array and sort
    const blocksToTrace = Array.from(blocksByScriptId.values())
        .sort((a, b) => a.scriptIdNum - b.scriptIdNum);

    console.log(`Processing ${blocksToTrace.length} unique block scripts...`);

    for (const item of blocksToTrace) {
        interpreter.clearTileBuffer();
        
        // Setup individual log file
        const logFileName = `${OUTPUT_DIR}/block_${item.scriptIdNum}.log`;
        const logStream = fs.createWriteStream(logFileName);
        interpreter.setLogStream(logStream);

        interpreter.executeBlock(item.block, item.roomId, item.scriptIdNum);
        
        logStream.end();

        const tileBuffer = interpreter.tileBuffer;
        
        // Render
        const output = new PNG({ width: SCREEN_WIDTH, height: SCREEN_HEIGHT });
        // Transparent BG
        for (let i=0; i<output.data.length; i++) output.data[i] = 0;

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

        for (const sprite of drawList) {
            const tileIdx = sprite.tileId;
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

        const fileName = `${OUTPUT_DIR}/block_${item.scriptIdNum}.png`;
        output.pack().pipe(fs.createWriteStream(fileName));
    }

    console.log(`Done. Generated ${blocksToTrace.length} blocks (images and logs) in ${OUTPUT_DIR}/
`);
}

main().catch(console.error);
