Add-Type -AssemblyName System.Drawing
# Asset importer (see ASSET_SPEC.md): packs assets/incoming/*.png into the
# two atlases by filename index. Validates 16x16 and index range; skips
# (with a reason) anything invalid. Safe to run repeatedly.
#   tile_NN_name.png   -> assets/tiles.png   (cells 0..24)
#   sprite_NN_name.png -> assets/sprites.png (cells 0..65)
$repo = "C:\colony-sim"
$incoming = Join-Path $repo "assets\incoming"
if (-not (Test-Path $incoming)) { New-Item -ItemType Directory $incoming | Out-Null }

$targets = @{
    "tile" = @{ "path" = (Join-Path $repo "assets\tiles.png"); "max" = 24 }
    "sprite" = @{ "path" = (Join-Path $repo "assets\sprites.png"); "max" = 65 }
}
# Open each atlas onto a canvas wide enough for all declared cells, so newly
# reserved cells exist (transparent) and packing never clips. Clone-copy
# (never Save over a file still open via FromFile).
$atlases = @{}
foreach ($kind in $targets.Keys) {
    $f = [System.Drawing.Bitmap]::FromFile($targets[$kind].path)
    $w = ($targets[$kind].max + 1) * 16
    $canvas = New-Object System.Drawing.Bitmap($w, 16)
    $g = [System.Drawing.Graphics]::FromImage($canvas)
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $g.DrawImage($f, (New-Object System.Drawing.Rectangle(0, 0, [Math]::Min($f.Width, $w), 16)),
        (New-Object System.Drawing.Rectangle(0, 0, [Math]::Min($f.Width, $w), 16)), [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose(); $f.Dispose()
    $atlases[$kind] = $canvas
}

$imported = 0
foreach ($file in Get-ChildItem $incoming -Filter *.png) {
    if ($file.Name -notmatch '^(tile|sprite)_(\d{1,2})(_.*)?\.png$') {
        Write-Output ("SKIP " + $file.Name + " - name must be tile_NN_*.png or sprite_NN_*.png")
        continue
    }
    $kind = $Matches[1]; $index = [int]$Matches[2]
    if ($index -gt $targets[$kind].max) {
        Write-Output ("SKIP " + $file.Name + " - cell $index does not exist; new cells need a code hook (file a request in ASSET_SPEC.md)")
        continue
    }
    $src = [System.Drawing.Bitmap]::FromFile($file.FullName)
    if ($src.Width -ne 16 -or $src.Height -ne 16) {
        Write-Output ("SKIP " + $file.Name + " - must be exactly 16x16 (is " + $src.Width + "x" + $src.Height + ")")
        $src.Dispose(); continue
    }
    $g = [System.Drawing.Graphics]::FromImage($atlases[$kind])
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $g.DrawImage($src, (New-Object System.Drawing.Rectangle(($index * 16), 0, 16, 16)),
        (New-Object System.Drawing.Rectangle(0, 0, 16, 16)), [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose(); $src.Dispose()
    Write-Output ("OK   " + $file.Name + " -> " + $kind + "s.png cell " + $index)
    $imported++
}

if ($imported -gt 0) {
    foreach ($kind in $targets.Keys) {
        $atlases[$kind].Save($targets[$kind].path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    Write-Output ("Done: " + $imported + " cell(s) imported. Godot re-imports the atlases on next focus.")
} else {
    Write-Output "Nothing imported."
}
foreach ($kind in $targets.Keys) { $atlases[$kind].Dispose() }
