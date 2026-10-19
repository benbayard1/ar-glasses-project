`timescale 1ns/1ps
`default_nettype none

module parallel_canvas_engine (
    input  wire         pixel_clk,              
    input  wire         reset_n,                
    input  wire         start_frame,            
    
    input  wire [127:0] vertex_pool_x,          
    input  wire [127:0] vertex_pool_y,          
    input  wire [127:0] street_edges_flat,      
    input  wire [127:0] route_edges_flat,       
    
    input  wire [9:0]   active_col,             
    input  wire [9:0]   active_row,             
    
    output wire         pixel_done_out,         
    output wire         raw_street_hit,         
    output wire         raw_priority_route_hit  
);

    reg [3:0]  m;                       
    reg        step_phase;              

    wire [7:0] current_street_edge = street_edges_flat[m*8 +: 8];
    wire [7:0] current_route_edge  = route_edges_flat[m*8 +: 8];
    wire       is_route_channel    = (m < 5'd16);//

    wire       street_active_m = (current_street_edge != 8'h00);
    wire       route_active_m  = is_route_channel && (current_route_edge != 8'h00);

    wire [3:0] v0_idx = is_route_channel && route_active_m ? current_route_edge[7:4] : current_street_edge[7:4];
    wire [3:0] v1_idx = is_route_channel && route_active_m ? current_route_edge[3:0] : current_street_edge[3:0];

    wire [9:0] coord_x0 = {2'd0, vertex_pool_x[v0_idx*8 +: 8]};
    wire [9:0] coord_y0 = {2'd0, vertex_pool_y[v0_idx*8 +: 8]};
    wire [9:0] coord_x1 = {2'd0, vertex_pool_x[v1_idx*8 +: 8]};
    wire [9:0] coord_y1 = {2'd0, vertex_pool_y[v1_idx*8 +: 8]};

    wire [9:0] d_x = (coord_x1 >= coord_x0) ? (coord_x1 - coord_x0) : (coord_x0 - coord_x1);
    wire [9:0] d_y = (coord_y1 >= coord_y0) ? (coord_y1 - coord_y0) : (coord_y0 - coord_y1);
    wire [9:0] x_min = (coord_x0 < coord_x1) ? coord_x0 : coord_x1;
    wire [9:0] x_max = (coord_x0 < coord_x1) ? coord_x1 : coord_x0;
    wire [9:0] y_min = (coord_y0 < coord_y1) ? coord_y0 : coord_y1;
    wire [9:0] y_max = (coord_y0 < coord_y1) ? coord_y1 : coord_y0;

    reg [9:0]  local_x0, local_y0, local_dx, local_dy;
    reg [9:0]  local_x_min, local_x_max, local_y_min, local_y_max;
    reg        local_route_active, local_street_active;

    reg [9:0]  beam_dx, beam_dy;
    reg [19:0] v_lhs_mult, v_rhs_mult, mult_diff, scaled_tol;
    reg [9:0]  v_max_delta;

    reg        street_accum, route_accum;
    reg        final_street_hit, final_route_hit;
    reg        internal_pixel_done;

    always @(posedge pixel_clk or negedge reset_n) begin
        if (!reset_n) begin
            m <= 4'd0; 
            step_phase <= 1'b0;
            street_accum <= 1'b0; 
            route_accum <= 1'b0;
            final_street_hit <= 1'b0; 
            final_route_hit <= 1'b0;
            internal_pixel_done <= 1'b0;
            local_x0 <= 8'd0; 
            local_y0 <= 8'd0;
            local_dx <= 8'd0; 
            local_dy <= 8'd0;
            local_x_min <= 8'd0; 
            local_x_max <= 8'd0;
            local_y_min <= 8'd0; 
            local_y_max <= 8'd0;
            local_route_active <= 1'b0; 
            local_street_active <= 1'b0;
            beam_dx <= 8'd0; 
            beam_dy <= 8'd0;
            v_lhs_mult <= 16'd0; 
            v_rhs_mult <= 16'd0;
            mult_diff <= 16'd0; 
            v_max_delta <= 8'd0; 
            scaled_tol <= 16'd0;
        end else begin
            internal_pixel_done <= 1'b0;

            if (m == 4'd0 && step_phase == 1'b0) begin
                street_accum <= 1'b0;
                route_accum  <= 1'b0;
            end

            if (step_phase == 1'b0) begin
                local_street_active <= street_active_m;
                local_route_active  <= route_active_m;
                local_x0    <= coord_x0; 
                local_y0    <= coord_y0;
                local_dx    <= d_x;      
                local_dy    <= d_y;
                local_x_min <= x_min;    
                local_x_max <= x_max;
                local_y_min <= y_min;    
                local_y_max <= y_max;
                step_phase  <= 1'b1;
            end else begin
                beam_dx = (active_col >= local_x0) ? (active_col - local_x0) : (local_x0 - active_col);
                beam_dy = (active_row >= local_y0) ? (active_row - local_y0) : (local_y0 - active_row);

                v_lhs_mult = local_dy * beam_dx;
                v_rhs_mult = beam_dy * local_dx;
                mult_diff  = (v_lhs_mult >= v_rhs_mult) ? (v_lhs_mult - v_rhs_mult) : (v_rhs_mult - v_lhs_mult);
                v_max_delta = (local_dx > local_dy) ? local_dx : local_dy;
                scaled_tol  = {8'd0, v_max_delta};

                if (v_max_delta > 8'd0) begin
                    if ((active_col >= local_x_min) && (active_col <= local_x_max) && 
                        (active_row >= local_y_min) && (active_row <= local_y_max) &&
                        (mult_diff <= scaled_tol)) begin
                        if (!local_route_active && local_street_active) street_accum <= 1'b1;
                        if (local_route_active)                         route_accum  <= 1'b1;
                    end
                end

                if (m == 4'd15) begin
                    m <= 4'd0;
                    final_street_hit <= street_accum;
                    final_route_hit  <= route_accum;
                    internal_pixel_done <= 1'b1;
                end else begin
                    m <= m + 4'd1;
                end
                step_phase <= 1'b0;
            end
        end
    end

    assign pixel_done_out         = internal_pixel_done;
    assign raw_street_hit         = (!start_frame) ? final_street_hit : 1'b0;
    assign raw_priority_route_hit = (!start_frame) ? final_route_hit  : 1'b0;

endmodule
`default_nettype wire
