// http://devernay.free.fr/hacks/chip8/C8TECH10.HTM
// https://github.com/JamesGriffin/CHIP-8-Emulator/blob/master/src/chip8.cpp

// TODO: create multiple VRAM buffers and then OR them together to reduce the flicker from XORing

module cpu(
    input clk,                          // Clock
    output reg gpu_clear,               // Clear line for GPU
    output reg gpu_draw,                // Draw line for GPU
    output reg [7:0] vx,                // Vx register (i.e., V[x] of D[x]yn)
    output reg [7:0] vy,                // Vy register (i.e., V[y] of Dx[y]n)
    output reg [7:0] vf,                // Vf register (i.e., V[0xF])
    output reg [3:0] n_bits,            // lower 4 bits of instruction (i.e., Dxy[n])
    output reg [119:0] sprite_data,     // TODO: move this to MMU
    output reg [1:0] cycle_count        // Count of how many cycles have occurred for a given instruction
);

// NOTE: initial values are supported on xilinx boards

integer i;                          // used for for loops (for initialization purposes)

reg [7:0] reg_file [0:15];          // 16 general-purpose 8-bit registers (register file)

reg [15:0] vi = 16'h0;              // 16-bit I register
reg [7:0] vd, vs = 8'h0;            // 8-bit special-purpose delay register and sound register

reg [15:0] pc = 16'h0;          // program counter

reg [7:0] sp = 8'h0;                // stack pointer
reg [15:0] stack [0:15];            // array of 16 16-bit values

// CPU states
localparam STATE_FETCH      = 0;    // fetch instruction
localparam STATE_DECODE     = 1;    // decode instruction
localparam STATE_EXECUTE    = 2;    // execute instruction
localparam STATE_WRITEBACK  = 3;    // write to reg file
localparam STATE_PC_UPDATE  = 4;    // update PC

reg [3:0] state = STATE_FETCH;      // 4-bit CPU state

// PC states
localparam PC_STATE_INC     = 0;    // increment the PC
localparam PC_STATE_SKIP    = 1;    // skip next instruction
localparam PC_STATE_JUMP    = 2;    // jump to a given instruction (pc_jump_addr)

reg [1:0] pc_state = PC_STATE_INC;  // 2-bit PC state
reg [15:0] pc_jump_addr = 16'h0;     // stored value that the PC jumps to

// Sets the PC state to JUMP and stores the jump address
task pc_prep_jump(input addr);
    begin
        pc_state <= PC_STATE_JUMP;
        pc_jump_addr <= addr;
    end
endtask

// TODO: move this to top_module
reg [11:0] write_addr = 12'h0;
reg write_flag = 1'h0;      
reg [1:0] write_len = 2'h0;
reg [3:0] write_data = 4'h0;
wire [15:0] ir;                     // instruction register bus

mmu u_mmu(                          // MMU
    .clk(clk),
    .pc(pc),
    .write_flag(write_flag),
    .write_addr(write_addr),
    .write_len(write_len),
    .write_data(write_data),
    .ir(ir)
);

/*
    nnn or addr - A 12-bit value, the lowest 12 bits of the instruction
    n or nibble - A 4-bit value, the lowest 4 bits of the instruction
    x - A 4-bit value, the lower 4 bits of the high byte of the instruction
    y - A 4-bit value, the upper 4 bits of the low byte of the instruction
    kk or byte - An 8-bit value, the lowest 8 bits of the instruction
*/
reg [11:0] nnn = 12'h0;
reg [3:0] x_bits = 4'h0;
reg [3:0] y_bits = 4'h0;
reg [7:0] kk = 8'h0;

reg [7:0] v0 = 8'h0;

