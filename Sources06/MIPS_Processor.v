/******************************************************************
* Description
*	This is the top-level of a MIPS processor
* This processor is written Verilog-HDL. Also, it is synthesizable into hardware.
* Parameter MEMORY_DEPTH configures the program memory to allocate the program to
* be execute. If the size of the program changes, thus, MEMORY_DEPTH must change.
* This processor was made for computer organization class at ITESO.
******************************************************************/


module MIPS_Processor
#(
	parameter MEMORY_DEPTH = 32
)

(
	// Inputs
	input clk,
	input reset,
	input [7:0] PortIn,
	// Output
	output [31:0] ALUResultOut,
	output [31:0] PortOut
);
//******************************************************************/
//******************************************************************/
assign  PortOut = 0;

//******************************************************************/
//******************************************************************/
// Data types to connect modules
wire BranchNE_wire;
wire BranchEQ_wire;
wire RegDst_wire;
wire NotZeroANDBrachNE;
wire ZeroANDBrachEQ;
wire MemtoReg_wire; // Cable sale de Control y es mi selector de MUx despés de RAM
wire MemWrite_wire; // Bandera de escritura RAM
wire MemRead_wire;  // Bandera de lectura RAM
wire [31:0] BranchAddr_wire;		 // Se shiftea 2 a la Izq.
wire [31:0] BranchAddrToMux_wire; // Se le suma el PC_4
wire [31:0] PC_4OrBranchAddr_wire;// Dirección del PC aumentada "normal" o por "branch"
wire [31:0] JumpAddr_wire;	 		 // Para dirección de JumpAddr
wire [31:0] PC4OrBranchAddr_OR_JumpAddr_wire;// Salida del MUX PC4 or Branch or Jump
wire [31:0] ALUOrRam_AND_RegA_wire;				// ALU o RAM o ra para escribir en el RegisterFile
wire [31:0] PC4OrBranchOrJump_OR_RegA_wire;
wire BranchEQOrBranchNE_wire;		// -> Entra a la Hazard Unit: se activó un branch
wire ORForBranch;
wire ALUSrc_wire;
wire RegWrite_wire;
//wire Zero_wire;	// Ahora se usará con una EXOR
wire Jump_wire;
wire Jal_wire;
wire Jr_wire;
wire Jump_OR_Jal_wire;
wire [3:0] ALUOp_wire;			// Lo cambiamos de 3bits a 4bits
wire [3:0] ALUOperation_wire;
wire [4:0] WriteRegister_wire;
wire [4:0] WriteRegisterFINAL_wire;	// Registro final a escribir
wire [4:0] Direction_RA_wire;			// Tiene la $ra address return
wire [31:0] MUX_PC_wire;		// Declaré el wire "pero no se usa"
wire [31:0] PC_wire;				// Declaré el wire
wire [31:0] Instruction_wire;
wire [31:0] ReadData1_wire;
wire [31:0] ReadData2_wire;
wire [31:0] InmmediateExtend_wire;
wire [31:0] ReadData2OrInmmediate_wire;
wire [31:0] ALUResult_wire;
wire [31:0] PC_4_wire;
wire [31:0] ALUResultOrRamData_wire;	// Salida de MUX después de Ram
wire [31:0] RamData_wire;					// Salida de la RAM
integer ALUStatus;

////////////////////////		
// wire [63:0] IF_ID_Salidas;		// Etapa de IF/ID	
wire [31:0] IF_ID_PC4_wire;
wire [31:0] IF_ID_Instruction_wire;
////////////////////////		
wire [31:0] ID_EX_PC4_wire;		// Etapa de ID/EX
wire [31:0] ID_EX_Instruction_wire; // Solo para debug	
wire [31:0] ID_EX_RD1_wire;
wire [31:0] ID_EX_RD2_wire;
wire [31:0] ID_EX_SignExt_wire;		// Es el cable de InmmediateExtend_wire
wire [4:0]  ID_EX_rt_wire;
wire [4:0]	ID_EX_rd_wire;
wire ID_EX_RegWrite_wire;	 // -> WB
wire ID_EX_MemtoReg_wire;	 //	 " "
wire ID_EX_MemWrite_wire;	 // -> Mem
wire ID_EX_MemRead_wire;	 //  " "
wire ID_EX_RegDst_wire;		 // -> EX
wire ID_EX_ALUSrc_wire;		 //  " "
wire [3:0] ID_EX_ALUOp_wire;// " "

