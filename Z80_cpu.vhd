library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity Z80_cpu is 
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
end Z80_cpu;

architecture Z80 of Z80_cpu is
	
	component ALU 
		port(
					OP8_A : 	in std_logic_vector(7 downto 0);
					OP8_B : 	in std_logic_vector(7 downto 0);
					
					CLK	: 	in std_logic;
					
					OP16_A : in std_logic_vector(15 downto 0);
					OP16_B : in std_logic_vector(15 downto 0);
					
					CODE : 	in std_logic_vector(3 downto 0);
					RAZR : 	in std_logic;								-- 0 - 8 разрядов	 			1- 16 разрядов 
					
					RES8 : 	out std_logic_vector(7 downto 0);
					RES16 : 	out std_logic_vector(15 downto 0);
					
					FLAGS : 	out std_logic_vector(7 downto 0)
				);
	end component;	
	
	component UART  
     port (     
					CLK               	:    in        Std_Logic;                        -- system clk
					RST_N               	:    in        Std_Logic;                           -- system reset#
					DATA_IN            	:    in        Std_Logic_Vector(7 downto 0);    -- Data to transmit
					DATA_OUT            	:    out    	Std_Logic_Vector(7 downto 0);    -- Recieved data    
					RX_VALID           	:    out    	Std_Logic;                        -- RX buffer data ready
					TX_VALID            	:    in        Std_Logic;                        -- Data for    TX avaible                 
					RXD                	:    in        Std_Logic;                        -- RX pin
					TXD                	:    out     	Std_Logic ;                       -- TX pin
					TX_BUSY            	:    out     	Std_Logic ;                       -- TX pin
					RX_BUSY					:    out     	Std_Logic;
					NEW_DATA_ON_THIS_CLK :	  out 		std_logic;
					TRNSMITTED_ON_THIS_CLK: out std_logic
        );
	end component;

	-- внутренние регистры процессора
	signal PC: 			std_logic_vector(15 downto 0);	-- Program Counter 
	signal SP: 			std_logic_vector(15 downto 0);	-- Stack Pointer  TODO: 65535!
	signal IX, IY: 	std_logic_vector(15 downto 0);	-- Index Registers - адресация
	signal I: 			std_logic_vector(7 downto 0);		-- Interrupt Vector 
	signal R: 			std_logic_vector(7 downto 0);		-- Refresh Register 
	
	-- регистры досутпные программно (блок главных регистров + блок вспомогательных (индекс 's'))
	signal A,  B,  C,  D,  E,  H,  L: std_logic_vector(7 downto 0);
	signal As, Bs, Cs, Ds, Es, Hs, Ls: std_logic_vector(7 downto 0);
	
	signal F:  std_logic_vector(7 downto 0);
	signal Fs: std_logic_vector(7 downto 0);
	-- флаги
	constant FLAG_S: integer := 7;
	constant FLAG_Z: integer := 6;
	constant FLAG_H: integer := 4;
	constant FLAG_P: integer := 2;
	constant FLAG_V: integer := 2;
	constant FLAG_N: integer := 1;
	constant FLAG_C: integer := 0;
	
	-- обмен данными
	signal programm_loaded: std_logic := '0';
	signal next_step: std_logic := '0';
	signal without_stopping: std_logic := '0';

	-- внутренние сигналы 
	signal OP8_A : 	std_logic_vector(7 downto 0);
	signal OP8_B : 	std_logic_vector(7 downto 0);
		
	signal OP16_A : 	std_logic_vector(15 downto 0);
	signal OP16_B : 	std_logic_vector(15 downto 0);
	
	signal CODE : 		std_logic_vector(3 downto 0);
	signal RAZR : 		std_logic;								-- 0 - 8 разрядов	 			1- 16 разрядов 
	
	signal RES8 : 		std_logic_vector(7 downto 0);
	signal RES16 : 	std_logic_vector(15 downto 0);
	
	-- rs232
	signal rs_DATA_IN  :   Std_Logic_Vector(7 downto 0); 
	signal rs_DATA_OUT :   Std_Logic_Vector(7 downto 0); 
	signal rs_RX_VALID :   Std_Logic;                    
	signal rs_TX_VALID :   Std_Logic;                                
	signal rs_TX_BUSY  :   Std_Logic;                   
	signal rs_RX_BUSY	 :	  Std_Logic;	
	signal rs_RESET	 :	  Std_Logic := '0';	
	signal rs_NEW_DATA :   Std_Logic := '0';
	signal rs_TRANSMITTED: Std_Logic := '0';
	
	signal new_rx_data : std_logic := '0';

