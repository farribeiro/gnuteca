/****************************************************************************
** Form interface generated from reading ui file 'mioloconf.ui'
**
** Created: Sex Out 7 16:09:57 2005
**      by: The User Interface Compiler ($Id: qt/main.cpp   3.3.3   edited Nov 24 2003 $)
**
** WARNING! All changes made in this file will be lost!
****************************************************************************/

#ifndef FORMMIOLOCONF_H
#define FORMMIOLOCONF_H

#include <qvariant.h>
#include <qdialog.h>

class QVBoxLayout;
class QHBoxLayout;
class QGridLayout;
class QSpacerItem;
class QPushButton;
class QProgressBar;
class QTabWidget;
class QWidget;
class QGroupBox;
class QLineEdit;
class QLabel;
class QComboBox;
class QTextEdit;

class FormMioloConf : public QDialog
{
    Q_OBJECT

public:
    FormMioloConf( QWidget* parent = 0, const char* name = 0, bool modal = FALSE, WFlags fl = 0 );
    ~FormMioloConf();

    QPushButton* btnLoad;
    QProgressBar* progressBar;
    QPushButton* btnCancel;
    QTabWidget* tabWidget;
    QWidget* tab;
    QGroupBox* groupURL;
    QLineEdit* editUrl;
    QLineEdit* editUrl_Themes;
    QLabel* lblUrl;
    QLabel* lblUrl_Themes;
    QGroupBox* groupHome;
    QLabel* lblHtml;
    QLabel* lblLogs;
    QLabel* lblThemes;
    QLabel* lblModules;
    QLabel* lblMiolo;
    QLineEdit* editModules;
    QLineEdit* editEtc;
    QLineEdit* editLogs;
    QLineEdit* editHtml;
    QLineEdit* editThemes;
    QLabel* lblEtc;
    QPushButton* btnClasses;
    QPushButton* btnModules;
    QPushButton* btnEtc;
    QPushButton* btnLogs;
    QPushButton* btnHtml;
    QPushButton* btnThemes;
    QLineEdit* editClasses;
    QWidget* tab_2;
    QGroupBox* groupBisDB;
    QLabel* lblHost;
    QLabel* lblHost_2;
    QLabel* lblHost_3;
    QLabel* lblHost_4;
    QLineEdit* editDBHost;
    QLineEdit* editDBName;
    QLineEdit* editDBUser;
    QLineEdit* editDBPassword;
    QLabel* lblDB;
    QComboBox* cbDBSystem;
    QGroupBox* groupLogin;
    QLabel* lblLoginCheck_2;
    QLabel* lblLoginCheck;
    QLabel* lblLoginCheck_3;
    QComboBox* cbLoginCheck;
    QComboBox* cbLoginShared;
    QComboBox* cbLoginAuto;
    QWidget* tab_3;
    QGroupBox* groupDump;
    QLabel* lblDump;
    QLabel* lblDump_2;
    QLabel* lblDump_2_2_3;
    QLabel* lblDump_2_2;
    QLabel* lblDump_2_2_2;
    QLabel* lblDump_2_2_3_2;
    QLineEdit* editDump_Peer;
    QComboBox* cbProfile;
    QComboBox* cbUses;
    QComboBox* cbTrace;
    QComboBox* cbHandlers;
    QComboBox* cbDebug;
    QGroupBox* groupTheme;
    QLabel* lbllookupTheme;
    QLabel* lblmainTheme;
    QLineEdit* editThemeMain;
    QLineEdit* editThemeLookUp;
    QGroupBox* groupTrace;
    QLabel* lblmainTheme_2;
    QLineEdit* editTrace_Port;
    QGroupBox* groupOptions;
    QLabel* lblDispatcher;
    QLabel* lblDispatcher_2;
    QLabel* lblScramble;
    QLineEdit* editStartUp;
    QLineEdit* editDispatch;
    QLineEdit* editIndex;
    QComboBox* cbScramble;
    QLabel* lblStartUp;
    QGroupBox* groupI18n;
    QLabel* lblLocale;
    QLineEdit* editLocale;
    QLabel* lblLanguage;
    QComboBox* cbLanguage;
    QWidget* tab_4;
    QTextEdit* confEdit;
    QPushButton* btnSave;

    virtual QString getConfigOption( QString & line );
    virtual QString getConfigValue( QString & line );
    virtual QString getNextWord( QString & line );

public slots:
    virtual void btnLoad_clicked();

protected:

protected slots:
    virtual void languageChange();

};

#endif // FORMMIOLOCONF_H
