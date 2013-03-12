
@dcai_script_utilities
@sdi_synth_fringes

;\\ EVENT HANDLER FOR THE DCAI GUI
pro DCAI_Control_Event, event

	COMMON DCAI_Control, dcai_global


	;\\ TIMER EVENTS -------------------------------------------------------------------------------------------------
	if tag_names(event, /structure_name) eq 'WIDGET_TIMER' then begin


		;\\ INDICATE THE CURRENT SCHEDULE COMMAND IN THE WIDGET LIST
		if size(*dcai_global.info.current_queue, /type) ne 0 then begin
			if dcai_global.info.current_command_index ne -1 and $
			   strlen((*dcai_global.info.current_queue)[dcai_global.info.current_command_index]) gt 0 then $
				widget_control, set_list_select=dcai_global.info.current_command_index-1, dcai_global.gui.queue
		endif


		;\\ SET UP THE NEXT GUI TIMER TICK
			widget_control, dcai_global.gui.base, timer = dcai_global.info.timer_tick_interval
			dcai_global.info.timer_ticks ++

		if dcai_global.info.run eq 1 then begin


			;\\ UPDATE ETALON LEG VOLTAGE INDICATORS
				tvlct, ctb_r, ctb_g, ctb_b, /get
				loadct, 39, /silent
				for j = 0, n_elements(dcai_global.settings.etalon) - 1 do begin
					frac = dcai_global.settings.etalon[j].leg_voltage / $
						   float(dcai_global.settings.etalon[j].voltage_range[1] - $
						   		 dcai_global.settings.etalon[j].voltage_range[0])

					wset, dcai_global.gui.leg_tvids[j,0]
					erase, 0
					polyfill, /normal, [0,0,1,1]*frac[0], [0,1,1,0], color = 80
					wset, dcai_global.gui.leg_tvids[j,1]
					erase, 0
					polyfill, /normal, [0,0,1,1]*frac[1], [0,1,1,0], color = 80
					wset, dcai_global.gui.leg_tvids[j,2]
					erase, 0
					polyfill, /normal, [0,0,1,1]*frac[2], [0,1,1,0], color = 80
				endfor
				tvlct, ctb_r, ctb_g, ctb_b


			;\\ ALERT THE TIMER LISTENERS
				if size(*dcai_global.info.timer_list, /n_dimensions) ne 0 then $
					for j = 0, n_elements(*dcai_global.info.timer_list) - 1 do $
						call_method, 'timer', (*dcai_global.info.timer_list)[j]


			;\\ CHECK FOR A NEW CAMERA FRAME
				if dcai_global.info.simulate_frames eq 0 then begin

					;\\ NOT SIMULATING CAMERA IMAGES, TRY TO GET A REAL IMAGE
					grab_settings = {mode:dcai_global.info.camera_settings.acqMode, $
									 imageMode:dcai_global.info.camera_settings.imageMode, $
									 startAndWait:1 }
									 ;exptime:dcai_global.info.camera_settings.exptime_set}

					;help, grab_settings.imagemode, /str

					Andor_Camera_Driver, dcai_global.settings.external_dll, 'uGrabFrame', $
										 grab_settings, out, image_result

				endif else begin


					;\\ SIMULATNG CAMERA IMAGES FOR TESTING

					dims = size(*dcai_global.info.image, /dimensions)

					zerph = 7.5 * (dcai_global.settings.etalon[0].leg_voltage[0] + 1) / $
							float(dcai_global.settings.etalon[0].voltage_range[1] - $
								  dcai_global.settings.etalon[0].voltage_range[0]) + .02

					xmag = 0.3e-5 & ymag = 0.3e-5 & zmag = 0
					sdi_synth_frnginit, php, dims[0], dims[1], mag=[xmag,ymag,zmag], $
										center=[dims[0]/2., dims[1]/2.], ordwin=[0.0,5.0], $
			                     		phisq=50.0, zerph=zerph, R=.7
			        sdi_synth_fringemap, image_a, pmap, php, field_stop

					;\\ SIMULATE WEDGED PLATES
						volts = dcai_global.settings.etalon[0].leg_voltage
						max_diff = max([abs(volts[1]-volts[0]),abs(volts[2]-volts[0]),abs(volts[1]-volts[2])])/$
									float(dcai_global.settings.etalon[0].voltage_range[1]-$
										  dcai_global.settings.etalon[0].voltage_range[0])
						if max_diff gt .4 then image_a *= 0

					if n_elements(dcai_global.settings.etalon) eq 2 then begin

						zerph = (10 * (dcai_global.settings.etalon[1].leg_voltage[0] + 1) / $
								float(dcai_global.settings.etalon[1].voltage_range[1] - $
									  dcai_global.settings.etalon[1].voltage_range[0])) - .2

						xmag = 0.2e-4 & ymag = 0.2e-4 & zmag = 0
						sdi_synth_frnginit, php, dims[0], dims[1], mag=[xmag,ymag,zmag], $
											center=[dims[0]/2., dims[1]/2.], ordwin=[0.0,5.0], $
				                     		phisq=.05, zerph=zerph, R=.7
				        sdi_synth_fringemap, image_b, pmap, php, field_stop

						;\\ SIMULATE WEDGED PLATES
							volts = dcai_global.settings.etalon[1].leg_voltage
							max_diff = max([abs(volts[1]-volts[0]),abs(volts[2]-volts[0]),abs(volts[1]-volts[2])])/$
										float(dcai_global.settings.etalon[1].voltage_range[1]-$
											  dcai_global.settings.etalon[1].voltage_range[0])
							if max_diff gt .4 then image_b *= 0

					endif else begin

						image_b = image_a

					endelse

					noise = randomu(systime(/sec)*100L, dims[0], dims[1]) - .5
			        image = 100.*(((image_a+image_b))*5. + noise)
			        image = long(image) > 0
			        image_result = 'image'
			        out = {image:image}

				endelse


				;\\ IF WE GOT A NEW FRAME, PROCESS IT AND ALERT THE FRAME LISTENERS
					if image_result eq 'image' then begin

						;\\ CALCULATE FRAME RATE
							frameTime = systime(/sec)
							dcai_global.info.frame_rate = 1.0 / (frameTime - dcai_global.info.image_systime)

						;\\ PERFORM IMAGE PROCESSING
							processed_image = dcai_process_image(out.image)

						;\\ STORE THE IMAGES IN THE GLOBAL BUFFER
							*dcai_global.info.raw_image = out.image
							*dcai_global.info.image = processed_image
							dcai_global.info.image_systime = frameTime

						;\\ ALERT THE LISTENERS
							if size(*dcai_global.info.frame_list, /n_dimensions) ne 0 then begin
								frame_list = *dcai_global.info.frame_list
								for j = 0, n_elements(frame_list) - 1 do begin
									if obj_valid(frame_list[j]) then call_method, 'frame', frame_list[j]
								endfor
							endif

						;\\ INCREMENT SCAN CHANNELS (IF SCANNING)
							success = DCAI_ScanControl('increment', 'dummy', 0, messages=messages)

					endif


		  	;\\ DO THINGS THAT DON'T NEED TO HAPPEN EVERY TICK
				dcai_global.info.info_update_ticks ++
			  	if dcai_global.info.info_update_ticks mod 5 eq 0 then begin

					;\\ UPDATE THE INFO LIST
						camTemp = -999
						if dcai_global.info.camera_settings.acqMode ne 5 then camTemp = CameraTemperature()

				  		dcai_global.info.info_update_ticks = 0
				    	info_list = ['Site: ' + dcai_global.settings.site.name, $
				    				 'Lat/Lon: ' + strjoin(string([dcai_global.settings.site.geo_lat, dcai_global.settings.site.geo_lon], f='(i0)'), ', '), $
				    				 'UT Time: ' + HourUtHHMMSS(), $
				       	             'Solar Zenith Angle: ' + SolarZenithAngleStr(), $
				       	             'Settings: ' + file_basename(dcai_global.info.settings_file), $
				       	             '', $
				       	             'Frame Rate: ' + string(dcai_global.info.frame_rate, f='(f0.2)') + ' Hz', $
				       	             'Exp. Time (Actual): ' + string(dcai_global.info.camera_settings.expTime_use, f='(f0.3)'), $
				       	             'EM Gain (Actual): ' + string(dcai_global.info.camera_settings.emgain_use, f='(f0.3)'), $
				                     'Camera Temperature: ' + string(camTemp, f='(f0.3)')]

						;\\ FILTERS INFO
						filters = where(tag_names(dcai_global.settings) eq 'FILTER', filters_yn)
						if filters_yn eq 1 then begin
							info_list = [info_list, $
										 '', $
										 'Filter: ' + string(dcai_global.settings.filter.current, f='(i0)') + $
										 ' (' + dcai_global.settings.filter.name[dcai_global.settings.filter.current] + ')']
						endif

						;\\ SCANNING INFO
						info_list = [info_list, $
									 '', $
									 'Scanning: ' + strjoin(string(dcai_global.scan.scanning, f='(i0)'), ', '), $
				                     'Channel: ' + strjoin(string(dcai_global.scan.channel, f='(i0)') + '/' + string(dcai_global.scan.n_channels, f='(i0)'), ', '), $
				                     'Step Size: ' + strjoin(string(dcai_global.scan.step_size, f='(i0)'), ', '), $
				                     'Steps/Order/nm: ' + strjoin(string(dcai_global.settings.etalon.steps_per_order, f='(f0.4)'), ', ')]

						;\\ ACTIVE PLUGIN INFO
						if obj_valid(dcai_global.info.active_plugin.object) eq 1 then begin
							active_plugin = obj_class(dcai_global.info.active_plugin.object) + ' ' + dcai_global.info.active_plugin.uid
						endif else begin
							active_plugin = 'None'
						endelse
						info_list = [info_list, $
									 '', $
									 'Active Plugin: ' + active_plugin]

						;\\ PHASEMAP INFO
						info_list = [info_list, '']
						for k = 0, n_elements(dcai_global.info.phasemap) - 1 do begin
							if size(*dcai_global.info.phasemap[k], /type) ne 0 then begin

								str = 'Acquired'

								t_diff = systime(/sec) - dcai_global.info.phasemap_systime[k]
								yr_diff = (t_diff / (365.*24.*60.*60.))
								dy_diff = (yr_diff mod 1)*365.
								hr_diff = (dy_diff mod 1)*24
								mn_diff = (hr_diff mod 1)*60.

								age = [fix(yr_diff), $
									   fix(dy_diff), $
									   fix(hr_diff), $
									   fix(mn_diff)]

								;\\ Pluralise labels
								not_one = where(age ne 1, n_not_one)
								age_str = [' year', ' day', ' hr', ' min']
								if n_not_one gt 0 then age_str[not_one] += 's'

								mn = (where(age gt 0, n_mn))[0]
								if n_mn eq 0 then begin
									age_out = ', Age: ' + strjoin(strtrim(string(t_diff, f='(f0.1)') + ' secs', 2), ', ')
								endif else begin
									age_out = ', Age: ' + strjoin(strtrim(string(age[mn:*], f='(i4)') + age_str[mn:*], 2), ', ')
								endelse
							endif else begin
								str = 'NOT ACQUIRED'
								age_out = ''
							endelse

							info_list = [info_list, $
										 'Phasemap ' + string(k, f='(i0)') + ', ' + str + age_out]
						endfor


			    		widget_control, set_value = info_list, dcai_global.gui.info


		    		;\\ CHECK TO SEE IF THE CURRENT LOG FILE IS STILL VALID
		    			DCAI_Control_LogCreate

				endif


			;\\ ONLY EXECUTE COMMANDS IF GUI_STOP IS NOT SET AND NOT DEBUGGING AND NO PLUGIN IS ACTIVE
			if (dcai_global.info.gui_stop ne 1 or dcai_global.info.debug.running eq 1) $
				and dcai_global.info.schedule_script ne '' $
				and obj_valid(dcai_global.info.active_plugin.object) ne 1 then begin

				;\\ IF THE COMMAND QUEUE IS EMPTY, GRAB ANOTHER QUEUE FROM THE SCHEDULE SCRIPT
				if dcai_global.info.current_command_index eq -1 then begin
					queue = call_function(dcai_global.info.schedule_script, info)
					*dcai_global.info.current_queue = queue
					dcai_global.info.current_command_index = 0

					;\\ UPDATE THE QUEUE LIST IN THE GUI
					widget_control, set_value = queue, dcai_global.gui.queue
				endif

				;\\ EXECUTE THE NEXT COMMAND IN THE QUEUE, OR RESET IF WE HAVE FINISHED THE CURRENT QUEUE
				if dcai_global.info.current_command_index lt n_elements(*dcai_global.info.current_queue) then begin
					;\\ Execute the next command in the queue
					cmd = (*dcai_global.info.current_queue)[dcai_global.info.current_command_index]
					dcai_global.info.current_command = cmd
					dcai_global.info.current_command_index ++
					DCAI_Command, cmd, errcode = errcode
					if strlen(cmd) ne 0 then DCAI_Log, cmd
				endif else begin
					;\\ Or reset the queue if we are done with the current queue
					dcai_global.info.current_command_index = -1
					dcai_global.info.current_command = ''
				endelse
			endif

		endif ;\\ info.run

	endif
	;\\ END TIMER EVENTS ----------------------------------------------------------------------------------------------



	;\\ WIDGET EVENTS -------------------------------------------------------------------------------------------------
	widget_control, get_uval = uval, event.id	;\\ GET THE UVAL

	;\\ DEAL WITH TOP LEVEL WIDGET KILL REQUESTS (THESE ARE USUALLY CHILDREN OF PLUGIN WIDGETS)
	if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then begin

		if size(uval, /type) eq 8 then begin

			case uval.tag of

				'plugin_base': begin
					tags = strlowcase(tag_names(uval))
					match = where(tags eq 'method', nmatch)
					;\\ RE-ROUTE TO THE PLUGIN'S CHOSEN METHOD
					if nmatch eq 1 then call_method, uval.method, uval.object, 0, index=uval.index
				end

				;\\ CHILD BASES ARE FREE (TOP LEVEL) BASES WHICH ARE CHILDREN OF PLUGINS
				'plugin_child_base': begin
					tags = strlowcase(tag_names(uval))
					match = where(tags eq 'method', nmatch)
					;\\ RE-ROUTE TO THE PARENT PLUGIN'S CHOSEN METHOD
					if nmatch eq 1 then call_method, uval.method, uval.object, 0, index=uval.index
				end

				else:

			endcase

		endif

	endif


	if size(uval, /type) eq 8 then begin

		tag = where(tag_names(uval) eq 'TAG', tag_yn)
		if tag_yn eq 0 then return

		case uval.tag of

			;\\ STOP/START THE SCHEDULE FILE EXECUTION
			'stop_start_button': begin
         		DCAI_Control_ScriptStartStop
			end

			;\\ LOAD UP A NEW SCRIPT
			'load_script_button': begin
				dcai_global.info.current_command_index = -1
				fname = dialog_pickfile(/read)
				script_name = file_basename(strcompress(fname, /remove_all))
				spl = strsplit(script_name, '.', /extract)
				script_name = spl[0]
				res = execute('resolve_routine, /is_function, "' + script_name + '"')
				if res eq 1 then begin
					dcai_global.info.schedule_script = script_name
					widget_control, dcai_global.gui.script_label, set_value = 'Current Schedule: ' + script_name
					DCAI_Log, 'Loaded new script: ' + script_name
				endif else begin
					DCAI_Log, 'Unable to load script: ' + script_name
				endelse
			end

			;\\ SEND THE RESET COMMAND TO THE CURRENT SCRIPT
			'reset_script_button': begin
		        dcai_global.info.current_command_index = -1
		        if (dcai_global.info.schedule_script ne '') then begin
		          	res = call_function(dcai_global.info.schedule_script, /reset)
		        endif
	      	end

			;\\ LOAD SETTINGS
			'load_settings_button': begin
		    	DCAI_Control_LoadSettings
	      	end

			;\\ SAVE SETTINGS
			'save_settings_button': begin
				fname = dialog_pickfile(title='Save Settings To...', $
							file = file_basename(dcai_global.info.settings_file), $
							path = file_dirname(dcai_global.info.settings_file))
				if fname ne '' then DCAI_Control_SaveSettings, filename=fname
	      	end

			;\\ SHOW SETTINGS
			'show_settings_button': begin
				DCAI_SettingsWrite, dcai_global.settings, '', /no_write, out_text = out_text, /parseall
				base = widget_base(group_leader = dcai_global.gui.base, uval = {tag:''}, col = 1)
				list = widget_text(base, value = out_text, font = dcai_global.gui.font, $
									ys=n_elements(out_text) < 80, xs = 100., /scroll)
				widget_control, /realize, base
	      	end

			;\\ LOAD UP THE CAMERA INTERFACE/GUI
			'start_camera_driver': begin
				;\\ Create a base widget to embed the driver gui in
					dcai_global.info.cam_driver_base = widget_base(group_leader = dcai_global.gui.base, title = 'Camera Driver', xoff = 40, yoff = 40)
					Andor_Camera_Driver_GUI, dcai_global.settings.external_dll, embed_in_widget = dcai_global.info.cam_driver_base, $
											 initial_settings = dcai_global.info.camera_settings, update_settings_callback = 'DCAI_Control_Driver_Callback'
			end

			;\\ SELECT A FILTER
			'command_filter': begin
				new_filt = event.index
				call_procedure, dcai_global.info.drivers, {device:'filter_select', filter:new_filt}
			end

			;\\ DRIVE MIRROR MOTOR
			'command_mirror': begin
				pos = ['sky','cal']
				new_pos = pos[event.index]
				if new_pos eq 'sky' then real_pos = dcai_global.settings.mirror.sky
				if new_pos eq 'cal' then real_pos = dcai_global.settings.mirror.cal
				call_procedure, dcai_global.info.drivers, {device:'mirror_drive', to:real_pos}
			end

			;\\ LAUNCH A NEW PLUGIN
			'plugin': begin

				new_plugin = obj_new(uval.plugin)
				if (size(*dcai_global.info.plugins, /n_dimensions)) ne 0 then begin
					*dcai_global.info.plugins = [*dcai_global.info.plugins, new_plugin]
				endif else begin
					*dcai_global.info.plugins = [new_plugin]
				endelse
			end

			;\\ REINIT ETALON
			'etalon_init': call_procedure, dcai_global.info.drivers, {device:'etalon_init'}

			;\\ HOME MOTORS
			'filter_init': call_procedure, dcai_global.info.drivers, {device:'filter_init'}
			'mirror_init': call_procedure, dcai_global.info.drivers, {device:'mirror_init'}
			'calibration_init': call_procedure, dcai_global.info.drivers, {device:'calibration_init'}


			;\\ RE-ROUTE AN EVENT GENERATED WITHIN A PLUGIN
			'plugin_event': begin
				call_method, uval.method, uval.object, event
			end

			else: print, 'Tag not recognized: ' + uval.tag
		endcase
	endif
	;\\ END WIDGET EVENTS ----------------------------------------------------------------------------------------------

end