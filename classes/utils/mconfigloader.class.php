<?php
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MConfigLoader
{
    /**
     * Attribute Description.
     */
    private $conf;
    private $defaultConf;

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function __construct($loadDefaultConf = true)
    {
        if ( $loadDefaultConf )
        {
            $this->setDefaultConf();
        }
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $module' (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function loadConf($module = '', $file = '')
    {

        $dir = substr($_SERVER['SCRIPT_FILENAME'], 0, strrpos($_SERVER['SCRIPT_FILENAME'], '/html') );
        $fname = ($file == '') ? $dir . (($module == '') ? '/etc/miolo.conf' : '/modules/' . $module . '/etc/module.conf') : $file;
        $xml = new MSimpleXML($fname);
        $this->conf = $xml->toSimpleArray($this->conf);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $key (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function getConf($key)
    {
        $value = is_null($this->conf[$key])
		  				? $this->defaultConf[$key]
						: $this->conf[$key];
        return $value;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $key (tipo) desc
     * @param $value (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setConf($key, $value)
    {
        $this->conf[$key] = $value;
    }
    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $key (tipo) desc
     * @param $value (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setDefaultConf()
    {
        $homeMiolo = $this->getConf("home.miolo");
	 	$this->defaultConf = array(
			"home.classes"=>$homeMiolo."/classes",
			"home.modules"=>$homeMiolo."/modules",
       		"home.etc"=>$homeMiolo."/etc",
       		"home.logs"=>$homeMiolo."/var/log",
       		"home.trace"=>$homeMiolo."/var/trace",
       		"home.db"=>$homeMiolo."/var/db",
	    	"home.html"=>$homeMiolo."/html",
			"home.themes"=>$homeMiolo."/classes/ui/themes",
			"home.extensions"=>$homeMiolo."/extensions",
			"home.reports"=>$homeMiolo."/var/reports",
			"home.images"=>$homeMiolo."/ui/images",
				
			"home.url_themes"=>"/themes",
			"home.url_reports"=>"/reports",
			"home.module.themes"=>"/ui/themes",
			"home.module.html"=>"/html",
			"home.module.images"=>"/html/images",

            "namespace.core"=>"/classes",
			"namespace.service"=>"/classes/services",
			"namespace.ui"=>"/classes/ui",
			"namespace.themes"=>"/ui/themes",
			"namespace.extensions"=>"/classes/extensions",
			"namespace.controls"=>"/ui/controls",
			"namespace.database"=>"/classes/database",
			"namespace.utils"=>"/classes/utils",
			"namespace.modules"=>"/modules"
		);
    }


    /**
    * Generate a xml string of configuration file
    * @params array conf values
    * @returns (string) conf
    */
    public function generateConfigXML($data,$confModule = null)
    {
        $dom  = new DOMDocument('1.0', 'ISO-8859-1'); // standalone="yes"
        $conf = $dom ->appendChild($dom->createElement('conf'));

        $data['home.miolo'        ] != '' ? $homeElements[] = $dom->createElement('miolo'        , $data['home.miolo'        ] ) : null;
        $data['home.classes'      ] != '' ? $homeElements[] = $dom->createElement('classes'      , $data['home.classes'      ] ) : null;
        $data['home.modules'      ] != '' ? $homeElements[] = $dom->createElement('modules'      , $data['home.modules'      ] ) : null;
        $data['home.etc'          ] != '' ? $homeElements[] = $dom->createElement('etc'          , $data['home.etc'          ] ) : null;
        $data['home.logs'         ] != '' ? $homeElements[] = $dom->createElement('logs'         , $data['home.logs'         ] ) : null;
        $data['home.trace'        ] != '' ? $homeElements[] = $dom->createElement('trace'        , $data['home.trace'        ] ) : null;
        $data['home.db'           ] != '' ? $homeElements[] = $dom->createElement('db'           , $data['home.db'           ] ) : null;
        $data['home.html'         ] != '' ? $homeElements[] = $dom->createElement('html'         , $data['home.html'         ] ) : null;
        $data['home.themes'       ] != '' ? $homeElements[] = $dom->createElement('themes'       , $data['home.themes'       ] ) : null;
        $data['home.extensions'   ] != '' ? $homeElements[] = $dom->createElement('extensions'   , $data['home.extensions'   ] ) : null;
        $data['home.reports'      ] != '' ? $homeElements[] = $dom->createElement('reports'      , $data['home.reports'      ] ) : null;
        $data['home.images'       ] != '' ? $homeElements[] = $dom->createElement('images'       , $data['home.images'       ] ) : null;
        $data['home.url'          ] != '' ? $homeElements[] = $dom->createElement('url'          , $data['home.url'          ] ) : null;
        $data['home.url_themes'   ] != '' ? $homeElements[] = $dom->createElement('url_themes'   , $data['home.url_themes'   ] ) : null;
        $data['home.url_reports'  ] != '' ? $homeElements[] = $dom->createElement('url_reports'  , $data['home.url_reports'  ] ) : null;
        $data['home.module.themes'] != '' ? $homeElements[] = $dom->createElement('module.themes', $data['home.module.themes'] ) : null;
        $data['home.module.html'  ] != '' ? $homeElements[] = $dom->createElement('module.html'  , $data['home.module.html'  ] ) : null;
        $data['home.module.images'] != '' ? $homeElements[] = $dom->createElement('module.images', $data['home.module.images'] ) : null;
        if( $homeElements )
        {
            $home = $conf->appendChild($dom->createElement('home'));
            foreach ( $homeElements as $element )
            {
                $home->appendChild($element);
            }
        }

        $data['namespace.core'      ] != '' ? $namespaceElements[] = $dom->createElement('core'       , $data['namespace.core'      ]) : null;
        $data['namespace.service'   ] != '' ? $namespaceElements[] = $dom->createElement('service'    , $data['namespace.service'   ]) : null;
        $data['namespace.ui'        ] != '' ? $namespaceElements[] = $dom->createElement('ui'         , $data['namespace.ui'        ]) : null;
        $data['namespace.themes'    ] != '' ? $namespaceElements[] = $dom->createElement('themes'     , $data['namespace.themes'    ]) : null;
        $data['namespace.extensions'] != '' ? $namespaceElements[] = $dom->createElement('extensions' , $data['namespace.extensions']) : null;
        $data['namespace.controls'  ] != '' ? $namespaceElements[] = $dom->createElement('controls'   , $data['namespace.controls'  ]) : null;
        $data['namespace.database'  ] != '' ? $namespaceElements[] = $dom->createElement('database'   , $data['namespace.database'  ]) : null;
        $data['namespace.utils'     ] != '' ? $namespaceElements[] = $dom->createElement('utils'      , $data['namespace.utils'     ]) : null;
        $data['namespace.modules'   ] != '' ? $namespaceElements[] = $dom->createElement('modules'    , $data['namespace.modules'   ]) : null;
        if( $namespaceElements )
        {
            $namespace = $conf->appendChild($dom->createElement('namespace'));
            foreach ( $namespaceElements as $element )
            {
                $namespace->appendChild($element);
            }
        }

        $data['theme.module' ] != '' ? $themeElements[] = $dom->createElement('module' , $data['theme.module' ]) : null;
        $data['theme.main'   ] != '' ? $themeElements[] = $dom->createElement('main'   , $data['theme.main'   ]) : null;
        $data['theme.lookup' ] != '' ? $themeElements[] = $dom->createElement('lookup' , $data['theme.lookup' ]) : null;
        $data['theme.title'  ] != '' ? $themeElements[] = $dom->createElement('title'  , $data['theme.title'  ]) : null;
        $data['theme.company'] != '' ? $themeElements[] = $dom->createElement('company', $data['theme.company']) : null;
        $data['theme.system' ] != '' ? $themeElements[] = $dom->createElement('system' , $data['theme.system' ]) : null;
        $data['theme.logo'   ] != '' ? $themeElements[] = $dom->createElement('logo'   , $data['theme.logo'   ]) : null;
        $data['theme.email'  ] != '' ? $themeElements[] = $dom->createElement('email'  , $data['theme.email'  ]) : null;
        if( $themeElements )
        {
            $theme = $conf->appendChild($dom->createElement('theme'));
            foreach ( $themeElements as $element )
            {
                $theme->appendChild($element);
            }
        }

        $data['theme.options.close'   ]  != '' ? $tOptionsElements[] = $dom->createElement('close'   , $data['theme.options.close'   ]) : null;
        $data['theme.options.minimize']  != '' ? $tOptionsElements[] = $dom->createElement('minimize', $data['theme.options.minimize']) : null;
        $data['theme.options.help'    ]  != '' ? $tOptionsElements[] = $dom->createElement('help'    , $data['theme.options.help'    ]) : null;
        $data['theme.options.move'    ]  != '' ? $tOptionsElements[] = $dom->createElement('move'    , $data['theme.options.move'    ]) : null;
        if( $tOptionsElements )
        {
            !$theme ? $theme = $conf->appendChild($dom->createElement('theme')) : null;
            $tOptions = $theme->appendChild($dom->createElement('options'));
            foreach ( $tOptionsElements as $element )
            {
                $tOptions->appendChild($element);
            }
        }
                $data['options.startup'           ] != '' ? $optionsElements[] = $dom->createElement('startup'            , $data['options.startup'           ]) : null;
        $data['options.common'            ] != '' ? $optionsElements[] = $dom->createElement('common'             , $data['options.common'            ]) : null;
        $data['options.scramble'          ] != '' ? $optionsElements[] = $dom->createElement('scramble'           , $data['options.scramble'          ]) : null;
        $data['options.scramble.password' ] != '' ? $optionsElements[] = $dom->createElement('scramble.password'  , $data['options.scramble.password' ]) : null;
        $data['options.dispatch'          ] != '' ? $optionsElements[] = $dom->createElement('dispatch'           , $data['options.dispatch'          ]) : null;
        $data['options.url.style'         ] != '' ? $optionsElements[] = $dom->createElement('url.style'          , $data['options.url.style'         ]) : null;
        $data['options.index'             ] != '' ? $optionsElements[] = $dom->createElement('index'              , $data['options.index'             ]) : null;
        $data['options.mainmenu'          ] != '' ? $optionsElements[] = $dom->createElement('mainmenu'           , $data['options.mainmenu'          ]) : null;
        $data['options.mainmenu.style'    ] != '' ? $optionsElements[] = $dom->createElement('mainmenu.style'     , $data['options.mainmenu.style'    ]) : null;
        $data['options.mainmenu.clickopen'] != '' ? $optionsElements[] = $dom->createElement('mainmenu.clickopen' , $data['options.mainmenu.clickopen']) : null;
        $data['options.dbsession'         ] != '' ? $optionsElements[] = $dom->createElement('dbsession'          , $data['options.dbsession'         ]) : null;
        $data['options.authmd5'           ] != '' ? $optionsElements[] = $dom->createElement('authmd5'            , $data['options.authmd5'           ]) : null;
        $data['options.debug'             ] != '' ? $optionsElements[] = $dom->createElement('debug'              , $data['options.debug'             ]) : null;
        $data['options.autocomplete_alert'] != '' ? $optionsElements[] = $dom->createElement('autocomplete_alert' , $data['options.autocomplete_alert']) : null;
            if( $optionsElements )
        {
            $options = $conf->appendChild($dom->createElement('options'));
            foreach ( $optionsElements as $element )
            {
                $options->appendChild($element);
            }
        }

        $data['options.dump.peer'    ] != '' ? $oDumpElements[] = $dom->createElement('peer'    , $data['options.dump.peer'    ]) : null;
        $data['options.dump.profile' ] != '' ? $oDumpElements[] = $dom->createElement('profile' , $data['options.dump.profile' ]) : null;
        $data['options.dump.uses'    ] != '' ? $oDumpElements[] = $dom->createElement('uses'    , $data['options.dump.uses'    ]) : null;
        $data['options.dump.trace'   ] != '' ? $oDumpElements[] = $dom->createElement('trace'   , $data['options.dump.trace'   ]) : null;
        $data['options.dump.handlers'] != '' ? $oDumpElements[] = $dom->createElement('handlers', $data['options.dump.handlers']) : null;
        if( $oDumpElements )
        {
            !$options ? $options = $conf->appendChild($dom->createElement('options')) : null;
            $oDump = $options->appendChild($dom->createElement('dump'));
            foreach ( $oDumpElements as $element )
            {
                $oDump->appendChild($element);
            }
        }
        $data['options.loading.show'      ] != '' ? $oLoadingElements[] = $dom->createElement('show'      , $data['options.loading.show'      ]) : null;
        $data['options.loading.generating'] != '' ? $oLoadingElements[] = $dom->createElement('generating', $data['options.loading.generating']) : null;
        if( $oLoadingElements )
        {
            !$options ? $options = $conf->appendChild($dom->createElement('options')) : null;
            $oLoading = $options->appendChild($dom->createElement('loading'));
            foreach ( $oLoadingElements as $element )
            {
                $oLoading->appendChild($element);
            }
        }             
        $data['i18n.locale'  ] != '' ? $oLocaleElements[] = $dom->createElement('locale'   , $data['i18n.locale'  ]) : null;
        $data['i18n.language'] != '' ? $oLocaleElements[] = $dom->createElement('language' , $data['i18n.language']) : null;
        if( $oLocaleElements )
        {
            $oLocale = $conf->appendChild($dom->createElement('i18n'));
            foreach ( $oLocaleElements as $element )
            {
                $oLocale->appendChild($element);
            }
        }

        $data['mad.module'] != '' ? $madElement = $dom->createElement('module'  , $data['mad.module']) : null;
        if( $madElement )
        {
            $mad = $conf->appendChild($dom->createElement('mad'));
            $mad->appendChild($madElement);
        }
        $data['mad.classes.access'     ] != '' ? $madClassesElements[] = $dom->createElement('access'      , $data['mad.classes.access'     ]) : null;
        $data['mad.classes.group'      ] != '' ? $madClassesElements[] = $dom->createElement('group'       , $data['mad.classes.group'      ]) : null;
        $data['mad.classes.log'        ] != '' ? $madClassesElements[] = $dom->createElement('log'         , $data['mad.classes.log'        ]) : null;
        $data['mad.classes.session'    ] != '' ? $madClassesElements[] = $dom->createElement('session'     , $data['mad.classes.session'    ]) : null;
        $data['mad.classes.transaction'] != '' ? $madClassesElements[] = $dom->createElement('transaction' , $data['mad.classes.transaction']) : null;
        $data['mad.classes.user'       ] != '' ? $madClassesElements[] = $dom->createElement('user'        , $data['mad.classes.user'       ]) : null;
        if( $madClassesElements )
        {
            !$mad ? $mad = $conf->appendChild($dom->createElement('mad')) : null;
            $madClasses = $mad->appendChild($dom->createElement('classes'));
            foreach ( $madClassesElements as $element )
            {
                $madClasses->appendChild($element);
            }
        }
        $data['login.module'] != '' ? $loginElements[] = $dom->createElement('module' , $data['login.module']) : null;
        $data['login.class' ] != '' ? $loginElements[] = $dom->createElement('class'  , $data['login.class' ]) : null;
        $data['login.check' ] != '' ? $loginElements[] = $dom->createElement('check'  , $data['login.check' ]) : null;
        $data['login.shared'] != '' ? $loginElements[] = $dom->createElement('shared' , $data['login.shared']) : null;
        $data['login.auto'  ] != '' ? $loginElements[] = $dom->createElement('auto'   , $data['login.auto'  ]) : null;
        if( $loginElements )
        {
            $login = $conf->appendChild($dom->createElement('login'));
            foreach ( $loginElements as $element )
            {
                $login->appendChild($element);
            }
        }
                $data['session.handler'] != '' ? $sessionElements[] = $dom->createElement('handler' , $data['session.handler']) : null;
        $data['session.timeout'] != '' ? $sessionElements[] = $dom->createElement('timeout' , $data['session.timeout']) : null;
        if( $sessionElements )
        {
            $session = $conf->appendChild($dom->createElement('session'));
            foreach ( $sessionElements as $element )
            {
                $session->appendChild($element);
            }
        }

        (!$confModule) ? $confModule = MIOLO::_REQUEST('confModule') : null;
        ! $confModule ? $confModule = 'miolo' : null;
        $data['db.'.$confModule.'.system'  ] != '' ? $dbMioloElements[] = $dom->createElement('system'  , $data['db.'.$confModule.'.system'  ]) : null;
        $data['db.'.$confModule.'.host'    ] != '' ? $dbMioloElements[] = $dom->createElement('host'    , $data['db.'.$confModule.'.host'    ]) : null;
        $data['db.'.$confModule.'.name'    ] != '' ? $dbMioloElements[] = $dom->createElement('name'    , $data['db.'.$confModule.'.name'    ]) : null;
        $data['db.'.$confModule.'.user'    ] != '' ? $dbMioloElements[] = $dom->createElement('user'    , $data['db.'.$confModule.'.user'    ]) : null;
        $data['db.'.$confModule.'.password'] != '' ? $dbMioloElements[] = $dom->createElement('password', $data['db.'.$confModule.'.password']) : null;
        if( $dbMioloElements )
        {
            $db      = $conf->appendChild($dom->createElement('db'));
            $dbMiolo = $db  ->appendChild($dom->createElement($confModule));
            foreach ( $dbMioloElements as $element )
            {
                $dbMiolo->appendChild($element);
            }
        }
                $data['logs.level'  ] != '' ? $logsElements[] = $dom->createElement('level'  , $data['logs.level'  ]) : null;
        $data['logs.handler'] != '' ? $logsElements[] = $dom->createElement('handler', $data['logs.handler']) : null;
        $data['logs.peer'   ] != '' ? $logsElements[] = $dom->createElement('peer'   , $data['logs.peer'   ]) : null;
        $data['logs.port'   ] != '' ? $logsElements[] = $dom->createElement('port'   , $data['logs.port'   ]) : null;
        if( $logsElements )
        {
            $logs = $conf->appendChild($dom->createElement('logs'));
            foreach ( $logsElements as $element )
            {
                $logs->appendChild($element);
            }
        }
        $dom->formatOutput = true;
        return $dom->saveXML();
    }

}
?>
