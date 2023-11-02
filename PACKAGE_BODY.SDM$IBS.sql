-- Start of DDL Script for Package Body GC.SDM$IBS
-- Generated 02.11.2023 20:18:03 from GC@RBSDEV

CREATE OR REPLACE 
package body sdm$ibs as


  function get_app_list
    (pSubjName varchar2:=null
    ,pSubjId varchar2:=null
    ,pNum_Dog varchar2:=null
    ,pNum_Ibs varchar2:=null
    ,pFilial varchar2:=null
    ,pOtdel varchar2:=null    
    ,pAppDateB date:=null
    ,pAppDateE date:=null
    ,pAppExecDateB date:=null
    ,pAppExecDateE date:=null
    ,pRateDateType varchar2:=null
    ,pLoop_All varchar2
    ,pLoop_Delay varchar2
    ) return sys_refcursor
  is
    vCursor sys_refcursor;
  begin
    open vCursor for
    --Колонки должны иметь тоже наименование, что и в грид форме блока кода
      select a.objid
            ,a.subj_id
            ,s.name as Subj_Name
            ,a.filial
            ,a.otdel
            ,a.num_dog
            ,a.num_ibs
            ,a.size_ibs
            ,a.place 
--            ,(select st.tariff_summ from gc.sdm$ibs_tariff st where st.id = a.tariff_id) tariff
            ,a.deposit
            ,(SELECT GC.NNS.GET(AA.S,AA.CUR) FROM GC.ACC AA WHERE AA.OBJID = A.OBJID_DEPOSIT) OBJID_DEPOSIT
            ,(SELECT GC.NNS.GET(AA.S,AA.CUR) FROM GC.ACC AA WHERE AA.OBJID = A.OBJID_RENT) OBJID_RENT
            ,a.objid_91202
            ,a.objid_91203
            ,a.nns
            ,to_char(a.date_open,'dd/mm/yyyy') date_open
            ,to_char(a.dfinal,'dd/mm/yyyy') dfinal
            ,to_char(a.date_close,'dd/mm/yyyy') date_close
            ,a.user_ins
            ,a.user_del
            ,to_char(a.date_ins,'dd/mm/yyyy') date_ins
            ,a.user_close
            ,case when dfinal < trunc(sysdate) then 'Да' else 'Нет' end delay
            
               from gc.sdm_ibs a
                   ,gc.subj s
      where 1=1
              and s.id = a.subj_id
              and (pSubjName is null or s.name like pSubjName || '%')
              and (pSubjId is null or a.Subj_Id = pSubjId)
              and (pNum_Dog is null or a.Num_Dog = pNum_Dog)
              and (pNum_Ibs is null or a.Num_Ibs = pNum_Ibs)  
              and (pOtdel is null or a.Otdel = pOtdel)   
              and (pFilial is null or a.Filial = pFilial)
              and (pAppDateB is null or a.date_open >= pAppDateB)
              and (pAppDateE is null or a.date_open <= pAppDateE)
              and (pAppExecDateB is null or a.dfinal >= pAppExecDateB)
              and (pAppExecDateE is null or a.dfinal <= pAppExecDateE)
              and ((a.Date_Close is null and a.User_Del is null and pLoop_All = '0') 
              or (pLoop_All = '1') )  
              and (case when dfinal < trunc(sysdate) then 'Да' else 'Нет' end = 'Да' and pLoop_Delay = '1'
              or (pLoop_Delay = '0'))                       
                     
             --
      order by s.name,a.objid desc;
    --
    return vCursor;
  end;
  
  --
  function get_subj_list
    (pSubjName varchar2
    ) return sys_refcursor
  is
    vCursor sys_refcursor;
  begin
    open vCursor for
      select s.id
            ,s.name
            ,nvl(gc.p_Subj.getDocNumForShowInDoss(s.id), gc.GetClientSerNum(s.id)) passport
            ,to_char(h.birthday,'dd/mm/yyyy') birthday
            ,h.rnn inn
      from   subj s
            ,human h
      where  s.name like upper(pSubjName) || '%'
             and h.subj_id = s.id
             and s.isklient = 1
      order by s.name, s.ins_date desc;
    --
    return vCursor;
  end;
  
  function get_subjdover_list
    (pSubjName varchar2
    ) return sys_refcursor
  is
    vCursor sys_refcursor;
  begin
    open vCursor for
      select s.id
            ,s.name
            ,nvl(gc.p_Subj.getDocNumForShowInDoss(s.id), gc.GetClientSerNum(s.id)) passport
            ,to_char(h.birthday,'dd/mm/yyyy') birthday
            ,h.rnn inn
      from   subj s
            ,human h
      where  s.name like upper(pSubjName) || '%'
             and h.subj_id = s.id
          --   and s.isklient = 1
      order by s.name, s.ins_date desc;
    --
    return vCursor;
  end;  
  
  procedure add_dover
    (pObjID in varchar2
    ,pSubjID in varchar2
    ,pDateSt in date
    ,pDateEn in date
    )    
  is
vCNT number;
BEGIN
gc.p_support.arm_start();

SELECT COUNT(*)
INTO vCNT
  FROM GC.SDM$IBS_TRUST 
WHERE OBJID = pObjID
  AND SUBJ_ID = pSubjID
  AND DATE_EN >= TRUNC(SYSDATE)
  AND DATE_ANNUL IS NULL;
IF vCNT > 0 THEN
app_err.put('0',0,'ДЛЯ ЭТОЙ ЯЧЕЙКИ УЖЕ ЕСТЬ ДЕЙСТВУЮЩАЯ ДОВЕРЕННОСТЬ ДЛЯ ВЫБРАННОГО ЛИЦА');
END IF;


    INSERT INTO GC.SDM$IBS_TRUST       
    SELECT gc.objid.nextval,pObjID,pSubjID,SYSDATE,SYS_CONTEXT('USERENV','SESSION_USER'),pDateSt,pDateEn,null FROM DUAL;
    COMMIT;
    GC.JOUR_PACK.ADD_TO_JOURNAL('SDMIBS',pObjID,'IBSDOVER_ADD','I','','Заведение доверенности для ячейки. Доверенное лицо ID = '||pSubjID);     
END;   

  procedure annul_dover
    (pID in number
    ,pTXT in varchar2
    )    
    is
    POBJID VARCHAR2(12);
  BEGIN
  GC.P_SUPPORT.ARM_START();
  
  --Найдем идентификатор ячейки
  SELECT MAX(OBJID)
  INTO pOBJID FROM GC.SDM$IBS_TRUST
  WHERE ID = pID;
  
  --Проставим дату аннулирования
  UPDATE GC.SDM$IBS_TRUST  
  SET DATE_ANNUL = SYSDATE
  WHERE ID = pID;
  
  --Запишем в журнал по ячейке
  GC.JOUR_PACK.ADD_TO_JOURNAL('SDMIBS',pObjID,'IBSDOVER_DEL','I','',pTXT||' . Идентификатор доверенности - '||pID);
  
  COMMIT;
      
  END;  
  
  FUNCTION GET_TRUST_LIST
    (POBJID VARCHAR2
    ) RETURN SYS_REFCURSOR
  IS
    VCURSOR SYS_REFCURSOR;
  BEGIN
    OPEN VCURSOR FOR
SELECT I.ID
      ,I.OBJID
      ,S.NAME FIO
      ,I.INSTIME
      ,I.DATE_ST
      ,I.DATE_EN
      ,I.DATE_ANNUL
      ,I.USER_INS FROM GC.SDM$IBS_TRUST I
             ,GC.SUBJ S
WHERE 1=1
  AND I.SUBJ_ID = S.ID 
  AND I.OBJID = POBJID
      ORDER BY S.NAME;
    --
    RETURN VCURSOR;
  end;      
  --
  
  FUNCTION GET_TARIFF_LIST
    (POBJID VARCHAR2
    ) RETURN SYS_REFCURSOR
  IS
    VCURSOR SYS_REFCURSOR;
  BEGIN
    OPEN VCURSOR FOR
SELECT T.ID
      ,T.OBJID
      ,T.DATE_ST
      ,T.DATE_EN
      ,DECODE(T.PERIOD_TYPE,'MONTH','Месяц','WEEK','Неделя',T.PERIOD_TYPE) PERIOD_TYPE
      ,T.PERIOD_INT
      ,T.TARIFF_SUMM
 FROM GC.SDM$IBS_TARIFF T
WHERE 1=1
  AND T.OBJID = POBJID
  order by 3;
    --
    RETURN VCURSOR;
  END;    
  
  FUNCTION GET_MAINA_LIST
    (POBJID VARCHAR2
    ) RETURN SYS_REFCURSOR
  IS
    VCURSOR SYS_REFCURSOR;
  BEGIN
    OPEN VCURSOR FOR
 SELECT D.OBJID ID
       ,M.UNP
       ,M.SUMM
       ,GC.NNS.GET(A_DT.S,A_DT.CUR) NNS_DT
       ,GC.NNS.GET(A_KT.S,A_KT.CUR) NNS_KT     
       ,M.TEX TXT
       ,'Проведено' STATUS   
     FROM GC.SDM$IBS_DOCUM D
         ,GC.MAINA M
         ,GC.VW$ACC_ACCA A_DT
         ,GC.VW$ACC_ACCA A_KT
  WHERE 1=1
    AND D.OBJID = pOBJID
    AND M.UNP = D.UNP
    AND A_DT.S = M.S_DT
    AND A_KT.S = M.S_KT
    AND M.STORNO IS NULL
UNION
 SELECT D.OBJID ID
       ,M.UNP
       ,M.SUMM
       ,GC.NNS.GET(A_DT.S,A_DT.CUR) NNS_DT
       ,GC.NNS.GET(A_KT.S,A_KT.CUR) NNS_KT     
       ,M.TEX TXT
       ,DS.NAME STATUS   
     FROM GC.SDM$IBS_DOCUM D
         ,GC.MAIN M
         ,GC.VW$ACC_ACCA A_DT
         ,GC.VW$ACC_ACCA A_KT
         ,GC.DS DS
  WHERE 1=1
    AND D.OBJID = pOBJID
    AND M.UNP = D.UNP
    AND A_DT.S = M.S_DT
    AND A_KT.S = M.S_KT
    AND DS.STATUS = M.STATUS
    AND DS.STATUS <> '12';
    
    RETURN VCURSOR;
    END;
              
 
 
 
       
  procedure get_ibs_info
    (pObjId in varchar2
    ,pOst_Deposit out varchar2
    ,pOst_Rent out varchar2
    ,pOst_Nns out varchar2
    ,pOst_91202 out varchar2   
    ,pOst_91203 out varchar2               
    )
  is
    vOst_Deposit number:=0;
    vOst_Rent number:=0;
    vOst_Nns number:=0;
    vOst_91202 number:=0;
    vOst_91203 number:=0;        
  begin
begin
    select gc.saldo.signed(a.s,a.cur)
    into vOst_Deposit
    from gc.sdm_ibs s
        ,gc.acc a
    where 1=1
      and s.objid = pObjid
      and a.objid = s.objid_deposit;
    EXCEPTION WHEN NO_DATA_FOUND THEN 
    vOst_Deposit:=0;            
END; 

begin
    select gc.saldo.signed(a.s,a.cur)
    into vOst_Rent
    from gc.sdm_ibs s
        ,gc.acc a
    where 1=1
      and s.objid = pObjid    
      and a.objid = s.objid_rent;
    EXCEPTION WHEN NO_DATA_FOUND THEN 
    vOst_Rent:=0;            
END; 

begin
    select gc.saldo.signed(a.s,a.cur)
    into vOst_Nns
    from gc.sdm_ibs s
        ,gc.nns_list n
        ,gc.acc a
    where 1=1
      and s.objid = pObjid    
      and n.nns = s.nns
      and n.enddat > sysdate
      and a.s = n.s;
    EXCEPTION WHEN NO_DATA_FOUND THEN 
    vOst_Nns:=0;            
END;  

begin
    select gc.saldo.signed(a.s,a.cur)
    into vOst_91202
    from gc.sdm_ibs s
        ,gc.acc a
    where 1=1
      and s.objid = pObjid    
      and a.objid = s.objid_91202;
    EXCEPTION WHEN NO_DATA_FOUND THEN 
    vOst_91202:=0;            
END;   

begin
    select gc.saldo.signed(a.s,a.cur)
    into vOst_91203
    from gc.sdm_ibs s
        ,gc.acc a
    where 1=1
      and s.objid = pObjid    
      and a.objid = s.objid_91203;
    EXCEPTION WHEN NO_DATA_FOUND THEN 
    vOst_91203:=0;            
END;         
    --
    pOst_Deposit:=fmt_num(vOst_Deposit,2,'C');
    pOst_Rent:=fmt_num(vOst_Rent,2,'C');
    pOst_Nns:=fmt_num(vOst_Nns,2,'C');
    pOst_91202:=fmt_num(vOst_91202,2,'C');
    pOst_91203:=fmt_num(vOst_91203,2,'C');        
  end;
  --
  
  function get_print_list return sys_refcursor
  is
    vCursor sys_refcursor;
  begin
    open vCursor for
select '1' as ID ,'Печать договора банковская ячейка' as CAPTION from dual
union all
select '2' as ID,'Дополнительное соглашение к договору индивидуального банковского сейфа' as CAPTION from dual
union all
select '3' as ID,'Договор аренды индивидуального банковского сейфа с условием ответственного хранения' as CAPTION from dual
union all
select '4' as ID,'Доверенность на доступ к индивидуальному банковскому сейфу с условием ответственного хранения' as CAPTION from dual
union all
select '5' as ID,'Доверенность на доступ к индивидуальному банковскому сейфу' as CAPTION from dual
union all
select '6' as ID,'Подтверждение о пролонгации' as CAPTION from dual
union all
select '7' as ID,'Акт вскрытия индивидуального банковского сейфа' as CAPTION from dual;
    return vCursor;
  end;
  
  function get_reason_unlock_list return sys_refcursor
  is
    vCursor sys_refcursor;
  begin
    open vCursor for
SELECT SV.VALUE1 AS ID,SV.VALUE2 AS CAPTION FROM GC.SPRAV$TYPES S
             ,GC.SPRAV$VALUES SV
WHERE 1=1
  AND S.NAME = 'USER$IBS_UNLOCK_REASON'
  AND SV.ID_TYPE = S.ID;
    return vCursor;
  end;  
  
  
  function get_execincome_list return sys_refcursor
  is
    vCursor sys_refcursor;
  begin
    open vCursor for
select uuid,user_exec,date_exec,date_start,date_end from gc.ibs$income_exec order by date_exec;
    return vCursor;
  end;  
  
  function get_typeibs_list return sys_refcursor
  is
    vCursor sys_refcursor;
  begin
    open vCursor for
