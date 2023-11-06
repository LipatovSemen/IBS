DECLARE vBS INT;
BEGIN
GC.P_SUPPORT.ARM_START(); 
--получаем свободный системный номер счета. BS
SELECT GC.P_BAL.GETNEWBS INTO vBS FROM DUAL;
GC.INS_PLAN( vBS
                , vBS
                , '42309'
                , '42309'
                , '011'
                , 'P' --ТОЧНО ПАССИВНЫЙ
                , 'Банковская ячейка'
                , ''
                , ''
                , 'N'
                , ''
                , 'N');
COMMIT;

SELECT GC.P_BAL.GETNEWBS INTO vBS FROM DUAL;
GC.INS_PLAN( vBS
                , vBS
                , '47422'
                , '47422'
                , '011'
                , 'P' --ТОЧНО ПАССИВНЫЙ
                , 'Банковская ячейка. Аренда'
                , ''
                , ''
                , 'N'
                , ''
                , 'N');
COMMIT;


SELECT GC.P_BAL.GETNEWBS INTO vBS FROM DUAL;
GC.INS_PLAN( vBS
                , vBS
                , '91202'
                , '91202'
                , '900'
                , '-' --АКТИВНО-ПАССИВНЫЙ УТОЧНИТЬ???
                , 'Внебалансовый счет учета ключей по депозитарию'
                , ''
                , ''
                , 'N'
                , ''
                , 'N');
COMMIT;

SELECT GC.P_BAL.GETNEWBS INTO vBS FROM DUAL;
GC.INS_PLAN( vBS
                , vBS
                , '91203'
                , '91203'
                , '900'
                , '-' --АКТИВНО-ПАССИВНЫЙ УТОЧНИТЬ???
                , 'Внебалансовый счет учета ключей по депозитарию'
                , ''
                , ''
                , 'N'
                , ''
                , 'N');
COMMIT;
END;
