/****************************************************************************
** Form implementation generated from reading ui file 'mainform.ui'
**
** Created: Sex Out 7 16:10:01 2005
**      by: The User Interface Compiler ($Id: qt/main.cpp   3.3.3   edited Nov 24 2003 $)
**
** WARNING! All changes made in this file will be lost!
****************************************************************************/

#include "mainform.h"

#include <qvariant.h>
#include <qlabel.h>
#include <qlayout.h>
#include <qtooltip.h>
#include <qwhatsthis.h>
#include <qaction.h>
#include <qmenubar.h>
#include <qpopupmenu.h>
#include <qtoolbar.h>
#include <qimage.h>
#include <qpixmap.h>

#include "../mainform.ui.h"
/*
 *  Constructs a MainForm as a child of 'parent', with the
 *  name 'name' and widget flags set to 'f'.
 *
 */
MainForm::MainForm( QWidget* parent, const char* name, WFlags fl )
    : QMainWindow( parent, name, fl )
{
    (void)statusBar();
    if ( !name )
	setName( "MainForm" );
    setIcon( QPixmap::fromMimeSource( "miolo.png" ) );
    setCentralWidget( new QWidget( this, "qt_central_widget" ) );

    pixmapLabel1 = new QLabel( centralWidget(), "pixmapLabel1" );
    pixmapLabel1->setGeometry( QRect( 200, 60, 300, 270 ) );
    pixmapLabel1->setPixmap( QPixmap::fromMimeSource( "logo_miolo.png" ) );
    pixmapLabel1->setScaledContents( FALSE );

    // actions
    fileExitAction = new QAction( this, "fileExitAction" );
    helpAboutAction = new QAction( this, "helpAboutAction" );
    mnuModulesConfigure = new QAction( this, "mnuModulesConfigure" );
    mnuMioloOpenConf = new QAction( this, "mnuMioloOpenConf" );
    mnuMioloUpdate = new QAction( this, "mnuMioloUpdate" );
    mnuMioloInstClasses = new QAction( this, "mnuMioloInstClasses" );
    mnuFileConfig = new QAction( this, "mnuFileConfig" );


    // toolbars
    toolBar = new QToolBar( QString(""), this, DockTop ); 

    toolBar->addSeparator();
    helpAboutAction->addTo( toolBar );
    toolBar->addSeparator();
    fileExitAction->addTo( toolBar );


    // menubar
    menubar = new QMenuBar( this, "menubar" );


    fileMenu = new QPopupMenu( this );
    mnuFileConfig->addTo( fileMenu );
    fileMenu->insertSeparator();
    fileExitAction->addTo( fileMenu );
    menubar->insertItem( QString(""), fileMenu, 1 );

    PopupMenu_4 = new QPopupMenu( this );
    mnuMioloOpenConf->addTo( PopupMenu_4 );
    PopupMenu_4->insertSeparator();
    mnuMioloUpdate->addTo( PopupMenu_4 );
    mnuMioloInstClasses->addTo( PopupMenu_4 );
    menubar->insertItem( QString(""), PopupMenu_4, 2 );

    PopupMenu = new QPopupMenu( this );
    mnuModulesConfigure->addTo( PopupMenu );
    menubar->insertItem( QString(""), PopupMenu, 3 );

    helpMenu = new QPopupMenu( this );
    helpMenu->insertSeparator();
    helpAboutAction->addTo( helpMenu );
    menubar->insertItem( QString(""), helpMenu, 4 );

    languageChange();
    resize( QSize(600, 480).expandedTo(minimumSizeHint()) );
    clearWState( WState_Polished );

    // signals and slots connections
    connect( fileExitAction, SIGNAL( activated() ), this, SLOT( fileExit() ) );
    connect( helpAboutAction, SIGNAL( activated() ), this, SLOT( helpAbout() ) );
    connect( mnuMioloOpenConf, SIGNAL( activated() ), this, SLOT( editConf() ) );
}

/*
 *  Destroys the object and frees any allocated resources
 */
MainForm::~MainForm()
{
    // no need to delete child widgets, Qt does it all for us
}

/*
 *  Sets the strings of the subwidgets using the current
 *  language.
 */
void MainForm::languageChange()
{
    setCaption( tr( "M.AD - Miolo ADministration Tool" ) );
    QWhatsThis::add( this, tr( "This is the MAD's main window" ) );
    fileExitAction->setText( tr( "Exit" ) );
    fileExitAction->setMenuText( tr( "E&xit" ) );
    fileExitAction->setToolTip( tr( "Exit MAD" ) );
    fileExitAction->setStatusTip( tr( "Exit MAD" ) );
    fileExitAction->setAccel( QString::null );
    helpAboutAction->setText( tr( "About" ) );
    helpAboutAction->setMenuText( tr( "&About" ) );
    helpAboutAction->setStatusTip( tr( "About MAD Tool" ) );
    helpAboutAction->setAccel( QString::null );
    mnuModulesConfigure->setText( tr( "&Configure Modules" ) );
    mnuModulesConfigure->setWhatsThis( tr( "This gives you access to the configuration of the environment Modules. You can configure, delete or install new modules." ) );
    mnuModulesConfigure->setMenuText(tr( "&Configure Modules" ));
    mnuMioloOpenConf->setText( tr( "&Open miolo.conf" ) );
    mnuMioloOpenConf->setToolTip( tr( "Open miolo.conf" ) );
    mnuMioloOpenConf->setStatusTip( tr( "Open MIOLO's configuration file: miolo.conf" ) );
    mnuMioloOpenConf->setWhatsThis( tr( "This option opens miolo configuration file" ) );
    mnuMioloOpenConf->setMenuText(tr( "&Open miolo.conf" ));
    mnuMioloUpdate->setText( tr( "&Update MIOLO" ) );
    mnuMioloUpdate->setToolTip( tr( "Update MIOLO" ) );
    mnuMioloUpdate->setStatusTip( tr( "Update installed MIOLO version" ) );
    mnuMioloUpdate->setWhatsThis( tr( "Use this option to update your installed version of MIOLO" ) );
    mnuMioloUpdate->setMenuText(tr( "&Update MIOLO" ));
    mnuMioloInstClasses->setText( tr( "Install New &Classes" ) );
    mnuMioloInstClasses->setToolTip( tr( "Install New Classes" ) );
    mnuMioloInstClasses->setMenuText(tr( "Install New &Classes" ));
    mnuFileConfig->setText( tr( "&Configure MAD" ) );
    mnuFileConfig->setToolTip( tr( "Configure MAD" ) );
    mnuFileConfig->setStatusTip( tr( "Configure MAD" ) );
    mnuFileConfig->setMenuText(tr( "&Configure MAD" ));
    toolBar->setLabel( tr( "Tools" ) );
    if (menubar->findItem(1))
        menubar->findItem(1)->setText( tr( "&Application" ) );
    if (menubar->findItem(2))
        menubar->findItem(2)->setText( tr( "&MIOLO" ) );
    if (menubar->findItem(3))
        menubar->findItem(3)->setText( tr( "M&odules" ) );
    if (menubar->findItem(4))
        menubar->findItem(4)->setText( tr( "&Help" ) );
}

