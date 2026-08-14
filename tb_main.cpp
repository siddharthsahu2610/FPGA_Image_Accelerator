#include "Vimage_accelerator_controller_tb.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char** argv) {
    // 1. Create VerilatedContext for proper time tracking
    const auto contextp = std::make_unique<VerilatedContext>();
    contextp->commandArgs(argc, argv);
    contextp->traceEverOn(true);

    // 2. Instantiate top level with context
    auto top = std::make_unique<Vimage_accelerator_controller_tb>(contextp.get());
    
    // 3. Attach VCD trace
    VerilatedVcdC* tfp = new VerilatedVcdC();
    top->trace(tfp, 99);
    tfp->open("dump.vcd");

    // 4. Main simulation loop
    while (!contextp->gotFinish()) {
        top->eval();
        
        // Dump trace using the internal context time instead of a manual counter
        tfp->dump(contextp->time());
        
        // Advance context time step
        contextp->timeInc(1);
    }

    tfp->close();
    delete tfp;
    return 0;
}
