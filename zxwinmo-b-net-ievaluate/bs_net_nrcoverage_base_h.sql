INSERT OVERWRITE TABLE $bs_net_nrcoverage_base_h$ PARTITION (p_provincecode=$bs_net_nrcoverage_base_h.p_provincecode$, p_date='$bs_net_nrcoverage_base_h.p_date$', p_hour=$bs_net_nrcoverage_base_h.p_hour$)
SELECT day AS day, hour AS hour, cellkey AS cellkey, gnbid AS gnbid, cellid AS cellid
	, ssbarfcn AS ssbarfcn, pci AS pci, provincecode AS provincecode, citycode AS citycode, districtcode AS districtcode
	, province AS province, city AS city, district AS district, mcc AS mcc, mnc AS mnc
	, regionid AS regionid, x_offset_100 AS x_offset_100, y_offset_100 AS y_offset_100, x_offset_50 AS x_offset_50, y_offset_50 AS y_offset_50
	, x_offset_20 AS x_offset_20, y_offset_20 AS y_offset_20, locationaccuracytype AS locationaccuracytype, positionmark AS positionmark
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
		WHEN totalssrsrp IS NOT NULL THEN totalssrsrp
		ELSE NULL
	END) AS totalssrsrp
	, SUM(CASE 
		WHEN ssrsrpcount IS NOT NULL THEN ssrsrpcount
		ELSE NULL
	END) AS ssrsrpcount, SUM(CASE 
		WHEN ssrsrpgoodcount IS NOT NULL THEN ssrsrpgoodcount
		ELSE NULL
	END) AS ssrsrpgoodcount
	, SUM(CASE 
		WHEN totalssrsrq IS NOT NULL THEN totalssrsrq
		ELSE NULL
	END) AS totalssrsrq, SUM(CASE 
		WHEN ssrsrqcount IS NOT NULL THEN ssrsrqcount
		ELSE NULL
	END) AS ssrsrqcount
	, SUM(CASE 
		WHEN ssrsrqgoodcount IS NOT NULL THEN ssrsrqgoodcount
		ELSE NULL
	END) AS ssrsrqgoodcount, SUM(CASE 
		WHEN totalsssinr IS NOT NULL THEN totalsssinr
		ELSE NULL
	END) AS totalsssinr
	, SUM(CASE 
		WHEN sssinrcount IS NOT NULL THEN sssinrcount
		ELSE NULL
	END) AS sssinrcount, SUM(CASE 
		WHEN sssinrgoodcount IS NOT NULL THEN sssinrgoodcount
		ELSE NULL
	END) AS sssinrgoodcount
	, SUM(CASE 
		WHEN compcovvalid_mrcount IS NOT NULL THEN compcovvalid_mrcount
		ELSE NULL
	END) AS compcovvalid_mrcount, SUM(CASE 
		WHEN compcovgood_mrcount IS NOT NULL THEN compcovgood_mrcount
		ELSE NULL
	END) AS compcovgood_mrcount
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
		WHEN mod30interfer_mrcount IS NOT NULL THEN mod30interfer_mrcount
		ELSE NULL
	END) AS mod30interfer_mrcount, SUM(CASE 
		WHEN puschprbnum IS NOT NULL THEN puschPrbNum
		ELSE NULL
	END) AS puschPrbNum
	, SUM(CASE 
		WHEN pdschprbnum IS NOT NULL THEN pdschPrbNum
		ELSE NULL
	END) AS pdschPrbNum, SUM(CASE 
		WHEN puschPrbTotalNum IS NOT NULL THEN puschPrbTotalNum
		ELSE NULL
	END) AS puschPrbTotalNum
	, SUM(CASE 
		WHEN puschPrbTotalNum IS NOT NULL THEN pdschPrbTotalNum
		ELSE NULL
	END) AS pdschPrbTotalNum
    , SUM(tafar_count) tafar_count
    , SUM(dlpdcpsendvolumesum) as dlpdcpsendvolumesum
    , SUM(ulpdcprcvvolumesum) as ulpdcprcvvolumesum
    , SUM(ulRlcSduVolumeWithoutLastPieceSum) as ulRlcSduVolumeWithoutLastPieceSum
    , SUM(dlRlcSduVolumeWithoutLastPieceSum) as dlRlcSduVolumeWithoutLastPieceSum
    , SUM(ulRlcTimeLenSum) as ulRlcTimeLenSum
    , SUM(dlRlcTimeLenSum) as dlRlcTimeLenSum
    , sum(azimuthinvalid_mrcount) as azimuthinvalid_mrcount
    , sum(azimuthalign_mrcount) as azimuthalign_mrcount
FROM $bs_net_nrcoverage_base_q$
WHERE p_provincecode = $bs_net_nrcoverage_base_q.p_provincecode$
	AND p_date = '$bs_net_nrcoverage_base_q.p_date$'
	AND p_hour = $bs_net_nrcoverage_base_q.p_hour$
GROUP BY day, hour, cellkey, gnbid, cellid, ssbarfcn, pci, provincecode, citycode, districtcode, province, city, district, mcc, mnc, regionid, x_offset_100, y_offset_100, x_offset_50, y_offset_50, x_offset_20, y_offset_20, locationaccuracytype, positionmark, p_provincecode, p_date, p_hour