library ieee;
use ieee.std_logic_1164.all;

entity count_fsm is
	port(
		ena,
		s_in,
		clk,
		n_reset,
		rdy_sub,
		rdy_cdiff
						:	in		std_ulogic;
		
		ena_cnt,
		ena_sub,
		ena_cdiff
						:	out	std_ulogic;
		state_x		
						:	out	std_ulogic_vector(3 downto 0)
	);
end count_fsm;

architecture arch of count_fsm is
	type 		state_t			is (s0, s0_ena, s1, s2, s3, s4, s5, s6);
	signal	state_reg,
				state_next:		state_t;

begin

	process(clk, n_reset)
	begin
		
		if (n_reset = '0') then
			state_reg <= s0;
		elsif falling_edge(clk) then
			state_reg <= state_next;
		end if;
		
	end process;
	
	
	process(state_reg, s_in)
	begin
		
		ena_cnt <= '0';
		ena_sub <= '0';
		ena_cdiff <= '0';
		case state_reg is
		
			when s0 =>
				if ena = '1' then
					state_next <= s0_ena;
				else state_next <= s0;
				end if;
				state_x <= x"F";
			
			-- find out where we are
			when s0_ena =>
			state_x <= x"0";
				if (s_in = '0') then
					-- slot is there, but falling edge missed, goto s1 to wait until slot is over
					state_next <= s1;
				elsif (s_in = '1') then
					-- goto s2 to wait for the falling edge to be detected
					state_next <= s2;
				-- explicitely filter out other (im)possible values of std_ulogic
				else state_next <= s0;
				end if;
				
			-- wait until slot is over, goto s2 to wait until the beginning of round
			when s1 =>
				state_x <= x"1";
				if (s_in = '1') then
					state_next <= s2;
				else state_next <= s1;
				end if;

			-- wait for the falling edge be detected, goto counting
			when s2 =>
				state_x <= x"2";
				if (s_in = '0') then
					state_next <= s3;
				else state_next <= s2;
				end if;
			
			-- counting, wait for rising edge to stop
			when s3 =>
				state_x <= x"3";
				if (s_in = '1') then
					state_next <= s4;
				else state_next <= s3;
				end if;
				ena_cnt <= '1';
			
			-- rising edge detected, stop counting, calculate position to drop (ena c_diff)
			-- when ready, load counter_sub
			when s4 =>
				state_x <= x"4";
				if rdy_cdiff = '1' then
					state_next <= s5;
					ena_sub <= '1';
				else state_next <= s4;
				end if;
				ena_cdiff <= '1';

			-- count down
			when s5 =>
				state_x <= x"5";
				if rdy_sub = '1' then
					state_next <= s6;
				else state_next <= s5;
				end if;
				ena_sub <= '1';
			
			when s6 =>	-- count down complete
				state_x <= x"6";
				state_next <= s6;
				
		end case;
		
	end process;

end arch;