////////////////////////
wire [31:0] EX_MEM_PC4_wire;		// Etapa de EX/MEM
wire [31:0] EX_MEM_Instruction_wire; // Solo para debug
wire [31:0] EX_MEM_ALUResult_wire;
wire [31:0] EX_MEM_RD2_OR_ForwardB_wire; // EX_MEM_RD2_wire; <- cambio por Forwarding
wire [4:0]  EX_MEM_WriteRegister_wire;
wire EX_MEM_RegWrite_wire;	// -> WB
wire EX_MEM_MemtoReg_wire;	//	 " "
wire EX_MEM_MemWrite_wire;	// -> Mem
wire EX_MEM_MemRead_wire;	//  " "
////////////////////////
wire [31:0]	MEM_WB_RamData_wire;	// Etapa de MEM/WB
wire [31:0] MEM_WB_Instruction_wire; // Solo para debug
wire [31:0] MEM_WB_ALUResult_wire; 	 // Aún con Forwarding sigue siendo este cable
wire [4:0] MEM_WB_WriteRegister_wire;
wire MEM_WB_RegWrite_wire;	// -> WB
wire MEM_WB_MemtoReg_wire;	//  " "

//////////////// FORWARDING UNIT ////////////////
wire [1:0] ForwardA_wire;
wire [1:0] ForwardB_wire;
wire [31:0] RD1_OR_ForwardA_wire;
wire [31:0] RD2_OR_ForwardB_wire;

//////////////// Hazard Detection Unit ////////////////
wire PCWrite_wire;
wire IF_ID_Write_wire;
wire sel_bubble_wire;
wire sel_flush_wire;		// Para beq, bne jump, jal

//wire RegDst_zero;		// banderas que anulan para NOP salen del mux
wire BranchNE_zero;
wire BranchEQ_zero;
//wire MemtoReg_zero;
wire MemWrite_zero;
//wire MemRead_zero;
//wire ALUSrc_zero;
wire RegWrite_zero;
wire Jump_zero;
wire Jal_zero;
wire Jr_zero;
//wire [3:0] ALUOp_zero;
wire ID_EX_BranchNE_zero;	// banderas que salen de la etapa ID_EX
wire ID_EX_BranchEQ_zero;
wire ID_EX_Jump_zero;
wire ID_EX_Jal_zero;
wire ID_EX_Jr_zero;

wire [31:0] InstructionOrPreset_wire;
wire [31:0]  Exor; // Este es mi restador
wire Zero_Exor;


