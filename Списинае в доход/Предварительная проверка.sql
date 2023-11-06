declare
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
vDATESTART:= to_date('01/10/2023','dd/mm/yyyy');
vDATEEND:= to_date('31/10/2023','dd/mm/yyyy');

--Логируем момент запуска
vUUID:=sys_guid();
--INSERT INTO GC.IBS$INCOME_EXEC
--SELECT vUUID,SYS_CONTEXT('USERENV','SESSION_USER'),SYSDATE,vDATESTART,vDATEEND FROM DUAL;

vNDS := gc.qual$p_main.get('SYSRGT','SYSTEM','NDS');
FOR I IN (
SELECT S.OBJID
      ,S.DATE_OPEN 
      ,T.DATE_ST DSTART_TARIFF
      ,T.DATE_EN DFINAL_TARIFF
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
  AND S.DATE_CLOSE IS NULL
  AND A.OBJID = S.OBJID_RENT
  AND T.OBJID = S.OBJID
 -- AND S.NUM_IBS in ('912','1072')
  AND T.DATE_ST <= vDATEEND
  --and s.num_ibs = '691'
  and t.date_en >= vDATESTART
  and t.id <> '15648' --Временно, некорректный тариф. В след месяце норм будет
  )
LOOP
vERROR:=0;
vDATESTART:= to_date('01/10/2023','dd/mm/yyyy');
vDATEEND:= to_date('31/10/2023','dd/mm/yyyy');
DBMS_OUTPUT.PUT_LINE('ID ЯЧЕЙКИ:'||i.OBJID);
DBMS_OUTPUT.PUT_LINE('Номер ячейки:'||i.NUM_IBS);
DBMS_OUTPUT.PUT_LINE('Дата открытия ячейки:'||to_char(i.DATE_OPEN,'dd.mm.yyyy'));
DBMS_OUTPUT.PUT_LINE('Дата начала тарифа:'||to_char(i.DSTART_TARIFF,'dd.mm.yyyy'));
DBMS_OUTPUT.PUT_LINE('Дата окончания тарифа:'||to_char(i.DFINAL_TARIFF,'dd.mm.yyyy'));
DBMS_OUTPUT.PUT_LINE('Дата окончания ячейки:'||to_char(i.DFINAL_IBS,'dd.mm.yyyy'));
--Посчитаем общую сумму стоимости аренды ячейки за весь период
vSUMM:=round(i.SUMM_ALL_PERIOD-((i.SUMM_ALL_PERIOD*vNDS)/(100+vNDS)),2); 
DBMS_OUTPUT.PUT_LINE('Общая сумма аренды за вычетом НДС:'||vSUMM);
--Посчитаем количество дней с даты начала ячейки по дату окончания
vCNT_DAY:=i.DFINAL_TARIFF-i.DSTART_TARIFF;
--Посчитаем сумму за 1 день
DBMS_OUTPUT.PUT_LINE('Количество дней, когда действует ячейка:'||vCNT_DAY);
vSUMM_DAY:=round(vSUMM/vCNT_DAY,2); 
DBMS_OUTPUT.PUT_LINE('Сумма за 1 день:'||vSUMM_DAY);
IF i.DSTART_TARIFF > vDATESTART THEN
vDATESTART:= i.DSTART_TARIFF;
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


--Занесем ошибки в протокол
IF i.OST_RENT = 0 THEN
vERROR:=1;
DBMS_OUTPUT.PUT_LINE('Остаток на счете аренды равен нулю');
INSERT INTO GC.TEMP_IBS_01112023
SELECT I.OBJID,I.NUM_IBS,I.DATE_OPEN,I.DFINAL_IBS,I.DSTART_TARIFF,I.DFINAL_TARIFF,vSUMM,vCNT_DAY,vSUMM_DAY,vDATESTART,vDATEEND,vCNT_INCOME_IBS,vSUMM_OUT_INCOME,i.OST_RENT,'Остаток на счете аренды равен нулю' FROM DUAL;
--INSERT INTO GC.IBS$INCOME_PROTOCOL
--SELECT i.OBJID,TRUNC(SYSDATE),'Остаток на счете аренды равен нулю',vUUID FROM DUAL;
END IF;
IF vSUMM_OUT_INCOME > i.OST_RENT THEN
vSUMM_OUT_INCOME:= i.OST_RENT;
END IF;

DBMS_OUTPUT.PUT_LINE('------------------');

IF vERROR=0 THEN
INSERT INTO GC.TEMP_IBS_01112023
SELECT I.OBJID,I.NUM_IBS,I.DATE_OPEN,I.DFINAL_IBS,I.DSTART_TARIFF,I.DFINAL_TARIFF,vSUMM,vCNT_DAY,vSUMM_DAY,vDATESTART,vDATEEND,vCNT_INCOME_IBS,vSUMM_OUT_INCOME,i.OST_RENT,NULL FROM DUAL;
END IF;
END LOOP;
END;
