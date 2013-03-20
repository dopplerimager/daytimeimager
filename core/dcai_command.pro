
@dcai_script_utilities


;\\ IF THE ARGUMENT IS A KEYWORD (A = B) THIS WILL SET 'out' EQUAL TO
;\\ {NAME:a, VALUE:b} AND RETURN A 1, ELSE WILL RETURN 0
function DCAI_Command_Keyword, in_arg, out

	sub = strsplit(in_arg, '=', /extract)
	if n_elements(sub) eq 2 then begin
		out = {name:strlowcase(strcompress(sub[0], /remove)), $
			   value:strlowcase(strcompress(sub[1], /remove))}
		return, 1
	endif else begin
		out = {name:'', value:''}
		return, 0
	endelse

end


;\\ SPLIT UP A SCHEDULE COMMAND STRING, PRESERVING ARRAYS AND STRUCTURES
pro DCAI_Command_Split, in_string, out_substrings

	i = 0
	curr_sub = ''
	in_array = 0
	in_struc = 0
	out_substrings = ['']
	while i lt strlen(in_string) do begin

		curr_char = strmid(in_string, i, 1)

		case curr_char of
			',': begin
				if in_array eq 0 and in_struc eq 0 then begin
					out_substrings = [out_substrings, strtrim(curr_sub, 2)]
					curr_sub = ''
				endif else begin
					curr_sub += curr_char
				endelse
			end
			'[': begin
				in_array++
				curr_sub += curr_char
			end
			']': begin
				in_array--
				curr_sub += curr_char
			end
			'{': begin
				in_struc++
				curr_sub += curr_char
			end
			'}': begin
				in_struc--
				curr_sub += curr_char
			end
			else: curr_sub += curr_char
		endcase

		i++
	endwhile

	if curr_sub ne '' then out_substrings = [out_substrings, strtrim(curr_sub, 2)]
	if n_elements(out_substrings) gt 1 then out_substrings = out_substrings[1:*]
end


;\\ GET ALL THE KEYWORDS AND ARGUMENTS FROM A GIVEN COMMAND STRING
pro DCAI_Command_GetArgsAndKeywords, in_args, out_args, n_args, out_keywords, n_keywords

	keywords = replicate({name:'', value:''}, n_elements(in_args))
	arguments = strarr(n_elements(in_args))
	keycount = 0
	argcount = 0
	for ai = 0, n_elements(in_args) - 1 do begin
		if (DCAI_Command_Keyword(in_args[ai], out) eq 1) then begin
	    	keywords[keycount] = out
	      	keycount ++
	    endif else begin
	      	arguments[argcount] = in_args[ai]
	      	argcount ++
	    endelse
	endfor

	n_args = argcount
	n_keywords = keycount
	if n_args gt 0 then out_args = arguments[0:argcount-1]
	if n_keywords gt 0 then out_keywords = keywords[0:keycount-1]

end


