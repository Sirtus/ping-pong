library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_controller is
    generic(
        hd: integer := 800;
        hf: integer := 56;
        hr: integer := 120;
        hb: integer := 64;

        vd: integer := 600;
        vf: integer := 37;
        vr: integer := 6;
        vb: integer := 23;

        h_pol: std_logic := '1';
        v_pol: std_logic := '1'
    );
    port(
        clk: in std_logic;
        pixel_x, pixel_y: out std_logic_vector(9 downto 0);
        h_sync, v_sync: out std_logic;
        video_on: out std_logic
    );
end vga_controller;

architecture arch of vga_controller is

    constant HTIME: integer := hd + hf + hr + hb;
    constant VTIME: integer := vd + vf + vr + vb;
    signal h_counter: integer range 0 to HTIME - 1;
    signal v_counter: integer range 0 to VTIME - 1;
    signal pix_x, pix_y: std_logic_vector(9 downto 0);

    begin

        process(clk)
        begin 
            if rising_edge(clk) then
                if h_counter = HTIME-1 then
                    h_counter <= 0;
                    if v_counter = VTIME-1 then
                        v_counter <= 0;
                    else
                        v_counter <= v_counter + 1;
                    end if ;
                else
                    h_counter <= h_counter + 1;
                end if ;
            
                if h_counter < hd then
                    pix_x <= std_logic_vector(to_unsigned(h_counter, 10));
                end if ;

                if v_counter < vd then
                    pix_y <= std_logic_vector(to_unsigned(v_counter, 10));
                end if ;
            end if ;
        end process;
        
        pixel_x <= std_logic_vector(to_unsigned(h_counter, 10));
        pixel_y <= std_logic_vector(to_unsigned(v_counter, 10));
        v_sync <= v_pol when (v_counter > vd+vf) and (v_counter < VTIME-vb-1) else not v_pol;
        h_sync <= h_pol when (h_counter > hd+hf) and (h_counter < HTIME-hb-1) else not h_pol;
        video_on <= '1' when (v_counter < vd) and (h_counter < hd) else '0';

    end arch;