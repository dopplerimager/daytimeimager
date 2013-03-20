
@dcai_script_utilities

function DCAI_Script, info, reset=reset

  COMMON DCAI_Script_Common, block0_flag

  	;\\ Default queue is empty
  		queue = ['']

	;\\ Some housekeeping
		if IsDefined(block0_flag) eq 0 then block0_flag = 0
    	if keyword_set(reset) then begin
    	  block0_flag = 0
    	  return, queue
    	endif


	if block0_flag eq 0 then begin
		queue = [ $ ;'plugin, type=dcai_stepsperorder, command=start, etalon=0, wavelength=632.8, ' + $
				; 'nscans=5, start=20500, stop=23500, step=100, close_on_finish=1', $
				;
				; 'plugin, type=dcai_phasemapper, command=start, etalons=[0], wavelength=632.8, ' + $
				; 'channels=100, nscans=3, smoothing=5, close_on_finish=1', $
				;
				'plugin, type=dcai_spectrum, command=create, title=spex1, wavelength=632.8, ' + $
				'        channels=100, min_scans=2, max_scans = 7, min_snr = 1234, ' + $
				'        zonemap=c:\users\daytimeimager\scripts\zonemap\default_zones.txt, filename_format=Y$_d$_n$, ' + $
				'        etalons=[0]', $

				'plugin, type=dcai_spectrum, command=start, title=spex1', $
				'plugin, type=dcai_spectrum, command=start, title=spex1, min_scans = 4']

		block0_flag = 1
	endif

  	;\\ Just in case we missed all the time blocks
  	return, queue

end