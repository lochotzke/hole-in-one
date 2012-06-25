library ieee;
use ieee.std_logic_1164.all;

entity main is
	generic(
				-- counter bits
				BITS	:		integer := 33
	);
	port(
		CLK_50,
		-- sensor
		B0,
		-- button
		B1
				:	in		std_ulogic;
		SW		:	in		std_ulogic_vector(17 downto 0);
		KEY	:	in		std_ulogic_vector(3 downto 0);

		LEDG	:	out	std_ulogic_vector(8 downto 0);
		LEDR	:	out	std_ulogic_vector(17 downto 0);
		
		-- magnet
		B3		:	out	std_ulogic
		
	);
end main;

architecture arch of main is
				-- adjustable release delay (Tf)
	signal	del,
				state_fsm,
				state_cdiff,
				state_sub
							:	std_ulogic_vector(3 downto 0);	

				-- global enable
	signal	ena,
				ena_cnt,
				ena_sub,
				ena_cdiff,
				rdy_c,
				rdy_sub,
				rdy_cdiff
							:	std_ulogic;								


	signal	diff,
				c_cnt,
				count		:	std_ulogic_vector(BITS-1 downto 0);
	
begin

	-- add some fancy-looking LEDs
	LEDR(3 downto 0) <= state_fsm;
	LEDG(7 downto 4) <= state_cdiff;
	LEDG(3 downto 0) <= state_sub;
	
	LEDG(8) <= not B0;	-- input from sensor, low active (rotation clockwise!)
	ena <= not B1;			-- input from button, low active

	-- main FSM
	count_fsm_unit: entity work.count_fsm
		port map(
		-- in
			ena => ena,
			s_in => not B0,
			clk => CLK_50,
			n_reset => KEY(2),
			rdy_sub => rdy_sub,
			rdy_cdiff => rdy_cdiff,
		-- out
			ena_cnt => ena_cnt,
			ena_sub => ena_sub,
			ena_cdiff => ena_cdiff,
			state_x => state_fsm
		);
	
	-- current round position counter
	counter_c_unit: entity work.counter_c
		generic map(
		-- setting number of bits
			BITS => BITS
			)
		port map(
		-- in
			s_in => not B0,
			ena => ena_cnt,
			clk => CLK_50,
			n_reset => KEY(2),
		-- out
			rdy_c => rdy_c,
			count => c_cnt
		);

	-- slot measurement counter
	counter_unit: entity work.counter
		generic map(
		-- setting number of bits
			BITS => BITS
			)
		port map(
		-- in
			clk => CLK_50,
			ena => ena_cnt,
			n_reset => KEY(2),
		-- out
			count => count
		);
	
	-- ball release countdown
	counter_sub_unit: entity work.counter_sub
		generic map(
		-- setting number of bits
			BITS => BITS
			)
		port map(
		-- in
			ena => ena_sub,
			clk => CLK_50,
			n_reset => KEY(2),
			load => diff,
		-- out
			rdy => rdy_sub,
			state_x => state_sub
		);
	
	B3 <= not rdy_sub;
	LEDR(17) <= rdy_sub;				-- MAGNET RELEASE, low active
	

	-- compute a correct value to load into counter_sub
	c_diff_unit: entity work.c_diff
		generic map(
		-- setting number of bits
			BITS => BITS
			)
		port map(
		-- in
			clk		=> CLK_50,
			ena		=> ena_cdiff,
			rdy_c		=> rdy_c,
			n_reset	=> KEY(2),
			count_in	=> count,
			count_c	=> c_cnt,
			-- adjustable Tf
			t_fall	=> '0' & x"0" & SW(17 downto 10) & x"12e62", -- "00f12e62"
		-- out
			diff		=> diff,
			diff_rdy	=> rdy_cdiff,
			state_x 	=> state_cdiff
		);

end arch;
