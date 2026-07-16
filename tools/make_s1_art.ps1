Add-Type -AssemblyName System.Drawing
# v1.3 S1 art:
#  tiles.png 18 -> 20 cells: 18 = pasture (fence ring, grass shows through),
#                            19 = loom (wooden frame with threads)
#  sprites.png 27 -> 28 cells: 27 = armor icon (Kenney dungeon crest shield)
$scratch = "C:\Users\ballz\AppData\Local\Temp\claude\C--colony-sim\7288020a-4f9f-4863-bbb5-53e51e3df69f\scratchpad"
function Hex($h) { [System.Drawing.ColorTranslator]::FromHtml($h) }
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

# --- tiles ---
$old = [System.Drawing.Bitmap]::FromFile("C:\colony-sim\assets\tiles.png")
$tiles = New-Object System.Drawing.Bitmap(320, 16)  # 20 cells
$g = [System.Drawing.Graphics]::FromImage($tiles)
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$g.DrawImage($old, (New-Object System.Drawing.Rectangle(0, 0, $old.Width, 16)),
    (New-Object System.Drawing.Rectangle(0, 0, $old.Width, 16)), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose(); $old.Dispose()

$post = (Hex '#6E4E28'); $rail = (Hex '#8A6335'); $railHi = (Hex '#A9743E')
# 18: pasture — fence posts at corners/mids, two rails per side, open center
$b = 288
for ($x = 0; $x -lt 16; $x++) { for ($y = 0; $y -lt 16; $y++) {
    $c = $clear
    $isPostX = ($x -le 1 -or $x -ge 14 -or ($x -ge 7 -and $x -le 8))
    $isPostY = ($y -le 1 -or $y -ge 14 -or ($y -ge 7 -and $y -le 8))
    # rails: horizontal at y 3-4 and 11-12 along top/bottom edges is wrong for
    # a ring; instead draw a border ring of rails with posts.
    $onBorder = ($x -le 2 -or $x -ge 13 -or $y -le 2 -or $y -ge 13)
    if ($onBorder) {
        if ((($x % 6) -eq 1) -and (($y -le 2) -or ($y -ge 13))) { $c = $post }
        elseif ((($y % 6) -eq 1) -and (($x -le 2) -or ($x -ge 13))) { $c = $post }
        elseif ($y -eq 1 -or $y -eq 14 -or $x -eq 1 -or $x -eq 14) { $c = $rail }
        elseif ($y -eq 2 -or $y -eq 13 -or $x -eq 2 -or $x -eq 13) { $c = $railHi }
    }
    $tiles.SetPixel($b + $x, $y, $c)
} }
# 19: loom — upright frame, warp threads, cloth forming at the bottom
$frame = (Hex '#6E4E28'); $frameHi = (Hex '#8A6335'); $thread = (Hex '#E8E2D0'); $cloth = (Hex '#C46A5A')
$b = 304
for ($x = 0; $x -lt 16; $x++) { for ($y = 0; $y -lt 16; $y++) {
    $c = $clear
    if (($x -eq 2 -or $x -eq 3 -or $x -eq 12 -or $x -eq 13) -and $y -ge 1 -and $y -le 14) {
        $c = $(if ($x -eq 2 -or $x -eq 12) { $frame } else { $frameHi })  # uprights
    }
    elseif (($y -eq 1 -or $y -eq 2) -and $x -ge 2 -and $x -le 13) { $c = $frame }  # top beam
    elseif (($y -eq 14) -and $x -ge 2 -and $x -le 13) { $c = $frame }  # foot beam
    elseif ($y -ge 3 -and $y -le 9 -and $x -ge 4 -and $x -le 11 -and (($x % 2) -eq 0)) { $c = $thread }
    elseif ($y -ge 10 -and $y -le 13 -and $x -ge 4 -and $x -le 11) { $c = $cloth }  # woven cloth
    $tiles.SetPixel($b + $x, $y, $c)
} }
$tiles.Save("C:\colony-sim\assets\tiles.png", [System.Drawing.Imaging.ImageFormat]::Png)
$tiles.Dispose()

# --- sprites: append cell 27 = dungeon crest shield (5,2) ---
$oldS = [System.Drawing.Bitmap]::FromFile("C:\colony-sim\assets\sprites.png")
$dun = [System.Drawing.Bitmap]::FromFile("$scratch\tiny-dungeon\Tilemap\tilemap_packed.png")
$sprites = New-Object System.Drawing.Bitmap(448, 16)  # 28 cells
$g2 = [System.Drawing.Graphics]::FromImage($sprites)
$g2.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$g2.DrawImage($oldS, (New-Object System.Drawing.Rectangle(0, 0, $oldS.Width, 16)),
    (New-Object System.Drawing.Rectangle(0, 0, $oldS.Width, 16)), [System.Drawing.GraphicsUnit]::Pixel)
$g2.DrawImage($dun, (New-Object System.Drawing.Rectangle(432, 0, 16, 16)),
    (New-Object System.Drawing.Rectangle(80, 32, 16, 16)), [System.Drawing.GraphicsUnit]::Pixel)
$g2.Dispose()
$sprites.Save("C:\colony-sim\assets\sprites.png", [System.Drawing.Imaging.ImageFormat]::Png)
$sprites.Dispose(); $oldS.Dispose(); $dun.Dispose()
Write-Output "tiles now 20 cells; sprites now 28 cells (armor crest at 27)"
