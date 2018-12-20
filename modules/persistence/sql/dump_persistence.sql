--
-- PostgreSQL database dump
--

-- Started on 2008-11-16 23:22:39

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- TOC entry 309 (class 2612 OID 16386)
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO postgres;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 1482 (class 1259 OID 78014)
-- Dependencies: 3
-- Name: tb_aluno; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE tb_aluno (
    numero integer NOT NULL,
    situacao character(5),
    idpessoa integer NOT NULL
);


ALTER TABLE public.tb_aluno OWNER TO postgres;

--
-- TOC entry 1487 (class 1259 OID 78039)
-- Dependencies: 3
-- Name: tb_grpusuario; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE tb_grpusuario (
    idusuario integer NOT NULL,
    idgrupo integer NOT NULL
);


ALTER TABLE public.tb_grpusuario OWNER TO postgres;

--
-- TOC entry 1485 (class 1259 OID 78029)
-- Dependencies: 3
-- Name: tb_grupo; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE tb_grupo (
    idgrupo integer NOT NULL,
    grupo character varying(50)
);


ALTER TABLE public.tb_grupo OWNER TO postgres;

--
-- TOC entry 1481 (class 1259 OID 78009)
-- Dependencies: 3
-- Name: tb_pessoa; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE tb_pessoa (
    idpessoa integer NOT NULL,
    nome character varying(100)
);


ALTER TABLE public.tb_pessoa OWNER TO postgres;

--
-- TOC entry 1486 (class 1259 OID 78034)
-- Dependencies: 3
-- Name: tb_setor; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE tb_setor (
    idsetor integer NOT NULL,
    sigla character(20),
    nome character varying(100),
    tipo character(1),
    idsetorpai integer
);


ALTER TABLE public.tb_setor OWNER TO postgres;

--
-- TOC entry 1483 (class 1259 OID 78019)
-- Dependencies: 3
-- Name: tb_teste; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE tb_teste (
    idteste integer NOT NULL,
    q1 character(1),
    q2 character(1),
    q3 character(1),
    q4 character(1),
    q5 character(1),
    numero integer NOT NULL,
    data date
);


ALTER TABLE public.tb_teste OWNER TO postgres;

--
-- TOC entry 1484 (class 1259 OID 78024)
-- Dependencies: 3
-- Name: tb_usuario; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE tb_usuario (
    idusuario integer NOT NULL,
    login character(20),
    password character(20),
    nick character(20),
    idpessoa integer NOT NULL,
    idsetor integer NOT NULL
);


ALTER TABLE public.tb_usuario OWNER TO postgres;

--
-- TOC entry 1489 (class 1259 OID 78106)
-- Dependencies: 3
-- Name: seq_tb_aluno; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_tb_aluno
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_tb_aluno OWNER TO postgres;

--
-- TOC entry 1798 (class 0 OID 0)
-- Dependencies: 1489
-- Name: seq_tb_aluno; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_tb_aluno', 5, true);


--
-- TOC entry 1492 (class 1259 OID 78112)
-- Dependencies: 3
-- Name: seq_tb_grupo; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_tb_grupo
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_tb_grupo OWNER TO postgres;

--
-- TOC entry 1799 (class 0 OID 0)
-- Dependencies: 1492
-- Name: seq_tb_grupo; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_tb_grupo', 8, true);


--
-- TOC entry 1488 (class 1259 OID 78104)
-- Dependencies: 3
-- Name: seq_tb_pessoa; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_tb_pessoa
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_tb_pessoa OWNER TO postgres;

--
-- TOC entry 1800 (class 0 OID 0)
-- Dependencies: 1488
-- Name: seq_tb_pessoa; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_tb_pessoa', 7, true);


--
-- TOC entry 1493 (class 1259 OID 78114)
-- Dependencies: 3
-- Name: seq_tb_setor; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_tb_setor
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_tb_setor OWNER TO postgres;

--
-- TOC entry 1801 (class 0 OID 0)
-- Dependencies: 1493
-- Name: seq_tb_setor; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_tb_setor', 16, true);


--
-- TOC entry 1490 (class 1259 OID 78108)
-- Dependencies: 3
-- Name: seq_tb_teste; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_tb_teste
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_tb_teste OWNER TO postgres;

--
-- TOC entry 1802 (class 0 OID 0)
-- Dependencies: 1490
-- Name: seq_tb_teste; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_tb_teste', 5, true);


