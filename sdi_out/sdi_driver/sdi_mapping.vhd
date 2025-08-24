--#######################################################################
--2025/02/25 maojin
--2025/08/12 LS
--sdi_mapping
--#######################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;


entity sdi_mapping is
generic(
    NUM_STREAMS                         : integer:= 4 
);
port(
    nRST_sdi                            : in std_logic;
    sdi_clk                             : in std_logic;

    --sdi_makeframe
    tx_enable                           : out std_logic;

    vidout_din_en                       : in  std_logic;---to req data in
    vidout_data                         : out std_logic_vector(NUM_STREAMS*20-1 downto 0);--YCBCR
    vidout_data_vld                     : out std_logic;
    vidout_vs                           : out std_logic;
    vidout_word_cnt                     : in  std_logic_vector(12 downto 0);
    
    --for test 
    words_per_active_line               : in  std_logic_vector(12 downto 0);--Total words in active part of line  pixel
    

    --std
    sdi_tx_enable                       : in  std_logic;  --from mapping
    sdi_tx_std                          : in  std_logic_vector(2 downto 0); 

    --from ctrl 
    vid_rden                            : out std_logic;
    vid_q                               : in  std_logic_vector(192+3-1 downto 0);

    format_10bit_en                     : in  std_logic;
    format_bt601_en                     : in  std_logic_vector(2 downto 0); --colormetiry input defualt 0

    ref_vs                              : in  std_logic;
    ref_de                              : in  std_logic;
    
    --brightness gen    
    brightness_manual_en                : in std_logic;--this is black_en in LCD, so There is no use
    brightness_manual                   : in std_logic_vector(8-1 downto 0);
    
    param_bright_local                  : in  std_logic_vector(7 downto 0);
    param_chroma_r                      : in  std_logic_vector(7 downto 0);
    param_chroma_g                      : in  std_logic_vector(7 downto 0);
    param_chroma_b                      : in  std_logic_vector(7 downto 0)

);
end entity;

architecture behav of sdi_mapping is

signal vid_rden_wire                    : std_logic;
signal vid_rden_wire_d1                 : std_logic;
signal vid_rden_wire_d2                 : std_logic;
signal vid_q_last                       : std_logic_vector(192+3-1 downto 0);

signal pix_rden                         : std_logic;
signal pix_rden_d1                      : std_logic;
signal pix_rden_d2                      : std_logic;
signal pix_rden_d3                      : std_logic;
signal pix_rden_d4                      : std_logic;

signal pix_inc                          : std_logic_vector(2 downto 0);
signal pix_cnt                          : std_logic_vector(3 downto 0);
signal pix_cnt_d1                       : std_logic_vector(2 downto 0);
signal pix_cnt_d2                       : std_logic_vector(2 downto 0);
signal pix_cnt_d3                       : std_logic_vector(2 downto 0);

signal pix_data_8bit                    : std_logic_vector(4*24-1 downto 0);
signal pix_data_10bit                   : std_logic_vector(4*32-1 downto 0);

signal pix_vld                          : std_logic;
signal pix_vld_d1                       : std_logic;
signal pix_data                         : std_logic_vector(4*32-1 downto 0);

signal pix_xbright_vld                  : std_logic;
signal pix_dataxbright_temp             : std_logic_vector(4*19*3-1 downto 0);
signal pix_dataxbright                  : std_logic_vector(4*30-1 downto 0);

---------------------------R G B---------------------------------
signal chrXbri_r                        : std_logic_vector(8 downto 0); 
signal chrXbri_g                        : std_logic_vector(8 downto 0);
signal chrXbri_b                        : std_logic_vector(8 downto 0);
signal chrXbri_r_buf                    : std_logic_vector(18 downto 0); 
signal chrXbri_g_buf                    : std_logic_vector(18 downto 0);
signal chrXbri_b_buf                    : std_logic_vector(18 downto 0);

signal param_chroma_r_vs                : std_logic_vector(7 downto 0);
signal param_chroma_g_vs                : std_logic_vector(7 downto 0);
signal param_chroma_b_vs                : std_logic_vector(7 downto 0);

signal bright_local                     : std_logic_vector(8 downto 0);

----------------------------enable ---------------------------------
signal ce_3gb                           : std_logic:= '0';
signal sd_cnt                           : std_logic_vector(3 downto 0):= (others => '0');
signal int_sd_en                        : std_logic:= '0';

