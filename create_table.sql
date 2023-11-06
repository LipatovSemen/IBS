-- Start of DDL Script for Table GC.SDM_IBS
-- Generated 12-сен-2023 17:13:03 from GC@RBSPRJ

CREATE TABLE sdm_ibs
    (objid                          VARCHAR2(12 BYTE),
    subj_id                        VARCHAR2(10 BYTE),
    filial                         VARCHAR2(255 BYTE),
    otdel                          VARCHAR2(255 BYTE),
    num_dog                        VARCHAR2(15 BYTE),
    num_ibs                        VARCHAR2(10 BYTE),
    size_ibs                       VARCHAR2(30 BYTE),
    size_ibs_id                    NUMBER,
    place                          VARCHAR2(70 BYTE),
    tariff_id                      NUMBER,
    deposit                        VARCHAR2(10 BYTE),
    objid_deposit                  VARCHAR2(10 BYTE),
    objid_rent                     VARCHAR2(10 BYTE),
    objid_91202                    VARCHAR2(10 BYTE),
    objid_91203                    VARCHAR2(10 BYTE),
    nns                            VARCHAR2(20 BYTE),
    date_open                      DATE,
    dfinal                         DATE,
    date_close                     DATE,
    user_ins                       VARCHAR2(70 BYTE),
    date_ins                       DATE,
    user_del                       VARCHAR2(70 BYTE),
    user_close                     VARCHAR2(70 BYTE),
    ibs_type                       VARCHAR2(1 BYTE),
    summa_otv                      NUMBER,
    linksubj                       VARCHAR2(10 BYTE),
    ibs_deal                       VARCHAR2(50 BYTE),
    deal_summ                      NUMBER,
    period_type                    VARCHAR2(10 BYTE),
    period_int                     NUMBER,
    prolong                        NUMBER)
  SEGMENT CREATION IMMEDIATE
  PCTFREE     10
  INITRANS    1
  MAXTRANS    255
  TABLESPACE  users
  STORAGE   (
    INITIAL     65536
    NEXT        1048576
    MINEXTENTS  1
    MAXEXTENTS  2147483645
  )
  NOCACHE
  MONITORING
  NOPARALLEL
  LOGGING
/

-- Grants for Table
GRANT ALTER ON sdm_ibs TO public
/
GRANT DELETE ON sdm_ibs TO public
/
GRANT INDEX ON sdm_ibs TO public
/
GRANT INSERT ON sdm_ibs TO public
/
GRANT SELECT ON sdm_ibs TO public
/
GRANT UPDATE ON sdm_ibs TO public
/
GRANT REFERENCES ON sdm_ibs TO public
/
GRANT READ ON sdm_ibs TO public
/
GRANT ON COMMIT REFRESH ON sdm_ibs TO public
/
GRANT QUERY REWRITE ON sdm_ibs TO public
/
GRANT DEBUG ON sdm_ibs TO public
/
GRANT FLASHBACK ON sdm_ibs TO public
/




-- Comments for SDM_IBS