//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/
Register_posedge
#(
	.N(64)		// Porque PC+4= 32bits y InstWire= 32bits
)
Reg1_IF_ID
(
	.clk(clk),
	.reset(reset),
	.enable(1 && IF_ID_Write_wire),	// Modificado con señal de la Hazard Unit para insertar Nop
	.DataInput ({ PC_4_wire,		InstructionOrPreset_wire }),
	.DataOutput({ IF_ID_PC4_wire, IF_ID_Instruction_wire   })
);
//assign IF_ID_PC4_wire = IF_ID_Salidas[63:32];			// Parte alta
//assign IF_ID_Instruction_wire = IF_ID_Salidas[31:0];	// Parte baja
//******************************************************************/
Register_posedge
#(					// IF_ID_PC + 4			= 32 bits
	.N(185)		// RD1 , RD2		= 64 bits
)					// SignExt			= 32 bits
Reg2_ID_EX				// Rt y rd 		= 10 bits - no se ocupo: 6 bits(funct)
(					// Señales Control= 10 bits
	.clk(clk),
	.reset(reset),
	.enable(1'b1),	//Ahora Tarea#11_...Se modificará a futuro																				// 	rt									//		rd																																																			 // Estas banderas me queda duda de que etapa se deben jalar a los circuitos combinacionales
	.DataInput ({ IF_ID_PC4_wire, IF_ID_Instruction_wire, ReadData1_wire, ReadData2_wire, InmmediateExtend_wire, IF_ID_Instruction_wire[20:16], IF_ID_Instruction_wire[15:11], RegWrite_zero,		   MemtoReg_wire,		   MemWrite_zero,		   MemRead_wire,		  RegDst_wire,		   ALUSrc_wire,		 ALUOp_wire,		 BranchNE_zero, 		 BranchEQ_zero, 		 Jump_zero, 		Jal_zero, 		 Jr_zero			}),
	.DataOutput({ ID_EX_PC4_wire, ID_EX_Instruction_wire, ID_EX_RD1_wire, ID_EX_RD2_wire, ID_EX_SignExt_wire,    ID_EX_rt_wire,                 ID_EX_rd_wire,                 ID_EX_RegWrite_wire, ID_EX_MemtoReg_wire, ID_EX_MemWrite_wire, ID_EX_MemRead_wire, ID_EX_RegDst_wire, ID_EX_ALUSrc_wire, ID_EX_ALUOp_wire, ID_EX_BranchNE_zero, ID_EX_BranchEQ_zero, ID_EX_Jump_zero, ID_EX_Jal_zero, ID_EX_Jr_zero })
);
//******************************************************************/
Register_posedge
#(					// ID_EX_PC + 4		= 32 bits		
	.N(137)		// ALUresult			= 32 bits
)					// RD2					= 32 bits
Reg3_EX_MEM		// WriteRegister		= 5 bits
(					// Señales Control	= 4 bits
	.clk(clk),
	.reset(reset),
	.enable(1'b1),	//Ahora Tarea#11_...Se modificará a futuro								// cambio por Forwarding
	.DataInput ({ BranchAddrToMux_wire, ID_EX_Instruction_wire,  ALUResult_wire, 		   RD2_OR_ForwardB_wire,		  WriteRegister_wire,		  ID_EX_RegWrite_wire,  ID_EX_MemtoReg_wire,		ID_EX_MemWrite_wire,  ID_EX_MemRead_wire  }),
	.DataOutput({ EX_MEM_PC4_wire, 		EX_MEM_Instruction_wire, EX_MEM_ALUResult_wire, EX_MEM_RD2_OR_ForwardB_wire, EX_MEM_WriteRegister_wire, EX_MEM_RegWrite_wire, EX_MEM_MemtoReg_wire,	EX_MEM_MemWrite_wire, EX_MEM_MemRead_wire })
);
//******************************************************************/
Register_posedge
#(
	.N(103)		// RAM_RD				= 32 bits
)					// RAM_address			= 32 bits
Reg4_MEM_WB		// EX_MEM_WirteRegister	= 5 bits	
(					// Señales de control	= 2 bits
	.clk(clk),
	.reset(reset),
	.enable(1'b1),	//Ahora Tarea#11_...Se modificará a futuro // NO hay cambio de ALUresult por ForwardingB
	.DataInput ({ RamData_wire, 		  EX_MEM_Instruction_wire, EX_MEM_ALUResult_wire,	EX_MEM_WriteRegister_wire,	EX_MEM_RegWrite_wire, EX_MEM_MemtoReg_wire }),
	.DataOutput({ MEM_WB_RamData_wire, MEM_WB_Instruction_wire, MEM_WB_ALUResult_wire,	MEM_WB_WriteRegister_wire,	MEM_WB_RegWrite_wire, MEM_WB_MemtoReg_wire })
);
//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/

//////// MUX para anular Control Values e insertar bubble a partir de ID_EX///////
Multiplexer2to1
#(
	.NBits(7)
)
MUX_ForControlValuesOr_0s
(			
	.Selector ( sel_bubble_wire ),	// Viene de Hazard Unit
	.MUX_Data0( { RegWrite_wire, MemWrite_wire, BranchNE_wire, BranchEQ_wire, Jump_wire, Jal_wire, Jr_wire } ), // banderas de control
	.MUX_Data1( 7'b000_0000			  ), // Esto anula las señales de la instrucción
	
	.MUX_Output({ RegWrite_zero, MemWrite_zero, BranchNE_zero, BranchEQ_zero, Jump_zero, Jal_zero, Jr_zero } )

);
////////////////////////////

Control
ControlUnit
(
	.OP(IF_ID_Instruction_wire[31:26]),
	.FUNCT(IF_ID_Instruction_wire[5:0]),	// Nuevo para detectar Jr una etapa antes para que funcione en la Hazard UNit
	.RegDst(RegDst_wire),
	.BranchNE(BranchNE_wire),
	.BranchEQ(BranchEQ_wire),
	.MemtoReg(MemtoReg_wire),	//Añadi mi selector para MUX después de RAM
	.MemWrite(MemWrite_wire),	// Bandera para escribir en RAM
	.MemRead(MemRead_wire),		// Bandera para leer de la RAM
	.ALUSrc(ALUSrc_wire),		// Añadí la coma final
	.RegWrite(RegWrite_wire),
	.Jump(Jump_wire),	// selector de jump
	.Jal(Jal_wire),	// selector de jal
	.Jr(Jr_wire),
	.ALUOp(ALUOp_wire)
);
//

////////// Forwarding Unit //////////
ForwardingUnit
ForwardUnit
(					

	.ID_EX_rs_i(ID_EX_Instruction_wire[25:21]),		// ID_EX_rs_wire
	.ID_EX_rt_i(ID_EX_rt_wire),
	.EX_MEM_rd_i(EX_MEM_WriteRegister_wire),
	.MEM_WB_rd_i(MEM_WB_WriteRegister_wire),
	.EX_MEM_RegWrite_i(EX_MEM_RegWrite_wire),
	.MEM_WB_RegWrite_i(MEM_WB_RegWrite_wire),
	.ForwardA_o(ForwardA_wire),	// selector de mux
	.ForwardB_o(ForwardB_wire)		// selector de mux

);
//

////////// Hazard Detection Unit //////////
HazardDetectionUnit
HazardUnit
(
	.ID_EX_MemRead_i(ID_EX_MemRead_wire),			// Se activa con lw
	.IF_ID_Rs_i(IF_ID_Instruction_wire[25:21]),	// rs
	.IF_ID_Rt_i(IF_ID_Instruction_wire[20:16]),	// rt
	.ID_EX_Rt_i(ID_EX_rt_wire),						// rt
	.BranchEQOrBranchNE_i(BranchEQOrBranchNE_wire),	// equivalente a beq | bne
	.Jump_OR_Jal_i(Jump_OR_Jal_wire),		 			// equivalente a jal | jr
	.Jr_i(Jr_zero),	// le pasamos bandera salida de control y mux con 0	
	.PCWrite_o(PCWrite_wire),		 	 // enable de PC
	.IF_ID_Write_o(IF_ID_Write_wire), // enable de Register IF/ID
	.sel_bubble_o(sel_bubble_wire),	 // selector de mux para poner 0's a las banderas de control
	.IF_ID_Flush_o(sel_flush_wire)	 // selector de muxPreseteado entre ROM y registro IF/ID	

);
//

////////// PRIMER Mux 3a 1 de 32 bits //////////
Mux_3to1
#(
	.NBits(32)
)
Mux_ThreeToOne
(	
	.Selector(ForwardA_wire),
	.MUX_Data0(ID_EX_RD1_wire),
	.MUX_Data1(ALUResultOrRamData_wire),	// MEM/WB
	.MUX_Data2(EX_MEM_ALUResult_wire),		// EX/MEM
	
	.MUX_Output(RD1_OR_ForwardA_wire)
);
//

