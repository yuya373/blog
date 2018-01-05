#!/bin/bash -eu
hugo
git add .
git commit -m "generated at: `date +\"%Y%m%d-%H%M%S\"`"


