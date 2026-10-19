`default_nettype none

module vector_post_processor_5px (
    input  wire        pixel_clk,              
    input  wire        reset_n,               
    input  wire [7:0]  active_col,           
    input  wire [6:0]  active_row,             
    
    input  wire        raw_street_hit,         
    input  wire        raw_priority_route_hit, 
    
    output reg         display_spi_mosi
);

    reg [2:0] street_pipe;
    reg [2:0] route_pipe;
    
    wire thick_street_pixel;
    wire thick_route_pixel;

    always @(posedge pixel_clk or negedge reset_n) begin
        if (!reset_n) begin
            street_pipe <= 3'b000;
            route_pipe  <= 3'b000;
        end else begin
            street_pipe <= {street_pipe[1:0], raw_street_hit};// raw_street_hit;
            route_pipe  <= {route_pipe[1:0],  raw_priority_route_hit};//raw_priority_route_hit;
        end
    end
    assign thick_street_pixel = raw_street_hit         || |street_pipe; 
    assign thick_route_pixel  = raw_priority_route_hit || |route_pipe;

    wire route_dash_pattern;
    reg [3:0] clock_occilator = 4'b0000; 
    always @(posedge pixel_clk or negedge reset_n) begin
        if (!reset_n) begin
            display_spi_mosi <= 1'b0;
        end else begin
            if (thick_route_pixel) begin
                display_spi_mosi <= 1'b1;//(clock_occilator <= 4'd8) ? (1'b1) : (1'b1); 
            end else if (thick_street_pixel) begin
                display_spi_mosi <= 1'b1; 
            end else begin
                display_spi_mosi <= 1'b0;
            end
        end
        clock_occilator <= clock_occilator + 4'd1; 
    end

endmodule
`default_nettype wire
