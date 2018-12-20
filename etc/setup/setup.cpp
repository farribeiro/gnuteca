/*************************************************
*                                                * 
*          MIOLO Installation Program            *
*                                                *
*    Author: Vilson Cristiano Gartner  -         *
*            MIOLO Development Coordinator       *
*    E-mail: vgartner@univates.br                *
*                                                *
*    Date: August/2002                           *
*                                                *
*    $Id: setup.cpp,v 1.2 2005/04/03 15:51:48 ematos Exp $
*                                                *
*************************************************/
// Normal installation: files -> destination
// miolo.tar.gz -> into classes dir
// common.tar.gz -> into modules dir
// htdocs.tar.gz -> into htdocs dir
// themes.tar.gz -> into themes dir
// examples.tar.gz -> into modules dir
// tutorial.tar.gz -> into modules dir
// locale.tar.gz -> into locale dir

#include "setup.h"
#include "language.h"
#include "logo_miolo.xpm"

#include <stdlib.h>

#include <qwidget.h>
#include <qhbox.h>
#include <qvbox.h>
#include <qlabel.h>
#include <qlineedit.h>
#include <qpushbutton.h>
#include <qvalidator.h>
#include <qapplication.h>
#include <qvgroupbox.h>
#include <qvgroupbox.h>
#include <qpushbutton.h>
#include <qfiledialog.h>
#include <qmessagebox.h>
#include <qstring.h>
#include <qcheckbox.h>
#include <qcombobox.h>
#include <qimage.h>
#include <qwhatsthis.h>
#include <qtextview.h>
#include <qtextstream.h>
#include <qprogressbar.h>

// Default installation settings
// for version 1.0 final
//#define MIOLO           "/usr/local/miolo/classes"
//#define MODULES      "/usr/local/miolo/modules"
//#define LOCALE         "/usr/local/miolo/locale"
//#define HTML             "/usr/local/miolo/htdocs"
//#define LOGS             "/usr/local/miolo/logs"
//#define THEMES         "/usr/local/miolo/htdocs/themes"
//#define URL_THEMES  "/themes"

#define MIOLO           "/usr/local/bis/html/miolo"
#define MODULES      "/usr/local/bis/html/modules"
#define LOCALE         "/usr/local/bis/locale"
#define HTML             "/usr/local/bis/html"
#define LOGS             "/usr/local/bis/logs"
#define THEMES         "/usr/local/bis/html/miolo/themes"
#define URL_THEMES  "/miolo/themes"

#define URL                "http://www.miolo.localhost"
#define TRACE_PORT  "0"

#define BIS_HOST        "127.0.0.1"
#define BIS_BASE        "bis"
#define BIS_USER        "postgres"
#define BIS_PASSWD   "postgres"

#define CMN_HOST        "127.0.0.1"
#define CMN_BASE        "bis"
#define CMN_USER        "postgres"
#define CMN_PASSWD   "postgres"


Wizard::Wizard( QWidget *parent, const char *name )
: QWizard( parent, name, TRUE )
{
    nextButton()->setText( NEXT );
    backButton()->setText( BACK );
    cancelButton()->setText( CANCEL );
    finishButton()->setText( FINISH );
    
    (void) QWhatsThis::whatsThisButton( helpButton() );
    
    setupPage1();
    setupPage2();
    setupPage3();
    setupPage4();
    setupPage4a();
    setupPage5();
    setupPage6();
}

void Wizard::setupPage1()
{
    page1 = new QHBox( this );
    page1->setSpacing(10);
    
    
    QLabel *info = new QLabel( page1 );
    info->setPalette( darkGray );    
    info->setText( PAGE1_INFO );
    info->setIndent( 8 );
    info->setMinimumWidth( 370 );    
    info->setMaximumWidth( 450 );
    info->setAlignment( AlignTop|AlignLeft );
    //info->setPixmap( QImage(miolo_xpm)  );
    
    QLabel *logo = new QLabel( page1 );
    logo->setPixmap( QPixmap(logo_miolo_xpm)  );
    
    addPage( page1, WELCOME );
    
    setNextEnabled( page1, TRUE );
    setHelpEnabled( page1, FALSE );
}


