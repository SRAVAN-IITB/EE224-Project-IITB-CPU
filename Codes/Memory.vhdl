library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Memory is
	port(Address:in STD_LOGIC_VECTOR(15 downto 0);
	     Input:in STD_LOGIC_VECTOR(7 downto 0);
		  data_write: in STD_LOGIC_VECTOR(15 downto 0);
		  data_out: out STD_LOGIC_VECTOR(15 downto 0);
		  Output:out STD_LOGIC_VECTOR(7 downto 0);
		  clock, MeM_R,MeM_W: in STD_LOGIC
		  );
end entity Memory;

architecture BHV of Memory is

	type array_of_vectors is ARRAY (255 downto 0) of STD_LOGIC_VECTOR(15 downto 0);

signal memory_storage: array_of_vectors := (17 => "1001001000011110",
                                            18 => "1010010001000000",
														  19 => "0001010010000010",
														  20 => "1011010001010000",
													 others => "0000000000000000");
signal output1: std_logic_vector(15 downto 0);
															
	begin
	
	-- Process to write data into the memory storage
	memory_write: PROCESS(clock, MeM_W, data_write, Address)
		begin
			if(clock' event and clock = '1') then
			memory_storage(30) <= "00000000" & Input(7 downto 0);
				if (MeM_W = '1') then
					memory_storage(to_integer(unsigned(Address))) <= data_write(15 downto 0);
				else 
					NULL;
				end if;
			else
				NULL;
			end if;
		end PROCESS;

	-- Process to read data from the memory storage
	memory_read: PROCESS(MeM_R, Address, memory_storage)
	begin
		if (MeM_R = '1') then
			if (unsigned(Address) < 255) then
					data_out(15 downto 0) <= memory_storage(to_integer(unsigned(Address)));
			else
				data_out <= (others => '0');  -- Default assignment for invalid address
			end if;
		end if;
	end PROCESS;


	-- unsigned(Address) converts the Address signal to an unsigned integer to make sure that 
	-- the range of values for Address is non-negative and falls within the valid range (0 to 4095), 
	-- and to_integer then converts that unsigned integer to a standard integer. 
	-- This resulting integer is used as an index to access the memory_storage array.
	
					Output1(15 downto 0) <= memory_storage(46);
					Output(7 downto 0) <= Output1(7 downto 0);
	
end architecture BHV;