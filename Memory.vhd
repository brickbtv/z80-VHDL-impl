library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Memory is 
	port (
			ADDR: 		in 	std_logic_vector(15 downto 0);	-- адрес
			DATA_IN:		in 	std_logic_vector(7 downto 0);		-- 
			DATA_OUT:	out 	std_logic_vector(7 downto 0);		-- 
			CLK:		 	in 	std_logic;								-- синхросигнал
			WR:			in 	std_logic								-- данные поданы на запись
			);
end Memory;

architecture Memory of Memory is 
	subtype word_t is std_logic_vector(7 downto 0);
	type memory_t is array(127 downto 0) of word_t;				-- TODO: расширить до 65535 ячеек
	
	signal ram : memory_t;
--	:= (
--	0 => "11001011",
--	1 => "11000110",
--	
--	2 => "11001011",
--	3 => "11111111",
--	
--	4 => "00000111",
--	
--	
--	
--	5 => "00000011",
--	
--	6 => "11011101",
--	
--	7 => "00111100",
--	8 => "01110110",
--
--	9 => "11001001",	
--	
--	10 => "00101010", 
--	11 => "00000000",
--	12 => "00111111",
--	
--	13 => "11011001",
--	14 => "00000000",
--	
--	others => "00000000");
	
	signal	ADDR_r		: std_logic_vector(15 downto 0);
begin 
	process(CLK)
	begin
		if(rising_edge(CLK)) then
			if(WR = '1') then		-- запись разрешена
				ram(to_integer(unsigned(ADDR))) <= DATA_IN;
			end if;	
			ADDR_r <= ADDR;
		end if;
	end process;
	
	DATA_OUT <= ram(to_integer(unsigned(ADDR))); 			-- выдавать данные по сохранённому адресу
end Memory;