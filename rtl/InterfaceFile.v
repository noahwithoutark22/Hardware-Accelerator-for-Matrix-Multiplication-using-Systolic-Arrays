`timescale 1ns / 1ps
module InterfaceFile(
    input clk,
    input reset,
    input start, 
    input [31:0] s_axis_tdata,
    input        s_axis_tvalid,
    input        s_axis_tlast,
    output reg   s_axis_tready,
    output reg [31:0] m_axis_tdata,
    output reg        m_axis_tvalid,
    input             m_axis_tready,
    output reg        m_axis_tlast,
    output reg done    
);
    wire [15:0] data_in_a, data_in_b;
    wire ready;
    reg compute_start;
    wire core_done;
    wire [2047:0] result_flat;

    assign data_in_a = s_axis_tdata[15:0];
    assign data_in_b = s_axis_tdata[31:16];

    data_loader loader_inst (
        .clk(clk),
        .reset(reset),
        .start(start),                  // manual
        .data_in_a(data_in_a),
        .data_in_b(data_in_b),
        .buf_a_flat(),
        .buf_b_flat(),
        .ready(ready)
    );
    wire [16*64-1:0] buf_a_flat, buf_b_flat;
    assign buf_a_flat = loader_inst.buf_a_flat;
    assign buf_b_flat = loader_inst.buf_b_flat;
    reg done_streamed;
    reg [6:0] load_count;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            s_axis_tready <= 1'b0;
            load_count <= 0;
        end else if (start) begin
            s_axis_tready <= 1'b1;
            load_count <= 0;
        end else if (s_axis_tready && s_axis_tvalid) begin
            load_count <= load_count + 1;
            if (load_count == 63 && s_axis_tlast) begin
                s_axis_tready <= 1'b0;
            end
        end
    end
    systolic_array systolic_inst (
        .clk(clk),
        .reset(reset),
        .compute_start(compute_start),
        .buf_a_flat(buf_a_flat),
        .buf_b_flat(buf_b_flat),
        .result_flat(result_flat),
        .done(core_done)
    );
reg [6:0] result_count;
reg sending_result;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            m_axis_tdata  <= 0;
            m_axis_tvalid <= 0;
            m_axis_tlast  <= 0;
            result_count  <= 0;
            done_streamed <= 0;
            sending_result <= 0;
        end else begin
   
            if (done && !sending_result && !done_streamed) begin
                result_count    <= 0;
                sending_result  <= 1;
                done_streamed <= 1;
                m_axis_tvalid  <= 1;
                m_axis_tdata   <= result_flat[0 +: 32];
            end

            if (sending_result) begin
              
                m_axis_tlast  <= (result_count == 63);

                if (m_axis_tready && m_axis_tvalid) begin
                    if (result_count == 63) begin
                        m_axis_tvalid <= 0;
                        m_axis_tlast  <= 0;
                        sending_result <= 0;
                        result_count    <= 0;
                    end else begin
                    result_count    <= result_count + 1;
                    m_axis_tdata    <= result_flat[(result_count+1)*32 +: 32];
                    m_axis_tlast    <= ((result_count+1) == 63);
                end
             
                end
            end else begin
                m_axis_tlast  <= 0;
            end
        end
    end
    reg ready_d, computing;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            compute_start <= 0;
            done <= 0;
            ready_d <= 0;
            computing <= 0;
        end else begin
            ready_d <= ready;
            if (ready && !ready_d && !computing) begin
                compute_start <= 1;
                computing <= 1;
            end else begin
                compute_start <= 0;
            end
            if (core_done) begin
                done <= 1;
                computing <= 0;
            end
            if (start) begin
                done <= 0;
            end
        end
    end

endmodule
