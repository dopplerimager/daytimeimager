;-------------------------------------------------------------
;+
; NAME:
;       COMMALIST
; PURPOSE:
;       Return a given array as a comma delimited text list.
; CATEGORY:
; CALLING SEQUENCE:
;       list = commalist(array, [form])
; INPUTS:
;       array = Input array of numbers.          in
;       form = Optional format (like I3).        in
; KEYWORD PARAMETERS:
;       Keywords:
;         /NOCOMMAS  do not add commas to returned list.
; OUTPUTS:
;       list = Returned text string with list.   out
; COMMON BLOCKS:
; NOTES:
;       Note: see wordarray as a near inverse.
; MODIFICATION HISTORY:
;       R. Sterner, 1995 Nov 28
;
; Copyright (C) 1995, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function commalist, arr, fmt, nocommas=nocom, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Return a given array as a comma delimited text list.'
	  print,' list = commalist(array, [form])'
	  print,'   array = Input array of numbers.          in'
	  print,'   form = Optional format (like I3).        in'
	  print,'   list = Returned text string with list.   out'
	  print,' Keywords:'
	  print,'   /NOCOMMAS  do not add commas to returned list.'
	  print,' Note: see wordarray as a near inverse.'
	  return,''
	endif
 
	;------  Determine default format if needed  --------
	i = isnumber(max(arr))>isnumber(min(arr))
	fmt0 = 'I'
	if i gt 1 then fmt0 = 'G13.5'
	if n_elements(fmt) eq 0 then fmt = fmt0
 
	;-------  Format list  --------------
	n = n_elements(arr)
	if n eq 0 then return,''
	if n eq 1 then return, strtrim(string(arr,form='('+fmt+')'),2)
	lst = strtrim(n-1,2)
	if keyword_set(nocom) then $
	  form="("+fmt+","+lst+"("+fmt+"))" $
	else form="("+fmt+","+lst+'(",",'+fmt+"))"
	list = strcompress(string(arr,form=form))
	return, list
 
	end	
