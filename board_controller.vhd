library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity board is
    generic(
        MAX_X: integer := 800;
        MAX_Y: integer := 600
    );
    port(
        clk: in std_logic;
        video_on: in std_logic;
        red, green, blue: out std_logic_vector(3 downto 0);
        pixel_x, pixel_y: in std_logic_vector(9 downto 0);
        player1_btn, player2_btn: in std_logic_vector(1 downto 0);
        space_btn: in std_logic
    );
end board;

architecture arch of board is
    type game_state_t is (idle, play, end_game);
    signal game_state: game_state_t := idle;

    signal pix_x, pix_y: unsigned(9 downto 0);
    signal px, py: integer := 0;
    signal refr_clk: std_logic;
    signal text_on: std_logic;
    signal text_rgb: std_logic_vector(11 downto 0);

    signal show_instructions, show_final: std_logic;

    constant PLAYER_DELTA: integer := 2;
    constant BALL_DELTA: integer := 2;
    constant PLAYER_WIDTH: integer := 30;
    constant PLAYER_HEIGHT: integer := 100;
    constant BALL_SIZE: integer := 8;

    -- ############################# PLAYER 1

    constant player1_x_l: integer := 100;
    signal player1_y_t: integer := MAX_Y/2; 
    signal player1_reg, player1_next: integer := MAX_Y/2;
    signal player1_on: std_logic;
    signal player1_rgb: std_logic_vector(11 downto 0);
    signal player1_score,player1_score_next: integer := 0;
    signal player1_reached_goal: std_logic;

    -- #######################################

    -- ############################# PLAYER 2

    constant player2_x_l: integer := 700 - PLAYER_WIDTH;
    signal player2_y_t: integer := MAX_Y/2; 
    signal player2_reg, player2_next: integer := MAX_Y/2;
    signal player2_on: std_logic;
    signal player2_rgb: std_logic_vector(11 downto 0);
    signal player2_score, player2_score_next: integer := 0;
    signal player2_reached_goal: std_logic;

    -- #######################################

    -- ############################# BALL

    signal ball_x_l, ball_y_t: integer := 300;
    signal ball_x_next, ball_x_reg: integer := MAX_X/2;
    signal ball_y_next, ball_y_reg: integer := MAX_Y/2;
    signal ball_x_delta_reg, ball_x_delta_next: integer := 0;
    signal ball_y_delta_reg, ball_y_delta_next: integer := 0;
    signal ball_on: std_logic;
    signal ball_bit_on: std_logic;
    signal ball_rom_addr: integer range 0 to 7;
    signal ball_rom_row: std_logic_vector(7 downto 0);
    signal ball_rom_bit_addr: integer range 0 to 7;
    signal ball_rom_bit: std_logic;
    signal ball_rgb: std_logic_vector(11 downto 0);
    
    type ball_rom_t is array(0 to 7) of std_logic_vector(7 downto 0);
    constant ball_rom: ball_rom_t := 
    (
        "00111100",
        "01111110",
        "11111111",
        "11111111",
        "11111111",
        "11111111",
        "01111110",
        "00111100"
    );

    -- #######################################

    begin

        text_controller: entity work.text_controller(arch)
        port map(
            clk => clk, pixel_x => pix_x, pixel_y => pix_y,
            text_rgb => text_rgb, text_on => text_on,
            player1_score => player1_score, player2_score => player2_score,
            refr_clk => refr_clk, show_final => show_final, show_instructions => show_instructions
        );

        process(clk)
        begin
            if rising_edge(clk) then
                player1_reg <= player1_next;
                player2_reg <= player2_next;
                ball_y_reg <= ball_y_next;
                ball_x_reg <= ball_x_next;
                ball_x_delta_reg <= ball_x_delta_next;
                ball_y_delta_reg <= ball_y_delta_next;

                case( game_state ) is
                
                    when idle =>
                        show_instructions <= '1';
                        show_final <= '0';
                        player2_score_next <= 0;
                        player1_score_next <= 0;
                        if space_btn = '1' then
                            game_state <= play;
                        end if ;

                    when play =>
                        show_instructions <= '0';
                        show_final <= '0';

                        if ball_x_l + BALL_SIZE < BALL_SIZE then
                    
                            if player2_reached_goal = '0' and ball_x_delta_reg = -BALL_DELTA then
                                player2_score_next <= player2_score + 1;
                            end if ;
                            player2_reached_goal <= '1';
                            player1_reached_goal <= '0';
                        elsif ball_x_l > MAX_X  then
                            
                            if player1_reached_goal = '0' and ball_x_delta_reg = BALL_DELTA then
                                player1_score_next <= player1_score + 1;
                            end if ;
                            player1_reached_goal <= '1';
                            player2_reached_goal <= '0';
                        else
                            player1_reached_goal <= '0';
                            player2_reached_goal <= '0';
                        end if;

                        if player1_score >= 3 or player2_score >= 3 then
                            game_state <= end_game;
                        end if ;

                    when end_game =>
                        show_instructions <= '1';
                        show_final <= '1';
                        if space_btn = '1' then
                            player2_score_next <= 0;
                            player1_score_next <= 0;
                            game_state <= play;
                        end if ;

                    when others =>
                        game_state <= idle;
                
                end case ;
            end if ;
        end process;

        pix_x <= unsigned(pixel_x);
        pix_y <= unsigned(pixel_y);
        px <= to_integer(unsigned(pixel_x));
        py <= to_integer(unsigned(pixel_y));
        refr_clk <= '1' when px = 0 and py = 601 else '0';

        -- player 1

        player1_y_t <= player1_reg;

        player1_on <= '1' when (pix_x > player1_x_l) and (pix_x < player1_x_l + PLAYER_WIDTH) and
                               (pix_y > player1_y_t) and (pix_y < player1_y_t + PLAYER_HEIGHT) 
                               else '0';
        player1_rgb <= "111001000111";

        process(player1_reg, player1_y_t, refr_clk)
        begin
            if refr_clk = '1' then
                
                if player1_btn(0) = '1' and player1_y_t + PLAYER_HEIGHT < MAX_Y then
                    player1_next <= player1_reg + PLAYER_DELTA;
                elsif player1_btn(1) = '1' and player1_y_t > 0 then
                    player1_next <= player1_reg - PLAYER_DELTA;
                else
                    player1_next <= player1_reg;
                end if ;
            else
                player1_next <= player1_reg;
            end if ;
        end process;

        -- player 2

        player2_y_t <= player2_reg;

        process(player2_reg, player2_y_t, refr_clk)
        begin
            if refr_clk = '1' then
                
                if player2_btn(0) = '1' and player2_y_t + PLAYER_HEIGHT < MAX_Y then
                    player2_next <= player2_reg + PLAYER_DELTA;
                elsif player2_btn(1) = '1' and player2_y_t > 0 then
                    player2_next <= player2_reg - PLAYER_DELTA;
                else
                    player2_next <= player2_reg;
                end if ;
            else
                player2_next <= player2_reg;
            end if ;
        end process;

        player2_on <= '1' when (pix_x > player2_x_l) and (pix_x < player2_x_l + PLAYER_WIDTH) and
                               (pix_y > player2_y_t) and (pix_y < player2_y_t + PLAYER_HEIGHT) 
                               else '0';
        player2_rgb <= "001101101110";

        -- ball

        player2_score <= player2_score_next when refr_clk = '1' else player2_score;
        player1_score <= player1_score_next when refr_clk = '1' else player1_score ;

        ball_x_l <= ball_x_reg;
        ball_y_t <= ball_y_reg;

        ball_x_next <= ball_x_reg + ball_x_delta_reg when refr_clk = '1' else ball_x_reg;
        ball_y_next <= ball_y_reg + ball_y_delta_reg when refr_clk = '1' else ball_y_reg;
        

        ball_on <= '1' when (pix_x >= ball_x_l) and (pix_x < ball_x_l + BALL_SIZE) and 
                            (pix_y >= ball_y_t) and (pix_y < ball_y_t + BALL_SIZE) else '0';
        ball_rgb <= "111011100011";
        
        ball_rom_addr <= to_integer(pix_y) - ball_y_t when ball_on = '1' else 0;
        ball_rom_row <= ball_rom(ball_rom_addr);
        ball_rom_bit_addr <=  to_integer(pix_x) - ball_x_l when ball_on = '1' else 0;
        ball_rom_bit <= ball_rom_row(ball_rom_bit_addr);
        ball_bit_on <= ball_rom_bit when ball_on = '1' else '0';

        process(ball_x_l, ball_y_t, ball_x_delta_reg, ball_y_delta_reg, ball_x_reg, ball_y_reg, player1_y_t, player2_y_t, game_state)
        begin
            if game_state = play then
                
                if ball_x_delta_next = 0 or ball_y_delta_next = 0 then
                    ball_x_delta_next <= -2;
                    ball_y_delta_next <= -2;
                else
                    ball_x_delta_next <= ball_x_delta_reg ;
                    ball_y_delta_next <= ball_y_delta_reg ;  
                end if ;
                
    
                if ball_x_l + BALL_SIZE < BALL_SIZE then
                    ball_x_delta_next <= BALL_DELTA;
                elsif ball_x_l > MAX_X  then
                    ball_x_delta_next <= -BALL_DELTA;
                end if;

                -- player 1
                if ball_x_l + BALL_SIZE > player1_x_l and ball_x_l < player1_x_l + (PLAYER_WIDTH/2) 
                      and ball_y_t > player1_y_t and ball_y_t + BALL_SIZE < player1_y_t + PLAYER_HEIGHT then
                    ball_x_delta_next <= -BALL_DELTA;
                elsif ball_x_l < player1_x_l + PLAYER_WIDTH and ball_x_l + BALL_SIZE >= player1_x_l + (PLAYER_WIDTH/2) 
                    and ball_y_t > player1_y_t and ball_y_t + BALL_SIZE < player1_y_t + PLAYER_HEIGHT then
                    ball_x_delta_next <= BALL_DELTA; 
                --player 2
                elsif ball_x_l + BALL_SIZE > player2_x_l and ball_x_l < player2_x_l + (PLAYER_WIDTH/2) 
                    and ball_y_t > player2_y_t and ball_y_t + BALL_SIZE < player2_y_t + PLAYER_HEIGHT then
                  ball_x_delta_next <= -BALL_DELTA;
                elsif ball_x_l < player2_x_l + PLAYER_WIDTH and ball_x_l + BALL_SIZE >= player2_x_l + (PLAYER_WIDTH/2) 
                  and ball_y_t > player2_y_t and ball_y_t + BALL_SIZE < player2_y_t + PLAYER_HEIGHT then
                  ball_x_delta_next <= BALL_DELTA;    
                end if;
                
                if ball_y_t > MAX_Y-BALL_DELTA then
                    ball_y_delta_next <= -BALL_DELTA;
                elsif ball_y_t < BALL_DELTA then
                    ball_y_delta_next <= BALL_DELTA;
                end if ;

                --player 1
                if ball_y_t + BALL_SIZE > player1_y_t and ball_y_t < player1_y_t and ball_x_l < player1_x_l + PLAYER_WIDTH 
                    and ball_x_l + BALL_SIZE > player1_x_l then
                        
                        ball_y_delta_next <= -BALL_DELTA;

                elsif ball_y_t < player1_y_t + PLAYER_HEIGHT and ball_y_t + BALL_SIZE > player1_y_t + PLAYER_HEIGHT 
                    and ball_x_l < player1_x_l + PLAYER_WIDTH and ball_x_l + BALL_SIZE > player1_x_l then
                    
                        ball_y_delta_next <= BALL_DELTA;
                end if;

                    --player 2
                if ball_y_t + BALL_SIZE > player2_y_t and ball_y_t < player2_y_t and ball_x_l < player2_x_l + PLAYER_WIDTH 
                    and ball_x_l + BALL_SIZE > player2_x_l then

                        ball_y_delta_next <= -BALL_DELTA;
            
                elsif ball_y_t < player2_y_t + PLAYER_HEIGHT and ball_y_t + BALL_SIZE > player2_y_t + PLAYER_HEIGHT 
                    and ball_x_l < player2_x_l + PLAYER_WIDTH and ball_x_l + BALL_SIZE > player2_x_l then
                    
                        ball_y_delta_next <= BALL_DELTA;
                end if;
            else
                ball_x_delta_next <= 0;
                ball_y_delta_next <= 0;
                
                
            end if ;
        end process;

        process(player1_on, player2_on, player1_rgb, player2_rgb, video_on, ball_on, 
                ball_bit_on, ball_rgb, text_on, text_rgb) 
        begin
            if video_on = '1' then
                if player1_on = '1' then
                    red <= player1_rgb(11 downto 8);
                    green <= player1_rgb(7 downto 4);
                    blue <= player1_rgb(3 downto 0);

                elsif player2_on = '1' then
                    red <= player2_rgb(11 downto 8);
                    green <= player2_rgb(7 downto 4);
                    blue <= player2_rgb(3 downto 0);

                elsif ball_bit_on = '1' then
                    red <= ball_rgb(11 downto 8);
                    green <= ball_rgb(7 downto 4);
                    blue <= ball_rgb(3 downto 0);

                elsif text_on = '1' then
                    red <= text_rgb(11 downto 8);
                    green <= text_rgb(7 downto 4);
                    blue <= text_rgb(3 downto 0);
                else
                    red <= "0000";
                    green <= "0000";
                    blue <= "0000";
                end if ;
            else
                red <= "0000";
                green <= "0000";
                blue <= "0000";
            end if ;
        end process;


    end arch;