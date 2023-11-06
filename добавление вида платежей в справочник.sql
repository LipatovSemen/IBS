declare
vNewId sprav.id%type;
begin
     p_support.arm_start;
  gc.jour_pack.add_jour_txt('Добавлен при запуске функционала по ИБС');
  gc.ins_sprav(V_SPRAV_ID  => vNewId
              ,V_TYPE => chr('37')
              ,V_NAME => 'ИБС СПИСАНИЕ ЗАЛОГА ЗА КЛЮЧ'
              ,V_SNAME => null
              ,V_OTHERCODE => null
              ,V_STATUS => '0');
end;
commit;


--ОТДЕЛЬНО

declare
vNewId sprav.id%type;
begin
  gc.jour_pack.add_jour_txt('Добавлен при запуске функционала по ИБС');
  gc.ins_sprav(V_SPRAV_ID  => vNewId
              ,V_TYPE => chr('37')
              ,V_NAME => 'ИБС СПИСАНИЕ АРЕНДЫ'
              ,V_SNAME => null
              ,V_OTHERCODE => null
              ,V_STATUS => 0);
end;
commit;
