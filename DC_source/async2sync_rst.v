module async2sync_rst ( rst_n, clk, asyncrst_n);
	
	input clk, asyncrst_n;
	output reg rst_n;
	reg rff1;

	always @(posedge clk or negedge asyncrst_n)
		if (!asyncrst_n) {rst_n,rff1} <= 2'b00;
		else {rst_n,rff1} <= {rff1,1'b1};
endmodule