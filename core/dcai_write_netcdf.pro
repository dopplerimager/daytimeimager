
pro DCAI_Write_NetCDF, 	filename, $
				 		new=new, $
                 		header=header, $
                 		data=data, $
                 		errcode=errcode

	errcode = 'ok'

	if keyword_set(new) then begin

		;\\ FILE DOES NOT EXIST, CREATE
		ncdid = ncdf_create(filename, /clobber)

		;\\ CREATE THE REQUIRED DIMENSIONS
		nchannels = n_elements(data.spectra(0,*))
		nzones = n_elements(data.spectra(*,0))

		chan_dim_id = 	ncdf_dimdef(ncdid, 'Channel', nchannels)
		zone_dim_id = 	ncdf_dimdef(ncdid, 'Zone',    nzones)
		time_dim_id = 	ncdf_dimdef(ncdid, 'Time',    /unlimited)
		xdim_id = 		ncdf_dimdef(ncdid, 'XDim',  data.x_pixels)
		ydim_id = 		ncdf_dimdef(ncdid, 'YDim',  data.y_pixels)
		range_dim_id =  ncdf_dimdef(ncdid, 'Range', 2)
		etalon_dim_id = ncdf_dimdef(ncdid, 'Etalon', 2)

		start_date_ut = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$_0d$_0n$')

		;\\ CREATE GLOBAL ATTRIBUTES
		ncdf_attput, ncdid, /global, 'Start_Date_UT',start_date_ut,    /char
		ncdf_attput, ncdid, /global, 'Site',      	 header.site,      /char
		ncdf_attput, ncdid, /global, 'Site_code', 	 header.site_code, /char
		ncdf_attput, ncdid, /global, 'Latitude',  	 header.latitude,  /float
		ncdf_attput, ncdid, /global, 'Longitude', 	 header.longitude, /float
		ncdf_attput, ncdid, /global, 'Operator',  	 header.operator,  /char
		ncdf_attput, ncdid, /global, 'Comment',   	 header.comment,   /char
		ncdf_attput, ncdid, /global, 'Software',  	 header.software,  /char

		;\\ CREATE THE VARIABLES
		id = ncdf_vardef  (ncdid, 'Start_Time',      time_dim_id, 	/long)
		id = ncdf_vardef  (ncdid, 'End_Time',        time_dim_id, 	/long)
    	id = ncdf_vardef  (ncdid, 'Number_Scans',    time_dim_id, 	/short)
       	id = ncdf_vardef  (ncdid, 'X_Center',        time_dim_id, 	/float)
      	id = ncdf_vardef  (ncdid, 'Y_Center',        time_dim_id, 	/float)
      	id = ncdf_vardef  (ncdid, 'Cam_Temp',        time_dim_id, 	/float)
      	id = ncdf_vardef  (ncdid, 'Cam_Gain',        time_dim_id, 	/short)
      	id = ncdf_vardef  (ncdid, 'Cam_Exptime',     time_dim_id, 	/float)
      	id = ncdf_vardef  (ncdid, 'X_Bin',             	  			/short)
      	id = ncdf_vardef  (ncdid, 'Y_Bin',                			/short)
       	id = ncdf_vardef  (ncdid, 'Scan_Channels',        			/short)
       	id = ncdf_vardef  (ncdid, 'Spectral_Channels',        		/short)
		id = ncdf_vardef  (ncdid, 'Wavelength',      	  			/float)
		id = ncdf_vardef  (ncdid, 'Wavelength_Range', range_dim_id, /float)
		id = ncdf_vardef  (ncdid, 'Wavelength_Range_Full', range_dim_id, /float)
		id = ncdf_vardef  (ncdid, 'Etalon_Gap_mm', etalon_dim_id, 	/float)
		id = ncdf_vardef  (ncdid, 'Spectra', [zone_dim_id, chan_dim_id, time_dim_id], /long)
		id = ncdf_vardef  (ncdid, 'Accumulated_Image', [xdim_id, ydim_id, time_dim_id], /long)

		;\\ WRITE THE ATTRIBUTES
		ncdf_attput, ncdid, ncdf_varid(ncdid, 'Start_Time'),           'Units', 'Julian seconds', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'End_Time'),             'Units', 'Julian seconds', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Number_Scans'),         'Units', 'Etalon scans', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'X_Center'),             'Units', 'Image pixel number', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Y_Center'),             'Units', 'Image pixel number', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Cam_Temp'),             'Units', 'Degrees', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Cam_Gain'),             'Units', 'Dimensionless', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Cam_Exptime'),          'Units', 'Seconds', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'X_Bin'), 	           'Units', 'Image x binning in pixels', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Y_Bin'),     	       'Units', 'Image y binning in pixels', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Scan_Channels'),        'Units', 'Number of scan channels', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Spectral_Channels'),    'Units', 'Number of spectral channels', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Wavelength'),   		   'Units', 'nm', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Wavelength_Range'),     'Units', 'nm', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Wavelength_Range_Full'),'Units', 'nm', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Etalon_Gap_mm'),		   'Units', 'mm', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Spectra'),              'Units', 'Camera digital units', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Accumulated_Image'),    'Units', 'Camera digital units', /char

		ncdf_control, ncdid, /endef

		;\\ WRITE THE STATIC VARIABLES
		ncdf_varput, ncdid, ncdf_varid(ncdid, 'X_Bin'),	                data.x_bin
      	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Y_Bin'),                 data.y_bin
      	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Scan_Channels'),         data.scan_channels
      	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Spectral_Channels'),     data.spectral_channels
       	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Wavelength'),  		    data.wavelength
       	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Wavelength_Range'),      data.wavelength_range
       	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Wavelength_Range_Full'), data.wavelength_range_full
       	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Etalon_Gap_mm'), 		data.etalon_gap

		;\\ UPDATE THE DISK COPY
		ncdf_control, ncdid, /sync
		ncdf_close, ncdid

	endif else begin ;\\ END NEW FILE

		;\\ MAKE SURE FILE EXISTS
		if file_test(filename) eq 0 then begin
			errcode = 'File does not exist'
			return
		endif

		ncdid = ncdf_open(fname, /write)

		;\\ GET THE TIME INDEX
		ncdf_diminq, ncdid, ncdf_dimid(ncdid, 'Time'), dummy, time_index
		ncdf_control, ncdid, /sync

		;\\ WRITE THE VARIABLES
		ncdf_varput, ncdid, ncdf_varid(ncdid, 'Start_Time'),            data.start_time, 	offset = [time_index]
      	ncdf_varput, ncdid, ncdf_varid(ncdid, 'End_Time'),              data.end_time,   	offset = [time_index]
      	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Number_Scans'),          data.nscans,     	offset = [time_index]
		ncdf_varput, ncdid, ncdf_varid(ncdid, 'X_Center'),              data.x_center, 		offset = [time_index]
      	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Y_Center'),              data.y_center, 		offset = [time_index]
       	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Cam_Temp'),  	    	data.cam_temp, 		offset = [time_index]
       	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Cam_Gain'),  		    data.cam_gain, 		offset = [time_index]
       	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Cam_Exptime'), 	 	    data.cam_exptime, 	offset = [time_index]
       	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Spectra'), 				data.spectra, 		offset = [0,0,time_index]
       	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Accumulated_Image'), 	data.acc_im, 		offset = [0,0,time_index]

		;\\ UPDATE THE DISK COPY
		ncdf_control, ncdid, /sync
		ncdf_close, ncdid

	endelse ;\\ END UPDATE EXISITING FILE

end
