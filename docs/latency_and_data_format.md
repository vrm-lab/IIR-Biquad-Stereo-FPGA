# Latency & Data Format

This document defines the **timing behavior** and **numeric formats** used by the IIR Biquad module.

---

## Data Format Summary

| Signal         | Format | Width         |
| -------------- | ------ | ------------- |
| Input samples  | Q1.15  | 16-bit signed |
| Coefficients   | Q1.15  | 16-bit signed |
| Accumulator    | Q2.30  | Internal wide |
| Output samples | Q1.15  | 16-bit signed |

All arithmetic is signed two's complement.

---

## Latency

* **Core latency:** 1 clock cycle
* **AXI wrapper latency:** 0 cycles
* **Total latency:** fixed and deterministic

Latency does not depend on coefficient values or input data.

---

## Saturation Behavior

* Output is saturated to the Q1.15 range:

  * +32767
  * −32768

* No wrap-around occurs at the output stage

---

## Throughput

* One sample per clock when `tvalid && tready`
* No internal FIFO or elastic buffering

---

## Timing Determinism

* No variable latency paths
* No hidden pipeline stages
* Suitable for cycle-accurate system integration

---

## Design Implication

Because latency is fixed and known, this module can be safely composed with other DSP blocks without additional alignment logic.
