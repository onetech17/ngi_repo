CREATE TEMPORARY FUNCTION getdis AS 'com.zte.bigdata.udf.lanlonutil.DistanceOfLatLon';
CREATE TEMPORARY FUNCTION getazimuthangle AS 'com.zte.bigdata.udf.lanlonutil.AngleOf2LatLon';
CREATE TEMPORARY FUNCTION getanglediff AS 'com.zte.bigdata.udf.angleutil.IntersactionAngle';
CREATE TEMPORARY FUNCTION getintersactionangle AS 'com.zte.bigdata.udf.lanlonutil.IntersactionAngleOf3Latlon';

cache table temp_nr_cm_projdata as
WITH WGS84 AS (
    SELECT 
        6378137.0 AS a,          -- 长半轴
        0.00669437999014 AS e2   -- 第一偏心率平方
)
SELECT
    cellkey  AS reportcellkey,
    cm.gnbid AS enodebid,
    cellid   AS cid,
    ssbarfcn AS dl_earfcn,
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
    COALESCE(cm.subcarrierSpacing, cm.maxScs, 15) AS subcarrierSpacing,
    -- Calculate the radius of curvature of the meridian N = a / sqrt(1 - e²*sin²(lat))
    w.a / SQRT(1 - w.e2 * POWER(SIN(RADIANS(cm.celllat)), 2)) AS N,
    -- Calculate the radius of curvature of the meridian M = a*(1-e²) / (1-e²*sin²(lat))^(3/2)
    w.a * (1 - w.e2) / POWER(1 - w.e2 * POWER(SIN(RADIANS(cm.celllat)), 2), 1.5) AS M
FROM
    ( SELECT
          cellkey,
          gnbid,
          cellid,
          ssbarfcn,
          pci,
          citycode,
          districtcode,
          province,
          city,
          district,
          celllon,
          celllat,
          azimuth,
          subcarrierSpacing,
          MAX(subcarrierSpacing) OVER (PARTITION BY ssbarfcn) AS maxScs
      FROM
          spark_catalog.zxdmo.nr_cm_projdata
      WHERE
          p_provincecode = $nr_cm_projdata.p_provincecode$ ) cm
        INNER JOIN ( SELECT
                         nodebid
                     FROM
                         spark_catalog.zxdmo.bs_net_prenodebid_q
                     WHERE
                         p_provincecode = $bs_net_nrcoverage_base_q.p_provincecode$
                         AND p_date = '$bs_net_nrcoverage_base_q.p_date$'
                         AND p_hour = $bs_net_nrcoverage_base_q.p_hour$
                         AND p_quarter = $bs_net_nrcoverage_base_q.p_quarter$
                         AND network = 'NR'
                         AND nodebid IS NOT NULL ) prenodebid ON cm.gnbid = prenodebid.nodebid
        LEFT JOIN ( SELECT
                        gnbid,
                        distance
                    FROM
                        spark_catalog.zxdmo.dm_nr_intersitedistance
                    WHERE
                        p_provincecode = $dm_nr_intersitedistance.p_provincecode$ ) dis ON cm.gnbid = dis.gnbid
        CROSS JOIN WGS84 w
;

cache table temp_neigh_mr as
select /*+ UNCHECKED_FUNC(getdis,getazimuthangle,getanglediff,getintersactionangle) */
    mrkey,
    locationtype,
    positionmark,
    mrlon,
    mrlat,
    grid_three_column_20,
    grid_three_column_50,
    grid_three_column_100,
    mcc,
    mnc,
    enodebid,
    cid,
    searfcn,
    pci,
    srsrp,
    srsrq,
    nenodebid,
    ncellid,
    nearfcn,
    npci,
    nrsrp,
    nrsrq,
    nrscsssinr,
    nrncsinr,
    snearfcnflag,
    mod30ncellnumflag,
    mod30snpciflag,
    mod30snrsrpflag,
    mod30srsrpflag,
    overlapncellnumflag,
    overlapsnrsrpflag,
    overlapsrsrpflag,
    overshootmrscellangleflag,
    overshootmrtoscelldistnsflag,
    overshootmrtoscelldistssflag,
    overshootncellnumflag,
    overshootsnrsrpflag,
    overshootsrsrpflag,
    (case when mod30srsrpflag=1 and mod30snrsrpflag=1 and mod30snpciflag=1 and mod30ncellnumflag=1 then 1 else 0 end) as mod30,
    (case when overlapsnrsrpflag=1 and overlapsrsrpflag=1 and snearfcnflag=1 and overlapncellnumflag=1 then 1 else 0 end) as overlapped,
    (case when overshootsnrsrpflag=1 and overshootsrsrpflag=1 and snearfcnflag=1 and overshootmrtoscelldistssflag=1 and overshootmrtoscelldistnsflag=1 and overshootmrscellangleflag=1 and overshootncellnumflag=1 then 1 else 0 end) as overshoot
