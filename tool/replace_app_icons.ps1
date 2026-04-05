Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $root 'Green bio care sales icon.png'

if (!(Test-Path $sourcePath)) {
  throw "Source icon not found: $sourcePath"
}

$targets = @(
  @{ Path='android/app/src/main/res/mipmap-mdpi/ic_launcher.png'; Size=48 },
  @{ Path='android/app/src/main/res/mipmap-hdpi/ic_launcher.png'; Size=72 },
  @{ Path='android/app/src/main/res/mipmap-xhdpi/ic_launcher.png'; Size=96 },
  @{ Path='android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png'; Size=144 },
  @{ Path='android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png'; Size=192 },
  @{ Path='ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png'; Size=20 },
  @{ Path='ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png'; Size=40 },
  @{ Path='ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png'; Size=60 },
  @{ Path='ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png'; Size=29 },
  @{ Path='ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png'; Size=58 },
  @{ Path='ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png'; Size=87 },
  @{ Path='ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png'; Size=40 },
  @{ Path='ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png'; Size=80 },
  @{ Path='ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png'; Size=120 },
  @{ Path='ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png'; Size=120 },
  @{ Path='ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png'; Size=180 },
  @{ Path='ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png'; Size=76 },
  @{ Path='ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png'; Size=152 },
  @{ Path='ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png'; Size=167 },
  @{ Path='ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png'; Size=1024 }
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