select '1' as ID ,'Простое хранение' as CAPTION from dual
union all
select '2' as ID,'Ответственное хранение' as CAPTION from dual
union all
select '3' as ID,'Сделка простое хранение' as CAPTION from dual
union all
select '4' as ID,'Сделка ответсвенное хранение' as CAPTION from dual;
    return vCursor;
  end;  
  --
  


  procedure add_ibs
    (pObjid number
    ,pSubjID varchar2
    ,pNumDog varchar2
    ,pNumIBS varchar2
    ,pSizeIBS varchar2
    ,pPlace varchar2
    ,pDeposit varchar2
    ,pNns varchar2   
    ,pDateOpen date
    ,pTypePeriod varchar2
    ,pPeriod int
    ,pTel varchar2 default null
    ,pMail varchar2 default null
    ,pTel_Dop varchar2 default null --Телефон связанного лица, в случае сделки
    ,pMail_Dop varchar2 default null --Почта связанного лица, в случае сделки    
    ,pIBS_Type int
    ,pLinkSubj varchar2
    ,pIBS_DEAL varchar2
    ,pProlong number
    )
  is
    vId number;
    vSubjId dog.subj_id%type;
    vNewMsg varchar2(4000);
    vSizeIBS sdm_ibs.size_ibs%type;
    vPlace sdm_ibs.Place%type;
    vDeposit sdm_ibs.Deposit%type;
    vFilial sdm_ibs.Filial%type;
    vOtdel sdm_ibs.Otdel%Type;
    vControl number;
    vOtdelID number;
    vFilialID number;
    vSum varchar2(8);
    v_ObjID_42309 varchar2(12);
    v_ObjID_47422 varchar2(12);
    v_ObjID_91202 varchar2(12);
    v_ObjID_91203 varchar2(12);  
    vDateEnd date;  
    vIBS_DEAL_INFO varchar2(100);
    vIBS_DEAL_SUMM number;
    vCheckSizeNum int;
    vTARIFF_ID number;
  begin
    --vId:=objid.nextval;
    --ID начитывается в блоке кода
    vID:=pObjid;
    IF pTypePeriod = 'MONTH' then 
    vDateEnd := Add_Months(pDateOpen,pPeriod)-1;
    END IF;
    IF pTypePeriod = 'WEEK' AND pPeriod = 1 then 
    vDateEnd := pDateOpen+7;
    END IF;  
    IF pTypePeriod = 'WEEK' AND pPeriod = 2 then 
    vDateEnd := pDateOpen+14;
    END IF;       
    
    select substr(oa1.value1,instr(oa1.value1,' ',-1)+1) 
    into vSizeIBS 
    from gc.sprav$values oa1 
    where id = pSizeIBS;
    
    SELECT COUNT(*)
    INTO vCheckSizeNum 
    FROM GC.SDM$IBS_NNS 
    WHERE SIZE_ID = pSizeIBS 
      AND NUM_IBS = pNumIBS;
      
    IF vCheckSizeNum = 0 THEN   
    app_err.put('0',0,'РАЗМЕР ЯЧЕЙКИ НЕ СООТВЕТСВУЕТ НОМЕРУ ЯЧЕЙКИ '||pNumIBS);
    END IF; 
    
    BEGIN
    SELECT SV1.VALUE2,CASE WHEN SV.VALUE1 LIKE '%ЦЕНТРАЛЬНЫЙ%' THEN TO_NUMBER(SV1.VALUE3) 
                       WHEN SV.VALUE1 LIKE '%ОТДЕЛЕНИЯ%' THEN TO_NUMBER(SV1.VALUE4)
                       ELSE TO_NUMBER(SV1.VALUE5)
                       END
    INTO vIBS_DEAL_INFO,vIBS_DEAL_SUMM
          FROM GC.SPRAV$VALUES SV
              ,GC.SPRAV$TYPES S
              ,GC.SPRAV$VALUES SV1
         WHERE 1=1
           AND SV.ID = pSizeIBS
           AND S.NAME = 'USER$IBS_DEAL'
           AND S.ID = SV1.ID_TYPE
           AND SV1.VALUE1 = pIBS_DEAL;
    EXCEPTION WHEN NO_DATA_FOUND THEN
    NULL;
    END;           
    
    select oa1.value1
          ,gc.a_otdelenie_fil(decode(oa1.value2,'M','382',oa1.value2))
          ,decode(oa1.Value3,'','ОТДЕЛЕНИЕ "ЦЕНТРАЛЬНОЕ"',ss.Name) OTD
          ,decode(oa1.value2,'M','382',oa1.value2)   
          ,decode(oa1.Value3,'','0',oa1.value3)
    into vPlace
        ,vFilial
        ,vOtdel
        ,vFilialID
        ,vOtdelID
    from gc.sprav$values oa1
        ,gc.subj ss 
    where oa1.id = pPlace
      and ss.id (+)=oa1.value3;
    
    select oa1.value1 
    into vDeposit
    from gc.sprav$values oa1
    where oa1.id = pDeposit;
BEGIN
    SELECT DISTINCT 1
      INTO vControl 
           FROM GC.SDM_IBS S
          WHERE 1=1
            AND S.NUM_IBS = pNumIBS
            AND S.FILIAL = vFilial
            AND S.OTDEL = vOtdel
            AND (S.DATE_CLOSE IS NULL OR S.DATE_CLOSE = TO_DATE('31/12/4712','DD/MM/YYYY'));
    EXCEPTION WHEN NO_DATA_FOUND THEN 
    vControl:=0;            
END;
    If vControl = 1 THEN 
    app_err.put('0',0,'ЯЧЕЙКА В ЭТОМ ОТДЕЛЕНИИ ПОД ТАКИМ НОМЕРОМ УЖЕ ОТКРЫТА');
    END IF;            

BEGIN
    SELECT DISTINCT 1
       INTO vControl
            FROM GC.SPRAV$VALUES SV
                ,GC.SPRAV$VALUES SV1
           WHERE 1=1
             AND SV.ID = pPlace
             AND SV1.ID = pSizeIBS
             AND (SV.VALUE2 = SV1.VALUE2 AND SV1.VALUE2 <> '0' --ФИЛИАЛ 
                   OR SV1.VALUE2 = '0' AND SV.VALUE3 IN ('1373255','1247202') --ОТДЕЛЕНИЕ 
                    OR SV.VALUE3 = SV1.VALUE2); --ЦЕНТРАЛИЗОВАННЫЕ ФИЛИАЛЫ
    EXCEPTION WHEN NO_DATA_FOUND THEN 
    vControl:=0;
END;                    
    IF vControl <> 1 THEN         
    app_err.put('0',0,'ВЫБРАННЫЙ РАЗМЕР ЯЧЕЙКИ НЕ СООТВЕТСВУЕТ МЕСТОПОЛОЖЕНИЮ'||'('||pPlace||'-'||pSizeIBS||')');
    END IF;             
    
--ПОСЧИТАЕМ ТАРИФ  
Begin  
select summ
into vSUM
from (    select case when d1.value >= 0 and d1.value < 1 then (select oaa.value2 from gc.sprav$values oaa where oaa.id_type = '2409475529' and oaa.value1 = d.value)
                      when d1.value between 1 and 2 then (select oaa.value3 from gc.sprav$values oaa where oaa.id_type = '2409475529' and oaa.value1 = d.value) 
                      when d1.value between 3 and 5 then (select oaa1.value4 from gc.sprav$values oaa1 where oaa1.id_type = '2409475529' and oaa1.value1 = d.value) 
                      when d1.value between 6 and 11 then (select oaa2.value5 from gc.sprav$values oaa2 where oaa2.id_type = '2409475529' and oaa2.value1 = d.value) 
                      when d1.value >=12 then (select oaa3.value6 from gc.sprav$values oaa3 where oaa3.id_type = '2409475529' and oaa3.value1 = d.value) 
                      
                

       
 else '0' end||'.00' as summ from
(select substr(oa1.value1,instr(oa1.value1,' ',-1)+1) as value1,oa1.value1 as value from gc.sprav$values oa1 where  oa1.Id = pSizeIBS) d,
(select round(MONTHS_BETWEEN(vDateEnd,nvl(pDateOpen,trunc(sysdate)))) as value from dual) d1);
    EXCEPTION WHEN NO_DATA_FOUND THEN 
    vSum:='999999';
End;  

--ПРОВЕРИМ ЕСТЬ ЛИ ТАКАЯ ЯЧЕЙКА ВООБЩЕ С ТАКИМ НОМЕРОМ
BEGIN
SELECT DISTINCT 1
into vControl
    FROM GC.SDM$IBS_NNS S
   WHERE 1=1
     AND S.NUM_IBS=PNUMIBS 
     AND S.FILIAL = vFilialID
     AND S.OTDEL = decode(vOtdelID,'382','0',vOtdelID);
    EXCEPTION WHEN NO_DATA_FOUND THEN 
    vControl:=0;
END;                    
    IF vControl <> 1 THEN         
    app_err.put('0',0,'ЯЧЕЙКА С ТАКИМ НОМЕРОМ НЕ НАЙДЕНА В ВЫБРАННОМ ОТДЕЛЕНИИ');
    END IF;      
    
    IF vDateEnd is null /*or vDateEnd < trunc(sysdate)*/ THEN         
    app_err.put('0',0,'НЕ КОРРЕКТНАЯ ДАТА ОКОНЧАНИЯ');
    END IF;

IF pTel is not null then
insert into gc.sdm$ibs_phone
select vID,'SUBJ',pSubjID,'PHONE',pTel from dual;
END IF;
IF pMail is not null then
insert into gc.sdm$ibs_phone
select vID,'SUBJ',pSubjID,'MAIL',pMail from dual;
END IF;
IF pTel_Dop is not null then
insert into gc.sdm$ibs_phone
select vID,'SUBJDOP',pLinkSubj,'PHONE',pTel_Dop from dual;
END IF;
IF pMail_Dop is not null then
insert into gc.sdm$ibs_phone
select vID,'SUBJDOP',pLinkSubj,'MAIL',pMail_DOp from dual;
END IF;



vTARIFF_ID:=GC.SDM$IBS_TARIFF_SEQ.NEXTVAL;
INSERT INTO GC.SDM$IBS_TARIFF
      (ID
      ,OBJID
      ,DATE_ST
      ,DATE_EN
      ,PERIOD_TYPE
      ,PERIOD_INT
      ,TARIFF_SUMM
      )
      VALUES
( vTARIFF_ID
      ,vID
      ,nvl(pDateOpen,trunc(sysdate))
      ,vDateEnd
      ,pTypePeriod
      ,pPeriod
      ,vSum); 



    insert into sdm_ibs
      (objid
      ,subj_id
      ,Filial
      ,Otdel
      ,num_dog
      ,num_ibs
      ,size_ibs
      ,size_ibs_id
      ,place
      ,tariff_id
      ,deposit
      ,nns
      ,date_open
      ,dfinal
      ,user_ins
      ,date_ins  
      ,ibs_type
      ,linksubj 
      ,ibs_deal
      ,deal_summ 
      ,period_type
      ,period_int
      ,prolong
      )
    values
      (vID
      ,pSubjID
      ,vFilial
      ,vOtdel
      ,pNumDog
      ,pNumIBS
      ,vSizeIBS
      ,pSizeIBS
      ,vPlace
      ,vTARIFF_ID
      ,vDeposit
      ,decode(pNns,'0','',pNns)
      ,nvl(pDateOpen,trunc(sysdate))
      ,vDateEnd
      ,SYS_CONTEXT('USERENV','SESSION_USER')
      ,sysdate
      ,pIBS_Type
      ,pLinkSubj
      ,vIBS_DEAL_INFO
      ,vIBS_DEAL_SUMM
      ,pTypePeriod
      ,pPeriod
      ,pProlong
      );
GC.P_SUPPORT.ARM_START();      
--    vNewMsg:=getjourinfo(vId);
    gc.jour_pack.add_to_journal('SDMIBS',vId,'SDMIBS_ADD','I','',vNewMsg);
    
begin
select a.ObjID into v_Objid_42309 
         from gc.sdm$ibs_nns s
             ,gc.nns_list n
             ,gc.acc a 
      where n.nns = s.NNS 
        and n.s = a.s 
        and s.NUM_IBS=pNumIBS
        and substr(s.NNS,1,5) = '42309'
        and s.filial = vFilialID 
        and s.otdel = decode(vOtdelID,'382','0',vOtdelID);
if not gc.radd_q(objtype_ =>'ACC'
                    ,objid_ =>v_Objid_42309
                    ,name_ =>'SDM_IBS_DEPOSIT'
                    ,num_ => 0
                    ,txt_ =>'Привязка договора залога к клиенту '||pSubjID||'. Добавлен при запуске блока кода "ИБС" '||sysdate
                    ,value_ =>pSubjID
                    ,date_b_ => sysdate
                    ,date_e_ => null
                    ,filial =>null)
    then 
        gc.app_err.put ('BOOKKEEP', 292);
    end if;
update gc.sdm_ibs
   set objid_deposit = v_Objid_42309
where num_ibs = pNumIBS
  and subj_id = pSubjID
  and filial = vFilial
  and otdel = vOtdel
  and date_close is null
  and user_del is null;
--commit;
end;



begin
GC.P_SUPPORT.ARM_START();
select a.ObjID into v_Objid_47422 
         from gc.sdm$ibs_nns s
             ,gc.nns_list n
             ,gc.acc a 
      where substr(n.nns,1,8) = substr(s.nns,1,8) 
        and substr(s.nns,10,11) = substr(n.nns,10,11) 
        and n.s = a.s 
        and s.NUM_IBS=pNumIBS
        and substr(s.NNS,1,5) = '47422'
        and s.filial = vFilialID 
        and s.otdel = decode(vOtdelID,'382','0',vOtdelID);
if not gc.radd_q(objtype_ =>'ACC'
                    ,objid_ =>v_ObjID_47422
                    ,name_ =>'SDM_IBS_RENT'
                    ,num_ => 0
                    ,txt_ =>'Привязка счета аренды к клиенту '||pSubjID||'. Добавлен при запуске блока кода "ИБС" '||sysdate
                    ,value_ =>pSubjID
                    ,date_b_ => sysdate
                    ,date_e_ => null
                    ,filial =>null)
    then 
        gc.app_err.put ('BOOKKEEP', 292);
    end if;
update gc.sdm_ibs
   set objid_rent = v_Objid_47422
where num_ibs = pNumIBS
  and subj_id = pSubjID
  and filial = vFilial
  and otdel = vOtdel
  and date_close is null
  and user_del is null;
--commit;
end;


begin
GC.P_SUPPORT.ARM_START();
select a.ObjID into v_Objid_91202 
         from gc.sdm$ibs_nns s
             ,gc.nns_list n
             ,gc.acc a 
      where n.nns = s.NNS 
        and n.s = a.s 
        and s.NUM_IBS=pNumIBS
        and substr(s.NNS,1,5) = '91202'
        and s.filial = vFilialID 
        and s.otdel = decode(vOtdelID,'382','0',vOtdelID);
if not gc.radd_q(objtype_ =>'ACC'
                    ,objid_ =>v_ObjID_91202
                    ,name_ =>'SDM_IBS_91202'
                    ,num_ => 0
                    ,txt_ =>'Привязка счета учета ключей к клиенту '||pSubjID||'. Добавлен при запуске блока кода "ИБС" '||sysdate
                    ,value_ =>pSubjID
                    ,date_b_ => sysdate
                    ,date_e_ => null
                    ,filial =>null)
    then 
        gc.app_err.put ('BOOKKEEP', 292);
    end if;
update gc.sdm_ibs
   set objid_91202 = v_Objid_91202
where num_ibs = pNumIBS
  and subj_id = pSubjID
  and filial = vFilial
  and otdel = vOtdel
  and date_close is null
  and user_del is null;
--commit;
end;



begin
GC.P_SUPPORT.ARM_START();
select a.ObjID into v_Objid_91203 
         from gc.sdm$ibs_nns s
             ,gc.nns_list n
             ,gc.acc a 
      where n.nns = s.NNS 
        and n.s = a.s 
        and s.NUM_IBS=pNumIBS 
        and substr(s.NNS,1,5) = '91203'
        and s.filial = vFilialID 
        and s.otdel = decode(vOtdelID,'382','0',vOtdelID);
if not gc.radd_q(objtype_ =>'ACC'
                    ,objid_ =>v_ObjID_91203
                    ,name_ =>'SDM_IBS_91203'
                    ,num_ => 0
                    ,txt_ =>'Привязка счета учета ключей к клиенту '||pSubjID||'. Добавлен при запуске блока кода "ИБС" '||sysdate
                    ,value_ =>pSubjID
                    ,date_b_ => sysdate
                    ,date_e_ => null
                    ,filial =>null)
    then 
        gc.app_err.put ('BOOKKEEP', 292);
    end if;
update gc.sdm_ibs
   set objid_91203 = v_Objid_91203
where num_ibs = pNumIBS
  and subj_id = pSubjID
  and filial = vFilial
  and otdel = vOtdel
  and date_close is null
  and user_del is null;
--commit;
end;
    
    
    
    
  end;
  --
  procedure upd_ibs
    (pObjId varchar2
    ,pNumDog varchar2
--    ,pTariff number
    ,pNns varchar2
    ,pDeposit number
    ,pDfinal date
    ,pPhone varchar2
    ,pMail varchar2
    ,pPhone_Dop varchar2
    ,pMail_Dop varchar2    
    )
  is
  vControl number;
  vOldMsg varchar2(4000);
  vNumDog_OLD varchar2(30);
