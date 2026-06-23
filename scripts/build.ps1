$ErrorActionPreference = "Stop"

$bookRoot = "book"

$outputDirectory = "$bookRoot/dist"
$tempFile = "$outputDirectory/combined.html"
$outputFile = "$outputDirectory/book.pdf"

$contentFiles = Get-ChildItem `
  "$bookRoot/chapters/*" `
  | Where-Object {
      $_.Extension -in @(".md", ".html")
    } `
  | Sort-Object Name

New-Item `
  -ItemType Directory `
  -Force `
  -Path $outputDirectory `
  | Out-Null

$combinedContent = @()

$combinedContent += '<meta charset="UTF-8">'
$combinedContent += ""

foreach ($file in $contentFiles) {

  if ($file.Extension -eq ".md") {

    $html = & "C:\Program Files\Pandoc\pandoc.exe" `
      $file.FullName `
      -f markdown `
      -t html

    $combinedContent += $html
  }
  else {
    $combinedContent += Get-Content $file.FullName
  }

  $combinedContent += ""
  $combinedContent += '<div style="page-break-after: always;"></div>'
  $combinedContent += ""
}

$currentDate = Get-Date

$currentDateFormatted = $currentDate.ToString(
  "yyyy, MMMM dd",
  [System.Globalization.CultureInfo]::InvariantCulture
)

$combinedContent = $combinedContent -replace '\$date\$', $currentDateFormatted

$combinedContent | Set-Content $tempFile -Encoding UTF8

& "C:\Program Files\Pandoc\pandoc.exe" `
  $tempFile `
  --css="$bookRoot/styles/book.css" `
  --standalone `
  --metadata charset=utf-8 `
  --pdf-engine="C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe" `
  -o $outputFile

Write-Host "Book built: $outputFile"