////////// SEGUNDO Mux 3a 1 de 32 bits //////////
Mux_3to1
#(
	.NBits(32)
)
Mux_ThreeToOne2
(	
	.Selector(ForwardB_wire),
	.MUX_Data0(ID_EX_RD2_wire),
	.MUX_Data1(ALUResultOrRamData_wire),	// MEM/WB
	.MUX_Data2(EX_MEM_ALUResult_wire),		// EX/MEM
	
	.MUX_Output(RD2_OR_ForwardB_wire)	// Error corregido:
);													// va a 1 mux2a_1 antes de la ALU
//



////////// Señal de Brach ////////
ANDGate	
ANDBeq_minusZero
(							// Si es instruccion beq & la salida de la ALU es Zero hay que hacer BRANCH_EQ
	.A(BranchEQ_zero),
	.B(Zero_Exor),		// Zero_wire = 1 cuando la resta es igual a 0
	.C(ZeroANDBrachEQ)
);
//
ANDGate
ANDBne_Zero
(							// Si es instruccion bne & la salida de la ALU es "NO" es Zero hay que hacer BRANCH_NE
	.A(BranchNE_zero),
	.B(~Zero_Exor),
	.C(NotZeroANDBrachNE)
);
// OR para detectar si hubo uno de los 2 branches
assign BranchEQOrBranchNE_wire = ZeroANDBrachEQ | NotZeroANDBrachNE;	
//
//////////////////////////////////
PC_Register			// Añadimos la instacia del...
#(						//... Contador de Programa
	.N(32)
)
ProgramCounter

