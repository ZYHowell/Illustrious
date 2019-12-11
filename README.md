# fake RISC-V CPU
MS108, Computer Architecture project in ACM class

* (modified) Tomasulo algorithm (with ROB and branch bits)
* Pipeline: 4 stages
* A 512B I-cache (to be a 2-way associative)
* A 512B D-cache in another branch(todo in another branch)
* Branch Prediction(doing)
* Precise Interruption unsupported(to fix in another branch)
* Virtual memory, CSR(control and status register) instructions, timers and counters, environment call and breakpoints unsupported, so cannot run an OS on it. (no time to improve and cannot achieve on FPGA, so I give up)
* Pass Implementation(to improve)
* 100MHz for the version without ROB

The out-of-order execution can be easily observed at queen test, where store instructions run and ALU works simultaneously. 

References:

1. https://github.com/riscv-boom/riscv-boom, an out of order RISC-V CPU using chisel, with branch bits(named branch mask there)
2. http://www.kroening.com/diplom/diplom/main003.html, details about the hardware of Tomasulo Architecture.