`include "cpu.v"
`include "gpu.v"
`include "mmu.v"

module cpu_tb();

reg clk;
wire gpu_clear, gpu_draw;
wire [7:0] vx, vy, vf;
wire [3:0] n_bits;
wire [119:0] sprite_data;

cpu dut(
    .clk(clk),
    .gpu_clear(gpu_clear),
    .gpu_draw(gpu_draw),
    .vx(vx),
    .vy(vy),
    .vf(vf),
    .n_bits(n_bits),
    .sprite_data(sprite_data)
);

// TODO: rename testbench to something more general, and add GPU here. connect wires so that u can actually see if the GPU is doing its job!
// TODO: because rn the GPU has no connections and thus doesnt do anything :(
// TODO: then remove the $dump stuff in gpu.v

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