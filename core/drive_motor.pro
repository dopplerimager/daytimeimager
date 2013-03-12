;\\ Code formatted by DocGen


;\D\<Wait for a position reached notification from the motor (a `p' character). A timeout>
;\D\<can be provided to prevent waiting forever.>
pro drive_motor_wait_for_position, port, $                          ;\A\<Com port for the motor>
                                   dll_name, $                      ;\A\<Name of the SDI\_External dll>
                                   com, $                           ;\A\<String `com' type, e.g. "moxa">
                                   max_wait_time=max_wait_time, $   ;\A\<Max time to wait in seconds>
                                   errcode=errcode                  ;\A\<Returned error code>

	if not keyword_set(max_wait_time) then max_wait_time = 30.	;\\ Max amount of time to wait, in seconds
	errcode = 'p'

	in = ''
	start_time = systime(/sec)
	while strmid(in, 0, 1) ne 'p' do begin
		in = ''
		comms_wrapper, port, dll_name, type=com, /read, data = in
		time_spent = systime(/sec) - start_time
		if time_spent gt max_wait_time then begin
			errcode = 'timeout'
			return
		endif
	endwhile

end

;\D\<Wrapper for controlling Fualhaber motors. Open/close ports, enable/disable motor,>
;\D\<get status, set position, drive to position, set speed/accel, drive in a direction>
;\D\<in small increments until blocked (i.e. when homing the mirror motor) etc.>
function drive_motor, port, $                                    ;\A\<Com port of the motor>
                      dll_name, $                                ;\A\<SDI\_External dll name (full path)>
                      direction=direction, $                     ;\A\<String direction ("forwards" or "backwards") to drive until blocked>
                      gohix=gohix, $                             ;\A\<Drive to nearest hall index>
                      goix=goix, $                               ;\A\<>
                      drive_to=drive_to, $                       ;\A\<Drive to absolute position>
                      control=control, $                         ;\A\<String control command (see function body)>
                      readpos=readpos, $                         ;\A\<Read the motor position (returned from the function)>
                      speed=speed, $                             ;\A\<Set the speed>
                      accel=accel, $                             ;\A\<Set the acceleration>
                      verbatim=verbatim, $                       ;\A\<Send a string command verbatim to the motor, appending a carriage return>
                      home_max_spin_time=home_max_spin_time, $   ;\A\<Max time to spin (for every small increment) when homing>
                      timeout=timeout                            ;\A\<Timeout in seconds>

	;\\ CONTROL keyword - string "enable"/"disable" enables/disables the motor

	;\\ Flush the moxa driven com buffer
	comms_wrapper, port, dll_name, type='moxa', /flush_input
	comms_wrapper, port, dll_name, type='moxa', /flush_output

	if not keyword_set(accel) then accel = 200
	if not keyword_set(home_max_spin_time) then home_max_spin_time = 3. ; seconds

	com = 'moxa'
	tx = string(13B)
	increments = 5000L

	if not keyword_set(direction) and not keyword_set(goix) and not keyword_set(gohix) and $
	   not keyword_set(drive_to) and not keyword_set(control) and not keyword_set(readpos) and $
	   not keyword_set(verbatim) then return, 0


	;\\ Deal with control calls
		if keyword_set(control) then begin

			case control of
				'openport':begin
					;\\ Open com port
					comms_wrapper, port, dll_name, type=com, /open, moxa_setbaud=12, errcode=errcode
					return, errcode
				end
				'closeport':begin
					;\\ Close com port
					comms_wrapper, port, dll_name, type=com, /close, errcode=errcode
					return, errcode
				end
				'enable':begin
					;\\ Disable Drive
					comms_wrapper, port, dll_name, type=com, /write, data = 'EN' + tx
				end
				'disable':begin
					;\\ Disable Drive
					comms_wrapper, port, dll_name, type=com, /write, data = 'DI' + tx
				end
				'status':begin
					comms_wrapper, port, dll_name, type=com, /write, data = 'GST' + tx
					comms_wrapper, port, dll_name, type=com, /read, data = status
					status = byte(status)
					return, status
				end
				'setpos0':begin
					;\\ Set pos to 0
					comms_wrapper, port, dll_name, type=com, /write, data = 'HO' + tx
				end
				else: return, -1
			endcase

			goto, END_DRIVE_MOTOR
		endif


	;\\ Send verbatim commands straight to the motor, adding a carriage return
		if keyword_set(verbatim) then begin
			comms_wrapper, port, dll_name, type=com, /write, data = verbatim + tx
		endif


	;\\ Handle readpos
		if keyword_set(readpos) then begin
			comms_wrapper, port, dll_name, type=com, /read, data = clear_buffer
			comms_wrapper, port, dll_name, type=com, /write, data = 'POS' + tx
			wait, 0.5
			comms_wrapper, port, dll_name, type=com, /read, data = in_pos
			return, long(in_pos)
		endif


	;\\ Set the maximum speed
		if size(speed, /type) ne 0 then begin
			data_str = 'SP' + string(speed, f='(i0)') + tx
			comms_wrapper, port, dll_name, type=com, /write, data = data_str, errcode=errcode
		endif


	;\\ Set the acceleration
		data_str = 'AC' + string(accel, f='(i0)') + tx
		comms_wrapper, port, dll_name, type=com, /write, data = data_str, errcode=errcode


	;\\ If gohix keyword is set then drive to hall zero index position
		if keyword_set(gohix) then begin
			comms_wrapper, port, dll_name, type=com, /write, data = 'NP' + tx, errcode=errcode
			comms_wrapper, port, dll_name, type=com, /write, data = 'GOHIX' + tx, errcode=errcode
			drive_motor_wait_for_position, port, dll_name, com, max_wait_time = timeout
		endif

	;\\ If goix keyword is set then drive to limit switch
		if keyword_set(goix) then begin
			comms_wrapper, port, dll_name, type=com, /write, data = 'NP' + tx, errcode=errcode
			comms_wrapper, port, dll_name, type=com, /write, data = 'GOIX' + tx, errcode=errcode
			drive_motor_wait_for_position, port, dll_name, com, max_wait_time = timeout
		endif


	;\\ If drive_to keyword is set, drive to that absolute position
		if size(drive_to, /type) ne 0 then begin
			comms_wrapper, port, dll_name, type=com, /write, data = 'NP' + tx, errcode=errcode
			comms_wrapper, port, dll_name, type=com, /write, data = 'LA' + string(drive_to, f='(i0)') + tx, errcode=errcode
			comms_wrapper, port, dll_name, type=com, /write, data = 'M' + tx, errcode=errcode
			drive_motor_wait_for_position, port, dll_name, com, max_wait_time = timeout
		endif


	;\\ If direction keyword is set, drive in that direction until blocked. Be sure to set current limits and speed before
	;\\ making this call.
		if keyword_set(direction) then begin

			if (direction ne 'forwards') and (direction ne 'backwards') then goto, END_DRIVE_MOTOR

			data_str = 'LR'
			if direction eq 'backwards' then data_str += '-'
			data_str += string(increments, f='(i0)') + tx

			stopped = 0
			while stopped eq 0 do begin

				;\\ Try to turn backwards/forwards by one revolution
					comms_wrapper, port, dll_name, type=com, /write, data = data_str, errcode=errcode
					if (errcode lt 0) then print, 'DriveMotor:Direction write error: ', errcode

				;\\ Initiate the motion
					comms_wrapper, port, dll_name, type=com, /write, data = 'NP' + tx, errcode=errcode
					comms_wrapper, port, dll_name, type=com, /write, data = 'M' + tx, errcode=errcode
					drive_motor_wait_for_position, port, dll_name, com, max_wait_time = home_max_spin_time, errcode=errcode

					if errcode eq 'timeout' then begin
						print, 'Homing... Timed Out'
						comms_wrapper, port, dll_name, type=com, /write, data = 'DI' + tx, errcode=errcode
						wait, 2
						comms_wrapper, port, dll_name, type=com, /write, data = 'EN' + tx, errcode=errcode
						wait, 1
						stopped = 1
					endif else begin
						print, 'Homing... intermediate position reached'
					endelse

				wait, 0.01
			endwhile

		endif

END_DRIVE_MOTOR:
comms_wrapper, port, dll_name, type=com, /read, data = clear_buffer

;\\ Flush the moxa driven com buffer
	comms_wrapper, port, dll_name, type='moxa', /flush_input
	comms_wrapper, port, dll_name, type='moxa', /flush_output
return, 1
end
