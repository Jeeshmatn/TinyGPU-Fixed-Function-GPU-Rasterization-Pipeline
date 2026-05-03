# ============================================================
# TinyGPU Simulation Makefile
# Cadence Xcelium
# ============================================================

.ONESHELL:
SHELL := /bin/bash

SIM_DIR = ./
SRC_DIR = ../SRC
CUR_DIR = $(shell pwd)

ACCESS       = -access +rwc -gui
ACCESS_BATCH = -access +rwc
TIMESCALE    = -timescale 1ns/1ps

GPU_FILES = \
    $(SRC_DIR)/framebuffer.v     \
    $(SRC_DIR)/fragment_unit.v   \
    $(SRC_DIR)/vertex_unit.v     \
    $(SRC_DIR)/rasterizer.v      \
    $(SRC_DIR)/gpu_top_simple.v

# ============================================================
# HELP
# ============================================================
help:
	@echo "TinyGPU Simulation Makefile"
	@echo "==========================="
	@echo ""
	@echo "--- Compilation ---"
	@echo "compile                    : Compile all GPU design files"
	@echo ""
	@echo "--- Unit Tests (GUI) ---"
	@echo "sim_framebuffer            : framebuffer testbench (GUI)"
	@echo "sim_fragment               : fragment_unit testbench (GUI)"
	@echo "sim_vertex                 : vertex_unit testbench (GUI)"
	@echo "sim_rasterizer             : rasterizer testbench (GUI)"
	@echo "sim_gpu_top                : gpu_top_simple testbench (GUI)"
	@echo ""
	@echo "--- Unit Tests (Batch) ---"
	@echo "sim_framebuffer_batch      : framebuffer testbench (Batch)"
	@echo "sim_fragment_batch         : fragment_unit testbench (Batch)"
	@echo "sim_vertex_batch           : vertex_unit testbench (Batch)"
	@echo "sim_rasterizer_batch       : rasterizer testbench (Batch)"
	@echo "sim_gpu_top_batch          : gpu_top_simple testbench (Batch)"
	@echo ""
	@echo "--- Verification ---"
	@echo "golden                     : Run Python golden reference"
	@echo "compare                    : RTL vs golden comparison"
	@echo "gen_tests                  : Generate 100 test cases + testbench"
	@echo "sim_100                    : Run 100-test simulation (Batch)"
	@echo "sim_100_gui                : Run 100-test simulation (GUI)"
	@echo "compare_100                : Compare 100 tests RTL vs golden"
	@echo "run_100                    : Full 100-test flow"
	@echo ""
	@echo "--- Utilities ---"
	@echo "run_all                    : Run all batch sims + compare"
	@echo "clean                      : Remove simulation files"

# ============================================================
# COMPILATION
# ============================================================
compile:
	@echo "Starting TinyGPU Compilation..."
	xrun $(TIMESCALE) $(GPU_FILES) $(ACCESS)
	@echo "Logfile path: $(CUR_DIR)/xrun.log"

# ============================================================
# FRAMEBUFFER TESTBENCH
# ============================================================
sim_framebuffer:
	@echo "Running framebuffer testbench (GUI)..."
	xrun -sv $(TIMESCALE) \
	    $(SRC_DIR)/framebuffer.v \
	    tb_framebuffer.v \
	    $(ACCESS)

sim_framebuffer_batch:
	@echo "Running framebuffer testbench (Batch)..."
	xrun -sv $(TIMESCALE) \
	    $(SRC_DIR)/framebuffer.v \
	    tb_framebuffer.v \
	    $(ACCESS_BATCH) \
	    | tee framebuffer_sim.log
	@echo "Logfile: $(CUR_DIR)/framebuffer_sim.log"

# ============================================================
# FRAGMENT UNIT TESTBENCH
# ============================================================
sim_fragment:
	@echo "Running fragment_unit testbench (GUI)..."
	xrun -sv $(TIMESCALE) \
	    $(SRC_DIR)/fragment_unit.v \
	    tb_fragment_unit.v \
	    $(ACCESS)

sim_fragment_batch:
	@echo "Running fragment_unit testbench (Batch)..."
	xrun -sv $(TIMESCALE) \
	    $(SRC_DIR)/fragment_unit.v \
	    tb_fragment_unit.v \
	    $(ACCESS_BATCH) \
	    | tee fragment_sim.log
	@echo "Logfile: $(CUR_DIR)/fragment_sim.log"

# ============================================================
# VERTEX UNIT TESTBENCH
# ============================================================
sim_vertex:
	@echo "Running vertex_unit testbench (GUI)..."
	xrun -sv $(TIMESCALE) \
	    $(SRC_DIR)/vertex_unit.v \
	    tb_vertex_unit.v \
	    $(ACCESS)

sim_vertex_batch:
	@echo "Running vertex_unit testbench (Batch)..."
	xrun -sv $(TIMESCALE) \
	    $(SRC_DIR)/vertex_unit.v \
	    tb_vertex_unit.v \
	    $(ACCESS_BATCH) \
	    | tee vertex_sim.log
	@echo "Logfile: $(CUR_DIR)/vertex_sim.log"

# ============================================================
# RASTERIZER TESTBENCH
# ============================================================
sim_rasterizer:
	@echo "Running rasterizer testbench (GUI)..."
	xrun -sv $(TIMESCALE) \
	    $(SRC_DIR)/framebuffer.v \
	    $(SRC_DIR)/fragment_unit.v \
	    $(SRC_DIR)/vertex_unit.v \
	    $(SRC_DIR)/rasterizer.v \
	    tb_rasterizer.v \
	    $(ACCESS)

