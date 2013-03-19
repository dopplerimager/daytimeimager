
pro DCAI_Read_NetCDF, filename

	globals = [ $
		'Start_Date_UT', $
		'Site', $
		'Site_code', $
		'Latitude', $
		'Longitude', $
		'Operator', $
		'Comment', $
		'Software' $
	]

	names = [ $
		'Start_Time', $
		'End_Time',   $
	    'Number_Scans', $
	    'X_Center', $
	    'Y_Center', $
	    'Cam_Temp', $
	    'Cam_Gain', $
	    'Cam_Exptime', $
	    'X_Bin', $
	    'Y_Bin', $
	    'Scan_Channels', $
	    'Spectral_Channels', $
		'Wavelength', $
		'Wavelength_Range', $
		'Wavelength_Range_Full', $
		'Etalon_Gap_mm', $
		'Spectra', $
		'Accumulated_Image' $
	]


	data = {filename:filename}

	id = ncdf_open(filename)

		names = reverse(names)
		for i = 0, n_elements(names) - 1 do begin

			skip_read = 0
			varid = ncdf_varid(id, names[i])
			inq = ncdf_varinq(id, varid)

			if (inq.ndims gt 0) then begin
				for j = 0, inq.ndims - 1 do begin
					ncdf_diminq, id, inq.dim[j], name, sz
					if sz eq 0 then skip_read = 1
				endfor
			endif

			if skip_read eq 1 then begin
				print, 'Variable ' + names[i] + ' contained zero-length dimension, skipping...'
				continue
			endif

			ncdf_varget, id, varid, temp
			data = create_struct(names[i], temp, data)
		endfor

		globals = reverse(globals)
		for i = 0, n_elements(globals) - 1 do begin
			ncdf_attget, id, globals[i], temp, /global
			data = create_struct(globals[i], temp, data)
		endfor

	ncdf_close, id

	help, data, /str

end