library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Memory is
	port(Address:in STD_LOGIC_VECTOR(15 downto 0);
		  data_write: in STD_LOGIC_VECTOR(15 downto 0);
		  data_out: out STD_LOGIC_VECTOR(15 downto 0);
		  clock, MeM_R,MeM_W: in STD_LOGIC
		  );
end entity Memory;

architecture BHV of Memory is

	type array_of_vectors is ARRAY (4095 downto 0) of STD_LOGIC_VECTOR(7 downto 0);
--	signal memory_storage: array_of_vectors := (0 => "01110000", 
--															 1 => "10100010", 
--															 2 => "00000000", 
--															 3 => "00000010", 
--															 4 => "00000000", 
--															 5 => "00000011", 
--															 6 => "00000000", 
--															 7 => "00000100",
--															 8 => "00000000", 
--															 9 => "00000101", 
--															10 => "00000000", 
--															11 => "00000110", 
--															12 => "00000000", 
--															13 => "00000111", 
--															14 => "00000000", 
--															15 => "00001000", 
--															16 => "00000000", 
--															17 => "00001001", 
--															others => "00000000"
--															);
signal memory_storage: array_of_vectors := (16 => "00010000", 
														17 => "01001100", 
														18 => "00010010", 
														19 => "00111011", 
														20 => "00110000", 
														21 => "01010000", 
														others => "00000000");
															
	begin
	-- Process to write data into the memory storage
	memory_write: PROCESS(clock, MeM_W, data_write, Address)
		begin
			if(clock' event and clock = '1') then
				if (MeM_W = '1') then
					memory_storage(to_integer(unsigned(Address))) <= data_write(15 downto 8);
					memory_storage(to_integer(unsigned(Address)) + 1) <= data_write(7 downto 0);
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
			if (unsigned(Address) < 4096) then
					data_out(15 downto 8) <= memory_storage(to_integer(unsigned(Address)));
					data_out(7 downto 0) <= memory_storage(to_integer(unsigned(Address)) + 1);
			else
				data_out <= (others => '0');  -- Default assignment for invalid address
			end if;
		end if;
	end PROCESS;


	-- unsigned(Address) converts the Address signal to an unsigned integer to make sure that 
	-- the range of values for Address is non-negative and falls within the valid range (0 to 4095), 
	-- and to_integer then converts that unsigned integer to a standard integer. 
	-- This resulting integer is used as an index to access the memory_storage array.
	
end architecture BHV;