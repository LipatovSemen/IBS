-- Start of DDL Script for Table GC.TEMP_IBS_02102023
-- Generated 04.10.2023 18:58:55 from GC@BANK

CREATE TABLE temp_ibs_02102023
    (objid                          VARCHAR2(12 BYTE),
    num_ibs                        VARCHAR2(12 BYTE),
    date_open                      DATE,
    dfinal                         DATE,
    date_st_tariff                 DATE,
    date_en_tariff                 DATE,
    summ_all                       NUMBER,
    cnt_all_days_ibs               NUMBER,
    summ_one_day                   NUMBER,
    date_st_period                 DATE,
    date_en_period                 DATE,
    cnt_spisan                     NUMBER,
    summ                           NUMBER,
    ost_47422                      NUMBER,
    error                          VARCHAR2(200 BYTE))
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





-- End of DDL Script for Table GC.TEMP_IBS_02102023