component rgb2ycbcr444 is
generic(
    SIM                                 : std_logic:= '0'
);
port(
    clkin                               : in  std_logic;
    format_bt601_en                     : in  std_logic_vector(2 downto 0); --colormetiry input 

    rgb_vld                             : in  std_logic;
    rgb_in                              : in  std_logic_vector(29 downto 0);

    ycbcr_vld                           : out std_logic;--5 clk delay
    ycbcr_out                           : out std_logic_vector(29 downto 0)
);
end component;
signal rgb_vld                          : std_logic_vector(4*1-1 downto 0);
signal rgb_in                           : std_logic_vector(4*30-1 downto 0);
signal ycbcr_vld                        : std_logic_vector(4*1-1 downto 0);
signal ycbcr_out                        : std_logic_vector(4*30-1 downto 0);

signal ycbcr444_data_last               : std_logic_vector(4*30-1 downto 0);
signal ycbcr444_data                    : std_logic_vector(4*30-1 downto 0);
signal ycbcr422_cnt                     : std_logic_vector(4*1-1 downto 0);
signal rgb_data                         : std_logic_vector(4*30-1 downto 0);

signal pix_data_d1                      : std_logic_vector(4*30-1 downto 0);
signal pix_data_d2                      : std_logic_vector(4*30-1 downto 0);
signal pix_data_d3                      : std_logic_vector(4*30-1 downto 0);
signal pix_data_d4                      : std_logic_vector(4*30-1 downto 0);
signal pix_data_d5                      : std_logic_vector(4*30-1 downto 0);

signal gen_data                         : std_logic_vector(4*20-1 downto 0);
signal gen_data_d1                      : std_logic_vector(4*20-1 downto 0);

-------------------------       vsync       ----------------------------
constant DELAY_TAP                      : integer:= 5+5+2;

signal de_delay                         : std_logic_vector(DELAY_TAP-1 downto 0);
signal hs_delay                         : std_logic_vector(DELAY_TAP-1 downto 0);
signal vs_delay                         : std_logic_vector(DELAY_TAP-1 downto 0);
signal gen_vs                           : std_logic;
signal gen_de                           : std_logic;

--test--

    type rom_type is array (0 to 31) of std_logic_vector(29 downto 0);
    signal rom        : rom_type;
    
    signal raddr      :std_logic_vector(4 downto 0) ;  
    signal raddr_inex : integer;

    signal bar_region : std_logic_vector(2 downto 0);
    
    signal y_bar      : std_logic_vector(9 downto 0);
    signal cr_bar     : std_logic_vector(9 downto 0);
    signal cb_bar     : std_logic_vector(9 downto 0);
    
    signal y_sum2     : std_logic_vector(11 downto 0);
    signal cb_sum2    : std_logic_vector(11 downto 0);
    signal cr_sum2    : std_logic_vector(11 downto 0);
    
    signal y_dly      : std_logic_vector(11 downto 0);
    signal cb_dly     : std_logic_vector(11 downto 0);
    signal cr_dly     : std_logic_vector(11 downto 0);
    
    signal y_en       : std_logic;
    signal c_en       : std_logic;

    signal bar_1 : std_logic_vector(11 downto 0);
    signal bar_2 : std_logic_vector(11 downto 0);
    signal bar_3 : std_logic_vector(11 downto 0);       
    signal bar_4 : std_logic_vector(11 downto 0);
    signal bar_5 : std_logic_vector(11 downto 0);
    signal bar_6 : std_logic_vector(11 downto 0);
    signal bar_7 : std_logic_vector(11 downto 0);

    signal ycbcr_cnt         :std_logic;
    signal ycbcr_mult_cnt    :std_logic_vector(1 downto 0);
    signal test_gen_data     :std_logic_vector(4*20-1 downto 0);
    signal test_gen_data_d1  :std_logic_vector(4*20-1 downto 0);

--test2
TYPE arr_187bit_16 is array (15 downto 0) of std_logic_vector(186 downto 0);
signal format_test                      : arr_187bit_16;

begin

process(nRST_sdi, sdi_clk)
begin
    if nRST_sdi = '0' then
        
    elsif rising_edge(sdi_clk) then

    end if;
end process;

