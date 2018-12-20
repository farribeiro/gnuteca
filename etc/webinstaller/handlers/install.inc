<?php

    //include_once('installer.class');

    $formAction = $MIOLO->getConf('home.url') . '/' . $MIOLO->getConf('options.dispatch');
    $form = new MForm('Install MIOLO');
    $form->defaultButton = true;

    if ( MForm::getFormValue('step3') )
    {
        $form->setTitle(_M('Install Miolo - Step 3/3') );

    $dest = MForm::getFormValue('txtDestination');
    $url = MForm::getFormValue('txtAddress');
    
    //copies miolo to target install directory
    MUtil::copyDirectory($MIOLO->GetAbsolutePath(),$dest);
    
    // generate miolo.conf
    
    $data['home.miolo'        ] = $dest;
    $data['home.classes'      ] = $dest . '/classes';
    $data['home.modules'      ] = $dest . '/modules';
    $data['home.etc'          ] = $dest . '/etc';
    $data['home.logs'         ] = $dest . '/var/log';
    $data['home.trace'        ] = $dest . '/var/trace';
    $data['home.db'           ] = $dest . '/var/db';
    $data['home.html'         ] = $dest . '/html';
    $data['home.themes'       ] = $dest . '/classes/ui/themes';
    $data['home.extensions'   ] = $dest . '/extensions';
    $data['home.reports'      ] = $dest . '/var/reports';
    $data['home.images'       ] = $dest . '/ui/images';
    $data['home.url'          ] = $url;
    $data['home.url_themes'   ] = '/themes';
    $data['home.url_reports'  ] = '/reports';
    $data['home.module.themes'] = '/ui/themes';
    $data['home.module.html'  ] = '/html';
    $data['home.module.images'] = '/html/images';
    
    $data['namespace.core'      ] = '/classes';
    $data['namespace.service'   ] = '/classes/services';
    $data['namespace.ui'        ] = '/classes/ui';
    $data['namespace.themes'    ] = '/ui/themes';
    $data['namespace.extensions'] = '/classes/extensions';
    $data['namespace.controls'  ] = '/ui/controls';
    $data['namespace.database'  ] = '/classes/database';
    $data['namespace.utils'     ] = '/classes/utils';
    $data['namespace.modules'   ] = '/modules';

    $data['theme.module' ] = null;
    $data['theme.main'   ] = 'miolo2';
    $data['theme.lookup' ] = 'miolo2';
    $data['theme.title'  ] = 'Miolo Web Application';
    $data['theme.company'] = 'MIOLO FRAMEWORK';
    $data['theme.system' ] = 'version 2.0 - rc1';
    $data['theme.logo'   ] = 'logo_miolo.png';
    $data['theme.email'  ] = 'admin@miolo2.localhost';

    $data['theme.options.close'   ]  = 'true';
    $data['theme.options.minimize']  = 'true';
    $data['theme.options.help'    ]  = 'true';
    $data['theme.options.move'    ]  = 'true';
    
    $data['options.startup'           ] = 'common';
    $data['options.common'            ] = 'common';
    $data['options.scramble'          ] = '0';
    $data['options.scramble.password' ] = 'password';
    $data['options.dispatch'          ] = 'index.php';
    $data['options.url.style'         ] = '0';
    $data['options.index'             ] = 'index.php';
    $data['options.mainmenu'          ] = '3';
    $data['options.mainmenu.style'    ] = 'office2003';
    $data['options.mainmenu.clickopen'] = 'false';
    $data['options.dbsession'         ] = '0';
    $data['options.authmd5'           ] = '0';
    $data['options.debug'             ] = '1';
    $data['options.autocomplete_alert'] = null;
    
    $data['options.dump.peer'    ] = '127.0.0.1';
    $data['options.dump.profile' ] = 'false';
    $data['options.dump.uses'    ] = 'false';
    $data['options.dump.trace'   ] = 'false';
    $data['options.dump.handlers'] = 'false';
    
    $data['options.loading.show'      ] = 'true';
    $data['options.loading.generating'] = 'true';
    
    $data['options.performance.uri_images' ] = null;
    $data['options.performance.enable_ajax'] = null;
    
    $data['i18n.locale'  ] = $dest . '/locale';
    $data['i18n.language'] = 'pt_BR';
    
    $data['mad.module'] = 'admin';
    $data['mad.classes.access'     ] = 'access';
    $data['mad.classes.group'      ] = 'group';
    $data['mad.classes.log'        ] = 'log';
    $data['mad.classes.session'    ] = 'session';
    $data['mad.classes.transaction'] = 'transaction';
    $data['mad.classes.user'       ] = 'user';
    
    $data['login.module'] = 'admin';
    $data['login.class' ] = 'MAuthDb';
    $data['login.check' ] = 'false';
    $data['login.shared'] = 'true';
    $data['login.auto'  ] = '1';
    
    $data['session.handler'] = 'file';
    $data['session.timeout'] = '300';
    
    $data['db.miolo.system'  ] = 'sqlite';
    $data['db.miolo.host'    ] = 'localhost';
    $data['db.miolo.name'    ] = $dest . '/var/db/miolo.sqlite';
    $data['db.miolo.user'    ] = MForm::getFormValue('txtUserName');
    $data['db.miolo.password'] = MForm::getFormValue('txtPassword');

    $data['logs.level'  ] = '2';
    $data['logs.handler'] = 'socket';
    $data['logs.peer'   ] = '0';
    $data['logs.port'   ] = '0';

    file_put_contents($dest . '/etc/miolo.conf', MConfigLoader::generateConfigXML($data) );

    $dataAdmin['db.admin.system'  ] = 'sqlite';
    $dataAdmin['db.admin.host'    ] = 'localhost';
    $dataAdmin['db.admin.name'    ] = $dest . '/modules/admin/sql/admin.sqlite';
    $dataAdmin['db.admin.user'    ] = MForm::getFormValue('txtUserName');
    $dataAdmin['db.admin.password'] = MForm::getFormValue('txtPassword');

    $xml=MConfigLoader::generateConfigXML($dataAdmin, 'admin');
    file_put_contents($dest . '/modules/admin/etc/module.conf', $xml);

    $theme->clearContent();

    $messageInfo = "<table>
                     <tr>
                      <td>
                       <img src=images/yes.png> Finished!
                      </td>
                     </tr>
                     <tr>
                      <td>
                       Miolo 2 was successfully installed!<br>Please create the following VirtualHost in your apache conf.
                      </td>
                     </tr>
                     <tr>
                      <td>
                       Remember to update your hosts information, otherways you'll not be able to access the new host. 
                      </td>
                     </tr>
                    </table>";

    $form->addInfo($messageInfo);

    $completeURL = $url;
    $url = substr($url, strrpos($url,'/')+1, strlen($url) );

    $virtualhost = "<VirtualHost *>\n    DocumentRoot ".$dest."/html\n    ServerName ".$url."\n</VirtualHost>";

    $multiField = new MMultilineField( 'multiField', $virtualhost, 'Virtual Host', 20, 10, 70 );
	$multiField->setReadOnly( true );

    $form->defaultButton = false;
    $form->addButton( new MButton( 'btnForm', 'Finish', $formAction ) );
    $form->addButton( new MButton( 'btnForm', 'Open ' . $completeURL , "javascript:window.open('$completeURL', '_new')" ) );

	$fields = array ( $multiField );
    
    }
    elseif ( MForm::getFormValue('txtDestination') )
    //if ( Form::getFormValue('txtDestination') )
    {
        $form->setTitle( _M('Install MIOLO - Step 2/3') );

        include_once('environment.inc');

        // Is dir writable?
        $installDir = MForm::getFormValue('txtDestination');
        Requisites::addRequisite("<b>$installDir</b> exists and is writable?", // label
                                    "is_writable(\"$installDir\")", // expression
                                    ' True ' , // expected label
                                    'You need to create this directory and it must be writable in order to install MIOLO!',
                                    true);

        Requisites::processRequisites( );

        if ( MUtil::getBooleanValue( Requisites::hasFatalError() ) == true )
        {
            $formAction = $MIOLO->getConf('home.url') . '/' . $MIOLO->getConf('options.dispatch') . '?module=install&action=install';
            $form->addButton( new MButton( 'btnForm', _M('< Back'), $formAction ) );
        }
        else
        {
            $form->buttons[] = new MButton(FORM_SUBMIT_BTN_NAME, 'Install Now', 'SUBMIT');
        }

        $fields = array( Requisites::$content, new MHiddenField('step3',true), new MHiddenField('txtDestination',MForm::getFormValue('txtDestination')), new MHiddenField('txtAddress',MForm::getFormValue('txtAddress')), new MHiddenField('txtUserName',MForm::getFormValue('txtUserName')), new MHiddenField('txtPassword',MForm::getFormValue('txtPassword')));

    }
    else
    {
        //$form->addButton( new MButton( 'btnForm', 'Go Back', "javascript:GotoURL('$formAction')" ) );
    
        $form->setTitle( _M('Install MIOLO - Step 1/3') );
    
        $sourceDirectory = $mioloDir;
    
        $lblSource = new MText('lblSource', _M('Source directory') . ':');
        $flds[]    = $lblSource;
        $txtSource = new MTextField('txtDestination', $sourceDirectory, '', 50);
        $txtSource->setReadOnly(true);
    
        $flds[]    = $txtSource;
        $hctSource = new MHContainer('hctSource', $flds);
        unset($flds);
        $fields[]  = $hctSource;
    
        $lblDestination = new MText('lblDestination', _M('Destination directory') . ':');
        $flds[]         = $lblDestination;
        $txtDestination = new MTextField('txtDestination', $form->getFormValue('txtDestination', '/usr/local/miolo2'), '', 50);
        $flds[]         = $txtDestination;
    
        $hctDestination = new MHContainer('hctDestination', $flds);
        unset($flds);
        $fields[]       = $hctDestination;
    
        $lblAddress = new MText('lblAddress', _M('Host URL') . ':');
        $flds[]     = $lblAddress;
        $txtAddress = new MTextField('txtAddress', $form->getFormValue('txtAddress', 'http://miolo2.localhost'), '', 50);
        $flds[]     = $txtAddress;
    
        $hctAddress = new MHContainer('hctDestination', $flds);
        unset($flds);
        $fields[]   = $hctAddress;
    
        $lblUserName = new MText('lblUserName', _M('DB UserName') . ':');
        $flds[]      = $lblUserName;
    
        $txtUserName = new MTextField('txtUserName', $form->getFormValue('txtUserName', 'admin'), '', 20);
        $txtUserName->setReadOnly(true);
        $flds[]      = $txtUserName;
    
        $hctUserName = new MHContainer('hctUserName', $flds);
        unset($flds);
        $fields[]   = $hctUserName;
    
        $lblPassword = new MText('lblPassword', _M('DB Password') . ':');
        $flds[]      = $lblPassword;
    
        $txtPassword = new MTextField('txtPassword', $form->getFormValue('txtPassword', 'admin'), '', 20);
        $txtPassword->setReadOnly(true);
        $flds[]      = $txtPassword;
    
        $hctPassword = new MHContainer('hctPassword', $flds);
        unset($flds);
        $fields[]   = $hctPassword;
    
        $destination  = new MTextField('destinat', $form->getFormValue('destinat', '/usr/local/miolo'), _M('Destination directory'), 70);
        $destination->setJsHint( _M('Please inform the destination directory, where MIOLO should be installed') );
    
        $form->buttons[] = new MButton(FORM_SUBMIT_BTN_NAME, 'Next >', 'SUBMIT');
    }

    $form->setFields( $fields );
    $theme->appendContent( $form );

?>
