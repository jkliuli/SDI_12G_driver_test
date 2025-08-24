
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity sdi_timing is
generic(
    NUM_STREAMS                         : integer:= 4 
);
port(
    nRST_sdi                            : in std_logic;
    sdi_clk                             : in std_logic;

    sdi_tx_std                          : in std_logic_vector(2 downto 0); 
    disp_en                             : in  std_logic;

    words_per_active_line               : in  std_logic_vector(12 downto 0);--Total words in active part of line  pixel
    words_per_total_line                : in  std_logic_vector(12 downto 0);--Total words per line
    lines_per_frame                     : in  std_logic_vector(10 downto 0);--Total lines per frame
    line_hanc_word                      : in  std_logic_vector(11 downto 0);--hanc words per line
    --F V
    f_rise_line                         : in  std_logic_vector(10 downto 0);--defualt is 0
    f_fall_line                         : in  std_logic_vector(10 downto 0);--defualt is 0
    v_fall_line_1                       : in  std_logic_vector(10 downto 0);-- Line number when V falls for first field
    v_rise_line_1                       : in  std_logic_vector(10 downto 0);-- Line number when V rises for first field
    v_fall_line_2                       : in  std_logic_vector(10 downto 0);-- defualt is 0
    v_rise_line_2                       : in  std_logic_vector(10 downto 0);-- defualt is 0

    ref_vs                              : out  std_logic;
    ref_de                              : out  std_logic

);
end entity;

architecture behav of sdi_timing is

signal words_cnt                        : std_logic_vector(12 downto 0);
signal line_cnt                         : std_logic_vector(10 downto 0);
signal gen_de                           : std_logic;
signal gen_vs                           : std_logic;--1 is valid

signal gen_de_dly                       : std_logic_vector(3 downto 0);
                  

begin

-- process(nRST_sdi,sdi_clk)
-- begin
--     if nRST_sdi = '0' then
--         sdi_tx_std <= (others=>'0');
--     elsif rising_edge(sdi_clk) then
--         sdi_tx_std <= "011";
--     end if;
-- end process;

process(nRST_sdi,sdi_clk)
begin
    if nRST_sdi = '0' then
        gen_vs   <= '0';
        gen_de   <= '0';
        words_cnt  <= words_per_total_line-1; 
        line_cnt   <= lines_per_frame-1; 
        gen_de_dly <= (others => '0'); 
    elsif rising_edge(sdi_clk) then
        if(disp_en = '0')then
            gen_vs <= '0';
        else
            if(words_cnt = words_per_total_line-1 and line_cnt >= lines_per_frame-1)then
                gen_vs <= '1';
            else
                gen_vs <= '0';
            end if;
        end if;

        if(disp_en = '0')then
            gen_de   <= '0';
        else
            if words_cnt >= words_per_total_line-1 or (line_cnt < v_fall_line_1-1 or line_cnt > v_rise_line_1-1-1) then
                gen_de <= '0';
            elsif(words_cnt >= line_hanc_word+8+4-1 and (line_cnt >= v_fall_line_1-1 and line_cnt <= v_rise_line_1-1-1))then
                gen_de <= '1';
            end if;
        end if;

        if(disp_en = '0')then
            words_cnt  <= words_per_total_line-1; 
        else
            -- if(words_cnt >= words_per_total_line-1 and line_cnt >= 1)then
            --     words_cnt  <= (others => '0'); 
            -- elsif(words_cnt >= words_per_total_line and line_cnt <= 0)then--first one
            --     words_cnt  <= (others => '0'); 
            if(words_cnt >= words_per_total_line-1)then
                words_cnt  <= (others => '0'); 
            else
                words_cnt <= words_cnt + 1;
            end if;
        end if;

        if(disp_en = '0')then
            line_cnt  <= lines_per_frame-1; 
        else
            if(line_cnt >= lines_per_frame-1  and words_cnt >= words_per_total_line-1)then
                line_cnt  <= (others => '0'); 
            -- elsif(words_cnt >= words_per_total_line-1 and line_cnt >= 1)then
            --     line_cnt <= line_cnt + 1;
            -- elsif(words_cnt >= words_per_total_line and line_cnt <= 0)then
            --     line_cnt <= line_cnt + 1;
            elsif(words_cnt >= words_per_total_line-1)then
                line_cnt <= line_cnt + 1;
            end if;
        end if;

        gen_de_dly <= gen_de_dly(2 downto 0) & gen_de;
    end if;
end process;

ref_vs <= gen_vs;
ref_de <= gen_de_dly(0);


end behav;