pix_rden <= ref_de;
vid_rden <= vid_rden_wire;

process(nRST_sdi, sdi_clk)
begin
    if nRST_sdi = '0' then
        vid_rden_wire <= '0';
        pix_cnt_d1 <= (others => '0');
        pix_cnt_d2 <= (others => '0');
        pix_cnt_d3 <= (others => '0');
        pix_cnt    <= (others => '0');
        pix_inc    <= (others => '0');
	elsif rising_edge(sdi_clk) then
        if(sdi_tx_std = "011" or sdi_tx_std = "010")then--3G SDI 
            pix_inc <= conv_std_logic_vector(1,3);
        end if;

        pix_cnt_d1 <= pix_cnt(2 downto 0);
        pix_cnt_d2 <= pix_cnt_d1;
        pix_cnt_d3 <= pix_cnt_d2;

        vid_rden_wire_d1 <= vid_rden_wire;
        vid_rden_wire_d2 <= vid_rden_wire_d1;

        if vid_rden_wire_d2 = '1' then
            vid_q_last <= vid_q;
        end if;

        if format_10bit_en = '0' then
            if pix_rden = '1' and pix_cnt(2 downto 0) = 0 then
                vid_rden_wire <= '1';
            else
                vid_rden_wire <= '0';
            end if;

            if pix_rden = '1' then
                pix_cnt(3) <= '0';
                pix_cnt(2 downto 0) <= pix_cnt(2 downto 0) + pix_inc;
            else
                pix_cnt <= (others => '0');
            end if;

            case conv_integer(pix_cnt_d2) is
                when 0 =>      pix_data_8bit <= vid_q(4*24-1 downto 0*24);
                when 1 =>      pix_data_8bit <= vid_q(5*24-1 downto 1*24);
                when 2 =>      pix_data_8bit <= vid_q(6*24-1 downto 2*24);
                when 3 =>      pix_data_8bit <= vid_q(7*24-1 downto 3*24);
                when 4 =>      pix_data_8bit <= vid_q(8*24-1 downto 4*24);
                when 5 =>      pix_data_8bit <= conv_std_logic_vector(0,1*24)&vid_q(8*24-1 downto 5*24);
                when 6 =>      pix_data_8bit <= conv_std_logic_vector(0,2*24)&vid_q(8*24-1 downto 6*24);
                -- when 7 =>      pix_data_8bit <= conv_std_logic_vector(0,3*8)&vid_q(8*24-1 downto 7*24);
                when others => pix_data_8bit <= conv_std_logic_vector(0,3*24)&vid_q(8*24-1 downto 7*24);
            end case;
        else

        end if;

	end if;
end process;

--gen_YCbCr 8bit to 10bit
process(nRST_sdi, sdi_clk)
begin
    if nRST_sdi = '0' then
        pix_data <= (others => '0');
        pix_rden_d1 <= '0';
        pix_rden_d2 <= '0';
        pix_rden_d3 <= '0';
        pix_rden_d4 <= '0';
        pix_vld     <= '0';
        pix_vld_d1  <= '0';
        pix_xbright_vld <= '0';
    elsif rising_edge(sdi_clk) then
        if format_10bit_en = '0' then
            for i in 0 to 3 loop
                pix_data((i+1)*32-1 downto (i+1)*32-2) <= "00";
                for j in 0 to 2 loop
                    pix_data(i*32+(j+1)*10-1 downto i*32+j*10) <= pix_data_8bit(i*24+(j+1)*8-1 downto i*24+j*8)&"00";
                end loop;
            end loop;
        else
            pix_data <= pix_data_10bit;
        end if;

        pix_rden_d1 <= pix_rden;
        pix_rden_d2 <= pix_rden_d1;
        pix_rden_d3 <= pix_rden_d2;
        pix_rden_d4 <= pix_rden_d3;
        pix_vld     <= pix_rden_d3;
        pix_vld_d1  <= pix_vld;
        pix_xbright_vld <= pix_vld_d1;
    end if;
end process;

