/******************************************************************
* Description
*	This is  a ROM memory that represents the program memory. 
* 	Internally, the memory is read without a signal clock. The initial 
*	values (program) of this memory are written from a file named text.dat.
* Version:
*	1.0
* Author:
*	Dr. José Luis Pizano Escalante
* email:
*	luispizano@iteso.mx
* Date:
*	01/03/2014
******************************************************************/
module ProgramMemory
#
(
	parameter MEMORY_DEPTH=32,
	parameter DATA_WIDTH=32
)
(
	input [(DATA_WIDTH-1):0] Address,
	output reg [(DATA_WIDTH-1):0] Instruction
);
wire [(DATA_WIDTH-1):0] RealAddress;

assign RealAddress = {2'b0,Address[(DATA_WIDTH-1):2]};

	// Declare the ROM variable
	reg [DATA_WIDTH-1:0] rom[MEMORY_DEPTH-1:0];

	initial
	begin																								// ver7... Success: JAL , J , BEQ , BNE 
		$readmemh("C:/MIPSProjects/MIPSProcessor_ver8/Sources/text.dat", rom);	// cambiar a _ver8 HAZARD + Pruebas de Jr y "HANOI"
	end

	always @ (RealAddress)
	begin
		Instruction = rom[RealAddress];
	end

endmodule
//programmemory