/*************************************************
*                                                * 
*          MIOLO Installation Program            *
*                                                *
*    Author: Vilson Cristiano Gärtner  -         *
*            MIOLO Development Coordinator       *
*    E-mail: vgartner@univates.br                *
*                                                *
*    Date: August/2002                           *
*                                                *
*    $Id: language-en.h,v 1.2 2005/04/03 15:51:48 ematos Exp $                                        *
*                                                *
*              MIOLO I18n Project                *
* Translation by Eduardo Bacchi Kienetz          *
*                eduardobk@via-rs.net            *
* Revision by J. Fernando de L. Machado Jr.      *
*             machx@ieg.com.br                   *
*************************************************/


// MIOLO Language: English
#define LANGUAGE "en"

// Wizard
#define CANCEL "Cancel"
#define NEXT "Next >>"
#define BACK "<< Previous"
#define FINISH "Finish"
#define INSTALL "Install"

// Page 1
#define WELCOME "Welcome"
#define PAGE1_INFO "\n\n       MIOLO INSTALLATION PROGRAM\n\n\n\n\n\n                        MIOLO version 1.0 RC4\n\n\n\n\n\n\n\nAuthor: Vilson Cristiano Gärtner - vgartner@univates.br\n\nhttp://miolo.codigolivre.org.br"

// Page 2
#define FILE_PATH "Files path"
#define PAGE2_INFO  "\n Enter the configuration \n files path.  \n\n All fields must be \n completed.  \n By default the files are \n installed in these directories. \n\n  Note: It is advisable \n that you proceed the \n installation as root. \n It is also possible to install\n as another user, but remember \n that it will be necessary to\n change writing permissions \n on the folders."

#define LBL_MODULES " Modules: "
#define LBL_THEMES " Themes: "
#define LBL_URL_THEMES " URL Themes: "


// Page 3
#define DB_SETTINGS "Database Settings"
#define PAGE3_INFO "\n Enter the database  \n configurations.  \n\n Enter the type of data base, \n its name, user and\n password to access it.\n\n The best is to keep \n the same configuration\n in both.\n\n The common configuration\n maintain the tables:\n cmn_users and cmn_access\n used by MIOLO for\n  user control and \n passwords."
#define BASE_TYPE " Type of data base: "
#define HOST_IP " Host IP: "
#define BASE_NAME " Base name: "
#define BASE_USER " User: "
#define BASE_PASSWD " Password: "


// Page 4
#define LOGIN_SETTINGS "Login Settings"
#define PAGE4_INFO "\n Enter the settings \n for MIOLO Login \n control.\n\n For further information , \n use the field sensitive \n help: \n  -click the button with\n the question mark and\n mouse cursor and then\n over the field."
 
#define ALWAYS_CHECK_LOGIN "It is always necessary to Login "
#define MIOLO_CONTROLS_LOGIN "The Login is controlled by MIOLO, not by the database"
#define AUTO_LOGIN "Use Automatic Login"
#define AUTO_LOGIN_ID " Auto Login ID: "
#define AUTO_LOGIN_PASS " Auto Login Password: "
#define USER_NAME " User's Name: "


// Page4a
#define INSTALL_OPTIONS "Installation options"
#define PAGE4A_INFO "\n Select which options you\n wish to install.\n\n If any option\n is disabled, it indicates that \n this option does not\n accompain the installer. This\n can happen in updating\n (when it is not\n necessary to install all\n files) or in case of\n the file not being on the\n installer directory.\n\n Important: the existing\n files will be overwritten, that \n is why it is secure keeping a\n copy of the actual files."
#define INSTALL_MIOLO_CLASSES "Install MIOLO classes"
#define INSTALL_COMMON "Install Common Module (Login and Screen/Main Menu)"
#define INSTALL_EXAMPLES "Install Example and Tutorial Modules"
#define INSTALL_THEMES "Install Themes"
#define CREATE_CONF_FILE "Create configuration file: miolo.conf"
#define SHOW_APACHE_EXAMPLE "Show VirtualHost suggestion for Apache"

// Page 5
#define APACHE_EXAMPLE "Apache Configuration"
#define PAGE5_INFO "\n  Apache Configuration.  \n\n According with the previously\n indicated configurations, \n we present here an\n example of Virtual Host\n that you could use\n for Apache.\n\n Tip: You can copy and \n paste the example.\n\n Note: \n if a configuration already \n exists for this domain, it is \n not necessary to create \n another."
#define SUGESTION_APACHE "Virtual Host suggestion for Apache: \n"

// Page 6
#define WAITING_INSTALL_TO_START "WAITING FOR MIOLO INSTALLATION TO START: "
#define PAGE6_INFO "\n   MIOLO's installer is\n ready to begin \n the installation process. \n\n Press the button\n to start...\n"
#define INSTALL_PROCESS "Installation Process"
#define BTN_START_INSTALL "Start MIOLO Installation"

