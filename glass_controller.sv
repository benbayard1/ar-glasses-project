
module glass_controller (
    input logic [189:0] packet [7:0]
); 

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

    wire w_raw_street_hit;
    wire w_raw_route_hit;
    wire w_display_mosi;

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



endmodule 