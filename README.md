###  fake RISC-V CPU
MS108, Computer Architecture project in ACM class

Version A: (the most innovative one)

* (modified) Tomasulo algorithm (with ROB and branch bits)
* Pipeline: 4 stages
* A 512B I-cache, direct mapped
* Branch Prediction supported(working)
* Precise Interruption unsupported
* Aim: pass implementation(the delay is too high even if it is on FPGA)
* The aim of this version is to explore how conditional execution and branch bits works in modern CPU(which is condition code in modern instruction sets), and the organization is **really really too complex**. 

Version B: (need to speed up)

* Basic Tomasulo algorithm (without ROB)
* Pipeline: 3 stages
* A 512B I-cache, direct mapped
* Branch Policy: stall
* Precise Interruption unsupported
* Pass Implementation
* This version aims to explore some tricks to speed up, but since branch&jump instruction appears frequently, the CPU frequently stalls, making it slower than a normal 5-pipeline.  (and actually not very Out-of-Order)

For all these versions above: 

* Virtual memory, CSR(control and status register) instructions, timers and counters, environment call and breakpoints unsupported, so cannot run an OS on it. (no time to improve and cannot achieve on FPGA, so I give up)

* The main problem is that FPGA cannot make sense when the structure becomes complex, so the frequency needs to slow down, making complex design unable to work well(Even a global&local branch prediction with a 512B I-cache can make the delay too high). 

Summary: 

* The most interesting thing I notice(though not the most important) is that the restriction comes from the situation that when adding a new instruction into the RS, the ready will be correct a cycle later, making the instruction without any hazard wait for a cycle. This leads to an innovation of my design. (Which is the only improvement of this work in the field of organization rather than architecture)

References:

1. https://github.com/riscv-boom/riscv-boom, an out of order RISC-V CPU using chisel, with branch bits(named branch mask there)
2. http://www.kroening.com/diplom/diplom/main003.html, details about the hardware of Tomasulo Architecture.