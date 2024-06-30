module mmu(
    input clk,
    input [15:0] pc,                // Program counter
    input write_enable,             // Write flag (if 1, then write to memory, else if 0, then read to memory)
    input [11:0] rw_addr,           // Read-write address (12 bits aka 2^12 = 4096)
    input [7:0] write_data,         // Write data
    input [3:0] read_len,           // Length of data to read (max 15 bytes)
    output reg [119:0] data_out,    // Output data (15 bytes) TODO: make 15 bytes a constant?
    output reg [15:0] ir            // Instruction register
);

// TODO: different write lengths?
// TODO: dynamic game selection

reg [7:0] ram [0:4095];     // 4096 bytes of ram

// readmemb is synthesizable on Xilinx boards
// CHIP-8 games start at byte 512 and end at byte 4095
initial begin
    $readmemh("games/pong.hex", ram, 512, 4095);
    $dumpfile("tb/cpu_tb.vcd");
    $dumpvars(0, ram[746], ram[513], ram[514]);
end

always @ (posedge clk) begin
    // load the current instruction based on the PC
    ir <= (ram[pc] << 8) | ram[pc + 1];

    if (write_enable)
        // TODO: maybe consider allowing multiple bytes to be written in one clock cycle?
        ram[rw_addr] <= write_data;
end

genvar g;
integer i;

// TODO: next time, ditch this and just make the read ram bus a fixed size like 16 bytes or smthn
generate
    always @ (posedge clk) begin
        if (!write_enable) begin
            for (i = 0; i < read_len; i = i + 1) begin
                // This stores data in data_out starting at the MSbyte
                // For example, if read_len is 3 (for the example, indices are 0-indexed bytes):
                // data_out[2] <= ram[addr + 0]
                // data_out[1] <= ram[addr + 1]
                // data_out[0] <= ram[addr + 2]
                // data_out[14:3] are ignored (NOT ZEROED)

                // -: 8 grabs 8 bits down i.e., d[23 -: 8] == d[23:16]
                data_out[8 * (read_len - i) - 1 -: 8] <= ram[rw_addr + i];
            end
        end
    end
endgenerate

endmodule