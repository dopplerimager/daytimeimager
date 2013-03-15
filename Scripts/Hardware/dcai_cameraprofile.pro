

pro DCAI_Cameraprofile, settings = settings

	settings.imagemode = {xbin:1, ybin:1, xpixstart:200, xpixstop:700, ypixstart:200, ypixstop:700}
	settings.acqmode = 5
	settings.acqmode_str = ""
	settings.readmode = 4
	settings.readmode_str = ""
	settings.triggermode = 0
	settings.triggermode_str = ""
	settings.baselineclamp = 1
	settings.frametransfer = 1
	settings.fanmode = 0
	settings.cooleron = 1
	settings.shutteropen = 1
	settings.settemp = -80
	settings.curtemp = 0.0000000000
	settings.adchannel = 0
	settings.bitdepth = 0
	settings.outamp = 0
	settings.preampgaini = 0
	settings.preampgain = 0.0000000000
	settings.exptime_set = 0.1
	settings.exptime_use = 0.1
	settings.cnvgain_set = 0
	settings.emgain_set = 2
	settings.emgain_use = 7
	settings.emgain_mode = 0
	settings.emadvanced = 0
	settings.vsspeedi = 3
	settings.vsspeed = 0.0000000000
	settings.vsamplitude = 0
	settings.hsspeedi = 1
	settings.hsspeed = 10.0000000000
	settings.pixels = [0, 0]
	settings.datatype = "counts"
	settings.initialized = 0

end
