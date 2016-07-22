/*
 *  Simple SPI protocol testbench for spi_slave module.
 *  
 * Copyright (c) 2016, Soukthavy Sopha <soukthavy@yahoo.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
*/

`timescale 1ns / 100ps 

module spi_slave_tb();

    reg clk,clk2,slow_clk;
    wire sck;
    wire mosi;
    wire miso;
    reg _cs;

    reg [7:0] dout_master, di_slave;
    reg [5:0] count;

    integer i;

    initial begin 
        _cs = 1'b1;
        clk = 1'b0;
	    count = 4'h0;
        clk2 = 1'b0;
        di_slave = 8'h0;
        forever #5 clk = ~clk; // 100MHZ
    end
    always@(posedge clk)
      clk2 = ~clk2; // 50MHZ

    initial begin 
        slow_clk = 1'b0;
        @(negedge _cs);
    end

    task send_slave; //use global vars
        for (i=0;i < 8;i = i+1) begin
        #25 slow_clk = 1'b1;
        #25 slow_clk = 1'b0;
        dout_master = {dout_master[6:0],1'b0};
		count = count + 1'b1;
        end
    endtask
    task recv_slave;
        for (i=0;i < 8;i = i+1) begin
        #25 slow_clk = 1'b1;
        #25 slow_clk = 1'b0;
		count = count + 1'b1;
        end  
    endtask

    initial begin
        //As a master, send one byte of data to slave
        #1 dout_master = 8'h1d;  //READ_ID command
        wait(clk2) #2 _cs = 1'b0;

        send_slave;
        
        for (i = 0; i < 8; i = i + 1) @(posedge clk2); //wait for 8 clk2 for ID data
        //MISO for READ_ID
        recv_slave;

        #5 _cs = 1'b1; //deassert _cs

        for (i = 0; i < 4; i = i + 1) @(posedge clk2); //wait for 4 clk2
        #1 dout_master = 8'hea;  //READ command
        wait(clk2) #2 _cs = 1'b0; //assert _cs

        send_slave; //send READ command

        for (i = 0; i < 8; i = i + 1) @(posedge clk2); //wait for 8 clk2
        //MISO for READ data
        recv_slave;

        for (i = 0; i < 4; i = i + 1) @(posedge clk2); //wait for 4 clk2
        #1 dout_master = 8'had;  //WRITE command
        send_slave;

        for (i = 0; i < 4; i = i + 1) @(posedge clk2); //wait for 4 clk2
        #1 dout_master = 8'ha5;  //data to write 
        send_slave;

        /* send invalid command follow by valid command */
        for (i = 0; i < 4; i = i + 1) @(posedge clk2); //wait for 4 clk2
        #1 dout_master = 8'h6c;  //invalid command
        send_slave;
        for (i = 0; i < 4; i = i + 1) @(posedge clk2); //wait for 4 clk2
        recv_slave;
        for (i = 0; i < 4; i = i + 1) @(posedge clk2); //wait for 4 clk2
        #1 dout_master = 8'hea;  //READ command
        send_slave; //send READ command
        for (i = 0; i < 8; i = i + 1) @(posedge clk2); //wait for 8 clk2
        recv_slave;

        for (i = 0; i < 4; i = i + 1) @(posedge clk2); //wait for 4 clk2
        #5 _cs = 1'b1; //deassert _cs

        #2000 $finish;
    end

    assign sck = ~_cs & slow_clk;

    //receive from slave
    always @(posedge sck ) #1 di_slave <= {di_slave[6:0],miso};

    assign #2 mosi = (_cs ? 1'bz: dout_master[7]); //always MSB from master

    spi_slave tb(
        .clk(clk),
        .sck(sck),
        .mosi(mosi),
        .miso(miso),
        ._cs(_cs)
    ); 

endmodule
