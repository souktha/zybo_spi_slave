/*
 *  Simple SPI protocol.
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

`define DEVICE_ID 8'h5a

/* SPI slave interface.
This is a simple version of SPI slave mode 0. 
*/

module spi_slave #(parameter WIDTH=8) (
    input clk,  //system clock feed
    input _cs,  // chip select, active low
    input sck,  //spi master clock 
    input mosi, //input from master
    output miso
);
    reg [WIDTH-1:0] din, dout,slave_dout;
    reg [4:0] bitcount;
    reg sout, dload;
    reg [7:0] command;

    reg [2:0] current,next;
    /* possible states: IDLE, CMD_IN, CMD_PROCESS for command received,
    DIN for data from master, DOUT for data to master.
    Commands are: READ_ID=0x1d, READ=0xea, WRITE=0xad.
	ID data  */ 
    parameter IDLE=0, CMD_IN=1, CMD_PROCESS=2, DIN=3, DOUT=4, INVALID=5, CMD_DEBUG=6;
    parameter READ_ID=8'h1d, READ=8'hea, WRITE=8'had;

	initial begin 
		current = IDLE; 
		next = IDLE;
		command = 8'h0;
		bitcount = 8'h0;
		dload = 1'b0;
		end

	/* _cs is to remain asserted during command and data transfer.*/

    always@(posedge clk, negedge _cs) 
     if ( !_cs ) begin
		 if (current == IDLE )
			current <= CMD_IN;	/* on assertion of _cs */
		 else 
			 current <= next;
	 end else current <= IDLE;


	/* state machine transition */

    always@(current or bitcount or _cs)
		if (_cs ) next = IDLE;
		else
        case(current) //full_case
         CMD_IN: begin
                if ( bitcount[3]) begin
                    #1 command = din; //latch in command
			next = CMD_PROCESS;
		  end 
		  else begin 
                  next = CMD_IN;
                  end
		end
	 CMD_PROCESS: begin
		case (command)
		READ_ID: begin
			slave_dout = `DEVICE_ID; //ID is 5A or as defined
			next = DOUT; // transition to DOUT via miso
			dload = 1'b1;
			end
		READ: begin
			slave_dout = 8'hc4; //use this for dummy read for now (FIXME)
			next = DOUT;
			dload = 1'b1;
			end
		WRITE: begin
			next = DIN;
			end
		default: begin 
                      	next = CMD_IN; //FIXME reject invalid cmd
                       	end
		endcase
				end
	DIN: begin
		if ( bitcount[4]  ) begin
			next = CMD_IN;
                end
		else 
		next = DIN;
		end
	DOUT: begin
		if ( bitcount[4] ) begin
			next = CMD_IN;
                end
		else 
		next = DOUT;
		dload = 1'b0;
		end
        endcase


    /* MISO at z if not in DOUT phase. Don't drive it.  */
    assign #1 miso = sout;

    always@(posedge sck, posedge _cs, posedge current )
      if (_cs || current != DOUT) 
       sout <= 1'bz; 
      else
       sout <= dout[7];

    /* sample MOSI bits 
    >--01234567---->---01234567----->
     |--------------------------|   */
    always@(posedge sck, posedge _cs ) begin
		if (_cs ) #1 bitcount <= 8'h0;
        else  begin
    		#1 din <= {din[6:0],mosi};
   	    	#1 bitcount <= bitcount + 1'b1; //count reset on every ?!
            if (bitcount[4]) #1 bitcount <= 4'h1;
         end 
    end
            
    /* Transmit MSB first */
    always@(posedge sck, posedge dload)
		if (dload) 
		 dout <= slave_dout;
		else
		 dout <= {dout[6:0],mosi}; //loop with input data
    
endmodule
