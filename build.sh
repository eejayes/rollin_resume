#!/usr/bin/env sh

config_file="${1:-config-default}"

mkdir build
lualatex --output-directory=build --shell-escape "\def\configfile{"$config_file"} \input{resume}"
