
module packet_parser (
    input logic packet_signal; 
    input logic [199:0] input_packet [7:0]; 

    output logic [2:0] input_type; 

    output logic [127:0] t_vertex_pool_x;
    output logic [127:0] t_vertex_pool_y;
    output logic [127:0] t_street_edges_flat;
    output logic [127:0] t_route_edges_flat;
); 

assign input_type = input_packet[2:0];

always_ff(posedge packet_signal) begin 
    if (input_type = 3'd0) begin 
        t_vertex_pool_x = input_packet[129 +: 128]; 
        t_vertex_pool_y = input_packet[257 +: 128]; 
        t_street_edges_flat = input_packet[385 +: 128]; 
        t_route_edges_flat = input_packet[513 +: 128]; 
    end else 
    if (input_type = 3'd1) begin 
        
    end 
end


endmodule