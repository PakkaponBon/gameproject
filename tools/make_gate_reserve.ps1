Add-Type -AssemblyName System.Drawing
# Reserve gate-animation cells: extend tiles.png from 22 cells (352px) to 25
# cells (400px), leaving cells 22/23/24 transparent for the asset agent to
# draw the gate opening/closing frames. Existing cells 0-21 are preserved.
$path = "C:\colony-sim\assets\tiles.png"
$f = [System.Drawing.Bitmap]::FromFile($path)
$src = New-Object System.Drawing.Bitmap($f)  # detach from the file handle
$f.Dispose()
$w = 400  # 25 cells * 16
$bmp = New-Object System.Drawing.Bitmap($w, 16)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$g.DrawImage($src, (New-Object System.Drawing.Rectangle(0, 0, $src.Width, 16)),
    (New-Object System.Drawing.Rectangle(0, 0, $src.Width, 16)), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose(); $src.Dispose()
Write-Output "tiles.png reserved to 25 cells (22/23/24 transparent, awaiting gate frames)"
