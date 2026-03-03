Add-Type -AssemblyName System.Drawing

$workspaceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$jsonPath = Join-Path $workspaceRoot "posts\places\posts-places.json"

if (-not (Test-Path $jsonPath)) {
    throw "Could not find JSON file at $jsonPath"
}

$posts = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json

function Save-Jpeg {
    param(
        [Parameter(Mandatory = $true)] [System.Drawing.Bitmap] $Bitmap,
        [Parameter(Mandatory = $true)] [string] $OutputPath,
        [int] $Quality = 92
    )

    $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
        Where-Object { $_.FormatID -eq [System.Drawing.Imaging.ImageFormat]::Jpeg.Guid }

    $encoderParameters = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $encoderParameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
        [System.Drawing.Imaging.Encoder]::Quality,
        [long]$Quality
    )

    $Bitmap.Save($OutputPath, $jpegCodec, $encoderParameters)
    $encoderParameters.Dispose()
}

function Get-VibeColors {
    param([string] $Vibe)

    switch ($Vibe.ToLowerInvariant()) {
        "hipster"      { return @{ Start = "#162824"; End = "#2E5A4F"; Accent = "#C6A76E" } }
        "chill"        { return @{ Start = "#1F3A34"; End = "#3F7868"; Accent = "#E8DCC5" } }
        "artsy"        { return @{ Start = "#0F1C1A"; End = "#2E5A4F"; Accent = "#B88A5A" } }
        "romantic"     { return @{ Start = "#162824"; End = "#3F7868"; Accent = "#E8DCC5" } }
        "energetic"    { return @{ Start = "#0F1C1A"; End = "#2E5A4F"; Accent = "#C6A76E" } }
        "family"       { return @{ Start = "#1F3A34"; End = "#2E5A4F"; Accent = "#E8DCC5" } }
        "adventurous"  { return @{ Start = "#0F1C1A"; End = "#1F3A34"; Accent = "#C6A76E" } }
        "cozy"         { return @{ Start = "#162824"; End = "#2E5A4F"; Accent = "#B88A5A" } }
        "party"        { return @{ Start = "#0F1C1A"; End = "#3F7868"; Accent = "#C6A76E" } }
        default         { return @{ Start = "#0F1C1A"; End = "#2E5A4F"; Accent = "#C6A76E" } }
    }
}

$imageWidth = 1600
$imageHeight = 1000
$randomSeed = 20260303
$randomGenerator = New-Object System.Random($randomSeed)

$generatedCount = 0

foreach ($post in $posts) {
    if (-not $post.images -or $post.images.Count -eq 0) {
        continue
    }

    $relativeImagePath = [string]$post.images[0]
    if ([string]::IsNullOrWhiteSpace($relativeImagePath)) {
        continue
    }

    $normalizedRelativePath = $relativeImagePath -replace '/', '\\'
    $absoluteImagePath = Join-Path $workspaceRoot $normalizedRelativePath
    $absoluteDirectoryPath = Split-Path -Parent $absoluteImagePath

    if (-not (Test-Path $absoluteDirectoryPath)) {
        New-Item -ItemType Directory -Path $absoluteDirectoryPath -Force | Out-Null
    }

    $palette = Get-VibeColors -Vibe ([string]$post.vibe)

    $startColor = [System.Drawing.ColorTranslator]::FromHtml($palette.Start)
    $endColor = [System.Drawing.ColorTranslator]::FromHtml($palette.End)
    $accentColor = [System.Drawing.ColorTranslator]::FromHtml($palette.Accent)
    $creamColor = [System.Drawing.ColorTranslator]::FromHtml("#E8DCC5")
    $sparkleColor = [System.Drawing.ColorTranslator]::FromHtml("#F8F3E7")

    $bitmap = New-Object System.Drawing.Bitmap($imageWidth, $imageHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    try {
        $fullRect = New-Object System.Drawing.Rectangle(0, 0, $imageWidth, $imageHeight)

        $backgroundBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            $fullRect,
            $startColor,
            $endColor,
            [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
        )
        $graphics.FillRectangle($backgroundBrush, $fullRect)
        $backgroundBrush.Dispose()

        for ($index = 0; $index -lt 9; $index++) {
            $ellipseWidth = $randomGenerator.Next(220, 620)
            $ellipseHeight = $randomGenerator.Next(160, 520)
            $ellipseX = $randomGenerator.Next(-180, $imageWidth - 40)
            $ellipseY = $randomGenerator.Next(-120, $imageHeight - 20)
            $alpha = $randomGenerator.Next(20, 58)

            $glowColor = [System.Drawing.Color]::FromArgb($alpha, $accentColor)
            $glowBrush = New-Object System.Drawing.SolidBrush($glowColor)
            $graphics.FillEllipse($glowBrush, $ellipseX, $ellipseY, $ellipseWidth, $ellipseHeight)
            $glowBrush.Dispose()
        }

        $vignetteBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            (New-Object System.Drawing.Point(0, 0)),
            (New-Object System.Drawing.Point(0, $imageHeight)),
            [System.Drawing.Color]::FromArgb(0, 0, 0, 0),
            [System.Drawing.Color]::FromArgb(130, 0, 0, 0)
        )
        $graphics.FillRectangle($vignetteBrush, $fullRect)
        $vignetteBrush.Dispose()

        for ($sparkleIndex = 0; $sparkleIndex -lt 180; $sparkleIndex++) {
            $sparkleX = $randomGenerator.Next(20, $imageWidth - 20)
            $sparkleY = $randomGenerator.Next(20, $imageHeight - 20)
            $sparkleRadius = $randomGenerator.Next(1, 4)
            $sparkleAlpha = $randomGenerator.Next(70, 190)

            $smallSparkleColor = [System.Drawing.Color]::FromArgb($sparkleAlpha, $sparkleColor)
            $smallSparkleBrush = New-Object System.Drawing.SolidBrush($smallSparkleColor)
            $graphics.FillEllipse($smallSparkleBrush, $sparkleX, $sparkleY, $sparkleRadius, $sparkleRadius)
            $smallSparkleBrush.Dispose()
        }

        $titleText = [string]$post.place
        if ([string]::IsNullOrWhiteSpace($titleText)) {
            $titleText = [string]$post.title
        }
        $subtitleText = "{0} • {1} vibe" -f ([string]$post.city), ([string]$post.vibe)

        $titleFont = New-Object System.Drawing.Font("Georgia", 58, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $subtitleFont = New-Object System.Drawing.Font("Segoe UI", 28, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)

        $titleBrush = New-Object System.Drawing.SolidBrush($creamColor)
        $subtitleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(232, 220, 197))
        $accentPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(210, $accentColor), 4)

        $leftMargin = 96
        $titleTop = $imageHeight - 270
        $subtitleTop = $imageHeight - 170

        $graphics.DrawLine($accentPen, $leftMargin, $imageHeight - 300, $leftMargin + 180, $imageHeight - 300)
        $graphics.DrawString($titleText, $titleFont, $titleBrush, $leftMargin, $titleTop)
        $graphics.DrawString($subtitleText, $subtitleFont, $subtitleBrush, $leftMargin, $subtitleTop)

        $titleFont.Dispose()
        $subtitleFont.Dispose()
        $titleBrush.Dispose()
        $subtitleBrush.Dispose()
        $accentPen.Dispose()

        Save-Jpeg -Bitmap $bitmap -OutputPath $absoluteImagePath -Quality 92
        $generatedCount++
        Write-Host "Generated: $relativeImagePath"
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

Write-Host "Done. Generated $generatedCount images."