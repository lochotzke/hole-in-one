library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity c_diff is
	generic(
		BITS		:	integer	:= 4		-- number of input bits
	);
	port(
		clk,
		ena,
		rdy_c,
		n_reset	:	in		std_ulogic;
		count_in,
		count_c,
		t_fall	:	in		std_ulogic_vector(BITS-1 downto 0);
		
		diff		:	out	std_ulogic_vector(BITS-1 downto 0);
					
		diff_rdy	:	out	std_ulogic;
		state_x	:	out	std_ulogic_vector(3 downto 0)
	);
	
end c_diff;

architecture arch of c_diff is
	signal	diff_r_tf,	-- calculated position to drop relative to the end of round
				diff_c_p,	-- difference between position to drop and current position
				tmp_x16,
				tmp_x18,		-- round
				
				tmp,			-- corrected position to drop relative to the end of round
				tmp_p,		-- p = round - tmp		-- position to drop relative to the beginning of round
				tmp_r,		-- r = round - count_c	-- round time left from current position
				tmp_next,
				round_int	:	std_ulogic_vector(BITS-1 downto 0);

	type		state_t		is (s0, s1, s2);
	signal	state_int,
				state_next	:	state_t;

	begin
	-- 16x count_in
	-- 28 = (33-1) - 4
	-- 33 - number of bits in project
	-- 1 bit reserved for sign
	-- 4 bits reserved for left shift for multiplication by 16 = 2^4
	tmp_x16		<= count_in(28 downto 0) & x"0";
	
	-- 16x+2x count_in
	tmp_x18		<= std_ulogic_vector(unsigned(tmp_x16) + unsigned(count_in(31 downto 0) & '0'));

	round_int		<= tmp_x18;
	
	diff_r_tf		<= std_ulogic_vector(unsigned(round_int) - unsigned(t_fall));
	diff_c_p			<= std_ulogic_vector(unsigned(count_c) - unsigned(tmp_p));
	
	tmp_p		<= tmp_next;
	tmp_r		<= std_ulogic_vector(unsigned(round_int) - unsigned(count_c));

	process(clk, n_reset)
	begin
		
		if (n_reset = '0') then
			state_int <= s0;
			tmp <= (others=>'0');
		elsif falling_edge(clk) then
			state_int <= state_next;
			tmp <= tmp_next;
		end if;
		
	end process;
	
	process(ena, state_int)
	begin
		
		diff <= tmp_next;
		
		case state_int is
			-- wait until ena asserted by count_fsm, load tmp with diff_r_tf
			when s0 =>
				state_x <= x"0";
				diff_rdy <= '0';
				-- dummy value while inactive
				tmp_next <= t_fall;

				if ena = '1' and rdy_c = '1' then
					-- if diff_r_tf negative goto s1 to find out (diff_r_rf mod round)
					if diff_r_tf(BITS-1) = '1' then
						state_next <= s1;
						tmp_next <= diff_r_tf;
					else 
						state_next <= s2;
					end if;
				else state_next <= s0;
				end if;
			
			-- add round until diff (i.e. tmp) is positive
			when s1 =>
				state_x	<= x"1";
				diff_rdy <= '0';
				tmp_next	<= std_ulogic_vector(unsigned(tmp) + unsigned(round_int));
				if tmp_next(BITS-1) = '1' then
					state_next <= s1;
				else
					state_next <= s2;
					-- enable rdy only in s2 to load tmp_next to the counter_sub in s1
				end if;
			
			when s2 =>
				state_x <= x"2";
				diff_rdy <= '1';
				tmp_next <= tmp;
				
				-- if current position is greater than position to drop
				-- add the rest of the round and position to drop to release the magnet in the next round
				-- else countdown the difference and release the magnet already in the current round
				if diff_c_p(BITS-1) = '0' then
					diff <= std_ulogic_vector(unsigned(tmp_p) + unsigned(tmp_r));
				else
					diff <= std_ulogic_vector(unsigned(tmp_p) - unsigned(count_c));
				end if;
				
				state_next <= s2;
				
		end case;
		
	end process;

end arch;
