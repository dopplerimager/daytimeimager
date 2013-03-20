
function DCAI_Scanner::init

	common DCAI_Control, dcai_global


	;\\ DEFAULTS

	;\\ SAVE FIELDS
		self.save_tags = ['norm_start', 'norm_channels', 'norm_etalons', $
						  'man_start', 'man_step', 'man_channels', 'man_etalons', $
						  'wave_start', 'wave_stop', 'wave_channels', 'wave_etalons', $
						  'wavelength', 'current_tab']


	;\\ RESTORE SAVED SETTINGS
		self->load_settings
		self.norm_start = dcai_global.settings.etalon.scan_voltage
		self.man_start = dcai_global.settings.etalon.scan_voltage


	;\\ CREATE THE GUI
		font = dcai_global.gui.font
		base = widget_base(group=dcai_global.gui.base, col=1, uval={tag:'plugin_base', object:self}, title = 'Scanner', $
						   xoffset = self.xpos, yoffset = self.ypos, /base_align_center, tab_mode=1)

		xsize = 500

		n_etalons = n_elements(dcai_global.settings.etalon)
		leg_bar_wids = lonarr(n_etalons, 3)

		;\\ LEG VALUE INDICATORS
			leg_bar_wids = lonarr(n_etalons, 3)
			indicator_base = widget_base(base, col = n_etalons)
			for i = 0, n_etalons - 1 do begin

				e = dcai_global.settings.etalon[i]

				sub_base = widget_base(indicator_base, col=1, /base_align_center)
				label = widget_label(sub_base, value = 'Etalon ' + string(i, f='(i0)'), font = font + '*Bold')
				vrange = 'Voltage Range: ' + string(dcai_global.settings.etalon[i].voltage_range[0], f='(i0)') + $
						 '...' + string(dcai_global.settings.etalon[i].voltage_range[1], f='(i0)')
				label = widget_label(sub_base, value = vrange, font = font)

				;\\ LEG VALUE INDICATORS
				leg_base = widget_base(sub_base, row = 3)
					leg1_base = widget_base(leg_base, col = 3)
						leg1_lab = widget_label(leg1_base, value = 'Leg 1', font=font)
						leg1_bar = widget_draw(leg1_base, xs = 150, ys = 16)
						leg1_val = widget_label(leg1_base, value = string(e.leg_voltage[0], f='(i0)'), font=font, xs=50 )
					leg2_base = widget_base(leg_base, col = 3)
						leg2_lab = widget_label(leg2_base, value = 'Leg 2', font=font)
						leg2_bar = widget_draw(leg2_base, xs = 150, ys = 16)
						leg2_val = widget_label(leg2_base, value = string(e.leg_voltage[1], f='(i0)'), font=font, xs=50 )
					leg3_base = widget_base(leg_base, col = 3)
						leg3_lab = widget_label(leg3_base, value = 'Leg 3', font=font)
						leg3_bar = widget_draw(leg3_base, xs = 150, ys = 16)
						leg3_val = widget_label(leg3_base, value = string(e.leg_voltage[2], f='(i0)'), font=font, xs=50 )

					leg_bar_wids[i,*] = [leg1_bar, leg2_bar, leg3_bar]
					self.leg_val_ids[i,*] = [leg1_val, leg2_val, leg3_val]

			endfor

			;\\ VIEWING WAVELENGTH EDIT
			label = widget_label(base, value = 'Viewing Wavelength', font=dcai_global.gui.font+'*Bold')
			widget_edit_field, base, label = 'Wavelength (nm)', font = font, start_val=string(self.wavelength, f='(f0.3)'), /column, $
								   edit_uval = {tag:'plugin_event', object:self, method:'Wavelength'}, edit_xs = 10

			self.status = widget_label(base, value = 'Status: Idle', font=font+'*Bold', xs=400, /align_left)


			tab_base = widget_tab(base, uval={tag:'plugin_event', object:self, method:'TabEvent'})

		;\\ NORMAL SCAN (OVER ONE ORDER)
			normal_base = widget_base(tab_base, col=1, frame=1, /base_align_center, xsize=xsize, title='Scan Over Order')
			label = widget_label(normal_base, value = 'Scan Over Order', font=font+'*Bold')

			nonexc_base = widget_base(normal_base, /nonexclusive, col=n_etalons)
			for i = 0, n_etalons - 1 do begin
				btn = widget_button(nonexc_base, value='Etalon ' + string(i, f='(i0)'), font=font, $
									uval={tag:'plugin_event', object:self, method:'NormalEdit', field:'Etalon', etalon:i})
				if self.norm_etalons[i] eq 1 then widget_control, btn, /set_button
			endfor

			sub_base = widget_base(normal_base, col=n_etalons + 2)
			for i = 0, n_etalons - 1 do begin

				e = dcai_global.settings.etalon[i]
				sub_base_1 = widget_base(sub_base, col=1)

				widget_edit_field, sub_base_1, label='Etalon ' + string(i, f='(i0)') + ' Start', font=font, $
								   start_val=string(self.norm_start[i,0], f='(i0)'), edit_xs = 10, $
								   edit_uval = {tag:'plugin_event', object:self, method:'NormalEdit', field:'Leg', etalon:i}
			endfor

			widget_edit_field, sub_base, label = 'Channels', font = font, start_val=string(self.norm_channels, f='(i0)'), $
							   edit_uval = {tag:'plugin_event', object:self, method:'NormalEdit', field:'Channels'}, edit_xs = 10

			btn_base = widget_base(sub_base, col=1)
				btn = widget_button(btn_base, value='Start', font=font, uval={tag:'plugin_event', object:self, method:'Scan', action:'Start', type:'Normal'})
				btn = widget_button(btn_base, value='Stop', font=font, uval={tag:'plugin_event', object:self, method:'Scan', action:'Stop', type:'Normal'})
				btn = widget_button(btn_base, value='Pause', font=font, uval={tag:'plugin_event', object:self, method:'Scan', action:'Pause', type:'Normal'})
				btn = widget_button(btn_base, value='UnPause', font=font, uval={tag:'plugin_event', object:self, method:'Scan', action:'UnPause', type:'Normal'})



		;\\ MANUAL SCAN
			manual_base = widget_base(tab_base, col=1, frame=1, /base_align_center, xsize=xsize, title='Manual Scan')
			label = widget_label(manual_base, value = 'Manual Scan', font=font+'*Bold')

			nonexc_base = widget_base(manual_base, /nonexclusive, col=n_etalons)
			for i = 0, n_etalons - 1 do begin
				btn = widget_button(nonexc_base, value='Etalon ' + string(i, f='(i0)'), font=font, $
									uval={tag:'plugin_event', object:self, method:'ManualEdit', field:'Etalon', etalon:i})
				if self.man_etalons[i] eq 1 then widget_control, btn, /set_button
			endfor

			sub_base = widget_base(manual_base, col=n_etalons + 1, /base_align_center)
			for i = 0, n_etalons - 1 do begin

				e = dcai_global.settings.etalon[i]

				label = widget_label(sub_base, value = 'Etalon ' + string(i, f='(i0)'), font=dcai_global.gui.font+'*Bold', /align_center)

				sub_base_1 = widget_base(sub_base, col=1, /base_align_right)
				widget_edit_field, sub_base_1, label = 'Start', font = font, start_val=string(self.man_start[i,0], f='(i0)'), /column, $
								   edit_uval = {tag:'plugin_event', object:self, method:'ManualEdit', field:'Start', etalon:i}, edit_xs = 10

				widget_edit_field, sub_base_1, label = 'Step Size', font = font, start_val=string(self.man_step[i], f='(i0)'), /column, $
							   edit_uval = {tag:'plugin_event', object:self, method:'ManualEdit', field:'StepSize', etalon:i}, edit_xs = 10
				widget_edit_field, sub_base_1, label = 'Channels', font = font, start_val=string(self.man_channels[i], f='(i0)'), /column, $
							   edit_uval = {tag:'plugin_event', object:self, method:'ManualEdit', field:'Channels', etalon:i}, edit_xs = 10

			endfor

			btn_base = widget_base(sub_base, col=1)
				btn = widget_button(btn_base, value='Start', font=font, uval={tag:'plugin_event', object:self, method:'Scan', action:'Start', type:'Manual'})
				btn = widget_button(btn_base, value='Stop', font=font, uval={tag:'plugin_event', object:self, method:'Scan', action:'Stop', type:'Manual'})
				btn = widget_button(btn_base, value='Pause', font=font, uval={tag:'plugin_event', object:self, method:'Scan', action:'Pause', type:'Manual'})
				btn = widget_button(btn_base, value='UnPause', font=font, uval={tag:'plugin_event', object:self, method:'Scan', action:'UnPause', type:'Manual'})


		;\\ WAVELENGTH SCAN
			if n_elements(dcai_global.settings.etalon) gt 1 then begin
				wavelength_base = widget_base(tab_base, col=1, frame=1, /base_align_center, xsize=xsize, title='Wavelength Scan')
				label = widget_label(wavelength_base, value = 'Wavelength Scan', font=font+'*Bold')

				nonexc_base = widget_base(wavelength_base, /nonexclusive, col=n_etalons)
				for i = 0, n_etalons - 1 do begin
					btn = widget_button(nonexc_base, value='Etalon ' + string(i, f='(i0)'), font=font, $
										uval={tag:'plugin_event', object:self, method:'WaveEdit', field:'Etalon', etalon:i})
					if self.wave_etalons[i] eq 1 then widget_control, btn, /set_button
				endfor

				sub_base = widget_base(wavelength_base, col=2)
				sub_base_1 = widget_base(sub_base, col=1, /base_align_right)
				widget_edit_field, sub_base_1, label = 'Start Wavelength (nm)', font = font, start_val=string(self.wave_start, f='(f0.5)'), /column, $
								   edit_uval = {tag:'plugin_event', object:self, method:'WaveEdit', field:'StartWavelength'}, edit_xs = 10
				widget_edit_field, sub_base_1, label = 'Stop Wavelength (nm)', font = font, start_val=string(self.wave_stop, f='(f0.5)'), /column, $
								   edit_uval = {tag:'plugin_event', object:self, method:'WaveEdit', field:'StopWavelength'}, edit_xs = 10
				widget_edit_field, sub_base_1, label = 'Channels', font = font, start_val=string(self.wave_channels, f='(i0)'), /column, $
								   edit_uval = {tag:'plugin_event', object:self, method:'WaveEdit', field:'Channels'}, edit_xs = 10

				btn_base = widget_base(sub_base, col=1)
					btn = widget_button(btn_base, value='Start', font=font, uval={tag:'plugin_event', object:self, method:'Scan', action:'Start', type:'Wave'})
					btn = widget_button(btn_base, value='Stop', font=font, uval={tag:'plugin_event', object:self, method:'Scan', action:'Stop', type:'Wave'})
					btn = widget_button(btn_base, value='Pause', font=font, uval={tag:'plugin_event', object:self, method:'Scan', action:'Pause', type:'Wave'})
					btn = widget_button(btn_base, value='UnPause', font=font, uval={tag:'plugin_event', object:self, method:'Scan', action:'UnPause', type:'Wave'})

				slider_base = widget_base(wavelength_base, col=1)
					if (self.wave_start eq self.wave_stop) then self.wave_stop += .1

					label = widget_label(slider_base, value='Manual Wavelength Scan', font=font+'*Bold')
					label = widget_label(slider_base, value=string(self.wave_start, f='(f0.5)'), font=font+'*Bold')
					sub_base = widget_base(slider_base, col=3)
					slider_minval = widget_label(sub_base, value=string(self.wave_start, f='(f0.5)'), font=font)
					slider = cw_fslider(sub_base, min=self.wave_start, max=self.wave_stop, $
									scroll=(self.wave_stop-self.wave_start)/self.wave_channels, /suppress, xsize = 300, $
									uval={tag:'plugin_event', object:self, method:'WaveSlider'}, /drag)
					slider_maxval = widget_label(sub_base, value=string(self.wave_stop, f='(f0.5)'), font=font)
					self.wave_slider_ids = [slider, slider_minval, slider_maxval, label]
					btn = widget_button(slider_base, value='Initialize', font=font+'*Bold', xs = 50, $
										uval={tag:'plugin_event', object:self, method:'WaveEdit', field:'ManualInit'})
			endif

	DCAI_Control_RegisterPlugin, base, self, /timer

	for i = 0, n_etalons - 1 do begin
		widget_control, get_value = leg1_id, leg_bar_wids[i,0]
		widget_control, get_value = leg2_id, leg_bar_wids[i,1]
		widget_control, get_value = leg3_id, leg_bar_wids[i,2]
		self.leg_bar_ids[i,*] = [leg1_id,  leg2_id,  leg3_id]
	endfor

	;\\ REMEMBER THE PREVIOUSLY CURRENT TAB
	widget_control, tab_base, set_tab_current = self.current_tab

	self.id = base
	return, 1
