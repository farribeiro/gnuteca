CREATE OR REPLACE FUNCTION compareyearperiod(searchcontent varchar , field1 varchar , field2 varchar) 
RETURNS bool as $BODY$
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

$BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION corrigeindicadores() 
RETURNS bool as $BODY$
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

$BODY$ language plpgsql;


SELECT * FROM drop_function_if_exists('get_multa','p_fineid int4');
DROP TYPE IF EXISTS TYPE_MULTA;
CREATE TYPE TYPE_MULTA AS
(
    personid int,
    loanid int,
    begindate timestamp without time zone,
    value numeric(10,2),
    observation text,
    waspaid boolean,
    fineid int,
    operator varchar,
    allowance boolean,
    allowancejustify text,
    enddate timestamp without time zone,
    returnoperator varchar,
    slipthrough boolean
);

CREATE OR REPLACE FUNCTION get_multa(p_fineid int4) 
RETURNS SETOF type_multa as $BODY$
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
$BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION getrelated( int4) 
RETURNS varchar as $BODY$
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

$BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION getsearchcontenttoyearcompare( varchar ,  bool) 
RETURNS varchar as $BODY$
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

$BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION getsuggestionmaterial() 
RETURNS SETOF type_suggestion_material as $BODY$
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
$BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION gtc_chk_domain(p_domain varchar , p_key varchar) 
RETURNS bool as $BODY$
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
$BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION gtc_chk_parameter(p_parameter text) 
RETURNS bool as $BODY$
DECLARE
    v_result boolean;
BEGIN
        SELECT INTO v_result count(*) > 0 FROM basConfig WHERE parameter = p_parameter;
        
        RETURN v_result;
END;
$BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION gtcfnc_updatesearchmaterialviewtable() 
RETURNS trigger as $BODY$
            BEGIN

                DELETE FROM gtcSearchMaterialView;
                INSERT INTO gtcSearchMaterialView SELECT * FROM searchMaterialView;

                DELETE FROM gtcSearchTableUpdateControl;
                INSERT INTO gtcSearchTableUpdateControl (lastUpdate) values (now());

                RETURN OLD;
            END;
        $BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION gtcfnc_updatesearchmaterialviewtablebool() 
RETURNS bool as $BODY$
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
$BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION gtcfncupdatematerialson() 
RETURNS trigger as $BODY$
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
$BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION gtcgnccheckhelp() 
RETURNS trigger as $BODY$
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
$BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION upd_pagar_multa(p_codigo_da_multa int4 , p_operador varchar) 
RETURNS bool as $BODY$
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
$BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION preparetopographicindex(content varchar , complement varchar) 
RETURNS varchar as $BODY$
DECLARE
    result varchar;
    number integer;
