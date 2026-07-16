Add-Type -AssemblyName System.Drawing
# 8 tiles, 16px: grass, dirt, wall, gate, bed, barn, forge, watchtower.
# Terrain is borderless + textured; buildings are pattern-drawn.
# Digit shade codes (PS hashtable keys are case-insensitive).
$ts = 16
$bmp = New-Object System.Drawing.Bitmap(160, 16)
$rand = New-Object System.Random(42)

function HexToColor($hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }

function Draw-Tile($index, $rows, $pal) {
    for ($y = 0; $y -lt $rows.Count; $y++) {
        $line = $rows[$y]
        for ($x = 0; $x -lt $line.Length; $x++) {
            $bmp.SetPixel($index * $ts + $x, $y, $pal[[string]$line[$x]])
        }
    }
}

function Fill-Terrain($index, $base, $dark, $light, $lightChance) {
    $cBase = HexToColor $base; $cDark = HexToColor $dark; $cLight = HexToColor $light
    for ($y = 0; $y -lt $ts; $y++) {
        for ($x = 0; $x -lt $ts; $x++) {
            $roll = $rand.NextDouble()
            $c = $cBase
            if ($roll -lt 0.10) { $c = $cDark }
            elseif ($roll -lt (0.10 + $lightChance)) { $c = $cLight }
            $bmp.SetPixel($index * $ts + $x, $y, $c)
        }
    }
}
Fill-Terrain 0 '#3F7A33' '#356A2B' '#4C8F3D' 0.08
Fill-Terrain 1 '#7A5C3D' '#6B4F33' '#8A6B49' 0.06

# --- 2 wall: stone bricks (W stone, 2 highlight, M mortar) ---
Draw-Tile 2 @(
"MMMMMMMMMMMMMMMM",
"WWWWWWWMWWWWWWWW",
"WWWWWWWMWWWWWWWW",
"2WWWWWWMWWWWWW2W",
"MMMMMMMMMMMMMMMM",
"WWWMWWWWWWWMWWWW",
"WWWMWWWW2WWMWWWW",
"WWWMWWWWWWWMWWWW",
"MMMMMMMMMMMMMMMM",
"WWWWWWWMWWWWWWWW",
"W2WWWWWMWWWWWWWW",
"WWWWWWWMWWWWW2WW",
"MMMMMMMMMMMMMMMM",
"WWWMWWWWWWWMWWWW",
"WWWMWWWWWWWMWWWW",
"WWWMWWW2WWWMWWWW") @{ W = HexToColor '#7E7E8A'; '2' = HexToColor '#8E8E9A'; M = HexToColor '#585864' }

# --- 3 gate: wooden planks (P plank, 3 highlight, K seam, I iron band) ---
Draw-Tile 3 @(
"KPPKPPKPPKPPKPPK",
"KPPKPPKPPKPPKPPK",
"KPPKPPKPPKPPKPPK",
"IIIIIIIIIIIIIIII",
"KPPKPPKPPKPPKPPK",
"KP3KPPKP3KPPKPPK",
"KPPKPPKPPKPPKPPK",
"KPPKPPKPPKPPKPPK",
"KPPKPPKPPKP3KPPK",
"KPPKPPKPPKPPKPPK",
"KPPKPPKPPKPPKPPK",
"IIIIIIIIIIIIIIII",
"KP3KPPKPPKPPKPPK",
"KPPKPPKPPKPPKPPK",
"KPPKPPKPPKP3KPPK",
"KPPKPPKPPKPPKPPK") @{ P = HexToColor '#8A6335'; '3' = HexToColor '#9A7345'; K = HexToColor '#6E4E28'; I = HexToColor '#4A4A52' }

# --- 4 bed: frame F, pillow W/4, blanket R/5, trim B ---
Draw-Tile 4 @(
"FFFFFFFFFFFFFFFF",
"FWWWWWWWWWWWWWWF",
"FWWWWWWWWWWWWWWF",
"FWWWW44WW44WWWWF",
"FWWWWWWWWWWWWWWF",
"FBBBBBBBBBBBBBBF",
"FBBRBBBBBBBBRBBF",
"FRRRRRRRRRRRRRRF",
"FRRRRRRRRRRRRRRF",
"FRRRRR5RRRRRRRRF",
"FRRRRRRRRRRR5RRF",
"FRRRRRRRRRRRRRRF",
"FRRRRRRR5RRRRRRF",
"FRRRRRRRRRRRRRRF",
"FRRRRRRRRRRRRRRF",
"FFFFFFFFFFFFFFFF") @{ F = HexToColor '#5C3E24'; W = HexToColor '#E8E8EE'; '4' = HexToColor '#CACAD4'; B = HexToColor '#B84848'; R = HexToColor '#A03A3A'; '5' = HexToColor '#B44C4C' }