end


;\\ TIMER EVENTS
pro DCAI_Scanner::timer
	COMMON DCAI_Control, dcai_global

    self->LegUpdate
    n_etz = n_elements(dcai_global.settings.etalon)

	;\\ UPDATE STATUS
	status = 'Status: Idle'
	if self.scanning eq 2 then status = 'Status: Paused'
	if self.scanning eq 1 then begin

		case self.scan_type of
			'Normal':begin
				channel = strjoin(string(dcai_global.scan.channel[0:n_etz-1], f='(i0)') + $
								  '/' + string(dcai_global.scan.n_channels[0:n_etz-1], f='(i0)'), ', ')
				status = 'Status: Scan over Order, Channels = ' + channel
			end
			'Manual':begin
				channel = strjoin(string(dcai_global.scan.channel[0:n_etz-1], f='(i0)') + $
								  '/' + string(dcai_global.scan.n_channels[0:n_etz-1], f='(i0)'), ', ')
				status = 'Status: Maunal Scan, Channels = ' + channel
			end
			'Wave':begin
				wavelength = string(self.wave_start + dcai_global.scan.channel[0] * $
									((self.wave_stop-self.wave_start)/self.wave_channels), f='(f0.5)')
				status = 'Status: Wavelength Scan, Center Wavelength = ' + wavelength
			end
			else:
		endcase

	endif

	widget_control, set_value=status, self.status

	;\\ KEEP RESTARTING SCANS, AFTER THEY ARE FINISHED, UNTIL STOP IS CLICKED
	if self.scanning eq 1 and total(dcai_global.scan.scanning) eq 0 then begin
		self->Scan, 0, struc={type:self.scan_type, action:'Start'}
	endif
