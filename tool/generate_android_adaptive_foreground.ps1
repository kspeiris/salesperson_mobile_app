Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $root 'Green bio care sales icon.png'

if (!(Test-Path $sourcePath)) {
  throw "Source icon not found: $sourcePath"
}

$targets = @(
  @{ Path='android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png'; Size=108 },
  @{ Path='android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png'; Size=162 },
  @{ Path='android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png'; Size=216 },
  @{ Path='android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png'; Size=324 },
  @{ Path='android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png'; Size=432 }
)

$source = [System.Drawing.Image]::FromFile($sourcePath)
try {
  foreach ($target in $targets) {
    $size = [int]$target.Size
    $bitmap = New-Object System.Drawing.Bitmap($size, $size)
    try {
      $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
      try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.DrawImage($source, 0, 0, $size, $size)
      }
      finally {
        $graphics.Dispose()
      }

      $targetPath = Join-Path $root $target.Path
      $bitmap.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
      $bitmap.Dispose()
    }
  }
}
finally {
  $source.Dispose()
}
