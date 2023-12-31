library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity tb_MUX_4 is
end entity;

architecture tb of tb_MUX_4 is
	component MUX_4 is 
		Port ( S : in STD_LOGIC_VECTOR (1 downto 0);
				 I : in STD_LOGIC_VECTOR (3 downto 0);
				 Y : out STD_LOGIC);
	end component;

	signal S : STD_LOGIC_VECTOR(1 downto 0);
	signal I : STD_LOGIC_VECTOR(3 downto 0);
	signal Y : STD_LOGIC;

	begin 
		uut : MUX_4 port map(
									S => S,
									I => I,
									Y => Y
									);
	stim : process
	begin
		I(0) <= '0';
		I(1) <= '1';
		I(2) <= '0';
		I(3) <= '1';

		S <= "00";wait for 10 ns;
		S <= "01";wait for 10 ns;
		S <= "10";wait for 10 ns;
		S <= "11";wait for 10 ns;
	wait;
	end process;
end tb;