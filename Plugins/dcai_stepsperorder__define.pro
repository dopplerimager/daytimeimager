@dcai_script_utilities

function DCAI_StepsperOrder::init

	common DCAI_Control, dcai_global

	;\\ DEFAULTS
		self.ref_image = ptr_new(/alloc)
		self.images = ptr_new(/alloc)
		self.xcorrs = ptr_new(/alloc)
		self.stepsperorder = ptr_new(/alloc)
		self.nscans[*] = 10
		self.acquire_ref[*] = 0

	;\\ SAVE FIELDS
		self.save_tags = ['etalon', 'step', 'start', 'stop', 'nscans', 'wavelength_nm']

	;\\ RESTORE SAVED SETTINGS
		self->load_settings
		etalon = dcai_global.settings.etalon

	;\\ CREATE THE GUI
		font = dcai_global.gui.font
		_base = widget_base(group=dcai_global.gui.base, col=1, uval={tag:'plugin_base', object:self}, title = 'Steps per Order', $
							xoffset = self.xpos, yoffset = self.ypos, tab_mode=1)
		view_1 = widget_draw(_base, xs = 550, ys = 200, /align_center)
		draw_base = widget_base(_base, col=2, /align_center)
		view_2 = widget_draw(draw_base, xs = 348, ys = 200, /align_center)
		view_3 = widget_draw(draw_base, xs = 200, ys = 200, /align_center)

		self.status_id = widget_label(_base, xs = 500, font=font + '*Bold', value='Status: Idle', /align_left)

		edit_base = widget_base(_base, col = 1, /base_align_center, /align_center)

			scan_base = widget_base(edit_base, col = n_elements(dcai_global.settings.etalon), /align_center)

			for k = 0, n_elements(etalon) - 1 do begin
				;\\ SCAN CONTROL FIELDS
					scan_base_sub = widget_base(scan_base, row=2, frame=1)
					label = widget_label(scan_base_sub, value = 'Etalon ' + string(k, f='(i0)'), font=font+'*Bold')

					offset_edit = widget_base(scan_base_sub, row = 2)
					widget_edit_field, offset_edit, label = 'Scan Start', font = font, start_val=string(self.start[k], f='(i0)'), $
								edit_uval = {tag:'plugin_event', object:self, method:'ScanEdit', param:'start', etalon:k}, edit_xs = 10, ids=ids
					self.edit_ids.start[k] = ids.text

					widget_edit_field, offset_edit, label = 'Scan Stop', font = font, start_val=string(self.stop[k], f='(i0)'), $
								edit_uval = {tag:'plugin_event', object:self, method:'ScanEdit', param:'stop', etalon:k}, edit_xs = 10, ids=ids
					self.edit_ids.stop[k] = ids.text

					widget_edit_field, offset_edit, label = 'Scan Step', font = font, start_val=string(self.step[k], f='(i0)'), $
								edit_uval = {tag:'plugin_event', object:self, method:'ScanEdit', param:'step', etalon:k}, edit_xs = 10, ids=ids
					self.edit_ids.step[k] = ids.text

					widget_edit_field, offset_edit, label = '# Scans', font = font, start_val=string(self.nscans[k], f='(i0)'), $
								edit_uval = {tag:'plugin_event', object:self, method:'ScanEdit', param:'nscans', etalon:k}, edit_xs = 10, ids=ids
					self.edit_ids.nscans[k] = ids.text

					widget_edit_field, offset_edit, label = 'Wavelength (nm)', font = font, start_val=string(self.wavelength_nm[k], f='(f0.3)'), $
								edit_uval = {tag:'plugin_event', object:self, method:'ScanEdit', param:'wavelength', etalon:k}, edit_xs = 10, ids=ids
					self.edit_ids.wavelength[k] = ids.text
			endfor

			etalon_base = widget_base(edit_base, /exclusive, col=2)
			for k = 0, n_elements(etalon) - 1 do begin
				btn = widget_button(etalon_base, value = 'Etalon ' + string(k, f='(i0)'), font=font, $
									uval={tag:'plugin_event', object:self, method:'EtalonSelect', etalon:k})
				if self.etalon eq k then widget_control, btn, /set_button
				self.edit_ids.etalon[k] = btn
			endfor

			;\\ SCAN CONTROL BUTTONS
				btn_base = widget_base(edit_base, col = 4)
					scan_btn = widget_button(btn_base, value = 'Start', font=font, xs=80, uval = {tag:'plugin_event', object:self, method:'Scan', action:'start'})
					scan_btn = widget_button(btn_base, value = 'Stop', font=font, xs=80, uval = {tag:'plugin_event', object:self, method:'Scan', action:'stop'})
					scan_btn = widget_button(btn_base, value = 'Pause ', font=font, xs=80, uval = {tag:'plugin_event', object:self, method:'Scan', action:'pause'})
					scan_btn = widget_button(btn_base, value = 'UnPause ', font=font, xs=80, uval = {tag:'plugin_event', object:self, method:'Scan', action:'unpause'})


	;\\ REGISTER FOR FRAME EVENTS
		DCAI_Control_RegisterPlugin, _base, self, /frame

		widget_control, get_value = wind_id1, view_1
		widget_control, get_value = wind_id2, view_2
		widget_control, get_value = wind_id3, view_3

		self.window_ids = [wind_id1, wind_id2, wind_id3]

	self.id = _base
	return, 1
