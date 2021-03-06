-- POSSIBLE DEPRECATED

-- CREATE SEQUENCE

CREATE SEQUENCE seq_miolo_group
    START WITH 100
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 100
    CACHE 1;

CREATE SEQUENCE seq_miolo_log
    START WITH 100
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 100
    CACHE 1;

CREATE SEQUENCE seq_miolo_session
    START WITH 100
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 100
    CACHE 1;

CREATE SEQUENCE seq_miolo_transaction
    START WITH 100
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 100
    CACHE 1;

CREATE SEQUENCE seq_miolo_user
    START WITH 100
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 100
    CACHE 1;

-- CREATE

CREATE TABLE miolo_sequence (
       sequence                      CHAR(30)       NOT NULL,
       value                         INTEGER);

ALTER TABLE miolo_sequence ADD CONSTRAINT PK_miolo_sequence PRIMARY KEY(sequence);

CREATE TABLE miolo_user (
       iduser                        INTEGER        NOT NULL,
       login                         CHAR(25),
       name                          VARCHAR(80),
       nickname                      CHAR(25),
       m_password                    CHAR(40),
       confirm_hash                  CHAR(40),
       theme                         CHAR(20));

ALTER TABLE miolo_user ADD CONSTRAINT PK_miolo_user PRIMARY KEY(iduser);

CREATE TABLE miolo_transaction (
       idtransaction                 INTEGER        NOT NULL,
       m_transaction                 CHAR(30));

ALTER TABLE miolo_transaction ADD CONSTRAINT PK_miolo_transaction PRIMARY KEY(idtransaction);

CREATE TABLE miolo_group (
       idgroup                       INTEGER        NOT NULL,
       m_group                       CHAR(50));

ALTER TABLE miolo_group ADD CONSTRAINT PK_miolo_group PRIMARY KEY(idgroup);

CREATE TABLE miolo_access (
       idgroup                       INTEGER        NOT NULL,
       idtransaction                 INTEGER        NOT NULL,
       rights                        INTEGER);

ALTER TABLE miolo_access ADD CONSTRAINT FK_miolo_access2_miolo FOREIGN KEY(idgroup) REFERENCES miolo_group ON DELETE CASCADE;
ALTER TABLE miolo_access ADD CONSTRAINT FK_miolo_access1_miolo FOREIGN KEY(idtransaction) REFERENCES miolo_transaction ON DELETE CASCADE;

CREATE TABLE miolo_session (
       idsession                     INTEGER        NOT NULL,
       tsin                          CHAR(15),
       tsout                         CHAR(15),
       name                          CHAR(50),
       sid                           CHAR(40),
       forced                        CHAR(1),
       remoteaddr                    CHAR(15),
       iduser                        INTEGER        NOT NULL);

ALTER TABLE miolo_session ADD CONSTRAINT PK_miolo_session PRIMARY KEY(idsession);
ALTER TABLE miolo_session ADD CONSTRAINT FK_miolo_session1_miolo FOREIGN KEY(iduser) REFERENCES miolo_user;

CREATE TABLE miolo_log (
       idlog                         INTEGER        NOT NULL,
       m_timestamp                   CHAR(15),
       description                   VARCHAR(200),
       module                        CHAR(25),
       class                         CHAR(25),
       iduser                        INTEGER        NOT NULL,
       idtransaction                 INTEGER        NOT NULL);

ALTER TABLE miolo_log ADD CONSTRAINT PK_miolo_log PRIMARY KEY(idlog);
ALTER TABLE miolo_log ADD CONSTRAINT FK_miolo_log2_miolo FOREIGN KEY(idtransaction) REFERENCES miolo_transaction;
ALTER TABLE miolo_log ADD CONSTRAINT FK_miolo_log1_miolo FOREIGN KEY(iduser) REFERENCES miolo_user;

CREATE TABLE miolo_groupuser (
       iduser                        INTEGER        NOT NULL,
       idgroup                       INTEGER        NOT NULL);

