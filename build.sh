#!/usr/bin/env sh

mkdir build
lualatex --output-directory=build --shell-escape resume.tex
