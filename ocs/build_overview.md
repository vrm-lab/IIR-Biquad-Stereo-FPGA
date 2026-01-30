# Build & Integration Overview

This document describes how the IIR Biquad module is intended to be **integrated**, not how to recreate a Vivado project.

---

## Intended Usage

This RTL is designed to be instantiated as:

* A standalone AXI-Stream DSP block, or
* A component inside a larger audio/DSP pipeline

The repository intentionally omits:

* Vivado project files
* Bitstreams
* Board-specific constraints

---

## Clocking & Reset

* **Clock:** Single synchronous clock (`aclk`)
* **Reset:**

  * Global reset: `aresetn` (active-low)
  * Soft reset via AXI-Lite (clears filter state)

No clock domain crossing logic is included.

---

## AXI Interfaces

### AXI-Stream

* Stereo samples packed as:

  * `[31:16]` — Left channel
  * `[15:0]`  — Right channel

* Fully backpressure-aware

* No internal buffering beyond register stages

### AXI-Lite

* Used exclusively for configuration
* Single outstanding transaction supported
* Suitable for bare-metal or Python (PYNQ) control

---

## Tool Compatibility

The RTL is written in synthesizable Verilog and has been validated using:

* RTL simulation
* FPGA-based execution (via PYNQ overlay)

No vendor-specific primitives are required.

---

## Philosophy

This module is meant to be:

* Readable
* Predictable
* Easily auditable

It is not intended to be a turnkey IP core.
