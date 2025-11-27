/*
 * Simple audio demo for DE1-SoC
 * - Uses intel_sound ROM: 32-bit wide, 2048 words deep
 * - Triggered by SW[1] going high (while not already playing)
 */

module audio_demo (
    // Inputs
    CLOCK_50,
    KEY,
    SW,
    AUD_ADCDAT,
    move_pulse,     // NEW

    // Bidirectionals
    AUD_BCLK,
    AUD_ADCLRCK,
    AUD_DACLRCK,
    FPGA_I2C_SDAT,

    // Outputs
    AUD_XCK,
    AUD_DACDAT,
    FPGA_I2C_SCLK
);


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
input              CLOCK_50;
input      [3:0]   KEY;
input      [3:0]   SW;
input              AUD_ADCDAT;
input              move_pulse;   // NEW


inout              AUD_BCLK;
inout              AUD_ADCLRCK;
inout              AUD_DACLRCK;
inout              FPGA_I2C_SDAT;

output             AUD_XCK;
output             AUD_DACDAT;
output             FPGA_I2C_SCLK;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
wire               audio_in_available;
wire               audio_out_allowed;
wire      [31:0]   left_channel_audio_out;
wire      [31:0]   right_channel_audio_out;
reg                write_audio_out;

wire      [31:0]   q_data;

wire               reset;
reg                playback;
reg      [10:0]    addr_cnt;   // 2048 words ⇒ 11 address bits (0..2047)
reg                is_lower;
reg                delay;
reg                enable;

/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

assign reset = ~KEY[0];  // KEY0 = global reset

always @(posedge CLOCK_50) begin
    if (reset) begin
        addr_cnt        <= 11'd0;
        write_audio_out <= 1'b0;
        playback        <= 1'b0;
    end
    // start playback on a valid move, or SW1 for manual testing,
    // but only if we're not already playing
    else if ( move_pulse && !playback ) begin
        playback        <= 1'b1;
        addr_cnt        <= 11'd0;
        write_audio_out <= 1'b0;
    end
    else if (audio_out_allowed && playback) begin
        if (enable)
            addr_cnt <= addr_cnt + 11'd1;

        write_audio_out <= 1'b1;

        // stop after address 0x7FF (2047) since ROM depth = 2048 words
        if (addr_cnt == 11'h7FF && enable)
            playback <= 1'b0;
    end
    else begin
        // not playing / not allowed → don't assert write
        write_audio_out <= 1'b0;
    end
end



// 32-bit, left-only, downsampled to 24 kHz (same pattern as original)
always @(posedge CLOCK_50) begin
    if (reset) begin
        enable   <= 1'b0;
        is_lower <= 1'b0;
        delay    <= 1'b0;
    end else if (audio_out_allowed && playback) begin
        if (delay && is_lower) begin
            enable <= 1'b1;
            delay  <= 1'b0;
        end else if (delay) begin
            enable <= 1'b0;
        end else if (is_lower) begin
            delay  <= ~delay;
            enable <= 1'b0;
        end else begin
            enable <= 1'b0;
        end
        is_lower <= ~is_lower;
    end
end

assign left_channel_audio_out  =
    (is_lower) ? {q_data[15:0], 16'b0} : {q_data[31:16], 16'b0};
assign right_channel_audio_out =
    (is_lower) ? {q_data[15:0], 16'b0} : {q_data[31:16], 16'b0};

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

// intel_sound: 32-bit wide, 2048 words deep
intel_sound intel_sound_inst (
    .address ( addr_cnt ),   // 11-bit address, 0..2047
    .clock   ( CLOCK_50 ),
    .data    (  ),
    .wren    ( 1'b0 ),
    .q       ( q_data )
);

Audio_Controller Audio_Controller (
    .CLOCK_50               (CLOCK_50),
    .reset                  (reset),

    .clear_audio_in_memory  (),
    .read_audio_in          (),

    .clear_audio_out_memory (),
    .left_channel_audio_out (left_channel_audio_out),
    .right_channel_audio_out(right_channel_audio_out),
    .write_audio_out        (write_audio_out),

    .AUD_ADCDAT             (AUD_ADCDAT),

    .AUD_BCLK               (AUD_BCLK),
    .AUD_ADCLRCK            (AUD_ADCLRCK),
    .AUD_DACLRCK            (AUD_DACLRCK),

    .audio_in_available     (audio_in_available),
    .left_channel_audio_in  (),
    .right_channel_audio_in (),
    .audio_out_allowed      (audio_out_allowed),

    .AUD_XCK                (AUD_XCK),
    .AUD_DACDAT             (AUD_DACDAT)
);

avconf #(.USE_MIC_INPUT(1)) avc (
    .FPGA_I2C_SCLK          (FPGA_I2C_SCLK),
    .FPGA_I2C_SDAT          (FPGA_I2C_SDAT),
    .CLOCK_50               (CLOCK_50),
    .reset                  (reset)
);

endmodule