end



;\\ UPDATE THE ETALON LEG INDICATORS
pro DCAI_Scanner::LegUpdate

	COMMON DCAI_Control, dcai_global

	;\\ STORE THE CURRENT CTABLE
	tvlct, r, g, b, /get
	loadct, 39, /silent

	for ii = 0, n_elements(dcai_global.settings.etalon) - 1 do begin

		e = dcai_global.settings.etalon[ii]
		for i = 0, 2 do begin
			wset, self.leg_bar_ids[ii,i]
			erase, 0
			polyfill, [0, 0, 1, 1] * e.leg_voltage[i]/float(e.voltage_range[1]), [.01,.9,.9,.01], color=80, /normal
			widget_control, set_value = string(e.leg_voltage[i], f='(i0)'), self.leg_val_ids[ii,i]
		endfor

	endfor

	;\\ RESTORE THE PREVIOUS CTABLE
	tvlct, r, g, b
end


;\\ NORMAL SCAN EDITS
pro DCAI_Scanner::NormalEdit, event
	COMMON DCAI_Control, dcai_global

	widget_control, get_uval=uval, event.id
	widget_control, get_val=val, event.id
	case uval.field of
		'Start':begin
			volt = fix(val, type=3)
			volt = volt > dcai_global.settings.etalon[uval.etalon].voltage_range[0]
			volt = volt < dcai_global.settings.etalon[uval.etalon].voltage_range[1]
			self.norm_start[uval.etalon] = volt
		end
		'Channels': self.norm_channels = fix(val, type=3)
		'Etalon': self.norm_etalons[uval.etalon] = event.select
		else:
	endcase
