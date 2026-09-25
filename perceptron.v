// =============================================================
// perceptron.v
// Quantized single-layer perceptron classifier - serial MAC datapath.
// One multiplier is reused 64 times per class x 10 classes = 640 MACs
// per inference, instead of instantiating 640 multipliers. This is
// the "resource-efficient via serial MAC reuse" architecture.
// =============================================================
module perceptron #(
    parameter INPUT_DIM   = 64,
    parameter NUM_CLASSES = 10,
    parameter DATA_W      = 8,   // pixel width (real range used: 0..16)
    parameter WEIGHT_W    = 8,   // signed weight width
    parameter BIAS_W      = 16,  // signed bias width
    parameter ACC_W       = 20   // accumulator width (see quantize.py sizing check)
)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire                          load_en,                // pulse 1 to write load_data into x_reg[load_addr]
    input  wire [6:0]                    load_addr,              // 0..63, which pixel slot to write
    input  wire [DATA_W-1:0]             load_data,              // pixel value being loaded
    input  wire                          start,                  // pulse 1 cycle to begin inference (after all 64 pixels loaded)
    output reg  [3:0]                    class_out,              // predicted class 0-9
    output reg                           done                    // pulses 1 cycle when class_out is valid
);

    // ---- weight / bias ROMs, loaded from the files produced by export_mem.py ----
    reg signed [WEIGHT_W-1:0] weight_rom [0:NUM_CLASSES*INPUT_DIM-1];
    reg signed [BIAS_W-1:0]   bias_rom   [0:NUM_CLASSES-1];

    initial begin
        $readmemh("weights.mem", weight_rom);
        $readmemh("bias.mem",    bias_rom);
    end

    // ---- input register bank, written one pixel at a time via load_en/load_addr/load_data ----
    reg signed [DATA_W-1:0] x_reg [0:INPUT_DIM-1];

    always @(posedge clk) begin
        if (load_en)
            x_reg[load_addr] <= load_data;
    end

    // ---- FSM states ----
    localparam S_IDLE      = 3'd0,
               S_MAC_INIT  = 3'd2,
               S_MAC       = 3'd3,
               S_ADD_BIAS  = 3'd4,
               S_NEXT_OR_DONE = 3'd5,
               S_DONE      = 3'd6;

    reg [2:0] state;
    reg [3:0] class_idx;   // 0..9
    reg [6:0] elem_idx;    // 0..63
    reg signed [ACC_W-1:0] acc;
    reg signed [ACC_W-1:0] best_score;
    reg [3:0] best_class;

    localparam signed [ACC_W-1:0] MOST_NEG = {1'b1, {(ACC_W-1){1'b0}}}; // most negative ACC_W-bit value

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            done       <= 1'b0;
            class_out  <= 4'd0;
            class_idx  <= 4'd0;
            elem_idx   <= 7'd0;
            acc        <= {ACC_W{1'b0}};
            best_score <= MOST_NEG;   // anything beats this
            best_class <= 4'd0;
        end else begin
            done <= 1'b0; // default: only high for exactly one cycle in S_DONE
            case (state)

                S_IDLE: begin
                    if (start) begin
                        class_idx  <= 4'd0;
                        best_score <= MOST_NEG;
                        best_class <= 4'd0;
                        state <= S_MAC_INIT;
                    end
                end

                S_MAC_INIT: begin
                    acc      <= {ACC_W{1'b0}};
                    elem_idx <= 7'd0;
                    state    <= S_MAC;
                end

                S_MAC: begin
                    acc <= acc + weight_rom[class_idx*INPUT_DIM + elem_idx] * x_reg[elem_idx];
                    if (elem_idx == INPUT_DIM-1)
                        state <= S_ADD_BIAS;
                    else
                        elem_idx <= elem_idx + 7'd1;
                end

                S_ADD_BIAS: begin
                    acc   <= acc + bias_rom[class_idx];
                    state <= S_NEXT_OR_DONE;
                end

                S_NEXT_OR_DONE: begin
                    if (acc > best_score) begin
                        best_score <= acc;
                        best_class <= class_idx;
                    end
                    if (class_idx == NUM_CLASSES-1) begin
                        state <= S_DONE;
                    end else begin
                        class_idx <= class_idx + 4'd1;
                        state     <= S_MAC_INIT;
                    end
                end

                S_DONE: begin
                    class_out <= best_class;
                    done      <= 1'b1;
                    state     <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