BEGIN
    --tira acentos e converte pra minusculas e adiciona | como terminador de string.
    result := lower ( unaccent ( trim( content ) ) ) || '|';
    --separa somente números
    number :=  CASE WHEN substr( regexp_replace(result,'[^0-9]','','g'),0,4) <> '' then substr( regexp_replace(result,'[^0-9]','','g'),0,4)::integer ELSE 0 END;
    --troca caracteres especiais números e letras
    /**
        Exemplo de precedência que deve ser levado em conta, vide #12268 :
        658.012.4+657 -> + vem primeiro
        658.012.4/.5 -> / vem segundo
        658.012.4 -> Numeros inteiros em terceiro
        658.012.4:266 -> : depois dos números inteiros
    */
    result := translate( result, '+/|:=(-."0123456789', 'ABCDEGHFIJKLMNOPQRS');
    --tratamento da excessão (0 => EI deve vir após (1/9 => EJ/9
    result := replace( result, 'EI','ES');

    --Trata a excessão quando o termo >= 820 e < 900 o (1/9 => E[JKLMNOPQR] vai depois do . => H (I))
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
$BODY$ language plpgsql;


SELECT * FROM drop_function_if_exists('sea_bibliography_data','p_controlnumber int4 , p_content varchar , p_libraryunit int4 , p_tags varchar');
DROP TYPE TYPE_BIBLIOGRAPHY_DATA;
CREATE TYPE TYPE_BIBLIOGRAPHY_DATA AS
(
    controlnumber int,
    fieldid varchar,
    subfieldid varchar,
    content varchar
);

CREATE OR REPLACE FUNCTION sea_bibliography_data(p_controlnumber int4 , p_content varchar , p_libraryunit int4 , p_tags varchar) 
RETURNS SETOF type_bibliography_data as $BODY$
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
$BODY$ language plpgsql;


SELECT * FROM drop_function_if_exists('sea_multas_em_aberto','p_codigo_da_pessoa int4');
DROP TYPE IF EXISTS type_multas_em_aberto;
CREATE TYPE type_multas_em_aberto AS (codigodamulta integer, codigodoemprestimo integer, valor numeric(10,2), observacao text, datahora timestamp );

CREATE OR REPLACE FUNCTION sea_multas_em_aberto(p_codigo_da_pessoa int4) 
RETURNS SETOF type_multas_em_aberto as $BODY$
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
$BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION unaccent( text) 
RETURNS text as $BODY$
BEGIN
    RETURN translate($1, 'áàâãäéèêëíìïóòôõöúùûüÁÀÂÃÄÉÈÊËÍÌÏÓÒÔÕÖÚÙÛÜçÇñÑ', 'aaaaaeeeeiiiooooouuuuAAAAAEEEEIIIOOOOOUUUUcCnN');
END;
$BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION upd_gerar_boleto_multa(p_codigo_da_multa int4 , p_operador varchar) 
RETURNS bool as $BODY$
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
$BODY$ language plpgsql;


SELECT * FROM drop_function_if_exists('gtcobterrestricoes','person int4');
DROP TYPE IF EXISTS type_obter_restricoes; 
CREATE TYPE type_obter_restricoes AS ( tipo text, quantidade bigint );

CREATE OR REPLACE FUNCTION gtcobterrestricoes(person int4) 
RETURNS SETOF type_obter_restricoes as $BODY$
DECLARE
BEGIN
    RETURN QUERY 
    SELECT 
            'Penalidade' AS "tipo",
            (   SELECT COUNT(*)
                FROM gtcpenalty
                WHERE coalesce( penaltyEndDate > now(), penaltyEndDate IS NULL )
                AND personid = person ) as "quantidade"
    UNION
            (
                SELECT 'Multas' AS "tipo",
                (  
                    SELECT COUNT(*)
                    FROM gtcfine f
                LEFT JOIN gtcloan l
                        ON f.loanid = l.loanid
                    WHERE finestatusid = ( SELECT value FROM basconfig WHERE parameter ='ID_FINESTATUS_OPEN' )::int
                    AND personid = person ) as "quantidade"
            )
    UNION
            (
                SELECT 'Empréstimos' AS "tipo",
                (
                    SELECT count(*)
                    FROM gtcloan
                    WHERE personid = person
                    AND returndate is null ) as "quantidade"
            );
END; 
$BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION gtcnadaconsta(person int4) 
RETURNS bool as $BODY$
DECLARE
    v_result boolean;
BEGIN
    SELECT into v_result SUM(quantidade) = 0 FROM gtcObterRestricoes(person);
    
    RETURN v_result;
END; 
$BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION prepareallsearchcontent() 
RETURNS bool as $BODY$
DECLARE
    vClassification varchar;
    vDate varchar;
BEGIN
    vClassification := value FROM basconfig WHERE parameter = 'MARC_CLASSIFICATION_TAG';
    vDate := value FROM basconfig WHERE parameter = 'CATALOGUE_DATE_FIELDS';

    --atualiza o searchContent de todos materiais para unaccent, conforme unaccent do PHP troca a + pelo A
    UPDATE gtcmaterial SET searchcontent = trim( upper( translate( unaccent( content ) ,'+', 'A') ) );

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

    -- atualiza as tags de data. Observação: na 3.2 tem que ser dd/mm/yyyy
    UPDATE gtcmaterial SET searchContent = to_char( content::date, 'YYYY-mm-dd')
    WHERE fieldid || '.' || subfieldid in ( SELECT regexp_split_to_table( vDate , ',') );

    return true;
END;
$BODY$ language plpgsql;

CREATE OR REPLACE FUNCTION preparesearchcontent(tag varchar , content varchar , complement varchar) 
RETURNS varchar as $BODY$
DECLARE
    isClassification integer;
    isDate integer;
BEGIN
    -- Controla casos onde a tag vem nula ou somente com ponto.
    IF length( tag ) > 1 
    THEN
        isClassification = position( tag in ( SELECT value FROM basconfig WHERE parameter = 'MARC_CLASSIFICATION_TAG' ) );

        IF isClassification > 0
        THEN
            return prepareTopographicIndex( content,complement );
        END IF;

        isDate = position( tag in ( SELECT value FROM basconfig WHERE parameter = 'CATALOGUE_DATE_FIELDS' ) );

        IF isDate > 0
        THEN
            return to_char( content::date, 'YYYY-mm-dd');
            --return to_char( content::date, 'dd/mm/yyyy'); --na 3.2 tem que ser dd/mm/yyyy
        END IF;
    END IF;

    return trim( upper( unaccent( translate( content ,'+', 'A') ) ) );
END;
$BODY$ language plpgsql;