end

;\\ WAVELENGTH EDIT
pro DCAI_Scanner::Wavelength, event
	widget_control, get_val=val, event.id
	self.wavelength = fix(val, type=4)
end

;\\ MANUAL SCAN EDITS
pro DCAI_Scanner::ManualEdit, event
	COMMON DCAI_Control, dcai_global

	widget_control, get_uval=uval, event.id
	widget_control, get_val=val, event.id
	case uval.field of
		'Start':begin
			volt = fix(val, type=3)
			volt = volt > dcai_global.settings.etalon[uval.etalon].voltage_range[0]
			volt = volt < dcai_global.settings.etalon[uval.etalon].voltage_range[1]
			self.man_start[uval.etalon] = volt
		end
		'Channels': self.man_channels[uval.etalon] = fix(val, type=3) > 0
		'StepSize': self.man_step[uval.etalon] = fix(val, type=3)
		'Etalon': self.man_etalons[uval.etalon] = event.select
		else:
	endcase
end


;\\ WAVELENGTH SCAN EDITS
pro DCAI_Scanner::WaveEdit, event
	COMMON DCAI_Control, dcai_global

	widget_control, get_uval=uval, event.id
	widget_control, get_val=val, event.id
	case uval.field of
		'StartWavelength': self.wave_start = fix(val, type=4)
		'StopWavelength': self.wave_stop = fix(val, type=4)
		'Channels': self.wave_channels = fix(val, type=3) > 0
		'Etalon': self.wave_etalons[uval.etalon] = event.select
		'ManualInit': begin
			;\\ UPDATE THE WAVE SLIDER
			parent = widget_info(self.wave_slider_ids[0], /parent)
			widget_control, self.wave_slider_ids[0], /destroy
			widget_control, self.wave_slider_ids[1], /destroy
			widget_control, self.wave_slider_ids[2], /destroy

			slider_minval = widget_label(parent, value=string(self.wave_start, f='(f0.5)'), font=dcai_global.gui.font)
			slider = cw_fslider(parent, min=self.wave_start, max=self.wave_stop, $
						scroll=(self.wave_stop-self.wave_start)/self.wave_channels, /suppress, xsize = 300, $
						uval={tag:'plugin_event', object:self, method:'WaveSlider'}, /drag)
			slider_maxval = widget_label(parent, value=string(self.wave_stop, f='(f0.5)'), font=dcai_global.gui.font)
			self.wave_slider_ids[0:2] = [slider, slider_minval, slider_maxval]

			;\\ SET UP SCAN AND DRIVE TO THE START WAVELENGTH
				etalons = where(self.wave_etalons eq 1, netalons)
				if netalons ne 0 then begin
					arg = {caller:self, etalons:etalons, n_channels:self.wave_channels, $
						   wavelength_range_nm:[self.wave_start, self.wave_stop]}

					success = DCAI_ScanControl('start', 'wavelength', arg, /delayed_start)

					arg = replicate({etalon:0, channel:0L}, netalons)
					for k = 0, netalons - 1 do begin
						arg[k].etalon = k
						arg[k].channel = 0
					endfor
					success = DCAI_ScanControl('increment', 'dummy', arg)

				endif

			;\\ UPDATE THE CURRENT WAVELENGTH
			widget_control, set_value=string(self.wave_start, f='(f0.5)'), self.wave_slider_ids[3]
		end
		else:
	endcase
