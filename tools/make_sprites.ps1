Add-Type -AssemblyName System.Drawing
# 14 sprites, 16x16 each, one row: 224x16, transparent background.
# Figures/items drawn in light grays so scenes tint them via modulate;
# trees/food/graves drawn in real colors (modulate stays white).
# Shade codes are digits (PS hashtable keys are case-insensitive).
$bmp = New-Object System.Drawing.Bitmap(400, 16, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

function HexToColor($hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }

function Draw-Sprite($index, $rows, $pal) {
    for ($y = 0; $y -lt $rows.Count; $y++) {
        $line = $rows[$y]
        for ($x = 0; $x -lt $line.Length; $x++) {
            $ch = $line[$x]
            if ($ch -ne '.') { $bmp.SetPixel($index * 16 + $x, $y, $pal[[string]$ch]) }
        }
    }
}

# 0: person (light grays -> tinted per role)
Draw-Sprite 0 @(
"................",
"......HHHH......",
".....HHHHHH.....",
".....HHHHHH.....",
"......HHHH......",
"....TTTTTTTT....",
"...TTTTTTTTTT...",
"...TT.TTTT.TT...",
"...TT.TTTT.TT...",
"....TTTTTTTT....",
"....BBBBBBBB....",
".....LL..LL.....",
".....LL..LL.....",
".....LL..LL.....",
"....LLL..LLL....",
"................") @{ H = HexToColor '#FFFFFF'; T = HexToColor '#D2D2D2'; B = HexToColor '#8E8E8E'; L = HexToColor '#ACACAC' }

# 1: tree (real colors)
Draw-Sprite 1 @(
"................",
"......GGGG......",
"....GGGGGGGG....",
"...GGGGGGGGGG...",
"...GGG2GGGGGG...",
"..GGGGGGGG2GGG..",
"..G2GGGGGGGGGG..",
"..GGGGG2GGGGGG..",
"...GGGGGGGG2G...",
"....GG2GGGGG....",
"......GGGG......",
".......KK.......",
".......KK.......",
".......KK.......",
"......KKKK......",
"................") @{ G = HexToColor '#2F7A38'; '2' = HexToColor '#245D2B'; K = HexToColor '#5C3A22' }

# 2: rock / ore node (light -> tinted by node color)
Draw-Sprite 2 @(
"................",
"................",
".....RRRRR......",
"....RRRRRRRR....",
"...RRRR3RRRRR...",
"..RR3RRRRRRRR...",
"..RRRRRRR3RRRR..",
".RRRRRRRRRRRRR..",
".RR3RRRRRRR3RR..",
".RRRRRR3RRRRRR..",
".RRRRRRRRRRRRR..",
"..RRRRRRRRRRR...",
"...RRRRRRRRR....",
"................",
"................",
"................") @{ R = HexToColor '#E4E4E4'; '3' = HexToColor '#B8B8B8' }

# 3: plant / crop (light -> tinted by crop color)
Draw-Sprite 3 @(
"................",
"................",
"......P..P......",
".....PPPPPP.....",
"....PPPPPPPP....",
"...PPP4PPPPP....",
"...PPPPPP4PP....",
"....PPPPPPPP....",
".....PPPPPP.....",
"......P4PP......",
".......PP.......",
".......55.......",
".......55.......",
"................",
"................",
"................") @{ P = HexToColor '#E8E8E8'; '4' = HexToColor '#C2C2C2'; '5' = HexToColor '#A8A090' }

# 4: log (light -> tinted)
Draw-Sprite 4 @(
"................",
"................",
"................",
"................",
"................",
"....55555555....",
"...LLLLLLLLL5...",
"...LLLLLLLLL5...",
"...LLLLLLLLL5...",
"....55555555....",
"................",
"................",
"................",
"................",
"................",
"................") @{ L = HexToColor '#ECECEC'; '5' = HexToColor '#BEBEBE' }

# 5: chunk (stone/ore item)
Draw-Sprite 5 @(
"................",
"................",
"................",
"................",
"................",
"......CCC.......",
".....CCCCCC.....",
"....CC6CCCCC....",
"....CCCCC6CC....",
".....CCCCCC.....",
"......CCCC......",
"................",
"................",
"................",
"................",
"................") @{ C = HexToColor '#E4E4E4'; '6' = HexToColor '#B0B0B0' }

# 6: ingot
Draw-Sprite 6 @(
"................",
"................",
"................",
"................",
"................",
"................",
".....IIIIIII....",
"....IIIIIIII7...",
"...IIIIIIIII7...",
"...7777777777...",
"................",
"................",
"................",
"................",
"................",
"................") @{ I = HexToColor '#F0F0F0'; '7' = HexToColor '#B8B8B8' }

# 7: sword (diagonal blade + hilt)
Draw-Sprite 7 @(
"................",
"...........SS...",
"..........SSS...",
".........SSS....",
"........SSS.....",
".......SSS......",
"......SSS.......",
".....SSS........",
"....SSS.........",
"...2SS2.........",
"..2222..........",
"..22.2..........",
".22.............",
"................",
"................",
"................") @{ S = HexToColor '#F2F2F2'; '2' = HexToColor '#A89468' }

# 8: bow (arc + string)
Draw-Sprite 8 @(
"................",
".....BB.........",
"....B..9........",
"...B....9.......",
"...B.....9......",
"..B.......9.....",
"..B.......9.....",
"..B.......9.....",
"..B.......9.....",
"..B.......9.....",
"...B.....9......",
"...B....9.......",
"....B..9........",
".....BB.........",
"................",
"................") @{ B = HexToColor '#E0D0B0'; '9' = HexToColor '#F8F8F8' }

# 9: arrow
Draw-Sprite 9 @(
"................",
"................",
"...........AA...",
"..........AAA...",
".........AAA....",
"........88......",
".......88.......",
"......88........",
".....88.........",
"....88..........",
"...99...........",
"..99............",
"................",
"................",
"................",
"................") @{ A = HexToColor '#F0F0F0'; '8' = HexToColor '#C8B896'; '9' = HexToColor '#E8E8E8' }

# 10: herb sprig
Draw-Sprite 10 @(
"................",
"................",
"................",
"......h..h......",
".....hh..hh.....",
"......h..h......",
".....hhhhhh.....",
"......hhhh......",
".......hh.......",
".......hh.......",
"................",
"................",
"................",
"................",
"................",
"................") @{ h = HexToColor '#E2F0E2' }

# 11: food (real colors: loaf + leaf)
Draw-Sprite 11 @(
"................",
"................",
"................",
"................",
"......22........",
".....FFFFFF.....",
"....FFFFFFFF....",
"...FF9FFF9FF....",
"...FFFFFFFFF....",
"....FFFFFFF.....",
"................",
"................",
"................",
"................",
"................",
"................") @{ F = HexToColor '#C7484F'; '9' = HexToColor '#E2707A'; '2' = HexToColor '#3E7A38' }

# 12: gem / relic (light -> tinted per relic)
Draw-Sprite 12 @(
"................",
"................",
"................",
".......GG.......",
"......GGGG......",
".....GG2GGG.....",
"....GGGGG2GG....",
"....G2GGGGGG....",
".....GGGGGG.....",
"......GGGG......",
".......GG.......",
"................",
"................",
"................",
"................",
"................") @{ G = HexToColor '#F4F4F4'; '2' = HexToColor '#FFFFFF' }

# 13: grave (real colors)
Draw-Sprite 13 @(
"................",
"................",
"................",
"......5555......",
".....555555.....",
".....55..55.....",
".....555555.....",
".....55..55.....",
".....555555.....",
".....555555.....",
"....mmmmmmmm....",
"...mmmmmmmmmm...",
"..mmmmmmmmmmmm..",
"................",
"................",
"................") @{ '5' = HexToColor '#9A9AA4'; m = HexToColor '#4E4034' }

# 14: person walk frame (legs apart, arms swing)
Draw-Sprite 14 @(
"................",
"......HHHH......",
".....HHHHHH.....",
".....HHHHHH.....",
"......HHHH......",
"....TTTTTTTT....",
"...TTTTTTTTTT...",
"..TT.TTTTTT.....",
"..TT.TTTT.TT....",
"....TTTTTT.TT...",
"....BBBBBBBB....",
"....LL....LL....",
"...LL......LL...",
"...LL......LL...",
"..LLL......LLL..",
"................") @{ H = HexToColor '#FFFFFF'; T = HexToColor '#D2D2D2'; B = HexToColor '#8E8E8E'; L = HexToColor '#ACACAC' }

# 15: hooded bandit (distinct silhouette: pointed hood, cloak)
Draw-Sprite 15 @(
"................",
".......HH.......",
"......HHHH......",
".....HHHHHH.....",
".....HHHHHH.....",
"....THHHHHHT....",
"...TTTTTTTTTT...",
"...TTTTTTTTTT...",
"...TTTTTTTTTT...",
"...TTTTTTTTTT...",
"....TTTTTTTT....",
"....TTTTTTTT....",
".....LL..LL.....",
".....LL..LL.....",
"....LLL..LLL....",
"................") @{ H = HexToColor '#E8E8E8'; T = HexToColor '#C4C4C4'; L = HexToColor '#9A9A9A' }

# 16: tree variant (tall pine)
Draw-Sprite 16 @(
".......GG.......",
"......GGGG......",
".....GGGGGG.....",
"......GGGG......",
".....GGGGGG.....",
"....GGG2GGGG....",
".....GGGGGG.....",
"....GGGGGGGG....",
"...GGG2GGGGGG...",
"....GGGGGGGG....",
"...GGGGGG2GGG...",
"..GGGGGGGGGGGG..",
".......KK.......",
".......KK.......",
"......KKKK......",
"................") @{ G = HexToColor '#2A6B33'; '2' = HexToColor '#1F5226'; K = HexToColor '#5C3A22' }

# 17: rock variant (jagged)
Draw-Sprite 17 @(
"................",
"................",
"......RR........",
".....RRRR..RR...",
"....RRRRRRRRRR..",
"...RRR3RRRRRRR..",
"..RRRRRRR3RRRR..",
"..RRRRRRRRRRRR..",
".RRR3RRRRRR3RR..",
".RRRRRRRRRRRRR..",
".RRRRRR3RRRRRR..",
"..RRRRRRRRRRR...",
"...RRRRRRRRR....",
"................",
"................",
"................") @{ R = HexToColor '#E4E4E4'; '3' = HexToColor '#B0B0B0' }

# 18: plant mid/mature stage (fuller bush with fruit dots)
Draw-Sprite 18 @(
"................",
".....P.PP.P.....",
"....PPPPPPPP....",
"...PPP4PPPPPP...",
"...PPPPPP4PPP...",
"..PPP4PPPPPPPP..",
"..PPPPPPP4PPPP..",
"...PPPPPPPPPP...",
"....PP4PPPPP....",
".....PPPPPP.....",
"......P44P......",
".......55.......",
".......55.......",
"................",
"................",
"................") @{ P = HexToColor '#E8E8E8'; '4' = HexToColor '#FFFFFF'; '5' = HexToColor '#A8A090' }

# 19: flower (real colors)
Draw-Sprite 19 @(
"................",
"................",
"................",
"................",
"................",
"......F.........",
".....FWF........",
"......F.........",
".......s........",
".......s..F.....",
".......s.FWF....",
".......ss.F.....",
"........s.s.....",
"................",
"................",
"................") @{ F = HexToColor '#D879A8'; W = HexToColor '#F2E8B0'; s = HexToColor '#3E7A38' }

# 20: pebbles (real colors)
Draw-Sprite 20 @(
"................",
"................",
"................",
"................",
"................",
"................",
"................",
"................",
"................",
".....pp.........",
"....pppp...pp...",
".....pp...pppp..",
"...........pp...",
"................",
"................",
"................") @{ p = HexToColor '#8E8E96' }

# 21: bush (real colors)
Draw-Sprite 21 @(
"................",
"................",
"................",
"................",
"................",
"......bbbb......",
"....bbbbbbbb....",
"...bbb2bbbbbb...",
"...bbbbbb2bbb...",
"....bbbbbbbb....",
".....bbbbbb.....",
"................",
"................",
"................",
"................",
"................") @{ b = HexToColor '#35703A'; '2' = HexToColor '#2A5A2E' }

# 22: mushroom (real colors)
Draw-Sprite 22 @(
"................",
"................",
"................",
"................",
"................",
"................",
"................",
"......mmmm......",
".....mm2mmm.....",
".....mmmmmm.....",
".......ww.......",
".......ww.......",
"................",
"................",
"................",
"................") @{ m = HexToColor '#B0523A'; '2' = HexToColor '#E8D8C8'; w = HexToColor '#E0D8C8' }

# 23: rabbit (real colors)
Draw-Sprite 23 @(
"................",
"................",
"................",
"................",
"................",
"......r..r......",
"......r..r......",
".....rrrrrr.....",
".....rrrrrr.....",
"....rrrrrrrr....",
"....rrrrrrrrr...",
".....rr..rr.....",
"................",
"................",
"................",
"................") @{ r = HexToColor '#C8B8A8' }

# 24: bird (real colors)
Draw-Sprite 24 @(
"................",
"................",
"................",
"................",
"................",
"................",
".......bb.......",
"......bbbb.o....",
".....bbbbbb.....",
"......bbbb......",
".......ll.......",
"................",
"................",
"................",
"................",
"................") @{ b = HexToColor '#7A5C3D'; o = HexToColor '#E0A030'; l = HexToColor '#C89858' }

New-Item -ItemType Directory -Force C:\colony-sim\assets | Out-Null
$bmp.Save('C:\colony-sim\assets\sprites.png', [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
$md5 = [System.Security.Cryptography.MD5]::Create()
$hash = ($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes('res://assets/sprites.png')) | ForEach-Object { $_.ToString('x2') }) -join ''
Write-Output "saved sprites; md5=$hash"