--gen_brightness
process(nRST_sdi, sdi_clk)
begin
    if nRST_sdi = '0' then
        bright_local       <= (others => '0');
        param_chroma_r_vs  <= (others => '0');
        param_chroma_g_vs  <= (others => '0');
        param_chroma_b_vs  <= (others => '0');
    elsif rising_edge(sdi_clk) then
        if ref_vs = '1' then 
            if brightness_manual_en = '1' then --serdes
                if brightness_manual = 0 then 
                  bright_local  <= (others => '0');
                else 
                  bright_local  <= ("0"&brightness_manual )+1;
                end if;
            else 
                if param_bright_local = 0 then--0x80
                   bright_local  <= (others => '0');
                else
                   bright_local  <= ('0'&param_bright_local) + '1';
                end if;	
            end if;

            param_chroma_r_vs <= param_chroma_r;--color
            param_chroma_g_vs <= param_chroma_g;    
            param_chroma_b_vs <= param_chroma_b;
        end if; 
    end if;
end process;

--
process(nRST_sdi, sdi_clk)
begin
    if nRST_sdi = '0' then
        chrXbri_r   <= (others => '0');
        chrXbri_g   <= (others => '0');
        chrXbri_b   <= (others => '0');
    elsif rising_edge(sdi_clk) then
        if vs_delay(DELAY_TAP-1-10 downto 0) = "10" then
            chrXbri_r <= ('0'&chrXbri_r_buf(15 downto 8)) + 1;
            chrXbri_g <= ('0'&chrXbri_g_buf(15 downto 8)) + 1;
            chrXbri_b <= ('0'&chrXbri_b_buf(15 downto 8)) + 1;
        end if; 
    end if;
end process;

process(nRST_sdi, sdi_clk)
begin
    if nRST_sdi = '0' then
        chrXbri_r_buf  <= (others => '0');
        chrXbri_g_buf  <= (others => '0');
        chrXbri_b_buf  <= (others => '0');
        pix_dataxbright_temp  <= (others => '0');
        pix_dataxbright <= (others => '0');
    elsif rising_edge(sdi_clk) then
        for i in 0 to 3 loop
            pix_dataxbright_temp(i*57+(0+1)*19-1 downto i*57+0*19) <= pix_data(i*32+(0+1)*10-1 downto i*32+0*10)*chrXbri_b;
            pix_dataxbright_temp(i*57+(1+1)*19-1 downto i*57+1*19) <= pix_data(i*32+(1+1)*10-1 downto i*32+1*10)*chrXbri_g;
            pix_dataxbright_temp(i*57+(2+1)*19-1 downto i*57+2*19) <= pix_data(i*32+(2+1)*10-1 downto i*32+2*10)*chrXbri_r;


            pix_dataxbright(i*30+(0+1)*10-1 downto i*30+0*10) <= pix_dataxbright_temp(i*57+0*19+18-1 downto i*57+0*19+8);
            pix_dataxbright(i*30+(1+1)*10-1 downto i*30+1*10) <= pix_dataxbright_temp(i*57+1*19+18-1 downto i*57+1*19+8);
            pix_dataxbright(i*30+(2+1)*10-1 downto i*30+2*10) <= pix_dataxbright_temp(i*57+2*19+18-1 downto i*57+2*19+8);

        end loop;

        chrXbri_r_buf <= ("00" & param_chroma_r_vs) * bright_local;
        chrXbri_g_buf <= ("00" & param_chroma_g_vs) * bright_local;
        chrXbri_b_buf <= ("00" & param_chroma_b_vs) * bright_local;
    end if;
end process;

--in:pix_dataxbright  
--in:pix_xbright_vld
--max support 4 pixel in
---======================   RGB to YCBCR =================---
RGB2YCBCR444_GEN: for i in 0 to 3 generate
    rgb2ycbcr444_inst: rgb2ycbcr444
    generic map(
        SIM                         => '0'
    )
    port map(
        clkin                       => sdi_clk          ,
        format_bt601_en             => format_bt601_en  ,

        rgb_vld                     => rgb_vld  (i),
        rgb_in                      => rgb_in   ((i+1)*30-1 downto i*30),

        ycbcr_vld                   => ycbcr_vld(i),
        ycbcr_out                   => ycbcr_out((i+1)*30-1 downto i*30)
    );
    rgb_vld(i) <= pix_xbright_vld;
    rgb_in((i+1)*30-1 downto i*30) <= pix_dataxbright((i+1)*30-1 downto i*30);
end generate RGB2YCBCR444_GEN;

