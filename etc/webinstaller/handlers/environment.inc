<?php

    include_once('installer.class');

    $theme->clearContent();
    $MIOLO->setConf('theme.system', 'Environment');
    //updateDispatcher('theme');

    // generates a link to put no the panel's close button
    $close = $MIOLO->getActionURL('install','main');

    // PHP
    Requisites::addRequisite('PHP Version', // label
                             array('PHP_VERSION < 5', 'PHP_VERSION'), // expression
                             ' >= 5 ' , // expected label
                             'PHP MUST be >= 5, get it at <a href=http://www.php.net/downloads.php target=_new>http://www.php.net</a>', // additional information
                             false); // is this a fatal error?

    // Apache
    Requisites::addRequisite('HTTP Server', // label
                             array(null, '$_SERVER["SERVER_SOFTWARE"]'), // expression
                             ' ' , // expected label
                             '');


    // zip
    Requisites::addRequisite('Suppor for Zip Files', // label
                             'function_exists(zip_read)', // expression
                             ' true ' , // expected label
                             'Miolo requires zip extension to be able to install new modules',
                             false);

    // gettext
    Requisites::addRequisite('Gettext Enabled', // label
                             'function_exists(gettext)', // expression
                             ' true ' , // expected label
                             'If you want i18n support...',
                             false);

    // GD
    Requisites::addRequisite('GD Enabled', // label
                             'function_exists(gd_info)', // expression
                             ' true ' , // expected label
                             'Some project may need GD support',
                             false);

    // SQLite
    Requisites::addRequisite('Support for SQLite', // label
                             'function_exists(sqlite_open)', // expression
                             ' true ' , // expected label
                             'MIOLO 2 requires SQLite support',
                             true);

    // Mysql
    Requisites::addRequisite('Support for Mysql', // label
                             'function_exists(mysql_connect)', // expression
                             ' true ' , // expected label
                             'Some project may need Mysql support',
                             false);

    // PGSQL
    Requisites::addRequisite('Support for Postgres', // label
                             'function_exists(pg_connect)', // expression
                             ' True ' , // expected label
                             'Some project may need Postgres support',
                             false);

    // ORACLE
    Requisites::addRequisite('Support for Oracle', // label
                             'function_exists(oci_connect)', // expression
                             ' ' , // expected label
                             ' ',
                             false);

    // MSSQL
    Requisites::addRequisite('Support for MS SQL', // label
                             'function_exists(mssql_connect)', // expression
                             ' ' , // expected label
                             ' ',
                             false);

    //$registerGlobalsActive =
    // $magicQuotes = 

?>