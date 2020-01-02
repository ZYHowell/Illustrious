###  Fake RISC-V CPU
MS108, Computer Architecture project in ACM class. Just try something new instead of simply copying seniors' designs. 

**pitfall** *Bigger and dumber is better.* 

**pitfall** *Sometimes smarter is better than bigger and dumber.* 

#### Feature

* (modified) Tomasulo algorithm (with ROB and branch bits)
* Pipeline: 4 stages
* A 1KiB I-cache, directly mapped
* A write-back D-cache supported
* Branch prediction supported and virtual regfile to support it. Branch prediction policy is Gshare
* Precise Interruption unsupported
* Running on FPGA with 80MHz, and higher frequency is also supported
* The aim is to explore how branch bits work. Though BOOM has already taped out a CPU with such branch bits, the organization is **really complex for a homework.** <font size=1>I've found that some reg are not needed, which the vivado opt can often notice too, but it is deceived by the codes in chaos. </font>

#### Mention: 

* Virtual memory, CSR(control and status register) instructions, timers and counters, environment call and breakpoints unsupported, so cannot run an OS on it. (no time to improve and cannot achieve on FPGA, so I give up)

* The main problem is that my FPGA cannot make sense when the structure becomes complex, so the frequency needs to slow down, making complex design unable to work well(Even a global&local branch prediction with a 512B I-cache can make the delay too high). 

#### Summary: 

* The most interesting thing I notice(though not the most important) is that the restriction comes from the situation that when adding a new instruction into the RS, the ready will be correct a cycle later, making the instruction without any hazard wait for a cycle. This leads to an innovation of my design. (Which is the only improvement of this work in the field of organization rather than architecture)

* The biggest problem is that I do not understand how Vivado works to design, even simply removing some register may lead to a  higher delay, and, the strangest, **more LUT**. <font size=1>This shows up in the following condition: in version A, I notice that I repeat calculating something in 32 units(see the head, tag and nxtTag in regfile/regfileLine), but if I calculate this outside and sends the result to each unit, The LUT useage increases so much that I have to give up this idea. </font>

#### Remark: 

* I've also tried some more complex cache designs and branch predictions, but they may not work well on the testbench (or be restricted by the FPGA), so I remove them and left a copy in the /backup/Units. 

#### References:

1. https://github.com/riscv-boom/riscv-boom, an out of order RISC-V CPU using chisel, with branch bits(named branch mask there)
2. http://www.kroening.com/diplom/diplom/main003.html, details about the hardware of Tomasulo Architecture.