from
(
    select
        mrkey,
        locationtype,
        positionmark,
        mrlon,
        mrlat,
        grid_three_column_20,
        grid_three_column_50,
        grid_three_column_100,
        mcc,
        mnc,
        enodebid,
        cid,
        searfcn,
        pci,
        srsrp,
        srsrq,
        nenodebid,
        ncellid,
        nearfcn,
        npci,
        nrsrp,
        nrsrq,
        nrscsssinr,
        nrncsinr,
        snearfcnflag,
        mod30snpciflag,
        mod30snrsrpflag,
        mod30srsrpflag,
        overlapsnrsrpflag,
        overlapsrsrpflag,
        overshootmrtoscelldistnsflag,
        overshootmrtoscelldistssflag,
        overshootsnrsrpflag,
        overshootsrsrpflag,
        (case when (abs(smrangle) < #smranglethd# and abs(nmrangle) < #nmranglethd# and abs(sangle-nangle) < #scellandncellanglethd#) and ((abs(snmrangle) >= #snmranglethd# and abs(mrsnangle) < #mrsnanglethd#) or snmlatdifflon = 1) then 1 else 0 end) as overshootmrscellangleflag,
        (case when sum( case when (overshootsnrsrpflag=1 and snearfcnflag=1 and overshootmrtoscelldistnsflag=1 and abs(smrangle) < #smranglethd# and abs(nmrangle) < #nmranglethd# and abs(sangle-nangle) < #scellandncellanglethd#) and ((abs(snmrangle) >= #snmranglethd# and abs(mrsnangle) < #mrsnanglethd#) or snmlatdifflon = 1) then 1 else 0 end ) over(partition by mrkey, enodebid, cid) >= #overshootncellnum# then 1 else 0 end) as overshootncellnumflag,
        (case when sum( case when overlapsnrsrpflag=1 and snearfcnflag=1 then 1 else 0 end) over(partition by mrkey, enodebid, cid) >=  #overlapncellnum# then 1 else 0 end) as overlapncellnumflag,
        (case when sum(case when mod30snrsrpflag = 1 and mod30snpciflag = 1 then 1 else 0 end) over(partition by mrkey, enodebid, cid) >=  #mod30ncellnum# then 1 else 0 end) as mod30ncellnumflag
    from
    (
        select
            mrkey,
            locationtype,
            positionmark,
            mrlon,
            mrlat,
            grid_three_column_20,
            grid_three_column_50,
            grid_three_column_100,
            mcc,
            mnc,
            n2.enodebid,
            n2.cid,
            searfcn,
            pci,
            srsrp,
            srsrq,
            nenodebid,
            ncellid,
            nearfcn,
            npci,
            nrsrp,
            nrsrq,
            nrscsssinr,
            nrncsinr,
            snearfcnflag,
            mod30snrsrpflag,
            mod30srsrpflag,
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
            (case when snearfcnflag=1 and npci%30=pci%30 then 1 else 0 end) as mod30snpciflag
        from
        (
            select
                mrkey,
                locationtype,
                positionmark,
                mrlon,
                mrlat,
                grid_three_column_20,
                grid_three_column_50,
                grid_three_column_100,
                mcc,
                mnc,
                n1.enodebid,
                n1.cid,
                if(searfcn is null,c1.dl_earfcn,searfcn) as searfcn,
                c1.pci,
                srsrp,
                srsrq,
                nenodebid,
                ncellid,
                if(nearfcn is null,c2.dl_earfcn,nearfcn) as nearfcn,
                if(npci is null,c2.pci,npci) as npci,
                nrsrp,
                nrsrq,
                nrscsssinr,
                nrncsinr,
                c1.distance,
                c1.celllon as scelllon,
                c1.celllat as scelllat,
                c1.azimuth as sangle,
                c2.azimuth as nangle,
                c2.celllon as ncelllon,
                c2.celllat as ncelllat,
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
                (case when positionmark=0 and srsrp >= #ucrsrpthd_mod30_indoor# then 1 when (positionmark is null or positionmark!=0) and srsrp >=  #ucrsrpthd_mod30_outdoor# then 1 else 0 end) as mod30srsrpflag,
                (case when positionmark=0 and nrsrp - srsrp > #ucrsrpdifferthd_mod30_indoor# then 1 when (positionmark is null or positionmark!=0) and nrsrp - srsrp > #ucrsrpdifferthd_mod30_outdoor# then 1 else 0 end) as mod30snrsrpflag
            from
            (
                select
                    mrkey,
                    locationtype,
                    positionmark,
                    uelon as mrlon,
                    uelat as mrlat,
                    grid_three_column_20,
                    grid_three_column_50,
                    grid_three_column_100,
                    mcc,
                    mnc,
                    gnodebid as enodebid,
                    cid,
                    nrscarfcn as searfcn,
                    nrscssrsrp as srsrp,
                    nrscssrsrq as srsrq,
                    nrncgnodebid as nenodebid,
                    nrnccellid as ncellid,
                    nrncarfcn as nearfcn,
                    nrncpci as npci,
                    nrncrsrp as nrsrp,
                    nrncrsrq as nrsrq,
                    nrscsssinr,
                    nrncsinr,
                    nrscssrsrp-nrncrsrp as snrsrpdiff
                 from $nr_nbrinfo_ex$
                where p_provincecode=$nr_nbrinfo_ex.p_provincecode$
                  and p_date='$nr_nbrinfo_ex.p_date$'
                  and p_hour=$nr_nbrinfo_ex.p_hour$
                  and p_quarter=$nr_nbrinfo_ex.p_quarter$
                  and p_region=$nr_nbrinfo_ex.p_region$
            ) n1
                INNER JOIN temp_nr_cm_projdata c1
            on n1.enodebid=c1.enodebid and n1.cid=c1.cid
                LEFT JOIN (
                SELECT
                    gnbid as enodebid,
                    cellid as cid,
                    ssbarfcn as dl_earfcn,
                    pci,
                    celllon,
                    celllat,
                    azimuth
                FROM spark_catalog.zxdmo.nr_cm_projdata
                WHERE p_provincecode = $nr_cm_projdata.p_provincecode$
            ) c2
            on n1.nenodebid=c2.enodebid and n1.ncellid=c2.cid
        ) n2
    ) n3
) n4
;


insert overwrite table $bs_net_nrcoverage_base_q$
    partition(
        p_provincecode=$bs_net_nrcoverage_base_q.p_provincecode$,
        p_date='$bs_net_nrcoverage_base_q.p_date$',
        p_hour=$bs_net_nrcoverage_base_q.p_hour$,
        p_quarter=$bs_net_nrcoverage_base_q.p_quarter$)
-- MR Data
with temp_mrdataAll as (
    select
        gnodebid as enodebid,
        s1.cid,
        if(s1.nrscarfcn is null,c.dl_earfcn,s1.nrscarfcn) as dlearfcn,
        if(s1.nrscpci is null,c.pci,s1.nrscpci) as pci,
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
        nrscssrsrp as rsrp,
        nrscssrsrq as rsrq,
        uelon as mrlon,
        uelat as mrlat,
        (case when uelat is not null and uelon is not null and c.celllat is not null and c.celllon is not null then cast(getdis(cast(uelat as double),cast(uelon as double),c.celllat,c.celllon) as double) else null end) as scellmrdis,
        nrscsssinr,
        ulsinr,
        cqi0,
        puschprbnum,
        pdschprbnum,
        puschprbtotalnum,
        pdschprbtotalnum,
        dlpdcpsendvolumesum,
        ulpdcprcvvolumesum,
        ulRlcSduVolumeWithoutLastPieceSum,
        dlRlcSduVolumeWithoutLastPieceSum,
        ulRlcTimeLenSum,
        dlRlcTimeLenSum,
        isoverlap,
        isovershoot,
        ismod30interfer,
        subcarrierSpacing * distance as scsd,
        ta,
        case
            when c.azimuth = 360 then null
            when hdoa is not null then hdoa
            else
            (
                PMOD(
                    DEGREES(
                        ATAN2(
                            -- Distance in X direction(m) = Arc length per degree of longitude * Longitude difference = (π/180) * N * cos(lat) * lon
                            (PI() / 180.0) * c.N * COS(RADIANS(uelat)) * (uelon - celllon),
                            -- Distance in Y direction(m) = Arc length per degree of latitude * Latitude difference = (π/180) * M * lat
                            (PI() / 180.0) * c.M * (uelat - celllat)
                        )
                    ) - azimuth + 180, 360
                ) - 180
            )
        end as hdoa
     from
     (
        select
            mrkey,
            gnodebid,
            cid,
            nrscpci,
            nrscarfcn,
            nrscssrsrp,
            nrscssrsrq,
            nrscsssinr,
            uelat,
            uelon,
            earthid,
            locationtype,
            positionmark,
            grid_three_column_20,
            grid_three_column_50,
            grid_three_column_100,
            mcc,
            mnc,
            puschprbnum,
            pdschprbnum,
            puschprbtotalnum,
            pdschprbtotalnum,
            dlpdcpsendvolumesum,
            ulpdcprcvvolumesum,
            ulRlcSduVolumeWithoutLastPieceSum,
            dlRlcSduVolumeWithoutLastPieceSum,
            ulRlcTimeLenSum,
            dlRlcTimeLenSum,
            ulsinr,
            cqi0,
            ta,
            hdoa
         from $nr_t054_ex$
        where p_provincecode=$nr_t054_ex.p_provincecode$
          and p_date='$nr_t054_ex.p_date$'
          and p_hour=$nr_t054_ex.p_hour$
          and p_quarter=$nr_t054_ex.p_quarter$
          and p_region=$nr_t054_ex.p_region$
     ) s1
         INNER JOIN temp_nr_cm_projdata c
       on concat(s1.gnodebid,'_',s1.cid)=c.reportcellkey
         LEFT JOIN
     (
         select
             mrkey,
             enodebid,
             cid,
             (case when sum(overlapped) > 0 then 1 else 0 end) as isoverlap,
             (case when sum(overshoot) > 0 then 1 else 0 end) as isovershoot,
             (case when sum(mod30) > 0 then 1 else 0 end) as ismod30interfer
          from temp_neigh_mr r
         group by mrkey, enodebid, cid
     ) f
       on s1.mrkey=f.mrkey and s1.gnodebid=f.enodebid and s1.cid=f.cid
),
temp_mrdata_hdoaCorrection as (
    select
        enodebid,
        cid,
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
        nrscsssinr,
        ulsinr,
        cqi0,
        puschprbnum,
        pdschprbnum,
        puschprbtotalnum,
        pdschprbtotalnum,
        dlpdcpsendvolumesum,
        ulpdcprcvvolumesum,
        ulRlcSduVolumeWithoutLastPieceSum,
        dlRlcSduVolumeWithoutLastPieceSum,
        ulRlcTimeLenSum,
        dlRlcTimeLenSum,
        isoverlap,
        isovershoot,
        ismod30interfer,
        scsd,
        ta,
        hdoa
    from(
        select 
            enodebid, cid, dlearfcn, pci, citycode, districtcode, province, city, district, mcc, mnc, 
            earthid, grid_three_column_20, grid_three_column_50, grid_three_column_100, locationtype, positionmark, 
            rsrp, rsrq, mrlon, mrlat, scellmrdis, nrscsssinr, ulsinr, cqi0, puschprbnum, pdschprbnum, puschprbtotalnum, pdschprbtotalnum, 
            dlpdcpsendvolumesum, ulpdcprcvvolumesum, ulRlcSduVolumeWithoutLastPieceSum, dlRlcSduVolumeWithoutLastPieceSum, 
            ulRlcTimeLenSum, dlRlcTimeLenSum, isoverlap, isovershoot, ismod30interfer, scsd, ta,
            hdoa
        from temp_mrdataAll
    ) h 
)
select
    '$bs_net_nrcoverage_base_q.p_date$' as `day`,
    $bs_net_nrcoverage_base_q.p_hour$ as `hour`,
    $bs_net_nrcoverage_base_q.p_quarter$ as quarter,
    concat(enodebid,'_',cid) as cellkey,
    enodebid as gnbid,
    cid as cellid,
    dlearfcn as ssbarfcn,
    pci,
    $bs_net_nrcoverage_base_q.p_provincecode$ as provincecode,
    citycode,
    districtcode,
    province,
    city,
    district,
    mcc,
    lpad(mnc, 2, '0') as mnc,
    earthid as regionid,
    cast(split(grid_three_column_100,'\\044')[1] as int) as x_offset_100,
    cast(split(grid_three_column_100,'\\044')[2] as int) as y_offset_100,
    cast(split(grid_three_column_50,'\\044')[1] as int) as x_offset_50,
    cast(split(grid_three_column_50,'\\044')[2] as int) as y_offset_50,
    cast(split(grid_three_column_20,'\\044')[1] as int) as x_offset_20,
    cast(split(grid_three_column_20,'\\044')[2] as int) as y_offset_20,
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
    sum(if(rsrp>=-157 and rsrp<=-30,rsrp,null)) as totalssrsrp,
    count(if(rsrp>=-157 and rsrp<=-30,1,null)) as ssrsrpcount,
    count(if((positionmark=0 and rsrp>=#host_mr_goodrsrp_indoor#) or ((positionmark is null or positionmark!=0) and rsrp>=#host_mr_goodrsrp_outdoor#),1,null)) as ssrsrpgoodcount,
    sum(rsrq) as totalssrsrq,
    count(rsrq) as ssrsrqcount,
    count(if((positionmark=0 and rsrq>=#host_mr_goodrsrq_indoor#) or ((positionmark is null or positionmark!=0) and rsrq>=#host_mr_goodrsrq_outdoor#),1,null)) as ssrsrqgoodcount,
    sum(nrscsssinr) as totalsssinr,
    count(nrscsssinr) as sssinrcount,
    count(if((positionmark=0 and nrscsssinr>=#host_mr_gooddlsinr_indoor#) or ((positionmark is null or positionmark!=0) and nrscsssinr>=#host_mr_gooddlsinr_outdoor#),1,null)) as sssinrgoodcount,
    count(if((rsrp is not null and nrscsssinr is not null),1,null)) as compcovvalid_mrcount,
    count(if((positionmark=0 and rsrp>=#host_dlcovrate_goodrsrp_indoor# and nrscsssinr>=#host_dlcovrate_gooddlsinr_indoor#) or ((positionmark is null or positionmark!=0) and rsrp>=#host_dlcovrate_goodrsrp_outdoor# and nrscsssinr>=#host_dlcovrate_gooddlsinr_outdoor#),1,null)) as compcovgood_mrcount,
    count(1) as period_totalmrcount,
    count(if((positionmark=0 and rsrp<#host_weakcovrsrp_indoor_thd#) or ((positionmark is null or positionmark!=0) and rsrp<#host_weakcovrsrp_outdoor_thd#),1,null)) as weakcover_mrcount,
    sum(isoverlap) as overlap_mrcount, -- isxxx flag is 1 or 0
    sum(isovershoot) as overshoot_mrcount, -- isxxx flag is 1 or 0
    sum(ismod30interfer) as mod30interfer_mrcount, -- isxxx flag is 1 or 0
    sum(puschprbnum) as puschprbnum,
    sum(pdschprbnum) as pdschprbnum,
    sum(puschprbtotalnum) as puschprbtotalnum,
    sum(pdschprbtotalnum) as pdschprbtotalnum,
    SUM(CASE WHEN ta * 1170 > #tafarsitedisthrd# * scsd THEN 1 ELSE 0 END) as tafar_count,
    sum(dlpdcpsendvolumesum) as dlpdcpsendvolumesum,
    sum(ulpdcprcvvolumesum) as ulpdcprcvvolumesum,
    sum(ulRlcSduVolumeWithoutLastPieceSum) as ulRlcSduVolumeWithoutLastPieceSum,
    sum(dlRlcSduVolumeWithoutLastPieceSum) as dlRlcSduVolumeWithoutLastPieceSum,
    sum(ulRlcTimeLenSum) as ulRlcTimeLenSum,
    sum(dlRlcTimeLenSum) as dlRlcTimeLenSum,
    count(if(hdoa is not null and hdoa > #abnormalbound#, hdoa,null)) as azimuthinvalid_mrcount,
    count(if(hdoa is not null and hdoa <= #alignbound#, hdoa,null)) as azimuthalign_mrcount,
    sum(ta) as totalta,
    count(ta) as tacount,
    sum(ulsinr) as totalulsinr,
    count(ulsinr) as ulsinrcount,
    sum(cqi0) as totalcqi0,
    count(cqi0) as cqi0count,
    count(dlpdcpsendvolumesum) as dlpdcpsendvolumesumcount,
    count(ulpdcprcvvolumesum) as ulpdcprcvvolumesumcount
from temp_mrdata_hdoaCorrection s2
group by enodebid,cid,dlearfcn,pci,citycode,districtcode,province,city,district,mcc,mnc,earthid,grid_three_column_20,grid_three_column_50,grid_three_column_100,locationtype,positionmark
;

uncache table temp_nr_cm_projdata;
uncache table temp_neigh_mr;
