 begin
     p_support.arm_start;
  reg_new_qual('SDM_IBS_DEPOSIT','ВЛАДЕЛЕЦ СЧЕТА БАНКОВСКОЙ ЯЧЕЙКИ (ЗАЛОГ)','CHAR');
  p_qual.obj2q('SDM_IBS_DEPOSIT','SYSUST','EDIT_UST');
  p_qual.obj2q('SDM_IBS_DEPOSIT','ACC','EDIT_ACC');

  reg_new_qual('SDM_IBS_RENT','ВЛАДЕЛЕЦ СЧЕТА БАНКОВСКОЙ ЯЧЕЙКИ (АРЕНДА)','CHAR');
  p_qual.obj2q('SDM_IBS_RENT','SYSUST','EDIT_UST');
  p_qual.obj2q('SDM_IBS_RENT','ACC','EDIT_ACC');

  reg_new_qual('SDM_IBS_91202','ВЛАДЕЛЕЦ СЧЕТА УЧЕТА КЛЮЧЕЙ (91202)','CHAR');
  p_qual.obj2q('SDM_IBS_91202','SYSUST','EDIT_UST');
  p_qual.obj2q('SDM_IBS_91202','ACC','EDIT_ACC');

  reg_new_qual('SDM_IBS_91203','ВЛАДЕЛЕЦ СЧЕТА УЧЕТА КЛЮЧЕЙ (91203)','CHAR');
  p_qual.obj2q('SDM_IBS_91203','SYSUST','EDIT_UST');
  p_qual.obj2q('SDM_IBS_91203','ACC','EDIT_ACC');
  commit;  
  end;
