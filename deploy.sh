#!/bin/bash
hugo -b "https://peng.guru/"
git add -A .
git commit -m "$1"
git push