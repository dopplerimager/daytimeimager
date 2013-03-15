

;\\ Settings file written (UT): 2013-03-15
pro dcai_settings, settings = settings

	settings.etalon[0].name = ''
	settings.etalon[0].port = 4
	settings.etalon[0].gap_mm = 3.0000
	settings.etalon[0].refractive_index = 1.0000
	settings.etalon[0].steps_per_order = 17.1025
	settings.etalon[0].scan_voltage = 47700
	settings.etalon[0].reference_voltage = 47400
	settings.etalon[0].parallel_offset = [0, 2867, 4106]
	settings.etalon[0].leg_gain = [1.0000, 0.9550, 0.9670]
	settings.etalon[0].wedge_voltage = [35460, 60134, 10000]
	settings.etalon[0].voltage_range = [0, 65535]
	
	settings.etalon[1].name = ''
	settings.etalon[1].port = 3
	settings.etalon[1].gap_mm = 0.2460
	settings.etalon[1].refractive_index = 1.0000
	settings.etalon[1].steps_per_order = 16.4532
	settings.etalon[1].scan_voltage = 12000
	settings.etalon[1].reference_voltage = 20803
	settings.etalon[1].parallel_offset = [0, -1308, 528]
	settings.etalon[1].leg_gain = [1.0000, 0.8909, 0.7213]
	settings.etalon[1].wedge_voltage = [53712, 5393, 5393]
	settings.etalon[1].voltage_range = [0, 65535]
	
	settings.filter.port = 1
	settings.filter.name = ['one', 'two', 'three', 'four', 'five', 'six']
	
	settings.mirror.port = 1
	settings.mirror.sky = 98774
	settings.mirror.cal = 2486
	
	settings.calibration.port = 0
	
	settings.paths.log = 'c:\users\DaytimeImager\Logs\'
	settings.paths.persistent = 'c:\users\DaytimeImager\Persistent\'
	settings.paths.plugin_base = 'c:\users\DaytimeImager\Plugins\'
	settings.paths.plugin_settings = 'c:\users\DaytimeImager\Plugins\Plugin_Settings\'
	settings.paths.screen_capture = 'c:\users\DaytimeImager\Plugins\ScreenCaps\'
	settings.paths.zonemaps = 'C:\users\DaytimeImager\Scripts\Zonemap\'
	
	settings.site.name = 'DCAI at the GI'
	settings.site.code = 'DCAI_Test'
	settings.site.geo_lat = 65.0000
	settings.site.geo_lon = -147.0000
	
	settings.external_dll = 'SDI_External.dll'
	

end
