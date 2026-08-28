INSERT OVERWRITE TABLE $bs_net_nrcoverage_base_d$ PARTITION (p_provincecode=$bs_net_nrcoverage_base_d.p_provincecode$, p_date='$bs_net_nrcoverage_base_d.p_date$')
SELECT day, cellkey, gnbid, cellid, ssbarfcn
	, pci, provincecode, citycode, districtcode, province
	, city, district, mcc, mnc, regionid
	, x_offset_100, y_offset_100, x_offset_50, y_offset_50, x_offset_20
	, y_offset_20, locationaccuracytype, positionmark, totalmrlon, totalmrlat
	, validlonlat_totalmrcount, celmr_totaldis, celmr_discount, totalssrsrp, ssrsrpcount
	, ssrsrpgoodcount, totalssrsrq, ssrsrqcount, ssrsrqgoodcount, totalsssinr
	, sssinrcount, sssinrgoodcount, compcovvalid_mrcount, compcovgood_mrcount, period_totalmrcount
	, weakcover_mrcount, overlap_mrcount, overshoot_mrcount, mod30interfer_mrcount, puschPrbNum
	, pdschPrbNum, puschPrbTotalNum, pdschPrbTotalNum, tafar_count
    , dlpdcpsendvolumesum, ulpdcprcvvolumesum, ulRlcSduVolumeWithoutLastPieceSum, dlRlcSduVolumeWithoutLastPieceSum, ulRlcTimeLenSum, dlRlcTimeLenSum
    , azimuthinvalid_mrcount, azimuthalign_mrcount
    , totalta, tacount, totalulsinr, ulsinrcount, totalcqi0, cqi0count
    , dlpdcpsendvolumesumcount, ulpdcprcvvolumesumcount