--  vTariff_OLD number;
  vNns_OLD varchar2(20);
  vDeposit_OLD number;
  vDfinal_OLD date;
  vPhone_OLD varchar2(100);
  vMAIL_OLD varchar2(100);
  vPhone_Dop_OLD varchar2(100);
  vMAIL_Dop_OLD varchar2(100);  
  vSUMMA_OTV_OLD number;
  vSUBJ_ID varchar2(15);
  vLINKSUBJ varchar2(15);
  begin
  --  vOldMsg:=getjourinfo(pId);
  vControl := 0;
BEGIN 
GC.P_SUPPORT.ARM_START();

 SELECT 1 
 INTO vControl
  FROM GC.NNS_LIST N
      ,GC.ACC A
      ,GC.PLAN P
  WHERE 1=1
    AND N.NNS = REPLACE(pNNS,' ')
    AND N.S = A.S
    AND N.CUR = A.CUR
    AND A.BS = P.BS
    AND P.PS = '003';
    EXCEPTION WHEN NO_DATA_FOUND THEN 
    vControl:=0;
END;
    IF vControl <> 1 AND LENGTH(REPLACE(pNNS,' '))>0 THEN         
    app_err.put('0',0,'ВВЕДЕН НЕКОРРЕКТНЫЙ НОМЕР СЧЕТА ДЛЯ СПИСАНИЯ');
    END IF;      
    --
    begin
    select a.num_dog
          ,a.nns
          ,a.deposit
          ,a.dfinal
          ,a.subj_id
          ,a.linksubj
    into   vNumDog_OLD
          ,vNns_OLD 
          ,vDeposit_OLD
          ,vDfinal_OLD  
          ,vSUBJ_ID
          ,vLINKSUBJ         
    from gc.sdm_ibs a
    where a.Objid = pObjId;
    end;
    
    begin
    select max(p.num)
    into vPhone_OLD
    from gc.sdm$ibs_phone p
    where 1=1
      and p.objid = pObjid
      and p.typesubj = 'SUBJ'
      and p.typephone = 'PHONE';
    exception when no_data_found then
    null;
    end;
    
    begin
    select max(p.num)
    into vMail_OLD
    from gc.sdm$ibs_phone p
    where 1=1
      and p.objid = pObjid
      and p.typesubj = 'SUBJ'
      and p.typephone = 'MAIL';
    exception when no_data_found then
    null;
    end;  
    
    begin
    select max(p.num)
    into vPhone_Dop_OLD
    from gc.sdm$ibs_phone p
    where 1=1
      and p.objid = pObjid
      and p.typesubj = 'SUBJDOP'
      and p.typephone = 'PHONE';
    exception when no_data_found then
    null;
    end;
    
    begin
    select max(p.num)
    into vMail_Dop_OLD
    from gc.sdm$ibs_phone p
    where 1=1
      and p.objid = pObjid
      and p.typesubj = 'SUBJDOP'
      and p.typephone = 'MAIL';
    exception when no_data_found then
    null;
    end;          
    
    update gc.sdm_ibs a
    set    a.num_dog      = pNumDog
          ,a.nns          = pNns
          ,a.deposit      = pDeposit
          ,a.dfinal       = pDfinal
    where  a.Objid = pObjId;
    
    IF vPhone_OLD is not null then
    update gc.sdm$ibs_phone
    set num = pPhone
    where objid = pObjId
      and typesubj = 'SUBJ'
      and typephone = 'PHONE';
    ELSE
    IF pPhone is not null then 
    insert into gc.sdm$ibs_phone
    select pObjid,'SUBJ',vSUBJ_ID,'PHONE',pPhone from dual;
    END IF;
    END IF;  
    
    IF vPHONE_OLD is not null then  
    update gc.sdm$ibs_phone
    set num = pMail
    where objid = pObjId
      and typesubj = 'SUBJ'
      and typephone = 'MAIL'; 
    ELSE 
    IF pMail is not null then
    insert into gc.sdm$ibs_phone
    select pObjid,'SUBJ',vSUBJ_ID,'MAIL',pMail from dual;
    END IF;
    END IF; 
    
    IF vPhone_Dop_OLD is not null then
    update gc.sdm$ibs_phone
    set num = pPhone_Dop
    where objid = pObjId
      and typesubj = 'SUBJDOP'
      and typephone = 'PHONE';
    ELSE
    IF pPhone_Dop is not null then
    insert into gc.sdm$ibs_phone
    select pObjid,'SUBJDOP',vLINKSUBJ,'PHONE',pPhone_dop from dual;
    END IF;
    END IF;     
    
    IF vMail_Dop_OLD is not null then
    update gc.sdm$ibs_phone
    set num = pMail_Dop
    where objid = pObjId
      and typesubj = 'SUBJDOP'
      and typephone = 'MAIL';
    ELSE
    IF pMail_Dop is not null then
    insert into gc.sdm$ibs_phone
    select pObjid,'SUBJDOP',vLINKSUBJ,'MAIL',pMail_dop from dual;
    END IF;
    END IF;                   
    --returning a.dog_id into vDogId;
    --
    --check_amount(pId,vDogId,pAmount);
    --
   -- vNewMsg:=getjourinfo(pId);
   IF vNumDog_OLD <> pNumDog THEN
   gc.jour_pack.add_to_journal('SDMIBS',pObjId,'SDMIBS_UPD1','U',vNumDog_OLD,pNumDog);
   END IF;
--   IF vTariff_OLD <> pTariff THEN
--   gc.jour_pack.add_to_journal('SDMIBS',pObjId,'SDMIBS_UPD2','U',vTariff_OLD,pTariff);
--   END IF; 
   IF vDeposit_OLD <> pDeposit THEN
   gc.jour_pack.add_to_journal('SDMIBS',pObjId,'SDMIBS_UPD3','U',vDeposit_OLD,pDeposit);
   END IF; 
   IF vNNS_OLD <> pNNS THEN
   gc.jour_pack.add_to_journal('SDMIBS',pObjId,'SDMIBS_UPD4','U',vNNS_OLD,pNNS);
   END IF;   
   IF vDfinal_OLD <> pDfinal THEN
   gc.jour_pack.add_to_journal('SDMIBS',pObjId,'SDMIBS_UPD6','U',vDfinal_OLD,pDfinal);
   END IF;
   IF vPhone_OLD <> pPhone THEN
   gc.jour_pack.add_to_journal('SDMIBS',pObjId,'SDMIBS_UPD7','U',vPhone_OLD,pPhone);
   END IF;
   IF vPhone_Dop_OLD <> pPhone_Dop THEN
   gc.jour_pack.add_to_journal('SDMIBS',pObjId,'SDMIBS_UPD10','U',vPhone_Dop_OLD,pPhone_Dop);
   END IF;         
   IF vMAIL_OLD <> pMail THEN
   gc.jour_pack.add_to_journal('SDMIBS',pObjId,'SDMIBS_UPD8','U',vMAIL_OLD,pMail);
   END IF;  
   IF vMAIL_Dop_OLD <> pMail_Dop THEN
   gc.jour_pack.add_to_journal('SDMIBS',pObjId,'SDMIBS_UPD11','U',vMAIL_Dop_OLD,pMail_Dop);
   END IF;        
   COMMIT;           
  end;
  --
  procedure del_ibs(pID varchar2
                   )
  is
    vOldMsg varchar2(4000);
  begin
  gc.p_support.arm_start();
    vOldMsg:='Удаление ячейки';
    update gc.sdm_ibs a set a.user_del=SYS_CONTEXT('USERENV','SESSION_USER') 
    where a.Objid = pID
      and nvl(length(a.user_del),0) = 0;
 gc.jour_pack.add_to_journal('SDMIBS',pId,'SDMIBS_DEL','D',vOldMsg,'');
  end;
  
  
  procedure close_ibs(pID varchar2
                     ,pControl varchar2
                   )
  is
    vOldMsg varchar2(4000);
    vSUM_RENT number;
    vSUM_DEPOSIT number;
    vOBJID_42309 varchar2(12);
    vOBJID_47422 varchar2(12);
    vOBJID_91202 varchar2(12);
    vOBJID_91203 varchar2(12);    
  begin
  gc.p_support.arm_start();
    vOldMsg:='Закрытие ячейки';            

--Если ячейка закрывается через списание просрочки, то не контролируем остатки, т.к. проводки создаются автоматом
IF pControl <> 'No' THEN   
    begin
    select gc.saldo.signed(a.s,a.cur)
    into vSUM_RENT
    from gc.sdm_ibs s
        ,gc.acc a
    where 1=1
      and s.objid = pID
      and s.objid_rent = a.objid;
     EXCEPTION WHEN NO_DATA_FOUND THEN 
    vSUM_RENT:=0;
    end; 
    
    begin
    select gc.saldo.signed(a.s,a.cur)
    into vSUM_DEPOSIT
    from gc.sdm_ibs s
        ,gc.acc a
    where 1=1
      and s.objid = pID
      and s.objid_deposit = a.objid;
     EXCEPTION WHEN NO_DATA_FOUND THEN 
    vSUM_DEPOSIT:=0;    
    end;

IF vSUM_DEPOSIT>0 THEN 
 app_err.put('0',0,'ОБНАРУЖЕН ПОЛОЖИТЕЛЬНЫЙ ОСТАТОК НА СЧЕТЕ ЗАЛОГА');
END IF; 

END IF;

select s.objid_deposit
      ,s.objid_rent
      ,s.objid_91202
      ,s.objid_91203
into vOBJID_42309,vOBJID_47422,vOBJID_91202,vOBJID_91203      
      from gc.sdm_ibs s
where 1=1
  and s.ObjID = pID;      

begin
if not gc.radd_q(objtype_ =>'ACC'
                    ,objid_ =>vOBJID_42309
                    ,name_ =>'SDM_IBS_DEPOSIT'
                    ,num_ => 0
                    ,txt_ =>'Закрытие ячейки '||pID
                    ,value_ =>' '
                    ,date_b_ => sysdate
                    ,date_e_ => null
                    ,filial =>null)
    then 
        gc.app_err.put ('BOOKKEEP', 292);
    end if;
--commit;
end;
  

begin
if not gc.radd_q(objtype_ =>'ACC'
                    ,objid_ =>vOBJID_47422
                    ,name_ =>'SDM_IBS_RENT'
                    ,num_ => 0
                    ,txt_ =>'Закрытие ячейки '||pID
                    ,value_ =>' '
                    ,date_b_ => sysdate
                    ,date_e_ => null
                    ,filial =>null)
    then 
        gc.app_err.put ('BOOKKEEP', 292);
    end if;
--commit;
end;
   

begin
if not gc.radd_q(objtype_ =>'ACC'
                    ,objid_ =>vOBJID_91202
                    ,name_ =>'SDM_IBS_91202'
                    ,num_ => 0
                    ,txt_ =>'Закрытие ячейки '||pID
                    ,value_ =>' '
                    ,date_b_ => sysdate
                    ,date_e_ => null
                    ,filial =>null)
    then 
        gc.app_err.put ('BOOKKEEP', 292);
    end if;
--commit;
end;
   

begin
if not gc.radd_q(objtype_ =>'ACC'
                    ,objid_ =>vOBJID_91203
                    ,name_ =>'SDM_IBS_91203'
                    ,num_ => 0
                    ,txt_ =>'Закрытие ячейки '||pID
                    ,value_ =>' '
                    ,date_b_ => sysdate
                    ,date_e_ => null
                    ,filial =>null)
    then 
        gc.app_err.put ('BOOKKEEP', 292);
    end if;
--commit;
end;

        
    update gc.sdm_ibs a set a.user_close=SYS_CONTEXT('USERENV','SESSION_USER') 
                           ,a.date_close = sysdate
                           ,a.dfinal = case when pControl = 'No' then trunc(sysdate) else a.dfinal end 
    where a.Objid = pID
      and nvl(length(a.user_close),0) = 0;
    --commit;  
        gc.jour_pack.add_to_journal('SDMIBS',pId,'SDMIBS_CLOSE','C',vOldMsg,'');
  end;
    
  function DEPT_DEPOSIT
    (pObjID varchar2
    ,pDeposit_Doc number
    ,pCur varchar2
    ,pNNS varchar2
    ,pObjidDeposit varchar2
    ,pVltrDt date
    ,pNazPlat varchar2
    ,pTypeOper varchar2    
    ) return number
  is
    vSumm number;
    vSDt acc.s%type;
    vCurDt acc.cur%type;
    vOtdel acc.otdel%type;
    vFilial acc.filial%type;    
    vAmount number;
    vSkt acc.s%type;
    vUnoDt number;
    vUnoKt number;
    vUnp number;
    vCashRes varchar2(4000);
    vStatus number;
    vSubjID varchar2(12);
    vCnt_maina number;
    vCnt_main number;
    vOst_408 number;
    vS_20202 varchar2(12);    
  begin

--pTypeOper 1 --Со счета 408
--pTypeOper 2 --Через кассу    

IF pTypeOper = '1' THEN
    BEGIN  
    select a.s
          ,a.cur
          ,gc.saldo.signed(a.s,a.cur)
    into   vSDt
          ,vCurDt
          ,vOst_408 
    from  gc.nns_list n
         ,gc.acc a
    where n.nns = pNNS
      and n.s = a.s;
    EXCEPTION WHEN NO_DATA_FOUND THEN
    APP_ERR.PUT('0',0,'НЕ НАЙДЕН СЧЕТ СПИСАНИЯ');         
    END;        
END IF;      
    
    BEGIN  
    select a.s
          ,a.Otdel    
          ,a.filial
    into   vSKt
          ,vOtdel
          ,vFilial
    from  gc.nns_list n
         ,gc.acc a
    where n.nns = pObjidDeposit
      and n.s = a.s;
    EXCEPTION WHEN NO_DATA_FOUND THEN
    APP_ERR.PUT('0',0,'НЕ НАЙДЕН СЧЕТ ЗАЛОГА');         
    END;      
      
    BEGIN
    select a.subj_id
    into   vSubjID
    from  gc.sdm_ibs a
    where a.objid = pObjID; 
    EXCEPTION WHEN NO_DATA_FOUND THEN
    APP_ERR.PUT('0',0,'ЧТО-ТО НЕ ПОНЯТНОЕ С ИДЕНТИФИКАТОРОМ ЯЧЕЙКИ');            
    END;           
    --
    --
    if vOtdel is null then
      vOtdel:=user_login.otdel_id;
    end if;
    
    BEGIN
    SELECT COUNT(*)
    INTO vCnt_maina
    FROM GC.MAINA M
    WHERE 1=1
      --AND M.S_DT = vSDt
      AND M.S_KT = vSKt
      AND TRUNC(M.VLTR_DT) = TRUNC(SYSDATE);
    EXCEPTION WHEN NO_DATA_FOUND THEN
    vCNT_Maina := 0;           
    END;
    
    IF vCNT_Maina > 0 THEN
    APP_ERR.PUT('0',0,'ДОКУМЕНТ СПИСАНИЯ ЗАЛОГА УЖЕ БЫЛ ПРОВЕДЕН В ТЕКУЩЕМ ОПЕРАЦИОННОМ ДНЕ. ОПЕРАЦИЯ НЕВОЗМОЖНА');
    END IF;
    
    BEGIN
    SELECT COUNT(*)
    INTO vCnt_main
    FROM GC.MAIN M
    WHERE 1=1
      --AND M.S_DT = vSDt
      AND M.S_KT = vSKt
      AND M.STATUS <> '12';
    EXCEPTION WHEN NO_DATA_FOUND THEN
    vCNT_Main := 0;           
    END;
    
    IF vCNT_Main > 0 THEN
    APP_ERR.PUT('0',0,'НАЙДЕНЫ НЕ ОБРАБОТАННЫЕ ИЛИ НЕ ПОДТВЕРЖДЕННЫЕ ДОКУМЕНТЫ ПО СПИСАНИЮ ЗАЛОГА. ОПЕРАЦИЯ НЕВОЗМОЖНА');
    END IF;      

    IF vOst_408 < pDeposit_Doc AND pTypeOper = '1' THEN
    APP_ERR.PUT('0',0,'На счете '||pNNS||' недостаточно средств для списание залога : '||to_char(pDeposit_Doc,'999999.99'));
    END IF;
 

    --ГО
    IF vFilial = 'M' and vOtdel = 0 THEN
    vS_20202 := '000000000038'; --20202810700000000001 
    END IF;  
    
    --Раменское
    IF vFilial = 'M' and vOtdel = '1247202' THEN
    vS_20202 := '000000106746'; --20202810000140000001
    END IF;       
    
    --Нижний Новгород
    IF vFilial = 'M' and vOtdel = '3012703215' THEN
    vS_20202 := '000002493711'; --20202810407000000003 
    END IF; 
    
    --Екатеринбург
    IF vFilial = 'M' and vOtdel = '2858299385' THEN
    vS_20202 := '000002444309'; --20202810410000000003    
    END IF;        
     
    --Красноярск
    IF vFilial = 'M' and vOtdel = '2895452858' THEN
    vS_20202 := '000002452752'; --20202810602000000002      
    END IF;     
    
    --Ростов
    IF vFilial = 'M' and vOtdel = '2719862922' THEN
    vS_20202 := '000002408788'; --20202810709000000002    
    END IF;    
    
    --Пермь
    IF vFilial = 'M' and vOtdel = '3012696210' THEN
    vS_20202 := '000002493642'; --20202810504000000003     
    END IF;           

    --Воронеж
    IF vFilial = 'M' and vOtdel = '3087040484' THEN
    vS_20202 := '000002525622'; --20202810203000000003     
    END IF;
    
    --Тверь (на всякий случай)
    IF vFilial = 'M' and vOtdel = '2895452718' THEN
    vS_20202 := '000002452710'; --20202810806000000002     
    END IF;  
    
    --Санкт-Петербург (на всякий случай)
    IF vFilial = 'M' and vOtdel = '3085772695' THEN
    vS_20202 := '000002525382'; --20202810805000000003     
    END IF;

