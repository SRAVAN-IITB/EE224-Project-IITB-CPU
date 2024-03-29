library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;

entity CPU is
    port (
        Clk, Reset: in std_logic;
		  Input: in std_logic_vector(7 downto 0);
		  Output: out std_logic_vector(7 downto 0)
		    );
end entity CPU;

architecture struct of CPU is

    type state is (rst, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17, S1delay, Sx, Sy);
	
	-- Declaration of components Reg_File, MUX_8, MUX_4, MUX_2, Memory, ALU
    component Reg_16BIT is
        port (
            Reset, clk: in std_logic;
            data_in : in std_logic_vector(15 downto 0);
            data_out : out std_logic_vector(15 downto 0)
        );
    end component Reg_16BIT;

    component Reg_File is
        port (
					Clk, Reset : in std_logic;
            Address_Read1 : in std_logic_vector(2 downto 0);
            Address_Read2 : in std_logic_vector(2 downto 0);
            Address_Write : in std_logic_vector(2 downto 0);
					data_Write : in std_logic_vector(15 downto 0);
					data_Read1 : out std_logic_vector(15 downto 0);
					data_Read2 : out std_logic_vector(15 downto 0);
					R7_dataold : out std_logic_vector(15 downto 0)
        );
    end component Reg_File;

    component MUX_8 is 
        port (
            S: in std_logic_vector(2 downto 0);
            I: in std_logic_vector(7 downto 0);
            Y: out std_logic
        );
    end component MUX_8;

    component MUX_4 is 
        port (
            S: in std_logic_vector(1 downto 0);
            I: in std_logic_vector(3 downto 0);
            Y: out std_logic
        );
    end component MUX_4;

    component MUX_2 is 
        port (
            S: in std_logic;
            I: in std_logic_vector(1 downto 0);
            Y: out std_logic
        );
    end component MUX_2;

    component Memory is
        port (
            Address: in std_logic_vector(15 downto 0);
			   Input:in std_logic_vector(7 downto 0);
            data_write: in std_logic_vector(15 downto 0);
            data_out: out std_logic_vector(15 downto 0);
				Output:out std_logic_vector(7 downto 0);
            clock, MeM_R, MeM_W: in std_logic);
    end component Memory;

    component ALU is
        port (
            A, B: in std_logic_vector(15 downto 0);
            Oper: in std_logic_vector(3 downto 0);
            Z: out std_logic;
            C: out std_logic_vector(15 downto 0)
        );
    end component ALU;
	 
    signal IP, T1_data, T2_data, T3_data, Mem_data, IR, BEQ,
			  M3, M4, M5, M6, M7, M8, DataA, DataB, ALU_data: std_logic_vector(15 downto 0) := (others => '0');  
    signal M2, M9, M10: std_logic_vector(2 downto 0) := (others => '0');
    signal M1: std_logic_vector(3 downto 0) := (others => '0');
    signal Mem_W, Mem_R, Z_flag, T1_W, T2_W, IP_store, IR_Write, Z_W, Z_Temp, R7_Push,R7_old, BM4, BM8: std_logic := '0';
    signal B: std_logic_vector(20 downto 0) := (others => '0');
    signal state_present: state := rst;
	 signal state_next: state := rst;
	 signal Mem_data_IR, DataA_T1, DataB_T2, IP_R7: std_logic_vector(15 downto 0) := (others => '0');
	 signal R7_datastore,R7_datatemp, T4_data, R7_update: std_logic_vector(15 downto 0) := (others => '0');