FROM (
	SELECT g0.day AS day, g0.cellkey AS cellkey, g0.gnbid AS gnbid, g0.cellid AS cellid, g0.ssbarfcn AS ssbarfcn
		, g0.pci AS pci, g0.provincecode AS provincecode, g0.citycode AS citycode, g0.districtcode AS districtcode, g0.province AS province
		, g0.city AS city, g0.district AS district, g0.mcc AS mcc, g0.mnc AS mnc, g0.regionid AS regionid
		, g0.x_offset_100 AS x_offset_100, g0.y_offset_100 AS y_offset_100, g0.x_offset_50 AS x_offset_50, g0.y_offset_50 AS y_offset_50, g0.x_offset_20 AS x_offset_20
		, g0.y_offset_20 AS y_offset_20, g0.locationaccuracytype AS locationaccuracytype, g0.positionmark AS positionmark, SUM(g0.totalmrlon) AS totalmrlon
		, SUM(g0.totalmrlat) AS totalmrlat, SUM(g0.validlonlat_totalmrcount) AS validlonlat_totalmrcount
		, SUM(g0.celmr_totaldis) AS celmr_totaldis, SUM(g0.celmr_discount) AS celmr_discount
		, SUM(g0.totalssrsrp) AS totalssrsrp, SUM(g0.ssrsrpcount) AS ssrsrpcount
		, SUM(g0.ssrsrpgoodcount) AS ssrsrpgoodcount, SUM(g0.totalssrsrq) AS totalssrsrq
		, SUM(g0.ssrsrqcount) AS ssrsrqcount, SUM(g0.ssrsrqgoodcount) AS ssrsrqgoodcount
		, SUM(g0.totalsssinr) AS totalsssinr, SUM(g0.sssinrcount) AS sssinrcount
		, SUM(g0.sssinrgoodcount) AS sssinrgoodcount, SUM(g0.compcovvalid_mrcount) AS compcovvalid_mrcount
		, SUM(g0.compcovgood_mrcount) AS compcovgood_mrcount, SUM(g0.period_totalmrcount) AS period_totalmrcount
		, SUM(g0.weakcover_mrcount) AS weakcover_mrcount, SUM(g0.overlap_mrcount) AS overlap_mrcount
		, SUM(g0.overshoot_mrcount) AS overshoot_mrcount, SUM(g0.mod30interfer_mrcount) AS mod30interfer_mrcount
		, SUM(g0.puschPrbNum) AS puschPrbNum, SUM(g0.pdschPrbNum) AS pdschPrbNum
		, SUM(g0.puschPrbTotalNum) AS puschPrbTotalNum, SUM(g0.pdschPrbTotalNum) AS pdschPrbTotalNum
		, g0.p_provincecode AS p_provincecode, g0.p_date AS p_date
        , SUM(g0.tafar_count) tafar_count
        , SUM(g0.dlpdcpsendvolumesum) AS dlpdcpsendvolumesum, SUM(g0.ulpdcprcvvolumesum) AS ulpdcprcvvolumesum
        , SUM(g0.ulRlcSduVolumeWithoutLastPieceSum) AS ulRlcSduVolumeWithoutLastPieceSum, SUM(g0.dlRlcSduVolumeWithoutLastPieceSum) AS dlRlcSduVolumeWithoutLastPieceSum
        , SUM(g0.ulRlcTimeLenSum) AS ulRlcTimeLenSum, SUM(g0.dlRlcTimeLenSum) AS dlRlcTimeLenSum
        , sum(azimuthinvalid_mrcount) as azimuthinvalid_mrcount
        , sum(azimuthalign_mrcount) as azimuthalign_mrcount
        , sum(g0.totalta) as totalta
        , sum(g0.tacount) as tacount
        , sum(g0.totalulsinr) as totalulsinr
        , sum(g0.ulsinrcount) as ulsinrcount
        , sum(g0.totalcqi0) as totalcqi0
        , sum(g0.cqi0count) as cqi0count
        , sum(g0.dlpdcpsendvolumesumcount) as dlpdcpsendvolumesumcount
        , sum(g0.ulpdcprcvvolumesumcount) as ulpdcprcvvolumesumcount
	FROM (
		SELECT day, cellkey, gnbid, cellid, ssbarfcn
			, pci, provincecode, citycode, districtcode, province
			, city, district, mcc, mnc, regionid
			, x_offset_100, y_offset_100, x_offset_50, y_offset_50, x_offset_20
			, y_offset_20, locationaccuracytype, positionmark, totalmrlon, totalmrlat
			, validlonlat_totalmrcount, celmr_totaldis, celmr_discount, totalssrsrp, ssrsrpcount
			, ssrsrpgoodcount, totalssrsrq, ssrsrqcount, ssrsrqgoodcount, totalsssinr
			, sssinrcount, sssinrgoodcount, compcovvalid_mrcount, compcovgood_mrcount, period_totalmrcount
			, weakcover_mrcount, overlap_mrcount, overshoot_mrcount, mod30interfer_mrcount, puschPrbNum
			, pdschPrbNum, puschPrbTotalNum, pdschPrbTotalNum, p_provincecode, p_date, tafar_count
            , dlpdcpsendvolumesum, ulpdcprcvvolumesum, ulRlcSduVolumeWithoutLastPieceSum, dlRlcSduVolumeWithoutLastPieceSum, ulRlcTimeLenSum, dlRlcTimeLenSum
            , azimuthinvalid_mrcount, azimuthalign_mrcount
            , totalta, tacount, totalulsinr, ulsinrcount, totalcqi0, cqi0count, dlpdcpsendvolumesumcount, ulpdcprcvvolumesumcount
		FROM $bs_net_nrcoverage_base_h$
		WHERE p_provincecode = $bs_net_nrcoverage_base_h.p_provincecode$
			AND p_date = '$bs_net_nrcoverage_base_h.p_date$'
	) g0
	GROUP BY g0.day, g0.cellkey, g0.gnbid, g0.cellid, g0.ssbarfcn, g0.pci, g0.provincecode, g0.citycode, g0.districtcode, g0.province, g0.city, g0.district, g0.mcc, g0.mnc, g0.regionid, g0.x_offset_100, g0.y_offset_100, g0.x_offset_50, g0.y_offset_50, g0.x_offset_20, g0.y_offset_20, g0.locationaccuracytype, g0.positionmark, g0.p_provincecode, g0.p_date
) outs
WHERE day IS NOT NULL
	AND cellkey IS NOT NULL