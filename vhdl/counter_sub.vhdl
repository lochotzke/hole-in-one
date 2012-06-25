library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_sub is
	generic(
		BITS:		integer := 4			-- counter bits
	);
	port(
		ena,
		clk,
		n_reset:		in		std_ulogic;
		load:			in		std_ulogic_vector(BITS-1 downto 0);
		rdy:			out	std_ulogic;
		count:		out	std_ulogic_vector(BITS-1 downto 0);
		state_x:		out	std_ulogic_vector(3 downto 0)
	);
end counter_sub;

architecture arch of counter_sub is
	type 		state_t is (s0, s1);
	signal	state, state_next
								:	state_t;
	signal	count_int,
				count_next	:	std_ulogic_vector(BITS-1 downto 0);

begin
	
	process(clk, n_reset)
	begin
		if (n_reset = '0') then
			count_int <= (others => '1');
			state <= s0;
		elsif falling_edge(clk) then
			count_int <= count_next;
			state <= state_next;
		end if;
	end process;

	
	process(ena, state)
	begin
		
		case state is
		
			-- load the counter with load-1 to avoid 1 tick delay
			-- if load=0 release the magnet immediately
			when s0 =>
				state_x <= x"0";
				rdy <= '0';
				if load = (load'range => '0') then
					count_next <= (others => '0');
				else
					count_next <= std_ulogic_vector(unsigned(load) - 1);
				end if;
				
				if ena = '1' then
					if load = (load'range => '0') then rdy <= '1';
					end if;
					state_next <= s1;
				else state_next <= s0;
				end if;
			
			-- release the magnet when countdown complete
			when s1 =>
				state_x <= x"1";
				state_next <= s1;
				if count_int = (count_int'range => '0') then
					rdy <= '1';
					count_next <= count_int;
				else
					rdy <= '0';
					count_next <= std_ulogic_vector(unsigned(count_int) - 1);
				end if;
			
		end case;
		
	end process;
	
	count <= std_ulogic_vector(count_int);

end arch;
