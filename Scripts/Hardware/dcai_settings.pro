

;\\ Settings file written (UT): 2013-03-19
pro dcai_settings, settings = settings

	settings.etalon.name = ''
	settings.etalon.port = 4
	settings.etalon.gap_mm = 3.0000
	settings.etalon.refractive_index = 1.0000
	settings.etalon.steps_per_order = 5.7311
	settings.etalon.scan_voltage = 43000
	settings.etalon.reference_voltage = 43000
	settings.etalon.parallel_offset = [0, 1765, 4926]
	settings.etalon.leg_gain = [1.0000, 0.9550, 0.9670]
	settings.etalon.wedge_voltage = [35460, 60134, 10000]
	settings.etalon.voltage_range = [0, 65535]
	
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
