
pro DCAI_Log, in_string, $
			  no_write=no_write ;\\ Dont write line out to log file, only display

	COMMON DCAI_Control, dcai_global

	if widget_info(dcai_global.gui.log, /valid_id) eq 0 then return

	if size(in_string, /type) ne 7 then in_string = string(in_string)

	log_string = systime() + '>> ' + in_string

	if dcai_global.log.n_entries lt dcai_global.log.max_entries then begin
		widget_control, set_value = log_string, dcai_global.gui.log, /append
		widget_control, set_text_top_line = (dcai_global.log.n_entries - 5) > 0, dcai_global.gui.log
		dcai_global.log.n_entries ++
	endif else begin
		widget_control, get_value = curr_log, dcai_global.gui.log
		sub_log = curr_log[50:*]
		dcai_global.log.n_entries = n_elements(sub_log)
		widget_control, set_value = sub_log, dcai_global.gui.log
		widget_control, set_value = log_string, dcai_global.gui.log, /append
		widget_control, set_text_top_line = (dcai_global.log.n_entries - 10) > 0, dcai_global. gui.log
		dcai_global.log.n_entries ++
	endelse

	;\\ Output to the log file
	if (dcai_global.log.file_handle ne 0) and not keyword_set(no_write) then begin
	  printf, dcai_global.log.file_handle, log_string
	endif

end