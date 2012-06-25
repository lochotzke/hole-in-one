library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_c is
	generic(
		-- counter bits
		BITS:		integer := 4
	);
	port(
		s_in,
		clk,
		ena,
		n_reset	:	in		std_ulogic;
		
		rdy_c		:	out	std_ulogic;
		count		:	out	std_ulogic_vector(BITS-1 downto 0);
		state_x	:	out	std_ulogic_vector(3 downto 0)
	);
end counter_c;

architecture arch of counter_c is
	type 		state_t is (s0, s1, s2);
	signal	state,
				state_next
								:	state_t;
	signal	count_int,
				count_next	:	std_ulogic_vector(BITS-1 downto 0);
				
	signal	mux			:	std_ulogic;

begin
	
	process(clk, n_reset)
	begin
		if (n_reset = '0') then
			count_int <= (others => '0');
			state <= s0;
		elsif falling_edge(clk) then
			count_int <= count_next;
			state <= state_next;
		end if;
	end process;

	
	process(s_in, state)
	begin
		
		-- keep current value, just to be sure nothing else happens if not assigned elsewhere
		count_next <= count_next;
		-- when '0', mux immediately routes '0' to the output to avoid 1 tick delay at reset
		mux <= '1';
		rdy_c <= '1';
		
		case state is
			
			-- detect round begin by sampling ena_cnt (from count_fsm)
			when s0 =>
				state_x <= x"0";
				-- don't let anyone trust the output yet
				rdy_c <= '0';
				if ena = '1' then
					state_next <= s1;
					-- ena always comes with 1 tick delay, therefore count in s2 must already be equal to 2 to be intact
					count_next <= std_ulogic_vector(to_unsigned(2, BITS));
				else
					state_next <= s0;
					count_next <= (others => '0');
				end if;
			
			-- counting, watch on rising_edge(s_in), proceed to s2
			when s1 =>
				state_x <= x"1";
				count_next <= std_ulogic_vector(unsigned(count_int) + 1);
				if s_in = '1' then
					state_next <= s2;
				else
					state_next <= s1;
				end if;
			
			-- counting, watch on falling_edge(s_in) to reset counter
			when s2 =>
				state_x <= x"2";
				if s_in = '1' then
					state_next <= s2;
					count_next <= std_ulogic_vector(unsigned(count_int) + 1);
				else
					state_next <= s1;
					-- set output immediately to '0'
					mux <= '0';
					-- set count to 1 in s1
					count_next <= std_ulogic_vector(to_unsigned(1, BITS));

				end if;
			
		end case;
		
	end process;
	
	count <=	count_int when mux = '1' else
				std_ulogic_vector(to_unsigned(0, BITS));

end arch;