// Methods
#define SELE_DIR "Choose the Directory..."
#define CREATING_DIRS "Creating directories..."
#define INSTALLING_MIOLO_FILES "Installing MIOLO files..."
#define MSG_MIOLO_FILE_NOT_FOUND "Directory: miolo (MIOLO classes) not found."
#define MSG_LOCALE_FILE_NOT_FOUND "Directory: locale (translations) not found."
#define INSTALLING_HTDOCS "Installing htdocs files..."
#define MSG_HTDOCS_FILE_NOT_FOUND "Directory: htdocs (needed by MIOLO) not found."
#define INSTALLING_COMMON "Installing Common Module files..."
#define MSG_COMMON_FILE_NOT_FOUND "Directory: common (Login, Screen/Main Menu) not found."
#define INSTALLING_EXAMPLES "Installing example modules..."
#define MSG_EXAMPLES_FILE_NOT_FOUND "Directory: sample (Programs/modules examples) not found."
#define INSTALLING_THEMES "Installing MIOLO themes..."
#define MSG_THEMES_FILE_NOT_FOUND "Directory: themes (MIOLO themes) not found."
#define MSG_MIOLOCONF_EXISTS "The file <b>miolo.conf</b> already exists.<br><br>It is advisable to make a copy of the actual file or unmark this option to not overwrite the existing file.<br><br>Path: "
#define CREATING_MIOLOCONF "Creating configuration file miolo.conf..."
#define INSTALLATION_FINISHED "Installation Finished.  Log file generated at /tmp/miolo_install.log"
#define INSTALL_END "Installation Finished."
#define MSG_ERROR_CREATING_MIOLOCONF "Unable to create the file miolo.conf with \nthe settings choosen.\nDo not forget that you must run the installer \nas root (preferably) or have writing permission\n on the directories."


// WhatsThis Help
  // Page 2
#define WT_DIRBUTTON "Click here to select and/or create a directory. <br> <b>Important:</b> to create a directory, you must have writing permission.";
#define WT_EDTHTML "Choose the folder that will be visible through the WEB. <br> You must also configure <b>Apache</b> correctly, so that the <em>DocumentRoot</em> (or <em>Virtual Host</em>) points to this directory and the browser finds the files correctly.";

#define WT_EDTMIOLO "In this field type the folder where <b>MIOLO</b> files should be installed.";
#define WT_EDTMODULES "Here, type the folder where the Modules/Systems developed with MIOLO can be found.";
#define WT_EDTLOCALE "Type the folder where the MIOLO and Modules/Systems translation files will be installed."
#define WT_EDTLOGS "Inform where MIOLO should write the log files of Modules/Systems. <br> <b>Very Important:</b> <em>Apache</em> must have writing permission on this directory.";
#define WT_EDTTHEMES "Directory where MIOLO and Modules/System will be installed."
#define WT_EDTURL "Type here the URL address of the site.<br><b>Important:</b> the address hereby informed must be correctly configured on <em>Apache</em> (DocumentRoot or Virtual Host)"


#define WT_EDTURL_THEMES "Choose the WEB address that points to the themes directory. This address will be under the URL given on the previous item"


#define WT_EDTTRACE_PORT "Through this port, MIOLO sends informations as errors, sqls,... Information which may be captured by debugging programs. An example of this is the MIOLO plugin for the JEdit editor, that receives this information."

  // Page 3
#define WT_BASE_TIPO "What kind of Database will you use?"
#define WT_BASE_HOST "Machine's IP address where the database is found."
#define WT_BASE_BASE "Database name where MIOLO tables will be stored"
#define WT_BASE_USER "User name to access the database"
#define WT_BASE_PASSWD "User's password to access the Database"

  // Page 4
#define WT_MKLOGIN "Activate this option to make MIOLO always ask for user Login. <br>In this case, MIOLO will always open the login screen when someone accesses the site."
#define WT_MIOLOLOGIN "There are two ways of doing system login control.<br> The first is to let MIOLO control this process and for that, the user and password must be registered on the cmn_users table. <br>The second option is to let the Database itself take care of user validation. It should be <em>expressly</em> registered on it. Even on this situation, the user must be registered on the cmn_users, with the difference that the password will not be necessary.<br>To let MIOLO control the users access (<em>default</em>) activate this option."
#define WT_AUTOLOGIN "MIOLO offers the possibility to create automatic logins. These logins may be, together with the attributed permissions on cmn_access, used to allow the access to certain pages and options of a system to whom it is not necessary make the explicit login form. <br>In other words, MIOLO makes system login using the user and password defined at the automatic login."
#define WT_LOGINID "Automatic login username. The permissions for this user must be completed later on cmn_access table"
#define WT_LOGINPWD "Password used for automatic login"
#define WT_LOGINNAME "Full user name"

  // Page 4a
#define WT_INSTALL_MIOLO "Activate this option to install MIOLO classes."
#define WT_INSTALL_COMMON "Activate this option to install MIOLO's Common Module. <br> The common module is used by MIOLO for login tasks, besides the Menu and Main Screen creation. "
#define WT_INSTALL_EXAMPLES "With this option checked, it will be necessary to install the example module and tutorials."
#define WT_INSTALL_THEMES "Activate this option to install the themes. <br> To change the standard theme used on the systems, change the configuration on file miolo.conf.<br> To create or modify themes, take a look on the themes folder (under the themes)."
#define WT_CREATE_CONF "miolo.conf is a file which keeps all MIOLO configurations, so, its creation is  needed. <br> <em>Important:</em> in case of MIOLO's update, it is <b>not</b> necessary to re-create it."
#define WT_SHOW_APACHE "To see a VirtualHost configuration suggestion for Apache according to the installation informed data, activate this option."
