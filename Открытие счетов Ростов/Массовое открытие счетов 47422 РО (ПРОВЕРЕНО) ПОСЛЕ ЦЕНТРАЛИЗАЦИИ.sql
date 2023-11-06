--��������� � ����� ������ PS=011 ���� 47422



declare
vKey number;                --����
pFilialId varchar2(15) := 'M'; --------------------------------------------------------------------------------------������ �����
t_mask varchar2(25);        --����� ���
V_ACCNUM varchar2(12);      --12-������� ����� ������ �����
bs_sys varchar2(10) ;       --��������� ����� ������ �����������
id_owner varchar2(10) :='382' ; --�� ��������� �����
type_acc varchar2(1);       --������� �����
date_open date :=sysdate;   --���� �������� �����
name_acc varchar2(256);     --������������ �����
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
and upper(p.name) like '%�����%';

for r in ( 

select  
    nns as newnns
    ,'�� ������. ���� ������ ���������� ������ � '||num_ibs as name_acc
    ,v47422 as bs_sys   
from sdm$ibs_nns
where 1=1
and substr(nns,1,5) = '47422'
and filial = '382'
and otdel = '2719862922'
) 
loop     
select type into type_acc from plan where bs=v47422;
DBMS_OUTPUT.put_line(r.newnns||' '||r.bs_sys||' '||type_acc||' '||r.name_acc);

t_mask := r.newnns;
vKey := nns.Get_Key(r.newnns, pFilialId); --���������� ����
t_mask := nns.Set_Field(t_mask, vKey, 9, 1); --������� ���� � ���

--������� ������� ���������� �����
GC.INS_DOG_USL(V_ACCNUM,'810','382','1',null,v47422,'U',V_OTDEL=>'2719862922',V_DOPEN=>sysdate,NO_NNS=>true);

select s into S_ObjID from acc where dog_id=V_ACCNUM;
select objid into S_ObjID_ACC from acc where dog_id=V_ACCNUM;
gc.nns.SetNewNNS(S_ObjID,'810',t_mask,date_open,null) ;   ---- ��������� ������ NNS
select rowid into ident from gc.acc where s = s_objid;
GC.UPD_ACC(ident,V_AUTOCLEAR=>NULL,V_STATUS=>0,V_NAME=>r.name_acc);  --������ ������������ �����


--��������� ��� ������� ��� �������� ���������� �����. 
select rowid into ident1 from gc.dog where objid = V_ACCNUM;
select ID into SPRAV_ID from gc.sprav where type = chr(37) and name = '��� �������� ������';
GC.UPD_DOG(ident1,'1',NULL,V_STATUS=>0,V_SPRAV_ID=>SPRAV_ID);
--��������� ��� ������� ��� �������� ���������� �����. 


--- ������������� EXT_CONS_ACC
--select ObjID into v_ObjID from acc where s=V_ACCNUM;
if not gc.radd_q(objtype_ =>'ACC'
                    ,objid_ =>s_ObjID_ACC
                    ,name_ =>'EXT_CONS_ACC'
                    ,num_ => 0
                    ,txt_ =>'�������� ��� ����� ����������� �� ���'
                    ,value_ =>'47422810409000011044'
                    ,date_b_ => sysdate
                    ,date_e_ => null
                    ,filial =>pFilialId)
    then 
        gc.app_err.put ('BOOKKEEP', 292);
    end if;   
--���������� ������� ����������
GC.SET_REKV(s_Objid
           ,'810'
           ,'044525685'
           ,'30101810845250000685'
           ,'00000810100000000001'
           ,'"���-����" (���)'
           ,'"���-����" (���)'
           ,'������'
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