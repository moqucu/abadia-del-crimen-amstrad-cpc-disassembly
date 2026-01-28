"""
Compare generated DSL scripts with JS reference to verify disassembly accuracy.
"""

import re
import difflib

GENERATED_FILE = "tests/abadia/resouces/scripts_disassembled.abs"
REFERENCE_FILE = "/Users/seikenberg/GitHub/abadia/public/assets/abadia/scripts.abs"

def parse_abs(filepath):
    scripts = {}
    current_script = None
    current_lines = []
    
    try:
        with open(filepath, 'r') as f:
            for line in f:
                line = line.strip()
                if not line: continue
                
                # Header [SCRIPTn]
                m = re.match(r'^\[SCRIPT(\d+)\]$', line)
                if m:
                    # Save previous
                    if current_script is not None:
                        scripts[current_script] = current_lines
                    
                    current_script = int(m.group(1))
                    current_lines = []
                else:
                    if current_script is not None:
                        current_lines.append(line)
            
            # Save last
            if current_script is not None:
                scripts[current_script] = current_lines
    except FileNotFoundError:
        print(f"Error: File not found: {filepath}")
        return {}
        
    return scripts

def compare_scripts():
    gen_scripts = parse_abs(GENERATED_FILE)
    ref_scripts = parse_abs(REFERENCE_FILE)
    
    common_ids = set(gen_scripts.keys()) & set(ref_scripts.keys())
    missing_in_gen = set(ref_scripts.keys()) - set(gen_scripts.keys())
    extra_in_gen = set(gen_scripts.keys()) - set(ref_scripts.keys())
    
    print(f"Generated Scripts: {len(gen_scripts)}")
    print(f"Reference Scripts: {len(ref_scripts)}")
    print(f"Common Scripts: {len(common_ids)}")
    
    differing = []
    
    for sid in sorted(common_ids):
        gen_lines = gen_scripts[sid]
        ref_lines = ref_scripts[sid]
        
        # Normalize: Reference seems to use specific formatting
        # We'll just compare stripped lines for now
        
        if gen_lines != ref_lines:
            differing.append(sid)
            
    print(f"\nIdentical Scripts: {len(common_ids) - len(differing)}")
    print(f"Differing Scripts: {len(differing)}")
    
    if missing_in_gen:
        print(f"\nMissing in Generated ({len(missing_in_gen)}): {sorted(list(missing_in_gen))}")
        # Note: SCRIPT96+ are common subroutines, likely 'missing' because we don't extract them as blocks
        
    if extra_in_gen:
        print(f"\nExtra in Generated ({len(extra_in_gen)}): {sorted(list(extra_in_gen))}")

    print("\n--- Detailed Differences (SCRIPT38) ---")
    if 38 in differing:
        print(f"\n[SCRIPT38]")
        diff = difflib.unified_diff(
            ref_scripts[38], 
            gen_scripts[38], 
            fromfile='Reference', 
            tofile='Generated', 
            lineterm=''
        )
        for line in diff:
            print(line)
    else:
        print("SCRIPT38 Matches!")

if __name__ == "__main__":
    compare_scripts()