IF pTypeOper = '1' THEN

    ins_doc_advanced(vUnoDt
                    ,vUnoKt
                    ,vUnp
                    ,vSDt
                    ,vSKt
                    ,vCurDt
                    ,pCur
                    ,v_KO => '2000'
                    ,V_SUMM_KT => pDeposit_Doc
                    ,V_TEX => pNazPlat
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => pNazPlat
                    ,V_STATUS => '13'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    ,V_EXT => ' EntAtExpOfLA#Y#  EntAtExpOfLAMethod#WaitResponse#  EntAtExpOfLARsv#F#'
                    );
ELSE

--42777    12 - Поступление налогов, сборов, взносов и страховых платежей
--1199    32 - Прочие поступления
--Запрос, который начитывает кассовые символы
--select id,name||decode(sname,null,'',' - '||sname) caption from gc.sprav where type=chr(7) and nvl(status,0) = 0 order by name

--Основной документ
    ins_doc_advanced(vUnoDt
                    ,vUnoKt
                    ,vUNP
                    ,vS_20202
                    ,vSKt
                    ,'810'
                    ,'810'
                    ,v_KO => '0420'
                    ,V_SUMM_KT => pDeposit_Doc
                    ,V_TEX => 'Взнос наличными .'||pNazPlat
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => 'Взнос наличными .'||pNazPlat
                    ,V_STATUS => '16'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    ,V_CASH_SYM_ID => '1199'
                    ,V_EXT => ' EntAtExpOfLA#Y#  EntAtExpOfLAMethod#WaitResponse#  EntAtExpOfLARsv#F#'
                    );
                    
END IF;                                        
    --
    if vUnp is null then
      doc_p(vUnp,vUnoDt);
      insert into gc.sdm$ibs_docum
      select pObjID,vUnp,'Списание залога' from dual;
    end if;
    --

    return vUnp;
  end;

  
function DEPT_RENT
    (pObjID varchar2
    ,pTariff_Doc number
    ,pCur varchar2
    ,pNNS varchar2
    ,pObjidTariff varchar2
    ,pVltrDt date
    ,pNazPlat varchar2
    ,pTypeOper varchar2
    ) return number
  is
    vSumm number;
    vSummNDS number;
    vSDt acc.s%type;
    vCurDt acc.cur%type;
    vOtdel acc.otdel%type;
    vFilial acc.otdel%type;    
    vAmount number;
    vSkt acc.s%type;
    vSkt_Nds acc.s%type;    
    vUnoDt number;
    vUnoKt number;
    vUnoDt_NDS number;
    vUnoKt_NDS number;    
    vUnp number;
    vCashRes varchar2(4000);
    vStatus number;
    vSubjID varchar2(12);
    vNDS number;
    vCNT_Maina number;
    vCNT_Main number;
    vOst_408 number;
    vS_20202 varchar2(12);
  begin
  
--pTypeOper 1 --Со счета 408
--pTypeOper 2 --Через кассу  

IF pTypeOper = '1' THEN
    BEGIN
    select a.s
          ,a.cur
          ,gc.saldo.signed(a.s,a.cur) 
    into   vSDt
          ,vCurDt
          ,vOst_408 
    from  gc.nns_list n
         ,gc.acc a
    where n.nns = pNNS
      and n.s = a.s;
    EXCEPTION WHEN NO_DATA_FOUND THEN
    APP_ERR.PUT('0',0,'НЕ НАЙДЕН СЧЕТ СПИСАНИЯ');         
    END;          
END IF;      
      
    select a.s
          ,a.filial
          ,a.otdel
    into   vSKt
          ,vFilial
          ,vOtdel           
    from  gc.nns_list n
         ,gc.acc a
    where n.nns = pObjidTariff
      and n.s = a.s;
      
    select a.subj_id
    into   vSubjID
    from  gc.sdm_ibs a
    where a.objid = pObjID; 
    
    BEGIN
    SELECT COUNT(*)
    INTO vCnt_maina
    FROM GC.MAINA M
    WHERE 1=1
      --AND M.S_DT = vSDt
      AND M.S_KT = vSKt
      AND TRUNC(M.VLTR_DT) = TRUNC(SYSDATE);
    EXCEPTION WHEN NO_DATA_FOUND THEN
    vCNT_Maina := 0;           
    END;
    
    IF vCNT_Maina > 0 THEN
    APP_ERR.PUT('0',0,'ДОКУМЕНТ СПИСАНИЯ АРЕНДЫ УЖЕ БЫЛ ПРОВЕДЕН В ТЕКУЩЕМ ОПЕРАЦИОННОМ ДНЕ. ОПЕРАЦИЯ НЕВОЗМОЖНА');
    END IF;
    
    BEGIN
    SELECT COUNT(*)
    INTO vCnt_main
    FROM GC.MAIN M
    WHERE 1=1
      --AND M.S_DT = vSDt
      AND M.S_KT = vSKt
      AND M.STATUS <> '12';
    EXCEPTION WHEN NO_DATA_FOUND THEN
    vCNT_Main := 0;           
    END;
    
    IF vCNT_Main > 0 THEN
    APP_ERR.PUT('0',0,'НАЙДЕНЫ НЕ ОБРАБОТАННЫЕ ИЛИ НЕ ПОДТВЕРЖДЕННЫЕ ДОКУМЕНТЫ ПО СПИСАНИЮ АРЕНДЫ. ОПЕРАЦИЯ НЕВОЗМОЖНА');
    END IF;    
       
    
    
   --ГО+Централизованные филиалы+Отделения
    IF vFilial = 'M' THEN 
    vSkt_Nds := '000000350796';
    END IF; 
    --Нижний
    IF vFilial = '2188666' THEN 
    vSkt_Nds := '000000771105';
    END IF;   
    --СПБ
    IF vFilial = '1228080' THEN 
    vSkt_Nds := '000002487936';
    END IF;   
    --Пермь
    IF vFilial = '1788104' THEN 
    vSkt_Nds := '000002487937';
    END IF;       
    --Воронеж       
    IF vFilial = '1787601' THEN 
    vSkt_Nds := '000000771280';
    END IF;  
    
    --ГО
    IF vFilial = 'M' and vOtdel = 0 THEN
    vS_20202 := '000000000038'; --20202810700000000001 
    END IF;  
    
    --Раменское
    IF vFilial = 'M' and vOtdel = '1247202' THEN
    vS_20202 := '000000106746'; --20202810000140000001
    END IF;       
    
    --Нижний Новгород
    IF vFilial = 'M' and vOtdel = '3012703215' THEN
    vS_20202 := '000002493711'; --20202810407000000003 
    END IF; 
    
    --Екатеринбург
    IF vFilial = 'M' and vOtdel = '2858299385' THEN
    vS_20202 := '000002444309'; --20202810410000000003    
    END IF;        
     
    --Красноярск
    IF vFilial = 'M' and vOtdel = '2895452858' THEN
    vS_20202 := '000002452752'; --20202810602000000002      
    END IF;     
    
    --Ростов
    IF vFilial = 'M' and vOtdel = '2719862922' THEN
    vS_20202 := '000002408788'; --20202810709000000002    
    END IF;    
    
    --Пермь
    IF vFilial = 'M' and vOtdel = '3012696210' THEN
    vS_20202 := '000002493642'; --20202810504000000003     
    END IF;           

    --Воронеж
    IF vFilial = 'M' and vOtdel = '3087040484' THEN
    vS_20202 := '000002525622'; --20202810203000000003     
    END IF;
    
    --Тверь (на всякий случай)
    IF vFilial = 'M' and vOtdel = '2895452718' THEN
    vS_20202 := '000002452710'; --20202810806000000002     
    END IF;  
    
    --Санкт-Петербург (на всякий случай)
    IF vFilial = 'M' and vOtdel = '3085772695' THEN
    vS_20202 := '000002525382'; --20202810805000000003     
    END IF;            
    
        
   --Получим текущий процент НДС
    vNDS := gc.qual$p_main.get('SYSRGT','SYSTEM','NDS');  
    --Посчитаем сумму документа без НДС
    vSumm:= round(pTariff_Doc-((pTariff_Doc*vNDS)/(100+vNDS)),2); 
    --Сумма НДС
    vSummNDS:= round(pTariff_Doc*vNDS/(100+vNDS),2);     
    --
    --
    if vOtdel is null then
      vOtdel:=user_login.otdel_id;
    end if;

    IF vOst_408 < vSumm+vSummNDS AND pTypeOper = '1' THEN
       APP_ERR.PUT('0',0,'На счете '||pNNS||' недостаточно средств для списание аренды : '||to_char(vSumm+vSummNDS,'999999.99'));
    END IF;       

SELECT gc.SEQ_DOC.NEXTVAL
INTO vUNP 
FROM DUAL;

IF pTypeOper = '1' THEN

--Основной документ
    ins_doc_advanced(vUnp
                    ,vUnp
                    ,vUNP
                    ,vSDt
                    ,vSKt
                    ,vCurDt
                    ,pCur
                    ,v_KO => '2000'
                    ,V_SUMM_KT => vSumm
                    ,V_TEX => pNazPlat
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => pNazPlat
                    ,V_STATUS => '13'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    ,V_EXT => ' EntAtExpOfLA#Y#  EntAtExpOfLAMethod#WaitResponse#  EntAtExpOfLARsv#F#'
                    );
--Документ НДС        
    ins_doc_advanced(vUnoDt_NDS
                    ,vUnoKt_NDS
                    ,vUnp
                    ,vSDt
                    ,vSkt_Nds
                    ,vCurDt
                    ,pCur
                    ,v_KO => '2359'
                    ,V_SUMM_KT => vSummNDS
                    ,V_TEX => 'НДС.'||pNazPlat
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => 'НДС.'||pNazPlat
                    ,V_STATUS => '13'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    ,V_EXT => ' EntAtExpOfLA#Y#  EntAtExpOfLAMethod#WaitResponse#  EntAtExpOfLARsv#F#'                    
                    );     

ELSE

--42777    12 - Поступление налогов, сборов, взносов и страховых платежей
--1199    32 - Прочие поступления
--Запрос, который начитывает кассовые символы
--select id,name||decode(sname,null,'',' - '||sname) caption from gc.sprav where type=chr(7) and nvl(status,0) = 0 order by name

--Основной документ
    ins_doc_advanced(vUnp
                    ,vUnp
                    ,vUNP
                    ,vS_20202
                    ,vSKt
                    ,'810'
                    ,'810'
                    ,v_KO => '0420'
                    ,V_SUMM_KT => vSumm
                    ,V_TEX => 'Взнос наличными. '||pNazPlat
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => 'Взнос наличными. '||pNazPlat
                    ,V_STATUS => '16'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    ,V_CASH_SYM_ID => '1199'
                    ,V_EXT => ' EntAtExpOfLA#Y#  EntAtExpOfLAMethod#WaitResponse#  EntAtExpOfLARsv#F#'
                    );
--Документ НДС        
    ins_doc_advanced(vUnoDt_NDS
                    ,vUnoKt_NDS
                    ,vUnp
                    ,vS_20202
                    ,vSkt_Nds
                    ,'810'
                    ,'810'
                    ,v_KO => '2333'
                    ,V_SUMM_KT => vSummNDS
                    ,V_TEX => 'Взнос наличными. НДС.'||pNazPlat
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => 'Взнос наличными. НДС.'||pNazPlat
                    ,V_STATUS => '16'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    ,V_CASH_SYM_ID => '42777'
                    ,V_EXT => ' EntAtExpOfLA#Y#  EntAtExpOfLAMethod#WaitResponse#  EntAtExpOfLARsv#F#'                    
                    );      
END IF;                        
    --
    if vUnp is null then
      doc_p(vUnp,vUnoDt);
    else
      insert into gc.sdm$ibs_docum
      select pObjID,vUnp,'Списание аренды' from dual;      
    end if;
    --

    return vUnp;
  end; 
  
 function OFF_DEPOSIT
    (pObjID varchar2
    ,pSUM number
    ,pCur varchar2
    ,pNNS varchar2
    ,pObjidDeposit varchar2
    ,pVltrDt date
    ,pNazPlat varchar2
    ,pTypeOper varchar2
    ) return number
  is
    vSumm number;
    vSDt acc.s%type;
    vCurDt acc.cur%type;
    vOtdel acc.otdel%type;
    vAmount number;
    vSkt acc.s%type;
    vUnoDt number;
    vUnoDtRent number;
    vUnoKt number;
    vUnoKtRent number;
    vUnp number;
    vCashRes varchar2(4000);
    vStatus number;
    vSubjID varchar2(12);
    vOst_Rent number;
    vIncome_Rent acc.s%type;
    vSDt_Rent acc.s%type;    
    vCurDt_Rent acc.cur%type;
    vFilialDt_Rent acc.filial%type;
    vOtdelDt_Rent acc.otdel%type;
    vNazPlat_Rent varchar2(200);
    vS_20202 number;
  begin

--pTypeOper 1 --На счет 408
--pTypeOper 2 --Через кассу  

IF pTypeOper = '1' THEN
    BEGIN
    SELECT A.S
          ,A.CUR
    INTO   vSKT
          ,vCURDT
    FROM  GC.NNS_LIST N
         ,GC.ACC A
    WHERE 1=1
      AND N.NNS = pNNS
      AND N.S = A.S;
    EXCEPTION WHEN NO_DATA_FOUND THEN
    APP_ERR.PUT('0',0,'НЕ НАЙДЕН СЧЕТ СПИСАНИЯ');         
    END;        
