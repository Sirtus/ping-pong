library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_receiver is
    generic(
        CLKS: integer := 5208
    );
    port(
        clk: in std_logic;
        rx: in std_logic;
        received_data: out std_logic_vector(7 downto 0);
        is_done: out std_logic
    );
end uart_receiver;

architecture arch of uart_receiver is
    type state_t is (idle, start_b, data_b, stop_b, clear);
    signal state_m: state_t := idle;
    signal counter: integer range 0 to CLKS-1;
    signal is_received: std_logic;
    signal data: std_logic_vector(7 downto 0);
    signal idx: integer range 0 to 7 := 0;

    begin 

    process(clk)
    begin 
        if rising_edge(clk) then
            case( state_m ) is
            
                when idle =>
                    if rx = '0' then
                        counter <= 0;
                        state_m <= start_b;
                    else
                        state_m <= idle;
                    end if ;
                
                when start_b =>
                    if counter = (CLKS-1)/2 then
                        counter <= 0;
                        if rx = '0' then
                            state_m <= data_b;
                            data <= (others => '0');
                            idx <= 0;
                        else 
                            state_m <= idle;
                        end if ;
                    else
                        counter <= counter + 1;
                    end if ;
                                        
                when data_b =>
                    if counter = CLKS-1 then
                        counter <= 0;
                        data(idx) <= rx;

                        if idx = 7 then
                            idx <= 0;
                            state_m <= stop_b;
                        else
                            idx <= idx + 1;
                        end if ;
                    else
                        counter <= counter + 1;
                    end if ;

                when stop_b =>
                    if counter = CLKS-1 then
                        counter <= 0;
                        is_received <= '1';
                        state_m <= clear;
                    else
                        counter <= counter + 1;
                    end if ;

                when clear =>
                    counter <= 0;
                    is_received <= '0';
                    state_m <= idle;
                    
                when others =>
                    state_m <= idle;
            
            end case ;
        end if ;
    end process;

    is_done <= is_received;
    received_data <= data;

end arch;