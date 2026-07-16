Add-Type -AssemblyName System.Drawing
# Replace the wood resource icon (sprites cell 4, x=64) with a bundle of
# cut logs seen end-on: three end-grain rounds, unmistakably lumber.
$path = "C:\colony-sim\assets\sprites.png"
$bmp = [System.Drawing.Bitmap]::FromFile($path)
$clone = New-Object System.Drawing.Bitmap($bmp)  # detach from the file handle
$bmp.Dispose()

function Hex($h) { [System.Drawing.ColorTranslator]::FromHtml($h) }
$pal = @{
    'B' = Hex '#4A3018'  # bark rim
    'W' = Hex '#A9743E'  # sapwood
    'R' = Hex '#8A5A2E'  # growth ring
    'C' = Hex '#C6935A'  # bright core
}
$log = @(
    ".BBBBB.",
    "BWWWWWB",
    "BWRRRWB",
    "BWRCRWB",
    "BWRRRWB",
    "BWWWWWB",
    ".BBBBB."
)
$base = 64  # cell 4 * 16
# Clear the cell to transparent first.
for ($x = 0; $x -lt 16; $x++) { for ($y = 0; $y -lt 16; $y++) {
    $clone.SetPixel($base + $x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
} }
function Stamp($ox, $oy) {
    for ($ry = 0; $ry -lt $log.Count; $ry++) {
        $line = $log[$ry]
        for ($rx = 0; $rx -lt $line.Length; $rx++) {
            $ch = [string]$line[$rx]
            if ($ch -eq '.') { continue }
            $clone.SetPixel($base + $ox + $rx, $oy + $ry, $pal[$ch])
        }
    }
}
Stamp 5 1   # top log
Stamp 0 8   # bottom-left log
Stamp 9 8   # bottom-right log

$clone.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
$clone.Dispose()
Write-Output "wood icon redrawn as cut logs"
