library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ping_pong is
    port(
        clk: in std_logic;
        v_sync, h_sync: out std_logic;
        red, blue, green: out std_logic_vector(3 downto 0);
        rx: in std_logic;
        leds: out std_logic_vector(7 downto 0)
    );
end ping_pong;

architecture arch of ping_pong is

    signal video_on: std_logic;
    signal pixel_x, pixel_y: std_logic_vector(9 downto 0);
    signal received_data: std_logic_vector(7 downto 0);
    signal is_received: std_logic;
    signal player1_btn, player2_btn: std_logic_vector(1 downto 0);
    signal space_btn: std_logic;
begin

    vga_controller: entity work.vga_controller(arch)
    port map(
        clk => clk, h_sync => h_sync, v_sync => v_sync,
        pixel_x => pixel_x, pixel_y => pixel_y,
        video_on => video_on
    );

    board_controller: entity work.board(arch)
    port map(
        clk => clk, red => red, green => green, blue => blue,
        video_on => video_on, pixel_x => pixel_x, pixel_y => pixel_y,
        player1_btn => player1_btn, player2_btn => player2_btn,
		  space_btn => space_btn
    );

    receiver: entity work.uart_receiver(arch)
    port map(
        clk => clk,
        rx => rx,
        received_data => received_data,
        is_done => is_received
    );
     
     process(is_received)
     begin
        if is_received = '1' then
            if received_data = "01000001" then
                leds(0) <= '1';
                leds(7 downto 1) <= (others => '0');
                player2_btn <= "10";
                space_btn <= '0';
            elsif received_data = "01000010" then
                leds(1) <= '1';
                leds(7 downto 2) <= (others => '0');    
                leds(0) <= '0';   
                player2_btn <= "01";
                space_btn <= '0';
            elsif received_data = "01110111" then
                leds(2) <= '1';
                leds(7 downto 3) <= (others => '0');    
                leds(1 downto 0) <= (others => '0');   
                player1_btn <= "10";
                space_btn <= '0';
            elsif received_data = "01110011" then
                leds(3) <= '1';
                leds(7 downto 4) <= (others => '0');    
                leds(2 downto 0) <= (others => '0');
                player1_btn <= "01";  
                space_btn <= '0';
            elsif received_data = "00100000" then
                space_btn <= '1';
            end if ; 
        end if ;
    end process;

end arch ; 