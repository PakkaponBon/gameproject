Add-Type -AssemblyName System.Drawing
# Rebuild sprites.png / tiles.png from Kenney Tiny Town + Tiny Dungeon (CC0),
# preserving our cell-index layout so no game code changes. Cells with no
# Kenney equivalent (rocks, grave) keep the old procedural art.
$scratch = "C:\Users\ballz\AppData\Local\Temp\claude\C--colony-sim\7288020a-4f9f-4863-bbb5-53e51e3df69f\scratchpad"
$town = [System.Drawing.Bitmap]::FromFile("$scratch\tiny-town\Tilemap\tilemap_packed.png")
$dun = [System.Drawing.Bitmap]::FromFile("$scratch\tiny-dungeon\Tilemap\tilemap_packed.png")
$oldSprites = [System.Drawing.Bitmap]::FromFile("C:\colony-sim\assets\sprites.png")
$oldTiles = [System.Drawing.Bitmap]::FromFile("C:\colony-sim\assets\tiles.png")

function New-Canvas($w) {
    $bmp = New-Object System.Drawing.Bitmap($w, 16)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    return @($bmp, $g)
}
function Put($g, $sheet, $cx, $cy, $index, $dy = 0) {
    $dest = New-Object System.Drawing.Rectangle(($index * 16), $dy, 16, 16)
    $src = New-Object System.Drawing.Rectangle(($cx * 16), ($cy * 16), 16, 16)
    $g.DrawImage($sheet, $dest, $src, [System.Drawing.GraphicsUnit]::Pixel)
}

# --- sprites.png: 27 cells (25 old + ally knight + merchant elder) ---
$out = New-Canvas 432; $sprites = $out[0]; $g = $out[1]
$g.DrawImage($oldSprites, (New-Object System.Drawing.Rectangle(0, 0, $oldSprites.Width, 16)),
    (New-Object System.Drawing.Rectangle(0, 0, $oldSprites.Width, 16)), [System.Drawing.GraphicsUnit]::Pixel)
Put $g $dun 1 7 0        # villager
Put $g $town 5 0 1       # tree (round green)
# 2 rock: keep procedural
Put $g $town 5 1 3       # young crop sprigs
Put $g $town 7 8 4       # wood -> crate
# 5 stone chunk: keep procedural
Put $g $dun 6 8 6        # ingot -> silver round
Put $g $dun 8 8 7        # sword
Put $g $town 10 9 8      # bow
Put $g $town 11 9 9      # arrow
Put $g $dun 6 9 10       # herb -> green flask
Put $g $town 10 7 11     # food -> beehive (honey stores)
Put $g $dun 10 10 12     # relic -> blue wand
# 13 grave: keep procedural
Put $g $dun 1 7 14 -1    # walk frame: same villager, 1px bob
Put $g $dun 4 9 15       # bandit
Put $g $town 4 2 16      # pine (small green)
# 17 jagged rock: keep procedural
Put $g $town 5 1 18      # mature crop (scale conveys growth)
Put $g $town 2 0 19      # decor: flowers on grass
Put $g $town 7 3 20      # decor: pebbles on grass
Put $g $town 3 2 21      # berry bush (orange-laden shrub)
Put $g $town 5 2 22      # decor: mushrooms
Put $g $dun 0 10 23      # rabbit-ish critter
Put $g $dun 3 10 24      # bird-ish critter
Put $g $dun 0 8 25       # NEW: ally -> knight
Put $g $dun 3 7 26       # NEW: merchant -> gray elder
$g.Dispose()
# Custom wood icon: Kenney has no clean log pile, so draw cut logs
# (end-grain rounds) into cell 4 directly.
function Hex($h) { [System.Drawing.ColorTranslator]::FromHtml($h) }
$woodPal = @{ 'B' = (Hex '#4A3018'); 'W' = (Hex '#A9743E'); 'R' = (Hex '#8A5A2E'); 'C' = (Hex '#C6935A') }
$logRows = @(".BBBBB.", "BWWWWWB", "BWRRRWB", "BWRCRWB", "BWRRRWB", "BWWWWWB", ".BBBBB.")
for ($x = 0; $x -lt 16; $x++) { for ($y = 0; $y -lt 16; $y++) { $sprites.SetPixel(64 + $x, $y, [System.Drawing.Color]::FromArgb(0,0,0,0)) } }
foreach ($p in @(@(5,1), @(0,8), @(9,8))) {
    for ($ry = 0; $ry -lt $logRows.Count; $ry++) { $line = $logRows[$ry]; for ($rx = 0; $rx -lt $line.Length; $rx++) {
        $ch = [string]$line[$rx]; if ($ch -ne '.') { $sprites.SetPixel(64 + $p[0] + $rx, $p[1] + $ry, $woodPal[$ch]) }
    } }
}
$sprites.Save("C:\colony-sim\assets\sprites_new.png", [System.Drawing.Imaging.ImageFormat]::Png)

# --- tiles.png: 18 cells (16 mapped + custom brewery + coop) ---
$out = New-Canvas 288; $tiles = $out[0]; $g = $out[1]
$g.DrawImage($oldTiles, (New-Object System.Drawing.Rectangle(0, 0, 256, 16)),
    (New-Object System.Drawing.Rectangle(0, 0, 256, 16)), [System.Drawing.GraphicsUnit]::Pixel)
