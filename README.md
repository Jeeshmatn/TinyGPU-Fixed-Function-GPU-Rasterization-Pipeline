# TinyGPU - Fixed-Function GPU Rasterization Pipeline

> A hardware implementation of a triangle rasterization pipeline in Verilog,  
> implementing Pineda's edge function algorithm on a 64×64 pixel framebuffer.  
> Verified with 100/100 test cases against a Python golden reference.

---

## Motivation

While browsing LinkedIn, I came across a post where a software engineer was building a small GPU from scratch — purely out of curiosity. That post stayed with me. I thought: if someone is building a GPU from the software side, I should build one at the hardware level — which is where GPUs actually live. That became the motivation for TinyGPU.

---

## What is a Fixed-Function Rasterization Pipeline?

A GPU graphics pipeline has several stages:

```
Application → Vertex Shader → Rasterization → Fragment Shader → Framebuffer → Display
```

TinyGPU implements the **rasterization stage** — the core of any GPU:
- Takes triangle vertices as input
- Determines which pixels fall inside the triangle
- Writes pixel colors to framebuffer

It is **not** a full programmable GPU — no compute shaders, no texturing, no depth buffer. It is the fundamental rasterization engine, architecturally correct and verified.

---


### Module Description

| Module | Purpose |
|--------|---------|
| `vertex_unit.v` | Clamps input coordinates to 0-63 screen boundary |
| `rasterizer.v` | 10-state FSM implementing Pineda edge function algorithm |
| `fragment_unit.v` | Assigns flat color to each valid pixel (combinational) |
| `framebuffer.v` | 64×64 dual-port SRAM — sync write, async read |
| `gpu_top_simple.v` | Connects all modules with parallel interface |

---

## Algorithm — Pineda Edge Function

For any edge from vertex A to vertex B, define:

```
E(P) = (Bx-Ax)(Py-Ay) - (By-Ay)(Px-Ax)
```

For a **clockwise** triangle in screen coordinates (Y increases downward):
- Pixel is **inside** when: `E1 ≤ 0` AND `E2 ≤ 0` AND `E3 ≤ 0`

**Bounding box optimization:** Only pixels within the tight rectangle around the triangle are tested — reduces computation significantly.

**Why Pineda over scanline?**
- No division needed — scanline requires edge intersection computation with division
- Pineda uses only multiply and subtract
- Inner loop can be optimized to additions only (incremental approach)

---

## FSM State Diagram
```


`IDLE`          -Wait for start pulse 
 `INIT`        - Register bounding box from vertex inputs 
 `INIT_WAIT`   - Load cur_x/cur_y from bounding box registers 
 `TEST`        - Evaluate px_inside combinationally, decide next state 
 `WRITE_PIXEL` - Assert pixel_valid with coordinates                   
 `NEXT_COL`    - Increment cur_x                                      
 `NEXT_ROW`    - Increment cur_y 
 `SCAN_ROW`    - Reset cur_x to x_min for new row 
 `DONE_ST`     - Assert done signal                               

---

## Verification

### Verification Flow

```
make run_100
    │
    ├── gen_tests.py     → generates 100 test cases + tb_rasterizer_100.v
    ├── xrun simulation  → runs RTL, captures PIXEL_N (x,y) per test
    └── gen_tests.py     → compares RTL output vs Python golden reference
```

### Test Categories

| Category        | Count   | Description                        |
|-----------------|---------|------------------------------------|
| Small triangles | 20      | Vertices in range 5-30             |
| Large triangles | 20      | Vertices spanning full 64×64       |
| Flat-bottom     | 20      | Two vertices share same Y          |
| Flat-top        | 20      | Two vertices share same Y          |
| Edge/corner     | 20      | Degenerate, boundary, single pixel |
| **Total**       | **100** | **100/100 PASS**                   |

### Result

```
============================================================
TinyGPU 100-Test Comparison
============================================================
Results:
  PASS: 100 / 100
  FAIL:   0 / 100
  ALL 100 TESTS PASSED!
============================================================
```

---

## How to Run

### Prerequisites
```bash
# Cadence Xcelium (for RTL simulation)
# Python 3.x (for golden reference)
```

### Quick Start
```bash
git clone https://github.com/jeeshma/tinygpu
cd tinygpu/SIM

# Run full 100-test verification
make run_100

# Run individual module tests
make sim_rasterizer       # GUI mode
make sim_rasterizer_batch # Batch mode

# Run full pipeline
make sim_gpu_top          # GUI mode
make sim_gpu_top_batch    # Batch mode

# Run golden reference only
make golden

# Compare RTL vs golden (single test)
make compare

# See all targets
make help
```

### Makefile Targets

| Target | Description |
|--------|-------------|
| `make sim_rasterizer` | Rasterizer GUI simulation |
| `make sim_gpu_top` | Full pipeline GUI simulation |
| `make golden` | Run Python golden reference |
| `make compare` | RTL vs golden comparison |
| `make gen_tests` | Generate 100 test cases |
| `make run_100` | Full 100-test automated flow |
| `make clean` | Remove simulation artifacts |

---

## Design Decisions

**Why Pineda over scanline rasterization?**
Scanline requires division to compute edge intersections. Division is expensive in hardware. Pineda uses only multiply and subtract — and can be further optimized to additions only in the inner loop.

**Why parallel interface (not AXI) for verified version?**
The parallel interface was used for the verified pipeline to keep focus on rasterizer correctness. AXI-Lite slave and AXI-Stream master modules are written and structurally complete — integration and simulation is the planned next step.

**Why 64×64 resolution?**
4096 pixels fits in 4KB on-chip SRAM without external memory. 12-bit address and 6-bit coordinates keep the design clean. The algorithm is resolution-independent — scaling requires only wider counters and larger memory.

**Why combinational edge functions?**
Earlier versions used registered incremental edge function updates (additions only in inner loop). This caused subtle register timing bugs. Replaced with purely combinational computation from cur_x/cur_y — always correct, zero timing issues. Incremental optimization is documented as a planned enhancement.

**Why clockwise winding convention?**
Triangle A(3,1) B(1,6) C(7,6) is clockwise in screen coordinates (Y increases downward). For clockwise winding, inside pixels have all edge functions ≤ 0.

---

## Planned Enhancements

```
Version 2:
  [ ] 2x2 quad parallel pixel evaluation (4x throughput)
  [ ] Incremental edge function updates (additions only)
  [ ] Dual-clock SRAM + Gray-code FIFO for CDC
  [ ] Barycentric color interpolation in fragment unit
  [ ] AXI-Lite + AXI-Stream full pipeline simulation
  [ ] OpenLane GDS and timing/area report
```

---

## Color Format — RGB 3:3:2

```
bits [7:5] = Red   (3 bits — 8 levels)
bits [4:2] = Green (3 bits — 8 levels)
bits [1:0] = Blue  (2 bits — 4 levels)

Example: 0xE3 = 1110_0011
  Red=7, Green=0, Blue=3 → orange-red
```

---

## About

Built as a personal RTL design project.
Inspired by a LinkedIn post about a software engineer building a GPU from scratch —  
decided to build the hardware version.

**Author:** Jeeshma TN  
**Year:** 2026

---

## Tools Used

| Tool            | Purpose                             |
|-----------------|-------------------------------------|
| Cadence Xcelium | RTL simulation                      |
| SimVision       | Waveform viewing                    |
| Python 3        | Golden reference + test generation  |
| OpenLane        | RTL-to-GDS synthesis                | -future 
| Git             | Version control                     |
