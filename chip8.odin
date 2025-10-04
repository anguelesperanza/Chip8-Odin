package main
/* Chip8 Emulator
	==============
	This is a Chip8 Emulator


	nnn or addr - 12 bit value, the lowest 12 bits of an instruction
	n or nibble - 4 bit value, lowest 4 bits of an instruction
	x 4 bit value, lower 4 bits of the high byte of the instruction
	y - 4 bit value, the upper 4 bits of the low bits of the instruction
*/

import "core:fmt"
import "core:os/os2"
import rl "vendor:raylib"
import "core:math/rand"
import "core:mem"

font_set: []u8 = {
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80  // F
}

SCREEN_SIZE :: 64 * 32
LOAD_ROM_INDEX :: 0x200

memory:[4095]u8 // Total size of the chip8 memory
registers:[16]u8 // 16 general purpose registers
index:u16 // Stores the memory address (lower 12 bits)
delay_timer:u8
sound_timer:u8
display:[SCREEN_SIZE]u8
program_counter:u16
stack_pointer:u8
stack:[16]u16
keys:[16]bool

accumulator := 0.0
last_time := 0.0

target_fps := 60.0
ms_per_frame := 1000.0 / target_fps

read_rom :: proc(filename:string) {

	data, ok := os2.read_entire_file_from_path(name = filename, allocator = context.allocator)
	if ok != nil {
		fmt.eprintf("%v", ok)
		return
	}

	fmt.printf("%x\n", data)

	for value, index in data{
		memory[LOAD_ROM_INDEX + index] = value
	}
}

load_font :: proc() {
	
	for font_index, value in font_set{
		memory[0x50 + font_index] = cast(u8)value
	}

}

