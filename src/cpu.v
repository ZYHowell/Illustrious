// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	  input  wire					        rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)

	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read takes 2 cycles(wait till next cycle), write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

    wire stall;
    //output of mem
    wire instEn;
    wire [`InstAddrBus] instAddr;
    wire instOutEn, mcuInstPortFree;
    wire [`InstBus] FetchInst;

    wire LOutEn, mcuLSportFree;
    wire [`DataBus] mcuLdata;

    //output of fetcher
    wire DecEn;
    wire [`InstAddrBus] ToDecAddr;
    wire [`InstBus] ToDecInst;

    //output of decoder
    wire [`NameBus] DecNameO, DecNameT, DecRdName;
    wire [`OpBus] DecOp;
    wire [`OpClassBus]  DecOpClass;
    wire [`InstAddrBus] DecAddr;
    wire [`DataBus] DecImm, DecUimm, DecJimm, DecSimm, DecBimm;

    //output of Table
    wire [`TagRootBus]  freeTagALUroot, freeTagLSroot;

    //output of dispatcher
    wire enRegWrt;
    wire [`NameBus] RegWrtName;
    wire [`TagBus]  RegWrtTag;

    wire ALUrsEn;
    wire [`DataBus] ALUrsOperandO, ALUrsOperandT;
    wire [`TagBus]  ALUrsTagO, ALUrsTagT, ALUrsTagW;
    wire [`NameBus] ALUrsNameW;
    wire [`OpBus]   ALUrsOp;
    wire [`InstAddrBus] ALUrsAddr;

    wire BranchRsEn;
    wire [`DataBus] BranchRsOperandO, BranchRsOperandT, BranchRsImm;
    wire [`TagBus]  BranchRsTagO, BranchRsTagT;
    wire [`OpBus]   BranchRsOp;
    wire [`InstAddrBus] BranchRsAddr;

    wire LSbufEn;
    wire [`DataBus] LSbufOperandO, LSbufOperandT, LSbufImm;
    wire [`TagBus]  LSbufTagO, LSbufTagT, LSbufTagW;
    wire [`NameBus] LSbufNameW;
    wire [`OpBus]   LSbufOp;

    //output of regf
    wire [`DataBus] regDataO, regDataT;
    wire [`TagBus] regTagO, regTagT;

    //output of ALUrs
    wire ALUworkEn;
    wire [`DataBus] ALUoperandO, ALUoperandT;
    wire [`TagBus]  ALUwrtTag;
    wire [`NameBus] ALUwrtName;
    wire [`OpBus]   ALUopCode;
    wire [`InstAddrBus] ALUaddr;
    wire [`rsSize - 1 : 0]  ALUfreeStatus;

    //output of ALU
    wire ALUROBen;
    wire[`TagBus] ALUROBtagW;
    wire[`DataBus] ALUROBdataW;
    wire[`NameBus] ALUROBnameW;
    wire jumpEn;
    wire [`InstAddrBus] jumpAddr;
    //
  mem mcu(
    .clk(clk_in), 
    .rst(rst_in), 
    //with PC
    .instEn(instEn), 
    .instAddr(instAddr), 
      //output
    .instOutEn(instOutEn), 
    .inst(FetchInst), 
    .instFree(mcuInstPortFree), 
    //with LS
    .dataEn(), 
    .LSRW(), //always 0 for read and 1 for write
    .dataAddr(),
    .LSlen(), 
    .Sdata(), 
      //is DataFree when it is read
      //output below
    .LOutEn(LOutEn), 
    .Ldata(mcuLdata), 
    .LSfree(mcuLSportFree), 
    //with ram
    .RWstate(mem_wr), 
    .RWaddr(mem_a), 
    .ReadData(mem_din), 
    .WrtData(mem_dout)
  );

  assign stall = !(ALUfreeStatus && ROBfreeStatus && LSfreeStatus);

  fetch fetcher(
    .clk(clk_in), 
    .rst(rst_in), 
    .stall(stall), 

    .enJump(), 
    .JumpAddr(), 

    .enBranch(), 
    .BranchAddr(),

    //to decoder
    .DecEn(DecEn), 
    .PC(ToDecAddr), 
    .inst(ToDecInst), 
    //with mem
    .memInstFree(mcuInstPortFree), 
    .memInstOutEn(instOutEn), 
    .memInst(FetchInst), 

    .instEn(instEn), 
    .instAddr(instAddr)
  );

  decoder decoder(
    .clk(clk_in), 
    .rst(rst_in),
    .DecEn(DecEn), 
    .instPC(DecPC),
    .inst(DecInst),

    //simply output everything to the dispatcher
    .regNameO(DecNameO), 
    .regNameT(DecNameT), 
    .rdName(DecRdName),
    .opCode(DecOp), 
    .opClass(DecOpClass),
    .instAddr(DecAddr), 
    .imm(DecImm), 
    .Uimm(DecUimm), 
    .Jimm(DecJimm), 
    .Simm(DecSimm), 
    .Bimm(DecBimm)
  );

  Table table(
    .rst(rst_in), 
    .freeStatusALU(), 
    .freeStatusLS(),
    //output
    .freeTagALU(freeTagALUroot), 
    .freeTagLS(freeTagLSroot)
  );

  dispatcher dispatcher(
    //from decoder
      .regNameO(DecNameO), 
      .regNameT(DecNameT), 
      .rdName(DecRdName),
      .opCode(DecOp),
      .opClass(DecOpClass),
      .instAddr(DecAddr), 
      .imm(DecImm), 
      .Uimm(DecUimm), 
      .Jimm(DecJimm), 
      .Simm(DecSimm), 
      .Bimm(DecBimm), 
    //from regfile
      .regTagO(), 
      .regDataO(), 
      .regTagT(), 
      .regDataT(), 
    //from ALUrs(), which tag is avaliable
      .ALUfreeStatus(),
    //from LSbuffer(), which tag is avaliable
      .LSfreeStatus(),

    //to regfile(rename the rd)
      .enWrt(enRegWrt), 
      .wrtTag(RegWrtTag), 
      .wrtName(RegWrtName), 
    //to ALUrs
      .ALUen(ALUrsEn), 
      .ALUoperandO(ALUrsOperandO), 
      .ALUoperandT(ALUrsOperandT), 
      .ALUtagO(ALUrsTagO), 
      .ALUtagT(ALUrsTagT),
      .ALUtagW(ALUrsTagW), 
      .ALUnameW(ALUrsNameW), 
      .ALUop(ALUrsOp), 
      .ALUaddr(ALUrsAddr), 
    //to BranchRS
      .BranchEn(BranchRsEn), 
      .BranchOperandO(BranchRsOperandO), 
      .BranchOperandT(BranchRsOperandT), 
      .BranchTagO(BranchRsTagO), 
      .BranchTagT(BranchRsTagT), 
      .BranchOp(BranchRsOp), 
      .BranchImm(BranchRsImm),
      .BranchAddr(BranchRsAddr),  
    //to LSbuffer
      .LSen(LSbufEn), 
      .LSoperandO(LSbufOperandO), 
      .LSoperandT(LSbufOperandT), 
      .LStagO(LSbufTagO), 
      .LStagT(LSbufTagT),
      .LStagW(LSbufTagW), 
      .ALUnameW(LSbufNameW), 
      .LSimm(LSbufImm), 
      .LSop(LSbufOp)
  );

  Regfile regf(
    .clk(clk_in), 
    .rst(rst_in), 
    //from CDB
    .enCDBWrt(), 
    .CDBwrtName(), 
    .CDBwrtData(), 
    .CDBwrtTag(), 
    //from decoder
    .regNameO(DecNameO), 
    .regNameT(DecNameT), 
    //from dispatcher
    .enWrtDec(enRegWrt), 
    .wrtTagDec(RegWrtTag), 
    .wrtNameDec(RegWrtName), 
    //to dispatcher
    .regDataO(regDataO), 
    .regTagO(regTagO), 
    .regDataT(regDataT), 
    .regTagT(regTagT)
  );

  ALUrs ALUrs(
    .rst(rst_in),
    .clk(clk_in),
    //from CDB
    .enCDBwrt(),
    .CDBTag(),
    .CDBData(),
    
    //from dispatcher
    .ALUen(ALUrsEn), 
    .ALUoperandO(ALUrsOperandO), 
    .ALUoperandT(ALUrsOperandT), 
    .ALUtagO(ALUrsTagO), 
    .ALUtagT(ALUrsTagT),
    .ALUtagW(ALUrsTagW),
    .ALUnameW(ALUrsNameW), 
    .ALUop(ALUrsOp), 
    .ALUaddr(ALUrsAddr), 

    //to ALU
    .ALUworkEn(ALUworkEn), 
    .operandO(ALUoperandO), 
    .operandT(ALUoperandT),
    .wrtTag(ALUwrtTag), 
    .wrtName(ALUwrtName), 
    .opCode(ALUopCode), 
    .instAddr(ALUaddr), 
    //to dispatcher
    .ALUfreeStatus(ALUfreeStatus)
  );

  ALU ALU(
    //from RS
    .ALUworkEn(ALUworkEn), 
    .operandO(ALUoperandO), 
    .operandT(ALUoperandT), 
    .wrtTag(ALUwrtTag), 
    .wrtName(ALUwrtName), 
    .opCode(ALUopCode), 
    .instAddr(ALUaddr),
    //to ROB
    .ROBen(ALUROBen), 
    .ROBtagW(ALUROBtagW), 
    .ROBdataW(ALUROBdataW),
    .ROBnameW(ALUROBnameW), 
    //to PC
    .jumpEn(jumpEn), 
    .jumpAddr(jumpAddr)
  );

  module BranchRS(
    .rst(rst_in), 
    .clk(clk_in), 
    //input from CDB
    .enCDBwrt(), 
    .CDBTag(), 
    . CDBData(), 
    //input from dispatcher
    .BranchEn(BranchRsEn), 
    .BranchOperandO(BranchOperandO), 
    .BranchOperandT(BranchOperandT), 
    .BranchTagO(BranchRsTagO), 
    .BranchTagT(BranchRsTagT), 
    .BranchOp(BranchRsOp), 
    .BranchImm(BranchRsImm), 
    .BranchPC(BranchRsAddr),
    //to branchEx
    .BranchWorkEn(), 
    .operandO(), 
    .operandT(), 
    .imm(), 
    .opCode(), 
    .PC(), 
    //to dispatcher
    .BranchFreeStatus()
  );

  module Branch(
    //from the RS
    .BranchWorkEn(), 
    .operandO(), 
    .operandT(), 
    .imm(), 
    .opCode(), 
    .PC(), 
    //to the PC
    .BranchResultEn(), 
    .BranchAddr()
  );

  module lsBuffer(
    .rst(rst_in), 
    .clk(clk_in), 
    //input from CDB
    .enCDBwrt(), 
    .CDBTag(), 
    . CDBData(), 
    //input from dispatcher
    .LSen(LSbufEn), 
    .LSoperandO(LSbufOperandO), 
    .LSoperandT(LSbufOperandT), 
    .LStagO(LSbufTagO), 
    .LStagT(LSbufTagT), 
    .LStagW(LSbufTagW), 
    .LSnameW(LSbufNameW), 
    .LSop(LSbufOp), 
    .LSimm(LSbufImm), 
    //from the LS
    .LSreadEn(), 
    //to LS
    .LSworkEn(), 
    .operandO(), 
    .operandT(),
    .imm(), 
    .wrtTag(), 
    .wrtName(), 
    .opCode(), 
    //to dispatcher
    .LSfreeStatus()
  );

  module LS(
    .clk(clk_in), 
    .rst(rst_in), 

    //from lsbuffer
    .LSworkEn(), 
    .operandO(), 
    .operandT(),
    .imm(), 
    .wrtTag(), 
    .wrtName(), 
    .opCode(), 

    //to lsbuffer
    .LSreadEn(), 

    //with mem
    .LOutEn(LOutEn), 
    .Ldata(mcuLdata), 
    .LSfree(mcuLSportFree), 

    .dataEn(), 
    .LSRW(), 
    .dataAddr(),
    .LSlen(), 
    .Sdata(),
    //to ROB
    .LS()
  );

  module ROB(
    .clk(clk_in), 
    .rst(rst_in), 
    //input from alu
    .ROBenW(), 
    .ROBtagW(), 
    .ROBdataW(), 
    .ROBnameW(), 
    //input from LS
    
    //output
    .enCDBWrt(), 
    .CDBwrtName(), 
    .CDBwrtTag(), 
    .CDBwrtData(), 
    .ROBfreeStatus()
  );
endmodule