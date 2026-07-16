Add-Type -AssemblyName System.Drawing
# Extend tiles.png from 16 to 17 cells; draw a brewing barrel at cell 16.
$path = "C:\colony-sim\assets\tiles.png"
$old = [System.Drawing.Bitmap]::FromFile($path)
$w = 272  # 17 cells * 16
$bmp = New-Object System.Drawing.Bitmap($w, 16)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$g.DrawImage($old, (New-Object System.Drawing.Rectangle(0, 0, $old.Width, 16)),
    (New-Object System.Drawing.Rectangle(0, 0, $old.Width, 16)), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$old.Dispose()

function Hex($h) { [System.Drawing.ColorTranslator]::FromHtml($h) }
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
$metal = (Hex '#9AA0AA'); $edge = (Hex '#5C3E24'); $bung = (Hex '#4A321C')
$stave = @((Hex '#8A6335'), (Hex '#A9743E'), (Hex '#6E4E28'))
$base = 256
for ($x = 0; $x -lt 16; $x++) {
    for ($y = 0; $y -lt 16; $y++) {
        $c = $clear
        $inBody = ($x -ge 2 -and $x -le 13 -and $y -ge 1 -and $y -le 14)
        $corner = (($x -le 2 -or $x -ge 13) -and ($y -le 2 -or $y -ge 13))
        if ($inBody -and -not $corner) {
            if ($x -eq 2 -or $x -eq 13 -or $y -eq 1 -or $y -eq 14) { $c = $edge }
            elseif ($y -eq 4 -or $y -eq 11) { $c = $metal }  # iron hoops
            elseif ($x -eq 7 -and $y -eq 7) { $c = $bung }
            else { $c = $stave[($x - 2) % 3] }
        }
        $bmp.SetPixel($base + $x, $y, $c)
    }
}
$bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output "brewery tile appended at cell 16 (tiles.png now 272 wide)"