// TODO: put everything in initial, and then just put declarations above it.
initial begin
    for (i = 0; i < 16; i = i + 1)
        reg_file[i] = 8'h0;

    for (i = 0; i < 16; i = i + 1)
        stack[i] = 16'h0;

    gpu_clear = 0;                      // Clear and draw lines for the GPU
    gpu_draw = 0;                       
    sprite_data = 120'h0;               // TODO: temp, sprite data for the GPU

    n_bits = 4'h0;

    vx = 8'h0;                          // Vx, Vy, V0, and VF for instructions
    vy = 8'h0;
    vf = 8'h0;                  

    cycle_count = 2'h0;                 // Keeps track of number of cycles for a given instruction
end

always @ (posedge clk) begin
    // set default values before case (so default isn't needed within case statements)
    pc_state <= PC_STATE_INC;

    case (state)
        STATE_FETCH: begin
            // program counter is loaded into MMU
            // instruction register will be loaded by next clock cycle

            // TODO: something here..?

            state <= STATE_DECODE;
        end

        STATE_DECODE: begin
            nnn     <= ir[11:0];
            n_bits  <= ir[3:0];
            x_bits  <= ir[11:8];
            y_bits  <= ir[7:4];
            kk      <= ir[7:0];

            // Cannot use x_bits and y_bits here since we don't know order of instructions within a state
            vx      <= reg_file[ir[11:8]];
            vy      <= reg_file[ir[7:4]];

            v0      <= reg_file[0];
            vf      <= reg_file[15]; // 0d15 = 0xF

            // Reset cycle count before execute state
            cycle_count <= 2'h0;

            state <= STATE_EXECUTE;
        end

        STATE_EXECUTE: begin
            casez (ir)
                // 00E0 : Clear the display.
                16'h00E0 : begin
                    if (cycle_count == 0) begin
                        gpu_clear <= 1;
                        cycle_count <= cycle_count + 1;
                    end else begin
                        gpu_clear <= 0;
                        state <= STATE_WRITEBACK;
                    end
                end

                // 00EE : Return from a subroutine.
                16'h00EE : begin
                    if (cycle_count == 0) begin
                        // Decrement stack pointer.
                        sp <= sp - 1;
                    end else begin
                        // Then, return from the subroutine at the stack.
                        // This means we go to its location and jump one more address.
                        pc_prep_jump(stack[sp] + 2);
                        state <= STATE_WRITEBACK;
                    end
                end

                // 0nnn : Jump to a machine code routine at nnn.
                16'h0zzz : begin
                    // pc_state <= PC_STATE_JUMP;
                    // pc_jump_addr <= nnn;
                    pc_prep_jump(nnn);
                    state <= STATE_WRITEBACK;
                end

                // 1nnn : Jump to location nnn.
                16'h1zzz : begin
                    // pc_state <= PC_STATE_JUMP;
                    // pc_jump_addr <= nnn;
                    pc_prep_jump(nnn);
                    state <= STATE_WRITEBACK;
                end

                // 2nnn : Call subroutine at nnn.
                16'h2zzz : begin
                    if (cycle_count == 0) begin
                        // Store PC on stack first so that we utilize index 0.
                        // If we increment first, 0 is never used.
                        stack[sp] <= pc;
                        cycle_count <= cycle_count + 1;
                    end else begin
                        // Increment stack pointer.
                        sp <= sp + 1;

                        // The PC is then set to nnn.
                        // pc_state <= PC_STATE_JUMP;
                        // pc_jump_addr <= nnn;
                        pc_prep_jump(nnn);
                        
                        state <= STATE_WRITEBACK;
                    end
                end

                // 3xkk : Skip next instruction if Vx = kk.
                16'h3zzz : begin
                    if (vx == kk) pc_state <= PC_STATE_SKIP;
                    state <= STATE_WRITEBACK;
                end

                // 4xkk: Skip next instruction if Vx != kk.
                16'h4zzz : begin
                    if (vx != kk) pc_state <= PC_STATE_SKIP;
                    state <= STATE_WRITEBACK;
                end

                // 5xy0: Skip next instruction if Vx == Vy.
                16'h5zz0 : begin
                    if (vx == vy) pc_state <= PC_STATE_SKIP;
                    state <= STATE_WRITEBACK;
                end

                // 6xkk : Set Vx = kk.
                16'h6zzz : begin
                    vx <= kk;
                    state <= STATE_WRITEBACK;
                end

                // 7xkk : Set Vx = Vx + kk.
                16'h7zzz : begin
                    vx <= vx + kk;
                    state <= STATE_WRITEBACK;
                end

                // 8xy0 : Set Vx = Vy.
                16'h8zz0 : begin
                    vx <= vy;
                    state <= STATE_WRITEBACK;
                end

                // 8xy1 : Set Vx = Vx OR Vy.
                16'h8zz1 : begin
                    vx <= vx | vy;
                    state <= STATE_WRITEBACK;
                end

                // 8xy2 : Set Vx = Vx AND Vy.
                16'h8zz2 : begin
                    vx <= vx & vy;
                    state <= STATE_WRITEBACK;
                end

                // 8xy3 : Set Vx = Vx XOR Vy.
                16'h8zz3 : begin
                    vx <= vx ^ vy;
                    state <= STATE_WRITEBACK;
                end

                // 8xy4 : Set Vx = Vx + Vy, set VF = carry.
                16'h8zz4 : begin
                    { vf, vx } <= vx + vy;
                    state <= STATE_WRITEBACK;
                end

                // 8xy5 : Set Vx = Vx - Vy, set VF = NOT borrow.
                16'h8zz5 : begin
                    if (cycle_count == 0) begin
                        // If Vx > Vy, then VF is set to 1, otherwise 0.
                        vf <= (vx > vy);
                    end else begin
                        // Then Vy is subtracted from Vx, and the results stored in Vx.
                        vx <= vx - vy;
                        state <= STATE_WRITEBACK;
                    end
                end

                // 8xy6 : Set Vx = Vx >> 1.
                16'h8zz6 : begin
                    if (cycle_count == 0) begin
                        // If the least-significant bit of Vx is 1, 
                        // then VF is set to 1, otherwise 0.
                        // Needs to be zero-extended to 8 bits.
                        vf <= {7'h0, vx[0]};
                        cycle_count <= cycle_count + 1;
                    end else begin
                        // Then Vx is divided by 2 (>> 1).
                        vx <= vx >> 1;
                        state <= STATE_WRITEBACK;
                    end
                end

                // 8xy7 : Set Vx = Vy - Vx, set VF = NOT borrow.
                16'h8zz7 : begin
                    if (cycle_count == 0) begin
                        // If Vy > Vx, then VF is set to 1, otherwise 0.
                        vf <= (vy > vx);
                    end else begin
                        // Then Vx is subtracted from Vy, and the results stored in Vx.
                        vx <= vy - vx;
                        state <= STATE_WRITEBACK;
                    end
                end

                // 8xyE : Set Vx = Vx << 1.
                16'h8zzE : begin
                    if (cycle_count == 0) begin
                        // If the most-significant bit of Vx is 1, 
                        // then VF is set to 1, otherwise to 0. 
                        // Needs to be zero-extended to 8 bits.
                        vf <= {7'h0, vx[7]};
                        cycle_count <= cycle_count + 1;
                    end else begin
                        // Then Vx is multiplied by 2 (<< 1).
                        vx <= vx << 1;
                        state <= STATE_WRITEBACK;
                    end
                end

                // 9xy0: Skip next instruction if Vx != Vy.
                16'h9zz0 : begin
                    if (vx != vy) pc_state <= PC_STATE_SKIP;
                    state <= STATE_WRITEBACK;
                end

                // Annn : Set I = nnn.
                16'hAzzz : begin 
                    vi <= nnn;
                    state <= STATE_WRITEBACK;
                end

                // Bnnn : Jump to location nnn + V0.
                16'hBzzz : begin
                    // pc_state <= PC_STATE_JUMP;
                    // pc_jump_addr <= nnn + v0;
                    pc_prep_jump(nnn + v0);
                end

                // Cxkk : Set Vx = random byte AND kk.
                16'hCzzz : begin
                    vx <= ($urandom % 255) & kk;
                    state <= STATE_WRITEBACK;
                end

                // Dxyn : Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision.
                // Each sprite has a width of 8 pixels and a height of n pixels.
                // TODO: set VF to 0 before running GPU
                16'hDzzz : begin
                    if (cycle_count == 0) begin
                        gpu_draw <= 1;
                        // TODO: concat sprite data together
                        /*sprite_data <= {

                        };*/
                        cycle_count <= cycle_count + 1;
                    end else if (cycle_count == 1) begin
                        
                        cycle_count <= cycle_count + 1;
                    end
                end

                // Ex9E : Skip next instruction if key with the value of Vx is pressed.
                16'hEz9E : begin
                    // TODO: this
                    state <= STATE_WRITEBACK;
                end

                // Skip next instruction if key with the value of Vx is not pressed.
                16'hEzA1 : begin
                    // TODO: this
                    state <= STATE_WRITEBACK;
                end

                // Fx07 : Set Vx = delay timer value.
                16'hFz07 : begin
                    vx <= vd;
                    state <= STATE_WRITEBACK;
                end

                // Fx0A : Wait for a key press, store the value of the key in Vx.
                16'hFz0A : begin
                    // TODO: this
                    state <= STATE_WRITEBACK;
                end

                // Fx15 : Set delay timer = Vx.
                16'hFz15 : begin
                    vd <= vx;
                    state <= STATE_WRITEBACK;
                end
                
                // Fx18 : Set sound timer = Vx.
                16'hFz18 : begin
                    vs <= vx;
                    state <= STATE_WRITEBACK;
                end

                // Fx1E : Set I = I + Vx.
                16'hFz1E : begin
                    vi <= vi + vx;
                    state <= STATE_WRITEBACK;
                end

                // Fx29 : Set I = location of sprite for digit Vx.
                16'hFz29 : begin
                    // TODO: load sprites starting at index 0 in memory
                    // Each font is 5 bytes long, so multiply by 5 to get the start of the font
                    // from its index (aka Vx)
                    vi <= vx * 5;
                    state <= STATE_WRITEBACK;
                end

                // Fx33 : Store decimal representation of Vx in memory locations I, I+1, and I+2.
                16'hFz33 : begin
                    // The interpreter takes the decimal value of Vx, 
                    // and places the hundreds digit in memory at location in I, 
                    // the tens digit at location I+1, 
                    // and the ones digit at location I+2.

                    if (cycle_count == 0) begin
                        write_flag <= 1;
                        write_addr <= vi;
                        write_len <= 3;
                        write_data <= {
                            vx / 100,
                            (vx % 100) / 10,
                            vx % 10
                        };

                        cycle_count <= cycle_count + 1;
                    end else begin
                        // TODO: reset all other buses somewhere else in the code?
                        write_flag <= 0;
                        state <= STATE_WRITEBACK;
                    end
                end

                16'hFz55 : begin

                end

                16'hFz65 : begin

                end
            endcase

            // TODO: make sure all instructions update state when needed
            // TODO: make sure PC_STATE is set if needed to jump/skip
        end

        STATE_WRITEBACK: begin
            // Update the register file
            reg_file[x_bits]    <= vx;
            reg_file[y_bits]    <= vy;
            reg_file[0]         <= v0;
            reg_file[15]        <= vf;

            state <= STATE_PC_UPDATE;
        end

        STATE_PC_UPDATE: begin
            case (pc_state)
                PC_STATE_INC    : pc <= pc + 2;
                PC_STATE_JUMP   : pc <= pc + 4;
                PC_STATE_SKIP   : pc <= pc_jump_addr;
            endcase

            state <= STATE_FETCH;
        end
    endcase
end

endmodule