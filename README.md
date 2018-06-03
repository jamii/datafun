# Overview

[latexrun]: https://github.com/aclements/latexrun

rntztex is a collection of tools I (Michael Arntzenius) use for my LaTeX
projects. It contains:

1. A Makefile for LaTeX projects that's short and fairly generic. It uses Austin
   Clements' wonderful [latexrun][] tool, which is included; no installation
   necessary.

2. `rntz.cls`, a document class based on `extarticle` with some formatting
   changes. Most notably, it puts section numbers into the left-margin.

3. `rntzfont.sty`, which chooses between some nice font combinations.

4. `rntzgeometry.sty`, which sets margins etc. appropriately for common paper
   sizes.

5. `narrow.sty`, which sets up a one-column layout with extra width for
   `figure*` and `fullwidth` environments. `rntzgeometry.sty` uses `narrow.sty`
   automatically, but you can also use `narrow.sty` on its own.

# Using rntztex

The easiest way to use this repo is to clone or copy it, put some `.tex` files
in it, and run `make`. That's all it takes!

Alternatively, you can keep rntztex in its own directory. This keeps your work
separate from mine, and lets you update rntztex easily. In this case, you should
copy the included `Makefile` to your source directory and update its
`RNTZTEXDIR` variable to contain the path to rntztex.

If you use git, you could use rntztex as a submodule, but submodules are a bit
complicated and beyond the scope of this README. Good luck!

# Licensing

This repo is currently MIT-licensed; see LICENSE.txt. If you want to reuse my
code but you're worried about licensing issues, send me an email or a pull
request; I want this to be useful to as many people as possible.

# Files

## Makefile

Should be fairly self-documenting. Let me know if you have any trouble with it.
Useful targets:

- `make all`: Makes PDFs for every `.tex` file in its directory. Does not look
  in subdirectories.

- `make watch`: Watches for changes and recompiles on-the-fly. Uses
  `inotifywait`, which is in the `inotify-tools` package on Ubuntu.

- `make foo.pdf`: Makes a PDF from `foo.tex`.

- `make foo-book.pdf`: Makes a zine-style "booklet" from a regular PDF. For
  example, if `foo.pdf` is formatted for A5 paper, `foo-book.pdf` will be A4,
  with two pages per side. You can print it out, cut or fold down the middle,
  and staple the pages together.

- `make clean`: Runs `latexrun --clean-all` and also removes `latex.out` (where
  `latexrun` stores intermediate files).

## example.tex

A simple example document showing off `rntz.cls`, `rntzgeometry.sty`, and
`rntzfont.sty`.

## rntz.cls

Based on extarticle, and supports most of its options. Notable differences:

1. Section & sub-section numbers go into the left margin.
2. Sections & sub-sections headings are smaller.
3. Sub-sub-sections are un-numbered; I use them sparingly if at all.
4. Redefines `\maketitle` and the `abstract` environment.

It also has a somewhat random grab-bag of other features I happen to use:

5. Requires and configures hyperref, url, and cleveref.

6. Requires amsmath & amsthm, and defines theorem, conjecture, lemma,
definition, and corollary environments. It sets them to share a single running
counter.

7. Defines some colors, taken from acmart.cls:
ACM{Blue,Yellow,Orange,Red,LightBlue,DarkBlue,Green,Purple}.

## rntzgeometry.sty

Sets the page geometry to have "reasonable" margins. It uses `narrow.sty` to
produce a single column of text; the `figure*` and `fullwidth` environments
expand to a larger width.

**Options**:

- `a5`, `b5`, `a4`, `letter`: Paper size. Default is b5.

- `width=LEN`: Width of the main text column. Default is 345pt.

- `fullwidth=LEN`: Width for `figure*` and `fullwidth` environments. Default
  varies by paper size.

## rntzfont.sty

This chooses from a set of paired text & math fonts, with appropriate scalings
and line spacings. The options are:

- `charter` for [Bitstream Charter][charter] with [Euler][]. Charter is a
  legible, no-nonsense font that displays well both on screen and in print.

- `cochineal` for [Cochineal][] with [Euler][]. Cochineal is an old-style font,
   very pleasant in print.

- `cm` for Computer Modern, which is TeX's default, but I've increased the line
  spacing. I dislike Computer Modern; I find it almost unreadable on screen.

- `libertine` for [Linux Libertine][Libertine] with [newtxmath][]. Libertine
  imitates Times New Roman. It's tolerable.

- `palatino` for [Palatino][] with [Euler][]. Both fonts are designed by Hermann
  Zapf, and match nicely.

- `pt` for [PT Serif][pt] with [newtxmath][]. PT Serif is quite readable on
  screen.

- `pteuler` for [PT Serif][pt] with [Euler][]. To match x-heights, PT Serif is
  scaled down.

The default is `palatino`.

[Cochineal]: https://ctan.org/pkg/cochineal
[Euler]: https://ctan.org/pkg/eulervm
[Libertine]: https://ctan.org/pkg/libertine
[Palatino]: https://ctan.org/pkg/newpx
[charter]: https://ctan.org/pkg/charter
[newtxmath]: https://ctan.org/pkg/newtx
[pt]: https://ctan.org/pkg/paratype

## narrow.sty

This sets your body text in a single narrow column, but defines a `fullwidth`
environment that expands to "full width". It redefines `figure*` to use full
width as well.

**Options**:

- `width=LEN`: The width of the main text column. Default 345pt.

- `fullwidth=LEN`: The width for `figure*` and `fullwidth` environments. Default
  is `\textwidth`, i.e. the width the text *would have been* before you loaded
  `narrow.sty`.