--
-- TOC entry 1491 (class 1259 OID 78110)
-- Dependencies: 3
-- Name: seq_tb_usuario; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_tb_usuario
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_tb_usuario OWNER TO postgres;

--
-- TOC entry 1803 (class 0 OID 0)
-- Dependencies: 1491
-- Name: seq_tb_usuario; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_tb_usuario', 6, true);


--
-- TOC entry 1787 (class 0 OID 78014)
-- Dependencies: 1482
-- Data for Name: tb_aluno; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tb_aluno (numero, situacao, idpessoa) VALUES (1, 'Ativo', 1);
INSERT INTO tb_aluno (numero, situacao, idpessoa) VALUES (2, 'Ativo', 2);
INSERT INTO tb_aluno (numero, situacao, idpessoa) VALUES (3, 'Ativo', 3);
INSERT INTO tb_aluno (numero, situacao, idpessoa) VALUES (4, 'Ativo', 4);
INSERT INTO tb_aluno (numero, situacao, idpessoa) VALUES (5, 'Ativo', 5);


--
-- TOC entry 1792 (class 0 OID 78039)
-- Dependencies: 1487
-- Data for Name: tb_grpusuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tb_grpusuario (idusuario, idgrupo) VALUES (6, 7);
INSERT INTO tb_grpusuario (idusuario, idgrupo) VALUES (2, 8);
INSERT INTO tb_grpusuario (idusuario, idgrupo) VALUES (3, 8);
INSERT INTO tb_grpusuario (idusuario, idgrupo) VALUES (4, 8);
INSERT INTO tb_grpusuario (idusuario, idgrupo) VALUES (5, 7);


--
-- TOC entry 1790 (class 0 OID 78029)
-- Dependencies: 1485
-- Data for Name: tb_grupo; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tb_grupo (idgrupo, grupo) VALUES (7, 'Grupo Usuario');
INSERT INTO tb_grupo (idgrupo, grupo) VALUES (8, 'Grupo Admin');


--
-- TOC entry 1786 (class 0 OID 78009)
-- Dependencies: 1481
-- Data for Name: tb_pessoa; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tb_pessoa (idpessoa, nome) VALUES (1, 'Martin Fowler');
INSERT INTO tb_pessoa (idpessoa, nome) VALUES (2, 'Craig Larman');
INSERT INTO tb_pessoa (idpessoa, nome) VALUES (3, 'Ted Codd');
INSERT INTO tb_pessoa (idpessoa, nome) VALUES (4, 'Peter Chen');
INSERT INTO tb_pessoa (idpessoa, nome) VALUES (5, 'Scott Ambler');
INSERT INTO tb_pessoa (idpessoa, nome) VALUES (6, 'name for sample');
INSERT INTO tb_pessoa (idpessoa, nome) VALUES (7, 'name for sample');


--
-- TOC entry 1791 (class 0 OID 78034)
-- Dependencies: 1486
-- Data for Name: tb_setor; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tb_setor (idsetor, sigla, nome, tipo, idsetorpai) VALUES (4, 'root                ', 'Setor Root', 'R', NULL);
INSERT INTO tb_setor (idsetor, sigla, nome, tipo, idsetorpai) VALUES (5, 'SA                  ', 'Setor Alpha', 'A', 4);
INSERT INTO tb_setor (idsetor, sigla, nome, tipo, idsetorpai) VALUES (6, 'SB                  ', 'Setor Beta', 'A', 4);
INSERT INTO tb_setor (idsetor, sigla, nome, tipo, idsetorpai) VALUES (7, 'SS1                 ', 'Secao Um', 'B', 5);
INSERT INTO tb_setor (idsetor, sigla, nome, tipo, idsetorpai) VALUES (8, 'SS2                 ', 'Secao Dois', 'B', 5);
INSERT INTO tb_setor (idsetor, sigla, nome, tipo, idsetorpai) VALUES (9, 'SS3                 ', 'Secao Tres', 'B', 5);
INSERT INTO tb_setor (idsetor, sigla, nome, tipo, idsetorpai) VALUES (10, 'SS4                 ', 'Secao Quatro', 'B', 6);
INSERT INTO tb_setor (idsetor, sigla, nome, tipo, idsetorpai) VALUES (11, 'SS5                 ', 'Secao Cinco', 'B', 6);
INSERT INTO tb_setor (idsetor, sigla, nome, tipo, idsetorpai) VALUES (12, 'SS6                 ', 'Secao Seis', 'B', 6);
INSERT INTO tb_setor (idsetor, sigla, nome, tipo, idsetorpai) VALUES (13, 'SS7                 ', 'Secao Sete', 'B', 7);
INSERT INTO tb_setor (idsetor, sigla, nome, tipo, idsetorpai) VALUES (14, 'SS8                 ', 'Secao Oito', 'B', 7);
INSERT INTO tb_setor (idsetor, sigla, nome, tipo, idsetorpai) VALUES (15, 'SS9                 ', 'Secao Nove', 'B', 8);
INSERT INTO tb_setor (idsetor, sigla, nome, tipo, idsetorpai) VALUES (16, 'SS10                ', 'Secao Dez', 'C', 14);