end


;\\ FRAME EVENT
pro DCAI_StepsperOrder::frame

	COMMON DCAI_Control, dcai_global

	tvlct, ct_r, ct_g, ct_b, /get

	status = ''
	case self.scanning of
		0: status = 'Status: Idle'
		1: status = 'Status: Scanning, Scan # ' + string(self.current_scan + 1, f='(i0)') + '/' + $
					string(self.nscans[self.etalon], f='(i0)') + ', Step # ' + string(dcai_global.scan.channel[self.etalon] + 1, f='(i0)') + $
					'/' + string(n_elements(*self.xcorrs), f='(i0)')
		2: status = 'Status: Paused'
		else: status = 'Status: Unknown'
	endcase

	if self.acquire_ref[0] eq 1 then status = 'Status: Acquiring reference image, ' + string(systime(/sec) - self.acquire_ref[1], f='(f0.2)')

	widget_control, set_value = status, self.status_id

	if self.scanning ne 1 and self.acquire_ref[0] ne 1 then return

	;\\ HERE WE ARE WAITING FOR A REFERENCE IMAGE
	if self.acquire_ref[0] eq 1 then begin
		elapsed_time = systime(/sec) - self.acquire_ref[1]

		;\\ IF WE HAVE WAITED LONG ENOUGH, USE THIS FRAME AS A REFERENCE, AND START SCANNING
		if elapsed_time gt 5 then begin

			*self.ref_image += *dcai_global.info.image
			self.acquire_ref = [0, 0]

			;\\ SHOW THE REFERENCE IMAGE
			wset, self.window_ids[2]
			tvscl, congrid(*self.ref_image, 200, 200)

			args = 0
			succes = 0
			args = {caller:self, etalon:self.etalon, n_channels:ceil((self.stop[self.etalon]-self.start[self.etalon])/float(self.step[self.etalon])), $
				    step_size:self.step[self.etalon], start_voltage:dcai_global.settings.etalon[self.etalon].scan_voltage + self.start[self.etalon]}

			success = DCAI_ScanControl('start', 'manual', args)
			if success eq 1 then self.scanning = 1
		endif
		return
	endif


	;\\ HERE WE ARE SCANNING
	channel = dcai_global.scan.channel[self.etalon]
	if self.scanning eq 1 and channel ge 0 then begin

		nsteps = float(dcai_global.scan.n_channels[self.etalon])
		new_frame = *dcai_global.info.image

		(*self.images)[*,*,channel] += new_frame
		cross_corr = total(reform((*self.images)[*,*,channel]) * (*self.ref_image)) / (2*float(n_elements((*self.images)[*,*,0])))
		(*self.xcorrs)[channel] = cross_corr


		;\\ PLOT CURRENT XCORR HISTORY
			wset, self.window_ids[0]
			use = where(*self.xcorrs ne 0, nuse)
			if nuse gt 2 then begin
				xarr = (findgen(n_elements(*self.xcorrs)))*float(self.step[self.etalon]) + float(self.start[self.etalon])

				plot, xarr[use], (*self.xcorrs)[use], psym=6, sym=.5, thick=2, $
					  xtitle='Channel', ytitle='Cross-Correlation', $
					  yrange=[min((*self.xcorrs)[use]), max((*self.xcorrs)[use])], /ystyle, /xstyle


			endif


		;\\ LAST IMAGE IN THE SCAN, CALCULATE THE STEPS/ORDER
		if channel eq (dcai_global.scan.n_channels[self.etalon] - 1) then begin

			xarr = (dindgen(nsteps))*float(self.step[self.etalon]) + float(self.start[self.etalon])
			corr = double(*self.xcorrs)

			xmin = 3
			fit_order = 3
			fit = poly_fit(xarr[xmin:*], corr[xmin:*], fit_order, yfit = curve, /double)

			dd = findgen(fit_order) + 1
			dd = dd * fit[1:*]
		 	dd = float(fz_roots(dd))
	    	ddy  = poly(dd, fit)
	    	best = where(ddy eq max(ddy))
	    	peak = dd[best[0]]
	    	(*self.stepsperorder)[self.current_scan] = peak


			;\\ PLOT THE XCORR AND FITTED CURVE
				wset, self.window_ids[0]
				loadct, 0, /silent
				plot, xarr, corr, psym=1, thick=2, xtitle='Channel', ytitle='Cross-Correlation', $
					  yrange=[min(corr), max(corr)], /ystyle, /nodata, /xstyle
				oplot, xarr, corr, color = 200, psym=6, sym=.5, thick=2
				loadct, 39, /silent
				oplot, xarr[xmin:*], curve, color=150, thick=1.5
				plots, [peak, peak], [min(corr), max(corr)], color = 90, thick=2
				xyouts, peak, min(corr) + 0.34*(max(corr) - min(corr)), 'Peak: ' + string(peak, f='(e0.4)'), $
						color = 90, align=-.1, chars=1

				if self.current_scan gt 0 then begin
					last = (*self.stepsperorder)[self.current_scan-1]
					change = string(100.*(peak - last)/last, f='(f0.4)') + '%'
				endif else begin
					change = 'N/A'
				endelse

				xyouts, peak, min(corr) + 0.22*(max(corr) - min(corr)), '!7D!3 Peak: ' + change, $
						color = 90, align=-.1, chars=1

				xyouts, peak, min(corr) + 0.1*(max(corr) - min(corr)), 'SPO: ' + string(peak/self.wavelength_nm[self.etalon], f='(f0.4)'), $
						color = 90, align=-.1, chars=1


			;\\ PLOT THE SPO HISTORY
				wset, self.window_ids[1]
				history = (*self.stepsperorder)/self.wavelength_nm[self.etalon]
				use = where(history ne 0, nuse)

				plot, use + 1, history, psym=1, thick=2, yrange = [(min(history[use])), (max(history[use]))], $
					  xtitle='Scan #', ytitle='Steps/Order', /nodata, xtickint = 1, $
					  xrange=[1, self.nscans[self.etalon]], /xstyle
				if nuse gt 0 then begin
					loadct, 0, /silent
					oplot, use + 1, history[use], psym=6, thick=2, sym=.5, color = 250
					loadct, 39, /silent
					oplot, use + 1, history[use], thick=1, color = 90
				endif

			;\\ INCREMENT THE SCAN NUMBER
			self.current_scan ++

			;\\ DO WE NEED TO DO ANOTHER SCAN?
			if self.current_scan ne self.nscans[self.etalon] then begin
				;\\ SET UP ANOTHER SCAN

				(*self.xcorrs)[*] = 0
				success = DCAI_ScanControl('setnominal', 'dummy', $
					{etalon:self.etalon, voltage:dcai_global.settings.etalon[self.etalon].scan_voltage})
				widget_control, set_value='Status: Driving to Ref Position and Waiting...', self.status_id
				wait, 5
				;\\ FLUSH THE CAMERA IMAGES
				call_procedure, dcai_global.info.drivers, {device:'camera_flush'}

				self.acquire_ref = [1,systime(/sec)]
				self.scanning = 0

			endif else begin
				;\\ DONE SCANNING, RECORD A FINAL STEPS/ORDER

				final_spo = (*self.stepsperorder)[n_elements(*self.stepsperorder)-1]
				final_spo /= self.wavelength_nm[self.etalon]
				dcai_global.settings.etalon[self.etalon].steps_per_order = final_spo

				;\\ SAVE THE SETTINGS
				DCAI_Control_SaveSettings

				success = DCAI_ScanControl('stop', 'manual', {caller:self, etalon:self.etalon})
				if success eq 1 then self.scanning = 0


				;\\ IF REQUESTED, CLOSE THE PLUGIN NOW THAT IT IS FINISHED
				if self.close_on_finish eq 1 then begin
					;\\ UNSET AS ACTIVE PLUGIN
					success = self->unset_active(self->uid())
					if success eq 1 then begin
						DCAI_Control_Cleanup, 0, object=self
					endif else begin
						DCAI_Log, 'ERROR: Unable to UNset as active plugin: ' + self->uid() + $
								  ', plugin was not auto-closed on finish!'
					endelse
				endif

			endelse
		endif

	endif

	tvlct, ct_r, ct_g, ct_b

