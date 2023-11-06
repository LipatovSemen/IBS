declare
  procedure ins_proc( p1 in varchar2, p2 in varchar2, p3 in varchar2
                    , p4 in varchar2, p5 in varchar2, p6 in varchar2
                    ) is
  begin
    begin
       insert into lmsg( GRP,ID,INFO,NAME,TEX,JP) values (p1,p2,p3,p4,p5,p6);
    exception when DUP_VAL_ON_INDEX then null;
    end;
  end;
begin
  p_support.arm_start;
  ins_proc('SDMIBS','SDMIBS_ADD','I','Добавление ячейки','','J');
  ins_proc('SDMIBS','IBSDOVER_ADD','I','Заведение доверенности для ячейки','','J');
  ins_proc('SDMIBS','IBSDOVER_DEL','I','Аннулирование доверенности для ячейки','','J');
  ins_proc('SDMIBS','SDMIBS_UPD1','U','Редактирование номера договора ячейки','','J');
  ins_proc('SDMIBS','SDMIBS_UPD2','U','Редактирование тарифа','','J');
  ins_proc('SDMIBS','SDMIBS_UPD3','U','Редактирование стоимости залога','','J');
  ins_proc('SDMIBS','SDMIBS_UPD4','U','Редактирование номера счета для списания','','J');
  ins_proc('SDMIBS','SDMIBS_UPD6','U','Редактирование даты окночания','','J');
  ins_proc('SDMIBS','SDMIBS_UPD7','U','Редактирование номер телефона','','J');
  ins_proc('SDMIBS','SDMIBS_UPD8','U','Редактирование почты','','J');
  ins_proc('SDMIBS','SDMIBS_UPD9','U','Редактирование суммы хранения','','J');  
  ins_proc('SDMIBS','SDMIBS_UPD10','U','Редактирование номер телефона связанного клиента','','J');
  ins_proc('SDMIBS','SDMIBS_UPD11','U','Редактирование почты связанного клиента','','J');
  ins_proc('SDMIBS','SDMIBS_UPROL','U','Изменение настроек пролонгации','','J'); 
  ins_proc('SDMIBS','SDMIBS_ULOCK','U','Вскрытие ячейки','','J');  
  ins_proc('SDMIBS','SDMIBS_DEL','D','Удаление ячейки','','J');
  ins_proc('SDMIBS','SDMIBS_CLOSE','C','Закрытие ячейки','','J');
  ins_proc('SDMIBS','SDMIBS_DOCUM','K','Формирование документа','','J');
  ins_proc('SDMIBS','SDMIBS_PROL','P','Пролонгация ячейки','','J');  
  commit;
end; 
/