END IF;      
      
    SELECT A.S
          ,A.OTDEL
    INTO   vSDT
          ,vOTDEL    
    FROM  GC.NNS_LIST N
         ,GC.ACC A
    WHERE 1=1
      AND N.NNS = pOBJIDDEPOSIT
      AND N.S = A.S;
      
    SELECT A.SUBJ_ID
    INTO   vSUBJID
    FROM  GC.SDM_IBS A
    WHERE 1=1
      AND A.OBJID = pOBJID;            
    --
    --
    IF vOTDEL IS NULL THEN
      vOTDEL:=USER_LOGIN.OTDEL_ID;
    END IF;

    BEGIN
    SELECT GC.SALDO.SIGNED(A.S,A.CUR)
          ,A.S
          ,A.CUR
          ,A.FILIAL
          ,A.OTDEL
          ,'Доходы за ИБС № '||S.NUM_IBS||' в связи с расторжением договора аренды'
    INTO vOst_Rent
        ,vSDt_Rent
        ,vCurDt_Rent
        ,vFilialDt_Rent
        ,vOtdelDt_Rent
        ,vNazPlat_Rent
    FROM GC.SDM_IBS S
        ,GC.ACC A
    WHERE 1=1
      AND S.OBJID_RENT = A.OBJID
      AND S.OBJID = pObjID;
    EXCEPTION WHEN NO_DATA_FOUND THEN       
       APP_ERR.PUT('0',0,'НЕ НАЙДЕН ОТКРЫТЫЙ СЧЕТ АРЕНДЫ ЯЧЕЙКИ');
    END;   
    
  --ГО
  IF vFilialDt_Rent = 'M' and vOtdelDt_Rent = 0 THEN
    vIncome_Rent := '000002509134'; --70601810200352830151 
    vS_20202 := '000000000038'; --20202810700000000001     
  END IF;  
    
  --Раменское
  IF vFilialDt_Rent = 'M' and vOtdelDt_Rent = '1247202' THEN
    vIncome_Rent := '000002509136'; --70601810300142830151
    vS_20202 := '000000106746'; --20202810000140000001    
  END IF;       
    
  --Нижний Новгород
  IF vFilialDt_Rent = 'M' and vOtdelDt_Rent = '3012703215' THEN
    vIncome_Rent := '000002509137'; --70601810307352830151 
    vS_20202 := '000002493711'; --20202810407000000003     
  END IF; 
    
  --Екатеринбург
  IF vFilialDt_Rent = 'M' and vOtdelDt_Rent = '2858299385' THEN
    vIncome_Rent := '000002509139'; --70601810110002830151    
    vS_20202 := '000002444309'; --20202810410000000003     
  END IF;        
     
  --Красноярск
  IF vFilialDt_Rent = 'M' and vOtdelDt_Rent = '2895452858' THEN
    vIncome_Rent := '000002509142'; --70601810602002830151    
    vS_20202 := '000002452752'; --20202810602000000002          
  END IF;     
    
  --Ростов
  IF vFilialDt_Rent = 'M' and vOtdelDt_Rent = '2719862922' THEN
    vIncome_Rent := '000002509144'; --70601810709002830151    
    vS_20202 := '000002408788'; --20202810709000000002      
  END IF;    
    
  --Пермь
  IF vFilialDt_Rent = 'M' and vOtdelDt_Rent = '3012696210' THEN
    vIncome_Rent := '000002542254'; --70601810204002830151
    vS_20202 := '000002493642'; --20202810504000000003              
  END IF;           

  --Воронеж
  IF vFilialDt_Rent = 'M' and vOtdelDt_Rent = '3087040484' THEN
    vIncome_Rent := '000002542255'; --70601810903002830151    
    vS_20202 := '000002525622'; --20202810203000000003       
  END IF;  
        
  --Тверь (на всякий случай)
  IF vFilialDt_Rent = 'M' and vOtdel = '2895452718' THEN
  vS_20202 := '000002452710'; --20202810806000000002     
  END IF;  
    
  --Санкт-Петербург (на всякий случай)
  IF vFilialDt_Rent = 'M' and vOtdel = '3085772695' THEN
  vS_20202 := '000002525382'; --20202810805000000003     
  END IF;            

SELECT gc.SEQ_DOC.NEXTVAL
INTO vUNP 
FROM DUAL;

IF pTypeOper = '1' THEN

    ins_doc_advanced(vUnoDt
                    ,vUnoKt
                    ,vUnp
                    ,vSDt
                    ,vSKt
                    ,vCurDt
                    ,pCur
                    ,v_KO => '2004'
                    ,V_SUMM_KT => pSUM
                    ,V_TEX => pNazPlat
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => pNazPlat
                    ,V_STATUS => '13'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    );
                    
ELSE        

--42777    12 - Поступление налогов, сборов, взносов и страховых платежей
--1199    32 - Прочие поступления
--1200  53 - Выдачи на другие цели (тут ХЗ, надо посоветоваться со Старчиковой)
--Запрос, который начитывает кассовые символы
--select id,name||decode(sname,null,'',' - '||sname) caption from gc.sprav where type=chr(7) and nvl(status,0) = 0 order by name

    ins_doc_advanced(vUnoDt
                    ,vUnoKt
                    ,vUNP
                    ,vSDt
                    ,vS_20202
                    ,'810'
                    ,'810'
                    ,v_KO => '0421'
                    ,V_SUMM_KT => pSUM
                    ,V_TEX => 'Выдача наличными .'||pNazPlat
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => 'Выдача наличными .'||pNazPlat
                    ,V_STATUS => '16'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    ,V_CASH_SYM_ID => '1200'
                    ,V_EXT => ' EntAtExpOfLA#Y#  EntAtExpOfLAMethod#WaitResponse#  EntAtExpOfLARsv#F#'
                    );
                    
END IF;                                 
                    
    IF vOst_Rent > 0 THEN
    ins_doc_advanced(vUnoDtRent
                    ,vUnoKtRent
                    ,vUnp
                    ,vSDt_Rent
                    ,vIncome_Rent
                    ,vCurDt_Rent
                    ,vCurDt_Rent
                    ,v_KO => '0429'
                    ,V_SUMM_KT => vOst_Rent
                    ,V_TEX => vNazPlat_Rent
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => vNazPlat_Rent
                    ,V_STATUS => '13'
                    ,V_OTDEL => vOtdelDt_Rent
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    );    
    END IF;
    
                        
    --
    if vUnp is null then
      doc_p(vUnp,vUnoDt);
    else  
      insert into gc.sdm$ibs_docum
      select pObjID,vUnp,'Возврат залога' from dual;      
    end if;


    return vUnp;
  end;  


 function UNLOCK_DEPOSIT
    (pObjID varchar2
    ,pSUM number
    ,pObjidDeposit varchar2
    ,pTypeOper varchar2    
    ,pVltrDt date
    ,pNazPlat varchar2
    ,pUNP number    
    ) return number
  is
    vSDt acc.s%type;
    vUnoDt number;
    vUnoKt number;
    vUnp number;
    vNazPlat varchar2(200);
    vNazPlatDop varchar2(200);
    vFilial acc.filial%type;
    vOtdel acc.otdel%type;
    vSubjID sdm_ibs.subj_id%type;
    vS_KT_INCOME varchar2(12);
    vS_47422 varchar2(12);
    vRES varchar2(300);
  
      
  BEGIN
  GC.P_SUPPORT.ARM_START();
  -- pTypeOper 1 Перечисление в доход
  -- pTypeOper 2 Перечисление на счет не выясненных сумм
  
    
  BEGIN 
    SELECT A.S
          ,A.FILIAL
          ,A.OTDEL
    INTO   vSDT
          ,vFilial
          ,vOtdel 
    FROM  GC.NNS_LIST N
         ,GC.ACC A
    WHERE 1=1
      AND N.NNS = pOBJIDDEPOSIT
      AND N.S = A.S;
  EXCEPTION WHEN NO_DATA_FOUND THEN  
      APP_ERR.PUT('0',0,'НЕ НАЙДЕН СЧЕТ ЗАЛОГА');
  END;
    
            
  SELECT A.SUBJ_ID
        ,'Доходы за ИБС № '||A.NUM_IBS||' по договору '||A.NUM_DOG||' от '||to_char(A.DATE_OPEN,'DD.MM.YYYY')||' '||S.NAME
        ,'Закрытие ИБС № '||A.NUM_IBS||' по договору '||A.NUM_DOG||' от '||to_char(A.DATE_OPEN,'DD.MM.YYYY')||' '||S.NAME
    INTO   vSUBJID
          ,vNazPlat
          ,vNazPlatDop
    FROM  GC.SDM_IBS A
         ,GC.SUBJ S
   WHERE 1=1
     AND A.OBJID = pOBJID
     AND S.ID = A.SUBJ_ID;  

  --ГО
  IF vFILIAL = 'M' and vOTDEL = 0 THEN
    vS_KT_INCOME := '000002509134'; --70601810200352830151 
    vS_47422 := '000002542248'; --47422810600000702000 --счет невыясненных сумм по учету залогов
  END IF;  
    
  --Раменское
  IF vFILIAL = 'M' and vOTDEL = '1247202' THEN
    vS_KT_INCOME := '000002509136'; --70601810300142830151
  END IF;       
    
  --Нижний Новгород
  IF vFILIAL = 'M' and vOTDEL = '3012703215' THEN
    vS_KT_INCOME := '000002509137'; --70601810307352830151 
  END IF; 
    
  --Екатеринбург
  IF vFILIAL = 'M' and vOTDEL = '2858299385' THEN
    vS_KT_INCOME := '000002509139'; --70601810110002830151    
  END IF;        
     
  --Красноярск
  IF vFILIAL = 'M' and vOTDEL = '2895452858' THEN
    vS_KT_INCOME := '000002509142'; --70601810602002830151      
  END IF;     
    
  --Ростов
  IF vFILIAL = 'M' and vOTDEL = '2719862922' THEN
    vS_KT_INCOME := '000002509144'; --70601810709002830151    
  END IF;    
    
  --Пермь
  IF vFILIAL = 'M' and vOTDEL = '3012696210' THEN
    vS_KT_INCOME := '000002542254'; --70601810204002830151     
  END IF;           

  --Воронеж
  IF vFILIAL = 'M' and vOTDEL = '3087040484' THEN
    vS_KT_INCOME := '000002542255'; --70601810903002830151     
  END IF;      
    
IF pUNP is null THEN
SELECT gc.SEQ_DOC.NEXTVAL
INTO vUNP 
FROM DUAL;
ELSE 
vUNP := pUNP;
END IF;

IF pTypeOper = '1' THEN
BEGIN
    ins_doc_advanced(vUnoDt
                    ,vUnokt
                    ,vUnp
                    ,vSDT
                    ,vS_KT_INCOME
                    ,'810'
                    ,'810'
                    ,v_KO => '0429'
                    ,V_SUMM_KT => pSUM
                    ,V_TEX => vNazPlat
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => vNazPlat
                    ,V_STATUS => '15'
                    ,V_OTDEL => vOTDEL
                    ,V_VLTR_DT => sysdate
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    );
  EXCEPTION WHEN OTHERS THEN
  vRES:=SQLERRM;
  APP_ERR.PUT('0',0,vRES);
  END;                    
END IF;         

IF pTypeOper = '2' THEN
  IF vS_47422 IS NULL THEN
  ROLLBACK;
      APP_ERR.PUT('0',0,'НЕ НАЙДЕН СЧЕТ НЕВЫЯСНЕННЫХ СУММ');
  END IF;   
BEGIN     
    ins_doc_advanced(vUnoDt
                    ,vUnokt
                    ,vUnp
                    ,vSDT
                    ,vS_47422
                    ,'810'
                    ,'810'
                    ,v_KO => '0428'
                    ,V_SUMM_KT => pSUM
                    ,V_TEX => vNazPlatDop
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => vNazPlatDop
                    ,V_STATUS => '15'
                    ,V_OTDEL => vOTDEL
                    ,V_VLTR_DT => sysdate
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    );  
  EXCEPTION WHEN OTHERS THEN
  vRES:=SQLERRM;
  APP_ERR.PUT('0',0,vRES);
  END;                         
END IF;                       

    if vUnp is null then
      doc_p(vUnp,vUnoDt);
    else  
      insert into gc.sdm$ibs_docum
      select pObjID,vUnp,'Вскрытие ячейки' from dual;      
    end if;

    return vUnp;
  end;    
  

function OVERDUE
    (pObjID varchar2
    ,pSUM number
    ,pCur varchar2
    ,pNNS varchar2
    ,pINCOME varchar2   
    ,pVltrDt date
    ,pNazPlat varchar2
    ,pTypePeriod varchar2
    ,pPeriod int     
    ,pTypeOperDelay varchar2
    ,pTypeOperClose varchar2
    ,pTypeOperProlong varchar2     
    ) return number
  is
    vSumm number;
    vSummNDS number;
    vSDt acc.s%type;
    vCurDt acc.cur%type;
    vOtdel acc.otdel%type;
    vFilial acc.filial%type;    
    vAmount number;
    vSkt acc.s%type;
    vSkt_Nds acc.s%type;  
    vOst_408 number;  
    vUnoDt number;
    vUnoKt number;
    vUnoDt_NDS number;
    vUnoKt_NDS number;   
    vUnoDt_OffDep number;
    vUnoKt_OffDep number;   
    vUnoDtRent number;
    vUnoKtRent number; 
    vUnoDtRentNew number;
    vUnoKtRentNew number;   
    vUnoDt_NDSRentNew number;
    vUnoKt_NDSRentNew number;                    
    vUnp number;
    vCashRes varchar2(4000);
    vStatus number;
    vSubjID varchar2(12);
    vNDS number;
    vNazPlat_OffDep varchar2(200);
    vNazPlat_Rent varchar2(200);   
    vNazPlatRentNew varchar2(200);    
    vOST_DEP number;
    vSDt_OffDep acc.s%type;
    vCUR_OffDep acc.cur%type;
    vOST_RENT number;
    vSDt_RENT acc.s%type;
    vCUR_RENT acc.cur%type; 
    vDateEnd date;
    vSizeIBS number; 
    vSUM_RENT_NEW number; 
    vSummNewRent number;  
    vSummNDSNewRent number;  
    vTariff_DocNewRent number; 
    vNum_Dog varchar2(100);   
    vFIO varchar2(100);  
    vDateDog date;  
    vTARIFF_ID number;  
    vNum_Ibs varchar2(10);
    vS_20202 varchar2(12);
    
  begin

IF pTypeOperDelay = '1' or (pTypeOperClose = '1' and pTypePeriod = 'CLOSE') or pTypeOperProlong = '1' THEN
    BEGIN
    select a.s
          ,a.cur
          ,gc.saldo.signed(a.s,a.cur) ost_408
    into   vSDt
          ,vCurDt
          ,vOst_408
    from  gc.nns_list n
         ,gc.acc a
    where 1=1
      and n.nns = pNNS
      and n.s = a.s;
  EXCEPTION WHEN NO_DATA_FOUND THEN  
      APP_ERR.PUT('0',0,'НЕ НАЙДЕН СЧЕТ '||pNNS);
  END;
END IF;        
      
    select a.s
    into   vSKt
    from  gc.nns_list n
         ,gc.acc a
    where 1=1
      and n.nns = pINCOME
      and n.enddat > sysdate
      and n.s = a.s;
      
    select a.subj_id
          ,a.size_ibs_id
          ,a.num_dog
          ,s.name
          ,a.date_ins
          ,a.num_ibs
    into   vSubjID
          ,vSizeIBS 
          ,vNum_Dog
          ,vFIO
          ,vDateDog
          ,vNum_Ibs
    from  gc.sdm_ibs a
         ,gc.subj s         
    where 1=1
      and a.objid = pObjID
      and s.id = a.subj_id;   
    
   --Получим текущий процент НДС
    vNDS := gc.qual$p_main.get('SYSRGT','SYSTEM','NDS');  
    --Посчитаем сумму документа без НДС
    vSumm:= round(pSUM-((pSUM*vNDS)/(100+vNDS)),2); 
    --Сумма НДС
    vSummNDS:= round(pSUM*vNDS/(100+vNDS),2);    
    --
    --
    if vOtdel is null then
      vOtdel:=user_login.otdel_id;
    end if;

SELECT gc.SEQ_DOC.NEXTVAL
INTO vUNP 
FROM DUAL;

IF pTypePeriod = 'CLOSE' then
SELECT GC.SALDO.SIGNED(A.S,A.CUR)
      ,A.S  
      ,A.CUR
      ,'Возврат залога за ключ от ИБС № '||vNum_Ibs||' по договору № '||s.num_dog||' от '||to_char(s.date_open,'dd.mm.yyyy')||' '||SS.NAME
INTO vOST_DEP
    ,vSDt_OffDep
    ,vCUR_OffDep
    ,vNazPlat_OffDep
 FROM GC.SDM_IBS S
     ,GC.ACC A
     ,GC.SUBJ SS
