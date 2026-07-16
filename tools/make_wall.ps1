Add-Type -AssemblyName System.Drawing
# Replace the wall tile (tiles cell 2, x=32) with a stone-brick wall:
# running-bond courses, mortar lines, a lit cap and a shadowed base so it
# reads as a raised barrier instead of a floor slab.
$path = "C:\colony-sim\assets\tiles.png"
$bmp = [System.Drawing.Bitmap]::FromFile($path)
$clone = New-Object System.Drawing.Bitmap($bmp)
$bmp.Dispose()

function Hex($h) { [System.Drawing.ColorTranslator]::FromHtml($h) }
$pal = @{
    '1' = Hex '#9A9AA6'  # cap (lightest)
    '2' = Hex '#82828E'  # brick top highlight
    '3' = Hex '#6E6E7A'  # brick body
    '4' = Hex '#565662'  # brick base shadow
    '0' = Hex '#3E3E48'  # mortar
}
$rows = @(
    "1111111111111111",
    "2222222022222222",
    "3333333033333333",
    "4444444044444444",
    "0000000000000000",
    "2220222222202222",
    "3330333333303333",
    "4440444444404444",
    "0000000000000000",
    "2222222022222222",
    "3333333033333333",
    "4444444044444444",
    "0000000000000000",
    "2220222222202222",
    "3330333333303333",
    "0000000000000000"
)
$base = 32  # cell 2 * 16
for ($y = 0; $y -lt 16; $y++) {
    $line = $rows[$y]
    for ($x = 0; $x -lt 16; $x++) {
        $clone.SetPixel($base + $x, $y, $pal[[string]$line[$x]])
    }
}
$clone.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
$clone.Dispose()
Write-Output "wall tile redrawn as stone brick"
