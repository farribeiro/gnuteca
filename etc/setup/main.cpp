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
*    $Id: main.cpp,v 1.2 2005/04/03 15:51:48 ematos Exp $
*                                                *
*************************************************/
// To compile de source, simply type: make

#include "setup.h"
#include <qapplication.h>
#include <qpixmap.h>

#include "miolo.xpm"

int main(int argc,char **argv)
{
    qDebug("\nLoading MIOLO Installer...");

    QApplication a(argc,argv);

    Wizard wizard;
    wizard.setIcon(QPixmap(*miolo_xpm));
    wizard.setCaption("MIOLO - Installation Program version 1.2");
    wizard.resize(600, 400);
    
    return wizard.exec();   
    
}
