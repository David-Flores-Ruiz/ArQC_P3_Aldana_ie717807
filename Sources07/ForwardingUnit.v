/******************************************************************
					// Módulo de la Forwarding Unit  //
* Description: Aquí solucionamos la dependencia de datos ya que, 
* cuando una instrucción quiere leer un registro que está en la 
* instrucción anterior, por las etapas del pipeline todavía no se
* escribe el nuevo dato pero en la etapa en que nosotros ya sabemos
* el resultado se lo pasamos para que opere con él.

******************************************************************/

module ForwardingUnit
(					// Nombres en el TOP:
	input [4:0] ID_EX_rs_i,			// ID_EX_rs_wire
	input [4:0] ID_EX_rt_i,			// ID_EX_rt_wire
	input [4:0] EX_MEM_rd_i,		// EX_MEM_WriteRegister_wire
	input [4:0] MEM_WB_rd_i,		// MEM_WB_WriteRegister_wire
	input EX_MEM_RegWrite_i, 			// EX_MEM_RegWrite_wire
	input MEM_WB_RegWrite_i,			// MEM_WB_RegWrite_wire
	
	output reg [1:0] ForwardA_o,	// selector de mux
	output reg [1:0] ForwardB_o	// selector de mux

);
//

always@(*)begin

	if 		(	(EX_MEM_RegWrite_i) && (EX_MEM_rd_i != 0) && (EX_MEM_rd_i == ID_EX_rs_i)	)
		begin
			 ForwardA_o = 2'b10;	// 2 en binario para selector
		end
	else if  (	(MEM_WB_RegWrite_i) && (MEM_WB_rd_i != 0) && (EX_MEM_rd_i != ID_EX_rs_i) && (MEM_WB_rd_i == ID_EX_rs_i) )
		begin
			 ForwardA_o = 2'b01;	// 1 en bin para sel
		end
	else // ELSE
		begin 
			 ForwardA_o = 2'b00;	// 0 en bin	"No hay Hazard (dependencia) de datos"
		end

		
	
	if 		(	(EX_MEM_RegWrite_i) && (EX_MEM_rd_i != 0) && (EX_MEM_rd_i == ID_EX_rt_i)	)
		begin
			 ForwardB_o = 2'b10;	// 2 en binario para selector
		end
	else if  (	(MEM_WB_RegWrite_i) && (MEM_WB_rd_i != 0) && (EX_MEM_rd_i != ID_EX_rt_i) && (MEM_WB_rd_i == ID_EX_rt_i) )
		begin
			 ForwardB_o = 2'b01;	// 1 en bin para sel
		end
		
	else	// ELSE
		begin

			 ForwardB_o = 2'b00;	// 0 en bin	" No hay Hazard "
		end
end
//

endmodule