void Wizard::setupPage2()
{
    page2 = new QHBox( this );
    page2->setSpacing(8);
    
    QLabel *info = new QLabel( page2 );
    info->setPalette( darkGray );
    info->setText( PAGE2_INFO );
    info->setAlignment( AlignTop|AlignLeft );
    info->setIndent(8);
    info->setMaximumWidth( 180 );
    info->setMinimumWidth(180);
    
    QVBox *page = new QVBox( page2 );
    
    QHBox *row1 = new QHBox( page );
    QHBox *row2 = new QHBox( page );
    QHBox *row3 = new QHBox( page );
    QHBox *row4 = new QHBox( page );
    QHBox *row5 = new QHBox( page );
    QHBox *row6 = new QHBox( page );
    QHBox *row7 = new QHBox( page );
    QHBox *row8 = new QHBox( page );
    QHBox *row9 = new QHBox( page );
    
    QLabel *label1 = new QLabel( " htdocs: ", row1 );
    label1->setAlignment( Qt::AlignVCenter );
    
    QLabel *label2 = new QLabel( " MIOLO: ", row2 );
    label2->setAlignment( Qt::AlignVCenter );
    
    QLabel *label3 = new QLabel( LBL_MODULES, row3 );
    label3->setAlignment( Qt::AlignVCenter );
    
    QLabel *label4 = new QLabel( " Locale: ", row4 );
    label4->setAlignment( Qt::AlignVCenter );
    
    QLabel *label5 = new QLabel( " Logs: ", row5 );
    label5->setAlignment( Qt::AlignVCenter );
    
    QLabel *label6 = new QLabel( LBL_THEMES, row6 );
    label6->setAlignment( Qt::AlignVCenter );
    
    QLabel *label7 = new QLabel( " URL Site: ", row7 );
    label7->setAlignment( Qt::AlignVCenter );
    
    QLabel *label8 = new QLabel( LBL_URL_THEMES, row8 );
    label8->setAlignment( Qt::AlignVCenter );
    
    QLabel *label9 = new QLabel( " Trace Port: ", row9 );
    label9->setAlignment( Qt::AlignVCenter );
    
    label1->setMinimumWidth( label8->sizeHint().width() );
    label2->setMinimumWidth( label8->sizeHint().width() );
    label3->setMinimumWidth( label8->sizeHint().width() );
    label4->setMinimumWidth( label8->sizeHint().width() );
    label5->setMinimumWidth( label8->sizeHint().width() );
    label6->setMinimumWidth( label8->sizeHint().width() );
    label7->setMinimumWidth( label8->sizeHint().width() );
    label8->setMinimumWidth( label8->sizeHint().width() );
    label9->setMinimumWidth( label8->sizeHint().width() );
    
    edthtml = new QLineEdit( row1 );
    edthtml->setText(HTML);
    const char * wt_edthtml = WT_EDTHTML;
    QWhatsThis::add( edthtml, wt_edthtml );
    
    QPushButton *btn1 = new QPushButton("...", row1);
    connect( btn1, SIGNAL( clicked() ), this, SLOT( SeleFile1() ) );
    const char *wt_dirbutton = WT_DIRBUTTON;
    QWhatsThis::add( btn1, wt_dirbutton );
    
    edtmiolo = new QLineEdit( row2 );
    edtmiolo->setText(MIOLO);
    const char * wt_edtmiolo = WT_EDTMIOLO;
    QWhatsThis::add( edtmiolo, wt_edtmiolo );
    
    QPushButton *btn2 = new QPushButton("...", row2);
    connect( btn2, SIGNAL( clicked() ), this, SLOT( SeleFile2() ) );
    QWhatsThis::add( btn2, wt_dirbutton );
    
    edtmodules = new QLineEdit( row3 );
    edtmodules->setText(MODULES);
    const char * wt_edtmodules = WT_EDTMODULES;
    QWhatsThis::add( edtmodules, wt_edtmodules );
    
    QPushButton *btn3 = new QPushButton("...", row3);
    connect( btn3, SIGNAL( clicked() ), this, SLOT( SeleFile3() ) );
    QWhatsThis::add( btn3, wt_dirbutton );
    
    edtlocale = new QLineEdit( row4 );    
    edtlocale->setText(LOCALE);
    const char * wt_edtlocale = WT_EDTLOCALE;
    QWhatsThis::add( edtlocale, wt_edtlocale );
    
    QPushButton *btn4 = new QPushButton("...", row4);
    connect( btn4, SIGNAL( clicked() ), this, SLOT( SeleFile4() ) );
    QWhatsThis::add( btn4, wt_dirbutton );
    
    edtlogs = new QLineEdit( row5 );
    edtlogs->setText(LOGS);
    const char * wt_edtlogs = WT_EDTLOGS;
    QWhatsThis::add( edtlogs, wt_edtlogs );
    
    QPushButton *btn5 = new QPushButton("...", row5);
    connect( btn5, SIGNAL( clicked() ), this, SLOT( SeleFile5() ) );
    QWhatsThis::add( btn5, wt_dirbutton );
    
    edtthemes = new QLineEdit( row6 );    
    edtthemes->setText(THEMES);
    const char * wt_edtthemes = WT_EDTTHEMES;
    QWhatsThis::add( edtthemes, wt_edtthemes );
    
    QPushButton *btn6 = new QPushButton("...", row6);
    connect( btn6, SIGNAL( clicked() ), this, SLOT( SeleFile6() ) );
    QWhatsThis::add( btn6, wt_dirbutton );
    
    edturl = new QLineEdit( row7 );    
    edturl->setText(URL);
    const char * wt_edturl = WT_EDTURL;
    QWhatsThis::add( edturl, wt_edturl );
    
    edturl_themes = new QLineEdit( row8 );    
    edturl_themes->setText(URL_THEMES);
    const char * wt_edturl_themes = WT_EDTURL_THEMES;
    QWhatsThis::add( edturl_themes, wt_edturl_themes );
    
    edttrace_port = new QLineEdit( row9 );    
    edttrace_port->setText(TRACE_PORT);
    edttrace_port->setValidator( new QIntValidator( 0, 999999, edttrace_port ) );
    const char * wt_edttrace_port = WT_EDTTRACE_PORT;
    QWhatsThis::add( edttrace_port, wt_edttrace_port );
    
    connect( edttrace_port, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( portChanged( const QString & ) ) );
    
    
    connect( edtmiolo, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( dataChanged( const QString & ) ) );
    connect( edtmodules, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( dataChanged( const QString & ) ) );
    connect( edtlogs, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( dataChanged( const QString & ) ) );
    connect( edthtml, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( dataChanged( const QString & ) ) ); 
    connect( edtthemes, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( dataChanged( const QString & ) ) );
    connect( edturl, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( dataChanged( const QString & ) ) );
    connect( edturl_themes, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( dataChanged( const QString & ) ) );
    connect( edtlocale, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( dataChanged( const QString & ) ) );
    
    addPage( page2, FILE_PATH );
    
}


