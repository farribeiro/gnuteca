#!/bin/bash

cd ../../../tools/dia2sql/
php dia2sql.php -f pgsql -i ../../trunk/misc/docs/er-gnuteca3.dia -o ../../trunk/misc/sql/gnuteca3.sql