begin
	-- 16BIT register responsible for keeping track of 
	-- the address of the next instruction to be fetched
    Program_Counter: Reg_16BIT port map (Clk => Clk, 
													Reset => Reset, 
												 data_in => M8, 
												data_out => IP);
	
	-- Represents the main memory of the CPU, allowing read and write operations.
    MyMemory: Memory port map (Address => M6, 
	                            Input => Input,
									 data_write => T2_data, 
										data_out => Mem_data, 
											clock => clk, 
											MeM_W => Mem_W, 
											MeM_R => Mem_R,
											Output => Output);
	
	-- 16-bit register that stores the currently fetched instruction from memory.
    Instruction_Register: Reg_16BIT port map (Reset => Reset, 
																Clk => clk, 
														  data_in => Mem_data_IR, 
														 data_out => IR);
	
	-- Register file is responsible for reading data from and writing data to the registers.
    Reg_File1 : Reg_File port map (Clk   => Clk,
											  Reset => Reset, 
									Address_Read1 => M9, 
									Address_Read2 => M10, 
									Address_Write => M2, 
										data_Write => M3, 
										data_Read1 => DataA, 
										data_Read2 => DataB,
										R7_dataold => R7_datatemp);
	
	-- These temporary registers (Temporary_Register1, Temporary_Register2, Temporary_Register3) 
	-- serve as storage for intermediate values during computation.													
    Temporary_Register1: Reg_16BIT port map (Clk => Clk, 
														 Reset => Reset, 
													  data_in => DataA_T1, 
													 data_out => T1_data);
																
    Temporary_Register2: Reg_16BIT port map (Clk => Clk, 
														 Reset => Reset, 
													  data_in => DataB_T2, 
													 data_out => T2_data);
	 
    Temporary_Register3: Reg_16BIT port map (Clk => Clk, 
														 Reset => Reset, 
													 data_in  => M7, 
													 data_out => T3_data);
													 
	 Temporary_Register4: Reg_16BIT port map (Clk => Clk, 
														 Reset => Reset, 
													 data_in  => R7_datastore, 
													 data_out => T4_data);
	
	-- Arithmetic Logic Unit (ALU) (Arithmetic) performs arithmetic and logic operations on 
	-- two input operands (A and B) based on the specified operation (Oper).
    Arithmetic: ALU port map (A => M4, 
										B => M5, 
									Oper => M1, 
										Z => Z_Temp, 
										C => ALU_data);

	-- Parallelly connected 1-bit MUXes that decide whether to branch to the 
	-- 16-bit ALU_Data ( (PC+2) + 2*imm6 ) or stay unchanged at the same 16-bit IP (PC+2).
    BEQ1: for j in 0 to 15 generate
        MUXA: MUX_2 port map (S => Z_Flag, 
									I(1) => ALU_Data(j), 
									I(0) => IP(j), 
										Y => BEQ(j));
    end generate BEQ1;
	 
	 R7BT: for j in 0 to 15 generate
        MUXB: MUX_2 port map (S => Z_Flag, 
									I(1) => IP(j), 
									I(0) => R7_datatemp(j), 
										Y => R7_update(j));
    end generate R7BT;

	 -- The following processes help integrate the FSM and Datapath for our CPU!
    clock_proc: process(clk, reset)
    begin
        if (clk = '1' and clk'event) then
            if (reset = '1') then
                state_present <= rst;
            else
                state_present <= state_next;
            end if;
        end if;
    end process;

    state_transition_proc: process(state_present, IR)
    begin
        case state_present is

            when rst=>
                state_next <= S1;
					 
			   when S1=>
				    state_next <= S1delay;

            when S1delay=>
                if ((IR(15 downto 12) = "1010") OR (IR(15 downto 12) = "1011")) then
                    state_next <= S17;
				    elsif IR(15 downto 0) = "0000000000000000" then
					     state_next <= S1;
					 else
					     state_next <= S2;
                end if;

            when S2=>
                case IR(15 downto 12) is
                    when "0000" | "0010" | "0011" | "0100" | "0101" | "0110" =>
                        state_next <= S3;
                    when "0001" =>
                        state_next <= S5;
                    when "1101" | "1111" =>
                        state_next <= S8;
                    when "1000" =>
                        state_next <= S9;
                    when "1001" =>
                        state_next <= S10;
                    when "1100" =>
                        state_next <= S12;
                    when others =>
                        NULL;
                end case;

            when S3 =>
                state_next <= S4;

            when S4 =>
                state_next <= Sx;

            when S5 =>
                case IR(15 downto 12) is
                    when "1010" =>
                        state_next <= S6;
                    when "1011" =>
                        state_next <= S11;
                    when "0001" =>
                        state_next <= S16;
                    when others =>
                        NULL;
                end case;

            when S6 =>
                state_next <= S7;

            when S7 =>
                state_next <= Sx;

            when S8 =>
                case IR(15 downto 12) is
                    when "1101" =>
                        state_next <= S14;
                    when "1111" =>
                        state_next <= S15;
                    when others =>
                        NULL;
                end case;

            when S9 =>
                state_next <= Sx;

            when S10 =>
                state_next <= Sx;

            when S11 =>
                state_next <= Sx;

            when S12 =>
                state_next <= S13;

            when S13 =>
                state_next <= Sx;

            when S14 =>
                state_next <= Sx;

            when S15 =>
                state_next <= Sx;

            when S16 =>
                state_next <= Sx;

            when S17 =>
                state_next <= S5;
					 
			   when Sx =>
                state_next <= Sy;
					 
			   when Sy =>
                state_next <= S1;

            when others =>
                NULL;

        end case;
    end process state_transition_proc;

    output_proc: process(state_present, Mem_W, Mem_R)
    begin
        B <= "000000000000000000000";
        Mem_W <= '0';
        Mem_R <= '0';
        T1_W <= '0';
        T2_W <= '0';
		  IR_Write <= '0';
		  Z_W <= '0';
		  R7_Push <= '0';
		  R7_old <= '0';
		  BM4 <= '0';

        case state_present is
		  
		      when rst =>
					B <= "000000000000000000000";
				  Mem_W <= '0';
				  Mem_R <= '0';
				  T1_W <= '0';
				  T2_W <= '0';
				  IP_store <= '0';
				  IR_Write <= '0';
				  Z_W <= '0';
				  R7_Push <= '0';
				  R7_old <= '0';
				  BM4 <= '0';
				  BM8 <= '0';
				
				when S1=>
				   B <= "010000001000000000000";
               Mem_W <= '0';
               Mem_R <= '1';
               T1_W <= '0';
               T2_W <= '0';
					IP_store <= '0';
					IR_Write <= '1';
					Z_W <= '0';
					R7_Push <= '1';
					R7_old <= '0';
					BM4 <= '0';
					BM8 <= '0';
				
            when S1delay=>
                B <= "010010001001011010001";
                Mem_W <= '0';
                Mem_R <= '1';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '1';
					 IR_Write <= '1';
					 Z_W <= '0';
					 R7_Push <= '1';
					 R7_old <= '0';
					 BM4 <= '0';
					 BM8 <= '0';

            when S2=>
                B <= "010000000000000000000";
                Mem_W <= '0';
                Mem_R <= '0';
                T1_W <= '1';
                T2_W <= '1';
					 IP_store <= '0';
					 IR_Write <= '0';
					 Z_W <= '0';
					 R7_Push <= '0';
					 R7_old <= '1';
					 BM4 <= '0';
					 BM8 <= '0';

            when S3=>
                B <= "010000100010100000011";
                Mem_W <= '0';
                Mem_R <= '0';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '0';
					 IR_Write <= '0';
					 Z_W <= '1';
					 R7_Push <= '0';
					 R7_old <= '0';
					 BM4 <= '0';
					 BM8 <= '0';

            when S4=>
                B <= "010000000000000010100";
                Mem_W <= '0';
                Mem_R <= '0';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '0';
					 IR_Write <= '0';
					 Z_W <= '0';
					 R7_Push <= '0';
					 R7_old <= '0';
					 BM4 <= '0';
					 BM8 <= '0';

            when S5=>
                B <= "010000100011100000000";
                Mem_W <= '0';
                Mem_R <= '0';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '0';
					 IR_Write <= '0';
					 Z_W <= '0';
					 R7_Push <= '0';
					 R7_old <= '0';
					 BM4 <= '0';
					 BM8 <= '0';

            when S6=>
                B <= "010001010000000000000";
                Mem_W <= '0';
                Mem_R <= '1';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '0';
					 IR_Write <= '0';
					 Z_W <= '0';
					 R7_Push <= '0';
					 R7_old <= '0';
					 BM4 <= '0';
					 BM8 <= '0';

            when S7=>
                B <= "010000000000000011100";
                Mem_W <= '0';
                Mem_R <= '0';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '0';
					 IR_Write <= '0';
					 Z_W <= '0';
					 R7_Push <= '0';
					 R7_old <= '0';
					 BM4 <= '0';
					 BM8 <= '0';

            when S8=>
                B <= "110000000000001101100";
                Mem_W <= '0';
                Mem_R <= '0';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '0';
					 IR_Write <= '0';
					 Z_W <= '0';
					 R7_Push <= '0';
					 R7_old <= '0';
					 BM4 <= '0';
					 BM8 <= '0';

            when S9=>
                B <= "010000000000000101100";
                Mem_W <= '0';
                Mem_R <= '0';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '0';
					 IR_Write <= '0';
					 Z_W <= '0';
					 R7_Push <= '0';
					 R7_old <= '0';
					 BM4 <= '0';
					 BM8 <= '0';

            when S10=>
                B <= "010000000000000111100";
                Mem_W <= '0';
                Mem_R <= '0';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '0';
					 IR_Write <= '0';
					 Z_W <= '0';
					 R7_Push <= '0';
					 R7_old <= '0';
					 BM4 <= '0';
					 BM8 <= '0';

            when S11=>
                B <= "010000010000000000000";
                Mem_W <= '1';
                Mem_R <= '0';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '0';
					 IR_Write <= '0';
					 Z_W <= '0';
					 R7_Push <= '0';
					 R7_old <= '0';
					 BM4 <= '0';
					 BM8 <= '0';

            when S12=>
                B <= "010000000010100000010";
                Mem_W <= '0';
                Mem_R <= '0';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '0';
					 IR_Write <= '0';
					 Z_W <= '1';
					 R7_Push <= '0';
					 R7_old <= '0';
					 BM4 <= '0';
					 BM8 <= '0';

            when S13=>
                B <= "110100000100111010001";
                Mem_W <= '0';
                Mem_R <= '0';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '1';
					 IR_Write <= '0';
					 Z_W <= '0';
					 R7_Push <= '0';
					 R7_old <= '0';
					 BM4 <= '0';

            when S14=>
                B <= "110010000101111010001";
                Mem_W <= '0';
                Mem_R <= '0';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '1';
					 IR_Write <= '0';
					 Z_W <= '0';
					 R7_Push <= '0';
					 R7_old <= '0';
					 BM4 <= '0';

            when S15=>
                B <= "010110000000001010000";
                Mem_W <= '0';
                Mem_R <= '0';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '1';
					 IR_Write <= '0';
					 Z_W <= '0';
					 R7_Push <= '0';
					 R7_old <= '0';
					 BM4 <= '0';

            when S16=>
                B <= "010000000000000011000";
                Mem_W <= '0';
                Mem_R <= '0';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '0';
					 IR_Write <= '0';
					 Z_W <= '0';
					 R7_Push <= '0';
					 R7_old <= '0';
					 BM4 <= '0';

            when S17=>
                B <= "101000000000000000000";
                Mem_W <= '0';
                Mem_R <= '0';
                T1_W <= '1';
                T2_W <= '1';
					 IP_store <= '0';
					 IR_Write <= '0';
					 Z_W <= '0';
					 R7_Push <= '0';
					 R7_old <= '1';
					 BM4 <= '0';
					 BM8 <= '0';
					 
				when Sx=>
				    B <= "000000000110010000010";
					 Mem_W <= '0';
                Mem_R <= '0';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '0';
					 IR_Write <= '0';
					 Z_W <= '1';
					 R7_Push <= '0';
					 R7_old <= '0';
					 BM4 <= '1';
					 BM8 <= '0';
					 
				when Sy=>
				    B <= "000010000000000000000";
					 Mem_W <= '0';
                Mem_R <= '0';
                T1_W <= '0';
                T2_W <= '0';
					 IP_store <= '0';
					 IR_Write <= '0';
					 Z_W <= '0';
					 R7_Push <= '0';
					 R7_old <= '0';
					 BM4 <= '0';
					 BM8 <= '1';

            when others =>
                NULL;

        end case;

    end process output_proc;
	 
	 IR_proc: process (IR_Write, Mem_data, Mem_data_IR)
	 begin
	     if (IR_Write ='1') then
		      Mem_data_IR <= Mem_data;
		  else
		      Mem_data_IR <= Mem_data_IR;
		  end if;
	 end process IR_proc;
	 
	 Z_proc: process (Z_W, Z_Temp, Z_flag)
	 begin
	     if (Z_W ='1') then
		      Z_Flag <= Z_Temp;
		  else
		      Z_Flag <= Z_Flag;
		  end if;
	 end process Z_proc;
	 
	 R7_proc: process (R7_Push, IP, IP_R7)
	 begin
	     if (R7_Push ='1') then
		      IP_R7 <= IP;
		  else
		      IP_R7 <= IP_R7;
		  end if;
	 end process R7_proc;
	 
	 R7_proc2: process (R7_old, R7_datatemp, R7_datastore)
	 begin
	     if (R7_old ='1') then
		      R7_datastore <= R7_datatemp;
		  else
		      R7_datastore <= R7_datatemp;
		  end if;
	 end process R7_proc2;
	 
	 
	 T1_proc: process (T1_W, DataA, DataA_T1)
	 begin
	     if (T1_W ='1') then
		      DataA_T1 <= DataA;
		  else
		      DataA_T1 <= DataA_T1;
		  end if;
	 end process T1_proc;
	 
	 T2_proc: process (T2_W, DataB, DataB_T2)
	 begin
	     if (T2_W ='1') then
		      DataB_T2 <= DataB;
		  else
		      DataB_T2 <= DataB_T2;
		  end if;
	 end process T2_proc;

		  
    MUX1: process (B, M1, IR)
    begin
        if ((B(1) = '0') and (B(0) = '1')) then
            M1 <= "0000";
        elsif ((B(1) = '1') and (B(0) = '0')) then
            M1 <= "0010";
        elsif ((B(1) = '1') and (B(0) = '1')) then
            M1 <= IR(15 downto 12);
        else
            M1 <= M1;
        end if;
    end process MUX1;

    MUX2: process (B, M2, IR, IP_store)
    begin
        if ((B(3) = '0') and (B(2) = '1') and (IP_store = '0')) then
            M2 <= IR(5 downto 3);
        elsif ((B(3) = '1') and (B(2) = '0') and (IP_store = '0')) then
            M2 <= IR(8 downto 6);
        elsif ((B(3) = '1') and (B(2) = '1') and (IP_store = '0')) then
            M2 <= IR(11 downto 9);
		  elsif (IP_store = '1') then
				M2 <= "111";
        else
            M2 <= M2;
        end if;
    end process MUX2;

   MUX3: process (B, M3, IP_R7, IR, T3_data, IP, DataB)
	begin
		 if ((B(6) = '0') and (B(5) = '0') and (B(4) = '1')) then
			  M3 <= T3_data;
		 elsif ((B(6) = '0') and (B(5) = '1') and (B(4) = '0')) then
			  M3 <= IR(7 downto 0) & "00000000";
		 elsif ((B(6) = '0') and (B(5) = '1') and (B(4) = '1')) then
			  M3 <= "00000000" & IR(7 downto 0);
		 elsif ((B(6) = '1') and (B(5) = '0') and (B(4) = '0')) then
			  M3 <= IP;
		 elsif ((B(6) = '1') and (B(5) = '0') and (B(4) = '1')) then
			  M3 <= IP_R7;
		 elsif ((B(6) = '1') and (B(5) = '1') and (B(4) = '0')) then
			  M3 <= DataB;
		 else
			  M3 <= M3;
		 end if;
	end process MUX3;

	MUX4: process (B, M4, IP, T1_data, DataB)
	begin
		 if ((BM4 = '0') and (B(8) = '0') and (B(7) = '1')) then
			  M4 <= IP;
		 elsif ((BM4 = '0') and (B(8) = '1') and (B(7) = '0')) then
			  M4 <= T1_data;
		 elsif ((BM4 = '0') and (B(8) = '1') and (B(7) = '1')) then
			  M4 <= DataB;
		 elsif ((BM4 = '1') and (B(8) = '0') and (B(7) = '1')) then
			  M4 <= R7_datatemp;
		 else
			  M4 <= M4;
		 end if;
	end process MUX4;

	MUX5: process (B, M5, T2_data, IR)
	begin
		 if ((B(11) = '0') and (B(10) = '0') and (B(9) = '1')) then
			  M5 <= "0000000000000001";
		 elsif ((B(11) = '0') and (B(10) = '1') and (B(9) = '0')) then
			  M5 <= T2_data;
		 elsif ((B(11) = '0') and (B(10) = '1') and (B(9) = '1')) then
			  if (IR(5) = '0') then 
					M5 <= "0000000000" & IR(5 downto 0);
			  elsif (IR(5) = '1') then
					M5 <= "1111111111" & IR(5 downto 0);
			  end if;
		 elsif ((B(11) = '1') and (B(10) = '0') and (B(9) = '0')) then
			  if (IR(5) = '0') then 
					M5 <= "000000000" & IR(5 downto 0) & "0";
			  elsif (IR(5) = '1') then
					M5 <= "111111111" & IR(5 downto 0) & "0";
			  end if;
		 elsif ((B(11) = '1') and (B(10) = '0') and (B(9) = '1')) then
			  if (IR(8) = '0') then 
					M5 <= "000000" & IR(8 downto 0) & "0";
			  elsif (IR(8) = '1') then
					M5 <= "111111" & IR(8 downto 0) & "0";
			  end if;
		 elsif ((B(11) = '1') and (B(10) = '1') and (B(9) = '0')) then
		         M5 <= T4_data;
		 else
			  M5 <= M5;
		 end if;
	end process MUX5;

	MUX6: process (B, M6, IP, T3_data)
	begin
		 if ((B(13) = '0') and (B(12) = '1')) then
			  M6 <= IP;
		 elsif ((B(13) = '1') and (B(12) = '0')) then
			  M6 <= T3_data;
		 else
			  M6 <= M6;
		 end if;
	end process MUX6;

	MUX7: process (B, M7, ALU_data, Mem_data)
	begin
		 if ((B(15) = '0') and (B(14) = '1')) then
			  M7 <= ALU_data;
		 elsif ((B(15) = '1') and (B(14) = '0')) then
			  M7 <= Mem_data;
		 else
			  M7 <= M7;
		 end if;
	end process MUX7;

	MUX8: process (B, M8, ALU_data, BEQ, T2_data)
	begin
		 if ((BM8 = '0') and (B(17) = '0') and (B(16) = '1')) then
			  M8 <= ALU_data;
		 elsif ((BM8 = '0') and (B(17) = '1') and (B(16) = '0')) then
			  M8 <= BEQ;
		 elsif ((BM8 = '0') and (B(17) = '1') and (B(16) = '1')) then
			  M8 <= T2_data;
		 elsif ((BM8 = '1') and (B(17) = '0') and (B(16) = '1')) then
			  M8 <= R7_update;
		 else
			  M8 <= M8;
		 end if;
	end process MUX8;

	MUX9: process (B, M9, IR, T1_W)
	begin
		 if ((B(18) = '0')) then
			  M9 <= IR(11 downto 9);
		 elsif ((B(18) = '1')) then
			  M9 <= IR(8 downto 6);
		 else 
			  M9 <= M9;
		 end if;
	end process MUX9;

	MUX10: process (B, M10, IR, T2_W)
	begin
		 if ((B(20) = '0') AND (B(19) = '1')) then
			  M10 <= IR(8 downto 6);
		 elsif ((B(20) = '1') AND (B(19) = '0')) then
			  M10 <= IR(11 downto 9);
		 elsif ((B(20) = '1') AND (B(19) = '1')) then
			  M10 <= "111";
		 else
			  M10 <= M10;
		 end if;
	end process MUX10;
	
end struct;