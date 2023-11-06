-- Start of DDL Script for Package GC.SDM$IBS
-- Generated 06-ноя-2023 16:14:22 from GC@BANK

CREATE OR REPLACE 
package sdm$ibs as
 
 --
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
    ,PLoop_Delay varchar2 
    ) return sys_refcursor;    
--    
  function get_subj_list
    (pSubjName varchar2
    ) return sys_refcursor;
    
  function get_subjdover_list
    (pSubjName varchar2
    ) return sys_refcursor;    
    
  function get_trust_list
    (pObjid varchar2
    ) return sys_refcursor;    
    
  function get_tariff_list
    (pObjid varchar2
    ) return sys_refcursor;        
    
  function get_maina_list
    (pObjid varchar2
    ) return sys_refcursor;     
    
  procedure add_dover
    (pObjID in varchar2
    ,pSubjID in varchar2
    ,pDateSt in date
    ,pDateEn in date
    );        
  --
  procedure annul_dover
    (pID in number
   ,pTXT in varchar2    
    );    
  --    
  procedure get_ibs_info
    (pObjID in varchar2
    ,pOst_Deposit out varchar2
    ,pOst_Rent out varchar2
    ,pOst_Nns out varchar2
    ,pOst_91202 out varchar2
    ,pOst_91203 out varchar2        
    );
  --Список возможных типов печати
  function get_print_list return sys_refcursor; 
  --Список возможных оснований для вскрытия ячейки (начитывается из справочника)
  function get_reason_unlock_list return sys_refcursor; 
  --Список возможных типов ячеек  
  function get_typeibs_list return sys_refcursor; 
  --Протокол начислений
  function get_execincome_list return sys_refcursor;   
  --Глобальные настройки функционала ячеек
  function get_global_quals return sys_refcursor;   
  
  
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
    ,pTel_Dop varchar2 default null
    ,pMail_Dop varchar2 default null    
    ,pIBS_Type int
    ,pLinkSubj varchar2
    ,pIBS_DEAL varchar2
    ,pProlong number 
    );
  -- 
  procedure upd_ibs
    (pObjId varchar2
    ,pNumDog varchar2
    ,pNns varchar2
    ,pDeposit number
    ,pDfinal date
    ,pPhone varchar2
    ,pMail varchar2
    ,pPhone_Dop varchar2
    ,pMail_Dop varchar2    
    );
  --
  procedure del_ibs(pId varchar2
  );
  
  procedure close_ibs(pId varchar2
                     ,pControl varchar2 
  );
  --Процедура начисления удержание в доход за период со счета аренды ячеек
  procedure mass_income(pDateStart date
                       ,pDateEnd date
                       ,pFilial varchar2 
  );  
  
  procedure prolong_rent(pObjid varchar2
                       ,pPeriod_type varchar2
                       ,pPeriod_Int int 
  );    
  --Списание залога за ключ
  function DEPT_DEPOSIT
    (pObjID varchar2
    ,pDeposit_Doc number
    ,pCur varchar2
    ,pNNS varchar2
    ,pObjidDeposit varchar2    
    ,pVltrDt date
    ,pNazPlat varchar2
    ,pTypeOper varchar2      
    ) return number;

 --Списание аренды за ячейку    
  function DEPT_RENT
    (pObjID varchar2
    ,pTariff_Doc number
    ,pCur varchar2
    ,pNNS varchar2
    ,pObjidTariff varchar2    
    ,pVltrDt date
    ,pNazPlat varchar2
    ,pTypeOper varchar2
    ) return number; 

--Возврат залога за ключ клиенту при закрытии ячейки    
  function OFF_DEPOSIT
    (pObjID varchar2
    ,pSUM number
    ,pCur varchar2
    ,pNNS varchar2
    ,pObjidDeposit varchar2    
    ,pVltrDt date
    ,pNazPlat varchar2
    ,pTypeOper varchar2
    ) return number;      

--Перечисление залога в доход или на счет невыясненных сумм при вскрытии ячейки
  function UNLOCK_DEPOSIT
    (pObjID varchar2
    ,pSUM number
    ,pObjidDeposit varchar2
    ,pTypeOper varchar2    
    ,pVltrDt date
    ,pNazPlat varchar2
    ,pUNP number    
    ) return number;  

--Списание просрочки с последующим закрытием ячейки или пролонгацией    
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
    ) return number;  

--Формирование проводок по внебалансу при открытии/закрытии ячейки    
  function vneb_key_create_doc
  (pObjid varchar2
  ,pType varchar2
  ,pUNP varchar2
  )
  return number;         

--Принудительное списание в доход остатка на счете аренды при досрочном закрытии ячейки или пролонгации    
  function INCOME_IBS
    (pObjID varchar2
    ,pSUM number
    ,pDateSt date
    ,pDateEnd date
    ,pVltrDt date
    ,pNazPlat varchar2   
    ,pUNP number
    ) return number;      
  --
end sdm$ibs;
/

-- Grants for Package
GRANT EXECUTE ON sdm$ibs TO bookkeeper
/


-- End of DDL Script for Package GC.SDM$IBS
