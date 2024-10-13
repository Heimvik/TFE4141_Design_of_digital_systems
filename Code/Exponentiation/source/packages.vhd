library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- IMPORTANT: MUST be compiled before anything it is used in!
package blakeley_utils is
    function log2(n : integer) return integer;
    function mod_mult(A, B, N : integer) return integer;
end package blakeley_utils;

package body blakeley_utils is
    function log2(n : integer) return integer is
    begin
        if n <= 1 then
            return 0;
        else
            return 1 + log2(n / 2);
        end if;
    end function log2;

    function mod_mult(A, B, N : integer) return integer is
        variable result : integer;
    begin
        result := (A * B) mod N;
        return result;
    end function;
end package body blakeley_utils;

