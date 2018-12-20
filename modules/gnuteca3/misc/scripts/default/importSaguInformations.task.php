<?php
/**
 * <--- Copyright 2005-2011 de Solis - Cooperativa de Soluções Livres Ltda. e
 * Univates - Centro Universitário.
 * 
 * Este arquivo é parte do programa Gnuteca.
 * 
 * O Gnuteca é um software livre; você pode redistribuí-lo e/ou modificá-lo
 * dentro dos termos da Licença Pública Geral GNU como publicada pela Fundação
 * do Software Livre (FSF); na versão 2 da Licença.
 * 
 * Este programa é distribuído na esperança que possa ser útil, mas SEM
 * NENHUMA GARANTIA; sem uma garantia implícita de ADEQUAÇÃO a qualquer MERCADO
 * ou APLICAÇÃO EM PARTICULAR. Veja a Licença Pública Geral GNU/GPL em
 * português para maiores detalhes.
 * 
 * Você deve ter recebido uma cópia da Licença Pública Geral GNU, sob o título
 * "LICENCA.txt", junto com este programa, se não, acesse o Portal do Software
 * Público Brasileiro no endereço www.softwarepublico.gov.br ou escreva para a
 * Fundação do Software Livre (FSF) Inc., 51 Franklin St, Fifth Floor, Boston,
 * MA 02110-1301, USA --->
 * 
 * Script de importação de informações do Sagu
 *
 * @author Jader Osvino Fiegenbaum [jader@solis.coop.br]
 *
 * @version $Id$
 *
 * \b Maintainers \n
 * Jader Osvino Fiegenbaum [jader@solis.coop.br]
 *
 * @since
 * Class created on 10/09/2011
 *
 **/
class importSaguInformations extends GTask
{
    /**
     * METODO CONSTRUCT É OBRIGATÓRIO, POIS A CLASSE DE SCHEDULE TASK SEMPRE VAI PASSAR O $this->MIOLO COMO PARAMETRO
     *
     * @param OBJECT $this->MIOLO
     */
    function __construct($MIOLO, $myTaskId)
    {
        parent::__construct($MIOLO, $myTaskId);
    }


