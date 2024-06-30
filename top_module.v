`default_nettype none

`include "cpu.v"
`include "gpu.v"
`include "mmu.v"

module top_module(
    input clk
);

// TODO: i dont think GPU should have direct access to vf
// and it also probably shouldnt to vx or vy.. idk tho

wire clear, draw;
wire [7:0] vx, vy, vf;
wire [3:0] n_bits;
wire [119:0] sprite_data;

cpu u_cpu(
    .clk(clk),
    .gpu_clear(clear),
    .gpu_draw(draw),
    .vx(vx),
    .vy(vy),
    .vf(vf),
    .n_bits(n_bits),
    .sprite_data(sprite_data)   // TODO: move this to MMU
);

gpu u_gpu(
    .clk(clk),
    .clear(clear),
    .draw(draw),
    .row(vy),
    .col(vx),
    .height(n_bits),
    .sprite_data(sprite_data),
    .vf(vf)
)

endmodule