WHERE 1=1
  AND S.OBJID = pObjID
  AND S.OBJID_DEPOSIT = A.OBJID
  AND SS.ID = S.SUBJ_ID;     
END IF;
  
SELECT GC.SALDO.SIGNED(A.S,A.CUR)
      ,A.S  
      ,A.CUR
      ,'Доходы за ИБС № '||vNum_Ibs||' по договору № '||s.num_dog||' от '||to_char(s.date_open,'dd.mm.yyyy')||' За период от '||
      --Найдем последнюю проводку по списанию в доход по этой ячейке      
      NVL(TO_CHAR((SELECT MAX(M.OPER_DT)+1 FROM GC.MAINA M 
            WHERE 1=1
              AND M.K_O = '0429'
              AND M.S_DT = A.S
              AND M.S_KT = vSKt --доходы
              AND M.OPER_DT >= TRUNC(S.DATE_OPEN)
              ),'DD.MM.YYYY'),TO_CHAR(S.DATE_OPEN,'DD.MM.YYYY'))||' по '||TO_CHAR(S.DFINAL,'DD.MM.YYYY')||' '||SS.NAME

      ,A.FILIAL
      ,NVL(A.OTDEL,0)      
       
INTO vOST_RENT
    ,vSDt_RENT
    ,vCUR_RENT
    ,vNazPlat_Rent
    ,vFilial
    ,vOtdel
 FROM GC.SDM_IBS S
     ,GC.ACC A
     ,GC.SUBJ SS
WHERE 1=1
  AND S.OBJID = pObjID
  AND S.OBJID_RENT = A.OBJID
  AND SS.ID = S.SUBJ_ID;   
  
    --ГО
    IF vFilial = 'M' and vOtdel = 0 THEN
    vSkt_Nds := '000000350796';    
    vS_20202 := '000000000038'; --20202810700000000001 
    END IF;  
    
    --Раменское
    IF vFilial = 'M' and vOtdel = '1247202' THEN
    vSkt_Nds := '000000350796';     
    vS_20202 := '000000106746'; --20202810000140000001
    END IF;       
    
    --Нижний Новгород
    IF vFilial = 'M' and vOtdel = '3012703215' THEN
    vSkt_Nds := '000000350796';     
    vS_20202 := '000002493711'; --20202810407000000003 
    END IF; 
    
    --Екатеринбург
    IF vFilial = 'M' and vOtdel = '2858299385' THEN
    vSkt_Nds := '000000350796';     
    vS_20202 := '000002444309'; --20202810410000000003    
    END IF;        
     
    --Красноярск
    IF vFilial = 'M' and vOtdel = '2895452858' THEN
    vSkt_Nds := '000000350796';     
    vS_20202 := '000002452752'; --20202810602000000002      
    END IF;     
    
    --Ростов
    IF vFilial = 'M' and vOtdel = '2719862922' THEN
    vSkt_Nds := '000000350796';     
    vS_20202 := '000002408788'; --20202810709000000002    
    END IF;    
    
    --Пермь
    IF vFilial = 'M' and vOtdel = '3012696210' THEN
    vSkt_Nds := '000000350796';     
    vS_20202 := '000002493642'; --20202810504000000003     
    END IF;           

    --Воронеж
    IF vFilial = 'M' and vOtdel = '3087040484' THEN
    vSkt_Nds := '000000350796';     
    vS_20202 := '000002525622'; --20202810203000000003     
    END IF;
    
    --Тверь (на всякий случай)
    IF vFilial = 'M' and vOtdel = '2895452718' THEN
    vSkt_Nds := '000000350796';     
    vS_20202 := '000002452710'; --20202810806000000002     
    END IF;  
    
    --Санкт-Петербург (на всякий случай)
    IF vFilial = 'M' and vOtdel = '3085772695' THEN
    vSkt_Nds := '000000350796';     
    vS_20202 := '000002525382'; --20202810805000000003     
    END IF;     


IF pTypePeriod = 'MONTH' then 
vDateEnd := Add_Months(trunc(sysdate),pPeriod)-1;
END IF;
IF pTypePeriod = 'WEEK' AND pPeriod = 1 then 
vDateEnd := trunc(sysdate)+7;
END IF;  
IF pTypePeriod = 'WEEK' AND pPeriod = 2 then 
vDateEnd := trunc(sysdate)+14;
END IF;      
 
--Посчитаем новый тариф
IF pTypePeriod in ('MONTH','WEEK') THEN
Begin  
select to_number(summ)
into vSUM_RENT_NEW
from (    select case when d1.value >= 0 and d1.value < 1 then (select oaa.value2 from gc.sprav$values oaa where oaa.id_type = '2409475529' and oaa.value1 = d.value)
                      when d1.value between 1 and 2 then (select oaa.value3 from gc.sprav$values oaa where oaa.id_type = '2409475529' and oaa.value1 = d.value) 
                      when d1.value between 3 and 5 then (select oaa1.value4 from gc.sprav$values oaa1 where oaa1.id_type = '2409475529' and oaa1.value1 = d.value) 
                      when d1.value between 6 and 11 then (select oaa2.value5 from gc.sprav$values oaa2 where oaa2.id_type = '2409475529' and oaa2.value1 = d.value) 
                      when d1.value >=12 then (select oaa3.value6 from gc.sprav$values oaa3 where oaa3.id_type = '2409475529' and oaa3.value1 = d.value) 
                      
                

       
 else '0' end||'.00' as summ from
(select substr(oa1.value1,instr(oa1.value1,' ',-1)+1) as value1,oa1.value1 as value from gc.sprav$values oa1 where  oa1.Id = vSizeIBS) d,
(select round(MONTHS_BETWEEN(vDateEnd,trunc(sysdate))) as value from dual) d1);
    EXCEPTION WHEN NO_DATA_FOUND THEN 
    vSUM_RENT_NEW:='0';
End;  

  IF vOst_408 < (vSUM_RENT_NEW*pPeriod)+pSUM THEN

       APP_ERR.PUT('0',0,'На счете '||pNNS||' недостаточно средств для списание аренды по новому сроку и просрочки: '||to_char((vSUM_RENT_NEW*pPeriod)+pSUM,'999999.99'));
  END IF;    
    --Новая сумма аренды за весь срок
    vTariff_DocNewRent := vSUM_RENT_NEW*pPeriod;
    --Получим текущий процент НДС
    vNDS := gc.qual$p_main.get('SYSRGT','SYSTEM','NDS');  
    --Посчитаем сумму документа без НДС
    vSummNewRent:= round(vTariff_DocNewRent-((vTariff_DocNewRent*vNDS)/(100+vNDS)),2); 
    --Сумма НДС
    vSummNDSNewRent:= round(vTariff_DocNewRent*vNDS/(100+vNDS),2);  
    --Назначение платежа основного документа по списанию аренды
    vNazPlatRentNew:= 'Оплата аренды ИБС № '||vNum_Ibs||' по Договору № '||vNum_Dog||' от '||to_char(vDateDog,'DD.MM.YYYY')||' за период с '||to_char(sysdate,'DD.MM.YYYY')||' по '||to_char(vDateEnd,'DD.MM.YYYY')||';(с л/сч '||pNNS||') '||vFIO;
    
vTARIFF_ID:=GC.SDM$IBS_TARIFF_SEQ.NEXTVAL;
INSERT INTO GC.SDM$IBS_TARIFF
      (ID
      ,OBJID
      ,DATE_ST
      ,DATE_EN
      ,PERIOD_TYPE
      ,PERIOD_INT
      ,TARIFF_SUMM
      )
      VALUES
( vTARIFF_ID
      ,pObjID
      ,trunc(sysdate)
      ,trunc(vDateEnd)
      ,pTypePeriod
      ,pPeriod
      ,vSUM_RENT_NEW); 


    
update gc.sdm_ibs
set tariff_id = vTARIFF_ID
   --,date_open = trunc(sysdate)
   ,dfinal = trunc(vDateEnd)
   ,period_type = pTypePeriod
   ,period_int = pPeriod
where objid = pObjID;   
GC.JOUR_PACK.ADD_TO_JOURNAL('SDMIBS',pObjID,'SDMIBS_PROL','P','','Пролонгация ячейки: период '||pTypePeriod||' , количество интервалов '||pPeriod);                      
END IF;



--Основной документ
--Просрочка есть. Выбран режим "Списать со счета"
IF vSumm > 0  and pTypeOperDelay = '1' THEN
BEGIN
    ins_doc_advanced(vUnoDt
                    ,vUnoKt
                    ,vUNP
                    ,vSDt
                    ,vSKt
                    ,vCurDt
                    ,pCur
                    ,v_KO => '0009'
                    ,V_SUMM_KT => vSumm
                    ,V_TEX => pNazPlat
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => pNazPlat
                    ,V_STATUS => '13'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    ,V_EXT => ' EntAtExpOfLA#Y#  EntAtExpOfLAMethod#WaitResponse#  EntAtExpOfLARsv#F#'                    
                    );
EXCEPTION WHEN OTHERS THEN
APP_ERR.PUT('0',0,'0-'||SQLERRM);
END;                    
--Документ НДС      
BEGIN  
    ins_doc_advanced(vUnoDt_NDS
                    ,vUnoKt_NDS
                    ,vUnp
                    ,vSDt
                    ,vSkt_Nds
                    ,vCurDt
                    ,pCur
                    ,v_KO => '2359'
                    ,V_SUMM_KT => vSummNDS
                    ,V_TEX => 'НДС.'||pNazPlat
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => 'НДС.'||pNazPlat
                    ,V_STATUS => '13'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    ,V_EXT => ' EntAtExpOfLA#Y#  EntAtExpOfLAMethod#WaitResponse#  EntAtExpOfLARsv#F#'                    
                    );   
EXCEPTION WHEN OTHERS THEN
APP_ERR.PUT('0',0,'1-'||SQLERRM);
END;  
END IF;    


IF vSumm > 0  and pTypeOperDelay = '2' THEN        
BEGIN               
    ins_doc_advanced(vUnoDt
                    ,vUnoKt
                    ,vUNP
                    ,vS_20202
                    ,vSKt
                    ,'810'
                    ,'810'
                    ,v_KO => '2661'
                    ,V_SUMM_KT => vSumm
                    ,V_TEX => 'Взнос наличными. '||pNazPlat
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => 'Взнос наличными. '||pNazPlat
                    ,V_STATUS => '16'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    ,V_CASH_SYM_ID => '1199'--	32 - Прочие поступления
                    ,V_EXT => ' EntAtExpOfLA#Y#  EntAtExpOfLAMethod#WaitResponse#  EntAtExpOfLARsv#F#'                    
                    );
EXCEPTION WHEN OTHERS THEN
APP_ERR.PUT('0',0,'2-'||SQLERRM);
END;                     
--Документ НДС 
BEGIN       
    ins_doc_advanced(vUnoDt_NDS
                    ,vUnoKt_NDS
                    ,vUnp
                    ,vS_20202
                    ,vSkt_Nds
                    ,'810'
                    ,'810'
                    ,v_KO => '2333'
                    ,V_SUMM_KT => vSummNDS
                    ,V_TEX => 'Взнос наличными. НДС.'||pNazPlat
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => 'Взнос наличными. НДС.'||pNazPlat
                    ,V_STATUS => '16'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    ,V_CASH_SYM_ID => '42777' --12 - Поступление налогов, сборов, взносов и страховых платежей
                    ,V_EXT => ' EntAtExpOfLA#Y#  EntAtExpOfLAMethod#WaitResponse#  EntAtExpOfLARsv#F#'                    
                    );  
EXCEPTION WHEN OTHERS THEN
APP_ERR.PUT('0',0,'3-'||SQLERRM);
END;                      
END IF; 

IF pTypePeriod = 'CLOSE' AND vOST_DEP > 0 and pTypeOperClose = '1' then      
--Если ячейка закрыватся до возвращаем залог 
BEGIN             
    ins_doc_advanced(vUnoDt_OffDep
                    ,vUnoKt_OffDep
                    ,vUnp
                    ,vSDt_OffDep
                    ,vSDt --Счет клиента
                    ,vCUR_OffDep
                    ,vCUR_OffDep
                    ,v_KO => '2004'
                    ,V_SUMM_KT => vOST_DEP
                    ,V_TEX => vNazPlat_OffDep
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => vNazPlat_OffDep
                    ,V_STATUS => '13'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => sysdate-5/86400
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true                 
                    ); 
EXCEPTION WHEN OTHERS THEN
APP_ERR.PUT('0',0,'4-'||SQLERRM);
END;                                         
END IF;  
IF pTypePeriod = 'CLOSE' AND vOST_DEP > 0 and pTypeOperClose = '2' then      
--Если ячейка закрыватся до возвращаем залог 
BEGIN             
    ins_doc_advanced(vUnoDt_OffDep
                    ,vUnoKt_OffDep
                    ,vUnp
                    ,vSDt_OffDep
                    ,vS_20202 
                    ,vCUR_OffDep
                    ,vCUR_OffDep
                    ,v_KO => '0421'
                    ,V_SUMM_KT => vOST_DEP
                    ,V_TEX => 'Выдача наличными .'||vNazPlat_OffDep
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => 'Выдача наличными .'||vNazPlat_OffDep
                    ,V_STATUS => '16'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    ,V_CASH_SYM_ID => '1200'
                    ,V_EXT => ' EntAtExpOfLA#Y#  EntAtExpOfLAMethod#WaitResponse#  EntAtExpOfLARsv#F#'
                    ); 
EXCEPTION WHEN OTHERS THEN
APP_ERR.PUT('0',0,'5-'||SQLERRM);
END;                                    
END IF;  
--Проводки по внебалансу
IF pTypePeriod = 'CLOSE' THEN
vUNP:=vneb_key_create_doc(pObjID,'CLOSE',vUNP);
END IF;
                      
IF vOST_RENT > 0 THEN   
--Перечисляем в доход остаток на счете аренды 47422 
BEGIN                
    ins_doc_advanced(vUnoDtRent
                    ,vUnoKtRent
                    ,vUnp
                    ,vSDt_Rent
                    ,vSKt --Доходы
                    ,vCUR_RENT
                    ,vCUR_RENT
                    ,v_KO => '0429'
                    ,V_SUMM_KT => vOst_Rent
                    ,V_TEX => vNazPlat_Rent
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => vNazPlat_Rent
                    ,V_STATUS => '13'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true                 
                    );     
EXCEPTION WHEN OTHERS THEN
APP_ERR.PUT('0',0,'6-'||SQLERRM);
END;                                   
END IF;     

IF pTypePeriod in ('MONTH','WEEK') AND pTypeOperProlong = '1' THEN
--Документ по списанию новой аренды
BEGIN
    ins_doc_advanced(vUnoDtRentNew
                    ,vUnoKtRentNew
                    ,vUnp
                    ,vSDt
                    ,vSDt_RENT
                    ,vCUR_RENT
                    ,vCUR_RENT
                    ,v_KO => '2000'
                    ,V_SUMM_KT => vSummNewRent
                    ,V_TEX => vNazPlatRentNew
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => vNazPlatRentNew
                    ,V_STATUS => '13'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    ,V_EXT => ' EntAtExpOfLA#Y#  EntAtExpOfLAMethod#WaitResponse#  EntAtExpOfLARsv#F#'                    
                    );
EXCEPTION WHEN OTHERS THEN
APP_ERR.PUT('0',0,'7-'||SQLERRM);
END;                     
--Документ НДС за новую аренду      
BEGIN 
    ins_doc_advanced(vUnoDt_NDSRentNew
                    ,vUnoKt_NDSRentNew
                    ,vUnp
                    ,vSDt
                    ,vSkt_Nds
                    ,'810'
                    ,'810'
                    ,v_KO => '2359'
                    ,V_SUMM_KT => vSummNDSNewRent
                    ,V_TEX => 'НДС.'||vNazPlatRentNew
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => 'НДС.'||vNazPlatRentNew
                    ,V_STATUS => '13'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    ,V_EXT => ' EntAtExpOfLA#Y#  EntAtExpOfLAMethod#WaitResponse#  EntAtExpOfLARsv#F#'                    
                    );
