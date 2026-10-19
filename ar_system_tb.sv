`timescale 1ns/1ps
`default_nettype none

module tb_graphics_pipeline;

    reg clk;
    reg rst_n;
    reg start_frame;
    reg [9:0] t_col;
    reg [9:0] t_row;
    wire pixel_processing_done; 

    reg [127:0] t_vertex_pool_x;
    reg [127:0] t_vertex_pool_y;
    reg [127:0] t_street_edges_flat;
    reg [127:0] t_route_edges_flat;

    //packet 
    logic input_type; 

    wire w_raw_street_hit;
    wire w_raw_route_hit;
    wire w_display_mosi;

    packet_parser uut_parser (
        .packet_signal(1), 
        .input_packet(), 
        .input_type(input_type),
        .t_vertex_pool_x(t_vertex_pool_x),
        .t_vertex_pool_y(t_vertex_pool_y),
        .t_street_edges_flat(t_street_edges_flat),
        .t_route_edges_flat(t_route_edges_flat)
    );

    parallel_canvas_engine uut_renderer (
        .pixel_clk(clk),
        .reset_n(rst_n),
        .start_frame(start_frame),
        .vertex_pool_x(t_vertex_pool_x),
        .vertex_pool_y(t_vertex_pool_y),
        .street_edges_flat(t_street_edges_flat),
        .route_edges_flat(t_route_edges_flat),
        .active_col(t_col),
        .active_row(t_row),
        .raw_street_hit(w_raw_street_hit),
        .raw_priority_route_hit(w_raw_route_hit), 
        .pixel_done_out(pixel_processing_done)
    );

    vector_post_processor_5px uut_shifter (
        .pixel_clk(clk),
        .reset_n(rst_n),
        .active_col(t_col),
        .active_row(t_row),
        .raw_street_hit(w_raw_street_hit),
        .raw_priority_route_hit(w_raw_route_hit),
        .display_spi_mosi(w_display_mosi)
    );

    always #41 clk = ~clk; 

    integer pixel_file;
    integer r_idx, c_idx;
    integer hit_count;

    initial begin
        clk = 0; 
        // Initialize simulation waveform dumping logs
        $dumpfile("pipeline_simulation.vcd");
        $dumpvars(0, tb_graphics_pipeline);

        // Open a flat text logging file to store coordinates for your Python visual lens
        pixel_file = $fopen("pixel_stream.txt", "w");
        hit_count = 0;

        clk = 0; rst_n = 0; start_frame = 0; t_col = 0; t_row = 0;
        t_vertex_pool_x = 128'd0; t_vertex_pool_y = 128'd0;
        t_street_edges_flat = 128'd0; t_route_edges_flat = 128'd0;

        #200 rst_n = 1; 
        #100;

        t_vertex_pool_x[0*8 +: 8]   = 8'd00;  
        t_vertex_pool_y[0*8 +: 8]   = 8'd11;

        t_vertex_pool_x[1*8 +: 8]   = 8'd54;  
        t_vertex_pool_y[1*8 +: 8]   = 8'd11;

        t_vertex_pool_x[2*8 +: 8]   = 8'd54;  
        t_vertex_pool_y[2*8 +: 8]   = 8'd63;

        t_vertex_pool_x[3*8 +: 8]   = 8'd00;  
        t_vertex_pool_y[3*8 +: 8]   = 8'd63;

        t_vertex_pool_x[4*8 +: 8]   = 8'd20;  
        t_vertex_pool_y[4*8 +: 8]   = 8'd15;

        t_vertex_pool_x[5*8 +: 8]   = 8'd20;  
        t_vertex_pool_y[5*8 +: 8]   = 8'd30;

        t_vertex_pool_x[6*8 +: 8]   = 8'd40;  
        t_vertex_pool_y[6*8 +: 8]   = 8'd15;

        t_vertex_pool_x[7*8 +: 8]   = 8'd40;  
        t_vertex_pool_y[7*8 +: 8]   = 8'd30;

        t_vertex_pool_x[8*8 +: 8]   = 8'd10;  
        t_vertex_pool_y[8*8 +: 8]   = 8'd40;

        t_vertex_pool_x[9*8 +: 8]   = 8'd27;  
        t_vertex_pool_y[9*8 +: 8]   = 8'd50;

        t_vertex_pool_x[10*8 +: 8]   = 8'd44;  
        t_vertex_pool_y[10*8 +: 8]   = 8'd40;

        
        t_street_edges_flat[0*8 +: 8] = 8'h01; 
        t_street_edges_flat[1*8 +: 8] = 8'h12; 
        t_street_edges_flat[2*8 +: 8] = 8'h23; 
        t_street_edges_flat[3*8 +: 8] = 8'h30; 

        t_street_edges_flat[4*8 +: 8] = 8'h45; 
        t_street_edges_flat[5*8 +: 8] = 8'h67; 

        t_street_edges_flat[6*8 +: 8] = 8'h89; 
        t_street_edges_flat[7*8 +: 8] = 8'h9A; 
        
    
        t_street_edges_flat[127:96]    = 32'd0;
        t_route_edges_flat             = 128'd0;
        #100;

        @(posedge clk);
        start_frame = 1; 
        @(posedge clk);
        start_frame = 0;
        #100;


        for (r_idx = 0; r_idx < 64; r_idx = r_idx + 1) begin
                        @(posedge clk);
            t_row = r_idx;
            t_col = 10'd639; 
            
            @(posedge clk);
                    
            for (c_idx = 0; c_idx < 128; c_idx = c_idx + 1) begin
                
                t_col = c_idx;
                
                @(posedge clk);
                while (!pixel_processing_done) begin
                    @(posedge clk);
                end
                
                @(negedge clk);
                if (w_display_mosi) begin
                    $fwrite(pixel_file, "%0d,%0d\n", t_row, t_col);
                    hit_count = hit_count + 1;
                end
            end
        end

        $fclose(pixel_file);

        $finish;
    end

endmodule
`default_nettype wire
