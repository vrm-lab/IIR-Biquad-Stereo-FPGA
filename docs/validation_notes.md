# Validation Notes

This document summarizes how the IIR Biquad design was verified.

---

## Verification Scope

Verification focuses on:

* Functional correctness
* Fixed-point numerical behavior
* AXI protocol compliance

It does **not** attempt exhaustive corner-case coverage.

---

## Testbenches

Two testbenches are provided:

1. **Core-level testbench**

   * Exercises the DSP arithmetic directly
   * Uses synthetic audio-like input
   * Logs input/output to CSV

2. **AXI-integrated testbench**

   * Programs coefficients via AXI-Lite
   * Streams stereo samples via AXI-Stream
   * Verifies handshake and ordering

---

## Observed Behavior

* Correct filtering behavior for LPF- and HPF-like coefficient sets
* Stable operation during runtime coefficient updates
* No data corruption under backpressure

---

## Hardware Validation

The RTL has been validated on FPGA using:

* PYNQ-based control and streaming

Hardware validation is used to confirm:

* Timing closure viability
* Real-world protocol behavior

---

## Limitations

* Coefficient stability must be ensured by the user
* No automatic overflow detection beyond saturation

---

## Conclusion

The verification performed is sufficient to establish this design as a **reliable reference implementation** within its intended scope.
