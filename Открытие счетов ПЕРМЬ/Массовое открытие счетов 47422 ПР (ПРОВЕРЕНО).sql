--Открываем в плане счетов PS=011 счет 47422

declare
vKey number;                --ключ
pFilialId varchar2(15) := '1788104'; --------------------------------------------------------------------------------------филиал НОМЕР
t_mask varchar2(25);        --Новый ННС
V_ACCNUM varchar2(12);      --12-значный номер нового счета
bs_sys varchar2(10) ;       --системный номер нового балансового
id_owner varchar2(10) :='1788104' ; --ИД владельца счета
type_acc varchar2(1);       --признак счета
date_open date :=sysdate;   --Дата открытия счета
name_acc varchar2(256);     --Наименование счета
s_ObjID varchar2(12);
s_ObjID_ACC varchar2(12);
ident rowid;
ident1 rowid;
SPRAV_ID rowid;
v47422 varchar2(5);
begin
--user_login.arm_start('CONVERT','03.20.005',pFilialId);
set_filial(pFilialId);
p_Support.arm_start();

select p.bs
into v47422 
            from gc.plan p
where 1=1
and bbaln = '47422' 
and p.ps = '011' 
and upper(p.name) like '%ЯЧЕЙК%';

for r in ( 

select  
    nns as newnns
    ,'ПР. Счет аренды банковской ячейки № '||num_ibs as name_acc
    ,v47422 as bs_sys   
from sdm$ibs_nns
where 1=1
and substr(nns,1,5) = '47422'
and filial = '1788104'
and otdel = '0'
) 
loop     
select type into type_acc from plan where bs=v47422;
DBMS_OUTPUT.put_line(r.newnns||' '||r.bs_sys||' '||type_acc||' '||r.name_acc);

t_mask := r.newnns;
vKey := nns.Get_Key(r.newnns, pFilialId); --рассчитаем ключ
t_mask := nns.Set_Field(t_mask, vKey, 9, 1); --вставим ключ в ННС

--Заводим договор поставщика услуг
GC.INS_DOG_USL(V_ACCNUM,'810','1788104','1',null,v47422,'U',V_OTDEL=>'0',V_DOPEN=>sysdate,NO_NNS=>true);

select s into S_ObjID from acc where dog_id=V_ACCNUM;
select objid into S_ObjID_ACC from acc where dog_id=V_ACCNUM;
gc.nns.SetNewNNS(S_ObjID,'810',t_mask,date_open,null) ;   ---- заведение нового NNS
select rowid into ident from gc.acc where s = s_objid;
GC.UPD_ACC(ident,V_AUTOCLEAR=>NULL,V_STATUS=>0,V_NAME=>r.name_acc);  --меняем наименование счета


--Проставим ВИД ПЛАТЕЖА для договора поставщика услуг. 
select rowid into ident1 from gc.dog where objid = V_ACCNUM;
select ID into SPRAV_ID from gc.sprav where type = chr(37) and name = 'ИБС СПИСАНИЕ АРЕНДЫ';
GC.UPD_DOG(ident1,'1',NULL,V_STATUS=>0,V_SPRAV_ID=>SPRAV_ID);
--Проставим ВИД ПЛАТЕЖА для договора поставщика услуг. 


--- устанавливаем EXT_CONS_ACC
--select ObjID into v_ObjID from acc where s=V_ACCNUM;
if not gc.radd_q(objtype_ =>'ACC'
                    ,objid_ =>s_ObjID_ACC
                    ,name_ =>'EXT_CONS_ACC'
                    ,num_ => 0
                    ,txt_ =>'Добавлен при вводе функционала по ИБС'
                    ,value_ =>'47422810504007700000'
                    ,date_b_ => sysdate
                    ,date_e_ => null
                    ,filial =>pFilialId)
    then 
        gc.app_err.put ('BOOKKEEP', 292);
    end if;   
--Добавление внешних реквизитов
GC.SET_REKV(s_Objid
           ,'810'
           ,'045773843'
           ,'30101810357730000843'
           ,'00000810100000000001'
           ,'ФИЛИАЛ "СДМ-БАНК" (ПАО) В Г.ПЕРМИ'
           ,'ФИЛИАЛ "СДМ-БАНК" (ПАО) В Г.ПЕРМИ'
           ,'ПЕРМЬ'
           ,V_UNB=>NULL
           ,V_SELF_MFO=>NULL
           ,V_NEW_MFO=>NULL
           ,V_TEXT=>NULL
           ,V_IDN=>'7733043350'
           ,V_OCHEREDN=>NULL
           ,V_BANK_ID=>id_owner
           ,V_COPYDIR=>0
           ,V_ORG_ID=>id_owner
           ,V_KPP=>'590202001');

--DBMS_OUTPUT.put_line('s-'||v_ACCNUM||' etx_cons_acc-'||t_mask);

end loop;
gc.user_login.arm_end;

end;
-----------------------------------------------------------