end


;\\ WAVE SLIDER EVENTS
pro DCAI_Scanner::WaveSlider, event
	new_lambda = event.value
	widget_control, set_value=string(new_lambda, f='(f0.5)'), self.wave_slider_ids[3]

	channel = round(self.wave_channels*(new_lambda - self.wave_start)/(self.wave_stop-self.wave_start))
	channel = channel < (self.wave_channels-1)

	etalons = where(self.wave_etalons eq 1, netalons)
	if netalons gt 0 then begin
		arg = replicate({etalon:0, channel:0L}, netalons)
		arg[*].etalon = etalons
		arg[*].channel = channel
		success = DCAI_ScanControl('increment', 'dummy', arg)
	endif

end


;\\ SCAN ACTIONS
pro DCAI_Scanner::Scan, event, struc=struc
	COMMON DCAI_Control, dcai_global

	if size(struc, /type) eq 8 then begin
		uval = struc
	endif else begin
		widget_control, get_uval=uval, event.id
	endelse

	if self.scanning eq 1 and self.scan_type ne uval.type then return

	case uval.type of
		'Normal': etz = self.norm_etalons
		'Manual': etz = self.man_etalons
		'Wave': etz = self.wave_etalons
	endcase

	case uval.action of
		'Start': begin

			case uval.type of
				'Normal':begin

					args = 0
					for k = 0, n_elements(self.norm_etalons) - 1 do begin
						if self.norm_etalons[k] eq 1 then begin
							if self.norm_channels[k] eq 0 then return
							new_arg = {caller:self, etalon:k, n_channels:self.norm_channels, wavelength_nm:self.wavelength, $
									   start_voltage:self.norm_start[k]}
							if size(args, /type) eq 2 then args = new_arg else args = [args, new_arg]
						endif
					endfor

					if size(args, /type) ne 2 then begin
						success = DCAI_ScanControl('start', 'normal', args)
						if success eq 1 then begin
							self.scanning = 1
							self.scan_type = 'Normal'
						endif
					endif

				end

				'Manual':begin

					args = 0
					for k = 0, n_elements(self.man_etalons) - 1 do begin
						if self.man_etalons[k] eq 1 then begin
							if self.man_channels[k] eq 0 then return
							new_arg = {caller:self, etalon:k, n_channels:self.man_channels[k], step_size:self.man_step[k], $
									   start_voltage:self.man_start[k]}
							if size(args, /type) eq 2 then args = new_arg else args = [args, new_arg]
						endif
					endfor

					if size(args, /type) ne 2 then begin
						success = DCAI_ScanControl('start', 'manual', args)
						if success eq 1 then begin
							self.scanning = 1
							self.scan_type = 'Manual'
						endif
					endif

				end

				'Wave':begin

					etalons = where(self.wave_etalons eq 1, netalons)
					if netalons ne 0 then begin

						arg = {caller:self, etalons:etalons, n_channels:self.wave_channels, $
							   wavelength_range_nm:[self.wave_start, self.wave_stop]}

						success = DCAI_ScanControl('start', 'wavelength', arg)
						if success eq 1 then begin
							self.scanning = 1
							self.scan_type = 'Wave'
						endif

					endif
				end

			endcase

		end

		'Stop': begin

			args = 0
			for k = 0, n_elements(etz) - 1 do begin
				if etz[k] eq 1 then begin
					new_arg = {caller:self, etalon:k}
					if size(args, /type) eq 2 then args = new_arg else args = [args, new_arg]
				endif
			endfor

			if size(args, /type) ne 2 then begin
				success = DCAI_ScanControl('stop', 'dummy', args)
				if success eq 1 then begin
					self.scanning = 0
					self.scan_type = ''
				endif
			endif

		end

		'Pause': begin

			args = 0
			for k = 0, n_elements(etz) - 1 do begin
				if etz[k] eq 1 then begin
					new_arg = {caller:self, etalon:k}
					if size(args, /type) eq 2 then args = new_arg else args = [args, new_arg]
				endif
			endfor

			if size(args, /type) ne 2 then begin
				success = DCAI_ScanControl('pause', 'dummy', args)
				if success eq 1 then self.scanning = 2
			endif

		end

		'UnPause': begin

			args = 0
			for k = 0, n_elements(etz) - 1 do begin
				if etz[k] eq 1 then begin
					new_arg = {caller:self, etalon:k}
					if size(args, /type) eq 2 then args = new_arg else args = [args, new_arg]
				endif
			endfor

			if size(args, /type) ne 2 then begin
				success = DCAI_ScanControl('unpause', 'dummy', args)
				if success eq 1 then self.scanning = 1
			endif

		end

		else:
	endcase

