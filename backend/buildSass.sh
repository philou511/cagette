#!/bin/sh

for dir in ../www/theme/*/; do
    sass $dir/css/style.scss $dir/css/style.css
    sass --style=compressed $dir/css/style.scss $dir/css/style.min.css
done