end



;\\ SCAN EDIT
pro DCAI_StepsperOrder::ScanEdit, event

	COMMON DCAI_Control, dcai_global

	widget_control, get_uval = uval, event.id
	widget_control, get_value = val, event.id
	case uval.param of
		'start': begin
			if self.scanning eq 0 and self.acquire_ref[0] eq 0 then begin
				self.start[uval.etalon] = fix(val, type=3)
			endif else begin
				widget_control, set_value=string(self.start[uval.etalon], f='(i0)'), event.id
			endelse
		end
		'stop':begin
			if self.scanning eq 0 and self.acquire_ref[0] eq 0 then begin
				self.stop[uval.etalon]  = fix(val, type=3)
			endif else begin
				widget_control, set_value=string(self.stop[uval.etalon], f='(i0)'), event.id
			endelse
		end
		'step':begin
			if self.scanning eq 0 and self.acquire_ref[0] eq 0 then begin
				self.step[uval.etalon]  = fix(val, type=3)
			endif else begin
				widget_control, set_value=string(self.step[uval.etalon], f='(i0)'), event.id
			endelse
		end
		'nscans':begin
			if self.scanning eq 0 and self.acquire_ref[0] eq 0 then begin
				self.nscans[uval.etalon] = fix(val, type=3)
			endif else begin
				widget_control, set_value=string(self.nscans[uval.etalon], f='(i0)'), event.id
			endelse
		end
		'wavelength':begin
			if self.scanning eq 0 and self.acquire_ref[0] eq 0 then begin
				self.wavelength_nm[uval.etalon] = fix(val, type=4)
			endif else begin
				widget_control, set_value=string(self.wavelength_nm[uval.etalon], f='(i0)'), event.id
			endelse
		end
	endcase
