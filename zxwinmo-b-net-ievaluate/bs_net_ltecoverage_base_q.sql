CREATE TEMPORARY FUNCTION getdis AS 'com.zte.bigdata.udf.lanlonutil.DistanceOfLatLon';
CREATE TEMPORARY FUNCTION getazimuthangle AS 'com.zte.bigdata.udf.lanlonutil.AngleOf2LatLon';
CREATE TEMPORARY FUNCTION getanglediff AS 'com.zte.bigdata.udf.angleutil.IntersactionAngle';
CREATE TEMPORARY FUNCTION getintersactionangle AS 'com.zte.bigdata.udf.lanlonutil.IntersactionAngleOf3Latlon';

cache table temp_lte_cm_projdata as
WITH WGS84 AS (
    SELECT 
        6378137.0 AS a,          -- 长半轴
        0.00669437999014 AS e2   -- 第一偏心率平方
)
SELECT
    reportcellkey,
    cm.enodebid,
    cid,
    rattypeid,
    dl_earfcn,
    pci,
    citycode,
    districtcode,
    province,
    city,
    district,
    celllon,
    celllat,
    distance,
    azimuth,
    -- Calculate the radius of curvature of the meridian N = a / sqrt(1 - e²*sin²(lat))
    w.a / SQRT(1 - w.e2 * POWER(SIN(RADIANS(cm.celllat)), 2)) AS N,
    -- Calculate the radius of curvature of the meridian M = a*(1-e²) / (1-e²*sin²(lat))^(3/2)
    w.a * (1 - w.e2) / POWER(1 - w.e2 * POWER(SIN(RADIANS(cm.celllat)), 2), 1.5) AS M
FROM
    ( SELECT
          reportcellkey,
          enodebid,
          cid,
          rattypeid,
          dl_earfcn,
          pci,
          citycode,
          districtcode,
          province,
          city,
          district,
          celllon,
          celllat,
          azimuth
      FROM
          spark_catalog.zxdmo.lte_cm_projdata
      WHERE
          p_provincecode = $lte_cm_projdata.p_provincecode$ ) cm
        INNER JOIN ( SELECT
                         nodebid
                     FROM
                         spark_catalog.zxdmo.bs_net_prenodebid_q
                     WHERE
                         p_provincecode = $bs_net_ltecoverage_base_q.p_provincecode$
                         AND p_date = '$bs_net_ltecoverage_base_q.p_date$'
                         AND p_hour = $bs_net_ltecoverage_base_q.p_hour$
                         AND p_quarter = $bs_net_ltecoverage_base_q.p_quarter$
                         AND network = 'LTE'
                         AND nodebid IS NOT NULL ) prenodebid ON cm.enodebid = prenodebid.nodebid
        LEFT JOIN ( SELECT
                        enodebid,
                        -- 若distance为空则此字段按0提供（无法判定）
                        (case when distance is null or distance='' then 0 else distance end) as distance
                    FROM
                        spark_catalog.zxdmo.dm_lte_intersitedistance
                    WHERE
                        p_provincecode = $dm_lte_intersitedistance.p_provincecode$ ) dis ON cm.enodebid = dis.enodebid
        CROSS JOIN WGS84 w
;

cache table temp_neigh_mr as
select /*+ UNCHECKED_FUNC(getdis,getazimuthangle,getanglediff,getintersactionangle) */
    mrkey,
    enodebid,
    cid,
    (case when mod3srsrpflag=1 and mod3snrsrpflag=1 and mod3snpciflag=1 and mod3ncellnumflag=1 then 1 else 0 end) as mod3,
    (case when overlapsnrsrpflag=1 and overlapsrsrpflag=1 and snearfcnflag=1 and overlapncellnumflag=1 then 1 else 0 end) as overlapped,
    (case when overshootsnrsrpflag=1 and overshootsrsrpflag=1 and snearfcnflag=1 and overshootmrtoscelldistssflag=1 and overshootmrtoscelldistnsflag=1 and overshootmrscellangleflag=1 and overshootncellnumflag=1 then 1 else 0 end) as overshoot