update_keys :: proc() {
	/*
		original keyset
		1 2 3 C
		4 5 6 D
		7 8 9 E
		A 0 B F

		mapped keyset
		1 2 3 4
		Q W E R
		A S D F
		Z X C V
	*/

	    // Keys Pressed
    if rl.IsKeyPressed(.X)     { keys[0x0] = true }
    if rl.IsKeyPressed(.ONE)   { keys[0x1] = true }
    if rl.IsKeyPressed(.TWO)   { keys[0x2] = true }
    if rl.IsKeyPressed(.THREE) { keys[0x3] = true }
    if rl.IsKeyPressed(.Q)     { keys[0x4] = true }
    if rl.IsKeyPressed(.W)     { keys[0x5] = true }
    if rl.IsKeyPressed(.E)     { keys[0x6] = true }
    if rl.IsKeyPressed(.A)     { keys[0x7] = true }
    if rl.IsKeyPressed(.S)     { keys[0x8] = true }
    if rl.IsKeyPressed(.D)     { keys[0x9] = true }
    if rl.IsKeyPressed(.Z)     { keys[0xA] = true }
    if rl.IsKeyPressed(.C)     { keys[0xB] = true }
    if rl.IsKeyPressed(.FOUR)  { keys[0xC] = true }
    if rl.IsKeyPressed(.R)     { keys[0xD] = true }
    if rl.IsKeyPressed(.F)     { keys[0xE] = true }
    if rl.IsKeyPressed(.V)     { keys[0xF] = true }

    // Keys Released
    if rl.IsKeyReleased(.X)     { keys[0x0] = false }
    if rl.IsKeyReleased(.ONE)   { keys[0x1] = false }
    if rl.IsKeyReleased(.TWO)   { keys[0x2] = false }
    if rl.IsKeyReleased(.THREE) { keys[0x3] = false }
    if rl.IsKeyReleased(.Q)     { keys[0x4] = false }
    if rl.IsKeyReleased(.W)     { keys[0x5] = false }
    if rl.IsKeyReleased(.E)     { keys[0x6] = false }
    if rl.IsKeyReleased(.A)     { keys[0x7] = false }
    if rl.IsKeyReleased(.S)     { keys[0x8] = false }
    if rl.IsKeyReleased(.D)     { keys[0x9] = false }
    if rl.IsKeyReleased(.Z)     { keys[0xA] = false }
    if rl.IsKeyReleased(.C)     { keys[0xB] = false }
    if rl.IsKeyReleased(.FOUR)  { keys[0xC] = false }
    if rl.IsKeyReleased(.R)     { keys[0xD] = false }
    if rl.IsKeyReleased(.F)     { keys[0xE] = false }
    if rl.IsKeyReleased(.V)     { keys[0xF] = false }

// 	// Keys Pressed
// 	// Top Row
// 	if rl.IsKeyPressed(.ONE) {
// 		keys[0] = true
// 	}
// 	if rl.IsKeyPressed(.TWO) {
// 		keys[1] = true
// 	}
// 	if rl.IsKeyPressed(.THREE) {
// 		keys[2] = true
// 	}
// 	if rl.IsKeyPressed(.FOUR) {
// 		keys[3] = true
// 	}

// 	// Second row
// 	if rl.IsKeyPressed(.Q) {
// 		keys[4] = true
// 	}
// 	if rl.IsKeyPressed(.W) {
// 		keys[5] = true
// 	}
// 	if rl.IsKeyPressed(.E) {
// 		keys[6] = true
// 	}
// 	if rl.IsKeyPressed(.R) {
// 		keys[7] = true
// 	}

// 	// Third Row
// 	if rl.IsKeyPressed(.A) {
// 		keys[8] = true
// 	}
// 	if rl.IsKeyPressed(.S) {
// 		keys[9] = true
// 	}
// 	if rl.IsKeyPressed(.D) {
// 		keys[10] = true
// 	}
// 	if rl.IsKeyPressed(.F) {
// 		keys[11] = true
// 	}

// 	// fouth row
// 	if rl.IsKeyPressed(.Z) {
// 		keys[12] = true
// 	}
// 	if rl.IsKeyPressed(.X) {
// 		keys[13] = true
// 	}
// 	if rl.IsKeyPressed(.C) {
// 		keys[14] = true
// 	}
// 	if rl.IsKeyPressed(.V) {
// 		keys[15] = true
// 	}


	
// 	// Keys Released
// 	// Top Row
// 	if rl.IsKeyReleased(.ONE) {
// 	    keys[0] = false
// 	}
// 	if rl.IsKeyReleased(.TWO) {
// 	    keys[1] = false
// 	}
// 	if rl.IsKeyReleased(.THREE) {
// 	    keys[2] = false
// 	}
// 	if rl.IsKeyReleased(.FOUR) {
// 	    keys[3] = false
// 	}

// 	// Second row
// 	if rl.IsKeyReleased(.Q) {
// 	    keys[4] = false
// 	}
// 	if rl.IsKeyReleased(.W) {
// 	    keys[5] = false
// 	}
// 	if rl.IsKeyReleased(.E) {
// 	    keys[6] = false
// 	}
// 	if rl.IsKeyReleased(.R) {
// 	    keys[7] = false
// 	}

// 	// Third Row
// 	if rl.IsKeyReleased(.A) {
// 	    keys[8] = false
// 	}
// 	if rl.IsKeyReleased(.S) {
// 	    keys[9] = false
// 	}
// 	if rl.IsKeyReleased(.D) {
// 	    keys[10] = false
// 	}
// 	if rl.IsKeyReleased(.F) {
// 	    keys[11] = false
// 	}

// 	// Fourth row
// 	if rl.IsKeyReleased(.Z) {
// 	    keys[12] = false
// 	}
// 	if rl.IsKeyReleased(.X) {
// 	    keys[13] = false
// 	}
// 	if rl.IsKeyReleased(.C) {
// 	    keys[14] = false
// 	}
// 	if rl.IsKeyReleased(.V) {
// 	    keys[15] = false
// 	}

}

