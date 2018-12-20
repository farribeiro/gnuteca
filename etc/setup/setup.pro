SOURCES	+= main.cpp setup.cpp 
HEADERS	+= setup.h language.h 
TARGET		= install
DEPENDPATH=../../include
TEMPLATE	=app
CONFIG	+= qt warn_on release
DBFILE	= setup.db
LANGUAGE	= C++
