# create_project.tcl

This script recreates the **Vivado block design project** used to integrate the IIR Biquad AXI-Stream module on **AMD Kria KV260**.

---

## Purpose

* Reconstruct the **Vivado project and block design** exactly as used during hardware validation
* Capture the **integration context** (PS, DMA, AXI interconnect), not just the RTL

This script exists for **reproducibility and reference**, not as a deployment flow.

---

## What This Script Does

* Creates a Vivado project targeting **xck26-sfvc784-2LV-c**
* Imports RTL sources:

  * `iir_biquad_core_16.v`
  * `iir_biquad_axis.v`
* Imports simulation testbenches
* Recreates the block design:

  * Zynq UltraScale+ MPSoC (KV260 preset)
  * AXI DMA (MM2S / S2MM)
  * AXI interconnect / SmartConnect
  * IIR Biquad AXI-Stream module
* Rebuilds address maps and clock/reset topology

---

## Intended Use

* Reference for how the module was **validated on real hardware**
* Documentation of **AXI system-level integration decisions**
* Optional starting point for users already familiar with Vivado BD flows

---

## What This Script Is Not

* ❌ A minimal build script
* ❌ A portable, tool-agnostic flow
* ❌ A replacement for proper project setup

Vivado-generated verbosity is intentionally preserved.

---

## Notes

* Bitstreams and generated outputs are **not versioned**
* Users are expected to adapt paths if recreating the project
* RTL functionality does **not depend** on this script

---

> This script documents integration decisions, not integration flexibility.
