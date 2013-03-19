
;\\ ASC control program entry point. Should be called with the following arguments:
;\\
;\\ External_dll = the dll containing wrapped camera calls, etc
;\\
;\\ Camera_profile = the initial set of camera settings to upload to the camera.
;\\
;\\ Schedule = a file containing a schedule script.
;\\


DCAI_Control_Main, settings = 'DCAI_Settings', $
				   camera_settings = 'DCAI_Cameraprofile', $
				   drivers = 'DCAI_Drivers', $
				   schedule = ''