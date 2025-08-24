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

entity rgb2ycbcr444 is
generic(
    SIM                         : std_logic:= '0'
);
port(
    clkin                       : in  std_logic;
    format_bt601_en             : in  std_logic_vector(2 downto 0); --colormetiry input 

    rgb_vld                     : in  std_logic;
    rgb_in                      : in  std_logic_vector(29 downto 0);--r/g/b

    ycbcr_vld                   : out std_logic;
    ycbcr_out                   : out std_logic_vector(29 downto 0) --y/cb/cr
);
end entity;

architecture behav of rgb2ycbcr444 is

signal r                        : std_logic_vector(9 downto 0);
signal g                        : std_logic_vector(9 downto 0);
signal b                        : std_logic_vector(9 downto 0);

signal temp_y                   : std_logic_vector(29 downto 0);
signal temp_cb                  : std_logic_vector(29 downto 0);
signal temp_cr                  : std_logic_vector(29 downto 0);


signal temp_vld                 : std_logic;



-- //https://it.sohu.com/a/528947031_121124366
----****************************************************************----
-- ITU-R BT.601
-- {Y }   { 16}   { 0.257  0.504  0.098} {R}    |--   RGB#[ 0,255]
-- {Cb} = {128} + {-0.148 -0.291  0.439}*{G}, --|--     Y#[16,235]
-- {Cr}   {128}   { 0.439 -0.368 -0.071} {B}    |-- Cb/Cr#[16,240]
constant BT601_COE11 : integer:= 263;--0.257*1024 = 263.168
constant BT601_COE21 : integer:= 151;--0.148*1024 = 151.552
constant BT601_COE31 : integer:= 449;--0.439*1024 = 449.536

constant BT601_COE12 : integer:= 516;--0.504*1024 = 516.096
constant BT601_COE22 : integer:= 298;--0.291*1024 = 297.984
constant BT601_COE32 : integer:= 377;--0.368*1024 = 376.832

constant BT601_COE13 : integer:= 100;--0.098*1024 = 100.352
constant BT601_COE23 : integer:= 449;--0.439*1024 = 449.536
constant BT601_COE33 : integer:=  73;--0.071*1024 =  72.704

constant BT601_CONST1 : integer:=  16*4*1024;
constant BT601_CONST2 : integer:= 128*4*1024;
constant BT601_CONST3 : integer:= 128*4*1024;
----****************************************************************----

----****************************************************************----
-- ITU-R BT.709
-- {Y }   { 16}   { 0.183  0.614  0.062} {R}    |--   RGB#[ 0,255]
-- {Cb} = {128} + {-0.101 -0.339  0.439}*{G}, --|--     Y#[16,235]
-- {Cr}   {128}   { 0.439 -0.339 -0.040} {B}    |-- Cb/Cr#[16,240]
constant BT709_COE11 : integer:= 187;--0.183*1024 = 187.392
constant BT709_COE21 : integer:= 103;--0.101*1024 = 103.424
constant BT709_COE31 : integer:= 449;--0.439*1024 = 449.536

constant BT709_COE12 : integer:= 629;--0.614*1024 = 628.736
constant BT709_COE22 : integer:= 347;--0.339*1024 = 347.136
constant BT709_COE32 : integer:= 347;--0.339*1024 = 347.136

constant BT709_COE13 : integer:=  63;--0.062*1024 =  63.488
constant BT709_COE23 : integer:= 449;--0.439*1024 = 449.536
constant BT709_COE33 : integer:=  41;--0.040*1024 =  40.96

constant BT709_CONST1 : integer:=  16*4*1024;
constant BT709_CONST2 : integer:= 128*4*1024;
constant BT709_CONST3 : integer:= 128*4*1024;
----****************************************************************----


----****************************************************************----
-- ITU-R BT.2020
-- {Y }   { 16}   { 0.2256  0.5823  0.05093} {R}    |--   RGB#[ 0,255]
-- {Cb} = {128} + {-0.1222 -0.3154  0.4375}*{G}, --|--     Y#[16,235]
-- {Cr}   {128}   { 0.4375 -0.4023 -0.0352} {B}    |-- Cb/Cr#[16,240]
constant BT2020_COE11 : integer:= 231;--0.2256*1024  
constant BT2020_COE21 : integer:= 125;--0.1222*1024  
constant BT2020_COE31 : integer:= 448;--0.4375*1024  

constant BT2020_COE12 : integer:= 596;--0.5823*1024  
constant BT2020_COE22 : integer:= 323;--0.3154*1024  
constant BT2020_COE32 : integer:= 412;--0.4023*1024  