(
	.clk(clk),
	.reset(reset),
	.enable(1 && PCWrite_wire), // Añadimos el enable y que sea con señal de Hazard Unit
	.NewPC(PC4OrBranchOrJump_OR_RegA_wire),	// Entra la salida del Sumador de 4bytes "futuro cambio con Branch la salida del MUX"
	.PCValue(PC_wire)									// La salida del PC va a la ROM
);
//

/////////////// ROM //////////////
ProgramMemory
#(
	.MEMORY_DEPTH(128)			//	.MEMORY_DEPTH(MEMORY_DEPTH) cte???
)
ROMProgramMemory
(
	.Address(PC_wire),
	.Instruction(Instruction_wire)
);
//

////////// ROM con "PRESET" //////////
Multiplexer2to1
#(
	.NBits(32)
)
MUX_ForPRESET
(			
	.Selector ( sel_flush_wire ),	// Viene de Hazard Unit
	.MUX_Data0( { Instruction_wire } ), // Viene de ROM
	.MUX_Data1( 32'h0000_0000		   ), // NOP -> no hace nada 
	
	.MUX_Output({ InstructionOrPreset_wire} )

);
////////////////////////////

Adder32bits
PC_Puls_4
(
	.Data0(PC_wire),
	.Data1(4),
	
	.Result(PC_4_wire)
);
//

////////// Sumador para BranchAddress //////////
Adder32bits
PC_BranchAddr
(
	.Data0(BranchAddr_wire),
	.Data1(IF_ID_PC4_wire),		// antes sin saltos: (PC_4_wire),
	
	.Result(BranchAddrToMux_wire) // va al registro EX/MEM y luego al mux antes de PC
);
//

////////// Mux para PC_4 o BranchAddress //////////
Multiplexer2to1
#(
	.NBits(32)
)
MUX_ForPC_4AndBranchAddr
(			// Escoge el segundo operando:
	.Selector(BranchEQOrBranchNE_wire),
	.MUX_Data0(PC_4_wire),						// PC normal
	.MUX_Data1(BranchAddrToMux_wire), 				//(EX_MEM_PC4_wire), = PC + Branch
	
	.MUX_Output(PC_4OrBranchAddr_wire)
);
//
//////////////////////////////////////////////////////////////
assign JumpAddr_wire = {  PC_4_wire[31:28], {IF_ID_Instruction_wire[25:0], 2'b00}	};		//{InstructionOrPreset_wire[25:0], 2'b00}	};

