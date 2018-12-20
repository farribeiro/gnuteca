/****************************************************************************
** FormMioloConf meta object code from reading C++ file 'mioloconf.h'
**
** Created: Mon Jun 26 11:51:54 2006
**      by: The Qt MOC ($Id: qt/moc_yacc.cpp   3.3.6   edited Mar 8 17:43 $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "../.ui/mioloconf.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.6. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *FormMioloConf::className() const
{
    return "FormMioloConf";
}

QMetaObject *FormMioloConf::metaObj = 0;
static QMetaObjectCleanUp cleanUp_FormMioloConf( "FormMioloConf", &FormMioloConf::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString FormMioloConf::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "FormMioloConf", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString FormMioloConf::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "FormMioloConf", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* FormMioloConf::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QDialog::staticMetaObject();
    static const QUMethod slot_0 = {"btnLoad_clicked", 0, 0 };
    static const QUMethod slot_1 = {"languageChange", 0, 0 };
    static const QMetaData slot_tbl[] = {
	{ "btnLoad_clicked()", &slot_0, QMetaData::Public },
	{ "languageChange()", &slot_1, QMetaData::Protected }
    };
    metaObj = QMetaObject::new_metaobject(
	"FormMioloConf", parentObject,
	slot_tbl, 2,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_FormMioloConf.setMetaObject( metaObj );
    return metaObj;
}

void* FormMioloConf::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "FormMioloConf" ) )
	return this;
    return QDialog::qt_cast( clname );
}

bool FormMioloConf::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: btnLoad_clicked(); break;
    case 1: languageChange(); break;
    default:
	return QDialog::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool FormMioloConf::qt_emit( int _id, QUObject* _o )
{
    return QDialog::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool FormMioloConf::qt_property( int id, int f, QVariant* v)
{
    return QDialog::qt_property( id, f, v);
}

bool FormMioloConf::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
