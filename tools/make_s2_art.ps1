Add-Type -AssemblyName System.Drawing
# v1.3 S2 art: tiles.png 20 -> 22 cells
#   20 = spike pit (dark pit, pale spikes)
#   21 = alarm bell (wooden frame, golden bell)
function Hex($h) { [System.Drawing.ColorTranslator]::FromHtml($h) }
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

$f = [System.Drawing.Bitmap]::FromFile("C:\colony-sim\assets\tiles.png")
$old = New-Object System.Drawing.Bitmap($f)
$f.Dispose()
$tiles = New-Object System.Drawing.Bitmap(352, 16)  # 22 cells
$g = [System.Drawing.Graphics]::FromImage($tiles)
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$g.DrawImage($old, (New-Object System.Drawing.Rectangle(0, 0, $old.Width, 16)),
    (New-Object System.Drawing.Rectangle(0, 0, $old.Width, 16)), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose(); $old.Dispose()

# 20: spike pit — dark pit with rim, four pale spikes rising
$pit = (Hex '#241C14'); $rim = (Hex '#4A3A28'); $spike = (Hex '#C9C4B4'); $spikeHi = (Hex '#E6E2D4')
$b = 320
for ($x = 0; $x -lt 16; $x++) { for ($y = 0; $y -lt 16; $y++) {
    $c = $clear
    if ($x -ge 1 -and $x -le 14 -and $y -ge 1 -and $y -le 14) {
        $c = $(if ($x -le 2 -or $x -ge 13 -or $y -le 2 -or $y -ge 13) { $rim } else { $pit })
    }
    $tiles.SetPixel($b + $x, $y, $c)
} }
foreach ($sx in @(4, 7, 10)) {
    for ($h = 0; $h -lt 6; $h++) {
        $y = 12 - $h
        $tiles.SetPixel($b + $sx, $y, $spike)
        if ($h -lt 3) { $tiles.SetPixel($b + $sx + 1, $y, $spikeHi) }
    }
}
# 21: alarm bell — two posts, crossbeam, golden bell hanging
$post = (Hex '#6E4E28'); $beam = (Hex '#8A6335'); $bell = (Hex '#D9A93A'); $bellHi = (Hex '#F2CE6B'); $clapper = (Hex '#4A3A28')
$b = 336
for ($x = 0; $x -lt 16; $x++) { for ($y = 0; $y -lt 16; $y++) {
    $c = $clear
    if (($x -eq 2 -or $x -eq 3 -or $x -eq 12 -or $x -eq 13) -and $y -ge 2 -and $y -le 14) { $c = $post }
    elseif (($y -eq 1 -or $y -eq 2) -and $x -ge 1 -and $x -le 14) { $c = $beam }
    $tiles.SetPixel($b + $x, $y, $c)
} }
for ($y = 4; $y -le 9; $y++) { for ($x = 6; $x -le 9; $x++) {
    $w = $(if ($y -le 5) { 1 } elseif ($y -le 7) { 0 } else { -1 })
    if ($x -ge (6 - $w) -and $x -le (9 + $w) -and $x -ge 5 -and $x -le 10) {
        $tiles.SetPixel($b + $x, $y, $(if ($x -eq 6 -and $y -le 6) { $bellHi } else { $bell }))
    }
} }
for ($x = 5; $x -le 10; $x++) { $tiles.SetPixel($b + $x, 10, $bell) }
$tiles.SetPixel($b + 7, 11, $clapper); $tiles.SetPixel($b + 8, 11, $clapper)
$tiles.SetPixel($b + 7, 3, $clapper); $tiles.SetPixel($b + 8, 3, $clapper)  # hanger

$tiles.Save("C:\colony-sim\assets\tiles.png", [System.Drawing.Imaging.ImageFormat]::Png)
$tiles.Dispose()
Write-Output "tiles.png now 22 cells (spike pit 20, bell 21)"
