# 🔋 Adaptive PAD Control with Power-Saving Modes

This repository contains the implementation of an **Adaptive PAD Control** architecture designed for low-power **System-on-Chip (SoC)** I/O interfaces. The design intelligently switches PAD behavior between multiple power modes — **Active**, **Sleep**, and **Deep-Sleep** — to reduce unnecessary dynamic and static power consumption.

Unlike conventional PADs that remain active throughout operation, this architecture integrates **power gating**, **data retention**, and **signal isolation** to achieve higher energy efficiency without impacting I/O functionality.

---

## 🧩 Key Features

✔ Adaptive PAD power modes: Active / Sleep / Deep-Sleep / Deep-Wake  
✔ **Power Management Unit (PMU)** controls state transitions  
✔ **Clock Management Unit (CMU)** ensures reset synchronization  
✔ **PAD Controller** retains state during low-power operation  
✔ Fully verified using **SystemVerilog testbench**  
✔ Accurate power reporting using **SAIF-based analysis in Vivado**  
✔ Achieved **~16% reduction** in total on-chip power vs. conventional PAD

---


---

## 🧪 Power Analysis Flow (Vivado)

1. Run behavioral simulation to generate **SAIF/VCD activity**
2. Load the SAIF into Vivado Power Analyzer
3. Generate accurate total on-chip power report
4. Compare **Adaptive vs Conventional PAD**

*SAIF-based results show ~16% power savings with Adaptive PAD Control.*

---

## 🖥️ Toolchain

| Tool | Purpose |
|------|---------|
| Vivado 2025 | RTL design, simulation, power analysis |
| Verilog HDL | RTL implementation |
| SystemVerilog | Testbench development |
| SAIF | Switching activity power measurement |

---

## 📊 Results Summary

| Design | Total On-Chip Power |
|--------|-------------------|
| Conventional PAD | 0.069 W |
| Adaptive PAD | 0.058 W |

➡ **~16% power reduction achieved**

---

## 📌 License

This project is released under the **MIT License**.  
You are free to modify and reuse with attribution.

---

### ⭐ If you found this useful, consider giving the repo a star!



