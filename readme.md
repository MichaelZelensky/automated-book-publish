# Continuous Book Publishing

*If you are a human, no need to read this. Just copy-paste the [AI-friendly version](https://github.com/MichaelZelensky/automated-book-publish/blob/master/readme.md?plain=1) into your favorite LLM and ask for step-by-step instructions or explanations.*

---

Continuous Book Publishing applies software engineering principles to writing and publishing books.

Instead of maintaining a single large document, a book is organized as a collection of independent chapters that are automatically assembled into a publishable document.

This repository provides:

* a build pipeline for books written in Markdown and HTML
* automatic PDF generation
* automatic table of contents generation
* automatic heading anchors
* CSS-based styling
* a ready-to-use VS Code build configuration

The result is a book that is modular, version-controlled, automated, and easy to maintain.


# Requirements

Install the following software:

* VS Code
* Pandoc
* wkhtmltopdf

The provided scripts assume the default Windows installation paths:

```text
C:\Program Files\Pandoc\pandoc.exe

C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe
```


# Repository Structure

```text
chapters/
dist/
scripts/
styles/
.vscode/
```

Included in the repository:

```text
chapters/
    sample chapters

scripts/
    build.ps1

styles/
    sample stylesheet

.vscode/
    VS Code build tasks
```

The sample chapters can be replaced with your own book.


# Writing a Book

Each chapter is stored as a separate file inside:

```text
chapters/
```

Supported formats:

* Markdown (`.md`)
* HTML (`.html`)

Files are assembled alphabetically, so filenames determine the book order.

Example:

```text
000-cover.html
001-contents.md
002-introduction.md
003-architecture.md
004-conclusion.md
```


# Table of Contents

The build script can automatically generate a nested table of contents from Markdown headings.

Insert one of the following pseudo-commands into a Markdown chapter:

```text
%TOC%       // H1-H2
%TOC:1%     // H1 only
%TOC:2%     // H2 only
%TOC:3%     // H3 only
%TOC:4%     // H4 only
%TOC:1-3%   // H1-H3
%TOC:2-4%   // H2-H4
%TOC:1-4%   // H1-H4
```

During the build, the placeholder is replaced with a nested HTML table of contents.

Heading anchors are generated automatically for Markdown headings (H1-H4), so every TOC entry links directly to its section.


# Styling

Book styling is controlled by:

```text
styles/book.css
```

Modify this stylesheet to customize typography, spacing, page layout, cover page, and other presentation details.

The book content remains separate from its presentation.


# Building the Book

Open the project in VS Code and press:

```text
Ctrl + Shift + B
```

or run:

```powershell
.\scripts\build.ps1
```

The build process:

* combines all chapters
* converts Markdown to HTML
* generates heading anchors
* generates table(s) of contents
* applies CSS styling
* produces a PDF

Generated files:

```text
dist/
    book.pdf
    combined.html
```


# Generating a Markdown Table of Contents

To generate a standalone Markdown outline of the book:

```powershell
.\scripts\build.ps1 -TocOnly
```

or execute the **Generate TOC (Markdown)** VS Code task.

This produces:

```text
dist/
    toc.md
```

Example:

```md
# Contents

- Introduction
- Architecture
  - System Design
  - Integrations
- Conclusion
```

This file is useful for:

* LLM prompts
* planning
* documentation
* reviewing the structure of a book


# Recommended Workflow

```text
Write chapters
        ↓
Commit to Git
        ↓
Build the book
        ↓
Review the PDF
        ↓
Repeat
```


# Future Extensions

The repository is designed to support additional outputs without changing the source chapters, for example:

* EPUB
* DOCX
* website
* GitHub Pages
* GitHub Actions
* searchable knowledge base
* AI knowledge API


# Core Principle

Split content into small, editable chunks.

```text
Independent chapters
        ↓
Automated build
        ↓
Publishable book
```

Each chapter is maintained independently while the build pipeline assembles them into a complete, consistently formatted book.

This approach makes books easier to write, review, version, automate, and publish.