Put $g $town 0 0 0       # grass
Put $g $town 1 2 1       # dirt
Put $g $town 1 9 2       # wall -> stone slab
Put $g $town 4 10 3      # gate -> stone arch w/ door
Put $g $dun 6 5 4        # bed -> bedroll pad
Put $g $town 10 10 5     # barn -> chest
Put $g $dun 2 6 6        # forge -> anvil
Put $g $town 3 4 7       # watchtower -> tower cap
Put $g $dun 5 5 8        # stove -> furnace
Put $g $town 4 7 9       # door -> door in stone frame
Put $g $dun 8 4 10       # hearth -> glowing pot
Put $g $dun 0 6 11       # table
Put $g $dun 1 6 12       # chair -> stool
Put $g $dun 8 2 13       # shrine -> glowing pedestal
Put $g $dun 5 2 14       # trophy wall -> mounted crest
Put $g $dun 5 10 15      # brazier -> torch
$g.Dispose()
# Custom wall tile: Kenney's stone slab read as floor, so draw a
# running-bond brick wall (lit cap, shadowed base) into cell 2.
$wallPal = @{ '1' = (Hex '#9A9AA6'); '2' = (Hex '#82828E'); '3' = (Hex '#6E6E7A'); '4' = (Hex '#565662'); '0' = (Hex '#3E3E48') }
$wallRows = @("1111111111111111", "2222222022222222", "3333333033333333", "4444444044444444", "0000000000000000", "2220222222202222", "3330333333303333", "4440444444404444", "0000000000000000", "2222222022222222", "3333333033333333", "4444444044444444", "0000000000000000", "2220222222202222", "3330333333303333", "0000000000000000")
for ($y = 0; $y -lt 16; $y++) { $line = $wallRows[$y]; for ($x = 0; $x -lt 16; $x++) { $tiles.SetPixel(32 + $x, $y, $wallPal[[string]$line[$x]]) } }
# Custom brewery barrel at cell 16 (Kenney has no clean vat).
$bMetal = (Hex '#9AA0AA'); $bEdge = (Hex '#5C3E24'); $bBung = (Hex '#4A321C')
$bStave = @((Hex '#8A6335'), (Hex '#A9743E'), (Hex '#6E4E28')); $bClear = [System.Drawing.Color]::FromArgb(0,0,0,0)
for ($x = 0; $x -lt 16; $x++) { for ($y = 0; $y -lt 16; $y++) {
    $c = $bClear
    if ($x -ge 2 -and $x -le 13 -and $y -ge 1 -and $y -le 14 -and -not ((($x -le 2) -or ($x -ge 13)) -and (($y -le 2) -or ($y -ge 13)))) {
        if ($x -eq 2 -or $x -eq 13 -or $y -eq 1 -or $y -eq 14) { $c = $bEdge }
        elseif ($y -eq 4 -or $y -eq 11) { $c = $bMetal }
        elseif ($x -eq 7 -and $y -eq 7) { $c = $bBung }
        else { $c = $bStave[($x - 2) % 3] }
    }
    $tiles.SetPixel(256 + $x, $y, $c)
} }
# Custom chicken coop at cell 17 (hut with peaked roof + round door).
$cRoof = (Hex '#8A4B32'); $cRoofHi = (Hex '#A65C3E'); $cDoor = (Hex '#33240F'); $cSeam = (Hex '#5C3E24')
$cWood = @((Hex '#8A6335'), (Hex '#A9743E'), (Hex '#6E4E28'))
for ($x = 0; $x -lt 16; $x++) { for ($y = 0; $y -lt 16; $y++) {
    $c = $bClear
    if ($y -ge 1 -and $y -le 5) { $half = $y + 1; if ($x -ge (7 - $half) -and $x -le (8 + $half)) { $c = $(if ($y -eq 1) { $cRoofHi } else { $cRoof }) } }
    elseif ($y -ge 6 -and $y -le 14 -and $x -ge 3 -and $x -le 12) { $c = $(if ($x -eq 3 -or $x -eq 12 -or $y -eq 14) { $cSeam } else { $cWood[($x - 3) % 3] }) }
    if ($x -ge 6 -and $x -le 9 -and $y -ge 10 -and $y -le 14) { $c = $cDoor }
    if ($x -ge 7 -and $x -le 8 -and $y -eq 9) { $c = $cDoor }
    $tiles.SetPixel(272 + $x, $y, $c)
} }
$tiles.Save("C:\colony-sim\assets\tiles_new.png", [System.Drawing.Imaging.ImageFormat]::Png)

$town.Dispose(); $dun.Dispose(); $oldSprites.Dispose(); $oldTiles.Dispose()
Move-Item -Force "C:\colony-sim\assets\sprites_new.png" "C:\colony-sim\assets\sprites.png"
Move-Item -Force "C:\colony-sim\assets\tiles_new.png" "C:\colony-sim\assets\tiles.png"
Copy-Item "$scratch\fonts\Fonts\Kenney Pixel.ttf" "C:\colony-sim\assets\kenney_pixel.ttf" -ErrorAction SilentlyContinue
if (-not (Test-Path "C:\colony-sim\assets\kenney_pixel.ttf")) {
    $ttf = Get-ChildItem "$scratch\fonts" -Recurse -Filter "Kenney Pixel.ttf" | Select-Object -First 1
    Copy-Item $ttf.FullName "C:\colony-sim\assets\kenney_pixel.ttf"
}
Write-Output "atlases composed + font copied"
