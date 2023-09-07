
/*
metastability experiment
*/

`default_nettype none

module tt_um_yubex_metastability_experiment (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

	
    wire rst;
    wire trigger;
    wire mode;
    wire [5:0] delay_ctrl;
  
    assign rst        = ! rst_n;
    assign trigger    = ui_in[0];
    assign mode       = ui_in[1];
    assign delay_ctrl = ui_in[7:2];
    assign uio_out = 8'bzzzzzzzz;
    assign uio_oe = 8'h00;

    localparam trigger_sr_size = 32;
    reg [trigger_sr_size-1:0] trigger_sr;
    
    reg toggle_dff;
    reg toggle_dff_en, toggle_dff_en_1t, toggle_dff_en_2t, toggle_dff_en_3t;
    (* keep *) wire [128:0] prog_delay;
    (* keep *) wire delayed_toggle_dff;

    reg meta_dff_0, meta_dff_1;
    reg meta_err_detected;


  // shift trigger input into shift register
  always @(posedge clk or posedge rst)
  begin
	if(rst) begin
       		    trigger_sr <= {trigger_sr_size{1'b0}};
    	    end 
    else begin
        trigger_sr <= {trigger_sr[trigger_sr_size-2:0],trigger};
    end
  end 

  // analyze shift register values and generate data input for meta_dff
  always @(posedge clk or posedge rst)
  begin
	if(rst) begin
                toggle_dff       <= 1'b0;
                toggle_dff_en    <= 1'b0;
                toggle_dff_en_1t <= 1'b0;
                toggle_dff_en_2t <= 1'b0;
                toggle_dff_en_3t <= 1'b0;
    	    end 
    else begin
        toggle_dff_en    <= 1'b0;
        toggle_dff_en_1t <= toggle_dff_en;
        toggle_dff_en_2t <= toggle_dff_en_1t;
        toggle_dff_en_3t <= toggle_dff_en_2t;

        if (toggle_dff_en) begin
            toggle_dff <= !toggle_dff;
        end
        if (mode) begin
            // manual mode
            if (trigger_sr == 32'h7FFFFFFF || trigger_sr == 32'h80000000) begin
                toggle_dff_en <= 1'b1;
            end
        end
        else begin
            // auto mode
            toggle_dff_en <= 1'b1;
            if (toggle_dff_en_3t == 1'b1 || toggle_dff_en_2t == 1'b1 || toggle_dff_en_1t == 1'b1 || toggle_dff_en == 1'b1) begin
                toggle_dff_en <= 1'b0;
            end 
        end
    end
  end

    // generate delay using inverters
    assign prog_delay[0] = toggle_dff;
    genvar i;
    generate 
        for (i = 0; i < 64; i = i + 1) begin
            // add two inverters for every loop
            assign prog_delay[i*2+1] = !prog_delay[i*2];
            assign prog_delay[i*2+2] = !prog_delay[i*2+1];
        end
    endgenerate

    // delay_ctrl controls how many inverters are used
    assign delayed_toggle_dff = prog_delay[delay_ctrl*2];

  always @(posedge clk or posedge rst)
  begin
	if(rst) begin
                meta_dff_0        <= 1'b0;
                meta_dff_1        <= 1'b0;
                meta_err_detected <= 1'b0;
    	    end 
    else begin
        
        meta_dff_0 <= delayed_toggle_dff;
        meta_dff_1 <= meta_dff_0;
        
        if (toggle_dff_en_3t == 1'b1) begin
            // 3 clks after data edge, check for metastability error
            if (toggle_dff == meta_dff_0 && meta_dff_0 == meta_dff_1) begin
                // no error
            end
            else begin
                // error detected
                meta_err_detected <= !meta_err_detected; 
            end
        end

    end
  end

    // assign 7 segment outputs
    assign uo_out[0] = mode;
    assign uo_out[1] = toggle_dff_en;
    assign uo_out[2] = toggle_dff;
    assign uo_out[3] = delayed_toggle_dff;
    assign uo_out[4] = meta_dff_0;
    assign uo_out[5] = meta_dff_1;
    assign uo_out[6] = toggle_dff_en_3t;
    assign uo_out[7] = meta_err_detected;

endmodule
