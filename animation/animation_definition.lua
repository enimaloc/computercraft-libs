return function(engine)
  -- Anime hand-dessinée existante, jouée quand un sub est jouable en style "pixelart"
  local subPixelArt = {
      {
    text = {
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "   #                                    ",
      "      #                                 ",
      "     #                                  ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        "
    },
    fg = {
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "   3e                                   ",
      "  efff3                                 ",
      "     3                                  ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        "
    }
  },
      {
    text = {
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                     -% ",
      "                                 @   #  ",
      "                                    % @:",
      "                                  %%    ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        "
    },
    fg = {
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                     92 ",
      "                                 1fff3  ",
      "                                fdef1 1b",
      "                                  21    ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        "
    }
  },
      {
    text = {
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "            %                           ",
      "     @    %  -%                         ",
      "     -%       ##                        ",
      "       #        #                       ",
      "      :       @                         ",
      "     -+#:  :*                           ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        "
    },
    fg = {
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "            2                           ",
      "     1    3 fa2                         ",
      "     92ffeffff33                        ",
      "       3fffffffe3                       ",
      "      beffffff1                         ",
      "     a63b  b5f                          ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        "
    }
  },
      {
    text = {
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                     %%.                ",
      "                    %  =                ",
      "                  #-   %.               ",
      "          #%%#%##%     *.               ",
      "           #            %=.. +          ",
      "             %%             .++.        ",
      "     *      % %             #= @*       ",
      "            @%           +++    +       ",
      "     *      % ++         :   % +        ",
      "           %  =  @##     - +  #%        ",
      "           %#%       #   :# +           ",
      "     + +              % +.+ #+          ",
      "            +           %. +            ",
      "          @@@ @@@@@@@@@@@@@@@@@@        ",
      "                                        ",
      "                                        "
    },
    fg = {
      "                                        ",
      "                                        ",
      "                                        ",
      "                                        ",
      "                     22c                ",
      "                    2ee7                ",
      "                  39fff3c               ",
      "          32332332effff4c               ",
      "           3 fffffffffff38cc 6          ",
      "             32fffffffffffeed66c        ",
      "     4      1 3 ffffffffffee38 15       ",
      "            02 ffffffffff666    6       ",
      "     4      3 66efffefffeb   1 6        ",
      "           3 f9  133  ffe9 6  42        ",
      "           233       3 eea4 6           ",
      "     6 6              3 7c6 36          ",
      "            6           3c 6            ",
      "          011 011110111111111111        ",
      "                                        ",
      "                                        "
    }
  },
      {
    text = {
      "                                        ",
      "                                        ",
      "               +                        ",
      "               ++ .                     ",
      "             +   +*%.                   ",
      "              % +-  %.                  ",
      "               +%    %#.      *-..-     ",
      "               #-      #-%%%%#-  %      ",
      "            #%%%               %.       ",
      "      %#                     ##.        ",
      "         %% -              :%.          ",
      "            %%%            %:+%+        ",
      "        +    %%             %.          ",
      "         #+  %      =   .+   *.         ",
      "             %      %% #%  . #.         ",
      "            %#*# %#    *++ %% %.        ",
      "            # %#             %          ",
      "        @%%#%%%%%%%%%%%%%%%%%%+%%%      ",
      "                                        ",
      "                                        "
    },
    fg = {
      "                                        ",
      "                                        ",
      "               6                        ",
      "               66 c                     ",
      "             6   642c                   ",
      "              2 69ff2c                  ",
      "               62fffe33c      5acca     ",
      "               3affffff3923323aee2      ",
      "            3332efffffffffffffe3c       ",
      "      23defffffffffffffffffff33c        ",
      "         32 9ffffffffffffffa3c          ",
      "            132 fffffffffff2b626        ",
      "        6    21effffffffffff2c          ",
      "         36  2 fffff8   d6eff4c         ",
      "             2 fff  32 32  de3c         ",
      "            2353 33    466 32 3c        ",
      "            3 23             2          ",
      "        13332333333222223333226222      ",
      "                                        ",
      "                                        "
    }
  },
      {
    text = {
      "                                        ",
      "            +    %                      ",
      "            +                           ",
      "                  =                     ",
      "                 %*#.                   ",
      "             +  %-  +-                  ",
      "            +   %  + %#.      *:..-     ",
      "               %-      %-%%%%%-  %      ",
      "            %%%%               #.       ",
      "      %#                     *#.        ",
      "         %# -              :#+ +        ",
      "        +   @%%            ++   +       ",
      "       + *+  %%             %.+         ",
      "      +   +  %      =   .    #.         ",
      "        +%   %      %% %#    #.         ",
      "         +  %%*# %%        %% #.        ",
      "            % %%                        ",
      "        @#%%%%%%%%%%%%%%%%%%%%%%%%      ",
      "                                        ",
      "                                        "
    },
    fg = {
      "                                        ",
      "            6    1                      ",
      "            6                           ",
      "                  8                     ",
      "                 243c                   ",
      "             6  29ee6a                  ",
      "            6   2ff6e33c      5adca     ",
      "               29ffffff3a22222afe2      ",
      "            2332fffffffffffffff3c       ",
      "      23deffffffffffffffffffe53c        ",
      "         33 affffffffffffffa36 6        ",
      "        6   132 ffffffffffe66   6       ",
      "       6 46  21effffffffffff2c6         ",
      "      6   6  2 fffff8   dffff3c         ",
      "        62   2 fff  31 33  ef3c         ",
      "         6  1254 23        33 3c        ",
      "            3 23                        ",
      "        03332333333333333333333333      ",
      "                                        ",
      "                                        "
    }
  },
      {
    text = {
      "                                        ",
      "                                        ",
      "                                        ",
      "              ++  .                     ",
      "               + %*%.                   ",
      "                %-  %.                  ",
      "                %    %%.      *-..-     ",
      "               %-      %=%%%%#-  %#     ",
      "            %%%#          +    %.       ",
      "      %#.                    #%.  +     ",
      "     +   %% -              :#.          ",
      "            @%%            %:           ",
      "             %%           + %.     +    ",
      "             %      -   :  + %.  +      ",
      "             %      %% %%+  +%.         ",
      "            %%** %%      #+%#+%.        ",
      "      +     % %#           @            ",
      "        @#%%%+%%%%%%%%%%%%%%%%%%%%      ",
      "                                        ",
      "                                        "
    },
    fg = {
      "                                        ",
      "                                        ",
      "                                        ",
      "              66  c                     ",
      "               6 252c                   ",
      "                29ff2c                  ",
      "                3ffff32c      4acd9     ",
      "               3afffffe39232249ee23     ",
      "            2323ffffffffff6effe3c       ",
      "      23cffefffffffffffffffff32c  6     ",
      "     6   32 afffffffffffffea3c          ",
      "            122 fffffffffff2b           ",
      "             21eefffffffff6e3c     6    ",
      "             2 fffff9   aef6f2c  6      ",
      "             2 ffe  32 336 d62c         ",
      "            1355 23      363362c        ",
      "      6     3 23           1            ",
      "        03332633333333333333333333      ",
      "                                        ",
      "                                        "
    }
  },
      {
    text = {
      "                                        ",
      "                                        ",
      "               +                        ",
      "               ++     #                 ",
      "             +   +   %#.                ",
      "              % +  %   %.               ",
      "               +  %    =%.              ",
      "        %% :#%%%%%      %.              ",
      "         %%+             %%##....       ",
      "           %                     %%.    ",
      "             %                 #%.      ",
      "            %              ##+:+        ",
      "        +  %              %.            ",
      "         #+              +%. #          ",
      "        %%    #%%%  %     %.            ",
      "        %%%          %#*++%.            ",
      "                       %%*@: #          ",
      "        @##%%%%%%%%%%%%%%%.#%%+%%%      ",
      "                                        ",
      "                                        "
    },
    fg = {
      "                                        ",
      "                                        ",
      "               6                        ",
      "               66     3                 ",
      "             6   6   23c                ",
      "              2 6  3eff3c               ",
      "               6  2efff82c              ",
      "        32eb333322ffffff3c              ",
      "         327ffffffffffffe3333dccc       ",
      "           2 effffffffffffffffeef22c    ",
      "             2 fffffffffffffffe33c      ",
      "            2 fffffffffffff336a6        ",
      "        6  2 fffffffffffef3c            ",
      "         36 effff    fffe63c 4          ",
      "        12    3332  2  fff2c            ",
      "        333          334763c            ",
      "                       3150b 3          ",
      "        133233333333333332c3336333      ",
      "                                        ",
      "                                        "
    }
  },
      {
    text = {
      "                                        ",
      "            +    +                      ",
      "                   +*                   ",
      "                  :                     ",
      "                 ##%.                   ",
      "                %-  #+                  ",
      "                %  + %#.      *:..-     ",
      "               %-      %-#%%%#-  %      ",
      "            #%%#             + %.       ",
      "      %%.                    ++.        ",
      "       + %% -              :+. +#       ",
      "       +#   @#%           +++  %        ",
      "      *   ++ %@             #.+%        ",
      "     +     + %      -   .    #.         ",
      "       @+ +  %      %% %%  + %.         ",
      "         ++ %%*# %%        ++ #.        ",
      "          + % %%                        ",
      "        @##%%%%%%%%%%%%%%%%%%%%%%%      ",
      "                                        ",
      "                                        "
    },
    fg = {
      "                                        ",
      "            6    6                      ",
      "                   65                   ",
      "                  b                     ",
      "                 343c                   ",
      "                29fe36                  ",
      "                2ef6e23c      5acc9     ",
      "               29ffffff3a32323aee2      ",
      "            3333effffffffffff6e3c       ",
      "      23cefffffffffffffffffff66c        ",
      "       6 33 9ffffffffffffffa6c 64       ",
      "       63   132 ffffffffff666  2        ",
      "      4   66 21effffffffffff3c62        ",
      "     6     6 2 fffff9   dffee3c         ",
      "       16 6  2 fff  31 33  6e2c         ",
      "         66 1244 23        66 3c        ",
      "          6 2 23                        ",
      "        13323333333333333333333333      ",
      "                                        ",
      "                                        "
    }
  },
      {
    text = {
      "                                        ",
      "                                        ",
      "                                        ",
      "              ++  .                     ",
      "               + %*%.                   ",
      "                %-  %.                  ",
      "                %    %#.      *-..-     ",
      "               %-      %-%%%%%-  %#     ",
      "            %#%#          +    %.       ",
      "      %%                     #%.  +     ",
      "     +   %% -              -%.          ",
      "            @%%            #:           ",
      "             #%           + %.     +    ",
      "             %      =   :  + %.  +      ",
      "             %      %% %#+  +%.         ",
      "            %%*# %%      %+%%+#.        ",
      "      +     % %%           %            ",
      "        @##%%+%%%%%%%%%%%%%%%%%%%%      ",
      "                                        ",
      "                                        "
    },
    fg = {
      "                                        ",
      "                                        ",
      "                                        ",
      "              66  c                     ",
      "               6 242c                   ",
      "                2afe2c                  ",
      "                2ffff23c      59cca     ",
      "               39fffffe3a22222aee33     ",
      "            3333ffffffffee6effe2c       ",
      "      23eeffffffffffffffffffe33c  6     ",
      "     6   32 9fffffffffffffea2c          ",
      "            122 fffffffffff3b           ",
      "             31eeffffffffe6e3c     6    ",
      "             3 fffff8   bee6f2c  6      ",
      "             2 fff  31 336 d62c         ",
      "            2254 23      262363c        ",
      "      6     3 23           1            ",
      "        13323633333333333333333333      ",
      "                                        ",
      "                                        "
    }
  }
  }

  -- === Génération procédurale ===

  local function blankGrid(gw, gh)
    local text, fg = {}, {}
    for y = 1, gh do
      text[y] = string.rep(" ", gw)
      fg[y] = string.rep(" ", gw)
    end
    return text, fg
  end

  local function setPixel(text, fg, x, y, char, color)
    if y < 1 or y > #text or x < 1 or x > #text[y] then return end
    text[y] = text[y]:sub(1, x - 1) .. char .. text[y]:sub(x + 1)
    fg[y] = fg[y]:sub(1, x - 1) .. color .. fg[y]:sub(x + 1)
  end

  --- Étoile qui pulse (jaune -> orange -> rouge -> orange -> jaune)
  local function subProcedural()
    local gw, gh = 11, 11
    local cx, cy = math.ceil(gw / 2), math.ceil(gh / 2)
    local colorSteps = { "4", "1", "e", "1", "4" }
    local frames = {}
    for step, color in ipairs(colorSteps) do
      local text, fg = blankGrid(gw, gh)
      local r = step <= 3 and step or (6 - step)
      for dy = -r, r do
        local dx = r - math.abs(dy)
        setPixel(text, fg, cx - dx, cy + dy, "*", color)
        setPixel(text, fg, cx + dx, cy + dy, "*", color)
      end
      table.insert(frames, { text = text, fg = fg })
    end
    return frames
  end

  --- Bannière qui s'étend depuis le centre, pour annoncer un raid
  local function raidProcedural()
    local gw, gh = 31, 5
    local cx, cy = math.ceil(gw / 2), math.ceil(gh / 2)
    local colorSteps = { "e", "1", "e", "1", "e", "1" }
    local frames = {}
    for step, color in ipairs(colorSteps) do
      local text, fg = blankGrid(gw, gh)
      local half = math.floor((step / #colorSteps) * (gw / 2))
      for dx = -half, half do
        setPixel(text, fg, cx + dx, cy, ">", color)
        setPixel(text, fg, cx + dx, cy - 1, "=", "1")
        setPixel(text, fg, cx + dx, cy + 1, "=", "1")
      end
      table.insert(frames, { text = text, fg = fg })
    end
    return frames
  end

  --- Éclats qui s'accumulent puis disparaissent, pour les cheers/bits
  local sparkColors = { "4", "9", "0" }
  local function cheerProcedural()
    local gw, gh = 21, 9
    local frames = {}
    local counts = { 3, 8, 14, 8, 3 }
    for _, count in ipairs(counts) do
      local text, fg = blankGrid(gw, gh)
      for _ = 1, count do
        local x = math.random(1, gw)
        local y = math.random(1, gh)
        local color = sparkColors[math.random(1, #sparkColors)]
        setPixel(text, fg, x, y, "*", color)
      end
      table.insert(frames, { text = text, fg = fg })
    end
    return frames
  end

  -- === Pixel-art dessinée à la main pour raid et cheer ===
  -- Volontairement modestes (peu de frames, formes simples) : à retoucher
  -- si tu veux quelque chose de plus abouti.

  local raidFlagUp = {
    text = {
      "   ###      ",
      "  #####     ",
      " |#######   ",
      " |          ",
      " |          ",
      " |          ",
    },
    fg = {
      "   111      ",
      "  11111     ",
      " c1111111   ",
      " c          ",
      " c          ",
      " c          ",
    },
  }
  local raidFlagDown = {
    text = {
      " |          ",
      " |          ",
      " |#######   ",
      "  #####     ",
      "   ###      ",
      "            ",
    },
    fg = {
      " c          ",
      " c          ",
      " c1111111   ",
      "  11111     ",
      "   111      ",
      "            ",
    },
  }
  local raidPixelArt = { raidFlagUp, raidFlagDown, raidFlagUp, raidFlagDown }

  local cheerGemSmall = {
    text = {
      "         ",
      "         ",
      "    #    ",
      "         ",
      "         ",
    },
    fg = {
      "         ",
      "         ",
      "    4    ",
      "         ",
      "         ",
    },
  }
  local cheerGemMid = {
    text = {
      "    *    ",
      "   ###   ",
      "  #####  ",
      "   ###   ",
      "    *    ",
    },
    fg = {
      "    9    ",
      "   444   ",
      "  44444  ",
      "   444   ",
      "    9    ",
    },
  }
  local cheerGemBurst = {
    text = {
      "  *   *  ",
      "   ###   ",
      "  #####  ",
      "   ###   ",
      "  *   *  ",
    },
    fg = {
      "  9   9  ",
      "   444   ",
      "  44444  ",
      "   444   ",
      "  9   9  ",
    },
  }
  local cheerPixelArt = { cheerGemSmall, cheerGemMid, cheerGemBurst, cheerGemMid, cheerGemSmall }

  -- === Style choisi pour chaque événement ===
  -- Change ces valeurs ("pixelart" ou "procedural") pour changer le rendu.
  local STYLE = {
    sub = "pixelart",
    raid = "procedural",
    cheer = "pixelart",
  }

  engine.define("sub_pixelart", subPixelArt)
  engine.define("sub_procedural", subProcedural)
  engine.define("raid_pixelart", raidPixelArt)
  engine.define("raid_procedural", raidProcedural)
  engine.define("cheer_pixelart", cheerPixelArt)
  engine.define("cheer_procedural", cheerProcedural)

  engine.define("sub", STYLE.sub == "procedural" and subProcedural or subPixelArt)
  engine.define("raid", STYLE.raid == "procedural" and raidProcedural or raidPixelArt)
  engine.define("cheer", STYLE.cheer == "procedural" and cheerProcedural or cheerPixelArt)
end