process(nRST_sdi, sdi_clk)
begin
    if nRST_sdi = '0' then
        pix_data_d1 <= (others => '0'); 
        pix_data_d2 <= (others => '0'); 
        pix_data_d3 <= (others => '0'); 
        pix_data_d4 <= (others => '0'); 
        pix_data_d5 <= (others => '0'); 
    elsif rising_edge(sdi_clk) then
        pix_data_d1 <= pix_dataxbright;
        pix_data_d2 <= pix_data_d1;
        pix_data_d3 <= pix_data_d2;
        pix_data_d4 <= pix_data_d3;
        pix_data_d5 <= pix_data_d4;
    end if;
end process;
ycbcr444_data <= ycbcr_out;
rgb_data <= pix_data_d5;


--=====================  4 pixel data  to  4 stream  ===========================
process(nRST_sdi, sdi_clk)
begin
    if nRST_sdi = '0' then
        ycbcr422_cnt <= (others => '0');
        gen_data_d1 <= (others => '0'); 
    elsif rising_edge(sdi_clk) then

        for i in 0 to 3 loop
            if ycbcr_vld(i) = '1' then
                ycbcr422_cnt(i) <= not ycbcr422_cnt(i);
            else
                ycbcr422_cnt(i) <= '0';
            end if;
        end loop;

        ycbcr444_data_last <= ycbcr444_data;

        vs_delay(DELAY_TAP-1 downto 0) <= vs_delay(DELAY_TAP-2 downto 0)&ref_vs;
        de_delay(DELAY_TAP-1 downto 0) <= de_delay(DELAY_TAP-2 downto 0)&ref_de;

        gen_vs <= vs_delay(DELAY_TAP-1);
        gen_de <= de_delay(DELAY_TAP-1);


        if(sdi_tx_std = "011" or sdi_tx_std = "010")then--3G SDI 
            if ycbcr422_cnt(0) = '0' then 
                gen_data(0*20+1*10-1 downto 0*20+0*10) <= ycbcr444_data     (0*30+2*10-1 downto 0*30+1*10);--Cb0  
            else                          
                gen_data(0*20+1*10-1 downto 0*20+0*10) <= ycbcr444_data_last(0*30+1*10-1 downto 0*30+0*10);--Cr0
            end if;

            gen_data(4*20-1 downto 1*20) <= (others => '0');

            for i in 0 to 3 loop
                gen_data(i*20+2*10-1 downto i*20+1*10) <= ycbcr444_data(i*30+3*10-1 downto i*30+2*10);--Y;
                -- gen_data(i*20+1*10-1 downto i*20+0*10) <= (others => '0');
            end loop;
        end if;
        gen_data_d1 <= gen_data;
    end if;
end process;


--vidout_data <= gen_data_d1;
--vidout_data_vld <= gen_de;
--vidout_vs   <= gen_vs;

----------------------------------------------------------------------------------------------------------------test-------------------------------------------------------------------------------------
--=====================  test gen color bar ===================================

--===================== enable gen ==================================
--gen ce_3G
process(sdi_clk,nRST_sdi)
begin
    if nRST_sdi = '0'then 
        ce_3gb <= '0';
    else     
        ce_3gb <= not ce_3gb;
    end if;
end process;

--gen sd_en 
process(sdi_clk, nRST_sdi)
begin
    if nRST_sdi = '0' then            
        sd_cnt    <= (others => '0'); 
        int_sd_en <= '0';
    elsif rising_edge(sdi_clk) then  
        --cnt
        if(sdi_tx_std = "000") then --sd
            if sd_cnt = 11 then          
                sd_cnt <= "0001";
            else
                sd_cnt <= sd_cnt + 1;    
            end if; 
        else 
            sd_cnt <= (others => '0');   
        end if;   
        --gen int_sd_en
        if(sd_cnt = 1 or sd_cnt = 6) then
            int_sd_en <= '1';
        else
            int_sd_en <= '0';
        end if;
    end if;
end process;

--tx_enable
--process(sdi_clk,nRST_sdi)
--begin
--    if nRST_sdi = '0' then            
--        tx_enable    <= '0'; 
--    elsif rising_edge(sdi_clk) then  
--        case sdi_tx_std is
--            when "000" => tx_enable <= int_sd_en; --SD
--            when "010" => tx_enable <= ce_3gb;    --3GB
--            when others  => tx_enable <= sdi_tx_enable;
--        end case;
--    end if;
--end process;

