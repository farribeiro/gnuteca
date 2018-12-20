SOURCES	+= main.cpp
unix {
  UI_DIR = .ui
  MOC_DIR = .moc
  OBJECTS_DIR = .obj
}
FORMS	= mainform.ui \
	mioloconf.ui
IMAGES	= images/print \
	images/searchfind \
	images/logo_miolo.png \
	images/miolo.png \
	images/button_cancel.png \
	images/button_ok.png \
	images/exit.png \
	images/configure.png \
	images/edit.png \
	images/filesaveas.png \
	images/fileimport.png \
	images/folder_blue_open.png \
	images/folder_blue.png \
	images/ok.png \
	images/no.png \
	images/oracle.png \
	images/pgsql.png \
	images/mysql.png
TEMPLATE	=app
CONFIG	+= qt warn_on release
LANGUAGE	= C++