execute_instruction :: proc() {

	// nnn or addr - 12 bit value, the lowest 12 bits of an instruction
	// n or nibble - 4 bit value, lowest 4 bits of an instruction
	// x 4 bit value, lower 4 bits of the high byte of the instruction
	// y 4 bit value, the upper 4 bits of the low bits of the instruction
	// kk or byte - An 8-bit value, the lowest 8 bits of the instruction

	opcode:u16 = cast(u16)memory[program_counter] << 8 | cast(u16)memory[program_counter + 1]

	nnn := opcode & 0x0FFF // Mask the value to get just the lower 12 bits of the instruction
	n := opcode & 0x000F // Mask the value to get the lower 4 bits of the instruction
	x := (opcode >> 8) & 0x0F // Mask the lower 4 bits of the high byte instruction
	y := (opcode >> 4) & 0x0F // Mask the upper 4 bits of the low byte instruction
	kk := opcode & 0x00FF // Mask the lower 8 bits of the instruction
	first := opcode >> 12 // Gets the first digit in instruction -- 1nnn gets 1, 00E0 gets 0

	// x := (opcode & 0x0F00) >> 8 // Mask the lower 4 bits of the high byte instruction
	// y := (opcode & 0x00F0) >> 4 // Mask the upper 4 bits of the low byte instruction

	fmt.printf("opcode: %x \n", opcode)	
	fmt.printf("nnn: %v \n", nnn)	
	fmt.printf("n: %v \n", n)	
	fmt.printf("x: %v \n", x)	
	fmt.printf("y: %v \n", y)	
	fmt.printf("kk: %v \n", kk)
	fmt.printf("first: %v \n", first)
	fmt.println("============================")

	switch first {
		case 0: 
			if opcode == 0x00E0{
				fmt.println("clear screen")
				// mem.zero(&display, 32*64)
				display = {}
				fmt.println(display)
				program_counter += 2
				break
			}
			if opcode == 0x00EE {
				fmt.println("Pop value off stack")
				program_counter = stack[stack_pointer]
				stack_pointer -= 1
			}
		case 1:
			fmt.printf("Jumping to location: %v\n", nnn)
			program_counter = nnn
		case 2:
			fmt.println("Running subroutine")
			stack_pointer += 1
			stack[stack_pointer] = program_counter + 2
			program_counter = nnn
		case 3:
			if registers[x] == cast(u8)kk {
				 program_counter += 4
			} else {
				program_counter += 2
			}
		case 4:
			if registers[x] != cast(u8)kk {
				 program_counter += 2
			} 

			program_counter += 2
		case 5:
			if registers[x] == registers[y] {
				 program_counter += 4
			} else {
				program_counter += 2
			}
		case 6:
			fmt.println("Load register")
			registers[x] = cast(u8)kk
			program_counter += 2
		case 7:
			registers[x] += cast(u8)kk

			program_counter += 2
		case 8:
			// fmt.printf("N: %x", n)
			switch n {
				case 0:
					registers[x] = registers[y]
					program_counter += 2
					fmt.println("stored x in y")
				case 1:
					registers[x] = registers[x] | registers[y]
					program_counter += 2
				case 2:
					registers[x] = registers[x] & registers[y]
					program_counter += 2
				case 3:
					registers[x] = registers[x] ~ registers[y]

					program_counter += 2
				case 4:
					value := registers[x] + registers[y]
					if value > 255 {
						registers[15] = 1
					} else {
						registers[15] = 0
					} 
					registers[x] = value & 0x00FF
					program_counter += 2
				case 5:
					if registers[x] > registers[y] {
						registers[15] = 1
					} else {
						registers[15] = 0
					}
					registers[x] -= registers[y]
					program_counter += 2
				case 6:
					lsb := registers[x] & 0x01
					if lsb == 1 {
						registers[15] = 1
					} else {
						registers[15] = 0
					}

					registers[x] = registers[x] / 2
					program_counter += 2
				case 7:
					if registers[y] > registers[x] {
						registers[15] = 1
					} else {
						registers[15] = 0
					}

					registers[x] = registers[y] - registers[x]

					program_counter += 2

				case 0x0E: 
					msb := (registers[x] >> 7) & 0x1
					if msb == 1 {
						registers[15] = 1
					} else {
						registers[15] = 0
					}
					registers[x] *= 2

					
					program_counter += 2
			}
		case 9:
			if registers[x] != registers[y] {
				program_counter += 2
			}
			program_counter += 2
		case 0x0A:
			fmt.println("Load index")
			index = nnn
			program_counter += 2
		case 0x0B:
			program_counter = nnn + cast(u16)registers[0]
		case 0x0C:
			rand_value:u8 = cast(u8)rand.int_max(256) // 256 is exclusive (not included in range)
			registers[x] = rand_value & cast(u8)kk
			program_counter += 2
		case 0x0D:
			fmt.println("Draw")
			// Dxyn - DRW Vx, Vy, nibble
			// Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision.
			// D -> Draw Instruction, x -> horizontal pos, y -> vertical pos, n -> number of rows

			// The interpreter reads n bytes from memory, starting at the address stored in I. These bytes are then displayed as sprites on screen at coordinates (Vx, Vy). 
			// Sprites are XORed onto the existing screen. If this causes any pixels to be erased, VF is set to 1, otherwise it is set to 0. 
			// If the sprite is positioned so part of it is outside the coordinates of the display, it wraps around to the opposite side of the screen. 
			// See instruction 8xy3 for more information on XOR, and section 2.4, Display, for more information on the Chip-8 screen and sprites.

			
			registers[15] = 0
			for row in 0..< n {
				sprite:u8 = memory[index + row]
				
				for col in 0 ..< 8 {
					pixel:u8 = (sprite >> (7 - cast(u8)col)) & 0x1
					pixel_x:u8 = (registers[x] + cast(u8)col) % 64 // % 64 wraps around to other end of screen
					pixel_y:u8 = (registers[y] + cast(u8)row) % 32 // % 32 wraps around to other end of screen

					pixel_index:u16 = cast(u16)pixel_y * 64 + cast(u16)pixel_x 

					if pixel == 1 {
						if display[pixel_index] == 1 {
 							registers[15] = 1
						}
						display[pixel_index] = display[pixel_index] ~ 1
					}
				}
			}
		
			program_counter += 2

			
		case 0x0E:
			switch kk {
				case 0x9E:
					if keys[registers[x]] == true {
						program_counter += 2
					}
					program_counter += 2

				case 0xA1:
					if keys[registers[x]] == false {
						program_counter += 2
					}
					program_counter += 2

			}
		case 0xF:
			fmt.println("0xF Instructions")
			switch kk {
				case 7:
					registers[x] = delay_timer
					program_counter += 2
				case 0x0A:
					waiting_for_key:bool = true
					for key, key_index in keys {
						if key {
							registers[x] = cast(u8)key_index
							program_counter += 2
							break
						}
						return 
					}
				case 0x15:
					delay_timer = registers[x]
					program_counter += 2
				case 0x18:
					sound_timer = registers[x]
					program_counter += 2
				case 0x1E:
					index += cast(u16)registers[x]
					program_counter += 2
				case 0x29:
					index = u16(0x50 + (registers[x] * 5))
					program_counter += 2
				case 0x33:
					value := registers[x]
					memory[index] = value / 100
					memory[index + 1] = (value / 10) % 10
					memory[index + 2] = value % 10
					program_counter += 2
				case 0x55:
					fmt.println("Reading registers into memory")
					for i in 0 ..=x {
						memory[index + cast(u16)i] = registers[i]
					}
					program_counter += 2
				case 0x65:
					fmt.println("Reading memory into registers")
					for i in 0 ..=x {
						registers[i] = memory[index + cast(u16)i]
					}
					program_counter += 2
			}
	}
}