constant BT2020_COE13 : integer:=  52;--0.05093*1024 
constant BT2020_COE23 : integer:= 448;--0.4375*1024  
constant BT2020_COE33 : integer:=  36;--0.0352*1024  

constant BT2020_CONST1 : integer:=  16*4*1024;
constant BT2020_CONST2 : integer:= 128*4*1024;
constant BT2020_CONST3 : integer:= 128*4*1024;


----****************************************************************----
-- full range or pc range
-- {Y }   {  0}   { 0.299  0.587  0.114} {R}    |--    RGB#[0,255]
-- {Cb} = {128} + {-0.169 -0.331  0.500}*{G}, --|
-- {Cr}   {128}   { 0.500 -0.419 -0.081} {B}    |-- YCb/Cr#[0,255]
constant FULL_RANGE_COE11 : integer:= 306;--0.299*1024 = 306.176
constant FULL_RANGE_COE21 : integer:= 173;--0.169*1024 = 173.056
constant FULL_RANGE_COE31 : integer:= 512;--0.500*1024 = 512

constant FULL_RANGE_COE12 : integer:= 601;--0.587*1024 = 601.088
constant FULL_RANGE_COE22 : integer:= 339;--0.331*1024 = 338.944
constant FULL_RANGE_COE32 : integer:= 429;--0.419*1024 = 429.056

constant FULL_RANGE_COE13 : integer:= 117;--0.114*1024 = 116.736
constant FULL_RANGE_COE23 : integer:= 512;--0.500*1024 = 512
constant FULL_RANGE_COE33 : integer:=  83;--0.081*1024 =  82.944

constant FULL_RANGE_CONST1 : integer:=   0*4*1024;
constant FULL_RANGE_CONST2 : integer:= 128*4*1024;
constant FULL_RANGE_CONST3 : integer:= 128*4*1024;
----****************************************************************----
signal coe11                    : std_logic_vector(19 downto 0);
signal coe21                    : std_logic_vector(19 downto 0);
signal coe31                    : std_logic_vector(19 downto 0);
signal coe12                    : std_logic_vector(19 downto 0);
signal coe22                    : std_logic_vector(19 downto 0);
signal coe32                    : std_logic_vector(19 downto 0);
signal coe13                    : std_logic_vector(19 downto 0);
signal coe23                    : std_logic_vector(19 downto 0);
signal coe33                    : std_logic_vector(19 downto 0);

signal const1                   : std_logic_vector(29 downto 0);
signal const2                   : std_logic_vector(29 downto 0);
signal const3                   : std_logic_vector(29 downto 0);

signal result11                 : std_logic_vector(29 downto 0);
signal result21                 : std_logic_vector(29 downto 0);
signal result31                 : std_logic_vector(29 downto 0);
signal result12                 : std_logic_vector(29 downto 0);
signal result22                 : std_logic_vector(29 downto 0);
signal result32                 : std_logic_vector(29 downto 0);
signal result13                 : std_logic_vector(29 downto 0);
signal result23                 : std_logic_vector(29 downto 0);
signal result33                 : std_logic_vector(29 downto 0);

signal result1x                 : std_logic_vector(29 downto 0);
signal result2x                 : std_logic_vector(29 downto 0);
signal result3x                 : std_logic_vector(29 downto 0);

signal rgb_vld_d1               : std_logic;
signal rgb_vld_d2               : std_logic;
signal rgb_vld_d3               : std_logic;




begin


