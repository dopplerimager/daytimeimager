
;\\ IMAGE PROCESSING - TAKE A RAW CAMERA FRAME AND RETURN A PROCESSED (BACKGROUND SUBTRACTION, ECT.) IMAGE
function DCAI_Process_Image, in_image
	return, (in_image - 1.*smooth(in_image, 100, /edge)) > 0
	;in_image = (in_image - min(smooth(in_image, 50, /edge))) > 0
	;in_image = in_image - median(in_image[100:400, 100:400])
	return, (in_image > 0)^0.999
end
