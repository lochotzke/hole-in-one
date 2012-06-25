library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
	generic(
		-- counter bits
		BITS:	integer := 4
	);
	port(
		clk,
		ena,
		n_reset:	in		std_ulogic;
		count:	out	std_ulogic_vector(BITS-1 downto 0)
	);
end counter;

architecture arch of counter is
	signal	count_int,
				count_int_next: unsigned(BITS-1 downto 0);
begin

	process(clk, n_reset)
	begin
		if n_reset='0' then
			count_int <= (others=>'0');
		elsif falling_edge(clk) then
			count_int <= count_int_next;
		end if;
	end process;
	
	count_int_next <=	count_int + 1 when ena = '1' else
							count_int;
	
	count <= std_ulogic_vector(count_int);

end arch;
