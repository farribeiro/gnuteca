#!/bin/bash

LOCALE_DIR="../../locale/pt_BR/LC_MESSAGES"
FILES=$(find . -name \*.po | cut -f2- -d/)

if [ $1 ]
then
        FILES=$1
fi

for FILE in $FILES
do
    echo "Processing $FILE..."
    echo " Copying file $FILE to $LOCALE_DIR/$FILE..."
    cp $FILE $LOCALE_DIR/$FILE
    echo " Generating $LOCALE_DIR/$(echo $FILE | cut -f1 -d.).mo file from $LOCALE_DIR/$FILE..."
    msgfmt -f $LOCALE_DIR/$FILE -o $LOCALE_DIR/$(echo $FILE | cut -f1 -d.).mo
done
echo "###############################################################################"
echo "# Don't forget to restart your apache server for the settings to take effect. #"
echo "###############################################################################"