tx_enable <= sdi_tx_enable;

--========================= gen color bar ============================
    --color rom gen
    process(sdi_clk)
    begin  
	 if rising_edge(sdi_clk) then        
        -- YCrCb SD 75% Bars
        rom(0)  <= conv_std_logic_vector(940, 10) & conv_std_logic_vector(512, 10) & conv_std_logic_vector(512, 10);  -- Bar 1
        rom(1)  <= conv_std_logic_vector(646, 10) & conv_std_logic_vector(567, 10) & conv_std_logic_vector(176, 10);  -- Bar 2
        rom(2)  <= conv_std_logic_vector(525, 10) & conv_std_logic_vector(176, 10) & conv_std_logic_vector(626, 10);  -- Bar 3
        rom(3)  <= conv_std_logic_vector(450, 10) & conv_std_logic_vector(231, 10) & conv_std_logic_vector(290, 10);  -- Bar 4
        rom(4)  <= conv_std_logic_vector(335, 10) & conv_std_logic_vector(793, 10) & conv_std_logic_vector(735, 10);  -- Bar 5
        rom(5)  <= conv_std_logic_vector(260, 10) & conv_std_logic_vector(848, 10) & conv_std_logic_vector(399, 10);  -- Bar 6
        rom(6)  <= conv_std_logic_vector(139, 10) & conv_std_logic_vector(457, 10) & conv_std_logic_vector(848, 10);  -- Bar 7
        rom(7)  <= conv_std_logic_vector(64,  10) & conv_std_logic_vector(512, 10) & conv_std_logic_vector(512, 10);  -- Bar 8

        -- YCrCb SD 100% Bars
        rom(8)  <= conv_std_logic_vector(940, 10) & conv_std_logic_vector(512, 10) & conv_std_logic_vector(512, 10);  -- Bar 1
        rom(9)  <= conv_std_logic_vector(840, 10) & conv_std_logic_vector(586, 10) & conv_std_logic_vector(64,  10);  -- Bar 2
        rom(10) <= conv_std_logic_vector(678, 10) & conv_std_logic_vector(64,  10)  & conv_std_logic_vector(664, 10);  -- Bar 3
        rom(11) <= conv_std_logic_vector(578, 10) & conv_std_logic_vector(137, 10) & conv_std_logic_vector(215, 10);  -- Bar 4
        rom(12) <= conv_std_logic_vector(426, 10) & conv_std_logic_vector(888, 10) & conv_std_logic_vector(809, 10);  -- Bar 5
        rom(13) <= conv_std_logic_vector(326, 10) & conv_std_logic_vector(960, 10) & conv_std_logic_vector(361, 10);  -- Bar 6
        rom(14) <= conv_std_logic_vector(164, 10) & conv_std_logic_vector(438, 10) & conv_std_logic_vector(960, 10);  -- Bar 7
        rom(15) <= conv_std_logic_vector(64,  10) & conv_std_logic_vector(512, 10) & conv_std_logic_vector(512, 10);  -- Bar 8

        -- YCrCb HD 75% Bars
        rom(16) <= conv_std_logic_vector(940, 10) & conv_std_logic_vector(512, 10) & conv_std_logic_vector(512, 10);  -- Bar 1
        rom(17) <= conv_std_logic_vector(674, 10) & conv_std_logic_vector(543, 10) & conv_std_logic_vector(176, 10);  -- Bar 2
        rom(18) <= conv_std_logic_vector(581, 10) & conv_std_logic_vector(176, 10) & conv_std_logic_vector(589, 10);  -- Bar 3
        rom(19) <= conv_std_logic_vector(534, 10) & conv_std_logic_vector(207, 10) & conv_std_logic_vector(253, 10);  -- Bar 4
        rom(20) <= conv_std_logic_vector(251, 10) & conv_std_logic_vector(817, 10) & conv_std_logic_vector(771, 10);  -- Bar 5
        rom(21) <= conv_std_logic_vector(204, 10) & conv_std_logic_vector(848, 10) & conv_std_logic_vector(435, 10);  -- Bar 6
        rom(22) <= conv_std_logic_vector(111, 10) & conv_std_logic_vector(481, 10) & conv_std_logic_vector(848, 10);  -- Bar 7
        rom(23) <= conv_std_logic_vector(64,  10) & conv_std_logic_vector(512, 10) & conv_std_logic_vector(512, 10);  -- Bar 8

        -- YCrCb HD 100% Bars
        rom(24) <= conv_std_logic_vector(940, 10) & conv_std_logic_vector(512, 10) & conv_std_logic_vector(512, 10);  -- Bar 1
        rom(25) <= conv_std_logic_vector(877, 10) & conv_std_logic_vector(553, 10) & conv_std_logic_vector(64,  10);  -- Bar 2
        rom(26) <= conv_std_logic_vector(754, 10) & conv_std_logic_vector(64,  10)  & conv_std_logic_vector(615, 10);  -- Bar 3
        rom(27) <= conv_std_logic_vector(691, 10) & conv_std_logic_vector(105, 10) & conv_std_logic_vector(167, 10);  -- Bar 4
        rom(28) <= conv_std_logic_vector(313, 10) & conv_std_logic_vector(919, 10) & conv_std_logic_vector(857, 10);  -- Bar 5
        rom(29) <= conv_std_logic_vector(250, 10) & conv_std_logic_vector(960, 10) & conv_std_logic_vector(409, 10);  -- Bar 6
        rom(30) <= conv_std_logic_vector(127, 10) & conv_std_logic_vector(471, 10) & conv_std_logic_vector(960, 10);  -- Bar 7
        rom(31) <= conv_std_logic_vector(64,  10) & conv_std_logic_vector(512, 10) & conv_std_logic_vector(512, 10);  -- Bar 8

        end if; 
    end process;
    

