INSERT OVERWRITE TABLE $bs_net_ltecoverage_base_d$ PARTITION (p_provincecode=$bs_net_ltecoverage_base_d.p_provincecode$, p_date='$bs_net_ltecoverage_base_d.p_date$')
SELECT day, cellkey, enodebid, cellid, rattypeid
	, dlearfcn, pci, provincecode, citycode, districtcode
	, province, city, district, mcc, mnc
	, regionid, x_offset_100, y_offset_100, x_offset_50, y_offset_50
	, x_offset_20, y_offset_20, locationaccuracytype, positionmark, totalmrlon
	, totalmrlat, validlonlat_totalmrcount, celmr_totaldis, celmr_discount, totalrsrp
	, rsrpcount, rsrpgoodcount, validlonlat_totalrsrp, validlonlatrsrp_totalmrcount, validta_totalrsrp
	, validta_totalmrcount, validlonlatta_totalrsrp, validlonlatta_totalmrcount, totalrsrq, rsrqcount
	, rsrqgoodcount, totalulsinr, ulsinrcount, ulsinrgoodcount, compulcovgood_mrcount
	, compulcovvalid_mrcount, period_totalmrcount, weakcover_mrcount, overlap_mrcount, overshoot_mrcount
	, mod3interfer_mrcount, puschprbnum, pdschprbnum, puschuseprbnum, pdschuseprbnum
	, puschavailprbnum, pdschavailprbnum, sumuetputpuschprbnum, sumuetputpdschprbnum, validlonlat_totalallerabpdcptput
	, validlonlat_totalallerabulpdcptput, validlonlat_totalallerabdlpdcptput, validlonlat_totalallerabdlpdcptput_aoa0_30, validlonlat_totalallerabdlpdcptput_aoa30_60, validlonlat_totalallerabdlpdcptput_aoa60_90
	, validlonlat_totalallerabdlpdcptput_aoa90_120, validlonlat_totalallerabdlpdcptput_aoa120_150, validlonlat_totalallerabdlpdcptput_aoa150_180, validlonlat_totalallerabdlpdcptput_aoa180_210, validlonlat_totalallerabdlpdcptput_aoa210_240
	, validlonlat_totalallerabdlpdcptput_aoa240_270, validlonlat_totalallerabdlpdcptput_aoa270_300, validlonlat_totalallerabdlpdcptput_aoa300_330, validlonlat_totalallerabdlpdcptput_aoa330_360
    , tafar_count, allerabulpdcptput, allerabdlpdcptput, sumulpdcpwithoutlastpiece, sumdlpdcpwithoutlastpiece, sumulpdcperabtimerlen, sumdlpdcperabtimerlen
    , azimuthinvalid_mrcount, azimuthalign_mrcount
