# Procedural placeholder audio: 16-bit mono PCM WAVs.
$rate = 22050
New-Item -ItemType Directory -Force C:\colony-sim\assets\sfx | Out-Null

function Write-Wav($path, $samples) {
    $n = $samples.Count
    $dataSize = $n * 2
    $fs = [System.IO.File]::Create($path)
    $w = New-Object System.IO.BinaryWriter($fs)
    $w.Write([char[]]"RIFF"); $w.Write([int](36 + $dataSize)); $w.Write([char[]]"WAVE")
    $w.Write([char[]]"fmt "); $w.Write([int]16); $w.Write([int16]1); $w.Write([int16]1)
    $w.Write([int]$rate); $w.Write([int]($rate * 2)); $w.Write([int16]2); $w.Write([int16]16)
    $w.Write([char[]]"data"); $w.Write([int]$dataSize)
    foreach ($s in $samples) {
        $v = [Math]::Max(-1.0, [Math]::Min(1.0, $s))
        $w.Write([int16]($v * 32000))
    }
    $w.Close()
}

$rand = New-Object System.Random(7)

# hit: noise burst, fast decay
$s = New-Object 'System.Collections.Generic.List[double]'
for ($i = 0; $i -lt [int]($rate * 0.12); $i++) {
    $t = $i / $rate
    $env = [Math]::Exp(-28.0 * $t)
    $s.Add((($rand.NextDouble() * 2 - 1) * 0.7 + [Math]::Sin(2 * [Math]::PI * 180 * $t) * 0.3) * $env)
}
Write-Wav 'C:\colony-sim\assets\sfx\hit.wav' $s

# thud: low sine knock (work done)
$s = New-Object 'System.Collections.Generic.List[double]'
for ($i = 0; $i -lt [int]($rate * 0.16); $i++) {
    $t = $i / $rate
    $env = [Math]::Exp(-18.0 * $t)
    $s.Add([Math]::Sin(2 * [Math]::PI * (95 - 40 * $t) * $t) * $env * 0.9)
}
Write-Wav 'C:\colony-sim\assets\sfx\thud.wav' $s

# spell: rising shimmer
$s = New-Object 'System.Collections.Generic.List[double]'
for ($i = 0; $i -lt [int]($rate * 0.35); $i++) {
    $t = $i / $rate
    $f = 380 + 1400 * $t
    $env = [Math]::Sin([Math]::PI * $t / 0.35)
    $s.Add(([Math]::Sin(2 * [Math]::PI * $f * $t) * 0.5 + [Math]::Sin(2 * [Math]::PI * $f * 1.5 * $t) * 0.25) * $env)
}
Write-Wav 'C:\colony-sim\assets\sfx\spell.wav' $s

# horn: raid warning, two-note swell
$s = New-Object 'System.Collections.Generic.List[double]'
for ($i = 0; $i -lt [int]($rate * 0.8); $i++) {
    $t = $i / $rate
    $f = 196.0; if ($t -gt 0.4) { $f = 233.0 }
    $env = [Math]::Min(1.0, $t * 8) * [Math]::Exp(-1.6 * $t)
    $v = 0.0
    foreach ($h in 1, 2, 3) { $v += [Math]::Sin(2 * [Math]::PI * $f * $h * $t) / $h }
    $s.Add($v * $env * 0.45)
}
Write-Wav 'C:\colony-sim\assets\sfx\horn.wav' $s

# death: falling tone
$s = New-Object 'System.Collections.Generic.List[double]'
for ($i = 0; $i -lt [int]($rate * 0.45); $i++) {
    $t = $i / $rate
    $f = 290 * [Math]::Exp(-2.8 * $t)
    $env = [Math]::Exp(-5.0 * $t)
    $s.Add([Math]::Sin(2 * [Math]::PI * $f * $t) * $env * 0.8)
}
Write-Wav 'C:\colony-sim\assets\sfx\death.wav' $s

# village loop: soft slow pad (A, C#, E), 8s
$s = New-Object 'System.Collections.Generic.List[double]'
$len = [int]($rate * 8)
for ($i = 0; $i -lt $len; $i++) {
    $t = $i / $rate
    $lfo = 0.6 + 0.4 * [Math]::Sin(2 * [Math]::PI * $t / 8.0)
    $v = 0.0
    foreach ($f in 110.0, 138.6, 164.8) { $v += [Math]::Sin(2 * [Math]::PI * $f * $t) }
    $s.Add($v / 3.0 * 0.16 * $lfo)
}
Write-Wav 'C:\colony-sim\assets\sfx\village_loop.wav' $s

# raid loop: beating low drone + pulse, 6s
$s = New-Object 'System.Collections.Generic.List[double]'
$len = [int]($rate * 6)
for ($i = 0; $i -lt $len; $i++) {
    $t = $i / $rate
    $pulse = 1.0; if (($t * 2.0) % 1.0 -lt 0.08) { $pulse = 1.6 }
    $v = [Math]::Sin(2 * [Math]::PI * 82.4 * $t) + [Math]::Sin(2 * [Math]::PI * 87.3 * $t)
    $s.Add($v / 2.0 * 0.2 * $pulse)
}
Write-Wav 'C:\colony-sim\assets\sfx\raid_loop.wav' $s

Write-Output "saved 7 audio files"