void Wizard::setupPage3()
{
    page3 = new QHBox( this );
    page3->setSpacing(8);
    
    QLabel *info = new QLabel( page3 );
    info->setPalette( darkGray );
    info->setText( PAGE3_INFO );
    info->setAlignment( AlignTop|AlignLeft );    
    info->setIndent(8);
    info->setMaximumWidth( 180 );
    info->setMinimumWidth(180);
    
    QVBox *page = new QVBox( page3 );
    
    QVGroupBox *group1 = new QVGroupBox( "BIS DataBase:", page );
    
    QHBox *row11 = new QHBox( group1 );
    QHBox *row12 = new QHBox( group1 );
    QHBox *row13 = new QHBox( group1 );
    QHBox *row14 = new QHBox( group1 );
    QHBox *row15 = new QHBox( group1 );
    
    QLabel *label11 = new QLabel( BASE_TYPE, row11 );
    label11->setAlignment( Qt::AlignVCenter );
    
    QLabel *label12 = new QLabel( HOST_IP, row12 );
    label12->setAlignment( Qt::AlignVCenter );
    
    QLabel *label13 = new QLabel( BASE_NAME, row13 );
    label13->setAlignment( Qt::AlignVCenter );
    
    QLabel *label14 = new QLabel( BASE_USER, row14 );
    label14->setAlignment( Qt::AlignVCenter );
    
    QLabel *label15 = new QLabel( BASE_PASSWD, row15 );
    label15->setAlignment( Qt::AlignVCenter );
    
    label11->setMinimumWidth( label11->sizeHint().width() );
    label12->setMinimumWidth( label11->sizeHint().width() );
    label13->setMinimumWidth( label11->sizeHint().width() );
    label14->setMinimumWidth( label11->sizeHint().width() );
    label15->setMinimumWidth( label11->sizeHint().width() );
    
    //edtbis_tipo = new QLineEdit( row11 );
    //edtbis_tipo->setText(BIS_TIPO);
    cbbis_tipo = new QComboBox( TRUE, row11 );
    cbbis_tipo->setEditable( FALSE );
    cbbis_tipo->insertItem( "postgres" );
    cbbis_tipo->insertItem( "mysql" );
    cbbis_tipo->setMinimumWidth( page3->sizeHint().width() - label11->sizeHint().width() +10 );
    const char * wt_base_tipo = WT_BASE_TIPO;
    QWhatsThis::add( cbbis_tipo, wt_base_tipo );
    
    edtbis_host = new QLineEdit( row12 );
    edtbis_host->setText(BIS_HOST);
    const char * wt_base_host = WT_BASE_HOST;
    QWhatsThis::add( edtbis_host, wt_base_host );
    
    edtbis_base = new QLineEdit( row13 );
    edtbis_base->setText(BIS_BASE);
    const char * wt_base_base = WT_BASE_BASE;
    QWhatsThis::add( edtbis_base, wt_base_base );
    
    edtbis_user = new QLineEdit( row14 );
    edtbis_user->setText(BIS_USER);
    const char * wt_base_user = WT_BASE_USER;
    QWhatsThis::add( edtbis_user, wt_base_user );
    
    edtbis_passwd = new QLineEdit( row15 );    
    edtbis_passwd->setText(BIS_PASSWD);
    const char * wt_base_passwd = WT_BASE_PASSWD;
    QWhatsThis::add( edtbis_passwd, wt_base_passwd );
    
    //connect( edtbis_tipo, SIGNAL( textChanged( const QString & ) ),
    //this, SLOT( baseChanged( const QString & ) ) );
    connect( edtbis_host, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( baseChanged( const QString & ) ) );
    connect( edtbis_base, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( baseChanged( const QString & ) ) ); 
    connect( edtbis_user, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( baseChanged( const QString & ) ) );
    connect( edtbis_passwd, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( baseChanged( const QString & ) ) );
    
    
    QVGroupBox *group2 = new QVGroupBox( "Common DataBase:", page );
    
    QHBox *row21 = new QHBox( group2 );
    QHBox *row22 = new QHBox( group2 );
    QHBox *row23 = new QHBox( group2 );
    QHBox *row24 = new QHBox( group2 );
    QHBox *row25 = new QHBox( group2 );
    
    QLabel *label21 = new QLabel( BASE_TYPE, row21 );
    label21->setAlignment( Qt::AlignVCenter );
    
    QLabel *label22 = new QLabel( HOST_IP, row22 );
    label22->setAlignment( Qt::AlignVCenter );
    
    QLabel *label23 = new QLabel( BASE_NAME, row23 );
    label23->setAlignment( Qt::AlignVCenter );
    
    QLabel *label24 = new QLabel( BASE_USER, row24 );
    label24->setAlignment( Qt::AlignVCenter );
    
    QLabel *label25= new QLabel( BASE_PASSWD, row25 );
    label25->setAlignment( Qt::AlignVCenter );
    
    label21->setMinimumWidth( label21->sizeHint().width() );
    label22->setMinimumWidth( label21->sizeHint().width() );
    label23->setMinimumWidth( label21->sizeHint().width() );
    label24->setMinimumWidth( label21->sizeHint().width() );
    label25->setMinimumWidth( label21->sizeHint().width() );
    
    //edtcmn_tipo = new QLineEdit( row21 );
    //edtcmn_tipo->setText(CMN_TIPO);
    cbcmn_tipo = new QComboBox( TRUE, row21 );
    cbcmn_tipo->setEditable( FALSE );
    cbcmn_tipo->insertItem( "postgres" );
    cbcmn_tipo->insertItem( "mysql" );
    cbcmn_tipo->setMinimumWidth( page3->sizeHint().width() - label21->sizeHint().width() + 10 );
    QWhatsThis::add( cbcmn_tipo, wt_base_tipo );
    
    edtcmn_host = new QLineEdit( row22 );
    edtcmn_host->setText(CMN_HOST);
    QWhatsThis::add( edtcmn_host, wt_base_host );
    
    edtcmn_base = new QLineEdit( row23 );
    edtcmn_base->setText(CMN_BASE);
    QWhatsThis::add( edtcmn_base, wt_base_base );
    
    edtcmn_user = new QLineEdit( row24 );
    edtcmn_user->setText(CMN_USER);
    QWhatsThis::add( edtcmn_user, wt_base_user );
    
    edtcmn_passwd = new QLineEdit( row25 );    
    edtcmn_passwd->setText(CMN_PASSWD);
    QWhatsThis::add( edtcmn_passwd, wt_base_passwd );
    
    //    connect( edtcmn_tipo, SIGNAL( textChanged( const QString & ) ),
    //    this, SLOT( baseChanged( const QString & ) ) );
    connect( edtcmn_host, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( baseChanged( const QString & ) ) );
    connect( edtcmn_base, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( baseChanged( const QString & ) ) ); 
    connect( edtcmn_user, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( baseChanged( const QString & ) ) );
    connect( edtcmn_passwd, SIGNAL( textChanged( const QString & ) ),
    this, SLOT( baseChanged( const QString & ) ) );
    
    addPage( page3, DB_SETTINGS );
    
    //   setHelpEnabled( page3, FALSE );
}

