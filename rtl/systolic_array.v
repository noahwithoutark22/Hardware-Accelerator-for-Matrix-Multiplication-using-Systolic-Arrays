`timescale 1ns / 1ps
module systolic_array (
    input clk, reset, compute_start,
    input signed [16*64-1:0] buf_a_flat,  
    input signed [16*64-1:0] buf_b_flat,  
    output reg signed [2047:0] result_flat, 
    output reg done
);
    parameter GRID_SIZE = 4;
    parameter STEPS = 4;
    reg signed [31:0] accum [0:63];
    reg signed [63:0] a_shift [0:15];
    reg signed [63:0] b_shift [0:15];
    reg [1:0] state;
    reg [2:0] step;
    reg signed [31:0] result [0:7][0:7];
    wire signed [127:0] partial_c [0:GRID_SIZE-1][0:GRID_SIZE-1];
    function [15:0] get_bufa(input integer row, input integer col);
        get_bufa = buf_a_flat[{((row)*8 + (col))*16} +: 16];
    endfunction
    function [15:0] get_bufb(input integer row, input integer col);
        get_bufb = buf_b_flat[{((row)*8 + (col))*16} +: 16];
    endfunction
    function integer accum_idx;
        input integer ri, cj, m, n;
        accum_idx = (ri*GRID_SIZE + cj)*4 + (m*2 + n);
    endfunction
    genvar gi, gj;
    generate
        for (gi = 0; gi < GRID_SIZE; gi = gi + 1) begin : row_gen
            for (gj = 0; gj < GRID_SIZE; gj = gj + 1) begin : col_gen
                mul_2x2 mul_inst (
                    .clk(clk),
                    .a(a_shift[gi*GRID_SIZE ]),
                    .b(b_shift[/*gi*GRID_SIZE*/ + gj]),
                    .c(partial_c[gi][gj])
                );
            end
        end
    endgenerate
    integer x, y, idx;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= 0;
            step <= 0;
            done <= 0;
            for (idx = 0; idx < 64; idx = idx + 1) begin
                accum[idx] <= 0;
            end
            for (idx = 0; idx < 16; idx = idx + 1) begin
                a_shift[idx] <= 0;
                b_shift[idx] <= 0;
            end
        end else begin
            case (state)
            0: begin 
                if (compute_start) begin
                    state <= 1;
                    step <= 0;
                    for (idx = 0; idx < 64; idx = idx + 1) begin
                        accum[idx] <= 0;
                    end
                    done <= 0;
                end
            end
            1: begin
                for (x = 0; x < GRID_SIZE; x = x + 1) begin
                    for (y = 0; y < GRID_SIZE; y = y + 1) begin
                        idx = x*GRID_SIZE + y;
                        a_shift[idx] <= {
                            get_bufa(x*2+1, step*2+y*2+1),
                            get_bufa(x*2+1, step*2+y*2),
                            get_bufa(x*2,   step*2+y*2+1),
                            get_bufa(x*2,   step*2+y*2)
                        };
                        b_shift[idx] <= {
                            get_bufb(step*2+x*2+1, y*2+1),
                            get_bufb(step*2+x*2+1, y*2),
                            get_bufb(step*2+x*2,   y*2+1),
                            get_bufb(step*2+x*2,   y*2)
                        };
                    end
                end
                state <= 2;
            end
            2: begin
                for (x = 0; x < GRID_SIZE; x = x + 1) begin
                    for (y = 0; y < GRID_SIZE; y = y + 1) begin
                        idx = accum_idx(x, y, 0, 0);
                        accum[idx]   <= accum[idx]   + partial_c[x][y][31:0];
                        accum[idx+1] <= accum[idx+1] + partial_c[x][y][63:32];
                        accum[idx+2] <= accum[idx+2] + partial_c[x][y][95:64];
                        accum[idx+3] <= accum[idx+3] + partial_c[x][y][127:96];
                    end
                end
                if (step < STEPS - 1 ) begin
                    for (x = 0; x < GRID_SIZE; x = x + 1) begin
                        for (y = GRID_SIZE - 1; y > 0; y = y - 1) begin
                            a_shift[x*GRID_SIZE + y] <= a_shift[x*GRID_SIZE + y - 1];
                        end
                        a_shift[x*GRID_SIZE] <=  a_shift[x*GRID_SIZE + 3];
                    end
                    for (y = 0; y < GRID_SIZE; y = y + 1) begin
                        for (x = GRID_SIZE - 1; x > 0; x = x - 1) begin
                            b_shift[x*GRID_SIZE + y] <= b_shift[(x-1)*GRID_SIZE + y];
                        end
                        b_shift[y] <= b_shift[(3)*GRID_SIZE + y];
                    end
                    step <= step + 1;
                    state <= 2;
                end else begin
                    state <= 3;
                    step <= 0;
                end
            end
            3: begin
                for (x = 0; x < GRID_SIZE; x = x + 1) begin
                    for (y = 0; y < GRID_SIZE; y = y + 1) begin
                        idx = accum_idx(x, y, 0, 0);
                        result[x*2][y*2]     <= accum[idx];
                        result[x*2][y*2+1]   <= accum[idx+1];
                        result[x*2+1][y*2]   <= accum[idx+2];
                        result[x*2+1][y*2+1] <= accum[idx+3];
                    end
                end
                done <= 1;
                state<=0;
            end
            endcase
        end
    end
    always @(posedge clk) begin
        if(done) begin
        for (x = 0; x < 8; x = x + 1) begin
                    for (y = 0; y < 8; y = y + 1) begin
                        result_flat[((x*8)+y)*32 +: 32] = result[x][y];
                    end
                end
            end
        end
        

endmodule