from
(
    select
        mrkey,
        enodebid,
        cid,
        snearfcnflag,
        mod3snpciflag,
        mod3snrsrpflag,
        mod3srsrpflag,
        overlapsnrsrpflag,
        overlapsrsrpflag,
        overshootmrtoscelldistnsflag,
        overshootmrtoscelldistssflag,
        overshootsnrsrpflag,
        overshootsrsrpflag,
        (case when (abs(smrangle) < #smranglethd# and abs(nmrangle) < #nmranglethd# and abs(sangle-nangle) < #scellandncellanglethd#) and ((abs(snmrangle) >= #snmranglethd# and abs(mrsnangle) < #mrsnanglethd#) or snmlatdifflon = 1) then 1 else 0 end) as overshootmrscellangleflag,
        (case when sum( case when (overshootsnrsrpflag=1 and snearfcnflag=1 and overshootmrtoscelldistnsflag=1 and abs(smrangle) < #smranglethd# and abs(nmrangle) < #nmranglethd# and abs(sangle-nangle) < #scellandncellanglethd#) and ((abs(snmrangle) >= #snmranglethd# and abs(mrsnangle) < #mrsnanglethd#) or snmlatdifflon = 1) then 1 else 0 end ) over(partition by mrkey, enodebid, cid) >= #overshootncellnum# then 1 else 0 end) as overshootncellnumflag,
        (case when sum( case when overlapsnrsrpflag=1 and snearfcnflag=1 then 1 else 0 end) over(partition by mrkey, enodebid, cid) >=  #overlapncellnum# then 1 else 0 end) as overlapncellnumflag,
        (case when sum(case when mod3snrsrpflag = 1 and mod3snpciflag = 1 then 1 else 0 end) over(partition by mrkey, enodebid, cid) >=  #mod3ncellnum# then 1 else 0 end) as mod3ncellnumflag
    from
    (
        select
            mrkey,
            enodebid,
            cid,
            snearfcnflag,
            mod3snrsrpflag,
            mod3srsrpflag,
            mrsnangle,
            nangle,
            nmrangle,
            overlapsnrsrpflag,
            overlapsrsrpflag,
            overshootsnrsrpflag,
            overshootsrsrpflag,
            sangle,
            smrangle,
            snmlatdifflon,
            snmrangle,
            (case when (positionmark=0 and scellmrdis >= #overshootsstimes_indoor# * distance) then 1 when ((positionmark is null or positionmark!=0) and scellmrdis >= #overshootsstimes_outdoor# * distance) then 1 else 0 end ) as overshootmrtoscelldistssflag,
            (case when (positionmark=0 and scellmrdis >= #overshootnstimes_indoor# * mrandncelldis and scellandncelldis > #sncelldistance# and scellmrdis >= #sncelldistimes# * scellandncelldis) then 1 when ((positionmark is null or positionmark!=0) and scellmrdis >= #overshootnstimes_outdoor# * mrandncelldis and scellandncelldis > #sncelldistance# and scellmrdis >= #sncelldistimes# * scellandncelldis ) then 1 else 0 end ) as overshootmrtoscelldistnsflag,
            (case when snearfcnflag=1 and npci%3=pci%3 then 1 else 0 end) as mod3snpciflag
        from
        (
            select
                mrkey,
                n1.enodebid,
                n1.cid,
                positionmark,
                c1.pci,
                if(npci is null,c2.pci,npci) as npci,
                c1.distance,
                c1.azimuth as sangle,
                c2.azimuth as nangle,
                (case when searfcn=nearfcn then 1 else 0 end) as snearfcnflag,
                (case when mrlat is not null and mrlon is not null and c1.celllat is not null and c1.celllon is not null then cast(getdis(cast(mrlat as double),cast(mrlon as double),c1.celllat,c1.celllon) as double) else c1.distance end) as scellmrdis,
                (case when mrlat is not null and mrlon is not null and c2.celllat is not null and c2.celllon is not null then cast(getdis(cast(mrlat as double),cast(mrlon as double),c2.celllat,c2.celllon) as double) else null end) as mrandncelldis,
                (case when c1.celllat is not null and c1.celllon is not null and c2.celllat is not null and c2.celllon is not null then cast(getdis(c1.celllat,c1.celllon,c2.celllat,c2.celllon) as double) else null end) as scellandncelldis,
                cast(getanglediff(cast(getazimuthangle(c1.celllat,c1.celllon,mrlat,mrlon) as double),c1.azimuth) as double) as smrangle,
                cast(getanglediff(cast(getazimuthangle(c2.celllat,c2.celllon,mrlat,mrlon) as double),c2.azimuth) as double) as nmrangle,
                cast(getintersactionangle(c1.celllat,c1.celllon,c2.celllat,c2.celllon,mrlat,mrlon) as double) as snmrangle,
                cast(getintersactionangle(mrlat,mrlon,c1.celllat,c1.celllon,c2.celllat,c2.celllon) as double) as mrsnangle,
                case when (c1.celllat=c2.celllat and c2.celllat=mrlat) and ((c1.celllon > c2.celllon and c2.celllon > mrlon) or (c1.celllon < c2.celllon and c2.celllon < mrlon)) then 1 when (c1.celllon=c2.celllon and c2.celllon=mrlon) and ((c1.celllat > c2.celllat and c2.celllat > mrlat) or (c1.celllat < c2.celllat and c2.celllat < mrlat)) then 1 else 0 end as snmlatdifflon,
                (case when positionmark=0 and snrsrpdiff < #overshootrsrpdifferthd_indoor# and snrsrpdiff < #overshootrsrpdifferthd_lt_indoor# then 1 when (positionmark is null or positionmark!=0) and snrsrpdiff < #overshootrsrpdifferthd_outdoor# and snrsrpdiff < #overshootrsrpdifferthd_lt_outdoor# then 1 else 0 end) as overshootsnrsrpflag,
                (case when positionmark=0 and srsrp >= #overshootrsrpthd_indoor# then 1 when (positionmark is null or positionmark!=0) and srsrp >=  #overshootrsrpthd_outdoor# then 1 else 0 end) as overshootsrsrpflag,
                (case when positionmark=0 and abs(snrsrpdiff) < #overlaprsrpdifferthd_indoor# then 1 when (positionmark is null or positionmark!=0) and abs(snrsrpdiff) < #overlaprsrpdifferthd_outdoor# then 1 else 0 end) as overlapsnrsrpflag,
                (case when positionmark=0 and srsrp >= #overlaprsrpthd_indoor# then 1 when (positionmark is null or positionmark!=0) and srsrp >=  #overlaprsrpthd_outdoor# then 1 else 0 end) as overlapsrsrpflag,
                (case when positionmark=0 and srsrp >= #ucrsrpthd_mod3_indoor# then 1 when (positionmark is null or positionmark!=0) and srsrp >=  #ucrsrpthd_mod3_outdoor# then 1 else 0 end) as mod3srsrpflag,
                (case when positionmark=0 and nrsrp - srsrp > #ucrsrpdifferthd_mod3_indoor# then 1 when (positionmark is null or positionmark!=0) and nrsrp - srsrp > #ucrsrpdifferthd_mod3_outdoor# then 1 else 0 end) as mod3snrsrpflag
            from
            (
                select
                    c030 as mrkey,
                    c037 as locationtype,
                    d129 as positionmark,
                    c017 as mrlon,
                    c018 as mrlat,
                    grid_three_column_20,
                    grid_three_column_50,
                    grid_three_column_100,
                    d001 as mcc,
                    d002 as mnc,
                    d004p as enodebid,
                    d005p as cid,
                    c039 as searfcn,
                    c010 as srsrp,
                    c034 as srsrq,
                    d004 as nenodebid,
                    d005 as ncellid,
                    c035 as nearfcn,
                    c001 as npci,
                    c002 as nrsrp,
                    c003 as nrsrq,
                    c040 as ta,
                    null as ulsinr,
                    c010-c002 as snrsrpdiff
                 from $l_t120_ex$
                where p_provincecode=$l_t120_ex.p_provincecode$
                  and p_date='$l_t120_ex.p_date$'
                  and p_hour=$l_t120_ex.p_hour$
                  and p_quarter=$l_t120_ex.p_quarter$
                  and p_region=$l_t120_ex.p_region$
                  and c019 in (1,3) -- datatype
            ) n1
                INNER JOIN temp_lte_cm_projdata c1
            on n1.enodebid=c1.enodebid and n1.cid=c1.cid
                LEFT JOIN (
                  select enodebid, cid, pci, azimuth, celllat, celllon from spark_catalog.zxdmo.lte_cm_projdata WHERE p_provincecode = $lte_cm_projdata.p_provincecode$
            )c2
            on n1.nenodebid=c2.enodebid and n1.ncellid=c2.cid
        ) n2
    ) n3
) n4
;


insert overwrite table $bs_net_ltecoverage_base_q$
    partition(
        p_provincecode=$bs_net_ltecoverage_base_q.p_provincecode$,
        p_date='$bs_net_ltecoverage_base_q.p_date$',
        p_hour=$bs_net_ltecoverage_base_q.p_hour$,
        p_quarter=$bs_net_ltecoverage_base_q.p_quarter$)
-- MR Data
with temp_mrdataAll as (
    select
        d004 as enodebid,
        d005 as cid,
        c.rattypeid,
        if(s1.c067 is null,c.dl_earfcn,s1.c067) as dlearfcn,
        if(s1.c002 is null,c.pci,s1.c002) as pci,
        citycode,
        districtcode,
        province,
        city,
        district,
        d001 as mcc,
        d002 as mnc,
        c031 as earthid,
        grid_three_column_20,
        grid_three_column_50,
        grid_three_column_100,
        c047 as locationtype,
        c129 as positionmark,
        c009 as rsrp,
        c010 as rsrq,
        c017 as mrlon,
        c018 as mrlat,
        (case when c018 is not null and c017 is not null and c.celllat is not null and c.celllon is not null then cast(getdis(cast(c018 as double),cast(c017 as double),c.celllat,c.celllon) as double) else null end) as scellmrdis,
        c024 as ulsinr,
        c027 as ta,
        c036 as aoa,
        c042 as puschprbnum,
        c043 as pdschprbnum,
        c137 as allerabulpdcptput,
        c138 as allerabdlpdcptput,
        c143 as puschuseprbnum,
        c144 as pdschuseprbnum,
        c145 as puschavailprbnum,
        c146 as pdschavailprbnum,
        c155 as sumuetputpuschprbnum,
        c156 as sumuetputpdschprbnum,
        c208 as sumulpdcpwithoutlastpiece,
        c209 as sumdlpdcpwithoutlastpiece,
        c210 as sumulpdcperabtimerlen,
        c211 as sumdlpdcperabtimerlen,
        isoverlap,
        isovershoot,
        ismod3interfer,
        -- Calculate HDOA with value range limitation using ellipsoid model
        -- First, determine whether it is an omnidirectional station（360）
        CASE WHEN c.azimuth =360 THEN NULL
             ELSE
             (
                PMOD(
                    DEGREES(
                        ATAN2(
                            -- Distance in X direction(m) = Arc length per degree of longitude * Longitude difference = (π/180) * N * cos(lat) * lon
                            (PI() / 180.0) * c.N * COS(RADIANS(mrlat)) * (mrlon - celllon),
                            -- Distance in Y direction(m) = Arc length per degree of latitude * Latitude difference = (π/180) * M * lat
                            (PI() / 180.0) * c.M * (mrlat - celllat)
                        )
                    ) - azimuth + 180, 360
                ) - 180
             )
        END AS hdoa
        , c.distance
     from
     (
        select
            c002, c009, c010, c017, c018, c024, c027, c031, c030, c036, c042, c043, c047, c067, c129, c137, 
            c138, c143, c144, c145, c146, c155, c156, c208, c209, c210, c211, d001, d002, d004, d005, 
            grid_three_column_20, grid_three_column_50, grid_three_column_100
        from $l_t054_ex$
        where p_provincecode=$l_t054_ex.p_provincecode$
          and p_date='$l_t054_ex.p_date$'
          and p_hour=$l_t054_ex.p_hour$
          and p_quarter=$l_t054_ex.p_quarter$
          and p_region=$l_t054_ex.p_region$
          and c019 in (1,3) -- datatype
     ) s1
         INNER JOIN temp_lte_cm_projdata c
       on concat(s1.d004,'_',s1.d005)=c.reportcellkey
         LEFT JOIN
     (
         select
             mrkey,
             enodebid,
             cid,
             (case when sum(overlapped) > 0 then 1 else 0 end) as isoverlap,
             (case when sum(overshoot) > 0 then 1 else 0 end) as isovershoot,
             (case when sum(mod3) > 0 then 1 else 0 end) as ismod3interfer
          from temp_neigh_mr r
         group by mrkey, enodebid, cid
     ) f
       on s1.c030=f.mrkey and s1.d004=f.enodebid and s1.d005=f.cid
),
temp_mrdata_hdoaCorrection as (
    select 
        enodebid,
        cid,
        rattypeid,
        dlearfcn,
        pci,
        citycode,
        districtcode,
        province,
        city,
        district,
        mcc,
        mnc,
        earthid,
        grid_three_column_20,
        grid_three_column_50,
        grid_three_column_100,
        locationtype,
        positionmark,
        rsrp,
        rsrq,
        mrlon,
        mrlat,
        scellmrdis,
        ulsinr,
        ta,
        aoa,
        puschprbnum,
        pdschprbnum,
        allerabulpdcptput,
        allerabdlpdcptput,
        puschuseprbnum,
        pdschuseprbnum,
        puschavailprbnum,
        pdschavailprbnum,
        sumuetputpuschprbnum,
        sumuetputpdschprbnum,
        sumulpdcpwithoutlastpiece,
        sumdlpdcpwithoutlastpiece,
        sumulpdcperabtimerlen,
        sumdlpdcperabtimerlen,
        isoverlap,
        isovershoot,
        ismod3interfer,
        hdoa,
        distance
    from(
        select 
            enodebid, cid, rattypeid, dlearfcn, pci, citycode, districtcode, province, city, district, mcc, mnc, 
            earthid, grid_three_column_20, grid_three_column_50, grid_three_column_100, locationtype, positionmark, 
            rsrp, rsrq, mrlon, mrlat, scellmrdis, ulsinr, ta, aoa, puschprbnum, pdschprbnum, allerabulpdcptput, allerabdlpdcptput, 
            puschuseprbnum, pdschuseprbnum, puschavailprbnum, pdschavailprbnum, sumuetputpuschprbnum, sumuetputpdschprbnum, 
            sumulpdcpwithoutlastpiece, sumdlpdcpwithoutlastpiece, sumulpdcperabtimerlen, sumdlpdcperabtimerlen, isoverlap, 
            isovershoot, ismod3interfer,
            hdoa,
            distance
        from temp_mrdataAll
    ) h
)
select
    '$bs_net_ltecoverage_base_q.p_date$' as `day`,
    $bs_net_ltecoverage_base_q.p_hour$ as `hour`,
    $bs_net_ltecoverage_base_q.p_quarter$ as `quarter`,
    concat(enodebid,'_',cid) as cellkey,
    enodebid,
    cid,
    rattypeid,
    dlearfcn,
    pci,
    $bs_net_ltecoverage_base_q.p_provincecode$ as provincecode,
    citycode,
    districtcode,
    province,
    city,
    district,
    mcc,
    lpad(mnc, 2, '0') as mnc,
    earthid as regionid,
    cast(split(grid_three_column_100,',')[1] as int) as x_offset_100,
    cast(split(grid_three_column_100,',')[2] as int) as y_offset_100,
    cast(split(grid_three_column_50,',')[1] as int) as x_offset_50,
    cast(split(grid_three_column_50,',')[2] as int) as y_offset_50,
    cast(split(grid_three_column_20,',')[1] as int) as x_offset_20,
    cast(split(grid_three_column_20,',')[2] as int) as y_offset_20,
    case
        when locationtype=0 then 1
        when locationtype=1 or locationtype=101 then 2
        when locationtype=2 or locationtype=3 then 3
        else 4
    end as locationaccuracytype,
    positionmark,
    sum(mrlon) as totalmrlon,
    sum(mrlat) as totalmrlat,
    count(if(mrlon is not null and mrlat is not null,1,null)) as validlonlat_totalmrcount,
    cast(sum(scellmrdis) as bigint) as celmr_totaldis,
    count(if(scellmrdis is not null,1,null)) as celmr_discount,
    sum(if(rsrp>=-140 and rsrp<=-43,rsrp,null)) as totalrsrp,
    count(if(rsrp>=-140 and rsrp<=-43,1,null)) as rsrpcount,
    count(if((positionmark=0 and rsrp>=#host_mr_goodrsrp_indoor#) or ((positionmark is null or positionmark!=0) and rsrp>=#host_mr_goodrsrp_outdoor#),1,null)) as rsrpgoodcount,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43,rsrp,null)) as validlonlat_totalrsrp,
    count(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43,1,null)) as validlonlatrsrp_totalmrcount,
    sum(if(rsrp>=-140 and rsrp<=-43 and ta is not null,rsrp,null)) as validta_totalrsrp,
    count(if(rsrp>=-140 and rsrp<=-43 and ta is not null,1,null)) as validta_totalmrcount,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43 and ta is not null,rsrp,null)) as validlonlatta_totalrsrp,
    count(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43 and ta is not null,1,null)) as validlonlatta_totalmrcount,
    sum(rsrq) as totalrsrq,
    count(rsrq) as rsrqcount,
    count(if((positionmark=0 and rsrq>=#host_mr_goodrsrq_indoor#) or ((positionmark is null or positionmark!=0) and rsrq>=#host_mr_goodrsrq_outdoor#),1,null)) as rsrqgoodcount,
    sum(ulsinr) as totalulsinr,
    count(ulsinr) as ulsinrcount,
    count(if((positionmark=0 and ulsinr>=#host_mr_goodulsinr_indoor#) or ((positionmark is null or positionmark!=0) and ulsinr>=#host_mr_goodulsinr_outdoor#),1,null)) as ulsinrgoodcount,
    count(if((positionmark=0 and rsrp>=#host_ulcovrate_goodrsrp_indoor# and ulsinr>=#host_ulcovrate_goodulsinr_indoor#) or ((positionmark is null or positionmark!=0) and rsrp>=#host_ulcovrate_goodrsrp_outdoor# and ulsinr>=#host_ulcovrate_goodulsinr_outdoor#),1,null)) as compulcovgood_mrcount,
    count(if((rsrp is not null and ulsinr is not null),1,null)) as compulcovvalid_mrcount,
    count(1) as period_totalmrcount,
    count(if((positionmark=0 and rsrp<#host_weakcovrsrp_indoor_thd#) or ((positionmark is null or positionmark!=0) and rsrp<#host_weakcovrsrp_outdoor_thd#),1,null)) as weakcover_mrcount,
    sum(isoverlap) as overlap_mrcount, -- isxxx flag is 1 or 0
    sum(isovershoot) as overshoot_mrcount, -- isxxx flag is 1 or 0
    sum(ismod3interfer) as mod3interfer_mrcount, -- isxxx flag is 1 or 0
    sum(puschprbnum) as puschprbnum,
    sum(pdschprbnum) as pdschprbnum,
    sum(puschuseprbnum) as puschuseprbnum,
    sum(pdschuseprbnum) as pdschuseprbnum,
    sum(puschavailprbnum) as puschavailprbnum,
    sum(pdschavailprbnum) as pdschavailprbnum,
    sum(sumuetputpuschprbnum) as sumuetputpuschprbnum,
    sum(sumuetputpdschprbnum) as sumuetputpdschprbnum,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43,allerabulpdcptput+allerabdlpdcptput,null)) as validlonlat_totalallerabpdcptput,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43,allerabulpdcptput,null)) as validlonlat_totalallerabulpdcptput,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43,allerabdlpdcptput,null)) as validlonlat_totalallerabdlpdcptput,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43 and aoa>=0 and aoa<30,allerabdlpdcptput,null)) as validlonlat_totalallerabdlpdcptput_aoa0_30,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43 and aoa>=30 and aoa<60,allerabdlpdcptput,null)) as validlonlat_totalallerabdlpdcptput_aoa30_60,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43 and aoa>=60 and aoa<90,allerabdlpdcptput,null)) as validlonlat_totalallerabdlpdcptput_aoa60_90,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43 and aoa>=90 and aoa<120,allerabdlpdcptput,null)) as validlonlat_totalallerabdlpdcptput_aoa90_120,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43 and aoa>=120 and aoa<150,allerabdlpdcptput,null)) as validlonlat_totalallerabdlpdcptput_aoa120_150,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43 and aoa>=150 and aoa<180,allerabdlpdcptput,null)) as validlonlat_totalallerabdlpdcptput_aoa150_180,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43 and aoa>=180 and aoa<210,allerabdlpdcptput,null)) as validlonlat_totalallerabdlpdcptput_aoa180_210,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43 and aoa>=210 and aoa<240,allerabdlpdcptput,null)) as validlonlat_totalallerabdlpdcptput_aoa210_240,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43 and aoa>=240 and aoa<270,allerabdlpdcptput,null)) as validlonlat_totalallerabdlpdcptput_aoa240_270,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43 and aoa>=270 and aoa<300,allerabdlpdcptput,null)) as validlonlat_totalallerabdlpdcptput_aoa270_300,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43 and aoa>=300 and aoa<330,allerabdlpdcptput,null)) as validlonlat_totalallerabdlpdcptput_aoa300_330,
    sum(if(mrlon is not null and mrlat is not null and rsrp>=-140 and rsrp<=-43 and aoa>=330 and aoa<360,allerabdlpdcptput,null)) as validlonlat_totalallerabdlpdcptput_aoa330_360,
    sum(CASE WHEN ta * 78 > #tafardisthrd#*distance THEN 1 ELSE 0 END) tafar_count,
    sum(allerabulpdcptput) as allerabulpdcptput,
    sum(allerabdlpdcptput) as allerabdlpdcptput,
    sum(sumulpdcpwithoutlastpiece) as sumulpdcpwithoutlastpiece,
    sum(sumdlpdcpwithoutlastpiece) as sumdlpdcpwithoutlastpiece,
    sum(sumulpdcperabtimerlen) as sumulpdcperabtimerlen,
    sum(sumdlpdcperabtimerlen) as sumdlpdcperabtimerlen,
    count(if(hdoa is not null and abs(hdoa) > #abnormalbound#, hdoa,null)) as azimuthinvalid_mrcount,
    count(if(hdoa is not null and abs(hdoa) <= #alignbound#, hdoa,null)) as azimuthalign_mrcount
from temp_mrdata_hdoaCorrection s2
group by enodebid,cid,rattypeid,dlearfcn,pci,citycode,districtcode,province,city,district,mcc,mnc,earthid,grid_three_column_20,grid_three_column_50,grid_three_column_100,locationtype,positionmark
;

uncache table temp_lte_cm_projdata;
uncache table temp_neigh_mr;