void Wizard::setupPage4()
{
    page4 = new QHBox( this );
    page4->setSpacing(8);
    
    QLabel *info = new QLabel( page4 );
    info->setPalette( darkGray );
    info->setText( PAGE4_INFO );
    info->setAlignment( AlignTop|AlignLeft );    
    info->setIndent(8);
    info->setMaximumWidth( 180 );
    info->setMinimumWidth(180);
    
    QVBox *page = new QVBox( page4 );
    
    QHBox *row1 = new QHBox( page );
    QHBox *row2 = new QHBox( page );
    QHBox *row3 = new QHBox( page );
    QHBox *row4 = new QHBox( page );
    QHBox *row5 = new QHBox( page );
    QHBox *row6 = new QHBox( page );
    
    QCheckBox *cbchklogin = new QCheckBox( ALWAYS_CHECK_LOGIN, row1);
    cbchklogin->setChecked(false);
    docheckLogin = false;
    connect( cbchklogin, SIGNAL( toggled(bool) ), this, SLOT( checkloginCheck(bool) ) );
    const char * wt_mklogin = WT_MKLOGIN;
    QWhatsThis::add( cbchklogin, wt_mklogin );
    
    QCheckBox *cbshrlogin = new QCheckBox( MIOLO_CONTROLS_LOGIN, row2);
    cbshrlogin->setChecked(true);
    connect( cbshrlogin, SIGNAL( toggled(bool) ), this, SLOT( sharedloginCheck(bool) ) );
    const char * wt_miolologin = WT_MIOLOLOGIN;
    QWhatsThis::add( cbshrlogin, wt_miolologin );
    
    QCheckBox *cbautlogin = new QCheckBox( AUTO_LOGIN, row3);
    cbautlogin->setChecked(false);
    doautoLogin = false;
    connect( cbautlogin, SIGNAL( toggled(bool) ), this, SLOT( autologinCheck(bool) ) );
    const char * wt_autologin = WT_AUTOLOGIN;
    QWhatsThis::add( cbautlogin, wt_autologin );
    
    QLabel *label4 = new QLabel( AUTO_LOGIN_ID, row4 );
    label4->setAlignment( Qt::AlignVCenter );
    
    QLabel *label5 = new QLabel( AUTO_LOGIN_PASS, row5 );
    label5->setAlignment( Qt::AlignVCenter );
    
    QLabel *label6 = new QLabel( USER_NAME, row6 );
    label6->setAlignment( Qt::AlignVCenter );
    
    label4->setMinimumWidth( label5->sizeHint().width() );
    label5->setMinimumWidth( label5->sizeHint().width() );
    label6->setMinimumWidth( label5->sizeHint().width() );
    
    edtlogin_id = new QLineEdit( row4 );
    edtlogin_id->setText("guest");
    edtlogin_id->setEnabled(false);
    const char * wt_edtlogin_id = WT_LOGINID;
    QWhatsThis::add( edtlogin_id, wt_edtlogin_id );
    
    edtlogin_pass = new QLineEdit( row5 );
    edtlogin_pass->setText("guest");
    edtlogin_pass->setEnabled(false);
    const char * wt_edtlogin_pass = WT_LOGINPWD;
    QWhatsThis::add( edtlogin_pass, wt_edtlogin_pass );
    
    edtlogin_name = new QLineEdit( row6 );
    edtlogin_name->setText("Guest User");
    edtlogin_name->setEnabled(false);
    const char * wt_edtlogin_name = WT_LOGINNAME;
    QWhatsThis::add( edtlogin_name, wt_edtlogin_name );
    
    addPage( page4, LOGIN_SETTINGS );
    
    //    setHelpEnabled( page4, FALSE );
}

void Wizard::setupPage4a()
{
    page4a = new QHBox( this );
    page4a->setSpacing(8);
    
    QLabel *info = new QLabel( page4a );
    info->setPalette( darkGray );
    info->setText( PAGE4A_INFO );
    info->setAlignment( AlignTop|AlignLeft );
    info->setIndent(8);
    info->setMaximumWidth( 180 );
    info->setMinimumWidth(180);
    
    QVBox *page = new QVBox( page4a );
    
    QHBox *row1 = new QHBox( page );
    QHBox *row2 = new QHBox( page );
    QHBox *row3 = new QHBox( page );
    QHBox *row4 = new QHBox( page );
    QHBox *row5 = new QHBox( page );
    QHBox *row6 = new QHBox( page );
    
    QCheckBox *chb_inst_miolo = new QCheckBox( INSTALL_MIOLO_CLASSES, row1);
    if (  ! QFile::exists( QDir::currentDirPath() + "/miolo" ) )
    {
        chb_inst_miolo->setEnabled(false);
        chb_inst_miolo->setChecked(false);
        installMiolo = false;
    }
    else
    {
        chb_inst_miolo->setEnabled(true);
        chb_inst_miolo->setChecked(true);
        installMiolo = true;
    }
    connect( chb_inst_miolo, SIGNAL( toggled(bool) ), this, SLOT( setinstallMiolo(bool) ) );
    const char * wt_install_miolo = WT_INSTALL_MIOLO;
    QWhatsThis::add( chb_inst_miolo, wt_install_miolo );
    
    QCheckBox *chb_inst_common = new QCheckBox( INSTALL_COMMON, row2);
    if (  ! QFile::exists( QDir::currentDirPath() + "/common" ) )
    {
        chb_inst_common->setEnabled(false);
        chb_inst_common->setChecked(false);
        installCommon = false;
    }
    else
    {
        chb_inst_common->setEnabled(true);
        chb_inst_common->setChecked(true);	
        installCommon = true;
    }
    connect( chb_inst_common, SIGNAL( toggled(bool) ), this, SLOT( setinstallCommon(bool) ) );
    const char * wt_install_common = WT_INSTALL_COMMON;
    QWhatsThis::add( chb_inst_common, wt_install_common );
    
    QCheckBox *chb_inst_examples = new QCheckBox( INSTALL_EXAMPLES, row3);
    if ( (  ! QFile::exists( QDir::currentDirPath() + "/tutorial" ) ) && (  ! QFile::exists( QDir::currentDirPath() + "/examples" ) ) )
    {
        chb_inst_examples->setEnabled(false);
        chb_inst_examples->setChecked(false);
        installExamples = false;
    }
    else
    {
        chb_inst_examples->setEnabled(true);
        chb_inst_examples->setChecked(true);	
        installExamples = true;
    }
    connect( chb_inst_examples, SIGNAL( toggled(bool) ), this, SLOT( setinstallExamples(bool) ) );
    const char * wt_install_examples = WT_INSTALL_EXAMPLES;
    QWhatsThis::add( chb_inst_examples, wt_install_examples );
    
    QCheckBox *chb_inst_themes = new QCheckBox( INSTALL_THEMES, row4);
    if (  ! QFile::exists( QDir::currentDirPath() + "/themes" ) )
    {
        chb_inst_themes->setEnabled(false);
        chb_inst_themes->setChecked(false);
        installThemes = false;
    }
    else
    {
        chb_inst_themes->setEnabled(true);
        chb_inst_themes->setChecked(true);	
        installThemes = true;
    }
    connect( chb_inst_themes, SIGNAL( toggled(bool) ), this, SLOT( setinstallThemes(bool) ) );
    const char * wt_install_themes = WT_INSTALL_THEMES;
    QWhatsThis::add( chb_inst_themes, wt_install_themes );
    
    QCheckBox *chb_create_conf = new QCheckBox( CREATE_CONF_FILE, row5);
    // for  version 1.0 final    if (  QFile::exists( edthtml->text() + "/../miolo.conf" ) )
    if (  QFile::exists( edtmiolo->text() + "/miolo.conf" ) )
    {
        chb_create_conf->setChecked(false);
        createConf = false;
    }
    else
    {
        chb_create_conf->setChecked(true);
        createConf = true;
    }
    connect( chb_create_conf, SIGNAL( toggled(bool) ), this, SLOT( setcreateConf(bool) ) );
    const char * wt_create_conf = WT_CREATE_CONF;
    QWhatsThis::add( chb_create_conf, wt_create_conf );
    
    QCheckBox *chb_show_virthost = new QCheckBox( SHOW_APACHE_EXAMPLE, row6);
    chb_show_virthost->setChecked(true);
    connect( chb_show_virthost, SIGNAL( toggled(bool) ), this, SLOT( toggleVirtHost(bool) ) );
    const char * wt_show_apache = WT_SHOW_APACHE;
    QWhatsThis::add( chb_show_virthost, wt_show_apache );
    
    addPage( page4a, INSTALL_OPTIONS );
    
    //    setHelpEnabled( page4a, FALSE );
}


