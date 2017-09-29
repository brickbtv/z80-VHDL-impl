library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity ALU is 
	port(
			OP8_A : in std_logic_vector(7 downto 0);
			OP8_B : in std_logic_vector(7 downto 0);
			
			CLK	: in std_logic;
			
			OP16_A : in std_logic_vector(15 downto 0);
			OP16_B : in std_logic_vector(15 downto 0);
			
			CODE : in std_logic_vector(3 downto 0);
			RAZR : in std_logic;								-- 0 - 8 разрядов	 			1- 16 разрядов 
			
			RES8 : out std_logic_vector(7 downto 0);
			RES16 : out std_logic_vector(15 downto 0);
			
			FLAGS : 	out std_logic_vector(7 downto 0)
			);
end entity;

architecture ALU of ALU is 
	-- флаги
	constant FLAG_S: integer := 7;
	constant FLAG_Z: integer := 6;
	constant FLAG_H: integer := 4;
	constant FLAG_P: integer := 2;
	constant FLAG_V: integer := 2;
	constant FLAG_N: integer := 1;
	constant FLAG_C: integer := 0;

	procedure Analyze(variable test: std_logic_vector (8 downto 0)) is 
	variable f_C : std_logic;
	begin
		FLAGS(FLAG_S) <= test(7);
		if (test = "000000000") then 
			FLAGS(FLAG_Z) <= '1';
		else 
			FLAGS(FLAG_Z) <= '0';
		end if;
		
		if (test(8) = '1') then 	-- переполнение 
			FLAGS(FLAG_C) <= '1';
			f_C := '1';
		else 
			FLAGS(FLAG_C) <= '0';
			f_C := '0';
		end if;
		
		if (f_C = '1' AND (OP8_A(7) = '0' AND test(7) = '1'))	then		-- был перенос из 6 в 7 разряд
			FLAGS(FLAG_V) <= '1';
		else 
			FLAGS(FLAG_V) <= '0';
		end if;
		
		if (f_C = '0' AND (OP8_A(7) = '0' AND test(7) = '0'))	then		-- не было переноса из 6 в 7 разряд
			FLAGS(FLAG_V) <= '1';
		else 
			FLAGS(FLAG_V) <= '0';
		end if;
	end;
	
begin 
	process (CLK)
		variable Temp: std_logic_vector(8 downto 0);
	begin
		if(rising_edge(CLK)) then
			case RAZR is
				-- 8и битные команды
				when '0' =>
					case CODE is 
						when "0000" =>					-- ADD
							RES8 <= OP8_A + OP8_B;
							
							Temp(7 downto 0) := OP8_A + OP8_B;
							if (OP8_A(7) = '1' AND OP8_B(7) = '1') then 	-- переполнение 
								Temp(8) := '1';
							end if;
							Analyze(Temp);
							
							FLAGS(FLAG_N) <= '0';
																				
						when "0001" =>					-- ADC
							RES8 <= OP8_A + OP8_B;
							
							Temp(7 downto 0) := OP8_A + OP8_B;
							if (OP8_A(7) = '1' AND OP8_B(7) = '1') then 	-- переполнение 
								Temp(8) := '1';
							end if;
							Analyze(Temp);
							
							FLAGS(FLAG_N) <= '0';
							
						when "0010" =>					-- SUB
							RES8 <= OP8_A - OP8_B;
							
							Temp(7 downto 0) := OP8_A - OP8_B;
							if (OP8_A < OP8_B) then 	-- заём
								Temp(8) := '1';
							end if;
							Analyze(Temp);
							
							FLAGS(FLAG_N) <= '1';
						when "0011" =>					-- SBC
							RES8 <= OP8_A - OP8_B;
							
							Temp(7 downto 0) := OP8_A - OP8_B;
							if (OP8_A < OP8_B) then 	-- заём
								Temp(8) := '1';
							end if;
							Analyze(Temp);
							
							FLAGS(FLAG_N) <= '1';
						when "0100" =>					-- AND
							RES8 <= OP8_A and OP8_B;
							
							Temp(7 downto 0) := OP8_A and OP8_B;
							Analyze(Temp);
							
							FLAGS(FLAG_N) <= '0';
							FLAGS(FLAG_H) <= '1';
							FLAGS(FLAG_C) <= '0';
						when "0110" =>					-- OR
							RES8 <= OP8_A or OP8_B;
							
							Temp(7 downto 0) := OP8_A or OP8_B;
							Analyze(Temp);
							
							FLAGS(FLAG_N) <= '0';
							FLAGS(FLAG_H) <= '0';
							FLAGS(FLAG_C) <= '0';
						when "0101" =>					-- XOR
							RES8 <= OP8_A xor OP8_B;
							
							Temp(7 downto 0) := OP8_A xor OP8_B;
							Analyze(Temp);
							
							FLAGS(FLAG_N) <= '0';
							FLAGS(FLAG_H) <= '0';
							FLAGS(FLAG_C) <= '0';
						when "0111" =>					-- CP
							RES8 <= OP8_A;
						when "1100" =>					-- INC
							RES8 <= OP8_A + 1;
							
							Temp(7 downto 0) := OP8_A + 1;
							Analyze(Temp);
							
							FLAGS(FLAG_N) <= '0';
						when "1101" =>					-- DEC
							RES8 <= OP8_A - 1;
							
							Temp(7 downto 0) := OP8_A + OP8_B;
							Analyze(Temp);
							
							FLAGS(FLAG_N) <= '1';
						when others =>
							null;
					end case; 
				
				-- 16и битные команды
				when '1' =>
					case CODE is 
						when "0000" =>					-- ADD
							RES16 <= OP16_A + OP16_B;
							
							if (OP16_A(15) = '1' AND OP16_B(15) = '1') then 
								FLAGS(FLAG_C) <= '1';
							else 
								FLAGS(FLAG_C) <= '0';
							end if;
							
							FLAGS(FLAG_N) <= '0';
						when "0001" =>					-- ADС
							RES16 <= OP16_A + OP16_B;
							
							if (OP16_A(15) = '1' AND OP16_B(15) = '1') then 
								FLAGS(FLAG_C) <= '1';
							else 
								FLAGS(FLAG_C) <= '0';
							end if;
							
							temp(7 downto 0) := OP16_A(15 downto 8) + OP16_B(15 downto 8);
							FLAGS(FLAG_S) <= temp(7);
							if (OP16_A + OP16_B = "0000000000000000") then 
								FLAGS(FLAG_Z) <= '1';
							else 
								FLAGS(FLAG_Z) <= '0';
							end if;
							
							FLAGS(FLAG_N) <= '0';
						when "0010" =>					-- SBC
							RES16 <= OP16_A - OP16_B;
							
							if (OP16_A(15) = '1' AND OP16_B(15) = '1') then 
								FLAGS(FLAG_C) <= '1';
							else 
								FLAGS(FLAG_C) <= '0';
							end if;
							
							temp(7 downto 0) := OP16_A(15 downto 8) - OP16_B(15 downto 8);
							FLAGS(FLAG_S) <= temp(7);							
							if (OP16_A - OP16_B = "0000000000000000") then 
								FLAGS(FLAG_Z) <= '1';
							else 
								FLAGS(FLAG_Z) <= '0';
							end if;
							
							FLAGS(FLAG_N) <= '0';
						when "0011" =>					-- INC
							RES16 <= OP16_A + 1;
						when "0100" =>					-- DEC
							RES16 <= OP16_A - 1;
						when others =>
							null;
					end case; 
				when others =>
					null;
			end case;
		end if;
	end process;
end architecture;
