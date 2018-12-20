/****************************************************************************
** Form interface generated from reading ui file 'mainform.ui'
**
** Created: Sex Out 7 16:09:57 2005
**      by: The User Interface Compiler ($Id: qt/main.cpp   3.3.3   edited Nov 24 2003 $)
**
** WARNING! All changes made in this file will be lost!
****************************************************************************/

#ifndef MAINFORM_H
#define MAINFORM_H

#include <qvariant.h>
#include <qmainwindow.h>

class QVBoxLayout;
class QHBoxLayout;
class QGridLayout;
class QSpacerItem;
class QAction;
class QActionGroup;
class QToolBar;
class QPopupMenu;
class QLabel;

class MainForm : public QMainWindow
{
    Q_OBJECT

public:
    MainForm( QWidget* parent = 0, const char* name = 0, WFlags fl = WType_TopLevel );
    ~MainForm();

    QLabel* pixmapLabel1;
    QMenuBar *menubar;
    QPopupMenu *fileMenu;
    QPopupMenu *PopupMenu_4;
    QPopupMenu *PopupMenu;
    QPopupMenu *helpMenu;
    QToolBar *toolBar;
    QAction* fileExitAction;
    QAction* helpAboutAction;
    QAction* mnuModulesConfigure;
    QAction* mnuMioloOpenConf;
    QAction* mnuMioloUpdate;
    QAction* mnuMioloInstClasses;
    QAction* mnuFileConfig;

public slots:
    virtual void fileExit();
    virtual void helpAbout();
    virtual void editConf();
    virtual void newSlot();

protected:

protected slots:
    virtual void languageChange();

};

#endif // MAINFORM_H