end


;\\ SELECT ETALON
pro DCAI_StepsperOrder::EtalonSelect, event
	widget_control, get_uval=uval, event.id
	if self.scanning eq 0 and self.acquire_ref[0] eq 0 then begin
		if event.select eq 1 then self.etalon = uval.etalon
	endif else begin
		widget_control, set_button=1, self.edit_ids.etalon[self.etalon]
	endelse
end


;\\ SCAN CONTROL
pro DCAI_StepsperOrder::Scan, event, action=action

	COMMON DCAI_Control, dcai_global

	if not keyword_set(action) then begin
		widget_control, get_uval = uval, event.id
		action = uval.action
	endif

	args = 0
	success = 0
	args = {caller:self, etalon:self.etalon, n_channels:ceil((self.stop[self.etalon]-self.start[self.etalon])/float(self.step[self.etalon])), $
		    step_size:self.step[self.etalon], start_voltage:dcai_global.settings.etalon[self.etalon].scan_voltage + self.start[self.etalon]}

	case action of
		'start': begin
			;\\ IF IN AUTO MODE, TRY TO SET AS ACTIVE PLUGIN
				success = 0
				if self.auto_mode eq 1 then success = self->set_active(self->uid()) else success = 1
				if success eq 0 then return

			if args.n_channels le 0 then return
			if self.scanning ne 1 and self.acquire_ref[0] ne 1 then begin

				;\\ WEDGE THE INACTIVE ETALON
				if n_elements(dcai_global.settings.etalon) gt 1 then begin
					inactive_etalon = 1 - self.etalon
					volts = dcai_global.settings.etalon[inactive_etalon].wedge_voltage
					dcai_global.settings.etalon[inactive_etalon].leg_voltage = volts

					command = {device:'etalon_setlegs', number:inactive_etalon, $
									   port:dcai_global.settings.etalon[inactive_etalon].port, $
									   voltage:dcai_global.settings.etalon[inactive_etalon].leg_voltage}
					call_procedure, dcai_global.info.drivers, command
				endif


				dims = size(*dcai_global.info.image, /dimensions)
				*self.images = lonarr(dims[0], dims[1], args[0].n_channels)
				*self.ref_image = lonarr(dims[0], dims[1])
				*self.xcorrs = fltarr(args[0].n_channels)
				*self.stepsperorder = fltarr(self.nscans[self.etalon])
				self.current_scan = 0

				;\\ NEED TO GET A REFERENCE IMAGE, SO DRIVE TO NORMAL SCAN START POSITION, AND WAIT
				;\\ A WHILE TO ALLOW A FEW FRAMES TO COME THROUGH
				success = DCAI_ScanControl('setnominal', 'dummy', $
					{etalon:self.etalon, voltage:dcai_global.settings.etalon[self.etalon].scan_voltage})
				widget_control, set_value='Status: Driving to Ref Position and Waiting...', self.status_id
				wait, 5
				;\\ FLUSH THE CAMERA IMAGES
				call_procedure, dcai_global.info.drivers, {device:'camera_flush'}

				self.acquire_ref = [1,systime(/sec)]
			endif
		end

		'stop':begin
			;\\ IF IN AUTO MODE, TRY TO UNSET AS ACTIVE PLUGIN
				success = 0
				if self.auto_mode eq 1 then success = self->unset_active(self->uid()) else success = 1
				if success eq 0 then return

			success = DCAI_ScanControl('stop', 'manual', args)
			if success eq 1 then begin
				self.scanning = 0
				self.acquire_ref = [0,0]
			endif
		end

		'pause':begin
			success = DCAI_ScanControl('pause', 'manual', args)
			if success eq 1 then self.scanning = 2
		end

		'unpause':begin
			success = DCAI_ScanControl('unpause', 'manual', args)
			if success eq 1 then self.scanning = 1
		end

		else:
	endcase