void Wizard::setupPage5()
{
    page5 = new QHBox( this );
    page5->setSpacing(8);
    
    QLabel *info = new QLabel( page5 );
    info->setPalette( darkGray );
    info->setText( PAGE5_INFO );
    info->setAlignment( AlignTop|AlignLeft );
    info->setIndent(8);
    info->setMaximumWidth( 180 );
    info->setMinimumWidth(180);
    
    //    QVBox *page = new QVBox( page5 );
    apache = new QTextView( page5 );
    
    //    view->setText( sayings[0] );
    
    addPage( page5, APACHE_EXAMPLE );
    
    setHelpEnabled( page5, FALSE );
}



void Wizard::setupPage6()
{
    page6 = new QHBox( this );
    page6->setSpacing(8);
    
    QLabel *info = new QLabel( page6 );
    info->setPalette( darkGray );
    info->setText( PAGE6_INFO );
    info->setIndent(8);
    info->setAlignment( AlignTop|AlignLeft );
    info->setMaximumWidth( 180 );
    info->setMinimumWidth(180);
    
    QVBox *page = new QVBox( page6 );
    QHBox *row1 = new QHBox( page );
    QVBox *row2 = new QVBox( page );
    QHBox *row3 = new QHBox( page );
    
    progressLabel = new QLabel( WAITING_INSTALL_TO_START, row1 );
    progressBar1 = new QProgressBar( row2 );
    
    btnStart = new QPushButton( BTN_START_INSTALL, row3);
    connect( btnStart, SIGNAL( clicked() ), this, SLOT( startInstall() ) );
    
    addPage( page6, INSTALL_PROCESS );
    
    setFinishEnabled( page6, FALSE );
    setHelpEnabled( page6, FALSE );
}


void Wizard::showPage( QWidget *page )
{
    if ( page == page5) 
    {
        apache->setText("");
        apache->append( SUGESTION_APACHE );
        apache->append("\n");
        apache->append("<VirtualHost *>\n");
        apache->append("    ServerAdmin root@localhost\n");
        apache->append("    DocumentRoot " + edthtml->text());
        apache->append("    ServerName " + edturl->text()  + "  #Remove the 'http://'");
        apache->append("    ErrorLog "   + edtlogs->text() + "/miolo.error_log");
        
        apache->append("    CustomLog " +edtlogs->text()+"/miolo.access_log common\n\n");
        
        apache->append("    <Directory \"" + edthtml->text() + "\">\n");
        apache->append("        Options FollowSymLinks\n");
        apache->append("        AllowOverride All\n");
        apache->append("        Order allow, deny\n");
        apache->append("        Allow from all\n");
        apache->append("    </Directory>\n\n");
        
        apache->append("</VirtualHost>\n");
        //        finishButton()->setEnabled( TRUE );
        //        finishButton()->setFocus();
    }
    
    if ( QWizard::currentPage() ==  page2)
    {
        QDir d ( edthtml->text() );
        edthtml->setText( d.absPath() );
        
        QDir d1 ( edtmiolo->text() );
        edtmiolo->setText( d1.absPath() );
        
        QDir d2 ( edtmodules->text() );
        edtmodules->setText( d2.absPath() );
        
        QDir d3 ( edtlocale->text() );
        edtlocale->setText( d3.absPath() );
        
        QDir d4 ( edtlogs->text() );
        edtlogs->setText( d4.absPath() );
        
        QDir d5 ( edtthemes->text() );
        edtthemes->setText( d5.absPath() );
    }
    
    if ( (QWizard::currentPage() == page4a) && (page == page5) && ( ! show_VirtualHost ) )
    {
        page = page6;
    }
    else if ( (QWizard::currentPage() == page6) && (page == page5) && ( ! show_VirtualHost ) )
    {
        page = page4a;
    }
    
    QWizard::showPage(page);
}

void Wizard::dataChanged( const QString & )
{
    if ( ! edtmiolo->text().isEmpty() &&
        ! edtmodules->text().isEmpty() &&
        ! edthtml->text().isEmpty() &&
        ! edtthemes->text().isEmpty() &&
        ! edturl->text().isEmpty() &&
        ! edturl_themes->text().isEmpty() &&
        ! edtlocale->text().isEmpty() &&
        ! edtlogs->text().isEmpty()  ) 
        {
            nextButton()->setEnabled( TRUE );
        }
        else
        {
            nextButton()->setEnabled( FALSE );
        }
}

void Wizard::portChanged( const QString &text )
{
    QString t = text;
    int p = 0;
    bool on = ( edttrace_port->validator()->validate(t, p) == QValidator::Acceptable );
    nextButton()->setEnabled( on );
}

void Wizard::baseChanged( const QString & )
{
    if ( ! edtbis_host->text().isEmpty() &&
        ! edtbis_base->text().isEmpty() &&
        ! edtbis_user->text().isEmpty() &&
        ! edtbis_passwd->text().isEmpty() &&
        ! edtcmn_host->text().isEmpty() &&
        ! edtcmn_base->text().isEmpty() &&
        ! edtcmn_user->text().isEmpty() &&
        ! edtcmn_passwd->text().isEmpty() ) 
        {
            nextButton()->setEnabled( TRUE );
        }
        else
        {
            nextButton()->setEnabled( FALSE );
        }
}

