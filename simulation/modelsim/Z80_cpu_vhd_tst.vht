-- Copyright (C) 1991-2012 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- ***************************************************************************
-- This file contains a Vhdl test bench template that is freely editable to   
-- suit user's needs .Comments are provided in each section to help the user  
-- fill out necessary details.                                                
-- ***************************************************************************
-- Generated on "02/17/2013 22:12:52"
                                                            
-- Vhdl Test Bench template for design  :  Z80_cpu
-- 
-- Simulation tool : ModelSim-Altera (VHDL)
-- 

LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;                                

ENTITY Z80_cpu_vhd_tst IS
END Z80_cpu_vhd_tst;
ARCHITECTURE Z80_cpu_arch OF Z80_cpu_vhd_tst IS
-- constants                                                 
-- signals                                                   
SIGNAL ADDR : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL CLK : STD_LOGIC := '0';
SIGNAL DATA : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL HALT : STD_LOGIC;
SIGNAL RESET : STD_LOGIC := '0';
SIGNAL WR : STD_LOGIC;
COMPONENT Z80_cpu
	PORT (
	ADDR : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
	CLK : IN STD_LOGIC;
	DATA : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	HALT : OUT STD_LOGIC;
	RESET : IN STD_LOGIC;
	WR : INOUT STD_LOGIC
	);
END COMPONENT;
BEGIN
	i1 : Z80_cpu
	PORT MAP (
-- list connections between master ports and signals
	ADDR => ADDR,
	CLK => CLK,
	DATA => DATA,
	HALT => HALT,
	RESET => RESET,
	WR => WR
	);
init : PROCESS                                               
-- variable declarations                                     
BEGIN                                                        
        -- code that executes only once        
			wait for 5 ns;
			RESET <= '1';
WAIT;                                                       
END PROCESS init;                                           
always : PROCESS                                              
-- optional sensitivity list                                  
-- (        )                                                 
-- variable declarations                                      
BEGIN                                                         
        -- code executes for every event on sensitivity list  
		wait for 10 ns;
		CLK <= NOT CLK;
                                                     
END PROCESS always;                                          
END Z80_cpu_arch;
