-- MIOLO Admin schema
-- Tested with Mysql, PostgreSql and SQLite

CREATE TABLE miolo_module (
  idmodule VARCHAR(40) NOT NULL,
  name VARCHAR(100) NULL,
  description TEXT NULL,
  PRIMARY KEY(idmodule)
);

CREATE TABLE miolo_sequence (
  sequence VARCHAR(30) NOT NULL,
  value INTEGER NOT NULL,
  PRIMARY KEY(sequence)
);

CREATE TABLE miolo_user (
  iduser SERIAL NOT NULL,
  login VARCHAR(25) NOT NULL,
  name VARCHAR(100) NULL,
  nickname VARCHAR(25) NULL,
  m_password VARCHAR(40) NULL,
  confirm_hash VARCHAR(40) NULL,
  theme VARCHAR(20) NULL,
  PRIMARY KEY(iduser)
);

-- Without Foreign Keys to be possible to put this table in other database
-- (if the admin database uses SQLite)

CREATE TABLE miolo_log (
  idlog SERIAL NOT NULL,
  m_timestamp TIMESTAMP NOT NULL,
  description TEXT NULL,
  module VARCHAR(40) NOT NULL,
  class VARCHAR(25) NULL,
  iduser INTEGER NOT NULL,
  idtransaction INTEGER NULL,
  remoteaddr VARCHAR(15) NOT NULL,
  PRIMARY KEY(idlog)
);

CREATE TABLE miolo_group (
  idgroup SERIAL NOT NULL,
  m_group VARCHAR(50) NOT NULL,
  PRIMARY KEY(idgroup)
);

CREATE TABLE miolo_session (
  idsession SERIAL NOT NULL,
  iduser INTEGER NOT NULL,
  tsin VARCHAR(15) NULL,
  tsout VARCHAR(15) NULL,
  name VARCHAR(50) NULL,
  sid VARCHAR(40) NULL,
  forced CHAR NULL,
  remoteaddr VARCHAR(15) NULL,
  PRIMARY KEY(idsession),
  FOREIGN KEY(iduser)
    REFERENCES miolo_user(iduser)
);

CREATE TABLE miolo_transaction (
  idtransaction SERIAL NOT NULL,
  m_transaction VARCHAR(40) NOT NULL,
  idmodule VARCHAR(40) NULL,
  PRIMARY KEY(idtransaction),
  FOREIGN KEY(idmodule)
    REFERENCES miolo_module(idmodule)
);

CREATE TABLE miolo_schedule (
  idschedule SERIAL NOT NULL,
  idmodule VARCHAR(40) NOT NULL,
  action TEXT NOT NULL,
  parameters TEXT NULL,
  beginTime TIMESTAMP NULL,
  completed BOOL NOT NULL DEFAULT FALSE,
  running BOOL NOT NULL DEFAULT FALSE,
  PRIMARY KEY(idschedule),
  FOREIGN KEY(idmodule)
    REFERENCES miolo_module(idmodule)
);

CREATE TABLE miolo_access (
  idtransaction INTEGER NOT NULL,
  idgroup INTEGER NOT NULL,
  rights INTEGER NULL,
  validatefunction TEXT NULL,
  FOREIGN KEY(idtransaction)
    REFERENCES miolo_transaction(idtransaction)
);

CREATE TABLE miolo_groupuser (
  iduser INTEGER NOT NULL,
  idgroup INTEGER NOT NULL,
  PRIMARY KEY(iduser, idgroup),
  FOREIGN KEY(iduser)
    REFERENCES miolo_user(iduser)
      ,
  FOREIGN KEY(idgroup)
    REFERENCES miolo_group(idgroup)
);


