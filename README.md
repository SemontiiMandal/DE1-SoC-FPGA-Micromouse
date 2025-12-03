
# Micromouse Maze Game

A hardware-based maze navigation game implemented on the **DE1-SoC (Cyclone V) FPGA** using **Verilog HDL**.  
The design uses FSM-driven control, PS/2 input decoding, VGA rendering, on-chip memory, audio playback, and a hardware countdown timer.

---
## Note on Academic Policy:

This project was completed as part of ECE241 – Digital Systems at the University of Toronto.
As per the course policy, source code cannot be publicly posted to prevent plagiarism in future years.

If you would like to learn more about the design and implementation details, please feel free to contact me directly, and I’d be happy to discuss the project!

That being said, the following sections outline the project’s features, technical details, and overall hardware architecture.

---
## Features

- Tile-based 2D maze at **640×480 @ 60Hz**
- Single-player and multiplayer modes
- PS/2 keyboard input (arrow keys + WASD)
- Power-up tiles for speed-boost movement
- Movement-triggered PCM audio playback
- **60-second hardware timer** displayed on VGA and HEX
- On-screen progress bar
- Modular, multi-FSM architecture

---

## Technical Details

- Developed in **Intel Quartus Prime** using **Verilog HDL**
- Simulated in **ModelSim** (behavioral + timing)
- Dual-FSM structure: Game FSM + Player FSM
- Maze stored in **M10K on-chip memory** (25×25 grid)
- VGA controller generates full timing and pixel output
- PS/2 interface decodes make/break scancodes
- Audio system uses PCM samples stored in M10K ROM
- Synchronization implemented using flip-flops and clock division
- Memory usage optimized to support VGA + audio concurrently

---

## System Architecture

```
top.v
├── Game FSM (global flow)
├── Player FSM (movement, collision, power-ups)
├── Maze Generator (25x25 ROM / register map)
├── PS/2 Controller (make/break scancode decoder)
├── Audio Controller (PCM playback from ROM)
├── VGA Adapter (dual-port video memory, timing)
└── HEX Display Driver (60-second countdown)
```

### Game FSM
- Manages global screens: `START → PLAY → WIN/TIMEOUT → RESET`
- Controls `enable_player` gating and synchronizes all subsystems  
- Reads `move_pulse` + win state from Player FSM

### Player FSM
- Reads PS/2 scancodes  
- Implements movement, collision detection, tile validation  
- Handles power-up–enabled 2-tile jumps with safe-boundary checks  
- Outputs: `move_pulse`, `player_x`, `player_y`, `player_win`

### Maze Generator
- Hardware-generated 25×25 maze grid  
- Flattened **625-bit register** for single-cycle access  
- Deterministic “snake-path” topology with branches

### VGA Pipeline
- Generates all VGA timing signals (HS/VS, pixel clock)  
- Priority rendering: **Text → Player → Maze → Background**  
- Uses PLL-derived 25MHz pixel clock for stable display  

### Audio Engine
- PCM samples stored in **M10K blocks**  
- Playback triggered on `move_pulse`  
- Memory reduced/optimized to fit alongside VGA tile RAM

---
## ModelSim Simulation

ModelSim testbenches were used to validate:

- Player FSM transition logic  
- Debounce logic for PS/2 movement  
- Collision + boundary handling  
- Speed-boost (2-tile) movement behavior  
- Game FSM response to `player_win` and timer expiry  
- VGA timing signal correctness (HS/VS generation)  

Waveform analysis was used to verify:

- Flip-flop timing
- Synchronization between modules
- Edge-detect logic
- Memory read/write timing relative to VGA scan

---
## Project Demo
**Start Screen**
<p align="center"> <img src="https://github.com/user-attachments/assets/16cb3c0c-b8eb-4812-b77e-6cbd7a8685d5" width="480"> </p>

**Maze Screen**
<p align="center"> <img src="https://github.com/user-attachments/assets/b46b0245-74bd-4f59-84a2-7eb551742e22" width="420"> </p>

**High-Level Block Diagram**
<p align="center"> <img src="https://github.com/user-attachments/assets/578ed011-c720-429b-8d47-ff211af51b77" width="800"> </p>

**Demo Video**

🔗 https://drive.google.com/file/d/1XJWmp2f3EBE5d46LysXajvJF4ft-UhSN/view

**Final Presentation Slides**

🔗 https://drive.google.com/file/d/19oJmUrXqgn0TVWOPY_k7Vsnctj13sHVR/view?usp=drive_link