COMMENT ON COLUMN sdm_ibs.date_close IS 'Дата закрытия'
/
COMMENT ON COLUMN sdm_ibs.date_ins IS 'Время добавления ячейки'
/
COMMENT ON COLUMN sdm_ibs.date_open IS 'Дата открытия'
/
COMMENT ON COLUMN sdm_ibs.deal_summ IS 'Сумма сделки'
/
COMMENT ON COLUMN sdm_ibs.deposit IS 'Залог'
/
COMMENT ON COLUMN sdm_ibs.dfinal IS 'Дата окончания'
/
COMMENT ON COLUMN sdm_ibs.filial IS 'Филиал'
/
COMMENT ON COLUMN sdm_ibs.ibs_deal IS 'Тип сделки'
/
COMMENT ON COLUMN sdm_ibs.ibs_type IS 'Тип ячейки 1 Простое 2 Ответственное 3 сделка простое 4 сделка ответственное'
/
COMMENT ON COLUMN sdm_ibs.linksubj IS 'Второй арендатор ячейки. В случае если сделка. IBS_TYPE = 3 или 4'
/
COMMENT ON COLUMN sdm_ibs.nns IS 'Счет списания'
/
COMMENT ON COLUMN sdm_ibs.num_dog IS 'Номер договора ячейки'
/
COMMENT ON COLUMN sdm_ibs.num_ibs IS 'Номер ячейки'
/
COMMENT ON COLUMN sdm_ibs.objid IS 'Идентификатор ячейки'
/
COMMENT ON COLUMN sdm_ibs.objid_91202 IS 'ID счета 91202'
/
COMMENT ON COLUMN sdm_ibs.objid_91203 IS 'ID счета 91203'
/
COMMENT ON COLUMN sdm_ibs.objid_deposit IS 'ID счета залога'
/
COMMENT ON COLUMN sdm_ibs.objid_rent IS 'ID счета аренды'
/
COMMENT ON COLUMN sdm_ibs.otdel IS 'Отдел'
/
COMMENT ON COLUMN sdm_ibs.period_int IS 'интервал'
/
COMMENT ON COLUMN sdm_ibs.period_type IS 'WEEK период в неделях MONTH месяц'
/
COMMENT ON COLUMN sdm_ibs.place IS 'Местоположение'
/
COMMENT ON COLUMN sdm_ibs.prolong IS '1 - есть 0 - нет'
/
COMMENT ON COLUMN sdm_ibs.size_ibs IS 'Размер ячейки'
/
COMMENT ON COLUMN sdm_ibs.size_ibs_id IS 'ID размер ячейки (gc.sprav)'
/
COMMENT ON COLUMN sdm_ibs.subj_id IS 'Владелец ячейки'
/
COMMENT ON COLUMN sdm_ibs.summa_otv IS 'Сумма ответственного хранения'
/
COMMENT ON COLUMN sdm_ibs.tariff_id IS 'ID тарифа gc.sdm$ibs_tariff'
/
COMMENT ON COLUMN sdm_ibs.user_close IS 'Пользователь закрывший ячейку'
/
COMMENT ON COLUMN sdm_ibs.user_del IS 'Пользователь удаливший ячейку'
/
COMMENT ON COLUMN sdm_ibs.user_ins IS 'Пользователь добавивший ячейку'
/

-- End of DDL Script for Table GC.SDM_IBS
-- Start of DDL Script for Table GC.SDM$IBS_NNS
-- Generated 30.08.2023 11:30:38 from GC@BANKNULL

CREATE TABLE sdm$ibs_nns                                                                                                  
    (num_ibs                        VARCHAR2(10 BYTE),
    nns                            VARCHAR2(20 BYTE),
    nns_5nt                        VARCHAR2(20 BYTE),
    filial                         VARCHAR2(12 BYTE),
    otdel                          VARCHAR2(12 BYTE),
    size_id                        VARCHAR2(12 BYTE))
  SEGMENT CREATION IMMEDIATE
  PCTFREE     10
  INITRANS    1
  MAXTRANS    255
  TABLESPACE  users
  STORAGE   (
    INITIAL     65536
    NEXT        1048576
    MINEXTENTS  1
    MAXEXTENTS  2147483645
  )
  NOCACHE
  MONITORING
  NOPARALLEL
  LOGGING
/





-- End of DDL Script for Table GC.SDM$IBS_NNS
                 
                                                                                                   
create table gc.sdm$ibs_choise (
   USERNAME varchar2(100)
  ,NUM_IBS varchar2(10)
  );
   
                                                                                                   
                                                                                                   
                                                                                                   
-- Start of DDL Script for Table GC.SDM$IBS_TRUST
-- Generated 06.07.2023 7:49:23 from GC@BANKNULL

-- Start of DDL Script for Table GC.SDM$IBS_TRUST
-- Generated 14-июл-2023 12:19:21 from GC@BANKNULL

