library ieee;
use ieee.std_logic_1164.all;

entity Z80_top is
	port (
				RESET:in 		std_logic;								-- сброс
				CLK:	in 		std_logic;								-- такт
				
				-- DBG
				LED:   out 		std_logic_vector(15 downto 0);	
				
				-- rs232
				RXD                	:    in        Std_Logic;               	        -- RX pin
				TXD                	:    out     	Std_Logic	                       -- TX pin
			);	
end entity;

architecture RTL of Z80_top is 
	component Z80_cpu 
		port (
					ADDR: inout 		std_logic_vector(15 downto 0);	-- адресная шина
					DATA: in 		std_logic_vector(7 downto 0);		-- шина данных
					WR:	out 		std_logic;								-- запись
					DATA_OUT: out 	std_logic_vector(7 downto 0);		
					
					RESET:in 		std_logic;								-- сброс
					CLK:	in 		std_logic;								-- такт
					
					-- DBG
					LED:   out 		std_logic_vector(15 downto 0);	
					
					-- rs232
					RXD                	:    in        Std_Logic;               	        -- RX pin
					TXD                	:    out     	Std_Logic	                       -- TX pin
				);	
	end component;


	component Memory
		port (
					ADDR: 		in 	std_logic_vector(15 downto 0);	-- адрес
					DATA_IN:		in 	std_logic_vector(7 downto 0);		-- 
					DATA_OUT:	out 	std_logic_vector(7 downto 0);		-- 
					CLK:		 	in 	std_logic;								-- синхросигнал
					WR:			in 	std_logic								-- данные поданы на запись
				);
	end component Memory;

	signal s_ADDR : std_logic_vector(15 downto 0);
	signal s_DATA : std_logic_vector(7 downto 0);
	signal s_DATA_OUT : std_logic_vector(7 downto 0);
	signal s_WR : std_logic;
begin 
	Mem1: Memory port map 	(
										ADDR 		=> s_ADDR,
										DATA_IN	=> s_DATA_OUT,
										DATA_OUT => s_DATA,
										WR 		=> s_WR,
										CLK 		=> CLK
									);
	
	Z80: Z80_cpu port map 	(
										ADDR 		=> s_ADDR,
										DATA     => s_DATA,
										WR	      => s_WR,
										DATA_OUT => s_DATA_OUT,
										RESET    =>	RESET,
										CLK	   => CLK,
										
										-- DBG
										LED   	=>	LED,
										
										-- rs232
										RXD      => RXD,   	
										TXD      => TXD   
									);
	
end architecture;