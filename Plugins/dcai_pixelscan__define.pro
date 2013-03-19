function DCAI_PixelScan::init

	common DCAI_Control, dcai_global

	if n_elements(dcai_global.settings.etalon) lt 2 then return, 0

	;\\ DEFAULTS
		dims = size(*dcai_global.info.image, /dimensions)
		self.pixel = dims/2
		self.history = ptr_new(/alloc)

	;\\ SAVE FIELDS
		self.save_tags = ['wave_start', 'wave_stop', 'wave_etalons', 'wave_channels', 'pixel', 'pixels_used']

	;\\ RESTORE SAVED SETTINGS
		self->load_settings

	;\\ CREATE THE GUI
		font = dcai_global.gui.font
		base = widget_base(group=dcai_global.gui.base, col=1, uval={tag:'plugin_base', object:self}, title = 'PixelScan', $
						   xoffset = self.xpos, yoffset = self.ypos, /base_align_center, tab_mode=1)

		draw = widget_draw(base, xs=500, ys=300)

		n_etalons = n_elements(dcai_global.settings.etalon)
		wavelength_base = widget_base(base, col=1, frame=1, /base_align_center, xs=500)
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

			;\\ PIXELS
			n_pixels = n_elements(self.pixels_used)
			pixel_base = widget_base(wavelength_base, col=n_pixels+1)
			for k = -1, n_pixels - 1 do begin
				pair_base = widget_base(pixel_base, col=1)
				if k eq -1 then begin
					label = widget_label(pair_base, font=font+'*Bold', value='Pixel', ys=30)
					label = widget_label(pair_base, font=font+'*Bold', value='Track', ys=30)
				endif else begin
					widget_edit_field, pair_base, label='', font = font, start_val=strjoin(string(self.pixel[k,*], f='(i0)'), ', '), /column, $
									   edit_uval = {tag:'plugin_event', object:self, method:'WaveEdit', field:'Pixel', id:k}, edit_xs = 7
					sub_base = widget_base(pair_base, col=1, /nonexclusive, /align_center)
					btn = widget_button(sub_base, value='', /align_center, $
									uval={tag:'plugin_event', object:self, method:'WaveEdit', field:'Track', id:k})
					if self.pixels_used[k] eq 1 then widget_control, /set_button, btn
				endelse
			endfor


		n_etalons = n_elements(dcai_global.settings.etalon)
		leg_bar_wids = lonarr(n_etalons, 3)

	DCAI_Control_RegisterPlugin, base, self, /frame

	widget_control, get_value=wind_id, draw
	self.window_id = wind_id

	self.id = base
	return, 1
end


;\\ FRAME EVENT
pro DCAI_PixelScan::frame

	COMMON DCAI_Control, dcai_global

	image = *dcai_global.info.image
	dims = size(image, /dimensions)
	channel = dcai_global.scan.channel[0]

	if size(*self.history, /type) ne 0 then begin

		loadct, 39, /silent
		wset, self.window_id


		;\\ WAVELENGTH OFFSET MAP
		use = where(self.pixels_used eq 1, n_use)
		offset_map = DCAI_ScanControl('getpixelwavelength', 'dummy', {nominal_wavelength:self.wave_start, $
										center_wavelength:0.0, pixel:[-1,-1]})

		max_offset = 0
		for k = 0, n_use - 1 do begin
			offset = abs(offset_map[self.pixel[use[k],0], self.pixel[use[k],1]])
			if offset gt max_offset then max_offset = offset
		endfor

		min_lambda = self.wave_start - max_offset
		max_lambda = self.wave_stop
		max_xaxis = interpol([min_lambda, max_lambda], [0,self.wave_channels], indgen(self.wave_channels))

		pts = where(*self.history ne 0, npts)
		if npts eq 0 then ymax = 0 else ymax = max((*self.history)[pts])

		plot, max_xaxis, *self.history, /nodata, yrange=[0, ymax], $
			  xtitle = 'Wavelength (nm)', /xstyle, /ystyle

		xaxis = interpol([self.wave_start, self.wave_stop], [0,self.wave_channels-1], indgen(self.wave_channels))

		for k = 0, n_elements(self.pixels_used) - 1 do begin

			x = self.pixel[k,0] > 0
			x = x < dims[0]
			y = self.pixel[k,1] > 0
			y = y < dims[1]

			if self.scanning eq 1 and channel ge 0 then (*self.history)[k, channel] += image[x,y]

			if self.pixels_used[k] eq 1 then begin
				yvals = (*self.history)[k, *]
				pts = where(yvals ne -999, npts)
				if npts gt 0 then $
					oplot, (xaxis + offset_map[x,y])[pts], yvals[pts], $
						color = 50 + 200*k/float(n_elements(self.pixels_used))
				if npts gt 6 then $
					oplot, (xaxis + offset_map[x,y])[pts], smooth(yvals[pts], 5, /edge), thick=2
			endif
		endfor
	endif


	if channel eq self.wave_channels - 1 then begin
		;\\ RESTART SCANNING, COADD SIGNAL
		etalons = where(self.wave_etalons eq 1, netalons)
		args = 0

		args = [{caller:self, etalon:0},{caller:self, etalon:1}]
		success = DCAI_ScanControl('stop', 'wavelength', args)
		print, 'Stop ', success
		if success eq 1 then self.scanning = 0

		arg = {caller:self, etalons:etalons, n_channels:self.wave_channels, $
			   wavelength_range_nm:[self.wave_start, self.wave_stop]}

		success = DCAI_ScanControl('start', 'wavelength', arg)
		print, 'Start ', success
		if success eq 1 then self.scanning = 1
	endif

	if dcai_global.scan.scanning[0] eq 0 then self.scanning = 0