--bar gen
process(sdi_clk, nRST_sdi)
begin
    if nRST_sdi = '0' then
        bar_1 <= x"0F0";  -- 12'd240
        bar_2 <= x"1E0";  -- 12'd480
        bar_3 <= x"2D0";  -- 12'd720
        bar_4 <= x"3C0";  -- 12'd960
        bar_5 <= x"4B0";  -- 12'd1200
        bar_6 <= x"5A0";  -- 12'd1440
        bar_7 <= x"690";  -- 12'd1680
    elsif rising_edge(sdi_clk) then
        if vidout_din_en = '1' then
            bar_1 <= "00" & words_per_active_line(12 downto 3);  -- /1
            bar_2 <= "0" & words_per_active_line(12 downto 2);   -- /2
            bar_3 <= '0'&(words_per_active_line(12 downto 2) +  words_per_active_line(12 downto 3));
            bar_4 <= words_per_active_line(12 downto 1);         -- /2
            bar_5 <= words_per_active_line(12 downto 1) +  words_per_active_line(12 downto 3); 
            bar_6 <= words_per_active_line(12 downto 1) +  words_per_active_line(12 downto 2); 
            bar_7 <= words_per_active_line(12 downto 1) +  words_per_active_line(12 downto 3) + words_per_active_line(12 downto 2);
        end if;
    end if;
end process;

process(sdi_clk)
begin
    if rising_edge(sdi_clk) then
        if vidout_din_en = '1' then
            if vidout_word_cnt < bar_1 then
                bar_region <= "000";
            elsif vidout_word_cnt < bar_2 then
                bar_region <= "001";
            elsif vidout_word_cnt < bar_3 then
                bar_region <= "010";
            elsif vidout_word_cnt < bar_4 then
                bar_region <= "011";
            elsif vidout_word_cnt < bar_5 then
                bar_region <= "100";
            elsif vidout_word_cnt < bar_6 then
                bar_region <= "101";
            elsif vidout_word_cnt < bar_7 then
                bar_region <= "110";
            else
                bar_region <= "111";
            end if;
        end if;
    end if;
end process;
    
process(sdi_clk,nRST_sdi)
begin
    if nRST_sdi = '0' then
        raddr <= (others => '0');
    elsif rising_edge(sdi_clk) then
        if sdi_tx_std = "000" then --sd
            raddr <=  "01" & bar_region ;
        else 
            raddr <=  "11" & bar_region ;
        end if;
    end if;
end process;
 
--signal ver to inex 
raddr_inex <= conv_integer(raddr);

process(nRST_sdi,sdi_clk)
begin
    if nRST_sdi ='0'then
            y_bar  <= (others => '0');
            cr_bar <= (others => '0');
            cb_bar <= (others => '0');            
    elsif rising_edge(sdi_clk) then
        if vidout_din_en = '1' then
            y_bar  <= rom(raddr_inex)(29 downto 20);
            cr_bar <= rom(raddr_inex)(19 downto 10);
            cb_bar <= rom(raddr_inex)(9 downto 0);
        end if;
    end if;
