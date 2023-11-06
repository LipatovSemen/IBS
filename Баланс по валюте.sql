declare 
T_BS varchar2(5); 
T_ACC1 varchar2(15); 
T_ACC2 varchar2(15); 
FIL_BRIEF varchar2(10);
vBS varchar2(5);
pFilialId varchar2(15) := 'M'; --------------------------------------------------------------------------------------филиал НОМЕР  M 1228080 по очереди каждый филиал обрабатываем
v42309 varchar2(5);
v47422 varchar2(5);
v91202 varchar2(5);
v91203 varchar2(5);
vOBJID varchar2(10);
vEXT_CONS_ACC varchar2(20);

begin 
FIL_BRIEF := '???';
---p_Support.arm_start();
user_login.arm_end;
gc.USER_LOGIN.ARM_START('BOOKKEEPER', gc.def_ust.C_VER);
---user_login.arm_start('CONVERT','03.20.005',pFilialId);
set_filial(pFilialId);
IF pFilialID = 'M'  
then FIL_BRIEF := 'ГО. '; 
End if;
IF pFilialID = '185746585' then 
FIL_BRIEF := 'ЕК. ';
End if;
--dbms_output.put_line(fil_brief);
IF pFilialID = '5004115' then 
FIL_BRIEF := 'РО. ';
End if;
IF pFilialID = '1368349' then 
FIL_BRIEF := 'ТВ. ';
End if;
IF pFilialID = '1787601' then 
FIL_BRIEF := 'ВР. ';
End if;
IF pFilialID = '1788509' then 
FIL_BRIEF := 'КРС. ';
End if;
IF pFilialID = '2188666' then 
FIL_BRIEF := 'НН. ';
End if;
IF pFilialID = '1788104' then 
FIL_BRIEF := 'ПР. ';
End if;
IF pFilialID = '1228080' then 
FIL_BRIEF := 'СПБ. ';
End if;

select p.bs 
into v42309 
            from gc.plan p        
where 1=1
and bbaln = '42309' 
and p.ps = '011' 
and upper(p.name) like '%ЯЧЕЙК%';

select p.bs
into v47422 
            from gc.plan p
where 1=1
and bbaln = '47422' 
and p.ps = '011' 
and upper(p.name) like '%ЯЧЕЙК%';

select p.bs
into v91202 
            from gc.plan p
where 1=1
and bbaln = '91202' 
and p.ps = '900' 
and upper(p.name) like '%ДЕПОЗИТАР%';

select p.bs
into v91203
           from gc.plan p
where 1=1
and bbaln = '91203' 
and p.ps = '900' 
and upper(p.name) like '%ДЕПОЗИТАР%';

GC.INS_BAL(T_BS,T_ACC1,T_ACC2,v42309,'810',FIL_BRIEF||rtrim('Банковская ячейка                             '),NULL,NULL,sysdate,V_DELAYSAL=>'N',V_SINGLE_DOC2ABS =>'N',V_ACC2ABS =>'N',V_F410NVS =>'N',V_TURN_CALC_LITE=>'N',V_F345DDU =>'N',V_F345DKP =>'N',V_DELAYSAL_CONS=>'N'); 
GC.INS_BAL(T_BS,T_ACC1,T_ACC2,v47422,'810',FIL_BRIEF||rtrim('Банковская ячейка. Аренда                     '),NULL,NULL,sysdate,V_DELAYSAL=>'N',V_SINGLE_DOC2ABS =>'N',V_ACC2ABS =>'N',V_F410NVS =>'N',V_TURN_CALC_LITE=>'N',V_F345DDU =>'N',V_F345DKP =>'N',V_DELAYSAL_CONS=>'N'); 
GC.INS_BAL(T_BS,T_ACC1,T_ACC2,v91202,'810',FIL_BRIEF||rtrim('Внебалансовый счет учета ключей по депозитарию'),NULL,NULL,sysdate,V_DELAYSAL=>'N',V_SINGLE_DOC2ABS =>'N',V_ACC2ABS =>'N',V_F410NVS =>'N'); 
GC.INS_BAL(T_BS,T_ACC1,T_ACC2,v91203,'810',FIL_BRIEF||rtrim('Внебалансовый счет учета ключей по депозитарию'),NULL,NULL,sysdate,V_DELAYSAL=>'N',V_SINGLE_DOC2ABS =>'N',V_ACC2ABS =>'N',V_F410NVS =>'N'); 

vOBJID := '0';

select b.objid
into vOBJID
         from gc.plan p
             ,gc.bal b 
where 1=1
and bbaln = '47422' 
and p.ps = '011' 
and upper(p.name) like '%ЯЧЕЙК%'
and p.bs = b.bs
and b.filial = pFilialId
and trunc(b.dopen) = trunc(sysdate);

SELECT DECODE(pFilialid,'M','47422810700000011044'
                       ,'185746585','47422810510000011044'
                       ,'5004115','47422810509000011044'
                       ,'1368349','0'
                       ,'1787601','0'
                       ,'1788509','47422810502000000111'
                       ,'2188666','47422810707000011044'
                       ,'1788104','47422810504007700000'
                       ,'1228080','47422810405000000044'
                       ,'0')
into vEXT_CONS_ACC from dual;

if vOBJID <> '0' then
if not gc.radd_q(objtype_ =>'BAL'
                    ,objid_ =>vOBJID
                    ,name_ =>'EXT_CONS_ACC'
                    ,num_ => 0
                    ,txt_ =>'Добавлен при вводе функционала по ИБС'
                    ,value_ =>vEXT_CONS_ACC
                    ,date_b_ => sysdate
                    ,date_e_ => null
                    ,filial =>pFilialId)
    then 
        gc.app_err.put ('BOOKKEEP', 292);
    end if;   
end if;


end;
--commit;
--+ФИЛИАЛ "СДМ-БАНК" (ПАО) В Г. ЕКАТЕРИНБУРГЕ  185746585
--+ФИЛИАЛ "СДМ-БАНК" (ПАО) В Г. РОСТОВ-НА-ДОНУ 5004115
--+ФИЛИАЛ "СДМ-БАНК" (ПАО) В Г. ТВЕРИ  1368349
--+ФИЛИАЛ "СДМ-БАНК" (ПАО) В Г.ВОРОНЕЖЕ    1787601
--+ФИЛИАЛ "СДМ-БАНК" (ПАО) В Г.КРАСНОЯРСКЕ 1788509
--+ФИЛИАЛ "СДМ-БАНК" (ПАО) В Г.НИЖНИЙ НОВГОРОД 2188666
--+ФИЛИАЛ "СДМ-БАНК" (ПАО) В Г.ПЕРМИ   1788104
--+ФИЛИАЛ "СДМ-БАНК"(ПАО)  В Г.САНКТ-ПЕТЕРБУРГЕ 1228080