ALTER TABLE miolo_groupuser ADD CONSTRAINT PK_miolo_groupuser PRIMARY KEY(iduser,idgroup);
ALTER TABLE miolo_groupuser ADD CONSTRAINT FK_miolo_groupuser1_miolo FOREIGN KEY(idgroup) REFERENCES miolo_group ON DELETE CASCADE;
ALTER TABLE miolo_groupuser ADD CONSTRAINT FK_miolo_groupuser2_miolo FOREIGN KEY(iduser) REFERENCES miolo_user ON DELETE CASCADE;

-- INSERT/UPDATE

insert into miolo_sequence values('seq_miolo_user',0);
insert into miolo_sequence values('seq_miolo_transaction',0);
insert into miolo_sequence values('seq_miolo_group',0);
insert into miolo_sequence values('seq_miolo_session',0);
insert into miolo_sequence values('seq_miolo_log',0);

update miolo_sequence set value = 2 where sequence = 'seq_miolo_user';
update miolo_sequence set value = 5 where sequence = 'seq_miolo_transaction';
update miolo_sequence set value = 3 where sequence = 'seq_miolo_group';

insert into miolo_user (iduser,login,name,nickname,m_password,confirm_hash,theme)
   values (1,'admin','Miolo Administrator','admin','admin','','miolo');
insert into miolo_user (iduser,login,name,nickname,m_password,confirm_hash,theme)
   values (2,'guest','Guest User','guest','guest','','miolo');

insert into miolo_transaction (idtransaction, m_transaction) values (1,'ADMIN');
insert into miolo_transaction (idtransaction, m_transaction) values (2,'USER');
insert into miolo_transaction (idtransaction, m_transaction) values (3,'GROUP');
insert into miolo_transaction (idtransaction, m_transaction) values (4,'LOG');
insert into miolo_transaction (idtransaction, m_transaction) values (5,'TRANSACTION');
insert into miolo_transaction (idtransaction, m_transaction) values (6,'SESSION');

insert into miolo_group (idgroup, m_group) values (1,'ADMIN');
insert into miolo_group (idgroup, m_group) values (2,'MAIN_RO');
insert into miolo_group (idgroup, m_group) values (3,'MAIN_RW');

insert into miolo_access (idgroup, idtransaction, rights) values (2,1,1);
insert into miolo_access (idgroup, idtransaction, rights) values (2,2,1);
insert into miolo_access (idgroup, idtransaction, rights) values (2,3,1);
insert into miolo_access (idgroup, idtransaction, rights) values (2,4,1);
insert into miolo_access (idgroup, idtransaction, rights) values (2,5,1);
insert into miolo_access (idgroup, idtransaction, rights) values (2,6,1);
insert into miolo_access (idgroup, idtransaction, rights) values (3,1,15);
insert into miolo_access (idgroup, idtransaction, rights) values (3,2,15);
insert into miolo_access (idgroup, idtransaction, rights) values (3,3,15);
insert into miolo_access (idgroup, idtransaction, rights) values (3,4,15);
insert into miolo_access (idgroup, idtransaction, rights) values (3,5,15);
insert into miolo_access (idgroup, idtransaction, rights) values (3,6,15);

insert into miolo_groupuser (idgroup, iduser) values (1,1);
insert into miolo_groupuser (idgroup, iduser) values (2,1);
insert into miolo_groupuser (idgroup, iduser) values (3,1);
insert into miolo_groupuser (idgroup, iduser) values (2,2);

INSERT INTO miolo_module (idmodule, name) values('admin','admin');
INSERT INTO miolo_module (idmodule, name) values('common','common');
INSERT INTO miolo_module (idmodule, name) values('helloworld','helloworld');
INSERT INTO miolo_module (idmodule, name) values('hangman','hangman');
INSERT INTO miolo_module (idmodule, name) values('tutorial','tutorial');
INSERT INTO miolo_module (idmodule, name) values('exemplo','exemplo');
