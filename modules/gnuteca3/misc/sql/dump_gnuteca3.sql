--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- Name: lo; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN lo AS oid;


ALTER DOMAIN public.lo OWNER TO postgres;

--
-- Name: type_bibliography_data; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE type_bibliography_data AS (
	controlnumber integer,
	fieldid character varying,
	subfieldid character varying,
	content character varying
);


ALTER TYPE public.type_bibliography_data OWNER TO postgres;

--
-- Name: type_multa; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE type_multa AS (
	personid integer,
	loanid integer,
	begindate timestamp without time zone,
	value numeric(10,2),
	observation text,
	waspaid boolean,
	fineid integer,
	operator character varying,
	allowance boolean,
	allowancejustify text,
	enddate timestamp without time zone,
	returnoperator character varying,
	slipthrough boolean
);


ALTER TYPE public.type_multa OWNER TO postgres;

--
-- Name: type_multas_em_aberto; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE type_multas_em_aberto AS (
	codigodamulta integer,
	codigodoemprestimo integer,
	valor numeric(10,2),
	observacao text,
	datahora timestamp without time zone
);


ALTER TYPE public.type_multas_em_aberto OWNER TO postgres;

--
-- Name: type_suggestion_material; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE type_suggestion_material AS (
	idperson integer,
	number integer
);


ALTER TYPE public.type_suggestion_material OWNER TO postgres;

--
-- Name: compareyearperiod(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION compareyearperiod(searchcontent character varying, field1 character varying, field2 character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
    DECLARE

        auxF1 varchar;
        auxF2 varchar;
        f1 varchar;
        f2 varchar;

        BEGIN

            IF strpos(searchContent, '-') <= 0 THEN
                RETURN FALSE;
            END IF;

            RAISE NOTICE ' == SearchContent: %, field1: %, field2: %; ', searchContent, field1, field2;

            auxF1   := getSearchContentToYearCompare(split_part(searchContent, '-', 1), FALSE);
            auxF2   := getSearchContentToYearCompare(split_part(searchContent, '-', 2), FALSE);
            f1      := getSearchContentToYearCompare(field1, FALSE);
            f2      := getSearchContentToYearCompare(field2, FALSE);

            IF char_length(auxF1) = 0 THEN
                auxF1 = 0;
            END IF;

            IF char_length(auxF2) = 0 THEN
                auxF2 = date_part('year', now());
            END IF;

            RAISE NOTICE ' == (split 1 % >= field1 % ) AND ( split2 % <= field2 % )', auxF1, f1,  auxF2,  f2;

            RETURN ((auxF1::integer >= f1::integer) AND (auxF2::integer <= f2::integer));

        END;

$$;


ALTER FUNCTION public.compareyearperiod(searchcontent character varying, field1 character varying, field2 character varying) OWNER TO postgres;

--
-- Name: corrigeindicadores(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION corrigeindicadores() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
    DECLARE

        row_data RECORD;

        BEGIN

            FOR row_data IN (SELECT DISTINCT controlNumber, fieldid, indicator1, indicator2 FROM gtcmaterial
                            WHERE subfieldid = '#' AND (char_length(indicator1) > 0 OR char_length(indicator2) > 0) )
            LOOP
                UPDATE  gtcMaterial
                SET     indicator1      = row_data.indicator1,
                        indicator2      = row_data.indicator2
                WHERE   controlNumber   = row_data.controlNumber
                AND     fieldid         = row_data.fieldid;
            END LOOP;

            DELETE FROM gtcmaterial WHERE subfieldid = '#';

            RETURN TRUE;

        END;

$$;


ALTER FUNCTION public.corrigeindicadores() OWNER TO postgres;

--
-- Name: get_multa(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_multa(p_fineid integer) RETURNS SETOF type_multa
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_line TYPE_MULTA;
    v_select text;
    
BEGIN
       
    v_select := 'SELECT C.personid, 
                        B.loanid, 
                        A.begindate, 
                        A.value, 
                        A.observation, 
                        (CASE WHEN finestatusid = 2
                        THEN
                            true
                        ELSE
                            false
                        END) AS waspaid, --foi paga
                        A.fineid,
                        B.loanoperator as operator,
                        (CASE WHEN finestatusid = 4 
                        THEN
                            true
                        ELSE
                            false
                        END) AS allowance, --foi abonada
                        '''' as allowancejustify, 
                        A.enddate,
                        B.returnoperator,
                        (CASE WHEN finestatusid = 3
                        THEN
                            true
                        ELSE
                           false
                        END) AS slipthrough --via boleto
                   FROM gtcfine A 
              LEFT JOIN gtcloan B 
                     ON (A.loanid = B.loanid) 
              LEFT JOIN basperson C 
                     ON (B.personid = C.personid)
                  WHERE A.fineid = ' || p_fineid;

 
    FOR v_line IN EXECUTE v_select
    LOOP
        RETURN NEXT v_line;
    END LOOP;
    
    RETURN;
          
END;
$$;


ALTER FUNCTION public.get_multa(p_fineid integer) OWNER TO postgres;

--
-- Name: getrelated(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION getrelated(integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
    DECLARE

        text_output TEXT;
        row_data RECORD;

        BEGIN

            text_output := '';

            FOR row_data IN SELECT DISTINCT relatedcontent FROM gtcdictionaryrelatedcontent
                            WHERE dictionarycontentid = $1 LOOP
                text_output := text_output || row_data.relatedcontent || '<br>';
            END LOOP;

            RETURN text_output;

        END;

$_$;


ALTER FUNCTION public.getrelated(integer) OWNER TO postgres;

--
-- Name: getsearchcontenttoyearcompare(character varying, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION getsearchcontenttoyearcompare(character varying, boolean) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
    DECLARE

        text_output TEXT;

        BEGIN

            text_output := $1;

            IF char_length(text_output) = 0 AND $2 THEN
                text_output := date_part('year', now());
            END IF;

            text_output := replace(text_output, '?', '0');
            text_output := regexp_replace(text_output, '[^0-9]', '', 'g');

            IF char_length(text_output) = 0 THEN
                RETURN '0';
            END IF;

            RETURN text_output;

        END;

$_$;


ALTER FUNCTION public.getsearchcontenttoyearcompare(character varying, boolean) OWNER TO postgres;

--
-- Name: getsuggestionmaterial(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION getsuggestionmaterial() RETURNS SETOF type_suggestion_material
    LANGUAGE plpgsql
    AS $$
DECLARE
    vclassification RECORD;
    vcontrolNumber RECORD;
BEGIN
    CREATE TEMP TABLE gtcPersonMaterial (personid int, controlnumber int); --tabela temporária para relacionar pessoa a número de controle
    
    FOR vclassification IN SELECT A.personId, 
                                  A.classificationareaid, 
                                  regexp_split_to_table(B.classification, ', ') as classification, 
                                  regexp_split_to_table( regexp_split_to_table(coalesce(B.ignoreclassification,''), ', '), ' ,')  as ignoreclassification
                             FROM gtcinterestsarea A
                       INNER JOIN gtcclassificationarea B
                            USING (classificationareaid)
    LOOP
        FOR vcontrolNumber IN SELECT distinct(A.controlNumber) as controlNumber, 
                                             count(B.*) as max 
                                        FROM gtcexemplarycontrol A 
                                  INNER JOIN gtcloan B 
                                       USING (itemnumber) 
                                   LEFT JOIN gtcMyLibrary C
                                          ON (C.tableid = 'gtcMaterial')  
                                   INNER JOIN gtcMaterial D
                                        USING (controlNumber)
                                       WHERE A.controlNumber NOT IN (SELECT controlnumber 
                                                                       FROM gtcloan 
                                                                 INNER JOIN gtcExemplaryControl 
                                                                       USING (itemnumber) 
                                                                       WHERE personid = vclassification.personId)
                                         AND (D.fieldid = '090' AND D.subfieldid = 'a')
                                         AND D.content LIKE (vclassification.classification) 
                                         AND D.content NOT LIKE (vclassification.ignoreclassification)
                                         AND controlNumber NOT IN (SELECT tableid::int FROM gtcMyLibrary WHERE tablename = 'gtcMaterial' AND personId = vclassification.personId)                      
                                    GROUP BY 1 ORDER BY 2 DESC LIMIT 1
        LOOP                    
            INSERT INTO gtcPersonMaterial VALUES ( vclassification.personId, vcontrolNumber.controlnumber );

        END LOOP;            
    END LOOP;

    RETURN QUERY SELECT DISTINCT personId, controlNumber FROM gtcPersonMaterial;

    DROP TABLE gtcPersonMaterial;
    
END;
$$;


ALTER FUNCTION public.getsuggestionmaterial() OWNER TO postgres;

--
-- Name: gtc_chk_domain(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION gtc_chk_domain(p_domain character varying, p_key character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_result boolean;
BEGIN

    --Se o valor do dominio for nulo permite inserir pois, em alguns casos, o campo da tabela em questão pode aceitar NULL.
    IF p_key iS NULL
    THEN
        RETURN TRUE;
    END IF;

    PERFORM * FROM gtcDomain LIMIT 1;
    IF NOT FOUND
    THEN
        RETURN TRUE; --Caso não haja nenhum dado na gtcDomain retorna como true. Isso é para resolver o bug do postgres que não ignora os check no dump
    END IF;

    SELECT INTO v_result count(*) > 0
           FROM gtcDomain
          WHERE domainId = p_domain
            AND key = p_key;

    RETURN v_result;

END;
$$;


ALTER FUNCTION public.gtc_chk_domain(p_domain character varying, p_key character varying) OWNER TO postgres;

--
-- Name: gtc_chk_parameter(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION gtc_chk_parameter(p_parameter text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_result boolean;
BEGIN
	SELECT INTO v_result count(*) > 0 FROM basConfig WHERE parameter = p_parameter;
	
	RETURN v_result;
END;
$$;


ALTER FUNCTION public.gtc_chk_parameter(p_parameter text) OWNER TO postgres;

--
-- Name: gtcfnc_updatesearchmaterialviewtable(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION gtcfnc_updatesearchmaterialviewtable() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            BEGIN

                DELETE FROM gtcSearchMaterialView;
                INSERT INTO gtcSearchMaterialView SELECT * FROM searchMaterialView;

                DELETE FROM gtcSearchTableUpdateControl;
                INSERT INTO gtcSearchTableUpdateControl (lastUpdate) values (now());

                RETURN OLD;
            END;
        $$;


ALTER FUNCTION public.gtcfnc_updatesearchmaterialviewtable() OWNER TO postgres;

--
-- Name: gtcfnc_updatesearchmaterialviewtablebool(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION gtcfnc_updatesearchmaterialviewtablebool() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
  DECLARE
    lastUpdate_ BOOLEAN;
  BEGIN
    --Havia problemas de corromper o indice. Então sempre exclui o indice e recria
    DROP INDEX index_gtcsearchmaterialview_controlnumber;

    DELETE FROM gtcSearchMaterialView;

    CREATE INDEX index_gtcsearchmaterialview_controlnumber ON gtcSearchMaterialView(controlnumber);

    INSERT INTO gtcSearchMaterialView SELECT * FROM searchMaterialView;

    DELETE FROM gtcSearchTableUpdateControl;
    INSERT INTO gtcSearchTableUpdateControl (lastUpdate) values (now());

    RETURN TRUE;
  END;
$$;


ALTER FUNCTION public.gtcfnc_updatesearchmaterialviewtablebool() OWNER TO postgres;

--
-- Name: gtcfncupdatematerialson(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION gtcfncupdatematerialson() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE

        row_data    RECORD;
        row_data1   RECORD;

        fatherCategory  char(2);
        fatherLevel     char(1);

        loopX       int;
        tag         char(5);
        fieldS      char(3);
        subFieldS   char(1);

        currentControlNumber    int;
        currentFieldId          char(3);
        currentSubFieldId       char(1);
        currentContent          text;
        currentSearchContent    text;
        currentLine             int;

    BEGIN

        IF (TG_OP != 'DELETE') THEN

            currentControlNumber    := NEW.controlnumber;
            currentFieldId          := NEW.fieldid;
            currentSubFieldId       := NEW.subfieldid;
            currentContent          := NEW.content;
            currentSearchContent    := NEW.searchcontent;
            currentLine             := NEW.line;

        ELSE

            currentControlNumber    := OLD.controlnumber;
            currentFieldId          := OLD.fieldid;
            currentSubFieldId       := OLD.subfieldid;
            currentContent          := OLD.content;
            currentSearchContent    := OLD.searchcontent;
            currentLine             := OLD.line;

        END IF;

        /**
         * BUSCA CATEGORIA E LEVEL DO PAI
         */
        FOR row_data IN (SELECT  category, level FROM  gtcMaterialControl WHERE  controlnumber = currentControlNumber)
        LOOP
            fatherCategory  := row_data.category;
            fatherLevel     := row_data.level;
        END LOOP;

        FOR row_data1 IN
        (
            SELECT  LK.tag, LK.tagson, MC.controlnumber
              FROM  gtcmaterialcontrol MC
        INNER JOIN  gtclinkoffieldsbetweenspreadsheets LK
                ON  (MC.category = LK.categoryson AND MC.level = LK.levelson )
             WHERE  LK.category         = fatherCategory
               AND  LK.level            = fatherLevel
               AND  LK.tag      like    ('%' || currentFieldId || '.' || currentSubFieldId || '%')
               AND  MC.controlnumberfather = currentControlNumber
               AND  LK.type = '2'
        )
        LOOP

            IF (strpos(row_data1.tagson, ',') = 0) THEN
                row_data1.tagson = row_data1.tagson || ',';
            END IF;

            loopX := 1;

            LOOP

                tag = split_part(row_data1.tagson, ',', loopX);

                IF char_length(tag) = 0 THEN
                    EXIT;
                END IF;

                fieldS      := split_part(tag, '.', 1);
                subFieldS   := split_part(tag, '.', 2);

                IF (TG_OP = 'DELETE') THEN

                    DELETE FROM gtcMaterial
                     WHERE controlnumber    = row_data1.controlnumber
                       AND fieldid          = fieldS
                       AND subfieldid       = subFieldS
                       AND line             = currentLine;

                ELSIF (TG_OP = 'UPDATE') THEN

                    UPDATE gtcMaterial
                       SET content          = currentContent,
                           searchcontent    = currentSearchContent
                     WHERE controlnumber    = row_data1.controlnumber
                       AND fieldid          = fieldS
                       AND subfieldid       = subFieldS
                       AND line             = currentLine;

                ELSIF (TG_OP = 'INSERT') THEN

                    INSERT INTO gtcMaterial
                        (content, searchcontent, controlnumber, fieldid, subfieldid, line)
                    VALUES
                        (currentContent, currentSearchContent, row_data1.controlnumber, fieldS, subFieldS, currentLine);

                END IF;

                loopX := loopX + 1;

            END LOOP;

        END LOOP;

        RETURN NULL;
    END;
$$;


ALTER FUNCTION public.gtcfncupdatematerialson() OWNER TO postgres;

--
-- Name: gtcgnccheckhelp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION gtcgnccheckhelp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
     v_result boolean;
 BEGIN
 
     IF ( TG_OP = 'UPDATE' )
     THEN
         IF ( (NEW.form = OLD.form) )
         THEN
            IF ( NEW.subform IS NOT NULL )
            THEN
                IF ( NEW.subform = OLD.subform )
                THEN
                    RETURN NEW;
                 END IF;
            ELSE
                RETURN NEW;
            END IF; 
         END IF;
         
         RAISE EXCEPTION 'Não é possível alterar o formulário deste registro.';    
     ELSE
         IF (NEW.subform IS NULL )
         THEN
             SELECT into v_result count(*) = 0
               FROM gtcHelp
              WHERE form = NEW.form
                AND subform IS NULL;
         ELSE
         
             SELECT into v_result count(*) = 0 
               FROM gtcHelp
              WHERE form = NEW.form
                AND subform = NEW.subform;
         END IF;
         
         IF ( v_result )
         THEN
             RETURN NEW;
         END IF;
         
         RAISE EXCEPTION 'Já existe um registo para este formulário.';
     END IF;
     
     RETURN NULL;    
 
 END;
$$;


ALTER FUNCTION public.gtcgnccheckhelp() OWNER TO postgres;

--
-- Name: prepareallsearchcontent(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION prepareallsearchcontent() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    vClassification varchar;
    vDate varchar;
BEGIN
    vClassification := value FROM basconfig WHERE parameter = 'MARC_CLASSIFICATION_TAG';
    vDate := value FROM basconfig WHERE parameter = 'CATALOGUE_DATE_FIELDS';

    --atualiza o searchContent de todos materiais para unaccent, conforme unaccent do PHP tira o + tambÃ©m
    UPDATE gtcmaterial SET searchcontent = trim( upper( translate( unaccent( content ) ,'+', '') ) );

    -- atualiza as tags 090.a e etc considerando a preferencia MARC_CLASSIFICATION_TAG
    UPDATE gtcmaterial EM SET searchContent = prepareTopographicIndex
        ( content,
            ( SELECT content
               FROM gtcmaterial IM
              WHERE fieldid = '090'
                AND subfieldid = 'b'
                AND line = 0
                AND EM.controlnumber = IM.controlNumber
            )
        )
     WHERE fieldid || '.' || subfieldid in (  SELECT regexp_split_to_table( vClassification, ',' ) );

    -- atualiza as tags de data. ObservaÃ§Ã£o: na 3.2 tem que ser dd/mm/yyyy
    UPDATE gtcmaterial SET searchContent = to_char( content::date, 'YYYY-mm-dd')
     WHERE fieldid || '.' || subfieldid in ( SELECT regexp_split_to_table( vDate , ',') );

    return true;
END;
$$;


ALTER FUNCTION public.prepareallsearchcontent() OWNER TO postgres;

--
-- Name: preparesearchcontent(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION preparesearchcontent(tag character varying, content character varying, complement character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    isClassification integer;
    isDate integer;
BEGIN
    isClassification = position( tag in ( SELECT value FROM basconfig WHERE parameter = 'MARC_CLASSIFICATION_TAG' ) );

    IF isClassification > 0
    THEN
        --raise notice 'topografico';
        return prepareTopographicIndex( content,complement );
    END IF;

    isDate = position( tag in ( SELECT value FROM basconfig WHERE parameter = 'CATALOGUE_DATE_FIELDS' ) );

    if isDate > 0
    THEN
        raise notice 'data';
        return to_char( content::date, 'YYYY-mm-dd');
        --return to_char( content::date, 'dd/mm/yyyy'); --na 3.2 tem que ser dd/mm/yyyy
    END IF;

    return trim( upper( unaccent( translate( content ,'+', '') ) ) );
END;
$$;


ALTER FUNCTION public.preparesearchcontent(tag character varying, content character varying, complement character varying) OWNER TO postgres;

--
-- Name: preparetopographicindex(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION preparetopographicindex(content character varying, complement character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    result varchar;
    number integer;
BEGIN
    --tira acentos e converte pra minusculas
    result := lower ( unaccent ( trim( content ) ) );
    --separa somente nÃºmeros
    number :=  CASE WHEN substr( regexp_replace(result,'[^0-9]','','g'),0,4) <> '' then substr( regexp_replace(result,'[^0-9]','','g'),0,4)::integer ELSE 0 END;
    --troca caracteres especiais nÃºmeros e letras
    result := translate( result, '/:=(-."0123456789', 'BCDEGHFIJKLMNOPQR');
    --tratamento da exceÃ§Ã£o (0 => EI deve vir apÃ³s (1/9 => EJ/9
    result := replace( result, 'EI','ES');

    --Trata a exceÃ§Ã£o quando o termo >= 820 e < 900 o (1/9 => E[JKLMNOPQR] vai depois do . => H (I))
    IF number >= 820 and number < 900
    THEN
        result := regexp_replace(result, 'E([JKLMNOPQR])', E'I\\1','g');
    END IF;

    --adiciona F na frente de cada caracter minusculo a fim de priorizar alguns caracteres
    result := trim( regexp_replace( result,'([a-z])',E'F\\1','g') );

    --caso tenha complemento concatena
    IF complement IS NOT NULL AND result <> ''
    THEN
        result := result || '@' || complement;
    END IF;

    return result;
END;
$$;


ALTER FUNCTION public.preparetopographicindex(content character varying, complement character varying) OWNER TO postgres;

--
-- Name: sea_bibliography_data(integer, character varying, integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION sea_bibliography_data(p_controlnumber integer, p_content character varying, p_libraryunit integer, p_tags character varying) RETURNS SETOF type_bibliography_data
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_line TYPE_BIBLIOGRAPHY_DATA;
    v_select text;
    
BEGIN
       
    v_select  = 'SELECT DISTINCT controlnumber
                           FROM gtcmaterial 
                         WHERE subfieldid <> ''#''';
  
 
    IF p_controlnumber IS NOT NULL
    THEN
        v_select = v_select || ' AND controlnumber = ' || p_controlnumber;
    END IF;
                                              
    IF p_content IS NOT NULL 
    THEN
        v_select = v_select || ' AND lower( unaccent( searchcontent ) ) LIKE lower( unaccent( ''%' || p_content || '%'' ) )';
    END IF;

                 
    v_select = 'SELECT controlnumber,
                       fieldid,
                       subfieldid,
                       content
                 FROM gtcmaterial
                WHERE controlnumber IN ( ' || v_select || ')';
                
    IF p_tags IS NOT NULL 
    THEN
        v_select = v_select || ' AND fieldid || ''.'' || subfieldid IN ( '''|| replace(p_tags, ',', ''',''') || ''')';
    END IF;            
               
    v_select = v_select || ' ORDER BY controlnumber, fieldid, subfieldid';        
                        
    FOR v_line IN EXECUTE v_select
    LOOP
        RETURN NEXT v_line;
    END LOOP;
    
    RETURN;
          
END;
$$;


ALTER FUNCTION public.sea_bibliography_data(p_controlnumber integer, p_content character varying, p_libraryunit integer, p_tags character varying) OWNER TO postgres;

--
-- Name: sea_multas_em_aberto(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION sea_multas_em_aberto(p_codigo_da_pessoa integer) RETURNS SETOF type_multas_em_aberto
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_select varchar;
    v_line type_multas_em_aberto;
BEGIN

    -- Funcao para buscar as multas em aberto. Será utilizado pelo SAGU
    v_select := 'SELECT F.fineId as codigodamulta , F.loanId as codigodoemprestimo, F.value as valor, F.observation as observacao, F.begindate as datahora FROM gtcFine F INNER JOIN gtcLoan L ON (F.loanId = L.loanId) WHERE L.personId = ' || p_codigo_da_pessoa || ' AND F.fineStatusId = 1';

    FOR v_line IN EXECUTE v_select
    LOOP
        RETURN NEXT v_line;
    END LOOP;
END;
$$;


ALTER FUNCTION public.sea_multas_em_aberto(p_codigo_da_pessoa integer) OWNER TO postgres;

--
-- Name: unaccent(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION unaccent(text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
BEGIN
     RETURN translate($1, 'áàâãäéèêëíìïóòôõöúùûüÁÀÂÃÄÉÈÊËÍÌÏÓÒÔÕÖÚÙÛÜçÇñÑ', 'aaaaaeeeeiiiooooouuuuAAAAAEEEEIIIOOOOOUUUUcCnN');
END;
$_$;


ALTER FUNCTION public.unaccent(text) OWNER TO postgres;

--
-- Name: upd_gerar_boleto_multa(integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION upd_gerar_boleto_multa(p_codigo_da_multa integer, p_operador character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_select varchar;
    v_line gtcFine;
BEGIN

    -- Funcao para pagar uma multa em aberto. Será utilizado pelo SAGU

    SELECT INTO v_line * from gtcFine where fineId = p_codigo_da_multa;

    IF ( v_line.fineStatusId = 2 )
    THEN
        raise exception 'Não foi possível gerar o boleto da multa % pois ela está como paga.', v_line.fineId;
        return FALSE;
    END IF;

    IF ( v_line.fineStatusId = 4 )
    THEN
        raise exception 'Não foi possível gerar o boleto da multa % pois ela está como abonada.', v_line.fineId;
        return FALSE;
    END IF;

    IF ( v_line.fineStatusId = 3 )
    THEN
        raise exception 'Não foi possível gerar o boleto da multa % pois ela está como paga via boleto.', v_line.fineId;
        return FALSE;
    END IF;

    UPDATE gtcFine SET fineStatusId = 3, enddate = now() where fineId = p_codigo_da_multa;
    INSERT INTO gtcFineStatusHistory (fineid, finestatusid, date, operator) VALUES (p_codigo_da_multa, 3, now(), p_operador);

    return true;
END;
$$;


ALTER FUNCTION public.upd_gerar_boleto_multa(p_codigo_da_multa integer, p_operador character varying) OWNER TO postgres;

--
-- Name: upd_pagar_multa(integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION upd_pagar_multa(p_codigo_da_multa integer, p_operador character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_select varchar;
    v_line gtcFine;
BEGIN
    -- Funcao para pagar uma multa em aberto. Será utilizado pelo SAGU

    SELECT INTO v_line * from gtcFine where fineId = p_codigo_da_multa;

    IF ( v_line.fineStatusId = 2 OR v_line.fineStatusId = 3 )
    THEN
        raise exception 'Não foi possível pagar a multa % pois ela está como paga.', v_line.fineId;
        return FALSE;
    END IF;

    IF (v_line.fineStatusId = 4)
    THEN
        raise exception 'Não foi possível pagar a multa % pois ela está como abonada.', v_line.fineId;
        return FALSE;
    END IF;

    UPDATE gtcFine SET fineStatusId = 2, enddate = now() where fineId = p_codigo_da_multa;
    INSERT INTO gtcFineStatusHistory (fineid, finestatusid, date, operator) VALUES (p_codigo_da_multa, 2, now(), p_operador);

    return true;
END;
$$;


ALTER FUNCTION public.upd_pagar_multa(p_codigo_da_multa integer, p_operador character varying) OWNER TO postgres;

--
-- Name: array_agg(anyelement); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE array_agg(anyelement) (
    SFUNC = array_append,
    STYPE = anyarray,
    INITCOND = '{}'
);


ALTER AGGREGATE public.array_agg(anyelement) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: basconfig; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE basconfig (
    moduleconfig text NOT NULL,
    parameter text NOT NULL,
    value text,
    description text NOT NULL,
    type character varying(50) NOT NULL,
    groupby character varying(50),
    orderby integer,
    label character varying(50),
    CONSTRAINT chk_basconfig_groupby CHECK (gtc_chk_domain('ABAS_PREFERENCIA'::character varying, groupby))
);


ALTER TABLE public.basconfig OWNER TO postgres;

--
-- Name: TABLE basconfig; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE basconfig IS 'configuracoes do sistema';


--
-- Name: COLUMN basconfig.moduleconfig; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basconfig.moduleconfig IS 'Modulo do parametro';


--
-- Name: COLUMN basconfig.parameter; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basconfig.parameter IS 'Parametro';


--
-- Name: COLUMN basconfig.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basconfig.value IS 'Valor';


--
-- Name: COLUMN basconfig.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basconfig.description IS 'Descricao do parametro';


--
-- Name: COLUMN basconfig.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basconfig.type IS 'Tipo do parametro';


--
-- Name: COLUMN basconfig.groupby; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basconfig.groupby IS 'Agrupa os parametros para uma tela de pesquisa mais amigavel';


--
-- Name: COLUMN basconfig.orderby; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basconfig.orderby IS 'Ordem em que a preferancia ira aparecer dentro do grupo. O numero mais baixo vem antes';


--
-- Name: COLUMN basconfig.label; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basconfig.label IS 'Rotulo do campo que sera exibido na interface de preferencias';


--
-- Name: basdocument; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE basdocument (
    personid integer NOT NULL,
    documenttypeid character varying(100) NOT NULL,
    content text NOT NULL,
    organ character varying(15),
    dateexpedition date,
    observation text,
    CONSTRAINT basdocument_documenttypeid CHECK (gtc_chk_domain('DOCUMENT_TYPE'::character varying, documenttypeid))
);


ALTER TABLE public.basdocument OWNER TO postgres;

--
-- Name: seq_linkid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_linkid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_linkid OWNER TO postgres;

--
-- Name: seq_linkid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_linkid', 2, true);


--
-- Name: baslink; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE baslink (
    linkid integer DEFAULT nextval('seq_linkid'::regclass) NOT NULL,
    description text,
    level integer,
    isvisibletoperson boolean,
    isoperator boolean
);


ALTER TABLE public.baslink OWNER TO postgres;

--
-- Name: seq_personid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_personid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_personid OWNER TO postgres;

--
-- Name: seq_personid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_personid', 1, false);


--
-- Name: basperson; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE basperson (
    personid integer DEFAULT nextval('seq_personid'::regclass) NOT NULL,
    name character varying(100) NOT NULL,
    city character varying(100),
    zipcode character varying(9),
    location character varying(100),
    number character varying(10),
    complement character varying(60),
    neighborhood text,
    email character varying(60),
    password character varying(100),
    login character varying(50),
    baseldap character varying(50),
    persongroup character varying(255),
    sex character(1),
    datebirth date,
    school character varying(100),
    profession character varying(100),
    workplace character varying(100),
    observation text,
    CONSTRAINT gtc_basperson_persongroup CHECK (gtc_chk_domain('PERSON_GROUP'::character varying, persongroup)),
    CONSTRAINT gtc_basperson_sex CHECK (gtc_chk_domain('SEX'::character varying, (sex)::character varying))
);


ALTER TABLE public.basperson OWNER TO postgres;

--
-- Name: TABLE basperson; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE basperson IS 'pessoas';


--
-- Name: COLUMN basperson.personid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basperson.personid IS 'Codigo da pessoa';


--
-- Name: COLUMN basperson.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basperson.name IS 'Nome';


--
-- Name: COLUMN basperson.city; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basperson.city IS 'Codigo da cidade';


--
-- Name: COLUMN basperson.zipcode; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basperson.zipcode IS 'CEP';


--
-- Name: COLUMN basperson.location; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basperson.location IS 'Logradouro';


--
-- Name: COLUMN basperson.number; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basperson.number IS 'Numero';


--
-- Name: COLUMN basperson.complement; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basperson.complement IS 'Complemento';


--
-- Name: COLUMN basperson.neighborhood; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basperson.neighborhood IS 'Bairro';


--
-- Name: COLUMN basperson.email; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basperson.email IS 'Email';


--
-- Name: COLUMN basperson.password; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basperson.password IS 'Senha para acesso aos processo on-line';


--
-- Name: baspersonlink; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE baspersonlink (
    personid integer NOT NULL,
    linkid integer NOT NULL,
    datevalidate date NOT NULL
);


ALTER TABLE public.baspersonlink OWNER TO postgres;

--
-- Name: TABLE baspersonlink; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE baspersonlink IS 'vinculos das pessoas';


--
-- Name: COLUMN baspersonlink.personid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN baspersonlink.personid IS 'Codigo da pessoa';


--
-- Name: COLUMN baspersonlink.linkid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN baspersonlink.linkid IS 'Codigo do vinculo';


--
-- Name: COLUMN baspersonlink.datevalidate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN baspersonlink.datevalidate IS 'Data de validade';


--
-- Name: baspersonoperationprocess; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE baspersonoperationprocess (
    personid integer,
    operationprocess timestamp without time zone
);


ALTER TABLE public.baspersonoperationprocess OWNER TO postgres;

--
-- Name: basphone; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE basphone (
    personid integer NOT NULL,
    type character varying(100) NOT NULL,
    phone character varying(20) NOT NULL,
    CONSTRAINT chk_basphone_type CHECK (gtc_chk_domain('TIPO_DE_TELEFONE'::character varying, type))
);


ALTER TABLE public.basphone OWNER TO postgres;

--
-- Name: TABLE basphone; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE basphone IS 'armazena os telefones da pessoa';


--
-- Name: COLUMN basphone.personid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basphone.personid IS 'C';


--
-- Name: COLUMN basphone.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basphone.type IS 'Tipo de telefone';


--
-- Name: COLUMN basphone.phone; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN basphone.phone IS 'telefone da pessoa';


--
-- Name: seq_analyticsid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_analyticsid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_analyticsid OWNER TO postgres;

--
-- Name: seq_analyticsid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_analyticsid', 1, false);


--
-- Name: gtcanalytics; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcanalytics (
    analyticsid integer DEFAULT nextval('seq_analyticsid'::regclass) NOT NULL,
    query text,
    action text,
    event text,
    libraryunitid integer,
    operator character varying(30),
    personid integer,
    "time" timestamp without time zone,
    ip text,
    browser text,
    loglevel integer NOT NULL,
    accesstype integer NOT NULL,
    menu text
);


ALTER TABLE public.gtcanalytics OWNER TO postgres;

--
-- Name: seq_associationid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_associationid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_associationid OWNER TO postgres;

--
-- Name: seq_associationid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_associationid', 1, false);


--
-- Name: gtcassociation; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcassociation (
    associationid integer DEFAULT nextval('seq_associationid'::regclass) NOT NULL,
    description character varying
);


ALTER TABLE public.gtcassociation OWNER TO postgres;

--
-- Name: seq_backgroundtasklogid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_backgroundtasklogid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_backgroundtasklogid OWNER TO postgres;

--
-- Name: seq_backgroundtasklogid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_backgroundtasklogid', 1, false);


--
-- Name: gtcbackgroundtasklog; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcbackgroundtasklog (
    backgroundtasklogid integer DEFAULT nextval('seq_backgroundtasklogid'::regclass) NOT NULL,
    begindate timestamp without time zone NOT NULL,
    enddate timestamp without time zone,
    task character varying NOT NULL,
    label character varying NOT NULL,
    status integer NOT NULL,
    message character varying,
    operator character varying NOT NULL,
    args character varying,
    libraryunitid integer,
    CONSTRAINT chk_gtcbackgroundtasklog_status CHECK (gtc_chk_domain('BACKGROUND_TASK_STATUS'::character varying, (status)::character varying))
);


ALTER TABLE public.gtcbackgroundtasklog OWNER TO postgres;

--
-- Name: TABLE gtcbackgroundtasklog; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcbackgroundtasklog IS 'armazena os logs executados pela tarefa de background';


--
-- Name: COLUMN gtcbackgroundtasklog.backgroundtasklogid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcbackgroundtasklog.backgroundtasklogid IS 'Codigo da tarefa ';


--
-- Name: gtcbackgroundtasklog_backgroundtasklogid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE gtcbackgroundtasklog_backgroundtasklogid_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.gtcbackgroundtasklog_backgroundtasklogid_seq OWNER TO postgres;

--
-- Name: gtcbackgroundtasklog_backgroundtasklogid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE gtcbackgroundtasklog_backgroundtasklogid_seq OWNED BY gtcbackgroundtasklog.backgroundtasklogid;


--
-- Name: gtcbackgroundtasklog_backgroundtasklogid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('gtcbackgroundtasklog_backgroundtasklogid_seq', 1, false);


--
-- Name: seq_cataloguingformatid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_cataloguingformatid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_cataloguingformatid OWNER TO postgres;

--
-- Name: seq_cataloguingformatid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_cataloguingformatid', 1, true);


--
-- Name: gtccataloguingformat; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtccataloguingformat (
    cataloguingformatid integer DEFAULT nextval('seq_cataloguingformatid'::regclass) NOT NULL,
    description character varying NOT NULL,
    observation character varying
);


ALTER TABLE public.gtccataloguingformat OWNER TO postgres;

--
-- Name: TABLE gtccataloguingformat; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtccataloguingformat IS 'tabela para separadores';


--
-- Name: seq_classificationareaid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_classificationareaid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_classificationareaid OWNER TO postgres;

--
-- Name: seq_classificationareaid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_classificationareaid', 1, false);


--
-- Name: gtcclassificationarea; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcclassificationarea (
    classificationareaid integer DEFAULT nextval('seq_classificationareaid'::regclass) NOT NULL,
    areaname character varying(50) NOT NULL,
    classification text,
    ignoreclassification text
);


ALTER TABLE public.gtcclassificationarea OWNER TO postgres;

--
-- Name: TABLE gtcclassificationarea; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcclassificationarea IS 'area de classificacao';


--
-- Name: COLUMN gtcclassificationarea.classificationareaid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcclassificationarea.classificationareaid IS 'Identificacao da classifica';


--
-- Name: COLUMN gtcclassificationarea.areaname; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcclassificationarea.areaname IS 'Nome da area de classificacao';


--
-- Name: COLUMN gtcclassificationarea.classification; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcclassificationarea.classification IS 'Classificacoess separadas por virgula e com percente para caracter de truncamento';


--
-- Name: COLUMN gtcclassificationarea.ignoreclassification; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcclassificationarea.ignoreclassification IS 'Ignorar classificacoes separadas por virgula e com percente para caracter de truncamento';


--
-- Name: seq_controlfielddetailid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_controlfielddetailid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_controlfielddetailid OWNER TO postgres;

--
-- Name: seq_controlfielddetailid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_controlfielddetailid', 64, true);


--
-- Name: gtccontrolfielddetail; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtccontrolfielddetail (
    controlfielddetailid integer DEFAULT nextval('seq_controlfielddetailid'::regclass) NOT NULL,
    fieldid character varying(3) NOT NULL,
    subfieldid character varying(1) NOT NULL,
    beginposition integer NOT NULL,
    lenght integer NOT NULL,
    description character varying(100) NOT NULL,
    categoryid character varying(2) NOT NULL,
    marctaglistid character varying,
    isactive boolean,
    defaultvalue character varying,
    emptyvalue character varying(50)
);


ALTER TABLE public.gtccontrolfielddetail OWNER TO postgres;

--
-- Name: seq_costcenterid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_costcenterid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_costcenterid OWNER TO postgres;

--
-- Name: seq_costcenterid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_costcenterid', 1, false);


--
-- Name: gtccostcenter; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtccostcenter (
    costcenterid integer DEFAULT nextval('seq_costcenterid'::regclass) NOT NULL,
    libraryunitid integer,
    description character varying(255) NOT NULL
);


ALTER TABLE public.gtccostcenter OWNER TO postgres;

--
-- Name: TABLE gtccostcenter; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtccostcenter IS 'centro de custo';


--
-- Name: gtccutter; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtccutter (
    abbreviation character varying NOT NULL,
    code integer NOT NULL
);


ALTER TABLE public.gtccutter OWNER TO postgres;

--
-- Name: TABLE gtccutter; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtccutter IS 'tabela cutter';


--
-- Name: seq_dictionaryid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_dictionaryid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_dictionaryid OWNER TO postgres;

--
-- Name: seq_dictionaryid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_dictionaryid', 1, false);


--
-- Name: gtcdictionary; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcdictionary (
    dictionaryid integer DEFAULT nextval('seq_dictionaryid'::regclass) NOT NULL,
    description character varying NOT NULL,
    tags text,
    readonly boolean
);


ALTER TABLE public.gtcdictionary OWNER TO postgres;

--
-- Name: TABLE gtcdictionary; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcdictionary IS 'dicion';


--
-- Name: seq_dictionarycontentid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_dictionarycontentid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_dictionarycontentid OWNER TO postgres;

--
-- Name: seq_dictionarycontentid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_dictionarycontentid', 1, false);


--
-- Name: gtcdictionarycontent; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcdictionarycontent (
    dictionarycontentid integer DEFAULT nextval('seq_dictionarycontentid'::regclass) NOT NULL,
    dictionaryid integer NOT NULL,
    dictionarycontent text NOT NULL
);


ALTER TABLE public.gtcdictionarycontent OWNER TO postgres;

--
-- Name: TABLE gtcdictionarycontent; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcdictionarycontent IS 'dicion';


--
-- Name: seq_dictionaryrelatedcontentid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_dictionaryrelatedcontentid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_dictionaryrelatedcontentid OWNER TO postgres;

--
-- Name: seq_dictionaryrelatedcontentid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_dictionaryrelatedcontentid', 1, false);


--
-- Name: gtcdictionaryrelatedcontent; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcdictionaryrelatedcontent (
    dictionaryrelatedcontentid integer DEFAULT nextval('seq_dictionaryrelatedcontentid'::regclass) NOT NULL,
    dictionarycontentid integer NOT NULL,
    relatedcontent character varying
);


ALTER TABLE public.gtcdictionaryrelatedcontent OWNER TO postgres;

--
-- Name: TABLE gtcdictionaryrelatedcontent; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcdictionaryrelatedcontent IS 'dicion';


--
-- Name: gtcdomain; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcdomain (
    domainid character varying(100) NOT NULL,
    sequence integer NOT NULL,
    key character varying(100) NOT NULL,
    abbreviated character varying(100) NOT NULL,
    label character varying(255) NOT NULL
);


ALTER TABLE public.gtcdomain OWNER TO postgres;

--
-- Name: TABLE gtcdomain; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcdomain IS 'armazena os dominios do sistema';


--
-- Name: gtcemailcontroldelayedloan; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcemailcontroldelayedloan (
    loanid integer,
    lastsent timestamp without time zone NOT NULL,
    amountsent integer NOT NULL
);


ALTER TABLE public.gtcemailcontroldelayedloan OWNER TO postgres;

--
-- Name: gtcemailcontrolnotifyaquisition; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcemailcontrolnotifyaquisition (
    personid integer,
    lastsent timestamp without time zone NOT NULL
);


ALTER TABLE public.gtcemailcontrolnotifyaquisition OWNER TO postgres;

--
-- Name: gtcexemplarycontrol; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcexemplarycontrol (
    controlnumber integer NOT NULL,
    itemnumber character varying(20) NOT NULL,
    originallibraryunitid integer NOT NULL,
    libraryunitid integer NOT NULL,
    acquisitiontype character varying(1) NOT NULL,
    exemplarystatusid integer NOT NULL,
    materialgenderid integer,
    materialtypeid integer,
    materialphysicaltypeid integer,
    entrancedate date,
    lowdate date,
    line integer,
    observation text
);


ALTER TABLE public.gtcexemplarycontrol OWNER TO postgres;

--
-- Name: TABLE gtcexemplarycontrol; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcexemplarycontrol IS 'armazena os exemplares';


--
-- Name: COLUMN gtcexemplarycontrol.controlnumber; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcexemplarycontrol.controlnumber IS 'Identificador da obra';


--
-- Name: COLUMN gtcexemplarycontrol.itemnumber; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcexemplarycontrol.itemnumber IS 'Descri';


--
-- Name: COLUMN gtcexemplarycontrol.libraryunitid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcexemplarycontrol.libraryunitid IS 'Codigo da unidade';


--
-- Name: COLUMN gtcexemplarycontrol.acquisitiontype; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcexemplarycontrol.acquisitiontype IS 'Tipo de aquisicao';


--
-- Name: COLUMN gtcexemplarycontrol.exemplarystatusid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcexemplarycontrol.exemplarystatusid IS 'C';


--
-- Name: seq_exemplaryfuturestatusdefinedid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_exemplaryfuturestatusdefinedid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_exemplaryfuturestatusdefinedid OWNER TO postgres;

--
-- Name: seq_exemplaryfuturestatusdefinedid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_exemplaryfuturestatusdefinedid', 1, false);


--
-- Name: gtcexemplaryfuturestatusdefined; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcexemplaryfuturestatusdefined (
    exemplaryfuturestatusdefinedid integer DEFAULT nextval('seq_exemplaryfuturestatusdefinedid'::regclass) NOT NULL,
    exemplarystatusid integer,
    itemnumber character varying(20),
    applied boolean,
    date timestamp without time zone,
    operator character varying(30),
    observation text
);


ALTER TABLE public.gtcexemplaryfuturestatusdefined OWNER TO postgres;

--
-- Name: TABLE gtcexemplaryfuturestatusdefined; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcexemplaryfuturestatusdefined IS '
';


--
-- Name: seq_exemplarystatusid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_exemplarystatusid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_exemplarystatusid OWNER TO postgres;

--
-- Name: seq_exemplarystatusid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_exemplarystatusid', 17, true);


--
-- Name: gtcexemplarystatus; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcexemplarystatus (
    exemplarystatusid integer DEFAULT nextval('seq_exemplarystatusid'::regclass) NOT NULL,
    description character varying(40) NOT NULL,
    mask character varying(40),
    level integer,
    executeloan boolean,
    momentaryloan boolean,
    daysofmomentaryloan integer,
    executereserve boolean,
    executereserveininitiallevel boolean,
    meetreserve boolean,
    isreservestatus boolean,
    islowstatus boolean,
    observation text,
    schedulechangestatusforrequest boolean
);


ALTER TABLE public.gtcexemplarystatus OWNER TO postgres;

--
-- Name: TABLE gtcexemplarystatus; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcexemplarystatus IS 'estado dos exemplares';


--
-- Name: COLUMN gtcexemplarystatus.exemplarystatusid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcexemplarystatus.exemplarystatusid IS 'Identificador do status';


--
-- Name: COLUMN gtcexemplarystatus.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcexemplarystatus.description IS 'descri';


--
-- Name: COLUMN gtcexemplarystatus.level; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcexemplarystatus.level IS 'Nivel definido como: 1 - Inicial e 2 - Transicao';


--
-- Name: COLUMN gtcexemplarystatus.executeloan; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcexemplarystatus.executeloan IS 'Define se neste estado o material podera ser emprestado.';


--
-- Name: COLUMN gtcexemplarystatus.momentaryloan; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcexemplarystatus.momentaryloan IS 'Se permite que o estado seja emprestado para o Xerox, etc.';


--
-- Name: COLUMN gtcexemplarystatus.meetreserve; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcexemplarystatus.meetreserve IS 'Se for true e um livro for devolvido para este estado ele executara o processo de atender reserva';


--
-- Name: gtcexemplarystatushistory; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcexemplarystatushistory (
    itemnumber character varying(20) NOT NULL,
    exemplarystatusid integer NOT NULL,
    libraryunitid integer NOT NULL,
    date timestamp without time zone NOT NULL,
    operator character varying(30) NOT NULL
);


ALTER TABLE public.gtcexemplarystatushistory OWNER TO postgres;

--
-- Name: TABLE gtcexemplarystatushistory; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcexemplarystatushistory IS 'mantem o historico das trocas de estado';


--
-- Name: COLUMN gtcexemplarystatushistory.itemnumber; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcexemplarystatushistory.itemnumber IS 'Identifica';


--
-- Name: COLUMN gtcexemplarystatushistory.exemplarystatusid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcexemplarystatushistory.exemplarystatusid IS 'Estado do exemplar';


--
-- Name: COLUMN gtcexemplarystatushistory.date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcexemplarystatushistory.date IS 'Cado o exemplar volta ela se torna confirmada';


--
-- Name: gtcfavorite; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcfavorite (
    personid integer NOT NULL,
    controlnumber integer NOT NULL,
    entracedate timestamp without time zone
);


ALTER TABLE public.gtcfavorite OWNER TO postgres;

--
-- Name: TABLE gtcfavorite; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcfavorite IS 'materiais favoritos do usu';


--
-- Name: COLUMN gtcfavorite.personid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcfavorite.personid IS 'Id da pessoa';


--
-- Name: COLUMN gtcfavorite.controlnumber; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcfavorite.controlnumber IS 'numero de controle';


--
-- Name: COLUMN gtcfavorite.entracedate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcfavorite.entracedate IS 'Data de entrada';


--
-- Name: seq_fineid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_fineid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_fineid OWNER TO postgres;

--
-- Name: seq_fineid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_fineid', 1, false);


--
-- Name: gtcfine; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcfine (
    fineid integer DEFAULT nextval('seq_fineid'::regclass) NOT NULL,
    loanid integer NOT NULL,
    begindate timestamp without time zone NOT NULL,
    value numeric(10,2) NOT NULL,
    finestatusid integer NOT NULL,
    enddate timestamp without time zone,
    observation text
);


ALTER TABLE public.gtcfine OWNER TO postgres;

--
-- Name: TABLE gtcfine; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcfine IS 'multas';


--
-- Name: COLUMN gtcfine.fineid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcfine.fineid IS 'Identificador da multa';


--
-- Name: COLUMN gtcfine.loanid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcfine.loanid IS 'Identifica';


--
-- Name: COLUMN gtcfine.begindate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcfine.begindate IS 'Data do registor da multa';


--
-- Name: COLUMN gtcfine.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcfine.value IS 'Valor total da multa. Deve vir calculada.';


--
-- Name: COLUMN gtcfine.finestatusid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcfine.finestatusid IS 'Estado da multa. 1 - Em aberto. 2 - Abonada. 3 - Pago 4 - Pagamento via boleto';


--
-- Name: COLUMN gtcfine.enddate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcfine.enddate IS 'Data do pagamento';


--
-- Name: seq_finestatusid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_finestatusid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_finestatusid OWNER TO postgres;

--
-- Name: seq_finestatusid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_finestatusid', 4, true);


--
-- Name: gtcfinestatus; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcfinestatus (
    finestatusid integer DEFAULT nextval('seq_finestatusid'::regclass) NOT NULL,
    description character varying(40) NOT NULL
);


ALTER TABLE public.gtcfinestatus OWNER TO postgres;

--
-- Name: TABLE gtcfinestatus; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcfinestatus IS 'estado da multa';


--
-- Name: COLUMN gtcfinestatus.finestatusid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcfinestatus.finestatusid IS 'Identificador do estado da multa';


--
-- Name: COLUMN gtcfinestatus.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcfinestatus.description IS 'Descri';


--
-- Name: gtcfinestatushistory; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcfinestatushistory (
    fineid integer NOT NULL,
    finestatusid integer NOT NULL,
    date timestamp without time zone NOT NULL,
    operator character varying(30) NOT NULL,
    observation text
);


ALTER TABLE public.gtcfinestatushistory OWNER TO postgres;

--
-- Name: TABLE gtcfinestatushistory; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcfinestatushistory IS 'mantem o historico das trocas de estado';


--
-- Name: COLUMN gtcfinestatushistory.fineid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcfinestatushistory.fineid IS 'Identifica';


--
-- Name: COLUMN gtcfinestatushistory.finestatusid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcfinestatushistory.finestatusid IS 'Estado da reserva';


--
-- Name: COLUMN gtcfinestatushistory.date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcfinestatushistory.date IS 'Cado o exemplar volta ela se torna confirmada';


--
-- Name: seq_formatbackofbookid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_formatbackofbookid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_formatbackofbookid OWNER TO postgres;

--
-- Name: seq_formatbackofbookid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_formatbackofbookid', 2, true);


--
-- Name: gtcformatbackofbook; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcformatbackofbook (
    formatbackofbookid integer DEFAULT nextval('seq_formatbackofbookid'::regclass) NOT NULL,
    description character varying(40) NOT NULL,
    format text NOT NULL,
    internalformat text
);


ALTER TABLE public.gtcformatbackofbook OWNER TO postgres;

--
-- Name: seq_formcontentid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_formcontentid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_formcontentid OWNER TO postgres;

--
-- Name: seq_formcontentid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_formcontentid', 5, true);


--
-- Name: gtcformcontent; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcformcontent (
    formcontentid integer DEFAULT nextval('seq_formcontentid'::regclass) NOT NULL,
    operator character varying,
    form character varying NOT NULL,
    name character varying,
    description character varying,
    formcontenttype integer NOT NULL
);


ALTER TABLE public.gtcformcontent OWNER TO postgres;

--
-- Name: gtcformcontentdetail; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcformcontentdetail (
    formcontentid character varying NOT NULL,
    field character varying NOT NULL,
    value character varying
);


ALTER TABLE public.gtcformcontentdetail OWNER TO postgres;

--
-- Name: seq_formcontenttypeid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_formcontenttypeid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_formcontenttypeid OWNER TO postgres;

--
-- Name: seq_formcontenttypeid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_formcontenttypeid', 3, true);


--
-- Name: gtcformcontenttype; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcformcontenttype (
    formcontenttypeid integer DEFAULT nextval('seq_formcontenttypeid'::regclass) NOT NULL,
    description character varying(40) NOT NULL
);


ALTER TABLE public.gtcformcontenttype OWNER TO postgres;

--
-- Name: TABLE gtcformcontenttype; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcformcontenttype IS 'identifica tipos de empr';


--
-- Name: COLUMN gtcformcontenttype.formcontenttypeid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcformcontenttype.formcontenttypeid IS 'Identificador do tipo de emprestimo';


--
-- Name: COLUMN gtcformcontenttype.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcformcontenttype.description IS 'Descri';


--
-- Name: gtcgeneralpolicy; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcgeneralpolicy (
    privilegegroupid integer NOT NULL,
    linkid integer NOT NULL,
    loangenerallimit integer,
    reservegenerallimit integer,
    reservegenerallimitininitiallevel integer
);


ALTER TABLE public.gtcgeneralpolicy OWNER TO postgres;

--
-- Name: gtchelp; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtchelp (
    helpid integer NOT NULL,
    form character varying(150) NOT NULL,
    subform character varying(150),
    help text NOT NULL,
    isactive boolean NOT NULL
);


ALTER TABLE public.gtchelp OWNER TO postgres;

--
-- Name: gtchelp_helpid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE gtchelp_helpid_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.gtchelp_helpid_seq OWNER TO postgres;

--
-- Name: gtchelp_helpid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE gtchelp_helpid_seq OWNED BY gtchelp.helpid;


--
-- Name: gtchelp_helpid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('gtchelp_helpid_seq', 4, true);


--
-- Name: seq_holidayid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_holidayid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_holidayid OWNER TO postgres;

--
-- Name: seq_holidayid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_holidayid', 3, true);


--
-- Name: gtcholiday; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcholiday (
    holidayid integer DEFAULT nextval('seq_holidayid'::regclass) NOT NULL,
    date date,
    description character varying,
    occursallyear boolean,
    libraryunitid integer
);


ALTER TABLE public.gtcholiday OWNER TO postgres;

--
-- Name: TABLE gtcholiday; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcholiday IS 'especifica o feriado para uma unidade. se for null vale para todas as unidades';


--
-- Name: seq_interchangeid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_interchangeid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_interchangeid OWNER TO postgres;

--
-- Name: seq_interchangeid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_interchangeid', 1, false);


--
-- Name: gtcinterchange; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcinterchange (
    interchangeid integer DEFAULT nextval('seq_interchangeid'::regclass) NOT NULL,
    type character(1),
    supplierid integer NOT NULL,
    description character varying,
    date timestamp without time zone NOT NULL,
    interchangestatusid integer,
    interchangetypeid integer,
    operator character varying(30),
    CONSTRAINT gtcinterchange_type_check CHECK ((type = ANY (ARRAY['p'::bpchar, 'd'::bpchar])))
);


ALTER TABLE public.gtcinterchange OWNER TO postgres;

--
-- Name: TABLE gtcinterchange; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcinterchange IS 'permuta';


--
-- Name: COLUMN gtcinterchange.interchangeid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcinterchange.interchangeid IS 'Identifica';


--
-- Name: COLUMN gtcinterchange.interchangetypeid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcinterchange.interchangetypeid IS '1 - Envio; 2 - Recebimento';


--
-- Name: seq_interchangeitemid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_interchangeitemid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_interchangeitemid OWNER TO postgres;

--
-- Name: seq_interchangeitemid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_interchangeitemid', 1, false);


--
-- Name: gtcinterchangeitem; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcinterchangeitem (
    interchangeitemid integer DEFAULT nextval('seq_interchangeitemid'::regclass) NOT NULL,
    interchangeid integer NOT NULL,
    controlnumber integer,
    content character varying
);


ALTER TABLE public.gtcinterchangeitem OWNER TO postgres;

--
-- Name: TABLE gtcinterchangeitem; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcinterchangeitem IS 'itens de permuta';


--
-- Name: COLUMN gtcinterchangeitem.interchangeitemid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcinterchangeitem.interchangeitemid IS 'Identifica';


--
-- Name: seq_interchangeobservationid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_interchangeobservationid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_interchangeobservationid OWNER TO postgres;

--
-- Name: seq_interchangeobservationid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_interchangeobservationid', 1, false);


--
-- Name: gtcinterchangeobservation; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcinterchangeobservation (
    interchangeobservationid integer DEFAULT nextval('seq_interchangeobservationid'::regclass) NOT NULL,
    interchangeid integer NOT NULL,
    observation text,
    date timestamp without time zone,
    operator character varying(30)
);


ALTER TABLE public.gtcinterchangeobservation OWNER TO postgres;

--
-- Name: TABLE gtcinterchangeobservation; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcinterchangeobservation IS 'observa';


--
-- Name: COLUMN gtcinterchangeobservation.interchangeobservationid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcinterchangeobservation.interchangeobservationid IS 'Identifica';


--
-- Name: seq_interchangestatusid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_interchangestatusid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_interchangestatusid OWNER TO postgres;

--
-- Name: seq_interchangestatusid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_interchangestatusid', 1, false);


--
-- Name: gtcinterchangestatus; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcinterchangestatus (
    interchangestatusid integer DEFAULT nextval('seq_interchangestatusid'::regclass) NOT NULL,
    description character varying(40) NOT NULL,
    interchangetypeid integer
);


ALTER TABLE public.gtcinterchangestatus OWNER TO postgres;

--
-- Name: TABLE gtcinterchangestatus; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcinterchangestatus IS 'estado da reserva';


--
-- Name: COLUMN gtcinterchangestatus.interchangestatusid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcinterchangestatus.interchangestatusid IS 'Identificador da situa';


--
-- Name: COLUMN gtcinterchangestatus.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcinterchangestatus.description IS 'Descri';


--
-- Name: seq_interchangetypeid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_interchangetypeid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_interchangetypeid OWNER TO postgres;

--
-- Name: seq_interchangetypeid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_interchangetypeid', 1, false);


--
-- Name: gtcinterchangetype; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcinterchangetype (
    interchangetypeid integer DEFAULT nextval('seq_interchangetypeid'::regclass) NOT NULL,
    description character varying(40) NOT NULL
);


ALTER TABLE public.gtcinterchangetype OWNER TO postgres;

--
-- Name: TABLE gtcinterchangetype; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcinterchangetype IS 'estado da reserva';


--
-- Name: COLUMN gtcinterchangetype.interchangetypeid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcinterchangetype.interchangetypeid IS 'Identificador da situa';


--
-- Name: COLUMN gtcinterchangetype.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcinterchangetype.description IS 'Descri';


--
-- Name: gtcinterestsarea; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcinterestsarea (
    personid integer NOT NULL,
    classificationareaid integer NOT NULL,
    bud_dia2sql_ignorar integer
);


ALTER TABLE public.gtcinterestsarea OWNER TO postgres;

--
-- Name: TABLE gtcinterestsarea; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcinterestsarea IS 'define as ';


--
-- Name: COLUMN gtcinterestsarea.personid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcinterestsarea.personid IS 'C';


--
-- Name: COLUMN gtcinterestsarea.classificationareaid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcinterestsarea.classificationareaid IS 'C';


--
-- Name: gtckardexcontrol; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtckardexcontrol (
    controlnumber integer NOT NULL,
    codigodeassinante character varying(40),
    libraryunitid integer NOT NULL,
    acquisitiontype character varying(1) NOT NULL,
    vencimentodaassinatura date,
    datadaassinatura date,
    entrancedate date,
    line integer
);


ALTER TABLE public.gtckardexcontrol OWNER TO postgres;

--
-- Name: TABLE gtckardexcontrol; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtckardexcontrol IS 'armazena dados da cole';


--
-- Name: COLUMN gtckardexcontrol.controlnumber; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtckardexcontrol.controlnumber IS 'Identificador da obra';


--
-- Name: COLUMN gtckardexcontrol.libraryunitid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtckardexcontrol.libraryunitid IS 'Codigo da unidade';


--
-- Name: COLUMN gtckardexcontrol.acquisitiontype; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtckardexcontrol.acquisitiontype IS 'Tipo de aquisicao';


--
-- Name: seq_labellayoutid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_labellayoutid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_labellayoutid OWNER TO postgres;

--
-- Name: seq_labellayoutid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_labellayoutid', 98, true);


--
-- Name: gtclabellayout; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtclabellayout (
    labellayoutid integer DEFAULT nextval('seq_labellayoutid'::regclass) NOT NULL,
    description character varying,
    topmargin double precision,
    leftmargin double precision,
    verticalspacing double precision,
    horizontalspacing double precision,
    height double precision,
    width double precision,
    lines double precision,
    columns double precision,
    pageformat character varying
);


ALTER TABLE public.gtclabellayout OWNER TO postgres;

--
-- Name: gtclibraryassociation; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtclibraryassociation (
    associationid integer NOT NULL,
    libraryunitid integer NOT NULL,
    bug_dia2sql_ignorar integer
);


ALTER TABLE public.gtclibraryassociation OWNER TO postgres;

--
-- Name: seq_librarygroupid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_librarygroupid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_librarygroupid OWNER TO postgres;

--
-- Name: seq_librarygroupid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_librarygroupid', 1, false);


--
-- Name: gtclibrarygroup; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtclibrarygroup (
    librarygroupid integer DEFAULT nextval('seq_librarygroupid'::regclass) NOT NULL,
    description character varying(100) NOT NULL,
    observation text
);


ALTER TABLE public.gtclibrarygroup OWNER TO postgres;

--
-- Name: TABLE gtclibrarygroup; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtclibrarygroup IS 'cadastra grupos para separar as unidades';


--
-- Name: COLUMN gtclibrarygroup.librarygroupid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclibrarygroup.librarygroupid IS 'C';


--
-- Name: COLUMN gtclibrarygroup.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclibrarygroup.description IS 'Nome do grupo';


--
-- Name: COLUMN gtclibrarygroup.observation; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclibrarygroup.observation IS 'Observacoes';


--
-- Name: seq_level; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_level
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_level OWNER TO postgres;

--
-- Name: seq_level; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_level', 1, true);


--
-- Name: seq_libraryunitid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_libraryunitid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_libraryunitid OWNER TO postgres;

--
-- Name: seq_libraryunitid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_libraryunitid', 1, true);


--
-- Name: gtclibraryunit; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtclibraryunit (
    libraryunitid integer DEFAULT nextval('seq_libraryunitid'::regclass) NOT NULL,
    libraryname character varying(100) NOT NULL,
    isrestricted boolean DEFAULT false,
    city character varying(50),
    zipcode character varying(9),
    location character varying(100),
    number character varying(10),
    complement character varying(60),
    email character varying(60),
    url character varying(60),
    librarygroupid integer,
    privilegegroupid integer NOT NULL,
    observation text,
    level integer DEFAULT nextval('seq_level'::regclass),
    acceptpurchaserequest boolean DEFAULT false NOT NULL
);


ALTER TABLE public.gtclibraryunit OWNER TO postgres;

--
-- Name: TABLE gtclibraryunit; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtclibraryunit IS 'unidades de bibliotecas';


--
-- Name: COLUMN gtclibraryunit.libraryunitid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclibraryunit.libraryunitid IS 'C';


--
-- Name: COLUMN gtclibraryunit.libraryname; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclibraryunit.libraryname IS 'Nome da unidade';


--
-- Name: COLUMN gtclibraryunit.city; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclibraryunit.city IS 'Nome da cidade, por enquanto fica com nome direto';


--
-- Name: COLUMN gtclibraryunit.zipcode; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclibraryunit.zipcode IS 'CEP';


--
-- Name: COLUMN gtclibraryunit.location; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclibraryunit.location IS 'Logradouro';


--
-- Name: COLUMN gtclibraryunit.number; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclibraryunit.number IS 'N';


--
-- Name: COLUMN gtclibraryunit.complement; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclibraryunit.complement IS 'Complemento';


--
-- Name: COLUMN gtclibraryunit.email; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclibraryunit.email IS 'Email da unidade';


--
-- Name: COLUMN gtclibraryunit.url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclibraryunit.url IS 'Site da unidade';


--
-- Name: gtclibraryunitaccess; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtclibraryunitaccess (
    libraryunitid integer NOT NULL,
    linkid integer NOT NULL,
    bug_dia2sql_ignorar integer
);


ALTER TABLE public.gtclibraryunitaccess OWNER TO postgres;

--
-- Name: TABLE gtclibraryunitaccess; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtclibraryunitaccess IS 'identifica os grupos que ter';


--
-- Name: gtclibraryunitconfig; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtclibraryunitconfig (
    libraryunitid integer NOT NULL,
    parameter text NOT NULL,
    value text,
    CONSTRAINT chk_library_unit_parameter CHECK (gtc_chk_parameter(parameter))
);


ALTER TABLE public.gtclibraryunitconfig OWNER TO postgres;

--
-- Name: TABLE gtclibraryunitconfig; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtclibraryunitconfig IS 'configuracoes do sistema';


--
-- Name: COLUMN gtclibraryunitconfig.libraryunitid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclibraryunitconfig.libraryunitid IS 'Modulo do parametro';


--
-- Name: COLUMN gtclibraryunitconfig.parameter; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclibraryunitconfig.parameter IS 'Parametro';


--
-- Name: COLUMN gtclibraryunitconfig.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclibraryunitconfig.value IS 'Valor';


--
-- Name: gtclibraryunitisclosed; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtclibraryunitisclosed (
    libraryunitid integer NOT NULL,
    weekdayid integer NOT NULL,
    bug_dia2sql_ignorar integer
);


ALTER TABLE public.gtclibraryunitisclosed OWNER TO postgres;

--
-- Name: seq_linkoffieldsbetweenspreadsheetsid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_linkoffieldsbetweenspreadsheetsid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_linkoffieldsbetweenspreadsheetsid OWNER TO postgres;

--
-- Name: seq_linkoffieldsbetweenspreadsheetsid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_linkoffieldsbetweenspreadsheetsid', 17, true);


--
-- Name: gtclinkoffieldsbetweenspreadsheets; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtclinkoffieldsbetweenspreadsheets (
    linkoffieldsbetweenspreadsheetsid integer DEFAULT nextval('seq_linkoffieldsbetweenspreadsheetsid'::regclass) NOT NULL,
    category character varying(2) NOT NULL,
    level character varying(1) NOT NULL,
    tag character varying NOT NULL,
    categoryson character varying(2) NOT NULL,
    levelson character varying(1) NOT NULL,
    tagson character varying NOT NULL,
    type integer
);


ALTER TABLE public.gtclinkoffieldsbetweenspreadsheets OWNER TO postgres;

--
-- Name: TABLE gtclinkoffieldsbetweenspreadsheets; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtclinkoffieldsbetweenspreadsheets IS 'liga';


--
-- Name: seq_loanid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_loanid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_loanid OWNER TO postgres;

--
-- Name: seq_loanid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_loanid', 1, false);


--
-- Name: gtcloan; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcloan (
    loanid integer DEFAULT nextval('seq_loanid'::regclass) NOT NULL,
    loantypeid integer NOT NULL,
    personid integer NOT NULL,
    linkid integer NOT NULL,
    privilegegroupid integer NOT NULL,
    itemnumber character varying(20) NOT NULL,
    libraryunitid integer,
    loandate timestamp without time zone NOT NULL,
    loanoperator character varying(30) NOT NULL,
    returnforecastdate timestamp without time zone NOT NULL,
    returndate timestamp without time zone,
    returnoperator character varying(30),
    renewalamount integer NOT NULL,
    renewalwebamount integer NOT NULL,
    renewalwebbonus boolean NOT NULL
);


ALTER TABLE public.gtcloan OWNER TO postgres;

--
-- Name: TABLE gtcloan; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcloan IS 'emprestimos';


--
-- Name: COLUMN gtcloan.loanid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloan.loanid IS 'Identificador do emprestimo';


--
-- Name: COLUMN gtcloan.linkid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloan.linkid IS 'Grupo que pertence o usu';


--
-- Name: COLUMN gtcloan.itemnumber; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloan.itemnumber IS 'N';


--
-- Name: COLUMN gtcloan.libraryunitid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloan.libraryunitid IS 'Unidade da biblioteca que emprestou';


--
-- Name: COLUMN gtcloan.loandate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloan.loandate IS 'Data e hora do empr';


--
-- Name: COLUMN gtcloan.loanoperator; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloan.loanoperator IS 'Login do miolo que emprestou o material';


--
-- Name: COLUMN gtcloan.returnforecastdate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloan.returnforecastdate IS 'Data prevista para devolu';


--
-- Name: COLUMN gtcloan.returndate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloan.returndate IS 'Data da devolu';


--
-- Name: COLUMN gtcloan.returnoperator; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloan.returnoperator IS 'Login do miolo que devolveu o material';


--
-- Name: COLUMN gtcloan.renewalamount; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloan.renewalamount IS 'Quantidade de renova';


--
-- Name: COLUMN gtcloan.renewalwebamount; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloan.renewalwebamount IS 'Valor das renova';


--
-- Name: COLUMN gtcloan.renewalwebbonus; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloan.renewalwebbonus IS 'Se este campo for verdadeiro, reinicia o campo renewalWebAmount a cada renova';


--
-- Name: seq_loanbetweenlibraryid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_loanbetweenlibraryid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_loanbetweenlibraryid OWNER TO postgres;

--
-- Name: seq_loanbetweenlibraryid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_loanbetweenlibraryid', 1, false);


--
-- Name: gtcloanbetweenlibrary; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcloanbetweenlibrary (
    loanbetweenlibraryid integer DEFAULT nextval('seq_loanbetweenlibraryid'::regclass) NOT NULL,
    loandate timestamp without time zone NOT NULL,
    returnforecastdate timestamp without time zone NOT NULL,
    returndate timestamp without time zone,
    limitdate timestamp without time zone,
    libraryunitid integer,
    personid integer,
    loanbetweenlibrarystatusid integer NOT NULL,
    observation text
);


ALTER TABLE public.gtcloanbetweenlibrary OWNER TO postgres;

--
-- Name: TABLE gtcloanbetweenlibrary; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcloanbetweenlibrary IS 'emprestimos';


--
-- Name: COLUMN gtcloanbetweenlibrary.loanbetweenlibraryid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloanbetweenlibrary.loanbetweenlibraryid IS 'Identificador do emprestimo';


--
-- Name: COLUMN gtcloanbetweenlibrary.loandate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloanbetweenlibrary.loandate IS 'Data e hora do empr';


--
-- Name: COLUMN gtcloanbetweenlibrary.returnforecastdate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloanbetweenlibrary.returnforecastdate IS 'Data prevista para devolu';


--
-- Name: COLUMN gtcloanbetweenlibrary.returndate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloanbetweenlibrary.returndate IS 'Data da devolu';


--
-- Name: gtcloanbetweenlibrarycomposition; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcloanbetweenlibrarycomposition (
    loanbetweenlibraryid integer NOT NULL,
    itemnumber character varying(20) NOT NULL,
    isconfirmed boolean NOT NULL
);


ALTER TABLE public.gtcloanbetweenlibrarycomposition OWNER TO postgres;

--
-- Name: TABLE gtcloanbetweenlibrarycomposition; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcloanbetweenlibrarycomposition IS 'composi';


--
-- Name: COLUMN gtcloanbetweenlibrarycomposition.loanbetweenlibraryid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloanbetweenlibrarycomposition.loanbetweenlibraryid IS 'Identificador do emprestimo';


--
-- Name: COLUMN gtcloanbetweenlibrarycomposition.itemnumber; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloanbetweenlibrarycomposition.itemnumber IS 'Data e hora do empr';


--
-- Name: COLUMN gtcloanbetweenlibrarycomposition.isconfirmed; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloanbetweenlibrarycomposition.isconfirmed IS 'Data prevista para devolu';


--
-- Name: seq_loanbetweenlibrarystatusid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_loanbetweenlibrarystatusid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_loanbetweenlibrarystatusid OWNER TO postgres;

--
-- Name: seq_loanbetweenlibrarystatusid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_loanbetweenlibrarystatusid', 1, false);


--
-- Name: gtcloanbetweenlibrarystatus; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcloanbetweenlibrarystatus (
    loanbetweenlibrarystatusid integer DEFAULT nextval('seq_loanbetweenlibrarystatusid'::regclass) NOT NULL,
    description character varying(40) NOT NULL
);


ALTER TABLE public.gtcloanbetweenlibrarystatus OWNER TO postgres;

--
-- Name: TABLE gtcloanbetweenlibrarystatus; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcloanbetweenlibrarystatus IS 'estado dos empr';


--
-- Name: COLUMN gtcloanbetweenlibrarystatus.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloanbetweenlibrarystatus.description IS 'Descri';


--
-- Name: gtcloanbetweenlibrarystatushistory; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcloanbetweenlibrarystatushistory (
    loanbetweenlibraryid integer NOT NULL,
    loanbetweenlibrarystatusid integer NOT NULL,
    date timestamp without time zone NOT NULL,
    operator character varying(30) NOT NULL
);


ALTER TABLE public.gtcloanbetweenlibrarystatushistory OWNER TO postgres;

--
-- Name: TABLE gtcloanbetweenlibrarystatushistory; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcloanbetweenlibrarystatushistory IS 'mantem o historico dos emprestimos entre bibliotecas';


--
-- Name: COLUMN gtcloanbetweenlibrarystatushistory.loanbetweenlibraryid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloanbetweenlibrarystatushistory.loanbetweenlibraryid IS 'Identifica';


--
-- Name: COLUMN gtcloanbetweenlibrarystatushistory.loanbetweenlibrarystatusid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloanbetweenlibrarystatushistory.loanbetweenlibrarystatusid IS 'Estado da reserva';


--
-- Name: COLUMN gtcloanbetweenlibrarystatushistory.date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloanbetweenlibrarystatushistory.date IS 'Cado o exemplar volta ela se torna confirmada';


--
-- Name: seq_loantypeid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_loantypeid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_loantypeid OWNER TO postgres;

--
-- Name: seq_loantypeid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_loantypeid', 1, false);


--
-- Name: gtcloantype; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcloantype (
    loantypeid integer DEFAULT nextval('seq_loantypeid'::regclass) NOT NULL,
    description character varying(40) NOT NULL
);


ALTER TABLE public.gtcloantype OWNER TO postgres;

--
-- Name: TABLE gtcloantype; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcloantype IS 'identifica tipos de empr';


--
-- Name: COLUMN gtcloantype.loantypeid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloantype.loantypeid IS 'Identificador do tipo de emprestimo';


--
-- Name: COLUMN gtcloantype.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcloantype.description IS 'Descri';


--
-- Name: seq_locationformaterialmovementid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_locationformaterialmovementid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_locationformaterialmovementid OWNER TO postgres;

--
-- Name: seq_locationformaterialmovementid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_locationformaterialmovementid', 1, true);


--
-- Name: gtclocationformaterialmovement; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtclocationformaterialmovement (
    locationformaterialmovementid integer DEFAULT nextval('seq_locationformaterialmovementid'::regclass) NOT NULL,
    description character varying(40) NOT NULL,
    observation text,
    sendloanreceiptbyemail boolean,
    sendrenewreceiptbyemail boolean,
    sendreturnreceiptbyemail boolean
);


ALTER TABLE public.gtclocationformaterialmovement OWNER TO postgres;

--
-- Name: TABLE gtclocationformaterialmovement; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtclocationformaterialmovement IS 'local para circula';


--
-- Name: COLUMN gtclocationformaterialmovement.locationformaterialmovementid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclocationformaterialmovement.locationformaterialmovementid IS 'Identificador do local para circula';


--
-- Name: COLUMN gtclocationformaterialmovement.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtclocationformaterialmovement.description IS 'Descri';


--
-- Name: seq_marctaglistingid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_marctaglistingid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_marctaglistingid OWNER TO postgres;

--
-- Name: seq_marctaglistingid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_marctaglistingid', 1, false);


--
-- Name: gtcmarctaglisting; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcmarctaglisting (
    marctaglistingid character varying DEFAULT nextval('seq_marctaglistingid'::regclass) NOT NULL,
    description character varying
);


ALTER TABLE public.gtcmarctaglisting OWNER TO postgres;

--
-- Name: gtcmarctaglistingoption; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcmarctaglistingoption (
    marctaglistingid character varying,
    option text,
    description character varying
);


ALTER TABLE public.gtcmarctaglistingoption OWNER TO postgres;

--
-- Name: seq_controlnumber; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_controlnumber
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_controlnumber OWNER TO postgres;

--
-- Name: seq_controlnumber; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_controlnumber', 1, false);


--
-- Name: gtcmaterial; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcmaterial (
    controlnumber integer DEFAULT nextval('seq_controlnumber'::regclass) NOT NULL,
    fieldid character varying(3) NOT NULL,
    subfieldid character varying(1) NOT NULL,
    line integer NOT NULL,
    indicator1 character varying(1),
    indicator2 character varying(1),
    content text,
    searchcontent text,
    prefixid integer,
    suffixid integer,
    separatorid integer
);


ALTER TABLE public.gtcmaterial OWNER TO postgres;

--
-- Name: TABLE gtcmaterial; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcmaterial IS 'armazena os materias no padr';


--
-- Name: gtcmaterialcontrol; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcmaterialcontrol (
    controlnumber integer NOT NULL,
    controlnumberfather integer,
    entrancedate date NOT NULL,
    lastchangedate date NOT NULL,
    category character varying(2) NOT NULL,
    level character varying(1) NOT NULL,
    materialgenderid integer,
    materialtypeid integer,
    materialphysicaltypeid integer
);


ALTER TABLE public.gtcmaterialcontrol OWNER TO postgres;

--
-- Name: TABLE gtcmaterialcontrol; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcmaterialcontrol IS 'armazena os exemplares';


--
-- Name: COLUMN gtcmaterialcontrol.controlnumber; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcmaterialcontrol.controlnumber IS 'Identificador da obra';


--
-- Name: seq_gtcmaterialevaluation; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_gtcmaterialevaluation
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_gtcmaterialevaluation OWNER TO postgres;

--
-- Name: seq_gtcmaterialevaluation; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_gtcmaterialevaluation', 1, false);


--
-- Name: gtcmaterialevaluation; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcmaterialevaluation (
    materialevaluationid integer DEFAULT nextval('seq_gtcmaterialevaluation'::regclass) NOT NULL,
    controlnumber integer NOT NULL,
    personid integer NOT NULL,
    date timestamp without time zone NOT NULL,
    comment text,
    evaluation integer
);


ALTER TABLE public.gtcmaterialevaluation OWNER TO postgres;

--
-- Name: seq_materialgenderid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_materialgenderid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_materialgenderid OWNER TO postgres;

--
-- Name: seq_materialgenderid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_materialgenderid', 5, true);


--
-- Name: gtcmaterialgender; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcmaterialgender (
    materialgenderid integer DEFAULT nextval('seq_materialgenderid'::regclass) NOT NULL,
    description character varying
);


ALTER TABLE public.gtcmaterialgender OWNER TO postgres;

--
-- Name: seq_materialhistoryid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_materialhistoryid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_materialhistoryid OWNER TO postgres;

--
-- Name: seq_materialhistoryid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_materialhistoryid', 1, false);


--
-- Name: gtcmaterialhistory; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcmaterialhistory (
    materialhistoryid integer DEFAULT nextval('seq_materialhistoryid'::regclass) NOT NULL,
    controlnumber integer NOT NULL,
    revisionnumber integer NOT NULL,
    operator character varying(30) NOT NULL,
    data timestamp without time zone NOT NULL,
    chancestype character(1) NOT NULL,
    fieldid character varying(3) NOT NULL,
    subfieldid character varying(1) NOT NULL,
    previousline integer,
    previousindicator1 character varying(1),
    previousindicator2 character varying(1),
    previouscontent text,
    currentline integer,
    currentindicator1 character varying(1),
    currentindicator2 character varying(1),
    currentcontent text,
    previousprefixid integer,
    previoussuffixid integer,
    previousseparatorid integer,
    currentprefixid integer,
    currentsuffixid integer,
    currentseparatorid integer
);


ALTER TABLE public.gtcmaterialhistory OWNER TO postgres;

--
-- Name: TABLE gtcmaterialhistory; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcmaterialhistory IS 'armazena os materias no padr';


--
-- Name: COLUMN gtcmaterialhistory.chancestype; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcmaterialhistory.chancestype IS 'I - insert U - update D - delete';


--
-- Name: seq_materialphysicaltypeid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_materialphysicaltypeid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_materialphysicaltypeid OWNER TO postgres;

--
-- Name: seq_materialphysicaltypeid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_materialphysicaltypeid', 9, true);


--
-- Name: gtcmaterialphysicaltype; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcmaterialphysicaltype (
    materialphysicaltypeid integer DEFAULT nextval('seq_materialphysicaltypeid'::regclass) NOT NULL,
    description character varying NOT NULL,
    image text,
    observation text
);


ALTER TABLE public.gtcmaterialphysicaltype OWNER TO postgres;

--
-- Name: seq_materialtypeid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_materialtypeid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_materialtypeid OWNER TO postgres;

--
-- Name: seq_materialtypeid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_materialtypeid', 39, true);


--
-- Name: gtcmaterialtype; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcmaterialtype (
    materialtypeid integer DEFAULT nextval('seq_materialtypeid'::regclass) NOT NULL,
    description character varying NOT NULL,
    isrestricted boolean NOT NULL,
    level integer,
    observation text
);


ALTER TABLE public.gtcmaterialtype OWNER TO postgres;

--
-- Name: gtcmylibrary; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcmylibrary (
    mylibraryid integer NOT NULL,
    personid integer NOT NULL,
    tablename character varying(255),
    tableid character varying(255),
    date timestamp without time zone NOT NULL,
    message text NOT NULL,
    visible boolean NOT NULL
);


ALTER TABLE public.gtcmylibrary OWNER TO postgres;

--
-- Name: gtcmylibrary_mylibraryid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE gtcmylibrary_mylibraryid_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.gtcmylibrary_mylibraryid_seq OWNER TO postgres;

--
-- Name: gtcmylibrary_mylibraryid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE gtcmylibrary_mylibraryid_seq OWNED BY gtcmylibrary.mylibraryid;


--
-- Name: gtcmylibrary_mylibraryid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('gtcmylibrary_mylibraryid_seq', 1, false);


--
-- Name: seq_newsid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_newsid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_newsid OWNER TO postgres;

--
-- Name: seq_newsid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_newsid', 1, true);


--
-- Name: gtcnews; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcnews (
    newsid integer DEFAULT nextval('seq_newsid'::regclass) NOT NULL,
    place integer NOT NULL,
    title1 character varying,
    news text,
    date timestamp without time zone NOT NULL,
    begindate timestamp without time zone,
    enddate timestamp without time zone,
    isrestricted boolean,
    isactive boolean,
    operator character varying(30),
    libraryunitid integer
);


ALTER TABLE public.gtcnews OWNER TO postgres;

--
-- Name: TABLE gtcnews; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcnews IS 'noticia';


--
-- Name: COLUMN gtcnews.newsid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcnews.newsid IS 'Identifica';


--
-- Name: COLUMN gtcnews.place; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcnews.place IS '1 - Minha biblioteca, 2 - Tela inicial, 3 - Pesquisa';


--
-- Name: gtcnewsaccess; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcnewsaccess (
    newsid integer NOT NULL,
    linkid integer NOT NULL,
    bug_dia2sql_ignorar integer
);


ALTER TABLE public.gtcnewsaccess OWNER TO postgres;

--
-- Name: TABLE gtcnewsaccess; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcnewsaccess IS 'identifica os grupos que ter';


--
-- Name: seq_operationid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_operationid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_operationid OWNER TO postgres;

--
-- Name: seq_operationid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_operationid', 22, true);


--
-- Name: gtcoperation; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcoperation (
    operationid integer DEFAULT nextval('seq_operationid'::regclass) NOT NULL,
    description character varying(100) NOT NULL,
    definerule boolean
);


ALTER TABLE public.gtcoperation OWNER TO postgres;

--
-- Name: TABLE gtcoperation; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcoperation IS 'operacoes';


--
-- Name: COLUMN gtcoperation.operationid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcoperation.operationid IS 'Identificador da operacao';


--
-- Name: COLUMN gtcoperation.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcoperation.description IS 'Descricao';


--
-- Name: gtcoperatorlibraryunit; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcoperatorlibraryunit (
    operator character varying NOT NULL,
    libraryunitid integer
);


ALTER TABLE public.gtcoperatorlibraryunit OWNER TO postgres;

--
-- Name: seq_penaltyid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_penaltyid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_penaltyid OWNER TO postgres;

--
-- Name: seq_penaltyid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_penaltyid', 1, false);


--
-- Name: gtcpenalty; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcpenalty (
    penaltyid integer DEFAULT nextval('seq_penaltyid'::regclass) NOT NULL,
    personid integer NOT NULL,
    libraryunitid integer,
    observation text,
    internalobservation text,
    penaltydate timestamp without time zone NOT NULL,
    penaltyenddate timestamp without time zone,
    operator character varying(30) NOT NULL
);


ALTER TABLE public.gtcpenalty OWNER TO postgres;

--
-- Name: TABLE gtcpenalty; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcpenalty IS 'penalidade';


--
-- Name: COLUMN gtcpenalty.penaltyid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcpenalty.penaltyid IS 'Identifica';


--
-- Name: COLUMN gtcpenalty.personid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcpenalty.personid IS 'C';


--
-- Name: COLUMN gtcpenalty.observation; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcpenalty.observation IS 'Descri';


--
-- Name: COLUMN gtcpenalty.penaltydate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcpenalty.penaltydate IS 'Data da inclus';


--
-- Name: COLUMN gtcpenalty.penaltyenddate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcpenalty.penaltyenddate IS 'Data de final da penalidade.';


--
-- Name: COLUMN gtcpenalty.operator; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcpenalty.operator IS 'Usu';


--
-- Name: gtcpersonconfig; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcpersonconfig (
    personid integer NOT NULL,
    parameter text NOT NULL,
    value text
);


ALTER TABLE public.gtcpersonconfig OWNER TO postgres;

--
-- Name: TABLE gtcpersonconfig; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcpersonconfig IS 'configuracoes do sistema';


--
-- Name: COLUMN gtcpersonconfig.personid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcpersonconfig.personid IS 'Modulo do parametro';


--
-- Name: COLUMN gtcpersonconfig.parameter; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcpersonconfig.parameter IS 'Parametro';


--
-- Name: COLUMN gtcpersonconfig.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcpersonconfig.value IS 'Valor';


--
-- Name: gtcpersonlibraryunit; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcpersonlibraryunit (
    libraryunitid integer NOT NULL,
    personid integer NOT NULL,
    bug_dia2sql_ignorar integer
);


ALTER TABLE public.gtcpersonlibraryunit OWNER TO postgres;

--
-- Name: TABLE gtcpersonlibraryunit; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcpersonlibraryunit IS 'reservas';


--
-- Name: COLUMN gtcpersonlibraryunit.libraryunitid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcpersonlibraryunit.libraryunitid IS 'C';


--
-- Name: COLUMN gtcpersonlibraryunit.personid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcpersonlibraryunit.personid IS 'C';


--
-- Name: gtcpolicy; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcpolicy (
    privilegegroupid integer NOT NULL,
    linkid integer NOT NULL,
    materialgenderid integer NOT NULL,
    loandays integer,
    loandate date,
    loanlimit integer,
    renewallimit integer,
    reservelimit integer,
    daysofwaitforreserve integer,
    reservelimitininitiallevel integer,
    daysofwaitforreserveininitiallevel integer,
    finevalue double precision,
    renewalweblimit integer,
    renewalwebbonus boolean,
    additionaldaysforholidays integer,
    penaltybydelay double precision
);


ALTER TABLE public.gtcpolicy OWNER TO postgres;

--
-- Name: TABLE gtcpolicy; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcpolicy IS 'numero maximo de reservas de nivel inicial - disponivel, congelado, etc';


--
-- Name: COLUMN gtcpolicy.penaltybydelay; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcpolicy.penaltybydelay IS 'Número de dias aplicado para cada dia de atraso';


--
-- Name: gtcprecatalogue; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcprecatalogue (
    controlnumber integer NOT NULL,
    fieldid character varying(3) NOT NULL,
    subfieldid character varying(1) NOT NULL,
    line integer NOT NULL,
    indicator1 character varying(1),
    indicator2 character varying(1),
    content text,
    searchcontent text,
    prefixid integer,
    suffixid integer,
    separatorid integer
);


ALTER TABLE public.gtcprecatalogue OWNER TO postgres;

--
-- Name: TABLE gtcprecatalogue; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcprecatalogue IS 'armazena temporariamente os materias no padr';


--
-- Name: seq_prefixsuffixid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_prefixsuffixid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_prefixsuffixid OWNER TO postgres;

--
-- Name: seq_prefixsuffixid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_prefixsuffixid', 2, true);


--
-- Name: gtcprefixsuffix; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcprefixsuffix (
    prefixsuffixid integer DEFAULT nextval('seq_prefixsuffixid'::regclass) NOT NULL,
    fieldid character varying(3) NOT NULL,
    subfieldid character varying(1) NOT NULL,
    content character varying NOT NULL,
    type integer
);


ALTER TABLE public.gtcprefixsuffix OWNER TO postgres;

--
-- Name: TABLE gtcprefixsuffix; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcprefixsuffix IS 'tabela para prefixos e sufixos';


--
-- Name: COLUMN gtcprefixsuffix.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcprefixsuffix.type IS '1 - prefix 2 - suffix';


--
-- Name: seq_privilegegroupid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_privilegegroupid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_privilegegroupid OWNER TO postgres;

--
-- Name: seq_privilegegroupid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_privilegegroupid', 1, true);


--
-- Name: gtcprivilegegroup; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcprivilegegroup (
    privilegegroupid integer DEFAULT nextval('seq_privilegegroupid'::regclass) NOT NULL,
    description character varying(50) NOT NULL
);


ALTER TABLE public.gtcprivilegegroup OWNER TO postgres;

--
-- Name: TABLE gtcprivilegegroup; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcprivilegegroup IS 'grupo de privilegio. relaciona as unidade com pol';


--
-- Name: seq_gtcpurchaserequest; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_gtcpurchaserequest
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_gtcpurchaserequest OWNER TO postgres;

--
-- Name: seq_gtcpurchaserequest; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_gtcpurchaserequest', 1, false);


--
-- Name: gtcpurchaserequest; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcpurchaserequest (
    purchaserequestid integer DEFAULT nextval('seq_gtcpurchaserequest'::regclass) NOT NULL,
    libraryunitid integer NOT NULL,
    personid integer NOT NULL,
    costcenterid integer,
    amount integer,
    course character varying(255),
    observation text,
    needdelivery date,
    forecastdelivery date,
    deliverydate date,
    voucher integer,
    controlnumber integer,
    precontrolnumber integer,
    externalid character varying(255)
);


ALTER TABLE public.gtcpurchaserequest OWNER TO postgres;

--
-- Name: gtcpurchaserequestmaterial; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcpurchaserequestmaterial (
    purchaserequestid integer NOT NULL,
    fieldid character varying(3) NOT NULL,
    subfieldid character varying(1) NOT NULL,
    content text NOT NULL
);


ALTER TABLE public.gtcpurchaserequestmaterial OWNER TO postgres;

--
-- Name: gtcpurchaserequestquotation; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcpurchaserequestquotation (
    purchaserequestid integer NOT NULL,
    supplierid integer NOT NULL,
    value real NOT NULL,
    observation text
);


ALTER TABLE public.gtcpurchaserequestquotation OWNER TO postgres;

--
-- Name: gtcpurchaserequestquotation_supplierid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE gtcpurchaserequestquotation_supplierid_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.gtcpurchaserequestquotation_supplierid_seq OWNER TO postgres;

--
-- Name: gtcpurchaserequestquotation_supplierid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE gtcpurchaserequestquotation_supplierid_seq OWNED BY gtcpurchaserequestquotation.supplierid;


--
-- Name: gtcpurchaserequestquotation_supplierid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('gtcpurchaserequestquotation_supplierid_seq', 1, false);


--
-- Name: seq_renewid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_renewid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_renewid OWNER TO postgres;

--
-- Name: seq_renewid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_renewid', 1, false);


--
-- Name: gtcrenew; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcrenew (
    renewid integer DEFAULT nextval('seq_renewid'::regclass) NOT NULL,
    loanid integer NOT NULL,
    renewtypeid integer,
    renewdate timestamp without time zone,
    returnforecastdate timestamp without time zone NOT NULL,
    operator character varying(30) NOT NULL
);


ALTER TABLE public.gtcrenew OWNER TO postgres;

--
-- Name: TABLE gtcrenew; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcrenew IS 'renovacao';


--
-- Name: COLUMN gtcrenew.renewid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcrenew.renewid IS 'Identifica';


--
-- Name: COLUMN gtcrenew.loanid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcrenew.loanid IS 'C';


--
-- Name: COLUMN gtcrenew.renewdate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcrenew.renewdate IS 'Data e hora da renovacao';


--
-- Name: COLUMN gtcrenew.returnforecastdate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcrenew.returnforecastdate IS 'Data da inclus';


--
-- Name: COLUMN gtcrenew.operator; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcrenew.operator IS 'Usu';


--
-- Name: seq_renewtypeid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_renewtypeid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_renewtypeid OWNER TO postgres;

--
-- Name: seq_renewtypeid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_renewtypeid', 1, false);


--
-- Name: gtcrenewtype; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcrenewtype (
    renewtypeid integer DEFAULT nextval('seq_renewtypeid'::regclass) NOT NULL,
    description character varying(40) NOT NULL
);


ALTER TABLE public.gtcrenewtype OWNER TO postgres;

--
-- Name: TABLE gtcrenewtype; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcrenewtype IS 'identifica tipos de renovacao.';


--
-- Name: COLUMN gtcrenewtype.renewtypeid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcrenewtype.renewtypeid IS 'Identificador do tipo de renovaca';


--
-- Name: COLUMN gtcrenewtype.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcrenewtype.description IS 'Descri';


--
-- Name: gtcreport; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcreport (
    reportid character varying(20) NOT NULL,
    title character varying NOT NULL,
    description text,
    permission character varying NOT NULL,
    reportsql text,
    reportsubsql text,
    script text,
    model character varying,
    isactive boolean NOT NULL,
    reportgroup character varying,
    CONSTRAINT chk_gtcreport_reportgroup CHECK (gtc_chk_domain('REPORT_GROUP'::character varying, reportgroup))
);


ALTER TABLE public.gtcreport OWNER TO postgres;

--
-- Name: TABLE gtcreport; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcreport IS 'relatorios';


--
-- Name: seq_reportparameterid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_reportparameterid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_reportparameterid OWNER TO postgres;

--
-- Name: seq_reportparameterid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_reportparameterid', 172, true);


--
-- Name: gtcreportparameter; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcreportparameter (
    reportparameterid integer DEFAULT nextval('seq_reportparameterid'::regclass) NOT NULL,
    reportid character varying(20) NOT NULL,
    label character varying NOT NULL,
    identifier character varying NOT NULL,
    type character varying NOT NULL,
    defaultvalue character varying,
    options text,
    lastvalue character varying,
    level integer
);


ALTER TABLE public.gtcreportparameter OWNER TO postgres;

--
-- Name: TABLE gtcreportparameter; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcreportparameter IS 'parametros do relatorios';


--
-- Name: seq_requestchangeexemplarystatusid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_requestchangeexemplarystatusid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_requestchangeexemplarystatusid OWNER TO postgres;

--
-- Name: seq_requestchangeexemplarystatusid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_requestchangeexemplarystatusid', 1, false);


--
-- Name: gtcrequestchangeexemplarystatus; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcrequestchangeexemplarystatus (
    requestchangeexemplarystatusid integer DEFAULT nextval('seq_requestchangeexemplarystatusid'::regclass) NOT NULL,
    futurestatusid integer NOT NULL,
    personid integer NOT NULL,
    observation text,
    date timestamp without time zone NOT NULL,
    finaldate timestamp without time zone NOT NULL,
    requestchangeexemplarystatusstatusid integer NOT NULL,
    libraryunitid integer NOT NULL,
    aprovejustone boolean DEFAULT true,
    discipline character varying
);


ALTER TABLE public.gtcrequestchangeexemplarystatus OWNER TO postgres;

--
-- Name: TABLE gtcrequestchangeexemplarystatus; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcrequestchangeexemplarystatus IS 'estado do exemplar';


--
-- Name: COLUMN gtcrequestchangeexemplarystatus.requestchangeexemplarystatusstatusid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcrequestchangeexemplarystatus.requestchangeexemplarystatusstatusid IS 'referencia tabela de possiveis estados';


--
-- Name: COLUMN gtcrequestchangeexemplarystatus.libraryunitid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcrequestchangeexemplarystatus.libraryunitid IS 'referencia biblioteca';


--
-- Name: COLUMN gtcrequestchangeexemplarystatus.discipline; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcrequestchangeexemplarystatus.discipline IS 'Disciplina (mat';


--
-- Name: gtcrequestchangeexemplarystatusaccess; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcrequestchangeexemplarystatusaccess (
    baslinkid integer NOT NULL,
    exemplarystatusid integer NOT NULL,
    bug_dia2sql_ignorar integer
);


ALTER TABLE public.gtcrequestchangeexemplarystatusaccess OWNER TO postgres;

--
-- Name: gtcrequestchangeexemplarystatuscomposition; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcrequestchangeexemplarystatuscomposition (
    requestchangeexemplarystatusid integer NOT NULL,
    itemnumber character varying(20) NOT NULL,
    exemplaryfuturestatusdefinedid integer,
    confirm boolean DEFAULT false,
    date timestamp without time zone NOT NULL,
    applied boolean DEFAULT false
);


ALTER TABLE public.gtcrequestchangeexemplarystatuscomposition OWNER TO postgres;

--
-- Name: TABLE gtcrequestchangeexemplarystatuscomposition; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcrequestchangeexemplarystatuscomposition IS 'quando o administrador permite a requisi';


--
-- Name: COLUMN gtcrequestchangeexemplarystatuscomposition.applied; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcrequestchangeexemplarystatuscomposition.applied IS 'quando a requisi';


--
-- Name: seq_requestchangeexemplarystatusstatusid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_requestchangeexemplarystatusstatusid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_requestchangeexemplarystatusstatusid OWNER TO postgres;

--
-- Name: seq_requestchangeexemplarystatusstatusid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_requestchangeexemplarystatusstatusid', 6, true);


--
-- Name: gtcrequestchangeexemplarystatusstatus; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcrequestchangeexemplarystatusstatus (
    requestchangeexemplarystatusstatusid integer DEFAULT nextval('seq_requestchangeexemplarystatusstatusid'::regclass) NOT NULL,
    description character varying(40) NOT NULL
);


ALTER TABLE public.gtcrequestchangeexemplarystatusstatus OWNER TO postgres;

--
-- Name: gtcrequestchangeexemplarystatusstatushistory; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcrequestchangeexemplarystatusstatushistory (
    requestchangeexemplarystatusid integer NOT NULL,
    requestchangeexemplarystatusstatusid integer NOT NULL,
    date timestamp without time zone NOT NULL,
    operator character varying(40) NOT NULL
);


ALTER TABLE public.gtcrequestchangeexemplarystatusstatushistory OWNER TO postgres;

--
-- Name: seq_reserveid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_reserveid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_reserveid OWNER TO postgres;

--
-- Name: seq_reserveid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_reserveid', 1, false);


--
-- Name: gtcreserve; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcreserve (
    reserveid integer DEFAULT nextval('seq_reserveid'::regclass) NOT NULL,
    libraryunitid integer,
    personid integer NOT NULL,
    requesteddate timestamp without time zone NOT NULL,
    limitdate timestamp without time zone,
    reservestatusid integer NOT NULL,
    reservetypeid integer NOT NULL
);


ALTER TABLE public.gtcreserve OWNER TO postgres;

--
-- Name: TABLE gtcreserve; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcreserve IS 'reservas';


--
-- Name: COLUMN gtcreserve.reserveid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcreserve.reserveid IS 'Identificador da reserva';


--
-- Name: COLUMN gtcreserve.libraryunitid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcreserve.libraryunitid IS 'C';


--
-- Name: COLUMN gtcreserve.personid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcreserve.personid IS 'C';


--
-- Name: COLUMN gtcreserve.limitdate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcreserve.limitdate IS 'Data limite de esprera. ';


--
-- Name: COLUMN gtcreserve.reservestatusid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcreserve.reservestatusid IS 'C';


--
-- Name: gtcreservecomposition; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcreservecomposition (
    reserveid integer NOT NULL,
    itemnumber character varying(20) NOT NULL,
    isconfirmed boolean DEFAULT false
);


ALTER TABLE public.gtcreservecomposition OWNER TO postgres;

--
-- Name: TABLE gtcreservecomposition; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcreservecomposition IS 'composi';


--
-- Name: COLUMN gtcreservecomposition.reserveid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcreservecomposition.reserveid IS 'Identifica';


--
-- Name: COLUMN gtcreservecomposition.itemnumber; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcreservecomposition.itemnumber IS 'N';


--
-- Name: COLUMN gtcreservecomposition.isconfirmed; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcreservecomposition.isconfirmed IS 'Cado o exemplar volta ela se torna confirmada';


--
-- Name: seq_reservestatusid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_reservestatusid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_reservestatusid OWNER TO postgres;

--
-- Name: seq_reservestatusid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_reservestatusid', 6, true);


--
-- Name: gtcreservestatus; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcreservestatus (
    reservestatusid integer DEFAULT nextval('seq_reservestatusid'::regclass) NOT NULL,
    description character varying(40) NOT NULL
);


ALTER TABLE public.gtcreservestatus OWNER TO postgres;

--
-- Name: TABLE gtcreservestatus; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcreservestatus IS 'estado da reserva';


--
-- Name: COLUMN gtcreservestatus.reservestatusid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcreservestatus.reservestatusid IS 'Identificador da situa';


--
-- Name: COLUMN gtcreservestatus.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcreservestatus.description IS 'Descri';


--
-- Name: gtcreservestatushistory; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcreservestatushistory (
    reserveid integer NOT NULL,
    reservestatusid integer NOT NULL,
    date timestamp without time zone NOT NULL,
    operator character varying(30) NOT NULL
);


ALTER TABLE public.gtcreservestatushistory OWNER TO postgres;

--
-- Name: TABLE gtcreservestatushistory; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcreservestatushistory IS 'mantem o historico das trocas de estado';


--
-- Name: COLUMN gtcreservestatushistory.reserveid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcreservestatushistory.reserveid IS 'Identifica';


--
-- Name: COLUMN gtcreservestatushistory.reservestatusid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcreservestatushistory.reservestatusid IS 'Estado da reserva';


--
-- Name: COLUMN gtcreservestatushistory.date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcreservestatushistory.date IS 'Cado o exemplar volta ela se torna confirmada';


--
-- Name: seq_reservetypeid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_reservetypeid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_reservetypeid OWNER TO postgres;

--
-- Name: seq_reservetypeid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_reservetypeid', 5, true);


--
-- Name: gtcreservetype; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcreservetype (
    reservetypeid integer DEFAULT nextval('seq_reservetypeid'::regclass) NOT NULL,
    description character varying(40) NOT NULL
);


ALTER TABLE public.gtcreservetype OWNER TO postgres;

--
-- Name: TABLE gtcreservetype; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcreservetype IS 'identifica tipos de reserva.';


--
-- Name: COLUMN gtcreservetype.reservetypeid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcreservetype.reservetypeid IS 'Identificador do tipo de reserva';


--
-- Name: COLUMN gtcreservetype.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcreservetype.description IS 'Descri';


--
-- Name: seq_returnregisterid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_returnregisterid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_returnregisterid OWNER TO postgres;

--
-- Name: seq_returnregisterid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_returnregisterid', 1, false);


--
-- Name: gtcreturnregister; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcreturnregister (
    returnregisterid integer DEFAULT nextval('seq_returnregisterid'::regclass) NOT NULL,
    returntypeid integer NOT NULL,
    itemnumber character varying(20) NOT NULL,
    date timestamp without time zone NOT NULL,
    operator character varying(30) NOT NULL
);


ALTER TABLE public.gtcreturnregister OWNER TO postgres;

--
-- Name: TABLE gtcreturnregister; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcreturnregister IS 'registra as devolu';


--
-- Name: seq_returntypeid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_returntypeid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_returntypeid OWNER TO postgres;

--
-- Name: seq_returntypeid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_returntypeid', 2, true);


--
-- Name: gtcreturntype; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcreturntype (
    returntypeid integer DEFAULT nextval('seq_returntypeid'::regclass) NOT NULL,
    description character varying(250) NOT NULL
);


ALTER TABLE public.gtcreturntype OWNER TO postgres;

--
-- Name: TABLE gtcreturntype; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcreturntype IS 'define os tipos de devolu';


--
-- Name: gtcright; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcright (
    privilegegroupid integer NOT NULL,
    linkid integer NOT NULL,
    materialgenderid integer NOT NULL,
    operationid integer NOT NULL
);


ALTER TABLE public.gtcright OWNER TO postgres;

--
-- Name: gtcrulesformaterialmovement; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcrulesformaterialmovement (
    currentstate integer NOT NULL,
    operationid integer NOT NULL,
    locationformaterialmovementid integer NOT NULL,
    futurestate integer NOT NULL
);


ALTER TABLE public.gtcrulesformaterialmovement OWNER TO postgres;

--
-- Name: TABLE gtcrulesformaterialmovement; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcrulesformaterialmovement IS 'regras para circulacao de material';


--
-- Name: COLUMN gtcrulesformaterialmovement.currentstate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcrulesformaterialmovement.currentstate IS 'Estado atual';


--
-- Name: COLUMN gtcrulesformaterialmovement.operationid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcrulesformaterialmovement.operationid IS 'Identificador da operacao';


--
-- Name: COLUMN gtcrulesformaterialmovement.locationformaterialmovementid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcrulesformaterialmovement.locationformaterialmovementid IS 'Identificacao do local para circulacao do material';


--
-- Name: COLUMN gtcrulesformaterialmovement.futurestate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcrulesformaterialmovement.futurestate IS 'Estado futuro';


--
-- Name: seq_rulestocompletefieldsmarcid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_rulestocompletefieldsmarcid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_rulestocompletefieldsmarcid OWNER TO postgres;

--
-- Name: seq_rulestocompletefieldsmarcid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_rulestocompletefieldsmarcid', 1, false);


--
-- Name: gtcrulestocompletefieldsmarc; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcrulestocompletefieldsmarc (
    rulestocompletefieldsmarcid integer DEFAULT nextval('seq_rulestocompletefieldsmarcid'::regclass) NOT NULL,
    category character varying(2) NOT NULL,
    originfield text NOT NULL,
    fatefield text NOT NULL,
    affectrecordscompleted boolean
);


ALTER TABLE public.gtcrulestocompletefieldsmarc OWNER TO postgres;

--
-- Name: TABLE gtcrulestocompletefieldsmarc; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcrulestocompletefieldsmarc IS 'regras para preenchimento de campos marc';


--
-- Name: COLUMN gtcrulestocompletefieldsmarc.affectrecordscompleted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcrulestocompletefieldsmarc.affectrecordscompleted IS 'Se for true altera os registros com valor';


--
-- Name: gtcschedulecycle; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcschedulecycle (
    schedulecycleid integer NOT NULL,
    description character varying NOT NULL,
    valuetype character varying NOT NULL
);


ALTER TABLE public.gtcschedulecycle OWNER TO postgres;

--
-- Name: TABLE gtcschedulecycle; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcschedulecycle IS 'ciclos de agendamento';


--
-- Name: gtcscheduletask; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcscheduletask (
    scheduletaskid integer NOT NULL,
    taskid integer NOT NULL,
    schedulecycleid integer NOT NULL,
    description character varying NOT NULL,
    cyclevalue character varying NOT NULL,
    enable boolean DEFAULT true,
    parameters character varying
);


ALTER TABLE public.gtcscheduletask OWNER TO postgres;

--
-- Name: TABLE gtcscheduletask; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcscheduletask IS 'agendamento de tarefas';


--
-- Name: gtcscheduletasklog; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcscheduletasklog (
    scheduletaskid integer NOT NULL,
    log text NOT NULL,
    date timestamp without time zone NOT NULL
);


ALTER TABLE public.gtcscheduletasklog OWNER TO postgres;

--
-- Name: TABLE gtcscheduletasklog; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcscheduletasklog IS 'log de tarefas realizadas';


--
-- Name: seq_searchablefieldid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_searchablefieldid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_searchablefieldid OWNER TO postgres;

--
-- Name: seq_searchablefieldid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_searchablefieldid', 18, true);


--
-- Name: gtcsearchablefield; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcsearchablefield (
    searchablefieldid integer DEFAULT nextval('seq_searchablefieldid'::regclass) NOT NULL,
    description character varying NOT NULL,
    field character varying NOT NULL,
    identifier character varying NOT NULL,
    fieldtype integer,
    isrestricted boolean,
    level integer,
    observation text,
    helps character varying
);


ALTER TABLE public.gtcsearchablefield OWNER TO postgres;

--
-- Name: TABLE gtcsearchablefield; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcsearchablefield IS 'campos pesquisaveis';


--
-- Name: COLUMN gtcsearchablefield.fieldtype; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcsearchablefield.fieldtype IS '1 - Numerico, 2 - String';


--
-- Name: gtcsearchablefieldaccess; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcsearchablefieldaccess (
    searchablefieldid integer NOT NULL,
    linkid integer NOT NULL,
    bug_dia2sql_ignorar integer
);


ALTER TABLE public.gtcsearchablefieldaccess OWNER TO postgres;

--
-- Name: TABLE gtcsearchablefieldaccess; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcsearchablefieldaccess IS 'especifica o acesso para o formato da pesquisa';


--
-- Name: seq_searchformatid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_searchformatid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_searchformatid OWNER TO postgres;

--
-- Name: seq_searchformatid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_searchformatid', 10, true);


--
-- Name: gtcsearchformat; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcsearchformat (
    searchformatid integer DEFAULT nextval('seq_searchformatid'::regclass) NOT NULL,
    description character varying NOT NULL,
    isrestricted boolean
);


ALTER TABLE public.gtcsearchformat OWNER TO postgres;

--
-- Name: TABLE gtcsearchformat; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcsearchformat IS 'formato da pesquisa';


--
-- Name: gtcsearchformataccess; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcsearchformataccess (
    searchformatid integer NOT NULL,
    linkid integer NOT NULL,
    bug_dia2sql_ignorar integer
);


ALTER TABLE public.gtcsearchformataccess OWNER TO postgres;

--
-- Name: TABLE gtcsearchformataccess; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcsearchformataccess IS 'especifica o acesso para o formato da pesquisa';


--
-- Name: gtcsearchformatcolumn; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcsearchformatcolumn (
    searchformatid integer NOT NULL,
    "column" character varying NOT NULL,
    bug_dia2sql_ignorar integer
);


ALTER TABLE public.gtcsearchformatcolumn OWNER TO postgres;

--
-- Name: TABLE gtcsearchformatcolumn; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcsearchformatcolumn IS 'especifica as colunas no search format';


--
-- Name: gtcsearchmaterialview; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcsearchmaterialview (
    controlnumber integer,
    entrancedate date,
    lastchangedate date,
    category character varying(2),
    level character varying(1),
    materialgenderid integer,
    materialtypeid integer,
    materialphysicaltypeid integer,
    exemplaryitemnumber character varying(20),
    exemplaryoriginallibraryunitid integer,
    exemplarylibraryunitid integer,
    exemplaryacquisitiontype character varying(1),
    exemplaryexemplarystatusid integer,
    exemplarymaterialgenderid integer,
    exemplarymaterialtypeid integer,
    exemplarymaterialphysicaltypeid integer,
    exemplaryentrancedate date,
    exemplarylowdate date
);


ALTER TABLE public.gtcsearchmaterialview OWNER TO postgres;

--
-- Name: gtcsearchpresentationformat; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcsearchpresentationformat (
    searchformatid integer NOT NULL,
    category character varying(2) NOT NULL,
    searchformat text NOT NULL,
    detailformat text NOT NULL
);


ALTER TABLE public.gtcsearchpresentationformat OWNER TO postgres;

--
-- Name: TABLE gtcsearchpresentationformat; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcsearchpresentationformat IS 'formato da apresentacao da pesquisa';


--
-- Name: gtcsearchtableupdatecontrol; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcsearchtableupdatecontrol (
    lastupdate timestamp without time zone
);


ALTER TABLE public.gtcsearchtableupdatecontrol OWNER TO postgres;

--
-- Name: seq_separatorid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_separatorid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_separatorid OWNER TO postgres;

--
-- Name: seq_separatorid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_separatorid', 1, true);


--
-- Name: gtcseparator; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcseparator (
    separatorid integer DEFAULT nextval('seq_separatorid'::regclass) NOT NULL,
    cataloguingformatid integer NOT NULL,
    fieldid character varying(3) NOT NULL,
    subfieldid character varying(1) NOT NULL,
    content character varying NOT NULL,
    fieldid2 character varying(3) NOT NULL,
    subfieldid2 character varying(1) NOT NULL
);


ALTER TABLE public.gtcseparator OWNER TO postgres;

--
-- Name: TABLE gtcseparator; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcseparator IS 'tabela para separadores';


--
-- Name: gtcsoapaccess; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcsoapaccess (
    soapclientid integer NOT NULL,
    webserviceid integer NOT NULL,
    bug_dia2sql_ignorar integer
);


ALTER TABLE public.gtcsoapaccess OWNER TO postgres;

--
-- Name: TABLE gtcsoapaccess; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcsoapaccess IS 'access soap';


--
-- Name: gtcsoapclient; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcsoapclient (
    soapclientid integer NOT NULL,
    clientdescription character varying,
    ip character varying NOT NULL,
    password character varying NOT NULL,
    enable boolean DEFAULT true
);


ALTER TABLE public.gtcsoapclient OWNER TO postgres;

--
-- Name: TABLE gtcsoapclient; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcsoapclient IS 'clientes soap';


--
-- Name: gtcspreadsheet; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcspreadsheet (
    category character varying(2) NOT NULL,
    level character varying(1) NOT NULL,
    field text NOT NULL,
    required text,
    repeatfieldrequired text,
    defaultvalue text,
    menuname character varying,
    menuoption character varying,
    menulevel integer
);


ALTER TABLE public.gtcspreadsheet OWNER TO postgres;

--
-- Name: TABLE gtcspreadsheet; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcspreadsheet IS 'armazenam o modelo das planilhas';


--
-- Name: COLUMN gtcspreadsheet.level; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcspreadsheet.level IS 'Nivel de catalogacao';


--
-- Name: COLUMN gtcspreadsheet.required; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcspreadsheet.required IS 'Campo obrigatorios';


--
-- Name: COLUMN gtcspreadsheet.defaultvalue; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcspreadsheet.defaultvalue IS 'Valor padrao de um campo marc';


--
-- Name: seq_supplierid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_supplierid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_supplierid OWNER TO postgres;

--
-- Name: seq_supplierid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_supplierid', 1, false);


--
-- Name: gtcsupplier; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcsupplier (
    supplierid integer DEFAULT nextval('seq_supplierid'::regclass) NOT NULL,
    name character varying,
    companyname character varying,
    date timestamp without time zone
);


ALTER TABLE public.gtcsupplier OWNER TO postgres;

--
-- Name: TABLE gtcsupplier; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcsupplier IS 'fornecedor';


--
-- Name: COLUMN gtcsupplier.supplierid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcsupplier.supplierid IS 'Identifica';


--
-- Name: gtcsuppliertypeandlocation; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcsuppliertypeandlocation (
    supplierid integer DEFAULT nextval('seq_supplierid'::regclass) NOT NULL,
    type character(1) NOT NULL,
    name character varying,
    companyname character varying,
    cnpj character varying,
    location character varying,
    neighborhood character varying,
    city character varying,
    zipcode character varying,
    phone character varying,
    fax character varying,
    alternativephone character varying,
    email character varying,
    alternativeemail character varying,
    contact character varying,
    site character varying,
    observation text,
    bankdeposit text,
    date timestamp without time zone,
    bug_dia2sql_ignorar integer,
    CONSTRAINT gtcsuppliertypeandlocation_type_check CHECK ((type = ANY (ARRAY['c'::bpchar, 'p'::bpchar, 'd'::bpchar])))
);


ALTER TABLE public.gtcsuppliertypeandlocation OWNER TO postgres;

--
-- Name: TABLE gtcsuppliertypeandlocation; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcsuppliertypeandlocation IS 'tipo de fornecedor e detalhes de localiza';


--
-- Name: COLUMN gtcsuppliertypeandlocation.supplierid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcsuppliertypeandlocation.supplierid IS 'Identifica';


--
-- Name: COLUMN gtcsuppliertypeandlocation.cnpj; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcsuppliertypeandlocation.cnpj IS 'CNPJ';


--
-- Name: COLUMN gtcsuppliertypeandlocation.location; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcsuppliertypeandlocation.location IS 'Endere';


--
-- Name: COLUMN gtcsuppliertypeandlocation.neighborhood; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcsuppliertypeandlocation.neighborhood IS 'Bairro';


--
-- Name: gtctag; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtctag (
    fieldid character varying(3) NOT NULL,
    subfieldid character varying(1) NOT NULL,
    description character varying(100) NOT NULL,
    observation text,
    isrepetitive boolean,
    hassubfield boolean,
    isactive boolean,
    indemonstration boolean,
    isobsolete boolean,
    help text
);


ALTER TABLE public.gtctag OWNER TO postgres;

--
-- Name: TABLE gtctag; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtctag IS 'etiquetas';


--
-- Name: COLUMN gtctag.fieldid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtctag.fieldid IS 'Campo marc';


--
-- Name: COLUMN gtctag.subfieldid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtctag.subfieldid IS 'Subcampo marc';


--
-- Name: gtctask; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtctask (
    taskid integer NOT NULL,
    description character varying NOT NULL,
    parameters character varying,
    enable boolean DEFAULT true,
    scriptname character varying NOT NULL
);


ALTER TABLE public.gtctask OWNER TO postgres;

--
-- Name: TABLE gtctask; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtctask IS 'tarefas';


--
-- Name: gtcwebservice; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcwebservice (
    webserviceid integer NOT NULL,
    servicedescription text,
    class character varying NOT NULL,
    method character varying NOT NULL,
    enable boolean DEFAULT true,
    needauthentication boolean DEFAULT true,
    checkclientip boolean DEFAULT true
);


ALTER TABLE public.gtcwebservice OWNER TO postgres;

--
-- Name: TABLE gtcwebservice; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcwebservice IS 'lista de servi';


--
-- Name: seq_weekdayid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_weekdayid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_weekdayid OWNER TO postgres;

--
-- Name: seq_weekdayid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_weekdayid', 1, false);


--
-- Name: gtcweekday; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcweekday (
    weekdayid integer DEFAULT nextval('seq_weekdayid'::regclass) NOT NULL,
    description character varying(40) NOT NULL
);


ALTER TABLE public.gtcweekday OWNER TO postgres;

--
-- Name: seq_gtcworkflowhistory; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_gtcworkflowhistory
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_gtcworkflowhistory OWNER TO postgres;

--
-- Name: seq_gtcworkflowhistory; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_gtcworkflowhistory', 1, false);


--
-- Name: gtcworkflowhistory; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcworkflowhistory (
    workflowhistoryid integer DEFAULT nextval('seq_gtcworkflowhistory'::regclass) NOT NULL,
    workflowinstanceid integer NOT NULL,
    workflowstatusid integer NOT NULL,
    date timestamp without time zone NOT NULL,
    operator character varying(30) NOT NULL,
    comment text
);


ALTER TABLE public.gtcworkflowhistory OWNER TO postgres;

--
-- Name: seq_gtcworkflowinstance; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_gtcworkflowinstance
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_gtcworkflowinstance OWNER TO postgres;

--
-- Name: seq_gtcworkflowinstance; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_gtcworkflowinstance', 1, false);


--
-- Name: gtcworkflowinstance; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcworkflowinstance (
    workflowinstanceid integer DEFAULT nextval('seq_gtcworkflowinstance'::regclass) NOT NULL,
    workflowstatusid integer NOT NULL,
    date timestamp without time zone NOT NULL,
    tablename character varying(255) NOT NULL,
    tableid character varying(255) NOT NULL
);


ALTER TABLE public.gtcworkflowinstance OWNER TO postgres;

--
-- Name: seq_gtcworkflowstatus; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_gtcworkflowstatus
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_gtcworkflowstatus OWNER TO postgres;

--
-- Name: seq_gtcworkflowstatus; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_gtcworkflowstatus', 1, false);


--
-- Name: gtcworkflowstatus; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcworkflowstatus (
    workflowstatusid integer DEFAULT nextval('seq_gtcworkflowstatus'::regclass) NOT NULL,
    workflowid character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    initial boolean NOT NULL,
    transaction character varying,
    CONSTRAINT chk_gtcworkflowstatus_workflowid CHECK (gtc_chk_domain('WORKFLOW'::character varying, workflowid))
);


ALTER TABLE public.gtcworkflowstatus OWNER TO postgres;

--
-- Name: COLUMN gtcworkflowstatus.transaction; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN gtcworkflowstatus.transaction IS 'Transação necessária para verificar a permissão';


--
-- Name: gtcworkflowtransition; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcworkflowtransition (
    previousworkflowstatusid integer NOT NULL,
    nextworkflowstatusid integer NOT NULL,
    name character varying(255) NOT NULL,
    function character varying(255)
);


ALTER TABLE public.gtcworkflowtransition OWNER TO postgres;

--
-- Name: seq_serverid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_serverid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_serverid OWNER TO postgres;

--
-- Name: seq_serverid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_serverid', 13, true);


--
-- Name: gtcz3950servers; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gtcz3950servers (
    serverid integer DEFAULT nextval('seq_serverid'::regclass) NOT NULL,
    description character varying(255) NOT NULL,
    host character varying(255) NOT NULL,
    recordtype character varying(100) NOT NULL,
    sintax character varying(50),
    username character varying(50),
    password character varying(32),
    country character varying(100),
    CONSTRAINT chk_gtcz3950servers_recordtype CHECK (gtc_chk_domain('Z3950_RECORD_TYPE'::character varying, recordtype))
);


ALTER TABLE public.gtcz3950servers OWNER TO postgres;

--
-- Name: TABLE gtcz3950servers; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE gtcz3950servers IS 'armazena o servidores z3950';


--
-- Name: miolo_access; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE miolo_access (
    idtransaction integer NOT NULL,
    idgroup integer NOT NULL,
    rights integer,
    validatefunction text
);


ALTER TABLE public.miolo_access OWNER TO postgres;

--
-- Name: miolo_group; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE miolo_group (
    idgroup integer NOT NULL,
    m_group character varying(50) NOT NULL,
    idmodule character varying(40)
);


ALTER TABLE public.miolo_group OWNER TO postgres;

--
-- Name: miolo_group_idgroup_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE miolo_group_idgroup_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.miolo_group_idgroup_seq OWNER TO postgres;

--
-- Name: miolo_group_idgroup_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE miolo_group_idgroup_seq OWNED BY miolo_group.idgroup;


--
-- Name: miolo_group_idgroup_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('miolo_group_idgroup_seq', 1, false);


--
-- Name: miolo_groupuser; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE miolo_groupuser (
    iduser integer NOT NULL,
    idgroup integer NOT NULL
);


ALTER TABLE public.miolo_groupuser OWNER TO postgres;

--
-- Name: miolo_log; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE miolo_log (
    idlog integer NOT NULL,
    m_timestamp timestamp without time zone NOT NULL,
    description text,
    module character varying(40) NOT NULL,
    class character varying(25),
    iduser integer NOT NULL,
    idtransaction integer,
    remoteaddr character varying(15) NOT NULL
);


ALTER TABLE public.miolo_log OWNER TO postgres;

--
-- Name: miolo_log_idlog_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE miolo_log_idlog_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.miolo_log_idlog_seq OWNER TO postgres;

--
-- Name: miolo_log_idlog_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE miolo_log_idlog_seq OWNED BY miolo_log.idlog;


--
-- Name: miolo_log_idlog_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('miolo_log_idlog_seq', 1, false);


--
-- Name: miolo_module; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE miolo_module (
    idmodule character varying(40) NOT NULL,
    name character varying(100),
    description text
);


ALTER TABLE public.miolo_module OWNER TO postgres;

--
-- Name: miolo_schedule; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE miolo_schedule (
    idschedule integer NOT NULL,
    idmodule character varying(40) NOT NULL,
    action text NOT NULL,
    parameters text,
    begintime timestamp without time zone,
    completed boolean DEFAULT false NOT NULL,
    running boolean DEFAULT false NOT NULL
);


ALTER TABLE public.miolo_schedule OWNER TO postgres;

--
-- Name: miolo_schedule_idschedule_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE miolo_schedule_idschedule_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.miolo_schedule_idschedule_seq OWNER TO postgres;

--
-- Name: miolo_schedule_idschedule_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE miolo_schedule_idschedule_seq OWNED BY miolo_schedule.idschedule;


--
-- Name: miolo_schedule_idschedule_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('miolo_schedule_idschedule_seq', 1, false);


--
-- Name: miolo_sequence; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE miolo_sequence (
    sequence character varying(30) NOT NULL,
    value integer NOT NULL
);


ALTER TABLE public.miolo_sequence OWNER TO postgres;

--
-- Name: miolo_session; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE miolo_session (
    idsession integer NOT NULL,
    iduser integer NOT NULL,
    tsin character varying(15),
    tsout character varying(15),
    name character varying(50),
    sid character varying(40),
    forced character(1),
    remoteaddr character varying(15)
);


ALTER TABLE public.miolo_session OWNER TO postgres;

--
-- Name: miolo_session_idsession_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE miolo_session_idsession_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.miolo_session_idsession_seq OWNER TO postgres;

--
-- Name: miolo_session_idsession_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE miolo_session_idsession_seq OWNED BY miolo_session.idsession;


--
-- Name: miolo_session_idsession_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('miolo_session_idsession_seq', 1, false);


--
-- Name: miolo_transaction; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE miolo_transaction (
    idtransaction integer NOT NULL,
    m_transaction character varying NOT NULL,
    idmodule character varying(40),
    nametransaction character varying(80) NOT NULL
);


ALTER TABLE public.miolo_transaction OWNER TO postgres;

--
-- Name: miolo_transaction_idtransaction_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE miolo_transaction_idtransaction_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.miolo_transaction_idtransaction_seq OWNER TO postgres;

--
-- Name: miolo_transaction_idtransaction_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE miolo_transaction_idtransaction_seq OWNED BY miolo_transaction.idtransaction;


--
-- Name: miolo_transaction_idtransaction_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('miolo_transaction_idtransaction_seq', 1, false);


--
-- Name: miolo_user; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE miolo_user (
    iduser integer NOT NULL,
    login character varying(25) NOT NULL,
    name character varying(100),
    nickname character varying(25),
    m_password character varying(40),
    confirm_hash character varying(40),
    theme character varying(20),
    idmodule character varying(40)
);


ALTER TABLE public.miolo_user OWNER TO postgres;

--
-- Name: miolo_user_iduser_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE miolo_user_iduser_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.miolo_user_iduser_seq OWNER TO postgres;

--
-- Name: miolo_user_iduser_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE miolo_user_iduser_seq OWNED BY miolo_user.iduser;


--
-- Name: miolo_user_iduser_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('miolo_user_iduser_seq', 1, false);


--
-- Name: searchmaterialview; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW searchmaterialview AS
    ((SELECT gtcmaterialcontrol.controlnumber, gtcmaterialcontrol.entrancedate, gtcmaterialcontrol.lastchangedate, gtcmaterialcontrol.category, gtcmaterialcontrol.level, gtcmaterialcontrol.materialgenderid, gtcmaterialcontrol.materialtypeid, gtcmaterialcontrol.materialphysicaltypeid, gtcexemplarycontrol.itemnumber AS exemplaryitemnumber, gtcexemplarycontrol.originallibraryunitid AS exemplaryoriginallibraryunitid, gtcexemplarycontrol.libraryunitid AS exemplarylibraryunitid, gtcexemplarycontrol.acquisitiontype AS exemplaryacquisitiontype, gtcexemplarycontrol.exemplarystatusid AS exemplaryexemplarystatusid, gtcexemplarycontrol.materialgenderid AS exemplarymaterialgenderid, gtcexemplarycontrol.materialtypeid AS exemplarymaterialtypeid, gtcexemplarycontrol.materialphysicaltypeid AS exemplarymaterialphysicaltypeid, gtcexemplarycontrol.entrancedate AS exemplaryentrancedate, gtcexemplarycontrol.lowdate AS exemplarylowdate FROM (gtcmaterialcontrol LEFT JOIN gtcexemplarycontrol USING (controlnumber)) UNION SELECT gtcmaterialcontrol.controlnumberfather AS controlnumber, gtcmaterialcontrol.entrancedate, gtcmaterialcontrol.lastchangedate, gtcmaterialcontrolfather.category, gtcmaterialcontrolfather.level, gtcmaterialcontrol.materialgenderid, gtcmaterialcontrol.materialtypeid, gtcmaterialcontrol.materialphysicaltypeid, gtcexemplarycontrol.itemnumber AS exemplaryitemnumber, gtcexemplarycontrol.originallibraryunitid AS exemplaryoriginallibraryunitid, gtcexemplarycontrol.libraryunitid AS exemplarylibraryunitid, gtcexemplarycontrol.acquisitiontype AS exemplaryacquisitiontype, gtcexemplarycontrol.exemplarystatusid AS exemplaryexemplarystatusid, gtcexemplarycontrol.materialgenderid AS exemplarymaterialgenderid, gtcexemplarycontrol.materialtypeid AS exemplarymaterialtypeid, gtcexemplarycontrol.materialphysicaltypeid AS exemplarymaterialphysicaltypeid, gtcexemplarycontrol.entrancedate AS exemplaryentrancedate, gtcexemplarycontrol.lowdate AS exemplarylowdate FROM ((gtcmaterialcontrol LEFT JOIN gtcexemplarycontrol USING (controlnumber)) JOIN gtcmaterialcontrol gtcmaterialcontrolfather ON ((gtcmaterialcontrol.controlnumberfather = gtcmaterialcontrolfather.controlnumber))) WHERE (gtcmaterialcontrol.controlnumberfather IS NOT NULL)) UNION SELECT a.controlnumberfather AS controlnumber, b.entrancedate, b.lastchangedate, b.category, b.level, b.materialgenderid, b.materialtypeid, b.materialphysicaltypeid, c.itemnumber AS exemplaryitemnumber, c.originallibraryunitid AS exemplaryoriginallibraryunitid, c.libraryunitid AS exemplarylibraryunitid, c.acquisitiontype AS exemplaryacquisitiontype, c.exemplarystatusid AS exemplaryexemplarystatusid, c.materialgenderid AS exemplarymaterialgenderid, c.materialtypeid AS exemplarymaterialtypeid, c.materialphysicaltypeid AS exemplarymaterialphysicaltypeid, c.entrancedate AS exemplaryentrancedate, c.lowdate AS exemplarylowdate FROM ((gtcmaterialcontrol a LEFT JOIN gtcmaterialcontrol b ON ((b.controlnumber = a.controlnumberfather))) LEFT JOIN gtcexemplarycontrol c ON ((a.controlnumber = c.controlnumber))) WHERE (a.controlnumberfather IS NOT NULL)) UNION SELECT gtcmaterialcontrol.controlnumber, gtcmaterialcontrol.entrancedate, gtcmaterialcontrol.lastchangedate, gtcmaterialcontrol.category, gtcmaterialcontrol.level, gtcmaterialcontrol.materialgenderid, gtcmaterialcontrol.materialtypeid, gtcmaterialcontrol.materialphysicaltypeid, gtcexemplarycontrol.itemnumber AS exemplaryitemnumber, gtcexemplarycontrol.originallibraryunitid AS exemplaryoriginallibraryunitid, gtcexemplarycontrol.libraryunitid AS exemplarylibraryunitid, gtcexemplarycontrol.acquisitiontype AS exemplaryacquisitiontype, gtcexemplarycontrol.exemplarystatusid AS exemplaryexemplarystatusid, gtcexemplarycontrol.materialgenderid AS exemplarymaterialgenderid, gtcexemplarycontrol.materialtypeid AS exemplarymaterialtypeid, gtcexemplarycontrol.materialphysicaltypeid AS exemplarymaterialphysicaltypeid, gtcexemplarycontrol.entrancedate AS exemplaryentrancedate, gtcexemplarycontrol.lowdate AS exemplarylowdate FROM (gtcmaterialcontrol JOIN gtcexemplarycontrol ON ((gtcmaterialcontrol.controlnumberfather = gtcexemplarycontrol.controlnumber)));


ALTER TABLE public.searchmaterialview OWNER TO postgres;

--
-- Name: seq_fileid; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_fileid
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seq_fileid OWNER TO postgres;

--
-- Name: seq_fileid; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_fileid', 1, false);


--
-- Name: seq_miolo_group; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_miolo_group
    START WITH 100
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 100
    CACHE 1;


ALTER TABLE public.seq_miolo_group OWNER TO postgres;

--
-- Name: seq_miolo_group; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_miolo_group', 100, false);


--
-- Name: seq_miolo_log; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_miolo_log
    START WITH 100
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 100
    CACHE 1;


ALTER TABLE public.seq_miolo_log OWNER TO postgres;

--
-- Name: seq_miolo_log; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_miolo_log', 100, false);


--
-- Name: seq_miolo_session; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_miolo_session
    START WITH 100
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 100
    CACHE 1;


ALTER TABLE public.seq_miolo_session OWNER TO postgres;

--
-- Name: seq_miolo_session; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_miolo_session', 100, false);


--
-- Name: seq_miolo_transaction; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_miolo_transaction
    START WITH 100
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 100
    CACHE 1;


ALTER TABLE public.seq_miolo_transaction OWNER TO postgres;

--
-- Name: seq_miolo_transaction; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_miolo_transaction', 100, false);


--
-- Name: seq_miolo_user; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_miolo_user
    START WITH 100
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 100
    CACHE 1;


ALTER TABLE public.seq_miolo_user OWNER TO postgres;

--
-- Name: seq_miolo_user; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('seq_miolo_user', 100, false);


--
-- Name: helpid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE gtchelp ALTER COLUMN helpid SET DEFAULT nextval('gtchelp_helpid_seq'::regclass);


--
-- Name: mylibraryid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE gtcmylibrary ALTER COLUMN mylibraryid SET DEFAULT nextval('gtcmylibrary_mylibraryid_seq'::regclass);


--
-- Name: supplierid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE gtcpurchaserequestquotation ALTER COLUMN supplierid SET DEFAULT nextval('gtcpurchaserequestquotation_supplierid_seq'::regclass);


--
-- Name: idgroup; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE miolo_group ALTER COLUMN idgroup SET DEFAULT nextval('miolo_group_idgroup_seq'::regclass);


--
-- Name: idlog; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE miolo_log ALTER COLUMN idlog SET DEFAULT nextval('miolo_log_idlog_seq'::regclass);


--
-- Name: idschedule; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE miolo_schedule ALTER COLUMN idschedule SET DEFAULT nextval('miolo_schedule_idschedule_seq'::regclass);


--
-- Name: idsession; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE miolo_session ALTER COLUMN idsession SET DEFAULT nextval('miolo_session_idsession_seq'::regclass);


--
-- Name: idtransaction; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE miolo_transaction ALTER COLUMN idtransaction SET DEFAULT nextval('miolo_transaction_idtransaction_seq'::regclass);


--
-- Name: iduser; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE miolo_user ALTER COLUMN iduser SET DEFAULT nextval('miolo_user_iduser_seq'::regclass);


--
-- Data for Name: basconfig; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY basconfig (moduleconfig, parameter, value, description, type, groupby, orderby, label) FROM stdin;
GNUTECA3	MATERIAL_TYPE_ID_PERIODIC_COLLECTION	23	Define materialTypeId para coleção de periódico	INT	\N	\N	\N
GNUTECA3	SHOW_TIPS	YES	Define na abertura do Gnuteca a exibição ou não das dicas do sistema.	VARCHAR	\N	\N	\N
GNUTECA3	MATERIAL_GENDER_CONTROL	2	Tipo de controle de material. 1 - Gênero de material para obra. 2 - Gênero do material por exemplar	INT	\N	\N	\N
GNUTECA3	MATERIAL_TYPE_CONTROL	2	Tipo de controle de material. 1 - Tipo de material para obra. 2 - Tipo do material por exemplar	INT	\N	\N	\N
GNUTECA3	MATERIAL_TYPE_FORCE_BY_MATERIAL	BA\nSA\nSE,#	Quando a configuração MATERIAL_TYPE_CONTROL for igual a 2 esta força o controle do tipo de material por obra.	VARCHAR	\N	\N	\N
GNUTECA3	MATERIAL_TYPE_FORCE_BY_EXEMPLARY	BK\nCF\nMU\nMX\nVM\nAM\nMP\nSE,12345678uz	Quando a configuração MATERIAL_TYPE_CONTROL for igual a 2 esta força o controle do tipo de material por exemplar.	VARCHAR	\N	\N	\N
GNUTECA3	USE_LOAN_DATE_FOR_RENEW	t	Utiliza a data de empréstimo definida nas políticas para a renovação. Caso não utilize o sistema irá utilizar os dias de empréstimo para a renovação.	BOOLEAN	\N	\N	\N
GNUTECA3	ISO2709_MAX_EXECUTION_TIME	15000	Seta o tempo maximo de execução na importação de arquivos ISO2709	integer	\N	\N	\N
GNUTECA3	ISO2709_MEMORY_LIMIT	256M	Seta o maximo de memoria para consumo do php.	integer	\N	\N	\N
GNUTECA3	ISO2709_MAX_POST_SIZE	16M	Seta o tamanho maximo do POST.	integer	\N	\N	\N
GNUTECA3	DAYS_BEFORE_DATE_OF_RETURN_CAN_INCREASE	2	Em uma renovação, quantos dias antes da data prevista, pode incrementar a data prevista de devolução;	INTEGER	\N	\N	\N
GNUTECA3	TABLE_RAW_DESCRIPTION_CELL_SIZE	150	Define o Tamanho celula de descrição de uma table raw	INT	\N	\N	\N
GNUTECA3	DB_TRUE	t	Caracter que o banco retorna dos campos do tipo boolean, que vem com o valor true	CHAR	\N	\N	\N
GNUTECA3	DB_FALSE	f	Caracter que o banco retorna dos campos do tipo boolean, que vem com o valor false	CHAR	\N	\N	\N
GNUTECA3	DB_NAME	gnuteca3	Nome da base de dados a ser utilizada pelo gnuteca3.	VARCHAR	\N	\N	\N
GNUTECA3	WEB_SERVICE_MATERIAL_DEFAULT_SEARCH_FORMAT_ID	1	Tipo de formato padrão a ser retornado no webservice de material (informação do material)	INT	\N	\N	\N
GNUTECA3	ID_RESERVESTATUS_REQUESTED	1	Define o código para o estado de reserva solicitada	INT	\N	\N	\N
GNUTECA3	ID_RESERVESTATUS_ANSWERED	2	Define o código para o estado de reserva atendida	INT	\N	\N	\N
GNUTECA3	ID_RESERVESTATUS_REPORTED	3	Define o código para o estado de reserva comunicada	INT	\N	\N	\N
GNUTECA3	ID_RESERVESTATUS_CONFIRMED	4	Define o código para o estado de reserva confirmada	INT	\N	\N	\N
GNUTECA3	ID_RESERVESTATUS_UNSUCCESSFUL	5	Define o código para o estado de reserva vencida	INT	\N	\N	\N
GNUTECA3	ID_RESERVESTATUS_CANCELLED	6	Define o código para o estado de reserva cancelada	INT	\N	\N	\N
GNUTECA3	ID_LOANTYPE_DEFAULT	1	Define o código para o tipo de empréstimo padrão	INT	\N	\N	\N
GNUTECA3	ID_LOANTYPE_FORCED	2	Define o código para o tipo de empréstimo forçado	INT	\N	\N	\N
GNUTECA3	ID_LOANTYPE_MOMENTARY	3	Define o código para o tipo de empréstimo momentâneo	INT	\N	\N	\N
GNUTECA3	ID_OPERATION_LOAN	1	Define o código para a operação de empréstimo	INT	\N	\N	\N
GNUTECA3	ID_OPERATION_LOAN_PENALTY	21	Define o código para a operação de empréstimo com penalidade	INT	\N	\N	\N
GNUTECA3	ID_OPERATION_LOAN_FINE	22	Define o código para a operação de empréstimo com multa	INT	\N	\N	\N
GNUTECA3	ID_OPERATION_RETURN	2	Define o código para a operação de devolução	INT	\N	\N	\N
GNUTECA3	ID_OPERATION_LOAN_BETWEEN_UNITS	3	Define o código para a operação de empréstimo entre unidades	INT	\N	\N	\N
GNUTECA3	ID_OPERATION_LOAN_BETWEEN_UNITS_CONFIRM_RECEIPT	5	Define o código para a operação de empréstimo entre unidades - Confirmação de recebimento	INT	\N	\N	\N
GNUTECA3	ID_OPERATION_RETURN_BETWEEN_UNITS	4	Define o código para a operação de devolução entre unidades	INT	\N	\N	\N
GNUTECA3	ID_OPERATION_MEET_RESERVE	14	Define o código para a operação de atender reserva	INT	\N	\N	\N
GNUTECA3	ID_OPERATION_LOCAL_RESERVE	10	Define o código para a operação de reserva local	INT	\N	\N	\N
GNUTECA3	ID_OPERATION_CANCEL_RESERVE	15	Define o código para a operação de cancelamento de reserva local	INT	\N	\N	\N
GNUTECA3	LISTING_NREGS	20	Número máximo de registros por página nas listagens	INT	ADM_INTERFACE	31	Registro por página
GNUTECA3	OPERATION_PROCESS_TIME	5	Tempo, em minutos, de limite da operação de empréstimo.	INT	LOAN	30	Tempo para bloqueio do usuário (m)
GNUTECA3	FIELD_ID_SIZE	8	Tamanho padrão para campos ID	INT	ADM_INTERFACE	6	Tamanho do campo código
GNUTECA3	FIELD_DATE_SIZE	12	Tamanho padrão para campos do tipo DATE	INT	ADM_INTERFACE	8	Tamanho do campo data
GNUTECA3	FIELD_TIME_SIZE	7	Tamanho padrão para campos TIME	INT	ADM_INTERFACE	9	Tamanho do campo hora
GNUTECA3	FIELD_MULTILINE_ROWS_SIZE	10	Quantidade de linhas padrão para um campo Multiline.	INT	ADM_INTERFACE	11	Altura do campo texto
GNUTECA3	FIELD_MNEMONIC_SIZE	5	Tamanho padrão para campos com Mnemônicos	INT	ADM_INTERFACE	12	Tamanho do campo mnemonico
GNUTECA3	FIELD_MONETARY_SIZE	16	Tamanho padrão para campos MONETARY	INT	ADM_INTERFACE	13	Tamanho do campo monetário
GNUTECA3	FIELD_DESCRIPTION_LOOKUP_SIZE	20	Tamanho padrão para campos DESCRIPTION nos lookups	INT	ADM_INTERFACE	15	Tamanho do campo descrição do lookup
GNUTECA3	REQUEST_CHANGE_STATUS_SCHEDULED_MSG	ATENÇÃO: Alguns exemplares poderão ser agendados.	Mensagem que aviso sobre agendamento no congelamento	VARCHAR	NOTIFICATION_REQUEST	50	Aviso de agendamento
GNUTECA3	RESERVE_QUEUE_DAYS	2	Define a quantidade de dias (data atual - dias definidos) no formulario de processo Reorganizar fila de reserva.	INTEGER	RESERVE	9	Dias antes para reorganizar a fila de reserva
GNUTECA3	CSV_MYLIBRARY	f	Mostrar botão Obter CSV nas grids da Minha Biblioteca	BOOLEAN	MY_LIBRARY	6	Ativar exportação para CSV e PDF
GNUTECA3	ID_OPERATION_LOAN_DELAY_LOAN	20	Define o código para a operação de empréstimo com material em atraso	INT	\N	\N	\N
GNUTECA3	FIELD_LABEL_SIZE	200px	Tamanho padrão (em pixel ou em percentual) para LABELS;\nEx:\n 180px\n18%	char	\N	5	Tamanho do rótulo
GNUTECA3	ID_OPERATION_LOCAL_RESERVE_IN_INITIAL_STATUS	11	Define o código para a operação de reserva local no estado inicial	INT	\N	\N	\N
GNUTECA3	ID_OPERATION_WEB_RESERVE	12	Define o código para a operação de reserva web	INT	\N	\N	\N
GNUTECA3	ID_OPERATION_WEB_RESERVE_IN_INITIAL_STATUS	13	Define o código para a operação de reserva web no estado inicial	INT	\N	\N	\N
GNUTECA3	ID_RENEWTYPE_LOCAL	1	Código de Renovação Local.	INT	\N	\N	\N
GNUTECA3	ID_RENEWTYPE_WEB	2	Código de Renovação Web.	INT	\N	\N	\N
GNUTECA3	ID_EXEMPLARYSTATUS_INITIAL	1	Código de estado inicial do exemplar	INT	\N	\N	\N
GNUTECA3	ID_EXEMPLARYSTATUS_PREVIOUS	2	Código de estado anterior do exemplar	INT	\N	\N	\N
GNUTECA3	ID_LOANBETWEENLIBRARYSTATUS_REQUESTED	1	Código do estado de emprestimo entre unidades - SOLICITADO	INT	\N	\N	\N
GNUTECA3	ID_LOANBETWEENLIBRARYSTATUS_CANCELED	2	Código do estado de emprestimo entre unidades - CANCELADO	INT	\N	\N	\N
GNUTECA3	ID_LOANBETWEENLIBRARYSTATUS_APPROVED	3	Código do estado de emprestimo entre unidades - APPROVED	INT	\N	\N	\N
GNUTECA3	ID_LOANBETWEENLIBRARYSTATUS_DISAPPROVED	4	Código do estado de emprestimo entre unidades - REPROVADO	INT	\N	\N	\N
GNUTECA3	ID_LOANBETWEENLIBRARYSTATUS_CONFIRMED	5	Código do estado de emprestimo entre unidades - CONFIRMADO	INT	\N	\N	\N
GNUTECA3	ID_LOANBETWEENLIBRARYSTATUS_DEVOLUTION	6	Código do estado de emprestimo entre unidades - DEVOLUCAO	INT	\N	\N	\N
GNUTECA3	ID_LOANBETWEENLIBRARYSTATUS_FINALIZED	7	Código do estado de emprestimo entre unidades - FINALIZADO	INT	\N	\N	\N
GNUTECA3	MARC_CONTROL_NUMBER_TAG	001.a	Definição do campo Marc para o número de controle	VARCHAR	\N	\N	\N
GNUTECA3	MARC_FIXED_DATA_TAG	008.a	Definição do campo Marc para os campos fixos	VARCHAR	\N	\N	\N
GNUTECA3	MARC_FIXED_DATA_FIELD	008	Definição do campo Marc para os campos fixos	VARCHAR	\N	\N	\N
GNUTECA3	MARC_LEADER_TAG	000.a	Definição do campo Marc para o leader	VARCHAR	\N	\N	\N
GNUTECA3	MARC_MATERIAL_TYPE_TAG	901.a	Definição do campo Marc para o tipo do material	VARCHAR	\N	\N	\N
GNUTECA3	MARC_MATERIAL_PHYSICAL_TYPE_TAG	901.c	Definição do campo Marc para o tipo do material	VARCHAR	\N	\N	\N
GNUTECA3	MARC_MATERIAL_GENDER_TAG	902.a	Definição do campo Marc para o gênero do material	VARCHAR	\N	\N	\N
GNUTECA3	MARC_TITLE_TAG	245.a	Definição do campo Marc para o título.	VARCHAR	\N	\N	\N
GNUTECA3	MARC_SECUNDARY_TITLE_TAG	440.a	Definição do campo Marc para o título.	VARCHAR	\N	\N	\N
GNUTECA3	MARC_AUTHOR_TAG	100.a	Definição do campo Marc para o autor.	VARCHAR	\N	\N	\N
GNUTECA3	MARC_CLASSIFICATION_TAG	090.a,080.a	Definição do campo Marc para a classificação.	VARCHAR	\N	\N	\N
GNUTECA3	MARC_CUTTER_TAG	090.b	Definição do campo Marc para o cutter.	VARCHAR	\N	\N	\N
GNUTECA3	MARC_WORK_NUMBER_TAG	950.a	Definição do campo Marc para o número da obra.	VARCHAR	\N	\N	\N
GNUTECA3	MARC_SPACE	#	Definicao do MARC para caracteres vazios	VARCHAR	\N	\N	\N
GNUTECA3	MARC_SUPPLIER_TAG	947.a	Definicao do campo MARC marc para fornecedor	VARCHAR	\N	\N	\N
GNUTECA3	MARC_ANALITIC_ENTRACE_TAG	773.w	Definicao do campo MARC marc para fornecedor	VARCHAR	\N	\N	\N
GNUTECA3	MARC_PERIODIC_INFORMATIONS	362.a	Definicao do campo MARC marc para informações de volume, etc	VARCHAR	\N	\N	\N
GNUTECA3	KARDEX_PERIOD	310.a	Definicao do campo MARC marc para informações de volume, etc	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EDITION_TAG	250.a	Definicao do campo MARC marc para informações de edição	VARCHAR	\N	\N	\N
GNUTECA3	MARC_PUBLICATION_DATE_TAG	260.c	Definicao do campo MARC marc para informações de edição	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_FIELD	949	Definição do campo Marc para os exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_ITEM_NUMBER_TAG	949.a	Definição do campo Marc para numero de tombo dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_LIBRARY_UNIT_ID_TAG	949.b	Definição do campo Marc para a unidade dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_ORIGINAL_LIBRARY_UNIT_ID_TAG	949.9	Definição do campo Marc para a unidade original dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_ACQUISITION_TYPE_TAG	949.c	Definição do campo Marc para o tipo de aquisição dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_MATERIAL_GENDER_TAG	949.d	Definição do campo Marc para o gênero do Material dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_MATERIAL_TYPE_TAG	949.1	Definição do campo Marc para o gênero do Material dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_MATERIAL_PHYSICAL_TYPE_TAG	949.3	Definição do campo Marc para o gênero do Material dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_EXEMPLARY_TAG	949.e	Definição do campo Marc para o exemplar dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_EXEMPLARY_STATUS_TAG	949.g	Definição do campo Marc para o estado dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_EXEMPLARY_STATUS_FUTURE_TAG	949.i	Definição do campo Marc para o estado dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_PATRIMONY_TAG	949.n	Definição do campo Marc para o patrimonio dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_VOLUME_TAG	949.v	Definição do campo Marc para o volume dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_OBSERVATION_TAG	949.w	Definição do campo Marc para a observação dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_EXEMPLARY_ID_TAG	949.x	Definição do campo Marc para o número dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_ENTRACE_DATE_TAG	949.y	Definição do campo Marc para a data de entrada dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_LOW_DATE_TAG	949.z	Definição do campo Marc para a data de baixa dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_TOMO_TAG	949.t	Definição do campo Marc para a tomo dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_COST_CENTER_TAG	949.q	Definição do campo Marc para o centro de custo dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_ITEM_NUMBER_SUBFIELD	a	Definição do subcampo Marc para numero de tombo dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_LIBRARY_UNIT_ID_SUBFIELD	b	Definição do subcampo Marc para unidade dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_ORIGINAL_LIBRARY_UNIT_ID_SUBFIELD	9	Definição do subcampo Marc para unidade original dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_ACQUISITION_TYPE_SUBFIELD	c	Definição do subcampo Marc para tipo de aquisição dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_MATERIAL_GENDER_SUBFIELD	d	Definição do subcampo Marc para gênero do material dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_NAME_SERVER	856.u	Definicao do campo MARC marc para nome do servidor (endereço da página Web)	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_MATERIAL_TYPE_SUBFIELD	1	Definição do subcampo Marc para gênero do material dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_MATERIAL_PHYSICAL_TYPE_SUBFIELD	3	Definição do subcampo Marc para gênero do material dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_EXEMPLARY_SUBFIELD	e	Definição do subcampo Marc para o exemplar dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_EXEMPLARY_STATUS_SUBFIELD	g	Definição do subcampo Marc para o status dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_EXEMPLARY_STATUS_FUTURE_SUBFIELD	i	Definição do subcampo Marc para o status futuro dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_PATRIMONY_SUBFIELD	n	Definição do subcampo Marc para o patrimonio dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_VOLUME_SUBFIELD	v	Definição do subcampo Marc para o volume dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_OBSERVATION_SUBFIELD	w	Definição do subcampo Marc para a observação dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_EXEMPLARY_ID_SUBFIELD	x	Definição do subcampo Marc para o número dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_ENTRACE_DATE_SUBFIELD	y	Definição do subcampo Marc para a data de entrada dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_LOW_DATE_SUBFIELD	z	Definição do subcampo Marc para a data de baixa dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_EXEMPLARY_TOMO_SUBFIELD	t	Definição do subcampo Marc para a tomo dos exemplares	VARCHAR	\N	\N	\N
GNUTECA3	MARC_KARDEX_FIELD	960	Definição do campo Marc para o kardex	VARCHAR	\N	\N	\N
GNUTECA3	MARC_KARDEX_SUBSCRIBER_ID_TAG	960.a	Definição do campo Marc para codigo do assinante	VARCHAR	\N	\N	\N
GNUTECA3	MARC_KARDEX_LIBRARY_UNIT_ID_TAG	960.b	Definição do campo Marc para codigo da unidade	VARCHAR	\N	\N	\N
GNUTECA3	MARC_KARDEX_ACQUISITION_TYPE_TAG	960.c	Definição do campo Marc para tipo de aquisição	VARCHAR	\N	\N	\N
GNUTECA3	MARC_KARDEX_SIGNATURE_END_TAG	960.d	Definição do campo Marc para vencimento da assinatura	VARCHAR	\N	\N	\N
GNUTECA3	MARC_KARDEX_SIGNATURE_DATE_TAG	960.h	Definição do campo Marc para data da assinatura	VARCHAR	\N	\N	\N
GNUTECA3	MARC_KARDEX_ENTRACE_DATE_TAG	960.y	Definição do campo Marc para data da entrada	VARCHAR	\N	\N	\N
GNUTECA3	MARC_KARDEX_PUBLICATION_TAG	960.j	Definição do campo Marc para publicação	VARCHAR	\N	\N	\N
GNUTECA3	MARC_KARDEX_SUBSCRIBER_ID_SUBFIELD	a	Definição do subcampo Marc para codigo do assinante	VARCHAR	\N	\N	\N
GNUTECA3	MARC_KARDEX_LIBRARY_UNIT_ID_SUBFIELD	b	Definição do subcampo Marc para codigo da unidade	VARCHAR	\N	\N	\N
GNUTECA3	MARC_KARDEX_ACQUISITION_TYPE_SUBFIELD	c	Definição do subcampo Marc para tipo de aquisição	VARCHAR	\N	\N	\N
GNUTECA3	MARC_KARDEX_SIGNATURE_END_SUBFIELD	d	Definição do subcampo Marc para vencimento da assinatura	VARCHAR	\N	\N	\N
GNUTECA3	MARC_KARDEX_FISCAL_NOTE_SUBFIELD	f	Definição do subcampo Marc para nota fiscal	VARCHAR	\N	\N	\N
GNUTECA3	MARC_KARDEX_SIGNATURE_DATE_SUBFIELD	h	Definição do subcampo Marc para data da assinatura	VARCHAR	\N	\N	\N
GNUTECA3	MARC_KARDEX_ENTRACE_DATE_SUBFIELD	y	Definição do subcampo Marc para data da entrada	VARCHAR	\N	\N	\N
GNUTECA3	DEFAULT_EXEMPLARY_STATUS_DISPONIVEL	1	Determina o id do status Disponivel do exemplar	INTEGER	\N	\N	\N
GNUTECA3	DEFAULT_EXEMPLARY_STATUS_PROCESSANDO	15	Determina o id do status em Processamento do exemplar 	INTEGER	\N	\N	\N
GNUTECA3	FORM_CONTENT_TYPE_ADMINISTRATOR	1	Valor padrao de formularios do tipo Administrador	BOOLEAN	\N	\N	\N
GNUTECA3	FORM_CONTENT_TYPE_OPERATOR	2	Valor padrao de formularios do tipo Operator	BOOLEAN	\N	\N	\N
GNUTECA3	FORM_CONTENT_TYPE_SEARCH	3	Valor padrao de formularios do tipo Busca	BOOLEAN	\N	\N	\N
GNUTECA3	FORM_CONTENT_SEARCH_ADVANCED_ID	2	Codigo do valor padrão de formularios para busca Avançada	INTEGER	\N	\N	\N
GNUTECA3	FORM_CONTENT_SEARCH_ACQUISITION_ID	1	Codigo do valor padrão de formularios para busca Aquisição	INTEGER	\N	\N	\N
GNUTECA3	DEFAULT_VALUE_PRIVILEGEGROUP_LOAN	1	Valor padrao do grupo de privilégio para empréstimo	INT	\N	\N	\N
GNUTECA3	ID_FINESTATUS_OPEN	1	Codigo do estado da multa em aberto	INT	\N	\N	\N
GNUTECA3	MASK_DATE_DB	yyyy-mm-dd	Define a mascara da data para o banco.\n\ndd   = Dia\nmm   = Mês\nyyyy = Ano	VARCHAR	\N	\N	\N
GNUTECA3	MASK_TIME_DB	hh:ii:ss	Define a mascara da hora para o banco.\n\nhh = Hora\nii = Minuto\nss = Segundo	VARCHAR	\N	\N	\N
GNUTECA3	MASK_DATE_USER	dd/mm/yyyy	Define a mascara da data para o usuário.\n\ndd   = Dia\nmm   = Mês\nyyyy = Ano	VARCHAR	\N	\N	\N
GNUTECA3	LABEL_CONGELADO	<CENTER><B>Lista de materiais congelados pelos professores</CENTER></B><BR>	Mensagem a ser mostrada no topo da tela dos congelados da Minha Biblioteca	VARCHAR	MY_LIBRARY	33	Mensagem para os congelados
GNUTECA3	LABEL_MY_RESERVES	<CENTER><B>Lista reservas em aberto do usuário.</CENTER></B><BR>	Mensagem a ser mostrada no topo da tela das Minhas reservas da Minha Biblioteca	VARCHAR	MY_LIBRARY	34	Mensagem para as reservas
GNUTECA3	LABEL_RENEW	<CENTER><B>Por aqui usuário pode renovar seus empréstimos.</CENTER></B><BR>	Mensagem na tela Renovar da Minha biblioteca	VARCHAR	MY_LIBRARY	36	Mensagem para renovação
GNUTECA3	CHARGE_FINE_IN_THE_HOLIDAY	f	Cobrar multas em feriados	BOOLEAN	FINE	5	Cobrar multa em feriados
GNUTECA3	CHANGE_FINE_WHEN_THE_LIBRARY_UNIT_IS_CLOSED	f	Cobrar multa quando a biblioteca está fechada	BOOLEAN	FINE	6	Cobrar multa quando a biblioteca está fechada
GNUTECA3	FORM_CONTENT	t	Ativa ou desativa o valor padrão de formularios.	BOOLEAN	ADM_INTERFACE	30	Ativar definição de valor padrão
GNUTECA3	DEFAULT_EXEMPLARY_STATUS_EMPRESTADO	2	Determina o id do status Emprestado do exemplar	INTEGER	\N	\N	\N
GNUTECA3	DEFAULT_EXEMPLARY_STATUS_RESERVADO	3	Determina o id do status Reservado do exemplar 	INTEGER	\N	\N	\N
GNUTECA3	DEFAULT_EXEMPLARY_STATUS_DESAPARECIDO	4	Determina o id do status Desaparecido do exemplar	INTEGER	\N	\N	\N
GNUTECA3	DEFAULT_EXEMPLARY_STATUS_DANIFICADO	5	Determina o id do status Danificado do exemplar	INTEGER	\N	\N	\N
GNUTECA3	DEFAULT_EXEMPLARY_STATUS_CONGELADO	7	Determina o id do status Congelado do exemplar 	INTEGER	\N	\N	\N
GNUTECA3	DEFAULT_EXEMPLARY_STATUS_DESCARTADO	8	Determina o id do status Emprestado do exemplar	INTEGER	\N	\N	\N
GNUTECA3	MASK_TIME_USER	hh:ii:ss	Define a mascara da hora para o usuário.\n\nhh = Hora\nii = Minuto\nss = Segundo	VARCHAR	\N	\N	\N
GNUTECA3	LIMIT_DAYS_BEFORE_EXPIRED	4	Limita o maior valor que o usuário poderá utilizar para o parâmetro USER_DAYS_BEFORE_EXPIRED.	INT	\N	\N	\N
GNUTECA3	ID_RESERVETYPE_LOCAL_ANSWERED	3	Código do tipo de reserva local atendida	INT	\N	\N	\N
GNUTECA3	ID_RESERVETYPE_LOCAL	1	Código do tipo de reserva local	INT	\N	\N	\N
GNUTECA3	ID_RESERVETYPE_WEB	2	Código do tipo de reserva web	INT	\N	\N	\N
GNUTECA3	ID_RESERVETYPE_WEB_ANSWERED	4	Código do tipo de reserva web atendida	INT	\N	\N	\N
GNUTECA3	ID_RESERVETYPE_LOCAL_INITIAL_STATUS	5	Código do tipo de reserva local em estado inicial	INT	\N	\N	\N
GNUTECA3	CATALOGUE_DATE_FIELDS	960.d,960.h,960.i,960.y,008.0-SE,949.y,949.z	define os campos que são data	VARCHAR	\N	\N	\N
GNUTECA3	CATALOGUE_ARRAY_FIELDS	949.q	define os campos que são arrayField	VARCHAR	\N	\N	\N
GNUTECA3	CATALOGUE_ORIGINAL_IMAGE_DIMENSIONS	800x600	Dimensos maximas da imagem original. Caso alguma imagem ultrpasse estas dimensoes, a imagem sera redimensionada	VARCHAR	\N	\N	\N
GNUTECA3	EMAIL_CONTENT_TYPE	html	Define a linguagem do conteudo.	CHAR	ADM_EMAIL	16	Tipo do conteúdo
GNUTECA3	CATALOGUE_MIDDLE_IMAGE_DIMENSIONS	400x300	Dimensos maximas da imagem média. Caso alguma imagem ultrpasse estas dimensoes, a imagem sera redimensionada	VARCHAR	\N	\N	\N
GNUTECA3	CATALOGUE_SMALL_IMAGE_DIMENSIONS	200x150	Dimensos maximas da imagem pequena. Caso alguma imagem ultrpasse estas dimensoes, a imagem sera redimensionada	VARCHAR	\N	\N	\N
GNUTECA3	CATALOGUE_FILTER_OPERATOR	TRUE	Constante que define se deve filtrar operadores dentro da catalogação 	BOOLEAN	\N	\N	\N
GNUTECA3	SPREADSHEET_CATEGORY_COLECTION	SE-#	define a plinilha de coleção	VARCHAR	\N	\N	\N
GNUTECA3	SPREADSHEET_CATEGORY_FASCICLE	SE-4	define a plinilha de coleção	VARCHAR	\N	\N	\N
GNUTECA3	SIMPLE_SEARCH_HIDE_EXEMPLAR	t	Determina se é ou não para esconder/recolher os dados do exemplar na busca simples.	BOOLEAN	\N	\N	\N
GNUTECA3	MATERIAL_MOVIMENT_SEARCH_FORMAT_ID	3	Define o id do formato de pesquisa (search format) que será utilizado como padrão para a Circulação de Material.	INTEGER	\N	\N	\N
GNUTECA3	SIMPLE_SEARCH_EXEMPLAR_DETAIL_FIELD_LIST_OPERATOR	Volume=949.v, Tomo=949.t, Unidade de biblioteca=949.b, Tipo de material=949.1	Relaciona a lista de campos marc que devem aparecer na listagem de exemplares dos detalhes da pesquisa. Para o operador.	VARCHAR	\N	\N	\N
GNUTECA3	SIMPLE_SEARCH_EXEMPLAR_DETAIL_FIELD_LIST_USER	Unidade de bilioteca=949.b, Tipo de material=949.d	Relaciona a lista de campos marc que devem aparecer na listagem de exemplares dos detalhes da pesquisa. Para usuário normal.	VARCHAR	\N	\N	\N
GNUTECA3	SIMPLE_SEARCH_RESERVE_DETAIL_FIELD_LIST	Unidade de bilioteca=949.b	Relaciona a lista de campos marc que devem aparecer na listagem de exemplares na reserva da pesquisa.	VARCHAR	\N	\N	\N
GNUTECA3	USER_SEND_DELAYED_LOAN	f	Define se é para enviar avisos de materiais em atraso por e-mail.	BOOLEAN	NOTIFICATION_LOAN	20	Ativar aviso de empréstimos atrasados
GNUTECA3	SIMPLE_SEARCH_ALL_LIBRARYS_PERSON	f	Define se é permitido a pessoa (usuário) pesquisar em todas unidades na pesquisa simples.	BOOLEAN	SEARCH	7	Ativar busca em todas as biblioteca (usuário)
GNUTECA3	_ID	2	Define o id do formato de pesquisa (search format) que será utilizado como padrão para a pesquisa.	INT	SEARCH	12	Formato para exibição do material
GNUTECA3	INTERCHANGE_SEARCH_FORMAT_ID	5	Define o SearchFormatId para o intercâmbio.	INTEGER	INTERCHANGE	6	Formato para exibição do material
GNUTECA3	SIMPLE_SEARCH_SEARCH_FORMAT_ID_DETAIL_ARTICLE	1	Define o id do formato de pesquisa (search format) que será utilizado nos detalhes do artigo.	INTEGER	SEARCH	10	Formato para exibição dos detalhes do artigo
GNUTECA3	SIMPLE_SEARCH_LOGIN_STRING	Por favor faça seu login abaixo:	Texto que aparece na tela de login do formulário da busca Simples.	CHAR	SEARCH	25	Mensagem do formulário de login
GNUTECA3	SIMPLE_SEARCH_ALL_LIBRARYS_OPERATOR	t	Define se permite ou não pesquisar em todas as bibliotecas para o operador do sistema.	BOOLEAN	SEARCH	6	Ativar busca em todas as biblioteca (operador)
GNUTECA3	FAVORITES_SEARCH_FORMAT_ID	4	Define o SearchFormatId usado no formulário de listagem de favoritos.	INTEGER	MY_LIBRARY	5	Formato para exibição do material nos favoritos
GNUTECA3	ADMINISTRATION_SEARCH_FORMAT_ID	5	Define o SearchFormatId para Administração em geral.	INT	ADMIN	5	Formato para exibição do material
GNUTECA3	MSG_INITIAL_STATUS	O(s) exemplar(es) está(ão) no estado inicial. Realmente deseja fazer a reserva?	Ao tentar reservar material que está no estado inicial, mostra este aviso	VARCHAR	RESERVE	30	Mensagem para material disponível
GNUTECA3	USER_SEND_DAYS_BEFORE_EXPIRED	t	Define se é para enviar avisos por e-mail antes de vencer os materiais.	BOOLEAN	NOTIFICATION_LOAN	10	Ativar aviso de devolução
GNUTECA3	USER_NOTIFY_AQUISITION	15	Valor padrão que indica o intervalo para notificações das novas aquisições	CHAR	NOTIFICATION_AQUISITION	34	Intervalo para notificação (d)
GNUTECA3	CATALOGUE_MULTILINE_FIELDS	949.w,960.w,500.a,502.a,504.a,505.a	define os campos que são texto	CHAR	CATALOG	5	Ativa modo texto para os campos
GNUTECA3	CATALOGUE_LOOKUP_FIELDS	947.a=SupplierType:DescON\n090.b=Cutter:DescOFF\n090.a=Classification:DescOFF\n949.q=CostCenter:DescOFF\n960.q=CostCenter:DescOFF	define os campos que são lookup	VARCHAR	\N	\N	\N
GNUTECA3	USER_SEND_NOTIFY_AQUISITION	f	Define se é para enviar notificações de novos materiais por e-mail.	BOOLEAN	NOTIFICATION_AQUISITION	30	Ativar
GNUTECA3	SIMPLE_SEARCH_SEARCH_FORMAT_ID_DETAIL_FASCICLE	7	Define o id do formato de pesquisa (search format) que será utilizado nos detalhes do fasciculo.	INT	SEARCH	11	Formato para exibição dos detalhes do fascículo
GNUTECA3	HELP_MAIN_MYLIBRARY_MYFINE	<CENTER><B>Aqui o usuário pode visualizar todas as multas por atraso na devolução de materiais.</CENTER></B>\nSempre que uma multa estiver no estado Aberta, significa que o usuário está impedido de retirar e/ou renovar materiais na biblioteca.\nÉ possível filtrar os resultados, para isto é só preencher algum dos campos e clicar em Pesquisar.\n\n<img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(loan-16x16.png)" align="top" /> Mostra informações sobre o empréstimo do material.\n<img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(renew-16x16.png)" align="top" /> Mostra informações sobre as renovações do material.	Conteúdo de ajuda que será exibido quando usuário clicar no botão Ajuda/Help do menu da pesquisa. Repare que todo form pode ter sua configuração de Help criando a preferência do sistema HELP_ + o action do handler.	VARCHAR	\N	\N	\N
GNUTECA3	EMAIL_LOANBETWEENLIBRARY_SUBJECT	Empréstimo entre unidades - $STATUS	Assunto do e-mail enviado para as bibliotecas sobre empréstimo entre unidades	CHAR	LOAN_LIBRARY	10	Assunto dos e-mails
GNUTECA3	EMAIL_RETURN_SUBJECT	Prazo de empréstimo	Define o sufixo no assunto do e-mail que será enviado ao usuário para avisá-lo da devolução do material emprestado. Complementa o parâmetro EMAIL_SUBJECT_PREFIX.	CHAR	NOTIFICATION_LOAN	16	Assunto do e-mail da devolução
GNUTECA3	SET_FIRST_OPTION_OF_THE_INDICATOR_AS_DEFAULT	t	Seta a primeira opção dos indicadores como valores padrão caso o mesmo valor não exista.	BOOLEAN	\N	\N	\N
GNUTECA3	HELP_MAIN_SEARCH_SIMPLESEARCH_3	<B><CENTER>Busca os materiais cadastrados num determinado período.</B></CENTER>\nDeve-se utilizar os campos data do filtro para especificar o período de busca. Pode-se deixar alguns dos campos em branco.	Conteúdo de ajuda que será exibida quando usuário clicar no botão Ajuda/Help do menu da pesquisa. Repare que todo form pode ter sua configuração de Help criando a preferência do sistema HELP_ + o action do handler.	VARCHAR	\N	\N	\N
GNUTECA3	SIMPLE_SEARCH_EXCLUDE_SPREEDSHET	SE,4	Relaciona as planilhas a serem excluídas na pesquisa simples, separe por linha nova para mais de um item: Ex.: SE,4	VARCHAR	SEARCH	15	Ignorar planilhas na busca
GNUTECA3	REQUEST_CHANGE_DAYS	10	Número de dias antes e após o final do período, onde será liberado a renovação	VARCHAR	NOTIFICATION_REQUEST	49	Período para renovar
GNUTECA3	SIMPLE_SEARCH_SEARCH_FORMAT_ID	1	Define o id do formato de pesquisa (search format) que será utilizado como padrão para a pesquisa.	INT	SEARCH	9	Formato para exibição do material na pesquisa
GNUTECA3	SIMPLE_SEARCH_SEARCH_FORMAT_STRING	Formato de pesquisa	Texto que aparece no formulário de pesquisa, acima da escolha de formatos de pesquisa	CHAR	SEARCH	14	Rótulo para o formato da pesquisa
GNUTECA3	HELP_MAIN_MYLIBRARY_CONGELADO	Aqui o usuário pode visualizar os materiais congelados. São materiais que não podem ser retirados, pois ficam a disposição para consulta local. \nÉ possível visualizar todos os materiais congelados e o período que os mesmos ficarão neste estado. Pelo campo Requisição pode-se restringir a busca pelo código do usuário que congelou o material.\n<ul><li><img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(cancel-16x16.png)" align="top" /> Somente a pessoa que requisitou o congelamento pode cancelar.\n<li><b>Biblioteca:</b> mostra em que unidade está o material.\n<li><b>Pessoa:</b> nome do usuário que congelou o material.\n<li><b>Data e Data final:</b> período em que o material ficará congelado.\n<li><b>Composição:</b> exemplar no estado Verdadeiro é quando a biblioteca aprovou o congelamento. E Aplicado é quando o material já está congelado, a disposição dos usuários para consulta.\n<li><b>Última coluna:</b> é para renovar o congelamento. Esta operação só é liberada em determinados períodos.\n</ul>	Conteúdo de ajuda que será exibido quando usuário clicar no botão Ajuda/Help do menu da pesquisa. Repare que todo form pode ter sua configuração de Help criando a preferência do sistema HELP_ + o action do handler.	VARCHAR	\N	\N	\N
GNUTECA3	SIMPLE_SEARCH_EXCLUDE_EXEMPLARY_STATUS	0,4,5	Id do estado de exemplares a ignorar na pesquisa.	CHAR	SEARCH	16	Ignorar exemplar nos estados
GNUTECA3	HELP_MAIN_MYLIBRARY_FAVORITE	<CENTER><B>Aqui estão armazenados todos os materiais que o usuário adicionou aos favoritos.</CENTER></B>\n<UL><LI>É possível pesquisar por período de inclusão. Para isto, é só selecionar a data inicial e final ou somente um dos campos data\n<LI><img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(table-delete.png)" align="top" /> Exclui o material da lista de favoritos.\n<LI><img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(config-16x16.png)" align="top" /> Mostra mais informações sobre o material.\n</UL>\n<B>Obs.</B>: Para adicionar material na lista de favoritos, deve-se ir em Pesquisa, selecionar o material e clicar no botão Favoritos <img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(favorites-16x16.png)" align="top" />. Caso, não esteja logado, é necessário digitar código de usuário e senha.	Conteúdo de ajuda que será exibido quando usuário clicar no botão Ajuda/Help do menu da pesquisa. Repare que todo form pode ter sua configuração de Help criando a preferência do sistema HELP_ + o action do handler.	VARCHAR	\N	\N	\N
GNUTECA3	EMAIL_CANCEL_RESERVE_COMUNICA_SOLICITANTE_CONTENT	Prezado(a) $USER_NAME! $LN\nSeu reserva intitulado "$MATERIAL_TITLE" ($ITEM_NUMBER) foi cancelada.$LN\nAtenciosamente,$LN\nbiblioteca de $LIBRARY_UNIT_DESCRIPTION	Define o conteúdo do e-mail que será enviado para o usuário com a data prevista para devolução do empréstimo.\nVariáveis aceitas:\n$USER_NAME - Nome do usuário\n$MATERIAL_TITLE - Descrição do material\n$ITEM_NUMBER - registro do material\n$LIBRARY_UNIT_DESCRIPTION - Library unit description	VARCHAR	RESERVE	16	Conteúdo do e-mail de reserva cancelada
GNUTECA3	HELP_MAIN_MYLIBRARY_MYRENEW	Aqui o usuário pode renovar os materiais que retirou na biblioteca. Não é possível renovar itens que estão atrasados, que tenham reserva, quando já tenha esgotado o limite de renovações e também quando a pessoa possuir alguma multa e/ou penalidade em aberto.\n<ol>\n<li>Selecionar os materiais que deseja renovar. O botão no título da 1ª coluna, marca todos os itens;\n<li>Clicar no botão Renovar;<BR> <B>Obs.</B>: Caso não mostre a caixa de seleção, verificar a última coluna (Mensagem) o motivo.\n<ol>	Conteúdo de ajuda que será exibido quando usuário clicar no botão Ajuda/Help do menu da pesquisa. Repare que todo form pode ter sua configuração de Help criando a preferência do sistema HELP_ + o action do handler.	VARCHAR	\N	\N	\N
GNUTECA3	RELATIONSHIP_OF_FIELDS_WITH_TABLES_FOR_SELECTS	MARC_EXEMPLARY_ORIGINAL_LIBRARY_UNIT_ID_TAG,MARC_KARDEX_LIBRARY_UNIT_ID_TAG,MARC_EXEMPLARY_LIBRARY_UNIT_ID_TAG=LibraryUnit;\nMARC_EXEMPLARY_MATERIAL_GENDER_TAG,MARC_MATERIAL_GENDER_TAG=MaterialGender;\nMARC_MATERIAL_TYPE_TAG,MARC_EXEMPLARY_MATERIAL_TYPE_TAG=MaterialType;\nMARC_EXEMPLARY_EXEMPLARY_STATUS_TAG,MARC_EXEMPLARY_EXEMPLARY_STATUS_FUTURE_TAG=ExemplaryStatus;\nMARC_MATERIAL_PHYSICAL_TYPE_TAG,MARC_EXEMPLARY_MATERIAL_PHYSICAL_TYPE_TAG=MaterialPhysicalType;\nMARC_EXEMPLARY_COST_CENTER_TAG=CostCenter;\n	Relaciona campos da catalogação com business. Não altere o conteúdo desta constante!	VARCHAR	\N	\N	\N
GNUTECA3	INTERCHANGE_TYPE_SEND	1	Código do tipo de permuta para envio.	INTEGER	\N	\N	\N
GNUTECA3	INTERCHANGE_TYPE_RECEIPT	2	Código do tipo de permuta para recebimento.	INTEGER	\N	\N	\N
GNUTECA3	INTERCHANGE_STATUS_CREATED	1	Código do estado de permuta CRIADO.	INTEGER	\N	\N	\N
GNUTECA3	HELP_MAIN_MYLIBRARY_MYRESERVES	<center><B>Aqui o usuário pode verificar a situação de suas reservas.</B></center>\nAs reservas podem ser feitas pelo site da biblioteca em Pesquisa online ou pelo terminais de pesquisa na própria biblioteca e também no balcão de empréstimos com os atendentes.\n<ul>\n<li><img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(cancel-16x16.png)" align="top" /> Cancela a reserva.\n<li><img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(favorites-16x16.png)" align="top" /> Adiciona o material aos favoritos.\n<li><img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(config-16x16.png)" align="top" /> Mostra mais informações sobre o material.\n<li><b>Data limite:</b> data máxima para o usuário retirar sua reserva.\n<li><b>Estado:</b> estados da reserva\n<ul><li><b>Solicitada:</b> usuário fez a reserva, mas ainda não chegou;\n<li><b>Atendida:</b> reserva está disponível para usuário retirá-la;\n<li><b>Comunicada:</b> usuário foi avisado que pode retirar sua reserva.</ul><li><b>Posição:</b> posição que o usuário está na lista de reserva.\n<li><b>Data prevista da devolução:</b> quando o material ainda está emprestado, é mostrado a previsão de retorno.\n</ul>	Conteúdo de ajuda que será exibido quando usuário clicar no botão Ajuda/Help do menu da pesquisa. Repare que todo form pode ter sua configuração de Help criando a preferência do sistema HELP_ + o action do handler.	VARCHAR	\N	\N	\N
GNUTECA3	HASH_KEY	xyzw095fgh	Define uma chave para criação do hash de recibos.	VARCHAR	\N	\N	\N
GNUTECA3	PRINT_SERVER_HOST	localhost	Endereço IP do servidor de impressão a ser utilizado	VARCHAR	\N	\N	\N
GNUTECA3	MARK_SEND_RETURN_MAIL_RECEIPT	f	Define se a opção de enviar recibo de devolucao sai marcada.	BOOLEAN	RETURN	6	Selecionar a opção enviar recibo
GNUTECA3	RECEIPT_COPIES_AMOUNT	1	Define s quatidade de cópias que será impressa dos recibos de empréstimo e devolução	INTEGER	LOAN	17	Quantidade de cópias do recibo
GNUTECA3	MARK_PRINT_RECEIPT_RETURN	t	Define se a opção de imprimir recibo de devolução sai marcada.	BOOLEAN	RETURN	5	Selecionar a opção imprimir recibo
GNUTECA3	PRINT_SERVER_PORT	1515	Porta do servidor de impressao a ser utilizada	INTEGER	PRINT	6	Porta utilizada para comunicação com a impressora
GNUTECA3	HELP_MAIN_MYLIBRARY_MYINFORMATION	Aqui o usuário pode visualizar seus dados de contato, além de seu vínculo.	Conteúdo de ajuda que será exibido quando usuário clicar no botão Ajuda/Help do menu da pesquisa. Repare que todo form pode ter sua configuração de Help criando a preferência do sistema HELP_ + o action do handler.	VARCHAR	\N	\N	\N
GNUTECA3	HELP_MAIN_MYLIBRARY_MYLOAN	<CENTER><B>Aqui o usuário pode visualizar todos materiais que retirou nas unidades de bibliotecas.</CENTER></B>\nÉ possível filtrar os resultados, para isto é só preencher algum dos campos e clicar em Pesquisar.\n<img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(renew-16x16.png)" align="top" /> Mostra as renovações do material.	Conteúdo de ajuda que será exibido quando usuário clicar no botão Ajuda/Help do menu da pesquisa. Repare que todo form pode ter sua configuração de Help criando a preferência do sistema HELP_ + o action do handler.	VARCHAR	\N	\N	\N
GNUTECA3	HELP_MAIN_MYLIBRARY_MYPENALTY	<CENTER><B>Aqui o usuário pode visualizar as penalidades recebidas.</CENTER></B>\nQuando uma penalidade tiver data final em branco ou maior que o dia atual, significa que a pessoa está impedida de retirar materiais na biblioteca. \nÉ possível filtrar os resultados, para isto é só preencher algum dos campos e clicar em Pesquisar.	Conteúdo de ajuda que será exibido quando usuário clicar no botão Ajuda/Help do menu da pesquisa. Repare que todo form pode ter sua configuração de Help criando a preferência do sistema HELP_ + o action do handler.	VARCHAR	\N	\N	\N
GNUTECA3	HELP_MAIN_MYLIBRARY_PERSONCONFIG	<CENTER><B>Configurações de avisos</CENTER></B>\nAqui o usuário pode configurar:\n<UL><LI><B>Enviar Empréstimo atrasado:</B> se quer receber aviso, quando seu empréstimo estiver atrasado.\n<LI><B>Empréstimo atrasado:</B> quantidade de e-mails e o período de intervalo entre os avisos.\n<LI><B>Enviar notificação de aquisição:</B> se quer receber aviso com as novas aquisições da biblioteca.\n<LI><B>Notificar aquisições:</B> período de envio de notificações.\n<LI><B>Enviar dias antes do vencimento:</B> se quer receber um aviso informando que o material retirado irá vencer.\n<LI><B>Dias antes do vencimento:</B> quantidade de dias antes do vencimento para enviar o aviso.\n<LI><B>Recibo de empréstimo:</B> se é para imprimir o comprovante de empréstimo no balcão de empréstimos.\n<LI><B>Recibo de devolução:</B> se é para imprimir o comprovante de devolução no balcão de empréstimos.\n<LI><B>Enviar recibo de empréstimo:</B> se é para enviar por e-mail o comprovante de empréstimo no balcão de empréstimos.\n<LI><B>Enviar recibo de devolução:</B> se é para enviar por e-mail o comprovante de devolução no balcão de empréstimos.\n</UL>\n<B>OBS.:</B> Alguns campos são somente leitura, nestes casos funciona a configuração padrão do sistema.	Conteúdo de ajuda que será exibido quando usuário clicar no botão Ajuda/Help do menu da pesquisa. Repare que todo form pode ter sua configuração de Help criando a preferência do sistema HELP_ + o action do handler.	VARCHAR	\N	\N	\N
GNUTECA3	EMAIL_ADMIN_NOTIFY_ACQUISITION_RESULT_SUBJECT	Comunicação das notificações de aquisições	Define o titulo de email que envia o resultado das notificações de aquisições para o administrador.	CHAR	NOTIFICATION_AQUISITION	32	Assunto do e-mail do adminstrador
GNUTECA3	HELP_MAIN_MYLIBRARY_RESERVESHISTORY	<CENTER><B>Aqui o usuário pode visualizar o histórico de suas reservas.</CENTER></B> \nÉ possível filtrar os resultados, para isto é só preencher algum dos campos e clicar em Pesquisar.\nA coluna Estado mostra a situação da reserva:\n<UL><LI><B>Solicitada</B>: aguardando material;\n<LI><B>Atendida</B>: usuário pode retirar sua reserva;\n<LI><B>Comunicada</B>: usuário foi avisado que pode retirar sua reserva;\n<LI><B>Confirmada</B>: reserva chegou e usuário já a retirou;\n<LI><B>Vencida</B>: reserva chegou, mas usuário não a retirou até a data limite;\n<LI><B>Cancelada</B>: reserva cancelada.\n<UL>	Conteúdo de ajuda que será exibido quando usuário clicar no botão Ajuda/Help do menu da pesquisa. Repare que todo form pode ter sua configuração de Help criando a preferência do sistema HELP_ + o action do handler.	VARCHAR	\N	\N	\N
GNUTECA3	Z3950_SEARCH_FORMAT_ID	6	Define o ID do formato de pesquisa que sera exibido na pesquisa z3950	INTEGER	\N	\N	\N
GNUTECA3	HELP_FIELD_SPREADSHEET_DEFAULT_VALUES	Para adicionar valores padrão para tag 008,<br>insira um linha semelhante a esta:<br>008=campo1,campo2,campo 3,campo 4<br><br>Para campos de datas, você pode usar a função date para setar o dia atual.<br>Exemplo:008=&lt;date d/m/y&gt;&lt;/&gt;	Define o texto de ajuda para o campo Default Value do form Spreadsheet.	VARCHAR	\N	\N	\N
GNUTECA3	HELP_FIELD_SPREADSHEET_WORK_VALIDATOR	Exemplo:<br>245.a=required<br>650.a=required<br>901.a=required<br>949.a=unique<br>950.a=required,unique,readonly	Define o texto de ajuda para o campo Work validator do form Spreadsheet.	VARCHAR	\N	\N	\N
GNUTECA3	HELP_FIELD_SPREADSHEET_REPEAT_FIELD_VALIDATOR	Exemplo:<br>650.a=required,unique,readonly<br>949.a=required,unique<br>949.b=required<br>949.c=required<br>949.d=required<br>949.g=required<br>949.i=required<br>949.y=required,date	Define o texto de ajuda para o campo Repeat field validator do form Spreadsheet.	VARCHAR	\N	\N	\N
GNUTECA3	INTERCHANGE_STATUS_LETTER_SENT	2	Código do estado de permuta CARTA ENVIADA.	INTEGER	\N	\N	\N
GNUTECA3	INTERCHANGE_STATUS_CONFIRMED	3	Código do estado de permuta CONFIRMADO.	INTEGER	\N	\N	\N
GNUTECA3	INTERCHANGE_STATUS_GRATEFUL	5	Código do estado de permuta AGRADECIDO.	INTEGER	\N	\N	\N
GNUTECA3	REQUEST_CHANGE_EXEMPLARY_STATUS_REQUESTED	1	Código inicial de uma solicitação de alteração de estado de material	INTEGER	\N	\N	\N
GNUTECA3	REQUEST_CHANGE_EXEMPLARY_STATUS_APROVED	2	Código de aprovação de uma solicitação de alteração de estado de material	INTEGER	\N	\N	\N
GNUTECA3	REQUEST_CHANGE_EXEMPLARY_STATUS_REPROVED	3	Código de reprovação de uma solicitação de alteração de estado de material	INTEGER	\N	\N	\N
GNUTECA3	REQUEST_CHANGE_EXEMPLARY_STATUS_CONCLUDE	4	Código de conclusão de uma solicitação de alteração de estado de material	INTEGER	\N	\N	\N
GNUTECA3	REQUEST_CHANGE_EXEMPLARY_STATUS_CANCEL	5	Código de cancelamento de uma solicitação de alteração de estado de material	INTEGER	\N	\N	\N
GNUTECA3	REQUEST_CHANGE_EXEMPLARY_STATUS_CONFIRMED	6	Código de confirmação de uma solicitação de alteração de estado de material	INTEGER	\N	\N	\N
GNUTECA3	MYLIBRARY_REQUEST_TITLE	Congelados	Título do formulário de Requisições da Minha Biblioteca	CHAR	MY_LIBRARY	10	Título para requisição de troca de estado
GNUTECA3	REQUEST_CHANGE_EXEMPLARY_STATUS_BY_SEMESTER	t	Determina que as requisições de troca de estado terão datas pre definidas por semestre	VARCHAR	NOTIFICATION_REQUEST	47	Datas pré-definidas
GNUTECA3	Z3950_SEARCH_OPTIONS	1016 = Todos os Campos;\n7 = ISBN (020);\n14 = CDU (080);\n21 = Assunto;\n1000 = Autor e título;\n1003 = Autor;\n1004 = Autor pessoal;\n//1005 = Autor corporativo;\n//1006 = Autor conferencia;\n//1036 = Autor, título ou assunto;	Define as Opções de pesquisa z3950. Fonte: http://www.loc.gov/z3950/agency/defns/bib1.html	VARCHAR	\N	\N	\N
GNUTECA3	MAIL_LOG_GENERATE	t	Seta se é para gerar log de envio de emails.	BOOLEAN	\N	\N	\N
GNUTECA3	MAIL_LOG_FILE_NAME	gnuteca3-mail.log	Seta o nome do arquivo de log.	VARCHAR	\N	\N	\N
GNUTECA3	EMAIL_TESTING	f	Define se os envios de email são testes	BOOLEAN	ADM_EMAIL	25	Ativar modo teste
GNUTECA3	EMAIL_RESERVE_ANSWERED_ADMIN_RESULT_CONTENT	Segue abaixo o resultado do comunicado de reservas atendidas.$LN $CONTENT	Conteudo do e-mail que é enviado para o administrado com o resultado do comunicado de reservas atendidas.	VARCHAR	RESERVE	22	Conteúdo do e-mail do administrador
GNUTECA3	EMAIL_RESERVE_ANSWERED_ADMIN_RESULT_SUBJECT	Reserva cancelada	Define o titulo de email que envia um comunicado de reserva cancelada para o usuário.	CHAR	RESERVE	21	Assunto do e-mail do administrador
GNUTECA3	EMAIL_SUBJECT_PREFIX	[Gnuteca]	Prefixo utilizado para a descrição do sistema no assunto dos e-mails.	CHAR	ADM_EMAIL	15	Prefixo do assunto
GNUTECA3	EMAIL_ADMIN_REQUEST_CHANGE_EXEMPLARY_STATUS	\N	Define o endereço de e-mail da biblioteca. Esse endereço é utilizado para envio dos e-mails de requisição de troca de estado de material.	CHAR	NOTIFICATION_REQUEST	45	E-mail do administrador para troca de estado
GNUTECA3	EMAIL_TEST_RECEIVE	\N	Define o email que recebera os testes.	CHAR	ADM_EMAIL	26	Email para testes
GNUTECA3	EMAIL_USER	\N	Define o user SMTP que será utilizado, pelo Gnuteca, para envio de mensagens.	CHAR	ADM_EMAIL	7	Usuário
GNUTECA3	EMAIL_ADMIN_LOAN_BETWEEN_LIBRARY	email@aministradorEntreBibliotecas	Define o endereço de e-mail da biblioteca. Esse endereço é utilizado para envio dos e-mails de emprestimo entre bibliotecas	CHAR	LOAN_LIBRARY	5	Email do administrador
GNUTECA3	LOAN_RECEIPT_WORK	\n| <pad 44| $SP | RIGHT>CODIGO DO EXEMPLAR: $ITEM_NUMBER</pad> |$LN\n| <pad 44| $SP | RIGHT>TITULO: $MATERIAL_TITLE</pad> |$LN\n| <pad 44| $SP | RIGHT>AUTOR: $MATERIAL_AUTHOR</pad> |$LN\n| <pad 44| $SP | RIGHT>DATA DE DEVOLUCAO: $DEVOLUTION_DATE</pad> |$LN\n| <pad 44| $SP | RIGHT>RENOVAÇÕES WEB: $WEB_RENEW_AMOUNT</pad> |$LN\n| <pad 44| $SP | RIGHT>RENOVAÇÕES LOCAIS: $LOCAL_RENEW_AMOUNT</pad> |$LN\n| <pad 44| $SP | RIGHT>MULTA DIARIA: R$ $DAILY_FINE</pad> |$LN\n+----------------------------------------------+$LN\n	Define o modelo das obras que é anexado ao recibo de empréstimo	VARCHAR	LOAN	16	Recibo - $WORKS
GNUTECA3	RETURN_RECEIPT_WORK	\n| <pad 44| $SP | RIGHT>CODIGO DO EXEMPLAR: $ITEM_NUMBER</pad> |$LN\n| <pad 44| $SP | RIGHT>TITULO: $MATERIAL_TITLE</pad> |$LN\n| <pad 44| $SP | RIGHT>AUTOR: $MATERIAL_AUTHOR</pad> |$LN\n| <pad 44| $SP | RIGHT>MULTA: R$ $FINE</pad> |$LN\n| <pad 44| $SP | RIGHT>DATA DE EMPRESTIMO: $LOAN_DATE</pad> |$LN\n+----------------------------------------------+$LN\n	Define o modelo das obras que é anexado ao recibo de devolução	VARCHAR	RETURN	16	Recibo - $WORK
GNUTECA3	EMAIL_LOAN_RENEW_RECEIPT_SUBJECT	Recibo de empréstimo e/ou renovação.	Define o sufixo no assunto do e-mail que será enviado ao usuário anexando o recibo de empréstimo e/ou renovação. Complementa o parâmetro EMAIL_LOAN_RENEW_RECEIPT_CONTENT.	CHAR	LOAN	25	E-mail do recibo - assunto
GNUTECA3	RETURN_RECEIPT	\n$LN$LN$LN$LN\n+----------------------------------------------+$LN\n| <pad 44| $SP | RIGHT>Biblioteca: $LIBRARY_UNIT_DESCRIPTION</pad> |$LN\n+----------------------------------------------+$LN\n|      COMPROVANTE DE DEVOLUÇÃO                |$LN\n|                                              |$LN\n| <pad 44| $SP | RIGHT>CODIGO: $USER_CODE</pad> |$LN\n| <pad 44| $SP | RIGHT>NOME: $USER_NAME</pad> |$LN\n| <pad 44| $SP | RIGHT>DATA DE DEVOLUÇÃO: $DATE - $TIME</pad> |$LN\n| <pad 44| $SP | RIGHT>OPERADOR: $OPERATOR</pad> |$LN\n+----------------------------------------------+$LN\n|                  OBRAS                       |$LN\n+----------------------------------------------+$LN\n$WORKS\n| <pad 44| $SP | RIGHT>VALOR TOTAL DA MULTA: $TOTAL_FINE_VALUE</pad> |$LN\n+----------------------------------------------+$LN\n| <pad 44| $SP | RIGHT>$RECEIPT_FOOTER</pad> |$LN\n+----------------------------------------------+$LN	Define o recibo de devolução	VARCHAR	RETURN	15	Recibo
GNUTECA3	FINE_RECEIPT	\n$LN$LN$LN$LN\n+----------------------------------------------+$LN\n| <pad 44| $SP | RIGHT>Biblioteca: $LIBRARY_UNIT_DESCRIPTION</pad> |$LN\n+----------------------------------------------+$LN\n|      COMPROVANTE DE ALTERAÇÃO DE MULTA       |$LN\n|                                              |$LN\n| <pad 44| $SP | RIGHT>CODIGO: $USER_CODE</pad> |$LN\n| <pad 44| $SP | RIGHT>NOME: $USER_NAME</pad> |$LN\n| <pad 44| $SP | RIGHT>DATA DE DEVOLUÇÃO: $DATE - $TIME</pad> |$LN\n| <pad 44| $SP | RIGHT>OPERADOR: $OPERATOR</pad> |$LN\n+----------------------------------------------+$LN\n|                  OBRAS                       |$LN\n+----------------------------------------------+$LN\n$WORKS\n| <pad 44| $SP | RIGHT>VALOR TOTAL DA MULTA: $TOTAL_FINE_VALUE</pad> |$LN\n+----------------------------------------------+$LN\n| <pad 44| $SP | RIGHT>$RECEIPT_FOOTER</pad> |$LN\n+----------------------------------------------+$LN	Define o recibo de devolução	VARCHAR	FINE	10	Recibo
GNUTECA3	EMAIL_PORT	\N	Define porta que será utilizadA, pelo Gnuteca, para envio de mensagens	INTEGER	ADM_EMAIL	6	Porta
GNUTECA3	EMAIL_FROM_NAME	Gnuteca	Define o nome do remetende para envio de e-mails.	CHAR	ADM_EMAIL	10	Nome
GNUTECA3	EMAIL_SMTP	\N	Define o servidor SMTP que será utilizado, pelo Gnuteca, para envio de mensagens.	CHAR	ADM_EMAIL	5	Servidor de saída de email
GNUTECA3	EMAIL_LINE_BREAK	<br>	Quebra de linha dos avisos enviados por e-mail	CHAR	ADM_EMAIL	17	Quebra de linha
GNUTECA3	EMAIL_FROM	\N	Define o remetente dos emails.	CHAR	ADM_EMAIL	11	Email
GNUTECA3	EMAIL_SERVER_DELAY	1	Tempo de espera em segundos do servidor de email para envio da próxima mensagem. Esta opção é importante para evitar a sobrecarga do servidor de emails ou a interpretação de um possível ataque.	INT	ADM_EMAIL	24	Intervalo entre o envio (s)
GNUTECA3	EMAIL_ADMIN_RESERVE	\N	Define o endereço de e-mail da biblioteca. Esse endereço é utilizado para envio dos e-mails de empréstimo entre bibliotecas.	CHAR	RESERVE	20	E-mail do administrador
GNUTECA3	EMAIL_ADMIN	\N	Define o endereço de e-mail da biblioteca. Esse endereço é utilizado para envio dos e-mails.	CHAR	ADM_EMAIL	20	Email do administrador
GNUTECA3	EMAIL_AUTHENTICATE	f	Define se o envio de email é authenticado ou não.	BOOLEAN	ADM_EMAIL	8	Usar autenticação
GNUTECA3	EMAIL_CANCEL_SUBJECT_REQUEST_CHANGE_EXEMPLARY_STATUS	Cancelamento de Solicitação de mudança de estado.	Define o assunto do email que sera enviado para o administrador informando o cancelamento de uma solicitação de mudança de estado.	 VARCHAR	\N	\N	\N
GNUTECA3	EMAIL_COMUNICA_SOLICITANTE_TERMINO_REQUISICAO_SUBJECT	Encerrando periodo de congelamento de material	Define o assunto do email que sera enviado para o professor informando o encerramento do prazo de congelamento de material.	CHAR	NOTIFICATION_REQUEST	43	Assunto do e-mail de termino de congelamento
GNUTECA3	EMAIL_CANCEL_RESERVE_COMUNICA_SOLICITANTE_SUBJECT	Reservas comunicadas.	Define o titulo de email que envia o resultado do comunicado de reservas atendidas.	CHAR	RESERVE	15	Assunto do e-mail de reserva cancelada
GNUTECA3	EMAIL_LOAN_RENEW_RECEIPT_CONTENT	Prezado(a) $USER_NAME!$LN Segue em anexo o seu recibo de empréstimo.	Conteudo do email que sera enviado com o recibo em anexo.	VARCHAR	LOAN	26	E-mail do recibo - conteúdo
GNUTECA3	EMAIL_RESERVE_ANSWERED_SUBJECT	Aviso de reserva	Define o assunto do email que será enviado para o usuário quando sua reserva for atendida. 	CHAR	RESERVE	10	Assunto do e-mail de reserva atendida
GNUTECA3	EMAIL_NOTIFY_ACQUISITION_SUBJECT	Novas aquisições	Define o sufixo no assunto do e-mail que será enviado ao usuário para avisá-lo de novas aquisições. Complementa o parâmetro EMAIL_SUBJECT_PREFIX.	CHAR	NOTIFICATION_AQUISITION	35	Assunto do e-mail
GNUTECA3	EMAIL_RETURN_RECEIPT_CONTENT	Prezado(a) $USER_NAME! $LN Segue em anexo o seu recibo de devolução	Conteudo do email que sera enviado com o recibo em anexo.	VARCHAR	RETURN	26	E-mail do recibo - conteúdo
GNUTECA3	EMAIL_DELAYED_LOAN_SUBJECT	Empréstimo atrasado	Define o sufixo no assunto do e-mail que será enviado ao usuário para avisá-lo do atraso da devolução do material emprestado. Complementa o parâmetro EMAIL_SUBJECT_PREFIX.	CHAR	NOTIFICATION_LOAN	25	Assunto do e-mail de empréstimos atrasados
GNUTECA3	EMAIL_LOANBETWEENLIBRARY_CANCEL_CONTENT	Informamos que a biblioteca $LIBRARY_UNIT_DESCRIPTION cancelou o pedido de empréstimo para os seguintes materiais:\n$LN $MATERIALS	Conteúdo do e-mail enviado para as bibliotecas sobre empréstimo entre unidades (CANCELAMENTO)	VARCHAR	LOAN_LIBRARY	14	E-mail de cancelamento
GNUTECA3	EMAIL_RETURN_RECEIPT_SUBJECT	Recibo de devolução	Define o sufixo no assunto do e-mail que será enviado ao usuário anexando o recibo de devolução. Complementa o parâmetro EMAIL_RETURN_RECEIPT_CONTENT.	CHAR	RETURN	25	E-mail do recibo - assunto
GNUTECA3	EMAIL_FINE_RECEIPT_CONTENT	Prezado(a) $USER_NAME! $LN Segue em anexo o seu recibo de alteração de multa	Conteudo do email que sera enviado com o recibo de alteração de multa em anexo.	VARCHAR	FINE	16	E-mail do recibo - conteúdo
GNUTECA3	EMAIL_FINE_RECEIPT_SUBJECT	Recibo de Alteração de Multa	Define o sufixo no assunto do e-mail que será enviado ao usuário anexando o recibo de alteração de multa. Complementa o parâmetro EMAIL_FINE_RECEIPT_CONTENT.	CHAR	FINE	15	E-mail do recibo - assunto
GNUTECA3	EMAIL_CANCEL_CONTENT_REQUEST_CHANGE_EXEMPLARY_STATUS	\nA Requisição de troca de estado (Congelamento) de numero $REQUEST_ID, foi cancelada.\n	Conteudo do e-mail enviado para as bibliotecas sobre o cancelamento de uma solicitação de troca de estado;	VARCHAR	NOTIFICATION_REQUEST	46	E-mail para cancelamento da troca de estado
GNUTECA3	EMAIL_LOANBETWEENLIBRARY_REQUEST_CONTENT	\nInformamos que a biblioteca $LIBRARY_UNIT_DESCRIPTION requisitou empréstimo para os seguintes materiais:$LN\n$MATERIALS $LN\nData do empréstimo: $LOAN_DATE $LN\nData prevista de retorno: $RETURN_FORECAST_DATE\n	Conteudo do e-mail enviado para as bibliotecas sobre empréstimo entre unidades (REQUISICAO)	VARCHAR	LOAN_LIBRARY	11	E-mail de requisição
GNUTECA3	EMAIL_DELAYED_LOAN_CONTENT	\nPrezado(a) $USER_NAME! $LN\nSeu empréstimo ($ITEM_NUMBER) intitulado "$MATERIAL_TITLE", cuja data de devolução era $RETURN_DATE, está atrasado.$LN\nCaso já tenha devolvido o material acima citado, desconsidere esta mensagem.$LN\nAtenciosamente,$LN\nbiblioteca $LIBRARY_UNIT_DESCRIPTION.\n	Define o conteudo do e-mail que será enviado para o usuário quando seu empréstimo estiver em atraso.\nVariáveis aceitas:\n$USER_NAME - Nome do usuário\n$ITEM_NUMBER - registro do material\n$MATERIAL_TITLE - Título do material\n$RETURN_DATE - Data prevista para devolução\n$LIBRARY_UNIT_DESCRIPTION - Nome da Biblioteca.\n	VARCHAR	NOTIFICATION_LOAN	26	Conteúdo do e-mail de empréstimos atrasados
GNUTECA3	EMAIL_NOTIFY_ACQUISITION_CONTENT	\nPrezado(a) $USER_NAME $LN\nOs materiais abaixo foram adquiridos desde $DATE_AQUISITIONS pela biblioteca nas suas áreas de interesses.\n$ACQUISITIONS\nCaso não deseje mais receber este aviso, acesse o link "Definir Interesses" do Gnuteca e desabilite as opções.\n	Define o conteúdo do e-mail que será enviado para os usuário quando da notificação de aquisições.\n$USER_NAME - Nome do usuário\n$DATE_AQUISITIONS - Data inicial das aquisições\n$ACQUISITIONS - Aquisições da biblioteca no período	VARCHAR	NOTIFICATION_AQUISITION	36	Conteúdo do e-mail
GNUTECA3	MARK_SEND_LOAN_MAIL_RECEIPT	f	Define se a opção de enviar recibo de emprestimo sai marcada.	BOOLEAN	LOAN	6	Selecionar a opção enviar recibo
GNUTECA3	BAR_CODE_CHARACTERS	0 Não fixos\n6 6\n8 8\n10 10\n12 12\n14 14\n16 16\n18 18	Especifica as opções que fazem parte do campo caracteres na geração do código de barras.\n\nVALOR<espaço>Descrição	VARCHAR	\N	\N	\N
GNUTECA3	HELP_MAIN_SEARCH_SIMPLESEARCH	<center><b>AtravÃ©s deste mÃ³dulo, os usuÃ¡rios podem pesquisar os materiais catalogados pela biblioteca, alÃ©m de reservarem os exemplares que necessitem.</b></center>\n<img WIDTH="120" HEIGHT="30" SRC="MIOLO_GET_IMAGE(ConteudoFormulario.png)" align="top" /> Pelo conteÃºdo do formulÃ¡rio Ã© possÃ­vel criar pesquisas personalizadas.\n\n\n<img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(add-16x16.png)" align="top" /> Para restringir uma busca, pode-se adicionar quantos termos achar necessÃ¡rio, clicando neste botÃ£o.\n\n<img WIDTH="150" HEIGHT="30" SRC="MIOLO_GET_IMAGE(FiltrosAvancados.png)" align="top" /> Outra maneira de restringir a busca Ã© atravÃ©s dos filtros avanÃ§ados: <ul><li><b>Estado do exemplar:</b> retorna na busca sÃ³ os materiais que estÃ£o no estado especificado.\n<li><b>Limite de ocorrÃªncias:</b> nÃºmero mÃ¡ximo de materiais listados na pesquisa.\n<li><b>Ano de ediÃ§Ã£o:</b> pode-se pesquisar a partir de um ano ou em determinado perÃ­odo.\n<li><b>PerÃ­odo de aquisiÃ§Ã£o:</b> pode-se pesquisar a partir de um determinado perÃ­odo de aquisiÃ§Ã£o.\n<li><b>Pesquisa por letras:</b> lista os materiais em que o tÃ­tulo inicie pela letra selecionada. Para gerar algum resultado, deve-se digitar um texto a ser pesquisado.\n<li><b>Ordem:</b> Ã© possÃ­vel ordenar a pesquisa por um determinado campo.\n</ul>\n<img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(config-16x16.png)" align="top" /> Para mais informaÃ§Ãµes sobre o material, Ã© sÃ³ clicar neste botÃ£o.\n\n<img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(catalogue-16x16.png)" align="top" /> Lista todos os exemplares do material, informando quantas reservas possui e data prevista de devoluÃ§Ã£o, quando estÃ¡ emprestado.\n\n<img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(reserve-16x16.png)" align="top" /> Serve para reservar o material. Desde que se tenha permissÃ£o, pode-se reservar tanto exemplares emprestados, quanto disponÃ­veis; sendo que para estes, Ã© enviado um aviso ao operador do sistema para separar o material e alterar o estado da reserva para Atendida. Feito isto, o usuÃ¡rio que fez a requisiÃ§Ã£o, terÃ¡ dois dias para retirar a obra.\n\n<img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(login-16x16.png)" align="top" /> Quando a coluna Exemplares estÃ¡ em branco Ã© porque o material pertence a uma coleÃ§Ã£o. Desta forma, para reservar o fascÃ­culo, deve-se clicar no link Detalhes deste botÃ£o.\n\n<img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(congelado-16x16.png)" align="top" /> BotÃ£o utilizado para solicitar o congelamento de materiais. Somente usuÃ¡rios com permissÃ£o, podem acessÃ¡-lo.\n\n<img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(favorites-16x16.png)" align="top" /> Ao selecionar um material e clicar neste botÃ£o, ele Ã© adicionado aos Favoritos em Minha Biblioteca.\n\n<img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(document-16x16.png)" align="top" /> Salva os materiais selecionados num arquivo PDF.\n\n<img WIDTH="15" HEIGHT="15" SRC="MIOLO_GET_IMAGE(email-16x16.png)" align="top" /> Envia por e-mail um arquivo PDF com os materiais selecionados.	ConteÃºdo de ajuda que serÃ¡ exibida quando usuÃ¡rio clicar no botÃ£o Ajuda/Help do menu da pesquisa. Repare que todo form pode ter sua configuraÃ§Ã£o de Help criando a preferÃªncia do sistema HELP_ + o action do handler.	VARCHAR	\N	\N	\N
GNUTECA3	ID_FINESTATUS_PAYED	2	Codigo do estado da multa Paga	INT	\N	\N	\N
GNUTECA3	ID_FINESTATUS_BILLET	3	Codigo do estado da multa Paga via boleto	INT	\N	\N	\N
GNUTECA3	ID_FINESTATUS_EXCUSED	4	Codigo do estado da multa Abonada	INT	\N	\N	\N
GNUTECA3	MARC_ISBN_TAG	020.a	Marc tag that represents ISBN identifier.	VARCHAR	\N	\N	\N
GNUTECA3	MATERIAL_SEARCH_USE_PREFIX_SUFFIX	t	Define se as buscas de material utilizam ou não prefixo e sufixo automaticamente	BOOLEAN	SEARCH	100	Mostrar prefixo e sufixo
GNUTECA3	EMAIL_SIMPLESEARCH_REPORT_SUBJECT	Relatório exemplares	Assunto do e-mail enviado para usuário na Busca Simples, contendo o relatório PDF gerado em anexo.	CHAR	SEARCH	30	E-mail dos materiais - assunto
GNUTECA3	EMAIL_LOANBETWEENLIBRARY_RETURNMATERIAL_CONTENT	Informamos que a biblioteca $LIBRARY_UNIT_DESCRIPTION encaminhou para devolução os seguintes materiais:\n$MATERIALS	Conteúdo do e-mail enviado para as bibliotecas ao encaminhar materiais para devolução	VARCHAR	LOAN_LIBRARY	13	E-mail de devolução
GNUTECA3	EMAIL_ADMIN_NOTIFY_END_REQUEST_RESULT_SUBJECT	Comunicação das notificações de término de requisição.	Define o titulo de email que envia o resultado das notificações de término de requisição para administrador.	CHAR	NOTIFICATION_REQUEST	41	Assunto do e-mail do administrador
GNUTECA3	GB_INTEGRATION	t	Define integração com Google Books	BOOLEAN	SEARCH	40	Integração com Google Books
GNUTECA3	INTERCHANGE_LETTER_SEND_CONTENT	Prezado $CONTACT_NAME! $LN\nEstamos enviando os seguintes materiais:\n$MATERIALS	Conteúdo da carta de envio para o intercambio	VARCHAR	INTERCHANGE	20	Conteúdo do e-mail
GNUTECA3	EMAIL_LOANBETWEENLIBRARY_CONFIRMLOAN_CONTENT	Informamos que a biblioteca $LIBRARY_UNIT_DESCRIPTION $ACTION o empréstimo para os seguintes materiais: $LN\n$MATERIALS	Conteúdo do e-mail enviado para as bibliotecas ao Aprovar ou Reprovar um empréstimo entre unidade	VARCHAR	LOAN_LIBRARY	12	E-mail de confirmação
GNUTECA3	EMAIL_SIMPLESEARCH_REPORT_CONTENT	Prezado usuário(a), $LN\n$LN\nSegue em anexo o relatório contendo informações dos exemplares selecionados.	Conteúdo do e-mail enviado para usuário na Busca Simples, contendo o relatório PDF gerado em anexo.	VARCHAR	SEARCH	31	E-mail dos materiais - conteúdo
GNUTECA3	INTERCHANGE_MAIL_RECEIPT_AUTOSEND	t	Indica se é para enviar e-mail de agradecimento diretamente para fornecedor ou abrir uma tela com conteúdo e destinatário para usuário personalizar a mensagem	BOOLEAN	INTERCHANGE	5	Ativar o envio automátioco para o fornecedor
GNUTECA3	INTERCHANGE_MAIL_RECEIPT_SUBJECT	Recebimento intercâmbio	Assunto do email de recebimento do intercambio	CHAR	INTERCHANGE	10	E-mail de recebimento - assunto
GNUTECA3	EMAIL_ADMIN_DEVOLUTION_RESULT_SUBJECT	Comunicação das devoluções.	Define o titulo de email que envia o resultado das devoluções para o administrador.	CHAR	NOTIFICATION_LOAN	12	Assunto do e-mail do adminstrador
GNUTECA3	EMAIL_ADMIN_DEVOLUTION_RESULT_CONTENT	Segue abaixo o resultado do comunicado de devoluções.$LN $CONTENT	Conteudo do e-mail que é enviado para o administrador com o resultado das devoluções.	VARCHAR	NOTIFICATION_LOAN	13	Conteúdo do e-mail do administrador
GNUTECA3	EMAIL_ADMIN_NOTIFY_ACQUISITION	\N	Define o endereço de e-mail da biblioteca. Esse endereço é utilizado para envio dos e-mails de notificação de aquisições.	CHAR	NOTIFICATION_AQUISITION	31	E-mail do administrador
GNUTECA3	EMAIL_ADMIN_DELAYED_LOAN_RESULT_CONTENT	Segue abaixo o resultado do comunicado de devoluções.$LN $CONTENT	Conteudo do e-mail que é enviado para o administrador com o resultado das devoluções atrasadas.	VARCHAR	NOTIFICATION_LOAN	23	Conteúdo do e-mail do administrador
GNUTECA3	SIMPLE_SEARCH_SHOW_EXTRA_ACTIONS	f	Mostra ou esconde ações extras na pesquisa. É importante notar que todas estas ações podem ser acessadas na janela de detalhes.	BOOLEAN	SEARCH	100	Mostra ações extras
GNUTECA3	MY_LIBRARY_AUTHENTICATE_LDAP	f	Caso verdadeiro, usa LDAP para autenticar na minha biblioteca, usando configuraÃÂ§ÃÂ£o de conexÃÂ£o de LDAP definida no conf	BOOLEAN	\N	\N	\N
GNUTECA3	EMAIL_ADMIN_DELAYED_LOAN	\N	Define o endereço de e-mail da biblioteca. Esse endereço é utilizado para envio dos e-mails de devolução atrasada.	CHAR	NOTIFICATION_LOAN	21	E-mail do administrador do empréstimo atrasado
GNUTECA3	INTERCHANGE_MAIL_RECEIPT_CONTENT	Prezado $CONTACT_NAME! $LN Informamos que recebemos os seguintes materiais:$LN$LN $MATERIALS	Conteúdo do email de recebimento	VARCHAR	INTERCHANGE	11	E-mail de recebimento - conteúdo
GNUTECA3	DEFAULT_BARCODE_LABEL_LAYOUT	3	Define o modelo de etiqueta que será utilizado para imprimir os códigos de barras. O valor utilizado é o código da etiqueta.	INT	ADMIN	6	Modelo de etiqueta padrão
GNUTECA3	SIMPLE_SEARCH_SHOW_TERM_CONDITION	f	Define se é para mostrar campo Condição dos Termos da pesquisa.	BOOLEAN	SEARCH	8	Ativar condição dos termos
GNUTECA3	FINE_RECEIPT_WORK	\n| <pad 44| $SP | RIGHT>CODIGO DA MULTA: $FINE_ID</pad> |$LN\n| <pad 44| $SP | RIGHT>CODIGO DO EXEMPLAR: $ITEM_NUMBER</pad> |$LN\n| <pad 44| $SP | RIGHT>TITULO: $MATERIAL_TITLE</pad> |$LN\n| <pad 44| $SP | RIGHT>AUTOR: $MATERIAL_AUTHOR</pad> |$LN\n| <pad 44| $SP | RIGHT>DATA: $DATE - $TIME</pad> |$LN\n| <pad 44| $SP | RIGHT>OPERACAO: $OPERATION</pad> |$LN\n| <pad 44| $SP | RIGHT>VALOR: R$ $VALUE</pad> |$LN\n+----------------------------------------------+$LN\n	Define o modelo das obras que é anexado ao recibo de devolução	VARCHAR	FINE	11	Recibo - $WORK
GNUTECA3	EMAIL_RESERVE_ANSWERED_CONTENT	\nPrezado(a) $USER_NAME!$LN\nSua reserva de código $RESERVE_CODE, intitulada "$MATERIAL_TITLE", já se encontra à sua disposição no balcão de empréstimo da biblioteca.$LN\nSua data limite para retirada é $RESERVE_WITHDRAWAL_DATE. Atente para esta data, pois após este prazo, o material passará automaticamente para o próximo da fila.$LN\nAtenciosamente,\nbiblioteca $LIBRARY_UNIT_DESCRIPTION.\n	Define o conteudo do e-mail que será enviado para o usuário quando sua reserva for atendida. O Gnuteca 2 após o envio desta mensagem, altera, automaticamente, o estado da reserva de Atendida para Comunicada.\nVariáveis aceitas:\n$USER_NAME - Nome do usuário\n$MATERIAL_TITLE - Descrição do material\n$RESERVE_WITHDRAWAL_DATE - Data limite de retirada	VARCHAR	RESERVE	11	Conteúdo do e-mail de reserva atendida
GNUTECA3	SIMPLE_SEARCH_DEFAULT_ORDER	1,ASC	Ordenação padrão para a pesquisa no formulario. A configuracao deve ser: CodigoDoCampoPesquisavel,TipoOrdenacao - Ex: 1,ASC	CHAR	SEARCH	13	Ordem padrão da pesquisa
GNUTECA3	MARK_PRINT_RECEIPT_LOAN	t	Define se a opção de imprimir recibo de empréstimo sai marcada.	BOOLEAN	LOAN	5	Selecionar a opção imprimir recibo
GNUTECA3	USER_DAYS_BEFORE_EXPIRED	2	Valor padrão que indica a quantidade de dias antes em que o usuário deva ser informado da devolução de um material. Este valor não pode ultrapassar o valor definido em LIMIT_DAYS_BEFORE_EXPIRED	INT	NOTIFICATION_LOAN	15	Avisar em X dias antes do vencimento
GNUTECA3	CHANGE_WRITE_PERSON	t	Permite cadastrar novas pessoas e alterar seus dados	BOOLEAN	ADMIN	11	Ativar cadastro de pessoas
GNUTECA3	FIELD_DESCRIPTION_SIZE	38	Tamanho padrão para campos DESCRIPTION	INT	ADM_INTERFACE	7	Tamanho do campo descrição
GNUTECA3	FIELD_LOOKUPFIELD_SIZE	8	Tamanho padrão para campos de Lookup	INT	ADM_INTERFACE	14	Tamanho do campo lookup
GNUTECA3	LABEL_PERSON_CONFIG	<CENTER><B>Configurações de avisos.</CENTER></B><BR>	Mensagem a ser mostrada no topo de configurações pessoais da Minha Biblioteca	VARCHAR	MY_LIBRARY	31	Mensagem para as configurações pessoais
GNUTECA3	SEARCH_REQUEST_TITLE	Requisitar congelamento	Título do formulário de Requisições das Pesquisas	CHAR	SEARCH	32	Título para requisição de troca de estado
GNUTECA3	PRINT_SERVER_CUT_COMMAND	27,109	Comando que indica para impressora que o recibo deve ser cortado na impressao (separado por virgula em ASCII code)	CHAR	PRINT	10	Comando para ativar a guilhotinha
GNUTECA3	LABEL_INTEREST_AREA	<CENTER><B>Áreas de interesse para os avisos de novas de aquisições.</CENTER></B><BR>	Mensagem a ser mostrada no topo da tela das áreas de interesse da Minha Biblioteca	VARCHAR	MY_LIBRARY	30	Mensagem para áreas de interesse
GNUTECA3	REQUEST_CHANGE_EXEMPLARY_STATUS_SEMESTER_PERIOD	A=\nStartDate:01/01,\nEndDate:30/06,\nStarting:01/12;\nB=\nStartDate:01/07,\nEndDate:31/12,\nStarting:01/06;\n	Determina os peridos validos das requisições; Pode ser definido N periodos.\n\nExemplos:\n\nA=\nStartDate:01/01,\nEndDate:30/06,\nStarting:01/12;\nB=\nStartDate:01/07,\nEndDate:31/12,\nStarting:01/06;\n	VARCHAR	NOTIFICATION_REQUEST	48	Período de requisição
GNUTECA3	USER_DELAYED_LOAN	7;1	Valor padrão que indica a quantidade de emails e o intervalo de dias para comunicar os usuários que estão com empréstimos atrasados. Ex: 5;7 - enviará 5 emails com um intervalo de 7 dias cada. 7;1 - enviará 7 email sem intervalo de dias entre eles.	CHAR	NOTIFICATION_LOAN	24	Quantidade de avisos e intervalo
GNUTECA3	CLASS_USER_ACCESS_IN_THE_LIBRARY	BusNotPersonLibraryUnit	Nome da classe que fará a checagem se o usuário terá permissão de retirar materiais na biblioteca. Não será executada esta verificação se o valor estiver em branco ou incorreto. Opções válidas: BusPersonLibraryUnit	CHAR	ADMIN	10	Controle de acesso por usuário
GNUTECA3	FIELD_MULTILINE_COLS_SIZE	50	Quantidade de colunas padrão para um campo Multiline.	INT	ADM_INTERFACE	10	Largura do campo texto
GNUTECA3	EMAIL_PASSWORD	\N	Define senha do user que será utilizado, pelo Gnuteca, para envio de mensagens.	CHAR	ADM_EMAIL	9	Senha
GNUTECA3	EMAIL_COMUNICA_SOLICITANTE_TERMINO_REQUISICAO_CONTENT	Prezado $REQUESTOR_NAME! $LN\nSua solicitação de congelamento de material esta encerrando.  $LN\nCódigo: $REQUEST_ID $LN\nEncerramento: $FINAL_DATE $LN\nMateriais : $MATERIALS 	Conteúdo do e-mail enviado para o professor sobre o encerramento do prazo de congelamento de material.	VARCHAR	NOTIFICATION_REQUEST	44	Conteúdo do e-mail de termino de congelamento
GNUTECA3	EMAIL_ADMIN_NOTIFY_END_REQUEST	\N	Define o endereço de e-mail da biblioteca. Esse endereço é utilizado para envio dos e-mails de notificação de término de requisição.	CHAR	NOTIFICATION_REQUEST	40	E-mail do administrador do termino de congelamento
GNUTECA3	LOAN_RECEIPT	\n$LN$LN$LN$LN\n+----------------------------------------------+$LN\n| <pad 44| $SP | RIGHT>Biblioteca: $LIBRARY_UNIT_DESCRIPTION</pad> |$LN\n+----------------------------------------------+$LN\n|         COMPROVANTE DE EMPRESTIMO            |$LN\n|                                              |$LN\n| <pad 44| $SP | RIGHT>CODIGO: $USER_CODE</pad> |$LN\n| <pad 44| $SP | RIGHT>NOME: $USER_NAME</pad> |$LN\n| <pad 44| $SP | RIGHT>DATA DE EMPRESTIMO: $DATE - $TIME</pad> |$LN\n| <pad 44| $SP | RIGHT>OPERADOR: $OPERATOR</pad> |$LN\n+----------------------------------------------+$LN\n|                  OBRAS                       |$LN\n+----------------------------------------------+$LN\n$WORKS\n| <pad 44| $SP | RIGHT>$RECEIPT_FOOTER</pad> |$LN\n+----------------------------------------------+$LN	Define o recibo de empréstimo	VARCHAR	LOAN	15	Recibo
GNUTECA3	EMAIL_RETURN_CONTENT	Prezado(a) $USER_NAME! $LN\nSeu empréstimo intitulado "$MATERIAL_TITLE" ($ITEM_NUMBER) irá vencer dia $RETURN_FORECAST_DATE.$LN\nAtenciosamente,$LN\nbiblioteca de $LIBRARY_UNIT_DESCRIPTION	Define o conteúdo do e-mail que será enviado para o usuário com a data prevista para devolução do empréstimo.\nVariáveis aceitas:\n$USER_NAME - Nome do usuário\n$MATERIAL_TITLE - Descrição do material\n$ITEM_NUMBER - registro do material\n$RETURN_FORECAST_DATE - Data prevista para devolução\n$LIBRARY_UNIT_DESCRIPTION - Library unit description	VARCHAR	NOTIFICATION_LOAN	17	Conteúdo do e-mail da devolução
GNUTECA3	EMAIL_ADMIN_DELAYED_LOAN_RESULT_SUBJECT	Comunicação das devoluções atrasadas	Define o titulo de email que envia o resultado das devoluções atrasadas para o administrador	CHAR	NOTIFICATION_LOAN	22	Assunto do e-mail do adminstrador
GNUTECA3	EMAIL_ADMIN_NOTIFY_ACQUISITION_RESULT_CONTENT	Segue abaixo o resultado do comunicado de reservas atendidas.$LN $CONTENT	Conteudo do e-mail que é enviado para o administrador com o resultado da notificação de aquisições.	VARCHAR	NOTIFICATION_AQUISITION	33	Conteúdo do e-mail do adminstrador
GNUTECA3	USER_CONFIG	USER_SEND_DELAYED_LOAN=w|Enviar avisos de materiais em atraso por e-mail?\nUSER_DELAYED_LOAN=w|Quantidade de e-mails enviados. Período em dias entre os avisos.\nUSER_SEND_NOTIFY_AQUISITION=r|Enviar notificações de materiais novos por e-mail?\nUSER_NOTIFY_AQUISITION=r|Envio de Lista de materiais adquiridos neste período (em dias).\nUSER_SEND_DAYS_BEFORE_EXPIRED=w|Enviar aviso por e-mail antes de vencer material?\nUSER_DAYS_BEFORE_EXPIRED=w|Período em dias, para envio de aviso antes de vencer.\nCONFIGURE_RECEIPT_LOAN=w|Configura a impressão e envio do comprovante de empréstimo.\nCONFIGURE_RECEIPT_RETURN=w|Configura a impressão e envio do comprovante de devolução.\nUSER_SEND_RECEIPT_RENEW_WEB=w|Enviar comprovantes de renovação via web?	Os campos válidos são: \nUSER_DELAYED_LOAN USER_SEND_DELAYED_LOAN \nUSER_NOTIFY_AQUISITION \nUSER_SEND_NOTIFY_AQUISITION \nUSER_DAYS_BEFORE_EXPIRED \nUSER_SEND_DAYS_BEFORE_EXPIRED \nCONFIGURE_RECEIPT_LOAN \nCONFIGURE_RECEIPT_RETURN \nUSER_SEND_RECEIPT_RENEW_WEB \n\nLegenda: \nW: Libera o campo para leitura e escrita. \nR: Libera apenas para leitura. \nI: Não mostra o campo. \nO ponto-e-vírgula separa os campos. \nA vírgula separa a preferência e seu valor da legenda. \nO igual separa o valor da preferência.	VARCHAR	MY_LIBRARY	15	Configurações do usuário
GNUTECA3	USER_SEND_RECEIPT_RENEW_WEB	t	Define se é enviado comprovante de renovação web.	BOOLEAN	\N	\N	\N
GNUTECA3	MARK_DONT_PRINT_SEND_RECEIPT	t	Listar a opção Não receber e enviar recibo nos campos Comprovantes de empréstimo e Comprovantes de devolução no formulário Configuração do usuário da Minha biblioteca.	BOOLEAN	\N	\N	\N
GNUTECA3	Z3950_IGNORAR_TAGS	9**	Exemplos: 24*,856.a,856.u,901.a,902.b,900* \n901.* = pega todas as tags da etiqueta 901 (901.a,901.b) \n990* = pega as tags de 901.* a 909.* \n9** = pega todas as tags da etiqueta 900	INT	\N	\N	\N
GNUTECA3	EMAIL_ADMIN_DEVOLUTION	\N	Define o endereço de e-mail da biblioteca. Esse endereço é utilizado para envio dos e-mails de devolução.	CHAR	NOTIFICATION_LOAN	11	E-mail do administrador da devolução
GNUTECA3	EMAIL_ADMIN_NOTIFY_END_REQUEST_RESULT_CONTENT	Segue abaixo o resultado do comunicado de término de requisições.$LN $CONTENT	Conteudo do e-mail que é enviado para o administrador com o resultado das notificações de término de requisição.	VARCHAR	NOTIFICATION_REQUEST	42	Conteúdo do e-mail do administrador
GNUTECA3	SEARCH_THEME_FOOTER	<div style='text-align:right;font-size:9px;margin-top:8px;'>\n<strong>SOLIS - Cooperativa de Soluções Livres</strong><br/>\nAv. Sete de Setembro, 184 - Sala 401<br/>\nBairro Moinhos - 95900-000 - Lajeado (RS)<br/>\nFone: +55 51 3714-6653<br/>\n<a href='mailto:negocios@solis.coop.br'>negocios@solis.coop.br<a/>\n</div>\n	Conteúdo de rodapé da pesquisa	VARCHAR	SEARCH	\N	Rodapé da pesquisa
GNUTECA3	INTERCHANGE_LETTER_MODEL	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">\n<HTML>\n<HEAD>\n\t<META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=utf-8">\n\t<TITLE></TITLE>\n\t<META NAME="GENERATOR" CONTENT="OpenOffice.org 2.4  (Unix)">\n\t<META NAME="CREATED" CONTENT="20081009;16441600">\n\t<META NAME="CHANGED" CONTENT="20090513;8525600">\n\t<STYLE TYPE="text/css">\n    p {\n        font-family:"Times New Roman",Georgia,Serif;\n        font-size: 11px;\n    }\n    table {\n        width: 550px;\n        border-bottom: 1px solid #000000;\n    }\n    .col1 {\n        width: 190px;\n    }\n    .col2 {\n    }\n\t</STYLE>\n</HEAD>\n<BODY LANG="pt-BR" DIR="LTR">\n<P ALIGN=CENTER STYLE="margin-bottom: 0cm; font-style: normal; line-height: 100%;">\n<table width="400px" style="border-bottom:none; margin: 0 0 0 25px">\n    <tr>\n    <td>\n    <IMG SRC="$IMG_LOGO" NAME="figura1">\n    </td>\n    <td width="400px">\n    <p align="center" style="font-size:10px"><B>NOME INSTITUIÇÃO<BR>Setor Intercâmbio<BR></B>\nRua<BR>Cidade - Estado<BR>CEP</p>\n    </td>\n    </tr>\n</table>\n\n<table style="margin: 0 0 0 25px">\n    <tr>\n        <td>\n            <p ><b><strong>$SUPPLIER_NAME</strong></b></p>\n            <p align="center"><b>SETOR DE INTERCÂMBIO</b></p>\n        </td>\n    </tr>\n</table>\n<br/>\n<br/>\n\n<table style="margin: 0 0 0 25px">\n    <tr>\n        <td class="col1">\n            <p>\n            <b>Recebemos e agradecemos:</b>\n            <br/>Recibimos y agradecemos\n            <br/>We have received with thanks\n            </p>\n        </td>\n        <td class="col2">\n            <p>\n            </p>\n        </td>\n    </tr>\n</table>\n\n\n<table style="margin: 0 0 0 25px">\n    <tr>\n        <td class="col1">\n            <p>\n            <b>Temos o prazer de enviar:</b>\n            <br/>Nos complace enviarle\n            <br/>We are glad to send\n            </p>\n        </td>\n        <td class="col2">\n            <p>\n            $MATERIALS\n            </p>\n        </td>\n    </tr>\n</table>\n\n\n<table style="margin: 0 0 0 25px">\n    <tr>\n        <td class="col1">\n            <p>\n            <b>Estamos interessados em receber:</b>\n            <br/>Deseamos\n            <br/>We would like to receive\n            </p>\n        </td>\n        <td class="col2">\n            <p>\n            </p>\n        </td>\n    </tr>\n</table>\n\n\n<table style="margin: 0 0 0 25px">\n    <tr>\n        <td class="col1">\n            <p>\n            <b>Informamos</b>\n            <br/>Informamos usted\n            <br/>We inform you\n            </p>\n        </td>\n        <td class="col2">\n            <p>\n            Favor confirmar recebimento através do e-mail\n            <br/>email@intituicao.com.br\n            </p>\n        </td>\n    </tr>\n</table>\n\n<table style="margin: 0 0 0 25px">\n    <tr>\n        <td>\n            <p >Atenciosamente</p>\n            <br/>\n\n            <p align="center">Nome responsável<br>Chefe setor</p>\n        </td>\n    </tr>\n</table>\n</P>\n</BODY>\n</HTML>	Modelo utilizado na geração da carta do intercâmbio	VARCHAR	INTERCHANGE	21	Modelo da carta
GNUTECA3	HELP_MAIN_MYLIBRARY_INTERESTSAREA	<CENTER><B>Aqui o usuário pode marcar as áreas de seu interesse e assim estar sempre atualizado sobre as novas aquisições da biblioteca.</CENTER></B>\n<UL><LI>Seleciona-se as áreas interesse e clica-se no botão Salvar.</UL> <B>Obs.</B>: O e-mail com os materiais adquiridos é enviado de acordo com o período especificado pelo usuário no campo Notificação de aquisições em Configuração pessoal.	Conteúdo de ajuda que será exibido quando usuário clicar no botão Ajuda/Help do menu da pesquisa. Repare que todo form pode ter sua configuração de Help criando a preferência do sistema HELP_ + o action do handler.	VARCHAR	\N	\N	\N
GNUTECA3	LABEL_PERSON_DATA		Mensagem a ser mostrada no topo de dados pessoais da Minha Biblioteca.	VARCHAR	MY_LIBRARY	37	Mensagem para configurações pessoais
GNUTECA3	REPORT_ID_DICTIONARY	38	Define o código do relatório de gerencia de dicionários	INTEGER	\N	\N	\N
GNUTECA3	USER_ESPECIFICAR_CODIGO_MANUALMENTE	f	Preferência que ativa/desativa o campo código no cadastro de pessoa. Quando o valor é true, o campo aparece no cadastro, caso contrário, o código é atribuído automáticamente.	BOOLEAN	ADMIN	\N	Especificar manualmente o código da pessoa
GNUTECA3	SIMPLE_SEARCH_EVALUATION	t	Ativa/desativa avaliações na pesquisa para usuário.	BOOLEAN	SEARCH	\N	Avaliações
GNUTECA3	MY_LIBRARY_AUTHENTICATE_TYPE	1	1 - autenticação via código da pessoa\n2 - autenticação via campo login\n3 - autenticação campo login/base	INT	\N	\N	Tipo de autenticação
GNUTECA3	MY_LIBRARY_LDAP_INSERT_USER	base_1;nome=<tagDoLdap>;email=<tagDoLdap>;login=<tagDoLdap>;vinculo=1;validade=12/12/2012\nbase_2;nome=<tagDoLdap>;email=<tagDoLdap>;login=<tagDoLdap>;vinculo=2;validade=11/11/2011	Esta preferência definirá como os usuários do LDAP serão inseridos. A configuração se dará com uma base por linha, exemplo:\nbase_1;nome=<tagDoLdap>;email=<tagDoLdap>;login=<tagDoLdap>;vinculo=1;validade=12/12/2012\nbase_2;nome=<tagDoLdap>;email=<tagDoLdap>;login=<tagDoLdap>;vinculo=2;validade=11/11/2011	VARCHAR	MY_LIBRARY	\N	Inclusão de usuários LDAP
GNUTECA3	PRINT_MODE	1	Define o modo de impressão. \n\nOpções: \n1 = Impressão por socket \n2 = Impressão pelo navegador	INT	PRINT	15	Modo de impressão
GNUTECA3	ROUND_PENALTY_BY_DELAY	t	Arredonda dias de penalidade por atraso para cima caso (true) ou para baixo caso (false).	BOOLEAN	\N	\N	\N
GNUTECA3	PRINT_SERVER_ENABLED	t	Marque TRUE (t) para ativar o servidor, FALSE (f) para desativar.	BOOLEAN	PRINT	\N	\N
GNUTECA3	EXECUTE_BACKGROUND_TASK	t	Permite, ou não a execução de tarefas em segundo plano.	BOOLEAN	ADMIN	100	Tarefas em segundo plano
GNUTECA3	SIMPLE_SEARCH_MAX_LIMIT	0	Define a quantidade máxima de indices a serem mostrados nas pesquisas	INTEGER	SEARCH	17	Limite máximo de registros
GNUTECA3	ANALYCTS_LOGLEVEL_OUTER	1	Nível de registro de acesso para pesquisa. Valores possíveis são 0-desligado, 1-normal, 2-máximo	integer	ADMIN	100	Nível de log de acesso para pesquisa
GNUTECA3	ANALYCTS_LOGLEVEL_INNER	1	Nível de registro de acesso para todo o sistema. Valores possíveis são 0-desligado, 1-normal, 2-máximo	integer	ADMIN	100	Nível de log de acesso para todo o sistema
GNUTECA3	FIELDS_PURCHASE_REQUEST	245.a|Título|Inserir o título da obra\n100.a|Autor|Inseir o autor da obra\n260.b|Editora|\n250.a|Edição|\n949.v|Volume|	Campos são separados por ""enter"". Etiqueta, rótulo e ajuda docampo são separados por pipe ""|"". Ordem das valores: Etiqueta MARC|Rótulo do campo|Ajuda do campo Exemplo: 100.a|Autor|Inseir o autor da obra	VARCHAR	PURCHASE_REQUEST	33	Campos para o formulário de solicitação de compras
GNUTECA3	EMAIL_ADMIN_PURCHASE_REQUEST	gnutecadevel@gmail.com	Define o endereço de email do administrador para solicitação de compras.	VARCHAR	PURCHASE_REQUEST	\N	Email administrativo
GNUTECA3	EMAIL_PURCHASE_REQUEST_CANCEL_SUBJECT	Aviso de cancelamento de solicitação de compra	Define o sufixo do assunto do email de cancelamento da solicitação de compra	VARCHAR	PURCHASE_REQUEST	\N	Email de cancelamento - Assunto 
GNUTECA3	EMAIL_PURCHASE_REQUEST_CANCEL_CONTENT	Prezado $username $LN\n$LN\nA solicitação de compra de número $purchaseRequestId foi cancelada:$LN\n$LN\nDetalhes do material:$LN\n$LN\n$content$LN\n$LN\nMotivo:$LN\n$comment$LN\n$LN\n$controlNumberLink$LN\n$LN\nAtenciosamente.$LN\n$LN\nBiblioteca.$LN	Conteúdo do email de aviso de cancelamento de solicitação de material. Variáveis: $username, $purchaseRequestId, $content, $comment, $controlNumberLink	VARCHAR	PURCHASE_REQUEST	\N	Email de cancelamento - Conteúdo.
GNUTECA3	EMAIL_PURCHASE_REQUEST_APROVE_SUBJECT	Aviso de aprovação de solicitação de compra	Define o sufixo do assunto do email de aprovação da solicitação de compra	VARCHAR	PURCHASE_REQUEST	\N	Email de aprovação - Assunto 
GNUTECA3	EMAIL_PURCHASE_REQUEST_APROVE_CONTENT	Prezado $username $LN\n$LN\nA solicitação de compra de número $purchaseRequestId foi aprovada:$LN\n$LN\nDetalhes do material:$LN\n$LN\n$content$LN\n$LN\nData de previsão de entrega: $forecastDelivery $LN\n$LN\nAtenciosamente.$LN\n$LN\nBiblioteca.$LN	Conteúdo do email de aviso de aprovação de solicitação de material. Variáveis: $username, $purchaseRequestId, $content, $comment,$forecastDelivery	VARCHAR	PURCHASE_REQUEST	\N	Email de aprovação - Conteúdo.
GNUTECA3	EMAIL_PURCHASE_REQUEST_FINALIZE_SUBJECT	Aviso de aprovação de solicitação de compra	Define o sufixo do assunto do email de finalização da solicitação de compra	VARCHAR	PURCHASE_REQUEST	\N	Email de finalização - Assunto 
GNUTECA3	EMAIL_PURCHASE_REQUEST_FINALIZE_CONTENT	Prezado $username $LN\n$LN\nA solicitação de compra de número $purchaseRequestId foi finalizada:$LN\nO material já se encontra disponível.$LN\n$LN\nDetalhes do material:$LN\n$LN\n$content$LN\n$LN\n$controlNumberLink$LN\n$LN\nAtenciosamente.$LN\n$LN\nBiblioteca.$LN	Conteúdo do email de aviso de finalização de solicitação de material. Variáveis: $username, $purchaseRequestId, $content, $comment,$controlNumberLink	VARCHAR	PURCHASE_REQUEST	\N	Email de finalização - Conteúdo.
GNUTECA3	EMAIL_PURCHASE_REQUEST_INITIALIZE_SUBJECT	Confirmação de solicitação de compra	Define o sufixo do assunto do email de inicio da solicitação de compra	VARCHAR	PURCHASE_REQUEST	\N	Email de inicio - Assunto 
GNUTECA3	EMAIL_PURCHASE_REQUEST_INITIALIZE_CONTENT	Prezado $username $LN\n$LN\nRecebemos a solicitação de compra de número $purchaseRequestId:$LN\n$LN\nDetalhes do material:$LN\n$LN\n$content$LN\n$LN\nAtenciosamente.$LN\n$LN\nBiblioteca.$LN	Conteúdo do email de aviso de aprovação de solicitação de material. Variáveis: $username, $purchaseRequestId, $content	VARCHAR	PURCHASE_REQUEST	\N	Email de aprovação - Conteúdo.
GNUTECA3	GNUTECA_USER_MENU_LIST	Renovar; javascript:miolo.doAjax('subForm','MyRenew','__mainForm'); renew-16x16.png \nMinhas reservas; javascript:miolo.doAjax('subForm','MyReservesSearch','__mainForm'); reserve-16x16.png \nCongelados; javascript:miolo.doAjax('subForm','Congelado', '__mainForm'); congelado-16x16.png \nSugest. de material; javascript:miolo.doAjax('subForm','PurchaseRequestSearch', '__mainForm'); purchaseRequest-16x16.png \nFavoritos; javascript:miolo.doAjax('subForm','Favorite', '__mainForm'); favorites-16x16.png \nÁrea de interesse; javascript:miolo.doAjax('subForm','InterestsArea', '__mainForm'); interestsarea-16x16.png \nConfigurações; javascript:miolo.doAjax('subForm','PersonConfig', '__mainForm');config-16x16.png \nDados pessoais; javascript:miolo.doAjax('subForm','MyInformation', '__mainForm'); gnutecaUserMenuDefault.png \nHist. Empréstimos.; javascript:miolo.doAjax('subForm','MyLoan', '__mainForm'); loan-16x16.png \nHist. Penalidades; javascript:miolo.doAjax('subForm','MyPenalty', '__mainForm'); penalty-16x16.png \nHist. Multas; javascript:miolo.doAjax('subForm','MyFine', '__mainForm'); fine-16x16.png \nHist. Reservas; javascript:miolo.doAjax('subForm','ReservesHistory', '__mainForm'); reserve-16x16.png 	Csv que monta os links para o usermenu da persquisa simples. Separado por linha, depois por ;,	VARCHAR	\N	\N	\N
GNUTECA3	LABEL_PURCHASE_REQUEST_SEARCH	Esta é a lista de suas sugestões de livros.	Label superior da interface de sugestão de livros.	VARCHAR	PURCHASE_REQUEST	\N	Mensagem para pesquisa de sugestão de compra
GNUTECA3	LABEL_PURCHASE_REQUEST	Adicionar uma nova sugestão de livro.	Label superior da interface de sugestão de livros.	VARCHAR	PURCHASE_REQUEST	\N	Mensagem para inserção de sugestão de compra
GNUTECA3	FBN_INTEGRATION	t	Ativa ou desativa integração com Fundação Biblioteca Nacional	BOOLEAN	SEARCH	40	Integração Biblioteca Nacional
GNUTECA3	MARC_SUBJECT_TAG	650.a	Informa a tag de assunto.	VARCHAR	\N	\N	Etiqueta de Assunto
GNUTECA3	MARC_EDITOR_TAG	260.b	Etiqueta de editora 	VARCHAR	\N	\N	Etiqueta Editora
GNUTECA3	MARC_GERAL_NOTE_TAG	500.a	Etiqueta marc de notas gerais	VARCHAR	\N	\N	Etiqueta notas gerais
GNUTECA3	MARC_EXTENSION_TAG	300.a	Etiqueta marc de extensão (normalmente contagem de páginas)	VARCHAR	\N	\N	Etiqueta marc de extensão
GNUTECA3	MARC_LANGUAGE_TAG	041.a	Etiqueta marc de linguagem.	VARCHAR	\N	\N	Etiqueta de linguagem.
GNUTECA3	PERSON_IS_A_OPERATOR	f	Vincula a tela de operadores com as pessoas cadastradas no gnuteca.	BOOLEAN	\N	\N	
GNUTECA3	URL_GNUTECA	http://gnuteca3trunk/	Define a URL do Gnuteca. Esta preferência é utilizada em processos rodados através do MIOLO Console e PHP client.	CHAR	\N	\N	\N
GNUTECA3	SUPRESS_RETURN_MESSAGE	f	Suprime as mensagens "Não há empréstimos em aberto" e "Reserva do exemplar X atendida para o usuário Y" na finalização da circulação de material.	BOOLEAN	\N	\N	\N
GNUTECA3	ISO2709_EXPORT	9	Tags a serem ignoradas na exportação de ISO 2709. \nEx:9,000,040.a Neste exemplo, serão ignoradas todas as tags que começam com 9, como (901.a, 901.b, ...), também serão ignoradas as tags 000 e 040.a. \nOs valores devem ser separadas por "","".	VARCHAR	CATALOG	\N	\N
GNUTECA3	ISO2709_IMPORT	001	Tags a serem ignoradas na importação de ISO 2709. \nEx:9,000,040.a Neste exemplo, serão ignoradas todas as tags que começam com 9, como (901.a, 901.b, ...), também serão ignoradas as tags 000 e 040.a.\nOs valores devem ser separadas por "","".	VARCHAR	CATALOG	\N	\N
GNUTECA3	SIMPLE_SEARCH_SHOW_RELATED_TERMS	t	Ativa/desativa dica de pesquisa.	BOOLEAN	\N	\N	\N
GNUTECA3	Z3950_SERVER_URL	127.0.0.1:9999	Define a url do servidor Z3950, por padrão o gnuteca somente suporta o servidor Zebra. Deixe vazio ou remova a preferência para desativar a integração. Ex.127.0.0.1:9999	VARCHAR	Z3950	\N	Url do servidor Z3950
GNUTECA3	Z3950_SERVER_USER	admin	Define senha do servidor Z3950.	VARCHAR	Z3950	\N	Usuário do servidor
GNUTECA3	Z3950_SERVER_PASSWORD	123	Define senha para funções extendidas ( insert/update/delete ) do servidor Z3950.	VARCHAR	Z3950	\N	Senha do servidor
GNUTECA3	SOCIAL_CONTENT	\n<script type="text/javascript" src="//platform.twitter.com/widgets.js"></script>\n<script type="text/javascript" src="https://apis.google.com/js/plusone.js"></script>\n\n<iframe src="//www.facebook.com/plugins/like.php?href="$href"&send=false&layout=button_count&width=80&show_faces=false&action=like&colorscheme=light&font&height=21" scrolling="no" frameborder="0" style="border:none; overflow:hidden; width:80px; height:21px;" allowTransparency="true"></iframe>\n\n<a href="https://twitter.com/share?url=$href&text=Gostei do livro $245.a - $100.a" target="_blank" class="twitter-share-button" data-count="horizontal">Tweet</a>\n\n<g:plusone width="55" height="20" href="$href"></g:plusone>\n	Conteúdo de integração com redes sociais. Usado para cada material utilize $href onde quiser colocar o link do material. Conteúdo html.	VARCHAR	SEARCH	\N	Conteúdo de integração com redes sociais.
GNUTECA3	SOCIAL_INTEGRATION	t	Ativa ou desativa integração com redes sociais.	VARCHAR	SEARCH	\N	Integração com redes sociais.
GNUTECA3	LABEL_MYLIBRARY	<CENTER><B>Lista informações relevantes para o usuário</CENTER></B><BR>	Lista informações relevantes para o usuário	VARCHAR	MY_LIBRARY	\N	Mensagem para minha biblioteca
GNUTECA3	MARC21_REPLACE_VALUES	\t= LDR=000\nLEADER=000\nLÍDER=000\n#-!@#= 	Substitui valores na importação de Marc 21. \nModo de usar: valor original=valor novo\nNovos valores devem ser separados por quebra de linha.\nExemplo: \n\t= \nLDR=000\nLEADER=000\nLÍDER=000 	VARCHAR	\N	\N	\N
GNUTECA3	SEARCH_THEME_TOP	<img style="margin-top: 15px; margin-left: 15px; margin-right: 20px; float:left; " src="file.php?folder=images&amp;file=logo.png">\n<div style="font-size: 26px; margin-top: 20px; color: darkBlue; font-weight: bold; ">Gnuteca</div>\n<span style="font-weight: bold;">Sistema de gestão de acervo, empréstimo <br/>e colaboração entre bibliotecas</span>	Conteúdo mostrado no topo da pesquisa.	VARCHAR	SEARCH	\N	Conteúdo do topo da pesquisa.
\.


--
-- Data for Name: basdocument; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY basdocument (personid, documenttypeid, content, organ, dateexpedition, observation) FROM stdin;
\.


--
-- Data for Name: baslink; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY baslink (linkid, description, level, isvisibletoperson, isoperator) FROM stdin;
\.


--
-- Data for Name: basperson; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY basperson (personid, name, city, zipcode, location, number, complement, neighborhood, email, password, login, baseldap, persongroup, sex, datebirth, school, profession, workplace, observation) FROM stdin;
\.


--
-- Data for Name: baspersonlink; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY baspersonlink (personid, linkid, datevalidate) FROM stdin;
\.


--
-- Data for Name: baspersonoperationprocess; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY baspersonoperationprocess (personid, operationprocess) FROM stdin;
\.


--
-- Data for Name: basphone; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY basphone (personid, type, phone) FROM stdin;
\.


--
-- Data for Name: gtcanalytics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcanalytics (analyticsid, query, action, event, libraryunitid, operator, personid, "time", ip, browser, loglevel, accesstype, menu) FROM stdin;
\.


--
-- Data for Name: gtcassociation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcassociation (associationid, description) FROM stdin;
\.


--
-- Data for Name: gtcbackgroundtasklog; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcbackgroundtasklog (backgroundtasklogid, begindate, enddate, task, label, status, message, operator, args, libraryunitid) FROM stdin;
\.


--
-- Data for Name: gtccataloguingformat; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtccataloguingformat (cataloguingformatid, description, observation) FROM stdin;
1	AACR2	Código de Catalogação Anglo-Americano
\.


--
-- Data for Name: gtcclassificationarea; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcclassificationarea (classificationareaid, areaname, classification, ignoreclassification) FROM stdin;
\.


--
-- Data for Name: gtccontrolfielddetail; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtccontrolfielddetail (controlfielddetailid, fieldid, subfieldid, beginposition, lenght, description, categoryid, marctaglistid, isactive, defaultvalue, emptyvalue) FROM stdin;
1	000	#	0	5	Tamanho do registro	LR	\N	f	\N	00000
2	000	#	5	1	Status do registro	LR	000-05	t	n	#
3	000	#	6	1	Tipo do registro	LR	000-06	t	a	#
4	000	#	7	1	Nível Bibliográfico	LR	000-07	t	m	#
5	000	#	8	1	Tipo de controle	LR	000-08	t	#	#
6	000	#	9	1	Character coding scheme	LR	\N	f	\N	#
7	000	#	10	1	Indicator count	LR	\N	f	\N	2
8	000	#	11	1	Subfield code count	LR	\N	f	\N	2
9	000	#	12	5	Base address of data	LR	\N	f	\N	00000
10	000	#	17	1	Nível de Catalogação	LR	000-17	t	4	4
11	000	#	18	1	Forma de catalogação	LR	000-18	t	#	#
12	000	#	19	1	Ligação de registro	LR	000-19	t	#	#
13	000	#	20	1	Length of the length-of-field portion	LR	\N	f	\N	4
14	000	#	21	1	Length of the starting-character-position	LR	\N	f	\N	5
15	000	#	22	1	Length of the implementation-defined portion	LR	\N	f	\N	0
16	000	#	23	1	Undefined	LR	\N	f	\N	0
17	008	a	0	6	Data de Entrada	BK	\N	t	\N	\N
18	008	a	6	1	Tipo de Data/Status de Publicação	BK	008-06-BK	t	\N	\N
19	008	a	7	4	Data 1	BK	\N	t	\N	\N
20	008	a	11	4	Data 2	BK	\N	t	\N	\N
21	008	a	15	3	Local de publicação	BK	008-15	t	\N	\N
22	008	a	18	1	Ilustração 1	BK	008-18-BK	t	\N	\N
23	008	a	19	1	Ilustração 2	BK	008-18-BK	t	\N	\N
24	008	a	20	1	Ilustração 3	BK	008-18-BK	t	\N	\N
25	008	a	21	1	Ilustração 4	BK	008-18-BK	t	\N	\N
26	008	a	22	1	Publico Alvo	BK	008-22-BK	t	\N	\N
27	008	a	23	1	Forma do Item	BK	008-23-BK	t	\N	\N
28	008	a	24	1	Natureza do conteúdo 1	BK	008-24-BK	t	\N	\N
29	008	a	25	1	Natureza do conteúdo 2	BK	008-24-BK	t	\N	\N
30	008	a	26	1	Natureza do conteúdo 3	BK	008-24-BK	t	\N	\N
31	008	a	27	1	Natureza do conteúdo 4	BK	008-24-BK	t	\N	\N
32	008	a	28	1	Publicação governamental	BK	008-28-BK	t	\N	\N
33	008	a	29	1	Publicação de evento	BK	008-29-BK	t	\N	\N
34	008	a	30	1	Coletânea de homenagem	BK	008-30-BK	t	\N	\N
35	008	a	31	2	Índice	BK	008-31-BK	t	\N	\N
36	008	a	32	1	Undefined	BK	\N	f	\N	\N
37	008	a	33	1	Forma Literária	BK	008-33-BK	t	\N	\N
38	008	a	34	1	Biografia	BK	008-34-BK	t	\N	\N
39	008	a	35	3	Idioma	BK	008-35	t	\N	\N
40	008	a	38	1	Registro modificado	BK	008-38-BK	t	\N	\N
41	008	a	39	1	Fonte da catalogação	BK	008-39-BK	t	\N	\N
42	008	a	0	6	Data de Entrada	SE	\N	t	\N	\N
43	008	a	6	1	Tipo de Data/Status de Publicação	SE	008-06-SE	t	\N	\N
44	008	a	7	4	Data 1	SE	\N	t	\N	\N
45	008	a	11	4	Data 2	SE	\N	t	\N	\N
46	008	a	15	3	Local de publicação	SE	008-15	t	\N	\N
47	008	a	18	1	Frequência	SE	008-18-SE	t	\N	\N
48	008	a	19	1	Regularidade	SE	008-19-SE	t	\N	\N
49	008	a	20	1	Centro que atribui o ISSN	SE	008-20-SE	t	\N	\N
50	008	a	21	1	Tipo de periódico	SE	008-21-SE	t	\N	\N
51	008	a	22	1	Forma do item original	SE	008-22-SE	t	\N	\N
52	008	a	23	1	Forma do item	SE	008-23-SE	t	\N	\N
53	008	a	24	1	Natureza da obra	SE	008-24-SE	t	\N	\N
54	008	a	25	1	Natureza do conteúdo 1	SE	008-25-SE	t	\N	\N
55	008	a	26	1	Natureza do conteúdo 2	SE	008-25-SE	t	\N	\N
56	008	a	27	1	Natureza do conteúdo 3	SE	008-25-SE	t	\N	\N
57	008	a	28	1	Publicação governamental	SE	008-28-SE	t	\N	\N
59	008	a	30	3	Undefined	SE	\N	f	\N	\N
60	008	a	33	1	Alfabeto original ou escrita do título	SE	008-33-SE	t	\N	\N
61	008	a	34	1	Entrada sucessiva/mais recente	SE	008-34-SE	t	\N	\N
62	008	a	35	3	Idioma	SE	008-35	t	\N	\N
63	008	a	38	1	Registro modificado	SE	008-38-SE	t	\N	\N
64	008	a	39	1	Fonte da catalogação	SE	008-39-SE	t	\N	\N
58	008	a	29	4	Publicação de evento	SE	008-29-SE	t	\N	\N
\.


--
-- Data for Name: gtccostcenter; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtccostcenter (costcenterid, libraryunitid, description) FROM stdin;
\.


--
-- Data for Name: gtccutter; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtccutter (abbreviation, code) FROM stdin;
AA	111
AAL	112
AAR	113
AARS	114
AAS	115
ABA	116
ABAL	117
ABAR	118
ABAT	119
ABAU	121
ABB	122
ABBAT	123
ABBE	124
ABBO	125
ABBOT	126
ABBOT, J.	127
ABBOT, M.	128
ABBOT, S.	129
ABBOTT	131
ABBOTT, J.	132
ABBOTT, M.	133
ABBOTT, S.	134
ABD	135
ABDUL	136
ABDY	137
ABE	138
ABEL	139
ABEL, L.	141
ABEN	142
ABER	143
ABERCR	144
ABERD	145
ABERN	146
ABERT	147
ABI	148
ABING	149
ABK	151
ABL	152
ABN	153
ABO	154
ABOU	155
ABOUT	156
ABOV	157
ABR	158
ABRAH	159
ABRAI	161
ABRE	162
ABRI	163
ABRU	164
ABU	165
ABUL	166
ABUR	167
ACA	168
ACC	169
ACCI	171
ACCO	172
ACE	173
ACES	174
ACH	175
ACHAR	176
ACHE	177
ACHI	178
ACHM	179
ACI	181
ACK	182
ACKW	183
ACL	184
ACO	185
ACQ	186
ACR	187
ACT	188
ACU	189
ADA	191
ADAL	192
ADAM	193
ADAMI	198
ADAM, J.	194
ADAM, M.	195
ADAMO	199
ADAMS	211
ADAM, S.	196
ADAMS, F.	212
ADAMS, G.	213
ADAMS, J.	214
ADAMS, M.	215
ADAMS, N.	216
ADAMSON	221
ADAMS, S.	217
ADAMS, T.	218
ADAMS, W.	219
ADAM, W.	197
ADD	222
ADDE	223
ADDI	224
ADDISON	225
ADDISON, M.	226
ADDISON, S.	227
ADE	228
ADELH	229
ADELO	231
ADEN	232
ADET	233
ADH	234
ADI	235
ADK	236
ADL	237
ADM	238
ADO	239
ADOR	241
ADR	242
ADRI	243
ADS	244
ADY	245
AE	246
AEG	247
AEL	248
AEM	249
AEN	251
AER	252
AES	253
AESO	254
AET	255
AFA	256
AFFL	257
AFR	258
AGA	259
AGAR	261
AGAS	262
AGAT	263
AGAY	264
AGE	265
AGG	266
AGI	267
AGIS	268
AGL	269
AGN	271
AGNES	272
AGNEW	273
AGNO	274
AGO	275
AGOU	276
AGR	277
AGRI	278
AGRIP	279
AGRO	281
AGU	282
AGUIL	283
AGUIR	284
AH	285
AHM	286
AHR	287
AI	288
AIG	289
AIK	291
AIKI	292
AIL	293
AIM	294
AIN	295
AINS	296
AINSW	297
AIR	298
AIS	299
AIT	311
AJ	312
AK	313
AKER	314
AKERS	315
AL	316
ALAIN	317
ALAM	318
ALAN	319
ALAR	321
ALARD	322
ALARY	323
ALAV	324
ALB	325
ALBAN	326
ALBAR	327
ALBE	328
ALBER	329
ALBERI	331
ALBERO	332
ALBERT	333
ALBERTI	334
ALBI	335
ALBINI	336
ALBINU	337
ALBIZ	338
ALBO	339
ALBR	341
ALBRI	342
ALBRIZ	343
ALBRO	344
ALBU	345
ALC	346
ALCAN	347
ALCAR	348
ALCAZ	349
ALCE	351
ALCI	352
ALCIP	353
ALCO	354
ALCOT	355
ALCU	356
ALD	357
ALDEN	358
ALDEN, S.	359
ALDER	361
ALDERS	362
ALDI	363
ALDO	364
ALDR	365
ALE	366
ALEM	367
ALEN	368
ALEP	369
ALES	371
ALESSI	372
ALEW	373
ALEX	374
ALEXANDER, C.	375
ALEXANDER, J.	376
ALEXANDER, M.	377
ALEXANDER, S.	378
ALEXANDER, W.	379
ALEXANDRE	381
ALEXANDRE, M.	382
ALEXANDRO	383
ALEXI	384
ALFA	385
ALFE	386
ALFI	387
ALFO	388
ALFORD	389
ALFR	391
ALFRED	392
ALFRI	393
ALG	394
ALGER	395
ALGH	396
ALH	397
ALI	398
ALIF	399
ALIG	411
ALIP	412
ALIS	413
ALISON, M.	414
ALK	415
ALL	416
ALLAN	417
ALLAN, M.	418
ALLARD	419
ALLAS	421
ALLE	422
ALLEIN	423
ALLEM	424
ALLEN	425
ALLEN, H.	426
ALLEN, J.	427
ALLEN, N.	428
ALLENS	433
ALLEN, S.	429
ALLEN, T.	431
ALLEN, W.	432
ALLER	434
ALLEY	435
ALLI	436
ALLING	437
ALLIS	438
ALLISON, M.	439
ALLO	441
ALLS	442
ALLY	443
ALM	444
ALMAN	445
ALMAS	446
ALME	447
ALMEN	448
ALMI	449
ALMO	451
ALMON	452
ALO	453
ALON	454
ALOS	455
ALP	456
ALPI	457
ALQ	458
ALR	459
ALS	461
ALSOP	462
ALSTE	463
ALSTO	464
ALT	465
ALTE	466
ALTH	467
ALTI	468
ALTO	469
ALU	471
ALV	472
ALVARE	473
ALVE	474
ALVI	475
ALVO	476
ALW	477
ALZ	478
AMA	479
AMAD	481
AMAL	482
AMALT	483
AMAN	484
AMAR	485
AMAS	486
AMAT	487
AMATO	488
AMAU	489
AMB	491
AMBI	492
AMBL	493
AMBO	494
AMBR	495
AMBROS	496
AMBU	497
AME	498
AMELO	499
AMEN	511
AMER	512
AMES	513
AMES, M.	514
AMH	515
AMI	516
AMIN	517
AMM	518
AMMIR	519
AMMO	521
AMN	522
AMO	523
AMOR	524
AMOS	525
AMP	526
AMPS	527
AMS	528
AMU	529
AMY	531
ANA	532
ANAM	533
ANAS	534
ANAT	535
ANAX	536
ANB	537
ANC	538
ANCH	539
ANCI	541
ANCO	542
AND	543
ANDERS	544
ANDERSON	545
ANDERSON, D.	546
ANDERSON, J.	547
ANDERSON, M.	548
ANDERSON, R.	549
ANDERSON, T.	551
ANDERSON, W.	552
ANDR	553
ANDRAL	554
ANDRE	555
ANDREA	556
ANDREAS	557
ANDREE	558
ANDREI	559
ANDRES	561
ANDREW	562
ANDREWE	564
ANDREW, M.	563
ANDREWS	565
ANDREWS, E.	566
ANDREWS, J.	567
ANDREWS, M.	568
ANDREWS, R.	569
ANDREWS, T.	571
ANDREWS, W.	572
ANDRI	573
ANDRO	574
ANDRON	575
ANDROS	576
ANDRY	577
ANE	578
ANER	579
ANG	581
ANGELI	582
ANGELL	583
ANGELO	584
ANGELU	585
ANGEN	586
ANGER	587
ANGI	588
ANGL	589
ANGLU	591
ANGO	592
ANGOU	593
ANGU	594
ANGUS	595
ANH	596
ANI	597
ANIM	598
ANIS	599
ANK	611
ANL	612
ANN	613
ANNES	614
ANNI	615
ANQ	616
ANS	617
ANSEL	618
ANSI	619
ANSL	621
ANSO	622
ANSP	623
ANST	624
ANSTEY	625
ANSTI	626
ANT	627
ANTHO	628
ANTI	629
ANTIM	631
ANTIO	632
ANTIP	633
ANTO	634
ANTONI	635
ANTR	636
ANV	637
AO	638
AP	639
APEL	641
API	642
APO	643
APOLLO	644
APOS	645
APP	646
APPI	647
APPL	648
APPLETON	649
APPLETON, J.	651
APPLETON, T.	652
APPU	653
APR	654
APT	655
AQU	656
AQUIN	657
ARA	658
ARAG	659
ARAM	661
ARAN	662
ARAT	663
ARB	664
ARBL	665
ARBO	666
ARBU	667
ARC	668
ARCH	669
ARCHER	671
ARCHER, M.	672
ARCHI	673
ARCI	674
ARCO	675
ARD	676
ARDO	677
ARE	678
AREH	679
AREN	681
ARET	682
ARETIN	683
AREZ	684
ARF	685
ARG	686
ARGEL	687
ARGEN	688
ARGENT	689
ARGENTI	691
ARGI	692
ARGO	693
ARGU	694
ARGY	695
ARI	696
ARIB	697
ARID	698
ARIG	699
ARIN	711
ARIO	712
ARIP	713
ARIS	714
ARISTI	715
ARISTO	716
ARISTOP	717
ARIU	718
ARIZ	719
ARK	721
ARKW	722
ARL	723
ARLING	724
ARLO	725
ARLU	726
ARM	727
ARME	728
ARMI	729
ARMIS	731
ARMIT	732
ARMITAGE, M.	733
ARMS	734
ARMSTRONG	735
ARMSTRONG, J.	736
ARMSTRONG, M.	737
ARMSTRONG, S.	738
ARMSTRONG, W.	739
ARMY	741
ARN	742
ARNAL	743
ARNAU	744
ARNAUL	745
ARNAY	746
ARND	747
ARNE	748
ARNI	749
ARNO	751
ARNOLD	752
ARNOLD, D.	753
ARNOLD, G.	754
ARNOLD, H.	755
ARNOLDI	762
ARNOLD, J.	756
ARNOLD, M.	757
ARNOLD, R.	758
ARNOLD, T.	759
ARNOLD, W.	761
ARNON	763
ARNOT	764
ARNOU	765
ARNOULT	766
ARNS	767
ARNU	768
ARO	769
AROU	771
ARP	772
ARR	773
ARRE	774
ARRI	775
ARRIG	776
ARRIV	777
ARRO	778
ARROWS	779
ARS	781
ARSI	782
ARSL	783
ART	784
ARTAU	785
ARTE	786
ARTH	787
ARTHUR	788
ARTHUR, M.	789
ARTHUR, S.	791
ARTO	792
ARU	793
ARUNT	794
ARV	795
ARW	796
ARZ	797
ASA	798
ASB	799
ASC	811
ASCH	812
ASCHEN	813
ASCL	814
ASCO	815
ASE	816
ASF	817
ASG	818
ASH	819
ASHBU	821
ASHBURT	822
ASHBY	823
ASHE	824
ASHER	825
ASHL	826
ASHM	827
ASHT	828
ASHTON, M.	829
ASHW	831
ASI	832
ASIO	833
ASK	834
ASKEW	835
ASM	836
ASO	837
ASP	838
ASPER	839
ASPI	841
ASPL	842
ASPR	843
ASS	844
ASSEN	845
ASSER	846
ASSH	847
ASSI	848
ASSO	849
ASSU	851
AST	852
ASTE	853
ASTI	854
ASTL	855
ASTO	856
ASTON, M.	857
ASTOR	858
ASTR	859
ASU	861
ATA	862
ATCH	863
ATE	864
ATH	865
ATHE	866
ATHEN	867
ATHER	868
ATHERTON, M.	869
ATHI	871
ATI	872
ATK	873
ATKINS, M.	874
ATKINSON	875
ATKINSON, J.	876
ATKINSON, M.	877
ATKINSON, T.	878
ATKY	879
ATL	881
ATR	882
ATT	883
ATTER	884
ATTI	885
ATTW	886
ATW	887
AUB	888
AUBERT	889
AUBERY	891
AUBES	892
AUBI	893
AUBIN	894
AUBR	895
AUBRY	896
AUBU	897
AUC	898
AUD	899
AUDI	911
AUDIN	912
AUDL	913
AUDO	914
AUDR	915
AUDU	916
AUE	917
AUF	918
AUG	919
AUGI	921
AUGU	922
AUGUS	923
AUL	924
AUM	925
AUN	926
AUR	927
AURI	928
AURIV	929
AURO	931
AUS	932
AUSTEN	933
AUSTEN, M.	934
AUSTIN	935
AUSTIN, J.	936
AUSTIN, M.	937
AUSTIN, T.	938
AUT	939
AUTR	941
AUV	942
AUX	943
AUZ	944
AVA	945
AVAN	946
AVAU	947
AVE	948
AVELL	949
AVEN	951
AVER	952
AVERO	953
AVERY	954
AVERY, M.	955
AVEZ	956
AVI	957
AVIL	958
AVIT	959
AVO	961
AVOS	962
AVR	963
AWA	964
AWB	965
AWD	966
AWI	967
AX	968
AXEL	969
AXO	971
AXT	972
AYA	973
AYC	974
AYD	975
AYE	976
AYERS	977
AYL	978
AYLM	979
AYLW	981
AYM	982
AYN	983
AYR	984
AYRES	985
AYRT	986
AYS	987
AYT	988
AYTON	989
AZA	991
AZAR	992
AZE	993
AZEV	994
AZI	995
AZO	996
AZR	997
AZY	998
AZZ	999
BA	111
BAB	112
BABE	113
BABI	114
BABR	115
BAC	116
BACCI	117
BACH	118
BACHE	110
BACHELL	121
BACHET	122
BACHI	123
BACHM	124
BACI	125
BACK	126
BACM	127
BACO	128
BACON M.	129
BACR	131
BAD	132
BADE	133
BADEN	134
BADG	135
BADI	136
BADO	137
BADR	138
BAE	139
BAER	141
BAERT	142
BAF	143
BAG	144
BAGI	145
BAGL	146
BAGN	147
BAGO	148
BAGS	149
BAH	151
BAI	152
BAIL	153
BAILE	154
BAILEY, L.	155
BAILEY, S.	156
BAILL	157
BAILLO	158
BAILS	159
BAILY	161
BAIN	162
BAIR	163
BAIT	164
BAJ	165
BAK	166
BAKE	167
BAKER, M.	168
BAKS	169
BAL	171
BALB	172
BALBO	173
BALC	174
BALD	175
BALDER	176
BALDI	177
BALDO	178
BALDU	179
BALDW	181
BALDWIN, M.	182
BALE	183
BALES	184
BALF	185
BALI	186
BALL	187
BALLA	188
BALLAR	189
BALLE	191
BALLI	192
BALLO	193
BALM	194
BALO	195
BALS	196
BALT	197
BALU	198
BAM	199
BAMP	211
BAN	212
BANC	213
BAND	214
BANE	215
BANG	216
BANI	217
BANK	218
BANN	219
BAO	221
BAP	222
BAR	223
BARAG	224
BARAN	225
BARAT	226
BARAU	227
BARB	228
BARBAR	229
BARBAT	231
BARBAU	232
BARBE	233
BARBER	234
BARBET	235
BARBI	236
BARBIL	237
BARBO	238
BARBOU	239
BARBU	241
BARC	242
BARCH	243
BARCL	244
BARD	245
BARDI	246
BARDO	247
BARE	248
BARF	249
BARG	251
BARI	252
BARIN	253
BARK	254
BARKER	255
BARKI	256
BARL	257
BARLETT, M.	291
BARLO	258
BARN	259
BARNES	261
BARNH	262
BARNU	263
BARO	264
BARON	265
BARONI	266
BAROT	267
BARR	268
BARRAS	269
BARRE	271
BARRER	272
BARRET	273
BARRETT	274
BARRI	275
BARRIN	276
BARRO	277
BARROW	278
BARRY	279
BARRY, L.	281
BARS	282
BART	283
BARTH	284
BARTHEL	285
BARTHO	286
BARTHOLO	287
BARTI	288
BARTL	280
BARTO	292
BARTON	293
BARTR	294
BARU	295
BARW	296
BAS	297
BASC	298
BASE	299
BASI	311
BASILI	312
BASIN	313
BASIR	314
BASK	315
BASN	316
BASS	317
BASSE	318
BASSET	319
BASSI	321
BASSO	322
BASSU	323
BAST	324
BASTE	325
BASTI	326
BASTO	327
BAT	328
BATES	329
BATH	331
BATHU	332
BATI	333
BATO	334
BATT	335
BATTI	336
BAU	337
BAUD	338
BAUDIO	339
BAUDO	341
BAUDR	342
BAUDU	343
BAUE	344
BAUF	345
BAUG	346
BAUM	347
BAUMG	348
BAUN	349
BAUR	351
BAUT	352
BAV	353
BAVI	354
BAX	355
BAY	356
BAYE	357
BAYL	358
BAYLY	359
BAYN	361
BAZ	362
BAZI	363
BAZO	364
BE	365
BEAL	366
BEAN	367
BEAR	368
BEAT	369
BEAU	371
BEAUCH	372
BEAUCL	373
BEAUF	374
BEAUG	375
BEAUH	376
BEAUL	377
BEAUM	378
BEAUMO	379
BEAUN	381
BEAUP	382
BEAUR	383
BEAUS	384
BEAUV	385
BEAUVO	386
BEB	387
BEC	388
BECE	389
BECH	391
BECHS	392
BECK	393
FI	438
BECKE	394
BECKER	395
BECKER, P.	396
BECKI	397
BECM	398
BED	399
BEDE	411
BEDI	412
BEDR	413
BEE	414
BEER	415
BEG	416
BEGI	417
BEGU	418
BEH	419
BEHR	421
BEI	422
BEIS	423
BEK	424
BEL	425
BELAN	426
BELCH	427
BELE	428
BELG	429
BELI	431
BELK	432
BELL	433
BELLAN	436
BELLAV	437
BELLE	438
BELLEG	439
BELLEN	441
BELLER	442
BELLI	443
BELLIN	444
BELL, L.	434
BELLM	445
BELLO	446
BELLON	447
BELLOW	448
BELL, R.	435
BELLU	449
BELM	451
BELO	452
BELT	453
BELV	454
BEM	110
BEN	456
BENC	457
BEND	458
BENDO	459
BENE	461
BENEDE	462
BENEDI	463
BENEF	464
BENEL	465
BENG	466
BENI	467
BENJ	468
BENN	469
BENNET	471
BENNET, M.	472
BENO	473
BENS	474
BENT	475
BENTH	476
BENTL	477
BENTO	478
BENW	479
BEO	481
BER	482
BERAR	483
BERAU	484
BERC	485
BERCK	486
BERE	487
BEREN	488
BERENS	489
BERES	491
BERET	492
BERG	493
BERGAN	494
BERGE	495
BERGER	496
BERGH	497
BERGI	498
BERGM	499
BERI	511
BERK	512
BERKL	513
BERL	514
BERLIN	515
BERM	516
BERN	517
BERNAR	518
BERNARDI	523
BERNARD, J.	519
BERNARD, M.	521
BERNARD, T.	522
BERNAT	524
BERNE	525
BERNET	526
BERNH	527
BERNI	528
BERNO	529
BERNS	531
BERO	532
BERR	533
BERRY	534
BERS	535
BERT	536
BERTE	537
BERTH	538
BERTHE	539
BERTHI	541
BERTHO	542
BERTI	543
BERTIN	544
BERTO	545
BERTOL	546
BERTON	547
BERTR	548
BERTRAND, F.	549
BERTRAND, N.	551
BERTU	552
BERW	553
BES	554
BESL	555
BESO	556
BESS	557
BESSEM	558
BESSI	559
BEST	561
BET	562
BETHM	563
BETO	564
BETT	565
BEU	566
BEUL	567
BEUS	568
BEUT	569
BEV	571
BEW	572
BEY	573
BEZ	574
BH	575
BI	576
BIAN	577
BIANCO	578
BIAR	579
BIB	581
BIBL	582
BIC	583
BID	584
BIDE	585
BIE	586
BIEL	587
BIEN	588
BIES	589
BIF	591
BIG	592
BIGL	593
BIGO	594
BIL	595
BILL	596
BILLE	597
BILLI	598
BILLO	599
BIM	611
BIN	612
BING	613
BINN	614
BIO	615
BIOR	616
BIR	617
BIRD	618
BIRK	619
BIS	621
BISH	622
BISS	623
BIT	624
BIZ	625
BJ	626
BL	627
BLACKB	628
BLACKM	629
BLACKS	631
BLACKW	632
BLAG	633
BLAI	634
BLAIR	635
GUI	943
BLAK	636
BLAKES	637
BLAN	638
BLANCH	639
BLANCHE	641
BLAND	642
BLANQ	643
BLAS	644
BLAU	645
BLE	646
BLEN	647
BLI	648
BLIS	649
BLO	651
BLOD	652
BLOM	653
BLON	654
BLOO	655
BLOS	656
BLOU	657
BLU	658
BLUNT	659
BLY	661
BO	662
BOB	663
BOC	664
BOCK	665
BOD	666
BODI	667
BODL	668
BOE	669
BOEH	671
BOER	672
BOET	673
BOG	674
BOGI	675
BOH	676
BOHN	677
BOI	678
BOIL	679
BOIN	681
BOIS	682
BOISG	683
BOISS	684
BOIT	685
BOK	686
BOL	687
BOLE	688
BOLI	689
BOLL	691
BOLLI	692
BOLO	693
BOLT	694
BOM	695
BOMI	696
BON	697
BONAP	698
BONAR	699
BOND	711
BONE	712
BONF	713
BONH	714
BONI	715
BONN	716
BONNET	717
BONNI	718
BONO	719
BONS	721
BONT	722
BONV	723
BOO	724
BOOT	725
BOR	726
BORD	727
BORDEN	728
BORDI	729
BORE	731
BORG	732
BORGI	733
BORGO	734
BORL	735
BORN	736
BORR	737
BORS	738
BORT	739
BOS	741
BOSCH	742
BOSE	743
BOSO	744
BOSS	745
BOSSU	746
BOST	747
BOT	748
BOTH	749
BOTT	751
BOU	752
BOUCHE	753
BOUCHI	754
BOUCHO	755
BOUD	756
BOUF	757
BOUG	758
BOUH	759
BOUI	761
BOUIL	762
BOUL	763
BOULL	764
BOUN	765
BOUR	766
BOURC	767
BOURD	768
BOURDI	769
BOURE	771
BOURG	772
BOURGO	773
BOURI	774
BOURN	775
BOURR	776
BOUS	777
BOUT	778
BOUTH	779
BOUTO	781
BOUV	782
BOV	783
BOW	784
BOWDI	785
BOWE	786
BOWL	787
BOWR	788
BOY	789
BOYE	791
BOYL	792
BOYS	793
BR	794
BRAB	795
BRAC	796
BRACK	797
BRAD	798
BRADF	799
BRADL	811
BRADS	812
BRAG	813
BRAI	814
BRAM	815
BRAN	816
BRAND	817
BRANDI	818
BRANDO	819
BRANDT	821
BRAR	822
BRAS	823
BRAT	824
BRAU	825
BRAV	826
BRAY	827
BRE	828
BREC	829
BRED	831
BREE	832
BREG	833
BREH	834
BREI	835
BREM	836
BREN	837
BRENN	838
BRENT	839
BRER	841
BRES	842
BRESS	843
BRET	844
BRETT	845
BREU	846
BREW	847
BREWS	848
BRI	849
BRID	851
BRIDGM	852
BRIE	853
BRIG	854
BRIGH	855
BRIGHTO	856
BRIL	857
BRIN	858
BRIS	859
BRIST	861
BRIT	862
BRO	863
BROCK	864
BROE	865
BROG	866
LYL	985
BROK	867
BROM	868
BRON	869
BROO	871
BROOKE	872
BROOKS	873
BROS	874
BROU	875
BROUS	876
BROW	877
BROWNE	882
BROWNE, M.	883
BROWNE, S.	884
BROWN, H.	878
BROWNI	885
BROWN, M.	879
BROWN, T.	881
BRU	886
BRUCE, J.	887
BRUCK	888
BRUE	889
BRUG	891
BRUH	892
BRUM	893
BRUNET	894
BRUNI	895
BRUNN	896
BRUNO	898
BRUNS	899
BRUNSW	911
BRUS	912
BRUT	913
BRUY	914
BRY	915
BRYC	916
BU	917
BUC	918
BUCHE	919
BUCHO	921
BUCK	922
BUCKI	923
BUCKL	924
BUCKM	925
BUCKS	926
BUD	927
BUE	928
BUF	929
BUG	931
BUI	932
BUL	933
BULK	934
BULL	935
BULLE	936
BULLI	937
BULLO	938
BULO	939
BULW	941
BUN	942
BUO	943
BUONI	944
BUR	945
BURB	946
BURC	947
BURCK	948
BURD	949
BURDET	951
BURE	952
BURF	953
BURG	954
BURGES	955
BURGH	956
BURGO	957
BURH	958
BURK	959
BURL	961
BURM	962
BURN	963
BURNET	964
BURNEY	965
BURNH	966
BURNS	967
BURR	968
BURRE	969
BURRI	971
BURRO	972
BURT	973
BURTO	974
BURY	975
BUS	976
BUSCH	977
BUSH	978
BUSHN	979
BUSS	981
BUST	982
BUT	983
BUTI	984
BUTL	985
BUTLER, M.	986
BUTLER, T.	987
BUTT	988
BUTTO	989
BUX	991
BUY	992
BY	993
BYN	994
BYR	995
BYRO	996
BYS	997
BYT	998
BZ	999
CA	111
CAB	112
CABAS	113
CABE	114
CABI	115
CABO	116
CABR	117
CAC	118
CACH	110
CAD	121
CADE	122
CADET	123
CADI	124
CADO	125
CADR	126
CAE	127
CAES	128
CAF	129
CAG	131
CAH	132
CAI	133
CAIL	134
CAIN	135
CAIR	136
CAIS	137
CAIU	138
CAJ	139
CAL	141
CALAN	142
CALAS	143
CALC	144
CALD	145
CALDE	146
CALDW	147
CALE	148
CALEN	149
CALF	151
CALH	152
CALI	153
CALIN	154
CALK	155
CALL	156
CALLE	157
CALLI	158
CALLIM	159
CALLIN	161
CALLIS	162
CALLO	163
CALM	164
CALO	165
CALT	166
CALV	167
CALVI	168
CALVO	169
CALZ	171
CAM	172
CAMAS	173
CAMB	174
CAMBI	175
CAMBO	176
CAMBR	177
CAMBRI	178
CAMD	179
CAME	181
CAMER	182
CAMI	183
CAMM	184
CAMO	185
CAMP	186
CAMPBELL	187
CAMPBELL, H.	188
CAMPBELL, M.	189
CAMPBELL, S.	191
CAMPBELL, W.	192
CAMPE	193
CAMPEN	194
CAMPER	195
CAMPI	196
CAMPIS	197
CAMPO	198
CAMPR	199
CAMU	211
CAN	212
CANAN	213
CANB	214
CANC	215
CAND	216
CANDI	217
CANDL	218
CANDO	219
CANE	221
CANF	222
CANI	223
CANN	224
CANNI	225
CANNO	226
CANO	227
CANS	228
CANT	229
CANTI	231
CANTO	232
CANTR	233
CANTW	234
CANU	235
CAP	236
CAPE	237
CAPEL	238
CAPEN	239
CAPET	241
CAPG	242
CAPI	243
CAPIT	244
CAPO	245
CAPON	246
CAPP	247
CAPPER	248
CAPPO	249
CAPR	251
CAPRE	252
CAPRI	253
CAPRO	254
CAPU	255
CAQ	256
CAR	257
CARAF	258
CARAM	259
CARAN	261
CARAT	262
CARB	263
CARBO	264
CARC	265
CARD	266
CARDI	267
CARDO	268
CARDW	269
CARE	271
CAREW	272
CAREY	273
CAREY, H.	274
CAREY, M.	275
CAREY, S.	276
CARI	277
CARL	278
CARLET	279
CARLETON	281
CARLI	282
CARLIS	283
CARLO	284
CARLT	285
CARLY	286
CARM	287
CARN	288
CARNE	280
CARNO	291
CARO	292
CARON	293
CARP	294
CARPENTER	295
CARPENTER, L.	296
CARPENTER, S.	297
CARPI	298
CARPO	299
CARR	311
CARRAR	313
CARRE	314
CARRET	315
CARRI	316
CARRIL	317
CARRIN	318
CARR, M.	312
CARRO	319
CARS	321
CART	322
CARTER	323
CARTER, L.	324
CARTER, S.	325
CARTH	326
CARTI	327
CARTO	328
CARTW	329
CARV	331
CARY	332
CARY, M.	333
CAS	334
CASAN	335
CASAT	336
CASE	337
CASEN	338
CASI	339
CASO	341
CASP	342
CASS	343
CASSE	344
CASSI	345
CAST	346
CASTE	347
CASTEL	348
CASTELN	348
CASTI	351
CASTIL	352
CASTL	353
CASTO	354
CASTR	355
CASW	356
CAT	357
CATEL	358
CATEN	359
CATH	361
CATHC	362
CATHE	363
CATI	364
CATL	365
CATO	366
CATR	367
CATT	368
CATTO	369
CAU	371
CAUL	372
CAUM	373
CAUS	374
CAUT	375
CAV	376
CAVALL	377
CAVE	378
CAVEN	379
CAVENDISH, L.	381
CAVI	382
CAVO	383
CAX	384
CAY	385
CAZ	386
CE	387
CECI	388
CED	389
CEI	391
CEL	392
CELL	393
CELS	394
CEN	395
CENS	396
CENT	397
CEO	398
CEP	399
CER	411
CERC	412
CERD	413
CERE	414
CERI	415
CERO	416
CERR	417
CERT	418
CERV	419
CES	421
CESO	422
CET	423
CEV	424
CEY	425
CH	426
CHABE	427
CHABO	428
CHABR	429
CHAC	431
CHAD	432
CHAF	433
CHAI	434
CHAIS	435
CHAL	436
CHALL	437
CHALM	438
CHALO	439
CHALT	441
CHAM	442
CHAMBER	443
CHAMBERS	444
CHAMBERS, M.	445
CHAMBO	446
CHAMBR	447
CHAMI	448
CHAMP	449
CHAMPE	451
CHAMPI	452
CHAMPL	453
CHAN	454
CHANDL	455
CHANDLER, M.	456
CHANL	457
CHANN	458
CHANT	459
CHAO	461
CHAP	462
CHAPI	463
CHAPL	464
CHAPM	465
CHAPMAN	466
CHAPP	467
CHAPU	468
CHAR	469
CHARD	471
CHARE	472
CHARI	473
CHARL	474
CHARLES	475
CHARLES, M.	476
CHARLES, S.	477
CHARLET	478
CHARLO	479
CHARLT	481
CHARM	482
CHARN	483
CHARP	484
CHARR	485
CHART	486
CHAS	487
CHASS	488
CHAST	489
CHASTIL	491
CHAT	492
CHATH	493
CHATI	494
CHATT	495
CHAU	496
CHAUL	497
CHAUN	498
CHAUS	499
CHAUV	511
CHAV	512
CHAZ	513
CHE	514
CHEE	515
CHEL	516
CHEM	517
CHEN	518
CHEP	519
CHER	521
CHERO	522
CHERU	523
CHES	524
CHEST	525
CHET	526
CHEV	527
CHEVI	528
CHEVR	529
CHEY	531
CHI	532
CHICH	533
CHIF	534
CHIL	535
CHILD	536
CHILDS	537
CHILL	538
CHIN	539
CHIP	541
CHIS	542
CHIT	543
CHLA	544
CHO	545
CHOIS	546
CHOL	547
CHOM	548
CHOP	549
CHOR	551
CHOU	552
CHR	553
CHRI	554
CHRISTI	555
CHRISTO	556
CHRO	557
CHRY	558
CHU	559
CHURCH	561
CHURCHILL	563
CHURCH, M.	562
CHUT	564
CI	565
CIAN	566
CIB	567
CIC	568
CIE	569
CIG	571
CIL	572
CIM	573
CIN	574
CINI	575
CIO	576
CIP	577
CIR	578
CIS	579
CIT	581
CIV	582
CL	583
CLAG	584
CLAI	585
CLAM	586
CLAN	587
CLAP	588
CLAPP	589
CLAR	591
CLARK	592
CLARKE	597
CLARKE, G.	598
CLARKE, M.	599
CLARKE, S.	611
CLARKE, W.	612
CLARK, G.	593
CLARK, M.	594
CLARKS	613
CLARK, S.	595
CLARK, W.	596
CLARY	614
CLAU	615
CLAUS	616
CLAV	617
CLAX	618
CLAY	619
CLAY, M.	621
CLAY, T.	622
CLE	623
CLEE	624
CLEM	625
CLEMENT	626
CLEN	627
CLEO	628
CLER	629
CLERK	631
CLERKE	632
CLERM	633
CLES	634
CLEV	635
CLI	636
CLIFFORD, M.	638
CLIFT	639
CLIN	641
CLIV	642
CLO	643
CLON	644
CLOS	645
CLOT	646
CLOU	647
CLOW	648
CLU	649
CN	651
CO	652
COBB	653
COBBET	654
COBD	655
COBH	656
COBO	657
COBU	658
COC	659
COCH	661
COCHIN	662
COCHR	663
COCK	664
COCKB	665
COCKE	666
COCO	667
COCQ	668
COD	669
CODM	671
COE	672
COES	673
COF	674
COFFIN	675
COG	676
COGS	677
COH	678
COIG	679
COIT	681
COK	682
COL	683
COLB	684
COLBU	685
COLBY	686
COLC	687
COLD	688
COLE	689
COLEB	691
COLEM	692
COLER	693
COLET	694
COLEV	695
COLI	696
COLL	697
COLLET	698
COLLI	699
COLLING	711
COLLINS	712
COLLINS, S.	713
COLLO	714
COLLY	715
COLM	716
COLN	717
COLO	718
COLON	719
COLP	721
COLQ	722
COLS	723
COLT	724
COLTO	725
COLU	726
COLV	727
COM	728
COMB	729
COMBES	731
COME	732
COMI	733
COMM	734
COMO	735
COMP	736
COMPAN	737
COMPT	738
COMS	739
COMT	741
COMY	742
CON	743
CONC	744
COND	745
CONDO	746
CONE	747
CONF	748
CONG	749
CONI	751
CONK	752
CONO	753
CONR	754
CONS	755
CONST	756
CONSTAN	757
CONSTANTI	758
CONT	759
CONTE	761
CONTI	762
CONTO	763
CONTR	764
CONTU	765
CONV	766
CONW	767
CONY	768
COO	769
COOK	771
COOKE	772
COOKE, M.	773
COOL	774
COOM	775
COOP	776
COOPER, H.	777
COOPER, O.	778
COOT	779
COP	781
COPE	782
COPI	783
COPL	784
COPP	785
COQ	786
COR	787
CORAN	788
CORB	789
CORBIN	791
CORBO	792
CORC	793
CORD	794
CORDI	795
CORDO	796
CORE	797
CORI	798
CORK	799
CORM	811
CORN	812
CORNE	813
CORNEL	814
CORNER	815
CORNET	816
CORNH	817
CORNI	818
CORNO	819
CORNW	821
CORO	822
CORR	823
CORRE	824
CORRI	825
CORS	826
CORT	827
CORTES	828
CORTI	829
CORTO	831
CORV	832
CORY	833
COS	834
COSP	835
COSS	836
COST	837
COSTAN	838
COSTE	839
COSTEL	841
COSTER	842
COT	843
COTI	844
COTO	845
COTT	846
COTTER	847
COTTI	848
COTTL	849
COTTO	851
COTY	852
COU	853
COUD	854
COUL	855
COUP	856
COUPL	857
COUR	858
COURC	859
COURL	861
COURT	862
COURTE	863
COURTI	864
COURTN	865
COURTO	866
COUS	867
COUSS	868
COUST	869
COUT	871
COUTU	872
COV	873
COW	874
COWL	875
COWP	876
COX	877
COXE	879
COX, R.	878
COY	881
COZ	882
CR	883
CRAD	884
CRAF	885
CRAI	886
CRAIK	887
CRAK	888
CRAM	889
CRAN	891
CRAO	892
CRAP	893
CRAS	894
CRAT	895
CRATO	896
CRAU	897
CRAV	898
CRAW	899
CRAWL	911
CRE	912
CREE	913
CREI	914
CREL	915
CREO	916
CREP	917
CREQ	918
CRES	919
CRESP	921
CRESS	922
CRESW	923
CRET	924
CREU	925
CREV	926
CREW	927
CRI	928
CRIL	929
CRIN	931
CRIS	932
CRIST	933
CRIT	934
CRITT	935
CRIV	936
CRO	937
CROCK	938
CROE	939
CROF	941
CROI	942
CROK	943
CROL	944
CROM	945
CROMW	946
CRON	947
CROO	948
CROS	949
CROSS	951
CROU	952
CROW	953
CROY	954
CRU	955
CRUM	956
CRUS	957
CS	958
CT	959
CU	961
CUB	962
CUC	963
CUD	964
CUE	965
CUI	966
CUL	967
CULP	968
CUM	969
CUMM	971
CUN	972
CUNN	973
CUP	974
CUR	975
CURR	976
CURS	977
CURT	978
CURTIS, J.	979
CURTIS, P.	981
CURW	982
CURZ	983
CUS	984
CUSHING, M.	985
CUSHM	986
CUST	987
CUT	988
CUTL	989
CUTT	991
CUV	992
CUY	993
CY	994
CYC	995
CYL	996
CYR	997
CZ	998
CZO	999
DA	111
DABI	112
DABL	113
DABN	114
DABO	115
DABR	116
DAC	117
DACI	118
DACR	119
DAD	121
DAE	122
DAEL	123
DAF	124
DAG	125
DAGL	126
DAGO	127
DAGU	128
DAH	129
DAHL	131
DAI	132
DAIL	133
DAIR	134
DAK	135
DAL	136
DALB	137
DALC	138
DALE	139
DALES	141
DALG	142
DALH	143
DALL	144
DALLAS	145
DALLE	146
DALLI	147
DALM	148
DALP	149
DALR	151
DALT	152
DALY	153
DAM	154
DAMAS	155
DAMB	156
DAME	157
DAMI	158
DAMIN	159
DAMIS	161
DAMM	162
DAMO	163
DAMOP	164
DAMP	165
DAMPI	166
DAN	167
DANA, H.	168
DANA, M.	169
DANA, S.	171
DANB	172
DANC	173
DANCK	174
DANCO	175
DAND	176
DANDO	177
DANDR	178
DANE	179
DANF	181
DANG	182
DANI	183
DANIEL	184
DANIELL	185
DANIELS	186
DANK	187
DANN	188
DANP	189
DANS	191
DANT	192
DANTI	193
DANTO	194
DANTZ	195
DANV	196
DANVI	197
DANY	198
DANZ	199
DAO	211
DAP	212
DAR	213
DARC	214
DARD	215
DARDE	216
DARE	217
DARI	218
DARK	219
DARL	221
DARM	222
DARN	223
DARO	224
DARR	225
DART	226
DARU	227
DARW	228
DAS	229
DASS	231
DAT	232
DATH	233
DATI	234
DAU	235
DAUBI	236
DAUC	237
DAUD	238
DAUL	239
DAUM	241
DAUN	242
DAUR	243
DAUS	244
DAV	245
DAVE	246
LYM	986
DAVENP	247
DAVES	248
DAVI	249
DAVIDS	251
DAVIDSON	252
DAVIDSON, M.	253
DAVIE	254
DAVIES	255
DAVIES, J.	256
DAVIES, P.	257
DAVIG	258
DAVIL	259
DAVIS	261
DAVIS, H.	262
DAVIS, M.	263
DAVIS, S.	264
DAVIS, W.	265
DAVO	266
DAVR	267
DAVY	268
DAW	269
DAWK	271
DAWS	272
DAY	273
DAY, J.	274
DAY, S.	275
DAYT	276
DAZ	277
DE	278
DEAL	279
DEAN	281
DEANE	283
DEANE, M.	284
DEAN, M.	282
DEAR	285
DEB	286
DEBO	287
DEBR	288
DEBU	289
DEC	291
DECE	292
DECH	293
DECI	294
DECK	295
DECO	296
DECOUR	297
DECR	298
DED	299
DEE	311
DEER	312
DEF	313
DEFO	314
DEFOR	315
DEFR	316
DEG	317
DEGL	318
DEGO	319
DEGR	321
DEH	322
DEHO	323
DEI	324
DEIS	325
DEJ	326
DEJO	327
DEK	328
DEKR	329
DEL	331
DELAC	332
DELAF	333
DELAI	334
DELAL	335
DELAM	336
DELAN	337
DELAP	338
DELAR	339
DELAT	341
DELAU	342
DELAV	343
DELB	344
DELC	345
DELE	346
DELES	347
DELEU	348
DELF	349
DELFO	351
DELG	352
DELI	353
DELIS	354
DELIU	355
DELK	356
DELL	357
DELLO	358
DELM	359
DELO	361
DELOR	362
DELP	363
DELR	364
DELS	365
DELT	366
DELV	367
DELZ	368
DEM	369
DEMAN	371
DEMAR	372
DEMAU	373
DEMB	374
DEMBO	375
DEME	376
DEMET	377
DEMI	378
DEMID	378
DEMIL	381
DEMM	382
DEMO	383
DEMON	384
DEMOP	385
DEMOR	386
DEMOS	387
DEMOU	388
DEMP	389
DEN	391
DENE	392
DENH	393
DENI	394
DENIS	395
DENISON	396
DENM	397
DENN	398
DENNER	399
DENNI	411
DENNY	412
DENO	413
DENT	414
DENTON	415
DENV	416
DENY	417
DEO	418
DEP	419
DEPL	421
DEPO	422
DEPP	423
DEPR	424
DEPU	425
DEQ	426
DER	427
DERBY, M.	428
DERC	429
DERE	431
DERH	432
DERI	433
DERL	434
DERM	435
DERN	436
DERO	437
DERR	438
DERW	439
DES	441
DESAU	442
DESB	443
DESBO	444
DESC	445
DESCH	446
DESCL	447
DESCO	448
DESCR	449
DESE	451
DESES	452
DESF	453
DESG	454
DESGR	455
DESH	456
DESI	457
DESIR	458
DESJ	459
DESL	461
DESLO	462
DESM	463
DESMO	464
DESMOU	465
DESN	466
DESO	467
DESP	468
DESPL	469
DESPO	471
DESPOR	472
DESPR	473
DESR	474
DESS	475
DEST	476
DESTR	477
DESV	478
DET	479
DETI	481
DETO	482
DETR	483
DETZ	484
DEU	485
DEUS	486
DEUX	487
DEV	488
DEVE	489
DEVER	491
DEVI	492
DEVIG	493
DEVIL	494
DEVIN	495
DEVIS	496
DEVL	497
DEVO	498
DEVON	499
DEVONS	511
DEVOS	512
DEVOT	513
DEVR	514
DEW	515
DEWE	516
DEWES	517
DEWET	518
DEWEY	519
DEWI	521
DEWITT	522
DEWITT, M.	523
DEWL	524
DEX	525
DEXT	526
DEXTER, M.	527
DEY	528
DEYN	529
DEYS	531
DEZ	532
DH	533
DHE	534
DHO	535
DI	536
DIAM	537
DIAN	538
DIAP	539
DIAS	541
DIAZ	542
DIB	543
DIBD	544
DIC	545
DICE	546
DICK	547
DICKE	548
DICKER	549
DICKEY	551
DICKI	552
DICKINSO	553
DICKS	554
DID	555
DIDI	556
DIDO	557
DIDR	558
DIE	559
DIEL	561
DIEN	562
DIER	563
DIES	564
DIET	565
DIETR	566
DIEU	567
DIEZ	568
DIF	569
DIG	571
DIGE	572
DIGG	573
DIGH	574
DIGN	575
DIL	576
DILK	577
DILL	578
DILLO	579
DILW	581
DIM	582
DIN	583
DING	584
DINI	585
DINO	586
DINS	587
DIO	588
DIOD	589
DIOG	591
DION	592
DIOP	593
DIOS	594
DIOT	595
DIP	596
DIR	597
DIRC	598
DIRK	599
DIS	611
DISN	612
DISR	613
DIST	614
DIT	615
DITS	616
DITT	617
DIV	618
DIX	619
DIXO	621
DIXW	622
DJ	623
DJE	624
DJI	625
DJO	626
DM	627
DMI	628
DMO	629
DO	631
DOB	632
DOBE	633
DOBR	634
DOBS	635
DOC	636
DOCH	637
DOD	638
DODD	639
DODDR	641
DODDS	642
DODE	643
DODG	644
DODGE, M.	645
DODI	646
DODS	647
DODW	648
DOE	649
DOEL	651
DOER	652
DOES	653
DOG	654
DOH	655
DOHN	656
DOI	657
DOIS	658
DOL	659
DOLB	661
DOLC	662
DOLE	663
DOLG	664
DOLL	665
DOM	666
DOMB	667
DOME	668
DOMI	669
DOMIN	671
DOMIT	672
DOMN	673
DON	674
DONAL	675
DONALDS	676
DONAT	677
DONC	678
DOND	679
DONE	681
DONG	682
DONI	683
DONK	684
DONN	685
DONNER	686
DONO	687
DONT	688
DONZ	689
DOO	691
DOP	692
DOR	693
DORAT	694
DORE	695
DORI	696
DORIG	697
DORIO	698
DORIS	699
DORL	711
DORM	712
DORN	713
DORNI	714
DORO	715
DORR	716
DORS	717
DORSE	718
DORT	719
DORV	721
DOS	722
DOSI	723
DOSS	724
DOT	725
DOU	726
DOUBL	727
DOUC	728
DOUE	729
DOUG	731
DOUGH	732
DOUGL	733
DOUGLAS, G.	734
DOUGLAS, M.	735
DOUGLAS, S.	736
DOUGLAS, W.	737
DOUL	738
DOUR	739
DOUS	741
DOUV	742
DOV	743
DOW	744
DOWD	745
DOWE	746
DOWL	747
DOWN	748
DOWNH	749
DOWNI	751
DOWS	752
DOY	753
DOYL	754
DOZ	755
DR	756
DRAC	757
DRAE	758
DRAG	759
DRAK	761
DRAKE, M.	762
DRAKE, S.	763
DRAN	764
DRAP	765
DRAPER, M.	766
DRAPP	767
DRAY	768
DRAYT	769
DRE	771
DREL	772
DRES	773
DREU	774
DREV	775
DREW	776
DREX	777
DREY	778
DRI	779
DRINK	781
DRIV	782
DRO	783
DROG	784
DROL	785
DROM	786
DROS	787
DROU	788
DROUO	789
DROV	791
DROY	792
DROZ	793
DRU	794
DRUM	795
DRUR	796
DRUS	797
DRY	798
DRYD	799
DRYS	811
DU	812
DUB	813
DUBE	814
DUBO	815
DUBOIS, M.	816
DUBOS	817
DUBOU	818
DUBR	819
DUBU	821
DUC	822
DUCAR	823
DUCAS	824
DUCE	825
DUCH	826
DUCHAT	827
DUCHE	828
DUCHES	829
DUCHI	831
DUCHO	832
DUCI	833
DUCK	834
DUCKE	835
DUCKW	836
DUCL	837
DUCLO	838
DUCO	839
DUCON	841
DUCR	842
DUCRO	843
DUD	844
DUDE	845
DUDI	846
DUDL	847
DUDLEY, L.	848
DUDLEY, S.	849
DUDO	851
DUE	852
DUER	853
DUF	854
DUFF	855
DUFFE	856
DUFFI	857
DUFFY	858
DUFL	859
DUFO	861
DUFOURN	862
DUFR	863
DUFRES	864
DUFU	865
DUG	866
DUGO	867
DUGU	868
DUH	869
DUHE	871
DUHO	872
DUI	873
DUIL	874
DUIS	875
DUJ	876
DUK	877
DUL	878
DULAU	879
DULC	881
DULI	882
DULL	883
DULO	884
DUM	885
DUMAS	886
DUMAY	887
DUME	888
DUMM	889
DUMN	892
DUMO	891
DUMONT	893
DUMOR	894
DUMOU	895
DUMOUR	896
DUN	897
DUNB	898
DUNBAR, M.	899
DUNC	911
DUNCAN, M.	912
DUNCO	913
DUND	914
DUNDO	915
DUNG	916
DUNH	917
DUNI	918
DUNK	919
DUNL	921
DUNLO	922
DUNN	923
DUNNI	924
DUNO	925
DUNS	926
DUNT	927
DUNU	928
DUP	929
DUPAR	931
DUPE	932
DUPERR	933
DUPI	934
DUPL	935
DUPLES	936
DUPO	937
DUPONT	938
DUPOR	939
DUPP	941
DUPR	942
DUPRES	943
DUPU	944
DUPUY	945
DUQ	946
DUR	947
DURAN	948
DURAND, M.	949
DURANT	951
DURAS	952
DURAZ	953
LYN	987
DURD	954
DURE	955
DURET	956
DUREY	957
DURF	958
DURFO	959
DURH	961
DURI	962
DURIV	963
DURO	964
DURR	965
DURS	966
DURU	967
DURUY	968
DURY	969
DUS	971
DUSE	972
DUSI	973
DUSS	974
DUT	975
DUTI	976
DUTO	977
DUTR	978
DUTT	979
DUTTON	981
DUV	982
DUVAL	983
DUVAU	984
DUVE	985
DUVET	986
DUVI	987
DUY	988
DW	989
DWI	991
DWIGHT, J.	992
DWIGHT, S.	993
DY	994
DYE	995
DYER	996
DYM	997
DYR	998
DZ	999
EA	11
EAM	12
EAS	13
EAT	14
EB	15
EBER	16
EC	17
ECH	18
ECK	19
ED	21
EDEN	22
EDF	27
EDG	23
EDM	24
EDW	25
EDWARDS	26
EG	28
EGE	29
EGL	31
EGR	32
EH	33
EI	34
EIN	35
EIS	36
EL	37
ELEA	38
ELEN	39
ELG	41
ELI	42
ELIS	43
ELL	44
ELLE	45
ELLI	46
ELLIS	47
ELM	48
ELS	49
ELT	51
ELW	52
EM	53
EMM	54
EMP	55
EN	56
ENG	57
ENGL	58
ENN	59
ENT	61
EO	62
EP	63
EPI	64
ER	65
ERD	66
ERE	67
ERI	68
ERL	69
ERM	71
ERR	72
ERS	73
ES	74
ESD	75
ESL	76
ESP	77
ESS	78
EST	79
ESTI	81
ESTR	82
ET	83
ETH	84
ETO	85
EU	86
EUG	87
EUL	88
EUP	89
EUS	91
EV	92
EVE	93
EW	94
EWI	95
EX	96
EY	97
EYR	98
EZ	99
FA	111
FAB	112
FABB	113
FABE	114
FABER	115
FABERI	116
FABERT	117
FABI	118
FABIL	119
FABIU	121
FABR	122
FABRE	123
FABRI	124
FABRIAN	125
FABRIC	126
FABRIN	127
FABRIS	128
FABRIZ	129
FABRO	131
FABROT	132
FABRY	133
FABU	134
FABV	135
FABY	136
FAC	137
FACCIO	138
FACH	139
FACI	141
FACIS	142
FACU	143
FAD	144
FADI	145
FADL	146
FAE	147
FAEN	148
FAES	149
FAG	151
FAGE	152
FAGEL	153
FAGG	154
FAGI	155
FAGN	156
FAH	157
FAHR	158
FAI	159
FAIL	161
FAIN	162
FAIR	163
FAIRBAN	164
FAIRC	165
FAIRF	166
FAIRFAX, M.	167
FAIRFIE	168
FAIRFIELD, M.	169
FAIRH	171
FAIRL	172
FAIS	173
FAIT	174
FAIV	175
FAK	176
FAL	177
FALC	178
FALCK	179
FALCO	181
FALCONE	182
FALCONER, M.	183
FALCONET	184
FALCU	185
FALD	186
FALE	187
FALG	188
FALI	189
FALK	191
FALKEN	192
FALKN	193
FALL	194
FALLET	195
FALLO	196
FALS	197
FAM	198
FAN	199
FANE	211
FANI	212
FANN	213
FANO	214
FANS	215
FANT	216
FANTO	217
FANTU	218
FAR	219
FARC	221
FARE	222
FARG	223
FARI	224
FARIN	225
FARING	226
FARINI	227
FARIS	228
FARJ	229
FARL	231
FARLEY, M.	232
FARM	233
FARMER, M.	234
FARN	235
FARNH	236
FARO	237
FARQ	238
FARR	239
FARRAN	241
FARRAR	242
FARRAR, J.	243
FARRAR, S.	244
FARRE	245
FARRI	246
FARS	247
FAS	248
FASS	249
FAST	251
FAT	252
FATI	253
FATO	254
FAU	255
FAUCH	256
FAUCI	257
FAUD	258
FAUG	259
FAUL	261
FAULH	262
FAULK	263
FAUN	264
FAUR	265
FAURI	266
FAUS	267
FAUSTI	268
FAUSTU	269
FAUV	271
FAV	272
FAVE	273
FAVI	274
FAVO	275
FAVR	276
FAVRE	277
FAW	278
FAWE	279
FAWK	281
FAY	282
FAYE	283
FAYET	284
FAYO	285
FAYT	286
FAZ	287
FE	288
FEB	289
FEC	291
FED	292
FEDER	293
FEDO	294
FEE	295
FEH	296
FEI	297
FEILDI	298
FEIN	299
FEIT	311
FELD	312
FELI	313
FELIC	314
FELIN	315
FELIX	316
FELL	317
FELLE	318
FELLI	319
FELLO	321
FELLOW	322
FELO	323
FELS	324
FELT	325
FELTO	326
FELTON, M.	327
FELTR	328
FELV	329
FEN	331
FENE	332
FENI	333
FENN	334
FENNEL	335
FENNER	336
FENNI	337
FENNO	338
FENO	339
FENS	341
FENT	342
FENW	343
FEO	344
FER	345
FERB	346
FERD	347
FERDO	348
FERE	349
FERG	351
FERGU	352
FERGUSON, M.	353
FERGUSS	354
FERH	355
FERI	356
FERL	357
FERM	358
FERME	359
FERMO	361
FERN	362
FERNAND	363
FERNE	364
FERNI	365
FERNO	366
FERO	367
FERR	368
FERRAL	369
FERRAM	371
FERRAN	372
FERRANT	373
FERRAR	374
FERRARI	375
FERRARO	376
FERRARS	377
FERRARY	378
FERRAT	379
FERRAU	381
FERRE	382
FERREL	383
FERREO	384
FERRER	385
FERRERO	386
FERRET	387
FERRI	388
FERRIB	389
FERRIE	391
FERRIN	392
FERRIO	393
FERRIS	394
FERRO	395
FERRON	396
FERROU	397
FERRU	398
FERRY	399
FERT	411
FERU	412
FES	413
FESSEN	414
FESSENDEN, M.	415
FESSI	416
FESSL	417
FEST	418
FET	419
FETT	421
FEU	422
FEUER	423
FEUG	424
FEUI	425
FEUILL	426
FEUT	427
FEV	428
FEVR	429
FEVRET	431
FEW	432
FEY	433
FEYER	434
FEYN	435
FFA	436
FFO	437
FIAM	439
FIAN	441
FIAS	442
FIB	443
FIC	444
FICH	445
FICI	446
FICK	447
FICO	448
FID	449
FIDE	451
FIE	452
FIELD	453
FIELDE	458
FIELD, H.	454
FIELDI	459
FIELD, M.	455
FIELDS	461
FIELD, S.	456
FIELDS, J.	462
FIELDS, S.	463
FIELD, W.	457
FIEN	464
FIER	465
FIES	466
FIESCO	467
FIESO	468
FIF	469
FIG	471
FIGI	472
FIGO	473
FIGR	474
FIGU	475
FIGUI	476
FIGUL	477
FIL	478
FILAS	479
FILE	481
FILI	482
FILIP	483
FILL	484
FILLE	485
FILLI	486
FILLM	487
FILO	488
FILS	489
FIN	491
FINCH	492
FINCK	493
FIND	494
FINE	495
FINET	496
FING	497
FINI	498
FINK	499
FINL	511
FINLAYS	512
FINLEY	513
FINN	514
FINO	515
FINS	516
FIO	517
FIORE	518
FIORI	519
FIORIN	521
FIR	522
FIRE	523
FIRM	524
FIRMIN	525
FIRN	526
FIRO	527
FIS	528
FISCHE	529
FISE	531
FISH	532
FISHER	533
FISHER, J.	534
FISHER, M.	535
FISHER, S.	536
FISHER, W.	537
FISK	538
FISKE	541
FISKE, M.	542
FISK, M.	539
FISS	543
FIT	544
FITCH, J.	545
FITCH, S.	546
FITT	547
FITZ	548
FITZA	549
FITZB	551
FITZC	552
FITZG	553
FITZGERALD, M.	554
FITZH	555
FITZJ	556
FITZM	557
FITZN	558
FITZP	559
FITZR	561
FITZS	562
FITZT	563
FITZW	564
FIU	565
FIX	566
FIZ	567
FL	568
FLAC	569
FLACH	571
FLACO	572
FLAD	573
FLAG	574
FLAH	575
FLAI	576
FLAM	577
FLAMEN	578
FLAMI	579
FLAMM	581
FLAMS	582
FLAN	583
FLAND	584
FLANDR	585
FLAT	586
FLAU	587
FLAV	588
FLAVI	589
FLAVU	591
FLAX	592
FLE	593
FLEE	594
FLEETW	595
FLEI	596
FLEM	597
FLEMING, M.	598
FLEMM	599
FLES	611
FLET	612
FLETCHER, J.	613
FLETCHER, P.	614
FLETCHER, S.	615
FLEU	616
FLEURI	617
FLEURY	618
FLEX	619
FLI	621
FLIN	622
FLINT	623
FLINT, J.	624
FLINT, S.	625
FLIP	626
FLIT	627
FLO	628
FLOG	629
FLOO	631
FLOR	632
FLORENT	633
FLORES	634
FLORI	635
FLORID	636
FLORIN	637
FLORIO	638
FLORIS	639
FLORU	641
FLOT	642
FLOTT	643
FLOW	644
FLOY	645
FLU	646
FLUR	647
FLY	648
FO	649
FOB	651
FOC	652
FOD	653
FOE	654
FOG	655
FOGL	656
FOH	657
FOI	658
FOIN	659
FOIX	661
FOK	662
FOL	663
FOLG	664
FOLI	665
FOLK	666
FOLL	667
FOLLI	668
FOLQ	669
FOLS	671
FOM	672
FON	673
FONF	674
FONN	675
FONS	676
FONT	677
FONTAI	678
FONTAN	679
FONTANI	681
FONTE	682
FONTEN	683
FONTI	684
FONTR	685
FOO	686
FOOT	687
FOOTE	688
FOOTE, M.	689
FOP	691
FOR	692
FORBES, H.	693
FORBES, M.	694
FORBES, S.	695
FORBI	696
FORC	697
FORCH	698
FORD	699
FORDH	712
FORD, M.	711
FORDY	713
FORE	714
FOREM	715
FORES	716
FORESTER	717
FORESTI	718
FORF	719
FORG	721
FORL	722
FORM	723
FORMAN	724
FORME	725
FORMO	726
FORN	727
FORR	728
FORRESTER	731
FORREST, M.	729
FORS	732
FORST	733
FORSTER	734
FORSY	735
FORT	736
FORTE	737
FORTES	738
FORTH	739
FORTI	741
FORTIN	742
FORTIS	743
FORTO	744
FORTU	745
FOS	746
FOSC	747
FOSD	748
FOSG	749
FOSS	751
FOSSE	752
FOST	753
FOSTER	754
FOSTER, H.	755
FOSTER, M.	756
FOSTER, S.	757
FOSTER, W.	758
FOT	759
FOTHER	761
FOU	762
FOUCH	763
FOUD	764
FOUG	765
FOUI	766
FOUL	767
FOULO	768
FOULQ	769
FOUN	771
FOUQ	772
FOUR	773
FOURER	774
FOURI	775
FOURM	776
FOURN	777
FOURNI	778
FOURNIV	779
FOURQ	781
FOUT	782
FOV	783
FOW	784
FOWL	785
FOWLER, H.	786
FOWLER, M.	787
FOWLER, S.	788
FOWLER, W.	789
FOX	791
FOXE	795
FOX, H.	792
FOX, M.	793
FOX, S.	794
FOY	796
FR	797
FRACH	798
FRAD	799
FRAG	811
FRAI	812
FRAM	813
FRAN	814
FRANCE	815
FRANCH	816
FRANCI	817
FRANCIS	818
FRANCIS, M.	819
FRANCIU	821
FRANCK	822
FRANCKE	823
FRANCKL	824
FRANCO	825
FRANCON	826
FRANG	827
FRANK	828
FRANKE	829
FRANKL	831
FRANKLIN, H.	832
FRANKLIN, M.	833
FRANKLIN, S.	834
FRANQ	835
FRANT	836
FRANZ	837
FRAP	838
FRAR	839
FRAS	841
FRASER, M.	842
FRASS	843
FRAT	844
FRAU	845
FRAV	846
FRAY	847
FRAZ	848
FRE	849
FREC	851
FRED	852
FREE	853
FREEL	854
FREEM	855
FREER	856
FREES	857
FREG	858
FREGO	859
FREH	861
FREI	862
FREIG	863
FREIL	864
FREIM	865
FREIR	866
FREK	867
FREL	868
FREM	869
FREMI	871
FREMO	872
FREN	873
FRENCH, H.	874
FRENCH, M.	875
FRENCH, S.	876
FRENCH, W.	877
FREND	878
FRENI	879
FRER	881
FRERET	882
FRERO	883
FRES	884
FRESH	885
FRESN	886
FRESS	887
FRET	888
FREU	889
FREV	891
FREW	892
FREY	893
FREYL	894
FREYT	895
FREZ	896
FRI	897
RAC	118
FRID	898
FRIE	899
FRIEDL	911
FRIES	912
FRIL	913
FRIN	914
FRIP	915
FRIR	916
FRIS	917
FRISW	918
FRIT	919
FRIZ	921
FRO	922
FROBI	923
FROC	924
FROE	925
FROEL	926
FROG	927
FROH	928
FROI	929
FROM	931
FROMM	932
FRON	933
FRONS	934
FRONT	935
FRONTO	936
FROR	937
FROS	938
FROST	939
FROT	941
FROU	942
FROW	943
FRU	944
FRUN	945
FRY	946
FRYE	948
FRY, M.	947
FU	949
FUCHS	951
FUD	952
FUE	953
FUEN	954
FUES	955
FUF	956
FUG	957
FUGG	958
FUH	959
FUI	961
FUL	962
FULG	963
FULK	964
FULL	965
FULLER, H.	966
FULLER, M.	967
FULLER, S.	968
FULLERT	971
FULLER, W.	969
FULLO	972
FULM	973
FULT	974
FULV	975
FUM	976
FUME	977
FUMI	978
FUN	979
FUND	981
FUNK	982
FUR	983
FURI	984
FURL	985
FURM	986
FURN	987
FURNES	988
FURNI	989
FURS	991
FURT	992
FUS	993
FUSS	994
FUST	995
FUSU	996
FY	997
FYO	998
FYR	999
GA	111
GAB	112
GABI	113
GABIO	114
GABL	115
GABO	116
GABR	117
GABRIEL	118
GABRO	119
GAC	121
GACO	122
GAD	123
GADE	124
GADO	125
GADS	126
GAE	127
GAER	128
GAET	129
GAF	131
GAG	132
GAGE, M.	133
GAGI	134
GAGL	135
GAGO	136
GAI	137
GAIL	138
GAILL	139
GAIM	141
GAIN	142
GAINS	143
GAIR	144
GAJ	145
GAL	146
GALAU	147
GALB	148
GALD	149
GALE	151
GALE, M.	152
GALEN	153
GALER	154
GALF	155
GALI	156
GALIG	157
GALIL	158
GALIT	159
GALITZ	161
GALL	162
GALLAN	163
GALLAT	164
GALLAU	165
GALLE	166
GALLET	167
GALLI	168
GALLIM	169
GALLIO	171
GALLO	172
GALLOIS	173
GALLOW	174
GALLU	175
GALLUS	176
GALLW	177
GALO	178
GALT	179
GALTO	181
GALV	182
GALW	183
GAM	184
GAMAI	185
GAMAL	186
GAMB	187
GAMBAR	188
GAMBE	189
GAMBI	191
GAMBO	192
GAMM	193
GAMO	194
GAN	195
GANDO	196
GANG	197
GANN	198
GANS	199
GANT	211
GAR	212
GARB	213
GARBO	214
GARC	215
GARCI	216
GARD	217
GARDE	218
GARDI	219
GARDINER	221
GARDINER, H.	222
GARDINER, M.	223
GARDINER, S.	224
GARDN	225
GARDNER	226
GARDNER, H.	227
GARDNER, P.	228
GARE	229
GARF	231
GARI	232
GARL	233
GARN	234
GARNET	235
GARNI	236
GARO	237
GARR	238
GARRE	239
GARRI	241
GARRIS	242
GARRO	243
GART	244
GARZ	245
GAS	246
GASCO	247
GASK	248
GASP	249
GASS	251
GASSET	252
GASSI	253
GASSO	254
GAST	255
GASTON	256
GASTR	257
GAT	258
GATES	259
GATI	261
GATT	262
GATTI	263
GAU	264
GAUC	265
GAUD	266
GAUDI	267
GAUF	268
GAUL	269
GAULT	271
GAUN	272
GAUR	273
GAUS	274
GAUT	275
GAUTH	276
GAUTI	277
GAUZ	278
GAV	279
GAVAU	281
GAVE	282
GAVI	283
GAW	284
GAY	285
GAYE	286
GAYL	287
GAYO	288
GAZ	289
GAZO	291
GE	292
GEB	293
GEBEN	444
GEC	294
GED	295
GEDI	296
GEE	297
GEER	298
GEF	299
GEH	311
GEI	312
GEIS	313
GEL	314
GELD	315
GELE	316
GELI	317
GELL	318
GELLI	319
GELO	321
GEM	322
GEMM	323
GEN	324
GEND	325
GENE	326
GENES	327
GENET	328
GENG	329
GENI	331
GENL	332
GENN	333
GENNE	334
GENO	335
GENS	336
GENT	337
GENTIL	338
GENTR	339
GENU	341
GEO	342
GEOF	343
GEOFFRI	344
GEOFFRO	345
GEOR	346
GEORGE	347
GEORGE, H.	348
GEORGES	351
GEORGE, S.	349
GEORGI	352
GEP	353
GER	354
GERAN	355
GERAR	356
GERARDI	358
GERARD, M.	357
GERAU	359
GERB	361
GERBER	362
GERBI	363
GERBO	364
GERC	365
GERD	366
GERE	367
GERH	368
GERI	369
GERL	371
GERM	372
GERMAN	373
GERMI	374
GERMO	375
GERN	376
GERO	377
GERR	378
GERRY	379
GERS	381
GERSO	382
GERST	383
GERT	384
GERV	385
GERVAS	386
GERVI	387
GERY	388
GES	389
GESN	391
GESS	392
GEST	393
GET	394
GEU	395
GEV	396
GEY	397
GEZ	398
GF	399
GH	411
GHEI	412
GHER	413
GHERARD	414
GHERARDI	415
GHERARDO	416
GHERL	417
GHES	418
GHEY	419
GHEZ	421
GHI	422
GHID	423
GHIL	424
GHIR	425
GHIS	426
GHISLI	427
GI	428
GIAC	429
GIAL	431
GIAM	432
GIAN	433
GIANNO	434
GIAR	435
GIAT	436
GIB	437
GIBBE	438
GIBBO	439
GIBBONS	441
GIBBS	442
GIBBS, H.	443
GIBBS, S.	444
GIBE	445
GIBI	446
GIBN	447
GIBS	448
GIBSON, H.	449
GIBSON, S.	451
GIC	452
GID	453
GIE	454
GIES	455
GIF	456
GIFFE	457
GIFFO	458
GIG	459
GIGO	461
GIH	462
GIL	463
GILBERT	464
GILBERT, J.	465
GILBERT, S.	466
GILC	467
GILD	468
GILDO	469
GILE	471
GILES	472
GILF	473
GILI	474
GILL	475
GILLE	476
GILLES	477
GILLESP	478
GILLET	479
GILLI	481
GILLM	482
GILLO	483
GILLS	484
GILLY	485
GILM	486
GILMAN	487
GILMO	488
GILP	489
GIM	491
GIN	492
GINO	493
GIO	494
GIOF	495
GIOL	496
GIOR	497
GIORG	498
GIORGIO	499
GIOT	511
GIOV	512
GIOVE	513
GIOVI	514
GIR	515
GIRAL	516
GIRAR	517
GIRARDE	519
GIRARDI	521
GIRARD, M.	518
GIRAU	522
GIRAUL	523
GIRD	524
GIRI	525
GIRO	526
GIRON	527
GIROU	528
GIRT	529
GIS	531
GISE	532
GISL	533
GISM	534
GISO	535
GIT	536
GIU	537
GIUS	538
GIV	539
GL	541
GLAD	542
GLADS	543
GLAI	544
GLAN	545
GLANV	546
GLAP	547
GLAS	548
GLASS	549
GLAU	551
GLAUC	552
GLAZ	553
GLE	554
GLED	555
GLEI	556
GLEIG	557
GLEN	558
GLI	559
GLIN	561
GLO	562
GLOS	563
GLOU	564
GLOV	565
GLOVER	566
GLU	567
GLY	568
GM	569
GN	571
GNI	572
GO	573
GOB	574
GOBI	575
GOC	576
GOD	577
GODD	578
GODE	579
GODEF	581
GODES	582
GODF	583
GODI	584
GODIN	585
GODK	586
GODM	587
GODO	588
GODON	589
GODW	591
GODWIN, M.	592
GOE	593
GOED	594
GOEL	595
GOEP	596
GOER	597
GOES	598
GOET	599
GOETZ	611
GOF	612
GOG	613
GOH	614
GOI	615
GOIS	616
GOL	617
GOLD	618
GOLDI	619
GOLDO	621
GOLDS	622
GOLDSC	623
GOLDSM	624
GOLE	625
GOLI	626
GOLO	627
GOLOV	628
GOLT	629
GOM	631
GOMBE	632
GOME	633
GOMM	634
GON	635
GOND	636
GONDI	637
GONE	638
GONN	639
GONT	641
GONZ	642
GONZAL	643
GOO	644
GOOC	645
GOOD	646
GOODE	647
GOODEL	648
GOODEN	649
GOODF	651
GOODH	652
GOODM	653
GOODR	654
GOODRICH, M.	655
GOODW	656
GOODWIN, M.	657
GOODY	658
GOOK	659
GOR	661
GORDON	662
GORDON, G.	663
GORDON, M.	664
GORDON, S.	665
GORE	666
GORG	667
GORH	668
GORI	669
GORM	671
GORO	672
GORR	673
GORS	674
GORT	675
GOS	676
GOSS	677
GOSSE	678
GOSSEL	679
GOSSO	681
GOST	682
GOT	683
GOTH	684
GOTT	685
GOTTI	686
GOTTS	687
GOU	688
GOUF	689
GOUG	691
GOUGH	692
GOUJ	693
GOUL	694
GOULB	695
GOULD	696
GOULD, J.	697
GOULD, S.	698
GOULS	699
GOUN	711
GOUP	712
GOUR	713
GOURD	714
GOURG	715
GOURL	716
GOUS	717
GOUT	718
GOUV	719
GOV	721
GOW	722
GOWER	723
GOY	724
GOZ	725
GR	726
GRAB	727
GRABER	728
GRAC	729
GRACI	731
GRAD	732
GRADO	733
GRAE	734
GRAES	735
GRAF	736
GRAFT	737
GRAH	738
GRAHAM, G.	739
GRAHAM, M.	741
GRAHAM, S.	742
GRAI	743
GRAL	744
GRAM	745
GRAMMO	746
GRAMO	747
GRAN	748
GRANC	749
GRAND	751
GRANDES	752
GRANDI	753
GRANDM	754
GRANDV	755
GRANE	756
GRANG	757
GRANGER	758
GRANI	759
GRANT	761
GRANT, H.	762
GRANTL	764
GRANT, S.	763
GRANV	765
GRAP	766
GRAS	767
GRASS	768
GRASSI	769
GRAT	771
GRATI	772
GRATT	773
GRAU	774
GRAV	775
GRAVES	776
GRAVI	777
GRAY	778
GRAY, G.	779
GRAY, M.	781
GRAYS	784
GRAY, S.	782
GRAY, W.	783
GRAZ	785
GRE	786
GREAV	787
GREB	788
GREC	789
GRECO	791
GRED	792
GREE	793
GREEL	794
GREEN	795
GREENE	799
GREENE, J.	811
GREENE, S.	812
GREEN, G.	796
GREENH	813
GREENL	814
GREEN, M.	797
GREENO	815
GREEN, S.	798
GREENW	816
GREF	817
GREG	818
GREGG	819
GREGORI	821
GREGORY	822
GREGORY, M.	823
GREI	824
GREL	825
GREN	826
GRENI	827
GRENV	828
GREP	829
GRES	831
GRESS	832
GRESW	833
GRET	834
GRETTO	835
GREU	836
GREV	837
GREVI	838
GREVY	839
GREW	841
GREY	842
GREY, G.	843
GREY, M.	844
GREY, S.	845
GRI	846
GRID	847
GRIE	848
GRIF	849
GRIFFIN	851
GRIFFIN, M.	852
GRIFFITH	853
GRIFFITH, M.	854
GRIFFITHS	855
GRIFFO	856
GRIG	857
GRIL	858
GRILLO	859
GRIM	861
GRIME	862
GRIMK	863
GRIMM	864
GRIMO	865
GRIN	866
GRINF	867
GRINN	868
GRIS	869
GRISW	871
GRIV	872
GRO	873
GROE	874
GROL	875
GRON	876
GROS	877
GROSS	878
GROSV	879
GROT	881
GROU	882
GROV	883
GROVES	884
GRU	885
GRUE	886
GRUL	887
GRUN	888
GRUND	889
GRUNE	891
GRUP	892
GRUT	893
GRY	894
GRYP	895
GU	896
GUAD	897
GUAI	898
GUAL	899
GUALD	911
GUALT	912
GUAN	913
GUAR	914
GUARI	915
GUARN	916
GUAS	917
GUAT	918
GUAZ	919
GUB	921
GUD	922
GUDM	923
GUE	924
GUEL	925
GUEN	926
GUENO	927
GUEP	928
GUER	929
GUERE	931
GUERI	932
GUERN	933
GUERR	934
GUERRI	935
GUES	936
GUET	937
GUEU	938
GUEV	939
GUF	941
GUG	942
GUIB	944
GUIC	945
GUID	946
GUIDI	947
GUIDO	948
GUIE	949
GUIG	951
GUIJ	952
GUIL	953
GUILD	954
GUILD, M.	955
GUILE	956
GUILL	957
GUILLE	958
GUILLI	959
GUILLO	961
GUILLOT	962
GUIM	963
GUIN	964
GUIR	965
GUIS	966
GUISE	967
GUIT	968
GUIZ	969
GUL	971
GULG	972
GULL	973
GUM	974
GUN	975
GUNN	976
GUNT	977
GUR	978
GURE	979
GURN	981
GUS	982
GUT	983
GUTH	984
GUTT	985
GUY	986
GUYAR	987
GUYE	988
GUYO	989
GUYS	991
GUYT	992
GUZ	993
GW	994
GWY	995
GY	996
GYLL	997
GYS	998
GYZ	999
HA	111
HAAS	112
HAB	113
HABER	114
HABERT	115
HABI	116
HAC	117
HACK	118
HACKET	119
HACKETT	121
HACKL	122
HACKM	123
HACO	124
HAD	125
HADD	126
HADDO	127
HADE	128
HADF	129
HADL	131
HADR	132
HAE	133
HAEL	134
HAEN	135
HAER	136
HAEU	137
HAF	138
HAFI	139
HAG	141
HAGEM	142
HAGEN	143
HAGER	144
HAGG	145
HAGS	146
HAGU	147
HAH	148
HAI	149
HAIL	151
HAIN	152
HAINES	153
HAJ	154
HAK	155
HAKL	156
HAL	157
HALD	158
HALDE	159
HALE	161
HALE, G.	162
HALE, M.	163
HALEN	166
HALES	167
HALE, S.	164
HALET	168
HALE, W.	165
HALF	169
HALH	171
HALI	172
HALIF	173
HALL	174
HALLAM	182
HALL, D.	175
HALLE	183
HALLEC	184
HALLER	185
HALLET	186
HALLEY	187
HALL, G.	176
HALLI	188
HALLIG	189
HALLIW	191
HALL, J.	177
HALL, M.	178
HALLO	192
HALLOW	193
HALL, S.	179
HALL, W.	181
HALM	194
HALP	195
HALS	196
HALT	197
HAM	198
HAMB	199
HAMD	211
HAME	212
HAMELI	213
HAMER	214
HAMERT	215
HAMI	216
HAMIL	217
HAMILTON, G.	218
HAMILTON, M.	219
HAMILTON, S.	221
HAMILTON, W.	222
HAML	223
HAMM	224
HAMMO	225
HAMMOND, G.	226
HAMMOND, M.	227
HAMO	228
HAMP	229
HAMPS	231
HAMPT	232
HAN	233
HANC	234
HANCOCK, M.	235
HAND	236
HANE	237
HANF	238
HANG	239
HANK	241
HANM	242
HANN	243
HANNE	244
HANNI	245
HANNO	246
HANO	247
HANR	248
HANS	249
HANSO	251
HANW	252
HAQ	253
HAR	254
HARB	255
HARC	256
HARCOU	257
HARD	258
HARDEN	259
HARDI	261
HARDIE	262
HARDING	263
HARDINGE	264
HARDO	265
HARDT	266
HARDW	267
HARDY	268
HARDY, G.	269
HARDY, M.	271
HARDY, S.	272
HARDY, W.	273
HARE	274
HARE, M.	275
HAREN	276
HAREW	277
HARF	278
HARG	279
HARI	281
HARIO	282
HARL	283
HARLE	284
HARLEY	285
HARLO	286
HARM	287
HARMO	288
HARN	289
HARNI	291
HARO	292
HARP	293
HARPER, G.	294
HARPER, M.	295
HARR	296
HARRI	297
HARRIMAN, M.	298
HARRIN	299
HARRINGTON, M.	311
HARRIO	312
HARRIS	313
HARRIS, F.	314
HARRIS, M.	315
HARRISON	318
HARRISON, F.	319
HARRISON, M.	321
HARRISON, S.	322
HARRISON, W.	323
HARRIS, S.	316
HARRIS, W.	317
HARS	324
HART	325
HARTE	327
HARTE, M.	328
HARTI	329
HARTL	331
HARTLEY	332
HARTM	333
HART, M.	326
HARTO	334
HARTS	335
HARTU	336
HARTW	337
HARTZ	338
HARV	339
HARVEY	341
HARVEY, M.	342
HARW	343
HAS	344
HASD	345
HASE	346
HASEL	347
HASEN	348
HASK	349
HASKI	351
HASL	352
HASS	353
HASSE	354
HASSEL	355
HAST	356
HASTINGS	357
HASTINGS, M.	358
HASW	359
HAT	361
HATF	362
HATH	363
HATHERT	364
HATS	365
HATT	366
HATZ	367
HAU	368
HAUF	369
HAUG	371
HAUL	372
HAUN	373
HAUP	374
HAUR	375
HAUS	376
HAUSS	377
HAUSSO	378
HAUT	379
HAUTEM	381
HAUTP	382
HAV	383
HAVEL	384
HAVEN	385
HAVEN, M.	386
HAVER	387
HAVI	388
HAW	389
HAWES	391
HAWK	392
HAWKINS	393
HAWKINS, M.	394
HAWKS	395
HAWL	396
HAWO	397
HAWS	398
HAWT	399
HAX	411
HAY	412
HAYDEN	414
HAYDEN, M.	415
HAYDON	416
HAYE	417
HAYES, M.	418
HAYG	419
HAYL	421
HAYM	422
HAY, M.	413
HAYN	423
HAYNES	424
HAYS	425
HAYT	426
HAYW	427
HAZ	428
HAZE	429
HAZL	431
HE	432
HEADL	433
HEAL	434
HEAR	435
HEARN	436
HEAT	437
HEATHC	439
HEATHE	441
HEATH, M.	438
HEATO	442
HEB	443
HEBER	445
HEBERT	446
HEC	447
HECK	448
HECKER	449
HECT	451
HED	452
HEDG	453
HEDI	454
HEDL	455
HEDO	456
HEDW	457
HEE	458
HEER	459
HEF	461
HEG	462
HEGES	463
HEGH	464
HEI	465
HEIL	466
HEIM	467
HEIN	468
HEINR	469
HEINS	471
HEINZ	472
HEIS	473
HEL	474
HELI	475
HELL	476
HELLE	477
HELM	478
HELMH	479
HELMO	481
HELO	482
HELP	483
HELPS	484
HELV	485
HELW	486
HEM	487
HEME	488
HEMM	489
HEMP	491
HEMS	492
HEN	493
HENC	494
HEND	495
HENDERSON	496
HENDERSON, M.	497
HENDR	498
HENF	499
HENG	511
HENK	512
HENKEL	513
HENL	514
HENN	515
HENNI	516
HENNIN	517
HENR	518
HENRIO	519
HENRY	521
HENRY, G.	522
HENRY, M.	523
HENRY, S.	524
HENRY, W.	525
HENS	526
HENT	527
HENTZ	528
HEP	529
HER	531
HERAR	532
HERAU	533
HERB	534
HERBER	535
HERBERT	536
HERBERT, M.	537
HERBI	538
HERC	539
HERD	541
HERE	542
HEREU	543
HERF	544
HERG	545
HERI	546
HERIO	547
HERIS	548
HERL	549
HERM	551
HERMANN	552
HERME	553
HERMI	554
HERMO	555
HERMON	556
HERN	557
HERND	558
HERO	559
HEROL	561
HERON	562
HERP	563
HERR	564
HERRER	565
HERRI	566
HERRIN	567
HERRM	568
HERS	569
HERSC	571
HERSE	572
HERT	573
HERTF	574
HERTS	575
HERTZ	576
HERV	577
HERVEY	578
HERVEY, M.	579
HERW	581
HERZ	582
HES	583
HESE	584
HESM	585
HESS	586
HEST	587
HET	589
HETT	591
HEU	592
HEUM	593
HEUR	594
HEUS	595
HEV	596
HEW	597
HEWE	598
HEWI	599
HEWIT	611
HEWL	612
HEWS	613
HEX	614
HEY	615
HEYF	616
HEYL	617
HEYM	618
HEYN	619
HEYS	621
HEYW	622
HI	623
HIB	624
HIBO	625
HIC	626
HICK	627
HICKE	628
HICKO	629
HICKS	631
HID	632
HIE	633
HIG	634
HIGG	635
HIGGINS	636
HIGGINSON	637
HIGH	638
HIJ	639
HIL	641
HILD	642
HILDER	643
HILDR	644
HILL	645
HILLA	649
HILLE	651
HILLER	652
HILL, G.	646
HILLH	653
HILLI	654
HILL, M.	647
HILLS	655
HILL, S.	648
HILT	656
HIM	657
HIMI	658
HIN	659
HINCKS	661
HIND	662
HING	663
HINR	664
HINS	665
HINT	666
HIP	667
HIR	668
HIRS	669
HIRT	671
HIRZ	672
HIS	673
HIT	674
HITCHI	675
HITT	676
HJ	677
HO	678
HOAR	679
HOB	681
HOBB	682
HOBH	683
HOBS	684
HOC	685
HOCQ	686
HOD	687
HODG	688
HODGES, M.	689
HODGS	691
HODS	692
HOE	693
HOEL	694
HOES	695
HOEY	696
HOF	697
HOFF	698
HOFFM	699
HOFFMAN, M.	711
HOFL	712
HOFM	713
HOG	714
HOGAR	715
HOGG	716
HOH	717
HOHENL	718
HOHENZ	719
HOK	721
HOL	722
HOLB	723
HOLBR	724
HOLC	725
HOLD	726
HOLDER	727
HOLDS	728
HOLE	729
HOLG	731
HOLI	732
HOLL	733
HOLLAND	734
HOLLAND, G.	735
HOLLAND, M.	736
HOLLAND, S.	737
HOLLEY	738
HOLLI	739
HOLLIN	741
HOLLIS	742
HOLLIS, M.	743
HOLLIST	744
HOLLO	745
HOLLY	746
RIN	578
HOLM	747
HOLME	748
HOLMES	749
HOLMES, G.	751
HOLMES, M.	752
HOLMES, S.	753
HOLO	754
HOLR	755
HOLS	756
HOLSTE	757
HOLT	758
HOLW	759
HOLY	761
HOLZ	762
HOM	763
HOMB	764
HOME	765
HOMER	766
HOMES	767
HOMM	768
HON	769
HOND	771
HONE	772
HONI	773
HONO	774
HONT	775
HOO	776
HOOD, M.	777
HOOF	778
HOOG	779
HOOK	781
HOOKE	782
HOOKER	783
HOOKER, M.	784
HOOP	785
HOOPER, G.	786
HOOPER, M.	787
HOOPER, S.	788
HOOR	789
HOP	791
HOPF	792
HOPK	793
HOPKINS, G.	794
HOPKINS, M.	795
HOPKINSON	797
HOPKINS, S.	796
HOPP	798
HOPT	799
HOR	811
HORL	812
HORN	813
HORNB	814
HORNE	815
HORNER	816
HORS	817
HORSL	818
HORST	819
HORT	821
HORTEN	822
HORTO	823
HORW	824
HOS	825
HOSK	826
HOSM	827
HOSP	828
HOSS	829
HOST	831
HOT	832
HOTM	833
HOTT	834
HOU	835
HOUD	836
HOUE	837
HOUG	838
HOUN	839
HOUR	841
HOUS	842
HOUST	843
HOUT	844
HOV	845
HOVEY	846
HOW	847
HOWARD	848
HOWARD, G.	849
HOWARD, M.	851
HOWARD, S.	852
HOWARD, W.	853
HOWD	854
HOWE	855
HOWE, G.	856
HOWEL	859
HOWE, M.	857
HOWE, S.	858
HOWI	861
HOWIS	862
HOWIT	863
HOWL	864
HOWLE	865
HOWS	866
HOX	871
HOY	867
HOYT	868
HOYT, M.	869
HOZ	872
HR	873
HU	874
HUB	875
HUBBARD, M.	876
HUBE	877
HUBERT	878
HUBN	879
HUBS	881
HUC	882
HUD	883
HUDDL	884
HUDS	885
HUDSON, M.	886
HUE	887
HUET	888
HUF	889
HUG	891
HUGH	892
HUGHES	893
HUGHES, M.	894
HUGO	895
HUGON	896
HUGU	897
HUGUI	898
HUI	899
HUIT	911
HUL	912
HULL	913
HULLI	914
HULM	915
HULO	916
HULS	917
HUM	918
HUMB	919
HUME	921
HUME, M.	922
HUMF	923
HUMI	924
HUMM	925
HUMP	926
HUMPHREYS	927
HUMPHRI	928
HUMPS	929
HUN	931
HUNC	932
HUND	933
HUNE	934
HUNF	935
HUNG	936
HUNI	937
HUNN	938
HUNT	939
HUNTE	944
HUNTER	945
HUNTER, M.	946
HUNTER, S.	947
HUNT, G.	941
HUNTIGTON	949
HUNTIGTON, G.	951
HUNTIGTON, M.	952
HUNTIGTON, S.	953
HUNTING	948
HUNTL	954
HUNT, M.	942
HUNTO	955
HUNTS	956
HUNT, S.	943
HUO	957
HUP	958
HUR	959
HURDI	962
HURD, M.	961
HURE	963
HURI	964
HURL	965
HURLS	966
HURT	967
HUS	968
HUSE	969
HUSK	971
HUSS	972
HUT	973
HUTCHINS	974
HUTCHINSON	975
HUTCHINSON, G.	976
HUTCHINSON, M.	977
HUTCHINSON, S.	978
HUTH	979
HUTI	981
HUTT	982
HUTTER	983
HUTTO	984
HUTTON, M.	985
HUX	986
HUY	987
HUYS	988
HUZ	989
HW	991
HY	992
HYDE	993
HYDE, H.	994
HYDE, P.	995
HYL	996
HYN	997
HYP	998
HYR	999
IA	11
IB	12
IBN	13
IBR	14
IC	15
ICH	16
ICK	17
ID	18
IDE	19
IDO	21
IE	22
IF	23
IG	24
IH	25
IK	26
IL	27
ILI	28
ILL	29
IM	31
IMB	32
IML	33
IMP	34
IN	35
INC	36
INCH	37
IND	38
INDI	39
INDO	41
INDU	42
INF	43
ING	44
INGE	45
INGEL	46
INGER	47
INGH	48
INGI	49
INGL	51
INGLI	52
INGO	53
INGR	54
INGRE	55
INI	56
INM	57
INN	58
INS	59
INT	61
INV	62
INW	63
IO	64
IR	65
IREN	66
IRET	67
IRI	68
IRL	69
IRO	71
IRV	72
IS	73
ISAB	74
ISAM	75
ISAR	76
ISC	77
ISE	78
ISH	79
ISI	81
ISL	82
ISM	83
ISN	84
ISO	85
ISS	86
IST	87
IT	88
ITH	89
ITT	91
IU	92
IV	93
IVE	94
IVES	95
IVO	96
IX	97
IZ	98
IZM	99
JA	11
JAC	12
JACKSON, J.	13
JACKSON, S.	14
JACO	15
JACOBI	16
JACOBS	17
JACOP	18
JACQ	19
JACQUI	21
JAE	22
JAF	23
JAG	24
JAH	25
JAL	26
JAM	27
JAMES, M.	28
JAMESO	31
JAMES, S.	29
JAMI	32
JAN	33
JANN	34
JANS	35
JAQ	36
JAR	37
JARV	38
JAS	39
JAU	41
JAY	42
JE	43
JEB	44
JEF	45
JEFFRE	46
JEFFRI	47
JEL	48
JEM	49
JEN	51
JENK	52
JENKS	53
JENN	54
JER	55
JERO	56
JERV	57
JES	58
JEW	59
JI	61
JO	62
JOC	63
JOE	64
JOH	65
JOHNSO	66
JOHNSON, G.	67
JOHNSON, M.	68
JOHNSON, S.	69
JOHNSON, W.	71
JOHNST	72
JOHNSTON, M.	73
JOI	74
JOL	75
JON	76
JONES, G.	77
JONES, M.	78
JONES, S.	79
JONS	81
JOR	82
JOS	83
JOSS	84
JOT	85
JOU	86
JOW	87
JOY	88
JOYC	89
JU	91
JUD	92
JUDS	93
JUL	94
JUN	95
JUS	96
JUV	97
JUX	98
JY	99
KA	11
KAH	12
KAI	13
KAL	14
KAM	15
KAN	16
KAP	17
KAR	18
KAS	19
KAU	21
KAW	22
KAY	23
KE	24
KEAT	25
KEE	26
KEI	27
KEITH	28
KEL	29
KEM	31
KEMP	32
KEN	33
KENN	34
KENNEDY	35
KENNEDY, M.	36
KENT	37
KEP	38
KER	39
SKI	628
KERR	41
KES	42
KET	43
KEY	44
KH	45
KI	46
KIE	47
KIL	48
KIM	49
KIN	51
KING	52
KING, J.	53
KING, P.	54
KINGS	55
KINS	56
KIP	57
KIR	58
KIRK	59
KIRS	61
KIT	62
KL	63
KLEIN	64
KLI	65
KLO	66
KN	67
KNE	68
KNI	69
KNIGHT, M.	71
KNO	72
KNOW	73
KNOX	74
KO	75
KOC	76
KOE	77
KOEN	78
KOH	79
KOL	81
KON	82
KOP	83
KOR	84
KORT	85
KOS	86
KOT	87
KOU	88
KR	89
KRAU	91
KRE	92
KRO	93
KRU	94
KU	95
KUH	96
KUS	97
KW	98
KY	99
LA	111
LAB	112
LABAR	113
LABAT	114
LABBE	115
LABE	116
LABEO	117
LABI	118
LABIL	119
LABL	121
LABO	122
LABOR	123
LABOU	124
LABOUR	125
LABR	126
LABRU	127
LAC	128
LACAM	129
LACE	131
LACH	132
LACHAP	133
LACHAS	134
LACHAT	135
LACHAU	136
LACHE	137
LACHM	138
LACI	139
LACK	141
LACO	142
LACOR	143
LACOS	144
LACOU	145
LACR	146
LACRO	147
LACROS	148
LACRU	149
LACT	151
LACY	152
LAD	153
LADD	154
LADI	155
LADO	156
LADR	157
LAE	158
LAF	159
LAFAY	161
LAFE	162
LAFF	163
LAFI	164
LAFO	165
LAFONT	166
LAFOR	167
LAFOS	168
LAFR	169
LAFU	171
LAG	172
LAGAR	173
LAGE	174
LAGI	175
LAGN	176
LAGO	177
LAGR	178
LAGRE	179
LAGU	181
LAGUI	182
LAH	183
LAHO	184
LAI	185
LAIN	186
LAING	187
LAIR	188
LAIS	189
LAJ	191
LAK	192
LAL	193
LALANN	194
LALI	195
LALL	196
LALLE	197
LALLI	198
LALLO	199
LALLY	211
LALO	212
LAM	213
LAMAN	214
LAMAR	215
LAMARM	216
LAMART	217
LAMB	218
LAMBA	219
LAMBE	221
LAMBERT	222
LAMBERTI	223
LAMBI	224
LAMBO	225
LAMBR	226
LAMBT	227
LAME	228
LAMET	229
LAMI	231
LAMIR	232
LAMO	233
LAMON	234
LAMOT	235
LAMOU	236
LAMP	237
LAMPI	238
LAMPR	239
LAMS	241
LAMY	242
LAN	243
LANC	244
LANCASTER, M.	245
LANCE	246
LANCEL	247
LANCEY	248
LANCI	249
LANCO	251
LANCR	252
LAND	253
LANDE	254
LANDER	255
LANDES	256
LANDI	257
LANDO	258
LANDON	259
LANDOR	261
LANDR	262
LANDS	263
LANDU	264
LANE	265
LANEH	267
LANE, M.	266
LANF	268
LANG	269
LANGD	272
LANGDO	273
LANGE	274
LANGEN	275
LANGER	276
LANGET	277
LANGF	278
LANGH	279
LANGI	281
LANGL	282
LANGLE	283
LANGLO	284
LANG, M.	271
LANGR	285
LANGT	286
LANGU	287
LANJ	288
LANK	289
LANM	291
LANN	292
LANO	293
LANS	294
LANSD	295
LANT	296
LANZ	297
LAO	298
LAP	299
LAPE	311
LAPH	312
LAPI	313
LAPL	314
LAPO	315
LAPP	316
LAPR	317
LAR	318
LARC	319
LARD	321
LARG	322
LARI	323
LARK	324
LARN	325
LARO	326
LAROCHEF	327
LAROCHEJ	328
LAROM	329
LARON	331
LAROU	332
LARR	333
LARRI	334
LART	335
LARU	336
LAS	337
LASAL	338
LASAN	339
LASC	341
LASCO	342
LASE	343
LASI	344
LASK	345
LASS	346
LASSE	347
LASSU	348
LAST	349
LAT	351
LATH	352
LATHR	353
LATHROP, G.	354
LATHROP, M.	355
LATI	356
LATIM	357
LATO	358
LATOUR	359
LATOURR	361
LATR	362
LATRI	363
LATRO	364
LATU	365
LAU	366
LAUD	367
LAUDE	368
LAUDERD	369
LAUDI	371
LAUDO	372
LAUF	373
LAUG	374
LAUM	375
LAUN	376
LAUR	377
LAURE	378
LAURENC	379
LAURENS	381
LAURENT	382
LAURENTI	383
LAURI	384
LAURIE	385
LAURIS	386
LAURO	387
LAUS	388
LAUT	389
LAUV	391
LAV	392
LAVALE	393
LAVALH	395
LAVALL	394
LAVAR	396
LAVAT	397
LAVAU	398
LAVE	399
LAVI	411
LAVIL	412
LAVIS	413
LAVO	414
LAW	415
LAWE	417
LAWL	418
LAW, M.	416
LAWRENCE	419
LAWRENCE, C.	421
LAWRENCE, M.	422
LAWRENCE, S.	423
LAWRENCE, W.	424
LAWS	425
LAY	426
LAYC	427
LAYN	428
LAYT	429
LAZ	431
LAZZ	432
LE	433
LEAC	434
LEAK	435
LEAM	436
LEAN	437
LEAR	438
LEAV	439
LEB	441
LEBE	442
LEBER	443
LEBI	444
LEBL	445
LEBLO	446
LEBO	447
LEBOR	448
LEBOU	449
LEBR	451
LEBRET	452
LEBRI	453
LEBRU	454
LEC	455
LECAR	456
LECC	457
LECH	458
LECHE	459
LECK	461
LECL	462
LECLU	463
LECO	464
LECOM	465
LECON	466
LECOQ	467
LECOU	468
LECR	469
LECT	471
LED	472
LEDE	473
LEDO	474
LEDR	475
LEDY	476
LEE	477
LEEC	483
LEED	484
LEE, G.	478
LEEK	485
LEE, M.	479
LEEN	486
LEES	487
LEE, S.	481
LEE, W.	482
LEF	488
LEFEBV	489
LEFER	491
LEFEU	492
LEFEV	493
LEFO	494
LEFR	495
LEG	496
LEGAR	497
LEGAT	498
LEGE	499
LEGEN	511
LEGER	512
LEGG	513
LEGI	514
LEGN	515
LEGO	516
LEGR	517
LEGRAS	518
LEGRO	519
LEGU	521
LEH	522
LEHM	523
LEHO	524
LEI	525
LEIC	526
LEID	527
LEIG	528
LEIGH, M.	529
LEIN	531
LEIS	532
LEIT	533
LEJ	534
LEJO	535
LEK	536
LEL	537
LELAND, M.	538
LELE	539
LELI	541
LELL	542
LELO	543
LEM	544
LEMAI	545
LEMAIS	546
LEMAIT	547
LEMAR	548
LEMAS	549
LEME	551
LEMERE	552
LEMET	553
LEMI	554
LEMO	555
LEMON	556
LEMONN	557
LEMOT	558
LEMOY	559
LEMP	561
LEMU	562
LEN	563
LEND	564
LENE	565
LENG	566
LENN	567
LENNOX	568
LENO	569
LENOIR	571
LENOR	572
LENS	573
LENT	574
LENZ	575
LEO	576
LEOD	577
LEOF	578
LEON	579
LEONARD	581
LEONC	582
LEONE	583
LEONH	584
LEONI	585
LEONT	586
LEOP	587
LEOT	588
LEOW	589
LEP	591
LEPAI	592
LEPAU	593
LEPE	594
LEPELL	595
LEPI	596
LEPL	597
LEPO	598
LEPR	599
LEPS	611
LEPU	612
LEQ	613
LER	614
LERD	615
LERM	616
LERO	617
LEROUX	618
LEROY	619
LEROY, M.	621
LES	622
LESB	623
LESC	624
LESCH	625
LESCO	626
LESCU	627
LESD	628
LESG	629
LESL	631
LESLEY	632
LESLEY, M.	633
LESLIE	634
LESLIE, G.	635
LESLIE, M.	636
LESLIE, S.	637
LESS	638
LESSI	639
LESSO	641
LEST	642
LESTR	643
LESU	644
LET	645
LETELL	646
LETH	647
LETI	648
LETO	649
LETT	651
LEU	652
LEUL	653
LEUS	654
LEV	655
LEVAS	656
LEVE	657
LEVER	658
LEVERE	661
LEVER, M.	659
LEVES	662
LEVET	663
LEVI	664
LEVIN	665
LEVIS	666
LEVR	667
LEVY	668
LEW	669
LEWE	671
LEWIN	672
LEWIS	673
LEWIS, G.	674
LEWIS, M.	675
LEWIS, S.	676
LEWIS, W.	677
LEWK	678
LEX	679
LEY	681
LEYBU	682
LEYD	683
LEYL	684
LEYS	685
LEZ	686
LEZO	687
LH	688
LHEU	689
LHO	671
LHU	692
LI	693
LIB	694
LIBER	695
LIBO	696
LIBR	697
LIC	698
LICHT	699
LICI	711
LID	712
LIDDO	713
LIDE	714
LIDO	715
LIE	716
LIEBN	717
LIEC	718
LIEF	719
LIEU	721
LIEV	722
LIG	723
LIGHTF	724
LIGN	725
LIGO	726
LIGU	727
LIL	728
LILL	729
LILY	731
LIM	732
LIMB	733
LIMI	734
LIN	735
LINC	736
LINCOLN, G.	737
LINCOLN, M.	738
LINCOLN, S.	739
LINCOLN, W.	741
LIND	742
LINDE	743
LINDEN	744
LINDES	745
LINDL	746
LINDN	747
LINDS	748
LINDSAY, M.	749
LINDSEL	751
LINDSEY	752
LINDSEY, M.	753
LINDW	754
LING	755
LINI	756
LINL	757
LINN	758
LINS	759
LINT	761
LINW	762
LIO	763
LIP	764
LIPP	765
LIPPM	766
LIPS	767
LIR	768
LIS	769
LISL	771
LISS	772
LIST	773
LISZ	774
LIT	775
LITCH	776
LITTE	777
LITTL	778
LITTLEB	779
LITTLET	781
LITTR	782
LIU	783
LIV	784
LIVERMORE, M.	785
LIVINGS	786
LIVINGSTONE	788
LIVINGSTON, M.	787
LIZ	789
LL	791
LLO	792
LLOYD	793
LLY	794
LO	795
LOB	796
LOBE	797
LOBK	798
LOBO	799
LOC	811
LOCH	812
LOCK	813
LOCKE	814
LOCKER	815
LOCKH	816
LOCKW	817
LOCKY	818
LOCO	819
LOD	821
LODG	822
LODI	823
LODO	824
LOE	825
LOES	826
LOEW	827
LOF	828
LOFT	829
LOG	831
LOGE	832
LOH	833
LOI	834
LOISEL	835
LOK	836
LOL	837
LOLM	838
LOM	839
LOMBARD	841
LOMBARDI	842
LOMBE	843
LOMBR	844
LOME	845
LOMO	846
LON	847
LONG	848
LONGC	851
LONGE	852
LONGF	853
LONGH	854
LONGI	855
LONGL	856
LONG, M.	849
LONGS	857
LONGU	858
LONGUS	859
LONI	861
LONS	862
LOO	863
LOP	864
LOR	865
LORD	866
LORD, M.	867
LORE	868
LORENZ	869
LORG	871
LORI	872
LORING	873
LORING, M.	874
LORM	875
LORR	876
LORRY	877
LORT	878
LOS	879
LOSO	881
LOT	882
LOTI	883
LOTT	884
LOTZ	885
LOU	886
LOUG	887
LOUI	888
LOUN	889
LOUP	891
LOUR	892
LOUT	893
LOUV	894
LOUVO	895
LOV	896
LOVE	897
LOVEL	898
LOVELL	899
LOVELL, M.	911
LOW	912
LOWE	913
LOWELL	914
LOWELL, G.	915
LOWELL, M.	916
LOWELL, S.	917
LOWI	918
LOWN	919
LOWR	921
LOWT	922
LOY	923
LOYS	924
LOZ	925
LU	926
LUBBO	927
LUBE	928
LUBI	929
LUC	931
LUCAN	932
LUCAS	933
LUCC	934
LUCE	935
LUCH	936
LUCI	937
LUCIN	938
LUCIU	939
LUCK	941
LUCR	942
LUCY	943
LUD	944
LUDL	945
LUDO	946
LUDR	947
LUDW	948
LUF	949
LUG	951
LUI	952
LUIS	953
LUK	954
LUL	955
LULLY	956
LUM	957
LUML	958
LUMS	959
LUN	961
LUND	962
LUNG	963
LUNT	964
LUP	965
LUPT	966
LUR	967
LUS	968
LUSH	969
LUSI	971
LUSS	972
LUT	973
LUTO	974
LUTZ	975
LUV	976
LUX	977
LUY	978
LUZ	979
LY	981
LYCU	982
LYD	983
LYE	984
LYND	988
LYNN	989
LYO	991
LYR	992
LYS	993
LYSI	994
LYSO	995
LYT	996
LYTTL	997
LYTTO	998
LYV	999
MA	111
MAB	112
MAC	113
MACAL	114
MACAR	115
MACART	116
MACAU	117
MACB	118
MACBR	119
MACC	121
MACCAL	122
MACCAR	123
MACCH	124
MACCI	125
MACCL	126
MACCLI	127
MACCLU	128
MACCO	129
MACCOR	131
MACCR	132
MACCU	133
MACD	134
MACDON	135
MACDONN	136
MACDOU	137
MACDOW	138
MACDU	139
MACE	141
MACER	142
MACF	143
MACFI	144
MACG	145
MACGO	146
MACGR	147
MACGU	148
MACH	149
MACHO	151
MACI	152
MACK	153
MACKE	154
MACKEN	155
MACKENZ	156
MACKENZIE, M.	157
MACKI	158
MACKN	159
MACL	161
MACLAY	162
MACLE	163
MACLEL	164
MACLEO	165
MACLU	166
MACM	167
MACMU	168
MACN	169
MACO	171
MACP	172
MACQ	173
MACR	174
MACS	175
MACV	176
MACW	177
MAD	178
MADD	179
MADE	181
MADI	182
MADO	183
MAE	184
MAEL	185
MAES	186
MAF	187
MAG	188
MAGAT	189
MAGE	191
MAGER	192
MAGG	193
MAGI	194
MAGL	195
MAGN	196
MAGNI	197
MAGNO	198
MAGNU	199
MAGO	211
MAGR	212
MAGU	213
MAH	214
MAHM	215
MAHO	216
MAI	217
MAIG	218
MAIL	219
MAILLE	221
MAILLY	222
MAIM	223
MAIN	224
MAINE	225
MAINT	226
MAINW	227
MAIR	228
MAIRO	229
MAIS	231
MAIT	232
MAJ	233
MAJO	234
MAK	235
MAL	236
MALAN	237
MALAS	238
MALAT	239
MALB	241
MALC	242
MALCO	243
MALD	244
MALE	245
MALES	246
MALET	247
MALEV	248
MALH	249
MALI	251
MALL	252
MALLET	253
MALLI	254
MALLO	255
MALM	256
MALO	257
MALOU	258
MALP	259
MALT	261
MALV	262
MAM	263
MAME	264
MAMI	265
MAN	266
MANAS	267
MANC	268
MANCI	269
MAND	271
MANDER	272
MANDR	273
MANE	274
MANET	275
MANF	276
MANG	277
MANI	278
MANL	279
MANN	281
MANNI	283
MANNING, M.	284
MANN, M.	282
MANNO	285
MANS	286
MANSF	287
MANSI	288
MANSO	289
MANT	291
MANTEL	292
MANTO	293
MANU	294
MANV	295
MANZ	296
MAP	297
MAR	298
MARAI	299
MARAN	311
MARB	312
MARC	313
MARCEL	314
MARCH	315
MARCHE	316
MARCHET	317
MARCHM	318
MARCI	319
MARCO	321
MARCU	322
MARE	323
MAREN	324
MARES	325
MARET	326
MARG	327
MARGE	328
MARGO	329
MARGU	331
MARI	332
MARIAN	333
MARIE	334
MARIG	335
MARIL	336
MARIN	337
MARINE	338
MARINI	339
MARIO	341
MARIOT	342
MARIU	343
MARJ	344
MARK	345
MARKL	346
MARL	347
MARLI	348
MARLO	349
MARM	351
MARMON	352
MARN	353
MARO	354
MAROT	355
MAROU	356
MARQ	357
MARR	358
MARRI	359
MARRO	361
MARRY	362
MARS	363
MARSD	364
MARSH	365
MARSHALL	367
MARSHALL, G.	368
MARSHALL, M.	369
MARSHM	371
MARSH, M.	366
MARSI	372
MARSO	373
MARST	374
MART	375
MARTEL	376
MARTEN	377
MARTI	378
MARTIN	379
MARTIND	384
MARTINE	385
MARTIN, G.	381
MARTINI	386
MARTIN, M.	382
MARTIN, S.	383
MARTO	387
MARTY	388
MARU	389
MARV	391
MARX	392
MARY	393
MAS	394
MASC	395
MASE	396
MASH	397
MASO	398
MASON, G.	399
MASON, M.	411
MASON, S.	412
MASQ	413
MASS	414
MASSE	415
MASSEY	416
MASSI	417
MASSING	418
MASSO	419
MASSON, M.	421
MASSU	422
MAST	423
MASU	424
MAT	425
MATH	426
MATHER	427
MATHEW	428
MATHEWS	429
MATHI	431
MATHO	432
MATI	433
MATS	434
MATT	435
MATTH	436
MATTHEW	437
MATTHEWS	438
MATTHEWS, G.	439
MATTHEWS, M.	441
MATTHEWS, S.	442
MATTHI	443
MATTI	444
MATY	445
MAU	446
MAUDS	447
MAUG	448
MAUN	451
MAUP	452
MAUR	453
MAURI	454
MAURICE, M.	455
MAURIT	456
MAURO	457
MAURU	458
MAURY	459
MAV	461
MAW	462
MAX	463
MAXI	464
MAXW	465
MAY	466
MAYER	468
MAYH	469
MAY, M.	467
MAYN	471
MAYNE	472
MAYO	473
MAYR	474
MAZ	475
MAZE	476
MAZZ	477
MAZZON	478
ME	479
MEADE	481
MEADO	482
MEAN	483
MEAS	484
MEB	485
MEC	486
MECK	487
MED	488
MEDI	489
MEDIN	491
MEDO	492
MEDU	493
MEE	494
MEER	495
MEG	496
MEGER	497
MEH	498
MEI	499
MEIER	511
MEIG	512
MEIL	513
MEIN	514
MEIS	515
MEJ	516
MEL	517
MELC	518
MELE	519
MELF	521
MELI	522
MELIS	523
MELL	524
MELLEN	525
MELLI	526
MELLO	527
MELO	528
MELU	529
MELV	531
MELZ	532
MEM	533
MEN	534
MENAR	535
MENC	536
MEND	537
MENDES	538
MENDO	539
MENE	541
MENEN	542
MENES	543
MENG	544
MENI	545
MENL	546
MENN	547
MENS	548
MENT	549
MENZ	551
MER	552
MERC	553
MERCER	554
MERCI	555
MERCO	556
MERCY	557
MERE	558
MEREDITH	559
MERI	561
MERIN	562
MERIV	563
MERL	564
MERLI	565
MERM	566
MERO	567
MERR	568
MERRIF	569
MERRIL	571
MERRIT	572
MERRY	573
MERS	574
MERT	575
MERV	576
MERZ	577
MES	578
MESM	579
MESN	581
MESNI	582
MESS	583
MESSE	584
MESSI	585
MEST	586
MET	587
METC	588
METE	589
METEY	591
METH	592
METO	593
METR	594
METT	595
METZ	596
MEU	597
MEUR	598
MEUS	599
MEW	611
MEY	612
MEYER, M.	613
MEYN	614
MEYR	615
MEYS	616
MEZ	617
MI	618
MIC	619
MICH	621
MICHAU	622
MICHE	623
MICHI	624
MICHO	625
MICO	626
MID	627
MIDDLETON	628
MIDDLETON, M.	629
MIE	631
MIER	632
MIF	633
MIG	634
MIGN	635
MIGNO	636
MIL	637
MILB	638
MILC	639
MILD	641
MILE	642
MILES	643
MILF	644
MILL	645
MILLE	646
MILLER	647
MILLER, G.	648
MILLER, M.	649
MILLER, S.	651
MILLER, W.	652
MILLET	653
MILLI	654
MILLIN	655
MILLO	656
MILLS	657
MILM	658
MILN	659
MILO	661
MILTS	662
MIN	663
MINE	664
MINI	665
MINO	666
MINT	667
MINU	668
MIO	669
MIR	671
MIRAN	672
MIRB	673
MIRE	674
MIRI	675
MIRO	676
MIRZ	677
MIS	678
MIT	679
MITCHELL	681
MITCHELL, M.	682
MITF	683
MITH	684
MITT	685
MN	686
MO	687
MOCE	688
MOD	689
MODES	671
MODI	692
MOE	693
MOER	694
MOF	695
MOG	696
MOH	697
MOHL	698
MOHR	699
MOHU	711
MOI	712
MOIR	713
MOIS	714
MOIT	715
MOK	716
MOL	717
MOLE	718
MOLES	719
MOLI	721
MOLIN	722
MOLINI	723
MOLIS	724
MOLIT	725
MOLL	726
MOLLO	727
MOLO	728
MOLT	729
MOLY	731
MOM	732
MOMM	733
MON	734
MONAL	735
MONAS	736
MONC	737
MONCL	738
MONCR	739
MOND	741
MONE	742
MONG	743
MONI	744
MONK	745
MONL	746
MONM	747
MONN	748
MONNI	749
MONO	751
MONR	752
MONROE	753
MONS	754
MONSO	755
MONSR	756
MONT	757
MONTAG	758
MONTAGUE	759
MONTAI	761
MONTAL	762
MONTALE	763
MONTAN	764
MONTANO	765
MONTAR	766
MONTAU	767
MONTB	768
MONTBR	769
MONTC	771
MONTE	772
MONTEB	773
MONTEF	774
MONTEG	775
MONTEL	776
MONTEM	777
MONTER	778
MONTES	779
MONTESS	781
MONTF	782
MONTFL	783
MONTFO	784
MONTG	785
MONTGO	786
MONTGOM	787
MONTGOMERY, M.	788
MONTH	789
MONTI	791
MONTIG	792
MONTL	793
MONTLU	794
MONTM	795
MONTMI	796
MONTMO	797
MONTO	798
MONTP	799
MONTR	811
MONTRI	812
MONTRO	813
MONTV	814
MONU	815
MONZ	816
MOO	817
MOON	818
MOOR	819
MOORE	821
MOORE, G.	822
MOORE, M.	823
MOORE, S.	824
MOORE, W.	825
MOQ	826
MOR	827
MORAL	828
MORAN	829
MORAT	831
MORAZ	832
MORC	833
MORD	834
MORE	835
MOREAU	837
MOREH	838
MOREL	839
MORELL	841
MORELLI	842
MORE, M.	836
MOREN	843
MORET	844
MORETI	845
MORF	846
MORG	847
MORGAN, G.	848
MORGAN, M.	849
MORGE	851
MORGEUS	852
MORI	854
MORIE	855
MORIG	856
MORIL	857
MORIN	858
MORINI	859
MORIS	861
MORIT	862
MORL	863
MORLE	864
MORLO	865
MORN	866
MORO	867
MORON	868
MOROS	869
MOROZ	871
MORR	872
MORRELL	873
MORRI	874
MORRIS	875
MORRIS, G.	876
MORRIS, M.	877
MORRISON	878
MORRISON, G.	879
MORRISON, M.	881
MORRISON, S.	882
MORRISON, W.	883
MORS	884
MORSE, G.	885
MORSE, M.	886
MORT	887
MORTH	853
MORTI	888
MORTO	889
MORTON, M.	891
MORV	892
MORY	893
MOS	894
MOSCH	895
MOSCHO	896
MOSE	897
MOSEL	898
MOSER	899
MOSES	911
MOSL	912
MOSS	913
MOSSO	914
MOST	915
MOSTO	916
MOT	917
MOTH	918
MOTL	919
MOTT	921
MOTTE	922
MOTZ	923
MOU	924
MOUF	925
MOUL	926
MOULT	927
MOUN	928
MOUR	929
MOURE	931
MOUS	932
MOUSS	933
MOUT	934
MOV	935
MOW	936
MOX	937
MOY	938
MOZ	939
MU	941
MUC	942
MUD	943
MUDG	944
MUDI	945
MUEL	946
MUELLER, M.	947
MUEN	948
MUF	949
MUG	951
MUH	952
MUI	953
MUL	954
MULF	955
MULG	956
MULL	958
MULLI	959
MULR	961
MUM	962
MUN	963
MUNCK	964
MUND	965
MUNF	966
MUNO	967
MUNR	968
MUNS	969
MUNT	971
MUR	972
MURC	973
MURD	974
MURE	975
MURG	976
MURI	977
MURP	978
MURR	979
MURRAY	981
MURRAY, G.	982
MURRAY, M.	983
MURRAY, S.	984
MUS	985
MUSE	986
MUSG	987
MUSP	988
MUSS	989
MUST	991
MUT	992
MUTR	993
MY	995
MYE	996
MYL	997
MYR	998
MYT	999
NA	111
NAAS	112
NAB	113
NABB	114
NABE	115
NABI	116
NABO	117
NAC	118
NACH	119
NACHI	121
NACHM	122
NACHO	123
NACHT	124
NACK	125
NAD	126
NADAL	127
NADAR	128
NADAS	129
NADAST	131
NADAU	132
SKR	629
NADE	134
NADER	135
NADI	136
NADJ	137
NADO	138
NAE	139
NAEG	141
NAEK	142
NAEL	143
NAER	144
NAEV	145
NAF	146
NAG	147
NAGI	148
NAGL	149
NAGLI	151
NAGO	152
NAH	153
NAHL	154
NAI	155
NAIL	156
NAIM	157
NAIR	158
NAIT	159
NAIV	161
NAJ	162
NAK	163
NAKW	164
NAL	165
NALDI	166
NALDIN	167
NALDO	168
NALE	169
NALI	171
NALL	172
NALS	173
NAM	174
NAN	175
NANC	176
NANE	177
NANG	178
NANI	179
NANIN	181
NANINI	182
NANN	183
NANNI	184
NANNO	185
NANNU	186
NANQ	187
NANS	188
NANSO	189
NANT	191
NANTEU	192
NANTI	193
NAO	194
NAP	195
NAPIER	196
NAPIER, C.	197
NAPIER, F.	198
NAPIER, J.	199
NAPIER, M.	211
NAPIER, S.	212
NAPIER, W.	213
NAPIO	214
NAPL	215
NAPO	216
NAPP	217
NAR	218
NARBO	219
NARBOR	221
NARC	222
NARD	223
NARDIN	224
NARE	225
NARES	226
NARES, M.	227
NARG	228
NARI	229
NARIN	231
NARN	232
NARP	233
NARR	234
NARS	235
NARST	236
NARU	237
NARV	238
NARVY	239
NAS	241
NASAF	242
NASAL	243
NASC	244
NASCO	245
NASE	246
NASER	247
NASH	248
NASH, F.	249
NASH, J.	251
NASH, M.	252
NASH, S.	253
NASI	254
NASM	255
NASMITH	256
NASMITH, M.	257
NASMYTH	258
NASMYTH, M.	259
NASO	261
NASOL	262
NASON	263
NASR	264
NASS	265
NASSAU	266
NASSE	267
NASSI	268
NAST	269
NAT	271
NATALI	272
NATAR	273
NATH	274
NATHANS	275
NATHU	276
NATI	277
NATIV	278
NATO	279
NATT	281
NATTE	282
NATTI	283
NATTO	284
NATU	285
NATZ	286
NAU	287
NAUB	288
NAUC	289
NAUD	291
NAUDAL	133
NAUDET	292
NAUDI	293
NAUDO	294
NAUE	295
NAUER	296
NAUG	297
NAUL	298
NAUM	299
NAUMANN, M.	311
NAUN	312
NAUS	313
NAUSS	314
NAUZ	315
NAV	316
NAVAG	317
NAVAI	318
NAVAR	319
NAVARR	321
NAVARRO	322
NAVE	323
NAVEZ	324
NAVI	325
NAVIL	326
NAVO	327
NAW	328
NAWR	329
NAY	331
NAYLI	332
NAYLO	333
NAZ	334
NAZAR	335
NAZO	336
NAZZ	337
NE	338
NEALE	345
NEALE, G.	346
NEALE, M.	347
NEALE, S.	348
NEAL, F.	339
NEAL, J.	341
NEAL, M.	342
NEAL, S.	343
NEAL, W.	344
NEANDER	349
NEANDER, J.	351
NEANDER, P.	352
NEAP	353
NEAR	354
NEAT	355
NEATE	356
NEAV	357
NEB	358
NEBE	359
NEBEN	361
NEBR	362
NEBU	363
NEC	364
NECK	365
NECKER	366
NECKER, M.	367
NECO	368
NECT	369
NED	371
NEE	372
NEEB	373
NEED	374
NEEDHAM, M.	375
NEEF	376
NEEFE	377
NEEL	378
NEELE	379
NEER	381
NEES	382
NEF	383
NEG	384
NEGR	385
NEGRI	386
NEGRIER	392
NEGRI, G.	387
NEGRI, M.	388
NEGRI, S.	389
NEGRI, W.	391
NEGRO	393
NEGRON	394
NEH	395
NEHR	396
NEI	397
NEIL	398
NEILE	399
NEILL	411
NEILL, J.	412
NEILL, P.	413
NEILS	414
NEIP	415
NEIS	416
NEIT	417
NEK	418
NEL	419
NELL	421
NELLI	422
NELLO	423
NELS	424
NELSON, C.	425
NELSON, F.	426
NELSON, J.	427
NELSON, M.	428
NELSON, R.	429
NELSON, S.	431
NELSON, W.	432
NEM	433
NEMI	434
NEMN	435
NEMO	436
NEN	437
NEO	438
NEP	439
NEPO	441
NEPOS	442
NER	443
NERE	444
NERI	445
NERIN	446
NERIT	447
NERL	448
NERO	449
NEROC	451
NERON	452
NERS	453
NERU	454
NERV	455
NERVET	456
NES	457
NESB	458
NESE	459
NESL	461
NESM	462
NESS	463
NESSEL	464
NESSI	465
NESSM	466
NESSO	467
NEST	468
NET	469
NETS	471
NETT	472
NETTE	473
NETTER	474
NETTL	475
NETTLETON, M.	476
NEU	477
NEUBE	478
NEUD	479
NEUE	481
NEUF	482
NEUFV	483
NEUG	484
NEUH	485
NEUK	486
NEUL	487
NEUM	488
NEUMAN	489
NEUMAN, G.	491
NEUMAN, M.	492
NEUMAR	493
NEUN	494
NEUS	495
NEUSI	496
NEUT	497
NEUV	498
NEV	499
NEVE	511
NEVEL	512
NEVER	513
NEVERS	514
NEVERS, G.	515
NEVERS, M.	516
NEVERS, S.	517
NEVERS, W.	518
NEVEU	519
NEVI	521
NEVILL	522
NEVILLE	523
NEVILLE, J.	524
NEVILLE, P.	525
NEVIN	526
NEVINS	527
NEVINS, M.	528
NEVIT	529
NEVY	531
NEW	532
NEWB	533
NEWBE	534
NEWBU	535
NEWC	536
NEWCO	537
NEWCOMBE	539
NEWCOMB, M.	538
NEWCOME	541
NEWD	542
NEWE	543
NEWELL	544
NEWELL, G.	545
NEWELL, M.	546
NEWELL, S.	547
NEWH	548
NEWL	549
NEWMAN, D.	552
NEWMAN, J.	553
NEWMAN, M.	554
NEWMAN, S.	555
NEWMAN, W.	556
NEWN	557
NEWP	558
NEWT	559
NEWTON	561
NEWTON, C.	562
NEWTON, F.	563
NEWTON, J.	564
NEWTON, M.	565
NEWTON, S.	566
NEWTON, W.	567
NEY	568
NEY, J.	569
NEYLP	572
NEYN	573
NEY, P.	571
NEYR	574
NEZ	575
NG	576
NI	577
NIB	578
NIBE	579
NIBO	581
NIC	582
NICAN	583
NICC	584
NICCOLI	585
NICCOLINI	586
NICCOLO	587
NICE	588
NICEP	589
NICER	591
NICET	592
NICETAS	593
NICH	594
NICHOL	595
NICHOLAS	597
NICHOLAS, J.	598
NICHOLAS, P.	599
NICHOLL	611
NICHOLL, M.	612
NICHOLLS	613
NICHOLLS, G.	614
NICHOLLS, M.	615
NICHOL, M.	596
NICHOLS	616
NICHOLS, C.	617
NICHOLS, F.	618
NICHOLS, J.	619
NICHOLS, M.	621
NICHOLSON	624
NICHOLSON, D.	625
NICHOLSON, J.	626
NICHOLSON, M.	627
NICHOLSON, S.	628
NICHOLSON, W.	629
NICHOLS, S.	622
NICHOLS, W.	623
NICI	631
NICK	632
NICO	633
NICOL	634
NICOLAI	635
NICOLAI, J.	636
NICOLAI, P.	637
NICOLAS	638
NICOLAU	639
NICOLAY	641
NICOLE	642
NICOLET	643
NICOLI	644
NICOLL	645
NICOLLET	646
NICOLLS	647
NICOLLS, J.	648
NICOLLS, P.	649
NICOLO	651
NICOLS	652
NICOLSON	653
NICOLSON, M.	654
NICOM	655
NICOME	656
NICON	657
NICOP	658
NICOR	659
NICOS	661
NICOT	662
NICOU	663
NID	664
NIE	665
NIED	666
NIEL	667
NIELL	668
NIELS	669
NIEM	671
NIEME	672
NIEMO	673
NIEP	674
NIER	675
NIERO	676
NIET	677
NIEU	678
NIEUL	679
NIEUP	681
NIEUW	682
NIF	683
NIG	684
NIGER	685
NIGET	686
NIGH	687
NIGHTENGALE, M.	688
NIGR	689
NIH	691
NIK	692
NIKO	693
NIKON	694
NIL	695
NILES	696
NILES, D.	697
NILES, L.	698
NILES, M.	699
NILES, S.	711
NILES, W.	712
NIM	713
NIN	714
NINI	715
NINO	716
NINU	717
NIO	718
NIP	719
NIQ	721
NIS	722
NISB	723
NISBET, M.	724
NISL	725
NISS	726
NISSO	727
NIT	728
NITH	729
NITO	731
NITS	732
NITT	733
NIV	734
NIVER	735
NIX	736
NIZ	737
NJ	738
NO	739
NOAIL	741
NOAILLES, M.	742
NOAK	743
NOB	744
NOBI	745
NOBL	746
NOBLE	747
NOBLE, D.	748
NOBLE, J.	749
NOBLE, M.	751
NOBLE, S.	752
NOBLE, W.	753
NOBR	754
NOBY	755
NOC	756
NOCH	757
NOCI	758
NOCR	759
NOD	761
NODU	762
NOE	763
NOED	764
NOEL	765
NOEL, D.	766
NOEL, J.	767
NOEL, M.	768
NOEL, S.	769
NOES	771
NOET	772
NOF	773
NOG	774
NOGARO	775
NOGE	776
NOGH	777
NOGU	778
NOH	779
NOHR	781
NOI	782
NOIRET	783
NOIROT	784
NOK	785
NOL	786
NOLAN	787
NOLAN, J.	788
NOLAN, P.	789
NOLD	791
NOLI	792
NOLL	793
NOLLEK	794
NOLLET	795
NOLLI	796
NOLP	797
NOLT	798
NOM	799
NOMU	811
NON	812
NONI	813
NONN	814
NOO	816
NOOM	817
NOOR	818
NOOT	819
NOP	821
NOR	822
NORBERT	823
NORBERT, M.	824
NORBL	825
NORBY	826
NORC	827
NORD	828
NORDEN	829
NORDENH	831
NORDENS	832
NORDT	833
NORE	834
NORF	835
NORFOLK, J.	836
NORFOLK, P.	837
NORG	838
NORGH	839
NORI	841
NORM	842
NORMANB	844
NORMAND	845
NORMAND, J.	846
NORMAND, P.	847
NORMANDY	848
NORMAN, M.	843
NORMANN	849
NORMANT	851
NORO	852
NORR	853
NORRIS, C.	854
NORRIS, F.	855
NORRIS, J.	856
NORRIS, M.	857
NORRIS, R.	858
NORRIS, S.	859
NORRIS, W.	861
NORRY	862
NORS	863
NORTH	864
NORTHA	868
NORTHAMPTON	869
NORTHAMPTON, M.	871
NORTHB	872
NORTHC	873
NORTHE	874
NORTH, G.	865
NORTH, M.	866
NORTHN	875
NORTHO	876
NORTHR	877
NORTH, S.	867
NORTHU	878
NORTHW	879
NORTHWO	881
NORTO	882
NORTON, C.	883
NORTON, F.	884
NORTON, J.	885
NORTON, M.	886
NORTON, R.	887
NORTON, S.	888
NORTON, W.	889
NORV	891
NORW	892
NORWICH, M.	893
NORWO	894
NORWOOD, M.	895
NORZ	896
NOS	897
NOST	898
NOT	899
NOTE	911
NOTH	912
NOTK	913
NOTR	914
NOTT	915
NOTT, G.	916
NOTTI	919
NOTTINGHAM, M.	921
NOTT, M.	917
NOTTN	922
NOTTO	923
NOTT, S.	918
NOU	924
NOUE	925
NOUET	926
NOUG	927
NOUH	928
NOUL	929
NOUR	931
NOURR	932
NOURS	933
NOUV	934
NOUZ	815
NOV	935
NOVAR	936
NOVE	937
NOVELLI	938
NOVELLO	939
NOVER	941
NOVES	942
NOVI	943
NOVIO	944
NOVIU	945
NOW	946
NOWE	947
NOWELL, M.	948
NOY	949
NOYER	951
NOYES	952
NOYES, C.	953
NOYES, F.	954
NOYES, J.	955
NOYES, M.	956
NOYES, R.	957
NOYES, S.	958
NOYES, W.	959
NOZ	961
NU	962
NUCE	963
NUCI	964
NUG	965
NUGENT	966
NUGENT, J.	967
NUGENT, S.	968
NUL	969
NUM	971
NUN	972
NUNU	973
NUR	974
NUS	975
NUT	976
NUTTA	979
NUTTALL, M.	981
NUTTER	982
NUTTER, G.	983
NUTTER, M.	984
NUTTER, S.	985
NUTTING	986
NUTTING, G.	987
NUTTING, M.	988
NUTT, J.	977
NUTT, P.	978
NUV	989
NUY	991
NYC	994
NYK	995
NYM	996
NYO	997
NYS	998
NYT	999
OA	11
OB	12
OBR	13
OBS	14
OCH	16
OCO	17
OCONN	18
OCOR	19
OCS	15
OCT	21
OD	22
ODE	23
ODI	24
ODO	25
ODON	26
ODR	27
OE	28
OER	29
OF	31
OFF	32
OFL	33
OG	34
OGL	35
OH	36
OHE	37
OHM	38
OI	39
OK	41
OL	42
OLB	43
OLD	44
OLE	45
OLI	46
OLIP	47
OLIV	48
OLIVI	49
OLM	51
OLO	52
OLY	53
OM	54
OME	55
OMO	56
OMU	57
ON	58
ONS	59
OP	61
OPP	62
OR	63
ORB	64
ORD	65
ORE	66
ORF	67
ORG	68
ORI	69
ORL	71
ORLO	72
ORM	73
ORN	74
ORR	75
ORS	76
ORT	77
ORTO	78
ORV	79
OS	81
OSG	82
OSM	83
OSS	84
OST	85
OSW	86
OT	87
OTI	88
OTT	89
OTTL	91
OTW	92
OU	93
OUS	94
OUV	95
OV	96
OW	97
OX	98
OZ	99
PA	111
PAACU	113
PAC	112
PACC	114
PACE	115
PACH	116
PACI	117
PACIN	118
PACK	119
PACO	121
PACU	122
PAD	123
PADO	124
PADU	125
PAE	126
PAEZ	127
PAG	128
PAGANI	129
PAGANO	131
PAGE	132
PAGE, M.	133
PAGEN	134
PAGET	135
PAGI	136
PAGIT	137
PAGL	138
PAGN	139
PAH	141
PAI	142
PAIL	143
PAIN	144
PAINE, G.	145
PAINE, M.	146
PAINE, S.	147
PAINT	148
PAIS	149
PAJ	151
PAK	152
PAL	153
PALAI	154
PALAZ	155
PALE	156
PALES	157
PALEY	158
PALF	159
PALG	161
PALI	162
PALIS	163
PALL	164
PALLAV	165
PALLE	166
PALLI	167
PALLIS	168
PALLU	169
PALM	171
PALME	172
PALMER	173
PALMER, G.	174
PALMER, M.	175
PALMERS	178
PALMER, S.	176
PALMER, W.	177
PALMI	179
PALO	181
PALS	182
PALT	183
PALU	184
PAM	185
PAMPH	186
PAN	187
PANC	188
PAND	189
PANE	191
PANI	192
PANIZ	193
PANN	194
PANO	195
PANS	196
PANT	197
PANTO	198
PANZ	199
PAO	211
PAOLO	212
PAP	213
PAPE	214
PAPI	215
PAPIL	216
PAPIN	217
PAPO	218
PAQ	219
PAR	221
PARAD	222
PARAN	223
PARAV	224
PARC	225
PARD	226
PARE	227
PAREN	228
PARF	229
PARI	231
PARIS	232
PARISH	233
PARISI	234
PARK	235
PARKE	237
PARKER	238
PARKER, F.	239
PARKER, J.	241
PARKER, M.	242
PARKER, S.	243
PARKER, W.	244
PARKES	245
PARKH	246
PARKI	247
PARKINSON, M.	248
PARK, M.	236
PARKMAN	249
PARKMAN, M.	251
PARKS	252
PARM	253
PARMENT	254
PARMI	255
PARN	256
PARO	257
PARR	258
PARRI	261
PARR, M.	259
PARRO	262
PARROT	263
PARRY	264
PARRY, M.	265
PARS	266
PARSONS	267
PARSONS, G.	268
PARSONS, M.	269
PARSONS, S.	271
PARSONS, W.	272
PART	273
PARTO	274
PARTR	275
PARV	276
PAS	277
PASC	278
PASCH	279
PASCO	281
PASI	282
PASO	283
PASQ	284
PASS	285
PASSAN	286
PASSE	287
PASSI	288
PASSO	289
PAST	291
PASTO	292
PASTOR	293
PAT	294
PATE	295
PATERS	296
PATERSON, M.	297
PATI	298
PATIS	299
PATM	311
PATO	312
PATOU	313
PATR	314
PATT	315
PATTEN	316
PATTERSON	317
PATTERSON, M.	318
PATTES	319
PATTI	321
PATTO	322
PAU	323
PAUL	324
PAULD	325
PAULE	326
PAULI	327
PAULIN	328
PAULL	329
PAULM	331
PAULS	332
PAULU	333
PAUS	334
PAUT	335
PAUW	336
PAV	337
PAVI	338
PAVO	339
PAX	341
PAXT	342
PAY	343
PAYER	344
PAYN	345
PAYNE	346
PAYS	347
PAZ	348
PE	349
PEABODY	351
PEABODY, G.	352
PEABODY, M.	353
PEABODY, S.	354
PEAC	355
PEACO	356
PEAK	357
PEAL	358
PEAR	359
PEARS	361
PEARSON, M.	362
PEAS	363
PEC	364
PECC	365
PECK	366
PECKH	368
PECK, M.	367
PECO	369
PED	371
PEDRO	372
PEE	373
PEEL	374
PEER	375
PEG	376
PEIRC	378
PEIRS	379
PEL	381
PELET	382
PELH	383
PELI	384
PELL	385
PELLE	386
PELLER	387
PELLET	388
PELLEW	389
PELLI	391
PELLO	392
PELT	393
PEMB	394
PEMBR	396
PEMERTON, M.	395
PEN	397
PENDL	398
PENH	399
PENI	411
PENN	412
PENNEL	413
PENNI	414
PENNO	415
PENNY	416
PENR	417
PENS	418
PENT	419
PEP	421
PEPI	422
PEPO	423
PEPP	424
PEPY	425
PER	426
PERAU	427
PERC	428
PERCI	429
PERCY	431
PERCY, M.	432
PERD	433
PERE	434
PEREG	435
PEREI	436
PEREL	437
PEREZ	438
PERG	439
PERI	441
PERIER	442
PERIG	443
PERIGO	444
PERIN	445
PERIS	446
PERK	447
PERKINS	448
PERKINS, J.	449
PERKINS, P.	451
PERN	452
PERO	453
PERR	454
PERRE	455
PERRI	456
PERRIER	457
PERRIN	458
PERRO	459
PERROT	461
PERRY	462
PERRY, G.	463
PERRY, M.	464
PERRY, S.	465
PERS	466
PERSO	467
PERT	468
PERTI	469
PERU	471
PES	472
PESC	473
PESE	474
PESS	475
PEST	476
PET	477
PETER	478
PETERB	479
PETERS	481
PETERSEN	484
PETERS, J.	482
PETERSON	485
PETERS, P.	483
PETH	486
PETI	487
PETIS	488
PETIT	489
PETITO	491
PETO	492
PETR	493
PETREI	494
PETRI	495
PETRIN	496
PETRO	497
PETRU	498
PETT	499
PETTI	511
PETTY	512
PETZ	513
PEU	514
PEY	515
PEYRO	516
PEYS	517
PEYST	518
PEYT	519
PEZ	521
PEZR	522
PF	523
PFE	524
PFEI	525
PFEIFFER	526
PFEIFFER, M.	527
PFEN	528
PFI	529
PFL	531
PH	532
PHAL	533
PHALE	534
PHAN	535
PHAR	536
PHE	537
PHEL	538
PHELPS, J.	539
PHELPS, P.	541
PHER	542
PHI	543
PHIL	544
PHILB	545
PHILE	546
PHILI	547
PHILID	548
PHILIP	549
PHILIPP	551
PHILIPPI	552
PHILIPPU	553
PHILIPS	554
PHILIPS, M.	555
PHILL	556
PHILLIP	557
PHILLIPS	558
PHILLIPS, F.	559
PHILLIPS, J.	561
PHILLIPS, M.	562
PHILLIPS, S.	563
PHILLIPS, W.	564
PHILO	565
PHILOC	566
PHILOM	567
PHILOS	568
PHILOX	569
PHILP	571
PHIN	572
PHIP	573
PHO	574
PHOR	575
PHR	576
PHRY	577
PHY	578
PI	579
PIAN	581
PIAT	582
PIATT	583
PIAZ	584
PIC	585
PICAR	586
PICC	587
PICCIN	588
PICCIO	589
PICCO	591
PICH	592
PICHO	593
PICK	594
PICKER	595
PICKERING, M.	596
PICKET	597
PICO	598
PICOU	599
PICT	611
PID	612
PIE	613
PIEN	614
PIER	615
PIERCE, G.	616
PIERCE, M.	617
PIERCE, S.	618
PIERL	619
PIERP	621
PIERR	622
PIERRES	623
PIERS	624
PIET	625
PIETRO	626
PIF	627
PIG	628
PIGE	629
PIGG	631
PIGN	632
PIGO	633
PIH	634
PIK	635
PIKE, M.	636
PIL	637
PILES	638
PILK	639
PILL	641
PILLO	642
PILO	643
PIM	644
PIN	645
PINAR	646
PINC	647
PIND	648
PINE	649
PINEL	651
PINET	652
PING	653
PINH	654
PINK	655
PINN	656
PINO	657
PINS	658
PINT	659
PINZ	661
PIO	662
PIOZ	663
PIP	664
PIPER	665
PIQ	666
PIR	667
PIRI	668
PIRK	669
PIRO	671
PIRON	672
PIS	673
PISANI	674
PISANO	675
PISC	676
PISE	677
PISO	678
PIST	679
PIT	681
PITC	682
PITH	683
PITI	684
PITM	685
PITR	686
PITS	687
PITT	688
PITTI	689
PITTO	691
PITTS	692
PIU	693
PIX	694
PIZ	695
PL	696
PLAC	697
PLACI	698
PLAN	699
PLANCHET	711
PLANE	712
PLANT	713
PLANTI	714
PLAS	715
PLAT	716
PLATN	717
PLATO	718
PLATT	719
PLAU	721
PLAY	722
PLAYFO	723
PLE	724
PLEN	725
PLES	726
PLEY	727
PLI	728
PLO	729
PLOU	731
PLOW	732
PLU	733
PLUM	734
PLUMM	735
PLUMP	736
PLUN	737
PLUY	738
PO	739
POCO	741
POD	742
POE	743
POEL	744
POER	745
POG	746
POH	747
POHL	748
POI	749
POIN	751
POINS	752
POIR	753
POIS	754
POISSO	755
POIT	756
POITI	757
POIX	758
POJ	759
POK	761
POL	762
POLE	763
POLEM	764
POLEN	765
POLI	766
POLIER	767
POLIG	768
POLIT	769
POLL	771
POLLARD, M.	772
POLLE	773
POLLI	774
POLLIO	775
POLLO	776
POLLOCK, M.	777
POLO	778
POLT	779
POLY	781
POLYC	782
POLYM	783
POM	784
POME	785
POMF	786
POMM	787
POMP	788
POMPI	789
POMPO	791
PON	792
PONCEL	793
PONCET	794
PONCH	795
POND	796
PONI	797
PONS	798
PONSO	799
PONT	811
PONTB	812
PONTE	813
PONTEC	814
PONTEV	815
PONTI	816
PONTM	817
PONTO	818
PONZ	819
POO	821
POOLE	822
POOR	823
POORT	824
POP	825
POPE, M.	826
POPH	827
POPI	828
POPO	829
POPP	831
POR	832
PORC	833
PORCI	834
PORD	835
PORI	836
PORP	837
PORR	838
PORT	839
PORTAF	841
PORTAL	842
PORTE	843
PORTER	844
PORTER, F.	845
PORTER, J.	846
PORTER, M.	847
PORTER, S.	848
PORTER, W.	849
PORTH	851
PORTI	852
PORTM	853
PORZ	854
POS	855
POSS	856
POST	857
POSTL	858
POT	859
POTE	861
POTH	862
POTI	863
POTO	864
POTT	865
POTTER	866
POTTER, G.	867
POTTER, M.	868
POTTER, S.	869
POTTI	871
POU	872
POUI	873
POUL	874
POULL	875
POULT	876
POUR	877
POUS	878
POUT	879
POW	881
POWELL	882
POWELL, F.	883
POWELL, J.	884
POWELL, M.	885
POWELL, S.	886
POWER	887
POWERS	888
POWN	889
POY	891
POYN	892
POZ	893
POZZO	894
PR	895
PRAD	896
PRAE	897
PRAET	898
PRAN	899
PRAS	911
PRAT	912
PRATT	913
PRATT, F.	914
PRATT, J.	915
PRATT, M.	916
PRATT, S.	917
PRAU	918
PRAX	919
PRAY	921
PRE	922
PREC	923
PREI	924
PREM	925
PREN	926
PRENT	927
PRES	928
PRESCOTT	929
PRESCOTT, G.	931
PRESCOTT, M.	932
PRESCOTT, S.	933
PRESL	934
PRESS	935
PREST	936
PRESTON	937
PRESTON, G.	938
PRESTON, M.	939
PRESTON, S.	941
PRESTON, W.	942
PREU	943
PREV	944
PRI	945
PRICE, M.	946
PRICH	947
PRIE	948
PRIES	949
PRIEU	951
PRIM	952
PRIME	953
PRIN	954
PRINCE, G.	955
PRINCE, M.	956
PRINCE, S.	957
PRIO	958
PRIS	959
PRIT	961
PRO	962
PROC	963
PROCT	964
PROM	965
PROS	966
PROT	967
PROU	968
PROV	969
PRU	971
PRUN	972
PRY	973
PS	974
PT	975
PU	976
PUC	977
PUG	978
PUI	979
PUL	981
PULL	982
PULT	983
PUN	984
PUR	985
PURS	986
PUS	987
PUT	988
PUTNAM	989
PUTNAM, G.	991
PUTNAM, M.	992
PUTNAM, S.	993
PUY	994
PY	995
PYL	996
PYN	997
PYR	998
PYT	999
QUA	1
QUAT	2
QUE	3
QUER	4
QUES	5
QUI	6
QUIN	7
QUIR	8
QUO	9
RA	111
RAB	112
RABAU	113
RABE	114
RABEN	115
RABI	116
RABU	117
RACH	119
RACI	121
RACK	122
RACO	123
RAD	124
RADC	125
RADE	126
RADEM	127
RADET	128
RADI	129
RADO	131
RADU	132
RADZ	133
RAE	134
RAEN	135
RAF	136
RAFFEN	137
RAFFL	138
RAFN	139
RAG	141
RAGG	142
RAGL	143
RAGO	144
RAGU	145
RAGUS	146
RAH	147
RAHN	148
RAI	149
RAIK	151
RAIL	152
RAIM	153
RAIN	154
RAINE	155
RAINEY	156
RAINI	157
RAINO	158
RAINV	159
RAIT	161
RAK	162
RAL	163
RALS	164
RAM	165
RAMAZ	166
RAMB	167
RAMBU	168
RAMD	169
RAME	171
RAMEL	172
RAMI	173
RAMM	174
RAMO	175
RAMOUN, M.	176
RAMP	177
RAMS	178
RAMSAY, J.	179
RAMSAY, P.	181
RAMSD	182
RAMSE	183
RAMU	184
RAN	185
RAND	186
RANDALL	188
RANDALL, M.	189
RANDE	191
RAND, M.	187
RANDO	192
RANDOLPH, G.	193
RANDOLPH, M.	194
RANDON	195
RANG	196
RANI	197
RANK	198
RANKEN	199
RANKI	211
RANS	212
RANT	213
RANZ	214
RAO	215
RAP	216
RAPH	217
RAPI	218
RAPO	219
RAPP	221
RAS	222
RASCH	223
RASE	224
RASK	225
RASP	226
RASPO	227
RASS	228
RAST	229
RASTO	231
RAT	232
RATC	233
RATH	234
RATHS	235
RATI	236
RATT	237
RATZ	238
RAU	239
RAUCH	241
RAUCO	242
RAUD	243
RAUF	244
RAUL	245
RAUM	246
RAUP	247
RAUS	248
RAUT	249
RAUZ	251
RAV	252
RAVEN	253
RAVENS	254
RAVES	255
RAVI	256
RAW	257
RAWL	258
RAWLIN	259
RAWLINSON	261
RAWS	262
RAY	263
RAYB	265
RAYE	266
RAYM	267
RAY, M.	264
RAYMOND	268
RAYMOND, G.	269
RAYMOND, M.	271
RAYMOND, S.	272
RAYMOND, W.	273
RAYN	274
RAYNE	275
RAYNO	276
RAYO	277
RAZ	278
RAZOU	279
RE	281
READ	282
READE	285
READE, M.	286
READ, H.	283
READING	287
READ, M.	284
REAL	288
REB	289
REBELL	291
REBO	292
REBS	293
REC	294
RECCO	295
RECH	296
RECHEN	297
RECK	298
RECL	299
RECO	311
RED	312
REDD	313
REDE	314
REDF	315
REDG	316
REDI	317
REDM	318
REDO	319
REDP	321
REE	322
REED	323
REED, G.	324
REED, M.	325
REED, S.	326
REED, W.	327
REES	328
REESE	329
REEV	331
REEVES	332
REG	333
REGG	334
REGI	335
REGIO	336
REGIS	337
REGN	338
REGNAU	339
REGNE	341
REGNI	342
REGO	343
REGU	344
REH	345
REHT	346
REI	347
REICHA	348
REICHE	349
REICHEN	351
REICHM	352
REID	353
REID, D.	354
REID, F.	355
REID, J.	356
REID, M.	357
REID, S.	358
REID, W.	359
REIF	361
REIL	362
REIM	363
REIN	364
REINE	365
REINEC	366
REINER	367
REINH	368
REINHARD	369
REINHART	371
REINHO	372
REINM	373
REINS	374
REIS	375
REISET	376
REISI	377
REISS	378
REIT	379
REJ	381
REL	382
RELL	383
REM	384
REMB	385
REME	386
REMI	387
REMIN	388
REMO	389
REMU	391
REMY	392
REN	393
RENAR	394
RENAU	395
RENAUL	396
REND	397
RENDU	398
RENE	399
RENES	411
RENG	412
RENI	413
RENN	414
RENNEV	415
RENNI	416
RENNY	417
RENO	418
RENOU	419
RENS	421
RENT	422
RENU	423
RENV	424
REP	425
REPT	426
REQ	427
RER	428
RES	429
RESE	432
RESEN	433
RESN	434
RESS	435
REST	436
RET	437
RETH	438
RETT	439
RETZ	441
REU	442
REUL	443
REUM	444
REUS	445
REUSS	446
REUT	447
REUV	448
REV	449
REVELL	451
REVER	452
REVES	453
REVI	454
REX	455
REY	456
REYB	457
REYM	458
REYN	459
REYNI	461
REYNO	462
REYNOLDS, G.	463
REYNOLDS, M.	464
REYNOLDS, S.	465
REYNOLDS, W.	466
REZ	467
RH	468
RHE	469
RHEN	471
RHET	472
RHI	473
RHO	474
RHOD	475
RHODES	476
RHODES M	477
RHODES, M.	477
RHODO	478
RHOU	479
RI	481
RIB	482
RIBB	483
RIBE	484
RIBES	485
RIBO	486
RIC	487
RICARDO	488
RICC	489
RICCI	491
RICCIAR	492
RICCIO	493
RICCO	494
RICE	495
RICE, G.	496
RICE, M.	497
RICH	498
RICHARD	511
RICHARD, G.	512
RICHARD, M.	513
RICHARDS	514
RICHARDS, F.	515
RICHARDS, J.	516
RICHARDS, M.	517
RICHARDSON	521
RICHARDSON, D.	522
RICHARDSON, J.	523
RICHARDSON, M.	524
RICHARDSON, S.	525
RICHARDSON, W.	526
RICHARDS, S.	518
RICHARDS, W.	519
RICHE	527
RICHEL	528
RICHER	529
RICHI	531
RICHM	532
RICH, M.	499
RICHMOND, M.	533
RICHT	534
RICHTER	535
RICHTER, M.	536
RICHTER, S.	537
RICI	538
RICK	539
RICO	541
RID	542
RIDDEL	543
RIDE	544
RIDL	545
RIDLEY, M.	546
RIDO	547
RIE	548
RIED	551
RIEDI	552
RIEF	553
RIEG	554
RIEH	555
RIEM	556
RIEN	557
RIEP	558
RIES	559
RIESE	561
RIESN	562
RIET	563
RIEU	564
RIG	565
RIGAUL	566
RIGB	567
RIGE	568
RIGG	569
RIGH	571
RIGN	572
RIIEDES	549
RIL	573
RILL	574
RIM	575
RIMI	576
RIMM	577
RINC	579
RING	581
RINGO	582
RINT	583
RINU	584
RIO	585
RIOS	586
RIOU	587
RIP	588
RIPLEY	589
RIPLEY, H.	591
RIPLEY, R.	592
RIPP	593
RIQ	594
RIS	595
RISS	596
RIST	597
RIT	598
RITCHIE, G.	599
RITCHIE, M.	611
RITS	612
RITT	613
RITTER	614
RITTER, M.	615
RIV	616
RIVAN	617
RIVAR	618
RIVAU	619
RIVE	621
RIVERS	622
RIVES	623
RIVET	624
RIVI	625
RIVO	626
RIZ	627
RO	628
ROBAR	629
ROBB	631
ROBBINS	632
ROBBINS, F.	633
ROBBINS, J.	634
ROBBINS, M.	635
ROBBINS, S.	636
ROBBINS, W.	637
ROBE	638
ROBERT	639
ROBERT, G.	641
ROBERT, M.	642
ROBERTS	643
ROBERTS, F.	644
ROBERTS, J.	645
ROBERTS, M.	646
ROBERTSON	649
ROBERTSON, J.	651
ROBERTSON, S.	652
ROBERTS, S.	647
ROBERTS, W.	648
ROBES	653
ROBI	654
ROBIN	655
ROBINE	656
ROBINS	657
ROBINSON	658
ROBINSON, D.	659
ROBINSON, G.	661
ROBINSON, J.	662
ROBINSON, M.	663
ROBINSON, S.	664
ROBINSON, T.	665
ROBINSON, W.	666
ROBS	667
ROBY	668
ROC	669
ROCC	671
ROCH	672
ROCHE	673
ROCHEF	674
ROCHEM	675
ROCHES	676
ROCHET	677
ROCHF	678
ROCHM	679
ROCHO	681
ROCK	682
ROCKI	683
ROCKW	684
ROD	685
RODD	686
RODE	687
RODER	688
RODEW	689
RODG	691
RODI	692
RODM	693
RODN	694
RODO	695
RODR	696
RODW	697
ROE	698
ROEB	711
ROED	712
ROEH	713
ROEL	714
ROEM	715
ROE, M.	699
ROEP	716
ROER	717
ROES	718
ROET	719
ROG	721
ROGER	722
ROGER, M.	723
ROGERS	724
ROGERS, D.	725
ROGERS, G.	726
ROGERS, J.	727
ROGERS, M.	728
ROGERS, S.	729
ROGERS, W.	731
ROGET	732
ROGG	733
ROGI	734
ROGN	735
ROGU	736
ROH	737
ROHL	738
ROHR	739
ROI	741
ROK	742
ROKO	743
ROL	744
ROLE	745
ROLF	746
ROLFE, M.	747
ROLI	748
ROLL	749
ROLLES	751
ROLLETT	752
ROLLI	753
ROLLIN	754
ROLLO	755
ROM	756
ROMAI	757
ROMAN	758
ROMANO	759
ROMANU	761
ROMB	762
ROME	763
ROMEY	764
ROMI	765
ROMM	766
ROMU	767
RON	768
RONC	769
ROND	771
RONE	772
RONG	773
RONS	774
RONZ	775
ROO	776
ROOK	777
ROOP	778
ROOR	779
ROOS	781
ROOT	782
ROOT, M.	783
ROP	784
ROPES	785
ROQ	786
ROR	787
ROS	788
ROSAR	789
ROSC	791
ROSCO	792
ROSCOE, G.	793
ROSCOE, M.	794
ROSE	795
ROSEB	798
ROSEC	799
ROSE, G.	796
ROSEL	811
ROSEM	812
ROSE, M.	797
ROSEMN	815
ROSEN	813
ROSENK	814
ROSENW	816
ROSET	817
ROSEW	818
ROSI	819
ROSIN	821
ROSN	822
ROSS	823
ROSSEL	828
ROSSET	829
ROSS, G.	824
ROSSI	831
ROSSIG	834
ROSSI, G.	832
ROSSI, M.	833
ROSSIN	835
ROSSL	836
ROSSM	837
ROSS, M.	825
ROSSO	838
ROSS, S.	826
ROSS, W.	827
ROST	839
ROSW	841
ROT	842
ROTE	843
ROTG	844
ROTH	845
ROTHEN	846
ROTHS	847
ROTHW	848
ROTR	849
ROTT	851
ROU	852
ROUB	853
ROUC	854
ROUG	855
ROUGET	856
ROUI	857
ROUJ	858
ROUL	859
ROUP	861
ROUQ	862
ROUS	863
ROUSS	864
ROUSSEL	865
ROUSSELE	866
ROUSSET	867
ROUST	868
ROUT	869
ROUX	871
ROUY	872
ROV	873
ROVET	874
ROVI	875
ROW	876
ROWAN	877
ROWE	878
ROWEL	881
ROWE, M.	879
ROWI	882
ROWL	883
ROWLE	884
ROWS	885
ROX	886
ROXB	887
ROY	888
ROYE	889
ROYER	891
ROYO	892
ROZ	893
RU	894
RUBEN	895
RUBI	896
RUBR	897
RUC	898
RUCH	899
RUCK	911
RUCKERS	912
RUD	913
RUDD	914
RUDE	915
RUDI	916
RUDO	917
RUE	918
RUEF	919
RUEL	921
RUF	922
RUFFI	923
RUFFN	924
RUFFO	925
RUFI	926
RUFU	927
RUG	928
RUGG	929
RUGGI	931
RUGGL	932
RUH	933
RUI	934
RUL	935
RUM	936
RUMM	937
RUMS	938
RUN	939
RUND	941
RUNG	942
RUNN	943
RUO	944
RUP	945
RUPP	946
RUPR	947
RUR	948
RUS	949
RUSCH	951
RUSH	952
RUSH, M.	953
RUSHT	954
RUSHW	955
RUSK	956
RUSP	957
RUSS	958
RUSSEL	959
RUSSELL	961
RUSSELL, D.	962
RUSSELL, F.	963
RUSSELL, J.	964
RUSSELL, M.	965
RUSSELL, P.	966
RUSSELL, S.	967
RUSSELL, W.	968
RUSSI	969
RUST	971
RUT	972
RUTG	973
RUTH	974
RUTHERF	975
RUTHV	976
RUTI	977
RUTL	978
RUTLAND, M.	979
RUTLEDGE	981
RUTT	982
RUV	983
RUX	984
RUY	985
RUYT	986
RUZ	987
RY	988
RYAN, M.	989
RYD	992
RYE	993
RYL	994
RYM	995
RYO	991
RYS	996
RYT	997
RYV	998
RZ	999
SA	111
SAAR	112
SAB	113
SABB	114
SABE	115
SABI	116
SABL	117
SABR	118
SAC	119
SACH	121
SACO	122
SACR	123
SAD	124
SADE	125
SADL	126
SAE	127
SAF	128
SAG	129
SAH	131
SAI	132
SAINT A	133
SAINT AN	134
SAINT B	135
SAINT C	136
SAINTE	156
SAINT E	137
SAINTE M	157
SAINT F	138
SAINT G	139
SAINT H	141
SAINT I	142
SAINT J	143
SAINT JU	144
SAINT L	145
SAINT M	146
SAINT N	147
SAINT O	148
SAINT P	149
SAINT R	151
SAINT S	152
SAINT U	154
SAINT V	155
SAIS	158
SAL	159
SALAN	161
SALD	162
SALE	163
SALG	164
SALI	165
SALIS	166
SALISBURY	167
SALL	168
SALLO	169
SALM	171
SALMON	172
SALO	173
SALOMON	174
SALON	175
SALT	176
SALTER	177
SALTM	178
SALTO	179
SALU	181
SALV	182
SALVE	183
SALVI	184
SALVIN	185
SALVO	186
SAM	187
SAMH	188
SAMM	189
SAMO	191
SAMP	192
SAMS	193
SAN	194
SANB	198
SANC	199
SANCH	211
SANCR	212
SAND	213
SANDE	214
SANDERS	215
SANDERSON	216
SANDF	217
SANDO	218
SANDR	219
SANDS	221
SANDY	222
SANE	223
SANF	224
SAN F	195
SANG	225
SANGR	226
SANI	227
SAN L	196
SANN	228
SANS	229
SAN S	197
SANT	231
SANTAG	232
SANTAR	233
SANTE	234
SANTI	235
SANTIS	236
SANTO	237
SANU	238
SAO	239
SAP	241
SAQ	242
SAR	243
SARD	244
SARG	245
SARM	246
SARR	247
SARS	248
SART	249
SARTO	251
SAS	252
SAT	253
SATU	254
SAU	255
SAUL	256
SAUN	257
SAUP	258
SAUR	259
SAUT	261
SAUV	262
SAV	263
SAVAGE, J.	264
SAVAS	266
SAVI	267
SAVO	268
SAVOT	269
SAW	271
SAX	272
SAXO	273
SAY	274
SAYAR	265
SAYL	275
SBA	276
SCA	277
SCAE	278
SCAL	279
SCALAB	281
SCALI	282
SCAM	283
SCAP	284
SCAR	285
SCARL	286
SCARS	287
SCAV	288
SCE	289
SCH	291
SCHAD	292
SCHAE	293
SCHAEF	294
SCHAER	295
SCHAF	296
SCHAL	297
SCHALL	298
SCHAM	299
SCHAR	311
SCHAT	312
SCHAU	313
SCHE	314
SCHED	315
SCHEF	316
SCHEFFER, J.	317
SCHEI	318
SCHEIF	319
SCHEIT	321
SCHEL	322
SCHEM	323
SCHEN	324
SCHEP	325
SCHER	326
SCHET	327
SCHEU	328
SCHI	329
SCHICK	331
SCHIE	332
SCHIF	333
SCHIL	334
SCHIM	335
SCHIN	336
SCHIR	337
SCHL	338
SCHLE	339
SCHLEI	341
SCHLES	342
SCHLEU	343
SCHLI	344
SCHLO	345
SCHLU	346
SCHM	347
SCHMI	348
SCHMIDT	349
SCHMIDT, F.	351
SCHMIDT, J.	352
SCHMIDT, L.	353
SCHMIDT, S.	354
SCHMIT	355
SCHMO	356
SCHN	357
SCHNE	358
SCHNEIDER, J.	359
SCHNI	361
SCHNO	362
SCHO	363
SCHOE	364
SCHOEN	365
SCHOENL	366
SCHOEP	367
SCHOL	368
SCHOM	369
SCHON	371
SCHOO	372
SCHOP	373
SCHOR	374
SCHOT	375
SCHOU	376
SCHRA	377
SCHREI	378
SCHREY	379
SCHRO	381
SCHROET	382
SCHU	383
SCHUBE	384
SCHUE	385
SCHUL	386
SCHULTZ	387
SCHULZ	388
SCHULZE	391
SCHULZ, J.	389
SCHUM	392
SCHUN	393
SCHUR	394
SCHUS	395
SCHUT	396
SCHUY	397
SCHW	398
SCHWAR	399
SCHWARZ	411
SCHWE	412
SCHWEI	413
SCHWEM	414
SCHWER	415
SCI	416
SCIN	417
SCIP	418
SCIR	419
SCO	421
SCOG	422
SCOR	423
SCOT	424
SCOTT	425
SCOTT, G.	426
SCOTT, J.	427
SCOTT, M.	428
SCOTT, S.	429
SCOTT, W.	431
SCOU	432
SCR	433
SCRI	434
SCRO	435
SCU	436
SCUL	437
SEA	438
SEAR	439
SEAT	441
SEAV	442
SEB	443
SEC	444
SECO	445
SECR	446
SED	447
SEDG	448
SEDL	449
SEE	451
SEEL	452
SEEM	453
SEG	454
SEGR	455
SEGU	456
SEI	457
SEID	458
SEIF	459
SEIL	461
SEIS	462
SEJ	463
SEL	464
SELF	465
SELK	466
SELL	467
SELLO	468
SELV	469
SEM	471
SEML	472
SEMP	473
SEN	474
SENE	475
SENF	476
SENI	477
SENN	478
SEP	479
SER	481
SERAS	482
SERE	483
SERG	484
SERI	485
SERM	486
SERR	487
SERRE	488
SERRO	489
SERV	491
SERVIN	492
SES	493
SEST	494
SET	495
SEU	496
SEV	497
SEVER	498
SEVERUS	499
SEVI	511
SEW	512
SEWALL, S.	513
SEWARD	514
SEWEL	515
SEWELL	516
SEWELL, S.	517
SEX	518
SEY	519
SEYM	521
SEYT	522
SFO	523
SHA	524
SHAF	525
SHAI	526
SHAK	527
SHAL	528
SHAP	529
SHAR	531
SHARPE	532
SHAT	533
SHAW	534
SHAW, L.	535
SHAW, S.	536
SHAW, W.	537
SHAY	538
SHE	539
SHED	541
SHEF	542
SHEI	543
SHEL	544
SHELLEY	545
SHEN	546
SHEP	547
SHEPH	548
SHEPP	549
SHER	551
SHERI	552
SHERM	553
SHERW	554
SHI	555
SHIL	556
SHIP	557
SHIR	558
SHO	559
SHR	561
SHU	562
SIB	563
SIBL	564
SIC	565
SICI	566
SICO	567
SID	568
SIDN	569
SIE	571
SIEN	572
SIES	573
SIG	574
SIGF	575
SIGI	576
SIGIS	577
SIGN	578
SIGU	579
SIL	581
SILB	582
SILI	583
SILL	584
SILO	585
SILV	586
SILVE	587
SIM	588
SIME	589
SIML	591
SIMM	592
SIMO	593
SIMON	594
SIMOND	597
SIMONE	598
SIMONI	599
SIMON, J.	595
SIMON, P.	596
SIMONS	611
SIMP	612
SIMPS	613
SIMS	614
SIN	615
SINCL	616
SING	617
SINS	618
SIRM	621
SIRS	619
SIS	622
SISM	623
SIV	624
SIX	625
SKA	626
SKE	627
SLA	631
SLE	632
SLI	633
SLO	634
SMA	635
SMAR	636
SME	637
SMEL	638
SMI	639
SMIL	641
SMIT	642
SMITH, B.	643
SMITH, C.	644
SMITH, D.	645
SMITH, E.	646
SMITH, F.	647
SMITH, G.	648
SMITH, H.	649
SMITH, J.	651
SMITH, JOHN	652
SMITH, JOS.	653
SMITH, L.	654
SMITH, M.	655
SMITH, O.	656
SMITH, R.	657
SMITH, ROB'	658
SMITH, S.	659
SMITH, SOL.	661
SMITH, T.	662
SMITH, W.	663
SMITH, WM.	664
SMITS	665
SMO	666
SMY	667
SMYTHE	668
SNA	669
SNE	671
SNI	672
SNO	673
SNOW	674
SNY	675
SOA	676
SOB	677
SOC	678
SOD	679
SOE	681
SOG	682
SOI	683
SOL	684
SOLE	685
SOLI	686
SOLIS	687
SOLL	688
SOLO	689
SOLT	691
SOLY	692
SOM	693
SOMER	694
SOMERSE	695
SOMERV	696
SOMM	697
SON	698
SONN	699
SOO	711
SOP	712
SOR	713
SORI	714
SOS	715
SOST	716
SOT	717
SOTO	718
SOU	719
SOUF	721
SOUL	722
SOULI	723
SOUM	724
SOUS	725
SOUT	726
SOUTHE	727
SOUTHW	728
SOUV	729
SOW	731
SPA	732
SPAF	733
SPAL	734
SPAN	735
SPAR	736
SPARR	737
SPAT	738
SPAU	739
SPE	741
SPEE	742
SPEL	743
SPEN	744
SPENCER	745
SPENCER, S.	746
SPENE	747
SPENS	748
SPER	749
SPERR	751
SPET	752
SPH	753
SPI	754
SPIE	755
SPIL	756
SPIN	757
SPINO	758
SPIR	759
SPIT	761
SPO	762
SPON	763
SPOO	764
SPOT	765
SPR	766
SPRAN	767
SPRE	768
SPRI	769
SPRO	771
SPU	772
SQU	773
SQUIR	774
STA	775
STAD	776
STADL	777
STAE	778
STAF	779
STAH	781
STAI	782
STAM	783
STAN	784
STAND	785
STANH	786
STANL	787
STANLEY, J.	788
STANLEY, S.	789
STANS	791
STANT	792
STAP	793
STAPL	794
STAR	795
STARR	796
STAT	797
STAU	798
STE	799
STEB	811
STED	812
STEE	813
STEELE	814
STEEV	815
STEF	816
STEFFE	817
STEI	818
STEIN	819
STEIND	821
STEINE	822
STEINM	823
STEL	824
STEN	825
STENO	826
STEP	827
STEPHEN	828
STEPHEN, M.	829
STEPHENS	832
STEPHEN, S.	831
STEPHENS, G.	833
STEPHENS, L.	834
STEPHENSON	836
STEPHENSON, R.	837
STEPHENS, R.	835
STER	838
STERN	839
STET	841
STEU	842
STEV	843
STEVENS	844
STEVENS, M.	845
STEVENSON	847
STEVENSON, M.	848
STEVENS, S.	846
STEW	849
STEWART, M.	851
STEWART, T.	852
STEY	853
STI	854
STIE	855
STIL	856
STILL	857
STIM	858
STIMP	859
STIR	861
STIT	862
STO	863
STOC	864
STOCKL	865
STOCKT	866
STOD	867
STODDARD, M.	868
STODDARD, S.	869
STOE	871
STOEL	872
STOF	873
STOK	874
STOL	875
STOLT	876
STON	877
STONE, J.	878
STONE, M.	879
STONE, T.	881
STOO	882
STOP	883
STOR	884
STORK	885
STORR	886
STORY	887
STORY, S.	888
STOU	889
STOW	891
STOWE	892
STOWELL	893
STRA	894
STRAD	895
STRAF	896
STRAN	897
STRAT	898
STRATH	899
STRATT	911
STRAU	912
STRAW	913
STRE	914
STREET	915
STRI	916
STRICKL	917
STRIN	918
STRO	919
STROG	921
STRON	922
STRONG	923
STRONG, P.	924
STROT	925
STROZ	926
STRU	927
STRY	928
ST. SIMON	153
STU	929
STUART, J.	931
STUART, M.	932
STUD	933
STUK	934
STUR	935
STURM	936
STUT	937
STUY	938
SUA	939
SUB	941
SUC	942
SUD	943
SUE	944
SUEV	945
SUF	946
SUG	947
SUI	948
SUL	949
SULLIVAN, M.	951
SULLIVAN, S.	952
SULLY	953
SULP	954
SUM	955
SUMN	956
SUN	957
SUNDERL	958
SUP	959
SUR	961
SURR	962
SURV	963
SUS	964
SUT	965
SUTH	966
SUTT	967
SUZ	968
SVI	969
SWA	971
SWAN	972
SWAR	973
SWE	974
SWET	975
SWI	976
SWIFT	977
SWIN	978
SWINT	979
SYA	981
SYD	982
SYK	983
SYL	984
SYLV	985
SYM	986
SYMM	987
SYMO	988
SYMP	989
SYMS	991
SYN	992
SYNG	993
SYP	994
SYR	995
SZA	996
SZE	997
SZI	998
SZY	999
TA	111
TAB	112
TABE	113
TABO	114
TAC	115
TACF	116
TACH	117
TACI	118
TACO	119
TAD	121
TADO	122
TAE	123
TAF	124
TAG	125
TAGL	126
TAGLIAS	127
TAGLIO	128
TAI	129
TAIL	131
TAILLE	132
TAILLI	133
TAIN	134
TAIS	135
TAK	136
TAL	137
TALBOT	138
TALBOT, G.	139
TALBOT, M.	141
TALBOT, S.	142
TALE	143
TALF	144
TALH	145
TALI	146
TALL	147
TALLEY	148
TALLI	149
TALM	151
TALO	152
TAM	153
TAMB	154
TAMBE	155
TAMBOU	156
TAME	157
TAMI	158
TAMP	159
TAN	161
TANC	162
TAND	163
TANE	164
TANK	165
TANN	166
TANNER, M.	167
TANS	168
TANT	169
TANZ	171
TAP	172
TAPL	173
TAPP	174
TAPPAN, M.	175
TAR	176
TARAS	177
TARAU	178
TARB	179
TARD	181
TARDIEU	182
TARDIF	183
TARG	185
TARI	186
TARIN	187
TARL	188
TARO	191
TARR	192
TARS	193
TARTAR	194
TARTI	195
TARU	196
TAS	197
TASK	198
TASM	199
TASS	211
TASSE	212
TASSI	213
TASSO	214
TASSON	215
TAT	216
TATE, M.	217
TATH	218
TATI	219
TATT	221
TAU	222
TAUBN	223
TAUC	224
TAUL	225
TAUN	226
TAUP	227
TAUS	228
TAUT	229
TAV	231
TAVE	232
TAVER	233
TAVERNI	234
TAX	235
TAY	236
TAYLER	237
TAYLOR	238
TAYLOR, C.	239
TAYLOR,C.	239
TAYLOR, F.	241
TAYLOR, H.	242
TAYLOR, J.	243
TAYLOR, M.	244
TAYLOR, P.	245
TAYLOR, S.	246
TAYLOR, W.	247
TAZ	248
TC	249
TCHE	251
TCHO	252
TE	253
TEB	254
TEC	255
TED	256
TEDM	257
TEE	258
TEF	259
TEG	261
TEI	262
TEIF	263
TEIL	264
TEIS	265
TEIX	266
TEL	267
TELEM	268
TELES	269
TELF	271
TELI	272
TELL	273
TELLER	274
TELLEZ	275
TELLI	276
TELLO	277
TEM	278
TEME	279
TEMM	281
TEMP	282
TEMPEST, M.	283
TEMPL	284
TEMPLE, G.	285
TEMPLE, M.	286
TEMPLE, S.	287
TEMPLET	288
TEN	289
TEND	291
TENE	292
TENI	293
TENIS	294
TENN	295
TENNANT, M.	296
TENNE	297
TENNEY	298
TENNEY, M.	299
TENNI	311
TENNY	312
TENT	313
TEO	314
TER	315
TERE	316
TERG	317
TERH	318
TERM	319
TERN	321
TERP	322
TERR	323
TERRAS	324
TERRE	325
TERRI	326
TERRIN	327
TERRO	328
TERRY	329
TERS	331
TERT	332
TERW	333
TERZ	334
TES	335
TESAU	336
TESC	337
TESS	338
TESSI	339
TESSIN	341
TEST	342
TESTE	343
TESTI	344
TESTO	345
TESTU	346
TET	347
TETR	348
TETZ	349
TEU	351
TEUT	352
TEV	353
TEW	354
TEX	355
TEY	356
TH	357
THAC	358
THACHER, G.	359
THACHER, M.	361
THACHER, S.	362
THACK	363
THAI	364
THAL	365
THAM	366
THAN	367
THAU	368
THAY	369
THAYER, G.	371
THAYER, M.	372
THAYER, S.	373
THE	374
THEB	375
THEI	376
THEIM	377
THEK	378
THEL	379
THELO	381
THELW	382
THEM	383
THEN	384
THEO	385
THEOC	386
THEOD	387
THEODO	388
THEODOS	389
THEOG	391
THEON	392
THEOP	393
THEOPHI	394
THEOPO	395
THEOR	396
THEOS	397
THER	398
THERI	399
THERM	411
THERO	412
THES	413
THESS	414
THEU	415
THEV	416
THEVENI	417
THEVENO	418
THEW	419
THEX	421
THI	422
THIARD	423
THIB	424
THIBAUL	425
THIBAUT	426
THIBO	427
THIC	428
THIE	429
THIELM	432
THIEM	433
THIEN	434
THIER	435
THIERRY	436
THIERRY, M.	437
THIERS	438
THIES	439
THIL	441
THILO	442
THIM	443
THIO	444
THIR	445
THIRL	446
THIRO	447
THIS	448
THO	449
THOL	451
THOM	452
THOMAN	453
THOMAS	454
THOMAS, C.	455
THOMAS, F.	456
THOMAS, H.	457
THOMAS, J.	458
THOMAS, M.	459
THOMAS, P.	461
THOMASS	464
THOMAS, S.	462
THOMASSY	465
THOMAS, W.	463
THOMO	466
THOMP	467
THOMPSON	468
THOMPSON, C.	469
THOMPSON, F.	471
THOMPSON, H.	472
THOMPSON, J.	473
THOMPSON, M.	474
THOMPSON, P.	475
THOMPSON, S.	476
THOMPSON, T.	477
THOMPSON, W.	478
THOMS	479
THOMSEN	481
THOMSON	482
THOMSON, G.	483
THOMSON, M.	484
THOMSON, S.	485
THOMSON, W.	486
THOR	487
THORE	488
THORES	489
THORI	491
THORIS	492
THORK	493
THORL	494
THORM	495
THORN	496
THORNB	497
THORND	498
THORNDI	499
THORNE	511
THORNEY	512
THORNT	513
THORNTON, M.	514
THORNW	515
THORO	516
THORP	517
THORPE	518
THORPE, G.	519
THORPE, M.	521
THORP, S.	522
THORT	523
THOU	524
THOUI	525
THOUR	526
THOUT	527
THOUV	528
THR	529
THRE	531
THU	532
THUI	533
THUL	534
THUN	535
THUR	536
THURL	537
THURLO	538
THURM	539
THURN	541
THURO	542
THURS	543
THURSTON	544
THURSTON, G.	545
THURSTON, M.	546
THURSTON, S.	547
THW	548
THY	549
TI	551
TIB	552
TIBE	553
TIBN	554
TIC	555
TICK	556
TICKNOR	557
TID	558
TIE	559
TIEF	561
TIEL	562
TIEP	563
TIER	564
TIF	565
TIG	566
TIGL	567
TIGR	568
TIL	569
TILD	571
TILE	572
TILI	573
TILL	574
TILLE	575
TILLET	576
TILLI	577
TILLO	578
TILLY	579
TILS	581
TIM	582
TIMB	583
TIMM	584
TIMO	585
TIMP	586
TIN	587
TIND	588
TINK	589
TINN	591
TINS	592
TINT	593
TIO	594
TIP	595
TIR	596
TIRI	597
TIS	598
TISCH	599
TISCHE	611
TISCHL	612
TISD	613
TISS	614
TISSI	615
TISSO	616
TIT	617
TITI	618
TITIN	619
TITO	621
TITT	622
TITU	623
TIX	624
TIZ	625
TK	626
TO	627
TOB	628
TOBI	629
TOC	631
TOCQ	632
TOD	633
TODD, G.	634
TODD, M.	635
TODD, S.	636
TODE	637
TODH	638
TODL	639
TOE	641
TOEP	642
TOES	643
TOF	644
TOG	645
TOI	646
TOL	647
TOLB	648
TOLE	649
TOLL	651
TOLM	652
TOLO	653
TOLS	654
TOM	655
TOMB	656
TOMI	657
TOMK	658
TOML	659
TOMM	661
TOMP	662
TON	663
TONE	664
TONG	665
TONN	666
TONT	667
TOO	668
TOOKE, M.	669
TOOL	671
TOOM	672
TOPH	674
TOPL	675
TOR	676
TORD	677
TORE	678
TOREN	679
TORES	681
TORG	682
TORI	683
TORL	684
TORN	685
TORNO	686
TORQ	687
TORR	688
TORRE	689
TORREN	691
TORRENT	692
TORRES	693
TORREY	694
TORRI	695
TORRIG	696
TORRIN	697
TORS	698
TORT	699
TORTI	711
TORTO	712
TOS	713
TOSE	714
TOSS	715
TOST	716
TOT	717
TOTT	718
TOTTEN	719
TOTTL	721
TOU	722
TOUL	723
TOULM	724
TOULO	725
TOUP	726
TOUR	727
TOURN	728
TOURNO	729
TOURO	731
TOURR	732
TOURV	733
TOUS	734
TOUSSE	735
TOUT	736
TOW	737
TOWER, M.	738
TOWERS	739
TOWG	741
TOWL	742
TOWN	743
TOWNE	744
TOWNEL	745
TOWNL	746
TOWNS	747
TOWNSEND, G.	749
TOWNSEND, M.	751
TOWNSEND, S.	752
TOWNSEND, W.	753
TOWNSH	753
TOWNSHEND, M.	754
TOWNSO	755
TOY	756
TOZ	757
TR	758
TRAC	759
TRACY	761
TRACY, M.	762
TRAD	763
TRAE	764
TRAG	765
TRAI	766
TRAILL, M.	767
TRAIN	768
TRAL	769
TRAM	771
TRAN	772
TRAP	773
TRAPP	774
TRAS	775
TRAT	776
TRAU	777
TRAUTS	778
TRAV	779
TRAVERS, M.	781
TRAVI	782
TRAX	783
TRE	784
TREBO	785
TRED	786
TREI	787
TREL	788
TREM	789
TREMO	791
TREN	792
TRENCH, M.	793
TRENCK	794
TRENT	795
TRES	796
TRESH	797
TRESI	798
TRESS	799
TREU	811
TREV	812
TREVI	813
TREVIS	814
TREVO	815
TREVOR, M.	816
TREW	817
TREZ	818
TRI	819
TRIAN	821
TRIB	822
TRIC	823
TRICO	824
TRIE	825
TRIER	826
TRIES	827
TRIG	828
TRIL	829
TRIM	831
TRIN	832
TRINCI	833
TRIO	834
TRIP	835
TRIPP	836
TRIS	837
TRIST	838
TRIT	839
TRIV	841
TRIVU	842
TRO	843
TROG	844
TROI	845
TROL	846
TROLLO	847
TROLLOPE, M.	848
TROM	849
TROMP	851
TRON	852
TRONCI	853
TRONS	854
TROO	855
TROP	856
TROS	857
TROT	858
TROU	859
TROUI	861
TROUV	862
TROW	863
TROY	864
TRU	865
TRUD	866
TRUM	867
TRUMBULL	868
TRUMBULL, J.	869
TRUMBULL, S.	871
TRUR	872
TRUS	873
TRUT	874
TRY	875
TRYP	876
TS	877
TSCHER	878
TSCHI	879
TSCHU	881
TSE	882
TU	883
TUB	884
TUBER	885
TUC	886
TUCH	887
TUCHER	888
TUCK	889
TUCKER	891
TUCKER, G.	892
TUCKER, M.	893
TUCKERMAN	896
TUCKERMAN, M.	897
TUCKER, S.	894
TUCKER, W.	895
TUCKET	898
TUD	899
TUDI	911
TUDO	912
TUE	913
TUF	914
TUFTS, M.	915
TUK	916
TUL	917
TULL	918
TULLOCH	919
TULLOCH, M.	921
TULLUS	922
TULLY	923
TULO	924
TUM	925
TUN	926
TUNS	927
TUP	928
TUR	929
TURB	931
TURC	932
TURCO	933
TURE	934
TUREN	935
TURG	936
TURGO	937
TURI	938
TURK	939
TURL	941
TURN	942
TURNBULL, M.	943
TURNE	944
TURNER, C.	945
TURNER, F.	946
TURNER, H.	947
TURNER, J.	948
TURNER, M.	949
TURNER, P.	951
TURNER, S.	952
TURNER, T.	953
TURNER, W.	954
TURNH	955
TURNO	956
TURP	957
TURR	958
TURRETT	959
TURRI	961
TURT	962
TURV	963
TUS	964
TUSS	965
TUT	966
TUTT	967
TUY	968
TW	969
TWEE	971
TWI	972
TWIN	973
TWIS	974
TWY	975
TWYS	976
TY	977
TYC	978
TYE	979
TYL	981
TYLER, G.	982
TYLER, M.	983
TYLER, S.	984
TYLER, W.	985
TYM	986
TYN	987
TYNDALL	988
TYNG	989
TYP	991
TYR	992
TYRRELL	993
TYS	994
TYT	995
TYTLER	996
TYTLER, S.	997
TZ	998
TZS	999
UA	11
UB	12
UBE	13
UBER	14
UBI	15
UC	16
UCH	17
UD	18
UDE	19
UDI	21
UE	22
UF	23
UFFI	24
UFFO	25
UG	26
UGO	27
UH	28
UHD	29
UHL	31
UHT	32
UI	33
UK	34
UKR	35
UL	36
ULE	37
ULF	38
ULI	39
ULL	41
ULLO	42
ULM	43
ULP	44
ULR	45
ULS	46
ULT	47
UM	48
UMBR	49
UMF	51
UML	52
UMS	53
UN	54
UNDE	55
UNDERW	56
UNG	57
UNI	58
UNS	59
UNT	61
UNW	62
UNZ	63
UO	64
UP	65
UPD	66
UPH	67
UPM	68
UPS	69
UPT	71
UR	72
URBI	73
URC	74
URE	75
URI	76
URL	77
URO	78
URQ	79
URR	81
URS	82
URV	83
US	84
USH	85
USL	86
USS	87
UST	88
UT	89
UTL	91
UTR	92
UTT	93
UV	94
UW	95
UX	96
UY	97
UYT	98
UZ	99
VA	111
VAC	112
VACC	113
VACCAR	114
VACCH	115
VACCHI	116
VACCO	117
VACH	118
VACHO	119
VACQ	121
VAD	122
VADE	123
VADI	124
VAE	125
VAG	126
VAH	127
VAI	128
VAIL	129
VAILL	131
VAIS	132
VAJ	133
VAK	134
VAL	135
VALAD	136
VALAR	137
VALAZ	138
VALB	139
VALC	141
VALCK	142
VALCKENB	143
VALD	144
VALDES	145
VALDI	146
VALDO	147
VALDR	148
VALE	149
VALEG	151
VALEN	152
VALENS	153
VALENT	154
VALENTI	155
VALENTIN	156
VALENTINE	157
VALENTINE, J.	158
VALENTINE, P.	159
VALENTINI	161
VALER	162
VALERI	163
VALERIO	164
VALERIU	165
VALERY	166
VALES	167
VALET	168
VALG	169
VALH	171
VALI	172
VALIN	173
VALK	174
VALL	175
VALLAD	176
VALLAN	177
VALLAR	178
VALLAU	179
VALLE	181
VALLEE	182
VALLEM	183
VALLER	184
VALLES	185
VALLET	186
VALLETT	187
VALLI	188
VALLIS	189
VALLO	191
VALLON	192
VALLOT	193
VALLOU	194
VALLS	195
VALM	196
VALMY	197
VALO	198
VALOR	199
VALP	211
VALPY	212
VALR	213
VALS	214
VALT	215
VAM	216
VAN	217
VANB	218
VANBR	219
VANBU	221
VANC	222
VANCO	223
VAND	224
VANDE	225
VANDEL	226
VANDEN	227
VANDER	228
VANDERBU	229
VANDERC	231
VANDERD	232
VANDERH	233
VANDERHO	234
VANDERL	235
VANDERM	236
VANDERME	237
VANDERMO	238
VANDERP	239
VANDERS	241
VANDERW	242
VANDEU	243
VANDEV	244
VANDI	245
VANDO	246
VANDY	247
VANDYK	248
VANE	249
VANEE	252
VANE, M.	251
VANG	253
VANH	254
VANHE	255
VANHO	256
VANHU	257
VANI	258
VANL	259
VANLOO	261
VANM	262
VANMO	263
VANN	264
VANNE	265
VANNES	266
VANNET	267
VANNI	268
VANNIN	269
VANNU	271
VANO	272
VANP	273
VANR	274
VANRO	275
VANS	276
VANSA	277
VANSC	278
VANSI	279
VANSP	281
VANT	282
VANU	283
VANV	284
VANW	285
VAP	286
VAR	287
VARAN	288
VARC	289
VARD	291
VARE	292
VAREL	293
VAREN	294
VARENN	295
VARES	296
VARG	297
VARGU	298
VARI	299
VARIL	311
VARIN	312
VARIU	313
VARL	314
VARLEY	315
VARLO	316
VARN	317
VARNEY	318
VARNH	319
VARNI	321
VARNU	322
VARO	323
VAROT	324
VARR	325
VART	326
VARU	327
VAS	328
VASC	329
VASCO	331
VASE	332
VASH	333
VASI	334
VASQ	335
VASS	336
VASSALL	337
VASSE	338
VASSI	339
VAST	341
VAT	342
VATER	343
VATH	344
VATI	345
VATIN	346
VATK	347
VATO	348
VATR	349
VATT	351
VATTI	352
VAU	353
VAUBAN	354
VAUBL	355
VAUC	356
VAUCH	357
VAUD	358
VAUDOY	359
VAUDR	361
VAUDREY	362
VAUG	363
VAUGHAN	364
VAUGHAN, C.	365
VAUGHAN, F.	366
VAUGHAN, J.	367
VAUGHAN, M.	368
VAUGHAN, S.	369
VAUGHAN, W.	371
VAUGI	372
VAUGO	373
VAUL	374
VAULO	375
VAULT	376
VAUM	377
VAUQ	378
VAUS	379
VAUT	381
VAUV	382
VAUVI	383
VAUX	384
VAUXC	387
VAUX, G.	385
VAUX, M.	386
VAUZ	388
VAV	389
VAVI	391
VAY	392
VAZ	393
VE	394
VEAU	395
VEC	396
VECCHI	397
VECCHIO	398
VECE	399
VECELLIO	411
VECN	412
VECO	413
VED	414
VEDD	415
VEDO	416
VEE	417
VEEN	418
VEER	419
VEES	421
VEG	422
VEGI	423
VEGL	424
VEH	425
VEI	426
VEIL	427
VEIT	428
VEITCH	429
VEITH	431
VEL	432
VELAS	433
VELASQ	434
VELD	435
VELE	436
VELI	437
VELL	438
VELLE	439
VELLO	441
VELLU	442
VELLY	443
VELP	444
VELT	445
VELTR	446
VEN	447
VENAN	448
VENC	449
VENCES	451
VEND	452
VENDR	453
VENE	454
VENEG	455
VENEL	456
VENET	457
VENEZ	458
VENI	459
VENIN	461
VENN	462
VENNER	463
VENNI	464
VENT	465
VENTO	466
VENTR	467
VENTU	468
VENTURI	469
VENU	471
VENUT	472
VER	473
VERAC	474
VERAL	475
VERAR	476
VERB	477
VERBI	478
VERBO	479
VERC	481
VERCI	482
VERD	483
VERDI	484
VERDIG	485
VERDO	486
VERDU	487
VERDY	488
VERE	489
VEREL	491
VERELS	492
VERG	493
VERGAR	494
VERGE	495
VERGER	496
VERGI	497
VERGN	498
VERGY	499
VERH	511
VERHAG	512
VERHE	513
VERHO	514
VERHU	515
VERI	516
VERIN	517
VERJ	518
VERK	519
VERL	521
VERM	522
VERME	523
VERMEU	524
VERMI	525
VERMIL	526
VERMO	527
VERMOO	528
VERN	529
VERNE	531
VERNET	532
VERNEU	533
VERNEY	534
VERNEY, M.	535
VERNI	536
VERNIN	537
VERNIZ	538
VERNO	539
VERNON, G.	541
VERNON, M.	542
VERNON, S.	543
VERNU	544
VERNY	545
VERO	546
VERON	547
VERONA	548
VERONE	549
VERP	551
VERPO	552
VERR	553
VERRI	554
VERRIL	555
VERRIM	556
VERRIO	557
VERRO	558
VERRU	559
VERS	561
VERSCHU	562
VERSE	563
VERSO	564
VERST	565
VERSTO	566
VERT	567
VERTO	568
VERU	569
VERV	571
VERW	572
VERY	573
VERZ	574
VES	575
VESEY	576
VESI	577
VESL	578
VESP	579
VESPU	581
VESQ	582
VEST	583
VESTR	584
VET	585
VETCH	586
VETH	587
VETI	588
VETR	589
VETT	591
VETTO	592
VETU	593
VEU	594
VEY	595
VEYS	596
VEZ	597
VI	598
VIAL	599
VIALE	611
VIALL	612
VIALO	613
VIAN	614
VIANEN	615
VIANI	616
VIANN	617
VIAR	618
VIARDO	619
VIART	621
VIAS	622
VIAU	623
VIB	624
VIBI	625
VIBN	626
VIC	627
VICAR	628
VICARS	629
VICAT	631
VICE	632
VICENTI	633
VICH	634
VICI	635
VICK	636
VICKERS	637
VICO	638
VICOM	639
VICQ	641
VICT	642
VICTOR, G.	643
VICTORIN	646
VICTOR, M.	644
VICTOR, S.	645
VICU	647
VICUV	669
VID	648
VIDAL, M.	649
VIDAU	651
VIDE	652
VIDI	653
VIDO	654
VIDU	655
VIE	656
VIEI	657
VIEILLO	658
VIEL	659
VIELL	661
VIEN	662
VIENNE	663
VIENNO	664
VIER	665
VIET	666
VIEU	667
VIEUS	668
VIEUX	671
VIG	672
VIGE	673
VIGER	674
VIGH	675
VIGI	676
VIGIL	677
VIGN	678
VIGNAL	679
VIGNAU	681
VIGNE	682
VIGNER	683
VIGNES	684
VIGNI	685
VIGNO	686
VIGNON	687
VIGNY	688
VIGO	689
VIGOR	691
VIGR	692
VIGU	693
VIGUI	694
VIL	695
VILAIN	696
VILAR	697
VILAT	698
VILB	699
VILH	711
VILL	712
VILLAF	713
VILLAL	714
VILLAM	715
VILLAN	716
VILLANO	717
VILLANU	718
VILLAR	719
VILLARET	721
VILLARI	722
VILLARS	723
VILLARS, G.	724
VILLARS, M.	725
VILLARS, S.	726
VILLAY	727
VILLE	728
VILLEC	729
VILLEF	731
VILLEG	732
VILLEGO	733
VILLEH	734
VILLEL	735
VILLEM	736
VILLEN	737
VILLENE	738
VILLEP	739
VILLEQ	741
VILLER	742
VILLERM	743
VILLERO	744
VILLERS	745
VILLERS, M.	746
VILLES	747
VILLET	748
VILLEU	749
VILLI	751
VILLIERS	752
VILLIERS, F.	753
VILLIERS, J.	754
VILLIERS, M.	755
VILLIERS, S.	756
VILLIERS, W.	757
VILLO	758
VILLON	759
VILLOT	761
VILM	762
VILS	763
VIM	764
VIMO	765
VIN	766
VINC	767
VINCENT	768
VINCENT, C.	769
VINCENT, F.	771
VINCENT, J.	772
VINCENT, M.	773
VINCENT, S.	774
VINCENT, W.	775
VINCH	776
VINCI	777
VINCK	778
VIND	779
VINDI	781
VINE	782
VINET	783
VING	784
VINI	785
VINK	786
VINN	787
VINO	788
VINT	789
VINTON	791
VINTON, G.	792
VINTON, M.	793
VINTON, S.	794
VIO	795
VIOLL	796
VIOM	797
VION	798
VIOT	799
VIP	811
VIPO	812
VIR	813
VIRE	814
VIREY	815
VIRG	816
VIRGIN	817
VIRI	818
VIRL	819
VIRU	821
VIS	822
VISCH	823
VISCO	824
VISCONTI, G.	825
VISCONTI, M.	826
VISCONTI, S.	827
VISD	828
VISE	829
VISI	831
VISM	832
VISS	833
VISSE	834
VIT	835
VITAL	836
VITALIS	837
VITE	838
VITEL	839
VITELLI	841
VITEN	842
VITER	843
VITET	844
VITO	845
VITR	846
VITRO	847
VITRU	848
VITRY	849
VITT	851
VITTL	852
VITTO	853
VITU	854
VIV	855
VIVARI	856
VIVE	857
VIVI	857
VIVIANI	859
VIVIEN	861
VIVIER	862
VIVO	863
VIZ	864
VL	865
VLAM	866
VLAS	867
VLE	868
VLI	869
VLIET	871
VO	872
VOELC	873
VOELL	874
VOER	875
VOET	876
VOG	877
VOGEL	878
VOGEL, M.	879
VOGH	881
VOGI	882
VOGL	883
VOGLER, M.	884
VOGO	885
VOGT	886
VOGT, M.	887
VOGU	888
VOI	889
VOIGT	891
VOIGT, G.	892
VOIGT, M.	893
VOIGT, S.	894
VOIL	895
VOIR	896
VOIS	897
VOIT	898
VOL	899
VOLC	911
VOLCK	912
VOLCKM	913
VOLD	914
VOLG	915
VOLK	916
VOLKE	917
VOLKH	918
VOLKM	919
VOLKO	921
VOLKV	922
VOLL	923
VOLLM	924
VOLLW	925
VOLM	926
VOLN	927
VOLNEY	928
VOLO	929
VOLP	931
VOLPI	932
VOLPIN	933
VOLS	934
VOLT	935
VOLTCH	936
VOLTE	937
VOLTO	938
VOLTR	939
VOLTU	941
VOLTZ	942
VOLU	943
VOLV	944
VON	945
VOND	946
VONK	947
VONO	948
VOO	949
VOOR	951
VOP	952
VOR	953
VORO	954
VORS	955
VORSTER	956
VORT	957
VORY	958
VOS	959
VOSE	961
VOSE, D.	962
VOSE, H.	963
VOSE, J.	964
VOSE, M.	965
VOSE, S.	966
VOSE, W.	967
VOSM	968
VOSS	969
VOSSI	971
VOU	972
VOUL	973
VOW	974
VOY	975
VOYS	976
VOZ	977
VR	978
VRE	979
VRI	981
VRIES	982
VRIL	983
VRO	984
VS	985
VU	986
VUI	987
VUIL	988
VUIT	989
VUL	991
VULP	992
VULS	993
VUO	994
VUY	995
VY	996
VYR	997
VYS	998
VZ	999
WA	111
WAAS	112
WAC	113
WACHS	114
WACK	115
WAD	116
WADDI	117
WADDINGTON	118
WADE	119
WADE, M.	121
WADH	122
WADL	123
WADS	124
WADSWORTH, M.	125
WAE	126
WAEL	127
WAF	128
WAG	129
WAGEN	131
WAGN	132
WAGNER, G.	133
WAGNER, M.	134
WAGNER, S.	135
WAH	136
WAHLEN	137
WAI	138
WAILL	139
WAIN	141
WAINWRIGHT, M.	142
WAIS	143
WAIT	144
WAITE	145
WAK	146
WAKEF	147
WAKEH	148
WAKEL	149
WAL	151
WALCH	152
WALCH, J.	153
WALCH, P.	154
WALCK	155
WALCO	156
WALD	157
WALDE	158
WALDEG	159
WALDEM	161
WALDEN	162
WALDER	163
WALDM	164
WALDO	165
WALDOR	166
WALDR	167
WALDS	168
WALE	169
WALEI	171
WALES	172
WALES, M.	173
WALF	174
WALG	175
WALI	176
WALK	177
WALKER, D.	178
WALKER, F.	179
WALKER, J.	181
WALKER, M.	182
WALKER, P.	183
WALKER, S.	184
WIF	653
WALKER, T.	185
WALKER, W.	186
WALL	187
WALLACE, D.	188
WALLACE, F.	189
WALLACE, J.	191
WALLACE, M.	192
WALLACE, P.	193
WALLACE, S.	194
WALLACE, W.	195
WALLC	196
WALLEN	197
WALLER	198
WALLEY	199
WALLI	211
WALLINGF	212
WALLINGT	213
WALLIS	214
WALLO	215
WALM	216
WALN	217
WALP	218
WALPOLE, M.	219
WALR	221
WALS	222
WALSH	223
WALSH, D.	224
WALSH, J.	225
WALSH, M.	226
WALSH, S.	227
WALSH, W.	228
WALSI	229
WALTER. G.	232
WALTER. M.	233
WALTERS	235
WALTER. S.	234
WALTH	236
WALTHER	237
WALTO	238
WALTON, G.	239
WALTON, M.	241
WALW	243
WAM	243
WAN	244
WAND	245
WANG	246
WANH	247
WANL	248
WANN	249
WANS	251
WAP	252
WAR	253
WARBURTON	254
WARBURTON, M.	255
WARD	256
WARD, C.	257
WARDE	265
WARD, F.	258
WARD, J.	259
WARDL	266
WARD, M.	261
WARD, P.	262
WARD, S.	263
WARD, W.	264
WARE	267
WARE, D.	268
WARE, J.	269
WARE, M.	271
WAREN	274
WARE, S.	272
WARE, W.	273
WARH	275
WARI	276
WARING, M.	277
WARN	278
WARNER	279
WARNER, D.	281
WARNER, J.	282
WARNER, M.	283
WARNER, S.	284
WARNER, W.	285
WARR	286
WARREN, C.	287
WARREN, F.	288
WARREN, J.	289
WARREN, M.	291
WARREN, P.	292
WARREN, S.	293
WARREN, W.	294
WARRI	295
WART	296
WARTENS	297
WARTO	298
WARW	299
WARWICK, M.	311
WAS	312
WASER	313
WASH	314
WASHBURN, M.	315
WASHI	316
WASHINGTON	317
WASHINGTON, G.	318
WASHINGTON, M.	319
WASS	321
WASSER	322
WASSI	323
WAT	324
WATERF	325
WATERH	326
WATERL	327
WATERM	328
WATERS	329
WATERS, M.	331
WATERST	332
WATERW	333
WATK	334
WATKE	335
WATKINSON	336
WATS	337
WATSON, D.	338
WATSON, J.	339
WATSON, M.	341
WATSON, S.	342
WATSON, W.	343
WATT	344
WATTI	347
WATT, J.	345
WATT, P.	346
WATTS	348
WATTS, D.	349
WATTS, J.	351
WATTS, M.	352
WATTS, S.	353
WAU	354
WAUT	355
WAW	356
WAY	357
WAYL	358
WAYN	359
WE	361
WEAL	362
WEAV	363
WEB	364
WEBB	365
WEBBE	369
WEBBER	371
WEBBER, M.	372
WEBB, G.	366
WEBB, M.	367
WEBB, S.	368
WEBER	373
WEBER, G.	374
WEBER, M.	375
WEBER, S.	376
WEBS	377
WEBSTER, C.	378
WEBSTER, F.	379
WEBSTER, J.	381
WEBSTER, M.	382
WEBSTER, P.	383
WEBSTER, S.	384
WEBSTER, W.	385
WECH	386
WECK	387
WED	388
WEDE	389
WEDEL	391
WEDG	392
WEDGW	393
WEE	394
WEEKS	395
WEEKS, M.	396
WEEM	397
WEER	398
WEEV	399
WEG	411
WEGN	412
WEH	413
WEHR	414
WEI	415
WEICH	416
WEID	417
WEIDM	418
WEIG	419
WEIK	421
WEIL	422
WEIN	423
WIG	654
WEINM	424
WEIR	425
WEIS	426
WEISE	427
WEISK	428
WEISS	429
WEISSEN	433
WEISS, J.	431
WEISS, P.	432
WEIT	434
WEITS	435
WEITZ	436
WEK	437
WEL	438
WELCH	439
WELCH, M.	441
WELCK	442
WELD	443
WELDE	445
WELD, M.	444
WELH	446
WELL	447
WELLER	448
WELLES	449
WELLESL	451
WELLI	452
WELLS	453
WELLS, G.	454
WELLS, M.	455
WELLS, S.	456
WELLW	457
WELS	458
WELSE	459
WELSH	461
WELSH, J.	462
WELSH, P.	463
WELT	464
WELW	465
WEM	466
WEN	467
WENC	468
WEND	469
WENDL	471
WENDO	472
WENDT	473
WENG	474
WENI	475
WENL	476
WENT	477
WENTWORTH, G.	478
WENTWORTH, M.	479
WENTZ	481
WENZ	482
WEP	483
WER	484
WERDE	485
WERE	486
WEREN	487
WERF	488
WERL	489
WERN	491
WERNER	492
WERNER, G.	493
WERNER, M.	494
WERNH	495
WERNI	496
WERNS	497
WERP	498
WERT	499
WES	511
WESL	513
WESLEY, M.	514
WESS	515
WESSEN	512
WEST	516
WESTB	523
WESTC	524
WEST, D.	517
WESTE	525
WESTER	526
WESTERM	527
WESTG	528
WESTH	529
WEST, J.	518
WESTM	531
WEST, M.	519
WESTMI	532
WESTMO	533
WESTO	534
WESTON, G.	535
WESTON, P.	536
WESTP	537
WESTR	538
WEST, S.	521
WEST, W.	522
WET	539
WETM	541
WETT	542
WETTS	543
WETZ	544
WEX	545
WEY	546
WEYE	547
WEYL	548
WEYM	549
WH	551
WHAL	552
WHART	553
WHARTON, M.	554
WHAT	555
WHE	556
WHEATL	557
WHEATO	558
WHED	559
WHEE	561
WHEELER	562
WHEELER, G.	563
WHEELER, P.	564
WHEELO	565
WHEELW	566
WHELP	567
WHET	568
WHEW	569
WHI	571
WHID	572
WHIP	573
WHIPPLE, J.	574
WHIPPLE, P.	575
WHIS	576
WHIT	577
WHITAKER, M.	578
WHITB	579
WHITC	581
WHITE	582
WHITE, C.	583
WHITEF	591
WHITE, F.	584
WHITEH	592
WHITEHO	593
WHITE, J.	585
WHITEL	594
WHITE, M.	586
WHITE, P.	587
WHITE, S.	588
WHITE, W.	589
WHITF	595
WHITG	596
WHITI	597
WHITING	598
WHITING, G.	599
WHITING, M.	611
WHITING, S.	612
WHITING, W.	613
WHITM	614
WHITMAN, M.	615
WHITMORE	616
WHITNEY	617
WHITNEY, D.	618
WHITNEY, J.	619
WHITNEY, M.	621
WHITNEY, S.	622
WHITNEY, W.	623
WHITT	624
WHITTI	625
WHITTING	626
WHITTL	627
WHITW	628
WHY	629
WI	631
WIB	632
WIC	633
WICHI	634
WICHM	635
WICK	636
WICKH	637
WID	638
WIDE	639
WIDM	641
WIE	642
WIEDE	643
WIEDEM	644
WIEG	645
WIEL	646
WIEN	647
WIER	648
WIES	649
WIESE	651
WIESS	652
WIGG	655
WIGGL	656
WIGH	657
WIGHTM	658
WIGM	659
WIGN	661
WIGR	662
WIILIAMSON, J.	731
WIK	663
WIL	664
WILBR	665
WILBU	666
WILC	667
WILD	668
WILDB	669
WILDE	671
WILDE, M.	672
WILDER	673
WILDM	674
WILDT	675
WILE	676
WILF	677
WILH	678
WILI	679
WILK	681
WILKES	682
WILKI	683
WILKINS	684
WILKINS, M.	685
WILKINSON	686
WILKINSON, M.	687
WILKS	688
WILL	689
WILLAR	691
WILLARD, D.	692
WILLARD, J.	693
WILLARD, M.	694
WILLARD, S.	695
WILLARD, W.	696
WILLC	697
WILLE	698
WILLEM	699
WILLEN	711
WILLER	712
WILLES	713
WILLEY	714
WILLI	715
WILLIAM	716
WILLIAM, G.	717
WILLIAM, M.	718
WILLIAMS	721
WILLIAM, S.	719
WILLIAMS, C.	722
WILLIAMS, F.	723
WILLIAMS, J.	724
WILLIAMS, M.	725
WILLIAMSON	729
WILLIAMSON, P.	732
WILLIAMS, P.	726
WILLIAMS, S.	727
WILLIAMS, W.	728
WILLIN	733
WILLIS	734
WILLIS, M.	735
WILLIST	736
WILLM	737
WILLMO	738
WILLO	739
WILLS	741
WILLSO	742
WILM	743
WILMO	744
WILR	745
WILS	746
WILSON, C.	747
WILSON, F.	748
WILSON, J.	749
WILSON, M.	751
WILSON, P.	752
WILSON, S.	753
WILSON, W.	754
WILT	755
WILTON, M.	756
WIM	757
WIN	758
WINCHE	759
WINCK	761
WINCKL	762
WIND	763
WINDH	764
WINDI	765
WINDS	766
WINE	767
WINES	768
WING	769
WINGF	771
WINGR	772
WINK	773
WINKELM	774
WINKL	775
WINN	776
WINS	777
WINSLOW	778
WINSLOW, G.	779
WINSLOW, M.	781
WINSLOW, S.	782
WINST	783
WINT	784
WINTERF	788
WINTER, G.	785
WINTER, M.	786
WINTER, S.	787
WINTH	789
WINTHROP	791
WINTHROP, J.	792
WINTHROP, P.	793
WINTR	794
WINW	795
WIO	796
WIP	797
WIR	798
WIRT	799
WIS	811
WISE	812
WISEM	814
WISE, M.	813
WISN	815
WISS	816
WIST	817
WISW	818
WIT	819
WITE	821
WITH	822
WITHERI	823
WITHERS	824
WITI	825
WITS	826
WITT	827
WITTE	828
WITTEN	829
WITTG	831
WITTI	832
WITZ	833
WITZL	834
WIX	835
WL	836
WO	837
WOD	838
WODES	839
WOE	841
WOEL	842
WOER	843
WOF	844
WOG	845
WOH	846
WOI	847
WOL	848
WOLCOTT	849
WOLCOTT, M.	851
WOLD	852
WOLF	853
WOLFFE	856
WOLFFE, J.	857
WOLFFE, P.	858
WOLFG	859
WOLF, J.	854
WOLF, P.	855
WOLFR	861
WOLK	862
WOLL	863
WOLLE	864
WOLM	865
WOLO	866
WOLS	867
WOLT	868
WOLTM	869
WOLZ	871
WOM	872
WOO	873
WOODBRI	882
WOODBRIDGE, M.	883
WOODBU	884
WOODBURY, M.	885
WOODC	886
WOOD, C.	874
WOODF	887
ZAM	23
WOOD, F.	875
WOODH	888
WOODHO	889
WOODHU	891
WOOD, J.	876
WOODM	892
WOOD, M.	877
WOOD, P.	878
WOODR	893
WOODS	894
WOOD, S.	879
WOODS, J.	895
WOODS, M.	896
WOODS, S.	897
WOODSW	899
WOODS, W.	898
WOOD, W.	881
WOODWARD, J.	911
WOODWARD, P.	912
WOOL	913
WOOLM	914
WOOLR	915
WOOLS	916
WOOLW	917
WOOT	918
WOR	919
WORCESTER, G.	921
WORCESTER, M.	922
WORCESTER, S.	923
WORD	924
WORDSW	925
WORDSWORTH, S.	926
WORL	927
WORM	928
WORO	929
WORS	931
WORT	932
WORTHINGTON	933
WORTHINGTON, M.	934
WORTL	935
WOT	936
WOTT	937
WOU	938
WR	939
WRAN	941
WRAT	942
WRAX	943
WRE	944
WREN	945
WRI	946
WRIGHT	947
WRIGHT, C.	948
WRIGHT, F.	949
WRIGHT, J.	951
WRIGHT, M.	952
WRIGHT, S.	953
WRIGHT, W.	954
WRIS	955
WRIT	956
WRO	957
WROTH	958
WU	959
WUL	961
WULFH	962
WULFR	963
WULFS	964
WUN	965
WUNS	966
WUR	967
WURM	968
WURT	969
WURTZ	971
WURZ	972
WUS	973
WY	974
WYATT	975
WYATT, M.	976
WYC	977
WYD	978
WYE	979
WYK	981
WYL	982
WYLE	983
WYM	984
WYN	985
WYNF	986
WYNG	987
WYNN	988
WYNNE, M.	989
WYNT	991
WYO	992
WYR	993
WYS	994
WYSS	995
WYT	996
WYTT	997
WYV	998
WZ	999
XA	1
XAN	2
XAV	3
XE	4
XEN	5
XER	6
XL	7
XU	8
XY	9
YA	11
YAC	12
YAH	13
YAI	14
YAK	15
YAL	16
YALE	17
YALE, M.	18
YALES	19
YAN	21
YANE	22
YANI	23
YANN	24
YAO	25
YAR	26
YARD	27
YARF	28
YARR	29
YAT	31
YATES, G.	32
YATES, M.	33
YATES, S.	34
YATM	35
YB	36
YE	37
YEAM	38
YEAR	39
YEAT	41
YEB	42
YEF	43
YEM	44
YEN	45
YEO	46
YEP	47
YET	48
YEZ	49
YH	51
YL	52
YN	53
YO	54
YON	55
YONGE, G.	56
YONGE, M.	57
YONGE, S.	58
YONGE, W.	59
YOR	61
YORKE	64
YORKE, M.	65
YORK, J.	62
YORK, P.	63
YOT	66
YOU	67
YOUNG	68
YOUNG, C.	69
YOUNG, E.	71
YOUNG, G.	72
YOUNG, J.	73
YOUNGM	79
YOUNG, M.	74
YOUNG, P.	75
YOUNGS	81
YOUNG, S.	76
YOUNG, T.	77
YOUNG, W.	78
YOUS	82
YOUSS	83
YOZ	84
YP	85
YPS	86
YR	87
YRI	88
YRIE	89
YS	91
YSEN	92
YSS	93
YU	94
YULE	95
YV	96
YVE	97
YVES	98
YVO	99
ZA	11
ZAB	12
ZAC	13
ZACCO	14
ZACH	15
ZACHAR	16
ZACU	17
ZAG	18
ZAH	19
ZAI	21
ZAL	22
ZAMBO	24
ZAMO	25
ZAMP	26
ZAN	27
ZANE	28
ZANG	29
ZANI	31
ZANN	32
ZANO	33
ZANT	34
ZAP	35
ZAR	36
ZARI	37
ZARO	38
ZAU	39
ZE	41
ZEC	42
ZED	43
ZEG	44
ZEI	45
ZEIL	46
ZEIS	47
ZEIT	48
ZEL	49
ZELL	51
ZELO	52
ZELT	53
ZEN	54
ZENO	55
ZENT	56
ZEP	57
ZER	58
ZES	59
ZET	61
ZEU	62
ZEV	63
ZI	64
ZIE	65
ZIEG	66
ZIES	67
ZIF	68
ZIL	69
ZIM	71
ZIMMER	72
ZIMMERMANN	73
ZIMMERMANN, G.	74
ZIMMERMANN, M.	75
ZIMMERMANN, S.	76
ZIN	77
ZINK	78
ZINZ	79
ZIR	81
ZIT	82
ZO	83
ZOC	84
ZOE	85
ZOL	86
ZON	87
ZOP	88
ZOR	89
ZOU	91
ZS	92
ZU	93
ZUC	94
ZUN	95
ZUR	96
ZW	97
ZWI	98
ZY	99
\.


--
-- Data for Name: gtcdictionary; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcdictionary (dictionaryid, description, tags, readonly) FROM stdin;
\.


--
-- Data for Name: gtcdictionarycontent; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcdictionarycontent (dictionarycontentid, dictionaryid, dictionarycontent) FROM stdin;
\.


--
-- Data for Name: gtcdictionaryrelatedcontent; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcdictionaryrelatedcontent (dictionaryrelatedcontentid, dictionarycontentid, relatedcontent) FROM stdin;
\.


--
-- Data for Name: gtcdomain; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcdomain (domainid, sequence, key, abbreviated, label) FROM stdin;
ABAS_PREFERENCIA	22	NOTIFICATION	Avisos	Avisos
ABAS_PREFERENCIA	30	ADM_EMAIL	ADM EMAIL	Admin. e-mail
ABAS_PREFERENCIA	31	ADM_INTERFACE	Adm interface	Admin. interface
ABAS_PREFERENCIA	1	LOAN	Empréstimo	Empréstimo
ABAS_PREFERENCIA	2	RETURN	Dev.	Devolução
ABAS_PREFERENCIA	3	RESERVE	Res.	Reserva
ABAS_PREFERENCIA	4	FINE	Multa	Multa
ABAS_PREFERENCIA	32	PRINT	Impressão	Impressão
ABAS_PREFERENCIA	5	ADMIN	Admin	Administração
ABAS_PREFERENCIA	6	INTERCHANGE	Intercâmbio	Intercâmbio de materiais
ABAS_PREFERENCIA	7	LOAN_LIBRARY	Emp. bibl.	Empréstimo entre biblioteca
ABAS_PREFERENCIA	8	CATALOG	Catalogação	Catalogação
ABAS_PREFERENCIA	9	MY_LIBRARY	Minha bib.	Minha biblioteca
ABAS_PREFERENCIA	10	SEARCH	Pesquisa	Pesquisa
ABAS_PREFERENCIA	23	NOTIFICATION_LOAN	Avisos de empréstimos	Avisos de empréstimos
ABAS_PREFERENCIA	24	NOTIFICATION_AQUISITION	Avisos de aquisições	Avisos de aquisições
ABAS_PREFERENCIA	25	NOTIFICATION_REQUEST	Avisos de requ. troca de estado	Avisos de requ. troca de estado
PREFERENCE_TYPE	1	INT	INTEGER	Número inteiro
PREFERENCE_TYPE	2	CHAR	CHAR	Caracter
PREFERENCE_TYPE	3	VARCHAR	VARCHAR	Texto
PREFERENCE_TYPE	4	DATE	DATE	Data
PREFERENCE_TYPE	5	FILE	FILE	Arquivo
PREFERENCE_TYPE	6	BOOLEAN	BOOLEAN	Booleano
PREFERENCE_TYPE	7	NULL	NULL	Nulo
PAGE_FORMAT	1	A4	A4	A4
PAGE_FORMAT	2	Letter	Letter	Letter
PAGE_FORMAT	3	A5	A5	A5
PAGE_FORMAT	4	Automatic	Auto	Automatic
REPORT_PERMISSION	1	basic	Bas.	Basico
REPORT_PERMISSION	2	intermediary	Interm.	Intermediário
REPORT_PERMISSION	3	advanced	Avan.	Avançado
REPORT_GROUP	1	EMP	Emp.	Empréstimos
REPORT_GROUP	2	RES	Res.	Reserva
REPORT_GROUP	3	UTL	Utiliz.	Utilização
REPORT_GROUP	4	ACV	Acervo.	Acervo
REPORT_GROUP	5	MAT	Mat.	Material
REPORT_GROUP	6	RST	Restaur.	Restauração
TIPO_DE_TELEFONE	1	RES	Resid.	Residencial
TIPO_DE_TELEFONE	2	CEL	Cel.	Celular
TIPO_DE_TELEFONE	3	PRO	Prof.	Profissional
TIPO_DE_TELEFONE	4	REC	Rec.	Recado
MATERIAL_SEARCH_TYPE	1	cn	Ctrl.N.	Número de controle
MATERIAL_SEARCH_TYPE	2	in	Item N.	Número do tombo
MATERIAL_SEARCH_TYPE	3	wn	Work N.	Número da obra
Z3950_RECORD_TYPE	1	xml	XML	XML
IDIOMA_PESQUISA_GOOGLE	1		Todos	Todos
IDIOMA_PESQUISA_GOOGLE	2	pt	Português	Português
IDIOMA_PESQUISA_GOOGLE	3	en	Inglês	Inglês
REPORT_GROUP	7	PRS	Pes.	Pessoas
PERSON_GROUP	1	PAD	Padrão	Padrão
SEX	1	M	Masc.	Masculino
SEX	2	F	Fem.	Feminino
DOCUMENT_TYPE	1	RG	RG	Identidade
DOCUMENT_TYPE	2	CPF	CPF	Cadastro de pessoas físicas
BACKGROUND_TASK_STATUS	1	1	Em exec.	Em execução
BACKGROUND_TASK_STATUS	2	2	Sucesso	Sucesso
BACKGROUND_TASK_STATUS	3	3	Erro	Erro
REPORT_GROUP	8	ACS	Acesso	Acesso
REPORT_GROUP	9	IMP	Impressão	Impressão
WORKFLOW	1	PURCHASE_REQUEST	Compra	Solicitação de compra
ABAS_PREFERENCIA	33	PURCHASE_REQUEST	Solicitação de compra	Solicitação de compras
BACKGROUND_TASK_STATUS	4	4	Reexecutando	Reexecutando
BACKGROUND_TASK_STATUS	5	5	Sucesso ao reexecutar	Sucesso ao reexecutar
BACKGROUND_TASK_STATUS	6	6	Falha ao reexecutar.	Falha ao reexecutar.
ABAS_PREFERENCIA	34	Z3950	Z3950	Z3950
\.


--
-- Data for Name: gtcemailcontroldelayedloan; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcemailcontroldelayedloan (loanid, lastsent, amountsent) FROM stdin;
\.


--
-- Data for Name: gtcemailcontrolnotifyaquisition; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcemailcontrolnotifyaquisition (personid, lastsent) FROM stdin;
\.


--
-- Data for Name: gtcexemplarycontrol; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcexemplarycontrol (controlnumber, itemnumber, originallibraryunitid, libraryunitid, acquisitiontype, exemplarystatusid, materialgenderid, materialtypeid, materialphysicaltypeid, entrancedate, lowdate, line, observation) FROM stdin;
\.


--
-- Data for Name: gtcexemplaryfuturestatusdefined; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcexemplaryfuturestatusdefined (exemplaryfuturestatusdefinedid, exemplarystatusid, itemnumber, applied, date, operator, observation) FROM stdin;
\.


--
-- Data for Name: gtcexemplarystatus; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcexemplarystatus (exemplarystatusid, description, mask, level, executeloan, momentaryloan, daysofmomentaryloan, executereserve, executereserveininitiallevel, meetreserve, isreservestatus, islowstatus, observation, schedulechangestatusforrequest) FROM stdin;
0	Estado inicial		1	f	f	0	f	f	f	f	f		f
4	Desaparecido		2	f	f	0	f	f	f	f	t		f
5	Danificado		2	f	f	0	f	f	f	f	t		f
16	Entre bibliotecas		2	f	f	0	f	f	f	f	f		t
1	Disponível		1	t	t	0	t	t	t	f	f		f
2	Emprestado		2	t	t	0	t	t	t	f	f		f
3	Reservado		2	t	t	0	t	f	t	t	f		f
6	Restaurando		2	t	f	0	t	f	t	f	f		f
7	Congelado		2	f	t	0	f	f	f	f	f		f
15	Em Processamento		2	t	f	0	t	t	t	f	f		f
8	Descartado		2	f	f	0	f	f	f	f	t		f
\.


--
-- Data for Name: gtcexemplarystatushistory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcexemplarystatushistory (itemnumber, exemplarystatusid, libraryunitid, date, operator) FROM stdin;
\.


--
-- Data for Name: gtcfavorite; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcfavorite (personid, controlnumber, entracedate) FROM stdin;
\.


--
-- Data for Name: gtcfine; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcfine (fineid, loanid, begindate, value, finestatusid, enddate, observation) FROM stdin;
\.


--
-- Data for Name: gtcfinestatus; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcfinestatus (finestatusid, description) FROM stdin;
1	Em aberto
2	Paga
3	Paga via boleto
4	Abonada
\.


--
-- Data for Name: gtcfinestatushistory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcfinestatushistory (fineid, finestatusid, date, operator, observation) FROM stdin;
\.


--
-- Data for Name: gtcformatbackofbook; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcformatbackofbook (formatbackofbookid, description, format, internalformat) FROM stdin;
\.


--
-- Data for Name: gtcformcontent; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcformcontent (formcontentid, operator, form, name, description, formcontenttype) FROM stdin;
4	\N	frmsimplesearch	materialMovement	\N	1
1	\N	frmsimplesearch	Simples	\N	1
2	\N	frmsimplesearch	Avançada	\N	1
3	\N	frmsimplesearch	Aquisição	\N	1
5	\N	frmsimplesearch	Periódicos	\N	1
\.


--
-- Data for Name: gtcformcontentdetail; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcformcontentdetail (formcontentid, field, value) FROM stdin;
1	termType[]	 
1	termCondition[]	LIKE
1	termType	array (   0 => ' ', )
1	termText	array (   0 => '', )
1	termCondition	array (   0 => 'LIKE', )
1	termOpt	array (   0 => '', )
1	searchFormat	1
2	termType[]	100.a,700.a
2	termType	array (\n  0 => '100.a,700.a',\n  1 => '240.a,245.a,245.b,246.a,246.b',\n  2 => '260.c',\n)
2	termText	array (\n   0 => '',\n   1 => '',\n   2 => '',\n)
2	termOpt	array (\n   0 => '',\n   1 => 'AND',\n   2 => 'AND',\n )
3	termType[]	 
3	termCondition[]	LIKE
3	termType	array (   0 => ' ', )
3	termText	array (   0 => '', )
3	termCondition	array (   0 => 'LIKE', )
3	termOpt	array (   0 => '', )
3	aquisitionFrom	2010-02-04
3	aquisitionTo	2010-02-19
4	termType[]	949.a
4	termCondition[] 	=
4	termType	array ( 0 => '949.a', )
4	termText	array ( 0 => '', )
4	termCondition	array ( 0 => '=', )
4	termOpt	array ( 0 => '', )
4	searchFormat	1
5	materialTypeId	23
5	letter	 
5	letterField	245.a
5	searchFormat	1
5	termCondition	array (   0 => 'LIKE', )
5	termCondition[]	LIKE
5	termOpt	array (   0 => '', )
5	termText	array (   0 => '%', )
5	termText[]	%
5	termType	array (   0 => '', )
3	searchFormat	1
\.


--
-- Data for Name: gtcformcontenttype; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcformcontenttype (formcontenttypeid, description) FROM stdin;
1	Administrador
2	Operador
3	Usuário
\.


--
-- Data for Name: gtcgeneralpolicy; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcgeneralpolicy (privilegegroupid, linkid, loangenerallimit, reservegenerallimit, reservegenerallimitininitiallevel) FROM stdin;
\.


--
-- Data for Name: gtchelp; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtchelp (helpid, form, subform, help, isactive) FROM stdin;
1	FrmLibraryUnit	\N	Ajuda da Unidade de Biblioteca.	t
2	FrmSimpleSearch	2	<B><CENTER>Através desta busca é possível pesquisar em vários campos ao mesmo tempo.</B></CENTER><br /><img WIDTH="13" HEIGHT="13" SRC="file.php?folder=theme&file=add-16x16.png" align="top" /> Ao clicar neste botão, acrescenta novo termo.<br /><img WIDTH="13" HEIGHT="13" SRC="file.php?folder=theme&file=delete-16x16.png" align="top" /> Ao clicar neste botão, exclui um termo.	t
3	FrmSimpleSearch	5	<B><CENTER>Pesquisa de periódicos com títulos iniciados pela letra marcada.</B></CENTER><br />É necessário preencher o campo termo com um texto a ser buscado ou deixar o símbolo porcentagem (busca tudo) e clicar numa das letras.<br /><br />Esta pesquisa só busca periódicos, mas este filtro por letras pode ser utilizado em outros materiais. Neste caso, deve-se adicioná-lo pelos filtros avançados.	t
4	FrmSimpleSearch	1	<center><b>Através deste módulo, os usuários podem pesquisar os materiais catalogados pela biblioteca, além de reservarem os exemplares que necessitem.</b></center><br /><img WIDTH="120" HEIGHT="30" SRC="file.php?folder=theme&file=ConteudoFormulario.png" align="top" /> Pelo conteúdo do formulário é possível criar pesquisas personalizadas.<br /><br /><br /><img WIDTH="15" HEIGHT="15" SRC="file.php?folder=theme&file=add-16x16.png" align="top" /> Para restringir uma busca, pode-se adicionar quantos termos achar necessário, clicando neste botão.<br /><br /><img WIDTH="150" HEIGHT="30" SRC="file.php?folder=theme&file=FiltrosAvancados.png" align="top" /> Outra maneira de restringir a busca é através dos filtros avançados: <ul><li><b>Estado do exemplar:</b> retorna na busca só os materiais que estão no estado especificado.<br /><li><b>Limite de ocorrências:</b> número máximo de materiais listados na pesquisa.<br /><li><b>Ano de edição:</b> pode-se pesquisar a partir de um ano ou em determinado período.<br /><li><b>Período de aquisição:</b> pode-se pesquisar a partir de um determinado período de aquisição.<br /><li><b>Pesquisa por letras:</b> lista os materiais em que o título inicie pela letra selecionada. Para gerar algum resultado, deve-se digitar um texto a ser pesquisado.<br /><li><b>Ordem:</b> é possível ordenar a pesquisa por um determinado campo.<br /></ul><br /><img WIDTH="15" HEIGHT="15" SRC="file.php?folder=theme&file=config-16x16.png" align="top" /> Para mais informações sobre o material, é só clicar neste botão.<br /><br /><img WIDTH="15" HEIGHT="15" SRC="file.php?folder=theme&file=catalogue-16x16.png" align="top" /> Lista todos os exemplares do material, informando quantas reservas possui e data prevista de devolução, quando está emprestado.<br /><br /><img WIDTH="15" HEIGHT="15" SRC="file.php?folder=theme&file=reserve-16x16.png" align="top" /> Serve para reservar o material. Desde que se tenha permissão, pode-se reservar tanto exemplares emprestados, quanto disponíveis; sendo que para estes, é enviado um aviso ao operador do sistema para separar o material e alterar o estado da reserva para Atendida. Feito isto, o usuário que fez a requisição, terá dois dias para retirar a obra.<br /><br /><img WIDTH="15" HEIGHT="15" SRC="file.php?folder=theme&file=login-16x16.png" align="top" /> Quando a coluna Exemplares está em branco é porque o material pertence a uma coleção. Desta forma, para reservar o fascículo, deve-se clicar no link Detalhes deste botão.<br /><br /><img WIDTH="15" HEIGHT="15" SRC="file.php?folder=theme&file=congelado-16x16.png" align="top" /> Botão utilizado para solicitar o congelamento de materiais. Somente usuários com permissão, podem acessá-lo.<br /><br /><img WIDTH="15" HEIGHT="15" SRC="file.php?folder=theme&file=favorites-16x16.png" align="top" /> Ao selecionar um material e clicar neste botão, ele é adicionado aos Favoritos em Minha Biblioteca.<br /><br /><img WIDTH="15" HEIGHT="15" SRC="file.php?folder=theme&file=document-16x16.png" align="top" /> Salva os materiais selecionados num arquivo PDF.<br /><br /><img WIDTH="15" HEIGHT="15" SRC="file.php?folder=theme&file=email-16x16.png" align="top" /> Envia por e-mail um arquivo PDF com os materiais selecionados.	t
\.


--
-- Data for Name: gtcholiday; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcholiday (holidayid, date, description, occursallyear, libraryunitid) FROM stdin;
\.


--
-- Data for Name: gtcinterchange; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcinterchange (interchangeid, type, supplierid, description, date, interchangestatusid, interchangetypeid, operator) FROM stdin;
\.


--
-- Data for Name: gtcinterchangeitem; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcinterchangeitem (interchangeitemid, interchangeid, controlnumber, content) FROM stdin;
\.


--
-- Data for Name: gtcinterchangeobservation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcinterchangeobservation (interchangeobservationid, interchangeid, observation, date, operator) FROM stdin;
\.


--
-- Data for Name: gtcinterchangestatus; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcinterchangestatus (interchangestatusid, description, interchangetypeid) FROM stdin;
1	Criada	1
2	Carta enviada	1
3	Confirmado	1
4	Criada	2
5	Agradecido	2
\.


--
-- Data for Name: gtcinterchangetype; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcinterchangetype (interchangetypeid, description) FROM stdin;
1	Envio
2	Recebimento
\.


--
-- Data for Name: gtcinterestsarea; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcinterestsarea (personid, classificationareaid, bud_dia2sql_ignorar) FROM stdin;
\.


--
-- Data for Name: gtckardexcontrol; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtckardexcontrol (controlnumber, codigodeassinante, libraryunitid, acquisitiontype, vencimentodaassinatura, datadaassinatura, entrancedate, line) FROM stdin;
\.


--
-- Data for Name: gtclabellayout; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtclabellayout (labellayoutid, description, topmargin, leftmargin, verticalspacing, horizontalspacing, height, width, lines, columns, pageformat) FROM stdin;
2	PIMACO 5580A/5580M/5580V	1.27	0.47999999999999998	2.54	6.9800000000000004	2.54	6.6699999999999999	10	3	Letter
3	PIMACO 6080/6180/ 6280/62580	1.27	0.47999999999999998	2.54	6.9800000000000004	2.54	6.6699999999999999	10	3	Letter
4	PIMACO 6081/6181/6281/62581	1.27	0.40000000000000002	2.54	10.68	2.54	10.16	10	2	Letter
5	PIMACO 6082/6182/6282/62582	2.1200000000000001	0.40000000000000002	3.3900000000000001	10.68	3.3900000000000001	10.16	7	2	Letter
6	PIMACO 6083/6183/6283	1.27	0.40000000000000002	5.0800000000000001	10.68	5.0800000000000001	10.16	5	2	Letter
7	PIMACO 6084/6184/6284	1.27	0.40000000000000002	8.4700000000000006	10.68	8.4700000000000006	10.16	3	2	Letter
8	PIMACO 6085/6185/6285	0	0	27.940000000000001	21.59	27.940000000000001	21.59	1	1	Letter
9	PIMACO 6086/6286	0.16	0.16	13.81	21.27	13.81	21.27	2	1	Letter
10	PIMACO 6087/6187/6287	1.27	1.45	1.27	4.75	1.27	4.4400000000000004	20	4	Letter
11	PIMACO 6088/6288	0.16	0.16	13.81	10.640000000000001	13.81	10.640000000000001	2	2	Letter
12	PIMACO 6089	1.27	1.45	1.6899999999999999	4.75	1.6899999999999999	4.4400000000000004	15	4	Letter
13	PIMACO 6092	1.6899999999999999	1.3	2.8900000000000001	2.9100000000000001	1.7	1.7	9	7	Letter
14	PIMACO 6093/6293	1.51	1.45	4.4100000000000001	5.2000000000000002	2.7400000000000002	3.1000000000000001	6	4	Letter
15	PIMACO 6094	1.6699999999999999	1.8999999999999999	6.5999999999999996	6.75	4.8499999999999996	4.3499999999999996	4	3	Letter
16	PIMACO 6095	2.1200000000000001	1.7	5.9299999999999997	9.6300000000000008	5.9299999999999997	8.5700000000000003	4	2	Letter
17	PIMACO 7088/7188	1.27	1.8999999999999999	5.0800000000000001	8.8900000000000006	5.0800000000000001	8.8900000000000006	5	2	Letter
18	PIMACO 8096/8196/8296	1.27	0.32000000000000001	7.6200000000000001	6.9800000000000004	6.9800000000000004	6.9800000000000004	3	3	Letter
19	PIMACO 8098	1.27	1.27	4.2300000000000004	10.16	4.2300000000000004	8.8900000000000006	6	2	Letter
20	PIMACO 8099F	2.3300000000000001	2.7200000000000002	4.6600000000000001	8.3800000000000008	4.6600000000000001	7.7800000000000002	5	2	Letter
21	PIMACO 8099L	1.27	3.4100000000000001	1.6899999999999999	14.76	1.6899999999999999	14.76	15	1	Letter
22	PIMACO A4248/A4348	1.25	0.69999999999999996	1.7	3.2999999999999998	1.7	3.1000000000000001	16	6	A4
23	PIMACO A4249/A4349	1.3500000000000001	0.80000000000000004	1.5	2.7999999999999998	1.5	2.6000000000000001	18	7	A4
24	PIMACO A4250/A4350	0.90000000000000002	0.46999999999999997	5.5800000000000001	10.16	5.5800000000000001	9.9000000000000004	5	2	A4
25	PIMACO A4251/A4351	1.0700000000000001	0.45000000000000001	2.1200000000000001	4.0700000000000003	2.1200000000000001	3.8199999999999998	13	5	A4
26	PIMACO A4254/A4354	0.88	0.46999999999999997	2.54	10.16	2.54	9.9000000000000004	11	2	A4
27	PIMACO A4255/A4355	0.90000000000000002	0.71999999999999997	3.1000000000000001	6.6100000000000003	3.1000000000000001	6.3499999999999996	9	3	A4
28	PIMACO A4256/A4356	0.88	0.71999999999999997	2.54	6.6100000000000003	2.54	6.3499999999999996	11	3	A4
29	PIMACO A4260/A4360	1.52	0.71999999999999997	3.8100000000000001	6.6100000000000003	3.8100000000000001	6.3499999999999996	7	3	A4
30	PIMACO A4261/A4361	0.91000000000000003	0.71999999999999997	4.6500000000000004	6.6100000000000003	4.6500000000000004	6.3499999999999996	6	3	A4
31	PIMACO A4262/A4362	1.29	0.46999999999999997	3.3900000000000001	10.16	3.3900000000000001	9.9000000000000004	8	2	A4
32	PIMACO A4263/A4363	1.52	0.46999999999999997	3.8100000000000001	10.16	3.8100000000000001	9.9000000000000004	7	2	A4
33	PIMACO A4264/A4364	0.46999999999999997	0.71999999999999997	7.1900000000000004	6.6100000000000003	7.1900000000000004	6.3499999999999996	4	3	A4
34	PIMACO A4265/A4365	1.3	0.46999999999999997	6.7800000000000002	10.16	6.7800000000000002	9.9000000000000004	4	2	A4
35	PIMACO A4267/A4367	0.42999999999999999	0.5	28.850000000000001	20	28.850000000000001	20	1	1	A4
36	PIMACO A4268/A4368	0.51000000000000001	0.51000000000000001	14.34	19.989999999999998	14.34	19.989999999999998	2	1	A4
37	PIMACO A4291F	0.93000000000000005	2.75	4.6399999999999997	7.8700000000000001	4.6399999999999997	7.6200000000000001	6	2	A4
38	PIMACO A4291L	1.25	3.25	1.7	14.5	1.7	14.5	16	1	A4
39	PIMACO A4292	1.8500000000000001	2.3300000000000001	5.2000000000000002	9.3300000000000001	5.2000000000000002	7	5	2	A4
40	PIMACO A4293	2.3599999999999999	2.1200000000000001	4.4000000000000004	4.5999999999999996	2.9700000000000002	2.9700000000000002	6	4	A4
76	PIMACO *A5Q-1219	0.85999999999999999	1.1499999999999999	1.2	1.8999999999999999	1.2	2.1000000000000001	11	9	A5
77	PIMACO *A5Q-1226	0.85999999999999999	0.80000000000000004	1.2	2.6000000000000001	1.2	2.7999999999999998	11	7	A5
78	PIMACO *A5Q-1250	1.22	2.7999999999999998	1.2	5	1.3999999999999999	5.2000000000000002	9	3	A5
79	PIMACO *A5Q-1534	1.46	1.2	1.5	3.3999999999999999	1.5	3.7999999999999998	8	5	A5
80	PIMACO *A5Q-1723	0.62	0.59999999999999998	1.7	2.2999999999999998	2	2.5	7	8	A5
81	PIMACO *A5Q-1837	1.1599999999999999	0.84999999999999998	1.8	3.7000000000000002	1.8	3.8999999999999999	7	5	A5
82	PIMACO *A5Q-2050	0.85999999999999999	1.75	2.2000000000000002	5.5	2.2000000000000002	6	6	3	A5
83	PIMACO *A5Q-2232	0.85999999999999999	1.5	2.2000000000000002	3.2000000000000002	2.2000000000000002	3.7000000000000002	6	5	A5
84	PIMACO *A5Q-2337	1.71	0.84999999999999998	2.2999999999999998	3.7000000000000002	2.2999999999999998	3.8999999999999999	5	5	A5
85	PIMACO *A5Q-2372	0.85999999999999999	1	2.2000000000000002	9	2.2000000000000002	10	6	2	A5
86	PIMACO *A5Q-3272	1.0600000000000001	1	3.2000000000000002	9	3.2000000000000002	10	4	2	A5
87	PIMACO *A5Q-3348	0.85999999999999999	0.59999999999999998	3.2999999999999998	4.7999999999999998	3.2999999999999998	5	4	4	A5
88	PIMACO A5Q-3465	2	0.81999999999999995	3.3999999999999999	6.5	3.3999999999999999	6.7000000000000002	5	2	A5
89	PIMACO A5Q-35105	1.1499999999999999	2.21	3.5	10.5	3.7999999999999998	10.5	5	1	A5
90	PIMACO A5Q-50100	2.5	2.46	5	10	5.5	10	3	1	A5
91	PIMACO A5Q-66115	0.59999999999999998	1.72	6.5999999999999996	11.5	6.5999999999999996	11.5	3	1	A5
92	PIMACO A5Q-813	0.56000000000000005	0.84999999999999998	0.80000000000000004	1.3	1	1.5	14	13	A5
93	PIMACO A5Q-916	1.1599999999999999	1.6000000000000001	0.90000000000000002	1.6000000000000001	0.90000000000000002	1.8	14	10	A5
94	PIMACO A5Q-932	1.1599999999999999	1.5	0.90000000000000002	3.2000000000000002	0.90000000000000002	3.7000000000000002	14	5	A5
95	PIMACO A5Q-97138	0.55000000000000004	0.56000000000000005	9.8000000000000007	13.800000000000001	10	13.800000000000001	2	1	A5
96	PIMACO A5R-1313	0.81000000000000005	0.84999999999999998	1.3	1.3	1.5	1.5	9	13	A5
97	PIMACO A5R1919	0.75	0.51000000000000001	1.8999999999999999	1.8999999999999999	2.2000000000000002	2	9	7	A5
98	PIMACO A5R-909	0.68000000000000005	0.68999999999999995	0.90000000000000002	0.90000000000000002	1.25	1.1499999999999999	16	12	A5
41	PIMACO 8136	0	0.94999999999999996	3.8100000000000001	0	3.6499999999999999	8.0999999999999996	8	1	A4
42	PIMACO 8923	0	1.1000000000000001	2.54	0	2.3799999999999999	8.8900000000000006	12	1	A4
43	PIMACO 8923 MC	0	1.1000000000000001	2.54	0	2.3799999999999999	8.8900000000000006	12	1	A4
44	PIMACO 8936	0	1.1000000000000001	3.8100000000000001	0	3.6499999999999999	8.8900000000000006	8	1	A4
45	PIMACO 10236 MC	0	0.90000000000000002	3.8100000000000001	0	3.6499999999999999	10.199999999999999	8	1	A4
46	PIMACO 10723	0	0.90000000000000002	2.54	0	2.3799999999999999	10.66	12	1	A4
47	PIMACO 10736	0	0.90000000000000002	3.8100000000000001	0	3.6499999999999999	10.66	8	1	A4
48	PIMACO 10748	0	0.90000000000000002	5.0800000000000001	0	4.9199999999999999	10.66	6	1	A4
49	PIMACO 12536	0	0.90000000000000002	3.8100000000000001	0	3.6499999999999999	12.5	8	1	A4
50	PIMACO 12548	0	0.90000000000000002	5.0800000000000001	0	4.9199999999999999	12.5	6	1	A4
51	PIMACO 12874	0	1.2	7.6200000000000001	0	7.46	12.800000000000001	4	1	A4
52	PIMACO 14948	0	0.90000000000000002	5.0800000000000001	0	4.9199999999999999	14.800000000000001	6	1	A4
53	PIMACO 7023	0	1.1000000000000001	2.54	7.3600000000000003	2.3799999999999999	7	12	2	A4
54	PIMACO 8923	0	1	2.54	9.1400000000000006	2.3799999999999999	8.8900000000000006	12	2	A4
55	PIMACO 8936	0	1	3.8100000000000001	9.1400000000000006	3.6499999999999999	8.8900000000000006	8	2	A4
56	PIMACO 10223 MC	0	0.90000000000000002	2.54	10.41	2.3799999999999999	10.16	6	2	A4
57	PIMACO 10723	0	1	2.54	10.92	2.3799999999999999	10.66	12	2	A4
58	PIMACO 10736	0	1	3.8100000000000001	10.92	3.6499999999999999	10.66	8	2	A4
59	PIMACO 10748	0	1	5.0800000000000001	10.92	4.9199999999999999	10.66	6	2	A4
60	PIMACO 12536	0	1.3	3.8100000000000001	12.699999999999999	3.6499999999999999	12.44	8	2	A4
61	PIMACO 8923	0	1	2.54	9.1400000000000006	2.3799999999999999	8.8900000000000006	12	3	A4
62	PIMACO 8936	0	1	3.8100000000000001	9.1400000000000006	3.6499999999999999	8.8900000000000006	8	3	A4
63	PIMACO 10236	0	1.1499999999999999	3.8100000000000001	10.41	3.6499999999999999	10.16	8	3	A4
64	PIMACO 10723	0	1	2.54	10.92	2.3799999999999999	10.66	12	3	A4
65	PIMACO 10736	0	1	3.8100000000000001	10.92	3.6499999999999999	10.66	8	3	A4
66	PIMACO 10748	0	1	5.0800000000000001	10.92	4.9199999999999999	10.66	6	3	A4
67	PIMACO 10774	0	1	7.6200000000000001	10.92	7.46	10.66	4	3	A4
68	PIMACO 5115	0	0.90000000000000002	1.6899999999999999	5.3300000000000001	1.53	5.0800000000000001	18	4	A4
69	PIMACO 8123	0	1.0600000000000001	2.54	8.3800000000000008	2.3799999999999999	8.1199999999999992	12	4	A4
70	PIMACO 8136	0	1.0600000000000001	3.8100000000000001	8.3800000000000008	3.6499999999999999	8.1199999999999992	8	4	A4
71	PIMACO 8148	0	1.0600000000000001	5.0800000000000001	8.3800000000000008	4.9199999999999999	8.1199999999999992	6	4	A4
72	PIMACO 2615	0	0.90000000000000002	1.6899999999999999	3.04	1.53	2.6699999999999999	18	5	A4
73	PIMACO 3823	0	1.0600000000000001	2.54	4.0599999999999996	2.3799999999999999	3.8100000000000001	12	5	A4
74	PIMACO 3810	0	1.1000000000000001	1.27	4.0599999999999996	1.1100000000000001	3.8100000000000001	24	8	A4
75	PIMACO 3117	0	0.90000000000000002	1.8999999999999999	3.2999999999999998	1.74	3.04	16	10	A4
\.


--
-- Data for Name: gtclibraryassociation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtclibraryassociation (associationid, libraryunitid, bug_dia2sql_ignorar) FROM stdin;
\.


--
-- Data for Name: gtclibrarygroup; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtclibrarygroup (librarygroupid, description, observation) FROM stdin;
\.


--
-- Data for Name: gtclibraryunit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtclibraryunit (libraryunitid, libraryname, isrestricted, city, zipcode, location, number, complement, email, url, librarygroupid, privilegegroupid, observation, level, acceptpurchaserequest) FROM stdin;
\.


--
-- Data for Name: gtclibraryunitaccess; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtclibraryunitaccess (libraryunitid, linkid, bug_dia2sql_ignorar) FROM stdin;
\.


--
-- Data for Name: gtclibraryunitconfig; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtclibraryunitconfig (libraryunitid, parameter, value) FROM stdin;
\.


--
-- Data for Name: gtclibraryunitisclosed; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtclibraryunitisclosed (libraryunitid, weekdayid, bug_dia2sql_ignorar) FROM stdin;
\.


--
-- Data for Name: gtclinkoffieldsbetweenspreadsheets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtclinkoffieldsbetweenspreadsheets (linkoffieldsbetweenspreadsheetsid, category, level, tag, categoryson, levelson, tagson, type) FROM stdin;
1	SE	#	001.a	SE	4	773.w	1
2	BK	4	001.a	BA	4	773.w	1
3	SE	4	001.a	SA	4	773.w	1
4	SE	#	090.a	SE	4	090.a	2
5	SE	#	090.b	SE	4	090.b	2
6	SE	#	245.a	SE	4	245.a	2
7	SE	#	245.b	SE	4	245.b	2
8	SE	#	245.c	SE	4	245.c	2
9	SE	#	245.h	SE	4	245.h	2
10	SE	#	246.a	SE	4	246.a	2
11	SE	#	246.b	SE	4	246.b	2
12	SE	4	090.a	SA	4	090.a	2
13	SE	4	090.b	SA	4	090.b	2
14	SE	4	245.a	SA	4	773.t	2
15	SE	4	246.a	SA	4	246.a	2
16	SE	4	246.b	SA	4	246.b	2
17	SE	4	362.a	SA	4	362.a	2
\.


--
-- Data for Name: gtcloan; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcloan (loanid, loantypeid, personid, linkid, privilegegroupid, itemnumber, libraryunitid, loandate, loanoperator, returnforecastdate, returndate, returnoperator, renewalamount, renewalwebamount, renewalwebbonus) FROM stdin;
\.


--
-- Data for Name: gtcloanbetweenlibrary; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcloanbetweenlibrary (loanbetweenlibraryid, loandate, returnforecastdate, returndate, limitdate, libraryunitid, personid, loanbetweenlibrarystatusid, observation) FROM stdin;
\.


--
-- Data for Name: gtcloanbetweenlibrarycomposition; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcloanbetweenlibrarycomposition (loanbetweenlibraryid, itemnumber, isconfirmed) FROM stdin;
\.


--
-- Data for Name: gtcloanbetweenlibrarystatus; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcloanbetweenlibrarystatus (loanbetweenlibrarystatusid, description) FROM stdin;
1	Solicitado
2	Cancelado
3	Aprovado
4	Reprovado
5	Confirmado
6	Devolução
7	Finalizado
\.


--
-- Data for Name: gtcloanbetweenlibrarystatushistory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcloanbetweenlibrarystatushistory (loanbetweenlibraryid, loanbetweenlibrarystatusid, date, operator) FROM stdin;
\.


--
-- Data for Name: gtcloantype; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcloantype (loantypeid, description) FROM stdin;
1	Padrão
2	Forçado
3	Momentâneo
\.


--
-- Data for Name: gtclocationformaterialmovement; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtclocationformaterialmovement (locationformaterialmovementid, description, observation, sendloanreceiptbyemail, sendrenewreceiptbyemail, sendreturnreceiptbyemail) FROM stdin;
0	Todos lugares	Lugar comum para vários lugares	t	t	t
1	Local	Quando houver circulação de material no local	t	t	t
\.


--
-- Data for Name: gtcmarctaglisting; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcmarctaglisting (marctaglistingid, description) FROM stdin;
000-05	Leader:Status
000-06	Leader:Tipo
000-07	Leader:Nivel Bibliografico
000-08	Leader:Tipo de controle
000-17	Leader:Nivel de catalagoção
000-18	Leader:Forma de catalogação
000-19	Leader:Ligação de registro
008-06-BK	Book:Tipo de Data/Status de Publicação
008-06-CF	Computer File:Tipo de data/status de publicação
008-06-MP	Mapas:Tipo de data / status de publicação
008-06-MX	Material Misto:Tipo de data / status de publicação
008-06-SE	Periódicos:Tipo de data/Status de publicação
008-06-VM	Material Visual:Tipo de data / status de publicação
008-18-BK	Book:Ilustrações
008-18-MP	Mapas:Relevo
008-18-MU	Música:Forma de composição
008-18-SE	Periódicos:Freqüência
008-19-SE	Periódicos:Regularidade
008-20-MU	Música:Formato da música
008-20-SE	Periódicos:Centro que atribui o ISSN
008-21-SE	Periódicos:Tipo de periódico
008-22-BK	Book:Público alvo
008-22-CF	Computer File:Público alvo
008-22-MP	Mapas:Projeção
008-22-MU	Música:Público alvo
008-22-SE	Periódicos:Forma do item original
008-22-VM	Material Visual:Público alvo
008-23-BK	Book:Forma do item
008-23-MU	Música:Forma do item
008-23-MX	Material Misto:Forma do item
008-23-SE	Periódicos:Forma do item
008-24-BK	Book:Natureza do conteúdo
008-24-MU	Música:Matéria completamentar
008-24-SE	Natureza da obra
008-24-SK	Periódicos:Natureza da obra
008-25-MP	Mapas:Tipo de material cartográfico
008-25-SE	Periódicos:Natureza do conteúdo
008-26-CF	Computer File:Tipo de arquivo de computador
008-28-BK	Book:Publicação governamental
008-28-CF	Computer File:Publicação governamental
008-28-MP	Mapas:Publicação governamental
008-28-SE	Periódicos:Publicação governamental
008-28-VM	Material Visual:Publicação governamental
008-29-BK	Book:Publicação de evento
008-29-SE	Periódicos:Publicação de evento
008-30-BK	Book:Coletânea de homenagem
008-30-MU	Música:Texto literário para gravação sonora
008-31-BK	Book:Índice
008-33-BK	Forma literária
008-33-MP	Mapas:Caracteristica especiais do formato
008-33-SE	Periódicos:Alfabeto original ou escrita do título
008-33-VM	Material Visual:Tipo de material visual
008-34-BK	Book:Biografia
008-34-SE	Periódicos:Entrada sucessiva/mais recente
008-34-VM	Material Visual:Técnica
008-38-BK	Book:Registro modificado
008-38-CF	Computer File:Registro modificado
008-38-MP	Mapas:Registro modificado
008-38-MU	Música:Registro modificado
008-38-MX	Material Misto:Registro modificado
008-38-SE	Periódicos:Registro modificado
008-38-VM	Material Visual:Registro modificado
008-39-BK	Book:Fonte da catalogação
008-39-CF	Computer File:Fontes da catalogação
008-39-MP	Mapas:Fonte da catalogação
008-39-MU	Música:Fonte da catalogação
008-39-MX	Material Misto:Fonte da catalogação
008-39-SE	Periódicos:Fonte da catalogação
008-39-VM	Material Visual:Fonte da catalogação
022-I1	Nível de interesse internacional
041-I1	Indicação de tradução
100-I1	Tipo de entrada do nome pessoal
110-I1	Tipo do nome corporativo
111-I1	Tipo do nome do evento
210-I1	Entrada secundária de título
210-I2	Tipo de título abreviado
245-I1	Entrada Secundária de Título
245-I2	Caracteres a desprezar na alfabetação
362-I1	Formato da data
440-I2	Caracteres a desprezar na alfabetação
505-I1	Controle de constante para visualização
505-I2	Nível da Informação de conteúdo
555-I1	Controle de constante para visualização
650-I1	Nível do Assunto
650-I2	Sistema de cabeçalho de assunto/thesaurus
653-I1	Nível do termo do índice
700-I1	Tipo de entrada do nome pessoal
700-I2	Tipo de entrada secundária
710-I1	Tipo de entrada do nome corporativo
710-I2	Tipo de entrada secundária
711-I1	Tipo de entrada secundária
711-I2	Tipo de entrada secundária
720-I1	Tipo do nome
780-I1	Controle de nota
780-I2	Tipo de relação
785-I1	Controle de nota
785-I2	Tipo de relação
949.c	Lista de Tipos de Aquisição
CATEGORY	Categoria dos materiais
LEVEL	Nível
008-31-MP	Mapa:Índice 
008-06-MU	Música:Tipo de data / status de publicação
008-15	Lugar de Publicação
008-35	Idioma
949.5	Material que acompanha
960.c	Lista de Tipos de Aquisição
901.b	Área de conhecimento
\.


--
-- Data for Name: gtcmarctaglistingoption; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcmarctaglistingoption (marctaglistingid, option, description) FROM stdin;
000-05	a	Aumento no nível de catalogação
000-05	c	Alterado ou revisado
000-05	d	Deletado
000-05	n	Novo
000-05	p	Aumento do Nível de catalogação da pré-publicação
000-06	a	Material Textual (impresso)
000-06	c	Música (impressa)
000-06	d	Música manuscrita
000-06	e	Material cartográfico (impresso)
000-06	f	Material cartográfico (manuscrito)
000-06	g	Material projetável
000-06	i	Gravação sonora (não musical)
000-06	j	Gravação sonora (musical)
000-06	k	Gráfico não projetável bidimensional
000-06	m	Arquivo de computador
000-06	o	Kit (contém duas ou mais categorias de material)
000-06	p	Material misto
000-06	r	Artefatos tridimensionais e objetos
000-06	t	Material textual (manuscrito)
000-07	a	Analítica de monografia
000-07	b	Analítica de periódico
000-07	c	Coleção
000-07	d	Sub-unidade
000-07	m	Monografia
000-07	s	Periódico
000-08	#	Nenhum tipo específico
000-08	a	Arquivamento
000-17	#	Completo
000-17	1	Completo (material não examinado)
000-17	2	Incompleto, material não examinado
000-17	3	Abreviado
000-17	4	Nível padrão
000-17	5	Parcial (preliminar)
000-17	7	Mínimo
000-17	8	Pré-publicação
000-17	u	Desconhecido
000-17	z	Não aplicável
000-18	#	Não está de acordo com ISBD
000-18	a	AACR2
000-18	i	ISBD
000-19	#	Não analítica
000-19	r	Analítica
008-06-BK	b	Não há datas; envolve data A.C.
008-06-BK	c	Data atual e de copyright (obsoleto)
008-06-BK	d	Data detalhada (obsoleto)
008-06-BK	i	Datas limite de uma coleção
008-06-BK	m	Múltiplas datas
008-06-BK	n	Data desconhecida
008-06-BK	q	Data incompleta
008-06-BK	r	Data de reimpressão/reedição e data original
008-06-BK	s	Data única/provável
008-06-CF	b	Não há datas; envolve data A.C.
008-06-CF	c	Data atual e de copyright (OBSOLETO)
008-06-CF	d	Data detalhada (OBSOLETO)
008-06-CF	i	Datas limite de uma coleção
008-06-CF	m	Múltiplas datas
008-06-CF	n	Data desconhecida
008-06-CF	q	Data incompleta
008-06-CF	r	Data de reimpressão / reedição e data original
008-06-CF	s	Data única / data provável
008-06-CF		
008-06-MP	b	Não há datas; envolve data A.C.
008-06-MP	c	Data atual e de copyright (OBSOLETO)
008-06-MP	d	Data detalhada (OBSOLETO)
008-06-MP	i	Datas limite de uma coleção
008-06-MP	m	Múltipas datas
008-06-MP	n	Data desconhecida
008-06-MP	q	data incompleta
008-06-MP	r	Data de reimpressão / reedição e data original
008-06-MP	s	Data única / data provável
008-06-MP		
008-06-MX	b	Não há  datas;  envolve data A.C.
008-06-MX	c	Data atual e de copyright (OBSOLETO)
008-06-MX	d	Data detalhada (OBSOLETO)
008-06-MX	i	Datas limite de uma coleção
008-06-MX	m	Múltiplas datas
008-06-MX	n	Data desconhecida
008-06-MX	q	Data incompleta
008-06-MX	r	Data de reimpressão / reedição e data original
008-06-MX	s	Data única / data provável
008-06-MX		
008-06-SE	c	Item seriado de publicação corrente
008-06-SE	d	Item seriado de publicação encerrada
008-06-SE	u	Status desconhecido
008-06-VM	b	Não há datas; envolve data A.C.
008-06-VM	c	Data atual e de copyright (OBSOLETO)
008-06-VM	d	Data detalhada (OBSOLETO)
008-06-VM	i	Datas limite de uma coleção
008-06-VM	m	Múltiplas datas
008-06-VM	n	Data desconhecida
008-06-VM	p	Data de distribuição / lançamento / publicação e produção / ou sessão de gravação quando diferente ( CF, MU, VM)
008-06-VM	q	Data incompleta
008-06-VM	r	Data de reimpressão / reedição e data original
008-06-VM	s	Data única / data provável
008-06-VM		
008-18-BK	#	Sem ilustração
008-18-BK	a	Ilustrações
008-18-BK	b	Mapas
008-18-BK	c	Retratos
008-18-BK	d	Gráficos
008-18-BK	e	Plantas
008-18-BK	f	Estampas
008-18-BK	g	Música (partitura)
008-18-BK	h	Fac-símiles
008-18-BK	i	Escudos ou brasões
008-18-BK	j	Árvore genealógica
008-18-BK	k	Formúlarios
008-18-BK	l	Amostras, tabelas estatísticas
008-18-BK	m	Gravações
008-18-BK	o	Fotografias
008-18-BK	p	Transparências
008-18-BK		
008-18-MP	#	Não há relevo
008-18-MP	a	Contorno do relevo
008-18-MP	b	Sombreado
008-18-MP	c	Gradiente e batimetria
008-18-MP	d	Hachuras
008-18-MP	e	Batimetria e sondagens
008-18-MP	f	Linhas de forma
008-18-MP	g	Pontos cotados
008-18-MP	i	Pictório
008-18-MP	j	Formas de relevo
008-18-MP	k	Batimetria / isolinhas
008-18-MP	m	Indicação de afloramentos rochosos
008-18-MP	z	Outros tipos de relevo
008-18-MP		
008-18-MU	an	 Canção patriótica
008-18-MU	bd	Baladas
008-18-MU	bg	Bluegrass
008-18-MU	bl	Blues
008-18-MU	bt	Ballet
008-18-MU	cn	Canon e rounds
008-18-MU	ct	Cantatas
008-18-MU	cz	Canzonas
008-18-MU	cr	Cântico de natal
008-18-MU	ca	Chaconnes
008-18-MU	cs	Chance compositions
008-18-MU	cp	Canções, polifonia
008-18-MU	cc	Canções, cristãs
008-18-MU	cb	Canções, outras religiões
008-18-MU	cl	Chorale preludes
008-18-MU	ch	Corais
008-18-MU	cg	Concerti grossi
008-18-MU	co	Concertos
008-18-MU	cy	Música country
008-18-MU	df	Dance forms
008-18-MU	dv	Divertimentos, etc.
008-18-MU	ft	Fantasias
008-18-MU	fm	Música gospel
008-18-MU	hy	Hino
008-18-MU	jz	Jazz
008-18-MU	md	Madrigais
008-18-MU	mr	Marchas
008-18-MU	ms	Missas
008-18-MU	mz	Mazurcas
008-18-MU	mi	Minuetos
008-18-MU	mo	Motetos
008-18-MU	mp	Música de filme
008-18-MU	mc	Revistas e comédias musicais
008-18-MU	mu	Múltiplas formas
008-18-MU	nc	Noturnos
008-18-MU	nn	Não aplicável
008-18-MU	op	Óperas
008-18-MU	or	Oratórios
008-18-MU	ov	Aberturas
008-18-MU	pt	Part-songs
008-18-MU	ps	Passacaglias
008-18-MU	pm	Passion music
008-18-MU	pv	Pavanas
008-18-MU	po	Polonaises
008-18-MU	pp	Música popular
008-18-MU	pr	Preludios
008-18-MU	pg	Program music
008-18-MU	rg	Ragtime music
008-18-MU	rq	Requiens
008-18-MU	ri	Ricercars
008-18-MU	rc	Rock
008-18-MU	rd	Rondós
008-18-MU	sn	Sonatas
008-18-MU	sg	Songs
008-18-MU	st	Estudos e exercícios
008-18-MU	su	Suítes
008-18-MU	sp	Poemas sinfônicos
008-18-MU	sy	Sinfonias
008-18-MU	tc	Tocatas
008-18-MU	ts	Trio-sonatas
008-18-MU	uu	Desconhecido
008-18-MU	vr	Variações
008-18-MU	wz	Valsas
008-18-MU	zz	Outro
008-18-MU		
008-18-SE	#	Freqüência não determinada
008-18-SE	a	Anual
008-18-SE	b	Bimestral
008-18-SE	c	Bissemanal
008-18-SE	d	Diário
008-18-SE	e	Quinzenal
008-18-SE	f	Semestral
008-18-SE	g	Bienal
008-18-SE	h	Trienal
008-18-SE	i	Três vezes por semana
008-18-SE	j	Três vezes por mês
008-18-SE	m	Mensal
008-18-SE	q	Trimestral
008-18-SE	s	Duas vezes por mês
008-18-SE	t	Quadrimestral
008-18-SE	u	Desconhecido
008-18-SE	w	Semanal
008-18-SE	z	Outro
008-19-SE	n	Irregular normalizado
008-19-SE	r	Regular
008-19-SE	u	Desconhecido
008-19-SE	x	Completamente irregular
008-20-MU	a	Full score
008-20-MU	b	Full score, miniature or study size
008-20-MU	c	Accompaniment reduced for keyboard
008-20-MU	d	Voice score
008-20-MU	e	Condensed score or piano-conductor score
008-20-MU	g	Close score
008-20-MU	m	Multiple score formats
008-20-MU	n	Não aplicável
008-20-MU	u	Desconhecido
008-20-MU	z	Outro
008-20-MU		
008-20-SE	#	Nenhum código atribuído
008-20-SE	0	Centro internacional (Paris, França)
008-20-SE	1	Estados Unidos
008-20-SE	2	Reino Unido (obsoleto)
008-20-SE	3	Austrália (obsoleto)
008-20-SE	4	Canadá
008-20-SE	5	Centro Regional de Moscou (obsoleto)
008-20-SE	6	República Federativa da Alemanha (obsoleto)
008-20-SE	7	França (obsoleto)
008-20-SE	8	Argentina (obsoleto)
008-20-SE	9	Japão (obsoleto)
008-20-SE	u	Desconhecido
008-20-SE	z	Outro
008-21-SE	#	Outro
008-21-SE	m	Série monográfica
008-21-SE	n	Jornal
008-21-SE	p	Revista/Publicação periódica
008-22-BK	#	Desconhecido ou não especificado
008-22-BK	a	Pré-escolar
008-22-BK	b	Primário
008-22-BK	c	1º Grau
008-22-BK	d	2º Grau
008-22-BK	e	Adulto
008-22-BK	f	Especializado
008-22-BK	g	Geral
008-22-BK	j	Juvenil
008-22-BK		
008-22-CF	#	Desconhecido ou não especificado
008-22-CF	a	Pré-escolar
008-22-CF	b	Primário
008-22-CF	c	1º Grau
008-22-CF	d	2º Grau
008-22-CF	e	Adulto
008-22-CF	f	Especializado
008-22-CF	g	Geral
008-22-CF	j	Juvenil
008-22-CF		
008-22-MP	##	Projeção não especificada
008-22-MP	aa	Aitoff
008-22-MP	ab	Gnomic
008-22-MP	ac	Lambert´s azimuthal equal area
008-22-MP	ad	Orthographic
008-22-MP	ae	Azimuthal equidistant
008-22-MP	af	Stereographic
008-22-MP	ag	General vertical near-sided
008-22-MP	am	Modified stereographic for Alaska
008-22-MP	an	Chamberlin trimetric
008-22-MP	ap	Polar stereographic
008-22-MP	au	Azimuthal, tipo específico desconhecido
008-22-MP	az	Azimuthal, Outro
008-22-MP	ba	Gall
008-22-MP	bb	Goode´s homolographic
008-22-MP	bc	Lambert´s cylindrical equal area
008-22-MP	bd	Mercator
008-22-MP	be	Miller
008-22-MP	bf	Mollweide
008-22-MP	bg	Sinusoidal
008-22-MP	gh	Transversa de Mercator
008-22-MP	bi	Gauss-Kruger
008-22-MP	bj	Equiretangular
008-22-MP	bo	Obliqua de Mercator
008-22-MP	br	Robinson
008-22-MP	bs	Space oblique Mercator
008-22-MP	bu	Cylindrical, tipo específico desconhecido
008-22-MP	bz	Cylindrical, outro
008-22-MP	ca	Alber´s equal area
008-22-MP	cb	Bonne
008-22-MP	cc	Lambert´s conformal conic
008-22-MP	cd	Equidistant conic
008-22-MP	cp	Policônica
008-22-MP	cu	Conic, tipo específico desconhecido
008-22-MP	cz	Conic, outro
008-22-MP	da	Armadillo
008-22-MP	db	Butterfly
008-22-MP	dc	Eckert
008-22-MP	dd	Goode´s homolosine
008-22-MP	de	Miller´s bipolar oblique conformal conic
008-22-MP	df	Van Der Grinten
008-22-MP	dg	Dimaxion
008-22-MP	dh	Cordiform
008-22-MP	dl	Lambert conformal
008-22-MP	zz	Outro
008-22-MP		
008-22-MU	#	Desconhecido ou não especificado
008-22-MU	a	Pré-escolar
008-22-MU	b	Primário
008-22-MU	c	1º Grau
008-22-MU	d	2º Grau
008-22-MU	e	Adulto
008-22-MU	f	Especializado
008-22-MU	g	Geral
008-22-MU	j	Juvenil
008-22-SE	#	Nenhuma das seguintes
008-22-SE	a	Microfilme
008-22-SE	b	Microficha
008-22-SE	c	Microficha opaca
008-22-SE	d	Impressão ampliada
008-22-SE	e	Formato de jornal
008-22-SE	f	Braille
008-22-SE	g	Fita de papel perfurada (obsoleto)
008-22-SE	h	Fita magnética (obsoleto)
008-22-SE	i	Multimídia (obsoleto)
008-22-SE	x	Outro meio físico (obsoleto)
008-22-SE	z	Outro meio físico (obsoleto)
008-22-VM	#	Desconhecido ou não especificado
008-22-VM	a	Pré-escolar
008-22-VM	b	Primário
008-22-VM	c	1º Grau
008-22-VM	d	2º Grau
008-22-VM	e	Adulto
008-22-VM	f	Especializado
008-22-VM	g	Geral
008-22-VM	j	Juvenil
008-22-VM		
008-23-BK	#	Nenhuma das seguintes
008-23-BK	a	Microfilme
008-23-BK	b	Microficha
008-23-BK	c	Microficha opaca
008-23-BK	d	Impressão ampliada
008-23-BK	f	Braille
008-23-BK	g	Fita de papel perfurada (obsoleto)
008-23-BK	h	Fita magnética (obsoleto)
008-23-BK	i	Multimídia (obsoleto)
008-23-BK	r	Impressão regular
008-23-BK	z	Outra forma de reprodução (obsoleto) 
008-23-BK		
008-23-MU	#	Nunhuma das seguintes
008-23-MU	a	Microfilme
008-23-MU	b	Microficha
008-23-MU	c	Microficha opaca
008-23-MU	d	Impressão ampliada
008-23-MU	f	Braille
008-23-MU	r	Impressão regular
008-23-MU	h	Fita magnética (OBSOLETO)
008-23-MU	i	Multimídia (OBSOLETO)
008-23-MU	x	Outra forma de reprodução (OBSOLETO)
008-23-MU	z	Outra forma de reprodução (OBSOLETO)
008-23-MU		
008-23-MX	#	Nenhuma das seguintes
008-23-MX	a	Microfilme
008-23-MX	b	Microficha
008-23-MX	c	Microficha opaca
008-23-MX	d	Impressão ampliada
008-23-MX	f	Braille
008-23-MX	g	Fita de papel perfurada (OBSOLETO)
008-23-MX	h	Fita magnética (OBSOLETO)
008-23-MX	i	Multimídia (OBSOLETO)
008-23-MX	r	Impressão regular
008-23-MX	z	Outra forma  de reprodução (OBSOLETO)
008-23-MX	j	Transcrição manual (OBSOLETO)
008-23-MX	p	Fotocópia (OBSOLETO)
008-23-MX	t	Transcrição a máquina (OBSOLETO)
008-23-MX		
008-23-SE	#	Nenhuma das seguintes
008-23-SE	a	Microfilme
008-23-SE	b	Microficha
008-23-SE	c	Microficha opaca
008-23-SE	d	Impressão ampliada
008-23-SE	e	Formato de jornal
008-23-SE	f	Braille
008-23-SE	g	Fita de papel perfurada (obsoleto)
008-23-SE	h	Fita magnética (obsoleto)
008-23-SE	i	Multimídia (obsoleto)
008-23-SE	r	Reprodução em impressão regular
008-23-SE	z	Outra forma de reprodução (obsoleto)
008-24-BK	#	Não especificado
008-24-BK	a	Resumos/sumários
008-24-BK	b	Bibliografias
008-24-BK	c	Catálogos
008-24-BK	d	Dicionários
008-24-BK	e	Enciclopédias
008-24-BK	f	Manuais
008-24-BK	g	Artigos legais
008-24-BK	i	Índices
008-24-BK	j	Patentes
008-24-BK	k	Discografia
008-24-BK	l	Legislação
008-24-BK	m	Teses
008-24-BK	n	Análise da literatura de uma área
008-24-BK	o	Recensões
008-24-BK	p	Textos programados
008-24-BK	q	Filmografias
008-24-BK	r	Guias/indicadores
008-24-BK	s	Estatísticas
008-24-BK	t	Relatórios técnicos
008-24-BK	v	Notas sobre casos legais
008-24-BK	w	Relatórios de legislação e jurisprudência
008-24-BK	y	Livros do ano (obsoleto)
008-24-BK	z	Tratados
008-24-BK		
008-24-MU	#	Não tem material complementar
008-24-MU	a	Discografia
008-24-MU	b	Bibliografia
008-24-MU	c	Índice temático
008-24-MU	d	Livreto ou texto
008-24-MU	e	Biografia do compositor ou autor
008-24-MU	f	Biografia do músico ou história do grupo
008-24-MU	g	Informações técnicas / históricas sobre instrumentos
008-24-MU	h	Informações técnicas sobre música
008-24-MU	i	Informação histórica
008-24-MU	k	Informação etnológica
008-24-MU	r	Material de instrução
008-24-MU	s	Música
008-24-MU	z	Outro
008-24-MU	j	Informação histórica mas não de música (OBSOLETO)
008-24-MU	n	Não aplicável (OBSOLETO)
008-24-MU		
008-24-SE	#	Natureza da obra
008-24-SE		
008-24-SE	a	Resumos/sumários
008-24-SE		
008-24-SE	b	Bibliografias
008-24-SE		
008-24-SE	c	Catálogos
008-24-SE		
008-24-SE	d	Dicionários
008-24-SE		
008-24-SE	e	Enciclopédias
008-24-SE		
008-24-SE	f	Manuais
008-24-SE		
008-24-SE	g	Artigos Legais
008-24-SE		
008-24-SE	i	Índices
008-24-SE		
008-24-SE	j	Patentes
008-24-SE		
008-24-SE	k	Discografias
008-24-SE		
008-24-SE	l	Legislação
008-24-SE		
008-24-SE	m	Teses
008-24-SE		
008-24-SE	n	Levantamento da literatura de uma área
008-24-SE		
008-24-SE	o	Recensões(criticas)
008-24-SE		
008-24-SE	p	Textos programados
008-24-SE		
008-24-SE	q	Filmografias
008-24-SE		
008-24-SE	r	Guias/indicadores
008-24-SE		
008-24-SE	s	Estatística
008-24-SE		
008-24-SE	t	Relatórios técnicos
008-24-SE		
008-24-SE	v	Notas sobre casos legais
008-24-SE		
008-24-SE	w	Relatórios de legislação e jurisprudência
008-24-SE		
008-24-SE	z	Tratados
008-24-SK	#	Não especificado
008-24-SK	a	Resumos/sumários
008-24-SK	b	Bibliografias
008-24-SK	c	Catálogos
008-24-SK	d	Dicionários
008-24-SK	e	Enciclopédias
008-24-SK	f	Manuais
008-24-SK	g	Artigos legais
008-24-SK	i	Índices
008-24-SK	j	Patentes
008-24-SK	k	Discografia
008-24-SK	l	Legislação
008-24-SK	m	Teses
008-24-SK	n	Levantamento da literatura de uma área
008-24-SK	o	Recensões (críticas)
008-24-SK	p	Textos programados
008-24-SK	q	Filmografias
008-24-SK	r	Guias/indicadores
008-24-SK	s	Estatísticas
008-24-SK	t	Relatórios técnicos
008-24-SK	v	Notas sobre casos legais
008-24-SK	w	Relatórios de legislação e jurisprudência
008-24-SK	z	Tratados
008-25-MP	a	Mapa simples
008-25-MP	b	Série de mapas - elemento de um conjunto
008-25-MP	c	Mapa seriado - parte de um mapa maior
008-25-MP	d	Globo
008-25-MP	e	Atlas
008-25-MP	f	Mapa separado, como parte de outra obra
008-25-MP	g	Mapa agregado, como parte de outra obra
008-25-MP	u	Desconhecido
008-25-MP	z	Outro
008-25-MP		
008-25-SE	#	Não especificado
008-25-SE	a	Resumos/sumários
008-25-SE	b	Bibliografias
008-25-SE	c	Catálogos
008-25-SE	d	Dicionários
008-25-SE	e	Enciclopédias
008-25-SE	f	Manuais
008-25-SE	g	Artigos legais
008-25-SE	h	Biografia
008-25-SE	i	Índices
008-25-SE	k	Discografia
008-25-SE	l	Legislação
008-25-SE	m	Teses
008-25-SE	n	Levantamento da literatura de uma área
008-25-SE	o	Recensões
008-25-SE	p	Textos programados
008-25-SE	q	Filmografias
008-25-SE	r	Guias/indicadores
008-25-SE	s	Estatísticas
008-25-SE	t	Relatórios técnicos
008-25-SE	v	Notas sobre casos legais
008-25-SE	w	Relatórios de legislação e jurisprudência
008-25-SE	y	Livros do ano (obsoleto)
008-25-SE	z	Tratados
008-26-CF	a	Dado numérico
008-26-CF	b	Programa de computador
008-26-CF	c	Representacional
008-26-CF	d	Documento
008-26-CF	e	Dado bibliográfico
008-26-CF	f	Fonte
008-26-CF	g	Jogo
008-26-CF	h	Som
008-26-CF	i	Multimídia interativa
008-26-CF	j	Sistema ou serviço online
008-26-CF	m	Combinação
008-26-CF	u	Desconhecido
008-26-CF	z	Outro
008-26-CF		
008-28-BK	#	Não é uma publicação governamental
008-28-BK	a	Membros autónomos/semi-autônomos de uma federação
008-28-BK	c	Multilocal
008-28-BK	f	Federal/nacional
008-28-BK	i	Internacionais intergovernamentais
008-28-BK	l	Municipal
008-28-BK	m	Multiestadual
008-28-BK	o	Publicação governamental - nível indeterminado
008-28-BK	s	Estado, província, território, jurisdição etc.
008-28-BK	u	Desconhecido se o item é publicação governamental
008-28-BK	z	Outros
008-28-BK		
008-28-CF	#	Não é publicação governamental
008-28-CF	a	Membros autônomos / semi-autônomos de uma federação
008-28-CF	c	Multilocal
008-28-CF	f	Federal / nacional
008-28-CF	i	Internacional intergovernamental
008-28-CF	l	Municipal
008-28-CF	m	Multiestadual
008-28-CF	s	Estado, província, território, jurisdição, etc.
008-28-CF	o	Publicação governamental / nível indeterminado
008-28-CF	u	Desconhecido se o item é publicação governamental
008-28-CF	z	Outro
008-28-CF		
008-28-MP	#	Não é publicação governamental
008-28-MP	a	Membros autônomos  / semi-autônomos de uma federação
008-28-MP	c	Multilocal
008-28-MP	f	Federal / nacional
008-28-MP	i	Internacional intergovernamental
008-28-MP	l	Municipal
008-28-MP	m	Multiestadual
008-28-MP	s	Estado, província, território, jurisdição, etc.
008-28-MP	o	Publicação governamental - nível indeterminado
008-28-MP	u	Desconhecido se o item é publicação governamental
008-28-MP	z	outro
008-28-MP		
008-28-SE	#	Não é uma publicação governamental
008-28-SE	a	Membros autónomos/semi-autônomos de uma federação
008-28-SE	c	Multilocal
008-28-SE	f	Federal/nacional
008-28-SE	i	Internacionais intergovernamentais
008-28-SE	l	Municipal
008-28-SE	m	Multiestadual
008-28-SE	o	Publicação governamental - nível indeterminado
008-28-SE	s	Estado, província, território, jurisdição etc.
008-28-SE	u	Desconhecido se o item é publicação governamental
008-28-SE	z	Outros
008-28-VM	#	Não é publicação governamental
008-28-VM	a	Membros autônomos / semi-autônomos de uma federação
008-28-VM	c	Multilocal
008-28-VM	f	Federal / nacional
008-28-VM	i	Internacional intergovernamental
008-28-VM	l	Municipal
008-28-VM	m	Multiestadual
008-28-VM	s	Estado, província, território, jurisdição, etc.
008-28-VM	o	Publicação governamental - nível indeterminado
008-28-VM	u	Desconhecido se o item é publicação governamental
008-28-VM	z	Outro
008-28-VM		
008-29-BK	0	Não é publicação de evento
008-29-BK	1	Publicação de evento
008-29-BK		
008-29-SE	0	Não é publicação de evento
008-29-SE	1	Publicação de evento
008-30-BK	0	Não é coletânea de homenagem
008-30-BK	1	Coletânea de homenagem
008-30-BK		
008-30-MU	#	Item é um registro sonoro musical
008-30-MU	a	Autobiografia
008-30-MU	b	Biografia
008-30-MU	c	Proceedings
008-30-MU	d	Drama
008-30-MU	e	Ensaio
008-30-MU	f	Ficção
008-30-MU	g	Reportagem
008-30-MU	h	História
008-30-MU	i	Instrução
008-30-MU	j	Curso de idioma
008-30-MU	k	Comédia
008-30-MU	l	Palestras, discursos
008-30-MU	m	Memórias
008-30-MU	n	Não aplicável
008-30-MU	o	Lenda popular
008-30-MU	p	Poesia
008-30-MU	r	Enaio
008-30-MU	s	Sons
008-30-MU	t	Entrevistas
008-30-MU	z	Outro
008-30-MU		
008-31-BK	0	Não possui índice
008-31-BK	1	Possui índice
008-31-BK		
008-33-BK	0	Não é ficção
008-33-BK	1	Ficção
008-33-BK	c	História em quadrinhos
008-33-BK	d	Drama
008-33-BK	e	Ensaio
008-33-BK	f	Romance
008-33-BK	h	Humor, sátira etc.
008-33-BK	i	Cartas
008-33-BK	j	Contos
008-33-BK	m	Formas mistas
008-33-BK	p	Poesia
008-33-BK	s	Discursos
008-33-BK	u	Desconhecido
008-33-BK		
008-33-MP	#	Não há caracteristica especiais do formato
008-33-MP	a	Fotocópia, cópia heliográfica (OBSOLETO)
008-33-MP	b	Fotocópia  (OBSOLETO)
008-33-MP	c	Fotocópia negativa (OBSOLETO)
008-33-MP	d	Filme negativo (OBSOLETO)
008-33-MP	e	Manuscrito
008-33-MP	f	Fac-símile (OBSOLETO)
008-33-MP	g	Relief model (OBSOLETO)
008-33-MP	h	Raro (OBSOLETO)
008-33-MP	j	Picture card, cartão postal
008-33-MP	k	Calendário
008-33-MP	l	Quebra cabeça
008-33-MP	m	Braille
008-33-MP	n	Jogo
008-33-MP	o	Mapa de parede
008-33-MP	p	Jogo de cartas
008-33-MP	q	Impressão ampliada
008-33-MP	r	Folhas soltas
008-33-MP	z	Outro
008-33-MP		
008-33-SE	#	Nenhum alfabeto/escrita determinado/Não há título chave
008-33-SE	a	Romano básico
008-33-SE	b	Romano estendido
008-33-SE	c	Cirílico
008-33-SE	d	Japonês
008-33-SE	e	Chinês
008-33-SE	f	Arábico
008-33-SE	g	Grego
008-33-SE	h	Hebreu
008-33-SE	i	Tailandês
008-33-SE	j	Devanagari
008-33-SE	k	Coreano
008-33-SE	l	Tamil
008-33-SE	u	Desconhecido
008-33-SE	z	Outro
008-33-VM	a	Arte (original)
008-33-VM	b	Kit
008-33-VM	c	Arte (reprodução)
008-33-VM	d	Diorama
008-33-VM	f	Tira de filme
008-33-VM	g	Jogo
008-33-VM	i	Quadro
008-33-VM	k	Graphic
008-33-VM	l	Desenho técnico
008-33-VM	m	Filme
008-33-VM	n	Mapa
008-33-VM	o	Flash card (Cartão relâmpago)
008-33-VM	p	Slide de microscopia
008-33-VM	q	Modelo
008-33-VM	r	Reália
008-33-VM	s	Slide
008-33-VM	t	Transparência
008-33-VM	v	Gravação em vídeo
008-33-VM	w	Brinquedo
008-33-VM	z	Outro
008-33-VM		
008-34-BK	#	Não contém dados biográficos
008-34-BK	a	Autobiografia
008-34-BK	b	Biografia individual
008-34-BK	c	Biografia coletiva
008-34-BK	d	Contém informação biográfica
008-34-BK		
008-34-SE	0	Entrada sucessiva
008-34-SE	1	Entrada mais recentes
008-34-VM	a	Animação
008-34-VM	c	Animação e ação com atores
008-34-VM	l	Ação com atores
008-34-VM	n	Não aplicável
008-34-VM	u	Desconhecido
008-34-VM	z	Outro
008-34-VM		
008-38-BK	#	Não modificado
008-38-BK	d	Omissões substituídas por traços na transliteração
008-38-BK	o	Completamente romanizado/imprimir ficha romanizada
008-38-BK	r	Completamente romanizado/imprimir ficha na escrita
008-38-BK	s	Abreviado
008-38-BK	x	Faltam caracteres
008-38-BK		
008-38-CF	#	Não modificado
008-38-CF	d	Omitida informação de transliteração, substituída por traço
008-38-CF	o	Completamente romanizado / imprimir ficha romanizada
008-38-CF	r	Completamente romanizado/ imprimir ficha na escrita
008-38-CF	s	Abreviado
008-38-CF	x	Faltam caracteres
008-38-CF		
008-38-MP	#	Não modificado
008-38-MP	d	Omissões substituídas por traços na transliteração
008-38-MP	o	Completamente romanizado / imprimir ficha romanizada
008-38-MP	r	Completamente romanizado / imprimir ficha na escrita
008-38-MP	s	Abreviado
008-38-MP	x	Faltam caracteres
008-38-MP		
008-38-MU	#	Não modificado
008-38-MU	d	Omissões substituídas por traços na transliteração
008-38-MU	o	Completamente romanizado / imprimir ficha romanizada
008-38-MU	r	Completamente romanizado / imprimir ficha na escrita
008-38-MU	s	Abreviado
008-38-MU	x	Faltam caracteres
008-38-MU		
008-38-MX	#	Não modificado
008-38-MX	d	Omissões substituídas  por traços na transliteração
008-38-MX	o	Completamente romanizado / imprimir ficha romanizada
008-38-MX	r	Completamente romanizado / imprimir ficha na escrita
008-38-MX	s	Abreviado
008-38-MX	x	Faltam caracteres
008-38-MX		
008-38-SE	#	Não modificado
008-38-SE	d	Omissões substituídas por traços na transliteração
008-38-SE	o	Completamente romanizado/imprimir ficha romanizada
008-38-SE	r	Completamente romanizado/imprimir ficha na escrita
008-38-SE	s	Abreviado
008-38-SE	x	Faltam caracteres
008-38-VM	#	Não modificado
008-38-VM	d	Omissões substituídas por traços na transliteração
008-38-VM	o	Completamente romanizado / imprimir ficha romanizada
008-38-VM	r	Completamente romanizado / imprimir ficha na escrita
008-38-VM	s	Abreviado
008-38-VM	x	Faltam caracteres
008-38-VM		
008-39-BK	#	Library of Congress
008-39-BK	a	National Agricultural Library
008-39-BK	b	National Library of Medicine
008-39-BK	c	Programa de catalogação cooperativa da Library of Congress
008-39-BK	d	Outra
008-39-BK	n	Report to New Serial Titles
008-39-BK	u	Desconhecido
008-39-BK		
008-39-CF	#	Library of Congress
008-39-CF	a	National Agricultural Library
008-39-CF	b	National Library of Medicine
008-39-CF	c	Programa de catalogação cooperativa da Library of Congress
008-39-CF	d	Outra
008-39-CF	n	Relatório para novos títulos seriados
008-39-CF	u	Desconhecido
008-39-CF		
008-39-MP	#	Library of congress
008-39-MP	a	National agricultural library
008-39-MP	b	National library of medicine
008-39-MP	c	Programa de catalogação cooperativa da library of congress
008-39-MP	d	Outra fonte
008-39-MP	n	Relatório para novos títulos seriados
008-39-MP	u	Desconhecido
008-39-MP		
008-39-MU	#	Library of Congress
008-39-MU	a	National agricultural library
008-39-MU	b	National library of medicine
008-39-MU	c	Programa de catalogação cooperativa da library of congress
008-39-MU	d	Outra
008-39-MU	n	Relatório para novos títulos seriados
008-39-MU	u	Desconhecido
008-39-MU		
008-39-MX	#	Library of congress
008-39-MX	a	National agricultural library
008-39-MX	b	National library of medicine
008-39-MX	c	Progr. De catal. Coop da library of congress
008-39-MX	d	Outra
008-39-MX	n	Relatório para novos títulos seriados
008-39-MX	u	desconhecido
008-39-MX		
008-39-SE	#	Library of Congress
008-39-SE	a	National Agricultural Library
008-39-SE	b	National Library of Medicine
008-39-SE	c	Programa de catalogação cooperativa da Library of Congress
008-39-SE	d	Outra
008-39-SE	n	Report to New Serial Titles
008-39-SE	u	Desconhecido
008-39-VM	#	Library of congress
008-39-VM	a	National agricultural library
008-39-VM	b	National library of medicine
008-39-VM	c	Programa de catalogação cooperativa da library of congress
008-39-VM	d	Outra
008-39-VM	n	Relatório para novos títulos seriados
008-39-VM	u	Desconhecido
008-39-VM		
022-I1	#	Nível de interesse internacional não especificado
022-I1	0	Per. de interesse internacional; registro completo, registrado na rede ISSN Network
022-I1	1	Per. sem interesse internacional; registro abreviado, registrado na rede ISSN Network
041-I1	#	indefinido (obsoleto)
041-I1	0	item não é ou não inclui tradução
041-I1	1	item é ou inclui tradução
041-I1		
100-I1	0	Prenome simples e/ou composto
100-I1	1	Sobrenome simples e/ou composto
100-I1	2	Múltiplos sobrenomes (obsoleto)
100-I1	3	Nome de família
100-I1		
110-I1	0	Nome invertido
110-I1	1	Nome da jurisdição
110-I1	2	Nome em ordem direta
111-I1	0	Nome invertido
111-I1	1	Nome da jurisdição
111-I1	2	Nome em ordem direta
210-I1	0	Não há entrada secundária de título
210-I1	1	Entrada secundária de título
210-I2	#	Título chave abreviado
210-I2	0	Outro título abreviado
245-I1	0	Não gerar entrada secundária de título
245-I1	1	Gerar entrada secundária de título
245-I2	0	Zero
245-I2	1	Um
245-I2	2	Dois
245-I2	3	Três
245-I2	4	Quatro
245-I2	5	Cinco
245-I2	6	Seis
245-I2	7	Sete
245-I2	8	Oito
245-I2	9	Nove
362-I1	0	Estilo formatado
362-I1	1	Nota não formatada
440-I2	0	Zero
440-I2	1	Um
440-I2	2	Dois
440-I2	3	Três
440-I2	4	Quatro
440-I2	5	Cinco
440-I2	6	Seis
440-I2	7	Sete
440-I2	8	Oito
440-I2	9	Nove
505-I1	0	Conteúdo
505-I1	1	Conteúdo incompleto
505-I1	2	Conteúdo
505-I1	8	Não gerar constante para visualização
505-I2	#	Básico
505-I2	0	Aumentado
555-I1	#	Não há informação Índice, pode ser gerado
555-I1	0	Índice Remissivo
555-I1	8	Não gerar constante para visualização
650-I1	#	Informação não disponível
650-I1	0	Nível não especificado
650-I1	1	Primário
650-I1	2	Secundário
650-I2	0	Cabeçalhos de assuntos da Library of Congress/lista de autoridades da LC
650-I2	1	Cabeçalhos de assuntos da LC para literatura infantil
650-I2	2	Cabeçalhos de assuntos de Medicina/lista de autoridades da NLM
650-I2	3	Lista de autoridade-assunto-Nat. Agricultural Library
650-I2	4	Fonte não especificada
650-I2	5	Cabeçalhos de as. Canadenses/lista de aut. da NLC
650-I2	6	Repertorie des vedettes-matiere/lista de aut. da NLC
650-I2	7	Fonte especificada no subcampo $2
653-I1	#	Informação não fornecida
653-I1	0	Nível não especificado
653-I1	1	Primário
653-I1	2	Secundário
700-I1	0	Prenome simples e/ou composto
700-I1	1	Sobrenome simples e/ou composto
700-I1	2	Múltiplos sobrenomes (obsoleto)
700-I1	3	Nome de família
700-I2	#	Não há informação
700-I2	0	Entrada alternativa (BK CF MP MU SE MX) (Obsoleto)
700-I2	1	Entrada secundária (BK CF MP MU SE MX) (Obsoleto)
700-I2	1	Imprimir ficha (VM) (Obsoleto)
700-I2	2	Entrada Analítica
700-I2	3	Não imprimir ficha (VM) (Obsoleto)
710-I1	0	Nome Invertido
710-I1	1	Nome da jursidição
710-I1	2	Nome em ordem direta
710-I2	#	Não há informação
710-I2	0	Entrada alternativa (BK CF MP MU SE MX) (Obsoleto)
710-I2	1	Entrada secundária (BK CF MP MU SE MX) (Obsoleto)
710-I2	1	Imprimir ficha (VM) (Obsoleto)
710-I2	2	Entrada Analítica
710-I2	3	Não imprimir ficha (VM) (Obsoleto)
711-I1	0	Nome invertido
711-I1	1	Nome da jurisdição
711-I1	2	Nome em ordem direta
711-I2	#	Não há informação
711-I2	0	Entrada alternativa (BK CF MP MU SE MX) (Obsoleto)
711-I2	1	Entrada secundária (BK CF MP MU SE MX) (Obsoleto)
711-I2	1	Imprimir ficha (VM) (Obsoleto)
711-I2	2	Entrada Analítica
711-I2	3	Não imprimir ficha (VM) (Obsoleto)
720-I1	#	Não especificado
720-I1	1	Pessoal
720-I1	2	Outro
780-I1	0	Exibir nota
780-I1	1	Não exibir nota
780-I2	0	Continua
780-I2	1	Continua em parte
780-I2	2	Substitui
780-I2	3	Substitui em parte
780-I2	4	Formado pela união de... e...
780-I2	5	Absorvido
780-I2	6	Absorvido em parte
780-I2	7	Separado de
785-I1	0	Exibir nota
785-I1	1	Não exibir nota
785-I2	0	Continuado por
785-I2	1	Continuado em parte por
785-I2	2	Substituído por
785-I2	3	Substituído em parte por
785-I2	4	Absorvido por
785-I2	5	Absorvido em parte por
785-I2	6	Dividido em... e...
785-I2	7	Fundido com... para forma...
785-I2	8	Voltou para...
949.c	C	Compra
949.c	D	Doação
949.c	P	Permuta
CATEGORY	BK	Livro
CATEGORY	BA	Analítica de livro
CATEGORY	SE	Periódico
CATEGORY	SA	Analítica de periódico
CATEGORY	AM	Controle de arquivos e manuscritos
CATEGORY	CF	Arquivos de computador
CATEGORY	MP	Mapas
CATEGORY	MU	Música
CATEGORY	VM	Material visual
CATEGORY	MX	Materiais diversos
LEVEL	#	Completo
LEVEL	1	Completo (material não examinado)
LEVEL	2	Incompleto, material não examinado
LEVEL	3	Abreviado
LEVEL	4	Nível padrão
LEVEL	5	Parcial (preliminar)
LEVEL	7	Mínimo
LEVEL	8	Pré-publicação
LEVEL	u	Desconhecido
LEVEL	z	Não aplicável
008-31-MP	0	Não possui índice
008-31-MP	1	Possui índice
008-06-MU	b	Não há datas; envolve data A.C.
008-06-MU	c	Data atual e de copyright (OBSOLETO)
008-06-MU	d	Data detalhada (OBSOLETO)
008-06-MU	i	Datas limite de uma coleção
008-06-MU	m	Múltiplas datas
008-06-MU	n	Data desconhecida
008-06-MU	p	Data de distribuição / lançamento / publicação e produção / ou sessão de gravação quando diferente ( CF, MU, VM)
008-06-MU	q	Data incompleta
008-06-MU	r	Data de reimpressão / reedição e data original
008-06-MU	s	Data única / data provável
008-15	aa	Albania
008-15	abc	Alberta
008-15	-ac	Ashmore and Cartier Islands
008-15	ae	Algeria
008-15	af	Afghanistan
008-15	ag	Argentina
008-15	ai	Armenia (Republic)
008-15	-ai	Anguilla
008-15	-air	Armenian S.S.R.
008-15	aj	Azerbaijan
008-15	-ajr	Azerbaijan S.S.R.
008-15	aku	Alaska
008-15	alu	Alabama
008-15	am	Anguilla
008-15	an	Andorra
008-15	ao	Angola
008-15	aq	Antigua and Barbuda
008-15	aru	Arkansas
008-15	as	American Samoa
008-15	at	Australia
008-15	au	Austria
008-15	aw	Aruba
008-15	ay	Antarctica
008-15	azu	Arizona
008-15	ba	Bahrain
008-15	bb	Barbados
008-15	bcc	British Columbia
008-15	bd	Burundi
008-15	be	Belgium
008-15	bf	Bahamas
008-15	bg	Bangladesh
008-15	bh	Belize
008-15	bi	British Indian Ocean Territory
008-15	bl	Brazil
008-15	bm	Bermuda Islands
008-15	bn	Bosnia and Hercegovina
008-15	bo	Bolivia
008-15	bp	Solomon Islands
008-15	br	Burma
008-15	bs	Botswana
008-15	bt	Bhutan
008-15	bu	Bulgaria
008-15	bv	Bouvet Island
008-15	bw	Belarus
008-15	-bwr	Byelorussian S.S.R.
008-15	bx	Brunei
008-15	cau	California
008-15	cb	Cambodia
008-15	cc	China
008-15	cd	Chad
008-15	ce	Sri Lanka
008-15	cf	Congo (Brazzaville)
008-15	cg	Congo (Democratic Republic)
008-15	ch	China (Republic : 1949- )
008-15	ci	Croatia
008-15	cj	Cayman Islands
008-15	ck	Colombia
008-15	cl	Chile
008-15	cm	Cameroon
008-15	-cn	Canada
008-15	cou	Colorado
008-15	-cp	Canton and Enderbury Islands
008-15	cq	Comoros
008-15	cr	Costa Rica
008-15	-cs	Czechoslovakia
008-15	ctu	Connecticut
008-15	cu	Cuba
008-15	cv	Cape Verde
008-15	cw	Cook Islands
008-15	cx	Central African Republic
008-15	cy	Cyprus
008-15	-cz	Canal Zone
008-15	d	 (Indian Ocean)
008-15	dcu	District of Columbia
008-15	deu	Delaware
008-15	dk	Denmark
008-15	dm	Benin
008-15	dq	Dominica
008-15	dr	Dominican Republic
008-15	ea	Eritrea
008-15	ec	Ecuador
008-15	eg	Equatorial Guinea
008-15	enk	England
008-15	er	Estonia
008-15	-err	Estonia
008-15	es	El Salvador
008-15	et	Ethiopia
008-15	fa	Faroe Islands
008-15	fg	French Guiana
008-15	fi	Finland
008-15	fj	Fiji
008-15	fk	Falkland Islands
008-15	flu	Florida
008-15	fm	Micronesia (Federated States)
008-15	fp	French Polynesia
008-15	fr	France
008-15	fs	Terres australes et antarctiques franaise
008-15	ft	Djibouti
008-15	gau	Georgia
008-15	gb	Kiribati
008-15	gd	Grenada
008-15	-ge	Germany (East)
008-15	gh	Ghana
008-15	gi	Gibraltar
008-15	gl	Greenland
008-15	gm	Gambia
008-15	-gn	Gilbert and Ellice Islands
008-15	go	Gabon
008-15	gp	Guadeloupe
008-15	gr	Greece
008-15	gs	Georgia (Republic)
008-15	-gsr	Georgian S.S.R.
008-15	gt	Guatemala
008-15	gu	Guam
008-15	gv	Guinea
008-15	gw	Germany
008-15	gy	Guyana
008-15	gz	Gaza Strip
008-15	hiu	Hawaii
008-15	-hk	Hong Kong
008-15	hm	Heard and McDonald Islands
008-15	ho	Honduras
008-15	ht	Haiti
008-15	hu	Hungary
008-15	iau	Iowa
008-15	ic	Iceland
008-15	idu	Idaho
008-15	ie	Ireland
008-15	ii	India
008-15	ilu	Illinois
008-15	inu	Indiana
008-15	io	Indonesia
008-15	iq	Iraq
008-15	ir	Iran
008-15	is	Israel
008-15	it	Italy
008-15	-iu	Israel-Syria Demilitarized Zones
008-15	iv	Côte dIvoire
008-15	-iw	Israel-Jordan Demilitarized Zones
008-15	iy	Iraq-Saudi Arabia Neutral Zone
008-15	ja	Japan
008-15	ji	Johnston Atoll
008-15	jm	Jamaica
008-15	-jn	Jan Mayen
008-15	jo	Jordan
008-15	ke	Kenya
008-15	kg	Kyrgyzstan
008-15	-kgr	Kirghiz S.S.R.
008-15	kn	Korea (North)
008-15	ko	Korea (South)
008-15	ksu	Kansas
008-15	ku	Kuwait
008-15	kyu	Kentucky
008-15	kz	Kazakhstan
008-15	-kzr	Kazakh S.S.R.
008-15	lau	Louisiana
008-15	lb	Liberia
008-15	le	Lebanon
008-15	lh	Liechtenstein
008-15	li	Lithuania
008-15	-lir	Lithuania
008-15	-ln	Central and Southern Line Islands
008-15	lo	Lesotho
008-15	ls	Laos
008-15	lu	Luxembourg
008-15	lv	Latvia
008-15	-lvr	Latvia
008-15	ly	Libya
008-15	mau	Massachusetts
008-15	mbc	Manitoba
008-15	mc	Monaco
008-15	mdu	Maryland
008-15	meu	Maine
008-15	mf	Mauritius
008-15	mg	Madagascar
008-15	-mh	Macao
008-15	miu	Michigan
008-15	mj	Montserrat
008-15	mk	Oman
008-15	ml	Mali
008-15	mm	Malta
008-15	mnu	Minnesota
008-15	mou	Missouri
008-15	mp	Mongolia
008-15	mq	Martinique
008-15	mr	Morocco
008-15	msu	Mississippi
008-15	mtu	Montana
008-15	mu	Mauritania
008-15	mv	Moldova
008-15	-mvr	Moldavian S.S.R.
008-15	mw	Malawi
008-15	mx	Mexico
008-15	my	Malaysia
008-15	mz	Mozambique
008-15	na	Netherlands Antilles
008-15	nbu	Nebraska
008-15	ncu	North Carolina
008-15	ndu	North Dakota
008-15	ne	Netherlands
008-15	nfc	Newfoundland
008-15	ng	Niger
008-15	nhu	New Hampshire
008-15	nik	Northern Ireland
008-15	nju	New Jersey
008-15	nkc	New Brunswick
008-15	nl	New Caledonia
008-15	-nm	Northern Mariana Islands
008-15	nmu	New Mexico
008-15	nn	Vanuatu
008-15	no	Norway
008-15	np	Nepal
008-15	nq	Nicaragua
008-15	nr	Nigeria
008-15	nsc	Nova Scotia
008-15	ntc	Northwest Territories
008-15	nu	Nauru
008-15	nuc	Nunavut
008-15	nvu	Nevada
008-15	nw	Northern Mariana Islands
008-15	nx	Norfolk Island
008-15	nyu	New York (State)
008-15	nz	New Zealand
008-15	ohu	Ohio
008-15	oku	Oklahoma
008-15	onc	Ontario
008-15	oru	Oregon
008-15	ot	Mayotte
008-15	pau	Pennsylvania
008-15	pc	Pitcairn Island
008-15	pe	Peru
008-15	pf	Paracel Islands
008-15	pg	Guinea-Bissau
008-15	ph	Philippines
008-15	pic	Prince Edward Island
008-15	pk	Pakistan
008-15	pl	Poland
008-15	pn	Panama
008-15	po	Portugal
008-15	pp	Papua New Guinea
008-15	pr	Puerto Rico
008-15	-pt	Portuguese Timor
008-15	pw	Palau
008-15	py	Paraguay
008-15	qa	Qatar
008-15	quc	Qubec (Province)
008-15	re	Runion
008-15	rh	Zimbabwe
008-15	riu	Rhode Island
008-15	rm	Romania
008-15	ru	Russia (Federation)
008-15	-rur	Russian S.F.S.R.
008-15	rw	Rwanda
008-15	-ry	Ryukyu Islands, Southern
008-15	sa	South Africa
008-15	-sb	Svalbard
008-15	scu	South Carolina
008-15	sdu	South Dakota
008-15	se	Seychelles
008-15	sf	Sao Tome and Principe
008-15	sg	Senegal
008-15	sh	Spanish North Africa
008-15	si	Singapore
008-15	sj	Sudan
008-15	-sk	Sikkim
008-15	sl	Sierra Leone
008-15	sm	San Marino
008-15	snc	Saskatchewan
008-15	so	Somalia
008-15	sp	Spain
008-15	sq	Swaziland
008-15	sr	Surinam
008-15	ss	Western Sahara
008-15	stk	Scotland
008-15	su	Saudi Arabia
008-15	-sv	Swan Islands
008-15	sw	Sweden
008-15	sx	Namibia
008-15	sy	Syria
008-15	sz	Switzerland
008-15	ta	Tajikistan
008-15	-tar	Tajik S.S.R.
008-15	tc	Turks and Caicos Islands
008-15	tg	Togo
008-15	th	Thailand
008-15	ti	Tunisia
008-15	tk	Turkmenistan
008-15	-tkr	Turkmen S.S.R.
008-15	tl	Tokelau
008-15	tnu	Tennessee
008-15	to	Tonga
008-15	tr	Trinidad and Tobago
008-15	ts	United Arab Emirates
008-15	-tt	Trust Territory of the Pacific Islands
008-15	tu	Turkey
008-15	tv	Tuvalu
008-15	txu	Texas
008-15	tz	Tanzania
008-15	ua	Egypt
008-15	uc	United States Misc. Caribbean Islands
008-15	ug	Uganda
008-15	-ui	United Kingdom Misc. Islands
008-15	uik	United Kingdom Misc. Islands
008-15	-uk	United Kingdom
008-15	un	Ukraine
008-15	-unr	Ukraine
008-15	up	United States Misc. Pacific Islands
008-15	-ur	Soviet Union
008-15	-us	United States
008-15	utu	Utah
008-15	uv	Burkina Faso
008-15	uy	Uruguay
008-15	uz	Uzbekistan
008-15	-uzr	Uzbek S.S.R.
008-15	vau	Virginia
008-15	vb	British Virgin Islands
008-15	vc	Vatican City
008-15	ve	Venezuela
008-15	vi	Virgin Islands of the United States
008-15	vm	Vietnam
008-15	-vn	Vietnam, North
008-15	vp	Various places
008-15	-vs	Vietnam, South
008-15	vtu	Vermont
008-15	wau	Washington (State)
008-15	-wb	West Berlin
008-15	wf	Wallis and Futuna
008-15	wiu	Wisconsin
008-15	wj	West Bank of the Jordan River
008-15	wk	Wake Island
008-15	wlk	Wales
008-15	ws	Samoa
008-15	wvu	West Virginia
008-15	wyu	Wyoming
008-15	xa	Christmas Islan
008-15	xb	Cocos (Keeling) Islands
008-15	xc	Maldives
008-15	xd	Saint Kitts-Nevis
008-15	xe	Marshall Islands
008-15	xf	Midway Islands
008-15	xh	Niue
008-15	-xi	Saint Kitts-Nevis-Anguilla
008-15	xj	Saint Helena
008-15	xk	Saint Lucia
008-15	xl	Saint Pierre and Miquelon
008-15	xm	Saint Vincent and the Grenadines
008-15	xn	Macedonia
008-15	xo	Slovakia
008-15	xp	Spratly Island
008-15	xr	Czech Republic
008-15	xs	South Georgia and the South Sandwich Islands
008-15	xv	Slovenia
008-15	xx	No place, unknown, or undetermined
008-15	xxc	Canada
008-15	xxk	United Kingdom
008-15	-xxr	Soviet Union
008-15	xxu	United States
008-15	ye	Yemen
008-15	ykc	Yukon Territory
008-15	-ys	Yemen (Peoples Democratic Republic)
008-15	yu	Yugoslavia
008-15	za	Zambia
008-35	aar	Afar
008-35	abk	Abkhaz
008-35	ace	Achinese
008-35	ach	Acoli
008-35	ada	Adangme
008-35	afa	Afroasiatic (Other)
008-35	afh	Afrihili (Artificial language)
008-35	afr	Afrikaans
008-35	-ajm	Aljamía
008-35	aka	Akan
008-35	akk	Akkadian
008-35	alb	Albanian
008-35	ale	Aleut
008-35	alg	Algonquian (Other)
008-35	amh	Amharic
008-35	ang	English, Old (ca. 450-1100)
008-35	apa	Apache languages
008-35	ara	Arabic
008-35	arc	Aramaic
008-35	arm	Armenian
008-35	arn	Mapuche
008-35	arp	Arapaho
008-35	art	Artificial (Other)
008-35	arw	Arawak
008-35	asm	Assamese
008-35	ath	Athapascan (Other)
008-35	aus	Australian languages
008-35	ava	Avaric
008-35	ave	Avestan
008-35	awa	Awadhi
008-35	aym	Aymara
008-35	aze	Azerbaijani
008-35	bad	Banda
008-35	bai	Bamileke languages
008-35	bak	Bashkir
008-35	bal	Baluchi
008-35	bam	Bambara
008-35	ban	Balinese
008-35	baq	Basque
008-35	bas	Basa
008-35	bat	Baltic (Other)
008-35	bej	Beja
008-35	bel	Belarusian
008-35	bem	Bemba
008-35	ben	Bengali
008-35	ber	Berber (Other)
008-35	bho	Bhojpuri
008-35	bih	Bihari
008-35	bik	Bikol
008-35	bin	Bini
008-35	bis	Bislama
008-35	bla	Siksika
008-35	bnt	Bantu (Other)
008-35	bos	Bosnian
008-35	bra	Braj
008-35	bre	Breton
008-35	btk	Batak
008-35	bua	Buriat
008-35	bug	Bugis
008-35	bul	Bulgarian
008-35	bur	Burmese
008-35	cad	Caddo
008-35	cai	Central American Indian (Other)
008-35	-cam	Khmer
008-35	car	Carib
008-35	cat	Catalan
008-35	cau	Caucasian (Other)
008-35	ceb	Cebuano
008-35	cel	Celtic (Other)
008-35	cha	Chamorro
008-35	chb	Chibcha
008-35	che	Chechen
008-35	chg	Chagatai
008-35	chi	Chinese
008-35	chk	Truk
008-35	chm	Mari
008-35	chn	Chinook jargon
008-35	cho	Choctaw
008-35	chp	Chipewyan
008-35	chr	Cherokee
008-35	chu	Church Slavic
008-35	chv	Chuvash
008-35	chy	Cheyenne
008-35	cmc	Chamic languages
008-35	cop	Coptic
008-35	cor	Cornish
008-35	cos	Corsican
008-35	cpe	Creoles and Pidgins, English-based (Other)
008-35	cpf	Creoles and Pidgins, French-based (Other)
008-35	cpp	Creoles and Pidgins, Portuguese-based (Other)
008-35	cre	Cree
008-35	crp	Creoles and Pidgins (Other)
008-35	cus	Cushitic (Other)
008-35	cze	Czech
008-35	dak	Dakota
008-35	dan	Danish
008-35	day	Dayak
008-35	del	Delaware
008-35	den	Slave
008-35	dgr	Dogrib
008-35	din	Dinka
008-35	div	Divehi
008-35	doi	Dogri
008-35	dra	Dravidian (Other)
008-35	dua	Duala
008-35	dum	Dutch, Middle (ca. 1050-1350)
008-35	dut	Dutch
008-35	dyu	Dyula
008-35	dzo	Dzongkha
008-35	efi	Efik
008-35	egy	Egyptian
008-35	eka	Ekajuk
008-35	elx	Elamite
008-35	eng	English
008-35	enm	English, Middle (1100-1500)
008-35	epo	Esperanto
008-35	-esk	Eskimo languages
008-35	-esp	Esperanto
008-35	est	Estonian
008-35	-eth	Ethiopic
008-35	ewe	Ewe
008-35	ewo	Ewondo
008-35	fan	Fang
008-35	fao	Faroese
008-35	-far	Faroese
008-35	fat	Fanti
008-35	fij	Fijian
008-35	fin	Finnish
008-35	fiu	Finno-Ugrian (Other)
008-35	fon	Fon
008-35	fre	French
008-35	-fri	Frisian
008-35	frm	French, Middle (ca. 1400-1600)
008-35	fro	French, Old (ca. 842-1400)
008-35	fry	Frisian
008-35	ful	Fula
008-35	fur	Friulian
008-35	gaa	Gã
008-35	-gae	Scottish Gaelic
008-35	-gag	Galician
008-35	-gal	Oromo
008-35	gay	Gayo
008-35	gba	Gbaya
008-35	gem	Germanic (Other)
008-35	geo	Georgian
008-35	ger	German
008-35	gez	Ethiopic
008-35	gil	Gilbertese
008-35	gla	Scottish Gaelic
008-35	gle	Irish
008-35	glg	Galician
008-35	glv	Manx
008-35	gmh	German, Middle High (ca. 1050-1500)
008-35	goh	German, Old High (ca. 750-1050)
008-35	gon	Gondi
008-35	gor	Gorontalo
008-35	got	Gothic
008-35	grb	Grebo
008-35	grc	Greek, Ancient (to 1453)
008-35	gre	Greek, Modern (1453- )
008-35	grn	Guarani
008-35	-gua	Guarani
008-35	guj	Gujarati
008-35	gwi	Gwichin
008-35	hai	Haida
008-35	hau	Hausa
008-35	haw	Hawaiian
008-35	heb	Hebrew
008-35	her	Herero
008-35	hil	Hiligaynon
008-35	him	Himachali
008-35	hin	Hindi
008-35	hit	Hittite
008-35	hmn	Hmong
008-35	hmo	Hiri Motu
008-35	hun	Hungarian
008-35	hup	Hupa
008-35	iba	Iban
008-35	ibo	Igbo
008-35	ice	Icelandic
008-35	ijo	Ijo
008-35	iku	Inuktitut
008-35	ile	Interlingue
008-35	ilo	Iloko
008-35	ina	Interlingua (International Auxiliary Language Association)
008-35	inc	Indic (Other)
008-35	ind	Indonesian
008-35	ine	Indo-European (Other)
008-35	-int	Interlingua (International Auxiliary Language Association)
008-35	ipk	Inupiaq
008-35	ira	Iranian (Other)
008-35	-iri	Irish
008-35	iro	Iroquoian (Other)
008-35	ita	Italian
008-35	jav	Javanese
008-35	jpn	Japanese
008-35	jpr	Judeo-Persian
008-35	jrb	Judeo-Arabic
008-35	kaa	Kara-Kalpak
008-35	kab	Kabyle
008-35	kac	Kachin
008-35	kal	Kalâtdlisut
008-35	kam	Kamba
008-35	kan	Kannada
008-35	kar	Karen
008-35	kas	Kashmiri
008-35	kau	Kanuri
008-35	kaw	Kawi
008-35	kaz	Kazakh
008-35	kha	Khasi
008-35	khi	Khoisan (Other)
008-35	khm	Khmer
008-35	kho	Khotanese
008-35	kik	Kikuyu
008-35	kin	Kinyarwanda
008-35	kir	Kyrgyz
008-35	kmb	Kimbundu
008-35	kok	Konkani
008-35	kom	Komi
008-35	kon	Kongo
008-35	kor	Korean
008-35	kos	Kusaie
008-35	kpe	Kpelle
008-35	kro	Kru
008-35	kru	Kurukh
008-35	kua	Kuanyama
008-35	kum	Kumyk
008-35	kur	Kurdish
008-35	-kus	Kusaie
008-35	kut	Kutenai
008-35	lad	Ladino
008-35	lah	Lahnda
008-35	lam	Lamba
008-35	-lan	Occitan (post-1500)
008-35	lao	Lao
008-35	-lap	Sami
008-35	lat	Latin
008-35	lav	Latvian
008-35	lez	Lezgian
008-35	lin	Lingala
008-35	lit	Lithuanian
008-35	lol	Mongo-Nkundu
008-35	loz	Lozi
008-35	ltz	Letzeburgesch
008-35	lua	Luba-Lulua
008-35	lub	Luba-Katanga
008-35	lug	Ganda
008-35	lui	Luiseño
008-35	lun	Lunda
008-35	luo	Luo (Kenya and Tanzania)
008-35	lus	Lushai
008-35	mac	Macedonian
008-35	mad	Madurese
008-35	mag	Magahi
008-35	mah	Marshall
008-35	mai	Maithili
008-35	mak	Makasar
008-35	mal	Malayalam
008-35	man	Mandingo
008-35	mao	Maori
008-35	map	Austronesian (Other)
008-35	mar	Marathi
008-35	mas	Masai
008-35	-max	Manx
008-35	may	Malay
008-35	mdr	Mandar
008-35	men	Mende
008-35	mga	Irish, Middle (ca. 1100-1550)
008-35	mic	Micmac
008-35	min	Minangkabau
008-35	mis	Miscellaneous languages
008-35	mkh	Mon-Khmer (Other)
008-35	-mla	Malagasy
008-35	mlg	Malagasy
008-35	mlt	Maltese
008-35	mnc	Manchu
008-35	mni	Manipuri
008-35	mno	Manobo languages
008-35	moh	Mohawk
008-35	mol	Moldavian
008-35	mon	Mongolian
008-35	mos	Mooré
008-35	mul	Multiple languages
008-35	mun	Munda (Other)
008-35	mus	Creek
008-35	mwr	Marwari
008-35	myn	Mayan languages
008-35	nah	Nahuatl
008-35	nai	North American Indian (Other)
008-35	nau	Nauru
008-35	nav	Navajo
008-35	nbl	Ndebele (South Africa)
008-35	nde	Ndebele (Zimbabwe)
008-35	ndo	Ndonga
008-35	nep	Nepali
008-35	new	Newari
008-35	nia	Nias
008-35	nic	Niger-Kordofanian (Other)
008-35	niu	Niuean
008-35	non	Old Norse
008-35	nor	Norwegian
008-35	nso	Northern Sotho
008-35	nub	Nubian languages
008-35	nya	Nyanja
008-35	nym	Nyamwezi
008-35	nyn	Nyankole
008-35	nyo	Nyoro
008-35	nzi	Nzima
008-35	oci	Occitan (post-1500)
008-35	oji	Ojibwa
008-35	ori	Oriya
008-35	orm	Oromo
008-35	osa	Osage
008-35	oss	Ossetic
008-35	ota	Turkish, Ottoman
008-35	oto	Otomian languages
008-35	paa	Papuan (Other)
008-35	pag	Pangasinan
008-35	pal	Pahlavi
008-35	pam	Pampanga
008-35	pan	Panjabi
008-35	pap	Papiamento
008-35	pau	Palauan
008-35	peo	Old Persian (ca. 600-400 B.C.)
008-35	per	Persian
008-35	phi	Philippine (Other)
008-35	phn	Phoenician
008-35	pli	Pali
008-35	pol	Polish
008-35	pon	Ponape
008-35	por	Portuguese
008-35	pra	Prakrit languages
008-35	pro	Provençal (to 1500)
008-35	pus	Pushto
008-35	que	Quechua
008-35	raj	Rajasthani
008-35	rap	Rapanui
008-35	rar	Rarotongan
008-35	roa	Romance (Other)
008-35	roh	Raeto-Romance
008-35	rom	Romany
008-35	rum	Romanian
008-35	run	Rundi
008-35	rus	Russian
008-35	sad	Sandawe
008-35	sag	Sango
008-35	sah	Yakut
008-35	sai	South American Indian (Other)
008-35	sal	Salishan languages
008-35	sam	Samaritan Aramaic
008-35	san	Sanskrit
008-35	-sao	Samoan
008-35	sas	Sasak
008-35	sat	Santali
008-35	scc	Serbian
008-35	sco	Scots
008-35	scr	Croatian
008-35	sel	Selkup
008-35	sem	Semitic (Other)
008-35	sga	Irish, Old (to 1100)
008-35	sgn	Sign languages
008-35	shn	Shan
008-35	-sho	Shona
008-35	sid	Sidamo
008-35	sin	Sinhalese
008-35	sio	Siouan (Other)
008-35	sit	Sino-Tibetan (Other)
008-35	sla	Slavic (Other)
008-35	slo	Slovak
008-35	slv	Slovenian
008-35	sme	Northern Sami
008-35	smi	Sami
008-35	smo	Samoan
008-35	sna	Shona
008-35	snd	Sindhi
008-35	-snh	Sinhalese
008-35	snk	Soninke
008-35	sog	Sogdian
008-35	som	Somali
008-35	son	Songhai
008-35	sot	Sotho
008-35	spa	Spanish
008-35	srd	Sardinian
008-35	srr	Serer
008-35	ssa	Nilo-Saharan (Other)
008-35	-sso	Sotho
008-35	ssw	Swazi
008-35	suk	Sukuma
008-35	sun	Sundanese
008-35	sus	Susu
008-35	sux	Sumerian
008-35	swa	Swahili
008-35	swe	Swedish
008-35	-swz	Swazi
008-35	syr	Syriac
008-35	-tag	Tagalog
008-35	tah	Tahitian
008-35	tai	Tai (Other)
008-35	-taj	Tajik
008-35	tam	Tamil
008-35	-tar	Tatar
008-35	tat	Tatar
008-35	tel	Telugu
008-35	tem	Temne
008-35	ter	Terena
008-35	tet	Tetum
008-35	tgk	Tajik
008-35	tgl	Tagalog
008-35	tha	Thai
008-35	tib	Tibetan
008-35	tig	Tigré
008-35	tir	Tigrinya
008-35	tiv	Tiv
008-35	tkl	Tokelauan
008-35	tli	Tlingit
008-35	tmh	Tamashek
008-35	tog	Tonga (Nyasa)
008-35	ton	Tongan
008-35	tpi	Tok Pisin
008-35	-tru	Truk
008-35	tsi	Tsimshian
008-35	tsn	Tswana
008-35	tso	Tsonga
008-35	-tsw	Tswana
008-35	tuk	Turkmen
008-35	tum	Tumbuka
008-35	tur	Turkish
008-35	tut	Altaic (Other)
008-35	tvl	Tuvaluan
008-35	twi	Twi
008-35	tyv	Tuvinian
008-35	uga	Ugaritic
008-35	uig	Uighur
008-35	ukr	Ukrainian
008-35	umb	Umbundu
008-35	und	Undetermined
008-35	urd	Urdu
008-35	uzb	Uzbek
008-35	vai	Vai
008-35	ven	Venda
008-35	vie	Vietnamese
008-35	vol	Volapük
008-35	vot	Votic
008-35	wak	Wakashan languages
008-35	wal	Walamo
008-35	war	Waray
008-35	was	Washo
008-35	wel	Welsh
008-35	wen	Sorbian languages
008-35	wol	Wolof
008-35	xho	Xhosa
008-35	yao	Yao
008-35	yap	Yapese
008-35	yid	Yiddish
008-35	yor	Yoruba
008-35	ypk	Yupik languages
008-35	zap	Zapotec
008-35	zen	Zenaga
008-35	zha	Zhuang
008-35	znd	Zande
008-35	zul	Zulu
008-35	zun	Zuni
949.5	n	Não
949.5	s	Sim
960.c	C	Compra
960.c	D	Doação
960.c	P	Permuta
901.b	CA	Ciências agrárias
901.b	CB	Ciências biológicas
901.b	CH	Ciências humanas
901.b	CS	Ciências da saúde
901.b	CET	Ciências exatas e da terra
901.b	CSA	Ciências sociais aplicadas
901.b	ENG	Engenharias
901.b	LLA	Linguística, letra e arte
\.


--
-- Data for Name: gtcmaterial; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcmaterial (controlnumber, fieldid, subfieldid, line, indicator1, indicator2, content, searchcontent, prefixid, suffixid, separatorid) FROM stdin;
\.


--
-- Data for Name: gtcmaterialcontrol; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcmaterialcontrol (controlnumber, controlnumberfather, entrancedate, lastchangedate, category, level, materialgenderid, materialtypeid, materialphysicaltypeid) FROM stdin;
\.


--
-- Data for Name: gtcmaterialevaluation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcmaterialevaluation (materialevaluationid, controlnumber, personid, date, comment, evaluation) FROM stdin;
\.


--
-- Data for Name: gtcmaterialgender; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcmaterialgender (materialgenderid, description) FROM stdin;
1	LIVRO
2	REFERÊNCIA
3	PERIÓDICO
4	DVD
5	CD
\.


--
-- Data for Name: gtcmaterialhistory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcmaterialhistory (materialhistoryid, controlnumber, revisionnumber, operator, data, chancestype, fieldid, subfieldid, previousline, previousindicator1, previousindicator2, previouscontent, currentline, currentindicator1, currentindicator2, currentcontent, previousprefixid, previoussuffixid, previousseparatorid, currentprefixid, currentsuffixid, currentseparatorid) FROM stdin;
\.


--
-- Data for Name: gtcmaterialphysicaltype; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcmaterialphysicaltype (materialphysicaltypeid, description, image, observation) FROM stdin;
1	Impresso	\N	
2	CD	\N	
3	DVD	\N	
5	Fita K7	\N	
6	Disquete	\N	
7	Calculadora	\N	
4	Fita VHS	\N	
8	Braille	\N	
9	Transparência	\N	
\.


--
-- Data for Name: gtcmaterialtype; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcmaterialtype (materialtypeid, description, isrestricted, level, observation) FROM stdin;
1	Livro	f	10	
2	Monografia	f	15	
5	Tese	f	20	
4	Dissertação	f	25	
3	Especialização	f	30	
23	Coleção de Periódico	f	35	
25	Artigo de periódico	f	40	
6	Referência	f	50	
16	Norma Brasileira	f	55	
15	Norma Internacional	f	60	
18	Norma Técnica Temática	f	65	
19	Norma Nacional/Internacional	f	70	
17	Norma Mercosur	f	75	
20	Norma Nacional/Internacional/Eletrotécnica	f	80	
21	American Society for Testing and Materials	f	85	
7	Anuário	f	95	
8	Balanço	f	100	
9	Catálogo	f	105	
10	Censo	f	110	
11	Folheto	f	115	
12	Governo do estado	f	120	
13	Prática de ensino	f	125	
14	Relatório	f	130	
26	Manual	f	135	
27	Livro de exercícios	f	140	
28	Livro do professor	f	145	
29	Índice	f	150	
30	Mapa	f	155	
31	Jogo	f	160	
32	Testes	f	165	
33	Suplemento	f	170	
34	Anexo	f	175	
35	Livro do aluno	f	180	
36	Planilha	f	185	
37	Temapédia	f	190	
38	Datapédia	f	195	
39	HP-12c	f	200	
24	Periódico	f	45	
\.


--
-- Data for Name: gtcmylibrary; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcmylibrary (mylibraryid, personid, tablename, tableid, date, message, visible) FROM stdin;
\.


--
-- Data for Name: gtcnews; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcnews (newsid, place, title1, news, date, begindate, enddate, isrestricted, isactive, operator, libraryunitid) FROM stdin;
1	2	Seja bem vindo ao Gnuteca3.	<center>Esta nova versão foi reestruturada adotando novas tecnologias e seguindo o conceito da Web 2.0. Agrega novas funcionalidades, dentre elas pode-se destacar: </center>\n<ul><li>suporte de políticas e direitos por unidade</li><li>associação de biblioteca</li><li>facilidade na configuração de formatos, filtros, regras de circulação de material, planilhas Marc</li><li>catalogo e visualização da capa de materiais</li><li>possui mais de 30 relatórios</li><li>integração com Google Livros</li><li>pesquisas personalizáveis</li><li>envio configurável de recibos por e-mail</li><li>preferências por biblioteca</li></ul>\nMais informações em <a href=http://www.solis.coop.br/gnuteca>www.solis.coop.br/gnuteca</a>.\nPara editar esta notícia e criar novas, clique <a href=/index.php?module=gnuteca3&action=main:administration:news>Aqui</a>.	2010-12-06 00:00:00	\N	\N	f	t	gnuteca	\N
\.


--
-- Data for Name: gtcnewsaccess; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcnewsaccess (newsid, linkid, bug_dia2sql_ignorar) FROM stdin;
\.


--
-- Data for Name: gtcoperation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcoperation (operationid, description, definerule) FROM stdin;
1	Empréstimo	t
2	Devolução	t
3	Empréstimo entre unidades	t
4	Devolução entre unidades	t
5	Empréstimo entre unidades - Confirma recebimento	t
10	Reserva local	f
11	Reserva local para nível inicial	f
12	Reserva web	f
13	Reserva web para nível inicial	f
14	Atender reserva	t
15	Cancelar reserva	t
20	Retirar com atraso	f
21	Retirar com penalidade	f
22	Retirar com multa	f
\.


--
-- Data for Name: gtcoperatorlibraryunit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcoperatorlibraryunit (operator, libraryunitid) FROM stdin;
gnuteca	\N
\.


--
-- Data for Name: gtcpenalty; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcpenalty (penaltyid, personid, libraryunitid, observation, internalobservation, penaltydate, penaltyenddate, operator) FROM stdin;
\.


--
-- Data for Name: gtcpersonconfig; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcpersonconfig (personid, parameter, value) FROM stdin;
\.


--
-- Data for Name: gtcpersonlibraryunit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcpersonlibraryunit (libraryunitid, personid, bug_dia2sql_ignorar) FROM stdin;
\.


--
-- Data for Name: gtcpolicy; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcpolicy (privilegegroupid, linkid, materialgenderid, loandays, loandate, loanlimit, renewallimit, reservelimit, daysofwaitforreserve, reservelimitininitiallevel, daysofwaitforreserveininitiallevel, finevalue, renewalweblimit, renewalwebbonus, additionaldaysforholidays, penaltybydelay) FROM stdin;
\.


--
-- Data for Name: gtcprecatalogue; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcprecatalogue (controlnumber, fieldid, subfieldid, line, indicator1, indicator2, content, searchcontent, prefixid, suffixid, separatorid) FROM stdin;
\.


--
-- Data for Name: gtcprefixsuffix; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcprefixsuffix (prefixsuffixid, fieldid, subfieldid, content, type) FROM stdin;
1	300	a	 p.	2
2	250	a	 ed.	2
\.


--
-- Data for Name: gtcprivilegegroup; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcprivilegegroup (privilegegroupid, description) FROM stdin;
\.


--
-- Data for Name: gtcpurchaserequest; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcpurchaserequest (purchaserequestid, libraryunitid, personid, costcenterid, amount, course, observation, needdelivery, forecastdelivery, deliverydate, voucher, controlnumber, precontrolnumber, externalid) FROM stdin;
\.


--
-- Data for Name: gtcpurchaserequestmaterial; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcpurchaserequestmaterial (purchaserequestid, fieldid, subfieldid, content) FROM stdin;
\.


--
-- Data for Name: gtcpurchaserequestquotation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcpurchaserequestquotation (purchaserequestid, supplierid, value, observation) FROM stdin;
\.


--
-- Data for Name: gtcrenew; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcrenew (renewid, loanid, renewtypeid, renewdate, returnforecastdate, operator) FROM stdin;
\.


--
-- Data for Name: gtcrenewtype; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcrenewtype (renewtypeid, description) FROM stdin;
1	Local
2	Web
\.


--
-- Data for Name: gtcreport; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcreport (reportid, title, description, permission, reportsql, reportsubsql, script, model, isactive, reportgroup) FROM stdin;
17	Estatística - Reservas Material Emprestado	 Gera a quantidade de reservas de materiais emprestados (material estava emprestado quando foi feita a reserva) realizadas num determinado período.	basic	SELECT \n    COUNT(DISTINCT reserveid) AS "Quantidade" \n    FROM \n        gtcreserve \n    WHERE\n        requesteddate::date BETWEEN '$beginDate' AND '$endDate' AND \n        CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE libraryUnitId = $libraryUnitId END AND \n        reservetypeid IN (1, 2);	\N	\N	\N	t	RES
18	Estatística - Reservas Material Disponível	 Gera a quantidade de reservas de materiais disponíveis (material estava disponível quando foi feita a reserva) realizadas num determinado período.	basic	SELECT \n    COUNT(DISTINCT reserveid) AS "Quantidade" \n    FROM \n        gtcreserve \n    WHERE \n        requesteddate::date BETWEEN '$beginDate' AND '$endDate' AND \n        CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE libraryUnitId = $libraryUnitId END AND \n        reservetypeid NOT IN (1, 2);	\N	\N	\N	t	RES
19	Estatística - Reserva vencida de Material Disponível	 Gera a quantidade de reservas vencidas (usuário não retirou o material até a data limite) de materiais disponíveis (material estava disponível quando foi feita a reserva) realizadas num determinado período.	basic	SELECT \n    COUNT(DISTINCT reserveid) AS "Quantidade" \n    FROM \n        gtcreserve \n    WHERE \n        requesteddate::date BETWEEN '$beginDate' AND '$endDate' AND \n        CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE libraryUnitId = $libraryUnitId END AND \n        reservetypeid NOT IN (1, 2) AND \n        reservestatusid IN (5, 6);	\N	\N	\N	t	RES
20	Estatística - Reserva vencida de Material Emprestado	 Gera a quantidade de reservas vencidas (usuário não retirou o material até a data limite) de materiais emprestados (material estava emprestado quando foi feita a reserva) realizadas num determinado período.	basic	SELECT \n    COUNT(DISTINCT reserveid) AS "Quantidade" \n    FROM \n        gtcreserve \n    WHERE \n        requesteddate::date BETWEEN '$beginDate' AND '$endDate' AND \n        CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE libraryUnitId = $libraryUnitId END AND \n        reservetypeid IN (1, 2) AND \n        reservestatusid IN (5, 6);	\N	\N	\N	t	RES
21	Estatística - Acervo Impresso (Livros)	Gera a quantidade de Obras e Exemplares de livros da biblioteca, agrupado pelo CNPQ (áreas do conhecimento de acordo com o Conselho Nacional de Desenvolvimento Científico e Tecnológico).<BR>\nÉ necessário que o campo 901.b (Áreas do conhecimento) na catalogação dos livros esteja preenchido.	basic	SELECT \n     C.description AS "CNPQ", \n     COUNT(DISTINCT A.controlnumber) AS "Quantidade de Obras", \n     COUNT(DISTINCT A.itemnumber) AS "Quantidade de Exemplares" \nFROM \n     gtcexemplarycontrol A, \n     gtcmaterial B, \n     gtcmarctaglistingoption C \nWHERE \n     A.controlnumber = B.controlnumber AND\n     CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE A.originallibraryUnitId = $libraryUnitId END AND \n     A.materialphysicaltypeid IN (1, 8) AND \n     A.materialtypeid NOT IN (23, 24, 25) AND \n     A.exemplarystatusid NOT IN (4, 5, 8) AND \n     C.marctaglistingid = '901.b' AND \n     B.content = C.option AND \n     B.fieldid = '901' AND \n     B.subfieldid = 'b' \nGROUP BY 1 \nORDER BY 1;	\N	\N	\N	t	ACV
22	Estatística - Acervo Impresso (Periódicos)	Gera a quantidade de Obras e Exemplares de livros da biblioteca, agrupado pelo CNPQ (áreas do conhecimento de acordo com o Conselho Nacional de Desenvolvimento Científico e Tecnológico).<BR>\nÉ necessário que o campo 901.b (Áreas do conhecimento) na catalogação dos periódicos esteja preenchido.	basic	SELECT \n     C.description AS "CNPQ", \n     COUNT(DISTINCT A.controlnumber) AS "Quantidade de Obras", \n     COUNT(DISTINCT A.itemnumber) AS "Quantidade de Exemplares" \nFROM \n     gtcexemplarycontrol A, \n     gtcmaterial B, \n     gtcmarctaglistingoption C \nWHERE \n     A.controlnumber = B.controlnumber AND\n     CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE A.originallibraryUnitId = $libraryUnitId END AND \n     A.materialphysicaltypeid IN (1, 8) AND \n     A.materialtypeid IN (24) AND \n     A.exemplarystatusid NOT IN (4, 5, 8) AND \n     C.marctaglistingid = '901.b' AND \n     B.content = C.option AND \n     B.fieldid = '901' AND \n     B.subfieldid = 'b' \nGROUP BY 1 \nORDER BY 1	\N	\N	\N	t	ACV
23	Estatística - Empréstimos por CNPQ	Gera a quantidade de empréstimos por CNPQ (áreas do conhecimento de acordo com o Conselho Nacional de Desenvolvimento Científico e Tecnológico).<BR>\nÉ necessário que o campo 901.b (Áreas do conhecimento) na catalogação esteja preenchido.<BR>\n* O relatório pode demorar para ser gerado caso o período de empréstimo informado no filtro seja muito grande.	basic	SELECT \n    Z.content AS "ID", \n    W.description AS "CNPQ", \n    COUNT(DISTINCT X.loanid) + (SELECT COUNT(DISTINCT D.renewid) FROM gtcloan A, gtcexemplarycontrol B, gtcmaterial C, gtcrenew D WHERE A.itemnumber = B.itemnumber AND  B.controlnumber = C.controlnumber AND A.loanid = D.loanid AND  D.renewdate BETWEEN '$beginDate' AND '$endDate' AND CASE WHEN $libraryUnitId = 0\n          THEN 1                     = 1\n          ELSE A.libraryUnitId         = $libraryUnitId\n          END \nAND  C.fieldid = '901' AND  C.subfieldid = 'b' AND C.content = Z.content) AS "Quantidade" \nFROM \n   gtcloan X, \n   gtcexemplarycontrol Y, \n   gtcmaterial Z, \n   gtcmarctaglistingoption W \nWHERE \n   X.itemnumber = Y.itemnumber AND \n   Y.controlnumber = Z.controlnumber AND \n   X.loandate::date BETWEEN '$beginDate' AND '$endDate'\n        AND CASE WHEN $libraryUnitId = 0\n          THEN 1                     = 1\n          ELSE X.libraryUnitId         = $libraryUnitId\n          END AND \n   W.marctaglistingid = '901.b' AND \n   Z.content = W.option AND \n   Z.fieldid = '901' AND \n   Z.subfieldid = 'b' \nGROUP BY 1, 2 \nORDER BY 2;	\N	\N	\N	t	EMP
24	Estatística - MNC	Gera uma lista com os tipos de materiais não convencionais (CD, DVD, calculadora, fita, etc) e a quantidade de obras e exemplares de cada um	basic	SELECT \n     B.description AS "Tipo", \n     COUNT(DISTINCT A.controlnumber) AS "Quantidade de Obras", \n     COUNT(DISTINCT A.itemnumber) AS "Quantidade de Exemplares" \nFROM \n     gtcexemplarycontrol A, \n     gtcmaterialphysicaltype B \nWHERE \n     A.materialphysicaltypeid = B.materialphysicaltypeid AND\n     CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE A.originallibraryUnitId = $libraryUnitId END AND  \n     A.exemplarystatusid NOT IN (4, 5, 8) AND \n     A.materialtypeid <> 24 AND \n     A.materialphysicaltypeid NOT IN (1, 8, 9) \nGROUP BY 1 \nORDER BY 1;	\N	\N	\N	t	ACV
25	Estatística - Utilização Local	Gera a quantidade de materiais utilizados localmente na biblioteca em determinado período, sem terem sidos retirados.<BR>\nPara isto é necessário que todos materiais encontrados nas mesas sejam devolvidos e que na tela de devolução do Circulação de material esteja selecionado o tipo: Utilização local.	basic	SELECT \n     D.description AS "CNPQ", \n     COUNT(DISTINCT A.returnregisterid) AS "Quantidade" \nFROM \n     gtcreturnregister A, \n     gtcexemplarycontrol B, \n     gtcmaterial C, \n     gtcmarctaglistingoption D  \nWHERE \n     A.returntypeid = 2 AND \n     A.itemnumber = B.itemnumber AND \n     B.controlnumber = C.controlnumber AND \n     B.line = C.line AND \n     CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE B.libraryUnitId = $libraryUnitId END AND \n     D.marctaglistingid = '901.b' AND \n     C.content = D.option AND \n     C.fieldid = '901' AND \n     C.subfieldid = 'b' AND \n     A.date::date BETWEEN '$beginDate' AND '$endDate' \nGROUP BY 1 \nORDER BY 1;	\N	\N	\N	t	UTL
1	Estatística - Quantidade de exemplares por unidade	Gera uma lista com a quantidade de exemplares por unidade.	basic	   SELECT A.libraryName as "Nome da biblioteca",\n          count(B.itemNumber) as "Quantidade de exemplares"\n     FROM gtcLibraryUnit      A\nLEFT JOIN gtcExemplaryControl B\n       ON (A.libraryUnitId = B.originalLibraryUnitId)\n    WHERE CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE B.libraryUnitId = $libraryUnitId END\n GROUP BY 1\n ORDER BY 2 DESC	\N	\N	\N	t	ACV
2	Estatística - Quantidade de obras por unidade	Gera uma lista com a quantidade de obras por unidade.	basic	      SELECT A.libraryName as "Nome da biblioteca",\n          count(distinct B.controlNumber) as "Quantidade de obras"\n     FROM gtcLibraryUnit      A\nLEFT JOIN gtcExemplaryControl B\n       ON (A.libraryUnitId = B.originalLibraryUnitId)\n    WHERE CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE B.libraryUnitId = $libraryUnitId END\n GROUP BY 1\n ORDER BY 2 DESC	\N	\N	\N	t	ACV
3	Estatítisca - Empréstimos por classe	Gera a quantidade de empréstimos por classes (classificação dada aos materiais) num determinado período.<BR>\nÉ necessário que o campo 090.a (Número da classificação) na Catalogação esteja preenchido.	basic	   SELECT b.content as "Classe do Material", \n        count(a.loanId) as "Quantidade de Empréstimos" \n   FROM gtcLoan a, gtcMaterial b, gtcExemplaryControl c \n  WHERE a.itemNumber             = c.itemNumber \n    AND c.controlNumber          = b.controlNumber\n    AND b.fieldId                = '090'\n    AND b.subFieldId             = 'a'\n    AND a.loanDate              >= '$beginDate'\n    AND a.loanDate              <= '$endDate' \n    AND CASE WHEN $libraryUnitId = 0\n          THEN 1                 = 1\n          ELSE a.libraryUnitId   = $libraryUnitId\n          END\nGROUP BY b.content\nORDER BY b.content	\N	\N	\N	t	EMP
4	Estatística - Empréstimos por grupo	Gera a quantidade de empréstimos por grupos de usuários num determinado período.<BR>	basic	  SELECT a.linkId as "Código grupo",\n          b.description as "Descrição",\n          count(a.loanId) as "Empréstimos"\n     FROM gtcloan a\nLEFT JOIN baslink b on a.linkId    = b.linkId\n    WHERE loanDate::date                >= '$beginDate'\n      AND loanDate::date                <= '$endDate'\n      AND CASE WHEN $libraryUnitId = 0\n          THEN 1                   = 1\n          ELSE a.libraryUnitId     = $libraryUnitId\n          END\n GROUP BY a.linkId, b.description\nORDER BY  b.description	\N	\N	\N	t	EMP
5	Estatística - Empréstimos por grupo x classe	Gera a quantidade de empréstimos por <B>grupos de usuários X classe</B> (classificação dada aos materiais).<BR>\nÉ necessário que o campo 090.a (Número da classificação) na Catalogação esteja preenchido.	basic	 SELECT a.linkId as "Código grupo", \n         d.description as "Grupo", \n         b.content as "Classe do Material", \n         count(a.loanId) as "Quantidade de Empréstimos"\n    FROM gtcLoan             a, \n         gtcMaterial         b, \n         gtcExemplaryControl c, \n         baslink             d \n   WHERE a.itemNumber             = c.itemNumber \n     AND c.controlNumber          = b.controlNumber \n     AND a.linkId                 = d.linkId \n     AND b.fieldId                = '090' \n     AND b.subFieldId             = 'a' \n     AND a.loanDate::date              >= '$beginDate' \n     AND a.loanDate::date              <= '$endDate'\n     AND CASE WHEN $libraryUnitId = 0\n          THEN 1                  = 1\n          ELSE a.libraryUnitId    = $libraryUnitId\n          END \ngroup by a.linkId, d.description, b.content\nORDER BY 1 desc	\N	\N	\N	t	EMP
7	Estatística - Renovações dos grupos	Gera a quantidade de renovações por grupos de usuários num determinado período.	basic	  SELECT a.linkid as "Código grupo", \n         b.description as "Grupo", \n         count(c.renewid) as "Quantidade de renovações" \n    FROM gtcloan  a, \n         baslink  b, \n         gtcrenew c \n   WHERE a.linkid                 = b.linkid \n     AND a.loanid                 = c.loanid \n     AND c.renewdate::date        >= '$beginDate' \n     AND c.renewdate::date        <= '$endDate'\n     AND CASE WHEN $libraryUnitId = 0\n          THEN 1                  = 1\n          ELSE a.libraryUnitId    = $libraryUnitId\n          END\nGROUP BY a.linkid, b.description \nORDER BY a.linkid	\N	\N	\N	t	EMP
8	Estatítisca - Renovações das classes	Gera a quantidade de renovações por classes (classificação dada aos materiais) num determinado período.<BR>\nÉ necessário que o campo 090.a (Número da classificação) na Catalogação esteja preenchido.	basic	  SELECT b.content as "Classe do Material", \n   COUNT(d.renewid) as "Quantidade de renovações" \n   FROM gtcloan             a, \n        gtcmaterial         b, \n        gtcexemplarycontrol c, \n        gtcrenew            d \n  WHERE a.itemnumber             = c.itemnumber \n    AND c.controlnumber          = b.controlnumber \n    AND a.loanid                 = d.loanid \n    AND b.fieldId                = '090' \n    AND b.subFieldId             = 'a' \n    AND d.renewdate::date        >= '$beginDate' \n    AND d.renewdate::date        <= '$endDate'\n    AND CASE WHEN $libraryUnitId = 0\n          THEN 1                 = 1\n          ELSE a.libraryUnitId   = $libraryUnitId\n          END \nGROUP BY b.content \nORDER BY b.content	\N	\N	\N	t	EMP
26	Estatística - Materiais Apagados	Gera a quantidade de materiais apagados em determinado período.<BR>\nPara isto, é necessário que após ter sido apagado, o material seja devolvido e que na tela de devolução do Circulação de material esteja selecionado o tipo: Apagados.	basic	SELECT \n     COUNT(A.returnregisterid) AS "Quantidade" \nFROM \n     gtcreturnregister A, \n     gtcexemplarycontrol B \nWHERE \n     A.itemnumber = B.itemnumber AND \n     CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE B.libraryUnitId = $libraryUnitId END AND \n     A.returntypeid = 1 AND \n     A.date::date BETWEEN '$beginDate' AND '$endDate';	\N	\N	\N	t	RST
27	Lista de Coleções de Periódicos	Gera uma lista com todos os títulos de coleções de periódicos.	basic	SELECT \n\tCASE WHEN \n\t\tB.content IS NULL \n\tTHEN \n\t\tA.content \n\tELSE \n\t\tA.content || ': ' || B.content \n\tEND AS "Título" \nFROM \n\tgtcmaterial A \n\t\tLEFT JOIN \n\tgtcmaterial B \n\t\tON (A.controlnumber = B.controlnumber AND \n\t\t\tB.fieldid = '245' AND \n\t\t\tB.subfieldid = 'b') \nWHERE \n\tA.controlnumber IN (SELECT DISTINCT controlnumber FROM gtckardexcontrol) AND \n\tA.fieldid = '245' AND \n\tA.subfieldid = 'a' \nORDER BY 1;	\N	\N	\N	t	MAT
28	Lista de títulos de VTs por CNPQ	Gera uma lista com todos os títulos de vídeos por CNPQ (áreas do conhecimento de acordo com o Conselho Nacional de Desenvolvimento Científico e Tecnológico).<BR>\nÉ necessário que o campo 901.b (Áreas do conhecimento) na catalogação esteja preenchido e o campo 901.c (Tipo físico do material) seja DVD ou Fita VHS.	basic	SELECT \n\tCASE WHEN \n\t\tB.content IS NULL \n\tTHEN \n\t\tA.content \n\tELSE \n\t\tA.content || ': ' || B.content \n\tEND AS "Título" \nFROM \n\tgtcmaterial X \n\t\tINNER JOIN \n\tgtcmaterial Y \n\t\tON (Y.controlnumber = X.controlnumber AND X.fieldid = '901' AND X.subfieldid = 'b' AND X.content = '$cnpq' AND Y.fieldid = '901' AND Y.subfieldid = 'c' AND Y.content IN ('2','3')) \n\t\tINNER JOIN \n\tgtcmaterial A \n\t\tON (A.controlnumber = Y.controlnumber)\n\t\tLEFT JOIN \n\tgtcmaterial B \n\t\tON (A.controlnumber = B.controlnumber AND \n\t\t\tB.fieldid = '245' AND \n\t\t\tB.subfieldid = 'b') \nWHERE \n\tA.fieldid = '245' AND \n\tA.subfieldid = 'a' \nORDER BY 1;	\N	\N	\N	t	MAT
9	Estatística - Renovações dos grupo X classe	Gera a quantidade de renovações por <B>grupos de usuários X classe</B>  (classificação dada aos materiais).<BR>\nÉ necessário que o campo 090.a (Número da classificação) na Catalogação esteja preenchido.	basic	 SELECT a.linkId as "Código grupo", \n         d.description as "Grupo", \n         b.content as "Classe do Material", \n         count(e.renewid) as "Quantidade de Renovações" \n    FROM gtcLoan             a, \n         gtcMaterial         b, \n         gtcExemplaryControl c, \n         baslink             d, \n         gtcrenew            e \n   WHERE a.itemNumber             = c.itemNumber \n     AND c.controlNumber          = b.controlNumber \n     AND a.linkId                 = d.linkId \n     AND a.loanid                 = e.loanid \n     AND b.fieldId                = '090' \n     AND b.subFieldId             = 'a' \n     AND e.renewDate::date        >= '$beginDate' \n     AND e.renewDate::date        <= '$endDate' \n     AND CASE WHEN $libraryUnitId = 0\n          THEN 1                  = 1\n          ELSE a.libraryUnitId    = $libraryUnitId\n          END\nGROUP BY a.linkId, d.description, b.content \nORDER BY 1 desc	\N	\N	\N	t	EMP
10	Exemplo de Script	Teste de código feito para a aba Script que retorna a quantidade de exemplares por estado do material.<BR>\nÉ simplesmente um exemplo para se ter ideia de como criar relatórios utilizando comandos de PHP.	advanced	\N	\N	\nclass FrmCustomReport extends FrmAdminReport \n{ \n    function __construct() \n    { \n        parent::__construct(); \n    } \n\n    public function getGrid() \n    { \n        $data = $this->getReportData(); \n        $args = (object) ( $_REQUEST ); \n        $sql = $data->reportSql; \n        $subSql = $data->reportSubSql; \n        $columns[]= 'Quantidade'; \n        $columns[]= 'Descrição'; \n\n        if ( $columns ) \n        { \n            foreach ( $columns as $line => $info ) \n            { \n                $gridColumns[] = new MGridColumn( $info, MGrid::ALIGN_LEFT, null, null, true, null, true); \n            } \n        } \n\n        $grid = new GnutecaGrid(null, $gridColumns, $this->MIOLO->getCurrentURL(), LISTING_NREGS); \n\n        if ( MIOLO::_REQUEST('reportType') == 'detail' ) \n        { \n            $gridArgs['0'] = '%0%'; \n            $gridArgs['event'] = 'showDetail'; \n            $hrefDetail = $this->MIOLO->getActionURL($this->module, $this->action, null, $gridArgs); \n            $grid->addActionIcon( _M('Details', $this->module), 'select', $hrefDetail ); \n            unset( $subSql ); \n        } \n\n        $sql = "SELECT count(A.exemplaryStatusId), B.description from gtcexemplarycontrol A, gtcExemplaryStatus B where A.exemplaryStatusId = B.exemplaryStatusId group by A.exemplaryStatusId, B.description order by count desc"; \n\n        $result = $this->business->executeSelect( $sql , $subSql, $args); \n        $grid->setData( $result ); \n        $grid->setIsScrollable(); \n        \n        return $grid; \n    } \n}	\N	t	\N
12	Atrasados por classificação	Gera uma lista ordenada pela classificação dos materiais atrasados dentro de um determinado período.<BR> \nAntes de avisar os usuários que seu empréstimo está atrasado, é bom conferir se por ventura o material não está na prateleira.	basic	(SELECT \n     A.personid AS "Código", \n     B.name AS "Nome", \n     A.itemnumber AS "Exemplar", \n     C.content || '  ' || D.content AS "Classificação", \n     (SELECT content FROM gtcmaterial WHERE fieldid = '250' AND subfieldid = 'a' AND controlnumber = C.controlnumber) AS "Edição", \n     (SELECT content FROM gtcmaterial WHERE fieldid = '949' AND subfieldid = 'v' AND controlnumber = C.controlnumber AND line = E.line) AS "Volume", \n     DATE(A.loandate) AS "Empréstimo", \n     DATE(A.returnforecastdate) AS "Prev. Devolução" \nFROM \n     gtcLoan A, \n     basperson B, \n     gtcmaterial C, \n     gtcmaterial D, \n     gtcExemplaryControl E \nWHERE\n     A.personid = B.personid AND \n     A.itemNumber = E.itemNumber AND \n     E.controlNumber = C.controlNumber AND \n     C.controlNumber = D.controlNumber AND  \n     C.fieldId = '090' AND \n     C.subFieldId = 'a' AND \n     D.fieldId = '090' AND \n     D.subFieldId = 'b' AND \n     A.returnforecastdate < DATE(NOW()) AND \n     DATE(A.returnforecastdate) >= '$beginDate' AND \n     DATE(A.returnforecastdate) <= '$endDate' AND \n     A.returndate IS NULL AND \n     A.itemnumber NOT ILIKE 'P%' AND \n     CASE WHEN $libraryUnitId = 0\n          THEN 1 = 1 \n     ELSE \n          A.libraryUnitId = $libraryUnitId \n     END\nORDER BY \n     SUBSTR(A.itemnumber, 0, 2), \n\tSUBSTR(C.content, 0, 2), \n     REPLACE(C.searchcontent, '@', '1'), \n     D.content)\nUNION ALL \n(SELECT \n     A.personid AS "Código", \n     B.name AS "Nome", \n     A.itemnumber AS "Exemplar", \n     C.content || '  ' || D.content || ' ' || F.content AS "Classificação", \n     (SELECT content FROM gtcmaterial WHERE fieldid = '250' AND subfieldid = 'a' AND controlnumber = C.controlnumber) AS "Edição", \n     (SELECT content FROM gtcmaterial WHERE fieldid = '949' AND subfieldid = 'v' AND controlnumber = C.controlnumber AND line = E.line) AS "Volume", \n     DATE(A.loandate) AS "Empréstimo", \n     DATE(A.returnforecastdate) AS "Prev. Devolução" \nFROM \n     gtcLoan A, \n     basperson B, \n     gtcmaterial C, \n     gtcmaterial D, \n     gtcExemplaryControl E, \n     gtcmaterial F \nWHERE\n     A.personid = B.personid AND \n     A.itemNumber = E.itemNumber AND \n     E.controlNumber = C.controlNumber AND \n     C.controlNumber = D.controlNumber AND \n     D.controlNumber = F.controlNumber AND \n     C.fieldId = '090' AND \n     C.subFieldId = 'a' AND \n     D.fieldId = '090' AND \n     D.subFieldId = 'b' AND \n     F.fieldId = '362' AND \n     F.subFieldId = 'a' AND \n     A.returnforecastdate < DATE(NOW()) AND \n     DATE(A.returnforecastdate) >= '$beginDate' AND \n     DATE(A.returnforecastdate) <= '$endDate' AND \n     A.returndate IS NULL AND \n     A.itemnumber ILIKE 'P%' AND \n     CASE WHEN $libraryUnitId = 0\n          THEN 1 = 1 \n     ELSE \n          A.libraryUnitId = $libraryUnitId \n     END\nORDER BY \n     SUBSTR(A.itemnumber, 0, 2), \n     REPLACE(C.searchcontent, '@', '1'), \n     D.content, \n     F.content)	\N	\N	\N	t	EMP
13	Conferir reservas atendidas	Gera uma lista com todas as reservas atendidas e comunicadas, para conferir se estão na biblioteca.<BR> É recomendado sempre fazer esta conferência antes de avisar os usuários sobre a chegada de sua reserva.	intermediary	 SELECT A.itemnumber, D.content, E.content\n            FROM gtcreservecomposition A \n            LEFT JOIN gtcreserve B \n            ON (A.reserveid = B.reserveid) \n            LEFT JOIN gtcexemplarycontrol C \n            ON (A.itemnumber = C.itemnumber) \n            LEFT JOIN gtcmaterial D \n            ON (C.controlnumber = D.controlnumber AND D.fieldid = '090' AND D.subfieldid = 'a') \n            LEFT JOIN gtcmaterial E \n            ON (D.controlnumber = E.controlnumber AND E.fieldid = '090' AND E.subfieldid = 'b') \n            WHERE A.isconfirmed = 't' AND B.reservestatusid IN (2, 3) AND \n            CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE C.libraryUnitId = $libraryUnitId END \n            ORDER BY SUBSTR(C.itemnumber, 0, 2), SUBSTR(D.content, 0, 2), \n            REPLACE(D.searchcontent, '@', '1'), \n            E.content;	\N	\N	\N	t	RES
14	Reservas disponíveis	Gera uma lista com todas as reservas de materiais disponíveis que ainda não foram atendidas.<BR> É útil para pegar os materiais nas prateleiras e separá-los junto com os outros reservados.	intermediary	SELECT \n     result."Cód. Reserva", \n     result."Classificação", \n     result."Exemplar", \n     (SELECT Y.description FROM gtcexemplarycontrol X, gtcmaterialtype Y where X.itemnumber = result."Exemplar" AND X.materialtypeid = Y.materialtypeid LIMIT 1) as "Tipo", \n     (SELECT Y.description FROM gtcexemplarycontrol X, gtcmaterialphysicaltype Y where X.itemnumber = result."Exemplar" AND X.materialphysicaltypeid = Y.materialphysicaltypeid LIMIT 1) as "Tipo Físico", \n     (SELECT Y.content FROM gtcexemplarycontrol X, gtcmaterial Y where X.itemnumber = result."Exemplar" AND Y.fieldid = '949' AND Y.subfieldid = 'v' AND X.line = Y.line AND X.controlnumber = Y.controlnumber LIMIT 1) as "Volume", \n     (SELECT Y.content FROM gtcexemplarycontrol X, gtcmaterial Y where X.itemnumber = result."Exemplar" AND Y.fieldid = '250' AND Y.subfieldid = 'a' AND X.line = Y.line AND X.controlnumber = Y.controlnumber LIMIT 1) as "Edição" \nFROM (\n     (SELECT \n          DISTINCT B.reserveid AS "Cód. Reserva", \n          D.content || '   ' || E.content AS "Classificação",\n          (SELECT x.itemnumber FROM gtcexemplarycontrol X, gtcreservecomposition Y WHERE X.itemnumber = Y.itemnumber AND Y.reserveid = B.reserveid LIMIT 1) AS "Exemplar", \n          SUBSTR((SELECT x.itemnumber FROM gtcexemplarycontrol X, gtcreservecomposition Y WHERE X.itemnumber = Y.itemnumber AND Y.reserveid = B.reserveid LIMIT 1), 0, 2), \n          SUBSTR(D.content, 0, 2), \n          REPLACE(D.searchcontent, '@', '1')\n     FROM \n          gtcreservecomposition A, \n          gtcreserve B, \n          gtcexemplarycontrol C, \n          gtcmaterial D, \n          gtcmaterial E \n     WHERE \n          A.reserveid = B.reserveid AND \n          A.itemnumber = c.itemnumber AND\n          C.controlnumber = D.controlnumber AND \n          D.controlnumber = E.controlnumber AND \n          D.fieldid = '090' AND \n          D.subfieldid = 'a' AND \n          E.fieldid = '090' AND \n          E.subfieldid = 'b' AND \n          B.reservestatusid = 1 AND \n          B.libraryUnitId = 1 AND \n          B.reservestatusid = 1 AND \n          C.materialtypeid <> 24 AND \n          C.exemplarystatusid = 1 AND \n          CASE WHEN $libraryUnitId = 0\n          THEN 1 = 1 \n          ELSE \n               B.libraryUnitId = $libraryUnitId \n          END\n     ORDER BY \n          4, 5, 6) \n     UNION ALL \n     (SELECT \n          DISTINCT B.reserveid AS "Cód. Reserva", \n          D.content || '   ' || E.content || '   ' || F.content AS "Classificação",\n          (SELECT x.itemnumber FROM gtcexemplarycontrol X, gtcreservecomposition Y WHERE X.itemnumber = Y.itemnumber AND Y.reserveid = B.reserveid LIMIT 1) AS "Tipo", \n          SUBSTR((SELECT x.itemnumber FROM gtcexemplarycontrol X, gtcreservecomposition Y WHERE X.itemnumber = Y.itemnumber AND Y.reserveid = B.reserveid LIMIT 1), 0, 2), \n          SUBSTR(D.content, 0, 2), \n          REPLACE(D.searchcontent, '@', '1')\n     FROM \n          gtcreservecomposition A, \n          gtcreserve B, \n          gtcexemplarycontrol C, \n          gtcmaterial D, \n          gtcmaterial E, \n          gtcmaterial F \n     WHERE \n          A.reserveid = B.reserveid AND \n          A.itemnumber = c.itemnumber AND\n          C.controlnumber = D.controlnumber AND \n          D.controlnumber = E.controlnumber AND \n          E.controlnumber = F.controlnumber AND \n          D.fieldid = '090' AND \n          D.subfieldid = 'a' AND \n          E.fieldid = '090' AND \n          E.subfieldid = 'b' AND \n          F.fieldid = '362' AND \n          F.subfieldid = 'a' AND \n          B.reservestatusid = 1 AND \n          B.libraryUnitId = 1 AND \n          B.reservestatusid = 1 AND \n          C.materialtypeid = 24 AND \n          C.exemplarystatusid = 1 AND \n          CASE WHEN $libraryUnitId = 0\n          THEN 1 = 1 \n          ELSE \n               B.libraryUnitId = $libraryUnitId \n          END\n     ORDER BY \n          4, 5, 6)\n) result	\N	\N	\N	t	RES
15	Restaurandos	Gera uma lista de todos os materiais que estão no estado restauração, com o número do tombo e seu respectivo título.	basic	SELECT \n\tDISTINCT A.itemnumber, \n\tB.content \nFROM \n\tgtcexemplarycontrol A, \n\tgtcmaterial B, \n\tgtcexemplarystatushistory C \nWHERE \n\tA.controlnumber = B.controlnumber AND \n\tA.itemnumber = C.itemnumber AND \n\tA.exemplarystatusid = 6 AND \n\tB.fieldid = '245' AND \n\tB.subfieldid = 'a' AND \n\tC.exemplarystatusid = 6 AND \n\tC.date::date > '$beginDate' \nORDER BY 2	\N	\N	\N	t	RST
16	Nota fiscal mês	Gera uma lista com a quantidade de materiais cadastrados por nota fiscal e centro de custo num determinado mês.<BR>\nÉ necessário o preenchimento dos seguintes campos na catalogação:<BR>\n949.f - Nota fiscal<BR>\n949.h - Data da nota fiscal<BR>\n949.q - Centro de custo	intermediary	select \n    A.content, b.content, G.description, H.description, COUNT(F.itemnumber), C.content, E.libraryname \n    FROM \n    gtcmaterial A, gtcmaterial B, gtcmaterial C, gtclibraryunit E, gtcexemplarycontrol F, gtcmaterialphysicaltype G, gtcmaterialtype H \n    where \n    F.acquisitiontype = 'C' and F.controlnumber = A.controlnumber and \n    F.line = A.line and a.fieldid = '949' and a.subfieldid = 'f' and A.controlnumber = B.controlnumber and \n    A.line = B.line and b.fieldid = '949' and b.subfieldid = 'h' and b.content ilike '$data' and B.controlnumber = C.controlnumber and \n    B.line = C.line and c.fieldid = '949' and c.subfieldid = 'q' and \n    F.materialtypeid <> 24 AND \n    F.originallibraryUnitId = E.libraryUnitId AND \n    G.materialphysicaltypeid = F.materialphysicaltypeid and \n    H.materialtypeid = F.materialtypeid \n    Group by 1, 2, 3, 4, 6, 7 \n    Order by 7, 1, 2, 3, 4, 6, 5;	\N	\N	\N	t	ACV
29	Estatística - Coleções X Quantidade de Fascículos	Gera uma lista com todos os títulos das coleções e a respectiva quantidade de fascículos.	basic	SELECT \n\tA.content AS "Coleção", \n\tCOUNT(DISTINCT B.controlnumber) AS "Quantidade de Fascículos" \nFROM \n\tgtcmaterial A, \n\tgtcmaterial B, \n\tgtckardexcontrol C \nWHERE \n\tA.controlnumber::TEXT = B.content AND \n\tA.controlnumber = C.controlnumber AND \n\tA.fieldid = '245' AND \n\tA.subfieldid = 'a' AND \n\tB.fieldid = '773' AND \n\tB.subfieldid = 'w' \nGROUP BY 1 \nORDER BY 1 ASC;	\N	\N	\N	t	ACV
30	Estatística - Exemplares Catalogados por Unidade	Gera a quantidade de exemplares (todos os tipos de materiais) cadastrados num determinado período.	basic	SELECT \n\tCOUNT(*) AS "Quantidade" \nFROM \n\tgtcexemplarycontrol \nWHERE \n\tentrancedate::date BETWEEN '$beginDate' AND '$endDate' AND\n    CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE originallibraryUnitId = $libraryUnitId END;	\N	\N	\N	t	ACV
31	Estatística - Artigos Processados por Mês	Gera a quantidade de artigos cadastrados por período em todas as biliotecas	basic	SELECT \n\tCOUNT(*) \nFROM \n\tgtcmaterialcontrol \nWHERE \n\tentrancedate BETWEEN '$beginDate' AND '$endDate' AND \n\tcategory = 'SA' AND \n\tlevel = '4';	\N	\N	\N	t	ACV
32	Lista de coleções por CNPQ	Gera uma lista contendo a classificação e o título de todas coleções, agrupadas pelo CNPQ (áreas do conhecimento de acordo com o Conselho Nacional de Desenvolvimento Científico e Tecnológico).<BR>\nÉ necessário que os seguinte campos na catalogação estejam preenchidos:<BR>\n090.a - Número de classificação<BR>\n090.b - Cutter<BR>\n245.a - Título<BR>\n901.b - Áreas do conhecimento	basic	SELECT DISTINCT\n\tC.content AS "Classificação", \n\tD.content AS "Cutter", \n\tB.content ||\n                  CASE WHEN\n                     (SELECT content FROM gtcmaterial WHERE fieldid = '245' AND subfieldid = 'b' AND controlnumber = D.controlnumber) IS NULL\n                  THEN\n                     ''\n                  ELSE\n                     ':' || (SELECT content FROM gtcmaterial WHERE fieldid = '245' AND subfieldid = 'b' AND controlnumber = D.controlnumber)\n                  END AS "Título", \n\tF.description AS "CNPQ" \nFROM \n\tgtcmaterial B,\n\tgtcmaterial C, \n\tgtcmaterial D, \n\tgtcmaterial E, \n\tgtcmarctaglistingoption F \nWHERE \n\tB.controlnumber = C.controlnumber AND \n\tC.controlnumber = D.controlnumber AND \n\tD.controlnumber = E.controlnumber AND \n\tC.fieldid = '090' AND \n\tC.subfieldid = 'a' AND \n\tD.fieldid = '090' AND \n\tD.subfieldid = 'b' AND \n\tE.fieldid = '901' AND \n\tE.subfieldid = 'b' AND \n\tE.content = F.option AND \n\tF.marctaglistingid = '901.b' AND \n\tB.controlnumber IN (SELECT DISTINCT controlnumber FROM gtckardexcontrol) AND \n\tB.fieldid = '245' AND \n\tB.subfieldid = 'a' \nORDER BY 4, 1, 2;	\N	\N	\N	t	MAT
33	Estatística - Estimativa de Visita	Gera uma estimativa de quantas pessoas utilizaram a biblioteca num determinado período.<BR>\nSoma a quantidade de empréstimos, devoluções, renovações, reservas solicitadas e confirmadas por pessoas diferentes.	basic	SELECT \n\tCOUNT(DISTINCT result."A")\nFROM \n\t(\n\t(SELECT \n\t\tDISTINCT personid::TEXT || '-' || DATE_PART('hour', loandate) || '-' || DATE_PART('day', loandate) AS "A" \n\tFROM \n\t\tgtcloan \n\tWHERE \n\t\tloandate::date BETWEEN '$beginDate' AND '$endDate' AND \n          CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE libraryUnitId = $libraryUnitId END \n\t)\n\tUNION\n\t(SELECT \n\t\tDISTINCT personid::TEXT || '-' || DATE_PART('hour', returndate) || '-' || DATE_PART('day', returndate) AS "A" \n\tFROM \n\t\tgtcloan \n\tWHERE \n\t\treturndate BETWEEN '$beginDate' AND '$endDate' AND \n          CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE libraryUnitId = $libraryUnitId END \n\t) \n\tUNION \n\t(SELECT \n\t\tDISTINCT personid::TEXT || '-' || DATE_PART('hour', requesteddate) || '-' || DATE_PART('day', requesteddate) AS "A" \n\tFROM \n\t\tgtcreserve \n\tWHERE \n\t\trequesteddate BETWEEN '$beginDate' AND '$endDate' AND \n\t\treservetypeid IN (1, 3) AND \n          CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE libraryUnitId = $libraryUnitId END \n\t)\n     UNION \n     (SELECT \n          DISTINCT Y.personid::TEXT || '-' || DATE_PART('hour', renewdate) || '-' || DATE_PART('day', renewdate) AS "A" \n     FROM \n          gtcrenew X, \n          gtcloan Y \n     WHERE \n          X.loanid = Y.loanid AND \n          CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE libraryUnitId = $libraryUnitId END AND \n          renewdate BETWEEN '$beginDate' AND '$endDate'\n     )\n     ) AS result;	\N	\N	\N	t	UTL
34	Estatística - Materiais Inseridos no Sistema por operador	Gera uma lista com os operadores e a quantidade de materiais (artigos, coleções, exemplares e kardex) que cada um cadastrou num determinado período.	intermediary	SELECT \n\t'Exemplares', \n\toperator, \n\tCOUNT(*) \nFROM \n\tgtcmaterialhistory \nWHERE \n\tfieldid = '949' AND \n\tsubfieldid = 'a' AND \n\tdata::date BETWEEN '$beginDate' AND '$endDate' AND \n\tchancestype = 'I' \nGROUP BY 1, 2 \nUNION \nSELECT \n\t'Artigos', \n\tB.operator, \n\tCOUNT(*) \nFROM \n\tgtcmaterialcontrol A, \n\tgtcmaterialhistory B \nWHERE \n\tA.controlnumber = B.controlnumber AND \n\tA.category = 'SA' AND \n\tA.level = '4' AND \n\tB.fieldid = '773' AND \n\tB.subfieldid = 'w' AND \n\tB.data::date BETWEEN '$beginDate' AND '$endDate' AND \n\tB.chancestype = 'I' \nGROUP BY 1, 2 \nUNION \nSELECT \n\t'Kardex', \n\toperator, \n\tCOUNT(*) \nFROM \n\tgtcmaterialhistory \nWHERE \n\tfieldid = '960' AND \n\tsubfieldid = 'a' AND \n\tdata::date BETWEEN '$beginDate' AND '$endDate' AND \n\tchancestype = 'I' \nGROUP BY 1, 2 \nUNION \nSELECT \n\t'Coleções', \n\tB.operator, \n\tCOUNT(*) \nFROM \n\tgtcmaterialcontrol A, \n\tgtcmaterialhistory B \nWHERE \n\tA.controlnumber = B.controlnumber AND \n\tA.category = 'SE' AND \n\tA.level = '#' AND \n\tB.fieldid = '245' AND \n\tB.subfieldid = 'a' AND \n\tB.data::date BETWEEN '$beginDate' AND '$endDate' AND \n\tB.chancestype = 'I' \nGROUP BY 1, 2  \nORDER BY 1, 2;	\N	\N	\N	t	ACV
35	Estatística - Empréstimos Por Turno	Gera a quantidade de empréstimos + renovações locais por turno.<BR>\nPara seu correto funcionamento, deve ser selecionado 1 dia de cada vez.<BR>\n* Manhã: entre 0 e 12 horas<BR>\n* Tarde: entre 12 e 18 horas<BR>\n* Noite: entre 18 e 24 horas	basic	SELECT \n'1-Manhã' AS "Turno", \n        count(distinct loanId) + (SELECT COUNT(DISTINCT B.renewId) \n    FROM gtcLoan A, gtcRenew B \n        WHERE A.loanId = B.loanId \n        AND B.renewdate BETWEEN '$beginDate 00:00:00' AND '$endDate 12:00:00' \n        AND CASE WHEN $libraryUnitId = 0\n          THEN 1                     = 1\n          ELSE libraryUnitId         = $libraryUnitId\n          END \n        AND B.renewtypeid = 1 ) \n        AS "Quantidade" \n    FROM gtcLoan \n        WHERE loanDate BETWEEN '$beginDate 00:00:00' AND '$endDate 12:00:00' \n        AND CASE WHEN $libraryUnitId = 0\n          THEN 1                     = 1\n          ELSE libraryUnitId         = $libraryUnitId\n          END \nUNION SELECT \n'2-Tarde' AS "Turno", \n        count(distinct loanId) + (SELECT COUNT(DISTINCT B.renewId) \n    FROM gtcLoan A, gtcRenew B \n        WHERE A.loanId = B.loanId \n        AND B.renewdate BETWEEN '$beginDate 12:00:00' AND '$endDate 18:00:00' \n        AND CASE WHEN $libraryUnitId = 0\n          THEN 1                     = 1\n          ELSE libraryUnitId         = $libraryUnitId\n          END \n        AND B.renewtypeid = 1 ) \n            AS "Quantidade" \n    FROM gtcLoan \n        WHERE loanDate BETWEEN '$beginDate 12:00:00' AND '$endDate 18:00:00' \n        AND CASE WHEN $libraryUnitId = 0\n          THEN 1                     = 1\n          ELSE libraryUnitId         = $libraryUnitId\n          END \nUNION SELECT \n'3-Noite' AS "Turno", \n        count(distinct loanId) + (SELECT COUNT(DISTINCT B.renewId) \n    FROM gtcLoan A, gtcRenew B \n        WHERE A.loanId = B.loanId \n        AND B.renewdate BETWEEN '$beginDate 18:00:00' AND '$endDate 00:00:00' \n        AND CASE WHEN $libraryUnitId = 0\n          THEN 1                     = 1\n          ELSE libraryUnitId         = $libraryUnitId\n          END \n        AND B.renewtypeid = 1 ) \n            AS "Quantidade" \n    FROM gtcLoan \n        WHERE loanDate BETWEEN '$beginDate 18:00:00' AND '$endDate 00:00:00' \n        AND CASE WHEN $libraryUnitId = 0\n          THEN 1                     = 1\n          ELSE libraryUnitId         = $libraryUnitId\n          END \nORDER BY 1;	\N	\N	\N	t	EMP
36	Estatística - Materiais Processados por Mês	Gera uma lista com a quantidade de materiais (exemplares, artigos e obras) cadastrados em determinado período para a primeira biblioteca do sistema.<BR>\nA geração deste relatório pode ser demorada.	basic	SELECT \n\t'1-Exemplares', \n\tCOUNT(*) AS "Quantidade" \nFROM \n\tgtcexemplarycontrol \nWHERE \n\tentrancedate::date BETWEEN '$beginDate' AND '$endDate'\nUNION \nSELECT \n\t'2-Artigos',\n\tCOUNT(*) AS "Quantidade" \nFROM \n\tgtcmaterialcontrol \nWHERE \n\tentrancedate::date BETWEEN '$beginDate' AND '$endDate' AND \n\tcategory = 'SA' AND \n\tlevel = '4' \nUNION \nSELECT \n\t'3-Obras', \n\tCOUNT(*) AS "Quantidade" \nFROM \n\tgtcmaterialcontrol \nWHERE \n\tentrancedate::date BETWEEN '$beginDate' AND '$endDate' ORDER BY 1;	\N	\N	\N	t	ACV
37	Obras mais retiradas	Lista o título das obras mais retiradas num determinado período.<BR>\nPara não demorar muito a geração do relatório, foi incluído um limite de itens na listagem.	intermediary	SELECT \n\tc.controlNumber as "Número de controle", c.content as "Título", count(distinct a.loanId) as "Quantidade de empréstimos" \nFROM \tgtcLoan a, \n\tgtcExemplaryControl b, \n\tgtcMaterial c \nWHERE \ta.itemNumber = b.itemNumber AND \n\tb.controlNumber = c.controlNumber AND \n\ta.loanDate::date >= '$beginDate' AND \n\ta.loanDate::date <= '$endDate' AND \n\t(c.fieldId = '245' and c.subfieldId = 'a') \n\tAND CASE WHEN $libraryUnitId = 0 THEN 1 = 1 ELSE a.libraryUnitId = $libraryUnitId END \nGROUP BY c.controlNumber, \n\tc.content ORDER BY 3 desc limit $limit	\N	\N	\N	t	EMP
6	Obras mais reservadas	Lista o título das obras mais reservadas num determinado período.<BR>\nPara não demorar muito a geração do relatório, foi incluído um limite de itens na listagem.	intermediary	  SELECT d.controlNumber as "Número de controle", d.content as "Título", \n         count(distinct b.reserveId) as "Quantidade de reservas" \n    FROM gtcReserve            a, \n         gtcReserveComposition b, \n         gtcExemplaryControl   c, \n         gtcMaterial           d \n   WHERE a.reserveId              = b.reserveId \n     AND b.itemNumber             = c.itemNumber \n     AND c.controlNumber          = d.controlNumber \n     AND a.requestedDate::date    >= '$beginDate'\n     AND a.requestedDate::date    <= '$endDate' \n     AND (d.fieldId = '245' and d.subfieldId = 'a') \n     AND CASE WHEN $libraryUnitId = 0\n           THEN 1                 = 1\n           ELSE a.libraryUnitId   = $libraryUnitId\n           END\nGROUP BY d.controlNumber, d.content \nORDER BY 3 desc limit $limit	\N	\N	\N	t	RES
38	Gerenciamento de Dicionários	Relatório de gerenciamento de dicionário visa detectar quais informações estão faltando ou sobrando em um dicionario, facilitando suas manutenção.\n<br/>\n<b>Sobrando:</b> quer dizer que o dado está sobrando no dicionário, ou seja nunca foi usado em nenhum material.\n<br/>\n<b>Faltando:</b> significa que o conteúdo foi utilizado em algum material, mas não foi adicionado ao dicionário.	intermediary	SELECT '''' || content || '''' as "Conteúdo", 'Faltando' as "Tipo" FROM (\nSELECT distinct content\nFROM\n(\n    SELECT substring(subTag, 0, position('.' in subTag)) as field,\n           substring(subTag, position('.' in subTag)+1) as subfield\n      FROM regexp_split_to_table( (\n                SELECT tags\n                  FROM gtcDictionary where dictionaryid =$dictionaryId ) , ',' ) AS subTag )\n        AS tags\nINNER JOIN gtcMaterial M ON (tags.field = M.fieldid AND tags.subfield = M.subfieldID )\n\nEXCEPT\n\nSELECT dictionaryContent FROM gtcDictionaryContent where dictionaryId = $dictionaryId\n\n) as faltando\n\nUNION\n\nSELECT '''' || dictionaryContent || '''' as "Conteúdo", 'Sobrando' as "Tipo" FROM (\n\nSELECT dictionaryContent FROM gtcDictionaryContent where dictionaryId = $dictionaryId\n\nEXCEPT\n\nSELECT distinct content\nFROM\n(\n    SELECT substring(subTag, 0, position('.' in subTag)) as field,\n           substring(subTag, position('.' in subTag)+1) as subfield\n      FROM regexp_split_to_table( (\n                SELECT tags\n                  FROM gtcDictionary where dictionaryid =$dictionaryId ) , ',' ) AS subTag )\n        AS tags\nINNER JOIN gtcMaterial M ON (tags.field = M.fieldid AND tags.subfield = M.subfieldID )\n\n) as sobrando\n	\N	\N	\N	t	ACV
39	Lista de Material por classificação	Este relatório mostra todos os materiais de uma determinada área de conhecimento escolhida pela sua classificação, resultando em uma listagem de materiais com suas respectivas quantidades de exemplares.\n<br><br>\n<b>Exemplos de preenchimento do campo "Classificação":</b> <br>\n<table align=center>\n<tr align=left>\n<td align=left>\n<b>51</b> - Pesquisa pela classificação <b>51</b>\n</td>\n</tr>\n<tr align=left>\n<td>\n<b>52,63</b> - Pesquisa pelas classificações <b>52</b> e <b>63</b>\n</tr>\n</td>\n<tr align=left>\n<td>\n<b>5%</b> - Pesquisa pelas classificações que <b>começam</b> com <b>5</b>\n</tr>\n</td>\n<tr align=left>\n<td>\n<b>5%,7%</b> - Pesquisa pelas classificações que <b>começam</b> com <b>5</b> e <b>7</b>\n</tr>\n</td>\n</table>\n\n<br>\nÉ necessário que o campo 090.a (Número de Classificação) na catalogação esteja preenchido.	basic	\N	\N	class FrmCustomReport extends FrmAdminReport \n{ \n    private $busGenericSearch, $busSearchFormat;\n\n    function __construct() \n    { \n//        ini_set('max_execution_time',300);\n        parent::__construct(); \n    } \n\n    public function getGrid() \n    { \n\n        $data = $this->getReportData(); \n        $args = (object) ( $_REQUEST ); \n        $sql = $data->reportSql; \n        \n        $columns[]= 'Número de controle'; \n        $columns[]= 'Classificação'; \n        $columns[]= 'Título';\n        $columns[]= 'Autor';\n        $columns[]= 'Quantidade de exemplares'; \n\n        if ( $columns ) \n        { \n            foreach ( $columns as $line => $info ) \n            { \n                $gridColumns[] = new MGridColumn( $info, MGrid::ALIGN_LEFT, null, null, true, null, true); \n            } \n        } \n\n        $grid = new GnutecaGrid(null, $gridColumns, $this->MIOLO->getCurrentURL(), LISTING_NREGS); \n\n        if ( MIOLO::_REQUEST('reportType') == 'detail' ) \n        { \n            $gridArgs['0'] = '%0%'; \n            $gridArgs['event'] = 'showDetail'; \n            $hrefDetail = $this->MIOLO->getActionURL($this->module, $this->action, null, $gridArgs); \n            $grid->addActionIcon( _M('Details', $this->module), 'select', $hrefDetail ); \n            unset( $subSql ); \n        } \n\n        $classificacoes = explode(",",$args->classificacao);\n\n        $filtroClassificacao = " AND (content LIKE '". implode("' OR content LIKE '",$classificacoes)."')";\n\n\n        $where = "";\n        if ( $args->dataInicial )\n        {\n            $where .= " AND MC.entranceDate >= '{$args->dataInicial}' ";\n        }\n        if ( $args->dataFinal )\n        {\n            $where .= " AND MC.entranceDate <= '{$args->dataFinal}' ";\n        }\n        if( $args->libraryUnitId > 0 )\n        {\n            $where .= " AND EC.libraryUnitId = '{$args->libraryUnitId}'"; \n        }\n\n        if ( $where )\n        {\n            $where = " WHERE ". substr($where,4,strlen($where));\n        }\n        \n        $ordem = $args->ordem;\n        if ( $ordem != '2' )\n        {\n            $ordenacao = " ORDER BY $ordem";\n        }\n        else\n        {\n            $ordenacao = " ORDER BY split_part(M.content, '@', 1),\n                                    split_part(M.content, '@', 2) ";\n        }\n\n        $sql = "    SELECT MC.controlnumber, \n                           M.content,\n                           (SELECT content FROM gtcMaterial WHERE fieldid = '245' AND subfieldid = 'a' AND controlNumber = MC.controlNumber) as \\"Título\\",\n                           (SELECT content FROM gtcMaterial WHERE fieldid = '100' AND subfieldid = 'a' AND controlNumber = MC.controlNumber) as \\"Autor\\", \n                           count(EC.itemNumber) as \\"Quantidade de exemplares\\"\n                      FROM gtcmaterialcontrol MC\n                INNER JOIN gtcmaterial M ON (MC.controlnumber = M.controlnumber AND fieldId = '090' and subfieldid = 'a' $filtroClassificacao )\n                INNER JOIN gtcexemplarycontrol EC ON (EC.controlnumber = MC.controlnumber) \n\n                           $where\n                  GROUP BY 1,2 \n                  {$ordenacao}"; \n        clog($sql);\n//AND ($filtroClassificacao )\n        $result = $this->business->executeSelect( $sql , $subSql, $args); \n        $grid->setData( $result );\n        $grid->setRowMethod($this, 'checkValues');\n        $grid->setIsScrollable(); \n        \n        return $grid; \n    } \n\n/*    public function checkValues($i, $row, $actions, $columns)\n    {\n        $this->busGenericSearch = $this->MIOLO->getBusiness($this->module, 'BusGenericSearch2');\n        $this->busSearchFormat   = $this->MIOLO->getBusiness($this->module, 'BusSearchFormat');\n\n        $fieldsList        = $this->busSearchFormat->getVariablesFromSearchFormat(1);\n        if ( is_array( $fieldsList ) )\n        {\n            foreach ( $fieldsList as $line => $info )\n            {\n                $tag = str_replace('$','', $info);\n                $this->busGenericSearch->addSearchTagField($tag);\n            }\n        }\n\n        $this->busGenericSearch->addControlNumber($row[0]);\n\n        $data = $this->busGenericSearch->getWorkSearch();\n\n        $columns[1]->control[$i]->setValue($this->busSearchFormat->formatSearchData(1, $data[0]));\n\n    }*/\n\n    public function getPDF()\n    {\n        $data   = $this->getReportData();\n        $args   = (object) ( $_REQUEST );\n\n        \n        $columns[]= 'Número de controle'; \n        $columns[]= 'Conteúdo'; \n        $columns[]= 'Quantidade de exemplares'; \n\n        $classificacoes = explode(",",$args->classificacao);\n\n        foreach ( $classificacoes as $classificacao )\n        {\n            $filtroClassificacao .= " OR content LIKE '$classificacao' ";\n        }\n        $sql = "    SELECT MC.controlnumber, M.content, count(EC.itemNumber) as \\"Quantidade de exemplares\\"\n                      FROM gtcmaterialcontrol MC\n                INNER JOIN gtcmaterial M ON (MC.controlnumber = M.controlnumber AND fieldId = '090' and subfieldid = 'a' AND ($filtroClassificacao ) )\n                INNER JOIN gtcexemplarycontrol EC ON (EC.controlnumber = MC.controlnumber) \n                     WHERE MC.entranceDate BETWEEN '{$args->dataInicial}'\n                       AND '{$args->dataFinal}'\n                       AND EC.libraryUnitId = '{$args->libraryUnitId}'\n                  GROUP BY 1,2 "; \n        $result = $this->business->executeSelect( $sql , $subSql, $args);\n\n\n        $orientation = $args->pageOrientation ? $args->pageOrientation : 'P';\n\n        if ($result && $columns)\n        {\n            $pdf = new GnutecaPDFTable( $orientation, 'pt');\n            $pdf->addTable( new MTableRaw($data->Title, $result, $columns) );\n\n            $output = $pdf->Output(null, 'S');\n        }\n\n        return $output;\n    }\n\n}	\N	t	MAT
40	Lista ordenada para inventário	Este relatório lista todos os exemplares da unidade de biblioteca selecionada de forma ordenada para a realização do \ninventário.\n\n<br><br>\n<b>Exemplos de preenchimento do campo "Classificação":</b> <br>\n<table align=center>\n<tr align=left>\n<td align=left>\n<b>51</b> - Pesquisa pela classificação <b>51</b>\n</td>\n</tr>\n<tr align=left>\n<td>\n<b>5%</b> - Pesquisa pelas classificações que <b>começam</b> com <b>5</b>\n</tr>\n</td>\n</table>\n\n<br>\nÉ necessário que o campo 090.a (Número de Classificação) na catalogação esteja preenchido.	basic	                    SELECT MC.controlnumber as "Número de controle", \n                           M.content as "Chamada",\n                           (SELECT content FROM gtcMaterial WHERE fieldid = '090' AND subfieldid = 'b' AND controlNumber = MC.controlNumber) as "Cutter",\n                           EC.itemNumber as "Exemplar",\n                           ES.description as "Estado do exemplar" \n                      FROM gtcMaterialControl MC\n                INNER JOIN gtcMaterial M ON (MC.controlnumber = M.controlnumber AND fieldId = '090' and subfieldid = 'a' AND ( content LIKE '$classification' ) ) --Filtro de classificação, um por vez, sem explode.\n                INNER JOIN gtcExemplaryControl EC ON (EC.controlnumber = MC.controlnumber) \n                 LEFT JOIN gtcExemplaryStatus ES ON (ES.exemplaryStatusID = EC.exemplaryStatusId)\n                     WHERE EC.libraryUnitId = '$libraryUnitId' -- um filtro por unidade, ou seja, sem a opção "Todas" \n                  ORDER BY split_part(M.searchContent, '@', 1),\n                           split_part(M.searchContent, '@', 2),\n                           MC.controlnumber\n	\N	\N	\N	t	MAT
MATERIAL_EVALUATION	Avaliações de Material	Este relatÃ³rio disponibiliza totais sobre quantidades, média e pontuações quanto a avaliações efetuadas por pesquisadores/usuáios/alunos. é importante considerar que todas avaliaçõees nulas ou zeradas são desconsideradas.	basic	   SELECT e.controlNumber as "Número de controle",\n          m.content as Autor, t.content as "Título" ,\n          count(evaluatioN) as "Quant." ,\n          round(avg(evaluation),2) as "Média",\n          count(evaluation) * sum(evaluation) as "Pontuação"\n     FROM gtcmaterialevaluation e\nLEFT JOIN gtcMaterial m ON ( e.controlNumber = m.controlNumber and fieldid = '100' and subfieldid='a' )\nLEFT JOIN gtcMaterial t ON ( e.controlNumber = t.controlNumber and t.fieldid = '245' and t.subfieldid='a' )\n    WHERE e.controlNumber in ( SELECT controlNumber FROM gtcExemplaryControl ex WHERE CASE WHEN $libraryUnitId::varchar = '0' THEN true ELSE libraryUNitId = $libraryUnitId END )\n      AND ( evaluation > 0 or evaluation is not null )\n GROUP BY e.controlNumber , m.content, t.content\n ORDER BY $order $type\n    LIMIT $limit;\n	\N	\N	\N	t	ACV
41	Estatística - Gênero Material	\N	basic	SELECT \n\tA.materialgenderid as "Id", \n\tB.description as "Descrição", \n        count(distinct controlnumber) as "Quantidade de obras",\n\tcount(itemnumber) as "Quantidade Exemplares"\n\nFROM \n\tgtcexemplarycontrol A \n\nINNER JOIN \n\tgtcmaterialgender B \n\tON \n\t\t(A.materialgenderid = B.materialgenderid) \n\nWHERE (A.libraryUnitId = $libraryUnitId OR 0 = $libraryUnitId)\n\n\tGroup by 1, 2;	\N	\N	\N	t	ACV
MULTAS_PERIODO	Multas por período	Retorna quantia das multas no período especificado.	basic	SELECT\n    loanid as "Código do empréstimo",\n    fineid as "Código da multa",\n    to_char(beginDate,'dd/mm/yyyy hh24:MI:SS') as "Data inicial",\n    to_char(enddate,'dd/mm/yyyy hh24:MI:SS') as "Data final" ,\n    libraryname as "Unidade",\n    operador as "Operador",\n    description as "Estado do empréstimo",\n    value as "Valor"\nFROM\n(\n    SELECT\n        f.loanid,\n        F.fineid,\n        f.begindate,\n        f.enddate ,\n        U.libraryname,\n        (SELECT operator FROM gtcfinestatushistory H WHERE H.fineid = F.fineid AND H.date = (SELECT max(date) from gtcfinestatushistory WHERE fineid = F.fineid) ) as "operador",\n        s.description ,\n        F.value ,\n        F.finestatusid\n    FROM     gtcfine as F\n        INNER JOIN gtcfinestatus as S  ON F.finestatusid = S.finestatusid\n        INNER JOIN gtcloan L  ON L.loanid = F.loanid\n        INNER JOIN gtclibraryunit U  ON L.libraryunitid = U.libraryunitid\n\n        AND CASE WHEN $unityId > 0\n        THEN  L.libraryunitid = $unityId\n        ELSE 1=1\n        END\n        AND CASE WHEN $status > 0\n        THEN  F.finestatusid = $status\n        ELSE 1=1\n        END\n) as AA\n\nWHERE\n\nbeginDate > '$beginDate'\nAND endDate < '$finalDate'\nAND CASE WHEN '$operator' = 'Todos' THEN  1=1\nELSE operador = '$operator'\nEND\n\n-- operador = '$operator'	\N	\N	\N	t	EMP
ACTIVE_PERSON	Pessoas ativas	\N	basic	    SELECT A.personId as "Código",\n           A.name as "Nome",\n           C.description as "Vínculo",\n           to_char(B.dateValidate, 'dd/mm/yyyy') as "Data de validade"\n      FROM basPerson A\nINNER JOIN basPersonLink B\n        ON (A.personId = B.personid)\nINNER JOIN basLink C\n        ON (B.linkId = C.linkId)\n     WHERE B.dateValidate >= now()::date\n       AND CASE WHEN $linkId = 0 THEN 1=1\n      ELSE B.linkId = $linkId\n       END\n     ORDER BY A.name\n	\N	\N	\N	t	PRS
LOAN_BY_TYPE	Quantidade de empréstimos por tipo	Mostra quais os tipos de materiais mais emprestados em um determinado período em ordem decrescente de quantidade de empréstimos o campo. O campo tipo do material 949.a deve estar preenchido para que o material conste neste relatório.	basic	    SELECT C.materialTypeId as "Código",\n           C.description as "Tipo do material",\n           count(*) as "Quantidade de empréstimos"\n      FROM gtcLoan A\nINNER JOIN gtcExemplaryControl B\n        ON (A.itemNumber = B.itemNumber)\nINNER JOIN gtcMaterialType C\n        ON (B.materialTypeId = C.materialTypeId)\n     WHERE A.loanDate between '$beginDate'::TIMESTAMP and '$finalDate'::TIMESTAMP\n       AND CASE WHEN $materialTypeId = 0 THEN 1=1\n           ELSE B.materialTypeId = $materialTypeId\n           END\n       AND CASE WHEN $libraryUnitId = 0 THEN 1=1\n           ELSE B.libraryUnitId = $libraryUnitId\n           END\n  GROUP BY 1, 2\n  ORDER BY 3 DESC;\n	\N	\N	\N	t	EMP
MOST_BORROWED	Materiais mais retirados	Exibe quais os materiais mais retirados da biblioteca mostrando número de controle, título e quantidade de empréstimos em ordem decrescente de quantidade de empréstimos. O campo tipo do material 949.a deve estar preenchido para que o material conste neste relatório.	basic	    SELECT C.controlNumber as "Número de controle",\n           C.content as Título,\n           count(*) as "Quantidade de empréstimos"\n      FROM gtcLoan A\nINNER JOIN gtcExemplaryControl B\n        ON (A.itemNumber = B.itemNumber)\nINNER JOIN gtcMaterial C\n        ON (B.controlNumber = C.controlNumber AND C.fieldId = '245' AND C.subfieldId = 'a')\n     WHERE A.loanDate between '$beginDate'::timestamp and '$finalDate'::timestamp\n       AND CASE WHEN $materialTypeId = 0 THEN 1=1\n           ELSE B.materialTypeId = $materialTypeId\n           END\n       AND CASE WHEN $libraryUnitId = 0 THEN 1=1\n           ELSE B.libraryUnitId = $libraryUnitId\n           END\n  GROUP BY 1, 2\n  ORDER BY 3 DESC;\n	\N	\N	\N	t	EMP
LOAN_BY_ENTERPRISE	Empréstimos por empresa	Exibe quantidade de empréstimos por empresa em ordem decrescente.	basic	    SELECT D.label as Empresa,\n           count(*) as "Quantidade de empréstimos"\n      FROM gtcLoan A\nINNER JOIN basPerson B\n        ON (A.personId = B.personId)\nINNER JOIN gtcExemplaryControl C\n        ON (C.itemNumber = A.itemNumber)\n LEFT JOIN gtcDomain D\n        ON (D.domainid = 'PERSON_GROUP' AND key = B.personGroup)\n     WHERE A.loanDate between '$beginDate'::TIMESTAMP and '$finalDate'::TIMESTAMP\n       AND CASE WHEN $libraryUnitId = 0 THEN 1=1\n           ELSE C.libraryUnitId = $libraryUnitId\n           END\n  GROUP BY 1\n  ORDER BY 2 DESC;\n	\N	\N	\N	t	EMP
LOAN_BY_PERSON	Empréstimos por pessoa	Exibe quantidade de empréstimos por usuário em ordem decrescente por quantidade de empréstimo.	basic	    SELECT B.personId as "Código",\n           B.name as "Nome",\n           count(*) as "Quantidade de empréstimos"\n      FROM gtcLoan A\nINNER JOIN basPerson B\n        ON (A.personId = B.personId)\nINNER JOIN gtcExemplaryControl C\n        ON (C.itemNumber = A.itemNumber)\n     WHERE A.loanDate between '$beginDate'::TIMESTAMP and '$finalDate'::TIMESTAMP\n       AND CASE WHEN $libraryUnitId = 0 THEN 1=1\n           ELSE C.libraryUnitId = $libraryUnitId\n           END\n  GROUP BY 1, 2\n  ORDER BY 3 DESC;\n	\N	\N	\N	t	EMP
MATERIAL_TYPE_STATIS	Estatística - Tipo de material	Exibe a quantidade de materiais e exemplares de um determinado tipo de material ordenando em ordem decrescente pela quantidade de materiais e exemplares. Para que o material conste neste relatório o campo 901.a deve estar preenchido.	basic	    SELECT A.materialTypeId as "Id",\n           A.description as "Tipo",\n           (SELECT count(distinct A1.controlnumber) FROM gtcMaterialControl A1 LEFT JOIN gtcExemplaryControl B1 ON (A1.controlNumber = B1.controlNumber)  WHERE A1.materialTypeId = A.materialTypeId AND CASE WHEN $libraryUnitId = 0 THEN 1=1 ELSE libraryUnitId = $libraryUnitId END) as "Obras",\n           (SELECT count(materialTypeId) FROM gtcExemplaryControl WHERE materialTypeId = A.materialTypeId AND CASE WHEN $libraryUnitId = 0 THEN 1=1 ELSE libraryUnitId = $libraryUnitId END) as "Exemplares"\n      FROM gtcMaterialType A\n      WHERE CASE WHEN $materialTypeId = 0 THEN 1=1\n                 ELSE A.materialTypeId = $materialTypeId\n            END\norder by 3 desc, 4 desc\n	\N	\N	\N	t	ACV
INVENTARY	Inventário	Exibe todos os exemplares existentes dentro dos filtros de "Classificação" e "Unidade de biblioteca", estes sendo estes ordenados pelo campo "Ordenar por".\n\nPara que os exemplares constem neste relatório os seguintes campos devem ser preenchidos :\n\n<b>090.a, 100.a, 245.a</b>	basic	    SELECT A.controlnumber as "Número de controle",\n           A.content as "Classificação",\n           D.content as "Título",\n           E.content as "Autor",\n           B.itemNumber as "Exemplar",\n           B.exemplaryStatusId || ' - ' || C.description as "Estado"\n\n      FROM gtcMaterial A\nINNER JOIN gtcExemplaryControl B\n        ON (A.controlNumber = B.controlNumber)\nINNER JOIN gtcExemplaryStatus C\n        ON (B.exemplaryStatusId = C.exemplaryStatusId)\n LEFT JOIN gtcMaterial D\n        ON (A.controlNumber = D.controlNumber AND D.fieldid = '245' AND D.subfieldid = 'a')\n LEFT JOIN gtcMaterial E\n        ON (A.controlNumber = E.controlNumber AND E.fieldid = '100' AND E.subfieldid = 'a')\n\nwhere A.fieldid = '090' and A.subfieldid = 'a'\n\nAND CASE WHEN $libraryUnitId = 0 THEN 1=1\n         ELSE B.libraryUnitId = $libraryUnitId\n    END\nand split_part(A.searchcontent, '@', 1) between '<executephp> GnutecaUtils::prepareSearchContent('090.a','$beginClassification') </executephp>' and '<executephp> GnutecaUtils::prepareSearchContent('090.a','$finalClassification') </executephp>'\n\nORDER BY $orderBy.searchcontent;\n	\N	\N	\N	t	ACV
MOST_BORROWED_SUB	Assuntos mais retirados.	Exibe quais os assuntos dos materiais mais retirados em ordem decrescente de quantidade. Para que os empréstimos sejam contabilizados é necessário que o campo <b>650.a</b> seja preenchido.	basic	    SELECT C.content as Assunto,\n           count(*) as "Quantidade de empréstimos"\n      FROM gtcLoan A\nINNER JOIN gtcExemplaryControl B\n        ON (A.itemNumber = B.itemNumber)\nINNER JOIN gtcMaterial C\n        ON (B.controlNumber = C.controlNumber AND C.fieldId = '650' AND C.subfieldId = 'a')\n     WHERE A.loanDate between '$beginDate' and '$endDate'\n       AND CASE WHEN $libraryUnitId = 0 THEN 1=1\n                ELSE B.libraryUnitId = $libraryUnitId\n           END\n  GROUP BY 1\n  ORDER BY 2 DESC;\n	\N	\N	\N	t	EMP
NEXT_ITEMNUMBER	Próximo número de exemplar/tombo.	Obtém o próximo número de exemplar/tombo, este relatório é utilizado dentro da catalogação, modificando ele, a catalogação preencherá os dados de forma diferenciada.	basic	--Sugere o número do tombo. Pega o último e soma 1. Isso pode duplicar números caso exista mais de um catalogador\n--Sugere o número do tombo. Pega o último e soma 1. Isso pode duplicar números caso exista mais de um catalogador\n--SELECT lpad( (max(myItemNumber::bigint)+1)::varchar,8,'0') as itemNumber  FROM ( SELECT regexp_replace( upper(itemnumber),'.*[A-z]','') as myItemNumber FROM gtcexemplarycontrol WHERE itemNumber <> '' AND itemNumber is not null ) AS f WHERE ascii(myItemNumber) <> 0 ORDER BY  1 DESC;\n\n--Busca o número por sequência. Isso garante que nenhum usuário irá utilizar o mesmo código\nCREATE OR REPLACE FUNCTION fnc_nextItemNumber ( libraryUnitId gtcLibraryUnit.libraryUnitId%TYPE )\nRETURNS integer AS $$\nDECLARE\n    codigo integer;\n    v_query varchar;\n    ultimo_codigo integer;\nBEGIN\n    SELECT INTO ultimo_codigo CASE WHEN max(myItemNumber::bigint) IS NULL THEN 1 ELSE max(myItemNumber::bigint) END  as itemNumber  FROM ( SELECT regexp_replace( upper(itemnumber),'.*[A-z]','') as myItemNumber FROM gtcexemplarycontrol WHERE itemNumber <> '' AND itemNumber is not null ) AS f WHERE ascii(myItemNumber) <> 0 ORDER BY 1 DESC;\n\n    -- Verifica se existe sequencia e pega o nextval, caso nao exista ainda, cria\n    BEGIN\n        codigo := nextval('seq_rptItemNumber');\n    EXCEPTION\n        WHEN OTHERS THEN\n            -- cai no erro se a sequencia ainda nao existir\n            v_query := 'CREATE SEQUENCE seq_rptItemNumber START ' || ultimo_codigo ;\n            EXECUTE v_query;\n            codigo := nextval('seq_rptItemNumber');\n    END;\n\n    IF (ultimo_codigo > codigo) THEN\n        PERFORM setval('seq_rptItemNumber', ultimo_codigo);\n        codigo := nextval('seq_rptItemNumber');\n    END IF;\n\n    RETURN codigo;\nEND;\n$$ language 'plpgsql';\n\nSELECT lpad(fnc_nextItemNumber($libraryUnitId)::varchar,8,'0');\n	\N	\N	\N	t	\N
TOTAL_ACQUISITION	Totalização de tipo de aquisição	Este relatório lista a totalização de exemplares por tipos de aquisição por período e unidade. Utiliza o campo 949.c como referência, caso esse campo não seja preenchido o material não será contabilizado.	basic	    SELECT o.description as "Tipo de aquisição",\n           count(controlNumber) as "Quantidade"\n      FROM gtcexemplarycontrol e\nINNER JOIN gtcmarctaglistingoption o\n        ON ( lower(e.acquisitiontype) = lower( o.option) and marctaglistingid = '949.c'  )\n       AND entrancedate >= '$beginDate'\n       AND entranceDate <= '$endDate' \n       AND CASE WHEN $libraryUnitId = 0 THEN 1=1\n                ELSE libraryUnitId = $libraryUnitId\n           END\n  GROUP BY acquisitiontype, o.description\n  ORDER BY 2 desc;	\N	\N	\N	t	ACV
LOAN_BY_ENT_SUB	Empréstimos por empresa/assuntos	Este relatório exibe a quantidade de empréstimos de materiais por assunto que uma empresa efetuou.\nPara que os materiais constem neste relatório o campo <b>650.a</b> deve estar preenchido.	basic	   SELECT B.personGroup as Empresa, \n           D.content as "Assunto", \n           count(*) as "Quantidade de empréstimos"\n      FROM gtcLoan A \nINNER JOIN basPerson B \n        ON (A.personId = B.personId) \nINNER JOIN gtcExemplaryControl C \n        ON (C.itemNumber = A.itemNumber) \nINNER JOIN gtcMaterial D\n        ON (C.controlNumber = D.controlNumber AND D.fieldId = '650' AND D.subfieldId = 'a') \n LEFT JOIN gtcDomain E\n        ON (E.domainid = 'PERSON_GROUP' AND key = B.personGroup)\n     WHERE A.loanDate between '$beginDate' and '$endDate' \n       AND CASE WHEN $libraryUnitId = 0 THEN 1=1 \n                ELSE C.libraryUnitId = $libraryUnitId \n           END \n       AND CASE WHEN '$personGroup' = '0' THEN 1=1 \n              ELSE B.personGroup = '$personGroup' \n           END \n  GROUP BY 1, 2 \n  ORDER BY 3 DESC; 	\N	\N	\N	t	EMP
TIPO_AQUISICAO_LISTA	Lista de tipos de aquisição	Lista os materiais pelo tipo de aquisição, para que o material seja contabilizado nesta listagem o campo <b>949.c</b> deste deve estar preenchido.	basic	SELECT \n\ta.itemnumber as "Numero do tombo", \n\ta.controlnumber as "Numero de controle", \n\tb.content as "Título",\n\tc.content as "Autor",\n\t(SELECT description FROM gtcmarctaglistingoption WHERE marctaglistingid = '949.c' and option = a.acquisitiontype) as "Tipo de aquisição",\n\tto_char(a.entrancedate,'DD/MM/YYYY') as "Data de entrada"\t\nFROM \n\tgtcexemplarycontrol as a,\n\tgtcmaterial as b,\n\tgtcmaterial as c\n\nWHERE\n\ta.controlnumber = c.controlnumber\n\tAND c.controlnumber = b.controlnumber\n\tAND b.fieldid = '245'\n\tAND b.subfieldid = 'a'\n\tAND c.fieldid = '100'\n\tAND c.subfieldid = 'a'\n\tAND CASE WHEN '$aquisitionType' = '0' THEN 1=1\n        ELSE a.acquisitiontype = '$aquisitionType'\n        END\n\tAND CASE WHEN  '$libraryUnitId' = '0' THEN 1=1\n        ELSE a.libraryunitid = '$libraryUnitId'\n        END\n\tAND a.entrancedate >= '$beginDate'\n\tAND a.entrancedate <= '$finalDate'\nORDER BY 6	\N	\N	\N	t	ACV
INSERIDO_PERIODO	Lista de materiais inseridos por período	Lista todos materiais inseridos dentro de um determinado período.\nPara que o material seja contabilizado corretamente será necessário o preenchimentos das etiquetas <b>950.a</b>,<b>90.a</b>,<b>245.a</b>	basic	SELECT \n        (SELECT distinct(content) from gtcmaterial where fieldid = '950' and subfieldid = 'a' and controlnumber = E.controlnumber limit 1) as Obra,\n        E.controlnumber as Controle,\n        E.itemnumber as Exemplar,\n        (SELECT content from gtcmaterial where fieldid = '245' and subfieldid = 'a' and controlnumber = E.controlnumber LIMIT 1) as Título,\n        (SELECT description FROM gtcexemplarystatus where exemplarystatusid = E.exemplarystatusid)  as Estado,\n        (SELECT distinct(content) from gtcmaterial where fieldid = '090' and subfieldid = 'a' and controlnumber = E.controlnumber limit 1) as Classificação\nFROM \n        gtcmaterialcontrol D \n        INNER JOIN gtcexemplarycontrol E ON (D.controlnumber = E.controlnumber) \n \nWHERE  \n        D.entrancedate::DATE BETWEEN '$beginDate' AND '$finalDate'\n        AND CASE WHEN '$materialGenderId' = '0' THEN 1=1\n        ELSE D.materialgenderid = '$materialGenderId'\n        END\n        AND CASE WHEN '$libraryUnitId' = 0 THEN 1=1\n        ELSE E.libraryunitid = '$libraryUnitId'\n        END\n	\N	\N	\N	t	ACV
LISTA_EXEMPLARES	Lista de exemplares	Este relatório lista exemplares da instituição por unidade de biblioteca, área de conhecimento, tipo físico do material, estado do exemplar e planilha.\nPara melhor visualização as etiquetas <b>245.a, 100.a, 901.b</b> devem estar preenchidas.\nCaso a planilha seja filtrada por SE.4, o autor não irá aparecer na listagem pois periódicos não tem autor.	basic	SELECT \n     A.controlnumber AS "Número de controle", \n     A.itemnumber AS "Número de obra" ,\n     b.content as "Título",\n     c.content as "Autor",\n     (E.category ||'.'|| E.level) as "Categoria",\n     ES.description as "Estado do exemplar",\n     MPT.description as "Tipo fisico do material",\n     MTLO.description as "Área de conhecimento"\nFROM \n     gtcexemplarycontrol A LEFT JOIN gtcmaterial B ON (A.controlnumber = B.controlnumber AND B.fieldid = '245' AND B.subfieldid = 'a')\n     LEFT JOIN gtcmaterial C ON (C.controlnumber = A.controlnumber AND C.fieldid = '100' AND C.subfieldid = 'a')\n     LEFT JOIN gtcmaterial D ON (D.controlnumber = A.controlnumber AND D.fieldid = '901' AND D.subfieldid = 'b')\n     LEFT JOIN gtcmaterialcontrol E ON (E.controlnumber = A.controlnumber)\n     LEFT JOIN gtcmaterialphysicaltype MPT ON (MPT.materialphysicaltypeid = A.materialphysicaltypeid)\n     LEFT JOIN gtcexemplarystatus ES ON (ES.exemplarystatusid =  A.exemplarystatusid)\n     LEFT JOIN gtcmarctaglistingoption MTLO ON (MTLO.marctaglistingid = '901.b' AND MTLO.option = D.content)\n\nWHERE \n     -- Unidade de biblioteca   \n     CASE WHEN '$libraryUnitId' = '0' \n     THEN '1'='1'\n     ELSE A.libraryunitid = '$libraryUnitId'\n     END\n     -- Tipo fisico\n     AND CASE WHEN '$materialPhysicalTypeId' = '0'\n     THEN '1'='1'\n     ELSE A.materialphysicaltypeid = '$materialPhysicalTypeId'\n     END \n     -- Tipo do material (Livro ou Periodico)\n     -- Planilha\n     AND CASE WHEN '$spreadSheetId' = '0' \n     THEN '1'='1'\n     ELSE (E.category ||'.'|| E.level) = '$spreadSheetId'\n     END\n    \n     -- Estado do exemplar      \n     AND CASE WHEN '$exemplaryStatusId' = (SELECT max(exemplarystatusid)+1 FROM gtcexemplarystatus)\n     THEN '1'='1'\n     ELSE A.exemplarystatusid = '$exemplaryStatusId'\n     END\n\n     -- Area de conhecimento\n     AND CASE WHEN '$knowledgeAreaId' = '0' \n     THEN '1'='1'\n     ELSE D.content = '$knowledgeAreaId' \n     END\n\nORDER BY 1,2;	\N	\N	\N	t	ACV
OBRA_LISTA	Lista de todas obras	Lista todas obras por unidade e tipo de material.\nPara melhor visualização do relatório, as etiquetas abaixo devem estar preenchidas :\n<b>245.a,100.a,901.a</b>.	basic	SELECT \n    B.controlNumber as "Número de controle",\n    titulo.content as "Título",\n    autor.content as "Autor",\n    A.libraryName as "Unidade de biblioteca",\n    materialtype.description as "Tipo de material"\n FROM gtcLibraryUnit A\n    LEFT JOIN gtcExemplaryControl B ON (A.libraryUnitId = B.originalLibraryUnitId)\n    LEFT JOIN gtcmaterial titulo ON (B.controlnumber = titulo.controlnumber AND titulo.fieldid = '245' and titulo.subfieldid = 'a' )\n    LEFT JOIN gtcmaterial autor ON (B.controlnumber = autor.controlnumber AND autor.fieldid = '100' and titulo.subfieldid = 'a' )          \n    LEFT JOIN gtcmaterial tipo ON (B.controlnumber = tipo.controlnumber AND tipo.fieldid = '901' and tipo.subfieldid = 'a' )\n    LEFT JOIN gtcmaterialtype materialtype ON (tipo.content = materialtype.materialtypeid::varchar)          \nWHERE \n    CASE WHEN '$libraryUnitId' = 0 THEN 1 = 1 ELSE B.libraryUnitId = '$libraryUnitId' END\n    AND CASE WHEN '$materialTypeId' = 0 THEN 1 = 1 ELSE materialtype.materialtypeid = '$materialTypeId' END\nGROUP BY A.libraryname,B.controlnumber,titulo.content,autor.content,tipo.content,materialtype.description\nORDER BY 1;	\N	\N	\N	t	ACV
CLASSE_ANO	Lista de exemplares por ano e classificação	Este relatório mostra todos os exemplares por <b>ano</b> e <b>classificação</b>.\nSó serão mostrados corretamente os materiais em que o campo <b>260.c</b> estiver preenchido com o ano corretamente, apenas com quatro dígitos.\nA classificação pode ser filtrada com o caractere <b>%</b>, isso significa que caso seja feito um filtro pela classificação <b>"2%"</b>, todos exemplares que tiverem a etiqueta <b>090.a</b> com o conteúdo que comece com <b>2</b> irão ser listados, caso queira filtrar por todas classificações preencha o campo <b>Classificação</b> com <b>%</b> apenas.	basic	SELECT \n\tA.controlnumber as "Número de controle",\n\tE.itemnumber as "Exemplar",\n\tB.content as "Autor",\n\tC.content as "Título",\n\trpad(regexp_replace(A.content, '[^0-9]','', 'g'), 4, '0') as "Ano",\n\tD.content as "Classificação"\n\t\nFROM \n\tgtcmaterial A \n\tLEFT JOIN gtcmaterial B ON (B.controlnumber = A.controlnumber AND B.fieldid = '100' and B.subfieldid = 'a')\n\tLEFT JOIN gtcmaterial C ON (C.controlnumber = A.controlnumber AND C.fieldid = '245' and B.subfieldid = 'a')\n\tLEFT JOIN gtcmaterial D ON (D.controlnumber = A.controlnumber AND D.fieldid = '090' and D.subfieldid = 'a')\n\tLEFT JOIN gtcexemplarycontrol E ON (E.controlnumber = A.controlnumber)\nWHERE \n\tA.fieldid = '260' \n\tAND A.subfieldid = 'c' \n\tAND length(regexp_replace(A.content, '[^0-9]','', 'g')) > 0\n\t\n        AND CASE WHEN '$beginYear' = '0' THEN 1=1\n        ELSE regexp_replace(A.content, '[^0-9]','', 'g')::int >= '$beginYear'\n        END\n        AND CASE WHEN '$finalYear' = '0' THEN 1=1\n\tELSE regexp_replace(A.content, '[^0-9]','', 'g')::int <= '$finalYear'\n        END\n\t\n        AND CASE WHEN '$classification' = '%' THEN 1=1\n        ELSE D.content like '$classification'\n        END	\N	\N	\N	t	ACV
EXEMPLAR_CNPQ	Lista de exemplares por CNPQ	Este relatÃ³rio lista todos os exemplares ordenandos por CNPQ, nÃºmero do tombo e nÃºmero de controle.\n<br>\nPara que os exemplares dos materiais sejam listados neste relatÃ³rio os campos abaixo devem estar preenchidos na catalogaÃ§Ã£o :\n<ul>\n<li> 901.b - Ãrea de conhecimento </li>\n<li> 245.a - TÃ­tulo </li>\n<li> 100.a - Autor </li>\n<li> 949.1 - Tipo do material </li>\n<li> 949.b - Unidade  </li>\n</ul>	basic	SELECT \n\tA.controlnumber as "NÃºmero de controle",\n\tA.itemnumber as "NÃºmero do tombo",\n\tC.content as "TÃ­tulo",\n\tD.content as "Autor",\n\t(SELECT description FROM gtcmarctaglistingoption WHERE marctaglistingid = '901.b' and option = B.content) as "Ãrea de conhecimento",\n\tF.description as "Tipo do material",\n\tE.libraryname as "Unidade"\n\t\nFROM \tgtcexemplarycontrol A \n\tLEFT JOIN gtcmaterial B ON A.controlnumber = B.controlnumber \n\tLEFT JOIN gtcmaterial C ON A.controlnumber = C.controlnumber\n\tLEFT JOIN gtcmaterial D ON A.controlnumber = D.controlnumber\n\tLEFT JOIN gtclibraryunit E ON A.libraryunitid = E.libraryunitid\n\tLEFT JOIN gtcmaterialtype F ON A.materialtypeid = F.materialtypeid\nWHERE \n\tB.fieldid = '901' \n\tAND B.subfieldid = 'b' \n\t--AND B.content = '0'\n        AND CASE WHEN '$knowledgeAreaId' = '0' THEN 1=1\n                ELSE b.content = '$knowledgeAreaId'\n        END\t\n\n\tAND C.fieldid = '245' \n\tAND C.subfieldid = 'a'\t\n\tAND D.fieldid = '100' \n\tAND D.subfieldid = 'a'\n\t--AND A.libraryunitid = 0\n        AND CASE WHEN $libraryUnitId = 0 THEN 1=1\n                ELSE A.libraryUnitId = $libraryUnitId\n        END\n\t--AND A.materialtypeid = 0\n        AND CASE WHEN $materialTypeId = 0 THEN 1=1\n                ELSE A.materialTypeId = $materialTypeId\n        END\t\t\n\t\nORDER BY 5,2,1;\n\n	\N	\N	\N	t	ACV
ESTATATISTA_CNPQ	EstatÃ­stica - Exemplares por CNPQ	RelatÃ³rio que mostra a totalizaÃ§Ã£o de exemplares por Ã¡rea de conhecimento e unidade.\n<br>\nPara que os materiais e exemplares sejam incluÃ­dos corretamente neste relatÃ³rio os campos abaixo devem estar cadastrados :\n<ul>\n<li>\n901.b - Ãrea de conhecimento\n</li>\n<li>\n949.b - CÃ³digo da unidade\n</li>\n</ul>	basic	SELECT \tO.option as "CÃ³digo",\n\tO.description as "Ãrea de conhecimento",\n\tcount(EX.itemnumber) as "Quantidade de exemplares"\n\nFROM \tgtcexemplarycontrol EX\n\tLEFT JOIN gtcmaterial M ON M.controlnumber = EX.controlnumber AND M.fieldid = '901' and M.subfieldid = 'b'\n\tLEFT JOIN gtcmarctaglistingoption O ON O.option = M.content AND marctaglistingid = '901.b'\n\nWHERE\n        CASE WHEN $libraryUnitId = 0 THEN 1=1\n                ELSE EX.libraryUnitId = $libraryUnitId\n        END\n\t\nGROUP by O.description,O.option \nORDER BY 1\n	\N	\N	\N	t	ACV
ACCESS_FORM	Formulários mais/menos acessados	Lista os formulários mais ou menos acessados.	basic	SELECT menu as "Formulário", count(*) as "Acessos" FROM gtcAnalytics WHERE menu != '' AND action != 'main' GROUP BY menu ORDER BY 2 $orderby LIMIT $limit;	\N	\N	\N	t	ACS
CAPA_DVD	Capa de DVD	Imprime capa de DVD	basic	   SELECT e.itemNumber, \n          CASE WHEN m245b.content IS NULL THEN m245a.content ELSE m245a.content || ':' END as "245.a",\n          m245b.content as "245.b",\n          m090a.content as "090.a",\n          m090b.content as "090.b"\n     FROM gtcexemplarycontrol e\nLEFT JOIN gtcMaterial m245a \n       ON ( m245a.controlnumber = e.controlnumber and m245a.fieldid = '245' and m245a.subfieldid = 'a' )\nLEFT JOIN gtcMaterial m245b \n       ON ( m245b.controlnumber = e.controlnumber and m245b.fieldid = '245' and m245b.subfieldid = 'b' )\nLEFT JOIN gtcMaterial m090a\n       ON ( m090a.controlnumber = e.controlnumber and m090a.fieldid = '090' and m090a.subfieldid = 'a' )\nLEFT JOIN gtcMaterial m090b\n       ON ( m090b.controlnumber = e.controlnumber and m090b.fieldid = '090' and m090b.subfieldid = 'b' )\n    WHERE materialphysicaltypeid = 3 and e.itemNumber IN ($itemNumber);\n	\N	\N	\N	t	IMP
CAPA_CD	Capa de CD	Imprime capas de CD. Somente os materias com tipo físico CD são aceitos.	basic	SELECT e.itemNumber, m245a.content as "245.a", m949a.content as "949.a", m090a.content as "090.a", m090b.content as "090.b", m950a.content as "950.a"\nFROM gtcexemplarycontrol e\nLEFT JOIN gtcMaterial m245a ON ( m245a.controlnumber = e.controlnumber and m245a.fieldid = '245' and m245a.subfieldid = 'a' )\nLEFT JOIN gtcMaterial m949a ON ( m949a.controlnumber = e.controlnumber and m949a.fieldid = '949' and m949a.subfieldid = 'a' )\nLEFT JOIN gtcMaterial m090a ON ( m090a.controlnumber = e.controlnumber and m090a.fieldid = '090' and m090a.subfieldid = 'a' )\nLEFT JOIN gtcMaterial m090b ON ( m090b.controlnumber = e.controlnumber and m090b.fieldid = '090' and m090b.subfieldid = 'b' )\nLEFT JOIN gtcMaterial m950a ON ( m950a.controlnumber = e.controlnumber and m950a.fieldid = '950' and m950a.subfieldid = 'a' )\nWHERE materialphysicaltypeid = 2 and e.itemNumber IN ($itemNumber);\n	\N	\N	\N	t	IMP
SIMPLE_SEARCH_TEM	Conteúdo pesquisado	Lista os conteúdos pesquisados na pesquisa simples/avançada entre outros.	basic	SELECT CASE WHEN campo != '' THEN campo ELSE action END as campo, termo, quantidade\n  FROM (     SELECT trim( ( SELECT array_to_string(array_agg(description),' e ')\n               FROM ( SELECT trim( regexp_split_to_table( action, E'\\and') ) AS searchField  ) AS S\n          LEFT JOIN gtcsearchablefield\n                 ON ( s.searchField = gtcsearchablefield .field) ) ,action ) AS\n                  campo , action, event as Termo ,count(*) as Quantidade\n       FROM gtcanalytics\n      WHERE accesstype = 3\n   GROUP BY 1,2,3\n   ORDER BY 3 desc\n      LIMIT $limit ) as foo;\n	\N	\N	\N	t	ACS
CART_BIBLIOTECA	Carteirinha da biblioteca	Carteirinha da biblioteca	basic	\nSELECT personId as "personId", \n      name as "name", \n      L.description as "link", \n      dateValidate as "validate", \n      'person/' || personId || '.' as "image", \n      personId as "codebar" \n FROM ( SELECT P.personId,\n               P.name,\n               min( L.level),\n               L.linkid as activelink,\n               login,\n               PL.dateValidate\n          FROM basPerson P \n    INNER JOIN basPersonLink PL\n            ON P.personId = PL.personId \n    INNER JOIN basLink L\n            ON L.linkId = PL.linkId AND PL.dateValidate >= now()::date \n      GROUP BY 1,2,4,5,6 ORDER BY 1) as temp \nLEFT JOIN basLink L \n       ON activelink = L.linkId \n    WHERE CASE WHEN '$interval' = 'D' \n          THEN \n              CASE WHEN $personId IS NULL \n                  THEN 1 = 1 \n              ELSE \n                  personId IN ($personId) \n              END \n          ELSE \n              CASE WHEN ($beginPersonId IS NOT NULL) AND ($endPersonId IS NOT NULL) \n              THEN \n                  (personId BETWEEN $beginPersonId AND $endPersonId) \n              ELSE \n                  1 = 1 \n              END \n          END \n          AND CASE WHEN $linkId IS NOT NULL \n          THEN \n              linkId = $linkId \n          ELSE \n              1 = 1 \n          END	\N	$MIOLO->GetClass('gnuteca3', 'codabar');\nclass FrmCustomReport extends FrmAdminReport\n{\n    public function createFields() \n    { \n        $data = $this->getReportData( );\n       \n       //Descrição do relatório a ser mostrada no topo da tela \n       if ($data->description) \n       { \n           $fields[] = new MDiv('divDescription', $data->description, 'reportDescription');\n       } \n       \n        $opts = array();\n        $opts[] = array(_M('Contínuo', $this->module), 'C');\n        $opts[] = array(_M('Discreto', $this->module), 'D');\n        $fields[] = $interval = new GRadioButtonGroup('interval', _M('Tipo de intervalo', $this->module), $opts, 'D', null, MFormControl::LAYOUT_HORIZONTAL);\n        $interval->addAttribute('onchange', "if ( dojo.byId('interval_0').checked ) { dojo.byId('continuouContent').style.display = 'block'; dojo.byId('discretContent').style.display = 'none'; dojo.byId('personId').value = ''; dojo.byId('linkId').value = ''; } else { dojo.byId('continuouContent').style.display = 'none'; dojo.byId('discretContent').style.display = 'block'; dojo.byId('beginPersonId').value = ''; dojo.byId('endPersonId').value = ''; dojo.byId('beginLinkId').value = ''; dojo.byId('endLinkId').value = ''; }");\n        $personLabel = new MLabel(_M('Código do aluno') . ':');\n        $linkLabel = new MLabel(_M('Código do vínculo') . ':');\n        \n        //intervalo discreto \n        $person = new MTextField('personId', null, null, FIELD_DESCRIPTION_SIZE );\n        $personHint = new MDiv('hintPersonD', _M('Separar os códigos por vírgula. Ex: 505052, 505053, ...', $this->module));\n        $personHint->setClass('mSpan mHint');\n        $person = new GContainer('personC', array($personLabel, $person, $personHint));\n        $fields[] = new MVContainer('discretContent', array($person));\n        \n        //intervalo contínuo \n        $beginPerson = new MTextField('beginPersonId', null, null, 10);\n        $endPerson = new MTextField('endPersonId', null, null, 10);\n        $personHint = new MDiv('hintPersonD', _M('Adicionar código inicial e código final', $this->module));\n        $personHint->setClass('mSpan mHint');\n        $person = new GContainer('personCont', array($personLabel, $beginPerson, $endPerson, $personHint));\n        $fields[] = $continuous = new MVContainer('continuouContent', array($person));\n        $continuous->addStyle('display', 'none');\n        $busBond = $this->MIOLO->getBusiness('gnuteca3', 'BusBond');\n        $fields[] = new GSelection('linkId', '', _M('Código do grupo de usuário', $this->module), $busBond->listBond(true));\n        $this->setFields( $fields );\n        $this->setValidators($valids);\n        //ler dados do formulário $form = 'frmadminreport'.MIOLO::_REQUEST('reportId');\n        $this->className = $form;\n        $this->busFormContent->loadFormValues( $this );\n\n        //forma padrão \n        $formContent = $this->busFormContent->loadFormValues( $this, true );\n\n        //obter coluna total \n        if ( $formContent['total'] ) \n        {\n            $totalField = $this->GetField('total');\n            \n            if ( $totalField )\n            {\n                $totalField->setChecked( true );\n            } \n        } \n    } \n    \n    /** \n     * Seta o conteúdo no segmeto "content"\n     * @param Segment $content objeto do segmento \n     * @param array $result resultado \n     * @param array $columns colunas do arquivo \n     */ \n    protected function setOdtContent(Segment $content, $result, $columns) \n    { \n         //defini dados para multiplicação de seguimentos \n         if ( is_array($result) && is_array( $columns ) ) \n         { \n            foreach ( $result as $line => $info )\n            {\n                foreach ( $columns as $l => $column )\n                {\n                    try \n                    {\n                        if ( $column == 'image' ) //foto da pessoa \n                        {\n                            $parts = explode('/', $info[$l]); //separa o arquivo do diretório \n                            $busFile = $this->MIOLO->getBusiness('gnuteca3','BusFile');\n                            $busFile->folder= $parts[0]; //seta o diretório \n                            $busFile->fileName = $parts[1]; //seta o arquivo\n                            $pathFile = $busFile->searchFile(true); //procura imagem default caso não tenha encotrado a imagem \n                         \n                            if ( count($pathFile) == 0 )\n                            {\n                                $busFile->fileName = 'default.';\n                                $pathFile = $busFile->searchFile(true);\n                            } \n                            \n                            $pathFile = $pathFile[0]->absolute;  //obtém caminho absoluto da imagem \n                            $content->setImage('image', $pathFile, 60, 75); //seta a imagem 3x4 \n                        } \n                        else if ( $column == 'codebar' ) //código de barras \n                        { \n                            $tmpPath = BusinessGnuteca3BusFile::getAbsoluteFilePath('tmp', 'codabar_' . $info[$l], 'png' ); //obtém o path completo para arquivo \n                            $barcode = new codabar( $info[$l] ); //gera o código de barras do código de aluno \n                            $barcode->output(0.04, 1.27, 2, $tmpPath); //faz output para o tmp do Gnuteca \n                            $content->setImage('barcode', $tmpPath, 140, 30);\n                            //seta código de barras \n                        } \n                        else \n                        { \n                            $content->$column( utf8_decode( $info[$l] ) );\n                        } \n                    } \n                    catch (Exception $exc) \n                    { \n                        //caso o parametro não exista no content \n                    } \n                } \n                \n                $content->merge();\n            } \n        } \n    } \n    \n    /** \n     * Método reescrito para tratar dados do formulário \n     */ \n     \n    public function getData() \n    { \n        $data = parent::getData();\n        $data->personId = $data->personId ? $data->personId : 'null';\n        $data->beginPersonId = $data->beginPersonId ? $data->beginPersonId : 'null';\n        $data->endPersonId = $data->endPersonId ? $data->endPersonId : 'null';\n        $data->linkId = $data->linkId ? $data->linkId : 'null';\n        $data->beginLinkId = $data->beginLinkId ? $data->beginLinkId : 'null';\n        $data->endLinkId = $data->endLinkId ? $data->endLinkId : 'null';\n\n        return $data;\n    } \n}	\N	t	IMP
\.


--
-- Data for Name: gtcreportparameter; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcreportparameter (reportparameterid, reportid, label, identifier, type, defaultvalue, options, lastvalue, level) FROM stdin;
1	1	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	0
2	2	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	0
3	3	Data inicial	beginDate	date	\N	\N	\N	0
4	3	Data final	endDate	date	\N	\N	\N	1
5	3	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
6	4	Data inicial	beginDate	date	\N	\N	\N	0
7	4	Data final	endDate	date	\N	\N	\N	1
8	4	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
9	5	Data inicial	beginDate	date	\N	\N	\N	0
10	5	Data final	endDate	date	\N	\N	\N	1
11	5	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
15	7	Data inicial	beginDate	date	\N	\N	\N	0
16	7	Data final	endDate	date	\N	\N	\N	1
17	7	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
18	8	Data inicial	beginDate	date	\N	\N	\N	0
19	8	Data final	endDate	date	\N	\N	\N	1
20	8	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
21	9	Data inicial	beginDate	date	\N	\N	\N	0
22	9	Data final	endDate	date	\N	\N	\N	1
23	9	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
24	12	Data inicial	beginDate	date	\N	\N	\N	0
25	12	Data final	endDate	date	\N	\N	\N	1
26	12	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
27	13	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
28	14	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
29	15	Data inicial	beginDate	date	\N	\N	\N	0
30	16	Período	data	string	__/01/2011	\N	\N	0
31	17	Data inicial	beginDate	date	\N	\N	\N	0
32	17	Data final	endDate	date	\N	\N	\N	1
33	17	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
34	18	Data inicial	beginDate	date	\N	\N	\N	0
35	18	Data final	endDate	date	\N	\N	\N	1
36	18	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
37	19	Data inicial	beginDate	date	\N	\N	\N	0
38	19	Data final	endDate	date	\N	\N	\N	1
39	19	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
40	20	Data inicial	beginDate	date	\N	\N	\N	0
41	20	Data final	endDate	date	\N	\N	\N	1
42	20	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
43	21	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
44	22	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
45	23	Data inicial	beginDate	date	\N	\N	\N	0
46	23	Data final	endDate	date	\N	\N	\N	1
47	23	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
48	24	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
49	25	Data inicial	beginDate	date	\N	\N	\N	0
50	25	Data final	endDate	date	\N	\N	\N	1
51	25	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
52	26	Data inicial	beginDate	date	\N	\N	\N	0
53	26	Data final	endDate	date	\N	\N	\N	1
54	26	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
55	28	Área do CNPQ	cnpq	select	\N	<executesql>SELECT option, description FROM gtcmarctaglistingoption WHERE marctaglistingid = '901.b'</executesql>	\N	0
56	30	Data inicial	beginDate	date	\N	\N	\N	0
57	30	Data final	endDate	date	\N	\N	\N	1
58	30	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
59	31	Data inicial	beginDate	date	\N	\N	\N	0
60	31	Data final	endDate	date	\N	\N	\N	1
61	33	Data inicial	beginDate	date	\N	\N	\N	0
62	33	Data final	endDate	date	\N	\N	\N	1
63	33	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
64	34	Data inicial	beginDate	date	\N	\N	\N	0
65	34	Data final	endDate	date	\N	\N	\N	1
66	35	Data inicial	beginDate	date	\N	\N	\N	0
67	35	Data final	endDate	date	\N	\N	\N	1
68	35	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
69	36	Data inicial	beginDate	date	\N	\N	\N	0
70	36	Data final	endDate	date	\N	\N	\N	1
71	37	Data inicial	beginDate	date	\N	\N	\N	0
72	37	Data final	endDate	date	\N	\N	\N	1
73	37	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
74	37	Limite	limit	int	10	\N	\N	1
12	6	Data inicial	beginDate	date	\N	\N	\N	0
13	6	Data final	endDate	date	\N	\N	\N	1
14	6	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	2
75	6	Limite	limit	int	10	\N	\N	1
76	38	Dicionário	dictionaryId	select	\N	<executesql>select * from gtcDictionary order by description</> 	\N	\N
77	39	Classificação	classificacao	string	\N	\N	\N	0
78	39	Data Inicial	dataInicial	date	\N	\N	\N	0
79	39	Data Final	dataFinal	date	\N	\N	\N	0
80	39	Unidade de biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</>	\N	0
81	39	Ordenar por	ordem	select	\N	<executesql>\nSELECT '4' as codigo,'Autor' as tipo \nUNION SELECT '2' as codigo,'Classificação'as tipo \nUNION SELECT '3' as codigo,'Título' as tipo \nUNION SELECT '1' as codigo,'Número de controle' as tipo   \nUNION SELECT '5' as codigo,'Quantidade de exemplares' as tipo \nORDER BY 2 \n</>	\N	0
82	40	Classificação	classification	string	\N	\N	\N	0
83	40	Unidade de biblioteca	libraryUnitId	select	\N	<executesql>SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</>	\N	0
84	41	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</> 	\N	0
85	MATERIAL_EVALUATION	Limite	limit	int	10	\N	\N	0
86	MATERIAL_EVALUATION	Ordem	order	select	10	<executePHP>array('4'=> 'Quantidade', 5=>'Média', 6=>'Pontuação')</executePHP>	\N	0
87	MATERIAL_EVALUATION	Tipo	type	select	desc	<executePHP>array( 'asc' => 'Piores', 'desc' => 'Melhores')</executePHP>	\N	0
88	MATERIAL_EVALUATION	Unidade	libraryUnitId	select	desc	<executeSQL>SELECT '0', 'Todas' UNION SELECT libraryUnitId::varchar, libraryName from gtcLibraryUnit;</executeSQL>	\N	0
89	MULTAS_PERIODO	Data Inicial	beginDate	date	new GDate::now()	\N	\N	0
90	MULTAS_PERIODO	Data Final	finalDate	date	new GDate::now()	\N	\N	0
91	MULTAS_PERIODO	Unidade	unityId	select	new GDate::now()	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit ORDER BY 1</> 	\N	0
92	MULTAS_PERIODO	Operador	operator	select		<executePHP>GnutecaOperator::listOperators(true);</executePHP>	\N	0
93	MULTAS_PERIODO	Estado	status	select		<executeSQL>select finestatusid,description  from gtcfinestatus UNION SELECT 0 as finestatusid ,'Todos' as description</executeSQL>	\N	0
94	ACTIVE_PERSON	Vinculo	linkId	select	\N	<executesql>SELECT 0 as linkid, 'Todos os vinculos' as description UNION SELECT linkid,description from baslink</executesql>\n	\N	0
95	LOAN_BY_TYPE	Data Inicial	beginDate	date	GDate::now()	\N	\N	0
96	LOAN_BY_TYPE	Data final	finalDate	date	GDate::now()	\N	\N	0
97	LOAN_BY_TYPE	Unidade de biblioteca	libraryUnitId	select	GDate::now()	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</executesql>	\N	0
98	LOAN_BY_TYPE	Tipo de material	materialTypeId	select	GDate::now()	<executesql>\nSELECT '0' as materialtypeid, 'Todos os tipos de material' as description UNION  SELECT  materialtypeid,description from gtcmaterialtype order by 1;\n</executesql>	\N	0
99	MOST_BORROWED	Data Inicial	beginDate	date	GDate::now()	\N	\N	0
100	MOST_BORROWED	Data final	finalDate	date	GDate::now()	\N	\N	0
101	MOST_BORROWED	Unidade de biblioteca	libraryUnitId	select	GDate::now()	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</executesql>	\N	0
102	MOST_BORROWED	Tipo de material	materialTypeId	select	GDate::now()	<executesql>\nSELECT '0' as materialtypeid, 'Todos os tipos de material' as description UNION  SELECT  materialtypeid,description from gtcmaterialtype order by 1;\n</executesql>	\N	0
103	LOAN_BY_ENTERPRISE	Data Inicial	beginDate	date	GDate::now()	\N	\N	0
104	LOAN_BY_ENTERPRISE	Data final	finalDate	date	GDate::now()	\N	\N	0
105	LOAN_BY_ENTERPRISE	Unidade de biblioteca	libraryUnitId	select	GDate::now()	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</executesql>	\N	0
106	LOAN_BY_PERSON	Data Inicial	beginDate	date	GDate::now()	\N	\N	0
107	LOAN_BY_PERSON	Data final	finalDate	date	GDate::now()	\N	\N	0
108	LOAN_BY_PERSON	Unidade de biblioteca	libraryUnitId	select	GDate::now()	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</executesql>	\N	0
109	MATERIAL_TYPE_STATIS	Unidade de biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</executesql>	\N	0
110	MATERIAL_TYPE_STATIS	Tipo de material	materialTypeId	select	\N	<executesql>\nSELECT '0' as materialtypeid, 'Todos os tipos de materiais' as description UNION  SELECT  materialtypeid,description from gtcmaterialtype order by 1;\n</executesql>	\N	0
111	INVENTARY	Classificação Inicial	beginClassification	string	\N	\N	\N	0
112	INVENTARY	Classificação final	finalClassification	string	\N	\N	\N	0
113	INVENTARY	Unidade de biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</executesql>	\N	0
114	INVENTARY	Ordenar por	orderBy	select	\N	<executesql>SELECT 'D' as tabela,'Título' as ordenacao UNION SELECT 'A','Classificação' UNION SELECT 'E','Autor' ORDER BY 1</executesql>	\N	0
115	MOST_BORROWED_SUB	Data inicial	beginDate	date	\N	\N	\N	0
116	MOST_BORROWED_SUB	Data final	endDate	date	\N	\N	\N	0
117	MOST_BORROWED_SUB	Unidade de biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</executesql>	\N	0
118	LOAN_BY_ENT_SUB	Data inicial	beginDate	date	\N	\N	\N	0
119	LOAN_BY_ENT_SUB	Data final	endDate	date	\N	\N	\N	0
120	LOAN_BY_ENT_SUB	Unidade de biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</executesql>	\N	0
121	LOAN_BY_ENT_SUB	Empresa	personGroup	select	\N	<executesql>\nSELECT '0' as "key",'Todas empresas' as "label"  UNION\nSELECT key,label from gtcdomain where domainid = 'PERSON_GROUP'\n</executesql>	\N	0
122	NEXT_ITEMNUMBER	Unidade	libraryUnitId	select	\N	<executesql>select libraryUnitId, libraryName from gtcLibraryUnit;</executesql>	\N	0
123	TOTAL_ACQUISITION	Data inicial	beginDate	date	\N	\N	\N	0
124	TOTAL_ACQUISITION	Data final	endDate	date	\N	\N	\N	0
125	TOTAL_ACQUISITION	Unidade de biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</executesql>	\N	0
126	TIPO_AQUISICAO_LISTA	Data inicial	beginDate	date	\N	\N	\N	0
127	TIPO_AQUISICAO_LISTA	Data final	finalDate	date	\N	\N	\N	0
128	TIPO_AQUISICAO_LISTA	Unidade de biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit</executesql>	\N	0
129	TIPO_AQUISICAO_LISTA	Tipo de aquisição	aquisitionType	select	\N	<executeSQL>\nSELECT '0' as option,'Todas' as description UNION SELECT option,description from gtcmarctaglistingoption where marctaglistingid = '949.c' ORDER by 1\n</executeSQL>	\N	0
130	INSERIDO_PERIODO	Unidade de biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit </executesql>	\N	0
131	INSERIDO_PERIODO	Data inicial	beginDate	date	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit </executesql>	\N	0
132	INSERIDO_PERIODO	Data final	finalDate	date	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit </executesql>	\N	0
133	INSERIDO_PERIODO	Gênero do material	materialGenderId	select	\N	<executesql>SELECT '0' as materialgenderid,'Todos' as description UNION SELECT materialgenderid,description from gtcmaterialgender order by 1;</executesql>	\N	0
134	LISTA_EXEMPLARES	Unidade de biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit ORDER BY 1</executesql>	\N	0
135	LISTA_EXEMPLARES	Área de conhecimento	knowledgeAreaId	select	\N	<executesql>SELECT '0' as option, 'Todas' as description UNION SELECT option,description from gtcmarctaglistingoption where marctaglistingid  = '901.b' order by 1\n</executesql>	\N	0
136	LISTA_EXEMPLARES	Tipo físico do material	materialPhysicalTypeId	select	\N	<executesql>\nSELECT '0' as materialphysicaltypeid, 'Todos'  as description UNION SELECT materialphysicaltypeid,description from gtcmaterialphysicaltype order by 1\n</executesql>	\N	0
137	LISTA_EXEMPLARES	Planilha	spreadSheetId	select	\N	<executesql>SELECT '0' as value, 'Todas' as description UNION SELECT (category ||'.'|| level) as value,(category ||'.'|| level) as description FROM gtcspreadsheet WHERE (category ||'.'|| level) NOT IN ('BA.4','SE.#','SA.4') ORDER BY 1 </executesql>	\N	0
138	LISTA_EXEMPLARES	Estado do exemplar	exemplaryStatusId	select	\N	<executesql>SELECT (SELECT max(exemplarystatusid)+1 FROM gtcexemplarystatus) as value, 'Todos' as description UNION SELECT exemplarystatusid,description from gtcexemplarystatus order by 1 DESC </executesql>	\N	0
139	OBRA_LISTA	Unidade da biblioteca	libraryUnitId	select	\N	<executesql>\nSELECT '0' as value, 'Todas' as description UNION SELECT libraryunitid as value, libraryname as description  from gtclibraryunit order by 1\n</executesql>	\N	0
140	OBRA_LISTA	Tipo de material	materialTypeId	select	\N	<executesql>\nSELECT '0' as value, 'Todos' as description UNION SELECT materialtypeid as value, description as description  from gtcmaterialtype order by 1\n</executesql>	\N	0
141	CLASSE_ANO	Ano inicial	beginYear	int	\N	\N	\N	0
142	CLASSE_ANO	Ano final	finalYear	int	\N	\N	\N	0
143	CLASSE_ANO	Classificação	classification	string	%	\N	\N	0
144	EXEMPLAR_CNPQ	Unidade de biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit ORDER BY 1</executesql>	\N	0
145	EXEMPLAR_CNPQ	Tipo de material	materialTypeId	select	\N	<executesql>\nSELECT '0' as value, 'Todos' as description UNION SELECT materialtypeid as value,description as description from gtcmaterialtype  order by 1\n</executesql>\n\n	\N	0
146	EXEMPLAR_CNPQ	Ãrea de conhecimento	knowledgeAreaId	select	\N	<executesql>SELECT '0' as value, 'Todos' as description UNION SELECT option as value,description from gtcmarctaglistingoption  where  marctaglistingid = '901.b' order by 1</executesql>	\N	0
147	ESTATATISTA_CNPQ	Unidade de biblioteca	libraryUnitId	select	\N	<executesql>SELECT '0', 'Todas unidades' UNION SELECT libraryUnitId, libraryName FROM gtcLibraryUnit ORDER BY 1</executesql>	\N	0
168	ACCESS_FORM	Limite	limit	int	10	\N	10	0
169	ACCESS_FORM	Acessos	orderby	select	desc	<executephp>array("desc" => "Mais acessados", "asc" => "Menos acessados");</executephp>	desc	0
170	CAPA_DVD	Número do tombo	itemNumber	itemNumber	'90006206', '90002215' , '90003748'	\N	\N	0
171	CAPA_CD	Número de exemplar	itemNumber	itemNumber	\N	\N	\N	0
172	SIMPLE_SEARCH_TEM	Limite	limit	int	50	\N	\N	0
\.


--
-- Data for Name: gtcrequestchangeexemplarystatus; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcrequestchangeexemplarystatus (requestchangeexemplarystatusid, futurestatusid, personid, observation, date, finaldate, requestchangeexemplarystatusstatusid, libraryunitid, aprovejustone, discipline) FROM stdin;
\.


--
-- Data for Name: gtcrequestchangeexemplarystatusaccess; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcrequestchangeexemplarystatusaccess (baslinkid, exemplarystatusid, bug_dia2sql_ignorar) FROM stdin;
\.


--
-- Data for Name: gtcrequestchangeexemplarystatuscomposition; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcrequestchangeexemplarystatuscomposition (requestchangeexemplarystatusid, itemnumber, exemplaryfuturestatusdefinedid, confirm, date, applied) FROM stdin;
\.


--
-- Data for Name: gtcrequestchangeexemplarystatusstatus; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcrequestchangeexemplarystatusstatus (requestchangeexemplarystatusstatusid, description) FROM stdin;
1	Solicitado
2	Aprovado
3	Reprovado
4	Concluído
5	Cancelado
6	Confirmado
\.


--
-- Data for Name: gtcrequestchangeexemplarystatusstatushistory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcrequestchangeexemplarystatusstatushistory (requestchangeexemplarystatusid, requestchangeexemplarystatusstatusid, date, operator) FROM stdin;
\.


--
-- Data for Name: gtcreserve; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcreserve (reserveid, libraryunitid, personid, requesteddate, limitdate, reservestatusid, reservetypeid) FROM stdin;
\.


--
-- Data for Name: gtcreservecomposition; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcreservecomposition (reserveid, itemnumber, isconfirmed) FROM stdin;
\.


--
-- Data for Name: gtcreservestatus; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcreservestatus (reservestatusid, description) FROM stdin;
1	Solicitada
2	Atendida
3	Comunicada
4	Confirmada
5	Vencida
6	Cancelada
\.


--
-- Data for Name: gtcreservestatushistory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcreservestatushistory (reserveid, reservestatusid, date, operator) FROM stdin;
\.


--
-- Data for Name: gtcreservetype; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcreservetype (reservetypeid, description) FROM stdin;
1	Local
2	Web
3	Local (Atendidas)
4	Web (Estado inicial)
5	Local (Estado Inicial)
\.


--
-- Data for Name: gtcreturnregister; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcreturnregister (returnregisterid, returntypeid, itemnumber, date, operator) FROM stdin;
\.


--
-- Data for Name: gtcreturntype; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcreturntype (returntypeid, description) FROM stdin;
1	Apagados
2	Utilização local
\.


--
-- Data for Name: gtcright; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcright (privilegegroupid, linkid, materialgenderid, operationid) FROM stdin;
\.


--
-- Data for Name: gtcrulesformaterialmovement; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcrulesformaterialmovement (currentstate, operationid, locationformaterialmovementid, futurestate) FROM stdin;
\.


--
-- Data for Name: gtcrulestocompletefieldsmarc; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcrulestocompletefieldsmarc (rulestocompletefieldsmarcid, category, originfield, fatefield, affectrecordscompleted) FROM stdin;
\.


--
-- Data for Name: gtcschedulecycle; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcschedulecycle (schedulecycleid, description, valuetype) FROM stdin;
1	Sem Ciclo	d/m/Y H
2	Anual	d/m H
3	Mensal	d H
4	Semanal	w H
5	Diário	H
\.


--
-- Data for Name: gtcscheduletask; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcscheduletask (scheduletaskid, taskid, schedulecycleid, description, cyclevalue, enable, parameters) FROM stdin;
1	28	5	Remover arquivos temporarios do gnuteca	11	t	\N
\.


--
-- Data for Name: gtcscheduletasklog; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcscheduletasklog (scheduletaskid, log, date) FROM stdin;
\.


--
-- Data for Name: gtcsearchablefield; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcsearchablefield (searchablefieldid, description, field, identifier, fieldtype, isrestricted, level, observation, helps) FROM stdin;
1	Título	240.a,245.a+245.b,246.a+246.b	titulo	2	f	9	\N	
2	Autor	100.a,700.a	autor	2	f	12	\N	
3	Assunto	650.a	assunto	2	f	15	\N	
5	Ano	260.c	ano	1	f	18	\N	
6	Classificação	090.a,090.b,080.a,090.a+090.b	classificacao	2	f	21	\N	
7	CDU (090)	090.a	cdu	2	t	24	\N	
8	Cutter	090.b	cutter	2	t	27	\N	
9	Editora	260.b	editora	2	f	30	\N	
10	Evento	111.a,711.a	evento	2	f	33	\N	
11	Número de controle	001.a	controle	1	t	36	\N	
12	Número do tombo	949.a	tombo	2	t	40	\N	
13	Número da obra	950.a	obra	1	t	43	\N	
14	Número da nota fiscal	949.f	nota	1	t	46	\N	
15	Data da nota fiscal	949.h	datanota	\N	t	49	\N	
16	Centro de custo	949.q	cc	\N	t	52	\N	
17	Volume de periódicos	362.a	volume	\N	t	55	\N	
18	CDU (080)	080.a	cdu080	\N	t	25	\N	
4	Todos os campos		todos	2	f	6	\N	
\.


--
-- Data for Name: gtcsearchablefieldaccess; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcsearchablefieldaccess (searchablefieldid, linkid, bug_dia2sql_ignorar) FROM stdin;
\.


--
-- Data for Name: gtcsearchformat; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcsearchformat (searchformatid, description, isrestricted) FROM stdin;
1	Padrão	f
2	Marc	f
3	Circulação de material	t
4	Favoritos	t
5	Administração	t
6	Z3950	t
7	Formato bibliográfico	f
10	ISO 2709	f
\.


--
-- Data for Name: gtcsearchformataccess; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcsearchformataccess (searchformatid, linkid, bug_dia2sql_ignorar) FROM stdin;
\.


--
-- Data for Name: gtcsearchformatcolumn; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcsearchformatcolumn (searchformatid, "column", bug_dia2sql_ignorar) FROM stdin;
10	Image	\N
10	Exemplarys	\N
\.


--
-- Data for Name: gtcsearchmaterialview; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcsearchmaterialview (controlnumber, entrancedate, lastchangedate, category, level, materialgenderid, materialtypeid, materialphysicaltypeid, exemplaryitemnumber, exemplaryoriginallibraryunitid, exemplarylibraryunitid, exemplaryacquisitiontype, exemplaryexemplarystatusid, exemplarymaterialgenderid, exemplarymaterialtypeid, exemplarymaterialphysicaltypeid, exemplaryentrancedate, exemplarylowdate) FROM stdin;
\.


--
-- Data for Name: gtcsearchpresentationformat; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcsearchpresentationformat (searchformatid, category, searchformat, detailformat) FROM stdin;
2	DF	<ifexists $090.a $090.b>\n    <style b>090</style>\n    <ifexists $090.a>^a $090.a</ifexists>\n    <ifexists $090.b>^b $090.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $100.a >\n    <style b>100</style>\n    ^a $100.a\n    $LN\n</ifexists>\n<ifexists $245.a $245.b>\n    <style b>245</style>\n    <ifexists $245.a>^a $245.a</ifexists>\n    <ifexists $245.b>^b $245.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $250.a >\n    <style b>250</style>\n    ^a $250.a\n    $LN\n</ifexists>\n<ifexists $260.c >\n    <style b>260</style>\n    ^c $260.c\n    $LN\n</ifexists>\n<ifexists $362.a >\n    <style b>362</style>\n    ^a $362.a\n    $LN\n</ifexists>	<ifexists $041.a >\n    <style b>041</style>\n    ^a $041.a\n    $LN\n</ifexists>\n<ifexists $090.a $090.b>\n    <style b>090</style>\n    <ifexists $090.a>^a $090.a</ifexists>\n    <ifexists $090.b>^b $090.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $100.a >\n    <style b>100</style>\n    ^a $100.a\n    $LN\n</ifexists>\n<ifexists $110.a >\n    <style b>110</style>\n    ^a $110.a\n    $LN\n</ifexists>\n<ifexists $111.d $111.n >\n    <style b>111</style>\n    <ifexists $111.d>^d $111.d</ifexists>\n    <ifexists $111.n>^n $111.d</ifexists>\n    $LN\n</ifexists>\n<ifexists $245.a $245.b $245.h $245.k>\n    <style b>245</style>\n    <ifexists $245.a>^a $245.a</ifexists>\n    <ifexists $245.b>^b $245.b</ifexists>\n    <ifexists $245.h>^h $245.h</ifexists>\n    <ifexists $245.k>^k $245.k</ifexists>\n    $LN\n</ifexists>\n<ifexists $246.a $246.b>\n    <style b>245</style>\n    <ifexists $246.a>^a $246.a</ifexists>\n    <ifexists $246.b>^b $246.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $250.a >\n    <style b>250</style>\n    ^a $250.a\n    $LN\n</ifexists>\n<ifexists $260.a $260.b $260.c>\n    <style b>260</style>\n    <ifexists $260.a>^a $260.a</ifexists>\n    <ifexists $260.b>^b $260.b</ifexists>\n    <ifexists $260.c>^c $260.c</ifexists>\n    $LN\n</ifexists>\n<ifexists $300.a $300.e >\n    <style b>300</style>\n    <ifexists $300.a>^a $300.a</ifexists>\n    <ifexists $300.e>^e $300.e</ifexists>\n    $LN\n</ifexists>\n<ifexists $310.a >\n    <style b>310</style>\n    ^a $310.a\n    $LN\n</ifexists>\n<ifexists $362.a >\n    <style b>362</style>\n    ^a $362.a\n    $LN\n</ifexists>\n<ifexists $440.a >\n    <style b>440</style>\n    ^a $440.a\n    $LN\n</ifexists>\n<ifexists $500.a >\n    <style b>500</style>\n    ^a $500.a\n    $LN\n</ifexists>\n<ifexists $502.a >\n    <style b>502</style>\n    ^a $502.a\n    $LN\n</ifexists>\n<ifexists $505.a >\n    <style b>505</style>\n    ^a $505.a\n    $LN\n</ifexists>\n<ifexists $510.a >\n    <style b>510</style>\n    ^a $510.a\n    $LN\n</ifexists>\n<ifexists $520.a >\n    <style b>520</style>\n    ^a $520.a\n    $LN\n</ifexists>\n<ifexists $590.a >\n    <style b>590</style>\n    ^a $590.a\n    $LN\n</ifexists>\n<ifexists $650.a >\n    <style b>650</style>\n    ^a $650.a\n    $LN\n</ifexists>\n<ifexists $653.a >\n    <style b>653</style>\n    ^a $653.a\n    $LN\n</ifexists>\n<ifexists $700.a >\n    <style b>700</style>\n    ^a $700.a\n    $LN\n</ifexists>\n<ifexists $710.a >\n    <style b>710</style>\n    ^a $710.a\n    $LN\n</ifexists>\n<ifexists $711.a $711.d $711.n >\n    <style b>711</style>\n    <ifexists $711.a>^a $711.a</ifexists>\n    <ifexists $711.d>^d $711.d</ifexists>\n    <ifexists $711.n>^n $711.n</ifexists>\n    $LN\n</ifexists>\n<ifexists $740.a >\n    <style b>740</style>\n    ^a $740.a\n    $LN\n</ifexists>\n<ifexists $773.t >\n    <style b>773</style>\n    ^t $773.t\n    $LN\n</ifexists>\n<ifexists $780.a $780.t >\n    <style b>780</style>\n    <ifexists $780.a>^a $780.a</ifexists>\n    <ifexists $780.t>^t $780.t</ifexists>\n    $LN\n</ifexists>\n<ifexists $785.a >\n    <style b>785</style>\n    ^a $785.a\n    $LN\n</ifexists>\n<ifexists $856.u >\n    <style b>856</style>\n    ^u $856.u\n    $LN\n</ifexists>\n<ifexists $947.a >\n    <style b>947</style>\n    ^a $947.a\n    $LN\n</ifexists>
2	SE	\n<ifexists $090.a $090.b ><style b>090:</style> <ifexists $090.a>^a $090.a</ifexists> &nbsp; <ifexists $090.b>^b $090.b</ifexists> $LN</ifexists>\n<ifexists $245.a ><style b>245:</style> ^a $245.a $LN</ifexists>\n<ifexists $260.a $260.b><style b>260:</style> <ifexists $260.a>^a $260.a</ifexists> &nbsp; <ifexists $260.b>^b $260.b</ifexists> $LN</ifexists>\n	\n<ifexists $000.a >000: ^a $000.a $LN</ifexists>\n<ifexists $041.a >041: ^a $041.a $LN</ifexists>\n<ifexists $090.a $090.b >090: <ifexists $090.a>^a $090.a</ifexists> &nbsp; <ifexists $090.b>^b $090.b</ifexists> $LN</ifexists>\n<ifexists $245.a >245: ^a $245.a $LN</ifexists>\n<ifexists $260.a $260.b>260: <ifexists $260.a>^a $260.a</ifexists> &nbsp; <ifexists $260.b>^b $260.b</ifexists> $LN</ifexists>\n<ifexists $310.a >310: ^a $310.a $LN</ifexists>\n<ifexists $590.a >590: ^a $590.a $LN</ifexists>\n<ifexists $650.a >650: ^a <replace -#- | $SP^a$SP >$650.a</replace> $LN</ifexists>\n<ifexists $856.u >856: ^u <href $856.u >$856.a</href> $LN</ifexists>\n
2	BK	\n<ifexists $090.a $090.a ><style b>090:</style> <ifexists $090.a>^a $090.a</ifexists> &nbsp; <ifexists $090.b>^b $090.b</ifexists> $LN</ifexists>\n<ifexists $100.a ><style b>100:</style> ^a $100.a $LN</ifexists>\n<ifexists $245.a ><style b>245:</style> ^a $245.a $LN</ifexists>\n	\n<ifexists $000.a >000: ^a $000.a $LN</ifexists>\n<ifexists $041.a >041: ^a $041.a $LN</ifexists>\n<ifexists $090.a $090.a >090: <ifexists $090.a>^a $090.a</ifexists> &nbsp; <ifexists $090.b>^b $090.b</ifexists> $LN</ifexists>\n<ifexists $100.a >100: ^a $100.a $LN</ifexists>\n<ifexists $245.a >245: ^a $245.a $LN</ifexists>\n<ifexists $250.a >250: ^a $250.a $LN</ifexists>\n<ifexists $260.a $260.b>260: <ifexists $260.a>^a $260.a</ifexists> &nbsp; <ifexists $260.b>^b $260.b</ifexists> $LN</ifexists>\n<ifexists $300.a >300: ^a $300.a $LN</ifexists>\n<ifexists $650.a >650: ^a <replace -#- | $SP^a$SP >$650.a</replace> $LN</ifexists>\n
1	SE	<ifexists $245.a >\n    <style b>\n        Título:\n    </style>\n    $245.a\n    <ifexists $245.b >:$245.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $260.c >\n    <style b>\n    Data de Publicação, Distribuição, etc.:\n    </style>\n    $260.c $LN\n</ifexists>\n<ifexists $090.a $090.b >\n    <style b>Classificação:</style>\n    <style color=DarkCyan | font-size=13px>$090.a $090.b </style>$LN\n</ifexists>\n<ifexists $362.a >\n    <style b>\n    Datas de Publicação / Indicação de Sequência:\n    </style><style color=DarkCyan | font-size=13px>\n    $362.a </style>$LN\n</ifexists>\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>\n<getevaluation $001.a></getevaluation>	<ifexists $245.a >\n    <style b>\n        Título:\n    </style>\n    $245.a\n    <ifexists $245.b>: $245.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $100.a >\n    <style b>\n    Autor:\n    </style>\n    $100.a $LN\n</ifexists>\n<ifexists $250.a >\n    <style b>\n    Edição:\n    </style>\n    $250.a $LN\n</ifexists>\n<ifexists $090.a $090.b >\n    <style b>Classificação: <style color=DarkCyan | font-size=13px> $090.a $090.b</style></style>$LN\n</ifexists>\n<ifexists $362.a >\n    <style b>\n    Datas de Publicação / Indicação de Sequência: <style color=DarkCyan | font-size=13px>$362.a </style></style>$LN\n</ifexists>\n<ifexists $246.a >\n    <style b>\n        Título/título Abreviado:\n    </style>\n    $246.a\n    <ifexists $246.b>: $246.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $650.a $653.a >\n    <style b>\n    Assunto:\n    </style>\n    $650.a $653.a $LN\n</ifexists>\n<ifexists $245.h >\n    <style b>\n    Meio físico:\n    </style>\n    $245.h $LN\n</ifexists>\n<ifexists $245.k >\n    <style b>\n    Forma:\n    </style>\n    $245.k $LN\n</ifexists>\n<ifexists $310.a >\n    <style b>\n    Periodicidade:\n    </style>\n    $310.a $LN\n</ifexists>\n<ifexists $700.a >\n    <style b>\n    Nome pessoal:\n    </style>\n    $700.a $LN\n</ifexists>\n<ifexists $710.a >\n    <style b>\n    Nome corporativo ou jurisdição:\n    </style>\n    $710.a $LN\n</ifexists>\n<ifexists $711.a >\n    <style b>\n    Nome do evento ou jurisdição como entrada:\n    </style>\n    $711.a - $711.d - $711.n $LN\n</ifexists>\n<ifexists $740.a >\n    <style b>\n    Título relacionado / Analítico não controlado:\n    </style>\n    $740.a $LN\n</ifexists>\n<ifexists $440.a >\n    <style b>\n    Título da série:\n    </style>\n    $440.a $LN\n</ifexists>\n<ifexists $500.a >\n    <style b>\n    Nota geral:\n    </style>\n    $500.a $LN\n</ifexists>\n<ifexists $502.a >\n    <style b>\n    Nota de Dissertação ou Tese:\n    </style>\n    $502.a $LN\n</ifexists>\n<ifexists $510.a >\n    <style b>\n    Nome da fonte:\n    </style>\n    $510.a $LN\n</ifexists>\n<ifexists $520.a >\n    <style b>\n    Nota de Resumo:\n    </style>\n    $520.a $LN\n</ifexists>\n<ifexists $590.a >\n    <style b>\n    Notas locais:\n    </style>\n    $590.a $LN\n</ifexists>\n<ifexists $773.t >\n    <style b>\n    Título:\n    </style>\n    $773.t $LN\n</ifexists>\n<ifexists $780.a >\n    <style b>\n    Título da entrada principal:\n    </style>\n    $780.a $LN\n</ifexists>\n<ifexists $780.t >\n    <style b>\n    Título:\n    </style>\n    $780.t $LN\n</ifexists>\n<ifexists $785.a >\n    <style b>\n    Título da entrada principal:\n    </style>\n    $785.a $LN\n</ifexists>\n<ifexists $111.d >\n    <style b>\n    Data do Evento:\n    </style>\n    $111.d $LN\n</ifexists>\n<ifexists $111.n >\n    <style b>\n    Número de Parte/Seção/Evento:\n    </style>\n    $111.n $LN\n</ifexists>\n<ifexists $041.a >\n    <style b>\n    Código de Idioma do Texto/trilha Sonora ou Título Diferente:\n    </style>\n    $041.a $LN\n</ifexists>\n<ifexists $260.a >\n    <style b>\n    Lugar de Publicação, Distribuição, etc.:\n    </style>\n    $260.a $LN\n</ifexists>\n<ifexists $260.b >\n    <style b>\n    Nome do Editor, Distribuidor, etc.:\n    </style>\n    $260.b $LN\n</ifexists>\n<ifexists $260.c >\n    <style b>\n    Data de Publicação, Distribuição, etc.:\n    </style>\n    $260.c $LN\n</ifexists>\n<ifexists $856.u >\n    <style b>\n    Localizador da fonte (endereço eletrônico):\n    </style>\n    $856.u $LN\n</ifexists>\n<ifexists $110.a >\n    <style b>\n    Nome Corporativo ou Nome da Jurisdição:\n    </style>\n    $110.a $LN\n</ifexists>\n<ifexists $300.a >\n    <style b>\n    Extensão:\n    </style>\n    $300.a $LN\n</ifexists>\n<ifexists $300.e >\n    <style b>\n    Material Complementar:\n    </style>\n    $300.e $LN\n</ifexists>\n<ifexists $505.a >\n    <style b>\n    Nota de conteúdo:\n    </style>\n    $505.a $LN\n</ifexists>\n<ifexists $947.a >\n    <style b>\n    Código do editor/fornecedor:\n    </style>\n    $947.a $LN\n</ifexists>
1	DF	<ifexists $245.a >\n    <style b>\n        Título:\n    </style>\n    $245.a\n    <ifexists $245.b>: $245.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $100.a >\n    <style b>\n    Autor:\n    </style>\n    $100.a $LN\n</ifexists>\n<ifexists $250.a >\n    <style b>\n    Edição:\n    </style>\n    $250.a $LN\n</ifexists>\n<ifexists $260.c >\n    <style b>\n    Ano:\n    </style>\n    $260.c $LN\n</ifexists>\n<ifexists $090.a $090.b >\n    <style b>Classificação: <style color=DarkCyan | font-size=13px> $090.a $090.b</style></style>$LN\n</ifexists>\n<ifexists $362.a >\n    <style b>\n    Datas de Publicação / Indicação de Sequência:\n    </style>\n    $362.a $LN\n</ifexists>\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>\n<getevaluation $001.a></getevaluation>	<ifexists $245.a >\n    <style b>\n        Título:\n    </style>\n    $245.a\n    <ifexists $245.b>: $245.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $100.a >\n    <style b>\n    Autor:\n    </style>\n    $100.a $LN\n</ifexists>\n<ifexists $250.a >\n    <style b>\n    Edição:\n    </style>\n    $250.a $LN\n</ifexists>\n<ifexists $090.a $090.b >\n    <style b>Classificação: <style color=DarkCyan | font-size=13px> $090.a $090.b</style></style>$LN\n</ifexists>\n<ifexists $362.a >\n    <style b>\n    Datas de Publicação / Indicação de Sequência: $362.a </style>$LN\n</ifexists>\n<ifexists $246.a >\n    <style b>\n        Título abreviado:\n    </style>\n    $246.a\n    <ifexists $246.b>: $246.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $650.a $653.a >\n    <style b>\n    Assunto:\n    </style>\n    $650.a $653.a $LN\n</ifexists>\n<ifexists $245.h >\n    <style b>\n    Meio físico:\n    </style>\n    $245.h $LN\n</ifexists>\n<ifexists $245.k >\n    <style b>\n    Forma:\n    </style>\n    $245.k $LN\n</ifexists>\n<ifexists $310.a >\n    <style b>\n    Periodicidade:\n    </style>\n    $310.a $LN\n</ifexists>\n<ifexists $700.a >\n    <style b>\n    Nome pessoal:\n    </style>\n    $700.a $LN\n</ifexists>\n<ifexists $710.a >\n    <style b>\n    Nome corporativo ou jurisdição:\n    </style>\n    $710.a $LN\n</ifexists>\n<ifexists $711.a >\n    <style b>\n    Nome do evento ou jurisdição:\n    </style>\n    $711.a - $711.d - $711.n $LN\n</ifexists>\n<ifexists $740.a >\n    <style b>\n    Título relacionado / Analítico não controlado:\n    </style>\n    $740.a $LN\n</ifexists>\n<ifexists $440.a >\n    <style b>\n    Título da série:\n    </style>\n    $440.a $LN\n</ifexists>\n<ifexists $500.a >\n    <style b>\n    Nota geral:\n    </style>\n    $500.a $LN\n</ifexists>\n<ifexists $502.a >\n    <style b>\n    Nota de Dissertação ou Tese:\n    </style>\n    $502.a $LN\n</ifexists>\n<ifexists $510.a >\n    <style b>\n    Nome da fonte:\n    </style>\n    $510.a $LN\n</ifexists>\n<ifexists $520.a >\n    <style b>\n    Nota de Resumo:\n    </style>\n    $520.a $LN\n</ifexists>\n<ifexists $590.a >\n    <style b>\n    Notas locais:\n    </style>\n    $590.a $LN\n</ifexists>\n<ifexists $773.t >\n    <style b>\n    Título da entrada principal:\n    </style>\n    $773.t $LN\n</ifexists>\n<ifexists $780.a >\n    <style b>\n    Título da entrada principal:\n    </style>\n    $780.a $LN\n</ifexists>\n<ifexists $780.t >\n    <style b>\n    Título:\n    </style>\n    $780.t $LN\n</ifexists>\n<ifexists $785.a >\n    <style b>\n    Titulo:\n    </style>\n    $785.a $LN\n</ifexists>\n<ifexists $111.d >\n    <style b>\n    Data do Evento:\n    </style>\n    $111.d $LN\n</ifexists>\n<ifexists $111.n >\n    <style b>\n    Número de Parte/Seção/Evento:\n    </style>\n    $111.n $LN\n</ifexists>\n<ifexists $041.a >\n    <style b>\n    Código de Idioma do Texto/trilha Sonora ou Título Diferente:\n    </style>\n    $041.a $LN\n</ifexists>\n<ifexists $260.a >\n    <style b>\n    Lugar de Publicação, Distribuição, etc.:\n    </style>\n    $260.a $LN\n</ifexists>\n<ifexists $260.b >\n    <style b>\n    Nome do Editor, Distribuidor, etc.:\n    </style>\n    $260.b $LN\n</ifexists>\n<ifexists $260.c >\n    <style b>\n    Data de Publicação, Distribuição, etc.:\n    </style>\n    $260.c $LN\n</ifexists>\n<ifexists $856.u >\n    <style b>\n    Localizador da fonte (endereço eletrônico):\n    </style>\n    $856.u $LN\n</ifexists>\n<ifexists $110.a >\n    <style b>\n    Nome Corporativo ou Nome da Jurisdição:\n    </style>\n    $110.a $LN\n</ifexists>\n<ifexists $300.a >\n    <style b>\n    Extensão:\n    </style>\n    $300.a $LN\n</ifexists>\n<ifexists $300.e >\n    <style b>\n    Material Complementar:\n    </style>\n    $300.e $LN\n</ifexists>\n<ifexists $505.a >\n    <style b>\n    Nota de conteúdo:\n    </style>\n    $505.a $LN\n</ifexists>\n<ifexists $947.a >\n    <style b>\n    Código do editor/fornecedor:\n    </style>\n    $947.a $LN\n</ifexists>
5	DF	\n<style b>Título:</style> $245.a $LN\n<style b>Autor:</style> $100.a $LN\n<style b>Classificação:</style> $090.a $090.b $LN\n\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>	\n<style b>Título:</style> $245.a $LN\n<style b>Autor:</style> $100.a $LN\n<style b>Classificação:</style> $090.a $090.b $LN\n\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>
1	BK	<ifexists $245.a >\n    <style b>\n        Título:\n    </style>\n    $245.a\n    <ifexists $245.b>: $245.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $100.a >\n    <style b>\n    Autor:\n    </style>\n    $100.a $LN\n</ifexists>\n<ifexists $250.a >\n    <style b>\n    Edição:\n    </style>\n    $250.a $LN\n</ifexists>\n<ifexists $090.a $090.b >\n    <style b>Classificação: <style color=DarkCyan | font-size=13px> $090.a $090.b</style></style>$LN\n</ifexists>\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>\n<getevaluation $001.a></getevaluation>	<ifexists $245.a >\n    <style b>\n        Título:\n    </style>\n    $245.a\n    <ifexists $245.b>: $245.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $100.a >\n    <style b>\n    Autor:\n    </style>\n    $100.a $LN\n</ifexists>\n<ifexists $250.a >\n    <style b>\n    Edição:\n    </style>\n    $250.a $LN\n</ifexists>\n<ifexists $090.a $090.b >\n    <style b>Classificação: <style color=DarkCyan | font-size=13px> $090.a $090.b</style></style>$LN\n</ifexists>\n<ifexists $362.a >\n    <style b>\n    Datas de Publicação / Indicação de Sequência: $362.a </style>$LN\n</ifexists>\n<ifexists $246.a >\n    <style b>\n        Título/título Abreviado:\n    </style>\n    $246.a\n    <ifexists $246.b>: $246.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $650.a $653.a >\n    <style b>\n    Assunto:\n    </style>\n    $650.a $653.a $LN\n</ifexists>\n<ifexists $245.h >\n    <style b>\n    Meio Físico:\n    </style>\n    $245.h $LN\n</ifexists>\n<ifexists $245.k >\n    <style b>\n    Forma:\n    </style>\n    $245.k $LN\n</ifexists>\n<ifexists $310.a >\n    <style b>\n    Periodicidade:\n    </style>\n    $310.a $LN\n</ifexists>\n<ifexists $700.a >\n    <style b>\n    Nome pessoal:\n    </style>\n    $700.a $LN\n</ifexists>\n<ifexists $710.a >\n    <style b>\n    Nome pessoal:\n    </style>\n    $710.a $LN\n</ifexists>\n<ifexists $711.a >\n    <style b>\n    Nome do evento ou jurisdição:\n    </style>\n    $711.a - $711.d - $711.n $LN\n</ifexists>\n<ifexists $740.a >\n    <style b>\n    Título relacionado / Analítico não controlado:\n    </style>\n    $740.a $LN\n</ifexists>\n<ifexists $440.a >\n    <style b>\n    Título da série:\n    </style>\n    $440.a $LN\n</ifexists>\n<ifexists $500.a >\n    <style b>\n    Nota geral:\n    </style>\n    $500.a $LN\n</ifexists>\n<ifexists $502.a >\n    <style b>\n    Nota de Dissertação ou Tese:\n    </style>\n    $502.a $LN\n</ifexists>\n<ifexists $510.a >\n    <style b>\n    Nome da fonte:\n    </style>\n    $510.a $LN\n</ifexists>\n<ifexists $520.a >\n    <style b>\n    Nota de Resumo:\n    </style>\n    $520.a $LN\n</ifexists>\n<ifexists $590.a >\n    <style b>\n    Notas locais:\n    </style>\n    $590.a $LN\n</ifexists>\n<ifexists $773.t >\n    <style b>\n    Título:\n    </style>\n    $773.t $LN\n</ifexists>\n<ifexists $780.a >\n    <style b>\n    Título da entrada principal:\n    </style>\n    $780.a $LN\n</ifexists>\n<ifexists $780.t >\n    <style b>\n    Titulo:\n    </style>\n    $780.t $LN\n</ifexists>\n<ifexists $785.a >\n    <style b>\n    Título da entrada principal:\n    </style>\n    $785.a $LN\n</ifexists>\n<ifexists $111.d >\n    <style b>\n    Nome de Evento ou Jurisdição:\n    </style>\n    $111.d $LN\n</ifexists>\n<ifexists $111.n >\n    <style b>\n    Número de Parte/Seção/Evento:\n    </style>\n    $111.n $LN\n</ifexists>\n<ifexists $041.a >\n    <style b>\n    Código de Idioma do Texto/trilha Sonora ou Título Diferente:\n    </style>\n    $041.a $LN\n</ifexists>\n<ifexists $260.a >\n    <style b>\n    Lugar de Publicação, Distribuição, etc.:\n    </style>\n    $260.a $LN\n</ifexists>\n<ifexists $260.b >\n    <style b>\n    Nome do Editor, Distribuidor, etc.:\n    </style>\n    $260.b $LN\n</ifexists>\n<ifexists $260.c >\n    <style b>\n    Data de Publicação, Distribuição, etc.:\n    </style>\n    $260.c $LN\n</ifexists>\n<ifexists $856.u >\n    <style b>\n    Localizador da fonte (endereço eletrônico):\n    </style>\n    $856.u $LN\n</ifexists>\n<ifexists $110.a >\n    <style b>\n    Nome Corporativo ou Nome da Jurisdição:\n    </style>\n    $110.a $LN\n</ifexists>\n<ifexists $300.a >\n    <style b>\n    Extensão:\n    </style>\n    $300.a $LN\n</ifexists>\n<ifexists $300.e >\n    <style b>\n    Extensão:\n    </style>\n    $300.e $LN\n</ifexists>\n<ifexists $505.a >\n    <style b>\n    Nota de conteúdo:\n    </style>\n    $505.a $LN\n</ifexists>\n<ifexists $947.a >\n    <style b>\n    Código do editor/fornecedor:\n    </style>\n    $947.a $LN\n</ifexists>
7	BK	<ifexists $111.a>\n<upper>$111.a</upper>, \n$111.n., \n$111.d, \n$111.c. \n<style b>\n<pregmatch ^[\\w]{0,} | $245.a></pregmatch>... \n</style>\n$260.a: \n$260.b, \n$260.c.\n<compare ($001.a 901.c) | != | 1 >\n<compare ($001.a 901.c) | = | 4 >\n1 videocassete.\n</compare>\n<compare ($001.a 901.c) | != | 4 >\n1 901.c.\n</compare>\n</compare>\n</ifexists>\n<ifNotExists $111.a>\n<ifNotExists $100.a>\n<ifexists $700.a>\n<getauthors700aabntformat $001.a></getauthors700aabntformat> \n</ifexists>\n<ifNotExists $700.a>\n<gettitleabntfotmated $001.a | 245.a></gettitleabntfotmated>\n</ifNotExists>  \n</ifNotExists>\n<ifexists $100.a>\n<upper><pregmatch ^[\\w]{0,} | $100.a></pregmatch></upper>,\n<pregmatch [\\w\\s.]{0,}$ | $100.a></pregmatch>. \n</ifexists>\n<ifNotExists $100.a>\n<ifExists $700.a>\n<style b>$245.a</style>\n<ifexists $245.b>\n: $245.b\n</ifexists>.\n</ifExists>  \n</ifNotExists>\n<ifExists $100.a>\n<ifNotExists $700.a>\n<style b>$245.a</style>\n<ifexists $245.b>\n: $245.b\n</ifexists>.\n</ifNotExists>  \n</ifExists>\n<ifExists $100.a>\n<ifExists $700.a>\n<style b>$245.a</style>\n<ifexists $245.b>\n: $245.b\n</ifexists>.\n</ifExists>  \n</ifExists>\n<compare ($001.a 901.a) | = | 2 >\n$260.c. $300.a f. $502.a\n<compare ($001.a 901.c) | != | 1 >\n<compare ($001.a 901.c) | = | 4 >\n1 videocassete.\n</compare>\n<compare ($001.a 901.c) | != | 4 >\n1 901.c.\n</compare>\n</compare>\n</compare>\n<compare ($001.a 901.a) | = | 3 >\n$260.c. $300.a f. $502.a\n<compare ($001.a 901.c) | != | 1 >\n<compare ($001.a 901.c) | = | 4 >\n1 videocassete.\n</compare>\n<compare ($001.a 901.c) | != | 4 >\n1 901.c.\n</compare>\n</compare>\n</compare>\n<compare ($001.a 901.a) | = | 4 >\n$260.c. $300.a f. $502.a\n<compare ($001.a 901.c) | != | 1 >\n<compare ($001.a 901.c) | = | 4 >\n1 videocassete.\n</compare>\n<compare ($001.a 901.c) | != | 4 >\n1 901.c.\n</compare>\n</compare>\n</compare>\n<compare ($001.a 901.a) | = | 5 >\n$260.c. $300.a f. $502.a\n<compare ($001.a 901.c) | != | 1 >\n<compare ($001.a 901.c) | = | 4 >\n1 videocassete.\n</compare>\n<compare ($001.a 901.c) | != | 4 >\n1 901.c.\n</compare>\n</compare>\n</compare>\n<compare ($001.a 901.a) | != | 2 >\n<compare ($001.a 901.a) | != | 3 >\n<compare ($001.a 901.a) | != | 4 >\n<compare ($001.a 901.a) | != | 5 >\n$260.a: $260.b, $260.c.\n</compare>\n</compare>\n</compare>\n</compare>\n</ifNotExists>\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>\n<getevaluation $001.a></getevaluation>	<ifexists $111.a>\n<upper>$111.a</upper>, \n$111.n., \n$111.d, \n$111.c. \n<style b>\n<pregmatch ^[\\w]{0,} | $245.a></pregmatch>... \n</style>\n$260.a: \n$260.b, \n$260.c.\n<compare ($001.a 901.c) | != | 1 >\n<compare ($001.a 901.c) | = | 4 >\n1 videocassete.\n</compare>\n<compare ($001.a 901.c) | != | 4 >\n1 901.c.\n</compare>\n</compare>\n</ifexists>\n<ifNotExists $111.a>\n<ifNotExists $100.a>\n<ifexists $700.a>\n<getauthors700aabntformat $001.a></getauthors700aabntformat> \n</ifexists>\n<ifNotExists $700.a>\n<gettitleabntfotmated $001.a | 245.a></gettitleabntfotmated>\n</ifNotExists>  \n</ifNotExists>\n<ifexists $100.a>\n<upper><pregmatch ^[\\w]{0,} | $100.a></pregmatch></upper>,\n<pregmatch [\\w\\s.]{0,}$ | $100.a></pregmatch>. \n</ifexists>\n<ifNotExists $100.a>\n<ifExists $700.a>\n<style b>$245.a</style>\n<ifexists $245.b>\n: $245.b\n</ifexists>.\n</ifExists>  \n</ifNotExists>\n<ifExists $100.a>\n<ifNotExists $700.a>\n<style b>$245.a</style>\n<ifexists $245.b>\n: $245.b\n</ifexists>.\n</ifNotExists>  \n</ifExists>\n<ifExists $100.a>\n<ifExists $700.a>\n<style b>$245.a</style>\n<ifexists $245.b>\n: $245.b\n</ifexists>.\n</ifExists>  \n</ifExists>\n<compare ($001.a 901.a) | = | 2 >\n$260.c. $300.a f. $502.a\n<compare ($001.a 901.c) | != | 1 >\n<compare ($001.a 901.c) | = | 4 >\n1 videocassete.\n</compare>\n<compare ($001.a 901.c) | != | 4 >\n1 901.c.\n</compare>\n</compare>\n</compare>\n<compare ($001.a 901.a) | = | 3 >\n$260.c. $300.a f. $502.a\n<compare ($001.a 901.c) | != | 1 >\n<compare ($001.a 901.c) | = | 4 >\n1 videocassete.\n</compare>\n<compare ($001.a 901.c) | != | 4 >\n1 901.c.\n</compare>\n</compare>\n</compare>\n<compare ($001.a 901.a) | = | 4 >\n$260.c. $300.a f. $502.a\n<compare ($001.a 901.c) | != | 1 >\n<compare ($001.a 901.c) | = | 4 >\n1 videocassete.\n</compare>\n<compare ($001.a 901.c) | != | 4 >\n1 901.c.\n</compare>\n</compare>\n</compare>\n<compare ($001.a 901.a) | = | 5 >\n$260.c. $300.a f. $502.a\n<compare ($001.a 901.c) | != | 1 >\n<compare ($001.a 901.c) | = | 4 >\n1 videocassete.\n</compare>\n<compare ($001.a 901.c) | != | 4 >\n1 901.c.\n</compare>\n</compare>\n</compare>\n<compare ($001.a 901.a) | != | 2 >\n<compare ($001.a 901.a) | != | 3 >\n<compare ($001.a 901.a) | != | 4 >\n<compare ($001.a 901.a) | != | 5 >\n$260.a: $260.b, $260.c.\n</compare>\n</compare>\n</compare>\n</compare>\n</ifNotExists>\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>
4	DF	<ifexists $245.a >\n    <style b>\n        Título:\n    </style>\n    $245.a\n    <ifexists $245.b>: $245.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $100.a >\n    <style b>\n    Autor:\n    </style>\n    $100.a $LN\n</ifexists>\n<ifexists $090.a $090.b >\n    <style b>Classificação: <style color=DarkCyan | font-size=13px> $090.a $090.b</style></style>$LN\n</ifexists>\n<ifexists $362.a >\n    <style b>\n    Datas de Publicação / Indicação de Sequência:\n    </style>\n    $362.a $LN\n</ifexists>\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>\n<getevaluation $001.a></getevaluation>	<ifexists $245.a >\n    <style b>\n        Título:\n    </style>\n    $245.a\n    <ifexists $245.b>: $245.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $100.a >\n    <style b>\n    Autor:\n    </style>\n    $100.a $LN\n</ifexists>\n<ifexists $090.a $090.b >\n    <style b>Classificação: <style color=DarkCyan | font-size=13px> $090.a $090.b</style></style>$LN\n</ifexists>\n<ifexists $362.a >\n    <style b>\n    Datas de Publicação / Indicação de Sequência:\n    </style>\n    $362.a $LN\n</ifexists>\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>
1	SA	<ifexists $245.a >\n    <style b>\n        Título:\n    </style>\n    $245.a\n    <ifexists $245.b >:$245.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $260.c >\n    <style b>\n    Data de Publicação, Distribuição, etc.:\n    </style>\n    $260.c $LN\n</ifexists>\n<ifexists $090.a $090.b >\n    <style b>Classificação:</style>\n    <style color=DarkCyan | font-size=13px>$090.a $090.b</style> $LN\n</ifexists>\n<ifexists $362.a >\n    <style b>\n    Datas de Publicação / Indicação de Sequência:\n    </style>\n    <style color=DarkCyan | font-size=13px>$362.a</style> $LN\n</ifexists>\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>\n<getevaluation $001.a></getevaluation>	<ifexists $245.a >\n    <style b>\n        Título:\n    </style>\n    $245.a\n    <ifexists $245.b >:$245.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $260.c >\n    <style b>\n    Data de Publicação, Distribuição, etc.:\n    </style>\n    $260.c $LN\n</ifexists>\n<ifexists $090.a $090.b >\n    <style b>Classificação:</style>\n    <style color=DarkCyan | font-size=13px>$090.a $090.b</style> $LN\n</ifexists>\n<ifexists $362.a >\n    <style b>\n    Datas de Publicação / Indicação de Sequência:\n    </style>\n    <style color=DarkCyan | font-size=13px>$362.a</style> $LN\n</ifexists>\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>
3	DF	<ifexists $245.a >\n    <style b>\n        Título:\n    </style>\n    $245.a\n    <ifexists $245.b>: $245.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $100.a >\n    <style b>\n    Autor:\n    </style>\n    $100.a $LN\n</ifexists>\n<ifexists $090.a $090.b >\n    <style b>Classificação: <style color=DarkCyan | font-size=13px> $090.a $090.b</style></style>$LN\n</ifexists>\n<ifexists $362.a >\n    <style b>\n    Datas de Publicação / Indicação de Sequência:\n    </style>\n    $362.a $LN\n</ifexists>\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>\n<getevaluation $001.a></getevaluation>	<ifexists $245.a >\n    <style b>\n        Título:\n    </style>\n    $245.a\n    <ifexists $245.b>: $245.b</ifexists>\n    $LN\n</ifexists>\n<ifexists $100.a >\n    <style b>\n    Autor:\n    </style>\n    $100.a $LN\n</ifexists>\n<ifexists $090.a $090.b >\n    <style b>Classificação: <style color=DarkCyan | font-size=13px> $090.a $090.b</style></style>$LN\n</ifexists>\n<ifexists $362.a >\n    <style b>\n    Datas de Publicação / Indicação de Sequência:\n    </style>\n    $362.a $LN\n</ifexists>\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>
6	DF	<ifexists $245.a >\n    <style b>Titulo:</style>$245.a\n    <ifexists $245.b>: $245.b</ifexists>$LN\n</ifexists>\n<ifexists $100.a >\n    <style b>Autor:</style>$100.a $LN\n</ifexists>\n<ifexists $110.a >\n    <style b>Nome Corporativo ou Nome da Jurisdição:</style>$110.a $LN\n</ifexists>\n<ifexists $111.a >\n    <style b>Nome de Evento ou Jurisdição:</style>$111.a $LN\n</ifexists>\n<ifexists $400.a >\n    <style b>Título da série:</style>$400.a $LN\n</ifexists>\n<ifexists $700.a >\n    <style b>Nome pessoal:</style>$700.a $LN\n</ifexists>\n<ifexists $800.a >\n    <style b>Nome pessoal:</style>$800.a $LN\n</ifexists>\n<ifexists $090.a $090.b >\n    <style b>Classificação:<style color=DarkCyan> $090.a $090.b</style></style> $LN\n</ifexists>\n<ifexists $080.a >\n    <style b>Número de Classificação Decimal Universal:<style color=DarkCyan> $080.a </style></style> $LN\n</ifexists>\n<ifexists $082.a >\n    <style b>Número de Classificação:<style color=DarkCyan> $082.a </style></style> $LN\n</ifexists>\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>\n<getevaluation $001.a></getevaluation>	001.a == $001.a $LN\n005.a == $005.a $LN\n008.a == $008.a $LN\n035.a == $035.a $LN\n040.a == $040.a $LN\n040.c == $040.c $LN\n040.d == $040.d $LN\n100.a == $100.a $LN\n100.d == $100.d $LN\n245.a == $245.a $LN\n245.b == $245.b $LN\n245.c == $245.c $LN\n260.a == $260.a $LN\n260.b == $260.b $LN\n260.c == $260.c $LN\n300.a == $300.a $LN\n300.c == $300.c $LN\n490.a == $490.a $LN\n490.v == $490.v $LN\n500.a == $500.a $LN\n650.a == $650.a $LN\n700.a == $700.a $LN\n700.d == $700.d $LN\n752.a == $752.a $LN\n752.d == $752.d $LN\n830.a == $830.a $LN\n830.v == $830.v $LN\n852.8 == $852.8 $LN\n852.a == $852.a $LN\n852.b == $852.b $LN\n852.h == $852.h $LN\n852.i == $852.i $LN\n852.j == $852.j $LN\n079.a == $079.a $LN\n090.a == $090.a $LN\n090.b == $090.b $LN\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>
7	SA	<ifNotExists $100.a>\n<ifexists $700.a>\n<getauthors700aabntformat $001.a></getauthors700aabntformat> \n</ifexists>\n<ifNotExists $700.a>\n<gettitleabntfotmated $001.a | 245.a></gettitleabntfotmated>\n</ifNotExists>  \n</ifNotExists>\n<ifexists $100.a>\n<upper><pregmatch ^[\\w]{0,} | $100.a></pregmatch></upper>,\n<pregmatch [\\w\\s.]{0,}$ | $100.a></pregmatch>. \n</ifexists>\n<ifNotExists $100.a>\n<ifExists $700.a>\n$245.a\n<ifexists $245.b>\n<gtcSeparator $001.a | 245.a | # | 245.b></gtcSeparator> \n$245.b\n</ifexists>.\n</ifExists>  \n</ifNotExists>\n<ifExists $100.a>\n<ifNotExists $700.a>\n$245.a\n<ifexists $245.b>\n<gtcSeparator $001.a | 245.a | # | 245.b></gtcSeparator> \n$245.b\n</ifexists>.\n</ifNotExists>  \n</ifExists>\n<ifExists $100.a>\n<ifExists $700.a>\n$245.a\n<ifexists $245.b>\n<gtcSeparator $001.a | 245.a | # | 245.b></gtcSeparator> \n$245.b\n</ifexists>.\n</ifExists>  \n</ifExists>\n<style b>$773.t</style>, \n<gettagdescription $773.w | 260.a | 1 >_DESCRIPTION_, </gettagdescription>\n<pregmatch v. [0-9]{0,20}, n. [0-9 a-z.]{0,50} | $362.a></pregmatch>, \np. $300.a, \n<pregmatch [0-9]{4}$ | $362.a></pregmatch>\n<gettagdescription $773.w | 245.h | 1 >1 _DESCRIPTION_</gettagdescription>.\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>\n<getevaluation $001.a></getevaluation>	<ifNotExists $100.a>\n<ifexists $700.a>\n<getauthors700aabntformat $001.a></getauthors700aabntformat> \n</ifexists>\n<ifNotExists $700.a>\n<gettitleabntfotmated $001.a | 245.a></gettitleabntfotmated>\n</ifNotExists>  \n</ifNotExists>\n<ifexists $100.a>\n<upper><pregmatch ^[\\w]{0,} | $100.a></pregmatch></upper>,\n<pregmatch [\\w\\s.]{0,}$ | $100.a></pregmatch>. \n</ifexists>\n<ifNotExists $100.a>\n<ifExists $700.a>\n$245.a\n<ifexists $245.b>\n<gtcSeparator $001.a | 245.a | # | 245.b></gtcSeparator> \n$245.b\n</ifexists>.\n</ifExists>  \n</ifNotExists>\n<ifExists $100.a>\n<ifNotExists $700.a>\n$245.a\n<ifexists $245.b>\n<gtcSeparator $001.a | 245.a | # | 245.b></gtcSeparator> \n$245.b\n</ifexists>.\n</ifNotExists>  \n</ifExists>\n<ifExists $100.a>\n<ifExists $700.a>\n$245.a\n<ifexists $245.b>\n<gtcSeparator $001.a | 245.a | # | 245.b></gtcSeparator> \n$245.b\n</ifexists>.\n</ifExists>  \n</ifExists>\n<style b>$773.t</style>, \n<gettagdescription $773.w | 260.a | 1 >_DESCRIPTION_, </gettagdescription>\n<pregmatch v. [0-9]{0,20}, n. [0-9 a-z.]{0,50} | $362.a></pregmatch>, \np. $300.a, \n<pregmatch [0-9]{4}$ | $362.a></pregmatch>\n<gettagdescription $773.w | 245.h | 1 >1 _DESCRIPTION_</gettagdescription>.\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>
7	SE	<upper>\n$245.a\n</upper>\n<ifexists $245.b>\n<gtcSeparator $001.a | 245.a | # | 245.b></gtcSeparator> $245.b\n</ifexists>. \n<ifexists $260.a>\n$260.a: $260.b, $260.c. \n<ifexists $245.h>\n1 $245.h. \n</ifexists>\n</ifexists>\n<ifNotExists $260.a>\n<gettagdescription $773.w | 260.a >_DESCRIPTION_, </gettagdescription> \n<gettagdescription $773.w | 260.b >_DESCRIPTION_, </gettagdescription> \n$362.a. \n<gettagdescription $773.w | 245.h >1 _DESCRIPTION_.</gettagdescription>\n</ifNotExists>\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>\n<getevaluation $001.a></getevaluation>	<upper>\n$245.a\n</upper>\n<ifexists $245.b>\n<gtcSeparator $001.a | 245.a | # | 245.b></gtcSeparator> $245.b\n</ifexists>. \n<ifexists $260.a>\n$260.a: $260.b, $260.c. \n<ifexists $245.h>\n1 $245.h. \n</ifexists>\n</ifexists>\n<ifNotExists $260.a>\n<gettagdescription $773.w | 260.a >_DESCRIPTION_, </gettagdescription> \n<gettagdescription $773.w | 260.b >_DESCRIPTION_, </gettagdescription> \n$362.a. \n<gettagdescription $773.w | 245.h >1 _DESCRIPTION_.</gettagdescription>\n</ifNotExists>\n<ifexists $856.u >\n    <style b>Arquivo digital: </style >\n    <href $856.u | -#- ></href>$LN\n</ifexists>
10	DF	<gtcIso2709 $001.a></gtcIso2709>	<gtcIso2709 $001.a></gtcIso2709>
\.


--
-- Data for Name: gtcsearchtableupdatecontrol; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcsearchtableupdatecontrol (lastupdate) FROM stdin;
2010-07-16 09:15:50.174814
\.


--
-- Data for Name: gtcseparator; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcseparator (separatorid, cataloguingformatid, fieldid, subfieldid, content, fieldid2, subfieldid2) FROM stdin;
1	1	245	a	:	245	b
\.


--
-- Data for Name: gtcsoapaccess; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcsoapaccess (soapclientid, webserviceid, bug_dia2sql_ignorar) FROM stdin;
1	1	\N
1	2	\N
1	3	\N
1	4	\N
1	5	\N
1	21	\N
1	22	\N
1	23	\N
1	24	\N
1	41	\N
1	42	\N
1	43	\N
1	44	\N
1	61	\N
1	80	\N
1	99	\N
\.


--
-- Data for Name: gtcsoapclient; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcsoapclient (soapclientid, clientdescription, ip, password, enable) FROM stdin;
1	LocalHost	127.0.0.1	123456	t
\.


--
-- Data for Name: gtcspreadsheet; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcspreadsheet (category, level, field, required, repeatfieldrequired, defaultvalue, menuname, menuoption, menulevel) FROM stdin;
\.


--
-- Data for Name: gtcsupplier; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcsupplier (supplierid, name, companyname, date) FROM stdin;
\.


--
-- Data for Name: gtcsuppliertypeandlocation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcsuppliertypeandlocation (supplierid, type, name, companyname, cnpj, location, neighborhood, city, zipcode, phone, fax, alternativephone, email, alternativeemail, contact, site, observation, bankdeposit, date, bug_dia2sql_ignorar) FROM stdin;
\.


--
-- Data for Name: gtctag; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtctag (fieldid, subfieldid, description, observation, isrepetitive, hassubfield, isactive, indemonstration, isobsolete, help) FROM stdin;
034	p	Equinócio	\N	f	f	t	f	f	\N
507	6	Ligação	\N	f	f	t	f	f	\N
710	u	Afiliação	\N	f	f	t	f	f	\N
036	b	Fonte	\N	f	f	t	f	f	\N
015	6	Ligação	\N	f	f	t	f	f	\N
082	b	Número do item	\N	f	f	t	f	f	\N
777	n	Nota	\N	t	f	t	f	f	\N
949	5	Material que acompanha	\N	t	f	t	f	f	\N
000	a	Lider	\N	f	f	f	f	f	\N
000	#	Líder	\N	f	f	t	f	f	\N
003	#	Identificador do Número de Controle	\N	f	f	t	f	f	\N
006	#	Material Adicional	\N	f	f	t	f	f	\N
007	#	Campos de descrição física	\N	f	f	t	f	f	\N
005	#	Data e Hora da Última intervenção	\N	f	f	t	f	f	\N
008	#	Campo fixo de dados	\N	f	f	t	f	f	\N
010	#	Numero de Controle da LC	\N	f	t	t	f	f	\N
013	#	Controle de Informação de Patente	\N	t	t	t	f	f	\N
015	#	Número Bibliográfico Nacional	\N	f	t	t	f	f	\N
016	#	Instituição que Atribuiu o Número Bibliográfico Nacional	\N	t	t	t	f	f	\N
017	#	Número de CopyRight	\N	t	t	t	f	f	\N
018	#	Taxa de Cobrança de CopyRight	\N	f	t	t	f	f	\N
020	#	ISBN - International Standard Book Number	\N	t	t	t	f	f	\N
022	#	ISSN - International Standard Serial Number	\N	t	t	t	f	f	\N
010	a	Numero de Controle da LC	\N	f	f	t	f	f	\N
010	b	Numero de Controle NUCMC	\N	t	f	t	f	f	\N
010	c	Numero de Controle Cancelado/Invalido	\N	t	f	t	f	f	\N
010	8	Numero de Ligação e Seqüência	\N	t	f	t	f	f	\N
013	a	Número	\N	f	f	t	f	f	\N
013	b	País	\N	f	f	t	f	f	\N
013	c	Tipo de Número	\N	f	f	t	f	f	\N
013	d	Data	\N	t	f	t	f	f	\N
013	e	Status	\N	t	f	t	f	f	\N
013	f	Participa do Documento	\N	t	f	t	f	f	\N
013	6	Ligação	\N	f	f	t	f	f	\N
015	a	Número Bibliográfico Nacional	\N	t	f	t	f	f	\N
521	b	Fonte	\N	f	f	t	f	f	\N
544	n	Nota	\N	t	f	t	f	f	\N
787	6	Ligação	\N	f	f	t	f	f	\N
856	i	Instrução	\N	t	f	t	f	f	\N
960	y	Data de Entrada	\N	t	\N	t	f	f	\N
015	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
016	a	Número de Controle do Registro	\N	f	f	t	f	f	\N
016	z	Número de Controle Cancelado/Inválido	\N	t	f	t	f	f	\N
016	2	Fonte	\N	f	f	t	f	f	\N
016	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
017	a	Número de CopyRight	\N	t	f	t	f	f	\N
017	b	Fonte (Instituição que atribuiu o número)	\N	t	f	t	f	f	\N
017	6	Ligação	\N	f	f	t	f	f	\N
017	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
018	a	Taxa de Cobrança de CopyRight	\N	f	f	t	f	f	\N
020	a	ISBN - International Standard Book Number	\N	f	f	t	f	f	\N
020	c	Termos de Avaliação	\N	f	f	t	f	f	\N
020	z	ISBN Cancelado/Inválido	\N	t	f	t	f	f	\N
020	6	Ligação	\N	f	f	t	f	f	\N
020	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
022	a	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
022	y	ISSN Incorreto	\N	t	f	t	f	f	\N
022	z	ISSN Cancelado	\N	t	f	t	f	f	\N
022	6	Ligação	\N	f	f	t	f	f	\N
022	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
024	#	Outros números ou códigos padrão	\N	t	t	t	f	f	\N
024	a	Standard Recording Code	\N	f	f	t	f	f	\N
024	c	Termos de Avaliação	\N	f	f	t	f	f	\N
024	d	Código Adicional Seguindo Número/Código padrão	\N	f	f	t	f	f	\N
024	z	Código Padrão Cancelado/Inválido	\N	t	f	t	f	f	\N
024	2	Fonte do Código ou Número	\N	f	f	t	f	f	\N
024	6	Ligação	\N	f	f	t	f	f	\N
024	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
025	#	Número de Aquisição no Exterior	\N	t	t	t	f	f	\N
025	a	Número de Aquisição no Exterior	\N	t	f	t	f	f	\N
025	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
027	#	Número Padrão de Relatório Técnico (STRN)	\N	t	t	t	f	f	\N
027	a	Número Padrão de Relatório Técnico (STRN)	\N	f	f	t	f	f	\N
027	z	STRN Cancelado/Inválido	\N	t	f	t	f	f	\N
027	6	Ligação	\N	f	f	t	f	f	\N
027	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
028	#	Número do Editor Para Música	\N	t	t	t	f	f	\N
028	a	Número do Editor	\N	f	f	t	f	f	\N
028	b	Fonte	\N	f	f	t	f	f	\N
028	6	Ligação	\N	f	f	t	f	f	\N
028	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
030	#	Número CODEN	\N	t	t	t	f	f	\N
030	a	CODEN	\N	f	f	t	f	f	\N
030	z	CODEN Cancelado/Inválido	\N	t	f	t	f	f	\N
030	6	Ligação	\N	f	f	t	f	f	\N
030	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
032	#	Número de Registro Postal	\N	t	t	t	f	f	\N
032	a	Número de Registro Postal	\N	f	f	t	f	f	\N
032	b	Fonte (Instituição que Atribuiu o número)	\N	f	f	t	f	f	\N
032	6	Ligação	\N	f	f	t	f	f	\N
032	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
033	#	Data/Hora e Lugar de um Evento	\N	t	t	t	f	f	\N
033	a	Data/Hora Formatada	\N	t	f	t	f	f	\N
033	b	Código de Classificação geográfica de área	\N	t	f	t	f	f	\N
033	c	Código de Classificação geográfica de Sub-Área	\N	t	f	t	f	f	\N
033	3	Materiais Específicos	\N	f	f	t	f	f	\N
033	6	Ligação	\N	f	f	t	f	f	\N
033	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
034	#	Dado Cartográfico Matemático Codificado	\N	t	t	t	f	f	\N
034	a	Categoria da Escala	\N	f	f	t	f	f	\N
034	b	Constante da Escala Horizontal Linear	\N	t	f	t	f	f	\N
034	c	Constante da Escala Vertical Linear	\N	t	f	t	f	f	\N
034	d	Coordenadas-longitude oeste	\N	f	f	t	f	f	\N
034	e	Coordenadas-longitude leste	\N	f	f	t	f	f	\N
034	f	Coordenadas-latitude norte	\N	f	f	t	f	f	\N
034	g	Coordenadas-latitude sul	\N	f	f	t	f	f	\N
034	h	Escala angular	\N	t	f	t	f	f	\N
034	j	Declinação - Limite Norte	\N	f	f	t	f	f	\N
034	k	Declinação - Limite Sul	\N	f	f	t	f	f	\N
034	m	Right Ascension - limite leste	\N	f	f	t	f	f	\N
034	n	Right Ascension - limite oeste	\N	f	f	t	f	f	\N
034	s	G-ring latitude	\N	t	f	t	f	f	\N
034	t	G-ring longitude	\N	t	f	t	f	f	\N
034	6	Ligação	\N	f	f	t	f	f	\N
034	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
035	#	Número de Controle do Sistema	\N	t	t	t	f	f	\N
035	a	Número de Controle do Sistema	\N	f	f	t	f	f	\N
035	z	Número de Controle do Sistema Cancelado/Inválido	\N	t	f	t	f	f	\N
035	6	Ligação	\N	f	f	t	f	f	\N
035	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
036	#	Número de Estudo Original para Arquivos de Computador	\N	f	t	t	f	f	\N
036	a	Número de Estudo Original	\N	f	f	t	f	f	\N
036	6	Ligação	\N	f	f	t	f	f	\N
036	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
037	#	Fonte de Aquisição	\N	t	t	t	f	f	\N
037	a	Código de Estoque do Fornecedor	\N	f	f	t	f	f	\N
037	b	Fonte do Código de Estoque/Aquisição	\N	f	f	t	f	f	\N
037	c	Termos de Avaliação	\N	t	f	t	f	f	\N
037	f	Formas de Edição	\N	t	f	t	f	f	\N
037	g	Característica Adicional do Formato	\N	t	f	t	f	f	\N
037	n	Nota	\N	t	f	t	f	f	\N
037	6	Ligação	\N	f	f	t	f	f	\N
037	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
040	#	Fonte de Catalogação	\N	f	t	t	f	f	\N
040	a	Instituição da Catalogação Original	\N	f	f	t	f	f	\N
040	b	Idioma de Catalogação	\N	f	f	t	f	f	\N
040	c	Instituição que transcreveu o Registro	\N	f	f	t	f	f	\N
040	d	Instituição que Modificou o Registro	\N	t	f	t	f	f	\N
040	e	Convenções da Descrição	\N	f	f	t	f	f	\N
040	6	Ligação	\N	f	f	t	f	f	\N
040	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
041	c	Idioma do Título Diferente/Idioma da Tradução Disponível	\N	f	f	t	f	t	\N
041	#	Código de Idioma	\N	f	t	t	f	f	\N
041	a	Código de Idioma do Texto/trilha Sonora ou Título Diferente	\N	f	f	t	f	f	\N
041	b	Código de Idioma do Sumário ou Resumo/Outro Título ou Subtítulo	\N	f	f	t	f	f	\N
041	d	Código do Idioma do Texto Falado ou Cantado	\N	f	f	t	f	f	\N
041	e	Código do Idioma do Libreto	\N	f	f	t	f	f	\N
041	f	Código do Idioma da Tabela de Conteúdo	\N	f	f	t	f	f	\N
041	g	Código do Idioma do material complementar que não Libreto	\N	f	f	t	f	f	\N
041	h	Código do Idioma do Original e/ou Traduções Intermediárias do Texto	\N	t	f	t	f	f	\N
041	6	Ligação	\N	f	f	t	f	f	\N
041	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
042	#	Código de Autenticação	\N	f	t	t	f	f	\N
042	a	Código de Autenticação	\N	t	f	t	f	f	\N
043	#	Código de Área Geográfica	\N	f	t	t	f	f	\N
043	a	Código de Área Geográfica	\N	t	f	t	f	f	\N
043	b	Código de Área Geográfica Local	\N	t	f	t	f	f	\N
043	2	Fonte do Código	\N	t	f	t	f	f	\N
043	6	Ligação	\N	f	f	t	f	f	\N
043	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
044	#	Código do País da Empresa de Publicação/Produção	\N	f	t	t	f	f	\N
044	a	Código do País da Empresa de Publicadora/Produtora	\N	t	f	t	f	f	\N
044	b	Código do Local da Sub-Entidade	\N	t	f	t	f	f	\N
044	c	Código ISO da Sub-Entidade	\N	t	f	t	f	f	\N
044	2	Fonte do Código do Local Sub-Entidade	\N	t	f	t	f	f	\N
044	6	Ligação	\N	f	f	t	f	f	\N
044	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
045	#	Código de Período Cronológico	\N	f	t	t	f	f	\N
045	a	Código de Período de Tempo	\N	t	f	t	f	f	\N
045	b	Formatada Abrangendo Per. de 9999 D.C. em diante	\N	t	f	t	f	f	\N
045	c	Formatada Pré-9999 A.C.	\N	t	f	t	f	f	\N
045	6	Ligação	\N	f	f	t	f	f	\N
045	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
046	#	Código do Tipo de Data, Data 1, Data 2 (Datas A.C.)	\N	f	t	t	f	f	\N
046	a	Código do Tipo de Data	\N	f	f	t	f	f	\N
046	b	Data 1 (A.C.)	\N	f	f	t	f	f	\N
046	c	Data 1 (D.C.)	\N	f	f	t	f	f	\N
046	d	Data 2 (A.C.)	\N	f	f	t	f	f	\N
046	e	Data 2 (D.C.)	\N	f	f	t	f	f	\N
046	6	Ligação	\N	f	f	t	f	f	\N
046	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
047	#	Código da forma de composição musical	\N	f	t	t	f	f	\N
047	a	Código da forma de composição musical	\N	t	f	t	f	f	\N
047	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
048	#	Código do número de instrumentos e vozes	\N	t	t	t	f	f	\N
048	a	Músico ou grupo	\N	t	f	t	f	f	\N
048	b	Solista	\N	t	f	t	f	f	\N
048	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
050	#	Número de chamada da Library of Congress	\N	t	t	t	f	f	\N
050	a	Número de classificação	\N	t	f	t	f	f	\N
050	b	Número do item	\N	f	f	t	f	f	\N
050	d	Número de classificação suplementar (MU)	\N	f	f	t	f	t	\N
050	3	Materiais especificados	\N	f	f	t	f	f	\N
050	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
051	#	Informação LC de cópia, edição e separata	\N	t	t	t	f	f	\N
051	a	Número de classificação	\N	f	f	t	f	f	\N
051	b	Número de item	\N	f	f	t	f	f	\N
051	c	Informação de cópia	\N	f	f	t	f	f	\N
051	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
052	#	Código de Classificação geográfica	\N	t	t	t	f	f	\N
052	a	Código de Classificação de área geográfica	\N	f	f	t	f	f	\N
052	b	Código de Classificação de sub-área geográfica	\N	t	f	t	f	f	\N
052	d	Nome do lugar povoado	\N	t	f	t	f	f	\N
052	2	Código da Fonte	\N	f	f	t	f	f	\N
052	6	Ligação	\N	f	f	t	f	f	\N
052	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
055	#	Número de chamada/Número de classificação atribuídos no Canadá	\N	t	t	t	f	f	\N
055	a	Número de classificação	\N	f	f	t	f	f	\N
055	b	Número do item	\N	f	f	t	f	f	\N
055	2	Fonte do número de Chamada/Classificação	\N	f	f	t	f	f	\N
055	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
060	#	Número de chamada da National Library of Medicine	\N	t	t	t	f	f	\N
060	a	Número de classificação	\N	t	f	t	f	f	\N
060	b	Número do item	\N	f	f	t	f	f	\N
060	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
061	#	Informação de cópia da National Library of Medicine	\N	t	t	t	f	f	\N
061	a	Número de classificação	\N	t	f	t	f	f	\N
061	b	Número do item	\N	f	f	t	f	f	\N
061	c	Informação de Cópia	\N	f	f	t	f	f	\N
061	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
066	#	Conjunto de caracteres presente	\N	f	t	t	f	f	\N
066	a	Conjunto de caracteres default Non-ASCII G0	\N	f	f	t	f	f	\N
066	b	Conjunto de caracteres default Non-ANSEL G1	\N	f	f	t	f	f	\N
066	c	Identificação do conjunto de caracteres alternativos	\N	t	f	t	f	f	\N
070	#	Número de chamada da National Agricultural Library	\N	t	t	t	f	f	\N
070	a	Número de classificação	\N	t	f	t	f	f	\N
070	b	Número do item	\N	f	f	t	f	f	\N
070	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
071	#	Informação de Cópia da National Agricultural Library	\N	t	t	t	f	f	\N
071	a	Número de Classificação	\N	t	f	t	f	f	\N
071	b	Número do item	\N	f	f	t	f	f	\N
071	c	Informação de Cópia	\N	f	f	t	f	f	\N
071	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
072	#	Código de categoria de assunto	\N	t	t	t	f	f	\N
072	a	Código de categoria de assunto	\N	f	f	t	f	f	\N
072	x	Subd. do Código de Categoria de Assunto	\N	t	f	t	f	f	\N
072	2	Fonte do Código	\N	f	f	t	f	f	\N
072	6	Ligação	\N	f	f	t	f	f	\N
072	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
074	#	Número do item GPO	\N	t	t	t	f	f	\N
074	a	Número do item GPO	\N	f	f	t	f	f	\N
074	z	Número do item GPO Cancelado/Inválido	\N	t	f	t	f	f	\N
074	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
080	#	CDU - Classificação Decimal Universal	\N	f	t	t	f	f	\N
080	2	Número da edição	\N	f	f	t	f	f	\N
080	x	Subdivisão Auxiliar	\N	t	f	t	f	f	\N
080	6	Ligação	\N	f	f	t	f	f	\N
080	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
082	#	CDD - Classificação Decimal de Dewey	\N	t	t	t	f	f	\N
082	a	Número de Classificação	\N	t	f	t	f	f	\N
082	2	Número da edição	\N	f	f	t	f	f	\N
082	6	Ligação	\N	f	f	t	f	f	\N
082	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
084	#	Outro número de classificação	\N	t	t	t	f	f	\N
084	a	Número de classificação	\N	t	f	t	f	f	\N
084	b	Número do item	\N	f	f	t	f	f	\N
084	2	Fonte do Número (Tipo de Classificação)	\N	f	f	t	f	f	\N
084	6	Ligação	\N	f	f	t	f	f	\N
084	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
086	#	Número de Classificação de Documento Governamental	\N	t	t	t	f	f	\N
086	a	Número de Classificação	\N	f	f	t	f	f	\N
086	z	Número de Classificação Cancelado/Inválido	\N	t	f	t	f	f	\N
086	2	Fonte do Número	\N	f	f	t	f	f	\N
086	6	Ligação	\N	f	f	t	f	f	\N
086	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
088	#	Número de relatório	\N	t	t	t	f	f	\N
088	a	Número de relatório	\N	f	f	t	f	f	\N
088	z	Número de relatório Cancelado/Inválido	\N	t	f	t	f	f	\N
088	6	Ligação	\N	f	f	t	f	f	\N
088	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
100	#	Entrada Principal - Nome Pessoal	\N	f	t	t	f	f	\N
100	b	Numeração	\N	f	f	t	f	f	\N
100	c	Títulos e outras palavras associadas ao nome	\N	t	f	t	f	f	\N
100	d	Datas associadas ao nome	\N	f	f	t	f	f	\N
100	e	Termo relacionador	\N	t	f	t	f	f	\N
100	f	Data da Obra	\N	f	f	t	f	f	\N
100	g	Miscelânea	\N	f	f	t	f	f	\N
100	k	SubCabeçalho	\N	t	f	t	f	f	\N
100	l	Idioma da Obra	\N	f	f	t	f	f	\N
100	n	Número da parte/Seção da Obra	\N	t	f	t	f	f	\N
100	p	Nome da parte/Seção da Obra	\N	t	f	t	f	f	\N
100	q	Forma completa do nome	\N	f	f	t	f	f	\N
100	t	Título da Obra	\N	f	f	t	f	f	\N
100	u	Afiliação	\N	f	f	t	f	f	\N
100	4	Código Relacionador	\N	t	f	t	f	f	\N
100	6	Ligação	\N	f	f	t	f	f	\N
100	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
110	#	Entrada Principal - Nome Corporativo	\N	f	t	t	f	f	\N
110	a	Nome Corporativo ou Nome da Jurisdição	\N	f	f	t	f	f	\N
110	b	Unidade Subordinada	\N	t	f	t	f	f	\N
110	c	Local do Encontro	\N	f	f	t	f	f	\N
110	d	Data do encontro ou assinatura do tratado	\N	t	f	t	f	f	\N
110	e	Termo relacionador	\N	t	f	t	f	f	\N
110	f	Data da Obra	\N	f	f	t	f	f	\N
110	g	Miscelânea	\N	f	f	t	f	f	\N
110	k	SubCabeçalho	\N	t	f	t	f	f	\N
110	l	Idioma da Obra	\N	f	f	t	f	f	\N
110	n	Número da Parte/Seção/Encontro	\N	t	f	t	f	f	\N
110	p	Nome de Parte/Seção da Obra	\N	t	f	t	f	f	\N
110	t	Título da Obra	\N	f	f	t	f	f	\N
110	u	Afiliação	\N	f	f	t	f	f	\N
110	4	Código Relacionador	\N	t	f	t	f	f	\N
110	6	Ligação	\N	f	f	t	f	f	\N
110	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
111	#	Entrada Principal - Nome de Evento	\N	f	t	t	f	f	\N
111	a	Nome de Evento ou Jurisdição	\N	f	f	t	f	f	\N
111	b	Número (BK CF MP MU SE VM MX)	\N	f	f	t	f	t	\N
111	c	Local do Evento	\N	f	f	t	f	f	\N
111	d	Data do Evento	\N	f	f	t	f	f	\N
111	e	Unidade Subordinada	\N	t	f	t	f	f	\N
111	f	Data da Obra	\N	f	f	t	f	f	\N
111	g	Miscelânea	\N	f	f	t	f	f	\N
111	k	SubCabeçalho	\N	t	f	t	f	f	\N
111	l	Idioma da Obra	\N	f	f	t	f	f	\N
400	f	Data da Obra	\N	f	f	t	f	f	\N
111	n	Número de Parte/Seção/Evento	\N	t	f	t	f	f	\N
111	p	Nome de Parte/Seção da Obra	\N	t	f	t	f	f	\N
111	q	Nome do Evento que segue nome da Jurisdição na Entrada	\N	f	f	t	f	f	\N
111	t	Título da Obra	\N	f	f	t	f	f	\N
111	u	Afiliação	\N	f	f	t	f	f	\N
111	4	Código Relacionador	\N	t	f	t	f	f	\N
111	6	Ligação	\N	f	f	t	f	f	\N
111	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
130	#	Entrada Principal - Título Uniforme	\N	f	t	t	f	f	\N
130	a	Título Uniforme	\N	f	f	t	f	f	\N
130	d	Data da assinatura do tratado	\N	t	f	t	f	f	\N
130	f	Data da Obra	\N	f	f	t	f	f	\N
130	g	Miscelânea	\N	f	f	t	f	f	\N
130	h	Meio Físico	\N	f	f	t	f	f	\N
130	k	SubCabeçalho	\N	t	f	t	f	f	\N
130	l	Idioma da Obra	\N	f	f	t	f	f	\N
130	m	Meio de Apresentação da Música	\N	t	f	t	f	f	\N
130	n	Número de Parte/Seção da Obra	\N	t	f	t	f	f	\N
130	o	Informação de Arranjo para Música	\N	f	f	t	f	f	\N
130	p	Nome de Parte/Seção da Obra	\N	t	f	t	f	f	\N
130	r	Chave para Música	\N	f	f	t	f	f	\N
130	s	Versão	\N	f	f	t	f	f	\N
130	t	Título da Obra	\N	f	f	t	f	f	\N
130	6	Ligação	\N	f	f	t	f	f	\N
130	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
210	#	Título Chave Abreviado	\N	f	t	t	f	f	\N
210	a	Título Abreviado	\N	f	f	t	f	f	\N
210	b	Informação Qualificadora	\N	f	f	t	f	f	\N
210	2	Fonte	\N	t	f	t	f	f	\N
210	6	Ligação	\N	f	f	t	f	f	\N
210	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
222	#	Título Chave	\N	t	t	t	f	f	\N
222	a	Título Chave	\N	f	f	t	f	f	\N
222	b	Informação Qualificadora	\N	f	f	t	f	f	\N
222	6	Ligação	\N	f	f	t	f	f	\N
222	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
240	#	Título Uniforme	\N	f	t	t	f	f	\N
240	a	Título Uniforme	\N	f	f	t	f	f	\N
240	d	Data de Assinatura do Tratado	\N	t	f	t	f	f	\N
240	f	Data da Obra	\N	f	f	t	f	f	\N
240	g	Miscelânea	\N	f	f	t	f	f	\N
240	h	Meio Físico	\N	f	f	t	f	f	\N
240	k	SubCabeçalho	\N	t	f	t	f	f	\N
240	l	Idioma da Obra	\N	f	f	t	f	f	\N
240	m	Meio de Apresentação para Música	\N	t	f	t	f	f	\N
240	n	Número de Parte/Seção da Obra	\N	t	f	t	f	f	\N
240	o	Informação de Arranjo para Música	\N	f	f	t	f	f	\N
240	p	Nome de Parte/Seção da Obra	\N	t	f	t	f	f	\N
240	r	Chave para Música	\N	f	f	t	f	f	\N
240	s	Versão	\N	f	f	t	f	f	\N
240	6	Ligação	\N	f	f	t	f	f	\N
240	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
242	#	Título Traduzido por Instituição Catalogadora	\N	t	t	t	f	f	\N
242	a	Título	\N	f	f	t	f	f	\N
242	b	Complemento do Título	\N	f	f	t	f	f	\N
242	c	Complemento do Título Transcrito da Pág. de Rosto/Indicação de Responsabilidade	\N	f	f	t	f	f	\N
242	d	Indicação de Sessão (BK AM MP MU VM SE)	\N	f	f	t	f	t	\N
242	e	Nome de Parte/Sessão (BK AM MP MU VM SE)	\N	f	f	t	f	t	\N
242	h	Meio Físico	\N	f	f	t	f	f	\N
242	n	Número da Parte/Seção da Obra	\N	t	f	t	f	f	\N
242	p	Nome da Parte/Seção da Obra	\N	t	f	t	f	f	\N
242	y	Código do Idioma do Título Traduzido	\N	f	f	t	f	f	\N
242	6	Ligação	\N	f	f	t	f	f	\N
242	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
243	#	Título Uniforme Coletico (Título de Coletânea)	\N	f	t	t	f	f	\N
243	a	Título Uniforme	\N	f	f	t	f	f	\N
243	d	Data de Assinatura do Tratado	\N	t	f	t	f	f	\N
243	f	Data da Obra	\N	f	f	t	f	f	\N
243	g	Miscelânea	\N	f	f	t	f	f	\N
243	h	Meio Físico	\N	f	f	t	f	f	\N
243	k	SubCabeçalho	\N	t	f	t	f	f	\N
243	l	Idioma da Obra	\N	f	f	t	f	f	\N
243	m	Meio de Apresentação para Música	\N	t	f	t	f	f	\N
243	n	Número de Parte/Seção da Obra	\N	t	f	t	f	f	\N
243	o	Informação de Arranjo para Música	\N	f	f	t	f	f	\N
243	p	Nome de Parte/Seção da Obra	\N	t	f	t	f	f	\N
243	r	Chave para Música	\N	f	f	t	f	f	\N
243	s	Versão	\N	f	f	t	f	f	\N
243	6	Ligação	\N	f	f	t	f	f	\N
243	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
245	#	Título	\N	f	t	t	f	f	\N
245	b	Complemento do Título	\N	f	f	t	f	f	\N
245	c	Complemento do Título Transcrito da Pág. de Rosto/Indicação de Responsabilidade	\N	f	f	t	f	f	\N
245	d	Indicação de Seção (SE)	\N	f	f	t	f	t	\N
245	e	Nome de Parte/Seção (SE)	\N	f	f	t	f	t	\N
245	f	Faixa de Datas	\N	f	f	t	f	f	\N
245	g	Conjunto de Datas	\N	f	f	t	f	f	\N
245	h	Meio Físico	\N	f	f	t	f	f	\N
245	k	Forma	\N	t	f	t	f	f	\N
245	n	Número de Parte/Seção da Obra	\N	t	f	t	f	f	\N
245	p	Nome de Parte/Seção da Obra	\N	t	f	t	f	f	\N
245	s	Versão	\N	f	f	t	f	f	\N
245	6	Ligação	\N	f	f	t	f	f	\N
245	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
246	#	Forma Variante do Título	\N	t	t	t	f	f	\N
246	a	Título/título Abreviado	\N	f	f	t	f	f	\N
246	b	Complemento do título	\N	f	f	t	f	f	\N
246	d	Indicação de Seção (SE)	\N	f	f	t	f	t	\N
246	e	Nome de Parte/Seção (SE)	\N	f	f	t	f	t	\N
246	f	Informação de Volume/Número de Fascículo e/ou Data da Obra	\N	f	f	t	f	f	\N
246	g	Miscelânea	\N	f	f	t	f	f	\N
246	h	Meio Físico	\N	f	f	t	f	f	\N
246	i	Exibir Texto	\N	f	f	t	f	f	\N
246	n	Número de Parte/Seção da Obra	\N	t	f	t	f	f	\N
246	p	Nome de Parte/Seção da Obra	\N	t	f	t	f	f	\N
246	5	Instituição à qual o Campo se Aplica	\N	f	f	t	f	f	\N
246	6	Ligação	\N	f	f	t	f	f	\N
246	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
400	g	Miscelânea	\N	f	f	t	f	f	\N
247	#	Título Anterior ou Variações do Título	\N	t	t	t	f	f	\N
247	a	Título/Título Abreviado	\N	f	f	t	f	f	\N
247	b	Complemento do Título	\N	f	f	t	f	f	\N
247	d	Indicação de Seção (SE)	\N	f	f	t	f	t	\N
247	e	Nome de Parte/Seção (SE)	\N	f	f	t	f	t	\N
247	f	Informação de Volume/Número de Fascículo e/ou Data da Obra	\N	f	f	t	f	f	\N
247	g	Miscelânea	\N	f	f	t	f	f	\N
247	h	Meio físico	\N	f	f	t	f	f	\N
247	i	Exibir Texto	\N	f	f	t	f	f	\N
247	n	Número de Parte/Seção da Obra	\N	t	f	t	f	f	\N
247	p	Nome de Parte/Seção da Obra	\N	t	f	t	f	f	\N
247	x	ISSN - International Standart Serial Number	\N	f	f	t	f	f	\N
247	6	Ligação	\N	f	f	t	f	f	\N
247	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
250	#	Edição	\N	f	t	t	f	f	\N
877	c	Preço	\N	t	f	t	f	f	\N
250	b	Complemento da Informação de Edição	\N	f	f	t	f	f	\N
250	6	Ligação	\N	f	f	t	f	f	\N
250	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
254	#	Informação de Apresentação Musical	\N	f	t	t	f	f	\N
254	a	Informação de Apresentação Musical	\N	f	f	t	f	f	\N
254	6	Ligação	\N	f	f	t	f	f	\N
254	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
255	#	Dado Cartográfico Matemático	\N	t	t	t	f	f	\N
255	a	Informação de Escala	\N	f	f	t	f	f	\N
255	b	Informação de Projeção	\N	f	f	t	f	f	\N
255	c	Informação de Coordenadas	\N	f	f	t	f	f	\N
255	d	Informação de Zona	\N	f	f	t	f	f	\N
255	e	Informação de Equinócio	\N	f	f	t	f	f	\N
255	f	Other G-ring Coordinate Pairs	\N	f	f	t	f	f	\N
342	o	LandSat Órbita ponto	\N	f	f	t	f	f	\N
255	g	Exclusion G-ring Coordinate Pairs	\N	f	f	t	f	f	\N
255	6	Ligação	\N	f	f	t	f	f	\N
255	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
256	#	Características de Arquivo de Computador	\N	f	t	t	f	f	\N
256	a	Características de Arquivo de Computador	\N	f	f	t	f	f	\N
256	6	Ligação	\N	f	f	t	f	f	\N
256	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
257	#	País da Instituição Produtora do Filme de Arquivo	\N	f	t	t	f	f	\N
257	a	País da Instituição Produtora do Filme de Arquivo	\N	f	f	t	f	f	\N
257	6	Ligação	\N	f	f	t	f	f	\N
257	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
260	a	Lugar de Publicação, Distribuição, etc.	\N	t	f	t	f	f	\N
250	a	Edição	\N	f	f	t	f	f	\N
876	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
260	d	Plates of Publisher's Number for Music (Pre-AACR2)	\N	t	f	t	f	f	\N
260	e	Lugar de Manufatura	\N	f	f	t	f	f	\N
260	f	Manufatureiro	\N	f	f	t	f	f	\N
260	g	Data de Manufatura	\N	f	f	t	f	f	\N
260	6	Ligação	\N	f	f	t	f	f	\N
260	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
261	#	Informação de Imprenta para Filmes (Pre-AACR1 Revised)	\N	f	t	t	f	f	\N
261	a	Companhia Produtora	\N	t	f	t	f	f	\N
261	b	Companhia Distribuidora (Primeiro distribuidor)	\N	t	f	t	f	f	\N
261	c	Data de Produção, Distribuição, etc.	\N	t	f	t	f	f	\N
261	e	Produtor Contratado	\N	t	f	t	f	f	\N
261	f	Lugar de Produção, Distribuição, etc.	\N	t	f	t	f	f	\N
261	6	Ligação	\N	f	f	t	f	f	\N
262	#	Informação de Imprenta para Gravação Sonora (Pré-AACR2)	\N	f	t	t	f	f	\N
262	a	Lugar de Produção, Distribuição, etc.	\N	f	f	t	f	f	\N
262	b	Editor ou Nome Comercial	\N	f	f	t	f	f	\N
262	c	Data de Produção, Distribuição, etc.	\N	f	f	t	f	f	\N
262	k	Identificação de Série	\N	f	f	t	f	f	\N
262	l	Matrix e/ou Número do Take	\N	f	f	t	f	f	\N
262	6	Ligação	\N	f	f	t	f	f	\N
263	#	Data Estimada de Publicação	\N	f	t	t	f	f	\N
263	a	Data Estimada de Publicação	\N	f	f	t	f	f	\N
263	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
270	#	Endereço	\N	t	t	t	f	f	\N
270	a	Endereço	\N	t	f	t	f	f	\N
270	b	Cidade	\N	f	f	t	f	f	\N
270	c	Estado ou Província	\N	f	f	t	f	f	\N
270	d	País	\N	f	f	t	f	f	\N
270	e	Código Postal (CEP)	\N	f	f	t	f	f	\N
270	f	Título que Precede Nome da Pessoa "Aos Cuidados de"	\N	f	f	t	f	f	\N
270	g	Nome da Pessoa "Aos Cuidados de"	\N	f	f	t	f	f	\N
270	h	Título que Segue o Nome da Pessoa "Aos Cuidados de"	\N	f	f	t	f	f	\N
270	i	Tipo de Endereço	\N	f	f	t	f	f	\N
270	j	Número de Telefone Especializado	\N	t	f	t	f	f	\N
270	k	Número de Telefone	\N	t	f	t	f	f	\N
270	l	Número de FAX	\N	t	f	t	f	f	\N
270	m	Endereço Eletrônico	\N	t	f	t	f	f	\N
270	n	Número TDD ou TTY	\N	t	f	t	f	f	\N
270	p	Pessoas de Contato	\N	t	f	t	f	f	\N
270	q	Título da Pessoa de Contato	\N	t	f	t	f	f	\N
270	r	Horário	\N	t	f	t	f	f	\N
270	z	Nota Pública	\N	t	f	t	f	f	\N
270	4	Código Relacionador	\N	t	f	t	f	f	\N
270	6	Ligação	\N	f	f	t	f	f	\N
270	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
300	#	Descrição Física	\N	t	t	t	f	f	\N
300	b	Outros Detalhes Físicos	\N	f	f	t	f	f	\N
300	a	Extensão	\N	t	f	t	f	f	\N
300	c	Dimensões	\N	t	f	t	f	f	\N
300	e	Material Complementar	\N	f	f	t	f	f	\N
300	f	Tipo de Unidade	\N	t	f	t	f	f	\N
300	g	Tamanho da Unidade	\N	t	f	t	f	f	\N
300	3	Materiais Especificados	\N	f	f	t	f	f	\N
300	6	Ligação	\N	f	f	t	f	f	\N
300	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
306	#	Tempo de Duração	\N	f	t	t	f	f	\N
306	a	Tempo de Duração	\N	t	f	t	f	f	\N
307	#	Horário, etc.	\N	f	t	t	f	f	\N
307	a	Horário	\N	f	f	t	f	f	\N
307	b	Informação Adicional	\N	f	f	t	f	f	\N
307	6	Ligação	\N	f	f	t	f	f	\N
307	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
310	#	Periodicidade Corrente	\N	f	t	t	f	f	\N
310	a	Periodicidade	\N	f	f	t	f	f	\N
310	b	Data da Periodicidade	\N	f	f	t	f	f	\N
310	6	Ligação	\N	f	f	t	f	f	\N
310	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
328	#	Periodicidade Anterior	\N	t	t	t	f	f	\N
328	a	Periodicidade Anterior	\N	f	f	t	f	f	\N
328	b	Datas de Periodicidade Anterior	\N	f	f	t	f	f	\N
328	6	Ligação	\N	f	f	t	f	f	\N
340	#	Meio Físico	\N	t	t	t	f	f	\N
340	a	Material Base e Configuração	\N	t	f	t	f	f	\N
340	b	Dimensões	\N	t	f	t	f	f	\N
340	c	Materiais Aplicados à Superfície	\N	t	f	t	f	f	\N
340	d	Informação da Técnica de Gravação	\N	t	f	t	f	f	\N
340	e	Suporte	\N	t	f	t	f	f	\N
340	f	Production Rate/Ratio	\N	t	f	t	f	f	\N
340	h	Localização Dentro do Veículo	\N	t	f	t	f	f	\N
340	i	Especificações Técnicas do Veículo	\N	t	f	t	f	f	\N
340	3	Materiais Especificados	\N	f	f	t	f	f	\N
342	#	Dados de Referência Geoespacial	\N	t	t	t	f	f	\N
342	a	Unidades de Coordenada ou distância	\N	f	f	t	f	f	\N
342	c	Resolução na Latitude	\N	f	f	t	f	f	\N
342	d	Resolução na Longitude	\N	f	f	t	f	f	\N
342	e	Paralelo padrão ou latitude linear oblíqua	\N	t	f	t	f	f	\N
342	f	longitude linear oblíqua	\N	t	f	t	f	f	\N
342	g	longitude do meridiano central/centro de projeção	\N	f	f	t	f	f	\N
342	h	Latitude da origem da projeção/centro de projeção	\N	f	f	t	f	f	\N
342	i	Indicação do Leste (False easting)	\N	f	f	t	f	f	\N
342	j	Indicação do Norte (False northing)	\N	f	f	t	f	f	\N
342	k	Fator de escala	\N	f	f	t	f	f	\N
342	l	Altura do ponto de perspectiva acima da superfície	\N	f	f	t	f	f	\N
342	m	Ângulo Azimutal	\N	f	f	t	f	f	\N
411	e	Unidade Subordinada	\N	t	f	t	f	f	\N
342	n	Medida da Longitude do ponto ou longitude vertical reta do pólo	\N	f	f	t	f	f	\N
342	p	Identificador de Zona	\N	f	f	t	f	f	\N
342	q	Nome do Elipsóide	\N	f	f	t	f	f	\N
342	r	Semi-Eixo maior	\N	f	f	t	f	f	\N
342	s	Denominador da fração de achatamento	\N	f	f	t	f	f	\N
342	t	Resolução vertical	\N	f	f	t	f	f	\N
342	u	Método de Codificação vertical	\N	f	f	t	f	f	\N
342	v	Planar, Local ou descrição de grade ou projeção	\N	f	f	t	f	f	\N
342	w	Planar, Local ou outras informações de referência	\N	f	f	t	f	f	\N
342	2	Método de referência utilizado	\N	f	f	t	f	f	\N
342	6	Ligação	\N	f	f	t	f	f	\N
342	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
343	#	Planar Coordinate Data	\N	t	t	t	f	f	\N
343	a	Método de codificação da coordenada planar	\N	f	f	t	f	f	\N
343	b	Unidade de distância plana	\N	f	f	t	f	f	\N
343	c	Resolução da Abcissa	\N	f	f	t	f	f	\N
343	d	Resolução Ordenada	\N	f	f	t	f	f	\N
343	e	Resolução na distância	\N	f	f	t	f	f	\N
343	f	Unidade de medida de Resolução	\N	f	f	t	f	f	\N
343	g	Unidade de medida	\N	f	f	t	f	f	\N
343	h	Unidade de medida da direção de referência	\N	f	f	t	f	f	\N
343	i	Unidade de medida do meridiano de referência	\N	f	f	t	f	f	\N
343	6	Ligação	\N	f	f	t	f	f	\N
343	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
351	#	Organização e arranjo dos materiais	\N	t	t	t	f	f	\N
351	a	Organização	\N	t	f	t	f	f	\N
351	b	Arranjo	\N	t	f	t	f	f	\N
351	c	Nível hierárquico	\N	f	f	t	f	f	\N
351	3	Materiais especificados	\N	f	f	t	f	f	\N
351	6	Ligação	\N	f	f	t	f	f	\N
351	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
352	#	Representação gráfica digital	\N	t	t	t	f	f	\N
352	a	Método de referência direta	\N	f	f	t	f	f	\N
352	b	Tipo de objeto	\N	t	f	t	f	f	\N
352	c	Número de Objetos	\N	t	f	t	f	f	\N
352	d	Número de Linhas	\N	f	f	t	f	f	\N
352	e	Número de Colunas	\N	f	f	t	f	f	\N
352	g	Contagem Vertical	\N	f	f	t	f	f	\N
352	i	Descrição Indireta de Referência	\N	f	f	t	f	f	\N
352	6	Ligação	\N	f	f	t	f	f	\N
352	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
355	#	Controle de Classificação de Segurança	\N	t	t	t	f	f	\N
355	a	Classificação de Segurança	\N	f	f	t	f	f	\N
355	b	Instruções de Manuseio	\N	t	f	t	f	f	\N
355	c	Informação de Disseminação Externa	\N	t	f	t	f	f	\N
355	d	Dados da Mudança de Catalogação/Liberação de Acesso	\N	f	f	t	f	f	\N
355	e	Sistema de Classificação	\N	f	f	t	f	f	\N
355	f	Código do País de Origem	\N	f	f	t	f	f	\N
355	g	Data da Mudança de Categoria	\N	f	f	t	f	f	\N
355	h	Data da Liberação de Acesso	\N	f	f	t	f	f	\N
355	j	Autorização	\N	t	f	t	f	f	\N
355	6	Ligação	\N	f	f	t	f	f	\N
355	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
357	#	Controle do Autor sobre a disseminação	\N	f	t	t	f	f	\N
357	a	Termos de controle do Autor	\N	f	f	t	f	f	\N
357	b	Instituição criadora	\N	t	f	t	f	f	\N
357	c	Usuários autorizados do Material	\N	t	f	t	f	f	\N
357	g	Outras Restrições	\N	t	f	t	f	f	\N
357	6	Ligação	\N	f	f	t	f	f	\N
357	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
362	#	Informação de Datas de Publicação e/ou volume	\N	t	t	t	f	f	\N
362	a	Datas de Publicação / Indicação de Seqüência	\N	f	f	t	f	f	\N
362	z	Fonte da Informação	\N	f	f	t	f	f	\N
362	6	Ligação	\N	f	f	t	f	f	\N
362	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
400	#	Informação de Série/Entrada Secundária - Nome Pessoal	\N	t	t	t	f	f	\N
400	a	Nome Pessoal	\N	f	f	t	f	f	\N
400	b	Numeração	\N	f	f	t	f	f	\N
877	t	Número do exemplar	\N	f	f	t	f	f	\N
400	c	Títulos e outras palavras associadas ao nome	\N	t	f	t	f	f	\N
400	d	Datas associadas ao nome	\N	f	f	t	f	f	\N
400	e	Termo relacionador	\N	t	f	t	f	f	\N
400	k	SubCabeçalho	\N	t	f	t	f	f	\N
400	l	Idioma da Obra	\N	f	f	t	f	f	\N
400	n	Número de Parte/Seção da Obra	\N	t	f	t	f	f	\N
400	p	Nome de Parte/Seção da Obra	\N	t	f	t	f	f	\N
400	t	Título da Obra	\N	f	f	t	f	f	\N
400	u	Afiliação	\N	f	f	t	f	f	\N
400	v	Informação de Número de Volume/Seqüência	\N	f	f	t	f	f	\N
400	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
400	4	Código Relacionador	\N	t	f	t	f	f	\N
400	6	Ligação	\N	f	f	t	f	f	\N
410	#	Informação de Série/Entrada Secundária - Nome Corporativo	\N	t	t	t	f	f	\N
410	a	Nome Corporativo ou nome de Jurisdição	\N	f	f	t	f	f	\N
410	b	Unidade Subordinada	\N	t	f	t	f	f	\N
410	c	Local do Evento	\N	f	f	t	f	f	\N
410	d	Data do Evento ou Assinatura do Tratado	\N	t	f	t	f	f	\N
410	e	Termo Relacionador	\N	t	f	t	f	f	\N
410	f	Data da Obra	\N	f	f	t	f	f	\N
410	g	Miscelânea	\N	f	f	t	f	f	\N
410	k	SubCabeçalho	\N	t	f	t	f	f	\N
410	l	Idioma da Obra	\N	f	f	t	f	f	\N
410	n	Número de Parte/Seção da Obra	\N	t	f	t	f	f	\N
410	p	Nome de Parte/Seção da Obra	\N	t	f	t	f	f	\N
410	t	Título da Obra	\N	f	f	t	f	f	\N
410	u	Afiliação	\N	f	f	t	f	f	\N
410	v	Número do Volume/Indicação de Seqüência	\N	f	f	t	f	f	\N
410	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
410	4	Código Relacionador	\N	t	f	t	f	f	\N
410	6	Ligação	\N	f	f	t	f	f	\N
411	#	Informação de Série/Entrada Secundária - Nome de Evento	\N	t	t	t	f	f	\N
411	a	Nome do Evento ou Nome da Jurisdição	\N	f	f	t	f	f	\N
411	b	Número (BK CF MP MU SE VM MX)	\N	f	f	t	f	t	\N
411	c	Local do Evento	\N	f	f	t	f	f	\N
411	d	Data do Evento	\N	f	f	t	f	f	\N
411	f	Data da Obra	\N	f	f	t	f	f	\N
411	g	Miscelânea	\N	f	f	t	f	f	\N
411	k	SubCabeçalho	\N	t	f	t	f	f	\N
411	l	Idioma da Obra	\N	f	f	t	f	f	\N
411	n	Número de Parte/Seção da Obra	\N	t	f	t	f	f	\N
411	p	Nome de Parte/Seção da Obra	\N	t	f	t	f	f	\N
411	q	Nome do Evento que segue nome da Jurisdição na Entrada	\N	f	f	t	f	f	\N
411	t	Título da Obra	\N	f	f	t	f	f	\N
411	u	Filiação	\N	f	f	t	f	f	\N
411	v	Número do Volume/Indicação de Seqüência	\N	f	f	t	f	f	\N
411	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
411	4	Código Relacionador	\N	t	f	t	f	f	\N
411	6	Ligação	\N	f	f	t	f	f	\N
440	#	Informação de Série/Entrada Secundária - Título	\N	t	t	t	f	f	\N
877	#	Informação de item - Material suplementar	\N	f	t	t	f	f	\N
440	n	Número de Parte/Seção da Obra	\N	t	f	t	f	f	\N
440	p	Nome de Parte/Seção da Obra	\N	t	f	t	f	f	\N
440	v	Número de Volume/Indicação de Seqüência	\N	f	f	t	f	f	\N
440	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
440	6	Ligação	\N	f	f	t	f	f	\N
440	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
490	#	Informação de Série	\N	t	t	t	f	f	\N
490	a	Informação de Série	\N	t	f	t	f	f	\N
490	l	Número de Chamada da Library of Congress	\N	f	f	t	f	f	\N
490	v	Número de Volume/Indicação de Seqüência	\N	f	f	t	f	f	\N
490	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
490	6	Ligação	\N	f	f	t	f	f	\N
490	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
500	#	Nota Geral	\N	t	t	t	f	f	\N
500	a	Nota Geral	\N	f	f	t	f	f	\N
500	l	Número de Chamada da Library of Congress (SE)	\N	f	f	t	f	t	\N
500	x	ISSN - International Standard Serial Number (SE)	\N	f	f	t	f	t	\N
500	z	Fonte de Informação da Nota (AM SE)	\N	f	f	t	f	t	\N
500	3	Materiais Especificados	\N	f	f	t	f	f	\N
500	5	Instituição à qual o campo se aplica	\N	f	f	t	f	f	\N
500	6	Ligação	\N	f	f	t	f	f	\N
500	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
501	#	Nota iniciada por "COM"	\N	t	t	t	f	f	\N
501	a	Nota iniciada por "COM"	\N	f	f	t	f	f	\N
501	5	Instituição à qual o campo se aplica	\N	f	f	t	f	f	\N
501	6	Ligação	\N	f	f	t	f	f	\N
501	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
502	#	Nota de Dissertação ou Tese	\N	t	t	t	f	f	\N
502	a	Nota de Dissertação ou Tese	\N	f	f	t	f	f	\N
502	6	Ligação	\N	f	f	t	f	f	\N
502	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
504	#	Nota de Bibliografia	\N	t	t	t	f	f	\N
504	a	Nota de Bibliografia	\N	f	f	t	f	f	\N
504	b	Número de Referências	\N	f	f	t	f	f	\N
504	6	Ligação	\N	f	f	t	f	f	\N
504	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
505	#	Nota de conteúdo	\N	f	t	t	f	f	\N
877	a	Número do item interno	\N	f	f	t	f	f	\N
505	g	Miscelânea	\N	t	f	t	f	f	\N
505	r	Indicação de Responsabilidade	\N	t	f	t	f	f	\N
505	t	Título	\N	t	f	t	f	f	\N
505	6	Ligação	\N	f	f	t	f	f	\N
505	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
506	#	Nota de Acesso Restrito	\N	t	t	t	f	f	\N
506	a	Termos Definindo o Acesso	\N	f	f	t	f	f	\N
506	b	Jurisdição	\N	t	f	t	f	f	\N
506	c	Condições para o Acesso Físico	\N	t	f	t	f	f	\N
506	d	Usuários autorizados	\N	t	f	t	f	f	\N
506	e	Autorização	\N	t	f	t	f	f	\N
506	3	Materiais Especificados	\N	f	f	t	f	f	\N
506	5	Instituição à qual o campo se aplica	\N	f	f	t	f	f	\N
506	6	Ligação	\N	f	f	t	f	f	\N
506	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
507	#	Nota de escala para material gráfico	\N	f	t	t	f	f	\N
507	a	Fração representante da nota de escala	\N	f	f	t	f	f	\N
507	b	Complemento da nota de escala	\N	f	f	t	f	f	\N
507	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
508	#	Nota de Crédito de Produção/Criação	\N	f	t	t	f	f	\N
508	a	Nota de Crédito de Produção/Criação	\N	f	f	t	f	f	\N
508	6	Ligação	\N	f	f	t	f	f	\N
508	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
510	#	Nota de Citação/Referência	\N	t	t	t	f	f	\N
510	a	Nome da fonte	\N	f	f	t	f	f	\N
510	b	Datas de cobertura da fonte	\N	f	f	t	f	f	\N
510	c	Localização da fonte	\N	f	f	t	f	f	\N
510	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
510	3	Materiais especificados	\N	f	f	t	f	f	\N
510	6	Ligação	\N	f	f	t	f	f	\N
510	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
511	#	Nota de Participante ou Executor	\N	t	t	t	f	f	\N
511	a	Nota de Participante ou Executor	\N	f	f	t	f	f	\N
511	6	Ligação	\N	f	f	t	f	f	\N
511	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
513	#	Nota tipo de relatório e período coberto	\N	t	t	t	f	f	\N
513	a	Tipo de relatório	\N	f	f	t	f	f	\N
513	b	Período coberto	\N	f	f	t	f	f	\N
513	6	Ligação	\N	f	f	t	f	f	\N
513	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
514	#	Nota de qualidade dos dados	\N	f	t	t	f	f	\N
514	a	Relatório de precisão dos atributos	\N	f	f	t	f	f	\N
514	b	Valor de precisão dos atributos	\N	t	f	t	f	f	\N
514	c	Explicação sobre a precisão dos atributos	\N	t	f	t	f	f	\N
514	d	Relatório de consistência lógica	\N	t	f	t	f	f	\N
514	e	Relatório de completude/Inteireza	\N	f	f	t	f	f	\N
514	f	Relatório de precisão da posição horizontal	\N	f	f	t	f	f	\N
514	g	Valor da precisão da posição horizontal	\N	t	f	t	f	f	\N
514	h	Explicação da precisão da posição horizontal	\N	t	f	t	f	f	\N
514	i	Relatório da precisão da posição vertical	\N	f	f	t	f	f	\N
514	j	Valor da precisão da posição vertical	\N	t	f	t	f	f	\N
514	k	Explicação da precisão da posição vertical	\N	t	f	t	f	f	\N
514	m	Cobertura da Nuvem	\N	f	f	t	f	f	\N
514	6	Ligação	\N	f	f	t	f	f	\N
514	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
515	#	Nota de peculiaridade na numeração	\N	t	t	t	f	f	\N
515	a	Nota de peculiaridade na numeração	\N	f	f	t	f	f	\N
515	6	Ligação	\N	f	f	t	f	f	\N
658	6	Ligação	\N	f	f	t	f	f	\N
515	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
516	#	Nota de tipo de arquivo ou dado de computador	\N	t	t	t	f	f	\N
516	a	Tipo de arquivo ou dado de computador	\N	f	f	t	f	f	\N
516	6	Ligação	\N	f	f	t	f	f	\N
516	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
518	#	Nota Data/Hora e lugar de um evento	\N	t	t	t	f	f	\N
518	a	Nota Data/Hora e lugar de um evento	\N	f	f	t	f	f	\N
518	3	Materiais especificados	\N	f	f	t	f	f	\N
518	6	Ligação	\N	f	f	t	f	f	\N
518	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
520	#	Nota de Resumo	\N	t	t	t	f	f	\N
520	a	Nota de Resumo	\N	f	f	t	f	f	\N
520	b	Expansão da nota de resumo	\N	f	f	t	f	f	\N
515	z	Fonte de informação da nota (SE)	\N	f	f	t	f	t	\N
520	z	Fonte da informação da nota (SE)	\N	f	f	t	f	t	\N
520	3	Materiais especificados	\N	f	f	t	f	f	\N
520	6	Ligação	\N	f	f	t	f	f	\N
520	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
521	#	Nota de público alvo	\N	t	t	t	f	f	\N
521	a	Nota de público alvo	\N	t	f	t	f	f	\N
521	3	Materiais especificados	\N	f	f	t	f	f	\N
521	6	Ligação	\N	f	f	t	f	f	\N
521	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
522	#	Nota de cobertura geográfica	\N	f	t	t	f	f	\N
522	a	Nota de cobertura geográfica	\N	f	f	t	f	f	\N
522	6	Ligação	\N	f	f	t	f	f	\N
522	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
524	#	Nota de forma preferida para descrição do material	\N	t	t	t	f	f	\N
524	a	Nota de forma preferida para descrição do material	\N	f	f	t	f	f	\N
524	2	Fonte ou esquema usado	\N	f	f	t	f	f	\N
524	3	Materiais especificados	\N	f	f	t	f	f	\N
524	6	Ligação	\N	f	f	t	f	f	\N
524	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
525	#	Nota de suplemento	\N	t	t	t	f	f	\N
525	a	Nota de suplemento	\N	f	f	t	f	f	\N
525	z	Fonte da informação da nota (SE)	\N	f	f	t	f	t	\N
525	6	Ligação	\N	f	f	t	f	f	\N
525	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
530	#	Nota de disponibilidade de forma física adicional	\N	t	t	t	f	f	\N
530	a	Nota de disponibilidade de forma física adicional	\N	f	f	t	f	f	\N
530	b	Fonte de aquisição	\N	f	f	t	f	f	\N
530	c	Condições de aquisição	\N	f	f	t	f	f	\N
530	d	Número de ordem	\N	f	f	t	f	f	\N
530	z	Fonte da informação da nota (AM CF VM SE)	\N	f	f	t	f	t	\N
530	3	Materiais especificados	\N	f	f	t	f	f	\N
530	6	Ligação	\N	f	f	t	f	f	\N
530	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
533	#	Nota de reprodução	\N	t	t	t	f	f	\N
533	a	Tipo de reprodução	\N	f	f	t	f	f	\N
533	b	Local de reprodução	\N	t	f	t	f	f	\N
533	c	Instituição responsável pela reprodução	\N	t	f	t	f	f	\N
533	d	Data da reprodução	\N	f	f	t	f	f	\N
533	e	Descrição física da reprodução	\N	f	f	t	f	f	\N
533	f	Informação série da reprodução	\N	t	f	t	f	f	\N
533	m	Datas de publicação e/ou indicação de seqüência para fascículos reproduzidos	\N	t	f	t	f	f	\N
533	n	Nota sobre a reprodução	\N	t	f	t	f	f	\N
533	3	Materiais especificados	\N	f	f	t	f	f	\N
533	6	Ligação	\N	f	f	t	f	f	\N
533	7	Campos de dados fixos para reprodução	\N	f	f	t	f	f	\N
533	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
534	#	Nota de versão original	\N	t	t	t	f	f	\N
534	a	Entrada principal do original	\N	f	f	t	f	f	\N
534	b	Informação de edição do original	\N	f	f	t	f	f	\N
534	c	Publicação, distribuição, etc. do original	\N	f	f	t	f	f	\N
534	e	Descrição física do original	\N	f	f	t	f	f	\N
534	f	Informação de Série do Original	\N	t	f	t	f	f	\N
534	k	Título chave do original	\N	t	f	t	f	f	\N
534	l	Localização do original	\N	f	f	t	f	f	\N
534	m	Detalhes do material especificado	\N	f	f	t	f	f	\N
534	n	Nota sobre o original	\N	t	f	t	f	f	\N
534	p	Frase introdutória	\N	f	f	t	f	f	\N
534	t	Informação do título do original	\N	f	f	t	f	f	\N
534	x	ISSN - International Standard Serial Number	\N	t	f	t	f	f	\N
534	z	ISBN - International Standard Book Number	\N	t	f	t	f	f	\N
534	6	Ligação	\N	f	f	t	f	f	\N
534	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
535	#	Nota de Localização dos originais / duplicatas	\N	t	t	t	f	f	\N
535	a	Depositário	\N	f	f	t	f	f	\N
535	b	Endereço postal	\N	t	f	t	f	f	\N
535	c	País	\N	t	f	t	f	f	\N
535	d	Endereço de telecomunicações	\N	t	f	t	f	f	\N
535	g	Código da localização do depósito	\N	f	f	t	f	f	\N
535	3	Materiais especificados	\N	f	f	t	f	f	\N
535	6	Ligação	\N	f	f	t	f	f	\N
535	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
536	#	Nota de informação sobre financiamento	\N	t	t	t	f	f	\N
536	a	Texto da nota	\N	f	f	t	f	f	\N
536	b	Número do contrato	\N	t	f	t	f	f	\N
536	c	Número da doação	\N	t	f	t	f	f	\N
536	d	Número do projeto, tarefa, trabalho	\N	t	f	t	f	f	\N
536	e	Número do elemento de programa	\N	t	f	t	f	f	\N
536	f	Número do projeto	\N	t	f	t	f	f	\N
536	g	Número da tarefa	\N	t	f	t	f	f	\N
536	h	Número da unidade de trabalho	\N	t	f	t	f	f	\N
536	6	Ligação	\N	f	f	t	f	f	\N
536	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
538	#	Nota detalhes do sistema	\N	t	t	t	f	f	\N
538	a	Nota detalhes do sistema	\N	f	f	t	f	f	\N
538	6	Ligação	\N	f	f	t	f	f	\N
538	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
540	#	Nota de termos governando uso e reprodução	\N	t	t	t	f	f	\N
540	a	Termos governando uso e reprodução	\N	f	f	t	f	f	\N
540	b	Jurisdição	\N	f	f	t	f	f	\N
540	c	Autorização	\N	f	f	t	f	f	\N
540	d	Usuários autorizados	\N	f	f	t	f	f	\N
540	3	Materiais especificados	\N	f	f	t	f	f	\N
540	5	Instituição à qual o campo se aplica	\N	f	f	t	f	f	\N
540	6	Ligação	\N	f	f	t	f	f	\N
540	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
541	#	Nota de Fonte imediata de aquisição	\N	t	t	t	f	f	\N
541	a	Fonte de aquisição	\N	f	f	t	f	f	\N
541	b	Endereço	\N	f	f	t	f	f	\N
541	c	Método de aquisição	\N	f	f	t	f	f	\N
541	d	Data de Aquisição	\N	f	f	t	f	f	\N
541	e	Número de acesso	\N	f	f	t	f	f	\N
541	f	Proprietário	\N	f	f	t	f	f	\N
541	h	Preço de compra	\N	f	f	t	f	f	\N
541	n	Extensão	\N	t	f	t	f	f	\N
541	o	Tipo de unidade	\N	t	f	t	f	f	\N
541	3	Materiais especificados	\N	f	f	t	f	f	\N
541	5	Instituição à qual o campo se aplica	\N	f	f	t	f	f	\N
541	6	Ligação	\N	f	f	t	f	f	\N
541	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
544	#	Nota de localização de materiais de arquivo	\N	t	t	t	f	f	\N
544	a	Depositária	\N	f	f	t	f	f	\N
544	b	Endereço	\N	t	f	t	f	f	\N
544	c	País	\N	t	f	t	f	f	\N
544	d	Título dos materiais associados	\N	t	f	t	f	f	\N
544	e	Procedência dos materiais associados	\N	t	f	t	f	f	\N
544	3	Materiais especificados	\N	f	f	t	f	f	\N
544	6	Ligação	\N	f	f	t	f	f	\N
544	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
545	#	Nota Biográfica ou histórica	\N	t	t	t	f	f	\N
545	a	Nota Biográfica ou histórica	\N	f	f	t	f	f	\N
545	b	Expansão da nota biográfica ou histórica	\N	f	f	t	f	f	\N
545	6	Ligação	\N	f	f	t	f	f	\N
545	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
546	#	Nota de idioma	\N	t	t	t	f	f	\N
546	a	Nota de idioma	\N	f	f	t	f	f	\N
546	b	Informação de código ou alfabeto	\N	t	f	t	f	f	\N
546	z	Fonte da informação da nota (SE)	\N	f	f	t	f	t	\N
546	3	Materiais especificados	\N	f	f	t	f	f	\N
546	6	Ligação	\N	f	f	t	f	f	\N
546	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
547	#	Nota complexa de título anterior	\N	t	t	t	f	f	\N
547	a	Nota complexa de título anterior	\N	f	f	t	f	f	\N
547	z	Fonte da informação da nota (SE)	\N	f	f	t	f	t	\N
547	6	Ligação	\N	f	f	t	f	f	\N
547	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
550	#	Nota de informação sobre a edição	\N	t	t	t	f	f	\N
550	a	Nota de informação sobre a edição	\N	f	f	t	f	f	\N
550	z	Fonte da informação da nota (SE)	\N	f	f	t	f	t	\N
550	6	Ligação	\N	f	f	t	f	f	\N
550	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
552	#	Nota de informação de atributo e unidade	\N	t	t	t	f	f	\N
552	a	Etiqueta do tipo de unidade	\N	f	f	t	f	f	\N
552	b	Fonte e definição do tipo de unidade	\N	f	f	t	f	f	\N
552	c	Etiqueta de atributo	\N	f	f	t	f	f	\N
552	d	Fonte e definição do atributo	\N	f	f	t	f	f	\N
552	e	Valor do domínio enumerado	\N	t	f	t	f	f	\N
552	f	Fonte e definição do valor do domínio enumerado	\N	t	f	t	f	f	\N
552	g	Abrangência máxima e mínima do domínio	\N	f	f	t	f	f	\N
552	h	Fonte e nome do conjunto de códigos	\N	f	f	t	f	f	\N
552	i	domínio não representável	\N	f	f	t	f	f	\N
552	j	Característica das unidades de medida e resolução	\N	f	f	t	f	f	\N
552	k	Data inicial e final dos valores de atributo	\N	f	f	t	f	f	\N
552	l	Precisão dos valores de atributo	\N	f	f	t	f	f	\N
552	m	Explicação da precisão dos valores de atributo	\N	f	f	t	f	f	\N
552	n	Freqüência de medida dos atributos	\N	f	f	t	f	f	\N
552	o	Visão geral da unidade e atributo	\N	t	f	t	f	f	\N
552	p	Citação de detalhe da unidade e atributo	\N	t	f	t	f	f	\N
552	6	Ligação	\N	f	f	t	f	f	\N
552	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
555	#	Nota de índice cumulativo e remissivo	\N	t	t	t	f	f	\N
555	a	Nota de índice cumulativo e remissivo	\N	f	f	t	f	f	\N
555	b	Fonte disponível	\N	t	f	t	f	f	\N
555	c	Grau de controle	\N	f	f	t	f	f	\N
555	d	Referência Bibliográfica	\N	f	f	t	f	f	\N
555	3	Materiais especificados	\N	f	f	t	f	f	\N
555	6	Ligação	\N	f	f	t	f	f	\N
555	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
556	#	Nota de informação sobre documentação	\N	t	t	t	f	f	\N
556	a	Nota de informação sobre documentação	\N	f	f	t	f	f	\N
877	e	Fonte da aquisição	\N	t	f	t	f	f	\N
556	z	ISBN - International Standard Book Number	\N	t	f	t	f	f	\N
556	6	Ligação	\N	f	f	t	f	f	\N
556	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
561	#	Nota de histórico de procedência	\N	t	t	t	f	f	\N
561	a	Histórico	\N	f	f	t	f	f	\N
561	3	Materiais especificados	\N	f	f	t	f	f	\N
561	5	Instituição à qual o campo se aplica	\N	f	f	t	f	f	\N
561	6	Ligação	\N	f	f	t	f	f	\N
561	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
562	#	Nota de identificação de cópia e versão	\N	t	t	t	f	f	\N
562	a	Marca identificadora	\N	t	f	t	f	f	\N
562	b	Identificação de cópia	\N	t	f	t	f	f	\N
562	c	Identificação de versão	\N	t	f	t	f	f	\N
562	d	Formato de apresentação	\N	t	f	t	f	f	\N
562	e	Número de cópias	\N	t	f	t	f	f	\N
562	3	Materiais especificados	\N	f	f	t	f	f	\N
562	5	Instituição à qual o campo se aplica	\N	f	f	t	f	f	\N
562	6	Ligação	\N	f	f	t	f	f	\N
562	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
565	#	Nota de características de arquivo	\N	t	t	t	f	f	\N
565	a	Número de pastas/Variáveis	\N	f	f	t	f	f	\N
565	b	Nome da variável	\N	t	f	t	f	f	\N
565	c	Unidade de análise	\N	t	f	t	f	f	\N
565	d	Universo de dados	\N	t	f	t	f	f	\N
565	e	Código ou esquema de preenchimento	\N	t	f	t	f	f	\N
565	3	Materiais especificados	\N	f	f	t	f	f	\N
565	6	Ligação	\N	f	f	t	f	f	\N
565	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
567	#	Nota de metodologia	\N	t	t	t	f	f	\N
567	a	Nota de metodologia	\N	f	f	t	f	f	\N
567	6	Ligação	\N	f	f	t	f	f	\N
567	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
580	#	Nota de ligação complexa de entrada	\N	t	t	t	f	f	\N
580	a	Nota de ligação complexa de entrada	\N	f	f	t	f	f	\N
580	z	Fonte da informação na nota	\N	f	f	t	f	t	\N
580	6	Ligação	\N	f	f	t	f	f	\N
580	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
581	#	Nota de publicações sobre materiais descritos	\N	t	t	t	f	f	\N
581	a	Nota de publicações sobre materiais descritos	\N	f	f	t	f	f	\N
581	z	ISSN - International Standard Serial Number	\N	t	f	t	f	f	\N
581	3	Materiais especificados	\N	f	f	t	f	f	\N
581	6	Ligação	\N	f	f	t	f	f	\N
581	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
583	#	Nota de ação	\N	t	t	t	f	f	\N
583	a	Ação	\N	f	f	t	f	f	\N
583	b	Identificação da Ação	\N	t	f	t	f	f	\N
583	c	Tempo da Ação	\N	t	f	t	f	f	\N
583	e	Contingência da Ação	\N	t	f	t	f	f	\N
583	f	Autorização	\N	t	f	t	f	f	\N
583	h	Jurisdição	\N	t	f	t	f	f	\N
583	i	Método da Ação	\N	t	f	t	f	f	\N
583	j	Lugar da Ação	\N	t	f	t	f	f	\N
583	k	Agente da Ação	\N	t	f	t	f	f	\N
583	l	Status	\N	t	f	t	f	f	\N
583	n	Extensão	\N	t	f	t	f	f	\N
583	o	Tipo de unidade	\N	t	f	t	f	f	\N
583	x	Nota interna	\N	t	f	t	f	f	\N
583	z	Nota Pública	\N	t	f	t	f	f	\N
583	3	Materiais especificados	\N	f	f	t	f	f	\N
583	5	Instituição à qual o campo se aplica	\N	f	f	t	f	f	\N
583	6	Ligação	\N	f	f	t	f	f	\N
583	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
584	#	Nota de acumulação e freqüência de uso	\N	t	t	t	f	f	\N
584	a	Acumulação	\N	t	f	t	f	f	\N
584	b	Freqüência de uso	\N	t	f	t	f	f	\N
584	3	Materiais especificados	\N	t	f	t	f	f	\N
584	5	Instituição à qual o campo se aplica	\N	f	f	t	f	f	\N
584	6	Ligação	\N	f	f	t	f	f	\N
584	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
585	#	Nota de exposição	\N	t	t	t	f	f	\N
585	a	Nota de exposição	\N	f	f	t	f	f	\N
585	3	Materiais especificados	\N	f	f	t	f	f	\N
585	5	Instituição à qual o campo se aplica	\N	f	f	t	f	f	\N
585	6	Ligação	\N	f	f	t	f	f	\N
585	8	Ligação de Campo e Seqüência	\N	f	f	t	f	f	\N
586	#	Nota de Premiação	\N	t	t	t	f	f	\N
586	a	Nota de Premiação	\N	f	f	t	f	f	\N
586	3	Materiais especificados	\N	f	f	t	f	f	\N
586	6	Ligação	\N	f	f	t	f	f	\N
586	8	Ligação de Campo e Seqüência	\N	t	f	t	f	f	\N
590	#	Notas Locais	\N	t	t	t	f	f	\N
590	a	Notas Locais	\N	f	f	t	f	f	\N
877	h	Restrição de uso	\N	t	f	t	f	f	\N
877	j	Status do item	\N	t	f	t	f	f	\N
877	l	Localização temporária	\N	t	f	t	f	f	\N
877	p	Designação da parte	\N	t	f	t	f	f	\N
877	r	Designação da parte inválida ou cancelada	\N	t	f	t	f	f	\N
877	x	Nota interna	\N	t	f	t	f	f	\N
877	z	Nota pública	\N	t	f	t	f	f	\N
877	3	Especificação dos materiais	\N	f	f	t	f	f	\N
877	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
878	#	Informação de item - Índices	\N	f	t	t	f	f	\N
878	a	Número do item interno	\N	f	f	t	f	f	\N
878	b	Número inválido ou cancelado do item interno	\N	t	f	t	f	f	\N
878	c	Preço	\N	t	f	t	f	f	\N
878	d	Data da aquisição	\N	t	f	t	f	f	\N
878	e	Fonte de aquisição	\N	t	f	t	f	f	\N
878	h	Restrições de uso	\N	t	f	t	f	f	\N
878	j	Status do item	\N	t	f	t	f	f	\N
878	l	Localização temporária	\N	t	f	t	f	f	\N
878	p	Designação da parte	\N	t	f	t	f	f	\N
878	r	Designação inválida ou cancelada da parte	\N	t	f	t	f	f	\N
878	t	Número do exemplar	\N	f	f	t	f	f	\N
878	x	Nota interna	\N	t	f	t	f	f	\N
878	z	Nota pública	\N	t	f	t	f	f	\N
878	3	Especificação dos materiais	\N	f	f	t	f	f	\N
878	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
880	#	Representação gráfica alternada	\N	t	t	t	f	f	\N
880	6	Ligação	\N	f	f	t	f	f	\N
610	#	Assunto - Nome Corporativo	\N	t	t	t	f	f	\N
610	a	Nome Corporativo ou nome da jurisdição	\N	f	f	t	f	f	\N
610	b	Unidade subordinada	\N	t	f	t	f	f	\N
610	c	Local do evento	\N	f	f	t	f	f	\N
610	d	Data do evento ou assinatura do acordo	\N	t	f	t	f	f	\N
610	e	Termo relacionador	\N	t	f	t	f	f	\N
610	f	Data da obra	\N	f	f	t	f	f	\N
610	g	Miscelânea	\N	f	f	t	f	f	\N
610	h	Meio físico	\N	f	f	t	f	f	\N
610	k	Subcabeçalho de forma	\N	t	f	t	f	f	\N
610	l	Idioma da obra	\N	f	f	t	f	f	\N
610	m	Forma de execução para música	\N	t	f	t	f	f	\N
610	o	Informações de arranjo para música	\N	f	f	t	f	f	\N
610	n	Número da parte / seção / evento	\N	t	f	t	f	f	\N
610	p	Nome da parte / seção da obra	\N	t	f	t	f	f	\N
610	r	Chave para música	\N	f	f	t	f	f	\N
610	s	Versão	\N	f	f	t	f	f	\N
610	t	Título da obra	\N	f	f	t	f	f	\N
610	u	Afiliação	\N	f	f	t	f	f	\N
610	v	Subdivisão de forma	\N	t	f	t	f	f	\N
610	x	Subdivisão geral	\N	t	f	t	f	f	\N
610	y	Subdivisão cronológica	\N	t	f	t	f	f	\N
610	z	Subdivisão geográfica	\N	t	f	t	f	f	\N
610	2	Fonte do cabeçalho ou termo	\N	f	f	t	f	f	\N
610	3	Materiais especificados	\N	f	f	t	f	f	\N
610	4	Código do relacionador	\N	t	f	t	f	f	\N
610	6	Ligação	\N	f	f	t	f	f	\N
610	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
611	#	Assunto - Nome do Evento	\N	t	t	t	f	f	\N
611	a	Nome do Evento ou Nome da Jurisdição como Entrada	\N	f	f	t	f	f	\N
611	b	Número (BK CF MP MU SE VM MX)	\N	f	f	t	f	t	\N
611	c	Local do Evento	\N	f	f	t	f	f	\N
611	d	Data do Evento	\N	f	f	t	f	f	\N
611	e	Unidade Subordinada	\N	t	f	t	f	f	\N
611	f	Data da Obra	\N	f	f	t	f	f	\N
611	g	Miscelânea	\N	f	f	t	f	f	\N
611	h	Meio físico	\N	f	f	t	f	f	\N
611	k	Subcabeçalho de Forma	\N	t	f	t	f	f	\N
611	l	Idioma da Obra	\N	f	f	t	f	f	\N
611	n	Número da parte / seção / evento	\N	t	f	t	f	f	\N
611	p	Nome da parte / seção da obra	\N	t	f	t	f	f	\N
611	q	Nome do evento seguindo o nome da jurisdição	\N	f	f	t	f	f	\N
611	s	Versão	\N	f	f	t	f	f	\N
611	t	Título da obra	\N	f	f	t	f	f	\N
611	u	Afiliação	\N	f	f	t	f	f	\N
611	v	Subdivisão de forma	\N	t	f	t	f	f	\N
611	x	Subdivisão geral	\N	t	f	t	f	f	\N
611	y	Subdivisão cronológica	\N	t	f	t	f	f	\N
611	z	Subdivisão geográfica	\N	t	f	t	f	f	\N
611	2	Fonte do cabeçalho ou termo	\N	f	f	t	f	f	\N
611	3	Materiais especificados	\N	f	f	t	f	f	\N
611	4	Código Relacionador	\N	t	f	t	f	f	\N
611	6	Ligação	\N	f	f	t	f	f	\N
611	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
630	#	Assunto - Título Uniforme	\N	t	t	t	f	f	\N
630	a	Título Uniforme	\N	f	f	t	f	f	\N
630	d	Data de assinatura do acordo	\N	t	f	t	f	f	\N
630	f	Data da obra	\N	f	f	t	f	f	\N
630	g	Miscelânea	\N	f	f	t	f	f	\N
630	h	Meio físico	\N	f	f	t	f	f	\N
630	k	Subcabeçalho de forma	\N	t	f	t	f	f	\N
630	l	Idioma da obra	\N	f	f	t	f	f	\N
630	m	Forma de execução para música	\N	t	f	t	f	f	\N
630	n	Número da parte / seção da obra	\N	t	f	t	f	f	\N
630	o	Informação de arranjo para música	\N	f	f	t	f	f	\N
630	p	Nome da parte / seção da obra	\N	t	f	t	f	f	\N
630	r	Chave para música	\N	f	f	t	f	f	\N
630	s	Versão	\N	f	f	t	f	f	\N
630	t	Título da obra	\N	f	f	t	f	f	\N
630	v	Subdivisão de forma	\N	t	f	t	f	f	\N
630	x	Subdivisão geral	\N	t	f	t	f	f	\N
630	y	Subdivisão cronológica	\N	t	f	t	f	f	\N
630	z	Subdivisão geográfica	\N	t	f	t	f	f	\N
630	2	Fonte do cabeçalho ou termo	\N	f	f	t	f	f	\N
630	3	Materiais especificados	\N	f	f	t	f	f	\N
630	6	Ligação	\N	f	f	t	f	f	\N
630	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
650	#	Assunto - Termo Tópico	\N	t	t	t	f	f	\N
650	b	Termo tópico seguindo o nome geográfico	\N	f	f	t	f	f	\N
650	c	Local do evento	\N	f	f	t	f	f	\N
650	d	Datas	\N	f	f	t	f	f	\N
650	e	Termo relacionador	\N	f	f	t	f	f	\N
650	v	Subdivisão de forma	\N	t	f	t	f	f	\N
650	x	Subdivisão geral	\N	t	f	t	f	f	\N
650	y	Subdivisão cronológica	\N	t	f	t	f	f	\N
650	z	Subdivisão geográfica	\N	t	f	t	f	f	\N
650	2	Fonte do cabeçalho ou termo	\N	f	f	t	f	f	\N
650	3	Materiais especificados	\N	f	f	t	f	f	\N
650	6	Ligação	\N	f	f	t	f	f	\N
650	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
651	#	Assunto - Nome geográfico	\N	t	t	t	f	f	\N
651	a	Nome geográfico	\N	f	f	t	f	f	\N
651	b	Nome geográfico seguindo o nome do local	\N	t	f	t	f	t	\N
651	v	Subdivisão de forma	\N	t	f	t	f	f	\N
651	x	Subdivisão geral	\N	t	f	t	f	f	\N
651	y	Subdivisão cronológica	\N	t	f	t	f	f	\N
651	z	Subdivisão geográfica	\N	t	f	t	f	f	\N
651	2	Fonte do cabeçalho ou termo	\N	f	f	t	f	f	\N
651	3	Materiais especificados	\N	f	f	t	f	f	\N
651	6	Ligação	\N	f	f	t	f	f	\N
651	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
653	#	Assunto - Termo livre	\N	t	t	t	f	f	\N
877	b	Número inválido ou cancelado do item interno	\N	t	f	t	f	f	\N
653	6	Ligação	\N	f	f	t	f	f	\N
653	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
654	#	Assunto - Termos tópicos facetados	\N	t	t	t	f	f	\N
654	a	Termo foco	\N	f	f	t	f	f	\N
654	b	Termo não foco	\N	t	f	t	f	f	\N
654	c	Designação da faceta / hierarquia	\N	t	f	t	f	f	\N
654	v	Subdivisão de forma	\N	t	f	t	f	f	\N
654	y	Subdivisão cronológica	\N	t	f	t	f	f	\N
654	z	Subdivisão geográfica	\N	t	f	t	f	f	\N
654	2	Fonte do cabeçalho ou termo	\N	f	f	t	f	f	\N
654	3	Material especificado	\N	f	f	t	f	f	\N
654	6	Ligação	\N	f	f	t	f	f	\N
654	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
655	#	Termo de índice - Gênero / forma / características físicas	\N	t	t	t	f	f	\N
655	a	Gênero / forma / características físicas	\N	f	f	t	f	f	\N
655	b	Termo não foco	\N	t	f	t	f	f	\N
655	c	Faceta / designação hierárquica	\N	t	f	t	f	f	\N
655	v	Subdivisão de forma	\N	t	f	t	f	f	\N
655	x	Subdivisão geral	\N	t	f	t	f	f	\N
655	y	Subdivisão cronológica	\N	t	f	t	f	f	\N
655	z	Subdivisão geográfica	\N	t	f	t	f	f	\N
655	2	Fonte do termo	\N	f	f	t	f	f	\N
655	3	Materiais especificados	\N	f	f	t	f	f	\N
655	5	Instituição a qual se refere o campo	\N	f	f	t	f	f	\N
655	6	Ligação	\N	f	f	t	f	f	\N
655	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
656	#	Termo de índice-ocupação	\N	t	t	t	f	f	\N
656	a	Ocupação	\N	f	f	t	f	f	\N
656	k	Forma	\N	f	f	t	f	f	\N
656	v	Subdivisão de forma	\N	f	f	t	f	f	\N
656	x	Subdivisão geral	\N	t	f	t	f	f	\N
656	y	Subdivisão cronológica	\N	t	f	t	f	f	\N
656	z	Subdivisão geográfica	\N	t	f	t	f	f	\N
656	2	Fonte do termo	\N	f	f	t	f	f	\N
656	3	Materiais especificados	\N	f	f	t	f	f	\N
656	6	Ligação	\N	f	f	t	f	f	\N
656	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
657	#	Termo de índice-função	\N	t	t	t	f	f	\N
657	a	Função	\N	f	f	t	f	f	\N
657	v	Subdivisão de forma	\N	f	f	t	f	f	\N
657	x	Subdivisão geral	\N	t	f	t	f	f	\N
657	y	Subdivisão cronológia	\N	t	f	t	f	f	\N
657	z	Subdivisão geográfica	\N	t	f	t	f	f	\N
657	2	Fonte do termo	\N	f	f	t	f	f	\N
657	3	Materiais especificados	\N	f	f	t	f	f	\N
657	6	Ligação	\N	f	f	t	f	f	\N
657	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
658	#	Termo de índice-currículum	\N	t	t	t	f	f	\N
658	a	Objetivo do currículo principal	\N	f	f	t	f	f	\N
658	b	Objetivo do currículo subordinado	\N	t	f	t	f	f	\N
658	d	Fator de correlação	\N	f	f	t	f	f	\N
658	2	Fonte do termo	\N	f	f	t	f	f	\N
658	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
700	#	Entrada secundária - Nome pessoal	\N	t	t	t	f	f	\N
877	d	Data da aquisição	\N	t	f	t	f	f	\N
700	b	Numeração	\N	f	f	t	f	f	\N
700	c	Títulos e outras palavras associadas ao nome	\N	t	f	t	f	f	\N
700	d	Datas associadas ao nome	\N	f	f	t	f	f	\N
700	e	Termo relacionador	\N	t	f	t	f	f	\N
700	f	Data da obra	\N	f	f	t	f	f	\N
700	g	Miscelânea	\N	f	f	t	f	f	\N
700	h	Meio físico	\N	f	f	t	f	f	\N
700	k	Subcabeçalho	\N	t	f	t	f	f	\N
700	l	Idioma da obra	\N	f	f	t	f	f	\N
700	m	Meio de apresentação para música	\N	t	f	t	f	f	\N
700	n	Número de parte / seção da obra	\N	t	f	t	f	f	\N
700	o	Informação de arranjo para música	\N	f	f	t	f	f	\N
700	p	Nome de parte / seção da obra	\N	t	f	t	f	f	\N
700	q	Forma completa do nome	\N	f	f	t	f	f	\N
700	r	Chave para música	\N	f	f	t	f	f	\N
700	s	Versão	\N	f	f	t	f	f	\N
700	t	Título da obra	\N	f	f	t	f	f	\N
700	u	Afiliação	\N	f	f	t	f	f	\N
700	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
700	3	Materiais especificados	\N	f	f	t	f	f	\N
700	4	Código relacionador	\N	t	f	t	f	f	\N
700	5	Instituição à qual o campo se aplica	\N	f	f	t	f	f	\N
700	6	Ligação	\N	f	f	t	f	f	\N
700	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
710	#	Entrada secundária - Nome corporativo	\N	t	t	t	f	f	\N
710	a	Nome corporativo ou jurisdição	\N	f	f	t	f	f	\N
710	b	Unidade subordinada	\N	t	f	t	f	f	\N
710	c	Local do evento	\N	f	f	t	f	f	\N
710	d	Data do evento ou assinatura de tratado	\N	t	f	t	f	f	\N
710	e	Termo relacionador	\N	t	f	t	f	f	\N
710	f	Data da obra	\N	f	f	t	f	f	\N
710	g	Miscelânea	\N	f	f	t	f	f	\N
710	h	Meio físico	\N	f	f	t	f	f	\N
710	k	Subcabeçalho	\N	t	f	t	f	f	\N
710	l	Idioma da obra	\N	f	f	t	f	f	\N
710	m	Meio de apresentação para música	\N	t	f	t	f	f	\N
710	n	Número de parte / seção da obra	\N	t	f	t	f	f	\N
710	o	Informação de arranjo para música	\N	f	f	t	f	f	\N
710	p	Nome de parte / seção da obra	\N	t	f	t	f	f	\N
710	r	Chave para música	\N	f	f	t	f	f	\N
710	s	Versão	\N	f	f	t	f	f	\N
710	t	Título da obra	\N	f	f	t	f	f	\N
710	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
710	3	Materiais especificados	\N	f	f	t	f	f	\N
710	4	Termo relacionador	\N	t	f	t	f	f	\N
710	5	Instituição à qual o campo se aplica	\N	f	f	t	f	f	\N
710	6	Ligação	\N	f	f	t	f	f	\N
710	8	Ligação de campos e seqüência	\N	t	f	t	f	f	\N
711	#	Entrada secundária - Nome de evento	\N	t	t	t	f	f	\N
711	a	Nome do evento ou jurisdição como entrada	\N	f	f	t	f	f	\N
711	b	Número (BK CF MP MU SE VM MX)	\N	f	f	t	f	t	\N
711	c	Local do evento	\N	f	f	t	f	f	\N
711	d	Data do evento	\N	f	f	t	f	f	\N
711	e	Unidade subordinada	\N	t	f	t	f	f	\N
711	f	Data da obra	\N	f	f	t	f	f	\N
711	g	Miscelânea	\N	f	f	t	f	f	\N
711	h	Meio físico	\N	f	f	t	f	f	\N
711	k	Subcabeçalho	\N	t	f	t	f	f	\N
711	l	Idioma da obra	\N	f	f	t	f	f	\N
711	n	Número de parte / seção da obra	\N	t	f	t	f	f	\N
711	p	Nome de parte / seção da obra	\N	t	f	t	f	f	\N
711	q	Nome do evento seguindo nome da jurisdição como elemento de entrada	\N	f	f	t	f	f	\N
711	s	Versão	\N	f	f	t	f	f	\N
711	t	Título da obra	\N	f	f	t	f	f	\N
711	u	Afiliação	\N	f	f	t	f	f	\N
711	x	ISSN -  International Standard Serial Number	\N	f	f	t	f	f	\N
711	3	Materiais especificados	\N	f	f	t	f	f	\N
711	4	Termo relacionador	\N	t	f	t	f	f	\N
711	5	Instituição à qual o campo se aplica	\N	f	f	t	f	f	\N
711	6	Ligação	\N	f	f	t	f	f	\N
711	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
720	#	Entrada secundária - Nome não controlado	\N	t	t	t	f	f	\N
720	a	Nome	\N	f	f	t	f	f	\N
720	e	Termo relacionador	\N	t	f	t	f	f	\N
720	4	Código relacionador	\N	t	f	t	f	f	\N
720	6	Ligação	\N	f	f	t	f	f	\N
720	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
730	#	Entrada secundária - Título uniforme	\N	t	t	t	f	f	\N
730	a	Título uniforme	\N	f	f	t	f	f	\N
730	d	Data da assinatura do tratado	\N	t	f	t	f	f	\N
730	g	Miscelânea	\N	f	f	t	f	f	\N
730	h	Meio físico	\N	f	f	t	f	f	\N
730	k	Subcabeçalho	\N	t	f	t	f	f	\N
730	l	Idioma da obra	\N	f	f	t	f	f	\N
730	m	Meio de apresentação para música	\N	t	f	t	f	f	\N
730	n	Número de parte / seção da obra	\N	t	f	t	f	f	\N
730	o	Informação de arranjo para música	\N	f	f	t	f	f	\N
730	p	Nome de parte / seção da obra	\N	t	f	t	f	f	\N
730	r	Chave para música	\N	f	f	t	f	f	\N
730	s	Versão	\N	f	f	t	f	f	\N
730	t	Título da obra	\N	f	f	t	f	f	\N
730	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
730	3	Materiais especificados	\N	f	f	t	f	f	\N
730	5	Instituição à qual o campo se aplica	\N	f	f	t	f	f	\N
730	6	Ligação	\N	f	f	t	f	f	\N
730	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
740	#	Entrada secundária - Título relacionado / Analítico não controlado	\N	t	t	t	f	f	\N
740	a	Título relacionado / Analítico não controlado	\N	f	f	t	f	f	\N
740	h	Meio físico	\N	f	f	t	f	f	\N
740	n	Número de parte / seção da obra	\N	t	f	t	f	f	\N
740	p	Nome de parte / seção da obra	\N	t	f	t	f	f	\N
740	5	Instituição à qual o campo se aplica	\N	f	f	t	f	f	\N
740	6	Ligação	\N	f	f	t	f	f	\N
740	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
752	#	Entrada secundária - Nome hierárquico de lugar	\N	t	t	t	f	f	\N
752	a	País	\N	f	f	t	f	f	\N
752	b	Estado, província, território	\N	f	f	t	f	f	\N
752	c	País, região, ilha	\N	f	f	t	f	f	\N
752	d	Cidade	\N	f	f	t	f	f	\N
752	6	Ligação	\N	f	f	t	f	f	\N
752	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
753	#	Detalhes de sistema para acesso a arquivos de computador	\N	t	t	t	f	f	\N
753	a	Tipo e modelo da máquina	\N	f	f	t	f	f	\N
753	b	Linguagem de programação	\N	f	f	t	f	f	\N
753	c	Sistema operacional	\N	f	f	t	f	f	\N
753	6	Ligação	\N	f	f	t	f	f	\N
753	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
754	#	Entrada secundária - Identificação taxonômica	\N	t	t	t	f	f	\N
754	a	Nome taxonômico / categoria taxonômica hierárquica	\N	t	f	t	f	f	\N
754	2	Fonte da identificação taxonômica	\N	f	f	t	f	f	\N
754	6	Ligação	\N	f	f	t	f	f	\N
754	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
755	#	Entrada secundária - Características físicas	\N	t	f	t	f	t	\N
760	#	Entrada de série principal	\N	t	t	t	f	f	\N
760	a	Título da entrada principal	\N	f	f	t	f	f	\N
760	b	Edição	\N	f	f	t	f	f	\N
760	c	Informação qualificadora	\N	f	f	t	f	f	\N
760	d	Lugar, editor, e data de publicação	\N	f	f	t	f	f	\N
760	g	Informação de relação	\N	t	f	t	f	f	\N
760	i	Exibir texto	\N	f	f	t	f	f	\N
760	h	Descrição física	\N	f	f	t	f	f	\N
760	m	Detalhes específicos do material	\N	f	f	t	f	f	\N
760	n	Nota	\N	t	f	t	f	f	\N
760	o	Outro identificador de item	\N	t	f	t	f	f	\N
760	q	Título paralelo (BK SE)	\N	f	f	t	f	t	\N
760	s	Título uniforme	\N	f	f	t	f	f	\N
760	t	Título	\N	f	f	t	f	f	\N
760	w	Número de controle do registro	\N	t	f	t	f	f	\N
760	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
760	y	Designação CODEN	\N	f	f	t	f	f	\N
760	6	Ligação	\N	f	f	t	f	f	\N
760	8	Ligação  de campo e seqüência	\N	t	f	t	f	f	\N
762	#	Entrada de sub-série	\N	t	t	t	f	f	\N
762	a	Título da entrada principal	\N	f	f	t	f	f	\N
762	b	Edição	\N	f	f	t	f	f	\N
762	c	Informação qualificadora	\N	f	f	t	f	f	\N
852	e	Endereço	\N	t	f	t	f	f	\N
762	d	Lugar, editor, e data de publicação	\N	f	f	t	f	f	\N
762	g	Informação de relação	\N	t	f	t	f	f	\N
762	i	Exibir texto	\N	f	f	t	f	f	\N
762	h	Descrição física	\N	f	f	t	f	f	\N
762	m	Detalhes específicos do material	\N	f	f	t	f	f	\N
762	n	Nota	\N	t	f	t	f	f	\N
762	o	Outro identificador de item	\N	t	f	t	f	f	\N
762	q	Título paralelo (BK SE)	\N	f	f	t	f	t	\N
762	s	Título uniforme	\N	f	f	t	f	f	\N
762	t	Título	\N	f	f	t	f	f	\N
762	w	Número de controle do registro	\N	t	f	t	f	f	\N
762	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
762	y	Designação CODEN	\N	f	f	t	f	f	\N
762	6	Ligação	\N	f	f	t	f	f	\N
762	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
765	#	Entrada de idioma original	\N	t	t	t	f	f	\N
765	a	Título de entrada principal	\N	f	f	t	f	f	\N
765	b	Edição	\N	f	f	t	f	f	\N
765	c	Informação qualificadora	\N	f	f	t	f	f	\N
765	d	Lugar, editor, e data de publicação	\N	f	f	t	f	f	\N
765	g	Informação de relação	\N	t	f	t	f	f	\N
765	i	Exibir texto	\N	f	f	t	f	f	\N
765	h	Descrição física	\N	f	f	t	f	f	\N
765	k	Dado de série para item relacionado	\N	t	f	t	f	f	\N
765	m	Detalhes específicos do material	\N	f	f	t	f	f	\N
765	n	Nota	\N	t	f	t	f	f	\N
765	o	Outro identificador de item	\N	t	f	t	f	f	\N
765	q	Título paralelo (BK SE)	\N	f	f	t	f	t	\N
765	r	Número de relatório	\N	t	f	t	f	f	\N
765	s	Título uniforme	\N	f	f	t	f	f	\N
765	t	Título	\N	f	f	t	f	f	\N
765	u	Standard technical report number	\N	f	f	t	f	f	\N
765	w	Número de controle do registro	\N	t	f	t	f	f	\N
765	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
765	y	Designação CODEN	\N	f	f	t	f	f	\N
765	6	Ligação	\N	f	f	t	f	f	\N
765	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
767	#	Entrada de tradução	\N	t	t	t	f	f	\N
767	a	Título de entrada principal	\N	f	f	t	f	f	\N
767	b	Edição	\N	f	f	t	f	f	\N
767	c	Informação qualificadora	\N	f	f	t	f	f	\N
767	d	Lugar, editor, e data de publicação	\N	f	f	t	f	f	\N
767	g	Informação de relação	\N	t	f	t	f	f	\N
767	i	Exibir texto	\N	f	f	t	f	f	\N
767	h	Descrição física	\N	f	f	t	f	f	\N
767	k	Dado de série para item relacionado	\N	t	f	t	f	f	\N
767	m	Detalhes específicos do material	\N	f	f	t	f	f	\N
767	n	Nota	\N	t	f	t	f	f	\N
767	o	Outro identificador de item	\N	t	f	t	f	f	\N
767	q	Título paralelo (BK SE)	\N	f	f	t	f	t	\N
767	r	Número de relatório	\N	t	f	t	f	f	\N
767	s	Título uniforme	\N	f	f	t	f	f	\N
767	t	Título	\N	f	f	t	f	f	\N
767	u	Standard technical report number	\N	f	f	t	f	f	\N
767	w	Número de controle do registro	\N	t	f	t	f	f	\N
767	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
767	z	ISBN - International Standard Book Number	\N	t	f	t	f	f	\N
767	y	Designação CODEN	\N	f	f	t	f	f	\N
767	6	Ligação	\N	f	f	t	f	f	\N
767	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
770	#	Entrada de suplemento / edição especial	\N	t	t	t	f	f	\N
770	a	Título da entrada principal	\N	f	f	t	f	f	\N
770	b	Edição	\N	f	f	t	f	f	\N
770	c	Informação qualificadora	\N	f	f	t	f	f	\N
770	d	Lugar, editor, e data de publicação	\N	f	f	t	f	f	\N
770	g	Informação de relação	\N	t	f	t	f	f	\N
770	i	Exibir texto	\N	f	f	t	f	f	\N
770	h	Descrição física	\N	f	f	t	f	f	\N
770	k	Dado de série para item relacionado	\N	t	f	t	f	f	\N
770	m	Detalhes específicos do material	\N	f	f	t	f	f	\N
770	n	Nota	\N	t	f	t	f	f	\N
770	o	Outro identificador de item	\N	t	f	t	f	f	\N
770	q	Título paralelo (BK SE)	\N	f	f	t	f	t	\N
770	r	Número de relatório	\N	t	f	t	f	f	\N
770	s	Título uniforme	\N	f	f	t	f	f	\N
770	t	Título	\N	f	f	t	f	f	\N
770	u	Standard technical report number	\N	f	f	t	f	f	\N
770	w	Número de controle do registo	\N	t	f	t	f	f	\N
770	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
770	z	ISBN - International Standard Book Number	\N	t	f	t	f	f	\N
770	y	Designação CODEN	\N	f	f	t	f	f	\N
770	6	Ligação	\N	f	f	t	f	f	\N
770	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
772	#	Entrada de registro fonte	\N	t	t	t	f	f	\N
772	a	Título da entrada principal	\N	f	f	t	f	f	\N
772	b	Edição	\N	f	f	t	f	f	\N
772	c	Informação qualificadora	\N	f	f	t	f	f	\N
772	d	Lugar, editor, e data de publicação	\N	f	f	t	f	f	\N
772	g	Informação de relação	\N	t	f	t	f	f	\N
772	i	Exibir texto	\N	f	f	t	f	f	\N
772	h	Descrição física da fonte	\N	f	f	t	f	f	\N
772	k	Dado de série para item relacionado	\N	t	f	t	f	f	\N
772	m	Detalhes específicos do material	\N	f	f	t	f	f	\N
772	n	Nota	\N	t	f	t	f	f	\N
772	o	Outro identificador de item	\N	t	f	t	f	f	\N
772	q	Título paralelo (BK SE)	\N	f	f	t	f	t	\N
772	r	Número de relatório	\N	t	f	t	f	f	\N
772	s	Título uniforme	\N	f	f	t	f	f	\N
772	t	Título	\N	f	f	t	f	f	\N
772	u	Standard technical report number	\N	f	f	t	f	f	\N
772	w	Número de controle do registro	\N	t	f	t	f	f	\N
772	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
772	z	ISBN - International Standard Book Number	\N	t	f	t	f	f	\N
772	y	Designação CODEN	\N	f	f	t	f	f	\N
772	6	Ligação	\N	f	f	t	f	f	\N
772	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
773	#	Entrada analítica	\N	t	t	t	f	f	\N
773	a	Título da entrada principal	\N	f	f	t	f	f	\N
773	b	Edição	\N	f	f	t	f	f	\N
773	d	Lugar, editor, e data de publicação	\N	f	f	t	f	f	\N
773	g	Informação de relação	\N	t	f	t	f	f	\N
773	h	Descrição física da fonte	\N	f	f	t	f	f	\N
773	i	Exibir texto	\N	f	f	t	f	f	\N
773	k	Dado de série para item relacionado	\N	t	f	t	f	f	\N
773	m	Detalhes específicos do material	\N	f	f	t	f	f	\N
773	n	Nota	\N	t	f	t	f	f	\N
773	o	Outro identificador de item	\N	t	f	t	f	f	\N
773	r	Número de relatório	\N	t	f	t	f	f	\N
773	p	Título Abreviado	\N	f	f	t	f	f	\N
773	s	Título uniforme	\N	f	f	t	f	f	\N
773	t	Título	\N	f	f	t	f	f	\N
773	u	Standard Technical Report Number	\N	f	f	t	f	f	\N
773	w	Número de controle	\N	t	f	t	f	f	\N
773	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
773	y	Designação CODEN	\N	f	f	t	f	f	\N
773	Z	ISBN - International Standard Book Number	\N	t	f	t	f	f	\N
773	3	Materiais especificados	\N	f	f	t	f	f	\N
773	6	Ligação	\N	f	f	t	f	f	\N
773	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
774	#	Entrada de unidade constituinte	\N	t	t	t	f	f	\N
774	a	Título da entrada principal	\N	f	f	t	f	f	\N
774	b	Edição	\N	f	f	t	f	f	\N
774	c	Informação qualificadora	\N	f	f	t	f	f	\N
774	d	Lugar, editor, e data de publicação	\N	f	f	t	f	f	\N
774	g	Informação de relação	\N	t	f	t	f	f	\N
774	i	Exibir texto	\N	f	f	t	f	f	\N
774	h	Descrição física da fonte	\N	f	f	t	f	f	\N
774	k	Dado de série para item relacionado	\N	t	f	t	f	f	\N
774	m	Detalhes específicos do material	\N	f	f	t	f	f	\N
774	n	Nota	\N	t	f	t	f	f	\N
774	o	Outro identificador de item	\N	t	f	t	f	f	\N
774	r	Número de relatório	\N	t	f	t	f	f	\N
774	s	Título uniforme	\N	f	f	t	f	f	\N
774	t	Título	\N	f	f	t	f	f	\N
774	u	Standard technical report number	\N	f	f	t	f	f	\N
774	w	Número de controle do registro	\N	t	f	t	f	f	\N
774	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
774	y	Designação CODEN	\N	f	f	t	f	f	\N
774	z	ISBN - International Standard Book Number	\N	t	f	t	f	f	\N
774	6	Ligação	\N	f	f	t	f	f	\N
774	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
775	#	Entrada de outra edição	\N	t	t	t	f	f	\N
775	a	Título da entrada principal	\N	f	f	t	f	f	\N
775	b	Edição	\N	f	f	t	f	f	\N
775	c	Informação qualificadora	\N	f	f	t	f	f	\N
775	d	Lugar, editor, e data de publicação	\N	f	f	t	f	f	\N
775	e	Código de idioma	\N	f	f	t	f	f	\N
775	f	Código de país	\N	f	f	t	f	f	\N
775	g	Informação de relação	\N	t	f	t	f	f	\N
775	i	Exibir texto	\N	f	f	t	f	f	\N
775	h	Descrição física	\N	f	f	t	f	f	\N
775	k	Dado de série para item relacionado	\N	t	f	t	f	f	\N
775	m	Detalhes específicos do material	\N	f	f	t	f	f	\N
775	n	Nota	\N	t	f	t	f	f	\N
775	o	Outro identificador de item	\N	t	f	t	f	f	\N
775	q	Título paralelo (BK SE)	\N	f	f	t	f	t	\N
775	r	Número de relatório	\N	t	f	t	f	f	\N
775	s	Título uniforme	\N	f	f	t	f	f	\N
775	t	Título	\N	f	f	t	f	f	\N
775	u	Standard Technical Report Number	\N	f	f	t	f	f	\N
775	w	Número de controle do registro	\N	t	f	t	f	f	\N
775	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
775	z	ISBN - International Standard Book Number	\N	t	f	t	f	f	\N
775	y	Designação CODEN	\N	f	f	t	f	f	\N
775	6	Ligação	\N	f	f	t	f	f	\N
775	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
776	#	Entrada de forma física adicional	\N	t	t	t	f	f	\N
776	a	Título da entrada principal	\N	f	f	t	f	f	\N
776	b	Edição	\N	f	f	t	f	f	\N
776	c	Informação qualificadora	\N	f	f	t	f	f	\N
776	d	Lugar, editor, e data de publicação	\N	f	f	t	f	f	\N
776	g	Informação de relação	\N	t	f	t	f	f	\N
776	i	Exibir texto	\N	f	f	t	f	f	\N
776	h	Descrição física	\N	f	f	t	f	f	\N
776	k	Dado de série para item relacionado	\N	t	f	t	f	f	\N
776	m	Detalhes específicos do material	\N	f	f	t	f	f	\N
776	n	Nota	\N	t	f	t	f	f	\N
776	o	Outro identificador de item	\N	t	f	t	f	f	\N
776	q	Título paralelo (BK SE)	\N	f	f	t	f	t	\N
776	r	Número de relatório	\N	t	f	t	f	f	\N
776	s	Título uniforme	\N	f	f	t	f	f	\N
776	t	Título	\N	f	f	t	f	f	\N
776	u	Standard Technical Report Number	\N	f	f	t	f	f	\N
776	w	Número de controle do registro	\N	t	f	t	f	f	\N
776	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
844	#	Nome da unidade	\N	f	t	t	f	f	\N
776	z	ISBN - International Standard Book Number	\N	t	f	t	f	f	\N
776	y	Designação CODEN	\N	f	f	t	f	f	\N
776	6	Ligação	\N	f	f	t	f	f	\N
776	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
777	#	Entrada de "Publicado com"	\N	t	t	t	f	f	\N
777	a	Título da entrada principal	\N	f	f	t	f	f	\N
777	b	Edição	\N	f	f	t	f	f	\N
777	c	Informação qualificadora	\N	f	f	t	f	f	\N
777	d	Lugar, editor, e data de publicação	\N	f	f	t	f	f	\N
777	g	Informação de relação	\N	t	f	t	f	f	\N
777	i	Exibir texto	\N	f	f	t	f	f	\N
777	h	Descrição física	\N	f	f	t	f	f	\N
777	k	Dado de série para item relacionado	\N	t	f	t	f	f	\N
777	m	Detalhes específicos do material	\N	f	f	t	f	f	\N
777	o	Outro identificador de item	\N	t	f	t	f	f	\N
777	q	Título paralelo (BK SE)	\N	f	f	t	f	t	\N
777	s	Título uniforme	\N	f	f	t	f	f	\N
777	t	Título	\N	f	f	t	f	f	\N
777	w	Número de controle do registro	\N	t	f	t	f	f	\N
777	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
777	y	Designação CODEN	\N	f	f	t	f	f	\N
777	6	Ligação	\N	f	f	t	f	f	\N
777	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
780	#	Entrada anterior	\N	t	t	t	f	f	\N
780	a	Título da entrada principal	\N	f	f	t	f	f	\N
780	b	Edição	\N	f	f	t	f	f	\N
780	c	Informação qualificadora	\N	f	f	t	f	f	\N
780	d	Lugar, editor, e data de publicação	\N	f	f	t	f	f	\N
780	g	Informação de relação	\N	t	f	t	f	f	\N
780	i	Exibir texto	\N	f	f	t	f	f	\N
780	h	Descrição física	\N	f	f	t	f	f	\N
780	k	Dado de série para item relacionado	\N	t	f	t	f	f	\N
780	m	Detalhes específicos do material	\N	f	f	t	f	f	\N
780	n	Nota	\N	t	f	t	f	f	\N
780	o	Outro identificador de item	\N	t	f	t	f	f	\N
780	q	Título paralelo (BK SE)	\N	f	f	t	f	t	\N
780	r	Número de relatório	\N	t	f	t	f	f	\N
780	s	Título uniforme	\N	f	f	t	f	f	\N
780	t	Título	\N	f	f	t	f	f	\N
780	u	Standard Technical Report Number	\N	f	f	t	f	f	\N
780	w	Número de controle do registro	\N	t	f	t	f	f	\N
780	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
780	z	ISBN - International Standard Book Number	\N	t	f	t	f	f	\N
780	y	Designação CODEN	\N	f	f	t	f	f	\N
780	6	Ligação	\N	f	f	t	f	f	\N
780	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
785	#	Entrada posterior	\N	t	t	t	f	f	\N
785	a	Título da entrada principal	\N	f	f	t	f	f	\N
785	b	Edição	\N	f	f	t	f	f	\N
785	c	Informação qualificadora	\N	f	f	t	f	f	\N
785	d	Lugar, editor, e data de publicação	\N	f	f	t	f	f	\N
785	g	Informação de relação	\N	t	f	t	f	f	\N
785	i	Exibir texto	\N	f	f	t	f	f	\N
785	h	Descrição física	\N	f	f	t	f	f	\N
785	k	Dado de série para item relacionado	\N	t	f	t	f	f	\N
785	m	Detalhes específicos do material	\N	f	f	t	f	f	\N
785	n	Nota	\N	t	f	t	f	f	\N
785	o	Outro identificador de item	\N	t	f	t	f	f	\N
785	q	Título paralelo (BK SE)	\N	f	f	t	f	t	\N
785	r	Número de relatório	\N	t	f	t	f	f	\N
785	s	Título uniforme	\N	f	f	t	f	f	\N
785	t	Título	\N	f	f	t	f	f	\N
785	u	Standard Technical Report Number	\N	f	f	t	f	f	\N
785	w	Número de controle do registro	\N	t	f	t	f	f	\N
785	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
785	z	ISBN - International Standard Book Number	\N	t	f	t	f	f	\N
785	y	Designação CODEN	\N	f	f	t	f	f	\N
785	6	Ligação	\N	f	f	t	f	f	\N
785	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
786	#	Entrada da fonte dos dados	\N	t	t	t	f	f	\N
786	a	Título da entrada principal	\N	f	f	t	f	f	\N
786	b	Edição	\N	f	f	t	f	f	\N
786	c	Informação qualificadora	\N	f	f	t	f	f	\N
786	d	Lugar, editor, e data de publicação	\N	f	f	t	f	f	\N
786	g	Informação de relação	\N	t	f	t	f	f	\N
786	i	Exibir texto	\N	f	f	t	f	f	\N
786	h	Descrição física da fonte	\N	f	f	t	f	f	\N
786	j	Período do conteúdo	\N	f	f	t	f	f	\N
786	k	Dado de série para item relacionado	\N	t	f	t	f	f	\N
786	m	Detalhes específicos do material	\N	f	f	t	f	f	\N
786	n	Nota	\N	t	f	t	f	f	\N
786	o	Outro identificador de item	\N	t	f	t	f	f	\N
786	r	Número de relatório	\N	t	f	t	f	f	\N
786	s	Título uniforme	\N	f	f	t	f	f	\N
786	t	Título	\N	f	f	t	f	f	\N
786	u	Standard Technical Report Number	\N	f	f	t	f	f	\N
786	v	Contribuição da fonte	\N	f	f	t	f	f	\N
786	w	Número de controle do registro	\N	t	f	t	f	f	\N
786	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
786	z	ISBN - International Standard Book Number	\N	t	f	t	f	f	\N
786	y	Designação CODEN	\N	f	f	t	f	f	\N
786	6	Ligação	\N	f	f	t	f	f	\N
786	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
765	z	ISBN - International Standard Book Number	\N	t	f	t	f	f	\N
658	c	Código do currículo	\N	f	f	t	f	f	\N
787	#	Entrada de relação não específica	\N	t	t	t	f	f	\N
787	a	Título da entrada principal	\N	f	f	t	f	f	\N
787	b	Edição	\N	f	f	t	f	f	\N
787	c	Informação qualificadora	\N	f	f	t	f	f	\N
787	d	Lugar, editor, e data de publicação	\N	f	f	t	f	f	\N
787	g	Informação de relação	\N	t	f	t	f	f	\N
787	i	Exibir texto	\N	f	f	t	f	f	\N
787	h	Descrição física da fonte	\N	f	f	t	f	f	\N
787	k	Dado de série para item relacionado	\N	t	f	t	f	f	\N
787	m	Detalhes específicos do material	\N	f	f	t	f	f	\N
787	n	Nota	\N	t	f	t	f	f	\N
787	o	Outro identificador de item	\N	t	f	t	f	f	\N
787	q	Título paralelo (BK SE)	\N	f	f	t	f	t	\N
787	r	Número de relatório	\N	t	f	t	f	f	\N
787	s	Título uniforme	\N	f	f	t	f	f	\N
787	t	Título	\N	f	f	t	f	f	\N
787	u	Standard Technical Report Number	\N	f	f	t	f	f	\N
787	w	Número de controle do registro	\N	t	f	t	f	f	\N
787	x	ISSN - International Standard Serial Number	\N	f	f	t	f	f	\N
787	z	ISBN - International Standard Book Number	\N	t	f	t	f	f	\N
787	y	Designação CODEN	\N	f	f	t	f	f	\N
787	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
800	#	Entrada secundária de série - Nome pessoal	\N	t	t	t	f	f	\N
800	a	Nome pessoal	\N	f	f	t	f	f	\N
800	b	Numeração	\N	f	f	t	f	f	\N
800	c	Títulos e outras palavras associadas ao nome	\N	t	f	t	f	f	\N
800	d	Datas associadas ao nome	\N	f	f	t	f	f	\N
800	e	Termo relacionador	\N	t	f	t	f	f	\N
800	f	Data da obra	\N	f	f	t	f	f	\N
800	g	Miscelânea	\N	f	f	t	f	f	\N
800	h	Meio físico	\N	f	f	t	f	f	\N
800	k	Subcabeçalho	\N	t	f	t	f	f	\N
800	l	Idioma da obra	\N	f	f	t	f	f	\N
800	m	Meio de apresentação para música	\N	t	f	t	f	f	\N
800	n	Número de parte / seção da obra	\N	t	f	t	f	f	\N
800	o	Informação de arranjo para música	\N	f	f	t	f	f	\N
800	p	Nome de parte / seção da obra	\N	t	f	t	f	f	\N
800	q	Forma completa do nome	\N	f	f	t	f	f	\N
800	r	Chave para música	\N	f	f	t	f	f	\N
800	s	Versão	\N	f	f	t	f	f	\N
800	t	Título da obra	\N	f	f	t	f	f	\N
800	u	Afiliação	\N	f	f	t	f	f	\N
800	v	Designação de volume / seqüência	\N	f	f	t	f	f	\N
800	4	Código relacionador	\N	t	f	t	f	f	\N
800	6	Ligação	\N	f	f	t	f	f	\N
800	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
810	#	Entrada secundária de série - Nome corporativo	\N	t	t	t	f	f	\N
810	a	Nome corporativo ou jurisdição como entrada	\N	f	f	t	f	f	\N
810	b	Unidade subordinada	\N	t	f	t	f	f	\N
810	c	Local do evento	\N	f	f	t	f	f	\N
810	d	Data do evento ou assinatura do tratado	\N	t	f	t	f	f	\N
810	e	Termo relacionador	\N	t	f	t	f	f	\N
810	f	Data da obra	\N	f	f	t	f	f	\N
810	g	Miscelânea	\N	f	f	t	f	f	\N
810	h	Meio físico	\N	f	f	t	f	f	\N
810	k	Subcabeçalho	\N	t	f	t	f	f	\N
810	l	Idioma da obra	\N	f	f	t	f	f	\N
810	m	Meio de apresentação para música	\N	t	f	t	f	f	\N
810	n	Número de parte / seção / evento	\N	t	f	t	f	f	\N
810	o	Informações de arranjo para música	\N	f	f	t	f	f	\N
810	p	Nome de parte / seção / evento	\N	t	f	t	f	f	\N
810	r	Chave para música	\N	f	f	t	f	f	\N
810	s	Versão	\N	f	f	t	f	f	\N
810	t	Título da obra	\N	f	f	t	f	f	\N
810	u	Afiliação	\N	f	f	t	f	f	\N
810	v	Designação de volume / seqüência	\N	f	f	t	f	f	\N
810	4	Código relacionador	\N	t	f	t	f	f	\N
810	6	Ligação	\N	f	f	t	f	f	\N
810	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
811	#	Entrada secundária de série - Nome do evento	\N	t	t	t	f	f	\N
811	a	Nome do evento ou jurisdição como entrada	\N	f	f	t	f	f	\N
811	b	Número (BK CF MP MU SE VM MX)	\N	f	f	t	f	t	\N
811	c	Local do evento	\N	f	f	t	f	f	\N
811	d	Data do evento	\N	f	f	t	f	f	\N
811	e	Unidade subordinada	\N	t	f	t	f	f	\N
811	f	Data da obra	\N	f	f	t	f	f	\N
811	g	Miscelânea	\N	f	f	t	f	f	\N
811	h	Meio físico	\N	f	f	t	f	f	\N
811	k	Subcabeçalho	\N	t	f	t	f	f	\N
811	l	Idioma da obra	\N	f	f	t	f	f	\N
811	n	Número de parte / seção / evento	\N	t	f	t	f	f	\N
811	p	Nome de parte / seção / evento	\N	t	f	t	f	f	\N
811	q	Nome do evento que segue nome da jurisdição na entrada	\N	f	f	t	f	f	\N
811	s	Versão	\N	f	f	t	f	f	\N
811	t	Título da obra	\N	f	f	t	f	f	\N
811	u	Afiliação	\N	f	f	t	f	f	\N
811	v	Designação de volume / seqüência	\N	f	f	t	f	f	\N
811	4	Código relacionador	\N	t	f	t	f	f	\N
811	6	Ligação	\N	f	f	t	f	f	\N
811	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
830	#	Entrada secundária de série - Título uniforme	\N	t	t	t	f	f	\N
830	a	Título uniforme	\N	f	f	t	f	f	\N
830	d	Data da assinatura do tratado	\N	t	f	t	f	f	\N
830	f	Data da obra	\N	t	f	t	f	f	\N
830	g	Miscelânea	\N	f	f	t	f	f	\N
830	h	Meio físico	\N	f	f	t	f	f	\N
830	k	Subcabeçalho	\N	t	f	t	f	f	\N
830	l	Idioma da obra	\N	f	f	t	f	f	\N
830	m	Meio da apresentação para música	\N	t	f	t	f	f	\N
830	n	Número de parte / seção da obra	\N	t	f	t	f	f	\N
830	o	Informação de arranjo para música	\N	f	f	t	f	f	\N
830	p	Nome de parte / seção da obra	\N	t	f	t	f	f	\N
830	r	Chave para música	\N	f	f	t	f	f	\N
830	s	Versão	\N	f	f	t	f	f	\N
830	t	Título da obra	\N	f	f	t	f	f	\N
830	v	Designação de volume / seqüência	\N	f	f	t	f	f	\N
830	6	Ligação	\N	f	f	t	f	f	\N
830	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
841	#	Valores de dados codificados de holdings	\N	f	t	t	f	f	\N
841	a	Tipo de registro	\N	f	f	t	f	f	\N
841	b	Elementos de dados de tamanho fixo	\N	f	f	t	f	f	\N
841	e	Nível de catalogação	\N	f	f	t	f	f	\N
842	#	Designação textual de forma física	\N	f	t	t	f	f	\N
842	a	Designação textual de forma física	\N	f	f	t	f	f	\N
843	#	Nota de reprodução	\N	t	t	t	f	f	\N
843	a	Tipo de reprodução	\N	f	f	t	f	f	\N
843	b	Lugar de reprodução	\N	t	f	t	f	f	\N
843	c	Instituição responsável pela reprodução	\N	t	f	t	f	f	\N
843	d	Data da reprodução	\N	f	f	t	f	f	\N
843	e	Descrição física da reprodução	\N	f	f	t	f	f	\N
843	f	Informação de séries de reprodução	\N	t	f	t	f	f	\N
856	b	Número de acesso	\N	f	f	t	f	f	\N
843	m	Datas de publicação e  / ou indicação de seqüência de edições reproduzidas	\N	t	f	t	f	f	\N
843	n	Notas sobre reprodução	\N	t	f	t	f	f	\N
843	3	Materiais especificados	\N	f	f	t	f	f	\N
844	a	Nome da unidade	\N	f	f	t	f	f	\N
845	#	Nota termos reguladores de uso e reprodução	\N	t	t	t	f	f	\N
845	a	Termos reguladores de uso e reprodução	\N	f	f	t	f	f	\N
845	b	Jurisdição	\N	f	f	t	f	f	\N
845	c	Autorização	\N	f	f	t	f	f	\N
845	d	Usuários autorizados	\N	f	f	t	f	f	\N
845	3	Materiais especificados	\N	f	f	t	f	f	\N
850	#	Instituição depositária	\N	t	t	t	f	f	\N
850	a	Instituição depositária	\N	t	f	t	f	f	\N
850	b	Holdings (Coleção) (MU VM SE)	\N	f	f	t	f	t	\N
850	d	Datas abrangentes (MU VM SE)	\N	f	f	t	f	t	\N
850	e	Informação de memória (CF MU VM SE)	\N	f	f	t	f	t	\N
850	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
852	#	Localização / Número de chamada	\N	t	t	t	f	f	\N
852	a	Localização	\N	f	f	t	f	f	\N
852	b	sub-localização ou coleção	\N	t	f	t	f	f	\N
852	c	Localização na prateleira	\N	t	f	t	f	f	\N
852	g	Atributo de localização não codificado	\N	t	f	t	f	f	\N
852	h	Parte referente à classificação	\N	f	f	t	f	f	\N
852	i	Parte referente ao item	\N	t	f	t	f	f	\N
852	j	Número de controle na estante	\N	f	f	t	f	f	\N
852	k	Prefixo do número de chamada	\N	f	f	t	f	f	\N
852	l	Forma do título na estante	\N	f	f	t	f	f	\N
852	m	Sufixo do número de chamada	\N	f	f	t	f	f	\N
852	n	Código de país	\N	f	f	t	f	f	\N
852	p	Designação do item	\N	f	f	t	f	f	\N
852	q	Condição física do item	\N	f	f	t	f	f	\N
852	s	Código de taxa de copyright	\N	t	f	t	f	f	\N
852	t	Número de cópia	\N	f	f	t	f	f	\N
852	x	Nota interna	\N	t	f	t	f	f	\N
852	z	Nota pública	\N	t	f	t	f	f	\N
852	2	Fonte da classificação ou esquema na prateleira	\N	f	f	t	f	f	\N
852	3	Materiais especificados	\N	f	f	t	f	f	\N
852	6	Ligação	\N	f	f	t	f	f	\N
852	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
853	#	Legenda e padrão - Unidade bibliográfica básica	\N	t	t	t	f	f	\N
853	a	Primeiro nível de enumeração	\N	f	f	t	f	f	\N
853	b	Segundo nível de enumeração	\N	f	f	t	f	f	\N
853	c	Terceiro nível de enumeração	\N	f	f	t	f	f	\N
853	d	Quarto nível de enumeração	\N	f	f	t	f	f	\N
853	e	Quinto nível de enumeração	\N	f	f	t	f	f	\N
853	f	Sexto nível de enumeração	\N	f	f	t	f	f	\N
853	g	Esquema de numeração altenativo, Primeiro nível de enumeração	\N	f	f	t	f	f	\N
853	h	Esquema de numeração altenativo, Segundo nível de enumeração	\N	f	f	t	f	f	\N
853	i	Primeiro nível de cronologia	\N	f	f	t	f	f	\N
853	j	Segundo nível de cronologia	\N	f	f	t	f	f	\N
853	k	Terceiro nível de cronologia	\N	f	f	t	f	f	\N
853	l	Quarto nível de cronologia	\N	f	f	t	f	f	\N
853	m	Esquema de numeração alternativo, cronologia	\N	f	f	t	f	f	\N
853	t	Cópia	\N	f	f	t	f	f	\N
853	3	Materiais especificados	\N	f	f	t	f	f	\N
853	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
854	#	Legenda e padrão - Material suplementar	\N	t	t	t	f	f	\N
854	a	Primeiro nível de enumeração	\N	f	f	t	f	f	\N
854	b	Segundo nível de enumeração	\N	f	f	t	f	f	\N
854	c	Terceiro nível de enumeração	\N	f	f	t	f	f	\N
854	d	Quarto nível de enumeração	\N	f	f	t	f	f	\N
854	e	Quinto nível de enumeração	\N	f	f	t	f	f	\N
854	f	Sexto nível de enumeração	\N	f	f	t	f	f	\N
854	g	Esquema de numeração alternativa, Primeiro nível de enumeração	\N	f	f	t	f	f	\N
854	h	Esquema de numeração alternativa, Segundo nível de enumeração	\N	f	f	t	f	f	\N
854	i	Primeiro nível de cronologia	\N	f	f	t	f	f	\N
854	j	Sgundo nível de cronologia	\N	f	f	t	f	f	\N
854	k	Terceiro nível de cronologia	\N	f	f	t	f	f	\N
854	l	Quarto nível de cronologia	\N	f	f	t	f	f	\N
854	m	Esquema de numeração alternativa, cronologia	\N	f	f	t	f	f	\N
854	o	Tipo de material suplementar	\N	f	f	t	f	f	\N
854	t	Reprodução	\N	f	f	t	f	f	\N
854	u	Unidade bibliográfica para o próximo nível	\N	t	f	t	f	f	\N
854	v	Continuidade da numeração	\N	t	f	t	f	f	\N
854	w	Freqüência	\N	f	f	t	f	f	\N
854	x	Mudança no calendário	\N	f	f	t	f	f	\N
854	y	Padrão de regularidade	\N	f	f	t	f	f	\N
854	3	Materiais especificados	\N	f	f	t	f	f	\N
854	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
855	#	Legenda e padrão - Índices	\N	t	t	t	f	f	\N
855	a	Primeiro nível de enumeração	\N	f	f	t	f	f	\N
855	b	Segundo nível de enumeração	\N	f	f	t	f	f	\N
855	c	Terceiro nível de enumeração	\N	f	f	t	f	f	\N
855	d	Quarto nível de enumeração	\N	f	f	t	f	f	\N
855	e	Quinto nível de enumeração	\N	f	f	t	f	f	\N
855	f	Sexto nível de enumeração	\N	f	f	t	f	f	\N
855	g	Esquema de numeração alternativa, Primeiro nível de enumeração	\N	f	f	t	f	f	\N
855	h	Esquema de numeração alternativa, Segundo nível de enumeração	\N	f	f	t	f	f	\N
855	i	Primeiro nível de cronologia	\N	f	f	t	f	f	\N
855	j	Segundo nível de cronologia	\N	f	f	t	f	f	\N
855	k	Terceiro nível de cronologia	\N	f	f	t	f	f	\N
855	l	Quarto nível de cronologia	\N	f	f	t	f	f	\N
855	m	Esquema de numeração alternativa, cronologia	\N	f	f	t	f	f	\N
855	o	Tipo de índice	\N	f	f	t	f	f	\N
855	t	Reprodução	\N	f	f	t	f	f	\N
855	u	Unidade bibliográfica para o próximo nível	\N	t	f	t	f	f	\N
855	v	Continuidade da numeração	\N	t	f	t	f	f	\N
855	w	Freqüência	\N	f	f	t	f	f	\N
855	x	Mudança no calendário	\N	f	f	t	f	f	\N
855	y	Padrão de regularidade	\N	f	f	t	f	f	\N
855	3	Materiais especificados	\N	f	f	t	f	f	\N
855	6	Ligação	\N	f	f	t	f	f	\N
855	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
856	#	Localização e acesso eletrônico	\N	t	t	t	f	f	\N
856	a	Nome do servidor	\N	t	f	t	f	f	\N
856	c	Informação de compressão	\N	t	f	t	f	f	\N
856	d	Caminho	\N	t	f	t	f	f	\N
856	f	Nome eletrônico	\N	t	f	t	f	f	\N
868	a	Holdings textual	\N	f	f	t	f	f	\N
856	g	Nome uniforme da fonte	\N	t	f	t	f	f	\N
856	h	Processador de pesquisa	\N	f	f	t	f	f	\N
856	j	Bits por segundo	\N	f	f	t	f	f	\N
856	k	Password (Senha)	\N	f	f	t	f	f	\N
856	L	Logon / login	\N	f	f	t	f	f	\N
856	m	Contato para acessar a ajuda	\N	t	f	t	f	f	\N
856	n	Nome do local do servidor no subcampo $a	\N	f	f	t	f	f	\N
856	p	Porta	\N	f	f	t	f	f	\N
856	q	Tipo de formato eletrônico	\N	f	f	t	f	f	\N
856	r	Ambiente	\N	f	f	t	f	f	\N
856	s	Tamanho do arquivo	\N	t	f	t	f	f	\N
856	t	Simulação de terminal	\N	t	f	t	f	f	\N
856	u	Localizador da fonte (endereço eletrônico)	\N	t	f	t	f	f	\N
856	v	Método de avaliação das horas de acesso	\N	t	f	t	f	f	\N
856	w	Número de controle do registro	\N	t	f	t	f	f	\N
856	x	Nota interna	\N	t	f	t	f	f	\N
856	z	Nota pública	\N	t	f	t	f	f	\N
856	2	Método de acesso	\N	f	f	t	f	f	\N
856	3	Materiais especificados	\N	f	f	t	f	f	\N
856	6	Ligação	\N	f	f	t	f	f	\N
856	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
863	#	Enumeração e cronologia - Unidade bibliográfica básica	\N	t	t	t	f	f	\N
863	a	Primeiro nível de enumeração	\N	f	f	t	f	f	\N
863	b	Segundo nível de enumeração	\N	f	f	t	f	f	\N
863	c	Terceiro nível de enumeração	\N	f	f	t	f	f	\N
863	d	Quarto nível de enumeração	\N	f	f	t	f	f	\N
863	e	Quinto nível de enumeração	\N	f	f	t	f	f	\N
863	f	Sexto nível de enumeração	\N	f	f	t	f	f	\N
863	g	Esquema alternativo de numeração, primeiro nível de enumeração	\N	f	f	t	f	f	\N
863	h	Esquema alternativo de numeração, segundo nível de enumeração	\N	f	f	t	f	f	\N
863	i	Primeiro nível de cronologia	\N	f	f	t	f	f	\N
863	j	Segundo nível de cronologia	\N	f	f	t	f	f	\N
863	k	Terceiro nível de cronologia	\N	f	f	t	f	f	\N
863	l	Quarto nível de cronologia	\N	f	f	t	f	f	\N
863	m	Esquema de numeração alternativa, cronologia	\N	f	f	t	f	f	\N
856	o	Sistema operacional	\N	f	f	t	f	f	\N
863	n	Ano Gregoriano convertido	\N	f	f	t	f	f	\N
863	p	Designação da parte	\N	f	f	t	f	f	\N
863	q	Condição física da parte	\N	f	f	t	f	f	\N
863	s	Código de taxa de copyright	\N	t	f	t	f	f	\N
863	t	Número do exemplar	\N	f	f	t	f	f	\N
863	w	Indicador de interrupção	\N	f	f	t	f	f	\N
863	x	Nota interna	\N	t	f	t	f	f	\N
863	z	Nota pública	\N	t	f	t	f	f	\N
863	3	Data do primeiro fascículo em seqüência	\N	t	f	t	f	f	\N
863	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
864	#	Enumeração e cronologia - Material suplementar	\N	t	t	t	f	f	\N
864	a	Primeiro nível de enumeração	\N	f	f	t	f	f	\N
864	b	Segundo nível de enumeração	\N	f	f	t	f	f	\N
864	c	Terceiro nível de enumeração	\N	f	f	t	f	f	\N
864	d	Quarto nível de enumeração	\N	f	f	t	f	f	\N
864	e	Quinto nível de enumeração	\N	f	f	t	f	f	\N
864	f	Sexto nível de enumeração	\N	f	f	t	f	f	\N
864	g	Esquema de numeração alternativa, primeiro nível de enumeração	\N	f	f	t	f	f	\N
864	h	Esquema de numeração alternativa, segundo nível de enumeração	\N	f	f	t	f	f	\N
864	i	Primeiro nível de cronologia	\N	f	f	t	f	f	\N
864	j	Segundo nível de cronologia	\N	f	f	t	f	f	\N
864	k	Terceiro nível de cronologia	\N	f	f	t	f	f	\N
864	l	Quarto nível de cronologia	\N	f	f	t	f	f	\N
864	m	Esquema de numeração alternativa, cronologia	\N	f	f	t	f	f	\N
864	n	Ano Gregoriano convertido	\N	f	f	t	f	f	\N
864	o	Título do material suplementar	\N	f	f	t	f	f	\N
864	p	Designação da parte	\N	f	f	t	f	f	\N
864	q	Condição física da parte	\N	f	f	t	f	f	\N
864	s	Código de taxa de copyright	\N	t	f	t	f	f	\N
864	t	Número de exemplar	\N	f	f	t	f	f	\N
864	w	Indicador de interrupção	\N	f	f	t	f	f	\N
864	x	Nota interna	\N	t	f	t	f	f	\N
864	z	Nota pública	\N	t	f	t	f	f	\N
864	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
865	#	Enumeração e cronologia - Índices	\N	t	t	t	f	f	\N
865	a	Primeiro nível de enumeração	\N	f	f	t	f	f	\N
865	b	Segundo nível de enumeração	\N	f	f	t	f	f	\N
865	c	Terceiro nível de enumeração	\N	f	f	t	f	f	\N
865	d	Quarto nível de enumeração	\N	f	f	t	f	f	\N
865	e	Quinto nível de enumeração	\N	f	f	t	f	f	\N
865	f	Sexto nível de enumeração	\N	f	f	t	f	f	\N
865	g	Esquema de numeração alternativa, primeiro nível de enumeração	\N	f	f	t	f	f	\N
865	h	Esquema de numeração alternativa, segundo nível de enumeração	\N	f	f	t	f	f	\N
865	i	Primeiro nível de cronologia	\N	f	f	t	f	f	\N
865	j	Segundo nível de cronologia	\N	f	f	t	f	f	\N
865	k	Terceiro nível de cronologia	\N	f	f	t	f	f	\N
865	l	Quarto nível de cronologia	\N	f	f	t	f	f	\N
865	m	Esquema de numeração alternativa, cronologia	\N	f	f	t	f	f	\N
865	n	Ano gregoriano convertido	\N	f	f	t	f	f	\N
865	o	Título do índice	\N	f	f	t	f	f	\N
865	p	Designação da parte	\N	f	f	t	f	f	\N
865	q	Condição física da parte	\N	f	f	t	f	f	\N
865	s	Código de taxa de copyright	\N	t	f	t	f	f	\N
865	t	Número do exemplar	\N	f	f	t	f	f	\N
865	w	indicador de interrupção	\N	f	f	t	f	f	\N
865	x	Nota interna	\N	t	f	t	f	f	\N
865	z	Nota pública	\N	t	f	t	f	f	\N
865	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
866	#	Holdings textual - Unidade bibliográfica básica	\N	t	t	t	f	f	\N
866	a	Seqüência textual	\N	f	f	t	f	f	\N
866	x	Nota interna	\N	t	f	t	f	f	\N
866	z	Nota pública	\N	t	f	t	f	f	\N
866	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
867	#	Holdings textual - Material suplementar	\N	t	t	t	f	f	\N
867	a	Holdings textual	\N	f	f	t	f	f	\N
867	x	Nota interna	\N	t	f	t	f	f	\N
867	z	Nota pública	\N	t	f	t	f	f	\N
867	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
868	#	Holdings textual - Índices	\N	t	t	t	f	f	\N
868	x	Nota interna	\N	t	f	t	f	f	\N
868	z	Nota pública	\N	t	f	t	f	f	\N
868	8	Ligação de campo e seqüência	\N	t	f	t	f	f	\N
876	#	Informação de item - Unidade bibliográfica básica	\N	f	t	t	f	f	\N
876	a	Número do item interno	\N	f	f	t	f	f	\N
876	b	Número inválido ou cancelado do item interno	\N	t	f	t	f	f	\N
876	c	Preço	\N	t	f	t	f	f	\N
876	d	Data de aquisição	\N	t	f	t	f	f	\N
876	e	Fonte de aquisição	\N	t	f	t	f	f	\N
876	h	Restrição de uso	\N	t	f	t	f	f	\N
876	j	Status do item	\N	t	f	t	f	f	\N
876	l	Localização temporária	\N	t	f	t	f	f	\N
876	p	Designação da parte	\N	t	f	t	f	f	\N
876	r	Designação da parte inválida ou cancelada	\N	t	f	t	f	f	\N
876	t	Número do exemplar	\N	t	f	t	f	f	\N
876	x	Nota interna	\N	t	f	t	f	f	\N
876	z	Nota pública	\N	t	f	t	f	f	\N
876	3	Especificação dos materiais	\N	f	f	t	f	f	\N
100	a	Autor	\N	f	f	t	f	f	\N
245	a	Título	\N	f	f	t	f	f	\N
440	a	Título	\N	f	f	t	f	f	\N
650	a	Assunto	\N	t	f	t	f	f	\N
700	a	Nome pessoal	\N	t	f	t	f	f	\N
001	a	Número de Controle	\N	f	f	t	f	f	\N
886	#	Campo de informação para MARC estrangeiro	\N	t	t	t	f	f	\N
886	a	Etiqueta do campo MARC estrangeiro	\N	f	f	t	f	f	\N
886	b	Conteúdo do campo MARC estrangeiro	\N	f	f	t	f	f	\N
886	2	Fonte do dado	\N	f	f	t	f	f	\N
090	a	Numero de Classificacao	\N	f	f	t	f	f	\N
001	#	Número de Controle	\N	f	t	t	f	f	\N
901	#	Tipo de Material	\N	f	t	t	f	f	\N
902	#	Gênero do Material	\N	f	t	t	f	f	\N
902	a	Gênero	\N	f	f	t	f	f	\N
653	a	Termo livre	\N	t	f	t	f	f	\N
901	a	Tipo de Material	\N	f	f	t	f	f	\N
901	b	Áreas do conhecimento	\N	f	\N	t	f	f	\N
901	c	Tipo Físico do Material	\N	f	f	t	f	f	\N
080	b	Número do item	\N	f	f	t	f	f	\N
260	c	Data de Publicação, Distribuição, etc.	\N	t	f	t	f	f	\N
903	#	Base de Dados	\N	f	t	t	f	\N	\N
903	a	Base de Dados	\N	f	f	t	f	\N	\N
904	#	Local	\N	f	t	t	f	\N	\N
904	a	Local	\N	f	f	t	f	\N	\N
505	a	Nota de conteúdo	\N	t	f	t	f	f	\N
008	a	Campo Fixo de Dados	\N	f	t	t	f	f	\N
080	a	Número de Classificação Decimal Universal	\N	t	f	t	f	f	\N
090	b	Cutter	\N	f	f	t	f	f	\N
090	#	Números de Chamada Local	\N	f	f	t	f	f	\N
260	b	Nome do Editor, Distribuidor, etc.	\N	t	f	t	f	f	\N
950	#	Número da Obra	\N	f	t	t	f	\N	\N
950	a	Número da Obra	\N	f	f	t	f	\N	\N
949	#	Dados do Exemplar	\N	t	t	t	f	f	\N
949	1	Tipo do Material	\N	t	\N	t	f	\N	\N
949	3	Tipo Físico do Material	\N	t	\N	t	f	\N	\N
949	9	Unidade Original	\N	t	\N	t	f	f	\N
949	a	Numero do tombo	\N	t	\N	t	f	f	\N
949	b	Código da Unidade	\N	t	\N	t	f	f	\N
949	c	Tipo de Aquisição	\N	t	\N	t	f	\N	\N
949	d	Gênero do Material	\N	t	\N	t	f	\N	\N
949	e	Exemplar	\N	t	\N	t	f	\N	\N
949	g	Código Do Estado	\N	t	\N	t	f	f	\N
949	h	Data da nota fiscal	\N	t	\N	t	f	f	\N
949	i	Código Do Estado Futuro	\N	t	\N	t	f	f	\N
949	f	Nota fiscal	\N	t	\N	t	f	f	\N
949	n	Patrimônio	\N	t	\N	t	f	f	\N
949	q	Centro de custo	\N	t	\N	t	f	f	\N
949	t	Tomo	\N	t	\N	t	f	\N	\N
949	v	Volume	\N	t	\N	t	f	f	\N
949	w	Observação	\N	t	\N	t	f	f	\N
949	y	Data de Entrada	\N	t	\N	t	f	\N	\N
949	z	Data da Baixa	\N	t	\N	t	f	\N	\N
948	#	Coleção	\N	f	t	t	f	f	\N
948	a	Código da Unidade	\N	f	\N	t	f	f	\N
960	#	Dados da assinatura	\N	t	t	t	f	f	\N
960	a	Código de assinante	\N	t	\N	t	f	f	\N
960	b	Código da Unidade	\N	t	\N	t	f	f	\N
960	c	Tipo de Aquisição	\N	t	\N	t	f	f	\N
960	d	Vencimento da assinatura	\N	t	\N	t	f	f	\N
960	e	Preço da assinatura	\N	t	\N	t	f	f	\N
960	f	Nota fiscal	\N	t	\N	t	f	f	\N
960	g	Informações	\N	t	\N	t	f	f	\N
960	h	Data da assinatura	\N	t	\N	t	f	f	\N
960	i	Data de renovação	\N	t	\N	t	f	f	\N
960	j	Publicação	\N	t	\N	t	f	f	\N
960	q	Centro de custo	\N	t	\N	t	f	f	\N
960	w	Observações	\N	t	\N	t	f	f	\N
947	#	Editor/Fornecedor	\N	f	t	t	f	f	\N
947	a	Código do editor/fornecedor	\N	f	\N	t	f	f	\N
260	#	Imprenta	\N	t	t	t	f	f	\N
\.


--
-- Data for Name: gtctask; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtctask (taskid, description, parameters, enable, scriptname) FROM stdin;
21	Comunica aquisições de materiais	$date|$librariUnits	t	default/comunicarAquisicoes.task.php
23	Informar solicitante sobre termino requisição	$diasAntecedencia|$libraries	t	default/informarSolicitanteSobreTerminoRequisicao.task.php
28	Remover arquivos temporarios do gnuteca		t	default/removeTempFiles.task.php
24	Informar usuários sobre renovação de material 	$libraries	t	default/informaUsuariosRenovarEmprestimo.task.php
22	Comunica materiais em atraso	$libraries	t	default/comunicarAtrazados.task.php
29	Importa informações do Sagu	$person|$link|$personLink	t	default/importSaguInformations.task.php
30	Finalização de solicitação de compras		t	default/finalizePurchaseRequest.task.php
31	Importar capas do google	$base	t	default/importCoverFromGoogle.task.php
32	Sincronizar servidor Z3950		t	default/sincronyzeZ3950.task.php
33	Gerar sitemap.xml		t	default/generateSiteMapXml.task.php
34	Sugerir material	\N	t	default/suggestMaterial.task.php
\.


--
-- Data for Name: gtcwebservice; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcwebservice (webserviceid, servicedescription, class, method, enable, needauthentication, checkclientip) FROM stdin;
1	Basic Test	gnuteca3WebServicesTesting	basicTest	t	f	f
2	Basic Test	gnuteca3WebServicesTesting	getSimpleArray	t	f	f
3	Basic Test	gnuteca3WebServicesTesting	testAutenticate	t	t	f
4	Basic Test	gnuteca3WebServicesTesting	testdIP	t	f	t
5	Basic Test	gnuteca3WebServicesTesting	getWebServiceObject	t	t	t
21	Multas - Retorna as multas em aberto	gnuteca3WebServicesFines	getFinesOpen	t	t	t
22	Multas - Seta as Multas como pagas	gnuteca3WebServicesFines	setFinePay	t	t	t
23	Multas - Seta todas multas como pagas e retorna um relatório	gnuteca3WebServicesFines	payAllFinesOpen	t	t	t
24	Multas - Retorna multas com pagamento via boleto.	gnuteca3WebServicesFines	getFinePayRoll	t	t	t
41	Vínculos - Retorna os vínculos de determinados usuários	gnuteca3WebServicesLink	getPersonLink	t	t	t
42	Vínculos - Deleta todos os vínculos de uma ou mais pessoas.	gnuteca3WebServicesLink	deletePersonLink	t	t	t
43	Vínculos - Insere um novo vínculo.	gnuteca3WebServicesLink	insertPersonLink	t	t	t
44	Vínculos - Deleta vínculos.	gnuteca3WebServicesLink	deleteLink	t	t	t
61	Empréstimos - Retorna todos os empréstimos em aberto de uma ou mais pessoas.	gnuteca3WebServicesLoans	getLoanOpen	t	t	t
80	.	gnuteca3WebServicesMaterial	getMaterialInformation	t	t	t
99	Unificar registros - Unifica registros de um usuário.	gnuteca3WebServicesUnifyRegister	unifyPerson	t	t	t
\.


--
-- Data for Name: gtcweekday; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcweekday (weekdayid, description) FROM stdin;
1	Segunda-feira
2	Terça-feira
3	Quarta-feira
4	Quinta-feira
5	Sexta-feira
6	Sábado
7	Domingo
\.


--
-- Data for Name: gtcworkflowhistory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcworkflowhistory (workflowhistoryid, workflowinstanceid, workflowstatusid, date, operator, comment) FROM stdin;
\.


--
-- Data for Name: gtcworkflowinstance; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcworkflowinstance (workflowinstanceid, workflowstatusid, date, tablename, tableid) FROM stdin;
\.


--
-- Data for Name: gtcworkflowstatus; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcworkflowstatus (workflowstatusid, workflowid, name, initial, transaction) FROM stdin;
100001	PURCHASE_REQUEST	Solicitada	t	2019
100002	PURCHASE_REQUEST	Cancelada	f	\N
100003	PURCHASE_REQUEST	Aguardando cotação	f	\N
100004	PURCHASE_REQUEST	Fora de catálogo	f	\N
100005	PURCHASE_REQUEST	Esgotado	f	\N
100006	PURCHASE_REQUEST	Não encontrado	f	\N
100007	PURCHASE_REQUEST	Aguardando aprovação	f	\N
100012	PURCHASE_REQUEST	Reprovada	f	\N
100009	PURCHASE_REQUEST	Aprovada	f	gtcCostCenter
100010	PURCHASE_REQUEST	Aguardando entrega	f	\N
100011	PURCHASE_REQUEST	Entregue	f	\N
100008	PURCHASE_REQUEST	Finalizada	f	\N
\.


--
-- Data for Name: gtcworkflowtransition; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcworkflowtransition (previousworkflowstatusid, nextworkflowstatusid, name, function) FROM stdin;
100001	100001	Solicitar	wfPurchaseRequestDefault::initialize
100001	100003	Cotar	\N
100001	100002	Cancelar	wfPurchaseRequestDefault::cancel
100003	100004	Fora de catálogo	wfPurchaseRequestDefault::cancel
100003	100005	Esgotado	wfPurchaseRequestDefault::cancel
100003	100006	Não encontrado	wfPurchaseRequestDefault::cancel
100003	100007	Solicitar aprovação	\N
100007	100012	Reprovar	wfPurchaseRequestDefault::cancel
100007	100009	Aprovar	wfPurchaseRequestDefault::aprove
100009	100002	Cancelar	wfPurchaseRequestDefault::cancel
100009	100010	Comprar	\N
100010	100002	Cancelar	wfPurchaseRequestDefault::cancel
100010	100011	Entregar	\N
100011	100002	Cancelar	wfPurchaseRequestDefault::cancel
100011	100008	Finalizar	wfPurchaseRequestDefault::finalize
\.


--
-- Data for Name: gtcz3950servers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gtcz3950servers (serverid, description, host, recordtype, sintax, username, password, country) FROM stdin;
\.


--
-- Data for Name: miolo_access; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY miolo_access (idtransaction, idgroup, rights, validatefunction) FROM stdin;
1	2	1	\N
2	2	1	\N
3	2	1	\N
4	2	1	\N
5	2	1	\N
6	2	1	\N
1	3	15	\N
2	3	15	\N
3	3	15	\N
4	3	15	\N
5	3	15	\N
6	3	15	\N
1013	1000	1	\N
1013	1000	2	\N
1013	1000	4	\N
1013	1000	8	\N
1050	1000	1	\N
1050	1000	2	\N
1050	1000	4	\N
1050	1000	8	\N
1051	1000	1	\N
1051	1000	2	\N
1051	1000	4	\N
1051	1000	8	\N
1052	1000	1	\N
1052	1000	2	\N
1052	1000	4	\N
1052	1000	8	\N
1053	1000	1	\N
1053	1000	2	\N
1053	1000	4	\N
1053	1000	8	\N
1054	1000	1	\N
1054	1000	2	\N
1054	1000	4	\N
1054	1000	8	\N
1055	1000	1	\N
1055	1000	2	\N
1055	1000	4	\N
1055	1000	8	\N
1056	1000	1	\N
1056	1000	2	\N
1056	1000	4	\N
1056	1000	8	\N
1057	1000	1	\N
1057	1000	2	\N
1057	1000	4	\N
1057	1000	8	\N
1058	1000	1	\N
1058	1000	2	\N
1058	1000	4	\N
1058	1000	8	\N
1059	1000	1	\N
1059	1000	2	\N
1059	1000	4	\N
1059	1000	8	\N
1060	1000	1	\N
1060	1000	2	\N
1060	1000	4	\N
1060	1000	8	\N
1061	1000	1	\N
1061	1000	2	\N
1061	1000	4	\N
1061	1000	8	\N
1062	1000	1	\N
1062	1000	2	\N
1062	1000	4	\N
1062	1000	8	\N
1063	1000	1	\N
1063	1000	2	\N
1063	1000	4	\N
1063	1000	8	\N
1064	1000	1	\N
1064	1000	2	\N
1064	1000	4	\N
1064	1000	8	\N
1065	1000	1	\N
1065	1000	2	\N
1065	1000	4	\N
1065	1000	8	\N
1066	1000	1	\N
1066	1000	2	\N
1066	1000	4	\N
1066	1000	8	\N
1067	1000	1	\N
1067	1000	2	\N
1067	1000	4	\N
1067	1000	8	\N
1068	1000	1	\N
1068	1000	2	\N
1068	1000	4	\N
1068	1000	8	\N
1069	1000	1	\N
1069	1000	2	\N
1069	1000	4	\N
1069	1000	8	\N
1070	1000	1	\N
1070	1000	2	\N
1070	1000	4	\N
1070	1000	8	\N
1071	1000	1	\N
1071	1000	2	\N
1071	1000	4	\N
1071	1000	8	\N
1072	1000	1	\N
1072	1000	2	\N
1072	1000	4	\N
1072	1000	8	\N
1073	1000	1	\N
1073	1000	2	\N
1073	1000	4	\N
1073	1000	8	\N
1074	1000	1	\N
1074	1000	2	\N
1074	1000	4	\N
1074	1000	8	\N
1075	1000	1	\N
1075	1000	2	\N
1075	1000	4	\N
1075	1000	8	\N
1076	1000	1	\N
1076	1000	2	\N
1076	1000	4	\N
1076	1000	8	\N
2000	1000	1	\N
2000	1000	2	\N
2000	1000	4	\N
2000	1000	8	\N
2001	1000	1	\N
2001	1000	2	\N
2001	1000	4	\N
2001	1000	8	\N
2002	1000	1	\N
2002	1000	2	\N
2002	1000	4	\N
2002	1000	8	\N
2003	1000	1	\N
2003	1000	2	\N
2003	1000	4	\N
2003	1000	8	\N
2004	1000	1	\N
2004	1000	2	\N
2004	1000	4	\N
2004	1000	8	\N
2005	1000	1	\N
2005	1000	2	\N
2005	1000	4	\N
2005	1000	8	\N
2006	1000	1	\N
2006	1000	2	\N
2006	1000	4	\N
2006	1000	8	\N
2007	1000	1	\N
2007	1000	2	\N
2007	1000	4	\N
2007	1000	8	\N
2008	1000	1	\N
2008	1000	2	\N
2008	1000	4	\N
2008	1000	8	\N
2009	1000	1	\N
2009	1000	2	\N
2009	1000	4	\N
2009	1000	8	\N
2010	1000	1	\N
2010	1000	2	\N
2010	1000	4	\N
2010	1000	8	\N
2011	1000	1	\N
2011	1000	2	\N
2011	1000	4	\N
2011	1000	8	\N
2012	1000	1	\N
2012	1000	2	\N
2012	1000	4	\N
2012	1000	8	\N
2013	1000	1	\N
2013	1000	2	\N
2013	1000	4	\N
2013	1000	8	\N
2014	1000	1	\N
2014	1000	2	\N
2014	1000	4	\N
2014	1000	8	\N
2015	1000	1	\N
2015	1000	2	\N
2015	1000	4	\N
2015	1000	8	\N
2016	1000	1	\N
2016	1000	2	\N
2016	1000	4	\N
2016	1000	8	\N
2017	1000	1	\N
2017	1000	2	\N
2017	1000	4	\N
2017	1000	8	\N
2018	1000	1	\N
2018	1000	2	\N
2018	1000	4	\N
2018	1000	8	\N
2019	1000	1	\N
2019	1000	2	\N
2019	1000	4	\N
2019	1000	8	\N
2020	1000	1	\N
2020	1000	2	\N
2020	1000	4	\N
2020	1000	8	\N
2021	1000	1	\N
2021	1000	2	\N
2021	1000	4	\N
2021	1000	8	\N
2023	1000	1	\N
2023	1000	2	\N
2023	1000	4	\N
2023	1000	8	\N
2024	1000	1	\N
2024	1000	2	\N
2024	1000	4	\N
2024	1000	8	\N
2025	1000	1	\N
2025	1000	2	\N
2025	1000	4	\N
2025	1000	8	\N
2026	1000	1	\N
2026	1000	2	\N
2026	1000	4	\N
2026	1000	8	\N
2050	1000	1	\N
2050	1000	2	\N
2050	1000	4	\N
2050	1000	8	\N
2052	1000	1	\N
2052	1000	2	\N
2052	1000	4	\N
2052	1000	8	\N
2053	1000	1	\N
2053	1000	2	\N
2053	1000	4	\N
2053	1000	8	\N
2054	1000	1	\N
2054	1000	2	\N
2054	1000	4	\N
2054	1000	8	\N
2055	1000	1	\N
2055	1000	2	\N
2055	1000	4	\N
2055	1000	8	\N
2056	1000	1	\N
2056	1000	2	\N
2056	1000	4	\N
2056	1000	8	\N
2057	1000	1	\N
2057	1000	2	\N
2057	1000	4	\N
2057	1000	8	\N
2058	1000	1	\N
2058	1000	2	\N
2058	1000	4	\N
2058	1000	8	\N
2059	1000	1	\N
2059	1000	2	\N
2059	1000	4	\N
2059	1000	8	\N
3000	1000	1	\N
3000	1000	2	\N
3000	1000	4	\N
3000	1000	8	\N
3001	1000	1	\N
3001	1000	2	\N
3001	1000	4	\N
3001	1000	8	\N
3002	1000	1	\N
3002	1000	2	\N
3002	1000	4	\N
3002	1000	8	\N
3003	1000	1	\N
3003	1000	2	\N
3003	1000	4	\N
3003	1000	8	\N
3004	1000	1	\N
3004	1000	2	\N
3004	1000	4	\N
3004	1000	8	\N
3005	1000	1	\N
3005	1000	2	\N
3005	1000	4	\N
3005	1000	8	\N
3006	1000	1	\N
3006	1000	2	\N
3006	1000	4	\N
3006	1000	8	\N
3007	1000	1	\N
3007	1000	2	\N
3007	1000	4	\N
3007	1000	8	\N
3008	1000	1	\N
3008	1000	2	\N
3008	1000	4	\N
3008	1000	8	\N
3009	1000	1	\N
3009	1000	2	\N
3009	1000	4	\N
3009	1000	8	\N
3010	1000	1	\N
3010	1000	2	\N
3010	1000	4	\N
3010	1000	8	\N
3011	1000	1	\N
3011	1000	2	\N
3011	1000	4	\N
3011	1000	8	\N
3012	1000	1	\N
3012	1000	2	\N
3012	1000	4	\N
3012	1000	8	\N
3013	1000	1	\N
3013	1000	2	\N
3013	1000	4	\N
3013	1000	8	\N
3014	1000	1	\N
3014	1000	2	\N
3014	1000	4	\N
3014	1000	8	\N
3015	1000	1	\N
3015	1000	2	\N
3015	1000	4	\N
3015	1000	8	\N
3016	1000	1	\N
3016	1000	2	\N
3016	1000	4	\N
3016	1000	8	\N
3018	1000	1	\N
3018	1000	2	\N
3018	1000	4	\N
3018	1000	8	\N
3019	1000	1	\N
3019	1000	2	\N
3019	1000	4	\N
3019	1000	8	\N
3021	1000	1	\N
3021	1000	2	\N
3021	1000	4	\N
3021	1000	8	\N
3022	1000	1	\N
3022	1000	2	\N
3022	1000	4	\N
3022	1000	8	\N
3023	1000	1	\N
3023	1000	2	\N
3023	1000	4	\N
3023	1000	8	\N
3024	1000	1	\N
3024	1000	2	\N
3024	1000	4	\N
3024	1000	8	\N
3025	1000	1	\N
3025	1000	2	\N
3025	1000	4	\N
3025	1000	8	\N
3026	1000	1	\N
3026	1000	2	\N
3026	1000	4	\N
3026	1000	8	\N
3500	1000	1	\N
3500	1000	2	\N
3500	1000	4	\N
3500	1000	8	\N
3501	1000	1	\N
3501	1000	2	\N
3501	1000	4	\N
3501	1000	8	\N
3502	1000	1	\N
3502	1000	2	\N
3502	1000	4	\N
3502	1000	8	\N
2061	1000	1	\N
2061	1000	2	\N
2061	1000	4	\N
2061	1000	8	\N
2062	1000	1	\N
2062	1000	2	\N
2062	1000	4	\N
2062	1000	8	\N
2063	1000	1	\N
2063	1000	2	\N
2063	1000	4	\N
2063	1000	8	\N
2064	1000	1	\N
2064	1000	2	\N
2064	1000	4	\N
2064	1000	8	\N
3027	1000	1	\N
3027	1000	2	\N
3027	1000	4	\N
3027	1000	8	\N
2065	1000	1	\N
2065	1000	2	\N
2065	1000	4	\N
2065	1000	8	\N
3504	1000	1	\N
3504	1000	2	\N
3504	1000	4	\N
3504	1000	8	\N
2066	1000	1	\N
2066	1000	2	\N
2066	1000	4	\N
2066	1000	8	\N
1077	1000	1	\N
1077	1000	2	\N
1077	1000	4	\N
1077	1000	8	\N
2070	1000	1	\N
2070	1000	2	\N
2070	1000	4	\N
2070	1000	8	\N
1090	1000	1	\N
1090	1000	2	\N
1090	1000	4	\N
1090	1000	8	\N
1078	1000	1	\N
1078	1000	2	\N
1078	1000	4	\N
1078	1000	8	\N
1079	1000	1	\N
1079	1000	2	\N
1079	1000	4	\N
1079	1000	8	\N
1080	1000	1	\N
1080	1000	2	\N
1080	1000	4	\N
1080	1000	8	\N
1081	1000	1	\N
1081	1000	2	\N
1081	1000	4	\N
1081	1000	8	\N
3505	1000	1	\N
3505	1000	2	\N
3505	1000	4	\N
3505	1000	8	\N
3506	1000	1	\N
3506	1000	2	\N
3506	1000	4	\N
3506	1000	8	\N
3507	1000	1	\N
3507	1000	2	\N
3507	1000	4	\N
3507	1000	8	\N
3508	1000	1	\N
3508	1000	2	\N
3508	1000	4	\N
3508	1000	8	\N
3509	1000	1	\N
3509	1000	2	\N
3509	1000	4	\N
3509	1000	8	\N
3509	1000	1	\N
3509	1000	2	\N
3509	1000	4	\N
3509	1000	8	\N
3512	1000	1	\N
3512	1000	2	\N
3512	1000	4	\N
3512	1000	8	\N
3511	1000	1	\N
3511	1000	2	\N
3511	1000	4	\N
3511	1000	8	\N
2071	1000	1	\N
2071	1000	2	\N
2071	1000	4	\N
2071	1000	8	\N
3513	1000	1	\N
3513	1000	2	\N
3513	1000	4	\N
3513	1000	8	\N
3514	1000	1	\N
3514	1000	2	\N
3514	1000	4	\N
3514	1000	8	\N
\.


--
-- Data for Name: miolo_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY miolo_group (idgroup, m_group, idmodule) FROM stdin;
1	ADMIN	\N
2	MAIN_RO	\N
3	MAIN_RW	\N
1000	GTC_ROOT	gnuteca3
\.


--
-- Data for Name: miolo_groupuser; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY miolo_groupuser (iduser, idgroup) FROM stdin;
1	1
1	2
1	3
2	2
1000	1000
1000	1
1000	2
1000	3
\.


--
-- Data for Name: miolo_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY miolo_log (idlog, m_timestamp, description, module, class, iduser, idtransaction, remoteaddr) FROM stdin;
\.


--
-- Data for Name: miolo_module; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY miolo_module (idmodule, name, description) FROM stdin;
admin	admin	\N
common	common	\N
helloworld	helloworld	\N
hangman	hangman	\N
tutorial	tutorial	\N
exemplo	exemplo	\N
gnuteca3	Gnuteca3	Sistema de gestão de acervo, empréstimo e colaboração para bibliotecas
\.


--
-- Data for Name: miolo_schedule; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY miolo_schedule (idschedule, idmodule, action, parameters, begintime, completed, running) FROM stdin;
\.


--
-- Data for Name: miolo_sequence; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY miolo_sequence (sequence, value) FROM stdin;
seq_miolo_session	0
seq_miolo_log	0
seq_miolo_user	2
seq_miolo_transaction	5
seq_miolo_group	3
\.


--
-- Data for Name: miolo_session; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY miolo_session (idsession, iduser, tsin, tsout, name, sid, forced, remoteaddr) FROM stdin;
\.


--
-- Data for Name: miolo_transaction; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY miolo_transaction (idtransaction, m_transaction, idmodule, nametransaction) FROM stdin;
1013	gtcMaterialMovement	gnuteca3	Circulação de materiais
1050	gtcLibraryUnit	gnuteca3	Unidade de biblioteca
1052	gtcHoliday	gnuteca3	Feriado
1051	gtcLibraryGroup	gnuteca3	Grupo de biblioteca
1053	gtcPreference	gnuteca3	Preferências
1054	gtcMaterialGender	gnuteca3	Gênero do material
1055	gtcClassificationArea	gnuteca3	Áreas de classificação
1056	gtcUserGroup	gnuteca3	Grupo de usuários
1057	gtcPrivilegeGroup	gnuteca3	Grupo de privilégio
1058	gtcRight	gnuteca3	Direito
1059	gtcPolicy	gnuteca3	Política
1060	gtcGeneralPolicy	gnuteca3	Políticas gerais
1061	gtcAssociation	gnuteca3	Associação entre bibliotecas
1063	gtcLabelLayout	gnuteca3	Formato de etiqueta
1064	gtcFormatBackOfBook	gnuteca3	Formato de lombada
1065	gtcSearchFormat	gnuteca3	Formato da pesquisa
1066	gtcSearchableField	gnuteca3	Campos pesquisáveis
1067	gtcOperatorLibraryUnit	gnuteca3	Operador da unidade da biblioteca
1068	gtcExemplaryStatus	gnuteca3	Estado do exemplar
1069	gtcOperation	gnuteca3	Operação de movimentação
1070	gtcFineStatus	gnuteca3	Estado da multa
1071	gtcLocationForMaterialMovement	gnuteca3	Local de circulação de material
1072	gtcRulesForMaterialMovement	gnuteca3	Regras para circulação de material
1073	gtcConfigReport	gnuteca3	Configuração de relatórios
1074	gtcMaterialType	gnuteca3	Tipo de material
1075	gtcMaterialPhysicalType	gnuteca3	Tipo físico do material
1076	gtcScheduleTask	gnuteca3	Agendar tarefa
2000	gtcLoan	gnuteca3	Empréstimo
2001	gtcReserve	gnuteca3	Reserva
2002	gtcRenew	gnuteca3	Renovação
2003	gtcFine	gnuteca3	Multa
2004	gtcExemplaryFutureStatusDefined	gnuteca3	Definir estado futuro do exemplar
2005	gtcSupplier	gnuteca3	Fornecedor
2006	gtcLoanBetweenLibrary	gnuteca3	Empréstimo entre bibliotecas
2007	gtcPerson	gnuteca3	Pessoa
2008	gtcBond	gnuteca3	Vínculo
2009	gtcPenalty	gnuteca3	Penalidade
2010	gtcBackOfBook	gnuteca3	Lombada
2011	gtcBarCode	gnuteca3	Código de barras
2012	gtcAdminReport	gnuteca3	Administração de relatórios
2013	gtcExemplaryStatusHistory	gnuteca3	Histórico de estados do exemplar
2014	gtcSendMailReturn	gnuteca3	Envio de e-mail de devolução
2016	gtcSendMailNotifyAcquisition	gnuteca3	Aviso de aquisições
2017	gtcSendMailAnsweredReserves	gnuteca3	Aviso de reservas atendidas
2018	gtcSendMailReserveQueue	gnuteca3	Aviso sobre fim de requisição
2019	gtcAdminReportBasic	gnuteca3	Administração básica de relatórios
2020	gtcAdminReportIntermediary	gnuteca3	Administração intermediária de relatórios
2021	gtcAdminReportAdvanced	gnuteca3	Administração avançada de relatórios
2023	gtcInterchange	gnuteca3	Intercâmbio de materiais
2024	gtcFormContent	gnuteca3	Conteúdo do formulário
2025	gtcRequestChangeExemplaryStatus	gnuteca3	Requisição de alteração de estado do exemplar
2026	gtcRequestChangeExemplaryStatusAccess	gnuteca3	Permissão para requisição de alteração de estado do exemplar
2050	gtcMaterial	gnuteca3	Catalogação de materiais
2052	gtcKardexControl	gnuteca3	Controle de kardex
2053	gtcPreCatalogue	gnuteca3	Pré-catalogação
2054	gtcTag	gnuteca3	Etiquetas
2055	gtcSpreadsheet	gnuteca3	Planilha
2056	gtcRulesToCompleteFieldsMarc	gnuteca3	Regras para completar campos MARC
2057	gtcLinkOfFieldsBetweenSpreadsheets	gnuteca3	Relação de campos entre planilhas
2058	gtcDictionary	gnuteca3	Dicionário
2059	gtcDictionaryContent	gnuteca3	Conteúdo do dicionário
3000	gtcMaterialMovementLoan	gnuteca3	Empréstimo na circulação de materiais
3001	gtcMaterialMovementReturn	gnuteca3	Devolução na circulação de materiais
3002	gtcMaterialMovementRequestReserve	gnuteca3	Requisitar reserva
3003	gtcMaterialMovementAnswerReserve	gnuteca3	Atender de reserva
3004	gtcMaterialMovementVerifyMaterial	gnuteca3	Verifica material
3005	gtcMaterialMovementVerifyUser	gnuteca3	Verificar usuário
3006	gtcMaterialMovementUserHistory	gnuteca3	Histórico do usuário
3007	gtcMaterialMovementChangeStatus	gnuteca3	Alterar estado do material
3008	gtcMaterialMovementExemplaryFutureStatusDefined	gnuteca3	Define estado futuro do material
3009	gtcMaterialMovementVerifyProof	gnuteca3	Verificar recibos
3010	gtcMaterialMovementChangePassword	gnuteca3	Alterar Senha
3011	gtcNews	gnuteca3	Notícias
3012	gtcPrefixSuffix	gnuteca3	Prefixo/sufixo
3013	gtcMaterialMovementSkipPassword	gnuteca3	Permitir empréstimo sem senha
3014	gtcMaterialMovementCancelOperationProcess	gnuteca3	Cancelar processo de operação
3015	gtcMaterialMovementCancelReserve	gnuteca3	Cancelar reserva
3016	gtcMaterialMovementChangeFine	gnuteca3	Alterar empréstimo
3018	gtcReturnType	gnuteca3	Tipo de devolução
3019	gtcReturnRegister	gnuteca3	Registro de tipo de retorno
3021	gtcMaterialMovementChangeStatusLow	gnuteca3	Baixa de materiais
3022	gtcMaterialMovementChangeStatusInitial	gnuteca3	Alterar estado inicial
3023	gtcMaterialMovementLoanMomentary	gnuteca3	Empréstimo momentâneo
3024	gtcMaterialMovementLoanForced	gnuteca3	Forçar empréstimo
3025	gtcMaterialMovementCheckPoint	gnuteca3	Check point
3026	gtcSeparator	gnuteca3	Separador
3500	gtcSearchAdministrator	gnuteca3	Pesquisa do administrador
3501	gtcZ3950	gnuteca3	Z3950
3502	gtcISO2709Import	gnuteca3	Importar ISO 2709
2061	gtcSendMailNotifyEndRequest	gnuteca3	Envio de e-mail notificando final da reserva
2062	gtcLibraryPreference	gnuteca3	Preferências da biblioteca
2063	gtcDomain	gnuteca3	Domínio
2064	gtcFile	gnuteca3	Arquivo
3027	gtcMaterialMovementCommunicateReserves	gnuteca3	Comunicar reservas
2065	gtcVerifyLinks	gnuteca3	Verificar links
3504	gtcUpdateSearch	gnuteca3	Atualizar pesquisa
2066	gtcDeleteValuesOfSpreadSheet	gnuteca3	Apagar valores de planilhas
1077	gtcz3950servers	gnuteca3	Servidores Z3950
1078	gtcBackgroundTaskLog	gnuteca3	Log de tarefas em segundo plano
3505	gtcAnalytics	gnuteca3	Analytics
3508	gtcConfigWorkflow	gnuteca3	Configurar Workflow
3507	gtcCostCenter	gnuteca3	Centro de custo
1062	gtcMarcTagListing	gnuteca3	Listagem de campos marc
3506	gtcMaterialHistory	gnuteca3	Histórico de material
1080	gtcOperatorGroup	gnuteca3	Grupo de operador
3509	gtcPurchaseRequest	gnuteca3	Requisição de compra
2015	gtcSendMailDelayedLoan	gnuteca3	Enviar e-mail de empréstimo atrasado
1081	gtcTagHelp	gnuteca3	Ajuda
1	ADMIN	\N	ADMIN
2	USER	\N	USER
3	GROUP	\N	GROUP
4	LOG	\N	LOG
5	TRANSACTION	\N	TRANSACTION
6	SESSION	\N	SESSION
2070	gtcMaterialEvaluation	gnuteca3	gtcMaterialEvaluation
1090	gtcBackup	gnuteca3	gtcBackup
3510	gtcDependencyCheck	gnuteca3	Conferir dependências
1079	gtcMarc21Import	gnuteca3	Importar Marc 21
3512	gtcISO2709Export	gnuteca3	Exportar ISO 2709
3511	gtcPersonSendMultipleEmail	gnuteca3	Envio de e-mails em lote para pessoas
2071	gtcInventoryCheck	gnuteca3	Verificação de inventário
3513	gtcHelp	gnuteca3	Ajuda
3514	gtcMyLibrary	gnuteca3	Minha biblioteca
\.


--
-- Data for Name: miolo_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY miolo_user (iduser, login, name, nickname, m_password, confirm_hash, theme, idmodule) FROM stdin;
1	admin	Miolo Administrator	admin	21232f297a57a5a743894a0e4a801fc3		miolo	\N
2	guest	Guest User	guest	084e0343a0486ff05530df6c705c8bb4		miolo	\N
1000	gnuteca	Gnuteca	gnuteca	7bf54004bd09cd27f98109368cc66a07		miolo	gnuteca3
\.


--
-- Name: basconfig_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY basconfig
    ADD CONSTRAINT basconfig_pkey PRIMARY KEY (moduleconfig, parameter);


--
-- Name: basdocument_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY basdocument
    ADD CONSTRAINT basdocument_pkey PRIMARY KEY (personid, documenttypeid);


--
-- Name: baslink_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY baslink
    ADD CONSTRAINT baslink_pkey PRIMARY KEY (linkid);


--
-- Name: basperson_login_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY basperson
    ADD CONSTRAINT basperson_login_key UNIQUE (login);


--
-- Name: basperson_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY basperson
    ADD CONSTRAINT basperson_pkey PRIMARY KEY (personid);


--
-- Name: baspersonlink_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY baspersonlink
    ADD CONSTRAINT baspersonlink_pkey PRIMARY KEY (personid, linkid);


--
-- Name: basphone_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY basphone
    ADD CONSTRAINT basphone_pkey PRIMARY KEY (personid, type);


--
-- Name: form_subform_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtchelp
    ADD CONSTRAINT form_subform_key UNIQUE (form, subform);


--
-- Name: gtcanalytics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcanalytics
    ADD CONSTRAINT gtcanalytics_pkey PRIMARY KEY (analyticsid);


--
-- Name: gtcassociation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcassociation
    ADD CONSTRAINT gtcassociation_pkey PRIMARY KEY (associationid);


--
-- Name: gtcbackgroundtasklog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcbackgroundtasklog
    ADD CONSTRAINT gtcbackgroundtasklog_pkey PRIMARY KEY (backgroundtasklogid);


--
-- Name: gtccataloguingformat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtccataloguingformat
    ADD CONSTRAINT gtccataloguingformat_pkey PRIMARY KEY (cataloguingformatid);


--
-- Name: gtcclassificationarea_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcclassificationarea
    ADD CONSTRAINT gtcclassificationarea_pkey PRIMARY KEY (classificationareaid);


--
-- Name: gtccontrolfielddetail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtccontrolfielddetail
    ADD CONSTRAINT gtccontrolfielddetail_pkey PRIMARY KEY (controlfielddetailid);


--
-- Name: gtccostcenter_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtccostcenter
    ADD CONSTRAINT gtccostcenter_pkey PRIMARY KEY (costcenterid);


--
-- Name: gtcdictionary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcdictionary
    ADD CONSTRAINT gtcdictionary_pkey PRIMARY KEY (dictionaryid);


--
-- Name: gtcdictionarycontent_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcdictionarycontent
    ADD CONSTRAINT gtcdictionarycontent_pkey PRIMARY KEY (dictionarycontentid);


--
-- Name: gtcdictionaryrelatedcontent_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcdictionaryrelatedcontent
    ADD CONSTRAINT gtcdictionaryrelatedcontent_pkey PRIMARY KEY (dictionaryrelatedcontentid);


--
-- Name: gtcdomain_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcdomain
    ADD CONSTRAINT gtcdomain_pkey PRIMARY KEY (domainid, sequence);


--
-- Name: gtcexemplarycontrol_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcexemplarycontrol
    ADD CONSTRAINT gtcexemplarycontrol_pkey PRIMARY KEY (controlnumber, itemnumber);


--
-- Name: gtcexemplaryfuturestatusdefined_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcexemplaryfuturestatusdefined
    ADD CONSTRAINT gtcexemplaryfuturestatusdefined_pkey PRIMARY KEY (exemplaryfuturestatusdefinedid);


--
-- Name: gtcexemplarystatus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcexemplarystatus
    ADD CONSTRAINT gtcexemplarystatus_pkey PRIMARY KEY (exemplarystatusid);


--
-- Name: gtcfavorite_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcfavorite
    ADD CONSTRAINT gtcfavorite_pkey PRIMARY KEY (personid, controlnumber);


--
-- Name: gtcfine_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcfine
    ADD CONSTRAINT gtcfine_pkey PRIMARY KEY (fineid);


--
-- Name: gtcfinestatus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcfinestatus
    ADD CONSTRAINT gtcfinestatus_pkey PRIMARY KEY (finestatusid);


--
-- Name: gtcformatbackofbook_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcformatbackofbook
    ADD CONSTRAINT gtcformatbackofbook_pkey PRIMARY KEY (formatbackofbookid);


--
-- Name: gtcformcontent_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcformcontent
    ADD CONSTRAINT gtcformcontent_pkey PRIMARY KEY (formcontentid);


--
-- Name: gtcformcontentdetail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcformcontentdetail
    ADD CONSTRAINT gtcformcontentdetail_pkey PRIMARY KEY (formcontentid, field);


--
-- Name: gtcformcontenttype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcformcontenttype
    ADD CONSTRAINT gtcformcontenttype_pkey PRIMARY KEY (formcontenttypeid);


--
-- Name: gtcgeneralpolicy_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcgeneralpolicy
    ADD CONSTRAINT gtcgeneralpolicy_pkey PRIMARY KEY (privilegegroupid, linkid);


--
-- Name: gtchelp_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtchelp
    ADD CONSTRAINT gtchelp_pkey PRIMARY KEY (helpid);


--
-- Name: gtcholiday_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcholiday
    ADD CONSTRAINT gtcholiday_pkey PRIMARY KEY (holidayid);


--
-- Name: gtcinterchange_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcinterchange
    ADD CONSTRAINT gtcinterchange_pkey PRIMARY KEY (interchangeid);


--
-- Name: gtcinterchangeitem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcinterchangeitem
    ADD CONSTRAINT gtcinterchangeitem_pkey PRIMARY KEY (interchangeitemid);


--
-- Name: gtcinterchangeobservation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcinterchangeobservation
    ADD CONSTRAINT gtcinterchangeobservation_pkey PRIMARY KEY (interchangeobservationid);


--
-- Name: gtcinterchangestatus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcinterchangestatus
    ADD CONSTRAINT gtcinterchangestatus_pkey PRIMARY KEY (interchangestatusid);


--
-- Name: gtcinterchangetype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcinterchangetype
    ADD CONSTRAINT gtcinterchangetype_pkey PRIMARY KEY (interchangetypeid);


--
-- Name: gtcinterestsarea_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcinterestsarea
    ADD CONSTRAINT gtcinterestsarea_pkey PRIMARY KEY (personid, classificationareaid);


--
-- Name: gtclabellayout_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtclabellayout
    ADD CONSTRAINT gtclabellayout_pkey PRIMARY KEY (labellayoutid);


--
-- Name: gtclibraryassociation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtclibraryassociation
    ADD CONSTRAINT gtclibraryassociation_pkey PRIMARY KEY (associationid, libraryunitid);


--
-- Name: gtclibrarygroup_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtclibrarygroup
    ADD CONSTRAINT gtclibrarygroup_pkey PRIMARY KEY (librarygroupid);


--
-- Name: gtclibraryunit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtclibraryunit
    ADD CONSTRAINT gtclibraryunit_pkey PRIMARY KEY (libraryunitid);


--
-- Name: gtclibraryunitaccess_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtclibraryunitaccess
    ADD CONSTRAINT gtclibraryunitaccess_pkey PRIMARY KEY (libraryunitid, linkid);


--
-- Name: gtclibraryunitconfig_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtclibraryunitconfig
    ADD CONSTRAINT gtclibraryunitconfig_pkey PRIMARY KEY (libraryunitid, parameter);


--
-- Name: gtclibraryunitisclosed_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtclibraryunitisclosed
    ADD CONSTRAINT gtclibraryunitisclosed_pkey PRIMARY KEY (libraryunitid, weekdayid);


--
-- Name: gtclinkoffieldsbetweenspreadsheets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtclinkoffieldsbetweenspreadsheets
    ADD CONSTRAINT gtclinkoffieldsbetweenspreadsheets_pkey PRIMARY KEY (linkoffieldsbetweenspreadsheetsid);


--
-- Name: gtcloan_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcloan
    ADD CONSTRAINT gtcloan_pkey PRIMARY KEY (loanid);


--
-- Name: gtcloanbetweenlibrary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcloanbetweenlibrary
    ADD CONSTRAINT gtcloanbetweenlibrary_pkey PRIMARY KEY (loanbetweenlibraryid);


--
-- Name: gtcloanbetweenlibrarycomposition_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcloanbetweenlibrarycomposition
    ADD CONSTRAINT gtcloanbetweenlibrarycomposition_pkey PRIMARY KEY (loanbetweenlibraryid, itemnumber);


--
-- Name: gtcloanbetweenlibrarystatus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcloanbetweenlibrarystatus
    ADD CONSTRAINT gtcloanbetweenlibrarystatus_pkey PRIMARY KEY (loanbetweenlibrarystatusid);


--
-- Name: gtcloantype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcloantype
    ADD CONSTRAINT gtcloantype_pkey PRIMARY KEY (loantypeid);


--
-- Name: gtclocationformaterialmovement_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtclocationformaterialmovement
    ADD CONSTRAINT gtclocationformaterialmovement_pkey PRIMARY KEY (locationformaterialmovementid);


--
-- Name: gtcmarctaglisting_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcmarctaglisting
    ADD CONSTRAINT gtcmarctaglisting_pkey PRIMARY KEY (marctaglistingid);


--
-- Name: gtcmaterial_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcmaterial
    ADD CONSTRAINT gtcmaterial_pkey PRIMARY KEY (controlnumber, fieldid, subfieldid, line);


--
-- Name: gtcmaterialcontrol_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcmaterialcontrol
    ADD CONSTRAINT gtcmaterialcontrol_pkey PRIMARY KEY (controlnumber);


--
-- Name: gtcmaterialevaluation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcmaterialevaluation
    ADD CONSTRAINT gtcmaterialevaluation_pkey PRIMARY KEY (materialevaluationid);


--
-- Name: gtcmaterialgender_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcmaterialgender
    ADD CONSTRAINT gtcmaterialgender_pkey PRIMARY KEY (materialgenderid);


--
-- Name: gtcmaterialhistory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcmaterialhistory
    ADD CONSTRAINT gtcmaterialhistory_pkey PRIMARY KEY (materialhistoryid);


--
-- Name: gtcmaterialphysicaltype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcmaterialphysicaltype
    ADD CONSTRAINT gtcmaterialphysicaltype_pkey PRIMARY KEY (materialphysicaltypeid);


--
-- Name: gtcmaterialtype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcmaterialtype
    ADD CONSTRAINT gtcmaterialtype_pkey PRIMARY KEY (materialtypeid);


--
-- Name: gtcmylibrary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcmylibrary
    ADD CONSTRAINT gtcmylibrary_pkey PRIMARY KEY (mylibraryid);


--
-- Name: gtcnews_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcnews
    ADD CONSTRAINT gtcnews_pkey PRIMARY KEY (newsid);


--
-- Name: gtcnewsaccess_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcnewsaccess
    ADD CONSTRAINT gtcnewsaccess_pkey PRIMARY KEY (newsid, linkid);


--
-- Name: gtcoperation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcoperation
    ADD CONSTRAINT gtcoperation_pkey PRIMARY KEY (operationid);


--
-- Name: gtcpenalty_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcpenalty
    ADD CONSTRAINT gtcpenalty_pkey PRIMARY KEY (penaltyid);


--
-- Name: gtcpersonconfig_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcpersonconfig
    ADD CONSTRAINT gtcpersonconfig_pkey PRIMARY KEY (personid, parameter);


--
-- Name: gtcpersonlibraryunit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcpersonlibraryunit
    ADD CONSTRAINT gtcpersonlibraryunit_pkey PRIMARY KEY (libraryunitid, personid);


--
-- Name: gtcpolicy_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcpolicy
    ADD CONSTRAINT gtcpolicy_pkey PRIMARY KEY (privilegegroupid, linkid, materialgenderid);


--
-- Name: gtcprecatalogue_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcprecatalogue
    ADD CONSTRAINT gtcprecatalogue_pkey PRIMARY KEY (controlnumber, fieldid, subfieldid, line);


--
-- Name: gtcprefixsuffix_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcprefixsuffix
    ADD CONSTRAINT gtcprefixsuffix_pkey PRIMARY KEY (prefixsuffixid);


--
-- Name: gtcprivilegegroup_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcprivilegegroup
    ADD CONSTRAINT gtcprivilegegroup_pkey PRIMARY KEY (privilegegroupid);


--
-- Name: gtcpurchaserequest_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcpurchaserequest
    ADD CONSTRAINT gtcpurchaserequest_pkey PRIMARY KEY (purchaserequestid);


--
-- Name: gtcpurchaserequestmaterial_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcpurchaserequestmaterial
    ADD CONSTRAINT gtcpurchaserequestmaterial_pkey PRIMARY KEY (purchaserequestid, fieldid, subfieldid);


--
-- Name: gtcpurchaserequestquotation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcpurchaserequestquotation
    ADD CONSTRAINT gtcpurchaserequestquotation_pkey PRIMARY KEY (purchaserequestid, supplierid);


--
-- Name: gtcrenew_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcrenew
    ADD CONSTRAINT gtcrenew_pkey PRIMARY KEY (renewid);


--
-- Name: gtcrenewtype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcrenewtype
    ADD CONSTRAINT gtcrenewtype_pkey PRIMARY KEY (renewtypeid);


--
-- Name: gtcreport_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcreport
    ADD CONSTRAINT gtcreport_pkey PRIMARY KEY (reportid);


--
-- Name: gtcreportparameter_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcreportparameter
    ADD CONSTRAINT gtcreportparameter_pkey PRIMARY KEY (reportparameterid);


--
-- Name: gtcrequestchangeexemplarystatus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcrequestchangeexemplarystatus
    ADD CONSTRAINT gtcrequestchangeexemplarystatus_pkey PRIMARY KEY (requestchangeexemplarystatusid);


--
-- Name: gtcrequestchangeexemplarystatusaccess_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcrequestchangeexemplarystatusaccess
    ADD CONSTRAINT gtcrequestchangeexemplarystatusaccess_pkey PRIMARY KEY (baslinkid, exemplarystatusid);


--
-- Name: gtcrequestchangeexemplarystatuscomposition_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcrequestchangeexemplarystatuscomposition
    ADD CONSTRAINT gtcrequestchangeexemplarystatuscomposition_pkey PRIMARY KEY (requestchangeexemplarystatusid, itemnumber);


--
-- Name: gtcrequestchangeexemplarystatusstatus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcrequestchangeexemplarystatusstatus
    ADD CONSTRAINT gtcrequestchangeexemplarystatusstatus_pkey PRIMARY KEY (requestchangeexemplarystatusstatusid);


--
-- Name: gtcreserve_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcreserve
    ADD CONSTRAINT gtcreserve_pkey PRIMARY KEY (reserveid);


--
-- Name: gtcreservecomposition_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcreservecomposition
    ADD CONSTRAINT gtcreservecomposition_pkey PRIMARY KEY (reserveid, itemnumber);


--
-- Name: gtcreservestatus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcreservestatus
    ADD CONSTRAINT gtcreservestatus_pkey PRIMARY KEY (reservestatusid);


--
-- Name: gtcreservetype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcreservetype
    ADD CONSTRAINT gtcreservetype_pkey PRIMARY KEY (reservetypeid);


--
-- Name: gtcreturnregister_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcreturnregister
    ADD CONSTRAINT gtcreturnregister_pkey PRIMARY KEY (returnregisterid);


--
-- Name: gtcreturntype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcreturntype
    ADD CONSTRAINT gtcreturntype_pkey PRIMARY KEY (returntypeid);


--
-- Name: gtcright_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcright
    ADD CONSTRAINT gtcright_pkey PRIMARY KEY (privilegegroupid, linkid, materialgenderid, operationid);


--
-- Name: gtcrulesformaterialmovement_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcrulesformaterialmovement
    ADD CONSTRAINT gtcrulesformaterialmovement_pkey PRIMARY KEY (currentstate, operationid, locationformaterialmovementid);


--
-- Name: gtcrulestocompletefieldsmarc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcrulestocompletefieldsmarc
    ADD CONSTRAINT gtcrulestocompletefieldsmarc_pkey PRIMARY KEY (rulestocompletefieldsmarcid);


--
-- Name: gtcschedulecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcschedulecycle
    ADD CONSTRAINT gtcschedulecycle_pkey PRIMARY KEY (schedulecycleid);


--
-- Name: gtcscheduletask_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcscheduletask
    ADD CONSTRAINT gtcscheduletask_pkey PRIMARY KEY (scheduletaskid);


--
-- Name: gtcsearchablefield_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcsearchablefield
    ADD CONSTRAINT gtcsearchablefield_pkey PRIMARY KEY (searchablefieldid);


--
-- Name: gtcsearchablefieldaccess_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcsearchablefieldaccess
    ADD CONSTRAINT gtcsearchablefieldaccess_pkey PRIMARY KEY (searchablefieldid, linkid);


--
-- Name: gtcsearchformat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcsearchformat
    ADD CONSTRAINT gtcsearchformat_pkey PRIMARY KEY (searchformatid);


--
-- Name: gtcsearchformataccess_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcsearchformataccess
    ADD CONSTRAINT gtcsearchformataccess_pkey PRIMARY KEY (searchformatid, linkid);


--
-- Name: gtcsearchformatcolumn_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcsearchformatcolumn
    ADD CONSTRAINT gtcsearchformatcolumn_pkey PRIMARY KEY (searchformatid, "column");


--
-- Name: gtcsearchpresentationformat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcsearchpresentationformat
    ADD CONSTRAINT gtcsearchpresentationformat_pkey PRIMARY KEY (searchformatid, category);


--
-- Name: gtcseparator_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcseparator
    ADD CONSTRAINT gtcseparator_pkey PRIMARY KEY (separatorid);


--
-- Name: gtcsoapaccess_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcsoapaccess
    ADD CONSTRAINT gtcsoapaccess_pkey PRIMARY KEY (soapclientid, webserviceid);


--
-- Name: gtcsoapclient_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcsoapclient
    ADD CONSTRAINT gtcsoapclient_pkey PRIMARY KEY (soapclientid);


--
-- Name: gtcspreadsheet_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcspreadsheet
    ADD CONSTRAINT gtcspreadsheet_pkey PRIMARY KEY (category, level);


--
-- Name: gtcsupplier_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcsupplier
    ADD CONSTRAINT gtcsupplier_pkey PRIMARY KEY (supplierid);


--
-- Name: gtcsuppliertypeandlocation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcsuppliertypeandlocation
    ADD CONSTRAINT gtcsuppliertypeandlocation_pkey PRIMARY KEY (supplierid, type);


--
-- Name: gtctag_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtctag
    ADD CONSTRAINT gtctag_pkey PRIMARY KEY (fieldid, subfieldid);


--
-- Name: gtctask_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtctask
    ADD CONSTRAINT gtctask_pkey PRIMARY KEY (taskid);


--
-- Name: gtcwebservice_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcwebservice
    ADD CONSTRAINT gtcwebservice_pkey PRIMARY KEY (webserviceid);


--
-- Name: gtcweekday_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcweekday
    ADD CONSTRAINT gtcweekday_pkey PRIMARY KEY (weekdayid);


--
-- Name: gtcworkflowinstance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcworkflowinstance
    ADD CONSTRAINT gtcworkflowinstance_pkey PRIMARY KEY (workflowinstanceid);


--
-- Name: gtcworkflowtransition_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcworkflowtransition
    ADD CONSTRAINT gtcworkflowtransition_pkey PRIMARY KEY (previousworkflowstatusid, nextworkflowstatusid);


--
-- Name: gtcz3950servers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcz3950servers
    ADD CONSTRAINT gtcz3950servers_pkey PRIMARY KEY (serverid);


--
-- Name: miolo_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY miolo_group
    ADD CONSTRAINT miolo_group_pkey PRIMARY KEY (idgroup);


--
-- Name: miolo_groupuser_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY miolo_groupuser
    ADD CONSTRAINT miolo_groupuser_pkey PRIMARY KEY (iduser, idgroup);


--
-- Name: miolo_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY miolo_log
    ADD CONSTRAINT miolo_log_pkey PRIMARY KEY (idlog);


--
-- Name: miolo_module_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY miolo_module
    ADD CONSTRAINT miolo_module_pkey PRIMARY KEY (idmodule);


--
-- Name: miolo_schedule_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY miolo_schedule
    ADD CONSTRAINT miolo_schedule_pkey PRIMARY KEY (idschedule);


--
-- Name: miolo_sequence_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY miolo_sequence
    ADD CONSTRAINT miolo_sequence_pkey PRIMARY KEY (sequence);


--
-- Name: miolo_session_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY miolo_session
    ADD CONSTRAINT miolo_session_pkey PRIMARY KEY (idsession);


--
-- Name: miolo_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY miolo_transaction
    ADD CONSTRAINT miolo_transaction_pkey PRIMARY KEY (idtransaction);


--
-- Name: miolo_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY miolo_user
    ADD CONSTRAINT miolo_user_pkey PRIMARY KEY (iduser);


--
-- Name: workflowhistoryid_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcworkflowhistory
    ADD CONSTRAINT workflowhistoryid_pkey PRIMARY KEY (workflowhistoryid);


--
-- Name: workflowstatusid_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gtcworkflowstatus
    ADD CONSTRAINT workflowstatusid_pkey PRIMARY KEY (workflowstatusid);


--
-- Name: index_baspersonlink_linkid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_baspersonlink_linkid ON baspersonlink USING btree (linkid);


--
-- Name: index_baspersonlink_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_baspersonlink_personid ON baspersonlink USING btree (personid);


--
-- Name: index_baspersonoperationprocess_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_baspersonoperationprocess_personid ON baspersonoperationprocess USING btree (personid);


--
-- Name: index_basphone_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_basphone_personid ON basphone USING btree (personid);


--
-- Name: index_gtcanalytics_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcanalytics_libraryunitid ON gtcanalytics USING btree (libraryunitid);


--
-- Name: index_gtcanalytics_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcanalytics_personid ON gtcanalytics USING btree (personid);


--
-- Name: index_gtcbackgroundtasklog_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcbackgroundtasklog_libraryunitid ON gtcbackgroundtasklog USING btree (libraryunitid);


--
-- Name: index_gtccontrolfielddetail; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtccontrolfielddetail ON gtccontrolfielddetail USING btree (fieldid, subfieldid, categoryid, isactive);


--
-- Name: index_gtccontrolfielddetail_1; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtccontrolfielddetail_1 ON gtccontrolfielddetail USING btree (fieldid, subfieldid, categoryid, isactive);


--
-- Name: index_gtccontrolfielddetail_fieldid_subfieldid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtccontrolfielddetail_fieldid_subfieldid ON gtccontrolfielddetail USING btree (fieldid, subfieldid);


--
-- Name: index_gtccontrolfielddetail_marctaglistid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtccontrolfielddetail_marctaglistid ON gtccontrolfielddetail USING btree (marctaglistid);


--
-- Name: index_gtcdictionarycontent_dictionarycontent; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcdictionarycontent_dictionarycontent ON gtcdictionarycontent USING btree (dictionarycontent);


--
-- Name: index_gtcdictionarycontent_dictionaryid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcdictionarycontent_dictionaryid ON gtcdictionarycontent USING btree (dictionaryid);


--
-- Name: index_gtcdictionaryrelatedcontent_dictionarycontentid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcdictionaryrelatedcontent_dictionarycontentid ON gtcdictionaryrelatedcontent USING btree (dictionarycontentid);


--
-- Name: index_gtcdictionaryrelatedcontent_relatedcontent; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcdictionaryrelatedcontent_relatedcontent ON gtcdictionaryrelatedcontent USING btree (relatedcontent);


--
-- Name: index_gtcemailcontroldelayedloan_loanid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcemailcontroldelayedloan_loanid ON gtcemailcontroldelayedloan USING btree (loanid);


--
-- Name: index_gtcemailcontrolnotifyaquisition_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcemailcontrolnotifyaquisition_personid ON gtcemailcontrolnotifyaquisition USING btree (personid);


--
-- Name: index_gtcexemplarycontrol_controlnumber; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcexemplarycontrol_controlnumber ON gtcexemplarycontrol USING btree (controlnumber);


--
-- Name: index_gtcexemplarycontrol_exemplarystatusid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcexemplarycontrol_exemplarystatusid ON gtcexemplarycontrol USING btree (exemplarystatusid);


--
-- Name: index_gtcexemplarycontrol_library; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcexemplarycontrol_library ON gtcexemplarycontrol USING btree (controlnumber, libraryunitid);


--
-- Name: index_gtcexemplarycontrol_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcexemplarycontrol_libraryunitid ON gtcexemplarycontrol USING btree (libraryunitid);


--
-- Name: index_gtcexemplarycontrol_materialgenderid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcexemplarycontrol_materialgenderid ON gtcexemplarycontrol USING btree (materialgenderid);


--
-- Name: index_gtcexemplarycontrol_materialphysicaltypeid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcexemplarycontrol_materialphysicaltypeid ON gtcexemplarycontrol USING btree (materialphysicaltypeid);


--
-- Name: index_gtcexemplarycontrol_materialtypeid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcexemplarycontrol_materialtypeid ON gtcexemplarycontrol USING btree (materialtypeid);


--
-- Name: index_gtcexemplarycontrol_originallibraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcexemplarycontrol_originallibraryunitid ON gtcexemplarycontrol USING btree (originallibraryunitid);


--
-- Name: index_gtcexemplarycontrol_status; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcexemplarycontrol_status ON gtcexemplarycontrol USING btree (controlnumber, exemplarystatusid);


--
-- Name: index_gtcexemplaryfuturestatusdefined_exemplarystatusid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcexemplaryfuturestatusdefined_exemplarystatusid ON gtcexemplaryfuturestatusdefined USING btree (exemplarystatusid);


--
-- Name: index_gtcexemplarystatushistory_exemplarystatusid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcexemplarystatushistory_exemplarystatusid ON gtcexemplarystatushistory USING btree (exemplarystatusid);


--
-- Name: index_gtcexemplarystatushistory_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcexemplarystatushistory_libraryunitid ON gtcexemplarystatushistory USING btree (libraryunitid);


--
-- Name: index_gtcfavorite_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcfavorite_personid ON gtcfavorite USING btree (personid);


--
-- Name: index_gtcfine_finestatusid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcfine_finestatusid ON gtcfine USING btree (finestatusid);


--
-- Name: index_gtcfine_loanid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcfine_loanid ON gtcfine USING btree (loanid);


--
-- Name: index_gtcfinestatushistory; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcfinestatushistory ON gtcfinestatushistory USING btree (fineid);


--
-- Name: index_gtcfinestatushistory_fineid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcfinestatushistory_fineid ON gtcfinestatushistory USING btree (fineid);


--
-- Name: index_gtcfinestatushistory_finestatusid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcfinestatushistory_finestatusid ON gtcfinestatushistory USING btree (finestatusid);


--
-- Name: index_gtcformcontent_formcontenttype; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcformcontent_formcontenttype ON gtcformcontent USING btree (formcontenttype);


--
-- Name: index_gtcgeneralpolicy_linkid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcgeneralpolicy_linkid ON gtcgeneralpolicy USING btree (linkid);


--
-- Name: index_gtcgeneralpolicy_privilegegroupid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcgeneralpolicy_privilegegroupid ON gtcgeneralpolicy USING btree (privilegegroupid);


--
-- Name: index_gtcholiday_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcholiday_libraryunitid ON gtcholiday USING btree (libraryunitid);


--
-- Name: index_gtcinterchange_interchangestatusid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcinterchange_interchangestatusid ON gtcinterchange USING btree (interchangestatusid);


--
-- Name: index_gtcinterchange_interchangetypeid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcinterchange_interchangetypeid ON gtcinterchange USING btree (interchangetypeid);


--
-- Name: index_gtcinterchangeitem_interchangeid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcinterchangeitem_interchangeid ON gtcinterchangeitem USING btree (interchangeid);


--
-- Name: index_gtcinterchangeobservation_interchangeid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcinterchangeobservation_interchangeid ON gtcinterchangeobservation USING btree (interchangeid);


--
-- Name: index_gtcinterchangestatus_interchangetypeid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcinterchangestatus_interchangetypeid ON gtcinterchangestatus USING btree (interchangetypeid);


--
-- Name: index_gtcinterestsarea_classificationareaid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcinterestsarea_classificationareaid ON gtcinterestsarea USING btree (classificationareaid);


--
-- Name: index_gtcinterestsarea_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcinterestsarea_personid ON gtcinterestsarea USING btree (personid);


--
-- Name: index_gtckardexcontrol; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX index_gtckardexcontrol ON gtckardexcontrol USING btree (controlnumber, codigodeassinante, libraryunitid);


--
-- Name: index_gtckardexcontrol_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtckardexcontrol_libraryunitid ON gtckardexcontrol USING btree (libraryunitid);


--
-- Name: index_gtclibraryassociation_associationid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtclibraryassociation_associationid ON gtclibraryassociation USING btree (associationid);


--
-- Name: index_gtclibraryassociation_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtclibraryassociation_libraryunitid ON gtclibraryassociation USING btree (libraryunitid);


--
-- Name: index_gtclibraryunit_librarygroupid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtclibraryunit_librarygroupid ON gtclibraryunit USING btree (librarygroupid);


--
-- Name: index_gtclibraryunit_privilegegroupid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtclibraryunit_privilegegroupid ON gtclibraryunit USING btree (privilegegroupid);


--
-- Name: index_gtclibraryunitaccess_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtclibraryunitaccess_libraryunitid ON gtclibraryunitaccess USING btree (libraryunitid);


--
-- Name: index_gtclibraryunitaccess_linkid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtclibraryunitaccess_linkid ON gtclibraryunitaccess USING btree (linkid);


--
-- Name: index_gtclibraryunitconfig_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtclibraryunitconfig_libraryunitid ON gtclibraryunitconfig USING btree (libraryunitid);


--
-- Name: index_gtclibraryunitisclosed_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtclibraryunitisclosed_libraryunitid ON gtclibraryunitisclosed USING btree (libraryunitid);


--
-- Name: index_gtclibraryunitisclosed_weekdayid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtclibraryunitisclosed_weekdayid ON gtclibraryunitisclosed USING btree (weekdayid);


--
-- Name: index_gtcloan_itemnumber_returndate; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcloan_itemnumber_returndate ON gtcloan USING btree (itemnumber) WHERE (returndate IS NULL);


--
-- Name: index_gtcloan_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcloan_libraryunitid ON gtcloan USING btree (libraryunitid) WHERE (returndate IS NULL);


--
-- Name: index_gtcloan_linkid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcloan_linkid ON gtcloan USING btree (linkid);


--
-- Name: index_gtcloan_loantypeid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcloan_loantypeid ON gtcloan USING btree (loantypeid);


--
-- Name: index_gtcloan_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcloan_personid ON gtcloan USING btree (personid);


--
-- Name: index_gtcloan_privilegegroupid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcloan_privilegegroupid ON gtcloan USING btree (privilegegroupid);


--
-- Name: index_gtcloanbetweenlibrary_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcloanbetweenlibrary_libraryunitid ON gtcloanbetweenlibrary USING btree (libraryunitid);


--
-- Name: index_gtcloanbetweenlibrary_loanbetweenlibrarystatusid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcloanbetweenlibrary_loanbetweenlibrarystatusid ON gtcloanbetweenlibrary USING btree (loanbetweenlibrarystatusid);


--
-- Name: index_gtcloanbetweenlibrary_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcloanbetweenlibrary_personid ON gtcloanbetweenlibrary USING btree (personid);


--
-- Name: index_gtcloanbetweenlibrarycomposition_loanbetweenlibraryid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcloanbetweenlibrarycomposition_loanbetweenlibraryid ON gtcloanbetweenlibrarycomposition USING btree (loanbetweenlibraryid);


--
-- Name: index_gtcloanbetweenlibrarystatushistory_loanbetweenlibrarystat; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcloanbetweenlibrarystatushistory_loanbetweenlibrarystat ON gtcloanbetweenlibrarystatushistory USING btree (loanbetweenlibrarystatusid);


--
-- Name: index_gtcmarctaglistingoption_marctaglistingid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmarctaglistingoption_marctaglistingid ON gtcmarctaglistingoption USING btree (marctaglistingid);


--
-- Name: index_gtcmaterial_3; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterial_3 ON gtcmaterial USING btree (fieldid, subfieldid, searchcontent varchar_pattern_ops);


--
-- Name: index_gtcmaterial_content; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterial_content ON gtcmaterial USING btree (controlnumber, content);


--
-- Name: index_gtcmaterial_controlnumbersearch; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterial_controlnumbersearch ON gtcmaterial USING btree (controlnumber, fieldid, subfieldid, searchcontent);


--
-- Name: index_gtcmaterial_fieldid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterial_fieldid ON gtcmaterial USING btree (controlnumber, fieldid);


--
-- Name: index_gtcmaterial_fieldid_subfieldid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterial_fieldid_subfieldid ON gtcmaterial USING btree (fieldid, subfieldid);


--
-- Name: index_gtcmaterial_fieldsubfield; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterial_fieldsubfield ON gtcmaterial USING btree (controlnumber, fieldid, subfieldid);


--
-- Name: index_gtcmaterial_indice4; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterial_indice4 ON gtcmaterial USING btree (fieldid, subfieldid, searchcontent varchar_pattern_ops);


--
-- Name: index_gtcmaterial_prefixid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterial_prefixid ON gtcmaterial USING btree (prefixid);


--
-- Name: index_gtcmaterial_searchcontent; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterial_searchcontent ON gtcmaterial USING btree (controlnumber, searchcontent);


--
-- Name: index_gtcmaterial_separatorid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterial_separatorid ON gtcmaterial USING btree (separatorid);


--
-- Name: index_gtcmaterial_subfieldid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterial_subfieldid ON gtcmaterial USING btree (controlnumber, subfieldid);


--
-- Name: index_gtcmaterial_suffixid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterial_suffixid ON gtcmaterial USING btree (suffixid);


--
-- Name: index_gtcmaterialcontrol_category; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialcontrol_category ON gtcmaterialcontrol USING btree (controlnumber, category);


--
-- Name: index_gtcmaterialcontrol_category_level; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialcontrol_category_level ON gtcmaterialcontrol USING btree (category, level);


--
-- Name: index_gtcmaterialcontrol_controlnumber; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialcontrol_controlnumber ON gtcmaterialcontrol USING btree (controlnumber, category, level);


--
-- Name: index_gtcmaterialcontrol_entrancedate; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialcontrol_entrancedate ON gtcmaterialcontrol USING btree (controlnumber, entrancedate);


--
-- Name: index_gtcmaterialcontrol_father; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialcontrol_father ON gtcmaterialcontrol USING btree (controlnumberfather);


--
-- Name: index_gtcmaterialcontrol_fathercatlev; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialcontrol_fathercatlev ON gtcmaterialcontrol USING btree (controlnumberfather, category, level);


--
-- Name: index_gtcmaterialcontrol_gender; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialcontrol_gender ON gtcmaterialcontrol USING btree (controlnumber, materialgenderid);


--
-- Name: index_gtcmaterialcontrol_level; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialcontrol_level ON gtcmaterialcontrol USING btree (controlnumber, level);


--
-- Name: index_gtcmaterialcontrol_materialgenderid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialcontrol_materialgenderid ON gtcmaterialcontrol USING btree (materialgenderid);


--
-- Name: index_gtcmaterialcontrol_materialphysicaltypeid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialcontrol_materialphysicaltypeid ON gtcmaterialcontrol USING btree (materialphysicaltypeid);


--
-- Name: index_gtcmaterialcontrol_materialtypeid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialcontrol_materialtypeid ON gtcmaterialcontrol USING btree (materialtypeid);


--
-- Name: index_gtcmaterialcontrol_physical; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialcontrol_physical ON gtcmaterialcontrol USING btree (controlnumber, materialphysicaltypeid);


--
-- Name: index_gtcmaterialcontrol_type; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialcontrol_type ON gtcmaterialcontrol USING btree (controlnumber, materialtypeid);


--
-- Name: index_gtcmaterialevaluation_controlnumber; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialevaluation_controlnumber ON gtcmaterialevaluation USING btree (controlnumber);


--
-- Name: index_gtcmaterialevaluation_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialevaluation_personid ON gtcmaterialevaluation USING btree (personid);


--
-- Name: index_gtcmaterialhistory_controlnumber; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialhistory_controlnumber ON gtcmaterialhistory USING btree (controlnumber);


--
-- Name: index_gtcmaterialhistory_fieldid_subfieldid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmaterialhistory_fieldid_subfieldid ON gtcmaterialhistory USING btree (fieldid, subfieldid);


--
-- Name: index_gtcmylibrary_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmylibrary_personid ON gtcmylibrary USING btree (personid);


--
-- Name: index_gtcmylibrary_tablename_tableid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcmylibrary_tablename_tableid ON gtcmylibrary USING btree (tablename, tableid);


--
-- Name: index_gtcnews_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcnews_libraryunitid ON gtcnews USING btree (libraryunitid);


--
-- Name: index_gtcnewsaccess_linkid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcnewsaccess_linkid ON gtcnewsaccess USING btree (linkid);


--
-- Name: index_gtcnewsaccess_newsid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcnewsaccess_newsid ON gtcnewsaccess USING btree (newsid);


--
-- Name: index_gtcoperatorlibraryunit_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcoperatorlibraryunit_libraryunitid ON gtcoperatorlibraryunit USING btree (libraryunitid);


--
-- Name: index_gtcoperatorlibraryunit_operator; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcoperatorlibraryunit_operator ON gtcoperatorlibraryunit USING btree (operator);


--
-- Name: index_gtcpenalty_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcpenalty_libraryunitid ON gtcpenalty USING btree (libraryunitid);


--
-- Name: index_gtcpenalty_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcpenalty_personid ON gtcpenalty USING btree (personid);


--
-- Name: index_gtcpersonconfig_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcpersonconfig_personid ON gtcpersonconfig USING btree (personid);


--
-- Name: index_gtcpersonlibraryunit_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcpersonlibraryunit_libraryunitid ON gtcpersonlibraryunit USING btree (libraryunitid);


--
-- Name: index_gtcpersonlibraryunit_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcpersonlibraryunit_personid ON gtcpersonlibraryunit USING btree (personid);


--
-- Name: index_gtcpolicy_linkid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcpolicy_linkid ON gtcpolicy USING btree (linkid);


--
-- Name: index_gtcpolicy_materialgenderid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcpolicy_materialgenderid ON gtcpolicy USING btree (materialgenderid);


--
-- Name: index_gtcpolicy_privilegegroupid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcpolicy_privilegegroupid ON gtcpolicy USING btree (privilegegroupid);


--
-- Name: index_gtcprecatalogue_prefixid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcprecatalogue_prefixid ON gtcprecatalogue USING btree (prefixid);


--
-- Name: index_gtcprecatalogue_separatorid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcprecatalogue_separatorid ON gtcprecatalogue USING btree (separatorid);


--
-- Name: index_gtcprecatalogue_suffixid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcprecatalogue_suffixid ON gtcprecatalogue USING btree (suffixid);


--
-- Name: index_gtcprefixsuffix_fieldid_subfieldid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcprefixsuffix_fieldid_subfieldid ON gtcprefixsuffix USING btree (fieldid, subfieldid);


--
-- Name: index_gtcpurchaserequest_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcpurchaserequest_libraryunitid ON gtcpurchaserequest USING btree (libraryunitid);


--
-- Name: index_gtcpurchaserequest_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcpurchaserequest_personid ON gtcpurchaserequest USING btree (personid);


--
-- Name: index_gtcrenew_loanid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcrenew_loanid ON gtcrenew USING btree (loanid);


--
-- Name: index_gtcrenew_renewtypeid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcrenew_renewtypeid ON gtcrenew USING btree (renewtypeid);


--
-- Name: index_gtcreportparameter_reportid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcreportparameter_reportid ON gtcreportparameter USING btree (reportid);


--
-- Name: index_gtcrequestchangeexemplarystatus_futurestatusid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcrequestchangeexemplarystatus_futurestatusid ON gtcrequestchangeexemplarystatus USING btree (futurestatusid);


--
-- Name: index_gtcrequestchangeexemplarystatus_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcrequestchangeexemplarystatus_libraryunitid ON gtcrequestchangeexemplarystatus USING btree (libraryunitid);


--
-- Name: index_gtcrequestchangeexemplarystatus_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcrequestchangeexemplarystatus_personid ON gtcrequestchangeexemplarystatus USING btree (personid);


--
-- Name: index_gtcrequestchangeexemplarystatusaccess_baslinkid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcrequestchangeexemplarystatusaccess_baslinkid ON gtcrequestchangeexemplarystatusaccess USING btree (baslinkid);


--
-- Name: index_gtcrequestchangeexemplarystatusaccess_exemplarystatusid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcrequestchangeexemplarystatusaccess_exemplarystatusid ON gtcrequestchangeexemplarystatusaccess USING btree (exemplarystatusid);


--
-- Name: index_gtcrequestchangeexemplarystatuscomposition_exemplaryfutur; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcrequestchangeexemplarystatuscomposition_exemplaryfutur ON gtcrequestchangeexemplarystatuscomposition USING btree (exemplaryfuturestatusdefinedid);


--
-- Name: index_gtcrequestchangeexemplarystatuscomposition_requestchangee; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcrequestchangeexemplarystatuscomposition_requestchangee ON gtcrequestchangeexemplarystatuscomposition USING btree (requestchangeexemplarystatusid);


--
-- Name: index_gtcrequestchangeexemplarystatusstatushistory_requestchang; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcrequestchangeexemplarystatusstatushistory_requestchang ON gtcrequestchangeexemplarystatusstatushistory USING btree (requestchangeexemplarystatusstatusid);


--
-- Name: index_gtcreserve_libraryunitid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcreserve_libraryunitid ON gtcreserve USING btree (libraryunitid);


--
-- Name: index_gtcreserve_personid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcreserve_personid ON gtcreserve USING btree (personid);


--
-- Name: index_gtcreserve_reservestatusid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcreserve_reservestatusid ON gtcreserve USING btree (reservestatusid);


--
-- Name: index_gtcreserve_reservetypeid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcreserve_reservetypeid ON gtcreserve USING btree (reservetypeid);


--
-- Name: index_gtcreservecomposition_itemnumber; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcreservecomposition_itemnumber ON gtcreservecomposition USING btree (itemnumber);


--
-- Name: index_gtcreservecomposition_reserveid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcreservecomposition_reserveid ON gtcreservecomposition USING btree (reserveid);


--
-- Name: index_gtcreservestatushistory_reserveid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcreservestatushistory_reserveid ON gtcreservestatushistory USING btree (reserveid);


--
-- Name: index_gtcreservestatushistory_reservestatusid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcreservestatushistory_reservestatusid ON gtcreservestatushistory USING btree (reservestatusid);


--
-- Name: index_gtcreturnregister_returntypeid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcreturnregister_returntypeid ON gtcreturnregister USING btree (returntypeid);


--
-- Name: index_gtcright_linkid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcright_linkid ON gtcright USING btree (linkid);


--
-- Name: index_gtcright_materialgenderid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcright_materialgenderid ON gtcright USING btree (materialgenderid);


--
-- Name: index_gtcright_operationid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcright_operationid ON gtcright USING btree (operationid);


--
-- Name: index_gtcright_privilegegroupid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcright_privilegegroupid ON gtcright USING btree (privilegegroupid);


--
-- Name: index_gtcrulesformaterialmovement_currentstate; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcrulesformaterialmovement_currentstate ON gtcrulesformaterialmovement USING btree (currentstate);


--
-- Name: index_gtcrulesformaterialmovement_futurestate; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcrulesformaterialmovement_futurestate ON gtcrulesformaterialmovement USING btree (futurestate);


--
-- Name: index_gtcrulesformaterialmovement_locationformaterialmovementid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcrulesformaterialmovement_locationformaterialmovementid ON gtcrulesformaterialmovement USING btree (locationformaterialmovementid);


--
-- Name: index_gtcrulesformaterialmovement_operationid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcrulesformaterialmovement_operationid ON gtcrulesformaterialmovement USING btree (operationid);


--
-- Name: index_gtcscheduletask_schedulecycleid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcscheduletask_schedulecycleid ON gtcscheduletask USING btree (schedulecycleid);


--
-- Name: index_gtcscheduletask_taskid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcscheduletask_taskid ON gtcscheduletask USING btree (taskid);


--
-- Name: index_gtcscheduletasklog_scheduletaskid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcscheduletasklog_scheduletaskid ON gtcscheduletasklog USING btree (scheduletaskid);


--
-- Name: index_gtcsearchablefieldaccess_linkid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcsearchablefieldaccess_linkid ON gtcsearchablefieldaccess USING btree (linkid);


--
-- Name: index_gtcsearchablefieldaccess_searchablefieldid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcsearchablefieldaccess_searchablefieldid ON gtcsearchablefieldaccess USING btree (searchablefieldid);


--
-- Name: index_gtcsearchformataccess_linkid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcsearchformataccess_linkid ON gtcsearchformataccess USING btree (linkid);


--
-- Name: index_gtcsearchformataccess_searchformatid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcsearchformataccess_searchformatid ON gtcsearchformataccess USING btree (searchformatid);


--
-- Name: index_gtcsearchformatcolumn_searchformatid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcsearchformatcolumn_searchformatid ON gtcsearchformatcolumn USING btree (searchformatid);


--
-- Name: index_gtcsearchmaterialview_controlnumber; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcsearchmaterialview_controlnumber ON gtcsearchmaterialview USING btree (controlnumber);


--
-- Name: index_gtcsearchpresentationformat_searchformatid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcsearchpresentationformat_searchformatid ON gtcsearchpresentationformat USING btree (searchformatid);


--
-- Name: index_gtcseparator_cataloguingformatid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcseparator_cataloguingformatid ON gtcseparator USING btree (cataloguingformatid);


--
-- Name: index_gtcsoapaccess_soapclientid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcsoapaccess_soapclientid ON gtcsoapaccess USING btree (soapclientid);


--
-- Name: index_gtcsoapaccess_webserviceid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcsoapaccess_webserviceid ON gtcsoapaccess USING btree (webserviceid);


--
-- Name: index_gtcsuppliertypeandlocation_supplierid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX index_gtcsuppliertypeandlocation_supplierid ON gtcsuppliertypeandlocation USING btree (supplierid);


--
-- Name: gtctgrupdatematerialsontrigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER gtctgrupdatematerialsontrigger
    AFTER INSERT OR DELETE OR UPDATE ON gtcmaterial
    FOR EACH ROW
    EXECUTE PROCEDURE gtcfncupdatematerialson();


--
-- Name: gtcthelp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER gtcthelp
    BEFORE INSERT OR UPDATE ON gtchelp
    FOR EACH ROW
    EXECUTE PROCEDURE gtcgnccheckhelp('form', 'subform');


--
-- Name: basdocument_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY basdocument
    ADD CONSTRAINT basdocument_personid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: baspersonlink_linkid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY baspersonlink
    ADD CONSTRAINT baspersonlink_linkid_fkey FOREIGN KEY (linkid) REFERENCES baslink(linkid);


--
-- Name: baspersonlink_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY baspersonlink
    ADD CONSTRAINT baspersonlink_personid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: baspersonoperationprocess_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY baspersonoperationprocess
    ADD CONSTRAINT baspersonoperationprocess_personid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: basphone_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY basphone
    ADD CONSTRAINT basphone_personid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: fk_miolo_access1_miolo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY miolo_access
    ADD CONSTRAINT fk_miolo_access1_miolo FOREIGN KEY (idtransaction) REFERENCES miolo_transaction(idtransaction) ON DELETE CASCADE;


--
-- Name: fk_miolo_access2_miolo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY miolo_access
    ADD CONSTRAINT fk_miolo_access2_miolo FOREIGN KEY (idgroup) REFERENCES miolo_group(idgroup) ON DELETE CASCADE;


--
-- Name: fk_miolo_groupuser1_miolo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY miolo_groupuser
    ADD CONSTRAINT fk_miolo_groupuser1_miolo FOREIGN KEY (idgroup) REFERENCES miolo_group(idgroup) ON DELETE CASCADE;


--
-- Name: fk_miolo_groupuser2_miolo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY miolo_groupuser
    ADD CONSTRAINT fk_miolo_groupuser2_miolo FOREIGN KEY (iduser) REFERENCES miolo_user(iduser) ON DELETE CASCADE;


--
-- Name: fk_miolo_log1_miolo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY miolo_log
    ADD CONSTRAINT fk_miolo_log1_miolo FOREIGN KEY (iduser) REFERENCES miolo_user(iduser);


--
-- Name: fk_miolo_log2_miolo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY miolo_log
    ADD CONSTRAINT fk_miolo_log2_miolo FOREIGN KEY (idtransaction) REFERENCES miolo_transaction(idtransaction);


--
-- Name: fk_miolo_session1_miolo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY miolo_session
    ADD CONSTRAINT fk_miolo_session1_miolo FOREIGN KEY (iduser) REFERENCES miolo_user(iduser);


--
-- Name: gtcanalytics_libraryunit_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcanalytics
    ADD CONSTRAINT gtcanalytics_libraryunit_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtcanalytics_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcanalytics
    ADD CONSTRAINT gtcanalytics_personid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: gtcbackgroundtasklog_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcbackgroundtasklog
    ADD CONSTRAINT gtcbackgroundtasklog_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtccontrolfielddetail_fieldid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtccontrolfielddetail
    ADD CONSTRAINT gtccontrolfielddetail_fieldid_fkey FOREIGN KEY (fieldid, subfieldid) REFERENCES gtctag(fieldid, subfieldid);


--
-- Name: gtccontrolfielddetail_marctaglistid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtccontrolfielddetail
    ADD CONSTRAINT gtccontrolfielddetail_marctaglistid_fkey FOREIGN KEY (marctaglistid) REFERENCES gtcmarctaglisting(marctaglistingid);


--
-- Name: gtcdictionarycontent_dictionaryid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcdictionarycontent
    ADD CONSTRAINT gtcdictionarycontent_dictionaryid_fkey FOREIGN KEY (dictionaryid) REFERENCES gtcdictionary(dictionaryid);


--
-- Name: gtcdictionaryrelatedcontent_dictionarycontentid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcdictionaryrelatedcontent
    ADD CONSTRAINT gtcdictionaryrelatedcontent_dictionarycontentid_fkey FOREIGN KEY (dictionarycontentid) REFERENCES gtcdictionarycontent(dictionarycontentid);


--
-- Name: gtcemailcontroldelayedloan_loanid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcemailcontroldelayedloan
    ADD CONSTRAINT gtcemailcontroldelayedloan_loanid_fkey FOREIGN KEY (loanid) REFERENCES gtcloan(loanid);


--
-- Name: gtcemailcontrolnotifyaquisition_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcemailcontrolnotifyaquisition
    ADD CONSTRAINT gtcemailcontrolnotifyaquisition_personid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: gtcexemplarycontrol_exemplarystatusid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcexemplarycontrol
    ADD CONSTRAINT gtcexemplarycontrol_exemplarystatusid_fkey FOREIGN KEY (exemplarystatusid) REFERENCES gtcexemplarystatus(exemplarystatusid);


--
-- Name: gtcexemplarycontrol_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcexemplarycontrol
    ADD CONSTRAINT gtcexemplarycontrol_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtcexemplarycontrol_materialgenderid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcexemplarycontrol
    ADD CONSTRAINT gtcexemplarycontrol_materialgenderid_fkey FOREIGN KEY (materialgenderid) REFERENCES gtcmaterialgender(materialgenderid);


--
-- Name: gtcexemplarycontrol_materialphysicaltypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcexemplarycontrol
    ADD CONSTRAINT gtcexemplarycontrol_materialphysicaltypeid_fkey FOREIGN KEY (materialphysicaltypeid) REFERENCES gtcmaterialphysicaltype(materialphysicaltypeid);


--
-- Name: gtcexemplarycontrol_materialtypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcexemplarycontrol
    ADD CONSTRAINT gtcexemplarycontrol_materialtypeid_fkey FOREIGN KEY (materialtypeid) REFERENCES gtcmaterialtype(materialtypeid);


--
-- Name: gtcexemplarycontrol_originallibraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcexemplarycontrol
    ADD CONSTRAINT gtcexemplarycontrol_originallibraryunitid_fkey FOREIGN KEY (originallibraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtcexemplaryfuturestatusdefined_exemplarystatusid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcexemplaryfuturestatusdefined
    ADD CONSTRAINT gtcexemplaryfuturestatusdefined_exemplarystatusid_fkey FOREIGN KEY (exemplarystatusid) REFERENCES gtcexemplarystatus(exemplarystatusid);


--
-- Name: gtcexemplarystatushistory_exemplarystatusid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcexemplarystatushistory
    ADD CONSTRAINT gtcexemplarystatushistory_exemplarystatusid_fkey FOREIGN KEY (exemplarystatusid) REFERENCES gtcexemplarystatus(exemplarystatusid);


--
-- Name: gtcexemplarystatushistory_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcexemplarystatushistory
    ADD CONSTRAINT gtcexemplarystatushistory_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtcfavorite_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcfavorite
    ADD CONSTRAINT gtcfavorite_personid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: gtcfine_finestatusid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcfine
    ADD CONSTRAINT gtcfine_finestatusid_fkey FOREIGN KEY (finestatusid) REFERENCES gtcfinestatus(finestatusid);


--
-- Name: gtcfine_loanid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcfine
    ADD CONSTRAINT gtcfine_loanid_fkey FOREIGN KEY (loanid) REFERENCES gtcloan(loanid);


--
-- Name: gtcfinestatushistory_fineid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcfinestatushistory
    ADD CONSTRAINT gtcfinestatushistory_fineid_fkey FOREIGN KEY (fineid) REFERENCES gtcfine(fineid);


--
-- Name: gtcfinestatushistory_finestatusid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcfinestatushistory
    ADD CONSTRAINT gtcfinestatushistory_finestatusid_fkey FOREIGN KEY (finestatusid) REFERENCES gtcfinestatus(finestatusid);


--
-- Name: gtcformcontent_formcontenttype_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcformcontent
    ADD CONSTRAINT gtcformcontent_formcontenttype_fkey FOREIGN KEY (formcontenttype) REFERENCES gtcformcontenttype(formcontenttypeid);


--
-- Name: gtcgeneralpolicy_linkid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcgeneralpolicy
    ADD CONSTRAINT gtcgeneralpolicy_linkid_fkey FOREIGN KEY (linkid) REFERENCES baslink(linkid);


--
-- Name: gtcgeneralpolicy_privilegegroupid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcgeneralpolicy
    ADD CONSTRAINT gtcgeneralpolicy_privilegegroupid_fkey FOREIGN KEY (privilegegroupid) REFERENCES gtcprivilegegroup(privilegegroupid);


--
-- Name: gtcholiday_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcholiday
    ADD CONSTRAINT gtcholiday_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtcinterchange_interchangestatusid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcinterchange
    ADD CONSTRAINT gtcinterchange_interchangestatusid_fkey FOREIGN KEY (interchangestatusid) REFERENCES gtcinterchangestatus(interchangestatusid);


--
-- Name: gtcinterchange_interchangetypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcinterchange
    ADD CONSTRAINT gtcinterchange_interchangetypeid_fkey FOREIGN KEY (interchangetypeid) REFERENCES gtcinterchangetype(interchangetypeid);


--
-- Name: gtcinterchangeitem_interchangeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcinterchangeitem
    ADD CONSTRAINT gtcinterchangeitem_interchangeid_fkey FOREIGN KEY (interchangeid) REFERENCES gtcinterchange(interchangeid);


--
-- Name: gtcinterchangeobservation_interchangeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcinterchangeobservation
    ADD CONSTRAINT gtcinterchangeobservation_interchangeid_fkey FOREIGN KEY (interchangeid) REFERENCES gtcinterchange(interchangeid);


--
-- Name: gtcinterchangestatus_interchangetypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcinterchangestatus
    ADD CONSTRAINT gtcinterchangestatus_interchangetypeid_fkey FOREIGN KEY (interchangetypeid) REFERENCES gtcinterchangetype(interchangetypeid);


--
-- Name: gtcinterestsarea_classificationareaid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcinterestsarea
    ADD CONSTRAINT gtcinterestsarea_classificationareaid_fkey FOREIGN KEY (classificationareaid) REFERENCES gtcclassificationarea(classificationareaid);


--
-- Name: gtcinterestsarea_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcinterestsarea
    ADD CONSTRAINT gtcinterestsarea_personid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: gtckardexcontrol_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtckardexcontrol
    ADD CONSTRAINT gtckardexcontrol_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtclibraryassociation_associationid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtclibraryassociation
    ADD CONSTRAINT gtclibraryassociation_associationid_fkey FOREIGN KEY (associationid) REFERENCES gtcassociation(associationid);


--
-- Name: gtclibraryassociation_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtclibraryassociation
    ADD CONSTRAINT gtclibraryassociation_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtclibraryunit_librarygroupid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtclibraryunit
    ADD CONSTRAINT gtclibraryunit_librarygroupid_fkey FOREIGN KEY (librarygroupid) REFERENCES gtclibrarygroup(librarygroupid);


--
-- Name: gtclibraryunit_privilegegroupid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtclibraryunit
    ADD CONSTRAINT gtclibraryunit_privilegegroupid_fkey FOREIGN KEY (privilegegroupid) REFERENCES gtcprivilegegroup(privilegegroupid);


--
-- Name: gtclibraryunitaccess_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtclibraryunitaccess
    ADD CONSTRAINT gtclibraryunitaccess_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtclibraryunitaccess_linkid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtclibraryunitaccess
    ADD CONSTRAINT gtclibraryunitaccess_linkid_fkey FOREIGN KEY (linkid) REFERENCES baslink(linkid);


--
-- Name: gtclibraryunitconfig_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtclibraryunitconfig
    ADD CONSTRAINT gtclibraryunitconfig_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtclibraryunitisclosed_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtclibraryunitisclosed
    ADD CONSTRAINT gtclibraryunitisclosed_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtclibraryunitisclosed_weekdayid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtclibraryunitisclosed
    ADD CONSTRAINT gtclibraryunitisclosed_weekdayid_fkey FOREIGN KEY (weekdayid) REFERENCES gtcweekday(weekdayid);


--
-- Name: gtcloan_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcloan
    ADD CONSTRAINT gtcloan_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtcloan_linkid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcloan
    ADD CONSTRAINT gtcloan_linkid_fkey FOREIGN KEY (linkid) REFERENCES baslink(linkid);


--
-- Name: gtcloan_loantypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcloan
    ADD CONSTRAINT gtcloan_loantypeid_fkey FOREIGN KEY (loantypeid) REFERENCES gtcloantype(loantypeid);


--
-- Name: gtcloan_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcloan
    ADD CONSTRAINT gtcloan_personid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: gtcloan_privilegegroupid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcloan
    ADD CONSTRAINT gtcloan_privilegegroupid_fkey FOREIGN KEY (privilegegroupid) REFERENCES gtcprivilegegroup(privilegegroupid);


--
-- Name: gtcloanbetweenlibrary_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcloanbetweenlibrary
    ADD CONSTRAINT gtcloanbetweenlibrary_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtcloanbetweenlibrary_loanbetweenlibrarystatusid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcloanbetweenlibrary
    ADD CONSTRAINT gtcloanbetweenlibrary_loanbetweenlibrarystatusid_fkey FOREIGN KEY (loanbetweenlibrarystatusid) REFERENCES gtcloanbetweenlibrarystatus(loanbetweenlibrarystatusid);


--
-- Name: gtcloanbetweenlibrary_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcloanbetweenlibrary
    ADD CONSTRAINT gtcloanbetweenlibrary_personid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: gtcloanbetweenlibrarycomposition_loanbetweenlibraryid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcloanbetweenlibrarycomposition
    ADD CONSTRAINT gtcloanbetweenlibrarycomposition_loanbetweenlibraryid_fkey FOREIGN KEY (loanbetweenlibraryid) REFERENCES gtcloanbetweenlibrary(loanbetweenlibraryid);


--
-- Name: gtcloanbetweenlibrarystatushist_loanbetweenlibrarystatusid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcloanbetweenlibrarystatushistory
    ADD CONSTRAINT gtcloanbetweenlibrarystatushist_loanbetweenlibrarystatusid_fkey FOREIGN KEY (loanbetweenlibrarystatusid) REFERENCES gtcloanbetweenlibrarystatus(loanbetweenlibrarystatusid);


--
-- Name: gtcmarctaglistingoption_marctaglistingid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmarctaglistingoption
    ADD CONSTRAINT gtcmarctaglistingoption_marctaglistingid_fkey FOREIGN KEY (marctaglistingid) REFERENCES gtcmarctaglisting(marctaglistingid);


--
-- Name: gtcmaterial_fieldid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterial
    ADD CONSTRAINT gtcmaterial_fieldid_fkey FOREIGN KEY (fieldid, subfieldid) REFERENCES gtctag(fieldid, subfieldid);


--
-- Name: gtcmaterial_prefixid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterial
    ADD CONSTRAINT gtcmaterial_prefixid_fkey FOREIGN KEY (prefixid) REFERENCES gtcprefixsuffix(prefixsuffixid);


--
-- Name: gtcmaterial_separatorid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterial
    ADD CONSTRAINT gtcmaterial_separatorid_fkey FOREIGN KEY (separatorid) REFERENCES gtcseparator(separatorid);


--
-- Name: gtcmaterial_suffixid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterial
    ADD CONSTRAINT gtcmaterial_suffixid_fkey FOREIGN KEY (suffixid) REFERENCES gtcprefixsuffix(prefixsuffixid);


--
-- Name: gtcmaterialcontrol_category_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterialcontrol
    ADD CONSTRAINT gtcmaterialcontrol_category_fkey FOREIGN KEY (category, level) REFERENCES gtcspreadsheet(category, level);


--
-- Name: gtcmaterialcontrol_materialgenderid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterialcontrol
    ADD CONSTRAINT gtcmaterialcontrol_materialgenderid_fkey FOREIGN KEY (materialgenderid) REFERENCES gtcmaterialgender(materialgenderid);


--
-- Name: gtcmaterialcontrol_materialphysicaltypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterialcontrol
    ADD CONSTRAINT gtcmaterialcontrol_materialphysicaltypeid_fkey FOREIGN KEY (materialphysicaltypeid) REFERENCES gtcmaterialphysicaltype(materialphysicaltypeid);


--
-- Name: gtcmaterialcontrol_materialtypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterialcontrol
    ADD CONSTRAINT gtcmaterialcontrol_materialtypeid_fkey FOREIGN KEY (materialtypeid) REFERENCES gtcmaterialtype(materialtypeid);


--
-- Name: gtcmaterialevaluation_controlnumber_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterialevaluation
    ADD CONSTRAINT gtcmaterialevaluation_controlnumber_fkey FOREIGN KEY (controlnumber) REFERENCES gtcmaterialcontrol(controlnumber);


--
-- Name: gtcmaterialevaluation_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterialevaluation
    ADD CONSTRAINT gtcmaterialevaluation_personid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: gtcmaterialhistory_currentprefixid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterialhistory
    ADD CONSTRAINT gtcmaterialhistory_currentprefixid_fkey FOREIGN KEY (currentprefixid) REFERENCES gtcprefixsuffix(prefixsuffixid);


--
-- Name: gtcmaterialhistory_currentseparatorid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterialhistory
    ADD CONSTRAINT gtcmaterialhistory_currentseparatorid_fkey FOREIGN KEY (currentseparatorid) REFERENCES gtcseparator(separatorid);


--
-- Name: gtcmaterialhistory_currentsuffixid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterialhistory
    ADD CONSTRAINT gtcmaterialhistory_currentsuffixid_fkey FOREIGN KEY (currentsuffixid) REFERENCES gtcprefixsuffix(prefixsuffixid);


--
-- Name: gtcmaterialhistory_fieldid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterialhistory
    ADD CONSTRAINT gtcmaterialhistory_fieldid_fkey FOREIGN KEY (fieldid, subfieldid) REFERENCES gtctag(fieldid, subfieldid);


--
-- Name: gtcmaterialhistory_previousprefixid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterialhistory
    ADD CONSTRAINT gtcmaterialhistory_previousprefixid_fkey FOREIGN KEY (previousprefixid) REFERENCES gtcprefixsuffix(prefixsuffixid);


--
-- Name: gtcmaterialhistory_previousseparatorid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterialhistory
    ADD CONSTRAINT gtcmaterialhistory_previousseparatorid_fkey FOREIGN KEY (previousseparatorid) REFERENCES gtcseparator(separatorid);


--
-- Name: gtcmaterialhistory_previoussufixxid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmaterialhistory
    ADD CONSTRAINT gtcmaterialhistory_previoussufixxid_fkey FOREIGN KEY (previoussuffixid) REFERENCES gtcprefixsuffix(prefixsuffixid);


--
-- Name: gtcmylibrary_mylibraryid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcmylibrary
    ADD CONSTRAINT gtcmylibrary_mylibraryid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: gtcnews_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcnews
    ADD CONSTRAINT gtcnews_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtcnewsaccess_linkid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcnewsaccess
    ADD CONSTRAINT gtcnewsaccess_linkid_fkey FOREIGN KEY (linkid) REFERENCES baslink(linkid);


--
-- Name: gtcnewsaccess_newsid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcnewsaccess
    ADD CONSTRAINT gtcnewsaccess_newsid_fkey FOREIGN KEY (newsid) REFERENCES gtcnews(newsid);


--
-- Name: gtcoperatorlibraryunit_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcoperatorlibraryunit
    ADD CONSTRAINT gtcoperatorlibraryunit_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtcpenalty_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcpenalty
    ADD CONSTRAINT gtcpenalty_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtcpenalty_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcpenalty
    ADD CONSTRAINT gtcpenalty_personid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: gtcpersonconfig_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcpersonconfig
    ADD CONSTRAINT gtcpersonconfig_personid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: gtcpersonlibraryunit_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcpersonlibraryunit
    ADD CONSTRAINT gtcpersonlibraryunit_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtcpersonlibraryunit_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcpersonlibraryunit
    ADD CONSTRAINT gtcpersonlibraryunit_personid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: gtcpolicy_linkid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcpolicy
    ADD CONSTRAINT gtcpolicy_linkid_fkey FOREIGN KEY (linkid) REFERENCES baslink(linkid);


--
-- Name: gtcpolicy_materialgenderid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcpolicy
    ADD CONSTRAINT gtcpolicy_materialgenderid_fkey FOREIGN KEY (materialgenderid) REFERENCES gtcmaterialgender(materialgenderid);


--
-- Name: gtcpolicy_privilegegroupid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcpolicy
    ADD CONSTRAINT gtcpolicy_privilegegroupid_fkey FOREIGN KEY (privilegegroupid) REFERENCES gtcprivilegegroup(privilegegroupid);


--
-- Name: gtcprecatalogue_prefixid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcprecatalogue
    ADD CONSTRAINT gtcprecatalogue_prefixid_fkey FOREIGN KEY (prefixid) REFERENCES gtcprefixsuffix(prefixsuffixid);


--
-- Name: gtcprecatalogue_separatorid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcprecatalogue
    ADD CONSTRAINT gtcprecatalogue_separatorid_fkey FOREIGN KEY (separatorid) REFERENCES gtcseparator(separatorid);


--
-- Name: gtcprecatalogue_suffixid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcprecatalogue
    ADD CONSTRAINT gtcprecatalogue_suffixid_fkey FOREIGN KEY (suffixid) REFERENCES gtcprefixsuffix(prefixsuffixid);


--
-- Name: gtcprefixsuffix_fieldid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcprefixsuffix
    ADD CONSTRAINT gtcprefixsuffix_fieldid_fkey FOREIGN KEY (fieldid, subfieldid) REFERENCES gtctag(fieldid, subfieldid);


--
-- Name: gtcpurchaserequest_controlnumber_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcpurchaserequest
    ADD CONSTRAINT gtcpurchaserequest_controlnumber_fkey FOREIGN KEY (controlnumber) REFERENCES gtcmaterialcontrol(controlnumber);


--
-- Name: gtcpurchaserequest_costcenterid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcpurchaserequest
    ADD CONSTRAINT gtcpurchaserequest_costcenterid_fkey FOREIGN KEY (costcenterid) REFERENCES gtccostcenter(costcenterid);


--
-- Name: gtcpurchaserequest_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcpurchaserequest
    ADD CONSTRAINT gtcpurchaserequest_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtcpurchaserequest_purchaserequestid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcpurchaserequest
    ADD CONSTRAINT gtcpurchaserequest_purchaserequestid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: gtcpurchaserequestmaterial_gtctag_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcpurchaserequestmaterial
    ADD CONSTRAINT gtcpurchaserequestmaterial_gtctag_fkey FOREIGN KEY (fieldid, subfieldid) REFERENCES gtctag(fieldid, subfieldid);


--
-- Name: gtcpurchaserequestmaterial_purchaserequestid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcpurchaserequestmaterial
    ADD CONSTRAINT gtcpurchaserequestmaterial_purchaserequestid_fkey FOREIGN KEY (purchaserequestid) REFERENCES gtcpurchaserequest(purchaserequestid);


--
-- Name: gtcpurchaserequestquotation_purchaserequestid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcpurchaserequestquotation
    ADD CONSTRAINT gtcpurchaserequestquotation_purchaserequestid_fkey FOREIGN KEY (purchaserequestid) REFERENCES gtcpurchaserequest(purchaserequestid);


--
-- Name: gtcrenew_loanid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcrenew
    ADD CONSTRAINT gtcrenew_loanid_fkey FOREIGN KEY (loanid) REFERENCES gtcloan(loanid);


--
-- Name: gtcrenew_renewtypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcrenew
    ADD CONSTRAINT gtcrenew_renewtypeid_fkey FOREIGN KEY (renewtypeid) REFERENCES gtcrenewtype(renewtypeid);


--
-- Name: gtcreportparameter_reportid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcreportparameter
    ADD CONSTRAINT gtcreportparameter_reportid_fkey FOREIGN KEY (reportid) REFERENCES gtcreport(reportid);


--
-- Name: gtcrequestchangeexemplarysta_requestchangeexemplarystatus_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcrequestchangeexemplarystatusstatushistory
    ADD CONSTRAINT gtcrequestchangeexemplarysta_requestchangeexemplarystatus_fkey1 FOREIGN KEY (requestchangeexemplarystatusstatusid) REFERENCES gtcrequestchangeexemplarystatusstatus(requestchangeexemplarystatusstatusid);


--
-- Name: gtcrequestchangeexemplarysta_requestchangeexemplarystatus_fkey2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcrequestchangeexemplarystatuscomposition
    ADD CONSTRAINT gtcrequestchangeexemplarysta_requestchangeexemplarystatus_fkey2 FOREIGN KEY (requestchangeexemplarystatusid) REFERENCES gtcrequestchangeexemplarystatus(requestchangeexemplarystatusid);


--
-- Name: gtcrequestchangeexemplarystat_exemplaryfuturestatusdefined_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcrequestchangeexemplarystatuscomposition
    ADD CONSTRAINT gtcrequestchangeexemplarystat_exemplaryfuturestatusdefined_fkey FOREIGN KEY (exemplaryfuturestatusdefinedid) REFERENCES gtcexemplaryfuturestatusdefined(exemplaryfuturestatusdefinedid);


--
-- Name: gtcrequestchangeexemplarystat_requestchangeexemplarystatus_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcrequestchangeexemplarystatusstatushistory
    ADD CONSTRAINT gtcrequestchangeexemplarystat_requestchangeexemplarystatus_fkey FOREIGN KEY (requestchangeexemplarystatusid) REFERENCES gtcrequestchangeexemplarystatus(requestchangeexemplarystatusid);


--
-- Name: gtcrequestchangeexemplarystatus_futurestatusid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcrequestchangeexemplarystatus
    ADD CONSTRAINT gtcrequestchangeexemplarystatus_futurestatusid_fkey FOREIGN KEY (futurestatusid) REFERENCES gtcexemplarystatus(exemplarystatusid);


--
-- Name: gtcrequestchangeexemplarystatus_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcrequestchangeexemplarystatus
    ADD CONSTRAINT gtcrequestchangeexemplarystatus_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtcrequestchangeexemplarystatus_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcrequestchangeexemplarystatus
    ADD CONSTRAINT gtcrequestchangeexemplarystatus_personid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: gtcrequestchangeexemplarystatusaccess_baslinkid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcrequestchangeexemplarystatusaccess
    ADD CONSTRAINT gtcrequestchangeexemplarystatusaccess_baslinkid_fkey FOREIGN KEY (baslinkid) REFERENCES baslink(linkid);


--
-- Name: gtcrequestchangeexemplarystatusaccess_exemplarystatusid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcrequestchangeexemplarystatusaccess
    ADD CONSTRAINT gtcrequestchangeexemplarystatusaccess_exemplarystatusid_fkey FOREIGN KEY (exemplarystatusid) REFERENCES gtcexemplarystatus(exemplarystatusid);


--
-- Name: gtcreserve_libraryunitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcreserve
    ADD CONSTRAINT gtcreserve_libraryunitid_fkey FOREIGN KEY (libraryunitid) REFERENCES gtclibraryunit(libraryunitid);


--
-- Name: gtcreserve_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcreserve
    ADD CONSTRAINT gtcreserve_personid_fkey FOREIGN KEY (personid) REFERENCES basperson(personid);


--
-- Name: gtcreserve_reservestatusid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcreserve
    ADD CONSTRAINT gtcreserve_reservestatusid_fkey FOREIGN KEY (reservestatusid) REFERENCES gtcreservestatus(reservestatusid);


--
-- Name: gtcreserve_reservetypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcreserve
    ADD CONSTRAINT gtcreserve_reservetypeid_fkey FOREIGN KEY (reservetypeid) REFERENCES gtcreservetype(reservetypeid);


--
-- Name: gtcreservecomposition_reserveid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcreservecomposition
    ADD CONSTRAINT gtcreservecomposition_reserveid_fkey FOREIGN KEY (reserveid) REFERENCES gtcreserve(reserveid);


--
-- Name: gtcreservestatushistory_reserveid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcreservestatushistory
    ADD CONSTRAINT gtcreservestatushistory_reserveid_fkey FOREIGN KEY (reserveid) REFERENCES gtcreserve(reserveid);


--
-- Name: gtcreservestatushistory_reservestatusid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcreservestatushistory
    ADD CONSTRAINT gtcreservestatushistory_reservestatusid_fkey FOREIGN KEY (reservestatusid) REFERENCES gtcreservestatus(reservestatusid);


--
-- Name: gtcreturnregister_returntypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcreturnregister
    ADD CONSTRAINT gtcreturnregister_returntypeid_fkey FOREIGN KEY (returntypeid) REFERENCES gtcreturntype(returntypeid);


--
-- Name: gtcright_linkid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcright
    ADD CONSTRAINT gtcright_linkid_fkey FOREIGN KEY (linkid) REFERENCES baslink(linkid);


--
-- Name: gtcright_materialgenderid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcright
    ADD CONSTRAINT gtcright_materialgenderid_fkey FOREIGN KEY (materialgenderid) REFERENCES gtcmaterialgender(materialgenderid);


--
-- Name: gtcright_operationid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcright
    ADD CONSTRAINT gtcright_operationid_fkey FOREIGN KEY (operationid) REFERENCES gtcoperation(operationid);


--
-- Name: gtcright_privilegegroupid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcright
    ADD CONSTRAINT gtcright_privilegegroupid_fkey FOREIGN KEY (privilegegroupid) REFERENCES gtcprivilegegroup(privilegegroupid);


--
-- Name: gtcrulesformaterialmovement_currentstate_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcrulesformaterialmovement
    ADD CONSTRAINT gtcrulesformaterialmovement_currentstate_fkey FOREIGN KEY (currentstate) REFERENCES gtcexemplarystatus(exemplarystatusid);


--
-- Name: gtcrulesformaterialmovement_futurestate_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcrulesformaterialmovement
    ADD CONSTRAINT gtcrulesformaterialmovement_futurestate_fkey FOREIGN KEY (futurestate) REFERENCES gtcexemplarystatus(exemplarystatusid);


--
-- Name: gtcrulesformaterialmovement_locationformaterialmovementid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcrulesformaterialmovement
    ADD CONSTRAINT gtcrulesformaterialmovement_locationformaterialmovementid_fkey FOREIGN KEY (locationformaterialmovementid) REFERENCES gtclocationformaterialmovement(locationformaterialmovementid);


--
-- Name: gtcrulesformaterialmovement_operationid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcrulesformaterialmovement
    ADD CONSTRAINT gtcrulesformaterialmovement_operationid_fkey FOREIGN KEY (operationid) REFERENCES gtcoperation(operationid);


--
-- Name: gtcscheduletask_schedulecycleid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcscheduletask
    ADD CONSTRAINT gtcscheduletask_schedulecycleid_fkey FOREIGN KEY (schedulecycleid) REFERENCES gtcschedulecycle(schedulecycleid);


--
-- Name: gtcscheduletask_taskid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcscheduletask
    ADD CONSTRAINT gtcscheduletask_taskid_fkey FOREIGN KEY (taskid) REFERENCES gtctask(taskid);


--
-- Name: gtcscheduletasklog_scheduletaskid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcscheduletasklog
    ADD CONSTRAINT gtcscheduletasklog_scheduletaskid_fkey FOREIGN KEY (scheduletaskid) REFERENCES gtcscheduletask(scheduletaskid);


--
-- Name: gtcsearchablefieldaccess_linkid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcsearchablefieldaccess
    ADD CONSTRAINT gtcsearchablefieldaccess_linkid_fkey FOREIGN KEY (linkid) REFERENCES baslink(linkid);


--
-- Name: gtcsearchablefieldaccess_searchablefieldid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcsearchablefieldaccess
    ADD CONSTRAINT gtcsearchablefieldaccess_searchablefieldid_fkey FOREIGN KEY (searchablefieldid) REFERENCES gtcsearchablefield(searchablefieldid);


--
-- Name: gtcsearchformataccess_linkid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcsearchformataccess
    ADD CONSTRAINT gtcsearchformataccess_linkid_fkey FOREIGN KEY (linkid) REFERENCES baslink(linkid);


--
-- Name: gtcsearchformataccess_searchformatid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcsearchformataccess
    ADD CONSTRAINT gtcsearchformataccess_searchformatid_fkey FOREIGN KEY (searchformatid) REFERENCES gtcsearchformat(searchformatid);


--
-- Name: gtcsearchformatcolumn_searchformatid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcsearchformatcolumn
    ADD CONSTRAINT gtcsearchformatcolumn_searchformatid_fkey FOREIGN KEY (searchformatid) REFERENCES gtcsearchformat(searchformatid);


--
-- Name: gtcsearchpresentationformat_searchformatid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcsearchpresentationformat
    ADD CONSTRAINT gtcsearchpresentationformat_searchformatid_fkey FOREIGN KEY (searchformatid) REFERENCES gtcsearchformat(searchformatid);


--
-- Name: gtcseparator_cataloguingformatid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcseparator
    ADD CONSTRAINT gtcseparator_cataloguingformatid_fkey FOREIGN KEY (cataloguingformatid) REFERENCES gtccataloguingformat(cataloguingformatid);


--
-- Name: gtcsoapaccess_soapclientid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcsoapaccess
    ADD CONSTRAINT gtcsoapaccess_soapclientid_fkey FOREIGN KEY (soapclientid) REFERENCES gtcsoapclient(soapclientid);


--
-- Name: gtcsoapaccess_webserviceid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcsoapaccess
    ADD CONSTRAINT gtcsoapaccess_webserviceid_fkey FOREIGN KEY (webserviceid) REFERENCES gtcwebservice(webserviceid);


--
-- Name: gtcsuppliertypeandlocation_supplierid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcsuppliertypeandlocation
    ADD CONSTRAINT gtcsuppliertypeandlocation_supplierid_fkey FOREIGN KEY (supplierid) REFERENCES gtcsupplier(supplierid);


--
-- Name: gtcworkflowhistory_workflowinstanceid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcworkflowhistory
    ADD CONSTRAINT gtcworkflowhistory_workflowinstanceid_fkey FOREIGN KEY (workflowinstanceid) REFERENCES gtcworkflowinstance(workflowinstanceid);


--
-- Name: gtcworkflowhistory_workflowstatusid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcworkflowhistory
    ADD CONSTRAINT gtcworkflowhistory_workflowstatusid_fkey FOREIGN KEY (workflowstatusid) REFERENCES gtcworkflowstatus(workflowstatusid);


--
-- Name: gtcworkflowinstance_workflowstatusid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcworkflowinstance
    ADD CONSTRAINT gtcworkflowinstance_workflowstatusid_fkey FOREIGN KEY (workflowstatusid) REFERENCES gtcworkflowstatus(workflowstatusid);


--
-- Name: gtcworkflowtransition_nextworkflowstatusid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcworkflowtransition
    ADD CONSTRAINT gtcworkflowtransition_nextworkflowstatusid_fkey FOREIGN KEY (nextworkflowstatusid) REFERENCES gtcworkflowstatus(workflowstatusid);


--
-- Name: gtcworkflowtransition_previousworkflowstatusid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gtcworkflowtransition
    ADD CONSTRAINT gtcworkflowtransition_previousworkflowstatusid_fkey FOREIGN KEY (previousworkflowstatusid) REFERENCES gtcworkflowstatus(workflowstatusid);


--
-- Name: miolo_access_idtransaction_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY miolo_access
    ADD CONSTRAINT miolo_access_idtransaction_fkey FOREIGN KEY (idtransaction) REFERENCES miolo_transaction(idtransaction);


--
-- Name: miolo_groupuser_idgroup_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY miolo_groupuser
    ADD CONSTRAINT miolo_groupuser_idgroup_fkey FOREIGN KEY (idgroup) REFERENCES miolo_group(idgroup);


--
-- Name: miolo_groupuser_iduser_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY miolo_groupuser
    ADD CONSTRAINT miolo_groupuser_iduser_fkey FOREIGN KEY (iduser) REFERENCES miolo_user(iduser);


--
-- Name: miolo_schedule_idmodule_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY miolo_schedule
    ADD CONSTRAINT miolo_schedule_idmodule_fkey FOREIGN KEY (idmodule) REFERENCES miolo_module(idmodule);


--
-- Name: miolo_session_iduser_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY miolo_session
    ADD CONSTRAINT miolo_session_iduser_fkey FOREIGN KEY (iduser) REFERENCES miolo_user(iduser);


--
-- Name: miolo_transaction_idmodule_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY miolo_transaction
    ADD CONSTRAINT miolo_transaction_idmodule_fkey FOREIGN KEY (idmodule) REFERENCES miolo_module(idmodule);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

