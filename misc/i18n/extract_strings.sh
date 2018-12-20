#!/bin/bash

SOURCE_DIR=../../
DEST_DIR=./

function addHTMLEntities() {
    FILE="$1"
    TMP_FILE="/tmp/1523tmp"

    echo " Adding HTML entities to file $FILE..."

    # acento circunflexo
    sed "s/�/\&acirc;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&ecirc;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&ocirc;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&Acirc;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&Ecirc;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&Ocirc;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    # til
    sed "s/�/\&atilde;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&otilde;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&Atilde;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&Otilde;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    # acento agudo
    sed "s/�/\&aacute;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&eacute;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&iacute;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&oacute;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&uacute;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&Aacute;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&Eacute;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&Iacute;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&Oacute;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&Uacute;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    # crase, cedilha e trema
    sed "s/�/\&agrave;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&ccedil;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&uuml;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&ouml;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&iuml;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&Agrave;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&Ccedil;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&Uuml;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&Ouml;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&Iuml;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE

    # caracteres especiais
    sed "s/�/\&ordf;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/�/\&ordm;/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
}

function removeHTMLEntities() {
    FILE="$1"
    TMP_FILE="/tmp/1523tmp"

    echo " Removing HTML entities from file $FILE..."

    # acento circunflexo
    sed "s/\&acirc;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&ecirc;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&ocirc;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&Acirc;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&Ecirc;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&Ocirc;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    # til
    sed "s/\&atilde;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&otilde;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&Atilde;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&Otilde;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    # acento agudo
    sed "s/\&aacute;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&eacute;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&iacute;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&oacute;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&uacute;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&Aacute;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&Eacute;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&Iacute;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&Oacute;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&Uacute;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    # crase, cedilha e trema
    sed "s/\&agrave;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&ccedil;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&uuml;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&ouml;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&iuml;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&Agrave;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&Ccedil;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&Uuml;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&Ouml;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&Iuml;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE

    # caracteres especiais
    sed "s/\&ordf;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE
    sed "s/\&ordm;/�/g" $FILE > $TMP_FILE
    mv $TMP_FILE $FILE

}

#FIXME:
mv miolo.po classes.po

DIRS="classes modules/admin modules/example"

if [ $1 ]
then
	DIRS=$1
fi
for DIR in $DIRS
do
    find $SOURCE_DIR/$DIR -type f | grep ".class.php$\|.inc.php$" > $DEST_DIR/files.txt

    if echo $DIR | grep '/'
    then
	    DIR=$(echo $DIR | cut -f2- -d/)
    fi

    OUT=$DEST_DIR/$DIR.po
    echo "Generating $OUT..."
    if [ ! -f $DEST_DIR/$OUT ]
    then
        echo " Creating file $OUT..."
        touch $OUT
        unset OMIT_HEADER
    else
        OMIT_HEADER="--omit-header"
    fi

    echo " Removing comments to regenerate them again..."
    grep -v "^#: " $OUT > /tmp/45633tmpfile
    mv /tmp/45633tmpfile $OUT
    
    addHTMLEntities $OUT
    echo " Extracting additional strings from files..."
    xgettext --from-code=ISO-8859-1 $OMIT_HEADER --no-wrap -j -s --keyword='_M:1' -Lphp -f $DEST_DIR/files.txt -o $OUT
    removeHTMLEntities $OUT

    rm $DEST_DIR/files.txt
done

#FIXME
mv classes.po miolo.po
