/****************************************************************************
** ui.h extension file, included from the uic-generated form implementation.
**
** If you wish to add, delete or rename functions or slots use
** Qt Designer which will update this file, preserving your code. Create an
** init() function in place of a constructor, and a destroy() function in
** place of a destructor.
*****************************************************************************/

#include <qfile.h>
#include <qmessagebox.h>
#include <qstring.h>
#include <qtextstream.h>


QString FormMioloConf::getConfigOption(QString &line)
{
    QString option;
    
    int pos = line.find("'");
    int pos0 = line.find("=");
            
    if  ( ( pos > 0 ) && ( pos0 > pos ) )
    {
        line.remove(0, pos+1);
        int pos1 = line.find("'");
        
        // lets see wich config option...
        option = line.left(pos1);
        //QMessageBox::about( this, "MAD", option );
                
        line.remove(0,pos1+1);
    }
   
    return option;
}

QString FormMioloConf::getConfigValue(QString &line)
{
    QString value;
    
    int pos = line.find("=");
    
    if ( pos > 0 )
    {
        line.remove(0, pos+1);
        int pos1 = line.find(";");
        
        QString tmpvalue = line.left(pos1);
        
        if ( line.find('"') > 0 )
        {
            tmpvalue.replace('"',"");
        }
        else
        {
            tmpvalue.replace("'","");
        }
        
        value = tmpvalue.stripWhiteSpace();
    }
    
    return value;
}


QString FormMioloConf::getNextWord(QString &line)
{
    QString word;

    while( ! line.isEmpty() && line.at(0) != ' ') 
    {
        word += line.at(0);
        line.remove(0, 1);
    }

    if ( ! line.isEmpty() )
    {
        line.remove(0, 1);
    }

//    debug("FormMioloConf::getNextWord word: \'%s\'", (const char *)word);
    
    return word;
}

void FormMioloConf::btnLoad_clicked()
{
    QFile file( "/etc/miolo/miolo.conf" );
    
    if ( ! file.open( IO_ReadWrite ) )
    {
        QMessageBox::critical( this, "MAD Tools",
                               "Não foi possível abrir o arquivo\n"
                               "/etc/miolo.conf");
        return;
    }
    
    int n=0;
    QString line;
    QTextStream stream ( &file );
    
    while ( ! stream.atEnd() )
    {
        line = stream.readLine();
        
        confEdit->insert(line+"\n");

        //let's see if it is a config line
        int pos = line.find("MIOLOCONF");
        int pos0 = line.find("//");
        int pos1 = line.find("#");
        
        if ( ( pos > 0 ) && 
             ( pos0 < 0 || pos0 > pos) && 
             ( pos1 < 0 ) 
            )
        {
            QString option1 = getConfigOption(line);
            QString option2 = getConfigOption(line);
            QString option3 = getConfigOption(line);
            QString value = getConfigValue(line);
            //QMessageBox::about( this, "MAD", option1+"-"+option2+"-"+option3+"="+value );
            
            if ( option1 == "home" && option2 == "miolo" )
            {                
                editClasses->setText(value);
            }
            else if ( option1 == "home" && option2 == "modules" )
            {
                editModules->setText(value);               
            }
            else if ( option1 == "home" && option2 == "etc" )
            {
                editEtc->setText(value);               
            }
            else if ( option1 == "home" && option2 == "logs" )
            {
                editLogs->setText(value);
            }
            else if ( option1 == "home" && option2 == "html" )
            {
                editHtml->setText(value);
            }
            else if ( option1 == "home" && option2 == "themes" )
            {
                editThemes->setText(value);
            }
            else if ( option1 == "home" && option2 == "url" )
            {
                editUrl->setText(value);
            }
            else if ( option1 == "home" && option2 == "url.themes" )
            {
                editUrl_Themes->setText(value);
            }
            else if ( option1 == "i18n" && option2 == "language" )
            {
               cbLanguage->setCurrentText(value);
            }
            else if ( option1 == "i18n" && option2 == "locale" )
            {
                editLocale->setText(value);
            }
            else if ( option1 == "theme" && option2 == "main" )
            {
                editThemeMain->setText(value);
            }
            else if ( option1 == "theme" && option2 == "lookup" )
            {
                editThemeLookUp->setText(value);
            }
            else if ( option1 == "options" && option2 == "startup" )
            {
                editStartUp->setText(value);
            }
            else if ( option1 == "options" && option2 == "scramble" )
            {
                cbScramble->setCurrentText(value);
            }
            else if ( option1 == "options" && option2 == "dispatch" )
            {
                editDispatch->setText(value);
            }
            else if ( option1 == "options" && option2 == "index" )
            {
                editIndex->setText(value);
            }
            else if ( option1 == "options" && option2 == "debug" )
            {
                cbDebug->setCurrentText(value);
            }
            else if ( option1 == "trace_port" )
            {
                editTrace_Port->setText(value);
            }
            else if ( option1 == "options" && option2 == "dump" && option3 == "peer" )
            {
                editDump_Peer->setText(value);
            }
            else if ( option1 == "options" && option2 == "dump" && option3 == "profile")
            {
                cbProfile->setCurrentText(value);
            }
            else if ( option1 == "options" && option2 == "dump" && option3 == "uses")
            {
                cbUses->setCurrentText(value);
            }
            else if ( option1 == "options" && option2 == "dump" && option3 == "trace")
            {
                cbTrace->setCurrentText(value);
            }
            else if ( option1 == "options" && option2 == "dump" && option3 == "handlers")
            {
                cbHandlers->setCurrentText(value);
            }
            else if ( option1 == "DB" && option2 == "bis" && option3 == "system")
            {
                cbDBSystem->setCurrentText(value);
            }
            else if ( option1 == "DB" && option2 == "bis" && option3 == "host")
            {
                editDBHost->setText(value);
            }
            else if ( option1 == "DB" && option2 == "bis" && option3 == "name")
            {
                editDBName->setText(value);
            }
            else if ( option1 == "DB" && option2 == "bis" && option3 == "user")
            {
                editDBUser->setText(value);
            }
            else if ( option1 == "DB" && option2 == "bis" && option3 == "password")
            {
                editDBPassword->setText(value);
            }
            else if ( option1 == "login" && option2 == "check" )
            {
                cbLoginCheck->setCurrentText(value);
            }
            else if ( option1 == "login" && option2 == "shared" )
            {
                cbLoginShared->setCurrentText(value);
            }
            else if ( option1 == "login" && option2 == "auto" )
            {
                cbLoginAuto->setCurrentText(value);
            }          
        }
        
        n += 1;
        //QMessageBox::about( this, "MAD", line );
        progressBar->setProgress(n);
    }
    
    //confEdit->setText( stream1.read() );
    
    progressBar->setProgress(-1);
    
}
