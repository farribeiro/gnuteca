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
*    $Id: setup.h,v 1.2 2005/04/03 15:51:48 ematos Exp $
*                                                *
*************************************************/

#ifndef WIZARD_H
#define WIZARD_H

#include <qstring.h>
#include <qwizard.h>

class QWidget;
class QHBox;
class QLineEdit;
class QLabel;
class QCheckBox;
class QComboBox;
class QTextView;
class QProgressBar;

class Wizard : public QWizard
{
    Q_OBJECT

public:
    Wizard( QWidget *parent = 0, const char *name = 0 );

    void showPage(QWidget* page);

protected:
    void setupPage1();
    void setupPage2();
    void setupPage3();
    void setupPage4();
    void setupPage4a();
    void setupPage5();
    void setupPage6();
    
    QHBox *page1, *page2, *page3, *page4, *page4a, *page5, *page6;
    QLineEdit *edtmiolo, *edtmodules, *edthtml, *edtlogs, *edtthemes, *edturl, *edturl_themes, *edtlocale, *edttrace_port, *edtbis_host, *edtbis_base, *edtbis_user, *edtbis_passwd, *edtcmn_host, *edtcmn_base, *edtcmn_user, *edtcmn_passwd, *edtlogin_id, *edtlogin_pass, *edtlogin_name;
    QCheckBox *cbchklogin, *cbshrlogin, *cbautlogin, *chb_inst_miolo, *chb_inst_common, *chb_inst_examples, *chb_inst_themes, *chb_show_virthost;
    QLabel *lblmiolo, *lblmodules, *lblhtml, *lbllogs, *lblthemes, *lblurl, *lbledturl_themes, *progressLabel;
    QComboBox *cbbis_tipo, *cbcmn_tipo ;
    QTextView *apache;
    QProgressBar *progressBar1;
    QPushButton *btnStart;
    bool show_VirtualHost, installMiolo, installCommon, installExamples, installThemes, docheckLogin, dosharedLogin, doautoLogin, createConf;
    
protected slots:
    void dataChanged( const QString & );
    void portChanged( const QString &text );
    void baseChanged( const QString & );
    void SeleFile1();
    void SeleFile2();
    void SeleFile3();
    void SeleFile4();
    void SeleFile5();
    void SeleFile6();
    void autologinCheck( bool on );
    void sharedloginCheck( bool on );
    void checkloginCheck( bool on );
    void setcreateConf(bool on);
    void toggleVirtHost( bool on);
    void startInstall();
    void setinstallMiolo(bool on);
    void setinstallCommon(bool on);
    void setinstallExamples(bool on);
    void setinstallThemes(bool on);
    void makeDir( const QString dirName);
    int copyFile(QString infile, QString outfile);
};

#endif