sim_rasterizer_batch:
	@echo "Running rasterizer testbench (Batch)..."
	xrun -sv $(TIMESCALE) \
	    $(SRC_DIR)/framebuffer.v \
	    $(SRC_DIR)/fragment_unit.v \
	    $(SRC_DIR)/vertex_unit.v \
	    $(SRC_DIR)/rasterizer.v \
	    tb_rasterizer.v \
	    $(ACCESS_BATCH) \
	    | tee rasterizer_sim.log
	@echo "Capturing pixel output..."
	grep "^PIXEL" rasterizer_sim.log > rtl_pixels.txt || true
	@echo "Pixel log saved: $(CUR_DIR)/rtl_pixels.txt"

# ============================================================
# GPU TOP SIMPLE TESTBENCH
# ============================================================
sim_gpu_top:
	@echo "Running gpu_top_simple testbench (GUI)..."
	xrun -sv $(TIMESCALE) \
	    $(GPU_FILES) \
	    tb_gpu_top_simple.v \
	    $(ACCESS)

sim_gpu_top_batch:
	@echo "Running gpu_top_simple testbench (Batch)..."
	xrun -sv $(TIMESCALE) \
	    $(GPU_FILES) \
	    tb_gpu_top_simple.v \
	    $(ACCESS_BATCH) \
	    | tee gpu_top_sim.log
	@echo "Logfile: $(CUR_DIR)/gpu_top_sim.log"

# ============================================================
# PYTHON GOLDEN REFERENCE
# ============================================================
golden:
	@echo "Running Python golden reference..."
	python3 golden_ref.py | tee golden_output.log
	@echo "Golden output saved: $(CUR_DIR)/golden_output.log"

# ============================================================
# COMPARE RTL vs GOLDEN
# ============================================================
capture:
	@echo "Capturing RTL pixel output..."
	xrun -sv $(TIMESCALE) \
	    $(SRC_DIR)/framebuffer.v \
	    $(SRC_DIR)/fragment_unit.v \
	    $(SRC_DIR)/vertex_unit.v \
	    $(SRC_DIR)/rasterizer.v \
	    tb_rasterizer.v \
	    $(ACCESS_BATCH) 2>&1 | grep "^PIXEL" > rtl_pixels.txt || true
	@echo "Pixel count: $$(wc -l < rtl_pixels.txt)"

compare: capture golden
	@echo "Comparing RTL output against golden reference..."
	python3 compare.py rtl_pixels.txt | tee compare_result.log
	@cat compare_result.log

# ============================================================
# 100 TEST CASE FLOW
# ============================================================
gen_tests:
	@echo "Generating 100 test cases..."
	python3 gen_tests.py
	@echo "tb_rasterizer_100.v generated"

sim_100: gen_tests
	@echo "Running 100-test rasterizer simulation (Batch)..."
	xrun -sv $(TIMESCALE) \
	    $(SRC_DIR)/framebuffer.v \
	    $(SRC_DIR)/fragment_unit.v \
	    $(SRC_DIR)/vertex_unit.v \
	    $(SRC_DIR)/rasterizer.v \
	    tb_rasterizer_100.v \
	    $(ACCESS_BATCH) 2>&1 | grep "^PIXEL_" > rtl_pixels_100.txt || true
	@echo "RTL pixel log saved: rtl_pixels_100.txt"
	@echo "Total pixel lines: $$(wc -l < rtl_pixels_100.txt)"

sim_100_gui: gen_tests
	@echo "Running 100-test rasterizer simulation (GUI)..."
	xrun -sv $(TIMESCALE) \
	    $(SRC_DIR)/framebuffer.v \
	    $(SRC_DIR)/fragment_unit.v \
	    $(SRC_DIR)/vertex_unit.v \
	    $(SRC_DIR)/rasterizer.v \
	    tb_rasterizer_100.v \
	    $(ACCESS)

compare_100: sim_100
	@echo "Comparing 100 tests RTL vs golden..."
	python3 gen_tests.py rtl_pixels_100.txt 2>&1 | tee compare_100_result.log
	@cat compare_100_result.log

run_100: compare_100
	@echo "100-test verification complete"

# ============================================================
# RUN ALL
# ============================================================
run_all: sim_framebuffer_batch sim_fragment_batch \
         sim_vertex_batch sim_rasterizer_batch \
         sim_gpu_top_batch compare run_100
	@echo "All simulations complete."
	@echo "Check individual .log files for results."

# ============================================================
# CLEAN
# ============================================================
clean:
	@echo "Cleaning simulation files..."
	rm -rf xcelium.d xrun.log xrun.history *.shm *.key *.log \
	       *.dsn *.trn waves.shm rtl_pixels.txt rtl_pixels_100.txt \
	       golden_output.log compare_result.log compare_100_result.log \
	       tb_rasterizer_100.v __pycache__
	@echo "Clean completed."

.PHONY: help compile \
        sim_framebuffer sim_framebuffer_batch \
        sim_fragment    sim_fragment_batch    \
        sim_vertex      sim_vertex_batch      \
        sim_rasterizer  sim_rasterizer_batch  \
        sim_gpu_top     sim_gpu_top_batch     \
        golden capture compare                \
        gen_tests sim_100 sim_100_gui         \
        compare_100 run_100                   \
        run_all clean
