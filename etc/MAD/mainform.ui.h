/****************************************************************************
** ui.h extension file, included from the uic-generated form implementation.
**
** If you wish to add, delete or rename functions or slots use
** Qt Designer which will update this file, preserving your code. Create an
** init() function in place of a constructor, and a destroy() function in
** place of a destructor.
*****************************************************************************/

#include <qmessagebox.h>
#include <mioloconf.h>

void MainForm::fileExit()
{
    switch( QMessageBox::information( this, "M.AD Tool",
                                      "Do you want to exit MAD?",
                                      "Yes", "No", 
			  0, 1 ) ) 
    {
    case 0:
        close();
        break;
    case 1:
        break;
    }    
}


void MainForm::helpAbout()
{
QMessageBox::about( this, "MAD Tools",
                        "This program was created to help the administration\n"
                        "os the MIOLO Enviroment.");
}


void MainForm::editConf()
{
    FormMioloConf mioloConf;
    //mioloConf->btnLoad_clicked();
    mioloConf.exec();
}


void MainForm::newSlot()
{

}