assign Jump_OR_Jal_wire = Jump_zero | Jal_zero;
////////// Mux para PC_4ORBranchAddress OR JumpAddr //////////
Multiplexer2to1
#(
	.NBits(32)
)
MUX_ForPC4ORBranchAddr_AND_JumpAddr
(
	.Selector(Jump_OR_Jal_wire),
	.MUX_Data0(PC_4OrBranchAddr_wire),				// PC+4_OR_BranchAddr
	.MUX_Data1(JumpAddr_wire - 32'h_0040_0000),	//	JumpAddr
	
	.MUX_Output(PC4OrBranchAddr_OR_JumpAddr_wire)
);
//

////////// Mux para PC_4ORBranchAddressORJumpAddr OR $ra //////////
Multiplexer2to1
#(
	.NBits(32)
)
MUX_ForPC4ORBranchAddrORJumpAddr_AND_RegA
(
	.Selector(Jr_zero),				//Sale de Control antes salía de ALUControl
	.MUX_Data0(PC4OrBranchAddr_OR_JumpAddr_wire),	// PC+4_OR_BranchAddr OR JumpAddr
	.MUX_Data1(ReadData1_wire),	//	$ra, para regresar el PC y está en rs
	
	.MUX_Output(PC4OrBranchOrJump_OR_RegA_wire) 		// Para sacar el $ra
);
//
//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/
//******************************************************************/
Multiplexer2to1
#(
	.NBits(5)
)
MUX_ForRTypeAndIType
(											// Escoge el registro de destino:
	.Selector(ID_EX_RegDst_wire),	// new RegDst de la etapa de ID_EX
	.MUX_Data0(ID_EX_rt_wire),	// rt -> Format_I 	Etapa ID/EX: Instruction_wire[20:16]
	.MUX_Data1(ID_EX_rd_wire),	// rd -> Rormat_R		Etapa ID/EX: Instruction_wire[15:11]
	
	.MUX_Output(WriteRegister_wire)

);
//
/////////////////////////////////
assign Direction_RA_wire = 5'b1_1111; // direccion de $ra = 31 hex = 11111 bin
/////////////////////////////////
Multiplexer2to1
#(
	.NBits(5)
)
MUX_ForRTypeAndIType_AND_RegA
(				// Escoge el registro de destino:
	.Selector(Jal_zero),	
	.MUX_Data0(WriteRegister_wire),	// rt -> Format_I   o   rd -> Rormat_R
	.MUX_Data1(Direction_RA_wire),			// dirección de $ra
	
	.MUX_Output(WriteRegisterFINAL_wire)

);
//


RegisterFile
Register_File
(
	.clk(clk),
	.reset(reset),
	.RegWrite(MEM_WB_RegWrite_wire),	// new viene de etapa de MEM/WB
	.WriteRegister(MEM_WB_WriteRegister_wire),	// new from MEM/WB		//(WriteRegisterFINAL_wire),	// Registro FINAL 
	.ReadRegister1(IF_ID_Instruction_wire[25:21]),	// Vienen del primer register rs
	.ReadRegister2(IF_ID_Instruction_wire[20:16]),	// x2 y rt
	.WriteData(ALUOrRam_AND_RegA_wire),	// CAMBIAR POR SALIDA DE 3 MUXes -> YA!!!
	.ReadData1(ReadData1_wire),	// rs
	.ReadData2(ReadData2_wire)		// rt
);
//

assign Exor = ( ReadData1_wire ^ ReadData2_wire );	// Esta linea es nuestro restador en etapa IF/ID
assign Zero_Exor = ( Exor  == 0 ) ? 1'b1 : 1'b0; // Se activa cuando la diferencia dio 0 


SignExtend
SignExtendForConstants
(   
	.DataInput(IF_ID_Instruction_wire[15:0]),
   .SignExtendOutput(InmmediateExtend_wire)
);
////// Inmmediate_ShiftLeft_2bits  //////
assign BranchAddr_wire = InmmediateExtend_wire << 2;		// Shiftea la salida del ID/EX
/////////////////////////////////////////