process(clkin)
begin
    if rising_edge(clkin) then

        r <= rgb_in(3*10-1 downto 2*10);
        g <= rgb_in(2*10-1 downto 1*10);
        b <= rgb_in(1*10-1 downto 0*10);
        rgb_vld_d1 <= rgb_vld;

        -- if format_bt601_en = '1' then
        if format_bt601_en = 0 then
            coe11 <= conv_std_logic_vector(BT601_COE11,20); coe12 <= conv_std_logic_vector(BT601_COE12,20); coe13 <= conv_std_logic_vector(BT601_COE13,20); const1 <= conv_std_logic_vector(BT601_CONST1,30);
            coe21 <= conv_std_logic_vector(BT601_COE21,20); coe22 <= conv_std_logic_vector(BT601_COE22,20); coe23 <= conv_std_logic_vector(BT601_COE23,20); const2 <= conv_std_logic_vector(BT601_CONST2,30);
            coe31 <= conv_std_logic_vector(BT601_COE31,20); coe32 <= conv_std_logic_vector(BT601_COE32,20); coe33 <= conv_std_logic_vector(BT601_COE33,20); const3 <= conv_std_logic_vector(BT601_CONST3,30);
        elsif format_bt601_en = 1 then
            coe11 <= conv_std_logic_vector(BT709_COE11,20); coe12 <= conv_std_logic_vector(BT709_COE12,20); coe13 <= conv_std_logic_vector(BT709_COE13,20); const1 <= conv_std_logic_vector(BT709_CONST1,30);
            coe21 <= conv_std_logic_vector(BT709_COE21,20); coe22 <= conv_std_logic_vector(BT709_COE22,20); coe23 <= conv_std_logic_vector(BT709_COE23,20); const2 <= conv_std_logic_vector(BT709_CONST2,30);
            coe31 <= conv_std_logic_vector(BT709_COE31,20); coe32 <= conv_std_logic_vector(BT709_COE32,20); coe33 <= conv_std_logic_vector(BT709_COE33,20); const3 <= conv_std_logic_vector(BT709_CONST3,30);
            -- coe11 <= conv_std_logic_vector(FULL_RANGE_COE11,20); coe12 <= conv_std_logic_vector(FULL_RANGE_COE12,20); coe13 <= conv_std_logic_vector(FULL_RANGE_COE13,20); const1 <= conv_std_logic_vector(FULL_RANGE_CONST1,30);
            -- coe21 <= conv_std_logic_vector(FULL_RANGE_COE21,20); coe22 <= conv_std_logic_vector(FULL_RANGE_COE22,20); coe23 <= conv_std_logic_vector(FULL_RANGE_COE23,20); const2 <= conv_std_logic_vector(FULL_RANGE_CONST2,30);
            -- coe31 <= conv_std_logic_vector(FULL_RANGE_COE31,20); coe32 <= conv_std_logic_vector(FULL_RANGE_COE32,20); coe33 <= conv_std_logic_vector(FULL_RANGE_COE33,20); const3 <= conv_std_logic_vector(FULL_RANGE_CONST3,30);
        else --bt.2020 
            coe11 <= conv_std_logic_vector(BT2020_COE11,20); coe12 <= conv_std_logic_vector(BT2020_COE12,20); coe13 <= conv_std_logic_vector(BT2020_COE13,20); const1 <= conv_std_logic_vector(BT2020_CONST1,30);
            coe21 <= conv_std_logic_vector(BT2020_COE21,20); coe22 <= conv_std_logic_vector(BT2020_COE22,20); coe23 <= conv_std_logic_vector(BT2020_COE23,20); const2 <= conv_std_logic_vector(BT2020_CONST2,30);
            coe31 <= conv_std_logic_vector(BT2020_COE31,20); coe32 <= conv_std_logic_vector(BT2020_COE32,20); coe33 <= conv_std_logic_vector(BT2020_COE33,20); const3 <= conv_std_logic_vector(BT2020_CONST3,30);
          
        
        end if;
        result11 <= coe11*r; result12 <= coe12*g; result13 <= coe13*b;
        result21 <= coe21*r; result22 <= coe22*g; result23 <= coe23*b;
        result31 <= coe31*r; result32 <= coe32*g; result33 <= coe33*b;
        
        
        rgb_vld_d2 <= rgb_vld_d1;

        result1x <= 0 + result11 + result12 + result13;
        result2x <= 0 - result21 - result22 + result23;
        result3x <= 0 + result31 - result32 - result33;
        rgb_vld_d3 <= rgb_vld_d2;

        temp_y  <= result1x + const1;
        temp_cb <= result2x + const2;
        temp_cr <= result3x + const3;
        temp_vld <= rgb_vld_d3;

        if temp_y (29 downto 10+10) = 0 then ycbcr_out(29 downto 20) <= temp_y  (10+10-1 downto 10);
        else                                 ycbcr_out(29 downto 20) <= (others => '1');
        end if;

        if temp_cb(29 downto 10+10) = 0 then ycbcr_out(19 downto 10) <= temp_cb (10+10-1 downto 10);
        else                                 ycbcr_out(19 downto 10) <= (others => '1');
        end if;

        if temp_cr(29 downto 10+10) = 0 then ycbcr_out(9 downto 0) <= temp_cr (10+10-1 downto 10);
        else                                 ycbcr_out(9 downto 0) <= (others => '1');
        end if;

        ycbcr_vld <= temp_vld;



    end if;
end process;

end behav;