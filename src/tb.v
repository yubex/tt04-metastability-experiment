`default_nettype none
`timescale 1us/1ns

module tb (
    );

	reg clk;
	reg rst_n;
	reg trigger;
	reg mode;
	reg [5:0] delay_ctrl;
	
    wire [7:0] inputs = {delay_ctrl, mode, trigger};
    wire [7:0] outputs;
	
	always 
	begin
		clk <= 1'b0;
		# 10;
		clk <= 1'b1;
		# 10;
	end 
	
	initial 
	begin
    $display("Simulation started!");
		rst_n      <= 1'b0;
		trigger    <= 1'b0;
		delay_ctrl <= 6'b000001;
		mode       <= 1'b1;
		# 5000;
		rst_n <= 1'b1;
		# 50000;
		trigger  <= 1'b1;
		# 500000;
		trigger  <= 1'b0;
		# 500000;
		trigger  <= 1'b1;
		# 500000;
		trigger  <= 1'b0;
		# 500000;
		trigger  <= 1'b1;
		# 6100;
		trigger  <= 1'b0;
		# 50000;        
		trigger  <= 1'b1;
		# 500000; 
		trigger  <= 1'b0;
		# 6100;
		trigger  <= 1'b1;
		# 50000;
		mode <= 1'b0;
		# 500000;
    $display("Done!");
    $finish ;
	end 

    tt_yubex_metastability_experiment tt_yubex_metastability_experiment (
         .ui_in(inputs),   // Dedicated inputs - connected to the input switches
         .uo_out(outputs), // Dedicated outputs - connected to the 7 segment display
         .uio_in(),        // IOs: Bidirectional Input path
         .uio_out(),       // IOs: Bidirectional Output path
         .uio_oe(),        // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
         .ena(1'b1),       // will go high when the design is enabled
         .clk(clk),        // clock
         .rst_n(rst_n)     // reset_n - low to reset        
    );

initial
 begin
    $dumpfile("test.vcd");
    $dumpvars(0,clk,rst_n,trigger,mode,delay_ctrl,outputs);
 end



endmodule
