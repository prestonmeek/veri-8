`include "cpu.v"
`include "gpu.v"
`include "mmu.v"

module cpu_tb();

reg clk;
wire gpu_clear, gpu_draw;
wire [7:0] vx, vy, vf;
wire [3:0] n_bits;
wire [119:0] sprite_data;
wire [1:0] cycle_count;

cpu dut(
    .clk(clk),
    .gpu_clear(gpu_clear),
    .gpu_draw(gpu_draw),
    .vx(vx),
    .vy(vy),
    .vf(vf),
    .n_bits(n_bits),
    .sprite_data(sprite_data),
    .cycle_count(cycle_count)
);

initial begin
    $dumpfile("tb/cpu_tb.vcd");
    $dumpvars(0, dut);

    clk = 0;

    repeat(500) #1 clk = ~clk;
end

endmodule

// iverilog -o tb/cpu_tb.vvp tb/cpu_tb.v
// vvp tb/cpu_tb.vvp
// clear && iverilog -o tb/cpu_tb.vvp tb/cpu_tb.v && vvp tb/cpu_tb.vvp && gtkwave tb/cpu_tb.vcd