CREATE TABLE sdm$ibs_trust
    (    id                             NUMBER,
    objid                          VARCHAR2(12 BYTE),
    subj_id                        VARCHAR2(12 BYTE),
    instime                        DATE,
    user_ins                       VARCHAR2(12 BYTE),
    date_st                        DATE,
    date_en                        DATE,
    date_annul                     DATE
)
  SEGMENT CREATION IMMEDIATE
  PCTFREE     10
  INITRANS    1
  MAXTRANS    255
  TABLESPACE  users
  STORAGE   (
    INITIAL     65536
    NEXT        1048576
    MINEXTENTS  1
    MAXEXTENTS  2147483645
  )
  NOCACHE
  MONITORING
  NOPARALLEL
  LOGGING
/

-- Grants for Table
GRANT ALTER ON sdm$ibs_trust TO public
/
GRANT DELETE ON sdm$ibs_trust TO public
/
GRANT INDEX ON sdm$ibs_trust TO public
/
GRANT INSERT ON sdm$ibs_trust TO public
/
GRANT SELECT ON sdm$ibs_trust TO public
/
GRANT UPDATE ON sdm$ibs_trust TO public
/
GRANT REFERENCES ON sdm$ibs_trust TO public
/
GRANT READ ON sdm$ibs_trust TO public
/
GRANT ON COMMIT REFRESH ON sdm$ibs_trust TO public
/
GRANT QUERY REWRITE ON sdm$ibs_trust TO public
/
GRANT DEBUG ON sdm$ibs_trust TO public
/
GRANT FLASHBACK ON sdm$ibs_trust TO public
/

                                                                                                   
                                                                                                   
                                                                                                   
-- Comments for SDM$IBS_TRUST

COMMENT ON COLUMN sdm$ibs_trust.date_en IS 'Дата окончания действия доверенности'
/
COMMENT ON COLUMN sdm$ibs_trust.date_st IS 'Дата начала действия доверенности'
/
COMMENT ON COLUMN sdm$ibs_trust.id IS 'ID доверенности'
/
COMMENT ON COLUMN sdm$ibs_trust.instime IS 'Время добавления доверенности'
/
COMMENT ON COLUMN sdm$ibs_trust.objid IS 'Идентификатор ячейки'
/
COMMENT ON COLUMN sdm$ibs_trust.subj_id IS 'Доверенное лицо'
/
COMMENT ON COLUMN sdm$ibs_trust.user_ins IS 'Пользователь добавивший доверенность'
/
COMMENT ON COLUMN sdm$ibs_trust.date_annul IS 'Дата аннулирования доверенности'
/

-- End of DDL Script for Table GC.SDM$IBS_TRUST

                                                                                                   
-- Start of DDL Script for Table GC.SDM$IBS_DOCUM
-- Generated 14-июл-2023 16:19:10 from GC@BANKNULL

-- Start of DDL Script for Table GC.SDM$IBS_DOCUM
-- Generated 14-июл-2023 16:19:10 from GC@BANKNULL

CREATE TABLE sdm$ibs_docum
    (objid                          VARCHAR2(12 BYTE),
    unp                            NUMBER,
    type_oper                      VARCHAR2(100 BYTE))
  PCTFREE     10
  INITRANS    1
  MAXTRANS    255
  TABLESPACE  users
  NOCACHE
  MONITORING
  NOPARALLEL
  LOGGING
/

                                                                                                   
                                                                                                   
                                                                                                   

-- End of DDL Script for Table GC.SDM$IBS_DOCUM




-- Start of DDL Script for Table GC.IBS$INCOME_PROTOCOL
-- Generated 29-авг-2023 18:27:36 from GC@BANKNULL

CREATE TABLE ibs$income_protocol
    (objid                          VARCHAR2(12 BYTE),
    date_event                     DATE,
    txt                            VARCHAR2(200 BYTE),
    uuid                           VARCHAR2(35 BYTE))
  SEGMENT CREATION IMMEDIATE
  PCTFREE     10
  INITRANS    1
  MAXTRANS    255
  TABLESPACE  users
  STORAGE   (
    INITIAL     65536
    NEXT        1048576
    MINEXTENTS  1
    MAXEXTENTS  2147483645
  )
  NOCACHE
  MONITORING
  NOPARALLEL
  LOGGING
/





-- Comments for IBS$INCOME_PROTOCOL

