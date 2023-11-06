--��������� � ����� ������ PS=900 ���� 91202

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
v_objid varchar2(12);
v91202 varchar2(5);
begin
--user_login.arm_start('CONVERT','03.20.005',pFilialId);
set_filial(pFilialId);
p_Support.arm_start();

select p.bs
into v91202 
            from gc.plan p
where 1=1
and bbaln = '91202' 
and p.ps = '900' 
and upper(p.name) like '%���������%';

for r in ( 

select  
    nns as newnns
    ,'�� ������ ��������. ������������� ���� ����� ������ �� ����������� ������ � '||num_ibs as name_acc
    ,v91202 as bs_sys   
from sdm$ibs_nns
where 1=1
and substr(nns,1,5) = '91202'
and filial = '382'
and otdel = '3012703215'
) 
loop     
select type into type_acc from plan where bs=v91202;
DBMS_OUTPUT.put_line(r.newnns||' '||r.bs_sys||' '||type_acc||' '||r.name_acc);

t_mask := r.newnns;
vKey := nns.Get_Key(r.newnns, pFilialId); --���������� ����
t_mask := nns.Set_Field(t_mask, vKey, 9, 1); --������� ���� � ���

GC.INS_ACC(V_ACCNUM,v91202,'810',id_owner,null,type_acc,null,date_open,r.name_acc,V_AUTOCLEAR=>'N',NO_NNS=>false,v_otdel=>'3012703215',pfilial=>pFilialId); --�������� ������ 91202
gc.nns.SetNewNNS(V_ACCNUM,'810',t_mask,date_open,null) ;   ---- ��������� ������ NNS

--- ������������� EXT_CONS_ACC
select a.objid into v_ObjID from gc.sdm$ibs_nns s,gc.nns_list n,gc.acc a where s.nns = n.nns and substr(s.nns,1,5) = '91202' and a.s = n.s and n.nns = t_mask;
if not gc.radd_q(objtype_ =>'ACC'
                    ,objid_ =>v_objid
                    ,name_ =>'EXT_CONS_ACC'
                    ,num_ => 0
                    ,txt_ =>'�������� ��� ����� ����������� �� ���'
                    ,value_ =>t_mask
                    ,date_b_ => sysdate
                    ,date_e_ => null
                    ,filial =>pFilialId)
    then 
        gc.app_err.put ('BOOKKEEP', 292);
    end if;   
--���������� ������� ����������
GC.SET_REKV(V_ACCNUM
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