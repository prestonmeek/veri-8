module gpu(
    input clk,
    input clear,                    // Clear line
    input draw,                     // Draw line
    input [7:0] row,                // Start row (Vy)
    input [7:0] col,                // Start col (Vx)
    input [7:0] height,             // Height of sprite (n)
    input [119:0] sprite_data,      // Entire sprite data (max 120 bits aka 15 bytes)
    input [1:0] cycle_count,        // Current drawing cycle
    output [7:0] vf                 // Need to set VF = 1 if a pixel is flipped
);

// NOTE: if a number base system is not specified, Verilog defaults to decimal

integer i, j;

reg [63:0] vram [0:31];             // 64 x 32 monochrome display (32 rows, 64 cols)

task clear_vram()
    begin
        for (i = 0; i < 32; i = i + 1)
            vram[i] = 64'h0;
    end
endtask

clear_vram();

// TODO: optimize this to run in less loops? idk how much the compiler optimizes...
always @ (posedge clk) begin
    if (clear) begin 
        clear_vram();

    end else if (write) begin
        // Grab the current row of the sprite
        for (i = 0; i < height; i = i + 1) begin
            // Draw the current row
            for (j = 0; j < 8; j = j + 1) begin
                // Sprites are stored MSbyte to LSbyte (first row is most significant, i.e., 14 to 0)
                // Sprites are drawn from MSbit to LSbit (7 to 0)
                if (sprite_data[((14 - i) * 8) + 7 - j] == 1) begin
                    // First cycle is simply setting the pixel flipped flag
                    // Second cycle is actually drawing the sprite
                    if (cycle_count == 1)
                        // Set pixel flipped flag to 1 if ANY pixel is flipped
                        // Since only one has to be flipped, we never set it back to 0
                        if (vram[row + i][col + j] == 1) vf <= 1;
                    else if (cycle_count == 2)
                        // Pixels are XORed
                        vram[row + i][col + j] <= vram[row + i][col + j] ^ 1;
                end
            end
        end
    end
end

endmodule