end


;\\ TAB SELECT EVENTS
pro DCAI_Scanner::TabEvent, event
	self.current_tab = event.tab
end


;\\ CLEANUP
pro DCAI_Scanner::cleanup, arg

	COMMON DCAI_Control, dcai_global

	self->DCAI_Plugin::cleanup

end


;\\ DEFINITION
pro DCAI_Scanner__define

	COMMON DCAI_Control, dcai_global

	n_etalons = n_elements(dcai_global.settings.etalon)

	state = {DCAI_Scanner, leg_bar_ids:intarr(n_etalons, 3), $
						   leg_val_ids:intarr(n_etalons, 3), $
						   wavelength:0.0, $
						   norm_etalons:intarr(n_etalons), $
						   norm_start:lonarr(n_etalons), $
						   norm_channels:0L, $
						   man_etalons:intarr(n_etalons), $
						   man_start:lonarr(n_etalons), $
						   man_step:lonarr(n_etalons), $
						   man_channels:lonarr(n_etalons), $
						   wave_etalons:intarr(n_etalons), $
						   wave_start:0.0, $
						   wave_stop:0.0, $
						   wave_channels:0L, $
						   wave_slider_ids:lonarr(4), $	;\\ slider, min label, max label
						   status:0L, $
						   scanning:0, $
						   scan_type:'', $
						   current_tab:0, $
						   INHERITS DCAI_Plugin}
end