void Wizard::SeleFile1( )
{
    QFileDialog *dlg = new QFileDialog( edthtml->text(), QString::null, 0, 0, TRUE );
    
    dlg->setCaption( QFileDialog::tr( SELE_DIR ) );
    dlg->setMode( QFileDialog::DirectoryOnly );
    if ( dlg->exec() )
    {
        edthtml->setText( (const char*) dlg->selectedFile() );
    }
}

void Wizard::SeleFile2( )
{
    QFileDialog *dlg = new QFileDialog( edtmiolo->text(), QString::null, 0, 0, TRUE );
    
    dlg->setCaption( QFileDialog::tr( SELE_DIR ) );
    dlg->setMode( QFileDialog::DirectoryOnly );
    if ( dlg->exec() )
    {
        edtmiolo->setText( (const char*) dlg->selectedFile() );
    }
}

void Wizard::SeleFile3( )
{
    QFileDialog *dlg = new QFileDialog( edtmodules->text(), QString::null, 0, 0, TRUE );
    
    dlg->setCaption( QFileDialog::tr( SELE_DIR ) );
    dlg->setMode( QFileDialog::DirectoryOnly );
    if ( dlg->exec() )
    {
        edtmodules->setText( (const char*) dlg->selectedFile() );
    }
}

void Wizard::SeleFile4( )
{
    QFileDialog *dlg = new QFileDialog( edtlocale->text(), QString::null, 0, 0, TRUE );
    
    dlg->setCaption( QFileDialog::tr( SELE_DIR ) );
    dlg->setMode( QFileDialog::DirectoryOnly );
    if ( dlg->exec() )
    {
        edtlocale->setText( (const char*) dlg->selectedFile() );
    }
}

void Wizard::SeleFile5( )
{
    QFileDialog *dlg = new QFileDialog( edtlogs->text(), QString::null, 0, 0, TRUE );
    
    dlg->setCaption( QFileDialog::tr( SELE_DIR ) );
    dlg->setMode( QFileDialog::DirectoryOnly );
    if ( dlg->exec() )
    {
        edtlogs->setText( (const char*) dlg->selectedFile() );
    }
}

void Wizard::SeleFile6( )
{
    QFileDialog *dlg = new QFileDialog( edtthemes->text(), QString::null, 0, 0, TRUE );
    
    dlg->setCaption( QFileDialog::tr( SELE_DIR ) );
    dlg->setMode( QFileDialog::DirectoryOnly );
    if ( dlg->exec() )
    {
        edtthemes->setText( (const char*) dlg->selectedFile() );
    }
}

void Wizard::autologinCheck( bool on )
{ 
    if ( on )
    {
        edtlogin_id->setEnabled(true);
        edtlogin_pass->setEnabled(true);
        edtlogin_name->setEnabled(true);
    }
    else
    {
        edtlogin_id->setEnabled(false);
        edtlogin_pass->setEnabled(false);
        edtlogin_name->setEnabled(false);	
    }
    
    doautoLogin = on;
}

void Wizard::sharedloginCheck( bool on )
{
    dosharedLogin = on;
}
void Wizard::checkloginCheck( bool on )
{
    docheckLogin = on;
}

void Wizard::toggleVirtHost( bool on )
{
    show_VirtualHost = on;
}