--
-- TOC entry 1788 (class 0 OID 78019)
-- Dependencies: 1483
-- Data for Name: tb_teste; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tb_teste (idteste, q1, q2, q3, q4, q5, numero, data) VALUES (1, 'A', 'C', 'D', 'E', 'A', 1, '2008-02-01');
INSERT INTO tb_teste (idteste, q1, q2, q3, q4, q5, numero, data) VALUES (2, 'A', 'D', 'C', 'B', 'D', 2, '2008-03-01');
INSERT INTO tb_teste (idteste, q1, q2, q3, q4, q5, numero, data) VALUES (3, 'A', 'D', 'B', 'C', 'A', 3, '2008-04-01');
INSERT INTO tb_teste (idteste, q1, q2, q3, q4, q5, numero, data) VALUES (4, 'A', 'A', 'B', 'D', 'D', 4, '2008-05-01');
INSERT INTO tb_teste (idteste, q1, q2, q3, q4, q5, numero, data) VALUES (5, 'A', 'E', 'D', 'E', 'A', 5, '2008-06-01');


--
-- TOC entry 1789 (class 0 OID 78024)
-- Dependencies: 1484
-- Data for Name: tb_usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tb_usuario (idusuario, login, password, nick, idpessoa, idsetor) VALUES (2, 'login1              ', 'pass1               ', 'nick1               ', 1, 4);
INSERT INTO tb_usuario (idusuario, login, password, nick, idpessoa, idsetor) VALUES (3, 'login2              ', 'pass2               ', 'nick2               ', 2, 4);
INSERT INTO tb_usuario (idusuario, login, password, nick, idpessoa, idsetor) VALUES (4, 'login3              ', 'pass3               ', 'nick3               ', 3, 6);
INSERT INTO tb_usuario (idusuario, login, password, nick, idpessoa, idsetor) VALUES (5, 'login4              ', 'pass4               ', 'nick4               ', 4, 12);
INSERT INTO tb_usuario (idusuario, login, password, nick, idpessoa, idsetor) VALUES (6, 'login5              ', 'pass5               ', 'nick5               ', 5, 12);


--
-- TOC entry 1763 (class 2606 OID 78018)
-- Dependencies: 1482 1482
-- Name: tb_ano_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY tb_aluno
    ADD CONSTRAINT tb_ano_pkey PRIMARY KEY (numero);


--
-- TOC entry 1773 (class 2606 OID 78043)
-- Dependencies: 1487 1487 1487
-- Name: tb_grpusuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY tb_grpusuario
    ADD CONSTRAINT tb_grpusuario_pkey PRIMARY KEY (idusuario, idgrupo);


--
-- TOC entry 1769 (class 2606 OID 78033)
-- Dependencies: 1485 1485
-- Name: tb_grupo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY tb_grupo
    ADD CONSTRAINT tb_grupo_pkey PRIMARY KEY (idgrupo);


--
-- TOC entry 1761 (class 2606 OID 78013)
-- Dependencies: 1481 1481
-- Name: tb_pessoa_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY tb_pessoa
    ADD CONSTRAINT tb_pessoa_pkey PRIMARY KEY (idpessoa);


--
-- TOC entry 1771 (class 2606 OID 78038)
-- Dependencies: 1486 1486
-- Name: tb_setor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY tb_setor
    ADD CONSTRAINT tb_setor_pkey PRIMARY KEY (idsetor);


--
-- TOC entry 1765 (class 2606 OID 78023)
-- Dependencies: 1483 1483
-- Name: tb_teste_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY tb_teste
    ADD CONSTRAINT tb_teste_pkey PRIMARY KEY (idteste);


