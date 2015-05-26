IF    (SELECT f_busca_codigo_cliente_asp()) NOT IN (28, 102, 135, 189, 89, 124, 144, 159, 215,231, 166, 202)
  AND (SELECT f_busca_codigo_cliente_asp()) < 239
THEN
  /*
    Os clientes 102, 135, 189, 89, 144  estão usando A versão da procedure DO ARQUIVO PR_CARNE_BANCO_CONTROLE_PORTADOR
    nesta, a geração do carne se baseia no PORTADOR DA PARCELA
  */
  DROP PROC pr_carne_banco_r;

  CREATE PROC pr_carne_banco_r(
    @IdTipoCarne          integer,
    @Banco                integer,
    @CdAgenciaPar         varchar(10),
    @CdContaCorrentePar   varchar(20),
    @comando              long varchar,
    @comando_order_by     long varchar,  -- estah sendo usada agora para como clausula Where na #temp_matricula
    @IdBancoGenerico      integer,
    @CdInstituicaoLogin   integer,
    @IdContraApresentacao integer,
    @IdEmiteNomeCurso     integer, -- 1) Boletos Unificados  ( /  2) Todos Boletos - Serie Curricular como Padrao ( aparece sempre o nome da curricular, se tiver /  3) Boletos vinculados a da Série
    @IdEndereco           integer,
    @CdUsuario            varchar(3)
  )

   /* IdTipoCarne -> Identifica qual momento esta sendo emitido o carne
      Caso seja 0 = Tela de Matricula botao CARNÊ
      Caso seja 1 = emissao normal
      Caso seja 2 = emissao normal modelo CARNE
      caso seja 3 = Emissao dos boletos de Titulos a receber
      caso seja 4 = Emissao dos Titulos a receber - CARNÊ

      @IdBancoGenerico usar ou nao o relacionamento da curso_turma
      Caso seja 0 = manter normal, tranzendo somente as turmas q usam o Banco do Parametro
      Caso seja 1 = Usar as variaveis Bco,Ag,CC dos parametros e trazer todas as turmas,
                    independentemente do que estiver parametrizado na bc/ag/cc da curso_turma

      @IdContraApresentacao 0 = Nao -> Mostrar entao a data de vencimento e tb calcula o fator de vencto no cod de barras
                            1 = Sim -> No boleto mostra "contra apresentacao" no lugar do vencimento e na hora do codigo de barras
                                         coloca a data de vencimento = 1997-10-07
   */

  BEGIN
    DECLARE @nrEventoBoleto            integer;
    DECLARE @dsPosto                   varchar(5);
    DECLARE @datainicio                datetime;
    DECLARE @dsMoeda                   varchar(10);
    DECLARE @NmBancoDados              varchar(100);
    DECLARE @CdCursoInstituicaoAnt     integer;
    DECLARE @DtPrimeiroDiaUtil         datetime;
    DECLARE @IdMensalidade             integer;
    DECLARE @idTipoFormaCobranca       integer;
    DECLARE @ComandoMatricula          long varchar;
    DECLARE @IdPessoa                  integer;
    DECLARE @IdRespFinanceiroMatricula integer;
    DECLARE @CdCursoInstituicao        integer;
    DECLARE @CdAluno                   integer;
    DECLARE @NmAluno                   varchar(256);
    DECLARE @DsNomeCursos              varchar(256);
    DECLARE @CdAnoExercicio            integer;
    DECLARE @NrMatricula               integer;
    DECLARE @NrDocumento               numeric(30);
    DECLARE @NrBloqueto                varchar(30);
    DECLARE @DtPrimeiraEmissao         datetime;
    DECLARE @NrControleEmissao         integer;
    DECLARE @NrBloquetoCalculo         varchar(30);
    DECLARE @NrBloquetoReal            varchar(30);
    DECLARE @NrBloquetoNovo            varchar(30);
    DECLARE @NrBloquetoBesc            varchar(30); -- usado apenas para calcular o Digito do Bloqueto do Banco Besc TRX-340
    DECLARE @NrBloquetoItau            varchar(30); -- usado apenas para calcular o Digito do Bloqueto do Banco Itau
    DECLARE @NrSeqBloqueto             varchar(30); -- usado apenas para calcular o Digito do Bloqueto do Banco Real
    DECLARE @NrBloquetoSant            varchar(30); -- usado apenas para calcular o Digito do Bloqueto do Banco Meridional Santander
    DECLARE @IdDocumento               integer;
    DECLARE @DtVencimento              DateTime;
    DECLARE @VlMensalidade             numeric(13,2);
    DECLARE @VlDesconto                numeric(13,2);
    DECLARE @IdResponsavelFinanceiro   integer;
    DECLARE @NrParcela                 integer;
    DECLARE @CdAtvdMsl                 integer;
    DECLARE @VlParcelaTotal            numeric(13,2);
    DECLARE @VlDescontoTotal           numeric(13,2);
    DECLARE @PctDescto                 numeric(13,2);
    DECLARE @DsAbreviacao              varchar(100);
    DECLARE @DsAbreviacaoEvento        varchar(100);
    DECLARE @DsAbreviacaoParcela       varchar(100);
    DECLARE @DsAbreviacaoParcelaEf     varchar(100);
    DECLARE @DsVariacaoEmissao         varchar(3);
    DECLARE @DsAbreviacaoDescto        varchar(100);
    DECLARE @DsParcelas                varchar(200);
    DECLARE @CdTurma                   varchar(5);
    DECLARE @DsInstrucoes              varchar(200);
    DECLARE @DsInstrucoesEf            varchar(200);
    DECLARE @cdBancoDebitoAuto         integer;
    DECLARE @nmBancoDebito             varchar(80);
    DECLARE @DsInstrucoesSemDesconto   varchar(200);
    DECLARE @DsEventoParcela           varchar(200);
    DECLARE @DsInstrucoesDescto        varchar(200);
    DECLARE @DsInstrucoesDesctoTotal   varchar(200);
    DECLARE @DsBairro                  varchar(20);
    DECLARE @CdCep                     integer;
    DECLARE @NrCpf                     varchar(20);
    DECLARE @NmResponsavel             varchar(50);
    DECLARE @DsComplemento             varchar(50);
    DECLARE @DsLogradouro              varchar(60);
    DECLARE @NmMunicipio               varchar(30);
    DECLARE @Uf                        varchar(2);
    DECLARE @CdAgencia                 varchar(10);
    DECLARE @CdContaCorrente           varchar(20);
    DECLARE @CdAgenciaBanco            varchar(10);
    DECLARE @CdContaCorrenteBanco      varchar(20);
    DECLARE @CdContaEmissaoAnt         varchar(20);
    DECLARE @NrTipoConta               varchar(5);
    DECLARE @DsCarteira                varchar(5);
    DECLARE @NrCnab                    integer;
    DECLARE @DsEspecie                 varchar(5);
    DECLARE @DsEspecieDoc              varchar(5);
    DECLARE @DsAceite                  varchar(5);
    DECLARE @DsContrato                varchar(15);
    DECLARE @DsCodigoBarras            varchar(44);
    DECLARE @DsCodigoBarrasAzalea      varchar(500);
    DECLARE @DsCodigoRepresentacao     varchar(100);
    DECLARE @DsDigitoBloqueto          varchar(1);
    DECLARE @DsDigitoBescCarne         varchar(1);
    DECLARE @NmInstituicao             varchar(40);
    DECLARE @dsEventos                 varchar(255);
    DECLARE @DsDadosAluno              varchar(255);
    DECLARE @DsMsg1                    varchar(255);
    DECLARE @DsMsg2                    varchar(255);
    DECLARE @DsMsg3                    varchar(255);
    DECLARE @DsMsg4                    varchar(255);
    DECLARE @DsMsg5                    varchar(255);
    DECLARE @DsMsg6                    varchar(255);
    DECLARE @DsMsg7                    varchar(255);
    DECLARE @DsMsg8                    varchar(255);
    DECLARE @DsMsg9                    varchar(255);
    DECLARE @DsMsg10                   varchar(255);
    DECLARE @DsMensagemAcrescimo       varchar(255);
    DECLARE @NrDiasFatorVencimento     integer;
    DECLARE @DsMsgDebito               varchar(200);
    DECLARE @IdDebitoAutomatico        integer;
    DECLARE @DsSituacaoTituloReceber   varchar(2);
    DECLARE @NrSequencia               integer;
    DECLARE @CdFonte                   integer;
    DECLARE @DsTitulo                  varchar(10);
    DECLARE @DsSerie                   varchar(5);
    DECLARE @ds_DtVencimento           varchar(15);
    DECLARE @NmInstituicaoBanco        varchar(5000);
    DECLARE @PcJuroMensal              numeric(13,4);
    DECLARE @PcJuroDiario              numeric(13,4);
    DECLARE @PcMulta                   numeric(13,4);
    DECLARE @IdRegraDesconto           integer;
    DECLARE @IdRegraDescontoBolsa      integer;
    DECLARE @DsMensagemAtraso          varchar(202);
    DECLARE @DsDoctosAtrasados         varchar(200);
    DECLARE @NrDoctosAtrasados         integer;
    DECLARE @DsDescPontualidade        varchar(255);
    DECLARE @CdBancoEmissao            integer;
    DECLARE @CdAgenciaemissao          varchar(10);
    DECLARE @CdContaEmissao            varchar(20);
    DECLARE @DsAnoVencto               varchar(1); -- Para uso na carteira 6 - TRX 340
    DECLARE @NrDiaPontualidade         integer;
    DECLARE @CdSituacaoParcela         integer;
    DECLARE @IdValorDocumento          integer;
    DECLARE @NrMensalidade             integer;
    DECLARE @DsParcelasRenegociadas    varchar(100);
    DECLARE @DsParcelasRenegociadasDoc varchar(100);
    DECLARE @DataHoje                  datetime;
    DECLARE @PcDescontoTotal           numeric(13,2);
    DECLARE @DsDigitoDesconto          integer;
    DECLARE @NmAgencia                 varchar(40);
    DECLARE @DsCarteiraEmissao         varchar(5);
    DECLARE @IdPodeEmitir              varchar(3);
    DECLARE @DsEspecieDocEmissao       varchar(5);
    DECLARE @CdInstituicaoEnsino       integer;
    DECLARE @VlDescontoBruto           numeric(13,2);
    DECLARE @VlTotalMensalidadeBruto   numeric(13,2);
    DECLARE @VlMensalidadeBruto        numeric(13,2);
    DECLARE @VlTaxaBancaria            numeric(13,2);

    DECLARE @DtVencimentoFixo1                 datetime;
    DECLARE @VlDescPontualidade1               numeric(13,2);
    DECLARE @VlTotalPagarPontualidade1         numeric(13,2);
    DECLARE @DsLiteralTotalEventoPontualidade1 varchar(255);

    DECLARE @DtVencimentoFixo2                 datetime;
    DECLARE @VlDescPontualidade2               numeric(13,2);
    DECLARE @VlTotalPagarPontualidade2         numeric(13,2);
    DECLARE @DsLiteralTotalEventoPontualidade2 varchar(255);

    DECLARE @DtVencimentoFixo3                 datetime;
    DECLARE @VlDescPontualidade3               numeric(13,2);
    DECLARE @VlTotalPagarPontualidade3         numeric(13,2);
    DECLARE @DsLiteralTotalEventoPontualidade3 varchar(255);

    DECLARE @DtVencimentoFixo4                 datetime;
    DECLARE @VlDescPontualidade4               numeric(13,2);
    DECLARE @VlTotalPagarPontualidade4         numeric(13,2);
    DECLARE @DsLiteralTotalEventoPontualidade4 varchar(255);

    DECLARE @DtVencimentoFixo5                 datetime;
    DECLARE @VlDescPontualidade5               numeric(13,2);
    DECLARE @VlTotalPagarPontualidade5         numeric(13,2);
    DECLARE @DsLiteralTotalEventoPontualidade5 varchar(255);

    DECLARE @DtVencimentoFixo6                 datetime;
    DECLARE @VlDescPontualidade6               numeric(13,2);
    DECLARE @VlTotalPagarPontualidade6         numeric(13,2);
    DECLARE @DsLiteralTotalEventoPontualidade6 varchar(255);

    DECLARE @pc_desconto_pontualidade1 numeric(6,3);
    DECLARE @nr_dias_pontualidade1     integer;
    DECLARE @id_tipo_pontualidade1     integer;
    DECLARE @pc_desconto_pontualidade2 numeric(6,3);
    DECLARE @nr_dias_pontualidade2     integer;
    DECLARE @id_tipo_pontualidade2     integer;
    DECLARE @pc_desconto_pontualidade3 numeric(6,3);
    DECLARE @nr_dias_pontualidade3     integer;
    DECLARE @id_tipo_pontualidade3     integer;
    DECLARE @pc_desconto_pontualidade4 numeric(6,3);
    DECLARE @nr_dias_pontualidade4     integer;
    DECLARE @id_tipo_pontualidade4     integer;
    DECLARE @pc_desconto_pontualidade5 numeric(6,3);
    DECLARE @nr_dias_pontualidade5     integer;
    DECLARE @id_tipo_pontualidade5     integer;
    DECLARE @pc_desconto_pontualidade6 numeric(6,3);
    DECLARE @nr_dias_pontualidade6     integer;
    DECLARE @id_tipo_pontualidade6     integer;

    DECLARE @DtVencimentoComFator datetime;

    DECLARE @VlTotalApenasPontualidade1 numeric(13,2);
    DECLARE @VlTotalApenasPontualidade2 numeric(13,2);
    DECLARE @VlTotalApenasPontualidade3 numeric(13,2);
    DECLARE @VlTotalApenasPontualidade4 numeric(13,2);
    DECLARE @VlTotalApenasPontualidade5 numeric(13,2);
    DECLARE @VlTotalApenasPontualidade6 numeric(13,2);

    DECLARE @DsConvenio         varchar(40);
    DECLARE @PcConvenio         numeric(13,2);
    DECLARE @VlDescontoConvenio numeric(13,2);
    DECLARE @DsMensagemConvenio varchar(255);

    DECLARE @DsDescontoComercial  varchar(256);
    DECLARE @DsDescontoBolsa      varchar(256);
    DECLARE @VlDescComercialTotal numeric(13,2);
    DECLARE @VlDescComercial      numeric(13,2);

    DECLARE @VlBasedeCalculo decimal(13,2);

    DECLARE @DsMsgPontualidade1 varchar(255);
    DECLARE @DsMsgPontualidade2 varchar(255);
    DECLARE @DsMsgPontualidade3 varchar(255);
    DECLARE @DsMsgPontualidade4 varchar(255);
    DECLARE @DsMsgPontualidade5 varchar(255);
    DECLARE @DsMsgPontualidade6 varchar(255);

    DECLARE @icAplicarRenegociacao integer;

    DECLARE @nm_fantasia           varchar(50);
    DECLARE @nm_instituicao_ensino varchar(100);
    DECLARE @nr_cgc_ie             varchar(40);
    DECLARE @cd_orgao_regulador    integer;
    DECLARE @cd_regional           integer;
    DECLARE @cd_instituicao_ensino integer;
    DECLARE @nm_mantenedora        varchar(100);
    DECLARE @nr_telefone_ie        varchar(15);

    DECLARE @IdRegistroCarteira integer; -- 0-Sem Registro /  1-Com Registro

    DECLARE @NmEventoMensalidade        varchar(50);
    DECLARE @NrParcelaMensalidade       integer;
    DECLARE @NrTotalParcelasMensalidade integer;

    DECLARE @CdBolsa                 integer;
    DECLARE @DsBolsa                 varchar(100);
    DECLARE @DsBolsaAluno            varchar(200);
    DECLARE @VlBolsaAluno            numeric(13,2);
    DECLARE @VlBolsa                 numeric(13,2);
    DECLARE @IcPermiteEmitirAdotador varchar(1);
    DECLARE @dsTipoImpressao         varchar(5);
    DECLARE @DsVariacao              varchar(10);
    DECLARE @DsISS                   varchar(255);
    DECLARE @DsObsParcela            varchar(255);
    DECLARE @DsObsParcelaBoleto      varchar(255);
    DECLARE @idAtualizarVencimento   varchar(10);
    DECLARE @icRegraPontualidade     tinyint;

    DECLARE @VlTotalDescPontualidade1 numeric(13,2);
    DECLARE @VlTotalDescPontualidade2 numeric(13,2);
    DECLARE @VlTotalDescPontualidade3 numeric(13,2);
    DECLARE @VlTotalDescPontualidade4 numeric(13,2);
    DECLARE @VlTotalDescPontualidade5 numeric(13,2);
    DECLARE @VlTotalDescPontualidade6 numeric(13,2);

    DECLARE @ds_logradouro_ie varchar(100);
    DECLARE @nm_bairro_ie     varchar(100);
    DECLARE @nm_municipio_ie  varchar(100);
    DECLARE @cd_uf_ie         varchar(2);
    DECLARE @cd_cep_ie        integer;
    DECLARE @ds_complemento_ie varchar(100);

    DECLARE c_mensalidade DYNAMIC SCROLL CURSOR FOR
      SELECT cd_curso_instituicao,
             cd_aluno,
             cd_ano_exercicio,
             nr_matricula,
             nr_documento,
             Id_responsavel_financeiro,
             cd_banco_emissao,
             cd_agencia_emissao,
             cd_conta_emissao,
             trim(ds_carteira_emissao),
             trim(ds_especie_doc),
             min(id_resp_financeiro_matricula),
             id_tipo_forma_cobranca,
             ds_msg_banco
      FROM #temp_rel
      GROUP BY cd_curso_instituicao,
               cd_aluno,
               cd_ano_exercicio,
               nr_matricula,
               nr_documento,
               Id_responsavel_financeiro,
               cd_banco_emissao,
               cd_agencia_emissao,
               cd_conta_emissao,
               trim(ds_carteira_emissao),
               trim(ds_especie_doc),
               id_tipo_forma_cobranca,
               ds_msg_banco
      ORDER BY 1,2,3,4,5
      FOR READ ONLY;

    DECLARE c_titulo_receber DYNAMIC SCROLL CURSOR FOR
      SELECT nr_documento,
             nr_sequencia,
             cd_fonte,
             id_fonte
      FROM #temp_rel_receber
      ORDER BY 1,2,3,4
      FOR READ ONLY;

    DECLARE c_parcela DYNAMIC SCROLL CURSOR FOR
      SELECT vl_mensalidade_msl,
             vl_desconto_msl,
             cd_documento,
             cd_atvd_secundaria_msl,
             nr_parcela_msl,
             nr_bloqueto,
             dt_vencimento_msl,
             dt_primeira_emissao,
             nr_controle_emissao,
             cd_situacao,
             nr_mensalidade,
             cd_bolsa,
             vl_desconto_bolsa,
             id_mensalidade,
             obs_estorno
      FROM mensalidade
      WHERE cd_situacao  IN (1,13,15,23,27)
      AND id_responsavel_financeiro   NOT IN (5,6)
        AND nr_documento = @NrDocumento
      ORDER BY 3,5,4
      FOR READ ONLY;

    CREATE TABLE #temp_carne (
      DsInstrucoes               varchar(200)  NULL,
      nm_aluno                   varchar(50)   NULL,
      nm_curso                   varchar(50)   NULL,
      nr_matricula               integer       NULL,
      pc_juro_mensal             numeric(6,2)  NULL,
      pc_juro_diario             numeric(6,2)  NULL,
      pc_multa                   numeric(6,2)  NULL,
      dt_vencimento_msl          datetime      NULL,
      vl_mensalidade             numeric(13,2) NULL,
      vl_desconto                numeric(13,2) NULL,
      nr_documento               numeric(30)   NULL,
      cd_aluno                   integer       NULL,
      cd_ano_exercicio           integer       NULL,
      nr_bloqueto                varchar(30)   NULL,
      cd_turma                   varchar(20)   NULL,
      Ds_parcelas                varchar(100)  NULL,
      nm_fantasia                varchar(50)   NULL,
      nm_instituicao_ensino      varchar(40)   NULL,
      nr_cgc_ie                  varchar(40)   NULL,
      DsInstrucoesDesconto       varchar(200)  NULL,
      ds_logradouro_rsp          varchar(60)   NULL,
      nm_bairro                  varchar(50)   NULL,
      cd_cep_rsp                 integer       NULL,
      nr_cpf_rsp                 varchar(20)   NULL,
      nm_municipio               varchar(50)   NULL,
      cd_uf                      varchar(2)    NULL,
      nm_responsavel             varchar(50)   NULL,
      ds_complemento             varchar(50)   NULL,
      cd_agencia                 varchar(10)   NULL,
      cd_conta_corrente          varchar(20)   NULL,
      nr_tipo_conta              varchar(5)    NULL,
      ds_carteira                varchar(5)    NULL,
      ds_especie                 varchar(5)    NULL,
      ds_especie_doc             varchar(5)    NULL,
      ds_aceite                  varchar(5)    NULL,
      ds_codigobarras            varchar(500)  NULL,
      ds_codigorepresentacao     varchar(100)  NULL,
      id_regra_desconto          integer       NULL,
      Ds_Msg1                    varchar(255)  NULL,
      Ds_Msg2                    varchar(255)  NULL,
      Ds_Msg3                    varchar(255)  NULL,
      Ds_Msg4                    varchar(255)  NULL,
      Ds_Msg5                    varchar(255)  NULL,
      ds_msg_debito              varchar(255)  NULL,
      ds_contrato                varchar(15)   NULL,
      nm_instituicao_banco       varchar(5000) NULL,
      ds_codigo_barra_numero     varchar(50)   NULL,
      cd_orgao_regulador         integer       NULL,
      cd_regional                integer       NULL,
      cd_instituicao_ensino      integer       NULL,
      nm_mantenedora             varchar(100)  NULL,
      ds_tipo_curso              varchar(100)  NULL,
      ds_digito_bloqueto         varchar(20)   NULL,
      nm_agencia                 varchar(40)   NULL,
      Ds_Msg6                    varchar(255)  NULL,
      Ds_Msg7                    varchar(255)  NULL,
      Ds_Msg8                    varchar(255)  NULL,
      Ds_Msg9                    varchar(255)  NULL,
      Ds_Msg10                   varchar(255)  NULL,
      nr_telefone_ie             varchar(15)   NULL,
      dt_vencimento_com_fator    datetime      NULL,
      nr_fator_vencimento        integer       NULL,
      NmEventoMensalidade        varchar(50)   NULL,
      NrParcelaMensalidade       integer       NULL,
      NrTotalParcelasMensalidade integer       NULL,
      DtVencimentoFixo1          datetime      NULL,
      VlTotalApenasPontualidade1 numeric(13,2) NULL,
      DsDigitoBloqueto           varchar(10)   NULL,
      nr_cnab                    integer       NULL,
      ds_habilitacao             varchar(100)  NULL,
      vl_taxa_bancaria           numeric(15,2) NULL,
      ds_bolsas                  varchar(200)  NULL,
      vl_bolsa                   numeric(15,2) NULL,
      id_valor_documento         integer       NULL,
      cd_curso_instituicao       integer       NULL,
      ds_variacao                varchar(5)    NULL,
      NmBancoDados               varchar(30),
      ds_logradouro_ie           varchar(100)  NULL,
      nm_bairro_ie               varchar(100)  NULL,
      nm_municipio_ie            varchar(100)  NULL,
      cd_uf_ie                   varchar(2)    NULL,
      cd_cep_ie                  integer       NULL
    );

    CREATE TABLE #temp_matricula (
      cd_tipo_curso    integer,
      cd_aluno         integer,
      cd_ano_exercicio integer,
      nr_matricula     integer
    );

    CREATE TABLE #temp_rel (
      cd_curso_instituicao         integer,
      cd_aluno                     integer,
      cd_ano_exercicio             integer,
      nr_matricula                 integer,
      nr_documento                 numeric(30),
      id_responsavel_financeiro    integer,
      cd_banco_emissao             integer     NULL,
      cd_agencia_emissao           varchar(10) NULL,
      cd_conta_emissao             varchar(20) NULL,
      ds_carteira_emissao          varchar(5)  NULL,
      ds_especie_doc               varchar(10) NULL,
      id_resp_financeiro_matricula integer,
      id_tipo_forma_cobranca       integer,
      ds_msg_banco                 varchar(100) NULL
    );

    CREATE TABLE #temp_rel_receber (
      nr_documento numeric(30),
      nr_sequencia integer,
      cd_fonte     integer,
      id_fonte     integer
    );

    CREATE TABLE #tmp_parcelaRenegociacao (
      nr_parcela varchar(9)
    );

    SET @ComandoMatricula= @comando_order_by;
    SET @comando = F_TROCA_CARACTER (@comando, ';', '=');
    SET @comando = F_TROCA_CARACTER (@comando, '!', char(39));

    SET @comandoMatricula = F_TROCA_CARACTER (@comandoMatricula, ';', '=');
    SET @comandoMatricula = F_TROCA_CARACTER (@comandoMatricula , '!', char(39));

    EXECUTE IMMEDIATE '
      INSERT INTO #temp_matricula
      SELECT DISTINCT tc.cd_tipo_Curso,
             ma.cd_aluno,
             ma.cd_ano_exercicio,
             ma.nr_matricula
      FROM curso c,
           tipo_curso tc,
           curso_instituicao ci,
           aluno a,
           matricula_responsavel_financeiro mrf,
           matricula ma
      WHERE tc.cd_tipo_curso        = c.cd_tipo_curso
        AND c.cd_curso              = ci.cd_curso
        AND a.cd_aluno              = ma.cd_aluno
        AND ma.cd_ano_exercicio     = mrf.cd_ano_exercicio
        AND ma.cd_curso_instituicao = mrf.cd_curso_instituicao
        AND ma.cd_aluno             = mrf.cd_aluno
        AND ma.nr_matricula         = mrf.nr_matricula
        AND ci.cd_curso_instituicao = ma.cd_curso_instituicao ' || @ComandoMatricula;

    -- talvez um indice na temp_matricula

    SELECT upper(db_name(*)) INTO @NmBancoDados;

    SELECT getdate() INTO @DataHoje;

    SET @dsMoeda = 'R$';

    IF @NmBancoDados = 'BD01108' THEN
      SET @dsMoeda = 'Kz';
    END IF;

    IF @IdTipoCarne IN (0,1,2) THEN
      IF @IdTipoCarne = 0 THEN
        EXECUTE IMMEDIATE '
          INSERT INTO #temp_rel
          SELECT DISTINCT me.cd_curso_instituicao,
                 me.cd_aluno,
                 me.cd_ano_exercicio,
                 me.nr_matricula,
                 me.nr_documento,
                 me.id_responsavel_financeiro,
                 cas.cd_banco,
                 cas.cd_agencia,
                 cas.cd_conta_corrente,
                 cc.ds_carteira,
                 cc.ds_especie_doc,
                 me.id_resp_financeiro_matricula,
                 fc.id_tipo_forma_cobranca,
                 fc.ds_msg_banco
          FROM aluno a,
               curso_atividade_secundaria cas,
               curso c,
               tipo_curso tc,
               conta_corrente cc,
               curso_instituicao ci,
               matricula_responsavel_financeiro mrf,
               #temp_matricula ma,
               mensalidade me,
               forma_cobranca fc
          WHERE me.cd_forma_cobranca                = fc.cd_forma_cobranca
            AND fc.id_emissao_banco                 = 1
            AND fc.id_tipo_forma_cobranca           IN (3, 4, 11)
            AND tc.id_modalidade                    = 1
            AND tc.cd_tipo_curso                    = c.cd_tipo_curso
            AND me.cd_ano_exercicio                 = mrf.cd_ano_exercicio
            AND me.cd_curso_instituicao             = mrf.cd_curso_instituicao
            AND me.cd_aluno                         = mrf.cd_aluno
            AND me.nr_matricula                     = mrf.nr_matricula
            AND c.cd_curso                          = ci.cd_curso
            AND ci.cd_curso_instituicao             = me.cd_curso_instituicao
            AND cc.cd_conta_corrente                = cas.cd_conta_corrente
            AND cc.cd_agencia                       = cas.cd_agencia
            AND cc.cd_banco                         = cas.cd_banco
            AND cas.cd_banco                        = '|| @Banco || '
            AND me.cd_documento                    <> 10
            AND me.id_responsavel_financeiro   NOT IN (5,6)
            AND cas.cd_atividade_secundaria         = me.cd_atvd_secundaria_msl
            AND cas.cd_ano_exercicio                = me.cd_ano_exercicio
            AND cas.cd_curso_instituicao            = me.cd_curso_instituicao
            AND f_verificaParcelaCobranca(me.id_mensalidade, me.cd_situacao ) = 1 -- se estiver com a situação de cobraça. verifica se a empresa de cobrança permite a baixa
            AND tc.cd_tipo_curso                    = ma.cd_tipo_curso
            AND a.cd_aluno                          = ma.cd_aluno
            AND convert(varchar(10), me.dt_vencimento_msl, 103) IN (
              SELECT convert(varchar(10), m.dt_vencimento_msl,103)
              FROM mensalidade m
              WHERE m.cd_documento         = 0
                AND m.cd_banco             = me.cd_banco
                AND m.nr_matricula         = me.nr_matricula
                AND m.cd_ano_exercicio     = me.cd_ano_exercicio
                AND m.cd_aluno             = me.cd_aluno
                AND m.cd_curso_instituicao = me.cd_curso_instituicao
            )
            AND me.nr_matricula                     = ma.nr_matricula
            AND me.cd_ano_exercicio                 = ma.cd_ano_exercicio
            AND me.cd_aluno                         = ma.cd_aluno' || @comando;

        -- inserindo as parcelas de outras modalidades

        EXECUTE IMMEDIATE '
          INSERT INTO #temp_rel
          SELECT DISTINCT me.cd_curso_instituicao,
                 me.cd_aluno,
                 me.cd_ano_exercicio,
                 me.nr_matricula,
                 me.nr_documento,
                 me.id_responsavel_financeiro,
                 cas.cd_banco,
                 cas.cd_agencia,
                 cas.cd_conta_corrente,
                 cc.ds_carteira,
                 cc.ds_especie_doc,
                 me.id_resp_financeiro_matricula,
                 fc.id_tipo_forma_cobranca,
                 fc.ds_msg_banco
          FROM aluno a,
               curso_atividade_secundaria cas,
               curso c,
               tipo_curso tc,
               conta_corrente cc,
               matricula_responsavel_financeiro mrf,
               curso_instituicao ci,
               #temp_matricula ma,
               mensalidade me,
               forma_cobranca fc
          WHERE me.cd_forma_cobranca                = fc.cd_forma_cobranca
            AND fc.id_emissao_banco                 = 1
            AND fc.id_tipo_forma_cobranca           IN (3, 4, 11)
            AND NOT exists (
              SELECT 1 FROM #temp_rel tmp
              WHERE tmp.nr_documento = me.nr_documento
            )
            AND tc.id_modalidade                    <> 1
            AND tc.cd_tipo_curso                    = c.cd_tipo_curso
            AND c.cd_curso                          = ci.cd_curso
            AND me.cd_ano_exercicio                 = mrf.cd_ano_exercicio
            AND me.cd_curso_instituicao             = mrf.cd_curso_instituicao
            AND me.cd_aluno                         = mrf.cd_aluno
            AND me.nr_matricula                     = mrf.nr_matricula
            AND ci.cd_curso_instituicao             = me.cd_curso_instituicao
            AND cc.cd_conta_corrente                = cas.cd_conta_corrente
            AND cc.cd_agencia                       = cas.cd_agencia
            AND cc.cd_banco                         = cas.cd_banco
            AND cas.cd_banco                        = '|| @Banco || '
            AND me.cd_documento                     <> 10
            AND me.id_responsavel_financeiro        NOT IN (5,6)
            AND cas.cd_atividade_secundaria         = me.cd_atvd_secundaria_msl
            AND cas.cd_ano_exercicio                = me.cd_ano_exercicio
            AND cas.cd_curso_instituicao            = me.cd_curso_instituicao
            AND f_verificaParcelaCobranca(me.id_mensalidade, me.cd_situacao) = 1 -- se estiver com a situação de cobraça. verifica se a empresa de cobrança permite a baixa
            AND a.cd_aluno                          = ma.cd_aluno
            AND convert(varchar(10), me.dt_vencimento_msl, 103) IN (
              SELECT convert(varchar(10), m.dt_vencimento_msl, 103)
              FROM mensalidade m
              WHERE m.cd_documento         = 0
                AND m.cd_banco             = me.cd_banco
                AND m.nr_matricula         = me.nr_matricula
                AND m.cd_ano_exercicio     = me.cd_ano_exercicio
                AND m.cd_aluno             = me.cd_aluno
                AND m.cd_curso_instituicao = me.cd_curso_instituicao
            )
            AND me.nr_matricula                     = ma.nr_matricula
            AND me.cd_ano_exercicio                 = ma.cd_ano_exercicio
            AND me.cd_aluno                         = ma.cd_aluno ' || @comando

      ELSE
        EXECUTE IMMEDIATE '
          INSERT INTO #temp_rel
          SELECT DISTINCT me.cd_curso_instituicao,
                 me.cd_aluno,
                 me.cd_ano_exercicio,
                 me.nr_matricula,
                 me.nr_documento,
                 me.id_responsavel_financeiro,
                 cas.cd_banco,
                 cas.cd_agencia,
                 cas.cd_conta_corrente,
                 cc.ds_carteira,
                 cc.ds_especie_doc,
                 me.id_resp_financeiro_matricula,
                 fc.id_tipo_forma_cobranca,
                 fc.ds_msg_banco
          FROM aluno a,
               curso_atividade_secundaria cas,
               curso c,
               tipo_curso tc,
               conta_corrente cc,
               curso_instituicao ci,
               matricula_responsavel_financeiro mrf,
               #temp_matricula ma ,
               mensalidade me,
               forma_cobranca fc
          WHERE me.cd_forma_cobranca                = fc.cd_forma_cobranca
            AND fc.id_emissao_banco                 = 1
            AND fc.id_tipo_forma_cobranca           IN (3, 4, 11)
            AND tc.id_modalidade                    = 1
            AND tc.cd_tipo_curso                    = c.cd_tipo_curso
            AND c.cd_curso                          = ci.cd_curso
            AND me.cd_ano_exercicio                 = mrf.cd_ano_exercicio
            AND me.cd_curso_instituicao             = mrf.cd_curso_instituicao
            AND me.cd_aluno                         = mrf.cd_aluno
            AND me.nr_matricula                     = mrf.nr_matricula
            AND ci.cd_curso_instituicao             = me.cd_curso_instituicao
            AND cc.cd_conta_corrente                = cas.cd_conta_corrente
            AND cc.cd_agencia                       = cas.cd_agencia
            AND cc.cd_banco                         = cas.cd_banco
            AND cas.cd_banco                        = '|| @Banco ||'
            AND me.cd_documento                     <> 10
            AND me.id_responsavel_financeiro        NOT IN (5,6)
            AND f_verificaParcelaCobranca(me.id_mensalidade, me.cd_situacao ) = 1 -- se estiver com a situação de cobraça. verifica se a empresa de cobrança permite a baixa
            AND cas.cd_atividade_secundaria         = me.cd_atvd_secundaria_msl
            AND cas.cd_ano_exercicio                = me.cd_ano_exercicio
            AND cas.cd_curso_instituicao            = me.cd_curso_instituicao
            AND tc.cd_tipo_curso                    = ma.cd_tipo_curso
            AND a.cd_aluno                          = ma.cd_aluno
            AND me.nr_matricula                     = ma.nr_matricula
            AND me.cd_ano_exercicio                 = ma.cd_ano_exercicio
            AND me.cd_aluno                         = ma.cd_aluno' || @comando;

        EXECUTE IMMEDIATE '
          INSERT INTO #temp_rel
          SELECT DISTINCT me.cd_curso_instituicao,
                 me.cd_aluno,
                 me.cd_ano_exercicio,
                 me.nr_matricula,
                 me.nr_documento,
                 me.id_responsavel_financeiro,
                 cas.cd_banco,
                 cas.cd_agencia,
                 cas.cd_conta_corrente,
                 cc.ds_carteira,
                 cc.ds_especie_doc,
                 me.id_resp_financeiro_matricula,
                 fc.id_tipo_forma_cobranca,
                 fc.ds_msg_banco
          FROM aluno a,
               curso_atividade_secundaria cas,
               curso c,
               tipo_curso tc,
               conta_corrente cc,
               curso_instituicao ci,
               matricula_responsavel_financeiro mrf,
               #temp_matricula ma ,
               mensalidade me,
               forma_cobranca fc
          WHERE me.cd_forma_cobranca                = fc.cd_forma_cobranca
            AND fc.id_emissao_banco                 = 1
            AND fc.id_tipo_forma_cobranca           IN (3, 4, 11)
            AND NOT exists (
              SELECT 1 FROM #temp_rel tmp
              WHERE tmp.nr_documento = me.nr_documento
            )
            AND tc.id_modalidade                    <> 1
            AND tc.cd_tipo_curso                    = c.cd_tipo_curso
            AND c.cd_curso                          = ci.cd_curso
            AND ci.cd_curso_instituicao             = me.cd_curso_instituicao
            AND cc.cd_conta_corrente                = cas.cd_conta_corrente
            AND cc.cd_agencia                       = cas.cd_agencia
            AND me.cd_ano_exercicio                 = mrf.cd_ano_exercicio
            AND me.cd_curso_instituicao             = mrf.cd_curso_instituicao
            AND me.cd_aluno                         = mrf.cd_aluno
            AND me.nr_matricula                     = mrf.nr_matricula
            AND cc.cd_banco                         = cas.cd_banco
            AND cas.cd_banco                        = '|| @Banco ||'
            AND me.cd_documento                     <> 10
            AND me.id_responsavel_financeiro        NOT IN (5,6)
            AND f_verificaParcelaCobranca(me.id_mensalidade, me.cd_situacao ) = 1 -- se estiver com a situação de cobraça. verifica se a empresa de cobrança permite a baixa
            AND cas.cd_atividade_secundaria         = me.cd_atvd_secundaria_msl
            AND cas.cd_ano_exercicio                = me.cd_ano_exercicio
            AND cas.cd_curso_instituicao            = me.cd_curso_instituicao
            AND a.cd_aluno                          = ma.cd_aluno
            AND me.nr_matricula                     = ma.nr_matricula
            AND me.cd_ano_exercicio                 = ma.cd_ano_exercicio
            AND me.cd_aluno                         = ma.cd_aluno ' || @comando
      END IF;

      SET @CdCursoInstituicaoAnt = -1;
      SET @CdContaEmissaoAnt     = '-1';

      OPEN c_mensalidade WITH HOLD;
      FETCH NEXT c_mensalidade INTO @CdCursoInstituicao, @CdAluno , @CdAnoExercicio, @NrMatricula, @NrDocumento, @IdResponsavelFinanceiro, @CdBancoEmissao, @CdAgenciaEmissao, @CdContaEmissao, @DsCarteiraEmissao, @DsEspecieDocEmissao, @IdRespFinanceiroMatricula, @idTipoFormaCobranca, @DsMsgDebito;

      IF @NrTipoConta IS NULL THEN
        SET @NrTipoConta = 'NULO';
      END IF;

      SET @DsParcelasRenegociadas = '';

      WHILE sqlcode = 0 LOOP
        SELECT id_valor_documento, nr_tipo_conta, ds_variacao
        INTO @IdValorDocumento, @NrTipoConta, @DsVariacaoEmissao
        FROM conta_corrente
        WHERE cd_conta_corrente = @CdContaEmissao
          AND cd_agencia        = @CdAgenciaEmissao
          AND cd_banco          = @CdBancoEmissao;

        SET @DsDadosAluno = NULL;

        SET @VlDescComercialTotal = 0;
        SET @VlDescComercial= 0;

        SELECT FIRST mensalidade.nr_parcela_msl,
               plano_pagamento.nr_parcelas,
               matricula_atividade_secundaria.cd_banco_debito_auto,
               convert(varchar(10),@CdAluno)|| ' - '||a.nm_aluno,
               matricula.cd_turma
        INTO @NrParcelaMensalidade,
             @NrTotalParcelasMensalidade,
             @cdBancoDebitoAuto,
             @DsDadosAluno,
             @CdTurma
        FROM matricula_atividade_secundaria,
             mensalidade,
             matricula,
             aluno a,
             plano_pagamento
        WHERE plano_pagamento.cd_plano_pgt                 = matricula_atividade_secundaria.cd_plano_pgto
          AND matricula_atividade_secundaria.cd_atividade_secundaria = mensalidade.cd_atvd_secundaria_msl
          AND matricula_atividade_secundaria.nr_matricula            = mensalidade.nr_matricula
          AND matricula_atividade_secundaria.cd_aluno                = mensalidade.cd_aluno
          AND matricula_atividade_secundaria.cd_ano_exercicio        = mensalidade.cd_ano_exercicio
          AND matricula_atividade_secundaria.cd_curso_instituicao    = mensalidade.cd_curso_instituicao
          AND a.cd_aluno                                   = matricula.cd_aluno
          AND matricula.nr_matricula                       = mensalidade.nr_matricula
          AND matricula.cd_ano_exercicio                   = mensalidade.cd_ano_exercicio
          AND matricula.cd_aluno                           = mensalidade.cd_aluno
          AND matricula.cd_curso_instituicao               = mensalidade.cd_curso_instituicao
          AND mensalidade.nr_documento                     = @NrDocumento
        ORDER BY mensalidade.cd_documento, mensalidade.nr_parcela_msl desc;


        SELECT list(DISTINCT ds_atividade_secundaria + ' ')
        INTO @NmEventoMensalidade
        FROM mensalidade me, atividade_secundaria a
        WHERE me.cd_atvd_secundaria_msl = a.cd_atividade_secundaria
          AND me.nr_documento           = @NrDocumento;


        IF @CdCursoInstituicao <> @CdCursoInstituicaoAnt OR @CdContaEmissao <> @CdContaEmissaoAnt THEN
          SET @CdContaEmissaoAnt     = @CdContaEmissao;
          SET @CdCursoInstituicaoAnt = @CdCursoInstituicao;

          SELECT conta_corrente.cd_agencia,
                 conta_corrente.cd_conta_corrente,
                 conta_corrente.nr_tipo_conta,
                 conta_corrente.ds_carteira,
                 isnull(conta_corrente.nr_padrao_cnab,0),
                 conta_corrente.ds_especie,
                 conta_corrente.ds_especie_doc,
                 conta_corrente.ds_aceite,
                 conta_corrente.Cd_Contrato,
                 conta_corrente.ds_msg1,
                 conta_corrente.ds_msg2,
                 conta_corrente.ds_msg3,
                 conta_corrente.ds_msg4,
                 conta_corrente.ds_msg5,
                 ie.nm_instituicao_ensino,
                 isnull(conta_corrente.nm_instituicao,ie.nm_instituicao_ensino),
                 pie.pc_juro_mensal,
                 pie.pc_juro_diario,
                 pie.pc_multa,
                 pie.id_regra_desconto,
                 pie.nr_dias_fator_vencimento,
                 agencia.nm_agencia,
                 conta_corrente.ds_msg6,
                 conta_corrente.ds_msg7,
                 conta_corrente.ds_msg8,
                 conta_corrente.ds_msg9,
                 conta_corrente.ds_msg10,
                 conta_corrente.id_registro_carteira,
                 conta_corrente.vl_taxa_bancaria,
                 conta_corrente.ds_tipo_impressao,
                 conta_corrente.ds_variacao
          INTO @CdAgenciaBanco,
               @CdContaCorrenteBanco,
               @NrTipoConta,
               @DsCarteira,
               @NrCnab,
               @DsEspecie,
               @DsEspecieDoc,
               @DsAceite,
               @DsContrato,
               @DsMsg1,
               @DsMsg2,
               @DsMsg3,
               @DsMsg4,
               @DsMsg5,
               @NmInstituicao,
               @NmInstituicaoBanco,
               @PcJuroMensal,
               @PcJuroDiario,
               @PcMulta,
               @IdRegraDesconto,
               @NrDiasFatorVencimento,
               @NmAgencia,
               @DsMsg6,
               @DsMsg7,
               @DsMsg8,
               @DsMsg9,
               @DsMsg10,
               @IdRegistroCarteira,
               @VlTaxaBancaria,
               @dsTipoImpressao,
               @DsVariacao
          FROM curso_instituicao ci,
               instituicao_de_ensino ie,
               parametro_instituicao_ensino pie,
               conta_corrente,
               agencia,
               banco
          WHERE pie.cd_ano_exercicio             = @CdAnoExercicio
            AND pie.cd_instituicao_ensino        = ie.cd_instituicao_ensino
            AND pie.cd_regional                  = ie.cd_regional
            AND pie.cd_orgao_regulador           = ie.cd_orgao_regulador
            AND ci.cd_instituicao_ensino         = ie.cd_instituicao_ensino
            AND ci.cd_regional                   = ie.cd_regional
            AND ci.cd_orgao_regulador            = ie.cd_orgao_regulador
            AND ci.cd_curso_instituicao          = @CdCursoInstituicao
            AND agencia.cd_agencia               = conta_corrente.cd_agencia
            AND agencia.cd_banco                 = conta_corrente.cd_banco
            AND banco.cd_banco                   = conta_corrente.cd_banco
            AND conta_corrente.cd_conta_corrente = @CdContaEmissao
            AND conta_corrente.cd_agencia        = @CdAgenciaEmissao
            AND conta_corrente.cd_banco          = @CdBancoEmissao;
        END IF;

        SET @CdAgencia       = @CdAgenciaBanco;
        SET @CdContaCorrente = @CdContaCorrenteBanco;

        SELECT NULL, NULL, NULL,
               NULL, NULL, NULL,
               NULL, NULL, NULL,
               NULL, NULL, NULL,
               NULL, NULL, NULL,
               NULL, NULL, NULL,
               NULL, NULL
        INTO @pc_desconto_pontualidade1, @nr_dias_pontualidade1, @id_tipo_pontualidade1,
             @pc_desconto_pontualidade2, @nr_dias_pontualidade2, @id_tipo_pontualidade2,
             @pc_desconto_pontualidade3, @nr_dias_pontualidade3, @id_tipo_pontualidade3,
             @pc_desconto_pontualidade4, @nr_dias_pontualidade4, @id_tipo_pontualidade4,
             @pc_desconto_pontualidade5, @nr_dias_pontualidade5, @id_tipo_pontualidade5,
             @pc_desconto_pontualidade6, @nr_dias_pontualidade6, @id_tipo_pontualidade6,
             @CdInstituicaoEnsino, @DsDescPontualidade;

        SET @DsBolsa      = '';
        SET @DsBolsaAluno = '';
        SET @VlBolsaAluno = 0;
        SET @VlBolsa      = 0;

        SET @idAtualizarVencimento = 'NAO';

        OPEN c_parcela WITH HOLD;
        FETCH NEXT c_parcela INTO @VlMensalidade, @VlDesconto, @IdDocumento, @CdAtvdMsl, @NrParcela, @NrBloqueto, @DtVencimento, @DtPrimeiraEmissao, @NrControleEmissao, @CdSituacaoParcela, @NrMensalidade, @CdBolsa, @VlBolsa, @IdMensalidade, @DsObsParcela;

        IF @NrTipoConta IS NULL THEN
          SET @NrTipoConta = 'NULO';
        END IF;

        IF @CdInstituicaoLogin = 24 AND @CdBancoEmissao = 27 THEN
          RAISERROR 99999 'Houve um problema com os parametros passados, entre em contato com o suporte!';
          RETURN
        END IF;

        -- DEVIDO A CARTEIRA 11 DO BANCO 1, ser do tipo que o banco é quem gera o nro do boleto, NAO
        -- DEVIDO A especie de DOC 06 DO BANCO 356, ser do tipo que o banco é quem gera o nro do boleto,
        -- DEVIDO A CARTEIRA 9 DO BANCO 237 E O TIPO DE CONTA FOR a literal 'BANCO', ser do tipo que o banco é quem gera o nro do boleto,
        -- DEVIDO A CARTEIRA 112 DO BANCO 341 E O TIPO DE CONTA FOR a literal 'BANCO', ser do tipo que o banco é quem gera o nro do boleto,
        -- PARA CEF (104), TIPO COINTA SIGCB E VARIACAO(@DsVariacaoEmissao) = 999 - banco gera boleto

        -- podem ser emitidos boletos para mensalidade que ainda NAO TENHAM O NR_BLOQUETO
        -- o NR bloqueto destas parcelas sao gerados no momento da imporcao de arquivo bancario com
        -- a confirmação das entradas pelo banco

        IF ((@CdBancoEmissao = 1 AND @DsCarteiraEmissao = '11') OR (@CdBancoEmissao = 104 AND @NrTipoConta = 'SIGCB' AND @DsVariacaoEmissao = '999') OR (@CdBancoEmissao = 341 AND @DsCarteiraEmissao = '112' AND @NrTipoConta = 'BANCO') OR (@CdBancoEmissao = 237 AND @DsCarteiraEmissao = '9' AND @NrTipoConta = 'BANCO') OR (@CdBancoEmissao = 356 AND @DsEspecieDocEmissao = '06')) AND (@NrBloqueto IS NULL OR @NrBloqueto = '') THEN
          SET @IdPodeEmitir = 'NAO'
        ELSE
          SET @IdPodeEmitir = 'SIM'
        END IF;

        -- SE O RESPONSAVEL FINANCEIRO FOR UM ADOTADOR E AINDA, SE ESTE ADOTADOR NAO PERMITE EMISSÃO DE BOLETO
        -- O BOLETO NUNCA SERÁ EMITIDO
        SET @IcPermiteEmitirAdotador = 'N';
        IF @IdResponsavelFinanceiro = 7 THEN
          SELECT ic_permite_emissao_boleto
          INTO @IcPermiteEmitirAdotador
          FROM matricula_responsavel_financeiro m, pessoa_adotador p
          WHERE p.id_pessoa_adotador           = m.id_pessoa
            AND m.id_resp_financeiro_matricula = @IdRespFinanceiroMatricula;

          IF @IcPermiteEmitirAdotador = 'N' THEN
            SET @IdPodeEmitir = 'NAO'
          END IF;
        END IF;

        IF @NrTipoConta IS NULL THEN
          SET @NrTipoConta = 'NULO';
        END IF;

        SET @IdRegraDescontoBolsa = NULL;
        IF @IdPodeEmitir = 'SIM' THEN
          IF @NrBloqueto IS NULL OR @NrBloqueto = '' THEN

            -- o cliente 189 necessitava que o vencimento da parcela, na primeira geração, de documento tipo "matricula" fosse gerado no momento da impressão do boleto
           -- sendo que o vencimento deve ser 2 dias uteis após a data atual

            IF @NmBancoDados = 'BD01189' AND @IdDocumento = 0 THEN
               --não posso somar 2 direto, pois se estiver em uma sexta, ao somar 2, o vencimento após o calculo cairia na segunda
               -- e de acordo com a regra é cair na terça ( 2 dias uteis a partir da emissão)
              SELECT F_DIA_UTIL(@CdInstituicaoEnsino, date(getdate())+1, @CdAnoExercicio, NULL, 2, 0)
              INTO @DtVencimento;

              SELECT F_DIA_UTIL(@CdInstituicaoEnsino, @DtVencimento+1, @CdAnoExercicio, NULL, 2, 0)
              INTO @DtVencimento;

              SET @idAtualizarVencimento = 'SIM';
            END IF;

            IF @NmBancoDados = 'BD01189' AND @CdBancoEmissao = 237 THEN
              IF @CdContaEmissao = '18112' THEN
                SELECT f_gera_nr_documento('237|18112',0,0,0)
                INTO @NrBloquetoNovo;
              ELSE
                SELECT f_gera_nr_documento('237',0,0,0)
                INTO @NrBloquetoNovo;

                -- se passar de 12119649600, invade a faixa da conta 18112
                IF convert(numeric(15,2),@NrBloquetoNovo) > 12119649600 THEN
                  -- passou da faixa, deve dar um erro
                  RAISERROR 99999 'ERRO na emissão, a faixa do banco 237 foi ultrapassada!!!';
                  RETURN
                END IF;
              END IF;

            ELSEIF @NmBancoDados = 'BD01189' AND @CdBancoEmissao = 341 AND @CdContaEmissao = '93297' THEN
              SELECT f_gera_nr_documento('341|93297',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 445006 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 341  da conta 93297 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01082' AND @CdBancoEmissao = 237 AND @CdAgenciaEmissao = '75033' AND @CdContaEmissao IN ('10964601','15125365' , '15864087') THEN
              SELECT f_gera_nr_documento('237|75033',0,0,0)
              INTO @NrBloquetoNovo;

            ELSEIF @NmBancoDados = 'BD01076' AND @CdBancoEmissao = 748 THEN
              SELECT f_gera_nr_documento('748',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) >  699999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 748 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01076' AND @CdBancoEmissao = 756 THEN
              SELECT f_gera_nr_documento('756', 0, 0, 0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) >  5094084 THEN
                 -- passou da faixa, deve dar um erro
                 RAISERROR 99999 'ERRO na emissão, a faixa do banco 756 foi ultrapassada!!!';
                 RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01076' AND @CdBancoEmissao = 409 AND @CdContaEmissao = '2073873' THEN
              SELECT f_gera_nr_documento('409|2073873',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 8579040304 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 409  da conta 2073873 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01076' AND @CdBancoEmissao = 409 AND @CdContaEmissao <> '2073873' THEN
              SELECT f_gera_nr_documento('409',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) >  9999999999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 409 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01028' AND @CdBancoEmissao = 399 AND @CdContaEmissao = '19700001990' THEN
              SELECT f_gera_nr_documento('399|19700001990',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 2412199999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 399  da conta 19700001990 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01028' AND @CdBancoEmissao = 399 AND @CdContaEmissao = '16050051667' THEN
              SELECT f_gera_nr_documento('399|16050051667',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 8210499999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 399  da conta 16050051667 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01028' AND @CdBancoEmissao = 399 AND @CdContaEmissao = '6080127052' THEN
              SELECT f_gera_nr_documento('399|6080127052',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 8210399999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 399  da conta 6080127052 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01028' AND @CdBancoEmissao = 399 AND @CdContaEmissao = '10710052690' THEN
              SELECT f_gera_nr_documento('399|10710052690',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 8210599999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 399  da conta 10710052690 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01028' AND @CdBancoEmissao = 399 AND @CdContaEmissao = '2580127300' THEN
              SELECT f_gera_nr_documento('399|2580127300',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 8210099999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 399  da conta 2580127300 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01028' AND @CdBancoEmissao = 399 AND @CdContaEmissao = '2442837476' THEN
              SELECT f_gera_nr_documento('399|2442837476',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 8210699999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 399  da conta 2442837476 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01028' AND @CdBancoEmissao = 399 AND @CdContaEmissao = '4260105000' THEN
              SELECT f_gera_nr_documento('399|4260105000',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 8106699999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 399  da conta 4260105000 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01028' AND @CdBancoEmissao = 399 AND @CdContaEmissao = '2400401670' THEN
              SELECT f_gera_nr_documento('399|2400401670',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 8210999999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 399  da conta 2400401670 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01028' AND @CdBancoEmissao = 399 AND @CdContaEmissao = '5340257629' THEN
              SELECT f_gera_nr_documento('399|5340257629',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 8209299999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 399  da conta 5340257629 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01028' AND @CdBancoEmissao = 399 AND @CdContaEmissao = '2440108450' THEN
              SELECT f_gera_nr_documento('399|2440108450',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 8210799999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 399  da conta 2440108450 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01028' AND @CdBancoEmissao = 399 AND @CdContaEmissao = '2590054445' THEN
              SELECT f_gera_nr_documento('399|2590054445',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 8211299999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 399  da conta 2590054445 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01028' AND @CdBancoEmissao = 399 AND @CdContaEmissao = '8960189756' THEN
              SELECT f_gera_nr_documento('399|8960189756',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 8211499999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 399  da conta 8960189756 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01028' AND @CdBancoEmissao = 399 AND @CdContaEmissao = '5780019513' THEN
              SELECT f_gera_nr_documento('399|5780019513',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 8245599999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 399  da conta 5780019513 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01028' AND @CdBancoEmissao = 399 AND @CdContaEmissao = '4170236059' THEN
              SELECT f_gera_nr_documento('399|4170236059',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 8245799999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 399  da conta 4170236059 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01028' AND @CdBancoEmissao = 399 AND @CdContaEmissao = '4910049630' THEN
              SELECT f_gera_nr_documento('399|4910049630',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 8246299999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 399  da conta 4910049630 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01110' AND @CdBancoEmissao = 399 AND @CdAgenciaEmissao = '8604' AND @CdContaEmissao = '2557' THEN
              SELECT f_gera_nr_documento('399|8604|2557',0,0,0)
              INTO @NrBloquetoNovo;

              IF convert(numeric(15,2),@NrBloquetoNovo) > 2469899999 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 399  da conta 4910049630 foi ultrapassada!!!';
                RETURN
              END IF;

            ELSEIF @NmBancoDados = 'BD01162' AND @CdBancoEmissao = 237 AND @CdAgenciaEmissao = '75063' AND @CdContaEmissao = '16815756' THEN
              SELECT f_gera_nr_documento('237|75063|16815756',0,0,0)
              INTO @NrBloquetoNovo;

      elseif @NmBancoDados = 'BD01124' and @CdBancoEmissao = 756  then 
        select f_gera_nr_documento('756|'||@CdAgenciaEmissao||'|'||@CdContaEmissao,0,0,0)
        into @NrBloquetoNovo
        from dummy;

            ELSE
              SELECT f_gera_nr_documento('BLOQUETO',0,0,0)
              INTO @NrBloquetoNovo;

              -- para o banco 189, como foi incluido uma faixa para um banco especifico(237)
              -- os outros bancos não podem alcancar aquele faixa
              IF convert(numeric(15,2),@NrBloquetoNovo) > 80000000 AND @NmBancoDados = 'BD01189'  THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, a faixa do banco 237 foi alcançada, entre em contato com o suporte!!!';
                RETURN
              END IF;

              IF @NmBancoDados = 'BD01189' AND CONVERT(NUMERIC(15,2),@NrBloquetoNovo) > 429900 THEN
                -- passou da faixa, deve dar um erro
                RAISERROR 99999 'ERRO na emissão, o numero do bloqueto gerado está alcançando a faixa reservada para a conta 93297 do banco 341!!!';
                RETURN
              END IF;
            END IF;

            IF @Banco = 748 THEN
              SET @NrBloquetoNovo = right(left(convert(varchar(5),@CdAnoExercicio),4),2)  + @NrBloquetoNovo;
              SET @NrBloquetoNovo = convert(integer, @NrBloquetoNovo)
            END IF;
          ELSE
            SET @NrBloquetoNovo = @NrBloqueto
          END IF;

          -- Seta a Data da Primeira Emissão
          IF @DtPrimeiraEmissao IS NULL THEN
            SET @DtPrimeiraEmissao = GetDate()
          END IF;

          -- Seta o NR Controle de Emissão
          IF @NrControleEmissao IS NULL OR @NrControleEmissao = 0 THEN
            SET @NrControleEmissao = 999
          ELSE
            SET @NrControleEmissao = @NrControleEmissao - 1
          END IF;

          SET @DsAbreviacaoDescto = '';
          SET @DsInstrucoes = '';
          SET @DsInstrucoesEf = '';
          SET @DsInstrucoesSemDesconto = '';
          SET @dsEventos = '';
          SET @DsParcelas= '';
          SET @VlParcelaTotal = 0;
          SET @VlDescontoTotal = 0;
          SET @DsInstrucoesDescto = '';
          SET @DsInstrucoesDesctoTotal = '';
          SET @DsDigitoBloqueto = '';
          SET @DsLiteralTotalEventoPontualidade1 = '';
          SET @VlTotalPagarPontualidade1 = 0;
          SET @DsLiteralTotalEventoPontualidade2 = '';
          SET @VlTotalPagarPontualidade2 = 0;
          SET @DsLiteralTotalEventoPontualidade3 = '';
          SET @VlTotalPagarPontualidade3 = 0;
          SET @DsLiteralTotalEventoPontualidade4 = '';
          SET @VlTotalPagarPontualidade4 = 0;
          SET @DsLiteralTotalEventoPontualidade5 = '';
          SET @VlTotalPagarPontualidade5 = 0;
          SET @DsLiteralTotalEventoPontualidade6 = '';
          SET @VlTotalPagarPontualidade6 = 0;
          SET @VlTotalMensalidadeBruto = 0;

          SET @VlTotalApenasPontualidade1 = 0;
          SET @VlTotalApenasPontualidade2 = 0;
          SET @VlTotalApenasPontualidade3 = 0;
          SET @VlTotalApenasPontualidade4 = 0;
          SET @VlTotalApenasPontualidade5 = 0;
          SET @VlTotalApenasPontualidade6 = 0;

          SET @VlTotalDescPontualidade1 = 0;
          SET @VlTotalDescPontualidade2 = 0;
          SET @VlTotalDescPontualidade3 = 0;
          SET @VlTotalDescPontualidade4 = 0;
          SET @VlTotalDescPontualidade5 = 0;
          SET @VlTotalDescPontualidade6 = 0;

          SET @nrEventoBoleto = 0;
          SET @DsObsParcelaBoleto = '';

          WHILE sqlcode = 0 LOOP -- inicio LOOP c_Parcela
            SET @VlMensalidadeBruto = @VlMensalidade;
            SET @VlDescontoBruto = @VlDesconto;
            SET @VlDescComercial = @VlDesconto - @VlBolsa;
            SET @nrEventoBoleto  = @nrEventoBoleto + 1;
            SET @VlTotalMensalidadeBruto = @VlTotalMensalidadeBruto + @VlMensalidadeBruto;

            IF @IdValorDocumento = 2 THEN
              SET @VlMensalidade   = @VlMensalidade - @VlDesconto;
              SET @VlDesconto      = 0;
              SET @VlDescComercial = 0;

            ELSEIF @IdValorDocumento = 3 THEN
              SET @VlMensalidade   = @VlMensalidade - @VlBolsa;
              SET @VlDescComercial = @VlDesconto - @VlBolsa;
              SET @VlDesconto      = @VlDescComercial;
              SET @VlBolsa         = 0;

            ELSEIF @IdValorDocumento = 4 AND (SELECT id_regra_desconto FROM bolsas WHERE cd_bolsa = @CdBolsa) = 1  THEN
              SET @VlMensalidade   = @VlMensalidade - @VlBolsa;
              SET @VlDescComercial = @VlDesconto - @VlBolsa;
              SET @VlDesconto      = @VlDescComercial;
              SET @VlBolsa         = 0;
            END IF;
      
            -- PROUNI regra sempre fixa, nao mostra no valor do boleto - considera sempre bolsa incondicional
            IF (SELECT id_bolsa FROM bolsas WHERE cd_bolsa = @CdBolsa) = 6 THEN
              SET @VlMensalidade   = @VlMensalidade - @VlBolsa;
              SET @VlDescComercial = @VlDesconto - @VlBolsa;
              SET @VlDesconto      = @VlDescComercial;
              SET @VlBolsa         = 0;
            END IF;
      
            SELECT f_id_documento(@IdDocumento,@CdAtvdMsl,2), ds_atividade_secundaria|| if @IdDocumento = 8 then '(DIF)' endif, if @IdDocumento = 8 then 'DIF' else abreviacao ENDIF
            INTO @DsAbreviacao, @DsEventoParcela, @DsAbreviacaoEvento
            FROM atividade_secundaria
            WHERE cd_atividade_secundaria = @CdAtvdMsl;

            -- inicio do desconto por pontualidade
            SELECT cip.pc_desconto_pontualidade1, cip.nr_dias_pontualidade1, cip.id_tipo_pontualidade1,
                   cip.pc_desconto_pontualidade2, cip.nr_dias_pontualidade2, cip.id_tipo_pontualidade2,
                   cip.pc_desconto_pontualidade3, cip.nr_dias_pontualidade3, cip.id_tipo_pontualidade3,
                   cip.pc_desconto_pontualidade4, cip.nr_dias_pontualidade4, cip.id_tipo_pontualidade4,
                   cip.pc_desconto_pontualidade5, cip.nr_dias_pontualidade5, cip.id_tipo_pontualidade5,
                   cip.pc_desconto_pontualidade6, cip.nr_dias_pontualidade6, cip.id_tipo_pontualidade6,
                   ie.cd_instituicao_ensino, ds_msg_pontualidade, ic_aplicar_renegociacao
            INTO @pc_desconto_pontualidade1, @nr_dias_pontualidade1, @id_tipo_pontualidade1,
                  @pc_desconto_pontualidade2, @nr_dias_pontualidade2, @id_tipo_pontualidade2,
                  @pc_desconto_pontualidade3, @nr_dias_pontualidade3, @id_tipo_pontualidade3,
                  @pc_desconto_pontualidade4, @nr_dias_pontualidade4, @id_tipo_pontualidade4,
                  @pc_desconto_pontualidade5, @nr_dias_pontualidade5, @id_tipo_pontualidade5,
                  @pc_desconto_pontualidade6, @nr_dias_pontualidade6, @id_tipo_pontualidade6,
                  @CdInstituicaoEnsino, @DsDescPontualidade, @icAplicarRenegociacao
            FROM curso_instituicao_pontualidade cip, instituicao_de_ensino ie, curso_instituicao ci, curso_atividade_secundaria cas
            WHERE ie.cd_instituicao_ensino = ci.cd_instituicao_ensino
              AND ( cas.id_permite_desconto_pontualidade  = 1
                OR (cas.id_permite_desconto_pontualidade  = 2 AND @VlBolsa = 0)
              )
              AND cas.cd_atividade_secundaria = @CdAtvdMsl
              AND cas.cd_ano_exercicio        = cip.cd_ano_exercicio
              AND cas.cd_curso_instituicao    = cip.cd_curso_instituicao
              AND ci.cd_curso_instituicao     = cip.cd_curso_instituicao
              AND cip.cd_ano_exercicio        = @CdAnoExercicio
              AND cip.cd_curso_instituicao    = @CdCursoInstituicao;

            SELECT ic_regra_pontualidade
            INTO @icRegraPontualidade
            FROM bolsas
            WHERE cd_bolsa = @CdBolsa;

            -- Se o documento FOR uma renegociação, Renegociação da Cobrança, Renegociação PIPEDUC
            -- e não estivar setado para aplicar renegociação, não será considerado o desconto de pontualidade
            -- Se no cadastro da bolsa estiver para nao considerar desconto de pontualidade.
            IF (@icAplicarRenegociacao = 0 AND @IdDocumento IN (7, 10)) OR @icRegraPontualidade = 0 THEN
              SET @id_tipo_pontualidade1 = NULL;
              SET @id_tipo_pontualidade2 = NULL;
              SET @id_tipo_pontualidade3 = NULL;
              SET @id_tipo_pontualidade4 = NULL;
              SET @id_tipo_pontualidade5 = NULL;
              SET @id_tipo_pontualidade6 = NULL;
            END IF;

            IF @id_tipo_pontualidade1 IS NOT NULL THEN
              IF @id_tipo_pontualidade1 IN (1, 3) THEN
                SET @DtVencimentoFixo1 = dateadd (dd, @nr_dias_pontualidade1,  @DtVencimento )
              ELSEIF @id_tipo_pontualidade1 IN (2, 4) THEN
                SET @DtVencimentoFixo1 = f_monta_data_fixa(@nr_dias_pontualidade1 , @DtVencimento);
              ELSE
                -- para este tipo de calculo, usa-se o valor parametrizado em nr_dias_pontualidade, para achar
                -- o NN dia util do mes de vencimento aonde NN = nr_dias_pontualidade
                SET @DtVencimentoFixo1 = f_dia_util(@CdInstituicaoEnsino, ymd(year(@DtVencimento), month(@DtVencimento), @nr_dias_pontualidade1), @CdAnoExercicio, NULL, 1, @id_tipo_pontualidade1)
              END IF;

              SELECT f_calculo_desconto_parcela(@IdMensalidade, @DtVencimentoFixo1, @IdContraApresentacao)
              INTO @VlDescPontualidade1;

              IF @id_tipo_pontualidade1 IN (1,2,5) THEN
                SET @VlBasedeCalculo = @VlMensalidadeBruto - @VlDescontoBruto;
              ELSE
                SET @VlBasedeCalculo = @VlMensalidade;
              END IF;

              IF @VlDescPontualidade1 > 0 THEN
                IF @nr_dias_pontualidade1 < 0 OR (@nr_dias_pontualidade1 >= 0 AND @DtVencimento >= @DtVencimentoFixo1) THEN
                  SET @VlTotalApenasPontualidade1 = @VlTotalApenasPontualidade1 + round(@VlBasedeCalculo * @pc_desconto_pontualidade1 / 100, 2);
                ELSE
                  SET @VlTotalApenasPontualidade1 = @VlTotalApenasPontualidade1 - round(@VlDescontoBruto * @pc_desconto_pontualidade1 / 100, 2);
                END IF;
              END IF;

              SET @VlTotalPagarPontualidade1 =  @VlTotalPagarPontualidade1 + (@VlMensalidadeBruto - @VlDescPontualidade1);

              IF @DsLiteralTotalEventoPontualidade1 = '' THEN
                SET @DsLiteralTotalEventoPontualidade1 = @dsMoeda || ' ' + f_formata_valor(@VlMensalidadeBruto - @VlDescPontualidade1, ',') + ' ' + @DsAbreviacao;
              ELSE
                SET @DsLiteralTotalEventoPontualidade1 = @DsLiteralTotalEventoPontualidade1 + ' + ' + @dsMoeda + '' + f_formata_valor(@VlMensalidadeBruto - @VlDescPontualidade1,',')+' '+@DsAbreviacao;
              END IF;
            ELSE
              SELECT f_calculo_desconto_parcela(@IdMensalidade, @DtVencimentoFixo1, @IdContraApresentacao)
              INTO @VlDescPontualidade1;

              SET @VlTotalPagarPontualidade1 =  @VlTotalPagarPontualidade1 + (@VlMensalidadeBruto - @VlDescPontualidade1);
            END IF;

            IF @id_tipo_pontualidade2 IS NOT NULL THEN
              IF @id_tipo_pontualidade2 IN (1,3) THEN
                SET @DtVencimentoFixo2= dateadd (dd, @nr_dias_pontualidade2,  @DtVencimento)
              ELSEIF @id_tipo_pontualidade2 IN (2,4) THEN
                SET @DtVencimentoFixo2 = f_monta_data_fixa(@nr_dias_pontualidade2 , @DtVencimento);
              ELSE
                -- para este tipo de calculo, usa-se o valor parametrizado em nr_dias_pontualidade, para achar
                -- o NN dia util do mes de vencimento aonde NN = nr_dias_pontualidade
                SET @DtVencimentoFixo2 = f_dia_util(@CdInstituicaoEnsino, ymd( year(@DtVencimento), month(@DtVencimento), @nr_dias_pontualidade2), @CdAnoExercicio, NULL, 1, @id_tipo_pontualidade2 )
              END IF;

              SELECT f_calculo_desconto_parcela(@IdMensalidade, @DtVencimentoFixo2, @IdContraApresentacao)
              INTO @VlDescPontualidade2;

              IF @id_tipo_pontualidade2 IN (1,2,5) THEN
                SET @VlBasedeCalculo = @VlMensalidadeBruto - @VlDescontoBruto;
              ELSE
                SET @VlBasedeCalculo = @VlMensalidade;
              END IF;

              IF @VlDescPontualidade2 > 0 THEN
                IF @nr_dias_pontualidade2 < 0 OR (@nr_dias_pontualidade2 >= 0 AND @DtVencimento >= @DtVencimentoFixo2) THEN
                  SET @VlTotalApenasPontualidade2 = @VlTotalApenasPontualidade2 + round( @VlBasedeCalculo * @pc_desconto_pontualidade2 / 100, 2 );
                ELSE
                  SET @VlTotalApenasPontualidade2 = @VlTotalApenasPontualidade2 - round( @VlDescontoBruto * @pc_desconto_pontualidade2 / 100, 2 );
                END IF;
              END IF;

              SET @VlTotalPagarPontualidade2 =  @VlTotalPagarPontualidade2 + (@VlMensalidadeBruto - @VlDescPontualidade2);

              IF @DsLiteralTotalEventoPontualidade2 = '' THEN
                SET @DsLiteralTotalEventoPontualidade2= @dsMoeda+' '+f_formata_valor(@VlMensalidadeBruto - @VlDescPontualidade2,',')+' '+@DsAbreviacao;
              ELSE
                SET @DsLiteralTotalEventoPontualidade2= @DsLiteralTotalEventoPontualidade2 + ' + '+ @dsMoeda+' '+f_formata_valor(@VlMensalidadeBruto - @VlDescPontualidade2,',')+' '+@DsAbreviacao;
              END IF;
            ELSE
              SELECT f_calculo_desconto_parcela(@IdMensalidade, @DtVencimentoFixo2, @IdContraApresentacao)
              INTO @VlDescPontualidade2;

              SET @VlTotalPagarPontualidade2 =  @VlTotalPagarPontualidade2 + (@VlMensalidadeBruto - @VlDescPontualidade2);
            END IF;

            IF @id_tipo_pontualidade3 IS NOT NULL THEN
              IF @id_tipo_pontualidade3 IN (1,3) THEN
                SET @DtVencimentoFixo3= dateadd (dd, @nr_dias_pontualidade3,  @DtVencimento )
              ELSEIF @id_tipo_pontualidade3 IN (2,4) THEN
                SET @DtVencimentoFixo3 = f_monta_data_fixa(@nr_dias_pontualidade3 , @DtVencimento);
              ELSE
                -- para este tipo de calculo, usa-se o valor parametrizado em nr_dias_pontualidade, para achar
                -- o NN dia util do mes de vencimento aonde NN = nr_dias_pontualidade
                SET @DtVencimentoFixo3 = f_dia_util(@CdInstituicaoEnsino, ymd( year(@DtVencimento), month(@DtVencimento), @nr_dias_pontualidade3), @CdAnoExercicio, NULL, 1, @id_tipo_pontualidade3 )
              END IF;

              SELECT f_calculo_desconto_parcela(@IdMensalidade, @DtVencimentoFixo3, @IdContraApresentacao)
              INTO @VlDescPontualidade3;

              IF @id_tipo_pontualidade3 IN (1,2,5) THEN
                SET @VlBasedeCalculo = @VlMensalidadeBruto - @VlDescontoBruto;
              ELSE
                SET @VlBasedeCalculo = @VlMensalidade;
              END IF;

              IF @VlDescPontualidade3 > 0 THEN
                IF @nr_dias_pontualidade3 < 0 OR (@nr_dias_pontualidade3 >= 0 AND @DtVencimento >= @DtVencimentoFixo3) THEN
                  SET @VlTotalApenasPontualidade3 = @VlTotalApenasPontualidade3 + round( @VlBasedeCalculo * @pc_desconto_pontualidade3 / 100, 2 );
                ELSE
                  SET @VlTotalApenasPontualidade3 = @VlTotalApenasPontualidade3 - round( @VlDescontoBruto * @pc_desconto_pontualidade3 / 100, 2 );
                END IF;
              END IF;

              SET @VlTotalPagarPontualidade3 =  @VlTotalPagarPontualidade3 + (@VlMensalidadeBruto - @VlDescPontualidade3);

              IF @DsLiteralTotalEventoPontualidade3 = '' THEN
                SET @DsLiteralTotalEventoPontualidade3= @dsMoeda+' '+f_formata_valor(@VlMensalidadeBruto - @VlDescPontualidade3,',')+' '+@DsAbreviacao;
              ELSE
                SET @DsLiteralTotalEventoPontualidade3= @DsLiteralTotalEventoPontualidade3 + ' + '+ @dsMoeda+' '+f_formata_valor(@VlMensalidadeBruto - @VlDescPontualidade3,',')+' '+@DsAbreviacao;
              END IF;
            ELSE
              SELECT f_calculo_desconto_parcela(@IdMensalidade, @DtVencimentoFixo3, @IdContraApresentacao)
              INTO @VlDescPontualidade3;

              SET @VlTotalPagarPontualidade3 =  @VlTotalPagarPontualidade3 + (@VlMensalidadeBruto - @VlDescPontualidade3);
            END IF;

            IF @id_tipo_pontualidade4 IS NOT NULL THEN
              IF @id_tipo_pontualidade4 IN (1,3) THEN
                SET @DtVencimentoFixo4= dateadd (dd, @nr_dias_pontualidade4,  @DtVencimento )
              ELSEIF @id_tipo_pontualidade4 IN (2,4) THEN
                SET @DtVencimentoFixo4 = f_monta_data_fixa(@nr_dias_pontualidade4 , @DtVencimento);
              ELSE
                -- para este tipo de calculo, usa-se o valor parametrizado em nr_dias_pontualidade, para achar
                -- o NN dia util do mes de vencimento aonde NN = nr_dias_pontualidade
                SET @DtVencimentoFixo4 = f_dia_util(@CdInstituicaoEnsino, ymd( year(@DtVencimento), month(@DtVencimento), @nr_dias_pontualidade4), @CdAnoExercicio, NULL, 1, @id_tipo_pontualidade4 )
              END IF;

              SELECT f_calculo_desconto_parcela(@IdMensalidade, @DtVencimentoFixo4, @IdContraApresentacao)
              INTO @VlDescPontualidade4;

              IF @id_tipo_pontualidade4 IN (1,2,5) THEN
                SET @VlBasedeCalculo = @VlMensalidadeBruto - @VlDescontoBruto;
              ELSE
                SET @VlBasedeCalculo = @VlMensalidade;
              END IF;

              IF @VlDescPontualidade4 > 0 THEN
                IF @nr_dias_pontualidade4 < 0 OR (@nr_dias_pontualidade4 >= 0 AND @DtVencimento >= @DtVencimentoFixo4) THEN
                  SET @VlTotalApenasPontualidade4 = @VlTotalApenasPontualidade4 + round( @VlBasedeCalculo * @pc_desconto_pontualidade4 / 100, 2 );
                ELSE
                  SET @VlTotalApenasPontualidade4 = @VlTotalApenasPontualidade4 - round( @VlDescontoBruto * @pc_desconto_pontualidade4 / 100, 2 );
                END IF;
              END IF;

              SET @VlTotalPagarPontualidade4 =  @VlTotalPagarPontualidade4 + (@VlMensalidadeBruto - @VlDescPontualidade4);

              IF @DsLiteralTotalEventoPontualidade4 = '' THEN
                SET @DsLiteralTotalEventoPontualidade4= @dsMoeda+' '+f_formata_valor(@VlMensalidadeBruto - @VlDescPontualidade4,',')+' '+@DsAbreviacao;
              ELSE
                SET @DsLiteralTotalEventoPontualidade4= @DsLiteralTotalEventoPontualidade4 + ' + '+ @dsMoeda+' '+f_formata_valor(@VlMensalidadeBruto - @VlDescPontualidade4,',')+' '+@DsAbreviacao;
              END IF;

            ELSE
              SELECT f_calculo_desconto_parcela(@IdMensalidade, @DtVencimentoFixo4, @IdContraApresentacao)
              INTO @VlDescPontualidade4;

              SET @VlTotalPagarPontualidade4 =  @VlTotalPagarPontualidade4 + (@VlMensalidadeBruto - @VlDescPontualidade4);
            END IF;

            IF @id_tipo_pontualidade5 IS NOT NULL THEN
              IF @id_tipo_pontualidade5 IN (1,3) THEN
                SET @DtVencimentoFixo5= dateadd (dd, @nr_dias_pontualidade5,  @DtVencimento )
              ELSEIF @id_tipo_pontualidade5 IN (2,4) THEN
                SET @DtVencimentoFixo5 = f_monta_data_fixa(@nr_dias_pontualidade5 , @DtVencimento);
              ELSE
                -- para este tipo de calculo, usa-se o valor parametrizado em nr_dias_pontualidade, para achar
                -- o NN dia util do mes de vencimento aonde NN = nr_dias_pontualidade
                SET @DtVencimentoFixo5 = f_dia_util(@CdInstituicaoEnsino, ymd( year(@DtVencimento), month(@DtVencimento), @nr_dias_pontualidade5), @CdAnoExercicio, NULL, 1, @id_tipo_pontualidade5)
              END IF;

              SELECT f_calculo_desconto_parcela(@IdMensalidade, @DtVencimentoFixo5, @IdContraApresentacao)
              INTO @VlDescPontualidade5;

              IF @id_tipo_pontualidade5 IN (1,2,5) THEN
                SET @VlBasedeCalculo = @VlMensalidadeBruto - @VlDescontoBruto;
              ELSE
                SET @VlBasedeCalculo = @VlMensalidade;
              END IF;

              IF @VlDescPontualidade5 > 0 THEN
                IF @nr_dias_pontualidade5 < 0 OR (@nr_dias_pontualidade5 >= 0 AND @DtVencimento >= @DtVencimentoFixo5) THEN
                  SET @VlTotalApenasPontualidade5 = @VlTotalApenasPontualidade5 + round( @VlBasedeCalculo * @pc_desconto_pontualidade5 / 100, 2 );
                ELSE
                  SET @VlTotalApenasPontualidade5 = @VlTotalApenasPontualidade5 - round( @VlDescontoBruto * @pc_desconto_pontualidade5 / 100, 2 );
                END IF;
              END IF;

              SET @VlTotalPagarPontualidade5 = @VlTotalPagarPontualidade5 + (@VlMensalidadeBruto - @VlDescPontualidade5);

              IF @DsLiteralTotalEventoPontualidade5 = '' THEN
                SET @DsLiteralTotalEventoPontualidade5= @dsMoeda+' '+f_formata_valor(@VlMensalidadeBruto - @VlDescPontualidade5,',')+' '+@DsAbreviacao;
              ELSE
                SET @DsLiteralTotalEventoPontualidade5= @DsLiteralTotalEventoPontualidade5 + ' + '+ @dsMoeda+' '+f_formata_valor(@VlMensalidadeBruto - @VlDescPontualidade5,',')+' '+@DsAbreviacao;
              END IF;

            ELSE
              SELECT f_calculo_desconto_parcela(@IdMensalidade, @DtVencimentoFixo5, @IdContraApresentacao)
              INTO @VlDescPontualidade5;

              SET @VlTotalPagarPontualidade5 =  @VlTotalPagarPontualidade5 + (@VlMensalidadeBruto - @VlDescPontualidade5);
            END IF;

            IF @id_tipo_pontualidade6 IS NOT NULL THEN
              IF @id_tipo_pontualidade6 IN (1,3) THEN
                SET @DtVencimentoFixo6= dateadd (dd, @nr_dias_pontualidade6,  @DtVencimento )
              ELSEIF @id_tipo_pontualidade6 IN (2,4) THEN
                SET @DtVencimentoFixo6 = f_monta_data_fixa(@nr_dias_pontualidade6 , @DtVencimento);
              ELSE
                -- para este tipo de calculo, usa-se o valor parametrizado em nr_dias_pontualidade, para achar
                -- o NN dia util do mes de vencimento aonde NN = nr_dias_pontualidade
                SET @DtVencimentoFixo6 = f_dia_util(@CdInstituicaoEnsino, ymd( year(@DtVencimento), month(@DtVencimento), @nr_dias_pontualidade6), @CdAnoExercicio, NULL, 1, @id_tipo_pontualidade6 )
              END IF;

              SELECT f_calculo_desconto_parcela(@IdMensalidade, @DtVencimentoFixo6, @IdContraApresentacao)
              INTO @VlDescPontualidade6;

              IF @id_tipo_pontualidade6 IN (1,2,5) THEN
                SET @VlBasedeCalculo = @VlMensalidadeBruto - @VlDescontoBruto;
              ELSE
                SET @VlBasedeCalculo = @VlMensalidade;
              END IF;

              IF @VlDescPontualidade6 > 0 THEN
                IF @nr_dias_pontualidade6 < 0 OR (@nr_dias_pontualidade6 >= 0 AND @DtVencimento >= @DtVencimentoFixo6) THEN
                  SET @VlTotalApenasPontualidade6 = @VlTotalApenasPontualidade6 + round( @VlBasedeCalculo * @pc_desconto_pontualidade6 / 100, 2 );
                ELSE
                  SET @VlTotalApenasPontualidade6 = @VlTotalApenasPontualidade6 - round( @VlDescontoBruto * @pc_desconto_pontualidade6 / 100, 2 );
                END IF;
              END IF;

              SET @VlTotalPagarPontualidade6 =  @VlTotalPagarPontualidade6 + (@VlMensalidadeBruto - @VlDescPontualidade6);

              IF @DsLiteralTotalEventoPontualidade6 = '' THEN
                SET @DsLiteralTotalEventoPontualidade6= @dsMoeda+' '+f_formata_valor(@VlMensalidadeBruto - @VlDescPontualidade6,',')+' '+@DsAbreviacao;
              ELSE
                SET @DsLiteralTotalEventoPontualidade6= @DsLiteralTotalEventoPontualidade6 + ' + '+ @dsMoeda+' '+f_formata_valor(@VlMensalidadeBruto - @VlDescPontualidade6,',')+' '+@DsAbreviacao;
              END IF;

            ELSE
              SELECT f_calculo_desconto_parcela(@IdMensalidade, @DtVencimentoFixo6, @IdContraApresentacao)
              INTO @VlDescPontualidade6;

              SET @VlTotalPagarPontualidade6 =  @VlTotalPagarPontualidade6 + (@VlMensalidadeBruto - @VlDescPontualidade6);
            END IF;

            IF @VlDescPontualidade1 > 0 THEN
              SET @VlTotalDescPontualidade1 = @VlTotalDescPontualidade1 + @VlDescPontualidade1;
            END IF;

            IF @VlDescPontualidade2 > 0 THEN
              SET @VlTotalDescPontualidade2 = @VlTotalDescPontualidade2 + @VlDescPontualidade2;
            END IF;

            IF @VlDescPontualidade3 > 0 THEN
              SET @VlTotalDescPontualidade3 = @VlTotalDescPontualidade3 + @VlDescPontualidade3;
            END IF;

            IF @VlDescPontualidade4 > 0 THEN
              SET @VlTotalDescPontualidade4 = @VlTotalDescPontualidade4 + @VlDescPontualidade4;
            END IF;

            IF @VlDescPontualidade5 > 0 THEN
              SET @VlTotalDescPontualidade5 = @VlTotalDescPontualidade5 + @VlDescPontualidade5;
            END IF;

            IF @VlDescPontualidade6 > 0 THEN
              SET @VlTotalDescPontualidade6 = @VlTotalDescPontualidade6 + @VlDescPontualidade6;
            END IF;
            -- fim do desconto por pontualidade

            SET @VlParcelaTotal = @VlParcelaTotal + @VlMensalidade;
            SET @VlDescontoTotal = @VlDescontoTotal + @VlDesconto;

            SET @DsAbreviacaoParcela   = ' '+@DsAbreviacao + ':'+@dsMoeda++' '+f_formata_valor(@VlMensalidade,',');
            SET @DsAbreviacaoParcelaEf   = ' '+@DsAbreviacaoEvento + ':'+@dsMoeda+' '+f_formata_valor(@VlMensalidade,',');

            IF @DsObsParcela IS NOT NULL AND trim(@DsObsParcela) <> '' THEN
              SET @DsObsParcelaBoleto = @DsObsParcelaBoleto+', ' + @DsObsParcela
            END IF;

            SET @DsInstrucoes = @DsInstrucoes + @DsAbreviacaoParcela;
            SET @DsInstrucoesEf = @DsInstrucoesEf + @DsAbreviacaoParcelaEf;

            SET @DsInstrucoesSemDesconto = @DsInstrucoesSemDesconto + ' '+@DsAbreviacao + ':'+@dsMoeda+' '+f_formata_valor(@VlMensalidadeBruto,',');

            SET @dsEventos = ' '+@dsEventos + @DsEventoParcela+ ', ';

            -- Adicionado espaços antes e após a vírgula por motivo de validação no Crystal,
            -- Banco 341, relat: r_carne_banco_341_26, FormulaField: TipoVencto
            SET @DsParcelas = @DsParcelas + convert(varchar(10),@NrParcela)+' , ';
            SET @DsAbreviacaoDescto = ' ';

            IF @VlDesconto > 0 AND @VlMensalidade > 0 THEN
              SET @PctDescto = (@VlDesconto * 100 / @VlMensalidade);
              SET @DsAbreviacaoDescto = ' '+@DsAbreviacao + ': '+@dsMoeda+' '+f_formata_valor(@VlDesconto,',')
            END IF;

            SET @DsInstrucoesDescto= @DsInstrucoesDescto + @DsAbreviacaoDescto;

            SET @DsParcelasRenegociadasDoc = '';

            IF @IdDocumento = 7 THEN
              DELETE #tmp_parcelaRenegociacao;

              -- eh uma parcela de renegociacao, é necessário colocar no "Parcelas" os nr_parcelas que geraram este documento
              INSERT INTO #tmp_parcelaRenegociacao
              SELECT convert(varchar(4), m.nr_parcela_msl) + '/' + convert(varchar(5), m.cd_ano_exercicio)
              FROM mensalidade_referencia mr, mensalidade m
              WHERE mr.id_responsavel_financeiro_de   = m.id_responsavel_financeiro
                AND mr.cd_atvd_secundaria_msl_de      = m.cd_atvd_secundaria_msl
                AND mr.cd_documento_de                = m.cd_documento
                AND mr.dt_vencimento_msl_de           = m.dt_vencimento_msl
                AND mr.nr_mensalidade_de              = m.nr_mensalidade
                AND mr.nr_matricula_de                = m.nr_matricula
                AND mr.cd_ano_exercicio_de            = m.cd_ano_exercicio
                AND mr.cd_aluno_de                    = m.cd_aluno
                AND mr.cd_curso_instituicao_de        = m.cd_curso_instituicao
                AND mr.id_responsavel_financeiro_para = @IdResponsavelFinanceiro
                AND mr.cd_atvd_secundaria_msl_para    = @CdAtvdMsl
                AND mr.cd_documento_para              = @IdDocumento
                AND mr.dt_vencimento_msl_para         = @DtVencimento
                AND mr.nr_mensalidade_para            = @NrMensalidade
                AND mr.nr_matricula_para              = @NrMatricula
                AND mr.cd_ano_exercicio_para          = @CdAnoExercicio
                AND mr.cd_aluno_para                  = @CdAluno
                AND mr.cd_curso_instituicao_para      = @CdCursoInstituicao
              ORDER BY 1;

              SELECT list(nr_parcela)
              INTO @DsParcelasRenegociadasDoc
              FROM #tmp_parcelaRenegociacao
            END IF;

            IF @CdBolsa <> 0 THEN
              SELECT ds_bolsa INTO @DsBolsa FROM bolsas
              WHERE cd_bolsa = @CdBolsa;

              IF @idDocumento = 1 OR @IdRegraDescontoBolsa IS NULL THEN
                SELECT id_regra_desconto INTO @IdRegraDescontoBolsa FROM bolsas
                WHERE cd_bolsa = @CdBolsa;
              END IF;

              IF @DsBolsaAluno <> @DsBolsa + ', ' THEN
                SET @DsBolsaAluno = @DsBolsaAluno + @DsBolsa + ', ';
              END IF;

              SET @VlBolsaAluno = @VlBolsaAluno + @VlBolsa;
            END IF;

            SET @VlDescComercialTotal = @VlDescComercialTotal + @VlDescComercial;

            IF @DsParcelasRenegociadasDoc <> '' THEN
              IF @DsParcelasRenegociadas <> '' THEN
                SET @DsParcelasRenegociadas = @DsParcelasRenegociadas + ', '+@DsParcelasRenegociadasDoc
              ELSE
                SET @DsParcelasRenegociadas = @DsParcelasRenegociadasDoc
              END IF
            END IF;

            FETCH NEXT c_parcela INTO @VlMensalidade, @VlDesconto, @IdDocumento, @CdAtvdMsl, @NrParcela, @NrBloqueto, @DtVencimento, @DtPrimeiraEmissao, @NrControleEmissao, @CdSituacaoParcela, @NrMensalidade, @CdBolsa, @VlBolsa, @IdMensalidade, @DsObsParcela;

            IF @NrBloqueto IS NULL OR @NrBloqueto = '' THEN
              SET @NrBloqueto = @NrBloquetoNovo
            END IF;
          END LOOP; -- fim LOOP c_parcela

          SELECT f_monta_mensagem_pontualidade(@DsDescPontualidade, @DtVencimento, @DtVencimentoFixo1, @VlTotalPagarPontualidade1, @DsLiteralTotalEventoPontualidade1, @nr_dias_pontualidade1, (@VlTotalMensalidadeBruto-@VlTotalPagarPontualidade1), abs(@VlTotalApenasPontualidade1))
          INTO @DsMsgPontualidade1;
          SELECT f_monta_mensagem_pontualidade(@DsDescPontualidade, @DtVencimento, @DtVencimentoFixo2, @VlTotalPagarPontualidade2, @DsLiteralTotalEventoPontualidade2, @nr_dias_pontualidade2, (@VlTotalMensalidadeBruto-@VlTotalPagarPontualidade2), abs(@VlTotalApenasPontualidade2))
          INTO @DsMsgPontualidade2;
          SELECT f_monta_mensagem_pontualidade(@DsDescPontualidade, @DtVencimento, @DtVencimentoFixo3, @VlTotalPagarPontualidade3, @DsLiteralTotalEventoPontualidade3, @nr_dias_pontualidade3, (@VlTotalMensalidadeBruto-@VlTotalPagarPontualidade3), abs(@VlTotalApenasPontualidade3))
          INTO @DsMsgPontualidade3;
          SELECT f_monta_mensagem_pontualidade(@DsDescPontualidade, @DtVencimento, @DtVencimentoFixo4, @VlTotalPagarPontualidade4, @DsLiteralTotalEventoPontualidade4, @nr_dias_pontualidade4, (@VlTotalMensalidadeBruto-@VlTotalPagarPontualidade4), abs(@VlTotalApenasPontualidade4))
          INTO @DsMsgPontualidade4;
          SELECT f_monta_mensagem_pontualidade(@DsDescPontualidade, @DtVencimento, @DtVencimentoFixo5, @VlTotalPagarPontualidade5, @DsLiteralTotalEventoPontualidade5, @nr_dias_pontualidade5, (@VlTotalMensalidadeBruto-@VlTotalPagarPontualidade5), abs(@VlTotalApenasPontualidade5))
          INTO @DsMsgPontualidade5;
          SELECT f_monta_mensagem_pontualidade(@DsDescPontualidade, @DtVencimento, @DtVencimentoFixo6, @VlTotalPagarPontualidade6, @DsLiteralTotalEventoPontualidade6, @nr_dias_pontualidade6, (@VlTotalMensalidadeBruto-@VlTotalPagarPontualidade6), abs(@VlTotalApenasPontualidade6))
          INTO @DsMsgPontualidade6;

          IF (@icAplicarRenegociacao = 0 AND @IdDocumento IN (7, 10)) OR @icRegraPontualidade = 0 THEN
            SET @DsMsgPontualidade1 = NULL;
            SET @DsMsgPontualidade2 = NULL;
            SET @DsMsgPontualidade3 = NULL;
            SET @DsMsgPontualidade4 = NULL;
            SET @DsMsgPontualidade5 = NULL;
            SET @DsMsgPontualidade6 = NULL;
          END IF;

          SELECT left(rtrim(@DsParcelas), length(rtrim(@DsParcelas))-1) INTO @DsParcelas;
          SELECT left(rtrim(@DsBolsaAluno), length(rtrim(@DsBolsaAluno))-1) INTO @DsBolsaAluno;

          IF @DsParcelasRenegociadas <> '' THEN
            SET @DsParcelas = @DsParcelas + ' - Renegociadas:'+ @DsParcelasRenegociadas
          END IF;

          SET @DsParcelasRenegociadas = '';

          SET @DsBairro      = '';
          SET @CdCep         = '';
          SET @NrCpf         = '';
          SET @NmResponsavel = '';
          SET @DsComplemento = '';
          SET @DsLogradouro  = '';
          SET @NmMunicipio   = '';
          SET @Uf            = '';
          SET @IdPessoa      = NULL;

          -- caso seja para enderecar a alguem DIFERENTE DO RESPONSÁVEL FINANCEIRO, coloca o reponsavel financeiro
          -- igual ao que foi escolhido em tela

          IF @IdEndereco <> 6 THEN
            SET @IdResponsavelFinanceiro = @IdEndereco;
            SELECT f_buscaPessoaRespAluno(@IdEndereco, @CdAluno) INTO @IdPessoa;
          ELSE
            SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 0 ) INTO @IdPessoa;
          END IF;
          SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 8 ) INTO @DsBairro;
          SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 4 ) INTO @CdCep;
          SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 12) INTO @NrCpf;
          SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 1 ) INTO @NmResponsavel;
          SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 3 ) INTO @DsComplemento;
          SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 2 ) INTO @DsLogradouro;
          SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 6 ) INTO @Uf;
          SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 5 ) INTO @NmMunicipio;

          SELECT conta_corrente.ds_msg1,
                 conta_corrente.ds_msg2,
                 conta_corrente.ds_msg3,
                 conta_corrente.ds_msg4,
                 conta_corrente.ds_msg5,
                 conta_corrente.ds_msg6,
                 conta_corrente.ds_msg7,
                 conta_corrente.ds_msg8,
                 conta_corrente.ds_msg9,
                 conta_corrente.ds_msg10
          INTO @DsMsg1,
               @DsMsg2,
               @DsMsg3,
               @DsMsg4,
               @DsMsg5,
               @DsMsg6,
               @DsMsg7,
               @DsMsg8,
               @DsMsg9,
               @DsMsg10
          FROM conta_corrente
          WHERE conta_corrente.cd_conta_corrente = @CdContaEmissao
            AND conta_corrente.cd_agencia        = @CdAgenciaEmissao
            AND conta_corrente.cd_banco          = @CdBancoEmissao;

          IF (@NmBancoDados = 'BD01028' OR @NmBancoDados = 'BD02001') AND @CdBancoEmissao = 347 AND @CdAnoExercicio = 2005 THEN
            SET @DsMsg1 = 'GRATUIDADE 5% JA CALCULADA NO VALOR A PAGAR ';
            SET @DsMsg2 = 'PONTUALIDADE1';
            SET @DsMsg3 = 'APOS VENCTO PAGAR R$378,10 + MULTA 2% E APOS 30D, +1% AO MES';
            SET @DsMsg4 = 'Após o vencimento pagamento apenas no banco SUDAMERIS'
          END IF;

          -- Verifica o debito automatico através da AtvdSec. após a última parcela

          IF   upper(@DsMsg1) = 'ATRASOS'
            OR upper(@DsMsg2) = 'ATRASOS'
            OR upper(@DsMsg3) = 'ATRASOS'
            OR upper(@DsMsg4) = 'ATRASOS'
            OR upper(@DsMsg5) = 'ATRASOS'
            OR upper(@DsMsg6) = 'ATRASOS'
            OR upper(@DsMsg7) = 'ATRASOS'
            OR upper(@DsMsg8) = 'ATRASOS'
            OR upper(@DsMsg9) = 'ATRASOS'
            OR upper(@DsMsg10) = 'ATRASOS'
          THEN
            SELECT F_nr_doctos_atrasados(@CdCursoInstituicao, @CdAluno, @CdAnoExercicio, @NrMatricula, DATE(GETDATE()))
            INTO @NrDoctosAtrasados;
          END IF;

          IF @NrDoctosAtrasados <> 0 THEN
            SELECT 'Voce possui '+convert(varchar(10),@NrDoctosAtrasados)+' parcela(s)/Docto(s) atrasados!'
            INTO @DsDoctosAtrasados

          ELSE
            SET  @DsDoctosAtrasados   = ''
          END IF;

          SELECT f_mensagem_atraso(@PcJuroMensal, @PcJuroDiario, @PcMulta, @VlParcelaTotal, @VlDescontoTotal, @IdRegraDesconto)
          INTO @DsMensagemAtraso;

          SET @DsInstrucoesdescto = trim(@DsInstrucoesdescto);

          IF @nrEventoBoleto = 1 THEN
            -- se este boleto FOR de apenas um evento financeiro, retira a abreviação do evento na mensagem de desconto
            SET @DsInstrucoesdescto = substring(@DsInstrucoesdescto, PATINDEX('%:%',@DsInstrucoesdescto)+1, 200);
            SET @DsInstrucoesdescto = trim(@DsInstrucoesdescto);
            SET @nrEventoBoleto = 0;
          END IF;

          SET @DsDescontoComercial = '';
          SET @DsDescontoBolsa  = '';

          SELECT f_dia_util(ci.cd_instituicao_ensino, ymd(year(@DtVencimento),month(@DtVencimento), 1 ), @CdAnoExercicio, NULL, 1, 0)
          INTO @DtPrimeiroDiaUtil
          FROM curso_instituicao ci
          WHERE ci.cd_curso_instituicao = @CdCursoInstituicao;

          IF @VlBolsaAluno > 0 THEN
            SET @DsDescontoBolsa = 'Conceder desconto de ' + @dsMoeda + ': ' + f_formata_valor(@VlBolsaAluno, ',') + ' referente a bolsa ' + @DsBolsaAluno;
            IF @IdRegraDescontoBolsa = 0 THEN
              SET @DsDescontoBolsa = @DsDescontoBolsa + ' até o vencimento'
            ELSEIF @IdRegraDescontoBolsa = 2 THEN
              SET @DsDescontoBolsa = @DsDescontoBolsa + ' até o dia ' + convert(varchar(10), @DtPrimeiroDiaUtil, 103);
            END IF;
          END IF;

          SET @dtVencimentoComFator = dateadd(dd,@NrDiasFatorVencimento, @DtVencimento);

          SELECT f_dia_util(@CdInstituicaoEnsino, @dtVencimentoComFator, @CdAnoExercicio, NULL, 2, 0)
          INTO @dtVencimentoComFator;

          IF @IdRegraDesconto = 0 AND @DsInstrucoesdescto IS NOT NULL AND @DsInstrucoesdescto <> '' THEN
            IF @NrDiasFatorVencimento > 0 THEN
              SET @DsInstrucoesdescto = 'Desconto de:' + @DsInstrucoesdescto + ' até o dia ' + convert(varchar(10), @DtVencimentoComFator, 103) + '.';
            IF @VlDescontoTotal > 0 THEN
              SET @DsInstrucoesdesctoTotal = 'Conceder desconto de ' + @dsMoeda + ' ' + f_formata_valor(@VlDescontoTotal, ',') + ' até o dia ' + convert(varchar(10), @dtVencimentoComFator, 103) + '.'
            END IF
          ELSE
            SET @DsInstrucoesdescto = 'Desconto de:' + @DsInstrucoesdescto + ' até o vencimento.';

            IF @VlDescontoTotal > 0 THEN
              SET @DsInstrucoesdesctoTotal = 'Conceder desconto de '+@dsMoeda+' '+f_formata_valor(@VlDescontoTotal,',')+ ' até o vencimento.'
            END IF
          END IF
        ELSEIF @IdRegraDesconto = 1 AND @DsInstrucoesdescto IS NOT NULL AND @DsInstrucoesdescto <> '' THEN
          SET @DsInstrucoesdescto = 'Desconto de:'+@DsInstrucoesdescto;

          IF @VlDescontoTotal > 0 THEN
            SET @DsInstrucoesdesctoTotal = 'Conceder desconto de '+@dsMoeda+' '+f_formata_valor(@VlDescontoTotal,',')
          END IF
        ELSEIF @IdRegraDesconto = 2 AND @DsInstrucoesdescto IS NOT NULL AND @DsInstrucoesdescto <> '' THEN
          SET @DsInstrucoesdesctoTotal = 'Conceder desconto de '+@dsMoeda+' '+f_formata_valor(@VlDescontoTotal,',')+ ' até o dia '+convert(varchar(10),@DtPrimeiroDiaUtil,103)+'.'
        END IF;

        IF @IdRegraDesconto = 0 AND @VlDescComercialTotal > 0  THEN
          IF @NrDiasFatorVencimento > 0 THEN
            SET @DsDescontoComercial = 'Descto comercial: '+@dsMoeda+' '+f_formata_valor(@VlDescComercialTotal,',')+ ' até o dia '+convert(varchar(10),@dtVencimentoComFator,103)+'.';
          ELSE
            SET @DsDescontoComercial = 'Descto comercial: '+@dsMoeda+' '+f_formata_valor(@VlDescComercialTotal,',')+ ' até o vencto.';
          END IF
        ELSEIF @IdRegraDesconto = 1 AND @VlDescComercialTotal > 0 THEN
          SET @DsDescontoComercial = 'Descto comercial de: '+@dsMoeda+' '+f_formata_valor(@VlDescComercialTotal,',');
        ELSEIF @IdRegraDesconto = 2 AND @VlDescComercialTotal > 0 THEN
          SET @DsDescontoComercial = 'Descto comercial:  '+@dsMoeda+' '+f_formata_valor(@VlDescComercialTotal,',')+ ' até o dia '+convert(varchar(10),@DtPrimeiroDiaUtil,103)+'.';
        END IF;

        SET @PcConvenio = NULL;
        SET @DsMensagemConvenio = '';

        SELECT c.nm_convenio,
               mcf.pc_convenio
        INTO @DsConvenio,
             @PcConvenio
        FROM matricula_convenio_financeiro mcf, convenio c
        WHERE c.cd_convenio = mcf.cd_convenio
          AND id_convenio = 1
          AND @DtVencimento  between  mcf.dt_inicio_convenio AND mcf.dt_final_convenio
          AND mcf.nr_matricula         = @NrMatricula
          AND mcf.cd_aluno             = @CdAluno
          AND mcf.cd_ano_exercicio     = @CdAnoExercicio
          AND mcf.cd_curso_instituicao = @CdCursoInstituicao;

        IF NOT @PcConvenio IS NULL AND @PcConvenio <> 0 THEN
          SELECT round(@VlParcelaTotal *  @PcConvenio / 100 ,2) INTO @VlDescontoConvenio;
          SET @DsMensagemConvenio = 'Convênio ' +@DsConvenio + ': Até o vencimento, desconto de '+@dsMoeda+' '+ f_formata_valor(@VlDescontoConvenio,',');
        END IF;

        SET @DsMensagemAcrescimo = '';

        IF @VlTaxaBancaria > 0 THEN
          SET @DsMensagemAcrescimo= 'Desconsiderar o acréscimo de '+@dsMoeda+' '+ f_formata_valor(@VlTaxaBancaria,',') +' se pago no colégio.'
        END IF;

        -- se a pessoa responsavel pela parcela FOR um adotador
        -- A MENSAGEM DE ATRASO, nao é apresentada no boleto

        IF exists (SELECT 1 FROM pessoa_adotador_aluno paa, pessoa_adotador pa WHERE pa.id_pessoa_adotador = @IdPessoa AND paa.id_pessoa_adotador = pa.id_pessoa_adotador AND ic_cobrar_juros = 'N') THEN
          SET @DsMensagemAtraso = '';
        END IF;

        SELECT list(DISTINCT tc.ds_tipo_curso || '/'||c.nm_curso)
        INTO @DsNomeCursos
        FROM tipo_curso tc, mensalidade me, curso_instituicao ci, curso c
        WHERE tc.cd_tipo_curso        = c.cd_tipo_curso
          AND c.cd_curso              = ci.cd_curso
          AND ci.cd_curso_instituicao = me.cd_curso_instituicao
          AND me.nr_documento         = @NrDocumento;

        IF TRIM(@DsObsParcelaBoleto) <> '' THEN
          SET @DsObsParcelaBoleto = LEFT(@DsObsParcelaBoleto, LEN(@DsObsParcelaBoleto)-2);
        END IF;

        IF TRIM(@dsEventos) <> '' THEN
          SET @dsEventos = LEFT(@dsEventos, LEN(@dsEventos)-2);
        END IF;

        SET @DsISS = '';
        SELECT f_monta_mensagem_ISS(@NrDocumento) INTO @DsISS;

        SELECT f_mensagens(upper(@DsMsg1),upper(@DsInstrucoes), upper(@NmInstituicao+ ' - '+@CdTurma), isnull((@DsInstrucoesdescto),''),ISNULL(upper(@NmResponsavel),''), @DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa, @dsEventos, @DsInstrucoesSemDesconto, upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg1;

        SELECT f_mensagens(upper(@DsMsg2),upper(@DsInstrucoes), upper(@NmInstituicao+ ' - '+@CdTurma), isnull((@DsInstrucoesdescto),''),ISNULL(upper(@NmResponsavel),''), @DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa, @dsEventos, @DsInstrucoesSemDesconto  , upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg2;

        SELECT f_mensagens(upper(@DsMsg3),upper(@DsInstrucoes), upper(@NmInstituicao+ ' - '+@CdTurma), isnull((@DsInstrucoesdescto),''),ISNULL(upper(@NmResponsavel),''), @DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa, @dsEventos, @DsInstrucoesSemDesconto  , upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg3;

        SELECT f_mensagens(upper(@DsMsg4),upper(@DsInstrucoes), upper(@NmInstituicao+ ' - '+@CdTurma), isnull((@DsInstrucoesdescto),''),ISNULL(upper(@NmResponsavel),''), @DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa, @dsEventos, @DsInstrucoesSemDesconto  , upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg4;

        SELECT f_mensagens(upper(@DsMsg5),upper(@DsInstrucoes), upper(@NmInstituicao+ ' - '+@CdTurma), isnull((@DsInstrucoesdescto),''),ISNULL(upper(@NmResponsavel),''), @DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa, @dsEventos, @DsInstrucoesSemDesconto  , upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg5;

        SELECT f_mensagens(upper(@DsMsg6),upper(@DsInstrucoes), upper(@NmInstituicao+ ' - '+@CdTurma), isnull((@DsInstrucoesdescto),''),ISNULL(upper(@NmResponsavel),''), @DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa, @dsEventos, @DsInstrucoesSemDesconto  , upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg6;

        SELECT f_mensagens(upper(@DsMsg7),upper(@DsInstrucoes), upper(@NmInstituicao+ ' - '+@CdTurma), isnull((@DsInstrucoesdescto),''),ISNULL(upper(@NmResponsavel),''), @DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa, @dsEventos, @DsInstrucoesSemDesconto  , upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg7;

        SELECT f_mensagens(upper(@DsMsg8),upper(@DsInstrucoes), upper(@NmInstituicao+ ' - '+@CdTurma), isnull((@DsInstrucoesdescto),''),ISNULL(upper(@NmResponsavel),''), @DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa, @dsEventos, @DsInstrucoesSemDesconto  , upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg8;

        SELECT f_mensagens(upper(@DsMsg9),upper(@DsInstrucoes), upper(@NmInstituicao+ ' - '+@CdTurma), isnull((@DsInstrucoesdescto),''),ISNULL(upper(@NmResponsavel),''), @DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa, @dsEventos, @DsInstrucoesSemDesconto  , upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg9;

        SELECT f_mensagens(upper(@DsMsg10),upper(@DsInstrucoes), upper(@NmInstituicao+ ' - '+@CdTurma), isnull((@DsInstrucoesdescto),''),ISNULL(upper(@NmResponsavel),''), @DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa, @dsEventos, @DsInstrucoesSemDesconto  , upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg10;

        IF @idTipoFormaCobranca = 4 THEN
          IF upper(@DsMsgDebito) = '@BANCODEBITOCONTA' THEN
            SELECT nm_banco INTO @nmBancoDebito FROM banco WHERE cd_banco = @cdBancoDebitoAuto;
            SET @DsMsgDebito = 'DÉBITO AUTOMÁTICO NO BANCO: '+UPPER(@nmBancoDebito);
          END IF;

          IF @Banco <> 1 AND @Banco <> 41 THEN
            -- para o BB e Banrisul mostra tb as demais mensagens.
            SET @DsMsg1 = '';
            SET @DsMsg2 = '';
            SET @DsMsg3 = '';
            SET @DsMsg4 = '';
            SET @DsMsg5 = '';
            SET @DsMsg6 = '';
            SET @DsMsg7 = '';
            SET @DsMsg8 = '';
            SET @DsMsg9 = '';
            SET @DsMsg10 = '';
          END IF
        END IF;

        IF (@IdValorDocumento IN (2,3,4) AND @VlParcelaTotal > 0 ) OR ( @IdValorDocumento = 1  AND (@VlParcelaTotal - @VlDescontoTotal) > 0 ) THEN
          -- caso o valor do boleto seja MENOR Q ZERO, nao emite o documento

          IF @Banco <> 55 AND @Banco <> 1 AND @Banco <> 422 AND @Banco <> 41 AND @Banco <> 104 AND @Banco <> 347 AND @Banco <> 707 AND @Banco <> 356 AND @Banco <> 237 AND @Banco <> 275 AND @Banco <> 341  AND @Banco <> 399 AND @Banco <> 409 AND @Banco <> 33 AND @Banco <> 291  AND @Banco <> 748 AND @Banco <> 756 AND @Banco <> 8 AND @Banco <> 389  AND @NrTipoConta <> 'T338' THEN
            -- Tirando o DV da ContaCorrente e da Agencia
            SET @CdAgencia = SUBSTRING( @CdAgencia,1 , LENGTH( @CdAgencia)-1);
            SET @CdContaCorrente= SUBSTRING( @CdContaCorrente,1 , LENGTH( @CdContaCorrente)-1);
          END IF;

          -- Atualmente, somente o BESC usa esta variável
          SET @DsAnoVencto = right(convert(varchar(4),year(@DtVencimento)),1);

          CASE @Banco
            -- tratamento especifico para o BB e suas cooperativas
            -- hoje tratamos as cooperativas '0005' e '0236' são codigos de cooperativas CECRED, conforme novos clientes forem utilizando novas acrescentar aqui
            -- n_recebimento_via_arquivo , pr_carne_banco, pr_arquivo_banco e f_CalculaCodigoBarras também tem referencia a estas cooperativas
            WHEN 1 THEN -- BB
              IF (right('00'+@DsCarteira,2) = '17' OR right('00'+@DsCarteira,2) = '31') AND upper(isnull(@NrTipoConta,'')) <> 'CONV7'  AND upper(isnull(@NrTipoConta,'')) NOT IN ('0005','0236') THEN
                SELECT right('000000'+@DsContrato,6)+right('00000'+ @NrBloqueto,5) INTO @NrBloquetoReal;
                SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto

              ELSEIF right('00'+@DsCarteira,2) = '18' AND upper(isnull(@NrTipoConta,'')) = '17POS' THEN
                -- carteira 18 nosso nro com 17 posicoes / sem registro
                SELECT right('00000000000000000'+ @NrBloqueto,17) INTO @NrBloquetoReal;
                SET @DsDigitoBloqueto = '';

              ELSEIF (right('00'+@DsCarteira,2) = '18' OR right('00'+@DsCarteira,2) = '17' OR right('00'+@DsCarteira,2) = '11')  AND upper(isnull(@NrTipoConta,'')) = 'CONV7' THEN
                -- convenio com 7 posicoes e nr bloqueto composto
                SELECT right('0000000'+@DsContrato,7)+right('0000000000'+ @NrBloqueto,10) INTO @NrBloquetoReal;
                SET @DsDigitoBloqueto = '';

              ELSEIF (right('00'+@DsCarteira,2) = '18' OR right('00'+@DsCarteira,2) = '17' OR right('00'+@DsCarteira,2) = '11')  AND upper(isnull(@NrTipoConta,'')) IN ('0005','0236') THEN
                -- convenio especial para a CECRED - cooperativa vinculada a o BB
                -- convenio com 7 posicoes e nr bloqueto composto
                SELECT right('0000000'+@DsContrato,7)+@NrTipoConta+right('000000'+ @NrBloqueto,6) INTO @NrBloquetoReal;
                SET @DsDigitoBloqueto = '';

              ELSEIF right('00'+@DsCarteira,2) = '18' AND upper(isnull(@NrTipoConta,'')) <> '17POS' AND upper(isnull(@NrTipoConta,'')) <> 'CONV7' AND upper(isnull(@NrTipoConta,'')) NOT IN ('0005','0236') THEN
                SELECT right('000000'+@DsContrato,6)+right('00000'+ @NrBloqueto,5) INTO @NrBloquetoReal;
                SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto

              ELSE
                SELECT right('00000000000000000'+ @NrBloqueto,17) INTO @NrBloquetoReal;
                SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto
              END IF

            WHEN 422 THEN -- SAFRA
              SET @NrBloquetoReal = right('000000000'+rtrim(convert(char(8),@NrBloqueto)),9);
              SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto

            WHEN 8 THEN -- MERIDIONAL mensalidade
              SET @NrBloquetoSant = right('000000000000'+rtrim(convert(char(8),@NrBloqueto)),12);
              SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoSant) INTO @DsDigitoBloqueto

            --douglas
            WHEN 27 THEN -- BESC
              IF @NrCnab = 400 AND @NrTipoConta <> 'T336' THEN
                SELECT '1'+right('000000'+ @NrBloqueto,6) INTO @NrBloquetoReal;
                SELECT f_Modulo11_peso9_0(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
                SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto

              ELSEIF @NrCnab = 340 AND @IdTipoCarne = 2 THEN
                SET @DsDigitoDesconto = 0;

                IF @CdInstituicaoLogin = 24 THEN
                  -- para o cepu o ultimo caracter do nr_bloqueto, mostra qual o pct de desconto
                  /*
                      0 =  5%
                      1 = 10%
                      2 = 15%
                      3 = 20%
                      4 =  7%
                      5 = 25%
                      6 =  0
                      7 = 30%
                  */
                  SET @PcDescontoTotal = round((@VlDescontoTotal * 100) / @VlParcelaTotal,0);

                  IF @PcDescontoTotal = 5 THEN
                    SET @DsDigitoDesconto = 0
                  ELSEIF @PcDescontoTotal = 10 THEN
                    SET @DsDigitoDesconto = 1
                  ELSEIF @PcDescontoTotal = 15 THEN
                    SET @DsDigitoDesconto = 2
                  ELSEIF @PcDescontoTotal = 20 THEN
                    SET @DsDigitoDesconto = 3
                  ELSEIF @PcDescontoTotal = 7 THEN
                    SET @DsDigitoDesconto = 4
                  ELSEIF @PcDescontoTotal = 25 THEN
                    SET @DsDigitoDesconto = 5
                  ELSEIF @PcDescontoTotal = 30 THEN
                    SET @DsDigitoDesconto = 7
                  ELSE
                    SET @DsDigitoDesconto = 6
                  END IF
                END IF;

                SET @NrBloquetoBesc = right('0000000000000'+ @DsAnoVencto + right('000000000'+@NrBloqueto,9) + right('00'+convert(varchar(10),@NrParcela),2) + right('0'+convert(varchar(1),@DsDigitoDesconto),1),13);

                SELECT f_Modulo11_peso9_0(@Banco,@NrBloquetoBesc) INTO @DsDigitoBloqueto;
                -- para o BESC tem o "3" fixo e sao dois calculos de digito
                SET @NrBloquetoReal    = @NrBloquetoBesc+@DsDigitoBloqueto+'3';
                SELECT f_Modulo11_peso9_0(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
                SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto

              ELSEIF @NrTipoConta = 'T336' THEN
                SELECT right('0000000000000'+ @NrBloqueto,13) INTO @NrBloquetoReal;
                SELECT f_Modulo11_peso9_0(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
                -- para o BESC tem o "3" fixo e sao dois calculos de digito
                SELECT @NrBloquetoReal+@DsDigitoBloqueto+'3' INTO @NrBloquetoReal;
                SELECT f_Modulo11_peso9_0(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
                SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto

              ELSE
                SELECT right('0000000000000'+ @NrBloqueto,13) INTO @NrBloquetoReal;
                SELECT f_Modulo11_peso9_0(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
                -- para o BESC tem o "3" fixo e sao dois calculos de digito
                SELECT @NrBloquetoReal+@DsDigitoBloqueto+'3' INTO @NrBloquetoReal;
                SELECT f_Modulo11_peso9_0(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
                SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto
              END IF;

            WHEN 33 THEN -- BANESPA
              IF @Banco = 33 AND @NrTipoConta = 'MIGRA' THEN
                --  especifico para o MARISTA, é o novo layout do banco 33 ( que é igual ao do 353 )
                IF @NrCnab = 400 THEN
                  SET @NrBloquetoSant = right('000000000000'+rtrim(convert(char(8),@NrBloqueto)),12);
                  SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoSant) INTO @DsDigitoBloqueto;
                ELSE
                  SET @NrBloquetoSant = right('000000000000'+rtrim(@NrBloqueto),12);
                  SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoSant) INTO @DsDigitoBloqueto;
                END IF
              ELSE
                -- Com registro
                SET @NrBloquetoReal = right('000'+rtrim(convert(char(3),@CdAgencia)),3) + right('0000000'+ @NrBloqueto,7);
                SELECT f_Modulo10_Banespa(@NrBloquetoReal) INTO @DsDigitoBloqueto;
                SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto
              END IF;

            WHEN 353 THEN
              -- Para o BANCO SANTANDER
              IF @NrCnab = 400 THEN
                SET @NrBloquetoSant = right('000000000000'+rtrim(convert(char(8),@NrBloqueto)),12);
                SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoSant) INTO @DsDigitoBloqueto;
              ELSE
                SET @NrBloquetoSant = right('000000000000'+rtrim(@NrBloqueto),12);
                SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoSant) INTO @DsDigitoBloqueto;
              END IF

            WHEN 389 THEN -- BANCO MERCANTIL
              IF right('00'+@DsCarteira,2) = '06' THEN
                SET @NrBloquetoReal = right('0000000000'+ @NrBloqueto,10);
                SET @NrBloquetoCalculo = right('0000000000'+ @NrBloqueto,10);
                -- concatena a agencia ao boleto APENAS PARA CALCULAR O DIGITO
                SET @NrBloquetoCalculo = right('0000'+SUBSTRING( @CdAgencia,1 , LENGTH( @CdAgencia)-1),4) + @NrBloquetoCalculo;
                SELECT f_Modulo11Peso_9(@Banco, @NrBloquetoCalculo) INTO @DsDigitoBloqueto;
              ELSE
                SET @NrBloquetoReal = right('0000000000'+ @NrBloqueto,10);
                SELECT f_Modulo11Peso_9(@Banco, @NrBloquetoReal) INTO @DsDigitoBloqueto;
              END IF;

            WHEN 41 THEN -- BANRISUL
              SET @NrBloquetoReal = right('0000000000'+ @NrBloqueto,10);
              SELECT f_Modulo10Peso_2_1(@NrBloquetoReal) INTO @DsDigitoBloqueto;
              SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto;
              SELECT f_Modulo11Peso_7(@Banco,@NrBloquetoReal) INTO @NrBloquetoReal;

            WHEN 104 THEN
              IF right('00'+@DsCarteira,2) = '14' AND upper(isnull(@NrTipoConta,'')) <> 'SIGCB' THEN
                SELECT '82'+right('00000000'+ @NrBloqueto,8) INTO @NrBloquetoReal;
                SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto

              ELSEIF right('00'+@DsCarteira,2) = 'SR' AND upper(isnull(@NrTipoConta,'')) <> 'SIGCB' THEN
                -- cobranca sem registro SR
                SELECT '82'+right('00000000'+ @NrBloqueto,8) INTO @NrBloquetoReal;
                SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto

              ELSEIF right('00'+@DsCarteira,2) = '12' AND upper(isnull(@NrTipoConta,'')) <> 'SIGCB' THEN
                -- cobranca rapida CR
                SELECT '9'+right('000000000'+ @NrBloqueto,9) INTO @NrBloquetoReal;
                SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto

              ELSEIF (right('00'+@DsCarteira,2) = '01' OR right('00'+@DsCarteira,2) = '24'  ) AND upper(isnull(@NrTipoConta,'')) <> 'SIGCB' THEN
                -- cobranca nOSSO NR de 19 posições
                -- calculando o digito do bloqueto
                SELECT f_Modulo11Peso_9(@Banco,'9'+right('00000000000000000'+ @NrBloqueto,17)) INTO @DsDigitoBloqueto;
                SET @NrBloquetoReal  = '9'+right('00000000000000000'+ @NrBloqueto,17);

              ELSEIF upper(isnull(@NrTipoConta,'')) = 'SIGCB' THEN
                IF @IdRegistroCarteira = 0then
                  SET @IdRegistroCarteira = 2;  -- para a CEF sem registro é 2
                END IF;
                -- GERANDO NO NOVO PADRAO SIGCB
                -- calculando o digito do bloqueto
                SELECT f_Modulo11Peso_9(@Banco,@IdRegistroCarteira|| @dsTipoImpressao  ||right('000000000000000'+ @NrBloqueto,15)) INTO @DsDigitoBloqueto;
                SET @NrBloquetoReal  = @IdRegistroCarteira|| @dsTipoImpressao  ||right('000000000000000'+ @NrBloqueto,15);

              ELSE
                -- Para a Caixa Economica, para as cobrancas 870, em geral a carteira eh 8
                -- o nosso numero tem 16 digitos Carteira+14numeros+dig
                SELECT '8'+right('00000000000000'+ @NrBloqueto,14) INTO @NrBloquetoReal;
                SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto
              END IF

            WHEN 275 THEN -- Para o BANCO REAL
              SELECT right('0000000'+ @NrBloqueto,7)+right('0000'+ @CdAgencia,4)+right('0000000'+ @CdContaCorrente,7) INTO @NrBloquetoReal;
              SELECT f_Modulo10Peso_2_1(@NrBloquetoReal) INTO @DsDigitoBloqueto

            WHEN 356 THEN -- Para o BANCO ABN - REAL
              -- para calcular o DIGITAO retira-se os digitos da agencia e da conta corrente.
              IF right('00'+@DsCarteira,2) = '57'  THEN
                SELECT right('0000000000000'+ @NrBloqueto,13)+right('0000'+ SUBSTRING( @CdAgencia,1 , LENGTH( @CdAgencia)-1),4)+right('0000000'+ SUBSTRING( @CdContaCorrente,1 , LENGTH( @CdContaCorrente)-1),7) INTO @NrBloquetoReal
              ELSE
                SELECT right('0000000'+ @NrBloqueto,7)+right('0000'+ SUBSTRING( @CdAgencia,1 , LENGTH( @CdAgencia)-1),4)+right('0000000'+ SUBSTRING( @CdContaCorrente,1 , LENGTH( @CdContaCorrente)-1),7) INTO @NrBloquetoReal
              END IF;
              SELECT f_Modulo10Peso_2_1(@NrBloquetoReal) INTO @DsDigitoBloqueto;

            WHEN 347 THEN -- Para o SUDAMERIS
              -- para calcular o DIGITAO retira-se os digitos da agencia e da conta corrente.
              IF right('00'+@DsCarteira,2) = '57'  THEN
                SELECT right('0000000000000'+ @NrBloqueto,13)+right('0000'+ SUBSTRING( @CdAgencia,1 , LENGTH( @CdAgencia)-1),4)+right('0000000'+ SUBSTRING( @CdContaCorrente,1 , LENGTH( @CdContaCorrente)-1),7) INTO @NrBloquetoReal
              ELSE
                SELECT right('0000000'+ @NrBloqueto,7)+right('0000'+ SUBSTRING( @CdAgencia,1 , LENGTH( @CdAgencia)-1),4)+right('0000000'+ SUBSTRING( @CdContaCorrente,1 , LENGTH( @CdContaCorrente)-1),7) INTO @NrBloquetoReal
              END IF;
              SELECT f_Modulo10Peso_2_1(@NrBloquetoReal) INTO @DsDigitoBloqueto;

            WHEN 707 THEN -- Para o BANCO DAYCOVAL
              SELECT f_Modulo11Peso_7(@Banco,right('0000'+@DsCarteira,4)+right('00000000000'+@NrBloqueto,11)) INTO @DsDigitoBloqueto

            WHEN 237 THEN -- Para o BANCO BRADESCO
              SELECT f_Modulo11Peso_7(@Banco,right('0000'+@DsCarteira,4)+right('00000000000'+@NrBloqueto,11)) INTO @DsDigitoBloqueto

            WHEN 291 THEN -- BCN
              SET @NrBloquetoReal = right('0000000000000'+ @NrBloqueto,13);
              SELECT f_Modulo10Peso_2_1(@NrBloquetoReal) INTO @DsDigitoBloqueto;
              SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto;
              SELECT f_Modulo11Peso_7(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
              SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto;

            WHEN 341 THEN -- Para o ITAU
              -- caso a agencia do ITAU esteja cadastrada COM O DIGITO, ELE SERA RETIRADO
              IF length(@CdAgencia) > 4 THEN
                SET @CdAgencia = SUBSTRING( @CdAgencia,1 , LENGTH( @CdAgencia)-1)
              END IF;
              -- a conta vai sem o DIGITO
              IF right('000'+@DsCarteira,3) = '103' THEN
                --sao iguais
                SET @NrBloquetoItau = right('0000'+rtrim(convert(char(4),@CdAgencia)),4) +
                      right('00000'+ SUBSTRING( @CdContaCorrente,1 , LENGTH( @CdContaCorrente)-1),5)+
                      right('000'+rtrim(@DsCarteira),3) +
                      right('00000000'+rtrim(convert(char(8),@NrBloqueto)),8);
              ELSE
                SET @NrBloquetoItau = right('0000'+rtrim(convert(char(4),@CdAgencia)),4) +
                      right('00000'+ SUBSTRING( @CdContaCorrente,1 , LENGTH( @CdContaCorrente)-1),5)+
                      right('000'+rtrim(@DsCarteira),3) +
                      right('00000000'+rtrim(convert(char(8),@NrBloqueto)),8);
              END IF;

              SELECT f_Modulo10Peso_2_1(@NrBloquetoItau) INTO @DsDigitoBloqueto;

            WHEN 399 THEN -- Para o HSBC
              IF @NrTipoConta = 'DRTVA' THEN
                -- cobranca diretiva
                SELECT right('00000000000'+ @NrBloqueto,11) INTO @NrBloquetoReal;
                SELECT f_Modulo11Peso_7(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
                SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto;
              ELSE
                SELECT right('0000000000'+ @NrBloqueto,10) INTO @NrBloquetoReal;
                SELECT f_Modulo11peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
                -- para o HSBC tem o "4" fixo e EH O TIPO IDENTIFICADOR
                SELECT @NrBloquetoReal+@DsDigitoBloqueto+'4' INTO @NrBloquetoReal;
                -- segundo digito / somar a data de vencimento com o Cd_Contrato (Cod. Cedente)
                SELECT convert(varchar(10), @DtVencimento  ,104)  INTO @ds_DtVencimento;
                SELECT substring(@ds_DtVencimento,1,2)+substring(@ds_DtVencimento,4,2)+substring(@ds_DtVencimento,9,2) INTO @ds_DtVencimento;
                SELECT f_Modulo11peso_9(@Banco, convert(varchar(30),convert(numeric(20),@NrBloquetoReal)+convert(numeric(20),@ds_DtVencimento)+convert(numeric(20),@DsContrato))) INTO @DsDigitoBloqueto;
                SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto;
              END IF;

            WHEN 409 THEN -- Para o UNIBANCO
              IF @NrCnab = 999 THEN -- Sem registro
                SET @NrBloquetoReal = right('00000000000000'+ @NrBloqueto,14);
                SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
                SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto
              ELSE -- Com registro
                -- calcula o digito verificador
                SET @NrBloquetoReal = @NrBloqueto;
                SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
                SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto;
                -- calcula o SUPER Digito verificador
                SET NrBloquetoReal = right('00000000000'+ @NrBloquetoReal,11);
                SELECT f_Modulo11Peso_9(@Banco,'1'+@NrBloquetoReal) INTO @DsDigitoBloqueto;
                SET @NrBloquetoReal = right('00000000000'+ @NrBloquetoReal,11)+@DsDigitoBloqueto;
              END IF;

            WHEN 748 THEN -- SICREDI
              -- Agencia vai para o calculo do digito , sem os seus respectivos digitos
              IF @NrTipoConta IS NULL OR @NrTipoConta = 'NULO' THEN
                -- sicredi guarda-se o posto de atendimento no nr_tipo_conta , se nao tiver nada usa fixo o posto 16 ( estava assim para o cliente 018)
                --'16' É POSTO  - fixo para o bd01018
                SET @dsPosto = '16'
              ELSE
                SET @dsPosto = convert(varchar(10), @NrTipoConta)
              END IF;

              SET @dsPosto = right('00'+@dsPosto,2);

              SELECT right('0000'+SUBSTRING( @CdAgencia,1 , LENGTH( @CdAgencia)-1),4) + @dsPosto + right('00000'+SUBSTRING( @CdContaCorrente,1 , LENGTH( @CdContaCorrente)-1),5)+ right('00000000'+ @NrBloqueto,8) INTO @NrBloquetoReal;
              SELECT f_Modulo11Peso_9(@Banco, @NrBloquetoReal) INTO @DsDigitoBloqueto;

            WHEN 756 THEN -- bancoob
              IF @NrTipoConta = '999' THEN
                -- sem registro monta o NN com AnoEmissao (00) + nr_boleto 6 caracteres
                --nao precisa calcular digito
                SELECT right('000000'+ @NrBloqueto,6) INTO @NrBloquetoReal;
                SELECT '' INTO @DsDigitoBloqueto;
        
       ELSEIF   @NrTipoConta = 'SREGI' THEN      -- sem registro MAS  com calculo de digito no boleto
                --nao precisa calcular digito
                SELECT right('000000'+ @NrBloqueto,6) INTO @NrBloquetoReal;
                SELECT '' INTO @DsDigitoBloqueto;
        SELECT right('0000' + @CdAgencia, 4) + right('000000000' + @DsContrato, 10) + right('0000000' + @NrBloqueto, 7) INTO @NrBloquetoReal;
        SELECT f_Modulo11_bancoob(@Banco, @NrBloquetoReal) INTO @DsDigitoBloqueto;
  
              ELSE
          -- foi necessário colocar um IF aqui para evitar problema com os clientes que já usam o banco 756 e estavam calculado o digito do boleto 
          -- SEM considerar o digito da agencia, apesar do layout falar que o digito DEVE ser levado em consideração mas até 04/02/2014 estava sendo calculado SEM
          -- e não tinha nenhuma reclamação - Entao para evitar problemas de recusa de boletos de clientes que já estão em pleno funcionamento decidimos separar
          -- o cliente 270 para fazer o calculo COM o digita da agencia, todas as proximas validações do banco 756(sicoob) devem entrar JUNTO com o 270 ( depois ver como melhorar o IF para não ter que colocar cada banco individualmente) 
          IF @NmBancoDados = 'BD01270' OR @NmBancoDados = 'BD01124'  then
          SELECT right('0000' + @CdAgencia, 4) + right('000000000' + @DsContrato, 10) + right('0000000' + @NrBloqueto, 7) INTO @NrBloquetoReal;
          else
          SELECT right('0000' + SUBSTRING(@CdAgencia, 1, LENGTH(@CdAgencia) - 1), 4) + right('000000000' + @DsContrato, 10) + right('0000000' + @NrBloqueto, 7) INTO @NrBloquetoReal;
          end if ;

                  SELECT f_Modulo11_bancoob(@Banco, @NrBloquetoReal) INTO @DsDigitoBloqueto;

              END IF;
            END CASE;

            -- Codigo de Barras
            IF @IdContraApresentacao = 1 THEN
              SET @DtVencimento = '1997-10-07'
            END IF;

            IF @Banco = 27 THEN
              IF @NrCnab = 400 THEN
                IF @NrTipoConta = 'T338' THEN
                  SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, 'T338', @NrBloquetoReal,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
                ELSEIF @NrTipoConta = 'T336' THEN
                  SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, 'T336', @NrBloquetoReal,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
                ELSE
                  SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, 'T400', @NrBloquetoReal,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
                END IF
              ELSEIF @NrCnab = 340 AND @IdTipoCarne = 2 THEN
                SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, 'T340', @NrBloquetoBesc,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
              ELSE
                SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloquetoReal,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
              END IF;
            ELSEIF @Banco = 341 AND @CdInstituicaoLogin = 26 THEN
              SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras

            ELSEIF @Banco = 409 THEN
              IF @NrCnab = 999 THEN
                SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, '999', @NrBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
              ELSE
                SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloquetoReal,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
              END IF;

            ELSEIF @Banco = 33 AND @NrTipoConta = 'MIGRA' THEN
              -- no santander o boleto vai com o digito para o Cd de barras
              SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloqueto+@DsDigitoBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
            ELSEIF @Banco = 353 OR @Banco = 8 THEN
              -- no santander o boleto vai com o digito para o Cd de barras
              SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloqueto+@DsDigitoBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
            ELSEIF @Banco = 748 THEN
              -- no SICREDI o boleto vai com o digito para o Cd de barras
              SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloqueto+@DsDigitoBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
            ELSEIF @Banco = 104 AND ( right('00'+@DsCarteira,2) = '14' OR upper(isnull(@NrTipoConta,'')) = 'SIGCB') THEN
              SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloquetoReal,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
            ELSEIF @Banco = 389 THEN
              -- MERCANTIL
              -- NO CAMPO @DsCarteira, mando a informação nao ter desconto umavezque o nosso desconto vai apenas na mensagem ou já imbutido na parcela

              SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloqueto+@DsDigitoBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , '2', @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
            ELSEIF @Banco = 756 THEN
              -- o BANCOOB
              SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloqueto+@DsDigitoBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras

            ELSEIF @Banco = 399 THEN
              -- o HSBC
              IF @NrTipoConta = 'DRTVA' THEN
                SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloqueto+@DsDigitoBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
              ELSE
                SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
              END IF;
            ELSE
              SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
            END IF;

            SELECT f_CodigoBarraRepresentacao(@Banco, @DsCarteira, @NrCnab, @DsCodigoBarras) INTO @DsCodigoRepresentacao;

            SELECT f_CodigoBarra2of5(@DsCodigoBarras) INTO @DsCodigoBarrasAzalea;

            -- O código de barras agora é retornado no formato do número e sua conversão é feita no relatório
            -- SELECT @DsCodigoBarrasAzalea = @DsCodigoBarras;

            IF @idAtualizarVencimento = 'SIM' THEN
              UPDATE mensalidade me
              SET nr_bloqueto         = @NrBloqueto,
                  cd_usuario          = @CdUsuario,
                  dt_primeira_emissao = @DtPrimeiraEmissao,
                  dt_vencimento_msl   = @DtVencimento
              FROM situacao_mensalidade sm
              WHERE sm.cd_situacao                  = me.cd_situacao
                AND isnull(trim(me.nr_bloqueto),'') = ''
                AND sm.cd_situacao_financeira      IN ( 10,1)
                AND me.nr_documento                 = @NrDocumento;
            ELSE
              UPDATE mensalidade me
              SET nr_bloqueto         = @NrBloqueto,
                  cd_usuario          = @CdUsuario,
                  dt_primeira_emissao = @DtPrimeiraEmissao
              FROM situacao_mensalidade sm
              WHERE sm.cd_situacao                  = me.cd_situacao
                AND isnull(trim(me.nr_bloqueto),'') = ''
                AND sm.cd_situacao_financeira      IN ( 10,1)
                AND me.nr_documento                 = @NrDocumento;
            END IF;

            -- Atualiza o Nr. Controle de Emissao toda vez q reemitir o bloqueto.
            UPDATE mensalidade me
            SET nr_controle_emissao    = @NrControleEmissao,
                cd_usuario             = @CdUsuario,
                id_contra_apresentacao = @IdContraApresentacao,
                ds_codigo_barra        = @DsCodigoBarras,
                ds_linha_digitavel     = @DsCodigoRepresentacao
            FROM situacao_mensalidade sm
            WHERE sm.cd_situacao            = me.cd_situacao
              AND sm.cd_situacao_financeira IN ( 10,1)
              AND me.nr_documento           = @NrDocumento;

            COMMIT;

            -- montando o nr-bloqueto, pro BESC eh diferenciado

            IF @Banco = 1 THEN
              -- tratamento especifico para o BB e suas cooperativas
              -- hoje tratamos as cooperativas '0005' e '0236' são codigos de cooperativas CECRED, conforme novos clientes forem utilizando novas acrescentar aqui
              -- n_recebimento_via_arquivo , pr_carne_banco, pr_arquivo_banco e f_CalculaCodigoBarras também tem referencia a estas cooperativas

              IF (right('00'+@DsCarteira,2) = '17' OR right('00'+@DsCarteira,2) = '31') AND upper(isnull(@NrTipoConta,'')) <> 'CONV7' AND upper(isnull(@NrTipoConta,'')) NOT IN ('0005','0236') THEN
                SET @NrBloqueto = right('000000'+@DsContrato,6)+right('00000'+ @NrBloqueto,5) + '-' + @DsDigitoBloqueto;
              ELSEIF right('00'+@DsCarteira,2) = '18' AND upper(isnull(@NrTipoConta,'')) = '17POS' THEN
                -- carteira 18 nosso nro com 17 posicoes
                SET @NrBloqueto = @NrBloquetoReal
              ELSEIF (right('00'+@DsCarteira,2) = '18' OR right('00'+@DsCarteira,2) = '17' OR right('00'+@DsCarteira,2) = '11')  AND upper(isnull(@NrTipoConta,'')) = 'CONV7' THEN
                -- carteira 18 nosso nro com 17 posicoes
                SET @NrBloqueto = @NrBloquetoReal
              ELSEIF ( right('00'+@DsCarteira,2) = '18' OR right('00'+@DsCarteira,2) = '17' OR right('00'+@DsCarteira,2) = '11')  AND upper(isnull(@NrTipoConta,'')) IN ('0005','0236') THEN
                -- convenio especial para a CECRED - cooperativa vinculada a o BB
                SET @NrBloqueto = @NrBloquetoReal
              ELSEIF right('00'+@DsCarteira,2) = '18' AND upper(isnull(@NrTipoConta,'')) <> '17POS' AND upper(isnull(@NrTipoConta,'')) <> 'CONV7' AND upper(isnull(@NrTipoConta,'')) NOT IN ('0005','0236') THEN
                SET @NrBloqueto = right('000000'+@DsContrato,6)+right('00000'+ @NrBloqueto,5) + '-' + @DsDigitoBloqueto;
              ELSE
                SET @NrBloqueto = @NrBloqueto+'-'+@DsDigitoBloqueto
              END IF;

            ELSEIF @Banco = 27 THEN
              IF @NrCnab = 340 AND @IdTipoCarne = 2 THEN
                SET @NrBloqueto = substring(@NrBloquetoReal,1,4)+'.'+substring(@NrBloquetoReal,5,4)+'.'+substring(@NrBloquetoReal,9,4)+'.'+substring(@NrBloquetoReal,13,4)

              ELSEIF @NrCnab = 400  THEN
                IF @NrTipoConta = 'T338'  THEN
                  SET @NrBloqueto = left(trim(@CdAgencia),length(trim(@CdAgencia)) - 1) + '-'+ right('00'+ @DsCarteira ,2)+'-' + LEFT(@NrBloquetoReal,4)+'.'+RIGHT(@NrBloquetoReal,4)+'-5'
                ELSEIF @NrTipoConta = 'T336' THEN
                  SET @NrBloqueto = RIGHT(@NrBloquetoReal,16);
                  SET @NrBloqueto = substring(@NrBloqueto,1,5)+'.'+substring(@NrBloqueto,6,4)+'.'+substring(@NrBloqueto,10,4)+'.'+substring(@NrBloqueto,14,3);
                ELSE
                  SET @NrBloqueto = left(@NrBloquetoReal,7)+'-'+right(@NrBloquetoReal,1)
                END IF
              ELSE
                SET @NrBloqueto = substring(@NrBloquetoReal,1,5)+'.'+substring(@NrBloquetoReal,6,4)+'.'+substring(@NrBloquetoReal,10,4)+'.'+substring(@NrBloquetoReal,14,3)
              END IF;

            ELSEIF @Banco = 33 THEN
              IF @NrTipoConta = 'MIGRA' THEN
                -- especifico para o MARISTA, é o novo layout do banco 33 ( que é igual ao do 353 )
                SET @NrBloqueto = @NrBloqueto+'-'+@DsDigitoBloqueto
              ELSE
                SET @NrBloqueto = right('000'+rtrim(convert(char(3),@CdAgencia)),3) + ' ' + right('0000000'+ @NrBloqueto,7) + ' ' + @DsDigitoBloqueto
              END IF;

            ELSEIF @Banco = 104 THEN
              SET @NrBloqueto = @NrBloquetoReal+'-'+@DsDigitoBloqueto

            ELSEIF @Banco = 341 THEN
              SET @NrBloqueto = right('000'+rtrim(@DsCarteira),3) + '/' + right('00000000'+rtrim(convert(char(8),@NrBloqueto)),8) + '-' + @DsDigitoBloqueto;
              -- para a carteira 198, do itau, o banco só aceita validar se mandar o nr_documento com 7 caracteres e mais um digito calculado
              -- como a variabvel @DsDigitoBloqueto não é mais utilizada para o itau, a partir daqui, para o boleto de validação
              -- colocamos neste campo o digito de right(nr_documento,7)
              IF right('000'+rtrim(@DsCarteira),3) = '198' THEN
                SET @DsDigitoBloqueto = f_Modulo10Peso_2_1(@NrDocumento);
              END IF;

            ELSEIF @Banco = 399 THEN
              IF @NrTipoConta = 'DRTVA' THEN
                -- cobranca diretiva
                SET @NrBloqueto = convert(numeric(20),@NrBloquetoReal);
                SET @NrBloqueto = substring(@NrBloqueto,1,length(@NrBloqueto)-1)+'-'+right(@NrBloqueto,1)
              ELSE
                SET @NrBloqueto = convert(numeric(20),@NrBloquetoReal);
                SET @NrBloqueto = substring(@NrBloqueto,1,length(@NrBloqueto)-3)+'-'+right(@NrBloqueto,3)
              END IF;

            ELSEIF @Banco = 748 THEN
              SET @NrBloqueto = @NrBloqueto + '-' + @DsDigitoBloqueto

            ELSEIF @Banco = 55 THEN
              SET @NrBloqueto = @NrBloqueto

            ELSEIF @Banco = 999 THEN
              SET @NrBloqueto = @NrBloqueto

            ELSEIF @Banco = 756 AND  @NrTipoConta = '999' THEN -- mantem o boleto sem o digito
              SET @NrBloqueto = @NrBloqueto;

            ELSEIF @Banco = 41 THEN
              -- BANRISUL
              SET @NrBloqueto = convert(numeric(20),@NrBloquetoReal);
              SET @NrBloqueto = substring(@NrBloqueto,1,length(@NrBloqueto)-2)+'-'+right(@NrBloqueto,2)

            ELSEIF @Banco = 409 THEN
              IF @NrCnab = 999 THEN -- Sem registro
                SET @NrBloqueto = right('00000000000000'+rtrim(convert(char(11),@NrBloqueto)),14) + '/' + @DsDigitoBloqueto;
              ELSE
                SET @NrBloqueto = '1/' + right('000000000000'+@NrBloquetoReal,12);
              END IF;

            ELSE
              IF @Banco <> 356 AND @Banco <> 347 THEN
                -- para os bancos em que o nosso numero e com o dv.
                SET @NrBloqueto = @NrBloqueto+'-'+@DsDigitoBloqueto
              END IF;
            END IF;

            IF @CdInstituicaoLogin = 8 THEN
              -- acerto temporario para DECISAO, quando FOR atividade
              -- NAO MOSTRAR O VALOR DA PARCELA NEM DE DESCONTO
              IF @VlParcelaTotal = 0 THEN
                SET @VlParcelaTotal = NULL;
                SET @VlDescontoTotal= NULL
              END IF
            END IF;

            IF @IdEmiteNomeCurso = 2 THEN
              SELECT F_cd_serie_aluno( @CdAluno , @CdAnoExercicio)
              INTO @CdCursoInstituicao

            END IF;

            SET @nm_instituicao_ensino = NULL;
            -- busca os dados da IE principal vinculada a conta corrente
            SELECT FIRST ie.nm_fantasia,
                   ie.nm_instituicao_ensino,
                   f_formata_cnpj(ie.nr_cgc_ie),
                   ie.cd_orgao_regulador,
                   ie.cd_regional,
                   ie.cd_instituicao_ensino,
                   ie.nm_mantenedora,
                   ie.nr_telefone
            INTO @nm_fantasia,
                 @nm_instituicao_ensino,
                 @nr_cgc_ie,
                 @cd_orgao_regulador,
                 @cd_regional,
                 @cd_instituicao_ensino,
                 @nm_mantenedora,
                 @nr_telefone_ie
            FROM instituicao_de_ensino ie,  contacorrente_instituicaoensino ccie
            WHERE ccie.cd_instituicao_ensino  = ie.cd_instituicao_ensino
              AND ccie.cd_regional            = ie.cd_regional
              AND ccie.cd_orgao_regulador     = ie.cd_orgao_regulador
              AND ccie.ic_instituicao_titular = 'S'
              AND ccie.cd_conta_corrente      = @CdContaEmissao
              AND ccie.cd_agencia             = @CdAgenciaEmissao
              AND ccie.cd_banco               = @CdBancoEmissao
            ORDER BY ie.cd_instituicao_ensino;

            IF @nm_instituicao_ensino IS NULL THEN
              -- busca os dados financeiros do DOCUMENTO
              SELECT FIRST ie.nm_fantasia,
                     ie.nm_instituicao_ensino,
                     f_formata_cnpj(ie.nr_cgc_ie),
                     ie.cd_orgao_regulador,
                     ie.cd_regional,
                     ie.cd_instituicao_ensino,
                     ie.nm_mantenedora,
                     ie.nr_telefone
              INTO @nm_fantasia,
                   @nm_instituicao_ensino,
                   @nr_cgc_ie,
                   @cd_orgao_regulador,
                   @cd_regional,
                   @cd_instituicao_ensino,
                   @nm_mantenedora,
                   @nr_telefone_ie
              FROM instituicao_de_ensino ie,
                   matricula_atividade_secundaria mas,
                   mensalidade me
              WHERE ie.cd_instituicao_ensino    = mas.cd_instituicao_ensino_financeiro
                AND ie.cd_regional              = mas.cd_regional_financeiro
                AND ie.cd_orgao_regulador       = mas.cd_orgao_regulador_financeiro
                AND mas.cd_atividade_secundaria = me.cd_atvd_secundaria_msl
                AND mas.nr_matricula            = me.nr_matricula
                AND mas.cd_ano_exercicio        = me.cd_ano_exercicio
                AND mas.cd_aluno                = me.cd_aluno
                AND mas.cd_curso_instituicao    = me.cd_curso_instituicao
                AND me.nr_documento             = @NrDocumento;
            END IF;

            -- CASO nao encontre pelo nro do documento, tenta pela matricula
            IF @nm_instituicao_ensino IS NULL THEN
              SELECT FIRST ie.nm_fantasia,
                     ie.nm_instituicao_ensino,
                     f_formata_cnpj(ie.nr_cgc_ie),
                     ie.cd_orgao_regulador,
                     ie.cd_regional,
                     ie.cd_instituicao_ensino,
                     ie.nm_mantenedora,
                     ie.nr_telefone
              INTO @nm_fantasia,
                   @nm_instituicao_ensino,
                   @nr_cgc_ie,
                   @cd_orgao_regulador,
                   @cd_regional,
                   @cd_instituicao_ensino,
                   @nm_mantenedora,
                   @nr_telefone_ie
              FROM instituicao_de_ensino ie,
                   matricula_atividade_secundaria mas
              WHERE ie.cd_instituicao_ensino = mas.cd_instituicao_ensino_financeiro
                AND ie.cd_regional           = mas.cd_regional_financeiro
                AND ie.cd_orgao_regulador    = mas.cd_orgao_regulador_financeiro
                AND mas.nr_matricula         = @NrMatricula
                AND mas.cd_ano_exercicio     = @CdAnoExercicio
                AND mas.cd_aluno             = @CdAluno
                AND mas.cd_curso_instituicao = @CdCursoInstituicao;
            END IF;

            -- Alteração feita opr Ismael
            SELECT ie.nm_bairro_ie, c.ds_logradouro, c.nm_municipio, c.cd_uf, c.cd_cep, ds_complemento_ie 
            INTO @nm_bairro_ie, @ds_logradouro_ie, @nm_municipio_ie, @cd_uf_ie, @cd_cep_ie, @ds_complemento_ie
            FROM instituicao_de_ensino ie, cep c
            WHERE c.cd_cep = ie.cd_cep_ie
              AND ie.cd_instituicao_ensino = @cd_instituicao_ensino;
            -- Fim

			set @ds_logradouro_ie = isnull(@ds_logradouro_ie,'')||' '|| isnull(@ds_complemento_ie,'');
			
            INSERT INTO #temp_carne
            SELECT @DsInstrucoes,
                   aluno.nm_aluno,
                   tipo_curso.ds_abreviacao || '-'||curso.nm_curso ,
                   @NrMatricula,
                   @PcJuroMensal,
                   @PcJuroDiario,
                   @PcMulta,
                   @DtVencimento,
                   @VlParcelaTotal,
                   @VlDescontoTotal,
                   @NrDocumento,
                   @CdAluno,
                   @CdAnoExercicio,
                   @NrBloqueto,
                   matricula.cd_turma,
                   @DsParcelas,
                   @nm_fantasia,
                   @nm_instituicao_ensino,
                   @nr_cgc_ie,
                   @DsInstrucoesdescto,
                   isnull(@DsLogradouro,''),
                   @DsBairro,
                   @CdCep,
                   IF PATINDEX('%.%',@NrCpf) = 0 THEN IF (length(@NrCpf) = 11) THEN f_formata_cpf(@NrCpf) ELSE IF ((length(@NrCpf) = 14) and @NrCpf != '00000000000000') THEN f_formata_cnpj(@NrCpf) ENDIF ENDIF ELSE @NrCpf ENDIF,
                   @NmMunicipio,
                   @Uf,
                   @NmResponsavel,
                   isnull(@DsComplemento,''),
                   isnull(@CdAgencia,''),
                   @CdContaCorrente,
                   @NrTipoConta,
                   @DsCarteira,
                   @DsEspecie,
                   @DsEspecieDoc,
                   @DsAceite,
                   @DsCodigoBarrasAzalea,
                   @DsCodigoRepresentacao,
                   @IdRegraDesconto,
                   isnull(@DsMsg1,''),
                   isnull(@DsMsg2,''),
                   isnull(@DsMsg3,''),
                   isnull(@DsMsg4,''),
                   isnull(@DsMsg5,''),
                   isnull(@DsMsgDebito,''),
                   @DsContrato,
                   @NmInstituicaoBanco,
                   @DsCodigoBarras,
                   @cd_orgao_regulador,
                   @cd_regional,
                   @cd_instituicao_ensino,
                   @nm_mantenedora,
                   tipo_curso.ds_tipo_curso,
                   @DsDigitoBloqueto,
                   @NmAgencia,
                   isnull(@DsMsg6,''),
                   isnull(@DsMsg7,''),
                   isnull(@DsMsg8,''),
                   isnull(@DsMsg9,''),
                   isnull(@DsMsg10,''),
                   @nr_telefone_ie,
                   @dtVencimentoComFator,
                   @NrDiasFatorVencimento,
                   @NmEventoMensalidade,
                   @NrParcelaMensalidade,
                   @NrTotalParcelasMensalidade,
                   @DtVencimentoFixo1,
                   @VlTotalApenasPontualidade1,
                   @DsDigitoBloqueto,
                   @NrCnab,
                   isnull((
                     SELECT list(hab.nm_habilitacao)
                     FROM habilitacao hab,
                          tipo_curso_competencia tcc
                     WHERE hab.id_especializacao     = 1
                       AND hab.cd_habilitacao        <> 0
                       AND hab.cd_habilitacao        = tcc.cd_habilitacao
                       AND hab.cd_tipo_curso         = tcc.cd_tipo_curso
                       AND @DtVencimento             between tcc.dt_inicio_vigencia AND dt_final_vigencia
                       AND tcc.cd_tipo_curso         = tipo_curso.cd_tipo_curso
                       AND tcc.cd_instituicao_ensino = instituicao_de_ensino.cd_instituicao_ensino
                       AND tcc.cd_regional           = instituicao_de_ensino.cd_regional
                       AND tcc.cd_orgao_regulador    = instituicao_de_ensino.cd_orgao_regulador
                   ),''),
                   @VlTaxaBancaria,
                   @DsBolsaAluno,
                   @VlBolsaAluno,
                   @IdValorDocumento,
                   matricula.cd_curso_instituicao,
                   @dsVariacao,
                   @NmBancoDados,
                   @nm_bairro_ie,
                   @ds_logradouro_ie,
                   @nm_municipio_ie,
                   @cd_uf_ie,
                   @cd_cep_ie
            FROM curso_instituicao,
                 tipo_curso,
                 curso,
                 instituicao_de_ensino,
                 aluno,
                 matricula
            WHERE tipo_curso.cd_tipo_curso                    = curso.cd_tipo_curso
              AND instituicao_de_ensino.cd_orgao_regulador    = curso_instituicao.cd_orgao_regulador
              AND instituicao_de_ensino.cd_regional           = curso_instituicao.cd_regional
              AND instituicao_de_ensino.cd_instituicao_ensino = curso_instituicao.cd_instituicao_ensino
              AND curso.cd_curso                              = curso_instituicao.cd_curso
              AND curso_instituicao.cd_curso_instituicao      = matricula.cd_curso_instituicao
              AND aluno.cd_aluno                              = matricula.cd_aluno
              AND matricula.nr_matricula                      = @NrMatricula
              AND matricula.cd_ano_exercicio                  = @CdAnoExercicio
              AND matricula.cd_aluno                          = @CdAluno
              AND matricula.cd_curso_instituicao              = @CdCursoInstituicao
          END IF;
        END IF;  -- fim IF @IdPodeEmitir = SIM

        CLOSE c_parcela;

        FETCH NEXT c_mensalidade INTO @CdCursoInstituicao, @CdAluno , @CdAnoExercicio, @NrMatricula, @NrDocumento, @IdResponsavelFinanceiro, @CdBancoEmissao, @CdAgenciaEmissao, @CdContaEmissao, @DsCarteiraEmissao, @DsEspecieDocEmissao, @IdRespFinanceiroMatricula, @idTipoFormaCobranca, @DsMsgDebito;
      END LOOP;

      CLOSE c_mensalidade;
      DEALLOCATE CURSOR c_parcela;
      DEALLOCATE CURSOR c_mensalidade;
    ELSE
      -- fazendo os carnes dos titulos a receber
      SET @DsSituacaoTituloReceber = 'AB';
      SET @DsDoctosAtrasados       = '';

      EXECUTE IMMEDIATE '
        INSERT INTO #temp_rel_receber
        SELECT DISTINCT titulo_receber.nr_documento,
               titulo_receber.sequencia,
               titulo_receber.cd_fonte,
               f.id_tipo_fonte
        FROM titulo_receber,
             fonte f,
             situacao_titulo_receber,
             situacao_financeira
        WHERE f.cd_fonte                                 = titulo_receber.cd_fonte
          AND situacao_titulo_receber.cd_situacao        = titulo_receber.cd_situacao
          AND situacao_financeira.cd_situacao_financeira = situacao_titulo_receber.cd_situacao_financeira
          AND situacao_financeira.ds_abreviacao          = '||char(39)|| @DsSituacaoTituloReceber|| char(39) || ' ' || @comando || @comando_order_by;

      OPEN c_titulo_receber WITH HOLD;
      FETCH NEXT c_titulo_receber INTO @NrDocumento,  @NrSequencia, @CdFonte, @IdResponsavelFinanceiro;

      WHILE sqlcode = 0 LOOP
        SET @VlParcelaTotal = 0;

        SELECT nr_bloqueto,
               dt_vencto,
               vl_titulo,
               vl_desconto,
               cd_aluno
        INTO @NrBloqueto,
             @DtVencimento,
             @VlMensalidade,
             @VlDesconto,
             @CdAluno
        FROM titulo_receber
        WHERE sequencia    = @NrSequencia
          AND nr_documento = @NrDocumento;

        IF @NrBloqueto IS NULL OR @NrBloqueto = '' THEN
          SELECT f_gera_nr_documento('BLOQUETO',0,0,0)
          INTO @NrBloquetoNovo;

          IF @Banco = 748 THEN
            SET @NrBloquetoNovo = right(left(convert(varchar(5),year(@DtVencimento)),4),2)  + @NrBloquetoNovo;
            SET @NrBloquetoNovo = convert(integer, @NrBloquetoNovo)
          END IF;

          SET @NrBloqueto = @NrBloquetoNovo;
        END IF;

        SET @DsDescPontualidade = '';

        SET @DsAbreviacaoDescto = '';
        SET @DsDigitoBloqueto = '';

        IF @VlDesconto > 0 THEN
          SET @PctDescto = (@VlDesconto * 100 / @VlMensalidade);
          SET @DsAbreviacaoDescto = ' Desconto: '+@dsMoeda+' '+f_formata_valor(@VlDesconto,',')
        END IF;

        SET @VlParcelaTotal = @VlParcelaTotal + @VlMensalidade;
        SET @DsParcelas = convert(varchar(20),@NrSequencia);

        SET @DsBairro      = '';
        SET @CdCep         = '';
        SET @NrCpf         = '';
        SET @NmResponsavel = '';
        SET @DsComplemento = '';

        IF @IdResponsavelFinanceiro = 4 THEN  -- id_responsavel financeiro = id_tipo_fonte tabela fonte
          -- aluno
          SELECT id_pessoa_fisica_aluno
          INTO @IdPessoa
          FROM pessoa_aluno
          WHERE cd_aluno = @CdAluno;

          SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 8 ) INTO @DsBairro;
          SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 4 ) INTO @CdCep;
          SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 12) INTO @NrCpf;
          SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 1 ) INTO @NmResponsavel;
          SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 3 ) INTO @DsComplemento;

          SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 2 ) INTO @DsLogradouro;
          SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 6 ) INTO @Uf;
          SELECT f_dados_pessoa_responsavel(@IdRespFinanceiroMatricula, @IdPessoa, 5 ) INTO @NmMunicipio;

        ELSE
          SELECT b.nm_bairro,
                 fonte.cd_cep,
                 fonte.cgc,
                 fonte.razao_social,
                 fonte.ds_complemento_logradouro
          INTO @DsBairro, @CdCep, @NrCpf, @NmResponsavel, @DsComplemento
          FROM fonte, bairro b
          WHERE b.id_bairro    =* fonte.id_bairro
            AND fonte.cd_fonte = @Cdfonte;

          SELECT cep.ds_logradouro,
                 cep.nm_municipio,
                 cep.cd_uf
          INTO @DsLogradouro, @NmMunicipio, @Uf
          FROM fonte, cep
          WHERE cep.cd_cep     = fonte.cd_cep
            AND fonte.cd_fonte = @CdFonte
        END IF;

        SELECT conta_corrente.cd_agencia,
               conta_corrente.cd_conta_corrente,
               conta_corrente.nr_tipo_conta,
               conta_corrente.ds_carteira,
               isnull(conta_corrente.nr_padrao_cnab,0),
               conta_corrente.ds_especie,
               conta_corrente.ds_especie_doc,
               conta_corrente.ds_aceite,
               conta_corrente.Cd_Contrato,
               conta_corrente.ds_msg1,
               conta_corrente.ds_msg2,
               conta_corrente.ds_msg3,
               conta_corrente.ds_msg4,
               conta_corrente.ds_msg5,
               '',
               ie.nm_instituicao_ensino,
               isnull(convert(varchar(10),tr.nr_titulo),''),
               isnull(tr.serie,''),
               pie.pc_juro_mensal,
               pie.pc_juro_diario,
               pie.pc_multa,
               pie.id_regra_desconto,
               pie.nr_dias_fator_vencimento,
               agencia.nm_agencia,
               conta_corrente.ds_msg6,
               conta_corrente.ds_msg7,
               conta_corrente.ds_msg8,
               conta_corrente.ds_msg9,
               conta_corrente.ds_msg10,
               conta_corrente.id_registro_carteira,
               conta_corrente.vl_taxa_bancaria,
               conta_corrente.ds_tipo_impressao,
               conta_corrente.ds_variacao
        INTO @CdAgencia,
             @CdContaCorrente,
             @NrTipoConta,
             @DsCarteira,
             @NrCnab,
             @DsEspecie,
             @DsEspecieDoc,
             @DsAceite,
             @DsContrato,
             @DsMsg1,
             @DsMsg2,
             @DsMsg3,
             @DsMsg4,
             @DsMsg5,
             @CdTurma,
             @NmInstituicao,
             @DsTitulo,
             @DsSerie,
             @PcJuroMensal,
             @PcJuroDiario,
             @PcMulta,
             @IdRegraDesconto,
             @NrDiasFatorVencimento,
             @NmAgencia,
             @DsMsg6,
             @DsMsg7,
             @DsMsg8,
             @DsMsg9,
             @DsMsg10,
             @IdRegistroCarteira,
             @VlTaxaBancaria,
             @dsTipoImpressao,
             @dsVariacao
        FROM titulo_receber tr,
             parametro_instituicao_ensino pie,
             instituicao_de_ensino ie,
             conta_corrente,
             agencia,
             banco
        WHERE pie.cd_ano_exercicio             = year(getdate())
          AND pie.cd_instituicao_ensino        = ie.cd_instituicao_ensino
          AND pie.cd_regional                  = ie.cd_regional
          AND pie.cd_orgao_regulador           = ie.cd_orgao_regulador
          AND conta_corrente.cd_conta_corrente = @CdContaCorrentePar
          AND conta_corrente.cd_agencia        = @CdAgenciaPar
          AND conta_corrente.cd_banco          = @Banco
          AND agencia.cd_agencia               = conta_corrente.cd_agencia
          AND agencia.cd_banco                 = conta_corrente.cd_banco
          AND banco.cd_banco                   = conta_corrente.cd_banco
          AND ie.cd_instituicao_ensino         = tr.cd_instituicao_ensino
          AND tr.sequencia                     = @NrSequencia
          AND tr.nr_documento                  = @NrDocumento;

        -- Montando as mensagens

        SET @DsMsgDebito = '';

        SET @DsInstrucoesdescto = trim(@DsInstrucoesdescto );
        IF @IdRegraDesconto = 0 AND @DsInstrucoesdescto IS NOT NULL THEN
          SET @DsInstrucoesdescto = @DsInstrucoesdescto+ ' ate o Vencto.'
        END IF;

        IF @DsTitulo <> '' THEN
          SET @DsInstrucoes = 'Refte Título: '+@DsTitulo+'/'+@DsSerie
        END IF;

        SET @DsObsParcelaBoleto  ='';
        SET @DsMensagemConvenio = '';
        SET @DsNomeCursos = '';

        IF @VlTaxaBancaria > 0 THEN
          SET @DsMensagemAcrescimo= 'Desconsiderar o acréscimo de '+@dsMoeda+' '+ f_formata_valor(@VlTaxaBancaria,',') +' se pago no colégio.'
        END IF;

        SELECT f_mensagem_atraso(@PcJuroMensal, @PcJuroDiario, @PcMulta, @VlParcelaTotal, @VlDesconto, 0)
        INTO @DsMensagemAtraso;

        SELECT f_mensagens(upper(@DsMsg1),upper(@DsInstrucoes), upper(@NmInstituicao), isnull(upper(@DsAbreviacaoDescto),''),ISNULL(upper(@NmResponsavel),''),@DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa, @dsEventos, @DsInstrucoesSemDesconto , upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg1;

        SELECT f_mensagens(upper(@DsMsg2),upper(@DsInstrucoes), upper(@NmInstituicao), isnull(upper(@DsAbreviacaoDescto),''),ISNULL(upper(@NmResponsavel),''),@DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa, @dsEventos, @DsInstrucoesSemDesconto , upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg2;

        SELECT f_mensagens(upper(@DsMsg3),upper(@DsInstrucoes), upper(@NmInstituicao), isnull(upper(@DsAbreviacaoDescto),''),ISNULL(upper(@NmResponsavel),''),@DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa, @dsEventos, @DsInstrucoesSemDesconto , upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg3;

        SELECT f_mensagens(upper(@DsMsg4),upper(@DsInstrucoes), upper(@NmInstituicao), isnull(upper(@DsAbreviacaoDescto),''),ISNULL(upper(@NmResponsavel),''),@DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa, @dsEventos, @DsInstrucoesSemDesconto , upper(@DsInstrucoesEf) , @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg4;

        SELECT f_mensagens(upper(@DsMsg5),upper(@DsInstrucoes), upper(@NmInstituicao), isnull(upper(@DsAbreviacaoDescto),''),ISNULL(upper(@NmResponsavel),''),@DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa, @dsEventos, @DsInstrucoesSemDesconto , upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg5;

        SELECT f_mensagens(upper(@DsMsg6),upper(@DsInstrucoes), upper(@NmInstituicao), isnull(upper(@DsAbreviacaoDescto),''),ISNULL(upper(@NmResponsavel),''),@DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa , @dsEventos, @DsInstrucoesSemDesconto, upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg6;

        SELECT f_mensagens(upper(@DsMsg7),upper(@DsInstrucoes), upper(@NmInstituicao), isnull(upper(@DsAbreviacaoDescto),''),ISNULL(upper(@NmResponsavel),''),@DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa , @dsEventos, @DsInstrucoesSemDesconto, upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg7;

        SELECT f_mensagens(upper(@DsMsg8),upper(@DsInstrucoes), upper(@NmInstituicao), isnull(upper(@DsAbreviacaoDescto),''),ISNULL(upper(@NmResponsavel),''),@DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa , @dsEventos, @DsInstrucoesSemDesconto, upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg8;

        SELECT f_mensagens(upper(@DsMsg9),upper(@DsInstrucoes), upper(@NmInstituicao), isnull(upper(@DsAbreviacaoDescto),''),ISNULL(upper(@NmResponsavel),''),@DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa , @dsEventos, @DsInstrucoesSemDesconto, upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg9;

        SELECT f_mensagens(upper(@DsMsg10),upper(@DsInstrucoes), upper(@NmInstituicao), isnull(upper(@DsAbreviacaoDescto),''),ISNULL(upper(@NmResponsavel),''),@DsMensagemAtraso, @DsDoctosAtrasados, @DsMsgPontualidade1,@DsMsgPontualidade2,@DsMsgPontualidade3,@DsMsgPontualidade4,@DsMsgPontualidade5,@DsMsgPontualidade6, @DsInstrucoesdesctoTotal, @DsMensagemConvenio, @DsMensagemAcrescimo, @DsNomeCursos, @DsDescontoComercial, @DsDescontoBolsa, @dsEventos, @DsInstrucoesSemDesconto, upper(@DsInstrucoesEf), @DsDadosAluno, @DsISS, @DsObsParcelaBoleto )
        INTO @DsMsg10;

        IF @Banco <> 275 AND @Banco <> 41 AND @Banco <> 347 AND @Banco <> 356 AND @Banco <> 237 AND @Banco <> 104  AND @Banco <> 1 AND @Banco <> 341 AND @Banco <> 409 AND @Banco <> 33 AND @Banco <> 291 AND @Banco <> 347 THEN
          -- Tirando o Digito Verificador da ContaCorrente e da Agencia
          SET @CdAgencia = SUBSTRING( @CdAgencia,1 , LENGTH( @CdAgencia)-1);
          SET @CdContaCorrente= SUBSTRING( @CdContaCorrente,1 , LENGTH( @CdContaCorrente)-1)

        ELSE
          IF @Banco = 356 AND @Banco = 347 THEN
            SET @CdAgencia = right('0000'+trim(@CdAgencia),4);
          END IF;
        END IF;

        CASE @Banco
          WHEN 1 THEN -- BB
            -- tratamento especifico para o BB e suas cooperativas
            -- hoje tratamos as cooperativas '0005' e '0236' são codigos de cooperativas CECRED, conforme novos clientes forem utilizando novas acrescentar aqui
            -- n_recebimento_via_arquivo , pr_carne_banco, pr_arquivo_banco e f_CalculaCodigoBarras também tem referencia a estas cooperativas
            IF ( right('00'+@DsCarteira,2) = '17'  OR right('00'+@DsCarteira,2) = '31') AND upper(isnull(@NrTipoConta,'')) <> 'CONV7' AND upper(isnull(@NrTipoConta,'')) NOT IN ('0005','0236') THEN
              SELECT right('000000'+@DsContrato,6)+right('00000'+ @NrBloqueto,5) INTO @NrBloquetoReal;
              SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto

            ELSEIF right('00'+@DsCarteira,2) = '18' AND upper(isnull(@NrTipoConta,'')) = '17POS' THEN
              -- carteira 18 nosso nro com 17 posicoes / sem registro
              SELECT right('00000000000000000'+ @NrBloqueto,17) INTO @NrBloquetoReal;
              SET @DsDigitoBloqueto = '';

            ELSEIF ( right('00'+@DsCarteira,2) = '18' OR right('00'+@DsCarteira,2) = '17' OR right('00'+@DsCarteira,2) = '11')  AND upper(isnull(@NrTipoConta,'')) = 'CONV7' THEN
              -- convenio com 7 posicoes e nr bloqueto composto
              SELECT right('0000000'+@DsContrato,7)+right('0000000000'+ @NrBloqueto,10) INTO @NrBloquetoReal;
              SET @DsDigitoBloqueto = '';

            ELSEIF ( right('00'+@DsCarteira,2) = '18' OR right('00'+@DsCarteira,2) = '17' OR right('00'+@DsCarteira,2) = '11')  AND upper(isnull(@NrTipoConta,'')) IN ('0005','0236') THEN
              -- convenio com 7 posicoes e nr bloqueto composto
              SELECT right('0000000'+@DsContrato,7)+right('0000000000'+ @NrBloqueto,10) INTO @NrBloquetoReal;
              SET @DsDigitoBloqueto = '';

            ELSEIF right('00'+@DsCarteira,2) = '18' AND upper(isnull(@NrTipoConta,'')) <> '17POS' AND upper(isnull(@NrTipoConta,'')) <> 'CONV7' AND upper(isnull(@NrTipoConta,'')) NOT IN ('0005','0236') THEN
              SELECT right('000000'+@DsContrato,6)+right('00000'+ @NrBloqueto,5) INTO @NrBloquetoReal;
              SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto

            ELSE
              SELECT right('00000000000000000'+ @NrBloqueto,17) INTO @NrBloquetoReal;
              SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto
            END IF

          WHEN 8 THEN -- MERIDIONAL mensalidade
            SET @NrBloquetoSant = right('000000000000'+rtrim(convert(char(8),@NrBloqueto)),12);
            SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoSant) INTO @DsDigitoBloqueto

          --douglas
          WHEN 27 THEN -- BESC
            IF @NrCnab = 400 AND @NrTipoConta <> 'T336' THEN
              SELECT '1'+right('000000'+ @NrBloqueto,6) INTO @NrBloquetoReal;
              SELECT f_Modulo11_peso9_0(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
              SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto

            ELSEIF @NrCnab = 340 AND @IdTipoCarne = 2 THEN
              SET @DsDigitoDesconto = 0;

              IF @CdInstituicaoLogin = 24 THEN
                -- para o cepu o ultimo caracter do nr_bloqueto, mostra qual o pct de desconto
                /*
                  1 = 10%
                  2 = 15%
                  3 = 20%
                  6 = 5%
                  0 = NDA
                */
                SET @PcDescontoTotal = "truncate"((@VlDescontoTotal * 100) / @VlParcelaTotal,0);

                IF @PcDescontoTotal = 10 THEN
                  SET @DsDigitoDesconto = 1
                ELSEIF @PcDescontoTotal = 15 THEN
                  SET @DsDigitoDesconto = 2
                ELSEIF @PcDescontoTotal = 20 THEN
                  SET @DsDigitoDesconto = 3
                ELSEIF @PcDescontoTotal = 5 THEN
                  SET @DsDigitoDesconto = 6
                ELSE
                  SET @DsDigitoDesconto = 0
                END IF
              END IF;

              SET @NrBloquetoBesc = right('0000000000000'+ @DsAnoVencto + right('000000000'+@NrBloqueto,9) + right('00'+convert(varchar(10),@NrParcela),2) + right('0'+convert(varchar(1),@DsDigitoDesconto),1),13);

              SELECT f_Modulo11_peso9_0(@Banco,@NrBloquetoBesc) INTO @DsDigitoBloqueto;
                -- para o BESC tem o "3" fixo e sao dois calculos de digito
              SET @NrBloquetoReal = @NrBloquetoBesc+@DsDigitoBloqueto+'3';
              SELECT f_Modulo11_peso9_0(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
              SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto
            ELSEIF @NrTipoConta = 'T336' THEN
              SELECT right('0000000000000'+ @NrBloqueto,13) INTO @NrBloquetoReal;
              SELECT f_Modulo11_peso9_0(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
              -- para o BESC tem o "3" fixo e sao dois calculos de digito
              SELECT @NrBloquetoReal+@DsDigitoBloqueto+'3' INTO @NrBloquetoReal;
              SELECT f_Modulo11_peso9_0(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
              SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto
            ELSE
              SELECT right('0000000000000'+ @NrBloqueto,13) INTO @NrBloquetoReal;
              SELECT f_Modulo11_peso9_0(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
              -- para o BESC tem o "3" fixo e sao dois calculos de digito
              SELECT  @NrBloquetoReal+@DsDigitoBloqueto+'3' INTO @NrBloquetoReal;
              SELECT f_Modulo11_peso9_0(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
              SET    @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto
            END IF;

          WHEN 33 THEN -- BANESPA
            -- Com registro
            SET @NrBloquetoReal = right('000'+rtrim(convert(char(3),@CdAgencia)),3) + right('0000000'+ @NrBloqueto,7);
            SELECT f_Modulo10_Banespa(@NrBloquetoReal) INTO @DsDigitoBloqueto;
            SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto

          WHEN 353 THEN
            -- Para o BANCO SANTANDER
            IF @NrCnab = 400 THEN
              SET @NrBloquetoSant = right('000000000000'+rtrim(convert(char(8),@NrBloqueto)),12);
              SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoSant) INTO @DsDigitoBloqueto;
            ELSE
              SET @NrBloquetoSant = right('000000000000'+rtrim(@NrBloqueto),12);
              SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoSant) INTO @DsDigitoBloqueto;
            END IF

          WHEN 389 THEN -- BANCO MERCANTIL
            SET @NrBloquetoReal = right('0000000000'+ @NrBloqueto,10);
            SELECT f_Modulo11Peso_9(@Banco , @NrBloquetoReal) INTO @DsDigitoBloqueto;

          WHEN 41 THEN -- BANRISUL
            SET @NrBloquetoReal = right('0000000000'+ @NrBloqueto,10);
            SELECT f_Modulo10Peso_2_1(@NrBloquetoReal) INTO @DsDigitoBloqueto;
            SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto;
            SELECT f_Modulo11Peso_7(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
            SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto;

            IF right('00'+@DsCarteira,2) = '14' AND upper(isnull(@NrTipoConta,'')) <> 'SIGCB' THEN
              SELECT '82'+right('00000000'+ @NrBloqueto,8) INTO @NrBloquetoReal;
              SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto
            ELSEIF right('00'+@DsCarteira,2) = 'SR' AND upper(isnull(@NrTipoConta,'')) <> 'SIGCB' THEN
              -- cobranca sem registro SR
              SELECT '82'+right('00000000'+ @NrBloqueto,8) INTO @NrBloquetoReal;
              SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto
            ELSEIF right('00'+@DsCarteira,2) = '12' AND upper(isnull(@NrTipoConta,'')) <> 'SIGCB' THEN
              -- cobranca rapida CR
              SELECT '9'+right('000000000'+ @NrBloqueto,9) INTO @NrBloquetoReal;
              SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto
            ELSEIF (right('00'+@DsCarteira,2) = '01' OR right('00'+@DsCarteira,2) = '24'  ) AND upper(isnull(@NrTipoConta,'')) <> 'SIGCB' THEN
              -- cobranca nOSSO NR de 19 posições
              -- calculando o digito do bloqueto
              SELECT f_Modulo11Peso_9(@Banco,'9'+right('00000000000000000'+ @NrBloqueto,17)) INTO @DsDigitoBloqueto;
              SET @NrBloquetoReal  = '9'+right('00000000000000000'+ @NrBloqueto,17);

            ELSEIF upper(isnull(@NrTipoConta,'')) = 'SIGCB' THEN
              IF @IdRegistroCarteira = 0then
                SET @IdRegistroCarteira = 2;  -- para a CEF sem registro é 2
              END IF;
              -- GERANDO NO NOVO PADRAO SIGCB
              -- calculando o digito do bloqueto
              SELECT f_Modulo11Peso_9(@Banco,@IdRegistroCarteira|| @dsTipoImpressao  ||right('000000000000000'+ @NrBloqueto,15)) INTO @DsDigitoBloqueto;
              SET @NrBloquetoReal  = @IdRegistroCarteira|| @dsTipoImpressao  ||right('000000000000000'+ @NrBloqueto,15);

            ELSE
              -- Para a Caixa Economica, para as cobrancas 870, em geral a carteira eh 8
              -- o nosso numero tem 16 digitos Carteira+14numeros+dig
              SELECT '8'+right('00000000000000'+ @NrBloqueto,14) INTO @NrBloquetoReal;
              SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto
            END IF

          WHEN 275 THEN -- Para o BANCO REAL
            SELECT right('0000000'+ @NrBloqueto,7)+right('0000'+ @CdAgencia,4)+right('0000000'+ @CdContaCorrente,7) INTO @NrBloquetoReal;
            SELECT f_Modulo10Peso_2_1(@NrBloquetoReal) INTO @DsDigitoBloqueto

          WHEN 356 THEN -- Para o BANCO ABN - REAL
            -- para calcular o DIGITAO retira-se os digitos da agencia e da conta corrente.
            IF right('00'+@DsCarteira,2) = '57'  THEN
              SELECT right('0000000000000'+ @NrBloqueto,13)+right('0000'+ SUBSTRING( @CdAgencia,1 , LENGTH( @CdAgencia)-1),4)+right('0000000'+ SUBSTRING( @CdContaCorrente,1 , LENGTH( @CdContaCorrente)-1),7) INTO @NrBloquetoReal
            ELSE
              SELECT right('0000000'+ @NrBloqueto,7)+right('0000'+ SUBSTRING( @CdAgencia,1 , LENGTH( @CdAgencia)-1),4)+right('0000000'+ SUBSTRING( @CdContaCorrente,1 , LENGTH( @CdContaCorrente)-1),7) INTO @NrBloquetoReal
            END IF;
            SELECT f_Modulo10Peso_2_1(@NrBloquetoReal) INTO @DsDigitoBloqueto;

          WHEN 347 THEN -- Para o SUDAMERIS
            -- para calcular o DIGITAO retira-se os digitos da agencia e da conta corrente.
            IF right('00'+@DsCarteira,2) = '57'  THEN
              SELECT right('0000000000000'+ @NrBloqueto,13)+right('0000'+ SUBSTRING( @CdAgencia,1 , LENGTH( @CdAgencia)-1),4)+right('0000000'+ SUBSTRING( @CdContaCorrente,1 , LENGTH( @CdContaCorrente)-1),7) INTO @NrBloquetoReal
            ELSE
              SELECT right('0000000'+ @NrBloqueto,7)+right('0000'+ SUBSTRING( @CdAgencia,1 , LENGTH( @CdAgencia)-1),4)+right('0000000'+ SUBSTRING( @CdContaCorrente,1 , LENGTH( @CdContaCorrente)-1),7) INTO @NrBloquetoReal
            END IF;
            SELECT f_Modulo10Peso_2_1(@NrBloquetoReal) INTO @DsDigitoBloqueto;

          WHEN 707 THEN -- Para o BANCO DAYCOVAL
            SELECT f_Modulo11Peso_7(@Banco,right('0000'+@DsCarteira,4)+right('00000000000'+@NrBloqueto,11)) INTO @DsDigitoBloqueto

          WHEN 237 THEN -- Para o BANCO BRADESCO
            SELECT f_Modulo11Peso_7(@Banco,right('0000'+@DsCarteira,4)+right('00000000000'+@NrBloqueto,11)) INTO @DsDigitoBloqueto

          WHEN 291 THEN -- BCN
            SET @NrBloquetoReal = right('0000000000000'+ @NrBloqueto,13);
            SELECT f_Modulo10Peso_2_1(@NrBloquetoReal) INTO @DsDigitoBloqueto;
            SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto;
            SELECT f_Modulo11Peso_7(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
            SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto;

          WHEN 341 THEN
            -- Para o ITAU
            -- caso a agencia do ITAU esteja cadastrada COM O DIGITO, ELE SERA RETIRADO
            IF right('000'+@DsCarteira,3) = '103' THEN
              --sao iguais
              SET @NrBloquetoItau = right('0000'+rtrim(convert(char(4),@CdAgencia)),4) +
                  right('00000'+ SUBSTRING( @CdContaCorrente,1 , LENGTH( @CdContaCorrente)-1),5)+
                  right('000'+rtrim(@DsCarteira),3) +
                  right('00000000'+rtrim(convert(char(8),@NrBloqueto)),8);
            ELSE
              SET @NrBloquetoItau = right('0000'+rtrim(convert(char(4),@CdAgencia)),4) +
                  right('00000'+ SUBSTRING( @CdContaCorrente,1 , LENGTH( @CdContaCorrente)-1),5)+
                  right('000'+rtrim(@DsCarteira),3) +
                  right('00000000'+rtrim(convert(char(8),@NrBloqueto)),8);
            END IF;

            SELECT f_Modulo10Peso_2_1(@NrBloquetoItau) INTO @DsDigitoBloqueto;

          WHEN 399 THEN
            -- Para o HSBC
            SELECT right('0000000000'+ @NrBloqueto,10) INTO @NrBloquetoReal;
            SELECT f_Modulo11peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
            -- para o HSBC tem o "4" fixo e EH O TIPO IDENTIFICADOR
            SELECT @NrBloquetoReal+@DsDigitoBloqueto+'4' INTO @NrBloquetoReal;
            -- segundo digito / somar a data de vencimento com o Cd_Contrato (Cod. Cedente)
            SELECT convert(varchar(10), @DtVencimento  ,104)  INTO @ds_DtVencimento;
            SELECT substring(@ds_DtVencimento,1,2)+substring(@ds_DtVencimento,4,2)+substring(@ds_DtVencimento,9,2) INTO @ds_DtVencimento;
            SELECT f_Modulo11peso_9(@Banco, convert(varchar(30),convert(numeric(20),@NrBloquetoReal)+convert(numeric(20),@ds_DtVencimento)+convert(numeric(20),@DsContrato))) INTO @DsDigitoBloqueto;
            SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto;

          WHEN 409 THEN -- Para o UNIBANCO
            IF @NrCnab = 999 THEN -- Sem registro
                SET @NrBloquetoReal = right('00000000000000'+ @NrBloqueto,14);
                SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
                SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto
            ELSE -- Com registro
                -- calcula o digito verificador
                SET @NrBloquetoReal = @NrBloqueto;
                SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto;
                SET @NrBloquetoReal = @NrBloquetoReal+@DsDigitoBloqueto;
                -- calcula o SUPER Digito verificador
                SET @NrBloquetoReal = right('00000000000'+ @NrBloquetoReal,11);
                SELECT f_Modulo11Peso_9(@Banco,'1'+@NrBloquetoReal) INTO @DsDigitoBloqueto;
                SET @NrBloquetoReal = right('00000000000'+ @NrBloquetoReal,11)+@DsDigitoBloqueto;
            END IF;

          WHEN 748 THEN -- SICREDI
            IF @NrTipoConta IS NULL OR @NrTipoConta = 'NULO' THEN
              -- sicredi guarda-se o posto de atendimento no nr_tipo_conta , se nao tiver nada usa fixo o posto 16 ( estava assim para o cliente 018)
              --'16' É POSTO  - fixo para o bd01018
              SET @dsPosto = '16'
            ELSE
              SET @dsPosto = convert(varchar(10), @NrTipoConta)
            END IF;

            SET @dsPosto = right('00'+@dsPosto,2);
            SELECT right('0000'+ @CdAgencia,4) + @dsPosto + right('00000'+SUBSTRING( @CdContaCorrente,1 , LENGTH( @CdContaCorrente)-1),5)+ right('00000000'+ @NrBloqueto,8) INTO @NrBloquetoReal;
            SELECT f_Modulo11Peso_9(@Banco, @NrBloquetoReal) INTO @DsDigitoBloqueto;

          WHEN 756 THEN -- bancoob
            IF @NrTipoConta = '999' THEN
              -- sem registro monta o NN com AnoEmissao (00) + nr_boleto 7 caracteres
              --nao precisa calcular digito
              SELECT right('000000'+ @NrBloqueto,6) INTO @NrBloquetoReal;
              SELECT '' INTO @DsDigitoBloqueto;
            ELSE
              -- Agencia vai para o calculo do digito , sem os seus respectivos digitos
              SELECT right('0000'+ @CdAgencia,4) + right('000000000'+@CdContaCorrente,9)+ right('0000000'+ @NrBloqueto,7) INTO @NrBloquetoReal;
              SELECT f_Modulo11_bancoob(@Banco, @NrBloquetoReal) INTO @DsDigitoBloqueto;
            END IF

          WHEN 104 THEN
            IF right('00'+@DsCarteira,2) = '14' AND upper(isnull(@NrTipoConta,'')) <> 'SIGCB' THEN
              SELECT '82'+right('00000000'+ @NrBloqueto,8) INTO @NrBloquetoReal;
              SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto

            ELSEIF right('00'+@DsCarteira,2) = 'SR' AND upper(isnull(@NrTipoConta,'')) <> 'SIGCB' THEN
              -- cobranca sem registro SR
              SELECT '82'+right('00000000'+ @NrBloqueto,8) INTO @NrBloquetoReal;
              SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto

            ELSEIF right('00'+@DsCarteira,2) = '12' AND upper(isnull(@NrTipoConta,'')) <> 'SIGCB' THEN
              -- cobranca rapida CR
              SELECT '9'+right('000000000'+ @NrBloqueto,9) INTO @NrBloquetoReal;
               SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto

            ELSEIF (right('00'+@DsCarteira,2) = '01' OR right('00'+@DsCarteira,2) = '24'  ) AND upper(isnull(@NrTipoConta,'')) <> 'SIGCB' THEN
              -- cobranca nOSSO NR de 19 posições
              -- calculando o digito do bloqueto
              SELECT f_Modulo11Peso_9(@Banco,'9'+right('00000000000000000'+ @NrBloqueto,17)) INTO @DsDigitoBloqueto;
              SET @NrBloquetoReal  = '9'+right('00000000000000000'+ @NrBloqueto,17);

            ELSEIF upper(isnull(@NrTipoConta,'')) = 'SIGCB' THEN
              IF @IdRegistroCarteira = 0then
                SET @IdRegistroCarteira = 2;  -- para a CEF sem registro é 2
              END IF;
              -- GERANDO NO NOVO PADRAO SIGCB
              -- calculando o digito do bloqueto
              SELECT f_Modulo11Peso_9(@Banco,@IdRegistroCarteira|| @dsTipoImpressao  ||right('000000000000000'+ @NrBloqueto,15)) INTO @DsDigitoBloqueto;
              SET @NrBloquetoReal  = @IdRegistroCarteira|| @dsTipoImpressao  ||right('000000000000000'+ @NrBloqueto,15);

            ELSE
              -- Para a Caixa Economica, para as cobrancas 870, em geral a carteira eh 8
              -- o nosso numero tem 16 digitos Carteira+14numeros+dig
              SELECT '8'+right('00000000000000'+ @NrBloqueto,14) INTO @NrBloquetoReal;
              SELECT f_Modulo11Peso_9(@Banco,@NrBloquetoReal) INTO @DsDigitoBloqueto
            END IF
        END CASE;

        -- Codigo de Barras
        IF @IdContraApresentacao = 1 THEN
            SET @DtVencimento = '1997-10-07'
        END IF;

        IF @Banco = 27 THEN
          IF @NrCnab = 400 THEN
            IF @NrTipoConta = 'T338' THEN
              SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, 'T338', @NrBloquetoReal,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
            ELSE
              SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, 'T400', @NrBloquetoReal,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
            END IF
          ELSEIF @NrCnab = 340 AND @IdTipoCarne = 2 THEN
            SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, 'T340', @NrBloquetoBesc,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
          ELSE
            SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloquetoReal,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
          END IF;

        ELSEIF @Banco = 341 AND @CdInstituicaoLogin = 26 THEN
            SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras

        ELSEIF @Banco = 409 THEN
          IF @NrCnab = 999 THEN
            SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, '999'       , @NrBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
          ELSE
            SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloquetoReal,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
          END IF;

        ELSEIF @Banco = 353 OR @Banco = 8 THEN
          -- no santander o boleto vai com o digito para o Cd de barras
          SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloqueto+@DsDigitoBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras

        ELSEIF @Banco = 748 THEN
          -- no SICREDI o boleto vai com o digito para o Cd de barras
          SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloqueto+@DsDigitoBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras

        ELSEIF @Banco = 756 THEN
          -- o BANCOOB
          SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloqueto+@DsDigitoBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras

        ELSEIF @Banco = 389 THEN
          -- MERCANTIL
          -- NO CAMPO @DsCarteira, mando a informação de ter ou nao desconto

          IF @VlDescontoTotal > 0 THEN
            SET @DsCarteira = '0'
          ELSE
            SET @DsCarteira = '2'
          END IF;

          SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloqueto+@DsDigitoBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
        ELSEIF @Banco = 104 AND ( right('00'+@DsCarteira,2) = '14' OR upper(isnull(@NrTipoConta,'')) = 'SIGCB') THEN
          SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloquetoReal,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
        ELSE
          SELECT f_CalculaCodigoBarras( @Banco, @CdAgencia, @CdContaCorrente, @NrTipoConta, @NrBloqueto,  @VlParcelaTotal+@VlTaxaBancaria , @DsCarteira, @DtVencimento, @DsContrato, @NrDocumento, @NrDiasFatorVencimento) INTO @DsCodigoBarras
        END IF;

        SELECT f_CodigoBarraRepresentacao(@Banco, @DsCarteira, @NrCnab, @DsCodigoBarras) INTO @DsCodigoRepresentacao;
        SELECT f_CodigoBarra2of5(@DsCodigoBarras) INTO @DsCodigoBarrasAzalea;

        -- O código de barras agora é retornado no formato do número e sua conversão é feita no relatório
        -- SELECT @DsCodigoBarrasAzalea = @DsCodigoBarras;

        UPDATE titulo_receber SET nr_bloqueto = @NrBloqueto
        WHERE nr_bloqueto IS NULL
          AND sequencia    = @NrSequencia
          AND nr_documento = @NrDocumento;

        COMMIT;

        IF @Banco = 1 THEN
          IF (right('00'+@DsCarteira,2) = '17' OR right('00'+@DsCarteira,2) = '31') AND upper(isnull(@NrTipoConta,'')) <> 'CONV7' AND upper(isnull(@NrTipoConta,'')) NOT IN ('0005','0236') THEN
            SET @NrBloqueto = right('000000'+@DsContrato,6)+right('00000'+ @NrBloqueto,5) + '-' + @DsDigitoBloqueto;
          ELSEIF right('00'+@DsCarteira,2) = '18' AND upper(isnull(@NrTipoConta,'')) = '17POS' THEN
            -- carteira 18 nosso nro com 17 posicoes
            SET @NrBloqueto = @NrBloquetoReal
          ELSEIF ( right('00'+@DsCarteira,2) = '18' OR right('00'+@DsCarteira,2) = '17' OR right('00'+@DsCarteira,2) = '11')  AND upper(isnull(@NrTipoConta,'')) = 'CONV7' THEN
            -- carteira 18 nosso nro com 17 posicoes
            SET @NrBloqueto = @NrBloquetoReal
          ELSEIF ( right('00'+@DsCarteira,2) = '18' OR right('00'+@DsCarteira,2) = '17' OR right('00'+@DsCarteira,2) = '11')  AND upper(isnull(@NrTipoConta,''))  IN ('0005','0236') THEN
            -- convenio especial para a CECRED - cooperativa vinculada a o BB
            SET @NrBloqueto = @NrBloquetoReal
          ELSEIF right('00'+@DsCarteira,2) = '18' AND upper(isnull(@NrTipoConta,'')) <> '17POS' AND upper(isnull(@NrTipoConta,'')) <> 'CONV7'  AND upper(isnull(@NrTipoConta,'')) NOT IN ('0005','0236') THEN
            SET @NrBloqueto = right('000000'+@DsContrato,6)+right('00000'+ @NrBloqueto,5) + '-' + @DsDigitoBloqueto;
          ELSE
            SET @NrBloqueto = @NrBloqueto+'-'+@DsDigitoBloqueto
          END IF;

        ELSEIF @Banco = 27 THEN
          IF @NrCnab = 340 AND @IdTipoCarne = 2 THEN
            SET @NrBloqueto = substring(@NrBloquetoReal,1,4)+'.'+substring(@NrBloquetoReal,5,4)+'.'+substring(@NrBloquetoReal,9,4)+'.'+substring(@NrBloquetoReal,13,4)
          ELSEIF @NrCnab = 400  THEN
            IF @NrTipoConta = 'T338'  THEN
              SET @NrBloqueto = left(trim(@CdAgencia),length(trim(@CdAgencia)) - 1) + '-'+ right('00'+ @DsCarteira ,2)+'-' + LEFT(@NrBloquetoReal,4)+'.'+RIGHT(@NrBloquetoReal,4)+'-5'
            ELSE
              SET @NrBloqueto = left(@NrBloquetoReal,7)+'-'+right(@NrBloquetoReal,1)
            END IF
          ELSE
            SET @NrBloqueto = substring(@NrBloquetoReal,1,5)+'.'+substring(@NrBloquetoReal,6,4)+'.'+substring(@NrBloquetoReal,10,4)+'.'+substring(@NrBloquetoReal,14,3)
          END IF;
        ELSEIF @Banco = 33 THEN
          SET @NrBloqueto = right('000'+rtrim(convert(char(3),@CdAgencia)),3) + ' ' + right('0000000'+ @NrBloqueto,7) + ' ' + @DsDigitoBloqueto
        ELSEIF @Banco = 104 THEN
          SET @NrBloqueto = @NrBloquetoReal+'-'+@DsDigitoBloqueto
        ELSEIF @Banco = 341 THEN
          SET @NrBloqueto = right('000'+rtrim(@DsCarteira),3) + '/' + right('00000000'+rtrim(convert(char(8),@NrBloqueto)),8) + '-' + @DsDigitoBloqueto
        ELSEIF @Banco = 399 THEN
          SET @NrBloqueto = convert(numeric(20),@NrBloquetoReal);
          SET @NrBloqueto = substring(@NrBloqueto,1,length(@NrBloqueto)-3)+'-'+right(@NrBloqueto,3)
        ELSEIF @Banco = 748 THEN
          SET @NrBloqueto = @NrBloqueto+'-'+@DsDigitoBloqueto
        ELSEIF @Banco = 41 THEN
          -- BANRISUL
          SET @NrBloqueto = convert(numeric(20),@NrBloquetoReal);
          SET @NrBloqueto = substring(@NrBloqueto,1,length(@NrBloqueto)-2)+'-'+right(@NrBloqueto,2)
        ELSEIF @Banco = 409 THEN
          IF @NrCnab = 999 THEN -- Sem registro
            SET @NrBloqueto = right('00000000000000'+rtrim(convert(char(11),@NrBloqueto)),14) + '/' + @DsDigitoBloqueto;
          ELSE
            SET @NrBloqueto = '1/' + right('000000000000'+@NrBloquetoReal,12);
          END IF;
        ELSE
          IF @Banco <> 356 AND @Banco <> 347 THEN
            -- para os bancos em que o nosso numero e com o dv.
            SET @NrBloqueto = @NrBloqueto+'-'+@DsDigitoBloqueto
          END IF;
        END IF;

        SELECT a.cd_aluno, a.nm_aluno
        INTO @CdAluno, @NmAluno
        FROM aluno a, titulo_receber tr
        WHERE a.cd_aluno = tr.cd_aluno
          AND tr.sequencia    = @NrSequencia
          AND tr.nr_documento = @NrDocumento;

        IF EXISTS (SELECT 1 FROM titulo_receber tr, emprestimo e  WHERE e.id_emprestimo = tr.id_emprestimo_biblioteca AND tr.sequencia = @NrSequencia AND tr.nr_documento = @NrDocumento ) THEN
          SELECT ub.nm_usr, null, null
          INTO @NmResponsavel, @CdAluno, @NmAluno
          FROM titulo_receber tr, emprestimo e, usuario_biblioteca ub 
          WHERE e.id_emprestimo = tr.id_emprestimo_biblioteca 
            AND ub.cd_usr       = cd_usr_emprestimo
            AND tr.sequencia    = @NrSequencia
            AND tr.nr_documento = @NrDocumento;
        END IF;        

        INSERT INTO #temp_carne
        SELECT @DsInstrucoes,
               @CdAluno || ' ' || @NmAluno,
               NULL,
               NULL,
               pie.pc_juro_mensal,
               pie.pc_juro_diario,
               pie.pc_multa,
               @DtVencimento,
               @VlParcelaTotal,
               @VlDesconto,
               convert(varchar(20),@NrDocumento)+convert(varchar(5),@NrSequencia),
               @CdFonte,
               NULL,
               @NrBloqueto,
               NULL,
               @DsParcelas,
               ie.nm_fantasia,
               ie.nm_instituicao_ensino,
               f_formata_cnpj(ie.nr_cgc_ie),
               @DsInstrucoesdescto,
               isnull(@DsLogradouro,''),
               @DsBairro,
               @CdCep,
               @NrCpf,
               @NmMunicipio,
               @Uf,
               @NmResponsavel,
               isnull(@DsComplemento,''),
               isnull(@CdAgencia,''),
               @CdContaCorrente,
               @NrTipoConta,
               @DsCarteira,
               @DsEspecie,
               @DsEspecieDoc,
               @DsAceite,
               @DsCodigoBarrasAzalea,
               @DsCodigoRepresentacao,
               pie.id_regra_desconto,
               isnull(@DsMsg1,''),
               isnull(@DsMsg2,''),
               isnull(@DsMsg3,''),
               isnull(@DsMsg4,''),
               isnull(@DsMsg5,''),
               isnull(@DsMsgDebito,''),
               @DsContrato,
               isnull(conta_corrente.nm_instituicao,ie.nm_instituicao_ensino),
               @DsCodigoBarras,
               ie.cd_orgao_regulador,
               ie.cd_regional,
               ie.cd_instituicao_ensino,
               ie.nm_mantenedora,
               NULL,
               NULL,
               agencia.nm_agencia,
               isnull(@DsMsg6,''),
               isnull(@DsMsg7,''),
               isnull(@DsMsg8,''),
               isnull(@DsMsg9,''),
               isnull(@DsMsg10,''),
               ie.nr_telefone,
               @dtVencimentoComFator,
               @NrDiasFatorVencimento,
               @NmEventoMensalidade,
               @NrParcelaMensalidade,
               @NrTotalParcelasMensalidade,
               @DtVencimentoFixo1,
               @VlTotalApenasPontualidade1,
               @DsDigitoBloqueto,
               @NrCnab,
               NULL,
               @VlTaxaBancaria,
               @DsBolsaAluno,
               @VlBolsaAluno,
               @IdValorDocumento,
               NULL,
               @dsVariacao,
               @NmBancoDados,
               @nm_bairro_ie,
               @ds_logradouro_ie,
               @nm_municipio_ie,
               @cd_uf_ie,
               @cd_cep_ie
        FROM titulo_receber tr,
             parametro_instituicao_ensino pie,
             instituicao_de_ensino ie,
             agencia,
             conta_corrente,
             banco
        WHERE agencia.cd_agencia              = conta_corrente.cd_agencia
          AND agencia.cd_banco                 = conta_corrente.cd_banco
          AND pie.cd_ano_exercicio             = year(getdate())
          AND pie.cd_instituicao_ensino        = ie.cd_instituicao_ensino
          AND pie.cd_regional                  = ie.cd_regional
          AND pie.cd_orgao_regulador           = ie.cd_orgao_regulador
          AND conta_corrente.cd_conta_corrente = @CdContaCorrentePar
          AND conta_corrente.cd_agencia        = @CdAgenciaPar
          AND conta_corrente.cd_banco          = @Banco
          AND banco.cd_banco                   = conta_corrente.cd_banco
          AND ie.cd_instituicao_ensino         = tr.cd_instituicao_ensino
          AND tr.sequencia                     = @NrSequencia
          AND tr.nr_documento                  = @NrDocumento;

        FETCH NEXT c_titulo_receber INTO @NrDocumento, @NrSequencia, @CdFonte, @IdResponsavelFinanceiro;
      END LOOP;

      CLOSE c_titulo_receber;
      DEALLOCATE CURSOR c_titulo_receber
    END IF;

    SELECT * FROM #temp_carne
    ORDER BY nm_curso, cd_turma, nm_aluno, dt_vencimento_msl;
  END;
END IF;

exec sa_set_permissao_grupo_usuario_sistema 'pr_carne_banco_r';
COMMIT;