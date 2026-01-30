# Design Rationale — IIR Biquad

This document explains the **key design decisions** behind the IIR Biquad implementation.

The goal is to clarify *why* the design looks the way it does.

---

## Why a Second-Order Biquad?

* Widely used canonical DSP building block
* Efficient for FPGA implementation
* Flexible enough to implement LPF, HPF, shelving, and peaking filters

A single biquad stage provides a good balance between:

* Resource usage
* Numerical stability
* Expressiveness

---

## Fixed-Point Arithmetic

The design uses **Q1.15 fixed-point** arithmetic for:

* Input samples
* Coefficients
* Output samples

Reasons:

* Matches common audio sample formats
* Predictable overflow behavior
* Efficient mapping to FPGA DSP blocks

---

## Accumulator Width

* Internal accumulation uses a wider accumulator (Q2.30)
* Prevents intermediate overflow
* Allows clean saturation at the output stage

---

## Damping Term

A small damping term is applied to the feedback path:

```
y1 <= y_next − (y_next >>> N)
```

Purpose:

* Reduce limit-cycle oscillation
* Improve long-term stability in fixed-point

This is an intentional design trade-off.

---

## Core vs Wrapper Separation

The design is explicitly split into:

* **DSP Core**
  Pure arithmetic, no bus logic

* **AXI Wrapper**
  Streaming, control, and protocol handling

This separation improves:

* Readability
* Reusability
* Verification clarity

---

## Non-Goals

This design intentionally avoids:

* Dynamic reconfiguration logic
* Parameter-heavy generic IP patterns
* Adaptive or self-tuning behavior

The focus is on **clarity and determinism**.
