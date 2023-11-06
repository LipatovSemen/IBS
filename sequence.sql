-- Start of DDL Script for Sequence GC.SDM$IBS_VREM_SEQ
-- Generated 12-сен-2023 16:51:30 from GC@RBSPRJ

CREATE SEQUENCE sdm$ibs_tariff_seq
  INCREMENT BY 1
  START WITH 15364
  MINVALUE 1
  MAXVALUE 999999999999999
  NOCYCLE
  ORDER
  NOCACHE
  NOKEEP
  GLOBAL
/

-- Grants for Sequence
GRANT ALTER ON sdm$ibs_tariff_seq TO public
/
GRANT SELECT ON sdm$ibs_tariff_seq TO public
/

-- End of DDL Script for Sequence GC.SDM$IBS_VREM_SEQ
