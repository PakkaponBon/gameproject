Add-Type -AssemblyName System.Drawing
# Extend tiles.png from 17 to 18 cells; draw a chicken coop at cell 17:
# a little wooden hut with a peaked roof and a round dark entrance.
$path = "C:\colony-sim\assets\tiles.png"
$old = [System.Drawing.Bitmap]::FromFile($path)
$w = 288  # 18 cells * 16
$bmp = New-Object System.Drawing.Bitmap($w, 16)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$g.DrawImage($old, (New-Object System.Drawing.Rectangle(0, 0, $old.Width, 16)),
    (New-Object System.Drawing.Rectangle(0, 0, $old.Width, 16)), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose(); $old.Dispose()

function Hex($h) { [System.Drawing.ColorTranslator]::FromHtml($h) }
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
$roof = (Hex '#8A4B32'); $roofHi = (Hex '#A65C3E')
$door = (Hex '#33240F')
$wood = @((Hex '#8A6335'), (Hex '#A9743E'), (Hex '#6E4E28'))
$seam = (Hex '#5C3E24')
$base = 272
for ($x = 0; $x -lt 16; $x++) {
    for ($y = 0; $y -lt 16; $y++) {
        $c = $clear
        # Roof: a triangle over rows 1..5.
        if ($y -ge 1 -and $y -le 5) {
            $half = $y + 1
            if ($x -ge (7 - $half) -and $x -le (8 + $half)) {
                $c = if ($y -eq 1) { $roofHi } else { $roof }
            }
        }
        # Body: rows 6..14, cols 3..12.
        elseif ($y -ge 6 -and $y -le 14 -and $x -ge 3 -and $x -le 12) {
            if ($x -eq 3 -or $x -eq 12 -or $y -eq 14) { $c = $seam }
            else { $c = $wood[($x - 3) % 3] }
        }
        # Round entrance: cols 6..9, rows 9..14 with an arched top.
        if ($x -ge 6 -and $x -le 9 -and $y -ge 10 -and $y -le 14) { $c = $door }
        if ($x -ge 7 -and $x -le 8 -and $y -eq 9) { $c = $door }
        $bmp.SetPixel($base + $x, $y, $c)
    }
}
$bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output "coop tile appended at cell 17 (tiles.png now 288 wide)"