FROM (
	SELECT g0.day AS day, g0.cellkey AS cellkey, g0.enodebid AS enodebid, g0.cellid AS cellid, g0.rattypeid AS rattypeid
		, g0.dlearfcn AS dlearfcn, g0.pci AS pci, g0.provincecode AS provincecode, g0.citycode AS citycode, g0.districtcode AS districtcode
		, g0.province AS province, g0.city AS city, g0.district AS district, g0.mcc AS mcc, g0.mnc AS mnc
		, g0.regionid AS regionid, g0.x_offset_100 AS x_offset_100, g0.y_offset_100 AS y_offset_100, g0.x_offset_50 AS x_offset_50, g0.y_offset_50 AS y_offset_50
		, g0.x_offset_20 AS x_offset_20, g0.y_offset_20 AS y_offset_20, g0.locationaccuracytype AS locationaccuracytype, g0.positionmark AS positionmark
		, SUM(g0.totalmrlon) AS totalmrlon, SUM(g0.totalmrlat) AS totalmrlat
		, SUM(g0.validlonlat_totalmrcount) AS validlonlat_totalmrcount, SUM(g0.celmr_totaldis) AS celmr_totaldis
		, SUM(g0.celmr_discount) AS celmr_discount, SUM(g0.totalrsrp) AS totalrsrp
		, SUM(g0.rsrpcount) AS rsrpcount, SUM(g0.rsrpgoodcount) AS rsrpgoodcount
		, SUM(g0.validlonlat_totalrsrp) AS validlonlat_totalrsrp, SUM(g0.validlonlatrsrp_totalmrcount) AS validlonlatrsrp_totalmrcount
		, SUM(g0.validta_totalrsrp) AS validta_totalrsrp, SUM(g0.validta_totalmrcount) AS validta_totalmrcount
		, SUM(g0.validlonlatta_totalrsrp) AS validlonlatta_totalrsrp, SUM(g0.validlonlatta_totalmrcount) AS validlonlatta_totalmrcount
		, SUM(g0.totalrsrq) AS totalrsrq, SUM(g0.rsrqcount) AS rsrqcount
		, SUM(g0.rsrqgoodcount) AS rsrqgoodcount, SUM(g0.totalulsinr) AS totalulsinr
		, SUM(g0.ulsinrcount) AS ulsinrcount, SUM(g0.ulsinrgoodcount) AS ulsinrgoodcount
		, SUM(g0.compulcovgood_mrcount) AS compulcovgood_mrcount, SUM(g0.compulcovvalid_mrcount) AS compulcovvalid_mrcount
		, SUM(g0.period_totalmrcount) AS period_totalmrcount, SUM(g0.weakcover_mrcount) AS weakcover_mrcount
		, SUM(g0.overlap_mrcount) AS overlap_mrcount, SUM(g0.overshoot_mrcount) AS overshoot_mrcount
		, SUM(g0.mod3interfer_mrcount) AS mod3interfer_mrcount, SUM(g0.puschprbnum) AS puschprbnum
		, SUM(g0.pdschprbnum) AS pdschprbnum, SUM(g0.puschuseprbnum) AS puschuseprbnum
		, SUM(g0.pdschuseprbnum) AS pdschuseprbnum, SUM(g0.puschavailprbnum) AS puschavailprbnum
		, SUM(g0.pdschavailprbnum) AS pdschavailprbnum, SUM(g0.sumuetputpuschprbnum) AS sumuetputpuschprbnum
		, SUM(g0.sumuetputpdschprbnum) AS sumuetputpdschprbnum, SUM(g0.validlonlat_totalallerabpdcptput) AS validlonlat_totalallerabpdcptput
		, SUM(g0.validlonlat_totalallerabulpdcptput) AS validlonlat_totalallerabulpdcptput, SUM(g0.validlonlat_totalallerabdlpdcptput) AS validlonlat_totalallerabdlpdcptput
		, SUM(g0.validlonlat_totalallerabdlpdcptput_aoa0_30) AS validlonlat_totalallerabdlpdcptput_aoa0_30, SUM(g0.validlonlat_totalallerabdlpdcptput_aoa30_60) AS validlonlat_totalallerabdlpdcptput_aoa30_60
		, SUM(g0.validlonlat_totalallerabdlpdcptput_aoa60_90) AS validlonlat_totalallerabdlpdcptput_aoa60_90, SUM(g0.validlonlat_totalallerabdlpdcptput_aoa90_120) AS validlonlat_totalallerabdlpdcptput_aoa90_120
		, SUM(g0.validlonlat_totalallerabdlpdcptput_aoa120_150) AS validlonlat_totalallerabdlpdcptput_aoa120_150, SUM(g0.validlonlat_totalallerabdlpdcptput_aoa150_180) AS validlonlat_totalallerabdlpdcptput_aoa150_180
		, SUM(g0.validlonlat_totalallerabdlpdcptput_aoa180_210) AS validlonlat_totalallerabdlpdcptput_aoa180_210, SUM(g0.validlonlat_totalallerabdlpdcptput_aoa210_240) AS validlonlat_totalallerabdlpdcptput_aoa210_240
		, SUM(g0.validlonlat_totalallerabdlpdcptput_aoa240_270) AS validlonlat_totalallerabdlpdcptput_aoa240_270, SUM(g0.validlonlat_totalallerabdlpdcptput_aoa270_300) AS validlonlat_totalallerabdlpdcptput_aoa270_300
		, SUM(g0.validlonlat_totalallerabdlpdcptput_aoa300_330) AS validlonlat_totalallerabdlpdcptput_aoa300_330, SUM(g0.validlonlat_totalallerabdlpdcptput_aoa330_360) AS validlonlat_totalallerabdlpdcptput_aoa330_360
		, g0.p_provincecode AS p_provincecode, g0.p_date AS p_date
        , SUM(g0.tafar_count) tafar_count
        , SUM(g0.allerabulpdcptput) AS allerabulpdcptput
        , SUM(g0.allerabdlpdcptput) AS allerabdlpdcptput
        , SUM(g0.sumulpdcpwithoutlastpiece) AS sumulpdcpwithoutlastpiece
        , SUM(g0.sumdlpdcpwithoutlastpiece) AS sumdlpdcpwithoutlastpiece
        , SUM(g0.sumulpdcperabtimerlen) AS sumulpdcperabtimerlen
        , SUM(g0.sumdlpdcperabtimerlen) AS sumdlpdcperabtimerlen
        , sum(azimuthinvalid_mrcount) as azimuthinvalid_mrcount
        , sum(azimuthalign_mrcount) as azimuthalign_mrcount
	FROM (
		SELECT day, cellkey, enodebid, cellid, rattypeid
			, dlearfcn, pci, provincecode, citycode, districtcode
			, province, city, district, mcc, mnc
			, regionid, x_offset_100, y_offset_100, x_offset_50, y_offset_50
			, x_offset_20, y_offset_20, locationaccuracytype, positionmark, totalmrlon
			, totalmrlat, validlonlat_totalmrcount, celmr_totaldis, celmr_discount, totalrsrp
			, rsrpcount, rsrpgoodcount, validlonlat_totalrsrp, validlonlatrsrp_totalmrcount, validta_totalrsrp
			, validta_totalmrcount, validlonlatta_totalrsrp, validlonlatta_totalmrcount, totalrsrq, rsrqcount
			, rsrqgoodcount, totalulsinr, ulsinrcount, ulsinrgoodcount, compulcovgood_mrcount
			, compulcovvalid_mrcount, period_totalmrcount, weakcover_mrcount, overlap_mrcount, overshoot_mrcount
			, mod3interfer_mrcount, puschprbnum, pdschprbnum, puschuseprbnum, pdschuseprbnum
			, puschavailprbnum, pdschavailprbnum, sumuetputpuschprbnum, sumuetputpdschprbnum, validlonlat_totalallerabpdcptput
			, validlonlat_totalallerabulpdcptput, validlonlat_totalallerabdlpdcptput, validlonlat_totalallerabdlpdcptput_aoa0_30, validlonlat_totalallerabdlpdcptput_aoa30_60, validlonlat_totalallerabdlpdcptput_aoa60_90
			, validlonlat_totalallerabdlpdcptput_aoa90_120, validlonlat_totalallerabdlpdcptput_aoa120_150, validlonlat_totalallerabdlpdcptput_aoa150_180, validlonlat_totalallerabdlpdcptput_aoa180_210, validlonlat_totalallerabdlpdcptput_aoa210_240
			, validlonlat_totalallerabdlpdcptput_aoa240_270, validlonlat_totalallerabdlpdcptput_aoa270_300, validlonlat_totalallerabdlpdcptput_aoa300_330, validlonlat_totalallerabdlpdcptput_aoa330_360, p_provincecode
            , p_date, tafar_count, allerabulpdcptput, allerabdlpdcptput, sumulpdcpwithoutlastpiece, sumdlpdcpwithoutlastpiece, sumulpdcperabtimerlen, sumdlpdcperabtimerlen, azimuthinvalid_mrcount, azimuthalign_mrcount
		FROM $bs_net_ltecoverage_base_h$
		WHERE p_provincecode = $bs_net_ltecoverage_base_h.p_provincecode$
			AND p_date = '$bs_net_ltecoverage_base_h.p_date$'
	) g0
	GROUP BY g0.day, g0.cellkey, g0.enodebid, g0.cellid, g0.rattypeid, g0.dlearfcn, g0.pci, g0.provincecode, g0.citycode, g0.districtcode, g0.province, g0.city, g0.district, g0.mcc, g0.mnc, g0.regionid, g0.x_offset_100, g0.y_offset_100, g0.x_offset_50, g0.y_offset_50, g0.x_offset_20, g0.y_offset_20, g0.locationaccuracytype, g0.positionmark, g0.p_provincecode, g0.p_date
) outs
WHERE day IS NOT NULL
	AND cellkey IS NOT NULL