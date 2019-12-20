// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "defines.v"

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
    wire memInstWaiting, memLSwaiting;
    wire instEn;
    wire [`InstAddrBus] instAddr;
    wire instOutEn;
    wire [`InstBus] FetchInst;

    wire LSoutEn;
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
    wire [`TagRootBus]  freeTagALUroot;

    //output of dispatcher
    wire enRegWrt;
    wire [`NameBus] RegWrtName;
    wire [`TagBus]  RegWrtTag;

    wire ALUrsEn;
    wire [`DataBus] rsOperandO, rsOperandT;
    wire [`TagBus]  rsTagO, rsTagT, rsTagW;
    wire [`NameBus] rsNameW;
    wire [`OpBus]   rsOp;
    wire [`InstAddrBus] rsAddr;

    wire BranchRsEn;
    wire [`DataBus] rsImm;

    wire LSbufEn;

    //output of regf
    wire [`DataBus] regDataO, regDataT;
    wire [`TagBus] regTagO, regTagT;

    //output of ALUrs
    wire ALUworkEn, ALUfree;
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

    //output of BranchRS
    wire BranchWorkEn;
    wire[`DataBus] BranchOperandO, BranchOperandT, BranchImm;
    wire[`OpBus]  BranchOp;
    wire[`InstAddrBus] BranchPC;

    //output of Branch 
    wire BranchEn;
    wire[`InstAddrBus]  BranchAddr;

    //output of LSbuffer
    wire LSworkEn;
    wire[`DataBus] LSoperandO, LSoperandT, LSimm;
    wire[`TagBus] LSwrtTag;
    wire[`NameBus]  LSwrtName;
    wire[`OpBus]  LSop;
    wire LSbufFree;
    wire [`TagRootBus]  freeTagLSroot;

    //output of LS
    wire LSunwork;
    wire dataEn, LSRW;
    wire [`DataAddrBus] dataAddr;
    wire [`LenBus] LSlen;
    wire [`DataBus] Sdata;

    wire LSROBen, LSdone;
    wire [`DataBus] LSROBdata;
    wire [`TagBus]  LSROBtag;
    wire [`NameBus] LSROBname;

  //about icache
    wire hit, memfetchEn;
    wire [`InstBus] cacheInst;
    wire [`InstAddrBus] memfetchAddr;
    wire [`InstAddrBus] addAddr;
  icache icache(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in), 
    .fetchEn(instEn), 
    .Addr(instAddr), 
    .addEn(instOutEn), 
    .addInst(FetchInst), 
    .addAddr(addAddr), 
    .hit(hit), 
    .foundInst(cacheInst), 
    .memfetchEn(memfetchEn), 
    .memfetchAddr(memfetchAddr)
  );

  mem mcu(
    .clk(clk_in), 
    .rst(rst_in), 
    .rdy(rdy_in), 
    //with PC
      .fetchEn(memfetchEn), 
      .fetchAddr(memfetchAddr), 
    //output
      .instOutEn(instOutEn), 
      .inst(FetchInst), 
      .addAddr(addAddr), 
    //with LS
    .LSen(dataEn), 
    .LSRW(LSRW), //always 0 for read and 1 for write
    .LSaddr(dataAddr),
    .LSlen(LSlen), 
    .Sdata(Sdata), //is DataFree when it is read
    //output below
      .LSdone(LSoutEn), 
      .LdData(mcuLdata), 
    //with ram
      .RWstate(mem_wr), 
      .RWaddr(mem_a), 
      .ReadData(mem_din), 
      .WrtData(mem_dout)
  );

  assign stall = ~(ALUfree & LSbufFree);

  fetch fetcher(
      .clk(clk_in), 
      .rst(rst_in), 
      .rdy(rdy_in), 
      .stall(stall), 

      .enJump(jumpEn), 
      .JumpAddr(jumpAddr), 

      .enBranch(BranchEn), 
      .BranchAddr(BranchAddr),

    //to decoder
      .DecEn(DecEn), 
      .DecPC(ToDecAddr), 
      .DecInst(ToDecInst), 
    //with mem and cache
      .memInstOutEn(instOutEn), 
      .memInst(FetchInst), 

      .instEn(instEn), 
      .instAddr(instAddr), 
      .hit(hit), 
      .cacheInst(cacheInst)
  );

  decoder decoder(
    .clk(clk_in), 
    .rst(rst_in),
    .rdy(rdy_in), 
    .stall(stall), 
    .DecEn(DecEn), 
    .instPC(ToDecAddr),
    .inst(ToDecInst),

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

  Table Table(
      .clk(clk_in),
      .rst(rst_in), 
      .freeStatusALU(ALUfreeStatus), 
    //output
      .freeTagALU(freeTagALUroot)
  );

  dispatcher dispatcher(
    //from decoder
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
      .regTagO(regTagO), 
      .regDataO(regDataO), 
      .regTagT(regTagT), 
      .regDataT(regDataT), 
    //from Table
      .ALUfreeTag(freeTagALUroot), 
    //from LSbuffer
      .LSfreeTag(freeTagLSroot),
    //to regfile(rename the rd)
      .enWrt(enRegWrt), 
      .wrtTag(RegWrtTag), 
      .wrtName(RegWrtName), 
    //to ALUrs
      .ALUen(ALUrsEn), 
      .operandO(rsOperandO), 
      .operandT(rsOperandT), 
      .tagO(rsTagO), 
      .tagT(rsTagT),
      .tagW(rsTagW), 
      .nameW(rsNameW), 
      .op(rsOp), 
      .addr(rsAddr), 
    //to BranchRS
      .BranchEn(BranchRsEn), 
      .Imm(rsImm),
    //to LSbuffer
      .LSen(LSbufEn)
  );

  Regfile regf(
    .clk(clk_in), 
    .rst(rst_in), 
    .rdy(rdy_in), 
    // 
    .ALUwrtEn(ALUROBen), 
    .ALUwrtData(ALUROBdataW),
    .ALUwrtName(ALUROBnameW), 
    .ALUwrtTag(ALUROBtagW),
    .LSwrtEn(LSROBen), 
    .LSwrtData(LSROBdata),
    .LSwrtName(LSROBname), 
    .LSwrtTag(LSROBtag), 
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
    .rdy(rdy_in), 
    //from ALU and LS
      .enALUwrt(ALUROBen),
      .ALUtag(ALUROBtagW),
      .ALUdata(ALUROBdataW),
      .enLSwrt(LSROBen), 
      .LStag(LSROBtag), 
      .LSdata(LSROBdata), 
    //from dispatcher
      .ALUen(ALUrsEn), 
      .ALUoperandO(rsOperandO), 
      .ALUoperandT(rsOperandT), 
      .ALUtagO(rsTagO), 
      .ALUtagT(rsTagT),
      .ALUtagW(rsTagW),
      .ALUnameW(rsNameW), 
      .ALUop(rsOp), 
      .ALUaddr(rsAddr), 

    //to ALU
      .ALUworkEn(ALUworkEn), 
      .operandO(ALUoperandO), 
      .operandT(ALUoperandT),
      .wrtTag(ALUwrtTag), 
      .wrtName(ALUwrtName), 
      .opCode(ALUopCode), 
      .instAddr(ALUaddr), 
    //to dispatcher
      .ALUfree(ALUfree), 
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

  BranchRS BranchRS(
    .rst(rst_in), 
    .clk(clk_in), 
    .rdy(rdy_in), 
    //from ALU and LS
      .enALUwrt(ALUROBen),
      .ALUtag(ALUROBtagW),
      .ALUdata(ALUROBdataW),
      .enLSwrt(LSROBen), 
      .LStag(LSROBtag), 
      .LSdata(LSROBdata),
    //input from dispatcher
      .BranchEn(BranchRsEn), 
      .BranchOperandO(rsOperandO), 
      .BranchOperandT(rsOperandT), 
      .BranchTagO(rsTagO), 
      .BranchTagT(rsTagT), 
      .BranchOp(rsOp), 
      .BranchImm(rsImm), 
      .BranchPC(rsAddr),
    //to branchEx
      .BranchWorkEn(BranchWorkEn), 
      .operandO(BranchOperandO), 
      .operandT(BranchOperandT), 
      .imm(BranchImm), 
      .opCode(BranchOp), 
      .PC(BranchPC)
  );

  Branch Branch(
    //from the RS
      .BranchWorkEn(BranchWorkEn), 
      .operandO(BranchOperandO), 
      .operandT(BranchOperandT), 
      .imm(BranchImm), 
      .opCode(BranchOp), 
      .PC(BranchPC), 
    //to the PC
      .BranchResultEn(BranchEn), 
      .BranchAddr(BranchAddr)
  );

  lsBuffer lsBuffer(
    .rst(rst_in), 
    .clk(clk_in), 
    .rdy(rdy_in), 
    //from ALU and LS
      .enALUwrt(ALUROBen),
      .ALUtag(ALUROBtagW),
      .ALUdata(ALUROBdataW),
      .enLSwrt(LSROBen), 
      .LStag(LSROBtag), 
      .LSdata(LSROBdata),
    //input from dispatcher
      .LSen(LSbufEn), 
      .LSoperandO(rsOperandO), 
      .LSoperandT(rsOperandT), 
      .LStagO(rsTagO), 
      .LStagT(rsTagT), 
      .LStagW(rsTagW), 
      .LSnameW(rsNameW), 
      .LSop(rsOp), 
      .LSimm(rsImm), 
    //from the LS
    .LSreadEn(LSunwork), 
    .LSdone(LSoutEn),
    //to LS
    .LSworkEn(LSworkEn), 
    .operandO(LSoperandO), 
    .operandT(LSoperandT),
    .imm(LSimm), 
    .wrtTag(LSwrtTag), 
    .wrtName(LSwrtName), 
    .opCode(LSop), 
    //to dispatcher
    .LSfreeTag(freeTagLSroot),
    .LSbufFree(LSbufFree)
  );

  LS LS(
    .clk(clk_in), 
    .rst(rst_in), 
    .rdy(rdy_in), 

    //from lsbuffer
      .LSworkEn(LSworkEn), 
      .operandO(LSoperandO), 
      .operandT(LSoperandT),
      .imm(LSimm), 
      .wrtTag(LSwrtTag), 
      .wrtName(LSwrtName), 
      .opCode(LSop), 

    //to lsbuffer
     .LSunwork(LSunwork), 

    //with mem
      .LSoutEn(LSoutEn), 
      .Ldata(mcuLdata), 

      .dataEn(dataEn), 
      .LSRW(LSRW), 
      .dataAddr(dataAddr),
      .LSlen(LSlen), 
      .Sdata(Sdata),
      //to ROB
      .LSROBen(LSROBen), 
      .LSROBdata(LSROBdata), 
      .LSROBtag(LSROBtag), 
      .LSROBname(LSROBname), 
      .LSdone(LSdone)
  );
endmodule