    /**
     * Método disparado na execução do agendador de tarefas
     *
     * @return boolean
     */
    public function execute()
    {
        $person = $this->parameters[0] == 'true';
        $link = $this->parameters[1] == 'true';
        $personLink = $this->parameters[2] == 'true';
        
    	//obtém as  configurações do sagu que estão no conf
        if ( strlen($this->MIOLO->getConf('db.sagu.user')) == 0 )
        {
            throw new Exception( _M("Faltando configuração da base do Sagu no miolo.conf",$this->module));
        }
        
        $conf = new stdClass();
        $conf->user = $this->MIOLO->getConf('db.sagu.user');
        $conf->password = $this->MIOLO->getConf('db.sagu.password');
        $conf->name = $this->MIOLO->getConf('db.sagu.name');
        $conf->host = $this->MIOLO->getConf('db.sagu.host');
        $conf->port = $this->MIOLO->getConf('db.sagu.port');

        $con = "dbname={$conf->name} 
                hostaddr={$conf->host} 
                user={$conf->user}\n";

        if ( strlen($conf->password) > 0 )
        {
            $con .= "password={$conf->password}\n";
        }

        if ( strlen($conf->port) > 0 )
        {
            $con .= "port={$conf->port}";
        }

        //conecta na base gnuteca3
        $dbGtc = $this->MIOLO->GetDatabase('gnuteca3');

        //inicia a transição
        $tr = $dbGtc->getTransaction(); //obtém transação
        $tr->begin(); //inicia a transação

        try
        {
            //importa as pessoas
            if ( $person )
            {
                $tr->conn->execute("ALTER TABLE basperson DISABLE TRIGGER ALL");
                $tr->conn->execute("DELETE FROM basperson"); //apaga todas pessoas

                //testa se pessoa já foi inserida
                $tr->conn->execute("CREATE FUNCTION gtcFnc_basPerson() RETURNS opaque AS '
                                    DECLARE
                                        personId_ INTEGER;
                                    BEGIN
                                        SELECT INTO personId_ personId
                                                FROM basPerson
                                                WHERE personId = NEW.personId;

                                        IF FOUND THEN
                                            RETURN NULL;
                                        END IF;

                                        RETURN NEW;
                                    END;
                                ' LANGUAGE 'plpgsql'");
                $tr->conn->execute("CREATE TRIGGER gtcTrg_basPerson BEFORE insert on basPerson for each row execute procedure gtcFnc_basPerson();");

                $tr->conn->execute($sql = "INSERT INTO basperson (SELECT  cmn_pessoas.personid, 
                                                        convert_to(cmn_pessoas.name::text, 'UTF8'),
                                                        convert_to(cmn_pessoas.city::text, 'UTF8'), 
                                                        convert_to(cmn_pessoas.zipcode::text, 'UTF8'), 
                                                        convert_to(cmn_pessoas.location::text, 'UTF8'), 
                                                        null,
                                                        convert_to(cmn_pessoas.complement::text, 'UTF8'), 
                                                        convert_to(cmn_pessoas.neighborhood::text, 'UTF8'), 
                                                        convert_to(cmn_pessoas.email::text, 'UTF8'),
                                                        convert_to(cmn_pessoas.password::text, 'UTF8'),
                                                        convert_to(cmn_pessoas.login::text, 'UTF8')

                                                    FROM dblink('{$con}'::text, 'SELECT DISTINCT personid, 
                                                                                                BP.name, 
                                                                                                BC.name, 
                                                                                                BP.zipcode,   
                                                                                                location,
                                                                                                null, 
                                                                                                complement, 
                                                                                                neighborhood, 
                                                                                                email, 
                                                                                                MU.m_password,
                                                                                                MU.login
                                                                                        FROM ONLY basperson BP 
                                                                                        LEFT JOIN miolo_user MU 
                                                                                            ON BP.miolousername = MU.login 
                                                                                        LEFT JOIN bascity BC
                                                                                            ON BC.cityid = BP.cityid'::text) cmn_pessoas(personid integer, 
                                                                                                                                        name character varying, 
                                                                                                                                        city character varying, 
                                                                                                                                        zipcode character varying, 
                                                                                                                                        location character varying, 
                                                                                                                                        number character varying, 
                                                                                                                                        complement character varying, 
                                                                                                                                        neighborhood text, 
                                                                                                                                        email character varying, 
                                                                                                                                        password varchar,
                                                                                                                                        login varchar))");
                $tr->conn->execute("DROP TRIGGER gtcTrg_basPerson ON basPerson");
                $tr->conn->execute("DROP FUNCTION gtcFnc_basPerson()");                                                      
                $tr->conn->execute("ALTER TABLE basperson ENABLE TRIGGER ALL");

                //apaga os telefones
                $tr->conn->execute("DELETE FROM basphone");

                //importa celular
                $tr->conn->execute("INSERT INTO basphone (SELECT DISTINCT personid,
                                                                            'CEL',
                                                                            phone
                                                                        FROM dblink('{$con}'::text, 'SELECT id as personid,
                                                                                                            fone_celular as phone
                                                                                                    FROM cmn_pessoas 
                                                                                                    WHERE fone_celular <> '''' '::text) cmn_pessoas(personid integer,
                                                                                                                                                    phone character varying))");
                //importa particular - residencial
                $tr->conn->execute("INSERT INTO basphone (SELECT DISTINCT personid,
                                                                            'RES',
                                                                            phone
                                                                        FROM dblink('{$con}'::text, 'SELECT id as personid,
                                                                                                            fone_particular as phone
                                                                                                    FROM cmn_pessoas
                                                                                                    WHERE fone_particular <> '''' '::text) cmn_pessoas(personid integer,
                                                                                                                                                        phone character varying))");

                //importa profissional
                $tr->conn->execute("INSERT INTO basphone (SELECT DISTINCT personid,
                                                                            'PRO',
                                                                            phone
                                                                        FROM dblink('{$con}'::text, 'SELECT id as personid,
                                                                                                            fone_profissional as phone
                                                                                                        FROM cmn_pessoas
                                                                                                    WHERE fone_profissional <> '''' '::text) cmn_pessoas(personid integer,
                                                                                                                                                            phone character varying))");

                //importa recado
                $tr->conn->execute("INSERT INTO basphone (SELECT DISTINCT personid,
                                                                            'REC',
                                                                            phone
                                                                        FROM dblink('{$con}'::text, 'SELECT id as personid,
                                                                                                            fone_recado as phone
                                                                                                    FROM cmn_pessoas
                                                                                                    WHERE fone_recado <> '''' '::text) cmn_pessoas(personid integer,
                                                                                                                                                    phone character varying))");
            }

            //importa os grupos
            if ( $link )
            {
                $tr->conn->execute("ALTER TABLE baslink DISABLE TRIGGER ALL"); //desabilita as chaves
                $tr->conn->execute("DELETE FROM baslink"); //apaga todos grupos
                $tr->conn->execute("INSERT INTO baslink (SELECT DISTINCT linkId,
                                                                            convert_to(description::text, 'UTF8'), 
                                                                            level
                                                                    FROM dblink('{$con}'::text, 'SELECT codigodogrupo as linkId,
                                                                                                        descricao as description,
                                                                                                        nivel as level
                                                                                                    FROM cmn_grupo'::text) cmn_grupo(linkId integer,
                                                                                                                                        description character varying,
                                                                                                                                        level integer))");
                $tr->conn->execute("ALTER TABLE baslink ENABLE TRIGGER ALL"); //ativa as chaves
            }
            
            //importa os vínculos
            //IMPORTANTE : Como o sagu permite o cadastro de vinculos duplicados por pessoa, o select que trás as informações do Sagu
            // obtem somente o vinculo com maior data de validade para a pessoa
            if ( $personLink )
            {
                $tr->conn->execute("ALTER TABLE baspersonlink DISABLE TRIGGER ALL"); //desabilita as chaves
                $tr->conn->execute("DELETE FROM baspersonlink"); //apaga todos vinculos
                $tr->conn->execute("INSERT INTO baspersonlink (SELECT DISTINCT personId,
                                                                                linkId,
                                                                                datevalidate
                                                                            FROM dblink('{$con}'::text, 'SELECT  codigodapessoa as personId, 
                                                                                                                    codigodogrupo as linkId, 
                                                                                                                    (CASE WHEN datavalidade IS NULL THEN now() + interval \'1 day\' ELSE datavalidade END) as datevalidate
                                                                                                        FROM 
                                                                                                        (
                                                                                                            SELECT DISTINCT 
                                                                                                                            codigodapessoa, 
                                                                                                                            codigodogrupo, 
                                                                                                                            ( SELECT max(datavalidade) FROM cmn_vinculo B WHERE a.codigodapessoa = b.codigodapessoa and a.codigodogrupo=b.codigodogrupo) as datavalidade  FROM cmn_vinculo A
                                                                                                        )as foo;'::text) cmn_vinculo(personId integer,
                                                                                                                                            linkId integer,
                                                                                                                                            datevalidate date))");
                $tr->conn->execute("ALTER TABLE baspersonlink ENABLE TRIGGER ALL"); //ativa as chaves
            }

            $tr->commit(); //commita a transação

        }
        catch( Exception $e )
        {
            $ok = $tr->rollback();
            throw $e; 
        }

        return true;
    }
}

?>