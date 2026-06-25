<#
BOOK GENERATION SCRIPT

Purpose:
- Builds a single HTML book from ordered chapter files
- Supports Markdown + HTML chapters
- Extracts H1/H2 headings from Markdown
- Builds a NESTED Table of Contents (hierarchical)
- Injects anchors into headings for correct linking
- Supports %TOC% placeholder (e.g. toc.md)
- Outputs final PDF via wkhtmltopdf

Pseudo-commands:
- %TOC% → replaced with generated nested TOC

Input:
- book/chapters/*.md
- book/chapters/*.html

Output:
- book/dist/book.pdf
#>

$ErrorActionPreference = "Stop"

$bookRoot = "book"

$outputDirectory = "$bookRoot/dist"
$tempFile = "$outputDirectory/combined.html"
$outputFile = "$outputDirectory/book.pdf"

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

$contentFiles = Get-ChildItem "$bookRoot/chapters/*" |
  Where-Object { $_.Extension -in @(".md", ".html") } |
  Sort-Object Name

# -------------------------
# HELPERS
# -------------------------

$convertFileNameToAnchor = {
  param ([string]$fileName)

  $name = [System.IO.Path]::GetFileNameWithoutExtension($fileName)

  $anchor = $name `
    -replace '^\d+[-_]*', '' `
    -replace '[^a-zA-Z0-9\-]', '-' `
    -replace '\s+', '-'

  return $anchor.ToLowerInvariant()
}

$extractMarkdownHeadings = {
  param ([string]$content, [string]$fileAnchor)

  $lines = $content -split "`n"

  $headings = @()
  $i = 0

  foreach ($line in $lines) {

    if ($line -match '^(#{1,2})\s+(.+)$') {

      $level = $matches[1].Length
      $text = $matches[2].Trim()

      $slug = ($text `
        -replace '[^a-zA-Z0-9\s-]', '' `
        -replace '\s+', '-' `
        -replace '-+', '-').ToLowerInvariant()

      $headings += [PSCustomObject]@{
        Level  = $level
        Text   = $text
        Anchor = "$fileAnchor-$i-$slug"
      }

      $i++
    }
  }

  return $headings
}

# -------------------------
# NESTED TOC BUILDER
# -------------------------

$buildTOC = {
  param ([array]$headings)

  $toc = @()
  $toc += '<section class="book-contents">'
  $toc += '<h1>Contents</h1>'
  $toc += '<ul>'

  $currentLevel = 1

  foreach ($h in $headings) {

    while ($h.Level -gt $currentLevel) {
      $toc += '<ul>'
      $currentLevel++
    }

    while ($h.Level -lt $currentLevel) {
      $toc += '</ul>'
      $currentLevel--
    }

    $toc += "  <li><a href=""#$($h.Anchor)"">$($h.Text)</a></li>"
  }

  while ($currentLevel -gt 1) {
    $toc += '</ul>'
    $currentLevel--
  }

  $toc += '</ul>'
  $toc += '</section>'

  return $toc -join "`n"
}

# -------------------------
# PHASE 1: COLLECT HEADINGS
# -------------------------

$chapterData = @()
$allHeadings = @()

foreach ($file in $contentFiles) {

  $anchor = & $convertFileNameToAnchor $file.Name
  $raw = Get-Content $file.FullName -Raw -Encoding UTF8

  if ($file.Extension -eq ".md") {
    $headings = & $extractMarkdownHeadings $raw $anchor
    $allHeadings += $headings
  }

  $chapterData += [PSCustomObject]@{
    File    = $file
    Anchor  = $anchor
    Content = $raw
  }
}

# Build TOC once
$tocHtml = & $buildTOC $allHeadings

# -------------------------
# PHASE 2: BUILD OUTPUT
# -------------------------

$combined = @()
$combined += '<meta charset="UTF-8">'
$combined += ''

foreach ($chapter in $chapterData) {

  $raw = $chapter.Content

  # Inject TOC
  if ($raw -match '%TOC%') {
    $raw = $raw -replace '%TOC%', $tocHtml
  }

  # Markdown processing
  if ($chapter.File.Extension -eq ".md") {

    foreach ($h in $allHeadings) {

      $escaped = [regex]::Escape($h.Text)

      $raw = [regex]::Replace(
        $raw,
        "^(#{1,2})\s+$escaped\s*$",
        "`$1 $($h.Text) {#$($h.Anchor)}",
        [System.Text.RegularExpressions.RegexOptions]::Multiline
      )
    }

    $tempMd = "$outputDirectory/tmp.md"
    $tempHtml = "$outputDirectory/tmp.html"

    Set-Content -Path $tempMd -Value $raw -Encoding UTF8

    & "C:\Program Files\Pandoc\pandoc.exe" `
      $tempMd `
      -f markdown `
      -t html `
      -o $tempHtml

    $combined += Get-Content $tempHtml -Encoding UTF8

    Remove-Item $tempMd -Force
    Remove-Item $tempHtml -Force
  }
  else {
    $combined += $raw
  }

  $combined += "</section>"
  $combined += '<div style="page-break-after: always;"></div>'
}

$currentDate = Get-Date
$currentDateFormatted = $currentDate.ToString(
  "yyyy, MMMM dd",
  [System.Globalization.CultureInfo]::InvariantCulture
)
$combined = $combined -replace '\$date\$', $currentDateFormatted

# -------------------------
# FINAL OUTPUT
# -------------------------

[System.IO.File]::WriteAllLines(
  $tempFile,
  $combined,
  [System.Text.UTF8Encoding]::new($false)
)

& "C:\Program Files\Pandoc\pandoc.exe" `
  $tempFile `
  --css="$bookRoot/styles/book.css" `
  --standalone `
  --pdf-engine="C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe" `
  -o $outputFile

Write-Host "Book built: $outputFile"