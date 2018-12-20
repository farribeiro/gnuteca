/****************************************************************************
** Form implementation generated from reading ui file 'mioloconf.ui'
**
** Created: Sex Out 7 16:10:08 2005
**      by: The User Interface Compiler ($Id: qt/main.cpp   3.3.3   edited Nov 24 2003 $)
**
** WARNING! All changes made in this file will be lost!
****************************************************************************/

#include "mioloconf.h"

#include <qvariant.h>
#include <qpushbutton.h>
#include <qprogressbar.h>
#include <qtabwidget.h>
#include <qwidget.h>
#include <qgroupbox.h>
#include <qlineedit.h>
#include <qlabel.h>
#include <qcombobox.h>
#include <qtextedit.h>
#include <qlayout.h>
#include <qtooltip.h>
#include <qwhatsthis.h>
#include <qimage.h>
#include <qpixmap.h>

#include "../mioloconf.ui.h"
/*
 *  Constructs a FormMioloConf as a child of 'parent', with the
 *  name 'name' and widget flags set to 'f'.
 *
 *  The dialog will by default be modeless, unless you set 'modal' to
 *  TRUE to construct a modal dialog.
 */
FormMioloConf::FormMioloConf( QWidget* parent, const char* name, bool modal, WFlags fl )
    : QDialog( parent, name, modal, fl )
{
    if ( !name )
	setName( "FormMioloConf" );
    setIcon( QPixmap::fromMimeSource( "configure.png" ) );

    btnLoad = new QPushButton( this, "btnLoad" );
    btnLoad->setGeometry( QRect( 12, 440, 130, 26 ) );
    btnLoad->setIconSet( QIconSet( QPixmap::fromMimeSource( "fileimport.png" ) ) );

    progressBar = new QProgressBar( this, "progressBar" );
    progressBar->setEnabled( FALSE );
    progressBar->setGeometry( QRect( 151, 441, 201, 22 ) );
    progressBar->setLineWidth( 0 );
    progressBar->setTotalSteps( 133 );

    btnCancel = new QPushButton( this, "btnCancel" );
    btnCancel->setGeometry( QRect( 450, 440, 82, 26 ) );
    btnCancel->setIconSet( QIconSet( QPixmap::fromMimeSource( "button_cancel.png" ) ) );

    tabWidget = new QTabWidget( this, "tabWidget" );
    tabWidget->setEnabled( TRUE );
    tabWidget->setGeometry( QRect( 10, 10, 580, 420 ) );

    tab = new QWidget( tabWidget, "tab" );

    groupURL = new QGroupBox( tab, "groupURL" );
    groupURL->setGeometry( QRect( 10, 270, 540, 100 ) );

    editUrl = new QLineEdit( groupURL, "editUrl" );
    editUrl->setGeometry( QRect( 80, 30, 390, 22 ) );
    editUrl->setLineWidth( 1 );

    editUrl_Themes = new QLineEdit( groupURL, "editUrl_Themes" );
    editUrl_Themes->setGeometry( QRect( 80, 60, 390, 22 ) );
    editUrl_Themes->setLineWidth( 1 );

    lblUrl = new QLabel( groupURL, "lblUrl" );
    lblUrl->setGeometry( QRect( 28, 30, 50, 20 ) );
    lblUrl->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblUrl_Themes = new QLabel( groupURL, "lblUrl_Themes" );
    lblUrl_Themes->setGeometry( QRect( 12, 60, 66, 20 ) );
    lblUrl_Themes->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    groupHome = new QGroupBox( tab, "groupHome" );
    groupHome->setGeometry( QRect( 10, 20, 540, 230 ) );
    groupHome->setPaletteForegroundColor( QColor( 0, 0, 0 ) );

    lblHtml = new QLabel( groupHome, "lblHtml" );
    lblHtml->setGeometry( QRect( 8, 150, 121, 20 ) );
    lblHtml->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblLogs = new QLabel( groupHome, "lblLogs" );
    lblLogs->setGeometry( QRect( 10, 120, 120, 20 ) );
    lblLogs->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblThemes = new QLabel( groupHome, "lblThemes" );
    lblThemes->setGeometry( QRect( 10, 180, 120, 20 ) );
    lblThemes->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblModules = new QLabel( groupHome, "lblModules" );
    lblModules->setGeometry( QRect( 20, 60, 110, 20 ) );
    lblModules->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblMiolo = new QLabel( groupHome, "lblMiolo" );
    lblMiolo->setGeometry( QRect( 40, 30, 89, 20 ) );
    lblMiolo->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    editModules = new QLineEdit( groupHome, "editModules" );
    editModules->setGeometry( QRect( 130, 60, 340, 22 ) );
    editModules->setLineWidth( 1 );

    editEtc = new QLineEdit( groupHome, "editEtc" );
    editEtc->setEnabled( TRUE );
    editEtc->setGeometry( QRect( 130, 90, 340, 22 ) );
    editEtc->setLineWidth( 1 );

    editLogs = new QLineEdit( groupHome, "editLogs" );
    editLogs->setGeometry( QRect( 130, 120, 340, 22 ) );
    editLogs->setLineWidth( 1 );

    editHtml = new QLineEdit( groupHome, "editHtml" );
    editHtml->setGeometry( QRect( 130, 150, 340, 22 ) );
    editHtml->setLineWidth( 1 );

    editThemes = new QLineEdit( groupHome, "editThemes" );
    editThemes->setGeometry( QRect( 130, 180, 340, 22 ) );
    editThemes->setLineWidth( 1 );

    lblEtc = new QLabel( groupHome, "lblEtc" );
    lblEtc->setGeometry( QRect( 10, 90, 120, 20 ) );
    lblEtc->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    btnClasses = new QPushButton( groupHome, "btnClasses" );
    btnClasses->setGeometry( QRect( 470, 30, 30, 23 ) );
    btnClasses->setPixmap( QPixmap::fromMimeSource( "folder_blue_open.png" ) );
    btnClasses->setOn( FALSE );
    btnClasses->setFlat( TRUE );

    btnModules = new QPushButton( groupHome, "btnModules" );
    btnModules->setGeometry( QRect( 470, 60, 30, 23 ) );
    btnModules->setPixmap( QPixmap::fromMimeSource( "folder_blue_open.png" ) );
    btnModules->setFlat( TRUE );

    btnEtc = new QPushButton( groupHome, "btnEtc" );
    btnEtc->setGeometry( QRect( 470, 90, 30, 23 ) );
    btnEtc->setPixmap( QPixmap::fromMimeSource( "folder_blue_open.png" ) );

    btnLogs = new QPushButton( groupHome, "btnLogs" );
    btnLogs->setGeometry( QRect( 470, 120, 30, 23 ) );
    btnLogs->setPixmap( QPixmap::fromMimeSource( "folder_blue_open.png" ) );

    btnHtml = new QPushButton( groupHome, "btnHtml" );
    btnHtml->setGeometry( QRect( 470, 150, 30, 23 ) );
    btnHtml->setPixmap( QPixmap::fromMimeSource( "folder_blue_open.png" ) );

    btnThemes = new QPushButton( groupHome, "btnThemes" );
    btnThemes->setGeometry( QRect( 470, 180, 30, 23 ) );
    btnThemes->setPixmap( QPixmap::fromMimeSource( "folder_blue_open.png" ) );

    editClasses = new QLineEdit( groupHome, "editClasses" );
    editClasses->setGeometry( QRect( 130, 30, 340, 22 ) );
    editClasses->setLineWidth( 1 );
    tabWidget->insertTab( tab, QString("") );

    tab_2 = new QWidget( tabWidget, "tab_2" );

    groupBisDB = new QGroupBox( tab_2, "groupBisDB" );
    groupBisDB->setGeometry( QRect( 10, 20, 280, 200 ) );

    lblHost = new QLabel( groupBisDB, "lblHost" );
    lblHost->setGeometry( QRect( 30, 60, 70, 20 ) );
    lblHost->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblHost_2 = new QLabel( groupBisDB, "lblHost_2" );
    lblHost_2->setGeometry( QRect( 30, 90, 70, 20 ) );
    lblHost_2->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblHost_3 = new QLabel( groupBisDB, "lblHost_3" );
    lblHost_3->setGeometry( QRect( 30, 120, 70, 20 ) );
    lblHost_3->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblHost_4 = new QLabel( groupBisDB, "lblHost_4" );
    lblHost_4->setGeometry( QRect( 30, 150, 70, 20 ) );
    lblHost_4->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    editDBHost = new QLineEdit( groupBisDB, "editDBHost" );
    editDBHost->setGeometry( QRect( 110, 60, 140, 22 ) );
    editDBHost->setLineWidth( 1 );

    editDBName = new QLineEdit( groupBisDB, "editDBName" );
    editDBName->setGeometry( QRect( 110, 90, 140, 22 ) );
    editDBName->setLineWidth( 1 );

    editDBUser = new QLineEdit( groupBisDB, "editDBUser" );
    editDBUser->setGeometry( QRect( 110, 120, 140, 22 ) );
    editDBUser->setLineWidth( 1 );

    editDBPassword = new QLineEdit( groupBisDB, "editDBPassword" );
    editDBPassword->setGeometry( QRect( 110, 150, 140, 22 ) );
    editDBPassword->setLineWidth( 1 );

    lblDB = new QLabel( groupBisDB, "lblDB" );
    lblDB->setGeometry( QRect( 20, 30, 80, 20 ) );
    lblDB->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    cbDBSystem = new QComboBox( FALSE, groupBisDB, "cbDBSystem" );
    cbDBSystem->setGeometry( QRect( 110, 30, 140, 22 ) );

    groupLogin = new QGroupBox( tab_2, "groupLogin" );
    groupLogin->setGeometry( QRect( 310, 20, 250, 120 ) );

    lblLoginCheck_2 = new QLabel( groupLogin, "lblLoginCheck_2" );
    lblLoginCheck_2->setGeometry( QRect( 20, 50, 80, 20 ) );
    lblLoginCheck_2->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblLoginCheck = new QLabel( groupLogin, "lblLoginCheck" );
    lblLoginCheck->setGeometry( QRect( 10, 20, 90, 20 ) );
    lblLoginCheck->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblLoginCheck_3 = new QLabel( groupLogin, "lblLoginCheck_3" );
    lblLoginCheck_3->setGeometry( QRect( 20, 80, 80, 20 ) );
    lblLoginCheck_3->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    cbLoginCheck = new QComboBox( FALSE, groupLogin, "cbLoginCheck" );
    cbLoginCheck->setGeometry( QRect( 110, 20, 120, 22 ) );

    cbLoginShared = new QComboBox( FALSE, groupLogin, "cbLoginShared" );
    cbLoginShared->setGeometry( QRect( 110, 50, 120, 22 ) );

    cbLoginAuto = new QComboBox( FALSE, groupLogin, "cbLoginAuto" );
    cbLoginAuto->setGeometry( QRect( 110, 80, 120, 22 ) );
    tabWidget->insertTab( tab_2, QString("") );

    tab_3 = new QWidget( tabWidget, "tab_3" );

    groupDump = new QGroupBox( tab_3, "groupDump" );
    groupDump->setGeometry( QRect( 310, 150, 250, 210 ) );

    lblDump = new QLabel( groupDump, "lblDump" );
    lblDump->setGeometry( QRect( 10, 50, 70, 20 ) );
    lblDump->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblDump_2 = new QLabel( groupDump, "lblDump_2" );
    lblDump_2->setGeometry( QRect( 10, 20, 80, 20 ) );
    lblDump_2->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblDump_2_2_3 = new QLabel( groupDump, "lblDump_2_2_3" );
    lblDump_2_2_3->setGeometry( QRect( 10, 140, 80, 20 ) );
    lblDump_2_2_3->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblDump_2_2 = new QLabel( groupDump, "lblDump_2_2" );
    lblDump_2_2->setGeometry( QRect( 10, 80, 80, 20 ) );
    lblDump_2_2->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblDump_2_2_2 = new QLabel( groupDump, "lblDump_2_2_2" );
    lblDump_2_2_2->setGeometry( QRect( 10, 110, 80, 20 ) );
    lblDump_2_2_2->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblDump_2_2_3_2 = new QLabel( groupDump, "lblDump_2_2_3_2" );
    lblDump_2_2_3_2->setGeometry( QRect( 10, 170, 80, 20 ) );
    lblDump_2_2_3_2->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    editDump_Peer = new QLineEdit( groupDump, "editDump_Peer" );
    editDump_Peer->setGeometry( QRect( 90, 50, 140, 22 ) );

    cbProfile = new QComboBox( FALSE, groupDump, "cbProfile" );
    cbProfile->setGeometry( QRect( 90, 80, 140, 22 ) );

    cbUses = new QComboBox( FALSE, groupDump, "cbUses" );
    cbUses->setGeometry( QRect( 90, 110, 140, 22 ) );

    cbTrace = new QComboBox( FALSE, groupDump, "cbTrace" );
    cbTrace->setGeometry( QRect( 90, 140, 140, 22 ) );

    cbHandlers = new QComboBox( FALSE, groupDump, "cbHandlers" );
    cbHandlers->setGeometry( QRect( 90, 170, 140, 22 ) );

    cbDebug = new QComboBox( FALSE, groupDump, "cbDebug" );
    cbDebug->setGeometry( QRect( 90, 20, 140, 22 ) );

    groupTheme = new QGroupBox( tab_3, "groupTheme" );
    groupTheme->setGeometry( QRect( 310, 20, 250, 100 ) );

    lbllookupTheme = new QLabel( groupTheme, "lbllookupTheme" );
    lbllookupTheme->setGeometry( QRect( 10, 60, 80, 20 ) );
    lbllookupTheme->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblmainTheme = new QLabel( groupTheme, "lblmainTheme" );
    lblmainTheme->setGeometry( QRect( 20, 30, 70, 20 ) );
    lblmainTheme->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    editThemeMain = new QLineEdit( groupTheme, "editThemeMain" );
    editThemeMain->setGeometry( QRect( 100, 30, 120, 22 ) );
    editThemeMain->setLineWidth( 1 );

    editThemeLookUp = new QLineEdit( groupTheme, "editThemeLookUp" );
    editThemeLookUp->setGeometry( QRect( 100, 60, 120, 22 ) );
    editThemeLookUp->setLineWidth( 1 );

    groupTrace = new QGroupBox( tab_3, "groupTrace" );
    groupTrace->setGeometry( QRect( 20, 280, 270, 100 ) );

    lblmainTheme_2 = new QLabel( groupTrace, "lblmainTheme_2" );
    lblmainTheme_2->setGeometry( QRect( 10, 30, 70, 20 ) );
    lblmainTheme_2->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    editTrace_Port = new QLineEdit( groupTrace, "editTrace_Port" );
    editTrace_Port->setGeometry( QRect( 90, 30, 120, 22 ) );
    editTrace_Port->setLineWidth( 1 );

    groupOptions = new QGroupBox( tab_3, "groupOptions" );
    groupOptions->setGeometry( QRect( 20, 20, 270, 150 ) );

    lblDispatcher = new QLabel( groupOptions, "lblDispatcher" );
    lblDispatcher->setGeometry( QRect( 10, 50, 90, 20 ) );
    lblDispatcher->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblDispatcher_2 = new QLabel( groupOptions, "lblDispatcher_2" );
    lblDispatcher_2->setGeometry( QRect( 10, 80, 90, 20 ) );
    lblDispatcher_2->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    lblScramble = new QLabel( groupOptions, "lblScramble" );
    lblScramble->setGeometry( QRect( 10, 110, 90, 20 ) );
    lblScramble->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    editStartUp = new QLineEdit( groupOptions, "editStartUp" );
    editStartUp->setGeometry( QRect( 100, 20, 120, 22 ) );
    editStartUp->setLineWidth( 1 );

    editDispatch = new QLineEdit( groupOptions, "editDispatch" );
    editDispatch->setGeometry( QRect( 100, 50, 120, 22 ) );
    editDispatch->setLineWidth( 1 );

    editIndex = new QLineEdit( groupOptions, "editIndex" );
    editIndex->setGeometry( QRect( 100, 80, 120, 22 ) );
    editIndex->setLineWidth( 1 );

    cbScramble = new QComboBox( FALSE, groupOptions, "cbScramble" );
    cbScramble->setGeometry( QRect( 100, 110, 120, 22 ) );

    lblStartUp = new QLabel( groupOptions, "lblStartUp" );
    lblStartUp->setGeometry( QRect( 10, 20, 90, 20 ) );
    lblStartUp->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    groupI18n = new QGroupBox( tab_3, "groupI18n" );
    groupI18n->setGeometry( QRect( 20, 178, 270, 90 ) );

    lblLocale = new QLabel( groupI18n, "lblLocale" );
    lblLocale->setGeometry( QRect( 7, 50, 93, 20 ) );
    lblLocale->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    editLocale = new QLineEdit( groupI18n, "editLocale" );
    editLocale->setGeometry( QRect( 100, 50, 160, 22 ) );
    editLocale->setLineWidth( 1 );

    lblLanguage = new QLabel( groupI18n, "lblLanguage" );
    lblLanguage->setGeometry( QRect( 10, 20, 90, 20 ) );
    lblLanguage->setAlignment( int( QLabel::AlignVCenter | QLabel::AlignRight ) );

    cbLanguage = new QComboBox( FALSE, groupI18n, "cbLanguage" );
    cbLanguage->setGeometry( QRect( 100, 20, 140, 22 ) );
    tabWidget->insertTab( tab_3, QString("") );

    tab_4 = new QWidget( tabWidget, "tab_4" );

    confEdit = new QTextEdit( tab_4, "confEdit" );
    confEdit->setGeometry( QRect( 1, 1, 570, 390 ) );
    confEdit->setLineWidth( 0 );
    confEdit->setReadOnly( TRUE );
    confEdit->setTabStopWidth( 4 );
    tabWidget->insertTab( tab_4, QString("") );

    btnSave = new QPushButton( this, "btnSave" );
    btnSave->setGeometry( QRect( 360, 440, 82, 26 ) );
    btnSave->setIconSet( QIconSet( QPixmap::fromMimeSource( "filesaveas.png" ) ) );
    languageChange();
    resize( QSize(600, 480).expandedTo(minimumSizeHint()) );
    clearWState( WState_Polished );

    // signals and slots connections
    connect( btnCancel, SIGNAL( clicked() ), this, SLOT( close() ) );
    connect( btnLoad, SIGNAL( clicked() ), this, SLOT( btnLoad_clicked() ) );

    // tab order
    setTabOrder( tabWidget, editClasses );
    setTabOrder( editClasses, btnClasses );
    setTabOrder( btnClasses, editModules );
    setTabOrder( editModules, btnModules );
    setTabOrder( btnModules, editEtc );
    setTabOrder( editEtc, btnEtc );
    setTabOrder( btnEtc, editLogs );
    setTabOrder( editLogs, btnLogs );
    setTabOrder( btnLogs, editHtml );
    setTabOrder( editHtml, btnHtml );
    setTabOrder( btnHtml, editThemes );
    setTabOrder( editThemes, btnThemes );
    setTabOrder( btnThemes, editUrl );
    setTabOrder( editUrl, editUrl_Themes );
    setTabOrder( editUrl_Themes, cbDBSystem );
    setTabOrder( cbDBSystem, editDBHost );
    setTabOrder( editDBHost, editDBName );
    setTabOrder( editDBName, editDBUser );
    setTabOrder( editDBUser, editDBPassword );
    setTabOrder( editDBPassword, editThemeMain );
    setTabOrder( editThemeMain, editThemeLookUp );
    setTabOrder( editThemeLookUp, editStartUp );
    setTabOrder( editStartUp, editDispatch );
    setTabOrder( editDispatch, editIndex );
    setTabOrder( editIndex, cbScramble );
    setTabOrder( cbScramble, editTrace_Port );
    setTabOrder( editTrace_Port, cbDebug );
    setTabOrder( cbDebug, cbProfile );
    setTabOrder( cbProfile, cbUses );
    setTabOrder( cbUses, cbTrace );
    setTabOrder( cbTrace, cbHandlers );
    setTabOrder( cbHandlers, btnLoad );
    setTabOrder( btnLoad, btnSave );
    setTabOrder( btnSave, btnCancel );
    setTabOrder( btnCancel, confEdit );
}

