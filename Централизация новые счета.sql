begin
for i in (
select num_ibs,nns,substr(nns,1,8)||case when substr(nns,9,1) = '0' then '1'
                                 when substr(nns,9,1) = '1' then '2'
                                 when substr(nns,9,1) = '2' then '3'
                                 when substr(nns,9,1) = '3' then '4'
                                 when substr(nns,9,1) = '4' then '5'
                                 when substr(nns,9,1) = '5' then '6'
                                 when substr(nns,9,1) = '6' then '7'
                                 when substr(nns,9,1) = '7' then '8'
                                 when substr(nns,9,1) = '8' then '9'
                                 when substr(nns,9,1) = '9' then '0'
                                 else '' end ||substr(nns,10,11) nns_new
                                 


 from GC.SDM$IBS_NNS
where otdel = '3012703215'
  and substr(nns,1,5) not in ('47422')
  and substr(nns,1,5) in ('91203')
  --and num_ibs = '1-9'
  )
  loop
  update gc.sdm$ibs_nns
  set nns = i.nns_new
     ,nns_5nt = i.nns_new
  where otdel = '3012703215'
    and substr(nns,1,5) not in ('47422')
    and num_ibs = i.num_ibs
    and substr(nns,1,5) in ('91203');
  end loop;
  end;  
  
  
  
select * from GC.SDM$IBS_NNS
where otdel = '3012703215'
