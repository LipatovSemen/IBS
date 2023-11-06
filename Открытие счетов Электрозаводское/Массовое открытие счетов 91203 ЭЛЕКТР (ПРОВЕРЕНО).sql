--Открываем в плане счетов PS=900 счет 91203



declare
vKey number;                --ключ
pFilialId varchar2(15) := 'M'; --------------------------------------------------------------------------------------филиал НОМЕР
t_mask varchar2(25);        --Новый ННС
V_ACCNUM varchar2(12);      --12-значный номер нового счета
bs_sys varchar2(10) ;       --системный номер нового балансового
id_owner varchar2(10) :='382' ; --ИД владельца счета
type_acc varchar2(1);       --признак счета
date_open date :=sysdate;   --Дата открытия счета
name_acc varchar2(256);     --Наименование счета
s_ObjID varchar2(12);
s_ObjID_ACC varchar2(12);
ident rowid;
v_objid varchar2(12);
v91203 varchar2(5);
begin
--user_login.arm_start('CONVERT','03.20.005',pFilialId);
--set_filial(pFilialId);
p_Support.arm_start();

select p.bs
into v91203
           from gc.plan p
where 1=1
and bbaln = '91203' 
and p.ps = '900' 
and upper(p.name) like '%ДЕПОЗИТАР%';


for r in ( 

select  
    nns as newnns
    ,'ЭЛЕКТРОЗАВОДСКОЕ. Внебалансовый счет учета ключей по депозитарию ячейки № '||num_ibs as name_acc
    ,v91203 as bs_sys   
from sdm$ibs_nns
where 1=1
and substr(nns,1,5) = '91203'
and filial = '382'
and otdel = '1373255'
) 
loop     
select type into type_acc from plan where bs=v91203;
DBMS_OUTPUT.put_line(r.newnns||' '||r.bs_sys||' '||type_acc||' '||r.name_acc);

t_mask := r.newnns;
vKey := nns.Get_Key(r.newnns, pFilialId); --рассчитаем ключ
t_mask := nns.Set_Field(t_mask, vKey, 9, 1); --вставим ключ в ННС
--- 706 GC.INS_ACC(V_ACCNUM,r.bs_sys,'810',id_owner,null,type_acc,null,date_open,r.name_acc,V_AUTOCLEAR=>'Y',NO_NNS=>true,V_OTDEL=>pFilialId);   --- заведение счета ACC
GC.INS_ACC(V_ACCNUM,v91203,'810',id_owner,null,type_acc,null,date_open,r.name_acc,V_AUTOCLEAR=>'N',NO_NNS=>false,v_otdel=>'1373255',pfilial=>pFilialId); --открытие счетов 91203
--GC.INS_DOG_USL(V_ACCNUM,'810','382','1',null,'00170','U',V_OTDEL=>'0',V_DOPEN=>sysdate,NO_NNS=>true);
--select s into S_ObjID from acc where objid=V_ACCNUM;
--select objid into S_ObjID_ACC from acc where dog_id=V_ACCNUM;
gc.nns.SetNewNNS(V_ACCNUM,'810',t_mask,date_open,null) ;   ---- заведение нового NNS
--select rowid into ident from gc.acc where s = s_objid;
--GC.UPD_ACC(ident,V_AUTOCLEAR=>NULL,V_STATUS=>0,V_NAME=>r.name_acc);  --меняем наименование счета
--AAAXUjAATAANfrBAAM  
--- устанавливаем EXT_CONS_ACC
--select ObjID into v_ObjID from acc where s=V_ACCNUM;
select a.objid into v_ObjID from gc.sdm$ibs_nns s,gc.nns_list n,gc.acc a where s.nns = n.nns and substr(s.nns,1,5) = '91203' and a.s = n.s and n.nns = t_mask;
if not gc.radd_q(objtype_ =>'ACC'
                    ,objid_ =>v_objid
                    ,name_ =>'EXT_CONS_ACC'
                    ,num_ => 0
                    ,txt_ =>'Добавлен при вводе функционала ИБС'
                    ,value_ =>t_mask
                    ,date_b_ => sysdate
                    ,date_e_ => null
                    ,filial =>pFilialId)
    then 
        gc.app_err.put ('BOOKKEEP', 292);
    end if;   
--Добавление внешних реквизитов
GC.SET_REKV(V_ACCNUM
           ,'810'
           ,'044525685'
           ,'30101810845250000685'
           ,'00000810100000000001'
           ,'"СДМ-БАНК" (ПАО)'
           ,'"СДМ-БАНК" (ПАО)'
           ,'МОСКВА'
           ,V_UNB=>NULL
           ,V_SELF_MFO=>NULL
           ,V_NEW_MFO=>NULL
           ,V_TEXT=>NULL
           ,V_IDN=>'7733043350'
           ,V_OCHEREDN=>NULL
           ,V_BANK_ID=>id_owner
           ,V_COPYDIR=>0
           ,V_ORG_ID=>id_owner
           ,V_KPP=>'773301001');


--DBMS_OUTPUT.put_line('s-'||v_ACCNUM||' etx_cons_acc-'||t_mask);

end loop;
gc.user_login.arm_end;

end;
-----------------------------------------------------------