/*
 *  Destroys the object and frees any allocated resources
 */
FormMioloConf::~FormMioloConf()
{
    // no need to delete child widgets, Qt does it all for us
}

/*
 *  Sets the strings of the subwidgets using the current
 *  language.
 */
void FormMioloConf::languageChange()
{
    setCaption( tr( "Edit miolo.conf" ) );
    btnLoad->setText( tr( "Load miolo.conf" ) );
    QToolTip::add( btnLoad, tr( "Load miolo.conf" ) );
    btnCancel->setText( tr( "&Cancel" ) );
    groupURL->setTitle( tr( "URL Related" ) );
    lblUrl->setText( tr( "Site URL" ) );
    lblUrl_Themes->setText( tr( "themes URL" ) );
    groupHome->setTitle( tr( "Directory Settings" ) );
    lblHtml->setText( tr( "Html (Browser visible)" ) );
    lblLogs->setText( tr( "Directory for the logs" ) );
    lblThemes->setText( tr( "Path of the themes" ) );
    lblModules->setText( tr( "Modules Directory" ) );
    lblMiolo->setText( tr( "MIOLO Classes" ) );
    lblEtc->setText( tr( "etc Directory" ) );
    btnClasses->setText( QString::null );
    QToolTip::add( btnClasses, tr( "Select directory" ) );
    btnModules->setText( QString::null );
    QToolTip::add( btnModules, tr( "Select directory" ) );
    btnEtc->setText( QString::null );
    QToolTip::add( btnEtc, tr( "Select directory" ) );
    btnLogs->setText( QString::null );
    QToolTip::add( btnLogs, tr( "Select directory" ) );
    btnHtml->setText( QString::null );
    QToolTip::add( btnHtml, tr( "Select directory" ) );
    btnThemes->setText( QString::null );
    QToolTip::add( btnThemes, tr( "Select directory" ) );
    QWhatsThis::add( editClasses, tr( "Directory where the MIOLO Classes \n"
"are located." ) );
    tabWidget->changeTab( tab, tr( "Home Settings" ) );
    groupBisDB->setTitle( tr( "BIS Database Configuration" ) );
    lblHost->setText( tr( "Host" ) );
    lblHost_2->setText( tr( "Name" ) );
    lblHost_3->setText( tr( "User" ) );
    lblHost_4->setText( tr( "Password" ) );
    lblDB->setText( tr( "System Type" ) );
    cbDBSystem->clear();
    cbDBSystem->insertItem( QPixmap::fromMimeSource( "pgsql.png" ), tr( "postgres" ) );
    cbDBSystem->insertItem( QPixmap::fromMimeSource( "mysql.png" ), tr( "mysql" ) );
    cbDBSystem->insertItem( QPixmap::fromMimeSource( "oracle.png" ), tr( "oracle" ) );
    groupLogin->setTitle( tr( "Login Settings" ) );
    lblLoginCheck_2->setText( tr( "Shared Login" ) );
    lblLoginCheck->setText( tr( "Always Check" ) );
    lblLoginCheck_3->setText( tr( "Auto Login" ) );
    cbLoginCheck->clear();
    cbLoginCheck->insertItem( QPixmap::fromMimeSource( "ok.png" ), tr( "true" ) );
    cbLoginCheck->insertItem( QPixmap::fromMimeSource( "no.png" ), tr( "false" ) );
    cbLoginShared->clear();
    cbLoginShared->insertItem( QPixmap::fromMimeSource( "ok.png" ), tr( "true" ) );
    cbLoginShared->insertItem( QPixmap::fromMimeSource( "no.png" ), tr( "false" ) );
    cbLoginAuto->clear();
    cbLoginAuto->insertItem( QPixmap::fromMimeSource( "ok.png" ), tr( "true" ) );
    cbLoginAuto->insertItem( QPixmap::fromMimeSource( "no.png" ), tr( "false" ) );
    tabWidget->changeTab( tab_2, tr( "DB && Password Settings" ) );
    groupDump->setTitle( tr( "Dump Options" ) );
    lblDump->setText( tr( "Dump Peer" ) );
    lblDump_2->setText( tr( "Show Debug?" ) );
    lblDump_2_2_3->setText( tr( "Trace?" ) );
    lblDump_2_2->setText( tr( "Dump Profile?" ) );
    lblDump_2_2_2->setText( tr( "Uses Info?" ) );
    lblDump_2_2_3_2->setText( tr( "Handlers?" ) );
    cbProfile->clear();
    cbProfile->insertItem( QPixmap::fromMimeSource( "ok.png" ), tr( "true" ) );
    cbProfile->insertItem( QPixmap::fromMimeSource( "no.png" ), tr( "false" ) );
    cbUses->clear();
    cbUses->insertItem( QPixmap::fromMimeSource( "ok.png" ), tr( "true" ) );
    cbUses->insertItem( QPixmap::fromMimeSource( "no.png" ), tr( "false" ) );
    cbTrace->clear();
    cbTrace->insertItem( QPixmap::fromMimeSource( "ok.png" ), tr( "true" ) );
    cbTrace->insertItem( QPixmap::fromMimeSource( "no.png" ), tr( "false" ) );
    cbHandlers->clear();
    cbHandlers->insertItem( QPixmap::fromMimeSource( "ok.png" ), tr( "true" ) );
    cbHandlers->insertItem( QPixmap::fromMimeSource( "no.png" ), tr( "false" ) );
    cbDebug->clear();
    cbDebug->insertItem( QPixmap::fromMimeSource( "ok.png" ), tr( "true" ) );
    cbDebug->insertItem( QPixmap::fromMimeSource( "no.png" ), tr( "false" ) );
    groupTheme->setTitle( tr( "Theme Settings" ) );
    lbllookupTheme->setText( tr( "LookUp theme" ) );
    lblmainTheme->setText( tr( "Main theme" ) );
    groupTrace->setTitle( tr( "Trace Options" ) );
    lblmainTheme_2->setText( tr( "Trace Port" ) );
    groupOptions->setTitle( tr( "Misc. Options" ) );
    lblDispatcher->setText( tr( "Dispatcher" ) );
    lblDispatcher_2->setText( tr( "Index File" ) );
    lblScramble->setText( tr( "Scramble URL?" ) );
    cbScramble->clear();
    cbScramble->insertItem( QPixmap::fromMimeSource( "ok.png" ), tr( "true" ) );
    cbScramble->insertItem( QPixmap::fromMimeSource( "no.png" ), tr( "false" ) );
    lblStartUp->setText( tr( "Startup Module" ) );
    groupI18n->setTitle( tr( "i18n" ) );
    lblLocale->setText( tr( "Locale Directory" ) );
    lblLanguage->setText( tr( "Language" ) );
    cbLanguage->clear();
    cbLanguage->insertItem( tr( "pt_BR" ) );
    cbLanguage->insertItem( tr( "en" ) );
    tabWidget->changeTab( tab_3, tr( "Other Options" ) );
    tabWidget->changeTab( tab_4, tr( "View File" ) );
    btnSave->setText( tr( "&Save" ) );
}

