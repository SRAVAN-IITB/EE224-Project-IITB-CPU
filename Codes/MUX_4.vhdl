library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MUX_4 is
    Port ( S : in  STD_LOGIC_VECTOR (1 downto 0);
           I : in  STD_LOGIC_VECTOR (3 downto 0);
           Y : out STD_LOGIC);
end MUX_4;

architecture BHV of MUX_4 is
begin
	process (S,I)
	begin
		if (S <= "00") 	then
			Y <= I(0);
		elsif (S <= "01") then
			Y <= I(1);
		elsif (S <= "10") then
			Y <= I(2);
		else
			Y <= I(3);
		end if;
	end process;
end BHV;