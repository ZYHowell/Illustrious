`include "defines.v"

module Regfile(
    input wire clk, 
    input wire rst, 

    input wire enWrite, 
    input wire [] writeName, 
    input wire [] writeData, 
    input wire [] writeTag, 

    input wire enReadO, 
    input wire [] readNameO, 
    input wire [] readDataO, 
    input wire [] readTagO, 

    input wire enReadT, 
    input wire [] readNameT, 
    input wire [] readDataT, 
    input wire [] readTagT 
)

    always @ (posedge clk) begin
      if (rst) begin
        
      end else begin
        if (enWrite) begin
          
        end
      end
    end

endmodule 