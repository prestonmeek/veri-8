module mmu(
    input clk,
    input [15:0] pc,            // Program counter
    input write_flag,           // Write flag (if 1, then write to memory)
    input [11:0] write_addr,    // Write address (12 bits aka 2^12 = 4096)
    input [1:0] write_len,      // Write length (max 3 bytes)
    input [3:0] write_data,     // Write data (max 3 bytes)
    output reg [15:0] ir        // Instruction register
);

// TODO: different write lengths?
// TODO: dynamic game selection

integer i;

reg [7:0] ram [0:4095];     // 4096 bytes of ram

// readmemb is synthesizable on Xilinx boards
// CHIP-8 games start at byte 512 and end at byte 4095
initial $readmemh("games/pong.hex", ram, 512, 4095);

always @ (posedge clk) begin
    // load the current instruction based on the PC
    ir <= (ram[pc + 512] << 8) | ram[pc + 512 + 1];

    if (write_flag) begin
        for (i = 0; i < )
    end
end

endmodule