end


;\\ EXECUTE COMMANDS SENT FROM A SCHEDULE FILE
pro DCAI_StepsperOrder::ScheduleCommand, command, keywords, values

	COMMON DCAI_Control, dcai_global

	if self.scanning ne 0 then return

	;\\ FLAG AUTO MODE
	self.auto_mode = 1

	;\\ HANDLE KEYWORDS
	;\\ FIND THE ETALON KEYWORD FIRST, SO WE KNOW WHICH SET OF VALUES TO UPDATE
	match = where(keywords eq 'etalon', nmatch)
	if nmatch eq 1 then self.etalon = fix(values[match])
	widget_control, set_button = 1, self.edit_ids.etalon[self.etalon]

	for k = 0, n_elements(keywords) - 1 do begin
		case keywords[k] of
			'close_on_finish': self.close_on_finish = 1
			'start':begin
				self.start[self.etalon] = fix(values[k])
				widget_control, set_value=string(self.start[self.etalon], f='(i0)'), self.edit_ids.start[self.etalon]
			end
			'stop':begin
				self.stop[self.etalon] = fix(values[k])
				widget_control, set_value=string(self.stop[self.etalon], f='(i0)'), self.edit_ids.stop[self.etalon]
			end
			'step':begin
				self.step[self.etalon] = fix(values[k])
				widget_control, set_value=string(self.step[self.etalon], f='(i0)'), self.edit_ids.step[self.etalon]
			end
			'wavelength':begin
				self.wavelength_nm[self.etalon] = float(values[k])
				widget_control, set_value=string(self.wavelength_nm[self.etalon], f='(f0.2)'), self.edit_ids.wavelength[self.etalon]
			end
			'nscans':begin
				self.nscans[self.etalon] = fix(values[k])
				widget_control, set_value=string(self.nscans[self.etalon], f='(i0)'), self.edit_ids.nscans[self.etalon]
			end
			'etalon':
			else: DCAI_Log, 'WARNING: Keyword not recognized by StepsperOrder plugin: ' + keywords[k]
		endcase
	endfor

	case command of

		'start':begin

			;\\ IF WE ARE NOT IN AUTO MODE, WE SHOULD NOT BE GETTING THIS COMMAND
				if self.auto_mode eq 0 then return

			;\\ TRY TO SET AS ACTIVE PLUGIN
				success = self->set_active(self->uid())
				if success eq 1 then self->Scan, 0, action='start'
		end

		else: DCAI_Log, 'WARNING: Command not recognized by StepsperOrder plugin: ' + command
	endcase

