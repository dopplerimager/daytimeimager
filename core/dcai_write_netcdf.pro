
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
		xdim_id = 		ncdf_dimdef(ncdid, 'XDim',    data.image_size[0])
		ydim_id = 		ncdf_dimdef(ncdid, 'YDim',    data.image_size[1])
		range_dim_id =  ncdf_dimdef(ncdid, 'Range', 2)
		etalon_dim_id = ncdf_dimdef(ncdid, 'Etalon', 2)
		etalon_leg_dim_id = ncdf_dimdef(ncdid, 'EtalonLeg', 3)

		start_date_ut = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$_0n$_0d$')

		;\\ CREATE THE VARIABLES
		id = ncdf_vardef  (ncdid, 'Start_Date_UT',  /char)
		id = ncdf_vardef  (ncdid, 'Site',      		/char)
		id = ncdf_vardef  (ncdid, 'Site_Code',      /char)
		id = ncdf_vardef  (ncdid, 'Latitude',      	/float)
		id = ncdf_vardef  (ncdid, 'Longitude',      /float)

		id = ncdf_vardef  (ncdid, 'Start_Time',      time_dim_id, 	/long)
		id = ncdf_vardef  (ncdid, 'End_Time',        time_dim_id, 	/long)
    	id = ncdf_vardef  (ncdid, 'Number_Scans',    time_dim_id, 	/short)

      	id = ncdf_vardef  (ncdid, 'Cam_Temp',        time_dim_id, 	/float)
      	id = ncdf_vardef  (ncdid, 'Cam_Gain',        time_dim_id, 	/short)
      	id = ncdf_vardef  (ncdid, 'Cam_Exptime',     time_dim_id, 	/float)

      	id = ncdf_vardef  (ncdid, 'Image_Center',    range_dim_id, 	/short)
      	id = ncdf_vardef  (ncdid, 'Image_Binning',   range_dim_id,   /short)
      	id = ncdf_vardef  (ncdid, 'Image_Size',      range_dim_id, 	/short)

       	id = ncdf_vardef  (ncdid, 'Scan_Channels',        			/short)
       	id = ncdf_vardef  (ncdid, 'Spectral_Channels',        		/short)
		id = ncdf_vardef  (ncdid, 'Wavelength',      	  			/float)
		id = ncdf_vardef  (ncdid, 'Wavelength_Range', range_dim_id, /float)
		id = ncdf_vardef  (ncdid, 'Wavelength_Range_Full', range_dim_id, /float)
		id = ncdf_vardef  (ncdid, 'Wavelength_Axis', chan_dim_id, /float)

		id = ncdf_vardef  (ncdid, 'Etalon_Gap_mm', etalon_dim_id, 	/float)
		id = ncdf_vardef  (ncdid, 'Etalon_Stepsperorder', etalon_dim_id, 	/float)
		id = ncdf_vardef  (ncdid, 'Etalon_Parallel_Offset', [etalon_dim_id,etalon_leg_dim_id], 	/long)

		id = ncdf_vardef  (ncdid, 'Spectra', [zone_dim_id, chan_dim_id, time_dim_id], /long)
		id = ncdf_vardef  (ncdid, 'Accumulated_Image', [xdim_id, ydim_id, time_dim_id], /long)

		;\\ WRITE THE ATTRIBUTES
		ncdf_attput, ncdid, ncdf_varid(ncdid, 'Start_Date_UT'),        'Units', 'UT Start date in YYYY_MM_DD format', /char
		ncdf_attput, ncdid, ncdf_varid(ncdid, 'Site'),        		   'Units', 'Site name string', /char
		ncdf_attput, ncdid, ncdf_varid(ncdid, 'Site_Code'),        	   'Units', 'Site code string', /char
		ncdf_attput, ncdid, ncdf_varid(ncdid, 'Latitude'),        	   'Units', 'Site geodetic latitude in degrees', /char
		ncdf_attput, ncdid, ncdf_varid(ncdid, 'Longitude'),        	   'Units', 'Site geodetic longitude in degrees', /char

		ncdf_attput, ncdid, ncdf_varid(ncdid, 'Start_Time'),           'Units', 'Julian seconds', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'End_Time'),             'Units', 'Julian seconds', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Number_Scans'),         'Units', 'Etalon scans', /char

       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Image_Center'),         'Units', 'Image [x,y] center in pixels', /char
		ncdf_attput, ncdid, ncdf_varid(ncdid, 'Image_Binning'),        'Units', 'Image [x,y] binning in pixels', /char
		ncdf_attput, ncdid, ncdf_varid(ncdid, 'Image_Size'),           'Units', 'Image [x,y] dimensions in pixels (accounting for binning)', /char

       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Cam_Temp'),             'Units', 'Degrees', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Cam_Gain'),             'Units', 'Dimensionless', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Cam_Exptime'),          'Units', 'Seconds', /char

       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Scan_Channels'),        'Units', 'Number of scan channels', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Spectral_Channels'),    'Units', 'Number of spectral channels', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Wavelength'),   		   'Units', 'nm', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Wavelength_Range'),     'Units', 'nm', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Wavelength_Range_Full'),'Units', 'nm', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Wavelength_Axis'),	   'Units', 'nm', /char

       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Etalon_Gap_mm'),		   'Units', 'mm', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Etalon_Stepsperorder'), 'Units', 'Etalon digital units per nm', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Etalon_Parallel_Offset'), 'Units', 'Etalon digital units', /char

       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Spectra'),              'Units', 'Camera digital units', /char
       	ncdf_attput, ncdid, ncdf_varid(ncdid, 'Accumulated_Image'),    'Units', 'Camera digital units', /char

		ncdf_control, ncdid, /endef

		;\\ WRITE THE STATIC VARIABLES
		ncdf_varput, ncdid, ncdf_varid(ncdid, 'Start_Date_UT'),	    	start_date_ut
		ncdf_varput, ncdid, ncdf_varid(ncdid, 'Site'),	        		header.site
		ncdf_varput, ncdid, ncdf_varid(ncdid, 'Site_Code'),	        	header.site_code
		ncdf_varput, ncdid, ncdf_varid(ncdid, 'Latitude'),	        	header.latitude
		ncdf_varput, ncdid, ncdf_varid(ncdid, 'Longitude'),	        	header.longitude

		ncdf_varput, ncdid, ncdf_varid(ncdid, 'Image_Center'),	        data.image_center
      	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Image_Binning'),         data.image_binning
      	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Image_Size'),	        data.image_size

      	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Scan_Channels'),         data.scan_channels
      	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Spectral_Channels'),     data.spectral_channels
       	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Wavelength'),  		    data.wavelength
       	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Wavelength_Range'),      data.wavelength_range
       	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Wavelength_Range_Full'), data.wavelength_range_full
       	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Wavelength_Axis'), 		data.wavelength_axis

       	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Etalon_Gap_mm'), 		data.etalon_gap
       	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Etalon_Stepsperorder'), 	data.etalon_stepsperorder
       	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Etalon_Parallel_Offset'),data.etalon_parallel_offset

		;\\ UPDATE THE DISK COPY
		ncdf_control, ncdid, /sync
		ncdf_close, ncdid

	endif else begin ;\\ END NEW FILE

		;\\ MAKE SURE FILE EXISTS
		if file_test(filename) eq 0 then begin
			errcode = 'File does not exist'
			return
		endif

		ncdid = ncdf_open(filename, /write)

		;\\ GET THE TIME INDEX
		ncdf_diminq, ncdid, ncdf_dimid(ncdid, 'Time'), dummy, time_index
		ncdf_control, ncdid, /sync

		;\\ WRITE THE VARIABLES
		ncdf_varput, ncdid, ncdf_varid(ncdid, 'Start_Time'),            data.start_time, 	offset = [time_index]
      	ncdf_varput, ncdid, ncdf_varid(ncdid, 'End_Time'),              data.end_time,   	offset = [time_index]
      	ncdf_varput, ncdid, ncdf_varid(ncdid, 'Number_Scans'),          data.nscans,     	offset = [time_index]
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