--
-- TOC entry 1767 (class 2606 OID 78028)
-- Dependencies: 1484 1484
-- Name: tb_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY tb_usuario
    ADD CONSTRAINT tb_usuario_pkey PRIMARY KEY (idusuario);


--
-- TOC entry 1774 (class 2606 OID 78044)
-- Dependencies: 1760 1481 1482
-- Name: tb_ano_idpessoa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_aluno
    ADD CONSTRAINT tb_ano_idpessoa_fkey FOREIGN KEY (idpessoa) REFERENCES tb_pessoa(idpessoa);


--
-- TOC entry 1775 (class 2606 OID 78049)
-- Dependencies: 1760 1481 1482
-- Name: tb_ano_idpessoa_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_aluno
    ADD CONSTRAINT tb_ano_idpessoa_fkey1 FOREIGN KEY (idpessoa) REFERENCES tb_pessoa(idpessoa);


--
-- TOC entry 1784 (class 2606 OID 78084)
-- Dependencies: 1487 1485 1768
-- Name: tb_grpusuario_idgrupo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_grpusuario
    ADD CONSTRAINT tb_grpusuario_idgrupo_fkey FOREIGN KEY (idgrupo) REFERENCES tb_grupo(idgrupo);


--
-- TOC entry 1785 (class 2606 OID 78089)
-- Dependencies: 1768 1485 1487
-- Name: tb_grpusuario_idgrupo_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_grpusuario
    ADD CONSTRAINT tb_grpusuario_idgrupo_fkey1 FOREIGN KEY (idgrupo) REFERENCES tb_grupo(idgrupo);


--
-- TOC entry 1782 (class 2606 OID 78074)
-- Dependencies: 1484 1487 1766
-- Name: tb_grpusuario_iduser_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_grpusuario
    ADD CONSTRAINT tb_grpusuario_iduser_fkey FOREIGN KEY (idusuario) REFERENCES tb_usuario(idusuario);


--
-- TOC entry 1783 (class 2606 OID 78079)
-- Dependencies: 1487 1484 1766
-- Name: tb_grpusuario_iduser_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_grpusuario
    ADD CONSTRAINT tb_grpusuario_iduser_fkey1 FOREIGN KEY (idusuario) REFERENCES tb_usuario(idusuario);


--
-- TOC entry 1776 (class 2606 OID 78064)
-- Dependencies: 1762 1483 1482
-- Name: tb_teste_numero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_teste
    ADD CONSTRAINT tb_teste_numero_fkey FOREIGN KEY (numero) REFERENCES tb_aluno(numero);


--
-- TOC entry 1777 (class 2606 OID 78069)
-- Dependencies: 1482 1762 1483
-- Name: tb_teste_numero_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_teste
    ADD CONSTRAINT tb_teste_numero_fkey1 FOREIGN KEY (numero) REFERENCES tb_aluno(numero);


--
-- TOC entry 1778 (class 2606 OID 78054)
-- Dependencies: 1481 1484 1760
-- Name: tb_usuario_idpessoa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_usuario
    ADD CONSTRAINT tb_usuario_idpessoa_fkey FOREIGN KEY (idpessoa) REFERENCES tb_pessoa(idpessoa);


--
-- TOC entry 1779 (class 2606 OID 78059)
-- Dependencies: 1481 1760 1484
-- Name: tb_usuario_idpessoa_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_usuario
    ADD CONSTRAINT tb_usuario_idpessoa_fkey1 FOREIGN KEY (idpessoa) REFERENCES tb_pessoa(idpessoa);


--
-- TOC entry 1780 (class 2606 OID 78094)
-- Dependencies: 1484 1486 1770
-- Name: tb_usuario_idsetor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_usuario
    ADD CONSTRAINT tb_usuario_idsetor_fkey FOREIGN KEY (idsetor) REFERENCES tb_setor(idsetor);


--
-- TOC entry 1781 (class 2606 OID 78099)
-- Dependencies: 1484 1486 1770
-- Name: tb_usuario_idsetor_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_usuario
    ADD CONSTRAINT tb_usuario_idsetor_fkey1 FOREIGN KEY (idsetor) REFERENCES tb_setor(idsetor);


--
-- TOC entry 1797 (class 0 OID 0)
-- Dependencies: 3
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2008-11-16 23:22:39

--
-- PostgreSQL database dump complete
--

