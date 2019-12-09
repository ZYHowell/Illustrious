# RISC-V
Architecture(1st semester) homework in ACM class

* (modified) Tomasulo algorithm (with branch bits and ROB)
* 3 or 4 stage(depends on the type of instruction, since ALU needs ROB)
* A 512B I-cache (to be a 2-way associative)
* A 512B D-cache in another branch(todo in another branch)
* Branch Prediction(todo)
* Precise Interruption unsupported(to fix in another branch)
* Pass Implementation(to improve)

The out-of-order execution can be easily observed at gcd test(-O), the 199~219th instructions, where store instructions runs when ALU works simultaneously. 

Based on:

1. https://github.com/riscv-boom/riscv-boom, an out of order RISC-V CPU using chisel;
2. http://www.kroening.com/diplom/diplom/main003.html, details about the hardware of Tomasulo Architecture.