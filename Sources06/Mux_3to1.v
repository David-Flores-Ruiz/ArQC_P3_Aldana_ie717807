/******************************************************************
				  // MUX 3 a 1 con entradas de 32 bits  //
* Description: Aquí cargamos el dato correspondiente al:
* Data del Register File ("Cuando no hay forwarding")
* Forward de MEM/WB
* Forward de EX/MEM
******************************************************************/

module Mux_3to1
#(
	parameter NBits=32
)
(
	input [1:0] Selector,
	input [NBits-1:0] MUX_Data0,
	input [NBits-1:0] MUX_Data1,
	input [NBits-1:0] MUX_Data2,
	
	output reg [NBits-1:0] MUX_Output

);
//

always@(Selector,MUX_Data0,MUX_Data1,MUX_Data2) begin	
	case(Selector)
		0: MUX_Output = MUX_Data0;	// Data del Register File
		1:	MUX_Output = MUX_Data1; // Forward de MEM/WB
		2: MUX_Output = MUX_Data2; // Forward de EX/MEM
		default: MUX_Output = 32'd0;
	endcase
end
//

endmodule