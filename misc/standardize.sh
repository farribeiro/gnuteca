#!/bin/bash
#
# Authors: Alexande H. Schmidt && Vilson C. Gärtner
# Date: April/07/2008
#
# Purpose: Use this script to standardize written code to be in compliance with Solis development standards and PHP 5 standards.
# What it does:
# - Converts function an variable names to lowercase (firs letter only)
# - Converts function call's first letter to lowercase (dynamic and static for MIOLO::)
# - Converts "var" instructions to public
# - Adds public on functions without visibility information
# - Converts file names: .inc -> .inc.php ; .class -> .class.php

# Convert function names to lowercase (firs letter)
echo -n "Converting function names... "
for i in $(find -name \*.php -exec grep "^ *\(public\|private\|\) *\(static\|\) function [A-Z][a-z]" {} -rl \;); do sed -i "s/function \([A-Z]\)\([a-z]\)/function \l\1\2/" $i; done
echo "done."

# Convert method invocations' first letter to lowercase (object)
echo -n "Converting method invocations... "
for i in $(find -name \*.php -exec grep "\->[A-Z][a-z]" {} -l \;); do sed -i "s/\->\([A-Z][a-z]\)/->\l\1/g" $i; done
echo "done."

# Convert function call's first letter to lowercase (static)
echo -n "Converting MIOLO:: and similar static calls and wrong variable names... "
# To view what will be changed
# for i in $(find -name \*.php); do sed "s/\(\$\|::\)\([A-Z]\)\([a-z][[:alnum:]_]*\)/\1\l\2\3/g" $i > /tmp/diff.diff; if [ $(diff $i /tmp/diff.diff | wc -l) -ne 0 ]; then diff $i /tmp/diff.diff | less; fi; done
# To apply changes directly
for i in $(find -name \*.php); do sed -i "s/\(\\$\|::\)\([A-Z]\)\([a-z][[:alnum:]_]*\)/\1\l\2\3/g" $i; done
echo "done."

# Change var declarations to public
echo -n "Changing 'var' to 'public'... "
# To only see
    # for i in $(find -name \*.php); do sed "s/^\( *\)var /\1public /" $i > /tmp/out.txt; if [ $(diff $i /tmp/out.txt | wc -l) -ne 0 ]; then diff $i /tmp/out.txt | less; fi; done
# To correct
for i in $(find -name \*.php); do sed -i "s/^\( *\)var /\1public /" $i; done
echo "done."

# Add public on function without visibility information
echo -n "Adding public on functions without visibility information... "
# To see
# for i in $(find -name \*.php); do sed "s/^\( *\)\(function \)/\1public \2/" $i > /tmp/out.txt; if [ $(diff $i /tmp/out.txt | wc -l) -ne 0 ]; then diff $i /tmp/out.txt | less; fi; done
# To correct
for i in $(find -name \*.php); do sed -i "s/^\( *\)\(function \)/\1public \2/" $i; done
echo "done."

#Convert file names
echo -n "Converting file names: from '.inc' to '.inc.php' ... "
for i in $(find -name \*.inc); do mv $i $i.php; done
echo "done."

echo -n "Converting file names: from '.class' to '.class.php' ... "
for i in $(find -name \*.class); do mv $i $i.php; done
echo "done."