;\\ EXECUTE A COMMAND STRING
pro DCAI_Command, in_string, errcode=errcode

	COMMON DCAI_Control, dcai_global

	;\\ EXTRACT COMMAND AND ARGUMENTS/KEYWORDS
		DCAI_Command_Split, in_string, substrings
		command = strlowcase(strcompress(substrings[0], /remove_all))

		if n_elements(substrings) gt 1 then begin
			DCAI_Command_GetArgsAndKeywords, substrings[1:*], args, nargs, keywords, nkeywords
		endif else begin
			nargs = 0
		    nkeywords = 0
		endelse



	;\\ PROCESS THE COMMAND
		dbg = dcai_global.info.debug.running
		errcode = 'null'


	case command of

    	;\\ EMPT COMMAND STRING. DO NOTHING.
		'' : begin
			errcode = 'Info: No command supplied'
			return
		end


		;\\ SELECT A FILTER
		'filter' : begin


		end


		;\\ CONTROL THE CAMERA
		'camera' : begin

			if nkeywords eq 0 then begin

				;\\ THE CAMERA COMMAND RELIES ON KEYWORDS, NONE SUPPLIED
				errcode  = 'Error: No keywords supplied to camera command'

			endif else begin

				;\\ SEND THE COMMAND TO DCAI_LOADCAMERASETTING
				cmd_str = 'DCAI_LoadCameraSetting, "' + dcai_global.settings.external_dll + '", '
	    		for j = 0, nkeywords - 1 do begin
	    			cmd_str += keywords[j].name + '=' + keywords[j].value
	    			if j ne nkeywords - 1 then cmd_str += ','
	    		endfor

	    		if dbg eq 0 then begin
					res = execute(cmd_str)
					if res eq 0 then begin
						errcode = 'Error: Error executing string: ' + cmd_str
					endif else begin
						errcode = in_string + ' - no error'
						DCAI_Log, 'Camera set: ' + cmd_str
					endelse
				endif else begin
					errcode = in_string + ' - no error'
				endelse
			endelse

		end


		;\\ OPEN/ACTIVATE A PLUGIN
		'plugin' : begin

			if nkeywords eq 0 then begin
				errcode = 'Error: No keywords for command PLUGIN'
				return
			endif

			type = where(keywords.name eq 'type', ntype, complement = other_keys, ncomp = n_keys)
			if ntype eq 0 then begin
				errcode = 'Error: No plugin type specified for command PLUGIN'
				return
			endif
			plugin_name = keywords[type[0]].value
			keywords = keywords[other_keys]


			;\\ EXTRACT COMMAND KEYWORD
			cmd = where(keywords.name eq 'command', ncommand, complement = other_keys, ncomp = n_keys)
			if ncommand eq 0 then begin
				errcode = 'Error: No plugin command specified for command PLUGIN'
				return
			endif
			cmd_type = keywords[cmd[0]].value

			if n_keys gt 0 then keywords = keywords[other_keys] else keywords = {name:'', value:''}


			;\\ IS THE PLUGIN ALREADY OPEN?
			opened = 0
			objref = obj_new()
			if size(*dcai_global.info.plugins, /n_dimensions) ne 0 then begin
				match = where(strlowcase(obj_class(*dcai_global.info.plugins)) eq plugin_name, nmatch)
				if nmatch ne 0 then begin
					opened = 1
					objref = (*dcai_global.info.plugins)[match[0]]
				endif
			endif


			;\\ IF NOT ALREADY OPEN, OPEN IT
			if opened eq 0 then begin
				new_plugin = obj_new(plugin_name)
				if (n_elements(*dcai_global.info.plugins)) ne 0 then begin
					*dcai_global.info.plugins = [*dcai_global.info.plugins, new_plugin]
				endif else begin
					*dcai_global.info.plugins = [new_plugin]
				endelse
				objref = new_plugin
			endif

			;\\ NOW SEND ALONG THE COMMAND STRING TO THE PLUGIN
			if (cmd_type eq 'open' and opened eq 0) or (cmd_type ne 'open') then begin
				objref->ScheduleCommand, cmd_type, keywords.name, keywords.value
			endif

		end


		;\\ EXECUTE AN IDL COMMAND STRING
		'idl' : begin

			if nargs gt 0 then begin
				cmd_str = ''
    			for j = 0, nargs - 1 do begin
    				cmd_str += args[j]
    				if j ne nargs - 1 then cmd_str += ','
    			endfor
				res = execute(cmd_str)
				if res eq 0 then begin
					errcode = 'Error: Error executing IDL string: ' + cmd_str
				endif else begin
					errcode = in_string + ' - no error'
				endelse
			endif else begin
				errcode = 'Error: No arguments supplied for command: idl'
			endelse

		end


		;\\ COMMAND WAS NOT RECOGNIZED
		else: begin
			errcode = 'Error: Command not recognized: ' + in_string
		end

	endcase

end