void Wizard::startInstall()
{
    int i=0;
    btnStart->setEnabled( FALSE );
    QFile logFile( "/tmp/miolo_install.log" );
    
    logFile.open( IO_WriteOnly );
    
    QTextStream logStream( &logFile );
    
    progressBar1->setTotalSteps( 21 );
    progressBar1->setProgress( i++ );
    progressBar1->reset();
    
    logStream << "MIOLO Installation Log \n\n";
    
    progressLabel->setText( CREATING_DIRS );
    logStream << "- Checking directories...\n";
    
    QDir dirMiolo( edtmiolo->text() );
    QDir dirHtml( edthtml->text() );
    QDir dirModules( edtmodules->text() );
    QDir dirLogs( edtlogs->text() );
    QDir dirThemes( edtthemes->text() );
    QDir dirLocale( edtlocale->text() );
    
    if ( ! dirMiolo.exists() )
    {
        logStream << "    - Creating directory miolo\n";
        makeDir( edtmiolo->text() );	
    }
    else
    {
        logStream << "    - Directory miolo already exists.\n";
    }
    progressBar1->setProgress( i++ );
    
    if ( ! dirHtml.exists() )
    {
        //for version 1.0 logStream << "    - Creating directory htdocs\n";
        logStream << "    - Creating directory html\n";
        makeDir( edthtml->text() );
    }      
    else
    {
        //for version 1.0 logStream << "    - Directory htdocs already exists.\n";
        logStream << "    - Directory html already exists.\n";
    }
    progressBar1->setProgress( i++ );
    
    if ( ! dirModules.exists() )
    {
        logStream << "    - Creating directory modules\n";
        makeDir( edtmodules->text() );
    }
    else
    {
        logStream << "    - Directory modules already exists.\n";
    }
    progressBar1->setProgress( i++ );
    
    if ( ! dirLogs.exists() )
    {
        logStream << "    - Creating directory logs\n";
        makeDir( edtlogs->text() );
    }
    else
    {
        logStream << "    - Directory logs already exists.\n";
    }
    progressBar1->setProgress( i++ );
    
    if ( ! dirThemes.exists() )
    {
        logStream << "    - Creating directory themes\n";
        makeDir( edtthemes->text() );
    }
    else
    {
        logStream << "    - Directory themes already exists.\n";
    }
    progressBar1->setProgress( i++ );
    
    if ( ! dirLocale.exists() )
    {
        logStream << "    - Creating directory locale\n";
        makeDir( edtlocale->text() );
    }
    else
    {
        logStream << "    - Directory locale already exists.\n";
    }
    progressBar1->setProgress( i++ );
    
    // install the files
    if ( installMiolo )
    {	
        progressLabel->setText( INSTALLING_HTDOCS );
        logStream << "- Installing htdocs files\n";
        
        if ( ! QFile::exists( QDir::currentDirPath() + "/html" ) )
        {
            QMessageBox::critical( 0, "MIOLO Installer", MSG_HTDOCS_FILE_NOT_FOUND );
            logStream << "- html not found in current directory. Will not be installed. (Probably MIOLO will not work.\n";
        }
        else
        {
            // install htdocs
            if ( copyFile("./html/*", edthtml->text() ) < 0 )
            {
                logStream << "    - Error copying html.\n";
            }
            else
            {
                logStream << "    - html sucessfully copied.\n";
            }

            if ( copyFile("./html/.htaccess", edthtml->text() ) < 0 )
            {
                logStream << "    - Error copying html/.htaccess.\n";
            }
            else
            {
                logStream << "    - html/.htaccess sucessfully copied.\n";
            }
        }
    }
    progressBar1->setProgress( i++ );
    
    
    if ( installMiolo )
    {
        progressLabel->setText( INSTALLING_MIOLO_FILES );
        logStream << "- Installing MIOLO files\n";
        
        if (  ! QFile::exists( QDir::currentDirPath() + "/miolo" ) )
        {
            QMessageBox::critical( 0, "MIOLO Installer", MSG_MIOLO_FILE_NOT_FOUND);
            logStream << "- MIOLO files not found in current directory. Will not be installed.\n";
        }
        else
        {
            // Install miolo
            if ( copyFile("./miolo/*", edtmiolo->text() ) < 0 )
            {
                logStream << "    - Error copying miolo's classes.\n";
            }
            else
            {
                logStream << "    - miolo copied sucessfully.\n";
            }
        }
         if (  ! QFile::exists( QDir::currentDirPath() + "/modules" ) )
        {
            logStream << "- modules not found. Will not be installed.\n";
        }
        else
        {
            // install modules
            if ( copyFile("./modules/*", edtmodules->text() ) < 0 )
            {
                logStream << "    - Error copying modules.\n";
            }
            else
            {
                logStream << "    - modules sucessfully copied.\n";
            }
	}
	
        if (  ! QFile::exists( QDir::currentDirPath() + "/locale" ) )
        {
            QMessageBox::critical( 0, "MIOLO Installer", MSG_LOCALE_FILE_NOT_FOUND);
            logStream << "- locale not found in current directory. Will not be installed.\n";
        }
        else
        {
            // Install locale
            if ( copyFile("./locale/*", edtlocale->text() ) < 0 )
            {
                logStream << "    - Error copying locale.\n";
            }
            else
            {
                logStream << "    - locale copied sucessfully.\n";
            }
        }
    }
    progressBar1->setProgress( i++ );
    
    
    if ( installCommon )
    {
        progressLabel->setText( INSTALLING_COMMON );
        logStream << "- Installing common module files\n";
        
        if ( ! QFile::exists( QDir::currentDirPath() + "/common" ) )
        {
            QMessageBox::critical( 0, "MIOLO Installer", MSG_COMMON_FILE_NOT_FOUND );
            logStream << "- common not found in current directory. Will not be installed.\n";
        }
        else
        {
            // install common
            if ( copyFile("./common", edtmodules->text()+ "/common" ) < 0 )
            {
                logStream << "    - Error copying common.\n";
            }
            else
            {
                logStream << "    - common sucessfully copied.\n";
            }
        }
    }
    progressBar1->setProgress( i++ );
    
    if ( installExamples )
    {
        progressLabel->setText( INSTALLING_EXAMPLES );
        logStream << "- Installing sample module files\n";
        
        if ( ! QFile::exists( QDir::currentDirPath() + "/sample" ) )
        {
            //QMessageBox::critical( 0, "MIOLO Installer", MSG_EXAMPLES_FILE_NOT_FOUND );
            logStream << "- sample not found in current directory. Will not be installed.\n";
        }
        else
        {
            // install examples
            if ( copyFile("./sample", edtmodules->text()+ "/sample" ) < 0 )
            {
                logStream << "    - Error copying sample.\n";
            }
            else
            {
                logStream << "    - sample sucessfully copied.\n ";
            }
        }
        
        if ( ! QFile::exists( QDir::currentDirPath() + "/tutorial" ) )
        {
            //QMessageBox::critical( 0, "MIOLO Installer", MSG_EXAMPLES_FILE_NOT_FOUND );
            logStream << "- tutorial not found in current directory. Will not be installed.\n";
        }
        else
        {
            // install examples
            if ( copyFile("./tutorial", edtmodules->text()+ "/tutorial" ) < 0 )
            {
                logStream << "    - Error copying tutorial.\n";
            }
            else
            {
                logStream << "    - tutorial sucessfully copied.\n";
            }
        }
        
    }
    progressBar1->setProgress( i++ );
    
    if ( installThemes )
    {
        progressLabel->setText( INSTALLING_THEMES );
        logStream << "- Installing themes files\n";
        
        if ( ! QFile::exists( QDir::currentDirPath() + "/themes" ) )
        {
            QMessageBox::critical( 0, "MIOLO Installer", MSG_THEMES_FILE_NOT_FOUND );
            logStream << "- themes not found in current directory. Will not be installed.\n";
        }
        else
        {
            // install themes
            if ( copyFile("./themes/*", edtthemes->text() ) < 0 )
            {
                logStream << "    - Error copying themes.\n";
            }
            else
            {
                logStream << "    - themes sucessfully copied.\n";
            }
        }
    }
    progressBar1->setProgress( i++ );
    
    // create miolo.conf file
    if ( createConf )
    {
        progressLabel->setText( CREATING_MIOLOCONF );
        logStream << "- Creating miolo.conf file....\n";
        
        QDir dir = QDir::currentDirPath();
        /* for version 1.0
        dir.setPath( edthtml->text() );
        dir.cd( "..");
        */
        dir.setPath( edtmiolo->text() );
        
        QFile file( dir.path() +"/miolo.conf" );
        
        if ( file.open( IO_WriteOnly ) )
        {
            QTextStream stream( &file );
            
            stream << "<?php \n// MIOLO Configuration File \n#Generator: MIOLO Installer by Vilson C. Gartner - vgartner@univates.br" << "\n\n#START_MIOLO Config\n\n";
            
            progressBar1->setProgress( i++ );
            stream << "$MIOLOCONF['home']['html']       = '" << edthtml->text() << "'; \n";
            
            progressBar1->setProgress( i++ );
            stream << "$MIOLOCONF['home']['logs']       = '" << edtlogs->text() << "'; \n";
            
            progressBar1->setProgress( i++ );
            stream << "$MIOLOCONF['home']['miolo']      = '" << edtmiolo->text() << "'; \n";
            
            progressBar1->setProgress( i++ );
            stream << "$MIOLOCONF['home']['modules']    = '" << edtmodules->text() << "'; \n";
            
            progressBar1->setProgress( i++ );
            stream << "$MIOLOCONF['home']['themes']     = '" << edtthemes->text() << "'; \n";
            
            progressBar1->setProgress( i++ );
            stream << "$MIOLOCONF['home']['url']        = '" << edturl->text() << "'; \n";
            
            progressBar1->setProgress( i++ );
            stream << "$MIOLOCONF['home']['url.themes'] = '" << edturl_themes->text() << "'; \n\n";
            
            progressBar1->setProgress( i++ );
            stream << "$MIOLOCONF['i18n']['language'] = '" << LANGUAGE << "'; \n";
            
            progressBar1->setProgress( i++ );
            stream << "$MIOLOCONF['i18n']['locale']   = '" << edtlocale->text() << "'; \n\n";
            
            stream << "$MIOLOCONF['theme']['main']   = 'miolo' ;\n";
            stream << "$MIOLOCONF['theme']['lookup'] = 'miolo' ;\n\n";
            
            stream << "$MIOLOCONF['trace_port'] = '" << edttrace_port->text() << "'; \n\n";
            
            stream << "$MIOLOCONF['options']['dispatch'] = 'handler.php'; \n";
            stream << "$MIOLOCONF['options']['index']    = 'index.html'; \n\n";
            
            stream << "$MIOLOCONF['options']['debug'] = false; \n\n";
            stream << "$MIOLOCONF['options']['dump']['peer']     = array('192.168.0.40'); \n";
            stream << "$MIOLOCONF['options']['dump']['profile']  = false; \n";
            stream << "$MIOLOCONF['options']['dump']['uses']     = false; \n";
            stream << "$MIOLOCONF['options']['dump']['trace']    = false; \n";
            stream << "$MIOLOCONF['options']['dump']['handlers'] = false; \n\n";
            
            stream << "// DB Settings\n";
            stream << "$MIOLOCONF['DB']['common']['system']   = '" << cbcmn_tipo->currentText() << "'; \n";
            stream << "$MIOLOCONF['DB']['common']['host']     = '" << edtcmn_host->text() << "'; \n";
            stream << "$MIOLOCONF['DB']['common']['name']     = '" << edtcmn_base->text() << "'; \n";
            stream << "$MIOLOCONF['DB']['common']['user']     = '" << edtcmn_user->text() << "'; \n";
            stream << "$MIOLOCONF['DB']['common']['password'] = '" << edtcmn_passwd->text() << "'; \n\n";
            
            stream << "$MIOLOCONF['DB']['bis']['system']   = '" << cbbis_tipo->currentText() << "'; \n";
            stream << "$MIOLOCONF['DB']['bis']['host']     = '" << edtbis_host->text() << "'; \n";
            stream << "$MIOLOCONF['DB']['bis']['name']     = '" << edtbis_base->text() << "'; \n";
            stream << "$MIOLOCONF['DB']['bis']['user']     = '" << edtbis_user->text() << "'; \n";
            stream << "$MIOLOCONF['DB']['bis']['password'] = '" << edtbis_passwd->text() << "'; \n\n";
            
            stream << "// Login properties\n";
            stream << "$MIOLOCONF['login']['check']  = ";
            if ( docheckLogin )
            {
                stream << "true; \n";
            }
            else
            {
                stream << "false; \n";
            }
            
            stream << "$MIOLOCONF['login']['shared'] = ";
            if ( dosharedLogin )
            {
                stream << "true; \n";
            }
            else
            {
                stream << "false; \n";
            }
            
            if ( doautoLogin )
            {
                stream << "//$MIOLOCONF['login']['auto'] = false; \n";
                stream << "$MIOLOCONF['login']['auto']   = 'public1'; \n\n";
            }
            else
            {
                stream << "$MIOLOCONF['login']['auto']   = false; \n";
                stream << "//$MIOLOCONF['login']['auto'] = 'public1'; \n\n";
            }
            
            stream << "$MIOLOCONF['login']['public1']['id']       = '" << edtlogin_id->text() << "'; \n";
            stream << "$MIOLOCONF['login']['public1']['password'] = '" << edtlogin_pass->text() << "'; \n";
            stream << "$MIOLOCONF['login']['public1']['name']     = '" << edtlogin_name->text() << "'; \n\n";
            stream << "#END_MIOLO Config \n\n?>";
            file.close();
            logStream << "    - miolo.conf created.\n";
            
            progressBar1->setProgress( i++ );
        }
        else
        {
            logStream << "- Problems creating miolo.conf (user's write permission?!) \n";
            
            QMessageBox::critical( 0, "MIOLO Installer", MSG_ERROR_CREATING_MIOLOCONF );
        }
    }
    progressLabel->setText( INSTALLATION_FINISHED );
    
    finishButton()->setEnabled( TRUE );
    
    logStream << "\n INTALLATION FINISHED.\n";
    logFile.close();   
    
    QMessageBox::information( 0, "MIOLO Installer", INSTALL_END );
}

