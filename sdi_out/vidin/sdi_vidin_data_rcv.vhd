----------------------------------------------------------------------------------
-- Create Date: 9:35 2022/10/9
--
-- Engineer: lijb
--
-- Additional Comments:
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sdi_vidin_data_rcv is
generic(
    SIM                         : std_logic:= '0'
);
port(
    nRST                        : in  std_logic;
    sysclk                      : in  std_logic;
    time_ms_en                  : in  std_logic;
    
    vidin_start                 : in  std_logic;
    vidin_end                   : in  std_logic;
    vidin_wren                  : in  std_logic;
    vidin_data                  : in  std_logic_vector(191 downto 0);

    vidin_black_en              : in  std_logic;
    format_10bit_src            : out  std_logic;
    format_10bit_vsync          : out  std_logic_vector(1 downto 0);
 
    vid_wren                    : out std_logic;
    vid_data                    : out std_logic_vector(192+3-1 downto 0)
);
end entity;

architecture behav of sdi_vidin_data_rcv is

signal vidin_start_d1,vidin_start_d2 : std_logic;
signal vidin_end_d1  ,vidin_end_d2   : std_logic;
signal vidin_wren_d1 ,vidin_wren_d2  : std_logic;
signal vidin_data_d1 ,vidin_data_d2  : std_logic_vector(191 downto 0);

signal frame_data_en,frame_data_en_d1,frame_data_en_d2,frame_data_en_d3 : std_logic;

attribute mark_debug : string;
attribute mark_debug of format_10bit_vsync       : signal is "true";

begin


process(sysclk)
begin
    if rising_edge(sysclk) then
        vidin_start_d1 <= vidin_start   ; vidin_end_d1 <= vidin_end   ; vidin_wren_d1 <= vidin_wren   ; vidin_data_d1 <= vidin_data   ;
        vidin_start_d2 <= vidin_start_d1; vidin_end_d2 <= vidin_end_d1; vidin_wren_d2 <= vidin_wren_d1; vidin_data_d2 <= vidin_data_d1;
    end if;
end process;

process(nRST,sysclk)
begin
    if nRST = '0' then
        frame_data_en <= '0';
        format_10bit_src          <= '0';
        format_10bit_vsync        <= (others=>'0');
  
    elsif rising_edge(sysclk) then
        if vidin_start = '1' and vidin_wren = '1' and vidin_data(23 downto 0) = x"0055fb" then
            frame_data_en <= '1';
            format_10bit_src     <= vidin_data(82);   --'0': use 2c, '1': use serdes 
            format_10bit_vsync   <= vidin_data(81 downto 80);
  
        elsif vidin_end = '1' and vidin_wren = '1' then
            frame_data_en <= '0';
        end if;
        frame_data_en_d1 <= frame_data_en;
        frame_data_en_d2 <= frame_data_en_d1;
        frame_data_en_d3 <= frame_data_en_d2;
    end if;
end process;

process(nRST,sysclk)
begin
    if nRST = '0' then
        vid_wren <= '0';
        vid_data <= (others => '0');
    elsif rising_edge(sysclk) then
        if frame_data_en_d3 = '0' and frame_data_en_d2 = '1' then vid_data(194) <= '1';
        else                                                      vid_data(194) <= '0';
        end if;

        if frame_data_en_d1 = '1' and frame_data_en = '0' then    vid_data(193) <= '1';
        else                                                      vid_data(193) <= '0';
        end if;

        if frame_data_en_d2 = '1' and vidin_wren_d2 = '1' and vidin_start_d2 = '0' and vidin_end_d2 = '0' then
            vid_wren <= '1';
            vid_data(192) <= '1';
        else
            vid_wren <= '0';
            vid_data(192) <= '0';
        end if;
        
        if vidin_black_en = '1' then
            vid_data(191 downto 0) <= (others => '0');
        else
            vid_data(191 downto 0) <= vidin_data_d2;
        end if;
    end if;
end process;



end behav;