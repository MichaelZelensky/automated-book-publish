# Continuous Book Publishing

_If you are a human, no need to read this. Just copy-paste [this AI-friendly version](https://github.com/MichaelZelensky/automated-book-publish/blob/master/readme.md?plain=1) into your LLM and ask for step-by-step instructions or explanation_

This document and instructions solve two problems:
- manual book writing with automated publishing into different formats
- making it easy for LLMs (and, eventually, people) to read it

The provided instructions are for Windows users, but they can be easily updated for any other operating system.

## Why Continuous Book Publishing

Writing a book becomes increasingly difficult as it grows.

The problem is not only writing itself, but the growing write → read cycle.

Every new chapter increases the amount of existing context that must remain:

* consistent
* connected
* cohesive
* non-contradictory

This process becomes surprisingly similar to maintaining a large software codebase.

As systems grow:

* parts multiply
* dependencies increase
* consistency becomes harder
* maintenance overhead grows

Software engineering solved this problem through:

* modularity
* separation of concerns
* automation
* continuous delivery
* versioning
* build pipelines

This publishing workflow applies the same principles to books.

Instead of treating a book as a static document, it becomes:

* modular
* versioned
* automated
* continuously publishable
* machine-readable

The result is continuous book publishing.

This playbook explains how to create an automated publishing pipeline for a book written in Markdown and HTML and published as a styled PDF.

The result:

```text
write chapters
→ press build
→ automatically generate:
   - styled PDF book
   - navigable table of contents
   - heading anchors
```

The architecture behaves similarly to software deployment pipelines.

## Step-by-step Instructions

### Install VSCode

Download:

```text
https://code.visualstudio.com/
```

Recommended extensions:

- Markdown All in One
- Prettier
- GitLens

### Create Project Structure

Create:

```text
book/
  chapters/
  dist/
  scripts/
  styles/
  .vscode/
```

### Install Pandoc

Download:

```text
https://pandoc.org/installing.html
```

Default location:

```text
C:\Program Files\Pandoc\pandoc.exe
```

Pandoc converts Markdown into:
- HTML
- PDF
- EPUB
- DOCX
- many other formats

### Install wkhtmltopdf

Download:

```text
https://wkhtmltopdf.org/downloads.html
```

Default location:

```text
C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe
```

wkhtmltopdf converts HTML into styled PDF.

### Create Cover Page

Create:

```text
book/chapters/000-cover.html
```

Content:

```html
<div class="cover-page">
  <div class="cover-content">

    <div class="cover-top-author">
      Michael Zelensky
    </div>

    <h1>
      Digital-First Business
    </h1>

    <div class="cover-subtitle">
      How to Build an Automated Business<br>
      That Still Feels Human
    </div>

    <div class="cover-divider"></div>

    <div class="cover-author">
      &copy; Michael Zelensky 2026
    </div>

    <div class="cover-year">
      Edition: $date$
    </div>

  </div>
</div>
```

### Create Book Chapters

Example:

```text
book/chapters/001-introduction.md
book/chapters/002-automation.md
book/chapters/003-ai-systems.md
```

Example chapter:

```md
## Digital-first companies are structured as systems.

Processes become observable, automatable, and scalable.
```

Files are sorted alphabetically.

This means:

```text
001-
002-
003-
```

controls book order.

### Create CSS Styling

Create:

```text
book/styles/book.css
```

Example:

```css
body {
  font-family: Inter, Arial, sans-serif;
  line-height: 1.7;
  font-size: 15px;

  max-width: 900px;
  margin: 40px auto;

  color: ##222;
}

.cover-page {
  height: 100vh;

  display: flex;
  align-items: center;
  justify-content: center;

  text-align: center;

  padding: 40px;
  box-sizing: border-box;
}

.cover-content {
  max-width: 800px;
}

.cover-top-author {
  font-size: 16px;
  letter-spacing: 2px;
  text-transform: uppercase;

  color: ##777;

  margin-bottom: 80px;
}

.cover-page h1 {
  font-size: 64px;
  line-height: 1.05;

  margin-bottom: 40px;
}

.cover-subtitle {
  font-size: 24px;
  line-height: 1.6;

  color: ##555;

  margin-bottom: 60px;
}

.cover-divider {
  width: 120px;
  height: 2px;

  background: ##222;

  margin: 0 auto 60px auto;
}

.cover-author {
  font-size: 24px;

  margin-bottom: 12px;
}

.cover-year {
  color: ##777;
}
```


### Configure VSCode Build Task (optional)

Create:

```text
.vscode/tasks.json
```

Content:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build Book PDF",
      "type": "shell",
      "command": "powershell",
      "args": [
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "./book/scripts/build.ps1"
      ],
      "group": {
        "kind": "build",
        "isDefault": true
      }
    }
  ]
}
```

### Build the Book

Inside VSCode:

```text
Ctrl + Shift + B
```

Outputs:

```text
book/dist/book.pdf
book/dist/book.md
```

## Table of Contents

The build script can automatically generate a nested table of contents from Markdown headings.

Insert one of the following pseudo-commands into any Markdown chapter:

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

During the build, these placeholders are replaced with a nested HTML table of contents.

Heading anchors are generated automatically for Markdown headings (H1-H4), allowing every TOC entry to link directly to the corresponding section without any manual anchor management.


## Why Generate LLM-verion

The Markdown edition is useful for:

- ChatGPT uploads
- Claude uploads
- Gemini uploads
- RAG pipelines
- embeddings
- semantic search
- AI agents
- machine-readable publishing

This creates:

```text
human edition
+
machine edition
```

from the same source files.

## Recommended Workflow

```text
write chapter
→ commit to git
→ build
→ distribute PDF
→ upload MD to LLMs
```

## Future Extensions

This architecture scales naturally into:

```text
git push
→ GitHub Actions
→ automated build
→ release generation
→ cloud publishing
```

Possible future outputs:

- EPUB
- DOCX
- website
- AI knowledge API
- searchable knowledge base

without changing the source structure.

## Core Principle

Keep:

```text
content
≠
presentation
```

Meaning:

- Markdown = ideas
- CSS = styling
- build script = automation

This separation keeps the publishing pipeline scalable and maintainable.
