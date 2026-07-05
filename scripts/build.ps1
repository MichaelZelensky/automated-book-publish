<#
BOOK GENERATION SCRIPT

Purpose:
- Builds a single HTML book from ordered chapter files
- Supports Markdown + HTML chapters
- Extracts Markdown headings (H1-H4)
- Builds nested Table of Contents
- Injects anchors into headings for correct linking
- Generates a styled PDF or a Markdown table of contents

Pseudo-commands:
- %TOC%       → H1-H2
- %TOC:N%     → heading level N only (e.g. %TOC:2%)
- %TOC:A-B%   → heading levels A through B (e.g. %TOC:1-3%)

Options:
- -TocOnly    → generate dist/toc.md and exit

Input:
- chapters/*.md
- chapters/*.html

Output:
- dist/book.pdf
- dist/combined.html
- dist/toc.md (with -TocOnly)

#>

param(
    [switch]$TocOnly
)

$ErrorActionPreference = "Stop"

$bookRoot = "."

$outputDirectory = "$bookRoot/dist"
$tempFile = "$outputDirectory/combined.html"
$outputFile = "$outputDirectory/book.pdf"
$tocMarkdownFile = "$outputDirectory/toc.md"

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

    if ($line -match '^(#{1,4})\s+(.+)$') {

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
  param (
    [array]$headings,
    [int]$minLevel = 1,
    [int]$maxLevel = 4
  )

  $filtered = $headings | Where-Object {
    $_.Level -ge $minLevel -and $_.Level -le $maxLevel
  }

  $toc = @()
  $toc += '<section class="book-contents">'
  $toc += '<h1>Contents</h1>'
  $toc += '<ul>'

  $currentLevel = $minLevel

  foreach ($h in $filtered) {

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

  while ($currentLevel -gt $minLevel) {
    $toc += '</ul>'
    $currentLevel--
  }

  $toc += '</ul>'
  $toc += '</section>'

  return $toc -join "`n"
}

$buildMarkdownTOC = {
  param(
    [array]$headings,
    [int]$minLevel = 1,
    [int]$maxLevel = 4
  )

  $filtered = $headings | Where-Object {
    $_.Level -ge $minLevel -and $_.Level -le $maxLevel
  }

  $toc = @()
  $toc += "# Contents"
  $toc += ""

  foreach ($h in $filtered) {

    $indent = "  " * ($h.Level - $minLevel)

    $toc += "$indent- $($h.Text)"
  }

  return $toc -join "`r`n"
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

if ($TocOnly) {

    $tocMarkdown = & $buildMarkdownTOC $allHeadings 1 4

    Set-Content `
        -Path $tocMarkdownFile `
        -Value $tocMarkdown `
        -Encoding UTF8

    Write-Host "TOC written: $tocMarkdownFile"

    return
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
  $raw = [regex]::Replace(
    $raw,
    '%TOC(?::(\d)(?:-(\d))?)?%',
    {
      param($match)

      if (-not $match.Groups[1].Success) {
        return & $buildTOC $allHeadings 1 4
      }

      $minLevel = [int]$match.Groups[1].Value

      if ($match.Groups[2].Success) {
        $maxLevel = [int]$match.Groups[2].Value
      }
      else {
        $maxLevel = $minLevel
      }

      return & $buildTOC $allHeadings $minLevel $maxLevel
    }
  )

  # Markdown processing
  if ($chapter.File.Extension -eq ".md") {

    foreach ($h in $allHeadings) {

      $escaped = [regex]::Escape($h.Text)

      $raw = [regex]::Replace(
        $raw,
        "^(#{1,4})\s+$escaped\s*$",
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