begin
								
	Alu1: ALU port map (
									OP8_A 	=> OP8_A,
									OP8_B 	=> OP8_B,
									CLK 		=> CLK,
									
									OP16_A 	=> OP16_A,
									OP16_B 	=>	OP16_B, 
									
									CODE 		=> CODE,
									RAZR     => RAZR,  
									RES8 		=> RES8,     
									RES16    => RES16 									
								);					
									
	Uart1: UART port map  (
									CLK      =>	CLK,
									RST_N    =>	rs_RESET,
									DATA_IN  =>	rs_DATA_IN,
									DATA_OUT =>	rs_DATA_OUT,
									RX_VALID =>	rs_RX_VALID,
									TX_VALID => rs_TX_VALID,
									RXD      =>	RXD,
									TXD      => TXD,
									TX_BUSY  => rs_TX_BUSY,
									RX_BUSY	=> rs_RX_BUSY,	
									NEW_DATA_ON_THIS_CLK => rs_NEW_DATA,
									TRNSMITTED_ON_THIS_CLK => rs_TRANSMITTED
									);
									
	-- основной цикл работы
	main: process (CLK, RESET)
		variable OpCode: std_logic_vector(7 downto 0) := "00000000";	-- код исполняемой команды
		variable Operand1, Operand2, Operand3, Operand4: std_logic_vector(7 downto 0) := "00000000";	-- хранилище операндов 
		
		variable CommandRunned: bit := '0';										-- флаг выполнения команды
		
		variable add_to_PC: integer := 1;										-- байт в команде
		variable MCycle: integer := 0;											-- номер текущего такта в команде
		variable SecCycle: integer := -1;										-- номер текущего такта для IX и IY команд 
		variable IXorIY: integer := 0;											-- 0 - IX, 1 - IY
		
		variable SSS, DDD: std_logic_vector(2 downto 0) := "000";		-- регистр источник, приёмник (8 бит)
		variable SS, DD: std_logic_vector(1 downto 0) := "00";			-- регистр источник, приёмник (16 бит)
				
		variable PairValue : std_logic_vector(15 downto 0) := "0000000000000000";	-- переменная, значение которой заносится в регистровую пару 
				
		-- получить значение регистра по его индексу
		impure function get_reg_val(RegIn: std_logic_vector) return std_logic_vector is 
		begin
			case RegIn(2 downto 0) is 
				when "111" => 
					return A;
				when "000" => 
					return B;
				when "001" => 
					return C;
				when "010" => 
					return D;
				when "011" => 
					return E;
				when "100" => 
					return H;
				when "101" => 
					return L;
				when others =>
					return "00000000";
			end case;
			
			return "00000000";
		end function;
		
		-- получить значение пары регистров по его индексу
		impure function get_reg_pair_val_dd(RegIn: std_logic_vector) return std_logic_vector is 
		begin
			case RegIn(1 downto 0) is 
				when "00" => 
					return B & C;
				when "01" => 
					return D & E;
				when "10" => 
					return H & L;
				when "11" => 
					return SP;
				when others =>
					return "0000000000000000";
			end case;
			return "0000000000000000";
		end function;
		
		impure function get_reg_pair_val_qq(RegIn: std_logic_vector) return std_logic_vector is 
		begin
			case RegIn(1 downto 0) is 
				when "00" => 
					return B & C;
				when "01" => 
					return D & E;
				when "10" => 
					return H & L;
				when "11" => 
					return A & F;
				when others =>
					return "0000000000000000";
			end case;
			return "0000000000000000";
		end function;
				
		impure function get_reg_pair_val_pp(RegIn: std_logic_vector) return std_logic_vector is 
		begin
			case RegIn(1 downto 0) is 
				when "00" => 
					return B & C;
				when "01" => 
					return D & E;
				when "10" => 
					return IX;
				when "11" => 
					return SP;
				when others =>
					return "0000000000000000";
			end case;
			return "0000000000000000";
		end function;
		
				
		impure function get_reg_pair_val_rr(RegIn: std_logic_vector) return std_logic_vector is 
		begin
			case RegIn(1 downto 0) is 
				when "00" => 
					return B & C;
				when "01" => 
					return D & E;
				when "10" => 
					return IY;
				when "11" => 
					return SP;
				when others =>
					return "0000000000000000";
			end case;
			return "0000000000000000";
		end function;
		
		-- процедура копирования значения одного регистра в другой регистр
		procedure copy_reg(variable SrcIndex, DstIndex: std_logic_vector(2 downto 0)) is 
		begin
			case DstIndex is 
				when "111" => 
					A <= get_reg_val(SrcIndex);
				when "000" => 
					B <= get_reg_val(SrcIndex);
				when "001" => 
					C <= get_reg_val(SrcIndex);
				when "010" => 
					D <= get_reg_val(SrcIndex);
				when "011" => 
					E <= get_reg_val(SrcIndex);
				when "100" => 
					H <= get_reg_val(SrcIndex);
				when "101" => 
					L <= get_reg_val(SrcIndex);
				when others =>
					null;
			end case;
		end procedure;
		
		-- процедура занесения 8 битного операдна в регистр по его индексу
		procedure set_reg(variable RegIndex: std_logic_vector(2 downto 0); signal ValToReg: std_logic_vector(7 downto 0)) is 
		begin
			case RegIndex is 
				when "111" => 
					A <= ValToReg;
				when "000" => 
					B <= ValToReg;
				when "001" => 
					C <= ValToReg;
				when "010" => 
					D <= ValToReg;
				when "011" => 
					E <= ValToReg;
				when "100" => 
					H <= ValToReg;
				when "101" => 
					L <= ValToReg;
				when others =>
					null;
			end case;
		end procedure;
				
		-- процедура занесения 16 битного операдна в пару регистров по её индексу
		procedure set_pair_dd(variable RegIndex: std_logic_vector(1 downto 0); variable ValToReg: std_logic_vector(15 downto 0)) is 
		begin
			case RegIndex is 
				when "00" => 
					B <= ValToReg(15 downto 8);
					C <= ValToReg(7 downto 0);
				when "01" => 
					D <= ValToReg(15 downto 8);
					E <= ValToReg(7 downto 0);
				when "10" => 
					H <= ValToReg(15 downto 8);
					L <= ValToReg(7 downto 0);
				when "11" => 
					SP <= ValToReg;
				when others =>
					null;
			end case;
		end procedure;
		
		procedure set_pair_qq(variable RegIndex: std_logic_vector(1 downto 0); variable ValToReg: std_logic_vector(15 downto 0)) is 
		begin
			case RegIndex is 
				when "00" => 
					B <= ValToReg(15 downto 8);
					C <= ValToReg(7 downto 0);
				when "01" => 
					D <= ValToReg(15 downto 8);
					E <= ValToReg(7 downto 0);
				when "10" => 
					H <= ValToReg(15 downto 8);
					L <= ValToReg(7 downto 0);
				when "11" => 
					A <= ValToReg(15 downto 8);
					F <= ValToReg(7 downto 0);
				when others =>
					null;
			end case;
		end procedure;
		
		procedure set_pair_pp(variable RegIndex: std_logic_vector(1 downto 0); variable ValToReg: std_logic_vector(15 downto 0)) is 
		begin
			case RegIndex is 
				when "00" => 
					B <= ValToReg(15 downto 8);
					C <= ValToReg(7 downto 0);
				when "01" => 
					D <= ValToReg(15 downto 8);
					E <= ValToReg(7 downto 0);
				when "10" => 
					IX <= ValToReg;
				when "11" => 
					SP <= ValToReg;
				when others =>
					null;
			end case;
		end procedure;
		
		procedure set_pair_rr(variable RegIndex: std_logic_vector(1 downto 0); variable ValToReg: std_logic_vector(15 downto 0)) is 
		begin
			case RegIndex is 
				when "00" => 
					B <= ValToReg(15 downto 8);
					C <= ValToReg(7 downto 0);
				when "01" => 
					D <= ValToReg(15 downto 8);
					E <= ValToReg(7 downto 0);
				when "10" => 
					IY <= ValToReg;
				when "11" => 
					SP <= ValToReg;
				when others =>
					null;
			end case;
		end procedure;
		
		-- конвертация std_logic в integer
		function to_int(x: std_logic) return integer is
		begin
			if x='1' then 
				return 1;
			else 
				return 0; 
			end if;
		end;
		
		-- инкремент/декремент пары 
		procedure inc_pair(variable pair: std_logic_vector(1 downto 0)) is 
		variable temp : std_logic_vector (15 downto 0);
		begin
			temp := get_reg_pair_val_dd(pair);
			temp := temp + 1;
			set_pair_dd(pair, temp);
		end;
		
		procedure dec_pair(variable pair: std_logic_vector(1 downto 0)) is 
		variable temp : std_logic_vector (15 downto 0);
		begin
			temp := get_reg_pair_val_dd(pair);
			temp := temp - 1;
			set_pair_dd(pair, temp);
		end;
		
		-- проверка условия 
		impure function check_cc(cc: std_logic_vector(2 downto 0)) return integer is 
		begin
			case cc is 
				when "000" =>						-- ноль
					if (F(FLAG_Z) = '1') then 
						return 1;
					end if;
				when "001" =>						-- не ноль
					if (F(FLAG_Z) = '0') then 
						return 1;
					end if;
				when "010" =>						-- нет переноса
					if (F(FLAG_C) = '0') then 
						return 1;
					end if;
				when "011" =>						-- перенос
					if (F(FLAG_C) = '1') then 
						return 1;
					end if;
				when "100" =>						-- не четность
					if (F(FLAG_P) = '0') then 
						return 1;
					end if;
				when "101" =>						-- четность
					if (F(FLAG_P) = '1') then 
						return 1;
					end if;
				when "110" =>						-- знак +
					if (F(FLAG_S) = '0') then 
						return 1;
					end if;
				when "111" =>						-- знак -
					if (F(FLAG_S) = '1') then 
						return 1;
					end if;
				when others => null;
			end case;
			
			return 0;
		end;		
		
		-- сдвиг и вращение 
		impure function shift_rotate(TempReg:std_logic_vector(7 downto 0); ShType:std_logic_vector(2 downto 0)) return std_logic_vector is 
		
		begin 
			case (ShType) is 
				when "000" => 					-- RLC
					F(FLAG_C) <= TempReg(7);
					return TempReg(6 downto 0) & TempReg(7);
				when "001" => 					-- RL
					F(FLAG_C) <= TempReg(7); 
					return TempReg(6 downto 0) & F(FLAG_C);
				when "010" => 					-- RRC
					F(FLAG_C) <= TempReg(0);
					return TempReg(0) & TempReg(7 downto 1);
				when "011" => 					-- RR
					F(FLAG_C) <= TempReg(0);
					return F(FLAG_C) & TempReg(7 downto 1);
				when "100" =>					-- SLA
					F(FLAG_C) <= TempReg(7);
					return TempReg(6 downto 0) & '0';
				when "101" =>					-- SRA
					F(FLAG_C) <= TempReg(0);
					return TempReg(7) & TempReg(7 downto 1);
				when "111" => 					-- SRL
					F(FLAG_C) <= TempReg(0);
					return '0' & TempReg(7 downto 1);
				when others => 
					return "00000000";
			end case;
		end;
			
		variable prog_load_counter : integer;	
		variable prog_load_transmitted : std_logic := '0';
		variable debug_counter: integer := 0;
		variable transmitting_reg_started: std_logic := '0';
		variable recieving_reg_started: std_logic := '0';
		variable recieving_reg_counter: integer := 0;
		variable recieving_RAM_started: std_logic := '0';
		variable recieving_RAM_counter: integer := 0;
		variable ADDR_saver :std_logic_vector(15 downto 0) := "0000000000000000";
	begin
		
			if (RESET = '0') then 
				PC 	<= (others => '0');
				ADDR 	<= (others => '1');		-- для загрузки программы
				A 		<= (others => '0');
				B 		<= (others => '0');
				C 		<= (others => '0');
				D 		<= (others => '0');
				E 		<= (others => '0');
				H 		<= (others => '0');
				L 		<= (others => '0');
				
				SP 	<= "0000000001111111";
				F 		<= (others => '0');
				Fs		<= (others => '0');
				IX		<= (others => '0');
				IY		<= (others => '0');
				
				WR		<= '1';		-- после сброса записываем программу в память
				
				MCycle := 0;
				SecCycle := 0;
				CommandRunned := '0';
				
				rs_RESET <= '1';
				rs_DATA_IN <= "01101111";
				rs_TX_VALID <= '0';
				prog_load_transmitted := '0';
				programm_loaded <= '0';
				prog_load_counter := 0;
				
				next_step <= '0';
				debug_counter := 0;
				
				transmitting_reg_started := '0';
				without_stopping <= '0';
				
				recieving_reg_started := '0';
				recieving_reg_counter := 0;
				
				recieving_RAM_started := '0';
				recieving_RAM_counter := 0;
				
				LED 	<= (others => '0');
			elsif (rising_edge(CLK)) then
				
				if (prog_load_transmitted ='0') then  
					rs_TX_VALID <= '1';
					prog_load_transmitted := '1';
				else 
					rs_TX_VALID <= '0';
				end if;
				
				if (rs_NEW_DATA = '1' and transmitting_reg_started = '0') then 
					case rs_DATA_IN is 
						when "01101111" => 			-- запрос программы
							if (prog_load_counter < 120) then 
								WR <= '1';
								ADDR <= ADDR + 1;
								--LED <= std_logic_vector(to_unsigned(prog_load_counter, LED'length));
								LED(7 downto 0) <= ADDR(7 downto 0) + 1;
								DATA_OUT <= rs_DATA_OUT;
							end if;
							
							prog_load_counter := prog_load_counter + 1;
							
							if (prog_load_counter = 120) then			-- программа загружена
								WR <= '0';
								programm_loaded <= '1';
								rs_DATA_IN <= "00000000";
								ADDR <= "0000000000000000";
								
								
								next_step <= '0';
							
								rs_DATA_IN <= "01110000";
								rs_TX_VALID <= '1';
								transmitting_reg_started := '1';
							end if;
							
						when "00000000" =>			-- ожидание произвольных команд извне
							if (rs_DATA_OUT = "11001111") then 		-- шаг
								next_step <= '1';
								ADDR <= PC;--ADDR_saver;
							end if;
							
							if (rs_DATA_OUT = "11010000") then 		-- выполнить до конца
								next_step <= '1';
								without_stopping <= '1';
							end if;
							
							if (rs_DATA_OUT = "11010001") then 		-- установить значения регистров 
								recieving_reg_started := '1';
								next_step <= '0';
								rs_DATA_IN <= "11010001";
							end if;
							
							if (rs_DATA_OUT = "11010010") then 	 	-- установить память
								recieving_RAM_started := '1';
								next_step <= '0';
								rs_DATA_IN <= "11010010";
								ADDR_saver := ADDR;
								ADDR <= "1111111111111111";
							end if;
							
						when "11010001" =>			-- получение новых значений регистров 
							if (recieving_reg_counter < 16) then 
								LED(15) <= '1';
								case recieving_reg_counter is 
									when 0 => 
										A <= rs_DATA_OUT;
									when 1 => 
										B <= rs_DATA_OUT;
									when 2 => 
										C <= rs_DATA_OUT;
									when 3 => 
										D <= rs_DATA_OUT;
									when 4 => 
										E <= rs_DATA_OUT;
									when 5 => 
										H <= rs_DATA_OUT;
									when 6 => 
										L <= rs_DATA_OUT;
									when 7 => 
										PC(15 downto 8) <= rs_DATA_OUT;
									when 8 => 
										PC(7 downto 0) <= rs_DATA_OUT;
									when 9 => 
										SP(15 downto 8) <= rs_DATA_OUT;
									when 10 => 
										SP(7 downto 0) <= rs_DATA_OUT;
									when 11 => 
										IX(15 downto 8) <= rs_DATA_OUT;
									when 12 => 
										IX(7 downto 0) <= rs_DATA_OUT;
									when 13 => 
										IY(15 downto 8) <= rs_DATA_OUT;
									when 14 => 
										IY(7 downto 0) <= rs_DATA_OUT;	
									when 15 => 
										F <= rs_DATA_OUT;
									when others => null;
								end case;
							end if;
							
							recieving_reg_counter := recieving_reg_counter + 1;
							
							if (recieving_reg_counter = 16) then 
								recieving_reg_started := '0';
								recieving_reg_counter := 0;
								rs_DATA_IN <= "00000000";
								
								LED(15) <= '0';
							end if;
						
						when "11010010" =>			-- получение новых значений памяти
							if (recieving_RAM_counter < 30) then 
								LED(11) <= '1';
								WR <= '1';
								ADDR <= ADDR + 1;
								DATA_OUT <= rs_DATA_OUT;
							end if;
							
							recieving_RAM_counter := recieving_RAM_counter + 1;
							
							if (recieving_RAM_counter = 30) then 
								recieving_RAM_started := '0';
								recieving_RAM_counter := 0;
								rs_DATA_IN <= "00000000";
								WR <= '0';
								ADDR <= ADDR_saver;
								LED(11) <= '0';
							end if;
						when others => null;
					end case; 	
				end if;	
				
				-- отправка значений регистров 
				if ((next_step = '0' and without_stopping = '0') and rs_TX_VALID = '0' and transmitting_reg_started = '1' and rs_TRANSMITTED = '1') then 
					
					
					
					case debug_counter is 
						when 0 => 
							rs_DATA_IN <= A;
							rs_TX_VALID <= '1';
							
							ADDR_saver := ADDR;
							ADDR <= "0000000000000000";
						when 1 => 
							rs_DATA_IN <= B;
							rs_TX_VALID <= '1';
						when 2 => 
							rs_DATA_IN <= C;
							rs_TX_VALID <= '1';
						when 3 => 
							rs_DATA_IN <= D;
							rs_TX_VALID <= '1';
						when 4 => 
							rs_DATA_IN <= E;
							rs_TX_VALID <= '1';
						when 5 => 
							rs_DATA_IN <= H;
							rs_TX_VALID <= '1';
						when 6 => 
							rs_DATA_IN <= L;
							rs_TX_VALID <= '1';
						when 7 => 
							rs_DATA_IN <= SP(15 downto 8);
							rs_TX_VALID <= '1';
						when 8 => 
							rs_DATA_IN <= SP(7 downto 0);
							rs_TX_VALID <= '1';
						when 9 => 
							rs_DATA_IN <= PC(15 downto 8);
							rs_TX_VALID <= '1';
						when 10 => 
							rs_DATA_IN <= PC(7 downto 0);
							rs_TX_VALID <= '1';
						when 11 => 
							rs_DATA_IN <= IX(15 downto 8);
							rs_TX_VALID <= '1';
						when 12 => 
							rs_DATA_IN <= IX(7 downto 0);
							rs_TX_VALID <= '1';
						when 13 => 
							rs_DATA_IN <= IY(15 downto 8);
							rs_TX_VALID <= '1';
						when 14 => 
							rs_DATA_IN <= IY(7 downto 0);
							rs_TX_VALID <= '1';
						when 15 => 
							rs_DATA_IN <= F;
							rs_TX_VALID <= '1';
							
							
						when  16|17|18|19|20|21|22|23|24|25|
								26|27|28|29|30|31|32|33|34|35|
								36|37|38|39|40|41|42|43|44|45 => 
							-- отправка 30 значений памяти 
							rs_DATA_IN <= DATA;
							rs_TX_VALID <= '1';
						when 46 => 
							--next_step <= '1';
							rs_DATA_IN <= "00000000";
							rs_TX_VALID <= '1';
							transmitting_reg_started := '0';
						when others => 
							null;
					end case;
					if (debug_counter < 47 and rs_TRANSMITTED = '1') then 
						debug_counter := debug_counter + 1;
						if (debug_counter > 16) then 
							ADDR <= ADDR + 1;
						end if;
					end if;
				end if;
				
				LED(13) <= programm_loaded;
				--LED(14) <= WR;
				LED(12) <= next_step;
				
				LED(10) <= '0';
				-- работать только после загрузки программы
				if (programm_loaded = '1' AND (next_step = '1' OR without_stopping = '1')) then 
					LED(10) <= '1';
						-- сброс значений при обработке новой команды
					if (CommandRunned = '0') then 
						CommandRunned := '1';
						OpCode := DATA;
						MCycle := 0;
					end if; 
						
					LED(7 downto 0)<= A(7 downto 0);		
					
					case OpCode is 
						-- 																	--
						--					8 битовые команды загрузки					--
						--																		--
					
						-- LD r1, r2		01 r1 r2
						when 	"01000000"|"01000001"|"01000010"|"01000011"|"01000100"|"01000101"|"01000111"|
								"01001000"|"01001001"|"01001010"|"01001011"|"01001100"|"01001101"|"01001111"|
								"01010000"|"01010001"|"01010010"|"01010011"|"01010100"|"01010101"|"01010111"|
								"01011000"|"01011001"|"01011010"|"01011011"|"01011100"|"01011101"|"01011111"|
								"01100000"|"01100001"|"01100010"|"01100011"|"01100100"|"01100101"|"01100111"|
								"01101000"|"01101001"|"01101010"|"01101011"|"01101100"|"01101101"|"01101111"|
								"01111000"|"01111001"|"01111010"|"01111011"|"01111100"|"01111101"|"01111111"	=>
							case MCycle is 
								when 0 =>
									DDD := OpCode(5 downto 3);
									SSS := OpCode(2 downto 0);
									copy_reg(SSS, DDD);
									add_to_PC := 1;
									CommandRunned := '0';
								when others => 
									null;
							end case;
					
						-- LD r, (HL)		01 r 110
						when "01111110"|"01000110"|"01001110"|"01010110"|"01011110"|"01100110"|"01101110" =>
							case MCycle is 
								when 0 =>
									DDD := OpCode(5 downto 3);
									add_to_PC := 1;
									ADDR <= H & L;
								when 1 => 
									set_reg(DDD, DATA);
									CommandRunned := '0';
								when others =>
									null;
							end case;				
						
						-- LD (HL), r			01 110 r
						when "01110111"|"01110000"|"01110001"|"01110010"|"01110011"|"01110100"|"01110101" => 
							case MCycle is 
								when 0 =>
									SSS := OpCode(2 downto 0);
									add_to_PC := 1;
									ADDR <= H & L;
									WR <= '1';
									DATA_OUT <= get_reg_val(SSS);
								when 1 => 
									WR <= '0';
									CommandRunned := '0';
								when others =>
									null;
							end case;
						
						
						-- LD r, n			00 r 110
						--						-- n ---
						when "00111110"|"00000110"|"00001110"|"00010110"|"00011110"|"00100110"|"00101110" =>
							case MCycle is 
								when 0 =>
									DDD := OpCode(5 downto 3);
									add_to_PC := 2;
									ADDR <= PC + 1;
								when 1 =>
									set_reg(DDD, DATA);
									CommandRunned := '0';
								when others =>
									null;
							end case;
							
						-- LD (HL), n		00 110 110
						--						--  n  ---
						when "00110110" => 
							case MCycle is 
								when 0 =>
									add_to_PC := 2;
									ADDR <= PC + 1;
								when 1 => 
									WR <= '1';
									ADDR <= H & L;
									DATA_OUT <= DATA;
								when 2 => 
									WR <= '0';
									CommandRunned := '0';
								when others =>
									null;
							end case;
						
						-- LD A, (BC)		00 001 010
						when "00001010" => 
							case MCycle is 
								when 0 =>
									DDD := "111";
									add_to_PC := 1;
									ADDR <= B & C;
								when 1 => 
									set_reg(DDD, DATA);
									CommandRunned := '0';
								when others => 
									null;
							end case;
							
						-- LD A, (DE)		00 011 010
						when "00011010" => 
							case MCycle is 
								when 0 =>
									DDD := "111";
									add_to_PC := 1;
									ADDR <= D & E;
								when 1 => 
									set_reg(DDD, DATA);
									CommandRunned := '0';
								when others => 
									null;
							end case;
							
						-- LD A, (nn)		00 111 010
						when "00111010" => 
							case MCycle is 
								when 0 =>
									DDD := "111";
									add_to_PC := 3;
									ADDR <= PC + 1;
								when 1 =>
									Operand1 := DATA;
									ADDR <= PC + 2;
								when 2 => 
									Operand2 := DATA;
									ADDR <= Operand1 & Operand2;
								when 3 => 
									set_reg(DDD, DATA);
									CommandRunned := '0';
								when others => 
									null;
							end case;
							
						-- LD (BC), A			00 000 010
						when "00000010" => 
							case MCycle is 
								when 0 =>
									SSS := "111";
									add_to_PC := 1;
									ADDR <= B & C;
									WR <= '1';
									DATA_OUT <= get_reg_val(SSS);
								when 1 => 
									WR <= '0';
									CommandRunned := '0';
								when others =>
									null;
							end case;
							
						-- LD (DE), A			00 010 010
						when "00010010" => 
							case MCycle is 
								when 0 =>
									SSS := "111";
									add_to_PC := 1;
									ADDR <= D & E;
									WR <= '1';
									DATA_OUT <= get_reg_val(SSS);
								when 1 => 
									WR <= '0';
									CommandRunned := '0';
								when others =>
									null;
							end case;
							
						-- LD (nn), A			00 110 010
						when "00110010" => 
							case MCycle is 
								when 0 =>
									DDD := "111";
									add_to_PC := 3;
									ADDR <= PC + 1;
								when 1 =>
									Operand1 := DATA;
									ADDR <= PC + 2;
								when 2 => 
									Operand2 := DATA;
									ADDR <= Operand1 & Operand2;
									DATA_OUT <= A;
									WR <= '1';
								when 3 => 
									WR <= '0';
									CommandRunned := '0';
								when others => 
									null;
							end case;
						
						-- LD dd, (nn)			11 101 101					              
						--							01 dd1 011
						--							--	 n	 ---              
						--							--	 n	 ---              

						-- LD с регистрами I, R			11 101 101
						when "11101101" => 
							case MCycle is 
								when 0 => 
									add_to_PC := 2;
									ADDR <= PC + 1;
								when 1 => 
									Operand1 := DATA;
									DD := DATA(5 downto 4);
									ADDR <= ADDR + 1;
								when 2 => 
									Operand2 := DATA;
									ADDR <= ADDR + 1;
								when 3 => 
									Operand3 := DATA;
									SecCycle := 0;
								when 4 =>
									MCycle := MCycle - 1;
									
									case Operand1 is 
										when "01010111" =>		-- LD A, I
											A <= I;
											CommandRunned := '0';
										when "01011111" =>		-- LD A, R
											A <= R;
											CommandRunned := '0';
										when "01000111" =>		-- LD I, A
											I <= A;
											CommandRunned := '0';
										when "01001111" =>		-- LD R, A
											R <= A;
											CommandRunned := '0';
										when "01001011" | "01011011" | "01101011" | "01111011" =>		-- LD dd, (nn)		
											case SecCycle is 
												when 1 => 
													add_to_PC := 4;
													ADDR <= Operand2 & Operand3;
												when 2 =>
													Operand4 := DATA;
													ADDR <= ADDR + 1;
												when 3 =>
													PairValue := DATA & Operand4;
													set_pair_dd(DD, PairValue);
													CommandRunned := '0';
												when others => null;
											end case;
										when "01000011" | "01010011" | "01100011" | "01110011" =>		-- LD (nn), dd											
											case SecCycle is 
												when 1 => 
													add_to_PC := 4;
													WR <= '1';
													ADDR <= Operand2 & Operand3;
													PairValue := get_reg_pair_val_dd(DD);
													DATA_OUT <= PairValue(7 downto 0);
												when 2 => 
													ADDR <= ADDR + 1;
													DATA_OUT <= PairValue(15 downto 8);
												when 3 => 
													WR <= '0';
													commandRunned := '0';
												when others => null;
											end case;
										
										-- 																	--
										--					команды обработки блоков				   --
										--																		--	
										when "10100000" =>											-- LDI
											case SecCycle is 
												when 1 => 
													ADDR <= H & L;
												when 2 => 
													WR <= '1';
													DATA_OUT <= DATA;
													ADDR <= D & E;
												when 3 =>
													WR <= '0';
													SS := "10";	-- HL
													inc_pair(SS);
													SS := "01";	-- DE
													inc_pair(SS);
													SS := "00";	-- BC
													dec_pair(SS);
												when 4 => 
													F(FLAG_H) <= '0';
													F(FLAG_N) <= '0';
													if (get_reg_pair_val_dd(SS) = "0000000000000000") then 		-- флаги
														F(FLAG_P) <= '0';
													else 
														F(FLAG_P) <= '1';
													end if;
													commandRunned := '0';
												when others => null;
											end case;
										
										when "10110000" =>											-- LDIR
											case SecCycle is 
												when 1 => 
													ADDR <= H & L;
												when 2 => 
													WR <= '1';
													DATA_OUT <= DATA;
													ADDR <= D & E;
												when 3 =>
													WR <= '0';
													SS := "10";	-- HL
													inc_pair(SS);
													SS := "01";	-- DE
													inc_pair(SS);
													SS := "00";	-- BC
													dec_pair(SS);
												when 4 => 
													F(FLAG_H) <= '0';
													F(FLAG_N) <= '0';
													F(FLAG_P) <= '0';
													if (get_reg_pair_val_dd(SS) = "0000000000000000") then 		-- флаги
														commandRunned := '0';
													else 
														SecCycle := 0;
													end if;
													
												when others => null;
											end case;
											
										when "10101000" =>											-- LDD
											case SecCycle is 
												when 1 => 
													ADDR <= H & L;
												when 2 => 
													WR <= '1';
													DATA_OUT <= DATA;
													ADDR <= D & E;
												when 3 =>
													WR <= '0';
													SS := "10";	-- HL
													dec_pair(SS);
													SS := "01";	-- DE
													dec_pair(SS);
													SS := "00";	-- BC
													dec_pair(SS);
												when 4 => 
													F(FLAG_H) <= '0';
													F(FLAG_N) <= '0';
													if (get_reg_pair_val_dd(SS) = "0000000000000000") then 		-- флаги
														F(FLAG_P) <= '0';
													else 
														F(FLAG_P) <= '1';
													end if;
													commandRunned := '0';
												when others => null;
											end case;
										
										when "10111000" =>											-- LDDR
											case SecCycle is 
												when 1 => 
													ADDR <= H & L;
												when 2 => 
													WR <= '1';
													DATA_OUT <= DATA;
													ADDR <= D & E;
												when 3 =>
													WR <= '0';
													SS := "10";	-- HL
													dec_pair(SS);
													SS := "01";	-- DE
													dec_pair(SS);
													SS := "00";	-- BC
													dec_pair(SS);
												when 4 => 
													F(FLAG_H) <= '0';
													F(FLAG_N) <= '0';
													F(FLAG_P) <= '0';
													if (get_reg_pair_val_dd(SS) = "0000000000000000") then 		-- флаги
														commandRunned := '0';
													else 
														SecCycle := 0;
													end if;
													
												when others => null;
											end case;
											
										when "10100001" =>											-- CPI
											case SecCycle is 
												when 1 => 
													ADDR <= H & L;
												when 2 => 
													if (A - DATA = 0) then
														F(FLAG_Z) <= '1';
													end if;
													
													if (A - DATA > 0) then 
														F(FLAG_S) <= '0';
														F(FLAG_Z) <= '0';
													end if;
													
													if (A - DATA < 0) then 
														F(FLAG_S) <= '1';
														F(FLAG_Z) <= '0';
													end if;
													
													SS := "00";	-- BC
													dec_pair(SS);
													SS := "10";	-- HL
													inc_pair(SS);
												when 4 => 
													F(FLAG_H) <= '0';
													F(FLAG_N) <= '1';
													if (get_reg_pair_val_dd(SS) = "0000000000000000") then 		-- флаги
														F(FLAG_P) <= '0';
													else 
														F(FLAG_P) <= '1';
													end if;
													commandRunned := '0';
													
												when others => null;
											end case;
											
										when "10110001" =>											-- CPIR
											case SecCycle is 
												when 1 => 
													ADDR <= H & L;
												when 2 => 
													if (A - DATA = 0) then
														F(FLAG_Z) <= '1';
													end if;
													
													if (A - DATA > 0) then 
														F(FLAG_S) <= '0';
														F(FLAG_Z) <= '0';
													end if;
													
													if (A - DATA < 0) then 
														F(FLAG_S) <= '1';
														F(FLAG_Z) <= '0';
													end if;
													
													SS := "00";	-- BC
													dec_pair(SS);
													SS := "10";	-- HL
													inc_pair(SS);
												when 4 => 
													F(FLAG_H) <= '0';
													F(FLAG_N) <= '1';
													if (get_reg_pair_val_dd(SS) = "0000000000000000") then 		-- флаги
														F(FLAG_P) <= '0';
														commandRunned := '0';
													else 
														F(FLAG_P) <= '1';
														SecCycle := 0;
													end if;
													
													if (A - DATA = 0) then
														commandRunned := '0';
													end if;
													
												when others => null;
											end case;
											
										when "10101001" =>											-- CPD
											case SecCycle is 
												when 1 => 
													ADDR <= H & L;
												when 2 => 
													if (A - DATA = 0) then
														F(FLAG_Z) <= '1';
													end if;
													
													if (A - DATA > 0) then 
														F(FLAG_S) <= '0';
														F(FLAG_Z) <= '0';
													end if;
													
													if (A - DATA < 0) then 
														F(FLAG_S) <= '1';
														F(FLAG_Z) <= '0';
													end if;
													
													SS := "00";	-- BC
													dec_pair(SS);
													SS := "10";	-- HL
													dec_pair(SS);
												when 4 => 
													F(FLAG_H) <= '0';
													F(FLAG_N) <= '1';
													if (get_reg_pair_val_dd(SS) = "0000000000000000") then 		-- флаги
														F(FLAG_P) <= '0';
													else 
														F(FLAG_P) <= '1';
													end if;
													commandRunned := '0';
													
												when others => null;
											end case;
											
										when "10111001" =>											-- CPID
											case SecCycle is 
												when 1 => 
													ADDR <= H & L;
												when 2 => 
													if (A - DATA = 0) then
														F(FLAG_Z) <= '1';
													end if;
													
													if (A - DATA > 0) then 
														F(FLAG_S) <= '0';
														F(FLAG_Z) <= '0';
													end if;
													
													if (A - DATA < 0) then 
														F(FLAG_S) <= '1';
														F(FLAG_Z) <= '0';
													end if;
													
													SS := "00";	-- BC
													dec_pair(SS);
													SS := "10";	-- HL
													dec_pair(SS);
												when 4 => 
													F(FLAG_H) <= '0';
													F(FLAG_N) <= '1';
													if (get_reg_pair_val_dd(SS) = "0000000000000000") then 		-- флаги
														F(FLAG_P) <= '0';
														commandRunned := '0';
													else 
														F(FLAG_P) <= '1';
														SecCycle := 0;
													end if;
													
													if (A - DATA = 0) then
														commandRunned := '0';
													end if;
													
												when others => null;
											end case;	
										
										-- 																	--
										--					8 и 16  битовые арифметические команды --
										--																		--
										
										-- NEG
										when "01000100" =>
											case SecCycle is 
												when 1 => 
													add_to_PC := 1;
													A(7) <= not A(7);
													commandRunned := '0';
												when others => null;
											end case;
											
										-- ADC HL, dd
										when "01001010"|"01011010"|"01101010"|"01111010" =>
											case SecCycle is 
												when 1 => 
													add_to_PC := 2;
													SS := Operand1(5 downto 4);
													RAZR <= '1';
													CODE <= "0001";
													OP16_A <= H & L;
													OP16_B <= get_reg_pair_val_dd(SS);
												when 2 => 
													null;
												when 3 =>
													H <= RES16(15 downto 8);
													L <= RES16(7  downto 0);
												
													commandRunned := '0';
												when others => null;
											end case;	
										
										-- SBC HL, dd
										when "01000010"|"01010010"|"01100010"|"01110010" =>
											case SecCycle is 
												when 1 => 
													add_to_PC := 2;
													SS := Operand1(5 downto 4);
													RAZR <= '1';
													CODE <= "0010";
													OP16_A <= H & L;
													OP16_B <= get_reg_pair_val_dd(SS);
												when 2 => 
													null;
												when 3 =>
													H <= RES16(15 downto 8);
													L <= RES16(7  downto 0);
												
													commandRunned := '0';
												when others => null;
											end case;		
											

										-- 																	--
										--					команды сдвига и вращения 					--
										--																		--

										-- RLD
										when "01101111" =>
											case SecCycle is 
												when 1 => 
													add_to_PC := 2; 
													ADDR <= H & L;
												when 2 => 
													R(7 downto 4) <= DATA(3 downto 0);
													R(3 downto 0) <= A(3 downto 0);
													A(3 downto 0) <= DATA(7 downto 4);
												when 3 => 
													WR <= '1';
													DATA_OUT <= R;
												when 4 => 
													WR <= '0';
													CommandRunned := '0';
												when others => 
													null;
											end case;
											
										-- RRD
										when "01100111" =>
											case SecCycle is 
												when 1 => 
													add_to_PC := 2; 
													ADDR <= H & L;
												when 2 => 
													R(3 downto 0) <= DATA(7 downto 4);
													R(7 downto 4) <= A(3 downto 0);
													A(3 downto 0) <= DATA(3 downto 0);
												when 3 => 
													WR <= '1';
													DATA_OUT <= R;
												when 4 => 
													WR <= '0';
													CommandRunned := '0';
												when others => 
													null;
											end case;
										
										-- 																	--
										--					команды ввода/вывода							--
										--																		--
										
										-- IN r, (C)
										
										when  "01000000"|
												"01001000"|
												"01010000"|
												"01011000"|
												"01100000"|
												"01101000"|
												"01111000" =>
											case SecCycle is 
												when 1 => 
													add_to_PC := 2;
													SSS := Operand1(5 downto 3);
													ADDR <= B & C;
												when 2 => 
													set_reg(SSS, DATA);
													
													if (DATA = "00000000") then 
														F(FLAG_Z) <= '1';
													else 
														F(FLAG_Z) <= '0';
													end if;
													
													F(FLAG_S) <= DATA(7);
													F(FLAG_N) <= '0';
																									
													
													commandRunned := '0';
												when others => 
													null;
											end case;
										
										-- INF
										when "10100010" =>	
											case SecCycle is 
												when 1 =>
													add_to_PC := 2;
													ADDR <= B & C;
												when 2 => 
													F <= DATA;
													
													commandRunned := '0';
												when others => 
													null;
											end case;	
											
										-- INI
										when "01110000" =>	
											case SecCycle is 
												when 1 =>
													add_to_PC := 2;
													ADDR <= B & C;
												when 2 => 
													SS := "10";
												
													DATA_OUT <= DATA;
													ADDR <= H & L;
													WR <= '1';
												when 3 => 
													WR <= '0';
													B <= B - 1;
													inc_pair(SS);
													
													if (DATA = "00000000") then 
														F(FLAG_Z) <= '1';
													else 
														F(FLAG_Z) <= '0';
													end if;
													
													F(FLAG_N) <= '0';
													
													commandRunned := '0';
												when others => 
													null;
											end case;
										
										-- INIR
										when "10110010" =>	
											case SecCycle is 
												when 1 =>
													add_to_PC := 2;
													ADDR <= B & C;
												when 2 => 
													SS := "10";
												
													DATA_OUT <= DATA;
													ADDR <= H & L;
													WR <= '1';
												when 3 => 
													WR <= '0';
													B <= B - 1;
													
													if (B - 1 > 0) then 
														SecCycle := 0;
													else 
														commandRunned := '0';
														
														F(FLAG_Z) <= '1';
														F(FLAG_N) <= '1';
													end if; 
													inc_pair(SS);
												when others => 
													null;
											end case;
									
										-- IND
										when "10101010" =>	
											case SecCycle is 
												when 1 =>
													add_to_PC := 2;
													ADDR <= B & C;
												when 2 => 
													SS := "10";
												
													DATA_OUT <= DATA;
													ADDR <= H & L;
													WR <= '1';
												when 3 => 
													WR <= '0';
													B <= B - 1;
													dec_pair(SS);
													
													if (DATA = "00000000") then 
														F(FLAG_Z) <= '1';
													else 
														F(FLAG_Z) <= '0';
													end if;
													
													F(FLAG_N) <= '1';
													
													commandRunned := '0';
												when others => 
													null;
											end case;
										
										-- INDR
										when "10111010" =>	
											case SecCycle is 
												when 1 =>
													add_to_PC := 2;
													ADDR <= B & C;
												when 2 => 
													SS := "10";
												
													DATA_OUT <= DATA;
													ADDR <= H & L;
													WR <= '1';
												when 3 => 
													WR <= '0';
													B <= B - 1;
													
													if (B - 1 > 0) then 
														SecCycle := 0;
													else 
														F(FLAG_Z) <= '1';
														F(FLAG_N) <= '1';
													
														commandRunned := '0';
													end if; 
													dec_pair(SS);
												when others => 
													null;
											end case;
											
											
											
											
											
											
										-- OUT (C), r
										
										when  "01000001"|
												"01001001"|
												"01010001"|
												"01011001"|
												"01100001"|
												"01101001"|
												"01111001" =>
											case SecCycle is 
												when 1 => 
													add_to_PC := 2;
													SSS := Operand1(5 downto 3);
													ADDR <= B & C;
													WR <= '1';
													DATA_OUT <= get_reg_val(SSS);
												when 2 => 
													WR <= '0';
													commandRunned := '0';
												when others => 
													null;
											end case;
										
											
										-- OUTI
										when "10100011" =>	
											case SecCycle is 
												when 1 =>
													add_to_PC := 2;
													ADDR <= H & L;
												when 2 => 
													SS := "10";
												
													DATA_OUT <= DATA;
													ADDR <= B & C;
													WR <= '1';
												when 3 => 
													WR <= '0';
													B <= B - 1;
													inc_pair(SS);
													
													if (B - 1 = "00000000") then 
														F(FLAG_Z) <= '1';
													else 
														F(FLAG_Z) <= '0';
													end if;
													
													F(FLAG_N) <= '1';
													
													commandRunned := '0';
												when others => 
													null;
											end case;
										
										-- OTIR
										when "10110011" =>	
											case SecCycle is 
												when 1 =>
													add_to_PC := 2;
													ADDR <= H & L;
												when 2 => 
													SS := "10";
												
													DATA_OUT <= DATA;
													ADDR <= B & C;
													WR <= '1';
												when 3 => 
													WR <= '0';
													B <= B - 1;
													
													if (B - 1 > 0) then 
														SecCycle := 0;
													else 
														F(FLAG_Z) <= '1';
														F(FLAG_N) <= '1';
													
														commandRunned := '0';
													end if; 
													inc_pair(SS);
												when others => 
													null;
											end case;
									
										-- OUTD
										when "10101011" =>	
											case SecCycle is 
												when 1 =>
													add_to_PC := 2;
													ADDR <= H & L;
												when 2 => 
													SS := "10";
												
													DATA_OUT <= DATA;
													ADDR <= B & C;
													WR <= '1';
												when 3 => 
													WR <= '0';
													B <= B - 1;
													dec_pair(SS);
													
													if (B - 1 = "00000000") then 
														F(FLAG_Z) <= '1';
													else 
														F(FLAG_Z) <= '0';
													end if;
													
													F(FLAG_N) <= '1';
													
													commandRunned := '0';
												when others => 
													null;
											end case;
										
										-- OTDR
										when "10111011" =>	
											case SecCycle is 
												when 1 =>
													add_to_PC := 2;
													ADDR <= H & L;
												when 2 => 
													SS := "10";
												
													DATA_OUT <= DATA;
													ADDR <= B & C;
													WR <= '1';
												when 3 => 
													WR <= '0';
													B <= B - 1;
													
													if (B - 1 > 0) then 
														SecCycle := 0;
													else 
														F(FLAG_C) <= '1';														
														F(FLAG_S) <= '1';
														F(FLAG_H) <= '1';
														
														commandRunned := '0';
													end if; 
													dec_pair(SS);
												when others => 
													null;
											end case;
											
											
											
										when others => 
											null;
									end case;
																
								when others => 
									null;
							end case;
						-- 																	--
						--					16 битовые команды загрузки				--
						--																		--
						
						-- LD dd, nn			00 dd0 001
						--							--	 n	 ---
						--							--	 n	 ---
						when "00000001"|"00010001"|"00100001"|"00110001" =>
							case MCycle is 
								when 0 =>
									DD := OPCode(5 downto 4);
									add_to_PC := 3;
									ADDR <= PC + 1;
								when 1 =>
									Operand1 := DATA;
									ADDR <= PC + 2;
								when 2 => 
									Operand2 := DATA;
									PairValue := Operand1 & Operand2;
									set_pair_dd(DD, PairValue);
									CommandRunned := '0';
								when others => 
									null;
							end case;
						
						-- LD IX(IY), nn			11 011 101					-- LD IX(IY), (nn)			11 011 101
						--								00 100 001              --									00 101 010
						--								--	 n	 ---              --									--	 n	 ---
						--								--	 n	 ---              --									--	 n	 ---
						
						-- LD r, (IX(IY) + d)									-- LD (IX(IY) + d), r
							
						-- PUSH IX(IY)												-- POP IX
													
						-- LD (nn), IX(IY)
						
						when "11011101"|"11111101" =>
							case MCycle is 
								when 0 =>
									DD := OPCode(5 downto 4);
									add_to_PC := 4;
									ADDR <= PC + 1;
								when 1 =>
									Operand1 := DATA;
									IXorIY := to_int(OpCode(5));
									ADDR <= ADDR + 1;
								when 2 =>
									Operand2 := DATA;
									ADDR <= ADDR + 1;
								when 3 =>
									Operand3 := DATA;
									SecCycle := 0;	
								when 4 => 	
								
									MCycle := MCycle - 1;	-- останавливаем такты команд, начинаем тактировать через SecCycle
									
									case Operand1 is 
										when "00110110" =>											-- LD (IX + d), n
											case SecCycle is 
												when 1 => 
													if (IXorIY = 0) then 
														ADDR <= IX + operand2;
													else 
														ADDR <= IY + operand2;
													end if;
													DATA_OUT <= operand3;
													WR <= '1';
												when 2 =>
													WR <= '0';
													commandRunned := '0';												
												when others => null;
											end case;
											
										when "00100001" =>											-- LD IX, nn
											case SecCycle is 
												when 1 => 
													if (IXorIY = 0) then 
														IX <= Operand2 & Operand3;
													else 
														IY <= Operand2 & Operand3;
													end if;
													CommandRunned := '0';
												when others => null;
											end case;
											
										when "00101010" =>											-- LD IX, (nn)
											case SecCycle is 
												when 1 => 
													ADDR <= Operand2 & Operand3; 
												when 2 => 
													ADDR <= ADDR + 1;		
													Operand2 := DATA;	
												when 3 => 
													if (IXorIY = 0) then 
														IX <= DATA & operand2;		
													else 
														IY <= DATA & operand2;
													end if;
													commandRunned := '0';
												when others => null;
											end case;
											
										when "00100010" =>											-- LD (nn), IX				
											case SecCycle is 	
												when 1 => 
													ADDR <= Operand2 & Operand3;
													WR <= '1';
													if (IXorIY = 0) then
														DATA_OUT <= IX(7 downto 0);
													else 
														DATA_OUT <= IY(7 downto 0);
													end if;
												when 2 => 
													ADDR <= ADDR + 1;
													if (IXorIY = 0) then
														DATA_OUT <= IX(15 downto 8);
													else 
														DATA_OUT <= IY(15 downto 8);
													end if;
												when 3 => 
													WR <= '0';
													CommandRunned := '0';
												when others => null;
											end case;
											
										when "11100101" =>											-- PUSH IX										
											case SecCycle is 
												when 1 => 
													add_to_PC := 2;
													WR <= '1';
													ADDR <= SP - 2;
													if (IXorIY = 0) then
														DATA_OUT <= IX(7 downto 0);
													else 
														DATA_OUT <= IY(7 downto 0);
													end if;
												when 2 =>
													ADDR <= SP - 1;
													if (IXorIY = 0) then
														DATA_OUT <= IX(15 downto 8);
													else 
														DATA_OUT <= IY(15 downto 8);
													end if;
												when 3 =>
													WR <= '0';
													SP <= SP - 2;
													CommandRunned := '0';
												when others => null;
											end case;
											
										when "11100001" =>											-- POP IX							
											case SecCycle is 
												when 1 => 
													add_to_PC := 2;
													ADDR <= SP;
												when 2 =>
													Operand2 := DATA;
													ADDR <= SP + 1;
												when 3 =>
													PairValue := DATA & Operand2;
													if (IXorIY = 0) then
														IX <= PairValue;
													else 
														IY <= PairValue;
													end if;
													SP <= SP + 1;
													CommandRunned := '0';
												when others => null;
											end case;
											
										when "01000110"|"01001110"|"01010110"|"01011110"|"01100110"|"01101110"|"01111110" =>	-- r, (IX + d)	
											case SecCycle is 
												when 1 => 
													add_to_PC := 3;
													if (IXorIY = 0) then
														ADDR <= IX + operand2;
													else 
														ADDR <= IY + operand2;
													end if;
													DDD := Operand1(5 downto 3);	
												when 2 =>
													set_reg(DDD, DATA);
													commandRunned := '0';
												when others => null;
											end case;
											
										when "01110000"|"01110001"|"01110010"|"01110011"|"01110100"|"01110101"|"01110111" =>	-- LD (IX + d), r										
											case SecCycle is 
												when 1 => 
													add_to_PC := 3;
													if (IXorIY = 0) then
														ADDR <= IX + operand2;	
													else 
														ADDR <= IY + operand2;	
													end if;
													DDD := Operand1(2 downto 0);
													DATA_OUT <= get_reg_val(DDD);
													WR <= '1';
												when 2 => 
													WR <= '0';
													commandRunned := '0';
												when others => null;
											end case;
										
										when "11101001" =>											-- JP (IX)							
											case SecCycle is 
												when 1 => 
													add_to_PC := 0;
													
													if (IXorIY = 0) then
														PC <= IX;
													else 
														PC <= IY;
													end if;
												when 2 =>
													CommandRunned := '0';
												when others => null;
											end case;
											
										when "11100011" =>											-- EX (SP), IX
											case SecCycle is 
												when 1 =>
													add_to_PC := 2;
													ADDR <= SP;	
													if (IXorIY = 0) then
														PairValue := IX;
													else 
														PairValue := IY;
													end if;
												when 2 =>
													if (IXorIY = 0) then
														IX(7 downto 0) <= DATA;
													else 
														IY(7 downto 0) <= DATA;
													end if;
													ADDR <= SP + 1;
												when 3 => 
													if (IXorIY = 0) then
														IX(15 downto 8) <= DATA;
													else 
														IY(15 downto 8) <= DATA;
													end if;
													
													ADDR <= SP;
													DATA_OUT <= PairValue(7 downto 0);								
													WR <= '1';                                            	
												when 4 =>                                                   
													ADDR <= SP + 1;                                          
													DATA_OUT <= PairValue(15 downto 8);                      
												when 5 =>                                                   
													WR <= '0';                                               
													CommandRunned := '0';                                    
												when others => null;
											end case;	
											
										when  "10000110"|													-- ADD A, (IX + d)
												"10001110"|	                                    -- ADC A, (IX + d)
												"10010110"|                                     -- SUB A, (IX + d)
												"10011110"|                                     -- SBC A, (IX + d)
												"10100110"|                                     -- AND A, (IX + d)
												"10101110"|                                     -- OR  A, (IX + d)
												"10110110"|                                     -- XOR A, (IX + d)
												"10111110" =>										      -- CP  A, (IX + d)
											case SecCycle is 										
												when 1 =>                                 
													add_to_PC := 3;                        
													if (IXorIY = 0) then                   
														ADDR <= IX + Operand2;                     
													else                                   
														ADDR <= IY + Operand2;                     
													end if;
												when 2 =>
													OP8_A <= A;
													OP8_B <= DATA;
													CODE <= "0" & Operand1(5 downto 3);
													RAZR <= '0';
												when 3 =>	
													null;
												when 4 =>
													A <= RES8;
													CommandRunned := '0';
												when others =>
													null;
											end case;	
											
										when  "00110100"|"00110101" =>								-- INC (IX + d)
											case SecCycle is 												-- DEC (IX + d)
												when 1 =>                                 
													add_to_PC := 3;                        
													if (IXorIY = 0) then                   
														ADDR <= IX + Operand2;                     
													else                                   
														ADDR <= IY + Operand2;                     
													end if;
												when 2 =>
													OP8_A <= DATA;
													CODE <= "1" & Operand1(2 downto 0);
													RAZR <= '0';
												when 3 =>	
													null;
												when 4 =>
													WR <= '1';
													DATA_OUT <= RES8;
												when 5 =>
													WR <= '0';
													CommandRunned := '0';
												when others =>
													null;
											end case;	
											
										when "00001001"|"00011001"|"00101001"|"00111001" =>
											case SecCycle is 												-- ADD IX, pp
												when 1 => 													-- ADD IY, rr
													add_to_PC := 2;
													SS := Operand1(5 downto 4);
													RAZR <= '1';
													CODE <= "0000";
													if (IXorIY = 0) then 
														OP16_A <= IX;
														OP16_B <= get_reg_pair_val_pp(SS);
													else 
														OP16_A <= IY;
														OP16_B <= get_reg_pair_val_rr(SS);
													end if;
													
												when 2 => 
													null;
												when 3 =>
													if (IXorIY = 0) then 
														IX <= RES16;
													else 
														IY <= RES16;
													end if;
													commandRunned := '0';
												when others =>
													null;
											end case;	
											
										when "00100011" =>
											case SecCycle is 												-- INC IX
												when 1 => 
													add_to_PC := 2;
													SS := Operand1(5 downto 4);
													RAZR <= '1';
													CODE <= "0011";
													if (IXorIY = 0) then 
														OP16_A <= IX;
													else 
														OP16_A <= IY;
													end if;
												when 2 => 
													null;
												when 3 =>
													if (IXorIY = 0) then 
														IX <= RES16;
													else 
														IY <= RES16;
													end if;
													commandRunned := '0';
												when others =>
													null;
											end case;	
											
										when "00101011" =>
											case SecCycle is 												-- DEC IX
												when 1 => 
													add_to_PC := 2;
													SS := Operand1(5 downto 4);
													RAZR <= '1';
													CODE <= "0100";
													if (IXorIY = 0) then 
														OP16_A <= IX;
													else 
														OP16_A <= IY;
													end if;
												when 2 => 
													null;
												when 3 =>
													if (IXorIY = 0) then 
														IX <= RES16;
													else 
														IY <= RES16;
													end if;
													commandRunned := '0';
												when others =>
													null;
											end case;	
											
										when "11001011" =>
										
											case (Operand3(7 downto 6)) is 
												when "00" => 														 -- RLC, RL, RRC, RR, SLA, SRA, SRL	 	(IX + d)
													case SecCycle is
														when 1 => 		
															ADD_to_PC := 4;
															SSS := Operand3(5 downto 3);
															if (IXorIY = 0) then 
																ADDR <= IX + Operand2;
															else 
																ADDR <= IY + Operand2;
															end if ;
														when 2 =>
															R <= shift_rotate(DATA, SSS);
														when 3 => 
															WR <= '1';
															DATA_OUT <= R;
														when 4 => 
															WR <= '0';
															CommandRunned := '0';
														when others => null;
													end case; 
												when "01" => 														-- BIT b, (IX + d)
													case SecCycle is 												
														when 1 => 
															add_to_PC := 4;
															SSS := Operand3(5 downto 3);
															if (IXorIY = 0) then 
																ADDR <= IX + Operand2;
															else 
																ADDR <= IY + Operand2;
															end if;
														when 2 => 
															Operand2 := DATA;
																																		
															F(FLAG_Z) <= not Operand2(to_integer(unsigned(SSS)));
															F(FLAG_N) <= '0';
															F(FLAG_H) <= '1';
														when 3 => 
															CommandRunned := '0';													
														when others => null;
													end case;
												when "10" => 
													null;
												when "11" => 														-- SET(RES) b, (IX + d)
													case SecCycle is 												
														when 1 => 
															add_to_PC := 4;
															SSS := Operand3(5 downto 3);
															if (IXorIY = 0) then 
																ADDR <= IX + Operand2;
															else 
																ADDR <= IY + Operand2;
															end if;
														when 2 => 
															Operand2 := DATA;
															OP8_A <= DATA;														
															
														when 3 => 
															OP8_A(to_integer(unsigned(SSS))) <= Operand3(6);													
															
														when 4 => 
															WR <= '1';
															DATA_OUT <= OP8_A;
														when 5 => 
															WR <= '0';
															commandRunned := '0';
														when others => null;
													end case;
												when others => 
													null;
											end case;
										
										when others => null;
									end case;						
								when others => 
									null;
							end case;
							
						-- LD HL, (nn)			00 101 010					              
						--							--	 n	 ---              
						--							--	 n	 ---              
						when "00101010" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 3;
									ADDR <= ADDR + 1;
								when 1 =>
									Operand1 := DATA;
									ADDR <= ADDR + 1;
								when 2 =>
									Operand2 := DATA;
									ADDR <= Operand1 & Operand2;
								when 3 => 
									L <= DATA;
									ADDR <= ADDR + 1;
								when 4 => 
									H <= DATA;
									CommandRunned := '0';
								when others => 
									null;
							end case;
						
						-- LD SP, HL			11 111 001	

						-- LD SP, IY			11 111 001 
						--							11 111 001
						when "11111001" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 2;
									ADDR <= ADDR + 1;
								when 1 =>
									if (DATA = "11111001") then 	-- LD SP, IY
										SP <= IY;
									else 									-- LD SP, HL
										SP <= H & L;
										add_to_PC := 1;
									end if;
									CommandRunned := '0';
								when others => 
									null;
							end case;
						
						-- LD SP, IX			11 011 001					              
						when "11011001" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 2;
									ADDR <= PC + 1;
								when 1 =>
									if (DATA = "11111001") then 
										SP <= IX;
									else 										-- EXX
										add_to_PC := 1;
									
										PairValue := Bs & Cs;
										Bs <= B; 
										Cs <= C;
										B <= PairValue(15 downto 8);
										C <= PairValue(7 downto 0);
										
										PairValue := Ds & Es;
										Ds <= D; 
										Es <= E;
										D <= PairValue(15 downto 8);
										E <= PairValue(7 downto 0);
										
										PairValue := Hs & Ls;
										Hs <= H; 
										Ls <= L;
										H <= PairValue(15 downto 8);
										L <= PairValue(7 downto 0);
									end if;
									CommandRunned := '0';
								when others => 
									null;
							end case;
							
					
						-- PUSH qq				11 qq0 101					              
						when "11000101" | "11010101" | "11100101" | "11110101" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									DD := OpCode(5 downto 4);
									WR <= '1';
									ADDR <= SP - 2;
									PairValue:= get_reg_pair_val_qq(DD);
									DATA_OUT <= PairValue(7 downto 0);
								when 1 =>
									ADDR <= SP - 1;
									DATA_OUT <= PairValue(15 downto 8);
								when 2 =>
									WR <= '0';
									SP <= SP - 2;
									CommandRunned := '0';
								when others => 
									null;
							end case;
							
						-- POP qq					11 qq0 001					              
						when "11000001" | "11010001" | "11100001" | "11110001" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									DD := OpCode(5 downto 4);
									ADDR <= SP;
								when 1 =>
									Operand1 := DATA;
									ADDR <= SP + 1;
								when 2 =>
									PairValue := DATA & Operand1;
									set_pair_qq(DD, PairValue);
									SP <= SP + 1;
									CommandRunned := '0';
								when others => 
									null;
							end case;
					
						-- LD (nn), HL
						when "00100010" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 3;
									ADDR <= PC + 1;
								when 1 =>
									Operand1 := DATA;
									ADDR <= ADDR + 1;
								when 2 =>
									Operand2 := DATA;
									WR <= '1';
									ADDR <= Operand1 & Operand2;
									DATA_OUT <= L;
								when 3 => 
									ADDR <= ADDR + 1;
									DATA_OUT <= H;
								when 4 => 
									WR <= '0';
									CommandRunned := '0';
								when others => 
									null;
							end case;
					
												
						-- 																	--
						--					8 битовые арифметические и логические  --
						--																		--
						
						-- ADD A, r		
						-- ADC A, r
						-- SUB A, r
						-- SBC A, r
						-- AND A, r
						-- OR  A, r
						-- XOR A, r
						-- CP  A, r
						when 	"10000111" | "10000000" | "10000001" | "10000010" | "10000011" | "10000100" | "10000101"| 
								"10001111" | "10001000" | "10001001" | "10001010" | "10001011" | "10001100" | "10001101"|
								"10010111" | "10010000" | "10010001" | "10010010" | "10010011" | "10010100" | "10010101"|
								"10011111" | "10011000" | "10011001" | "10011010" | "10011011" | "10011100" | "10011101"|
								"10100111" | "10100000" | "10100001" | "10100010" | "10100011" | "10100100" | "10100101"|
								"10101111" | "10101000" | "10101001" | "10101010" | "10101011" | "10101100" | "10101101"|
								"10110111" | "10110000" | "10110001" | "10110010" | "10110011" | "10110100" | "10110101"|
								"10111111" | "10111000" | "10111001" | "10111010" | "10111011" | "10111100" | "10111101"	=>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									DDD := OPCode(2 downto 0);
									OP8_A <= A;
									OP8_B <= get_reg_val(DDD);
									CODE <= "0" & OpCode(5 downto 3);
									RAZR <= '0';
								when 1 =>	
									null;
								when 2 =>
									A <= RES8;
									CommandRunned := '0';
								when others =>
									null;
							end case;
		
						-- ADD A, n
						-- ADC A, n
						-- SUB A, n
						-- SBC A, n
						-- AND A, n
						-- OR  A, n
						-- XOR A, n
						-- CP  A, n
						when  "11000110"|
								"11001110"|
								"11010110"|
								"11011110"|
								"11100110"|
								"11101110"|
								"11110110"|
								"11111110" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 2;
									ADDR <= PC + 1;
								when 1 =>
									OP8_A <= A;
									OP8_B <= DATA;
									CODE <= "0" & OpCode(5 downto 3);
									RAZR <= '0';
								when 2 =>	
									null;
								when 3 =>
									A <= RES8;
									CommandRunned := '0';
								when others =>
									null;
							end case;
							
						-- ADD A, (HL)
						-- ADC A, (HL)
						-- SUB A, (HL)
						-- SBC A, (HL)
						-- AND A, (HL)
						-- OR  A, (HL)
						-- XOR A, (HL)
						-- CP  A, (HL)
						when  "10000110"|
								"10001110"|
								"10010110"|
								"10011110"|
								"10100110"|
								"10101110"|
								"10110110"|
								"10111110" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									ADDR <= H & L;
								when 1 =>
									OP8_A <= A;
									OP8_B <= DATA;
									CODE <= "0" & OpCode(5 downto 3);
									RAZR <= '0';
								when 2 =>	
									null;
								when 3 =>
									A <= RES8;
									CommandRunned := '0';
								when others =>
									null;
							end case;
							
						-- INC A, r		
						-- DEC A, r
						when 	"00000100"|"00001100"|"00010100"|"00011100"|"00100100"|"00101100"|"00111100"|  	
								"00000101"|"00001101"|"00010101"|"00011101"|"00100101"|"00101101"|"00111101"  	=>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									DDD := OPCode(5 downto 3);
									OP8_A <= get_reg_val(DDD);
									CODE <= "1" & OpCode(2 downto 0);
									RAZR <= '0';
								when 1 =>	
									null;
								when 2 =>
									set_reg(DDD, RES8);
									CommandRunned := '0';
								when others =>
									null;
							end case;	
						
						-- INC (HL)
						when  "00110100"|
								"00110101" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									ADDR <= H & L;
								when 1 =>
									OP8_A <= DATA;
									CODE <= "1" & OpCode(2 downto 0);
									RAZR <= '0';
								when 2 =>	
									null;
								when 3 =>
									WR <= '1';
									ADDR <= H & L;
									DATA_OUT <= RES8;
								when 4 => 
									WR <= '0';
									CommandRunned := '0';
								when others =>
									null;
							end case;
							
						-- DAA 
						when  "00100111" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									
									if ((A(3 downto 0) > 9) or F(FLAG_H) = '1') then 			-- младшая тетрада больше девяти
										A <= A + 6;
									end if;
								when 1 => 
									if ((A(7 downto 4) > 9) or F(FLAG_C) = '1') then 			-- старшая тетрада больше девяти
										A(7 downto 4) <= A(7 downto 4) + 6;
									end if;
									CommandRunned := '0';
								when others =>
									null;
							end case;
						
						-- CPL 
						when  "00101111" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									
									A <= not A;
									F(FLAG_N) <= '1';
									F(FLAG_H) <= '1';
									CommandRunned := '0';
								when others =>
									null;
							end case;
				
						-- CCF 
						when  "00111111" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;

									F(FLAG_C) <= not F(FLAG_C);
									
									CommandRunned := '0';
								when others =>
									null;
							end case;
							
						-- SCF 
						when  "00110111" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;

									F(FLAG_C) <= '1';
									
									CommandRunned := '0';
								when others =>
									null;
							end case;
						
						-- 																	--
						--					16 битовые арифметические 					--
						--																		--
						
						-- ADD HL, dd
						when  "00001001"|"00011001"|"00111001" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									SS := OpCode(5 downto 4);
									RAZR <= '1';
									CODE <= "0000";
									OP16_A <= H & L;
									OP16_B <= get_reg_pair_val_dd(SS);
								when 1 => 
									null;
								when 2 =>
									H <= RES16(15 downto 8);
									L <= RES16(7  downto 0);
									commandRunned := '0';
								when others =>
									null;
							end case;
						
						-- INC dd
						when  "00000011"|"00010011"|"00100011"|"00110011" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									SS := OpCode(5 downto 4);
									RAZR <= '1';
									CODE <= "0011";
									OP16_A <= get_reg_pair_val_dd(SS);
								when 1 => 
									null;
								when 2 =>
									PairValue := RES16;
									set_pair_dd(SS, PairValue);
									commandRunned := '0';
								when others =>
									null;
							end case;
						
						-- DEC dd
						when  "00001011"|"00011011"|"00101011"|"00111011" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									SS := OpCode(5 downto 4);
									RAZR <= '1';
									CODE <= "0100";
									OP16_A <= get_reg_pair_val_dd(SS);
								when 1 => 
									null;
								when 2 =>
									PairValue := RES16;
									set_pair_dd(SS, PairValue);
									commandRunned := '0';
								when others =>
									null;
							end case;
							
						-- 																	--
						--					команды переходов								--
						--																		--
						
						-- JP nn
						when "11000011" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 0;
									ADDR <= PC + 1;
								when 1 =>
									Operand1 := DATA;
									ADDR <= ADDR + 1;
								when 2 =>
									Operand2 := DATA;
									PC <= Operand1 & Operand2;
								when 3 =>
									CommandRunned := '0';
								when others => null;
							end case;				
						
						-- JP cc, nn
						when "11000010"|"11001010"|"11010010"|"11011010"|"11100010"|"11101010"|"11110010"|"11111010" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 0;
									SSS := OpCode(5 downto 3);
									ADDR <= PC + 1;
								when 1 =>
									Operand1 := DATA;
									ADDR <= ADDR + 1;
								when 2 =>
									Operand2 := DATA;
									
									if (check_cc(SSS) = 1) then 
										PC <= Operand1 & Operand2;
									else 
										add_to_PC := 3;
									end if;
								
								when 3 =>
									CommandRunned := '0';
								when others => null;
							end case;	
			
						-- JR e
						when "00011000" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 0;
									ADDR <= PC + 1;
								when 1 =>
									Operand1 := DATA;
									if (operand1(7) = '0') then
										PC <= PC + 2 + Operand1(6 downto 0);
									else 
										PC <= PC + 2 - Operand1(6 downto 0);
									end if;
								when 2 =>
									CommandRunned := '0';
								when others => null;
							end case;				
						
						-- JR C, e
						when "00111000" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 0;
									ADDR <= PC + 1;
								when 1 =>
									Operand1 := DATA;
									if (F(FLAG_C) = '1') then 
										if (operand1(7) = '0') then
											PC <= PC + 2 + Operand1(6 downto 0);
										else 
											PC <= PC + 2 - Operand1(6 downto 0);
										end if;
									else 
										add_to_PC := 2;
									end if;
								when 2 =>
									CommandRunned := '0';
								when others => null;
							end case;	
			
						-- JR NC, e
						when "00110000" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 0;
									ADDR <= PC + 1;
								when 1 =>
									Operand1 := DATA;
									if (F(FLAG_C) = '0') then 
										if (operand1(7) = '0') then
											PC <= PC + 2 + Operand1(6 downto 0);
										else 
											PC <= PC + 2 - Operand1(6 downto 0);
										end if;
									else 
										add_to_PC := 2;
									end if;
								when 2 =>
									CommandRunned := '0';
								when others => null;
							end case;	
							
						-- JR Z, e
						when "00101000" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 0;
									ADDR <= PC + 1;
								when 1 =>
									Operand1 := DATA;
									if (F(FLAG_Z) = '1') then 
										if (operand1(7) = '0') then
											PC <= PC + 2 + Operand1(6 downto 0);
										else 
											PC <= PC + 2 - Operand1(6 downto 0);
										end if;
									else 
										add_to_PC := 2;
									end if;
								when 2 =>
									CommandRunned := '0';
								when others => null;
							end case;	
							
							-- JR NZ, e
						when "00100000" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 0;
									ADDR <= PC + 1;
								when 1 =>
									Operand1 := DATA;
									if (F(FLAG_Z) = '0') then 
										if (operand1(7) = '0') then
											PC <= PC + 2 + Operand1(6 downto 0);
										else 
											PC <= PC + 2 - Operand1(6 downto 0);
										end if;
									else 
										add_to_PC := 2;
									end if;
								when 2 =>
									CommandRunned := '0';
								when others => null;
							end case;	
							
						-- JP (HL)
						when "11101001" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 0;
									PC <= H & L;
								when 1 =>
									CommandRunned := '0';
								when others => null;
							end case;	
							
						-- DJNZ e
						when "00010000" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 0;
									ADDR <= PC + 1;
								when 1 =>
									Operand1 := DATA;
									B <= B - 1;
								when 2 => 
									if (B = "00000000") then 
										add_to_PC := 2;
									else 
										if (operand1(7) = '0') then
											PC <= PC + 2 + Operand1(6 downto 0);
										else 
											PC <= PC + 2 - Operand1(6 downto 0);
										end if;
									end if;
								when 3 =>
									CommandRunned := '0';
								when others => null;
							end case;	
					
						-- 																	--
						--					команды обмена									--
						--																		--
				
						-- EX DE, HL
						when "11101011" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									PairValue := D & E;
									D <= H; 
									E <= L;
									H <= PairValue(15 downto 8);
									L <= PairValue(7 downto 0);
									CommandRunned := '0';
								when others => null;
							end case;	
							
						-- EX AF, AF'
						when "00001000" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									PairValue := As & Fs;
									As <= A; 
									Fs <= F;
									A <= PairValue(15 downto 8);
									F <= PairValue(7 downto 0);
									CommandRunned := '0';
								when others => null;
							end case;	
						
						-- EX (SP), HL
						when "11100011" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									ADDR <= SP;	
									PairValue := H & L;
								when 1 =>
									L <= DATA;
									ADDR <= SP + 1;
								when 2 => 
									H <= DATA;
									ADDR <= SP;
									DATA_OUT <= PairValue(7 downto 0);
									WR <= '1';
								when 3 => 
									ADDR <= SP + 1;
									DATA_OUT <= PairValue(15 downto 8);
								when 4 =>
									WR <= '0';
									CommandRunned := '0';
								when others => null;
							end case;	
						
						-- 																	--
						--					команды вызова и возврата					--
						--																		--
						
						-- CALL nn
						when "11001101" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 0;
									ADDR <= PC + 1;
								when 1 => 
									Operand1 := DATA;
									ADDR <= ADDR + 1;
								when 2 =>
									Operand2 := DATA;
									WR <= '1';
									ADDR <= SP - 1;
									DATA_OUT <= PC(15 downto 8);
								when 3 => 
									ADDR <= SP - 2;
									DATA_OUT <= PC(7 downto 0);
								when 4 => 
									WR <= '0';
									SP <= SP - 2;
									PC <= Operand1 & Operand2;
								when 5 => 
									commandRunned := '0';
								when others => null;
							end case;	
								
						-- CALL nn
						when  "11000100"|
								"11001100"|
								"11010100"|	
								"11011100"|
								"11100100"|
								"11101100"|
								"11110100"|
								"11111100" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 0;
									ADDR <= PC + 1;
									SSS := OpCode(5 downto 3);
									if (check_cc(SSS) = 0) then 
										add_to_PC := 3;
										commandRunned := '0';
									end if;
								when 1 => 
									Operand1 := DATA;
									ADDR <= ADDR + 1;
								when 2 =>
									Operand2 := DATA;
									WR <= '1';
									ADDR <= SP - 1;
									DATA_OUT <= PC(15 downto 8);
								when 3 => 
									ADDR <= SP - 2;
									DATA_OUT <= PC(7 downto 0);
								when 4 => 
									WR <= '0';
									SP <= SP - 2;
									PC <= Operand1 & Operand2;
								when 5 =>
									commandRunned := '0';
								when others => null;
							end case;	
						
						-- RET
						when "11001001" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 0;
									ADDR <= SP;
								when 1 =>
									PC(7 downto 0) <= DATA;
									ADDR <= SP + 1;
								when 2 => 
									PC(15 downto 8) <= DATA;
									SP <= SP + 2;
								when 3 => 
									commandRunned := '0';
								when others => null;
							end case;	
							
						-- RET cc
						when  "11000000"|
								"11001000"|
								"11010000"|	
								"11011000"|
								"11100000"|
								"11101000"|
								"11110000"|
								"11111000" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 0;
									SSS := OpCode(5 downto 3);
									
									if (check_cc(SSS) = 0) then 
										add_to_PC := 1;
										commandRunned := '0';
									else 
										ADDR <= SP;
									end if;
								when 1 =>
									PC(7 downto 0) <= DATA;
									ADDR <= SP + 1;
								when 2 => 
									PC(15 downto 8) <= DATA;
									SP <= SP + 2;
								when 3 => 
									commandRunned := '0';
								when others => null;
							end case;	
							
						-- 																	--
						--					команды управления микропроцессором		--
						--																		--
						
						-- NOP
						when "00000000" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									commandRunned := '0';
								when others => null;
							end case;	
							
						-- HALT
						when "01110110" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 0;
								when others => null;
							end case;		
							
						-- 																	--
						--					команды для работы с битами				--
						--																		--
						when "11001011" =>
							case MCycle is 
								when 0 =>
									add_to_PC := 2;
									ADDR <= PC + 1;
								when 1 => 
									Operand1 := DATA;
									SecCycle := 0;
								when 2 =>
									MCycle := MCycle - 1;
									
									case Operand1 is 
										when 	"01000000"|"01001000"|"01010000"|"01011000"|"01100000"|"01101000"|"01110000"|"01111000"|		-- BIT b, r
												"01000001"|"01001001"|"01010001"|"01011001"|"01100001"|"01101001"|"01110001"|"01111001"|
												"01000010"|"01001010"|"01010010"|"01011010"|"01100010"|"01101010"|"01110010"|"01111010"|	
												"01000011"|"01001011"|"01010011"|"01011011"|"01100011"|"01101011"|"01110011"|"01111011"|
												"01000100"|"01001100"|"01010100"|"01011100"|"01100100"|"01101100"|"01110100"|"01111100"|
												"01000101"|"01001101"|"01010101"|"01011101"|"01100101"|"01101101"|"01110101"|"01111101"|
												"01000111"|"01001111"|"01010111"|"01011111"|"01100111"|"01101111"|"01110111"|"01111111" 	=>
											case SecCycle is
												when 1 => 
													SSS := Operand1(5 downto 3);		-- b
													DDD := Operand1(2 downto 0);		-- r
													Operand2 := get_reg_val(DDD);
													F(FLAG_Z) <= not Operand2(to_integer(unsigned(SSS)));
													F(FLAG_N) <= '0';
													F(FLAG_H) <= '1';
												when 2 =>
													CommandRunned := '0';
												when others => null;
											end case;
										when 	"01000110"|"01001110"|"01010110"|"01011110"|"01100110"|"01101110"|"01110110"|"01111110" => 	-- BIT b, (HL)
											case SecCycle is
												when 1 => 
													SSS := Operand1(5 downto 3);		-- b
													ADDR <= H & L;
												when 2 =>
													Operand2 := DATA;
													
													F(FLAG_Z) <= not Operand2(to_integer(unsigned(SSS)));
													F(FLAG_N) <= '0';
													F(FLAG_H) <= '1';
												when 3 =>
													CommandRunned := '0';
												when others => null;
											end case;
										
										when 	"11000000"|"11001000"|"11010000"|"11011000"|"11100000"|"11101000"|"11110000"|"11111000"|		-- SET b, r
												"11000001"|"11001001"|"11010001"|"11011001"|"11100001"|"11101001"|"11110001"|"11111001"|
												"11000010"|"11001010"|"11010010"|"11011010"|"11100010"|"11101010"|"11110010"|"11111010"|	
												"11000011"|"11001011"|"11010011"|"11011011"|"11100011"|"11101011"|"11110011"|"11111011"|
												"11000100"|"11001100"|"11010100"|"11011100"|"11100100"|"11101100"|"11110100"|"11111100"|
												"11000101"|"11001101"|"11010101"|"11011101"|"11100101"|"11101101"|"11110101"|"11111101"|
												"11000111"|"11001111"|"11010111"|"11011111"|"11100111"|"11101111"|"11110111"|"11111111" 	=>
											case SecCycle is
												when 1 => 
													SSS := Operand1(5 downto 3);		-- b
													DDD := Operand1(2 downto 0);		-- r
													OP8_A <= get_reg_val(DDD);						-- TODO: не использовать OP8_A!!!!
												when 2 =>
													OP8_A(to_integer(unsigned(SSS))) <= '1';
												when 3 => 
													set_reg(DDD, OP8_A);
													commandRunned := '0';
												when others => null;
											end case;
										
										when 	"11000110"|"11001110"|"11010110"|"11011110"|"11100110"|"11101110"|"11110110"|"11111110" => 	-- SET b, (HL)
											case SecCycle is
												when 1 => 
													SSS := Operand1(5 downto 3);		-- b
													ADDR <= H & L;
												when 2 =>
													OP8_A <= DATA;
												when 3 => 
													OP8_A(to_integer(unsigned(SSS))) <= '1';
												when 4 =>
													WR <= '1';
													DATA_OUT <= OP8_A;
												when 5 =>
													WR <= '0';
													CommandRunned := '0';
												when others => null;
											end case;	
										
										when 	"10000000"|"10001000"|"10010000"|"10011000"|"10100000"|"10101000"|"10110000"|"10111000"|		-- RES b, r
												"10000001"|"10001001"|"10010001"|"10011001"|"10100001"|"10101001"|"10110001"|"10111001"|
												"10000010"|"10001010"|"10010010"|"10011010"|"10100010"|"10101010"|"10110010"|"10111010"|	
												"10000011"|"10001011"|"10010011"|"10011011"|"10100011"|"10101011"|"10110011"|"10111011"|
												"10000100"|"10001100"|"10010100"|"10011100"|"10100100"|"10101100"|"10110100"|"10111100"|
												"10000101"|"10001101"|"10010101"|"10011101"|"10100101"|"10101101"|"10110101"|"10111101"|
												"10000111"|"10001111"|"10010111"|"10011111"|"10100111"|"10101111"|"10110111"|"10111111" 	=>
											case SecCycle is
												when 1 => 
													SSS := Operand1(5 downto 3);		-- b
													DDD := Operand1(2 downto 0);		-- r
													OP8_A <= get_reg_val(DDD);						-- TODO: не использовать OP8_A!!!!
												when 2 =>
													OP8_A(to_integer(unsigned(SSS))) <= '0';
												when 3 => 
													set_reg(DDD, OP8_A);
													commandRunned := '0';
												when others => null;
											end case;
										
										when 	"10000110"|"10001110"|"10010110"|"10011110"|"10100110"|"10101110"|"10110110"|"10111110" => 	-- RES b, (HL)
											case SecCycle is
												when 1 => 
													SSS := Operand1(5 downto 3);		-- b
													ADDR <= H & L;
												when 2 =>
													OP8_A <= DATA;
												when 3 => 
													OP8_A(to_integer(unsigned(SSS))) <= '0';
												when 4 =>
													WR <= '1';
													DATA_OUT <= OP8_A;
												when 5 =>
													WR <= '0';
													CommandRunned := '0';
												when others => null;
											end case;	
										
										-- 																	--
										--					команды сдвига и вращения					--
										--																		--
											
										when  "00000000"|"00000001"|"00000010"|"00000011"|"00000100"|"00000101"|"00000111"|
												"00001000"|"00001001"|"00001010"|"00001011"|"00001100"|"00001101"|"00001111"|
												"00010000"|"00010001"|"00010010"|"00010011"|"00010100"|"00010101"|"00010111"|
												"00011000"|"00011001"|"00011010"|"00011011"|"00011100"|"00011101"|"00011111"|
												"00100000"|"00100001"|"00100010"|"00100011"|"00100100"|"00100101"|"00100111"|
												"00101000"|"00101001"|"00101010"|"00101011"|"00101100"|"00101101"|"00101111"|
												"00111000"|"00111001"|"00111010"|"00111011"|"00111100"|"00111101"|"00111111"  => 	-- RLC, RL, RRC, RR, SLA, SRA, SRL			r
											case SecCycle is
												when 1 => 
													DDD := Operand1(2 downto 0);
													SSS := Operand1(5 downto 3);
													PairValue(7 downto 0) := get_reg_val(DDD);
													
												when 2 =>
													R <= shift_rotate(PairValue(7 downto 0), SSS);
												when 3 => 
													set_reg(DDD, R);
												when 4 => 
													CommandRunned := '0';
												when others => null;
											end case; 
										
										when  "00000110"|
												"00001110"|
												"00010110"|
												"00011110"|
												"00100110"|
												"00101110"|
												"00111110"  => 		-- -- RLC, RL, RRC, RR, SLA, SRA, SRL	 	(HL)
											case SecCycle is
												when 1 => 						
													SSS := Operand1(5 downto 3);
													ADDR <= H & L;
												when 2 =>
													R <= shift_rotate(DATA, SSS);
												when 3 => 
													WR <= '1';
													DATA_OUT <= R;
												when 4 => 
													WR <= '0';
													CommandRunned := '0';
												when others => null;
											end case; 
										
										when others => null;
									end case;
								when 3 => 
									commandRunned := '0';
								when others => null;
							end case;	
							
						
						-- 																	--
						--					команды сдвига и вращения					--
                  --																		--
						
						-- RLCA
						when "00000111" => 
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									F(FLAG_C) <= A(7);
									A(7 downto 1) <= A(6 downto 0);
									A(0) <= A(7);
									F(FLAG_N) <= '0';									
									F(FLAG_H) <= '0';
									commandRunned := '0';
								when others => null;
							end case;	
						
						-- RLA
						when "00010111" => 
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									F(FLAG_C) <= A(7);
									A(7 downto 1) <= A(6 downto 0);
									A(0) <= F(FLAG_C);
									F(FLAG_N) <= '0';									
									F(FLAG_H) <= '0';
									commandRunned := '0';
								when others => null;
							end case;	
						
						-- RRCA
						when "00001111" => 
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									F(FLAG_C) <= A(0);
									A(6 downto 0) <= A(7 downto 1);
									A(7) <= A(0);
									F(FLAG_N) <= '0';									
									F(FLAG_H) <= '0';
									commandRunned := '0';
								when others => null;
							end case;	
						
						-- RRA
						when "00011111" => 
							case MCycle is 
								when 0 =>
									add_to_PC := 1;
									F(FLAG_C) <= A(0);
									A(6 downto 0) <= A(7 downto 1);
									A(7) <= F(FLAG_C);
									F(FLAG_N) <= '0';									
									F(FLAG_H) <= '0';
									commandRunned := '0';
								when others => null;
							end case;	
							
						-- 																	--
						--					команды ввода/вывода							--
                  --																		--
						
						-- IN A, (n)
						when "11011011" => 
							case MCycle is 
								when 0 =>
									add_to_PC := 2; 
									ADDR <= PC + 1;
								when 1 => 
									Operand1 := DATA;
									ADDR <= A & Operand1;
								when 2 => 
									A <= DATA;
									CommandRunned := '0';
								when others => null;
							end case;
						
						-- OUT A, (n)
						when "11010011" => 
							case MCycle is 
								when 0 =>
									add_to_PC := 2; 
									ADDR <= PC + 1;
								when 1 => 
									Operand1 := DATA;
									ADDR <= A & Operand1;
									WR <= '1';
									DATA_OUT <= A;
								when 2 => 
									WR <= '0';
									CommandRunned := '0';
								when others => null;
							end case;
						
						when others =>
							add_to_PC := 1;
							commandRunned := '0';
							--null;
					end case;
					
					-- по завершению выполнения команды - инкрементировать PC, выставить адрес по PC
					if (CommandRunned = '0') then 
						if (PC + add_to_PC < "0000000001111111") then 
							PC <= PC + add_to_PC;
							ADDR <= PC + add_to_PC;
							SecCycle := -1;
							next_step <= '0';
							
							rs_DATA_IN <= "01110000";
							rs_TX_VALID <= '1';
							debug_counter := 0;
							transmitting_reg_started := '1';
						else 
							programm_loaded <= '0';
							without_stopping <= '0';
							next_step <= '0';
							transmitting_reg_started := '1';
						end if;
					end if; 				
					if (SecCycle >= 0) then 
						SecCycle := SecCycle + 1;
					end if;
					MCycle := MCycle + 1;
				end if;
			end if;
	end process main;
end Z80;