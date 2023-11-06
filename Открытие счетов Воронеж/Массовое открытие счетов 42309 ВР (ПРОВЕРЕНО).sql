--Открываем в плане счетов PS=011 счет 42309


declare
vKey number;                --ключ
pFilialId varchar2(15) := '1787601'; --------------------------------------------------------------------------------------филиал НОМЕР
t_mask varchar2(25);        --Новый ННС
V_ACCNUM varchar2(12);      --12-значный номер нового счета
bs_sys varchar2(10) ;       --системный номер нового балансового
id_owner varchar2(10) := '1787601'; --ИД владельца счета
type_acc varchar2(1);       --признак счета
date_open date :=sysdate;   --Дата открытия счета
name_acc varchar2(256);     --Наименование счета
s_ObjID varchar2(12);
v_ObjID varchar2(12);
ident rowid;
ident1 rowid;
SPRAV_ID varchar2(12);
v42309 varchar2(5);
begin
--user_login.arm_start('CONVERT','03.20.005',pFilialId);
set_filial(pFilialId);
p_Support.arm_start();

select p.bs 
into v42309 
            from gc.plan p        
where 1=1
and bbaln = '42309' 
and p.ps = '011' 
and upper(p.name) like '%ЯЧЕЙК%';

for r in ( 

select  
    nns as newnns
    ,'ВР. Счет залога банковской ячейки № '||num_ibs as name_acc
    ,v42309 as bs_sys   
from sdm$ibs_nns
where 1=1
and substr(nns,1,5) = '42309'
and filial = '1787601'
and otdel = '0'
) 
loop     
select type into type_acc from plan where bs=v42309;
DBMS_OUTPUT.put_line(r.newnns||' '||r.bs_sys||' '||type_acc||' '||r.name_acc);

t_mask := r.newnns;
vKey := nns.Get_Key(r.newnns, pFilialId); --рассчитаем ключ
t_mask := nns.Set_Field(t_mask, vKey, 9, 1); --вставим ключ в ННС
--- 706 GC.INS_ACC(V_ACCNUM,r.bs_sys,'810',id_owner,null,type_acc,null,date_open,r.name_acc,V_AUTOCLEAR=>'Y',NO_NNS=>true,V_OTDEL=>pFilialId);   --- заведение счета ACC
---GC.INS_ACC(V_ACCNUM,'00168','810',id_owner,null,type_acc,null,date_open,r.name_acc,V_AUTOCLEAR=>'N',NO_NNS=>false,pfilial=>pFilialId); --открытие счетов 42309
GC.INS_DOG_USL(V_ACCNUM,'810','1787601','1',null,v42309,'U',V_OTDEL=>'0',V_DOPEN=>sysdate,NO_NNS=>true);
select s into S_ObjID from acc where dog_id=V_ACCNUM;
gc.nns.SetNewNNS(S_ObjID,'810',t_mask,date_open,null) ;   ---- заведение нового NNS
select rowid into ident from gc.acc where s = s_objid;
GC.UPD_ACC(ident,V_AUTOCLEAR=>NULL,V_STATUS=>0,V_NAME=>r.name_acc); 

--Проставим ВИД ПЛАТЕЖА для договора поставщика услуг. 
select rowid into ident1 from gc.dog where s = s_objid;
select ID into SPRAV_ID from gc.sprav where type = chr(37) and name = 'ИБС СПИСАНИЕ ЗАЛОГА ЗА КЛЮЧ';
GC.UPD_DOG(ident1,'1',NULL,V_STATUS=>0,V_SPRAV_ID=>SPRAV_ID);
--Проставим ВИД ПЛАТЕЖА для договора поставщика услуг. 

--- устанавливаем EXT_CONS_ACC
select ObjID into v_ObjID from acc where s=s_OBJID;
if not gc.radd_q(objtype_ =>'ACC'
                    ,objid_ =>v_ObjID
                    ,name_ =>'EXT_CONS_ACC'
                    ,num_ => 0
                    ,txt_ =>'Добавлен при введении функционала по ИБС'
                    ,value_ =>t_mask
                    ,date_b_ => sysdate
                    ,date_e_ => null
                    ,filial =>pFilialId)
    then 
        gc.app_err.put ('BOOKKEEP', 292);
    end if;   

--Добавление внешних реквизитов
GC.SET_REKV(s_Objid
           ,'810'
           ,'042007778'
           ,'30101810500000000778'
           ,'00000810100000000001'
           ,'ФИЛИАЛ "СДМ-БАНК" (ПАО) В Г.ВОРОНЕЖЕ'
           ,'ФИЛИАЛ "СДМ-БАНК" (ПАО) В Г.ВОРОНЕЖЕ'
           ,'ВОРОНЕЖ'
           ,V_UNB=>NULL
           ,V_SELF_MFO=>NULL
           ,V_NEW_MFO=>NULL
           ,V_TEXT=>NULL
           ,V_IDN=>'7733043350'
           ,V_OCHEREDN=>NULL
           ,V_BANK_ID=>id_owner
           ,V_COPYDIR=>0
           ,V_ORG_ID=>id_owner
           ,V_KPP=>'366402002');


--DBMS_OUTPUT.put_line('s-'||v_ACCNUM||' etx_cons_acc-'||t_mask);

end loop;
gc.user_login.arm_end;

end;
-----------------------------------------------------------
