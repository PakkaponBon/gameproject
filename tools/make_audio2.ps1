# Phase 12 sound pass: work sounds, footsteps, bow, hurt, click, ambience.
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

$rand = New-Object System.Random(11)

# chop: sharp knock + wood crack noise
$s = New-Object 'System.Collections.Generic.List[double]'
for ($i = 0; $i -lt [int]($rate * 0.1); $i++) {
    $t = $i / $rate
    $env = [Math]::Exp(-45.0 * $t)
    $s.Add(([Math]::Sin(2 * [Math]::PI * 620 * $t) * 0.4 + ($rand.NextDouble() * 2 - 1) * 0.6) * $env)
}
Write-Wav 'C:\colony-sim\assets\sfx\chop.wav' $s

# mine: metallic tink
$s = New-Object 'System.Collections.Generic.List[double]'
for ($i = 0; $i -lt [int]($rate * 0.12); $i++) {
    $t = $i / $rate
    $env = [Math]::Exp(-40.0 * $t)
    $s.Add(([Math]::Sin(2 * [Math]::PI * 1350 * $t) * 0.5 + [Math]::Sin(2 * [Math]::PI * 2020 * $t) * 0.25 + ($rand.NextDouble() * 2 - 1) * 0.2) * $env)
}
Write-Wav 'C:\colony-sim\assets\sfx\mine.wav' $s

# hammer: two quick knocks
$s = New-Object 'System.Collections.Generic.List[double]'
for ($i = 0; $i -lt [int]($rate * 0.22); $i++) {
    $t = $i / $rate
    $tt = $t; if ($t -ge 0.12) { $tt = $t - 0.12 }
    $env = [Math]::Exp(-50.0 * $tt)
    $s.Add(([Math]::Sin(2 * [Math]::PI * 420 * $tt) * 0.6 + ($rand.NextDouble() * 2 - 1) * 0.3) * $env)
}
Write-Wav 'C:\colony-sim\assets\sfx\hammer.wav' $s

# eat: two soft blips
$s = New-Object 'System.Collections.Generic.List[double]'
for ($i = 0; $i -lt [int]($rate * 0.2); $i++) {
    $t = $i / $rate
    $f = 480.0; $tt = $t
    if ($t -ge 0.1) { $f = 610.0; $tt = $t - 0.1 }
    $env = [Math]::Exp(-30.0 * $tt) * 0.5
    $s.Add([Math]::Sin(2 * [Math]::PI * $f * $tt) * $env)
}
Write-Wav 'C:\colony-sim\assets\sfx\eat.wav' $s

# step: tiny soft tick
$s = New-Object 'System.Collections.Generic.List[double]'
for ($i = 0; $i -lt [int]($rate * 0.04); $i++) {
    $t = $i / $rate
    $env = [Math]::Exp(-90.0 * $t)
    $s.Add(($rand.NextDouble() * 2 - 1) * 0.35 * $env)
}
Write-Wav 'C:\colony-sim\assets\sfx\step.wav' $s

# bow: string twang (fast pitch drop)
$s = New-Object 'System.Collections.Generic.List[double]'
for ($i = 0; $i -lt [int]($rate * 0.16); $i++) {
    $t = $i / $rate
    $f = 520 * [Math]::Exp(-6.0 * $t) + 90
    $env = [Math]::Exp(-16.0 * $t)
    $s.Add([Math]::Sin(2 * [Math]::PI * $f * $t) * $env * 0.7)
}
Write-Wav 'C:\colony-sim\assets\sfx\bow.wav' $s

# hurt: short low grunt-ish blip
$s = New-Object 'System.Collections.Generic.List[double]'
for ($i = 0; $i -lt [int]($rate * 0.14); $i++) {
    $t = $i / $rate
    $f = 190 * [Math]::Exp(-3.0 * $t)
    $env = [Math]::Exp(-18.0 * $t)
    $v = [Math]::Sin(2 * [Math]::PI * $f * $t)
    $v = [Math]::Sign($v) * [Math]::Pow([Math]::Abs($v), 0.6)  # rougher
    $s.Add($v * $env * 0.55)
}
Write-Wav 'C:\colony-sim\assets\sfx\hurt.wav' $s

# click: tiny UI tick
$s = New-Object 'System.Collections.Generic.List[double]'
for ($i = 0; $i -lt [int]($rate * 0.03); $i++) {
    $t = $i / $rate
    $env = [Math]::Exp(-120.0 * $t)
    $s.Add([Math]::Sin(2 * [Math]::PI * 1900 * $t) * 0.4 * $env)
}
Write-Wav 'C:\colony-sim\assets\sfx\click.wav' $s

# birds_loop (day ambience, 10s): soft wind + sparse chirps
$s = New-Object 'System.Collections.Generic.List[double]'
$len = [int]($rate * 10)
$wind = 0.0
$chirps = @(1.2, 3.7, 5.1, 7.8, 9.0)
for ($i = 0; $i -lt $len; $i++) {
    $t = $i / $rate
    $wind = $wind * 0.995 + ($rand.NextDouble() * 2 - 1) * 0.005  # low-passed noise
    $v = $wind * 2.2
    foreach ($c in $chirps) {
        $dt = $t - $c
        if ($dt -ge 0 -and $dt -lt 0.14) {
            $f = 2800 + 900 * [Math]::Sin(2 * [Math]::PI * 18 * $dt)
            $v += [Math]::Sin(2 * [Math]::PI * $f * $dt) * [Math]::Sin([Math]::PI * $dt / 0.14) * 0.10
        }
    }
    $s.Add($v)
}
Write-Wav 'C:\colony-sim\assets\sfx\birds_loop.wav' $s

# crickets_loop (night ambience, 6s): wind + pulsing chirr
$s = New-Object 'System.Collections.Generic.List[double]'
$len = [int]($rate * 6)
$wind = 0.0
for ($i = 0; $i -lt $len; $i++) {
    $t = $i / $rate
    $wind = $wind * 0.995 + ($rand.NextDouble() * 2 - 1) * 0.004
    $pulse = [Math]::Max(0.0, [Math]::Sin(2 * [Math]::PI * 2.2 * $t))
    $chirr = [Math]::Sin(2 * [Math]::PI * 4100 * $t) * [Math]::Pow($pulse, 6) * 0.05
    $s.Add($wind * 2.0 + $chirr)
}
Write-Wav 'C:\colony-sim\assets\sfx\crickets_loop.wav' $s

Write-Output "saved 10 phase-12 audio files"
