library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity text_controller is
    generic(
        MAX_X: integer := 800;
        MAX_Y: integer := 600
    );
    port(
        clk: in std_logic;
        refr_clk: in std_logic;
        text_on: out std_logic;
        text_rgb: out std_logic_vector(11 downto 0);
        pixel_x, pixel_y: in unsigned(9 downto 0);
        player1_score, player2_score: in integer;
        show_instructions, show_final: in std_logic
    );
end text_controller;

architecture arch of text_controller is

    -- score
    constant SCORE_TEXT_CHARS:integer := 12;
    constant SCORE_TEXT_SIZE: integer := 2;
    constant SCORE_TEXT_LEN:integer := SCORE_TEXT_CHARS*8;
	 constant DIGITS: string(1 to 10) := "0123456789";

    signal score_text: string(1 to SCORE_TEXT_CHARS) := "SCORE: 0 - 0";
    signal score_x_l: integer := MAX_X/2  - (SCORE_TEXT_LEN*SCORE_TEXT_SIZE)/2;
    constant score_y_t: integer := 10;
    signal score_char_number: integer range 0 to SCORE_TEXT_CHARS := 0;
    signal score_char: std_logic_vector(6 downto 0);
    signal score_on, score_bit_on, score_bit: std_logic;
    signal score_rgb: std_logic_vector(11 downto 0);
    signal score_row_addr: integer range 0 to 16;
    signal score_char_addr: std_logic_vector(10 downto 0);
    signal score_char_row: std_logic_vector(7 downto 0);
    signal score_bit_addr: integer range 0 to 7;

    -- instructions
    constant INST_TEXT_CHARS:integer := 11;
    constant INST_TEXT_SIZE: integer := 1;
    constant INST_TEXT_LEN:integer := INST_TEXT_CHARS*8;

    signal inst_text: string(1 to INST_TEXT_CHARS) := "PRESS SPACE";
    signal inst_x_l: integer := MAX_X/2  - (INST_TEXT_LEN*INST_TEXT_SIZE)/2;
    constant inst_y_t: integer := MAX_Y/2+(8*INST_TEXT_SIZE)/2 + 50;
    signal inst_char_number: integer range 0 to INST_TEXT_CHARS := 0;
    signal inst_char: std_logic_vector(6 downto 0);
    signal inst_on, inst_bit_on, inst_bit: std_logic;
    signal inst_rgb: std_logic_vector(11 downto 0);
    signal inst_row_addr: integer range 0 to 16;
    signal inst_char_addr: std_logic_vector(10 downto 0);
    signal inst_char_row: std_logic_vector(7 downto 0);
    signal inst_bit_addr: integer range 0 to 7;

    -- end
    constant END_TEXT_CHARS:integer := 12;
    constant END_TEXT_SIZE: integer := 1;
    constant END_TEXT_LEN:integer := END_TEXT_CHARS*8;

    type end_text_t is array(0 to 1) of string(1 to END_TEXT_CHARS);
    signal end_text: end_text_t := (" GAME  OVER ", "PLAYER X WON");
    signal end_text_string: string(1 to END_TEXT_CHARS);
    signal end_array_row: integer range 0 to 1;
    signal end_x_l: integer := MAX_X/2  - (END_TEXT_LEN*END_TEXT_SIZE)/2;
    constant end_y_t: integer := 150;
    signal end_char_number: integer range 0 to END_TEXT_CHARS := 0;
    signal end_char: std_logic_vector(6 downto 0);
    signal end_on, end_bit_on, end_bit: std_logic;
    signal end_rgb: std_logic_vector(11 downto 0);
    signal end_row_addr: integer range 0 to 16;
    signal end_char_addr: std_logic_vector(10 downto 0);
    signal end_char_row: std_logic_vector(7 downto 0);
    signal end_bit_addr: integer range 0 to 7;


    signal addr: std_logic_vector(10 downto 0);
    signal row: std_logic_vector(7 downto 0);
    signal start_on, final_on: std_logic;



    begin 

    font_rom: entity work.font_rom(arch)
    port map(
        clk => clk, addr => addr, row => row
    );

    process(refr_clk)
    begin
        if refr_clk = '1' then
            score_text(8) <= DIGITS(player1_score+1);
            score_text(12) <= DIGITS(player2_score+1);
            if player1_score = 3 then
                end_text(1) <= "PLAYER 1 WON";
            elsif player2_score = 3 then
                end_text(1) <= "PLAYER 2 WON";
            end if ;
            start_on <= show_instructions;
            final_on <= show_final;

            
        end if ;
    end process;


    -- SCORE ===============================================================
    score_on <= '1' when (pixel_x >= score_x_l) and (pixel_x <= score_x_l + (SCORE_TEXT_LEN*SCORE_TEXT_SIZE)) and
                         (pixel_y >= score_y_t) and (pixel_y <= score_y_t + (16*SCORE_TEXT_SIZE)) else '0';
    
    score_char_number <= ((to_integer(pixel_x) - score_x_l)/(8*SCORE_TEXT_SIZE))+1;
    score_char <= std_logic_vector(to_unsigned(character'pos(score_text(score_char_number)), 7)) when 
                score_on = '1' else (others => '0');
    score_row_addr <= (to_integer(pixel_y) - score_y_t)/SCORE_TEXT_SIZE when score_on = '1' else 0;
    score_char_addr <= score_char & std_logic_vector(to_unsigned(score_row_addr, 4)) when 
                score_on = '1' else (others => '0');

    score_bit_addr <= (8 - to_integer(pixel_x((2+SCORE_TEXT_SIZE) downto (SCORE_TEXT_SIZE-1))) + score_x_l) mod 8 when score_on = '1' else 0;

    score_char_row <= row when score_on = '1' else (others => '0');
    score_bit <= score_char_row(score_bit_addr) when score_on = '1' else '0';
    score_bit_on <= score_bit when score_on = '1' else '0';

    -- INSTRUCTIONS ===============================================================

    inst_on <= '1' when (pixel_x >= inst_x_l) and (pixel_x <= inst_x_l + (INST_TEXT_LEN*INST_TEXT_SIZE)) and
                (pixel_y >= inst_y_t) and (pixel_y <= inst_y_t + (16*INST_TEXT_SIZE)) else '0';

    inst_char_number <= ((to_integer(pixel_x) - inst_x_l)/(8*INST_TEXT_SIZE))+1;
    inst_char <= std_logic_vector(to_unsigned(character'pos(inst_text(inst_char_number)), 7)) when 
                inst_on = '1' else (others => '0');
    inst_row_addr <= (to_integer(pixel_y) - inst_y_t)/INST_TEXT_SIZE when inst_on = '1' else 0;
    inst_char_addr <= inst_char & std_logic_vector(to_unsigned(inst_row_addr, 4)) when 
                inst_on = '1' else (others => '0');

    inst_bit_addr <= 8 - (to_integer(pixel_x((2+INST_TEXT_SIZE) downto (INST_TEXT_SIZE-1))) + inst_x_l mod 8) when inst_on = '1' else 0;

    inst_char_row <= row when inst_on = '1' else (others => '0');
    inst_bit <= inst_char_row(inst_bit_addr) when inst_on = '1' else '0';
    inst_bit_on <= inst_bit when inst_on = '1' and start_on = '1' else '0';


    -- END ===============================================================

    end_on <= '1' when (pixel_x >= end_x_l) and (pixel_x <= end_x_l + (END_TEXT_LEN*END_TEXT_SIZE)) and
                (pixel_y >= end_y_t) and (pixel_y <= end_y_t + (16*END_TEXT_SIZE*2)) else '0';

    end_char_number <= ((to_integer(pixel_x) - end_x_l)/(8*END_TEXT_SIZE))+1;
    end_array_row <= (to_integer(pixel_y) - end_y_t)/(END_TEXT_SIZE*16); 
    end_text_string <= end_text(end_array_row);
    end_char <= std_logic_vector(to_unsigned(character'pos(end_text_string(end_char_number)), 7)) when 
                end_on = '1' else (others => '0');
    end_row_addr <= ((to_integer(pixel_y) - (( end_y_t))/END_TEXT_SIZE) mod 16) when end_on = '1' else 0;
    end_char_addr <= end_char & std_logic_vector(to_unsigned(end_row_addr, 4)) when 
                end_on = '1' else (others => '0');

    end_bit_addr <= 8 - (to_integer(pixel_x) + end_x_l )/END_TEXT_SIZE when end_on = '1' else 0;

    end_char_row <= row when end_on = '1' else (others => '0');
    end_bit <= end_char_row(end_bit_addr) when end_on = '1' else '0';
    end_bit_on <= end_bit when end_on = '1' and final_on = '1' else '0';


    text_on <= score_bit_on or inst_bit_on or end_bit_on;

    addr <= score_char_addr when score_on = '1' else inst_char_addr when inst_on = '1' 
            else end_char_addr when end_on = '1' else (others => '0');

    process(score_on, score_rgb, score_bit_on, inst_on, inst_rgb, inst_bit_on)
    begin 
        if score_on = '1' then
            text_rgb <= "111111111111";
        elsif inst_on = '1' then
            text_rgb <= "111111110000";
        elsif end_on = '1' then
            text_rgb <= "000111100111";
        end if ;
    end process;


end arch;