void Wizard::setinstallMiolo(bool on)
{
    installMiolo = on;
}

void Wizard::setinstallCommon(bool on)
{
    installCommon = on;
}

void Wizard::setinstallExamples(bool on)
{
    installExamples = on;
}

void Wizard::setinstallThemes(bool on)
{
    installThemes = on;
}

void Wizard::setcreateConf(bool on)
{
    createConf = on;
    if ( on )
    {
        /* for version 1.0 final if (  QFile::exists( edthtml->text() + "/../miolo.conf" ) )
        {
            QMessageBox::warning( 0, "MIOLO Installer",  MSG_MIOLOCONF_EXISTS +edthtml->text() + "/../miolo.conf");
        }
        */
        if (  QFile::exists( edtmiolo->text() + "/miolo.conf" ) )
        {
            QMessageBox::warning( 0, "MIOLO Installer",  MSG_MIOLOCONF_EXISTS +edtmiolo->text() + "/miolo.conf");
        }
        
        
    }
}

void Wizard::makeDir( const QString dirName)
{
    QDir dir = QDir::currentDirPath();
    dir.setPath( "/" );
    
    QStringList dirs = QStringList::split( "/", dirName );
    
    for ( int i=0; i < (int) dirs.count(); i++ )
    {
        if ( dir.exists( dirs[i] ) )
        {
            dir.cd( dirs[i] );
        }
        else
        {
            dir.mkdir( dirs[i] );
            dir.cd( dirs[i] );
            //   qDebug("Diret?rio atual: "+dir.path() );
        }
    }
}

int Wizard::copyFile(QString infile, QString outfile)
{
  return system("cp -R  " + infile + " " + outfile);
}
