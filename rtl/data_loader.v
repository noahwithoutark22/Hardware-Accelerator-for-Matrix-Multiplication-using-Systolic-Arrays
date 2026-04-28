`timescale 1ns / 1ps
module data_loader (
    input clk, reset, start,
    input [15:0] data_in_a, data_in_b,  
    output reg [16*64-1:0] buf_a_flat,  
    output reg [16*64-1:0] buf_b_flat,  
    output reg ready  
);
    reg [15:0] ping_a [0:7][0:7];
    reg [15:0] ping_b [0:7][0:7];
    reg [15:0] pong_a [0:7][0:7];
    reg [15:0] pong_b [0:7][0:7];
    reg [2:0] row_cnt;
    reg [2:0] col_cnt;
    reg loading;  
    reg ping_active;  
    integer i=0,j=0,idx=0;
    always @(posedge clk) begin
        if (reset) begin
            row_cnt <= 0;
            col_cnt <= 0;
            loading <= 0;
            ready <= 0;
            ping_active <= 0;
            for(i = 0;i<8;i=i+1)
                for(j=0;j<8;j=j+1)
                    begin
                        ping_a[i][j] <= 0;
                        ping_b[i][j] <= 0;
                        pong_a[i][j] <= 0;
                        pong_b[i][j] <= 0;
                    end
                    
        end else begin
            if (start && !loading) begin
                loading <= 1;  
                ready <= 0;    
            end
            if (loading) begin
                if (!ping_active) begin
                    ping_a[row_cnt][col_cnt] <= data_in_a;
                    ping_b[row_cnt][col_cnt] <= data_in_b;
                end else begin
                    pong_a[row_cnt][col_cnt] <= data_in_a;
                    pong_b[row_cnt][col_cnt] <= data_in_b;
                end
                if (col_cnt == 7) begin
                    col_cnt <= 0;
                    if (row_cnt == 7) begin
                        loading <= 0;
                        ready <= 1;  
                        ping_active <= ~ping_active;
                    end else begin
                        row_cnt <= row_cnt + 1;
                    end
                end else begin
                    col_cnt <= col_cnt + 1;
                end
            end
        end
    end
always @(posedge clk or posedge reset or posedge ready) begin
    if (reset) begin
        buf_a_flat <= 0;
        buf_b_flat <= 0;
    end else begin
        if (ready) begin
            idx = 0;
            if (ping_active) begin
                for (i = 0; i < 8; i = i + 1)
                    for (j = 0; j < 8; j = j + 1) begin
                        buf_a_flat[16*idx +: 16] <= ping_a[i][j];
                        buf_b_flat[16*idx +: 16] <= ping_b[i][j];
                        idx = idx + 1;
                    end
            end else begin
                for (i = 0; i < 8; i = i + 1)
                    for (j = 0; j < 8; j = j + 1) begin
                        buf_a_flat[16*idx +: 16] <= pong_a[i][j];
                        buf_b_flat[16*idx +: 16] <= pong_b[i][j];
                        idx = idx + 1;
                    end
            end
        end  
    end
end


endmodule