end


;\\ WAVELENGTH SCAN EDITS
pro DCAI_PixelScan::WaveEdit, event
	COMMON DCAI_Control, dcai_global

	widget_control, get_uval=uval, event.id
	widget_control, get_val=val, event.id
	case uval.field of
		'StartWavelength': self.wave_start = fix(val, type=4)
		'StopWavelength': self.wave_stop = fix(val, type=4)
		'Channels': self.wave_channels = fix(val, type=3) > 1
		'Etalon': self.wave_etalons[uval.etalon] = event.select
		'Pixel': begin
			split = strtrim(strcompress(strsplit(val, ',', /extract), /remove), 2)
			if n_elements(split) ne 2 then begin
				widget_control, set_value=strjoin(string(self.pixel[uval.id,*], f='(i0)'), ', '), event.id
			endif else begin
				self.pixel[uval.id,*] = [fix(split[0], type=3), fix(split[1], type=3)]
			endelse
		end
		'Track': self.pixels_used[uval.id] = event.select
		else:
	endcase
end


;\\ SCAN ACTIONS
pro DCAI_PixelScan::Scan, event, struc=struc
	COMMON DCAI_Control, dcai_global

	if size(struc, /type) eq 8 then begin
		uval = struc
	endif else begin
		widget_control, get_uval=uval, event.id
	endelse

	etz = self.wave_etalons
	if uval.action ne 'Start' then begin
		args = 0
		for k = 0, n_elements(etz) - 1 do begin
			if etz[k] eq 1 then begin
				new_arg = {caller:self, etalon:k}
				if size(args, /type) eq 2 then args = new_arg else args = [args, new_arg]
			endif
		endfor
	endif


	case uval.action of
		'Start': begin

			if self.scanning eq 0 then begin

				if self.wave_channels le 0 then break

				etalons = where(self.wave_etalons eq 1, netalons)
				if netalons ne 0 then begin
					arg = {caller:self, etalons:etalons, n_channels:self.wave_channels, $
						   wavelength_range_nm:[self.wave_start, self.wave_stop]}
					success = DCAI_ScanControl('start', 'wavelength', arg)
					if success eq 1 then self.scanning = 1
				endif

				*self.history = dblarr(n_elements(self.pixels_used), self.wave_channels)
			endif
		end

		'Stop': begin
			if size(args, /type) ne 2 then begin
				success = DCAI_ScanControl('stop', 'dummy', args)
				if success eq 1 then self.scanning = 0
			endif
		end

		'Pause': begin
			if size(args, /type) ne 2 then begin
				success = DCAI_ScanControl('pause', 'dummy', args)
				if success eq 1 then self.scanning = 2
			endif
		end

		'UnPause': begin
			if size(args, /type) ne 2 then begin
				success = DCAI_ScanControl('unpause', 'dummy', args)
				if success eq 1 then self.scanning = 1
			endif
		end

		else:
	endcase

end


;\\ CLEANUP
pro DCAI_PixelScan::cleanup, arg

	COMMON DCAI_Control, dcai_global

	self->DCAI_Plugin::cleanup

end


;\\ DEFINITION
pro DCAI_PixelScan__define

	COMMON DCAI_Control, dcai_global

	n_etalons = n_elements(dcai_global.settings.etalon)

	state = {DCAI_PixelScan, window_id:0, $
							 pixel:intarr(5,2), $
							 pixels_used:intarr(5), $
						   	 wave_etalons:intarr(n_etalons), $
						   	 wave_start:0.0, $
						   	 wave_stop:0.0, $
						   	 wave_channels:0L, $
						   	 full_range:0.0, $
						   	 scanning:0, $
						   	 history:ptr_new(), $
						   	 INHERITS DCAI_Plugin}
end