end process;

--==================================== test for 4 pixel data  to  4 stream  YCbCr422=============================================

process(nRST_sdi, sdi_clk)
begin
    if nRST_sdi = '0' then
        ycbcr_cnt        <= '0';
        ycbcr_mult_cnt   <= (others => '0');
        test_gen_data    <= (others => '0'); 
        test_gen_data_d1 <= (others => '0');

    elsif rising_edge(sdi_clk) then
        --20 bit stream
        if vidout_din_en = '1' then
            ycbcr_cnt <= not ycbcr_cnt;
        else
            ycbcr_cnt <= '0';
        end if;
        
        --10 bit stream
        if vidout_din_en = '1' then
            if(ycbcr_mult_cnt = 2 ) then
                ycbcr_mult_cnt <= (others => '0');
            else
                ycbcr_mult_cnt <= ycbcr_mult_cnt + 1;
            end if;
        else
            ycbcr_mult_cnt <= (others => '0');
        end if;

        -- data mapping
        if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
            if ycbcr_cnt = '0' then 
                test_gen_data(0*20+1*10-1 downto 0*20+0*10) <= cb_bar;--Cb0  
            else                          
                test_gen_data(0*20+1*10-1 downto 0*20+0*10) <= cr_bar;--Cr0
            end if;

            test_gen_data(0*20+2*10-1 downto 0*20+1*10)     <= y_bar;--Y;

        elsif(sdi_tx_std = "000")then --SD
            if(ycbcr_mult_cnt ="00") then
                test_gen_data(0*20+1*10-1 downto 0*20+0*10) <=  cb_bar ;--cb
            elsif(ycbcr_mult_cnt = "10") then
                test_gen_data(0*20+1*10-1 downto 0*20+0*10) <=  cr_bar ;--cr
            else
                test_gen_data(0*20+1*10-1 downto 0*20+0*10) <=  y_bar ;--Y
            end if;
        elsif(sdi_tx_std = "111")then --12G
            --CbCr
            if ycbcr_cnt = '0' then 
                for i in 0 to 3 loop
                    test_gen_data(i*20+1*10-1 downto i*20+0*10) <= cb_bar;--Cb0  
                end loop;
            else 
                for i in 0 to 3 loop
                    test_gen_data(i*20+1*10-1 downto i*20+0*10) <= cr_bar;--Cb0  
                end loop;                         
            end if;
            --Y
            for i in 0 to 3 loop
                test_gen_data(i*20+2*10-1 downto i*20+1*10) <= y_bar;--Y 
            end loop;  

        elsif(sdi_tx_std = "101")then --6G
            --CbCr--std 100
--            if(ycbcr_mult_cnt ="00") then
--                for i in 0 to 3 loop
--                test_gen_data(i*10+10-1 downto i*10)       <=  cb_bar ;--cb;
--                end loop;
--            elsif(ycbcr_mult_cnt = "10") then
--                for i in 0 to 3 loop
--                test_gen_data(i*10+10-1 downto i*10)       <=  cr_bar ;--cr;
--                end loop;
--            else
--                --Y
--                for i in 0 to 3 loop
--                test_gen_data(i*10+10-1 downto i*10)       <=  y_bar ;--Y;
--                end loop;
--            end if;

            --CbCr --std 101
            if ycbcr_cnt = '0' then 
                for i in 0 to 1 loop
                    test_gen_data(i*20+1*10-1 downto i*20+0*10) <= cb_bar;--Cb0  
                end loop;
            else 
                for i in 0 to 1 loop
                    test_gen_data(i*20+1*10-1 downto i*20+0*10) <= cr_bar;--Cb0  
                end loop;                         
            end if;
            --Y
            for i in 0 to 1 loop
                test_gen_data(i*20+2*10-1 downto i*20+1*10) <= y_bar;--Y 
            end loop; 
        end if;
        test_gen_data_d1 <= test_gen_data;
    end if;
end process;

vidout_data     <= test_gen_data_d1;
vidout_data_vld <= gen_de;
vidout_vs       <= gen_vs;

end behav;

