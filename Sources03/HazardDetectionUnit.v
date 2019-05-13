/******************************************************************
					// Módulo de la Hazard Detection Unit  //
* Description: Aquí debemos resolver cuando meter un NOP o STALL
* a través del Pipeline, controlando los enable de los registros
* y tambíen haciendo FLUSH para eliminar instrucciones no deseadas
* por saltos y que se alcanzaron a introducir en el Pipe.

******************************************************************/

module HazardDetectionUnit
(					// Nombres en el TOP:
	input ID_EX_MemRead_i,		// ID_EX_MemRead_wire
	input [4:0] IF_ID_Rs_i,				// IF_ID_Instruction_wire[25:21]  // rs
	input [4:0] IF_ID_Rt_i,				// IF_ID_Instruction_wire[20:16]	 // rt
	
	input [4:0] ID_EX_Rt_i,				// ID_EX_rt_wire						 // rt
	
	output reg PCWrite_o,		// enable de PC
	output reg IF_ID_Write_o,	// enable de Register IF/ID
	output reg sel_bubble_o		// selector de mux para poner 0's a las banderas de control

);
//

always@(*)begin

	if 		(	(ID_EX_MemRead_i) 
				 && (ID_EX_Rt_i == IF_ID_Rs_i)  )	
		begin
			 PCWrite_o = 1'b0;		// No se escriba el PC+4
			 IF_ID_Write_o = 1'b0;  // Para que No lea la sig. instrucción
			 sel_bubble_o = 1'b1; 	// Insertar 0's en las señales de COntrol (Stall)
		end
		
	else if  (	(ID_EX_MemRead_i)
				 && (ID_EX_Rt_i == IF_ID_Rt_i)  )
		begin
			 PCWrite_o = 1'b0;		// No se escriba el PC+4
			 IF_ID_Write_o = 1'b0;  // Para que No lea la sig. instrucción
			 sel_bubble_o = 1'b1; 	// Insertar 0's en las señales de COntrol (Stall)
		end
		
	else // ELSE
		begin
			 PCWrite_o = 1'b1;		// activa "como antes" 
			 IF_ID_Write_o = 1'b1;  // x2
			 sel_bubble_o = 1'b0; 	// x3
		end

end
//

endmodule