Multiplexer2to1
#(
	.NBits(32)
)
MUX_ForReadDataAndInmediate
(			// Escoge el segundo operando:
	.Selector(ID_EX_ALUSrc_wire),		// new ALUsrc del PipeLine
	.MUX_Data0(RD2_OR_ForwardB_wire),// Etapa de ID/EX		//viene del PipeLine	// Registro B = rt
	.MUX_Data1(ID_EX_SignExt_wire),	//viene del PipeLine	//	Registro B = Inmediato
	
	.MUX_Output(ReadData2OrInmmediate_wire)

);
//

ALUControl
ArithmeticLogicUnitControl
(
	.ALUOp(ID_EX_ALUOp_wire),	// new ALUOp de la etapa ID_EX
	.ALUFunction(ID_EX_SignExt_wire[5:0]),		// 6 bits de FUNCT - Tarea11
//	.Jr(Jr_wire),
	.ALUOperation(ALUOperation_wire)

);
//

ALU
ArithmeticLogicUnit 
(
	.ALUOperation(ALUOperation_wire),
	.A(RD1_OR_ForwardA_wire),					// new conection
	.B(ReadData2OrInmmediate_wire),
	.shamt(ID_EX_Instruction_wire[10:6]),	//  sale del PIPE_3 los bits del 10:6 de shamt para hacer sll y srl
//	.Zero(Zero_wire),
	.ALUResult(ALUResult_wire)
);
//

///////// 	RAM	//////////	Instanciar: DataMemory.v
DataMemory 
#(	
	.DATA_WIDTH(32),		// (8) Mis datos del MIPS son de 32bits
	.MEMORY_DEPTH(256)	// (1024)...localidades se ajustan a HANOI  -  (256)...mínimo para Datos y Stack con multiplo de 8
)
RAMDataMemory					// nombre de la instancia
(
	.WriteData(EX_MEM_RD2_OR_ForwardB_wire),	// Rt para escribirlo si uso SW
	.Address( (EX_MEM_ALUResult_wire  &  32'h0000_FFFF) >> 2 ),	// La suma de Rs(dirección) + SignExt(cte.offset) es mi ... >> 2 para juntar las direcciones de los discos en RAM (antes iban de 4 en 4)
	.MemWrite(EX_MEM_MemWrite_wire),	// new from EX/MEM			// ...dirección de 32bits; con mascara para dejar solo los 16 bits LSB
	.MemRead(EX_MEM_MemRead_wire),
	.clk(clk),
	.ReadData(RamData_wire)	// Dato de RAM
);
////////////////////////////

//////// MUX sw O lw ///////
Multiplexer2to1
#(
	.NBits(32)
)
MUX_ForALUResultAndRamData
(			// Escoge el segundo operando:
	.Selector(MEM_WB_MemtoReg_wire),	// new from MEM/WB	 // Bandera de Control
	.MUX_Data0(MEM_WB_ALUResult_wire),// NO hay cambio de ALUresult por ForwardingB// Registro B = rt
	.MUX_Data1(MEM_WB_RamData_wire),	//	Dato de RAM
	
	.MUX_Output(ALUResultOrRamData_wire)

);
////////////////////////////

//////// MUX para $ra ///////
Multiplexer2to1
#(
	.NBits(32)
)
MUX_ForALUResultORRamData_AND_RegA
(			// Escoge el segundo operando:
	.Selector(Jal_zero),	// Bandera de Control
	.MUX_Data0(ALUResultOrRamData_wire),// ALU o RAM -> direccion calculada de salto
	.MUX_Data1(PC_4_wire),				// PC + 8
	
	.MUX_Output(ALUOrRam_AND_RegA_wire)	// ALU RAM RegA

);
////////////////////////////

assign ALUResultOut = ALUResult_wire;


endmodule

