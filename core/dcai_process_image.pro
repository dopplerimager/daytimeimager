
;\\ IMAGE PROCESSING - TAKE A RAW CAMERA FRAME AND RETURN A PROCESSED (BACKGROUND SUBTRACTION, ECT.) IMAGE
function DCAI_Process_Image, in_image
	return, (in_image - 0.*smooth(in_image, 80, /edge)) > 0
	;return, sqrt(in_image)
end