end

;\\ BUILD A UID STRING FROM THIS OBJECT
function DCAI_StepsperOrder::uid, args=args
	return, 'stepsperorder_' + strjoin(string(self.wavelength_nm, f='(f0.2)'), '_')
end

;\\ CLEANUP
pro DCAI_StepsperOrder::Cleanup

	self->DCAI_Plugin::Cleanup
	ptr_free, self.ref_image, self.images, self.xcorrs, self.stepsperorder

end


;\\ DEFINITION
pro DCAI_StepsperOrder__define

	COMMON DCAI_Control, dcai_global

	n = n_elements(dcai_global.settings.etalon)
	state = {DCAI_StepsperOrder, window_ids:[0,0,0], $
								 status_id:0L, $
								 edit_ids:{spo_edit_ids, start:lonarr(n), stop:lonarr(n), step:lonarr(n), wavelength:lonarr(n), $
								 		   				 nscans:lonarr(n), etalon:lonarr(n)}, $
								 etalon:0, $
								 start:lonarr(n), $
								 stop:lonarr(n), $
								 step:lonarr(n), $
								 wavelength_nm:fltarr(n), $
								 nscans:intarr(n), $
								 current_scan:0, $
								 scanning:0, $
								 acquire_ref:[0D,0D], $
								 ref_image:ptr_new(), $
								 images:ptr_new(), $
								 xcorrs:ptr_new(), $
								 stepsperorder:ptr_new(), $
								 close_on_finish:0, $
						   		 INHERITS DCAI_Plugin}
end
