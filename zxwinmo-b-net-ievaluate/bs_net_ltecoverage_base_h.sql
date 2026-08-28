INSERT OVERWRITE TABLE $bs_net_ltecoverage_base_h$ PARTITION (p_provincecode=$bs_net_ltecoverage_base_h.p_provincecode$, p_date='$bs_net_ltecoverage_base_h.p_date$', p_hour=$bs_net_ltecoverage_base_h.p_hour$)
SELECT day AS day, hour AS hour, cellkey AS cellkey, enodebid AS enodebid, cellid AS cellid
	, rattypeid AS rattypeid, dlearfcn AS dlearfcn, pci AS pci, provincecode AS provincecode, citycode AS citycode
	, districtcode AS districtcode, province AS province, city AS city, district AS district, mcc AS mcc
	, mnc AS mnc, regionid AS regionid, x_offset_100 AS x_offset_100, y_offset_100 AS y_offset_100, x_offset_50 AS x_offset_50
	, y_offset_50 AS y_offset_50, x_offset_20 AS x_offset_20, y_offset_20 AS y_offset_20, locationaccuracytype AS locationaccuracytype, positionmark AS positionmark
	, SUM(CASE 
		WHEN totalmrlon IS NOT NULL THEN totalmrlon
		ELSE NULL
	END) AS totalmrlon, SUM(CASE 
		WHEN totalmrlat IS NOT NULL THEN totalmrlat
		ELSE NULL
	END) AS totalmrlat
	, SUM(CASE 
		WHEN validlonlat_totalmrcount IS NOT NULL THEN validlonlat_totalmrcount
		ELSE NULL
	END) AS validlonlat_totalmrcount, SUM(CASE 
		WHEN celmr_totaldis IS NOT NULL THEN celmr_totaldis
		ELSE NULL
	END) AS celmr_totaldis
	, SUM(CASE 
		WHEN celmr_discount IS NOT NULL THEN celmr_discount
		ELSE NULL
	END) AS celmr_discount, SUM(CASE 
		WHEN totalrsrp IS NOT NULL THEN totalrsrp
		ELSE NULL
	END) AS totalrsrp
	, SUM(CASE 
		WHEN rsrpcount IS NOT NULL THEN rsrpcount
		ELSE NULL
	END) AS rsrpcount, SUM(CASE 
		WHEN rsrpgoodcount IS NOT NULL THEN rsrpgoodcount
		ELSE NULL
	END) AS rsrpgoodcount
	, SUM(CASE 
		WHEN validlonlat_totalrsrp IS NOT NULL THEN validlonlat_totalrsrp
		ELSE NULL
	END) AS validlonlat_totalrsrp, SUM(CASE 
		WHEN validlonlatrsrp_totalmrcount IS NOT NULL THEN validlonlatrsrp_totalmrcount
		ELSE NULL
	END) AS validlonlatrsrp_totalmrcount
	, SUM(CASE 
		WHEN validta_totalrsrp IS NOT NULL THEN validta_totalrsrp
		ELSE NULL
	END) AS validta_totalrsrp, SUM(CASE 
		WHEN validta_totalmrcount IS NOT NULL THEN validta_totalmrcount
		ELSE NULL
	END) AS validta_totalmrcount
	, SUM(CASE 
		WHEN validlonlatta_totalrsrp IS NOT NULL THEN validlonlatta_totalrsrp
		ELSE NULL
	END) AS validlonlatta_totalrsrp, SUM(CASE 
		WHEN validlonlatta_totalmrcount IS NOT NULL THEN validlonlatta_totalmrcount
		ELSE NULL
	END) AS validlonlatta_totalmrcount
	, SUM(CASE 
		WHEN totalrsrq IS NOT NULL THEN totalrsrq
		ELSE NULL
	END) AS totalrsrq, SUM(CASE 
		WHEN rsrqcount IS NOT NULL THEN rsrqcount
		ELSE NULL
	END) AS rsrqcount
	, SUM(CASE 
		WHEN rsrqgoodcount IS NOT NULL THEN rsrqgoodcount
		ELSE NULL
	END) AS rsrqgoodcount, SUM(CASE 
		WHEN totalulsinr IS NOT NULL THEN totalulsinr
		ELSE NULL
	END) AS totalulsinr
	, SUM(CASE 
		WHEN ulsinrcount IS NOT NULL THEN ulsinrcount
		ELSE NULL
	END) AS ulsinrcount, SUM(CASE 
		WHEN ulsinrgoodcount IS NOT NULL THEN ulsinrgoodcount
		ELSE NULL
	END) AS ulsinrgoodcount
	, SUM(CASE 
		WHEN compulcovgood_mrcount IS NOT NULL THEN compulcovgood_mrcount
		ELSE NULL
	END) AS compulcovgood_mrcount, SUM(CASE 
		WHEN compulcovvalid_mrcount IS NOT NULL THEN compulcovvalid_mrcount
		ELSE NULL
	END) AS compulcovvalid_mrcount
	, SUM(CASE 
		WHEN period_totalmrcount IS NOT NULL THEN period_totalmrcount
		ELSE NULL
	END) AS period_totalmrcount, SUM(CASE 
		WHEN weakcover_mrcount IS NOT NULL THEN weakcover_mrcount
		ELSE NULL
	END) AS weakcover_mrcount
	, SUM(CASE 
		WHEN overlap_mrcount IS NOT NULL THEN overlap_mrcount
		ELSE NULL
	END) AS overlap_mrcount, SUM(CASE 
		WHEN overshoot_mrcount IS NOT NULL THEN overshoot_mrcount
		ELSE NULL
	END) AS overshoot_mrcount
	, SUM(CASE 
		WHEN mod3interfer_mrcount IS NOT NULL THEN mod3interfer_mrcount
		ELSE NULL
	END) AS mod3interfer_mrcount, SUM(CASE 
		WHEN puschprbnum IS NOT NULL THEN puschprbnum
		ELSE NULL
	END) AS puschprbnum
	, SUM(CASE 
		WHEN pdschprbnum IS NOT NULL THEN pdschprbnum
		ELSE NULL
	END) AS pdschprbnum, SUM(CASE 
		WHEN puschuseprbnum IS NOT NULL THEN puschuseprbnum
		ELSE NULL
	END) AS puschuseprbnum
	, SUM(CASE 
		WHEN pdschuseprbnum IS NOT NULL THEN pdschuseprbnum
		ELSE NULL
	END) AS pdschuseprbnum, SUM(CASE 
		WHEN puschavailprbnum IS NOT NULL THEN puschavailprbnum
		ELSE NULL
	END) AS puschavailprbnum
	, SUM(CASE 
		WHEN pdschavailprbnum IS NOT NULL THEN pdschavailprbnum
		ELSE NULL
	END) AS pdschavailprbnum, SUM(CASE 
		WHEN sumuetputpuschprbnum IS NOT NULL THEN sumuetputpuschprbnum
		ELSE NULL
	END) AS sumuetputpuschprbnum
	, SUM(CASE 
		WHEN sumuetputpdschprbnum IS NOT NULL THEN sumuetputpdschprbnum
		ELSE NULL
	END) AS sumuetputpdschprbnum, SUM(CASE 
		WHEN validlonlat_totalallerabpdcptput IS NOT NULL THEN validlonlat_totalallerabpdcptput
		ELSE NULL
	END) AS validlonlat_totalallerabpdcptput
	, SUM(CASE 
		WHEN validlonlat_totalallerabulpdcptput IS NOT NULL THEN validlonlat_totalallerabulpdcptput
		ELSE NULL
	END) AS validlonlat_totalallerabulpdcptput, SUM(CASE 
		WHEN validlonlat_totalallerabdlpdcptput IS NOT NULL THEN validlonlat_totalallerabdlpdcptput
		ELSE NULL
	END) AS validlonlat_totalallerabdlpdcptput
	, SUM(CASE 
		WHEN validlonlat_totalallerabdlpdcptput_aoa0_30 IS NOT NULL THEN validlonlat_totalallerabdlpdcptput_aoa0_30
		ELSE NULL
	END) AS validlonlat_totalallerabdlpdcptput_aoa0_30, SUM(CASE 
		WHEN validlonlat_totalallerabdlpdcptput_aoa30_60 IS NOT NULL THEN validlonlat_totalallerabdlpdcptput_aoa30_60
		ELSE NULL
	END) AS validlonlat_totalallerabdlpdcptput_aoa30_60
	, SUM(CASE 
		WHEN validlonlat_totalallerabdlpdcptput_aoa60_90 IS NOT NULL THEN validlonlat_totalallerabdlpdcptput_aoa60_90
		ELSE NULL
	END) AS validlonlat_totalallerabdlpdcptput_aoa60_90, SUM(CASE 
		WHEN validlonlat_totalallerabdlpdcptput_aoa90_120 IS NOT NULL THEN validlonlat_totalallerabdlpdcptput_aoa90_120
		ELSE NULL
	END) AS validlonlat_totalallerabdlpdcptput_aoa90_120
	, SUM(CASE 
		WHEN validlonlat_totalallerabdlpdcptput_aoa120_150 IS NOT NULL THEN validlonlat_totalallerabdlpdcptput_aoa120_150
		ELSE NULL
	END) AS validlonlat_totalallerabdlpdcptput_aoa120_150, SUM(CASE 
		WHEN validlonlat_totalallerabdlpdcptput_aoa150_180 IS NOT NULL THEN validlonlat_totalallerabdlpdcptput_aoa150_180
		ELSE NULL
	END) AS validlonlat_totalallerabdlpdcptput_aoa150_180
	, SUM(CASE 
		WHEN validlonlat_totalallerabdlpdcptput_aoa180_210 IS NOT NULL THEN validlonlat_totalallerabdlpdcptput_aoa180_210
		ELSE NULL
	END) AS validlonlat_totalallerabdlpdcptput_aoa180_210, SUM(CASE 
		WHEN validlonlat_totalallerabdlpdcptput_aoa210_240 IS NOT NULL THEN validlonlat_totalallerabdlpdcptput_aoa210_240
		ELSE NULL
	END) AS validlonlat_totalallerabdlpdcptput_aoa210_240
	, SUM(CASE 
		WHEN validlonlat_totalallerabdlpdcptput_aoa240_270 IS NOT NULL THEN validlonlat_totalallerabdlpdcptput_aoa240_270
		ELSE NULL
	END) AS validlonlat_totalallerabdlpdcptput_aoa240_270, SUM(CASE 
		WHEN validlonlat_totalallerabdlpdcptput_aoa270_300 IS NOT NULL THEN validlonlat_totalallerabdlpdcptput_aoa270_300
		ELSE NULL
	END) AS validlonlat_totalallerabdlpdcptput_aoa270_300
	, SUM(CASE 
		WHEN validlonlat_totalallerabdlpdcptput_aoa300_330 IS NOT NULL THEN validlonlat_totalallerabdlpdcptput_aoa300_330
		ELSE NULL
	END) AS validlonlat_totalallerabdlpdcptput_aoa300_330, SUM(CASE 
		WHEN validlonlat_totalallerabdlpdcptput_aoa330_360 IS NOT NULL THEN validlonlat_totalallerabdlpdcptput_aoa330_360
		ELSE NULL
	END) AS validlonlat_totalallerabdlpdcptput_aoa330_360
    , SUM(tafar_count) tafar_count
    , SUM(allerabulpdcptput) as allerabulpdcptput
    , SUM(allerabdlpdcptput) as allerabdlpdcptput
    , SUM(sumulpdcpwithoutlastpiece) as sumulpdcpwithoutlastpiece
    , SUM(sumdlpdcpwithoutlastpiece) as sumdlpdcpwithoutlastpiece
    , SUM(sumulpdcperabtimerlen) as sumulpdcperabtimerlen
    , SUM(sumdlpdcperabtimerlen) as sumdlpdcperabtimerlen
    , sum(azimuthinvalid_mrcount) as azimuthinvalid_mrcount
    , sum(azimuthalign_mrcount) as azimuthalign_mrcount
    , sum(totalta) as totalta
    , sum(tacount) as tacount
    , sum(beforetherotysinrcount) as beforetherotysinrcount
    , sum(totalbeforetherotysinr) as totalbeforetherotysinr
    , sum(totalcqi0) as totalcqi0
    , sum(cqi0count) as cqi0count
    , sum(totalulmcs) as totalulmcs
    , sum(ulmcscount) as ulmcscount
    , sum(totaldlmcs) as totaldlmcs
    , sum(dlmcscount) as dlmcscount
    , sum(allerabulpdcptputcount) as allerabulpdcptputcount
    , sum(allerabdlpdcptputcount) as allerabdlpdcptputcount
FROM $bs_net_ltecoverage_base_q$
WHERE p_provincecode = $bs_net_ltecoverage_base_q.p_provincecode$
	AND p_date = '$bs_net_ltecoverage_base_q.p_date$'
	AND p_hour = $bs_net_ltecoverage_base_q.p_hour$
GROUP BY day, hour, cellkey, enodebid, cellid, rattypeid, dlearfcn, pci, provincecode, citycode, districtcode, province, city, district, mcc, mnc, regionid, x_offset_100, y_offset_100, x_offset_50, y_offset_50, x_offset_20, y_offset_20, locationaccuracytype, positionmark, p_provincecode, p_date, p_hour