update_hz :: proc() {
    current_time := rl.GetTime() * 1000.0
    delta_time := current_time - last_time
    last_time = current_time

    accumulator += delta_time
    timer_accumulator: f64 = 0.0

    // Instruction rate: ~700 Hz
    instructions_per_second := 500.0
    ms_per_instruction := 1000.0 / instructions_per_second

    // Timer rate: 60 Hz
    ms_per_timer_tick := 1000.0 / 60.0

    // Run instructions
    for accumulator >= ms_per_instruction {
        execute_instruction()
        accumulator -= ms_per_instruction
        timer_accumulator += ms_per_instruction

    }

    if delay_timer > 0 do delay_timer -= 1
    if sound_timer > 0 do sound_timer -= 1
    timer_accumulator -= ms_per_timer_tick
}

main :: proc() {
	fmt.println("Welcome to Chip8")

	program_counter = LOAD_ROM_INDEX
	
	load_font()
	read_rom("./roms/Breakout.ch8")

	// rl.InitWindow(1080, 720, "Chip8 Emulator")
	rl.InitWindow(640, 320, "Chip8 Emulator")
	defer rl.CloseWindow()


	for !rl.WindowShouldClose() {
		update_keys()
		update_hz()
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLUE)

	    for y:i32= 0; y < 32; y += 1 {
	        for x:i32= 0; x < 64; x += 1 {
	            if display[y * 64 + x] == 1 {
					// rl.DrawRectangleLines(x * 10, y * 10, 10, 10, rl.GRAY) // grid
	                rl.DrawRectangle(x * 10, y * 10, 10, 10, rl.WHITE);
	            }
	        }
	    }
		rl.EndDrawing()
	}
}