EXCEPTION WHEN OTHERS THEN
APP_ERR.PUT('0',0,'8-'||SQLERRM);
END;                        
END IF; 

IF pTypePeriod in ('MONTH','WEEK') AND pTypeOperProlong = '2' THEN
--Документ по списанию новой аренды
BEGIN
    ins_doc_advanced(vUnoDtRentNew
                    ,vUnoKtRentNew
                    ,vUnp
                    ,vS_20202
                    ,vSDt_RENT
                    ,vCUR_RENT
                    ,vCUR_RENT
                    ,v_KO => '0420'
                    ,V_SUMM_KT => vSummNewRent
                    ,V_TEX => vNazPlatRentNew
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => vNazPlatRentNew
                    ,V_STATUS => '16'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    ,V_CASH_SYM_ID => '1199'                    
                    ,V_EXT => ' EntAtExpOfLA#Y#  EntAtExpOfLAMethod#WaitResponse#  EntAtExpOfLARsv#F#'                    
                    );
EXCEPTION WHEN OTHERS THEN
APP_ERR.PUT('0',0,'9-'||SQLERRM);
END;                     
--Документ НДС за новую аренду  
BEGIN     
    ins_doc_advanced(vUnoDt_NDSRentNew
                    ,vUnoKt_NDSRentNew
                    ,vUnp
                    ,vS_20202
                    ,vSkt_Nds
                    ,'810'
                    ,'810'
                    ,v_KO => '2333'
                    ,V_SUMM_KT => vSummNDSNewRent
                    ,V_TEX => 'Взнос наличными. НДС.'||vNazPlatRentNew
                    ,V_SUBJ => vSubjID
                    ,V_SUBJ_KT => vSubjID
                    ,V_TEX_KT => 'Взнос наличными. НДС.'||vNazPlatRentNew
                    ,V_STATUS => '16'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => pVltrDt
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    ,V_CASH_SYM_ID => '42777'                    
                    ,V_EXT => ' EntAtExpOfLA#Y#  EntAtExpOfLAMethod#WaitResponse#  EntAtExpOfLARsv#F#'                    
                    );   
EXCEPTION WHEN OTHERS THEN
APP_ERR.PUT('0',0,'10-'||SQLERRM);
END;                     
                    
                    
END IF;                                 
    --
    if vUnp is null then
      doc_p(vUnp,vUnoDt);
/*    else
      insert into gc.sdm$ibs_docum
      select pObjID,vUnp,'Списание просрочки' from dual;*/      
    end if;
    --

    return vUnp;
  end;   
  

  function vneb_key_create_doc
  (pObjid varchar2
  ,pType varchar2
  ,pUNP varchar2
  ) return number
  is
  vSum number;
  vS_91202 acc.s%type;
  vCur_91202 acc.Cur%type;
  vS_91203 acc.s%type;
  vCur_91203 acc.Cur%type;
  vS_91202_FIX acc.s%type; 
  vType_Ibs varchar2(50);
  vFILIAL acc.filial%type;
  vOTDEL acc.otdel%type;
  vNaz_Plat varchar2(200); 
  vNaz_Plat_Dop varchar2(200);
  vSUBJ_ID subj.id%type;
  vFIO varchar2(255);
  vFIO_LINK varchar2(255);
  vNUM_DOG varchar2(50);
  vNUM_IBS varchar2(8);
  vSUMMA_OTV varchar2(200);
  vUNP number;
  vS_99999 varchar2(12);
  vUnoDt number;
  vUnoKt number;
  vUnoDt_Dop number;
  vUnoKt_Dop number;  
  pSTATUS varchar2(2);   
  vDATEOPEN varchar2(10);
  begin
  
  gc.p_support.arm_start();
  SELECT A.S
        ,A.CUR
        ,A.FILIAL
        ,A.OTDEL        
        ,S.IBS_TYPE
        ,SS.ID
        ,SS.NAME
        ,S.NUM_DOG
        ,S.NUM_IBS
        ,(SELECT REGEXP_REPLACE(TO_CHAR(SYS_XMLAGG (XMLELEMENT (col, ST.SUMMA||DECODE(ST.CUR,'810',' руб','840',' долларов','978',' евро','156',' юаней','')||';')).EXTRACT('/ROWSET/COL/text()').getclobval ()),'.$','')  
            FROM GC.SDM$IBS_OTV ST                
            WHERE ST.OBJID = S.OBJID
            group by st.objid
            ) summa_otv
        ,TO_CHAR(S.DATE_OPEN,'DD.MM.YYYY')
        ,SSS.NAME 
  INTO vS_91202
      ,vCur_91202
      ,vFILIAL     
      ,vOTDEL
      ,vType_Ibs
      ,vSUBJ_ID
      ,vFIO   
      ,vNUM_DOG
      ,vNUM_IBS 
      ,vSUMMA_OTV
      ,vDATEOPEN
      ,vFIO_LINK
      FROM GC.SDM_IBS S
          ,GC.ACC A
          ,GC.SUBJ SS
          ,GC.SUBJ SSS
  WHERE 1=1
    AND S.OBJID = pOBJID
    AND A.OBJID = S.OBJID_91202
    AND SS.ID = S.SUBJ_ID
    AND SSS.ID(+)=S.LINKSUBJ;
    
  SELECT A.S
        ,A.CUR
  INTO vS_91203
      ,vCur_91203         
      FROM GC.SDM_IBS S
          ,GC.ACC A
  WHERE 1=1
    AND S.OBJID = pOBJID
    AND A.OBJID = S.OBJID_91203;    

    
--ibs_type
--1 Простое хранение
--2 Ответственное хранение 
--3 Сделка простое хранение
--4 Сделка ответсвенное хранение


IF pType = 'OPEN'  THEN
vNaz_Plat:='Выдача ключа от ИБС № '||vNUM_IBS||' по Договору № '||vNUM_DOG||' от '||vDATEOPEN||' '||vFIO;
END IF;

IF pType = 'CLOSE' THEN
vNaz_Plat:='Возврат ключа от ИБС № '||vNUM_IBS||' по Договору № '||vNUM_DOG||' от '||vDATEOPEN||' '||vFIO;
END IF;

IF pType = 'OPEN' AND vType_Ibs in ('2','4') THEN
vNaz_Plat_Dop:='Приняты ценности на ответственное хранение ИБС № '||vNUM_IBS||' по Договору № '||vNUM_DOG||' от '||vDATEOPEN||' в размере '||vSUMMA_OTV||' '||vFIO;
END IF;

IF pType = 'CLOSE' AND vType_Ibs in ('2','4') THEN
vNaz_Plat_Dop:='Возврат ценностей с ответственного хранения ИБС № '||vNUM_IBS||' по Договору № '||vNUM_DOG||' от '||vDATEOPEN||' в размере '||vSUMMA_OTV||' '||vFIO_LINK;
END IF;

If vFILIAL = 'M' then
vS_99999:='000000068099';
BEGIN
SELECT A.S
  INTO vS_91202_FIX 
   FROM GC.NNS_LIST N
       ,GC.ACC A
WHERE 1=1
  AND N.NNS = '91202810300000702000'
  AND N.ENDDAT > SYSDATE
  AND A.S = N.S;
    EXCEPTION WHEN NO_DATA_FOUND THEN    
       APP_ERR.PUT('0',0,'НЕ НАЙДЕН СЧЕТ ЦЕННОСТЕЙ (91202810300000702000)');
END;         
END IF;

--Если идет закрытие через меню Опериции-Закрытие ячейки, то пачку делаем новую
--Елси закрытие идет через списание просрочки, то там уже известен номер пачки. Поэтому передаем номер пачки в процедуру
IF pUNP is null THEN
pSTATUS:='15'; --Принудительное закрытие. Отправим сразу на проводку
ELSE
pSTATUS:='13';--Закрытие через просрочку. Отправим в бухгалтерию
END IF;

IF pUNP is null THEN
SELECT gc.SEQ_DOC.NEXTVAL
INTO vUNP 
FROM DUAL;
ELSE 
vUNP := pUNP;
END IF;



IF pTYPE = 'OPEN' then
    ins_doc_advanced(vUnoDt
                    ,vUnoKt
                    ,vUnp
                    ,vS_91202
                    ,vS_99999
                    ,'810'
                    ,'810'
                    ,v_KO => '9000'
                    ,V_SUMM_KT => '1'
                    ,V_TEX => vNaz_Plat
                    ,V_SUBJ => vSUBJ_ID
                    ,V_SUBJ_KT => vSUBJ_ID
                    ,V_TEX_KT => vNaz_Plat
                    ,V_STATUS => pSTATUS
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => sysdate
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    );  

IF vType_Ibs in ('1','3') THEN                  
    ins_doc_advanced(vUnoDt_Dop
                    ,vUnoKt_Dop
                    ,vUnp
                    ,vS_99999
                    ,vS_91203
                    ,'810'
                    ,'810'
                    ,v_KO => '9000'
                    ,V_SUMM_KT => '1'
                    ,V_TEX => nvl(vNaz_Plat_Dop,vNaz_Plat)
                    ,V_SUBJ => vSUBJ_ID
                    ,V_SUBJ_KT => vSUBJ_ID
                    ,V_TEX_KT => nvl(vNaz_Plat_Dop,vNaz_Plat)
                    ,V_STATUS => pSTATUS
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => sysdate
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    );  
                    
ELSE 

    ins_doc_advanced(vUnoDt_Dop
                    ,vUnoKt_Dop
                    ,vUnp
                    ,vS_99999
                    ,vS_91202_FIX
                    ,'810'
                    ,'810'
                    ,v_KO => '9000'
                    ,V_SUMM_KT => '1'
                    ,V_TEX => nvl(vNaz_Plat_Dop,vNaz_Plat)
                    ,V_SUBJ => vSUBJ_ID
                    ,V_SUBJ_KT => vSUBJ_ID
                    ,V_TEX_KT => nvl(vNaz_Plat_Dop,vNaz_Plat)
                    ,V_STATUS => pSTATUS
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => sysdate
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    );  

END IF;                    
                                      
END IF;      

IF pTYPE = 'CLOSE' then

IF vType_Ibs in ('1','3') THEN   
    ins_doc_advanced(vUnoDt
                    ,vUnoKt
                    ,vUnp
                    ,vS_91203
                    ,vS_99999
                    ,'810'
                    ,'810'
                    ,v_KO => '9000'
                    ,V_SUMM_KT => '1'
                    ,V_TEX => vNaz_Plat
                    ,V_SUBJ => vSUBJ_ID
                    ,V_SUBJ_KT => vSUBJ_ID
                    ,V_TEX_KT => vNaz_Plat
                    ,V_STATUS => pSTATUS
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => sysdate
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    );  
ELSE 
    ins_doc_advanced(vUnoDt
                    ,vUnoKt
                    ,vUnp
                    ,vS_91202_FIX
                    ,vS_99999
                    ,'810'
                    ,'810'
                    ,v_KO => '9000'
                    ,V_SUMM_KT => '1'
                    ,V_TEX => vNaz_Plat_Dop
                    ,V_SUBJ => vSUBJ_ID
                    ,V_SUBJ_KT => vSUBJ_ID
                    ,V_TEX_KT => vNaz_Plat_Dop
                    ,V_STATUS => pSTATUS
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => sysdate
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    );  
END IF;                                        
                    
    ins_doc_advanced(vUnoDt_Dop
                    ,vUnoKt_Dop
                    ,vUnp
                    ,vS_99999
                    ,vS_91202
                    ,'810'
                    ,'810'
                    ,v_KO => '9000'
                    ,V_SUMM_KT => '1'
                    ,V_TEX => vNaz_Plat
                    ,V_SUBJ => vSUBJ_ID
                    ,V_SUBJ_KT => vSUBJ_ID
                    ,V_TEX_KT => vNaz_Plat
                    ,V_STATUS => pSTATUS
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => sysdate
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    );                    
END IF;                   

    if vUnp is null then
      doc_p(vUnp,vUnoDt);
/*    else
      insert into gc.sdm$ibs_docum
      select pObjID,vUnp,'Списание просрочки' from dual;*/      
    end if;
    
      return vUnp;
  end;   


 function income_ibs
    (pObjID varchar2
    ,pSUM number
    ,pDateSt date
    ,pDateEnd date
    ,pVltrDt date
    ,pNazPlat varchar2   
    ,pUNP number
    ) return number  
  is
  vS_DT acc.s%type;
  vS_KT acc.s%type;
  vFILIAL acc.filial%type;
  vOTDEL acc.otdel%type;
  vUNP number;
  vUnoDt number;
  vUnoKt number;
  vRes varchar2(255);
  vSubj_id sdm_ibs.subj_id%type;
  begin
  gc.p_support.arm_start();
  
  BEGIN
  SELECT A.S 
        ,A.FILIAL 
        ,A.OTDEL
        ,S.SUBJ_ID
     INTO vS_DT
         ,vFILIAL
         ,vOTDEL
         ,vSubj_ID
     FROM GC.SDM_IBS S
         ,GC.ACC A
  WHERE 1=1
    AND S.OBJID = pOBJID
    AND A.OBJID = S.OBJID_RENT;
  EXCEPTION WHEN NO_DATA_FOUND THEN
          APP_ERR.PUT('0',0,'НЕ НАЙДЕН СЧЕТ АРЕНДЫ');
  END;                  

    --ГО
  IF vFILIAL = 'M' and vOTDEL = 0 THEN
    vS_KT := '000002509134'; --70601810200352830151 
  END IF;  
    
  --Раменское
  IF vFILIAL = 'M' and vOTDEL = '1247202' THEN
    vS_KT := '000002509136'; --70601810300142830151
  END IF;       
    
  --Нижний Новгород
  IF vFILIAL = 'M' and vOTDEL = '3012703215' THEN
    vS_KT := '000002509137'; --70601810307352830151 
  END IF; 
    
  --Екатеринбург
  IF vFILIAL = 'M' and vOTDEL = '2858299385' THEN
    vS_KT := '000002509139'; --70601810110002830151    
  END IF;        
     
  --Красноярск
  IF vFILIAL = 'M' and vOTDEL = '2895452858' THEN
    vS_KT := '000002509142'; --70601810602002830151      
  END IF;     
    
  --Ростов
  IF vFILIAL = 'M' and vOTDEL = '2719862922' THEN
    vS_KT := '000002509144'; --70601810709002830151    
  END IF;    
    
  --Пермь
  IF vFILIAL = 'M' and vOTDEL = '3012696210' THEN
    vS_KT := '000002542254'; --70601810204002830151     
  END IF;           

  --Воронеж
  IF vFILIAL = 'M' and vOTDEL = '3087040484' THEN
    vS_KT := '000002542255'; --70601810903002830151     
  END IF;  
    
    
    IF pUNP is null THEN
    SELECT gc.SEQ_DOC.NEXTVAL
    INTO vUNP 
    FROM DUAL;
    ELSE 
    vUNP := pUNP;
    END IF;  
  
  BEGIN
    ins_doc_advanced(vUnoDt
                    ,vUnoKt
                    ,vUnp
                    ,vS_DT
                    ,vS_KT
                    ,'810'
                    ,'810'
                    ,v_KO => '0429'
                    ,V_SUMM_KT => pSUM
                    ,V_TEX => pNazPlat
                    ,V_SUBJ => vSubj_Id
                    ,V_SUBJ_KT => vSubj_Id
                    ,V_TEX_KT => pNazPlat
                    ,V_STATUS => '15'
                    ,V_OTDEL => vOtdel
                    ,V_VLTR_DT => sysdate
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    );
  EXCEPTION WHEN OTHERS THEN
  vRES:=SQLERRM;
  APP_ERR.PUT('0',0,vRES);
  END;
  
    if vUnp is null then
      doc_p(vUnp,vUnoDt);   
    end if;
    
      return vUnp;
   
  
  end;    
  
  procedure mass_income(pDateStart in date
                       ,pDateEnd in date
                       ,pFilial in varchar2 
                       )
  is  
        vDATESTART DATE;
        vDATEEND DATE;
        vNDS NUMBER;
        vSUMM NUMBER;
        vSUMM_DAY number;
        vCNT_DAY number;
        vCNT_INCOME_IBS number;
        vSUMM_OUT_INCOME number;
        vNAZPLAT varchar2(200);
        vS_KT varchar2(12);
        vERROR int;
        vUNP number;
        vUnoDt number;
        vUnoKt number;
        vEXISTS_PAYMENT int; 
        vUUID varchar2(35);
        vRES varchar2(2000);
