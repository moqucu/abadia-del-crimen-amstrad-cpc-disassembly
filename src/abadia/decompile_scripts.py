import re
import sys

# This script decompiles the custom scripting language used in "La Abadía del Crimen".
# It parses the Z80 assembly source file, finds script blocks initiated by 'rst 08h'
# and 'rst 10h', and translates the bytecode into human-readable pseudo-code.

# Operator mapping derived from the game's interpreter logic at 3DF6h
OPERATORS = {
    0x3D: "==", 0x3E: ">=", 0x3C: "<",
    0x2A: "OR", 0x26: "AND",
    0x2B: "+", 0x2D: "-",
    0x84: "NEG"  # Unary negation
}

# Variable mapping from tokens to names, based on the table at 3D1D
VARIABLES = {
    0x80: "[william_x]", 0x81: "[william_y]", 0x82: "[william_z]",
    0x83: "[adso_x]", 0x84: "[berengario_x]", 0x85: "[adso_z]",
    0x86: "[malaquias_goal]", 0x87: "[malaquias_arrival]", 0x88: "[time_of_day]",
    0x89: "[is_voice_playing]", 0x8A: "[abbot_arrival]", 0x8B: "[abbot_goal]",
    0x8C: "[abbot_state]", 0x8D: "[day_number]", 0x8E: "[malaquias_state]",
    0x8F: "[scriptorium_disobey_counter]", 0x90: "[berengario_goal]",
    0x91: "[berengario_arrival]", 0x92: "[berengario_state]", 0x93: "[severino_goal]",
    0x94: "[severino_arrival]", 0x95: "[severino_state]", 0x96: "[adso_goal]",
    0x97: "[adso_arrival]", 0x98: "[adso_state]", 0x99: "[general_counter]",
    0x9A: "[current_screen_num]", 0x9B: "[advance_time_of_day_flag]",
    0x9C: "[is_william_dead_flag]", 0x9D: "[npc_x]",
    0x9E: "[door_check_mask]", 0x9F: "[door1_wing_state]",
    0xA0: "[door2_wing_state]", 0xA1: "[sleep_response_timer]",
    0xA2: "[phrase_to_show]", 0xA3: "[monks_in_place_flag]",
    0xA4: "[william_inventory]", 0xA5: "[berengario_warned_abbot_flag]",
    0xA6: "[abbot_inventory]", 0xA7: "[idle_follow_char]",
    0xA8: "[berengario_inventory]",
    0xAC: "[malaquias_death_state]",
    0xAD: "[jorge_active_for_severino]",
    0xAE: "[npc_state_flags_1]",
    0xAF: "[william_in_place_flag]",
    0xB0: "[berengario_pickup_mask]",
    0xB1: "[william_severino_state_flags]",
    0xB2: "[adso_random_movement_val]",
    0xB3: "[parchment_is_safe]",
    0xB4: "[is_night_ending]",
    0xB5: "[lamp_state_change]",
    0xB6: "[dark_library_timer]",
    0xB7: "[is_lamp_being_used]",
    0xB8: "[adso_has_lamp_flag]",
    0xB9: "[investigation_complete_flag]",
    0xBA: "[malaquias_pickup_mask]",
    0xBB: "[malaquias_inventory]",
    0xBC: "[UNKNOWN_416E]",
    0xBD: "[book_read_without_gloves_timer]",
    0xBE: "[adso_inventory]",
    0xBF: "[bonuses_part1]",
    0xC0: "[bonuses_part2]",
}

def get_operand_str(byte_val):
    """Converts a bytecode operand to its string representation."""
    if byte_val < 0x80:
        return f"0x{byte_val:02X}"
    return VARIABLES.get(byte_val, f"VAR_0x{byte_val:02X}")

def decompile_expression(bytecode):
    """Decompiles a bytecode expression using a stack-based RPN evaluation."""
    stack = []
    for byte in bytecode:
        if byte in OPERATORS:
            op_str = OPERATORS[byte]
            if op_str == "NEG" and stack:
                op1 = stack.pop()
                stack.append(f"NOT ({op1})")
            elif len(stack) >= 2:
                op2 = stack.pop()
                op1 = stack.pop()
                stack.append(f"({op1} {op_str} {op2})")
            else:
                # Handle malformed expression gracefully
                stack.append(f"[Malformed Expression: Operator '{op_str}']")
        else:
            stack.append(get_operand_str(byte))
    return " ".join(stack)

def parse_asm_file(input_path, output_path):
    """
    Parses the entire assembly file, finds script blocks,
    and writes the decompiled pseudo-code to the output file.
    """
    in_script_block = False
    current_script = []
    script_type = ""
    address = "UNKNOWN"

    # Regex to find all hex values in a 'db' line, handling 'h' suffix and '0x' prefix
    hex_finder = re.compile(r'(?:0x)?([0-9a-fA-F]{2})h?', re.IGNORECASE)

    with open(input_path, 'r', encoding='utf-8', errors='ignore') as f_in, \
         open(output_path, 'w') as f_out:
        for i, line in enumerate(f_in):
            stripped_line = line.strip()
            if not stripped_line:
                continue

            # If we were in a script block, check if the new line ends it
            if in_script_block and not stripped_line.lower().startswith('db'):
                if current_script:
                    f_out.write(f"--- Script at ~{address} ---\n")
                    if script_type == 'RST 10h':
                        dest_var = get_operand_str(current_script[0])
                        expression = decompile_expression(current_script[1:])
                        f_out.write(f"SET {dest_var} = {expression}\n\n")
                    else:  # RST 08h
                        expression = decompile_expression(current_script)
                        f_out.write(f"EVALUATE: {expression}\n\n")

                # Reset for the next block
                in_script_block = False
                current_script = []

            # Check if a new script block is starting
            if 'rst 08h' in stripped_line.lower() or 'rst 10h' in stripped_line.lower():
                in_script_block = True
                script_type = 'RST 10h' if 'rst 10h' in stripped_line.lower() else 'RST 08h'
                # Try to get the address from the line
                match = re.match(r'([0-9a-fA-F]{4}):', stripped_line)
                if match:
                    address = f"{match.group(1)}h"
                else:
                    address = f"line {i+1}" # Fallback to line number

            # If we are in a script block, parse the 'db' line
            if in_script_block and stripped_line.lower().startswith('db'):
                hex_vals = hex_finder.findall(stripped_line)
                for val in hex_vals:
                    try:
                        current_script.append(int(val, 16))
                    except ValueError:
                        pass # Ignore non-hex values that might be in comments

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python decompile_scripts.py <input_asm_file> <output_txt_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    print(f"Decompiling scripts from '{input_file}' to '{output_file}'...")
    parse_asm_file(input_file, output_file)
    print("Decompilation complete.")
