# AXI-Lite Address Map — IIR Biquad

This document describes the **AXI-Lite register map** used to control and configure the IIR Biquad module.

The register interface is intentionally minimal and deterministic.

---

## Address Map Overview

| Address | Name | Description                |
| ------: | ---- | -------------------------- |
|    0x00 | CTRL | Control register           |
|    0x04 | B0   | Feedforward coefficient b0 |
|    0x08 | B1   | Feedforward coefficient b1 |
|    0x0C | B2   | Feedforward coefficient b2 |
|    0x10 | A1   | Feedback coefficient a1    |
|    0x14 | A2   | Feedback coefficient a2    |

All registers are **32-bit wide**. Only the **lower 16 bits** are used for coefficient storage.

---

## CTRL Register (0x00)

|  Bit | Name       | Description                           |
| ---: | ---------- | ------------------------------------- |
|    0 | ENABLE     | Enables streaming and core processing |
|    1 | SOFT_RESET | Clears internal filter state          |
| 31:2 | —          | Reserved (write as 0)                 |

### Notes

* `SOFT_RESET` is synchronous and clears internal delay registers
* `ENABLE` gates both AXI-Stream dataflow and core computation

---

## Coefficient Registers

* Format: **Q1.15 signed fixed-point**
* Stored in bits `[15:0]` of each register
* Upper bits are ignored

### Sign Convention

The implemented difference equation is:

```
y[n] = b0·x[n] + b1·x[n−1] + b2·x[n−2]
       − a1·y[n−1] − a2·y[n−2]
```

Coefficient signs must be programmed accordingly.

---

## Design Intent

This register map is designed for:

* Simple software drivers
* Deterministic behavior
* Easy inspection via AXI-Lite tools

It is **not intended** to be a feature-rich control interface.
