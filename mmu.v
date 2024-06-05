module mmu(
    input clk,
    output reg [7:0] ram [0:4095]   // 4096 bytes of ram
);

// TODO: dynamic game selection

// readmemb is synthesizable on Xilinx boards
// CHIP-8 games start at byte 512 and end at byte 4095
initial $readmemb("games/pong.ch8", ram, 512, 4095);

endmodule