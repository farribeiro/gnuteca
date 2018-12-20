/****************************************************************************
** Wizard meta object code from reading C++ file 'setup.h'
**
** Created: Mon Jun 26 11:53:17 2006
**      by: The Qt MOC ($Id: qt/moc_yacc.cpp   3.3.6   edited Mar 8 17:43 $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "setup.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.6. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *Wizard::className() const
{
    return "Wizard";
}

QMetaObject *Wizard::metaObj = 0;
static QMetaObjectCleanUp cleanUp_Wizard( "Wizard", &Wizard::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString Wizard::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "Wizard", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString Wizard::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "Wizard", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* Wizard::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QWizard::staticMetaObject();
    static const QUParameter param_slot_0[] = {
	{ 0, &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_0 = {"dataChanged", 1, param_slot_0 };
    static const QUParameter param_slot_1[] = {
	{ "text", &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_1 = {"portChanged", 1, param_slot_1 };
    static const QUParameter param_slot_2[] = {
	{ 0, &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_2 = {"baseChanged", 1, param_slot_2 };
    static const QUMethod slot_3 = {"SeleFile1", 0, 0 };
    static const QUMethod slot_4 = {"SeleFile2", 0, 0 };
    static const QUMethod slot_5 = {"SeleFile3", 0, 0 };
    static const QUMethod slot_6 = {"SeleFile4", 0, 0 };
    static const QUMethod slot_7 = {"SeleFile5", 0, 0 };
    static const QUMethod slot_8 = {"SeleFile6", 0, 0 };
    static const QUParameter param_slot_9[] = {
	{ "on", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_9 = {"autologinCheck", 1, param_slot_9 };
    static const QUParameter param_slot_10[] = {
	{ "on", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_10 = {"sharedloginCheck", 1, param_slot_10 };
    static const QUParameter param_slot_11[] = {
	{ "on", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_11 = {"checkloginCheck", 1, param_slot_11 };
    static const QUParameter param_slot_12[] = {
	{ "on", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_12 = {"setcreateConf", 1, param_slot_12 };
    static const QUParameter param_slot_13[] = {
	{ "on", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_13 = {"toggleVirtHost", 1, param_slot_13 };
    static const QUMethod slot_14 = {"startInstall", 0, 0 };
    static const QUParameter param_slot_15[] = {
	{ "on", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_15 = {"setinstallMiolo", 1, param_slot_15 };
    static const QUParameter param_slot_16[] = {
	{ "on", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_16 = {"setinstallCommon", 1, param_slot_16 };
    static const QUParameter param_slot_17[] = {
	{ "on", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_17 = {"setinstallExamples", 1, param_slot_17 };
    static const QUParameter param_slot_18[] = {
	{ "on", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_18 = {"setinstallThemes", 1, param_slot_18 };
    static const QUParameter param_slot_19[] = {
	{ "dirName", &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_19 = {"makeDir", 1, param_slot_19 };
    static const QUParameter param_slot_20[] = {
	{ 0, &static_QUType_int, 0, QUParameter::Out },
	{ "infile", &static_QUType_QString, 0, QUParameter::In },
	{ "outfile", &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_20 = {"copyFile", 3, param_slot_20 };
    static const QMetaData slot_tbl[] = {
	{ "dataChanged(const QString&)", &slot_0, QMetaData::Protected },
	{ "portChanged(const QString&)", &slot_1, QMetaData::Protected },
	{ "baseChanged(const QString&)", &slot_2, QMetaData::Protected },
	{ "SeleFile1()", &slot_3, QMetaData::Protected },
	{ "SeleFile2()", &slot_4, QMetaData::Protected },
	{ "SeleFile3()", &slot_5, QMetaData::Protected },
	{ "SeleFile4()", &slot_6, QMetaData::Protected },
	{ "SeleFile5()", &slot_7, QMetaData::Protected },
	{ "SeleFile6()", &slot_8, QMetaData::Protected },
	{ "autologinCheck(bool)", &slot_9, QMetaData::Protected },
	{ "sharedloginCheck(bool)", &slot_10, QMetaData::Protected },
	{ "checkloginCheck(bool)", &slot_11, QMetaData::Protected },
	{ "setcreateConf(bool)", &slot_12, QMetaData::Protected },
	{ "toggleVirtHost(bool)", &slot_13, QMetaData::Protected },
	{ "startInstall()", &slot_14, QMetaData::Protected },
	{ "setinstallMiolo(bool)", &slot_15, QMetaData::Protected },
	{ "setinstallCommon(bool)", &slot_16, QMetaData::Protected },
	{ "setinstallExamples(bool)", &slot_17, QMetaData::Protected },
	{ "setinstallThemes(bool)", &slot_18, QMetaData::Protected },
	{ "makeDir(const QString)", &slot_19, QMetaData::Protected },
	{ "copyFile(QString,QString)", &slot_20, QMetaData::Protected }
    };
    metaObj = QMetaObject::new_metaobject(
	"Wizard", parentObject,
	slot_tbl, 21,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_Wizard.setMetaObject( metaObj );
    return metaObj;
}

void* Wizard::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "Wizard" ) )
	return this;
    return QWizard::qt_cast( clname );
}

bool Wizard::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: dataChanged((const QString&)static_QUType_QString.get(_o+1)); break;
    case 1: portChanged((const QString&)static_QUType_QString.get(_o+1)); break;
    case 2: baseChanged((const QString&)static_QUType_QString.get(_o+1)); break;
    case 3: SeleFile1(); break;
    case 4: SeleFile2(); break;
    case 5: SeleFile3(); break;
    case 6: SeleFile4(); break;
    case 7: SeleFile5(); break;
    case 8: SeleFile6(); break;
    case 9: autologinCheck((bool)static_QUType_bool.get(_o+1)); break;
    case 10: sharedloginCheck((bool)static_QUType_bool.get(_o+1)); break;
    case 11: checkloginCheck((bool)static_QUType_bool.get(_o+1)); break;
    case 12: setcreateConf((bool)static_QUType_bool.get(_o+1)); break;
    case 13: toggleVirtHost((bool)static_QUType_bool.get(_o+1)); break;
    case 14: startInstall(); break;
    case 15: setinstallMiolo((bool)static_QUType_bool.get(_o+1)); break;
    case 16: setinstallCommon((bool)static_QUType_bool.get(_o+1)); break;
    case 17: setinstallExamples((bool)static_QUType_bool.get(_o+1)); break;
    case 18: setinstallThemes((bool)static_QUType_bool.get(_o+1)); break;
    case 19: makeDir((const QString)static_QUType_QString.get(_o+1)); break;
    case 20: static_QUType_int.set(_o,copyFile((QString)static_QUType_QString.get(_o+1),(QString)static_QUType_QString.get(_o+2))); break;
    default:
	return QWizard::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool Wizard::qt_emit( int _id, QUObject* _o )
{
    return QWizard::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool Wizard::qt_property( int id, int f, QVariant* v)
{
    return QWizard::qt_property( id, f, v);
}

bool Wizard::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