COMMENT ON COLUMN ibs$income_protocol.date_event IS 'Дата'
/
COMMENT ON COLUMN ibs$income_protocol.objid IS 'ID ячейки'
/
COMMENT ON COLUMN ibs$income_protocol.txt IS 'Ошибка'
/
COMMENT ON COLUMN ibs$income_protocol.uuid IS 'Идентификатор запуска'
/

-- End of DDL Script for Table GC.IBS$INCOME_PROTOCOL

-- Start of DDL Script for Table GC.IBS$INCOME_EXEC            
-- Generated 29-авг-2023 18:28:55 from GC@BANKNULL

CREATE TABLE ibs$income_exec
    (uuid                           VARCHAR2(35 BYTE),
    user_exec                      VARCHAR2(100 BYTE),
    date_exec                      DATE,
    date_start                     DATE,
    date_end                       DATE)
  SEGMENT CREATION IMMEDIATE
  PCTFREE     10
  INITRANS    1
  MAXTRANS    255
  TABLESPACE  users
  STORAGE   (
    INITIAL     65536
    NEXT        1048576
    MINEXTENTS  1
    MAXEXTENTS  2147483645
  )
  NOCACHE
  MONITORING
  NOPARALLEL
  LOGGING
/





-- Comments for IBS$INCOME_EXEC

COMMENT ON COLUMN ibs$income_exec.date_end IS 'Дата окончания периода'
/
COMMENT ON COLUMN ibs$income_exec.date_exec IS 'Дата запуска начисления'
/
COMMENT ON COLUMN ibs$income_exec.date_start IS 'Дата начало периода'
/
COMMENT ON COLUMN ibs$income_exec.user_exec IS 'Пользователь запустивший начисление'
/
COMMENT ON COLUMN ibs$income_exec.uuid IS 'Идентификатор запуска (ibs_income_exec)'
/

-- End of DDL Script for Table GC.IBS$INCOME_EXEC





-- Start of DDL Script for Table GC.IBS$INCOME_PAYMENT
-- Generated 31-авг-2023 10:33:09 from GC@BANKNULL

CREATE TABLE ibs$income_payment
    (objid                          VARCHAR2(12 BYTE),
    date_st                        DATE,
    date_e                         DATE,
    summ                           NUMBER,
    unp                            VARCHAR2(12 BYTE))
  SEGMENT CREATION IMMEDIATE
  PCTFREE     10
  INITRANS    1
  MAXTRANS    255
  TABLESPACE  users
  STORAGE   (
    INITIAL     65536
    NEXT        1048576
    MINEXTENTS  1
    MAXEXTENTS  2147483645
  )
  NOCACHE
  MONITORING
  NOPARALLEL
  LOGGING
/





CREATE TABLE GC.SDM$IBS_PHONE 
(OBJID VARCHAR2(15)
,TYPESUBJ VARCHAR2(12)
,SUBJ_ID VARCHAR2(15)
,TYPEPHONE VARCHAR2(20)
,NUM VARCHAR2(100)
)
/



CREATE TABLE GC.SDM$IBS_TARIFF
  (ID NUMBER
  ,OBJID VARCHAR2(12)
  ,DATE_ST DATE
  ,DATE_EN DATE
  ,PERIOD_TYPE VARCHAR2(10)
  ,PERIOD_INT INT
  ,TARIFF_SUMM NUMBER
  );

CREATE TABLE GC.SDM$IBS_OTV (OBJID VARCHAR2(12)
                            ,CUR VARCHAR2(3)
                            ,SUMMA NUMBER
                            );





CREATE TABLE GC.SDM$IBS_GLOBAL_QUALS
           (NAME_QUAL VARCHAR2(100)
           ,VALUE VARCHAR2(50)
           );
           
CREATE TABLE GC.SDM$IBS_GLOBAL_QUAL_JOUR
           (NAME_QUAL VARCHAR2(100)
           ,OLD_VALUE VARCHAR2(50)
           ,NEW_VALUE VARCHAR2(50)
           ,DTIME DATE
           ,USR VARCHAR2(150)
           );   
