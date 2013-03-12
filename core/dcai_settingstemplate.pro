
function DCAI_SettingsTemplate

	whoami, dir, file

	etalon = {name:'', $
	          port:0, $
			  gap_mm:0.0, $
			  refractive_index:1.0, $
			  steps_per_order:0.0, $
			  scan_voltage:0L, $
			  reference_voltage:0L, $
			  parallel_offset:[0l,0l,0l], $
			  leg_gain:[0.0, 0.0, 0.0], $
			  leg_voltage:[0l,0l,0l], $
			  wedge_voltage:[0L,0L,0L], $
			  voltage_range:[0l,1l], $
			  editable:['name',$
			  			'port',$
			  			'gap_mm',$
			  			'refractive_index',$
			  			'steps_per_order',$
			  			'scan_voltage', $
			  			'reference_voltage',$
			  			'parallel_offset',$
			  			'leg_gain',$
			  			'wedge_voltage',$
			  			'voltage_range']}

	filter = {port:0, $
			  open:-1, $
			  name:['one','two','three','four','five','six'], $
			  current:0, $
			  editable:['port', 'name']}

	mirror = {port:0, $
			  open:-1, $
			  sky:0L, $
			  cal:0L, $
			  current:0L, $
			  editable:['port', 'sky', 'cal']}

	calibration = {port:0, $
				   open:-1, $
			  	   current:0, $
			  	   editable:['port']}

	paths = {log:dir + '..\Logs\', $
			 persistent:dir + '..\Persistent\', $
			 plugin_base:dir + '..\Plugins\', $
			 plugin_settings:dir + '..\Plugins\Plugin_Settings\', $
			 screen_capture:dir + '..\Plugins\ScreenCaps\', $
			 zonemaps:dir + '..\Scripts\Zonemap\', $
			 editable:['log', $
			 			'persistent', $
			 			'plugin_base', $
			 			'plugin_settings', $
			 			'screen_capture', $
			 			'zonemaps']}

	site = {name:'', $
			code:'', $
			geo_lat:0.0, $
			geo_lon:0.0, $
			editable:['name', 'code', 'geo_lat', 'geo_lon']}

	settings = {etalon:[etalon, etalon], $
				filter:filter, $
				mirror:mirror, $
				calibration:calibration, $
				paths:paths, $
				site:site, $
				external_dll:'SDI_External.dll'}

	return, settings
end