# --- 5 barn: plank floor (P plank, 6 highlight, D seam) ---
Draw-Tile 5 @(
"DDDDDDDDDDDDDDDD",
"DPPPPPPPDPPPPPPD",
"DPPPPPPPDPPPPPPD",
"DP6PPPPPDPPP6PPD",
"DPPPPPPPDPPPPPPD",
"DDDDDDDDDDDDDDDD",
"DPPPDPPPPPPPDPPD",
"DPPPDPP6PPPPDPPD",
"DPPPDPPPPPPPDPPD",
"DPPPDPPPPPPPDPPD",
"DDDDDDDDDDDDDDDD",
"DPPPPPPPDPPPPPPD",
"DPP6PPPPDPPPP6PD",
"DPPPPPPPDPPPPPPD",
"DPPPPPPPDPPPPPPD",
"DDDDDDDDDDDDDDDD") @{ D = HexToColor '#54381F'; P = HexToColor '#7A5636'; '6' = HexToColor '#8A6646' }

# --- 6 forge: dark stone S/7, anvil A, embers E/O ---
Draw-Tile 6 @(
"SSSSSSSSSSSSSSSS",
"S7SSSSSSSSSSS7SS",
"SSSSAAAAAAASSSSS",
"SSSSSAAAAASSSSSS",
"SSSSSSAAASSSSSSS",
"SSSSSAAAAASSSSSS",
"SSSSAAAAAAASSSSS",
"SSSSSSSSSSSSSSSS",
"SSSEEESSSSEEESSS",
"SSEEOEESSEEOEESS",
"SSSEEESSSSEEESSS",
"SSSSSSSSSSSSSSSS",
"S7SSSSSSSSSSSS7S",
"SSSSSSEEOSSSSSSS",
"SSSSSSSESSSSSSSS",
"SSSSSSSSSSSSSSSS") @{ S = HexToColor '#443E3C'; '7' = HexToColor '#524B48'; A = HexToColor '#2A2624'; E = HexToColor '#D97B29'; O = HexToColor '#F2A649' }

# --- 7 watchtower: light brick T/8, mortar M, crenellations C, sky 9 ---
Draw-Tile 7 @(
"CC99CC99CC99CC99",
"CC99CC99CC99CC99",
"TTTTTTTTTTTTTTTT",
"TTTMTTTTTTTMTTTT",
"MMMMMMMMMMMMMMMM",
"TTTTTTTMTTTTTTTT",
"TT8TTTTMTTTT8TTT",
"MMMMMMMMMMMMMMMM",
"TTTMTTTTTTTMTTTT",
"TTTMTTTTT8TMTTTT",
"MMMMMMMMMMMMMMMM",
"TTTTTTTMTTTTTTTT",
"TTTTTTTMTTTTTTTT",
"MMMMMMMMMMMMMMMM",
"TTTMTTTTTTTMTTTT",
"TTTMTTTTTTTMTTTT") @{ C = HexToColor '#C4C4CC'; T = HexToColor '#9E9EA8'; '8' = HexToColor '#AEAEB8'; M = HexToColor '#74747E'; '9' = HexToColor '#8E8E96' }

# --- 8 stove: dark stone, pot P/9, fire E/O ---
Draw-Tile 8 @(
"SSSSSSSSSSSSSSSS",
"S7SSSSSSSSSSS7SS",
"SSSSSSSSSSSSSSSS",
"SSSSPPPPPPPSSSSS",
"SSSP9PPPPPP9SSSS",
"SSSPPPPPPPPPSSSS",
"SSSPPPPPPPPPSSSS",
"SSSSPPPPPPPSSSSS",
"SSSSSSSSSSSSSSSS",
"SSSSEEEEEEESSSSS",
"SSSEEOEEOEEESSSS",
"SSSSEEEEEEESSSSS",
"SSSSSSSSSSSSSSSS",
"S7SSSSSSSSSSSS7S",
"SSSSSSSSSSSSSSSS",
"SSSSSSSSSSSSSSSS") @{ S = HexToColor '#443E3C'; '7' = HexToColor '#524B48'; P = HexToColor '#6E6E7A'; '9' = HexToColor '#8A8A96'; E = HexToColor '#D97B29'; O = HexToColor '#F2A649' }

# --- 9 door: light planks, handle, no iron (interior version of the gate) ---
Draw-Tile 9 @(
"KDDDKDDDKDDDKDDK",
"KDDDKDDDKDDDKDDK",
"KDDDKDDDKDDDKDDK",
"KDDDKDDDKDDDKDDK",
"KDD3KDDDKDD3KDDK",
"KDDDKDDDKDDDKDDK",
"KDDDKDDDKDDDKDDK",
"KDDDKDDDKHHDKDDK",
"KDDDKDDDKHHDKDDK",
"KDDDKDDDKDDDKDDK",
"KDD3KDDDKDDDKDDK",
"KDDDKDDDKDDDKDDK",
"KDDDKDDDKDD3KDDK",
"KDDDKDDDKDDDKDDK",
"KDDDKDDDKDDDKDDK",
"KDDDKDDDKDDDKDDK") @{ D = HexToColor '#A07A48'; '3' = HexToColor '#B08A58'; K = HexToColor '#7E5E38'; H = HexToColor '#4A4A52' }

$bmp.Save('C:\colony-sim\assets\tiles.png', [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output "saved 10-tile atlas v4"
