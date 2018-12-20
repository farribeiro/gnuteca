#!/bin/bash
# Rafael Dutra

echo -e '\E[37;44m'"\033[1mSearching files...\033[0m"
echo -e '\E[37;44m'"\033[1m *.class \033[0m"
CLASSES=`find ../classes/ -name "*.class"`    # procura todos os arquivos .class
echo -e '\E[37;44m'"\033[1m *.php \033[0m"
PHP=`find ../classes/ -name "*.php"`          # procura todos os arquivos .php 
echo -e '\E[37;44m'"\033[1m *.inc \033[0m"
INC=`find ../classes/ -name "*.inc"`          # procura todos os arquivos .inc 
DIR=/tmp
ARQ=arq_functions.txt
TEMPARQ=arquivo_functions.txt

echo -e '\E[37;44m'"\033[1mExtracting...\033[0m"
echo -e '\E[37;44m'"\033[1m *.class \033[0m"
cat $CLASSES >$DIR/$ARQ
echo -e '\E[37;44m'"\033[1m *.php \033[0m"
cat $PHP >>$DIR/$ARQ
echo -e '\E[37;44m'"\033[1m *.inc \033[0m"
cat $INC >>$DIR/$ARQ
cd $DIR
echo -e '\E[37;44m'"\033[1mConverting from DOS (if any)... \033[0m"
fromdos <$ARQ> $TEMPARQ
echo -e '\E[37;44m'"\033[1mMoving...\033[0m"
mv $TEMPARQ $ARQ
