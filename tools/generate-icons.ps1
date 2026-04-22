Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutDir = Join-Path (Split-Path -Parent $ScriptDir) 'icons'
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

function New-SnowflakeIcon {
    param(
        [int]$Size,
        [string]$Path,
        [double]$ContentScale = 0.82
    )

    $bmp = [System.Drawing.Bitmap]::new($Size, $Size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

    $cx = [float]($Size / 2.0)
    $cy = [float]($Size / 2.0)

    # Background: radial-like gradient using PathGradientBrush
    $bgPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $bgPath.AddEllipse([float](-$Size * 0.2), [float](-$Size * 0.2), [float]($Size * 1.4), [float]($Size * 1.4))
    $bgBrush = [System.Drawing.Drawing2D.PathGradientBrush]::new($bgPath)
    $bgBrush.CenterPoint = [System.Drawing.PointF]::new($cx, [float]($cy - $Size * 0.1))
    $bgBrush.CenterColor = [System.Drawing.Color]::FromArgb(255, 36, 58, 110)
    $bgBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(255, 8, 14, 32))
    $g.FillRectangle($bgBrush, 0, 0, $Size, $Size)
    $bgBrush.Dispose()
    $bgPath.Dispose()

    # Subtle stars scattered in background (upper half)
    $rand = [System.Random]::new(42)
    $starBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(140, 255, 255, 220))
    for ($i = 0; $i -lt 14; $i++) {
        $sx = $rand.NextDouble() * $Size
        $sy = $rand.NextDouble() * $Size * 0.55
        $sr = ($Size / 420.0) * (1 + $rand.NextDouble() * 1.5)
        $g.FillEllipse($starBrush, [float]($sx - $sr), [float]($sy - $sr), [float]($sr * 2), [float]($sr * 2))
    }
    $starBrush.Dispose()

    # Snowflake geometry
    $arm = ($Size / 2.0) * $ContentScale
    $lineWidth = [float]($Size / 44.0)
    $branchWidth = [float]($Size / 56.0)

    $penMain = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 240, 250, 255), $lineWidth)
    $penMain.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $penMain.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    $penBranch = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 220, 235, 255), $branchWidth)
    $penBranch.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $penBranch.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    # Soft glow halo behind snowflake
    $haloPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $haloR = $arm * 0.95
    $haloPath.AddEllipse([float]($cx - $haloR), [float]($cy - $haloR), [float]($haloR * 2), [float]($haloR * 2))
    $haloBrush = [System.Drawing.Drawing2D.PathGradientBrush]::new($haloPath)
    $haloBrush.CenterPoint = [System.Drawing.PointF]::new($cx, $cy)
    $haloBrush.CenterColor = [System.Drawing.Color]::FromArgb(70, 170, 210, 255)
    $haloBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 170, 210, 255))
    $g.FillPath($haloBrush, $haloPath)
    $haloBrush.Dispose()
    $haloPath.Dispose()

    # Draw 6 arms with branches
    for ($i = 0; $i -lt 6; $i++) {
        $angle = $i * [Math]::PI / 3
        $ax = [float]($cx + [Math]::Cos($angle) * $arm)
        $ay = [float]($cy + [Math]::Sin($angle) * $arm)
        $g.DrawLine($penMain, $cx, $cy, $ax, $ay)

        foreach ($frac in @(0.42, 0.68)) {
            $bx = [float]($cx + [Math]::Cos($angle) * $arm * $frac)
            $by = [float]($cy + [Math]::Sin($angle) * $arm * $frac)
            $branchLen = if ($frac -lt 0.5) { $arm * 0.28 } else { $arm * 0.20 }
            foreach ($off in @(-60, 60)) {
                $br = $angle + [Math]::PI * $off / 180.0
                $bex = [float]($bx + [Math]::Cos($br) * $branchLen)
                $bey = [float]($by + [Math]::Sin($br) * $branchLen)
                $g.DrawLine($penBranch, $bx, $by, $bex, $bey)
            }
        }

        # Tip ornament dot
        $tr = [float]($Size / 70.0)
        $tipBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
        $g.FillEllipse($tipBrush, [float]($ax - $tr), [float]($ay - $tr), [float]($tr * 2), [float]($tr * 2))
        $tipBrush.Dispose()
    }

    # Center hexagon + bright core
    $hexPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $hexR = $Size / 22.0
    $hexPoints = New-Object 'System.Drawing.PointF[]' 6
    for ($j = 0; $j -lt 6; $j++) {
        $ha = $j * [Math]::PI / 3
        $hexPoints[$j] = [System.Drawing.PointF]::new(
            [float]($cx + [Math]::Cos($ha) * $hexR),
            [float]($cy + [Math]::Sin($ha) * $hexR)
        )
    }
    $hexPath.AddPolygon($hexPoints)
    $hexFill = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 200, 230, 255))
    $g.FillPath($hexFill, $hexPath)
    $hexFill.Dispose()
    $hexPath.Dispose()

    $coreBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
    $cr = [float]($Size / 38.0)
    $g.FillEllipse($coreBrush, [float]($cx - $cr), [float]($cy - $cr), [float]($cr * 2), [float]($cr * 2))
    $coreBrush.Dispose()

    $penMain.Dispose()
    $penBranch.Dispose()

    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)

    $g.Dispose()
    $bmp.Dispose()
    Write-Host "  wrote $Path"
}

Write-Host "Generating icons into $OutDir"

New-SnowflakeIcon -Size 192 -Path (Join-Path $OutDir 'icon-192.png') -ContentScale 0.82
New-SnowflakeIcon -Size 512 -Path (Join-Path $OutDir 'icon-512.png') -ContentScale 0.82
New-SnowflakeIcon -Size 192 -Path (Join-Path $OutDir 'icon-192-maskable.png') -ContentScale 0.64
New-SnowflakeIcon -Size 512 -Path (Join-Path $OutDir 'icon-512-maskable.png') -ContentScale 0.64
New-SnowflakeIcon -Size 180 -Path (Join-Path $OutDir 'apple-touch-icon.png') -ContentScale 0.82
New-SnowflakeIcon -Size 32 -Path (Join-Path $OutDir 'favicon-32.png') -ContentScale 0.88

Write-Host "Done."