BEGIN
GC.P_SUPPORT.ARM_START();
vDATESTART:= pDateStart;
vDATEEND:= pDateEnd;

--Логируем момент запуска
vUUID:=sys_guid();
INSERT INTO GC.IBS$INCOME_EXEC
SELECT vUUID,SYS_CONTEXT('USERENV','SESSION_USER'),SYSDATE,vDATESTART,vDATEEND FROM DUAL;

vNDS := gc.qual$p_main.get('SYSRGT','SYSTEM','NDS');
FOR I IN (

/*SELECT S.OBJID
      ,S.DATE_OPEN
      ,S.DFINAL
      ,T.TARIFF_SUMM*NVL(T.PERIOD_INT,1) SUMM_ALL_PERIOD 
      ,GC.SALDO.SIGNED(A.S,A.CUR) OST_RENT
      ,S.DEAL_SUMM
      ,A.S
      ,A.CUR
      ,A.FILIAL
      ,A.OTDEL
      ,s.NUM_DOG 
      ,s.SUBJ_ID
      ,s.NUM_IBS
      FROM GC.SDM_IBS S
          ,GC.SDM$IBS_TARIFF T
          ,GC.ACC A
WHERE 1=1
  AND S.DATE_OPEN <= vDATEEND      
  AND S.DATE_CLOSE IS NULL
  AND A.OBJID = S.OBJID_RENT
  AND T.ID = S.TARIFF_ID*/
  
  SELECT S.OBJID
      ,S.DATE_OPEN 
      ,T.DATE_ST DSTART_TARIFF
      ,T.DATE_EN DFINAL_TARIFF
      ,CASE WHEN T.DATE_EN > vDATEEND 
                 THEN vDATEEND ELSE T.DATE_EN END-CASE WHEN T.DATE_ST < vDATESTART 
                                                              THEN vDATESTART ELSE T.DATE_ST END+1
      ,S.DFINAL DFINAL_IBS

      ,T.TARIFF_SUMM*NVL(T.PERIOD_INT,1) SUMM_ALL_PERIOD 
      ,GC.SALDO.SIGNED(A.S,A.CUR) OST_RENT
      ,S.DEAL_SUMM
      ,A.S
      ,A.CUR
      ,A.FILIAL
      ,A.OTDEL
      ,s.NUM_DOG 
      ,s.SUBJ_ID
      ,s.NUM_IBS

      FROM GC.SDM_IBS S
          ,GC.SDM$IBS_TARIFF T
          ,GC.ACC A
WHERE 1=1
  AND T.DATE_ST <= vDATEEND     
  AND S.DATE_CLOSE IS NULL
  AND A.OBJID = S.OBJID_RENT
  AND T.OBJID = S.OBJID
  --AND S.NUM_IBS in ('31')


  )
LOOP
vERROR:=0;
vDATESTART:= pDateStart;
vDATEEND:= pDateEnd;
DBMS_OUTPUT.PUT_LINE('ID ЯЧЕЙКИ:'||i.OBJID);
DBMS_OUTPUT.PUT_LINE('Номер ячейки:'||i.NUM_IBS);
DBMS_OUTPUT.PUT_LINE('Дата открытия ячейки:'||to_char(i.DATE_OPEN,'dd.mm.yyyy'));
DBMS_OUTPUT.PUT_LINE('Дата начала тарифа:'||to_char(i.DSTART_TARIFF,'dd.mm.yyyy'));
DBMS_OUTPUT.PUT_LINE('Дата окончания тарифа:'||to_char(i.DFINAL_TARIFF,'dd.mm.yyyy'));
DBMS_OUTPUT.PUT_LINE('Дата окончания ячейки:'||to_char(i.DFINAL_IBS,'dd.mm.yyyy'));
--Посчитаем общую сумму стоимости аренды ячейки за весь период
vSUMM:=round(i.SUMM_ALL_PERIOD-((i.SUMM_ALL_PERIOD*vNDS)/(100+vNDS)),2); 
DBMS_OUTPUT.PUT_LINE('Общая сумма аренды за вычетом НДС:'||vSUMM);
--Посчитаем количество дней с даты начала тарифа по дату окончания
vCNT_DAY:=i.DFINAL_TARIFF-i.DSTART_TARIFF;
--Посчитаем сумму за 1 день
DBMS_OUTPUT.PUT_LINE('Количество дней, когда действует ячейка:'||vCNT_DAY);
vSUMM_DAY:=round(vSUMM/vCNT_DAY,2); 
DBMS_OUTPUT.PUT_LINE('Сумма за 1 день:'||vSUMM_DAY);
IF i.DSTART_TARIFF > vDATESTART THEN
vDATESTART:= i.DATE_OPEN;
END IF;
IF i.DFINAL_TARIFF < vDATEEND THEN
vDATEEND:=i.DFINAL_TARIFF;
END IF;
--Посчитаем количество дней, за которое нужно списать в доход
vCNT_INCOME_IBS:=vDATEEND+1-vDATESTART;
IF vCNT_INCOME_IBS = 0 THEN
vCNT_INCOME_IBS:=1;
END IF;
DBMS_OUTPUT.PUT_LINE('Дата начала периода '||to_char(vDATESTART,'dd.mm.yyyy'));
DBMS_OUTPUT.PUT_LINE('Дата окончания периода '||to_char(vDATEEND,'dd.mm.yyyy'));
DBMS_OUTPUT.PUT_LINE('Списываем за '||vCNT_INCOME_IBS||' дней');
--Сумма для перечисления в доход
vSUMM_OUT_INCOME:=vSUMM_DAY*vCNT_INCOME_IBS;
--Если дата окончания ячейки меньше или равно дате окончания периода, то списываем весь остаток на счете аренды в дохол
IF i.DFINAL_IBS <= vDATEEND THEN
vSUMM_OUT_INCOME:=i.OST_RENT;
END IF;
DBMS_OUTPUT.PUT_LINE('Списываем:'||vSUMM_OUT_INCOME);
DBMS_OUTPUT.PUT_LINE('------------------');

--Занесем ошибки в протокол
IF i.OST_RENT = 0 THEN
vERROR:=1;
INSERT INTO GC.IBS$INCOME_PROTOCOL
SELECT i.OBJID,TRUNC(SYSDATE),'Остаток на счете аренды равен нулю',vUUID FROM DUAL;
END IF;
IF vSUMM_OUT_INCOME > i.OST_RENT THEN
vSUMM_OUT_INCOME:= i.OST_RENT;
--vERROR:=1;
--INSERT INTO GC.IBS$INCOME_PROTOCOL
--SELECT i.OBJID,TRUNC(SYSDATE),'Рассчитанная сумма удержания в доход ('||vSUMM_OUT_INCOME||') больше чем остаток на счете аренды ('||i.OST_RENT||')',vUUID FROM DUAL;
END IF;



vNAZPLAT:='Перечисление в счет доходов за аренду ИБС № '||i.NUM_IBS||' по договору № '||i.NUM_DOG||' за период с '||to_char(vDATESTART,'DD.MM.YYYY')||' по '||to_char(vDATEEND,'DD.MM.YYYY');

    --ГО
  IF i.FILIAL = 'M' and i.OTDEL = 0 THEN
    vS_KT := '000002509134'; --70601810200352830151 
  END IF;  
    
  --Раменское
  IF i.FILIAL = 'M' and i.OTDEL = '1247202' THEN
    vS_KT := '000002509136'; --70601810300142830151
  END IF;       
    
  --Нижний Новгород
  IF i.FILIAL = 'M' and i.OTDEL = '3012703215' THEN
    vS_KT := '000002509137'; --70601810307352830151 
  END IF; 
    
  --Екатеринбург
  IF i.FILIAL = 'M' and i.OTDEL = '2858299385' THEN
    vS_KT := '000002509139'; --70601810110002830151    
  END IF;        
     
  --Красноярск
  IF i.FILIAL = 'M' and i.OTDEL = '2895452858' THEN
    vS_KT := '000002509142'; --70601810602002830151      
  END IF;     
    
  --Ростов
  IF i.FILIAL = 'M' and i.OTDEL = '2719862922' THEN
    vS_KT := '000002509144'; --70601810709002830151    
  END IF;    
    
  --Пермь
  IF i.FILIAL = 'M' and i.OTDEL = '3012696210' THEN
    vS_KT := '000002542254'; --70601810204002830151     
  END IF;           

  --Воронеж
  IF i.FILIAL = 'M' and i.OTDEL = '3087040484' THEN
    vS_KT := '000002542255'; --70601810903002830151     
  END IF;   

IF vS_KT is null THEN
vERROR:=1;
INSERT INTO GC.IBS$INCOME_PROTOCOL
SELECT i.OBJID,TRUNC(SYSDATE),'Не найден счет доходов',vUUID FROM DUAL;
END IF;

--Формируем документ
IF vERROR = 0 AND vSUMM_OUT_INCOME > 0 THEN

SELECT gc.SEQ_DOC.NEXTVAL
INTO vUNP 
FROM DUAL;

begin
    ins_doc_advanced(vUnoDt
                    ,vUnoKt
                    ,vUnp
                    ,i.S
                    ,vS_KT
                    ,i.CUR
                    ,i.CUR
                    ,v_KO => '0429'
                    ,V_SUMM_KT => vSUMM_OUT_INCOME
                    ,V_TEX => vNAZPLAT
                    ,V_SUBJ => i.SUBJ_ID
                    ,V_SUBJ_KT => i.SUBJ_ID
                    ,V_TEX_KT => vNAZPLAT
                    ,V_STATUS => '13'
                    ,V_OTDEL => i.Otdel
                    ,V_VLTR_DT => sysdate
                    ,v_DOC_GROUP=>'IBS'                    
                    ,V_CROSS => true
                    );
EXCEPTION WHEN OTHERS THEN
vRES:=SQLERRM;
INSERT INTO GC.IBS$INCOME_PROTOCOL
SELECT i.OBJID,TRUNC(SYSDATE),'Ошибка по договору: '||vRES,vUUID FROM DUAL;
END;                            
                    
    if vUnp is null then
      doc_p(vUnp,vUnoDt);
    else  
      insert into gc.sdm$ibs_docum
      select i.OBJID,vUnp,'Перечисление в доход' from dual; 
      insert into gc.ibs$income_payment
      select i.objid,vDATESTART,vDATEEND,vSUMM_OUT_INCOME,vUNP from dual;     
    end if;                     

END IF;

END LOOP;
COMMIT;
END;        

  procedure prolong_rent(pOBJID in varchar2
                       ,pPERIOD_TYPE in varchar2
                       ,pPERIOD_INT in int 
                       )
  is  
  vTARIFF_ID number;
  vSUMM_RENT_OLD number;
  vSUMM_RENT_NEW number;
  vDFINAL_OLD date;
  vDATESTART_NEW date;
  vDATEEND_NEW date;
  vSIZE_IBS_ID varchar2(15);
  vFUTURE_TARIFF_CNT int;
  
  begin

SELECT DFINAL
      ,SIZE_IBS_ID
 INTO vDFINAL_OLD 
     ,vSIZE_IBS_ID 
    FROM GC.SDM_IBS
WHERE 1=1
  AND OBJID = pOBJID; 
  
vDATESTART_NEW:=vDFINAL_OLD+1;

 IF pPERIOD_TYPE = 'MONTH' then 
    vDATEEND_NEW := Add_Months(vDATESTART_NEW,pPERIOD_INT)-1;
 END IF;
 IF pPERIOD_TYPE = 'WEEK' AND pPERIOD_INT = 1 then 
    vDATEEND_NEW := vDATESTART_NEW+7;
 END IF;  
 IF pPERIOD_TYPE = 'WEEK' AND pPERIOD_INT = 2 then 
    vDATEEND_NEW := vDATESTART_NEW+14;
 END IF;    
 
--Проверим, может уже ячейка была пролонгирована и новый срок тарифа еще не наступил. 
BEGIN
SELECT COUNT(*)
INTO vFUTURE_TARIFF_CNT
     FROM GC.SDM$IBS_TARIFF S
WHERE 1=1
  AND S.OBJID = pOBJID
  AND TRUNC(SYSDATE) BETWEEN S.DATE_ST AND S.DATE_EN
  AND EXISTS (SELECT 1 FROM GC.SDM$IBS_TARIFF SS
                   WHERE 1=1
                     AND SS.OBJID = S.OBJID
                     AND SS.DATE_ST > S.DATE_EN
                     );
EXCEPTION WHEN NO_DATA_FOUND THEN
vFUTURE_TARIFF_CNT:=0;
END;                     
                     

IF vFUTURE_TARIFF_CNT > 0 THEN  
       APP_ERR.PUT('0',0,'У ЯЧЕЙКИ УЖЕ ЕСТЬ ПРОЛОНГАЦИЯ В БУДУЩЕМ, КОТОРАЯ ЕЩЕ НЕ НАСТУПИЛА. ПОДРОБНО СМОТРИТЕ В ТАРИФАХ ЯЧЕЙКИ');
END IF;                               
                         
    
Begin  
select summ
into vSUMM_RENT_NEW
from (    select case when d1.value >= 0 and d1.value < 1 then (select oaa.value2 from gc.sprav$values oaa where oaa.id_type = '2409475529' and oaa.value1 = d.value)
                      when d1.value between 1 and 2 then (select oaa.value3 from gc.sprav$values oaa where oaa.id_type = '2409475529' and oaa.value1 = d.value) 
                      when d1.value between 3 and 5 then (select oaa1.value4 from gc.sprav$values oaa1 where oaa1.id_type = '2409475529' and oaa1.value1 = d.value) 
                      when d1.value between 6 and 11 then (select oaa2.value5 from gc.sprav$values oaa2 where oaa2.id_type = '2409475529' and oaa2.value1 = d.value) 
                      when d1.value >=12 then (select oaa3.value6 from gc.sprav$values oaa3 where oaa3.id_type = '2409475529' and oaa3.value1 = d.value) 
                      
                

       
 else '0' end||'.00' as summ from
(select substr(oa1.value1,instr(oa1.value1,' ',-1)+1) as value1,oa1.value1 as value from gc.sprav$values oa1 where  oa1.Id = vSIZE_IBS_ID) d,
(select round(MONTHS_BETWEEN(vDATEEND_NEW,nvl(vDATESTART_NEW,trunc(sysdate)))) as value from dual) d1);
    EXCEPTION WHEN NO_DATA_FOUND THEN 
    vSUMM_RENT_NEW:='0';
End;  

vTARIFF_ID:=GC.SDM$IBS_TARIFF_SEQ.NEXTVAL;
INSERT INTO GC.SDM$IBS_TARIFF
      (ID
      ,OBJID
      ,DATE_ST
      ,DATE_EN
      ,PERIOD_TYPE
      ,PERIOD_INT
      ,TARIFF_SUMM
      )
      VALUES
( vTARIFF_ID
      ,pOBJID
      ,vDATESTART_NEW
      ,vDATEEND_NEW
      ,pPERIOD_TYPE
      ,pPERIOD_INT
      ,vSUMM_RENT_NEW); 


UPDATE GC.SDM_IBS
SET DFINAL = vDATEEND_NEW
WHERE OBJID = pOBJID; 
gc.p_support.arm_start();
GC.JOUR_PACK.ADD_TO_JOURNAL('SDMIBS',pObjID,'SDMIBS_PROL','P','','Пролонгация ячейки: период '||pPERIOD_TYPE||' , количество интервалов '||pPERIOD_INT||'. Дата начала действия тарифа:'||to_char(vDATESTART_NEW,'dd.mm.yyyy')); 
  end;
end sdm$ibs;
/

-- Grants for Package Body
GRANT EXECUTE ON sdm$ibs TO bookkeeper
/


-- End of DDL Script for Package Body GC.SDM$IBS
