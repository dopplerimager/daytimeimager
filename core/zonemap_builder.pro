
;\\ A FUNCTION TO CALCULATE FRACTIONAL DISTANCE FROM A GIVEN CENTER TO EDGE IN A 2D ARRAY
function zonemap_distance, zmap, center, $ ;\\ center is [x center, y center]
						   xarr=xarr, $
						   yarr=yarr, $
						   xxarr=xxarr, $
						   yyarr=yyarr
	dims = float(size(zmap, /dimensions))
	idx = findgen(n_elements(zmap))
	xx = (idx mod dims[0]) - center[0]
	yy = fix(idx / dims[0]) - center[1]
	x = fltarr(dims[0],dims[1])
	x[*] = xx
	y = x
	y[*] = yy
	dist = sqrt(x*x + y*y)
	dist = dist / float(dims[0]/2.)
	xarr = x
	yarr = y
	xxarr = xx
	yyarr = yy
	return, dist
end


;\\ BUILD A ZONEMAP FROM EITHER ANNULAR SEGMENTS OR A REGULAR GRID
;\\ annular = {xsize:0, ysize:0, xcenter:0, ycenter:0, radii:[], sectors:[]}
;\\ grid = {xsize:0, ysize:0, xwidth:0, ywidth:0, xcenter:0, ycenter:0, max_radius:0.0}
function zonemap_builder, annular=annular, $
				 		  grid=grid, $
				 		  zone_centers=zone_centers, $
				 		  zone_pixel_count=zone_pixel_count



	;\\ BUILD A ZONEMAP OUT OF CONCENTRIC ANNULI
	if keyword_set(annular) then begin

			secs = annular.sectors
			rads = annular.radii
			nx = annular.xsize
			ny = annular.ysize
			cent = [annular.xcenter, annular.ycenter]

			nums = secs
			nums(0) = 0
			for n = 1, n_elements(secs) - 1 do nums(n) = total(secs(0:n-1))

			zone = intarr(nx,ny)
			zone[*] = -1
			zone_xcen = [-1]
			zone_ycen = [-1]
			zone_pixel_count = [-1]

			;\\ Make a distance map from [cent(0),cent(1)]
				caldist = zonemap_distance(zone, cent, xarr=calx, yarr=caly, xxarr=calxx, yyarr=calyy)

			;\\ Make an angle map
				calang = atan(caly,calx)
				pts = where(calang lt 0, npts)
				if npts gt 0 then calang(pts) = calang(pts) + (2*!PI)

			zcount = 0
			for ridx = 0, n_elements(rads) - 2 do begin
				lower_dist = rads(ridx)
				upper_dist = rads(ridx+1)
				circ = where(caldist ge lower_dist and caldist lt upper_dist, ncirc)

				if ncirc gt 0 then begin
					nsecs = secs(ridx)
					angles = findgen(nsecs+1) * (360./nsecs) * !dtor
					for sidx = 0, nsecs - 1 do begin
						lower_ang = angles[sidx]
						upper_ang = angles[sidx+1]
						seg = where(calang[circ] ge lower_ang and calang[circ] lt upper_ang, nseg)
						if nseg gt 0 then begin
							zone[circ[seg]] = zcount
							zone_xcen = [zone_xcen, mean(calxx[circ[seg]])]
							zone_ycen = [zone_ycen, mean(calyy[circ[seg]])]
							zone_pixel_count = [zone_pixel_count, nseg]
							zcount ++
						endif
					endfor
				endif
			endfor

			zone_xcen = zone_xcen[1:*] + cent[0]
			zone_ycen = zone_ycen[1:*] + cent[1]
			zone_centers = [[zone_xcen],[zone_ycen]]
			zone_pixel_count = zone_pixel_count[1:*]
			return, zone

	endif


	;\\ BUILD A ZONEMAP OUT OF RECTANGLES (A REGULAR GRID)
	if keyword_set(grid) then begin

		nx = grid.xsize
		ny = grid.ysize
		xw = grid.xwidth
		yw = grid.ywidth
		cent = [grid.xcenter, grid.ycenter]

		zone = intarr(nx,ny)
		zone(*) = -1

		nx_rects = fix(nx) / fix(xw)
		ny_rects = fix(ny) / fix(yw)

		zone = indgen(nx_rects, ny_rects)

		;\\ Center
		zn_x = cent[0] / xw
		zn_y = cent[1] / yw

		zm_copy = zone
		for xx = 0, nx_rects - 1 do begin
		for yy = 0, ny_rects - 1 do begin

			xd = xx - zn_x
			yd = yy - zn_y

			pts = where(zone eq xx + nx_rects*yy)
			zm_copy[pts] = max([abs(xd),abs(yd)])

		endfor
		endfor

		vals = zm_copy[sort(zm_copy)]
		uvals = vals[uniq(vals)]
		counter = 0
		zone *= 0
		for i = 0, n_elements(uvals) - 1 do begin

			pts = where(zm_copy eq uvals[i], npts)
			idx = array_indices(zm_copy, pts)
			x = idx[0,*]
			y = idx[1,*]
			xd = x - zn_x
			yd = y - zn_y
			sorter = atan(xd, yd)
			zone[pts[sort(sorter)]] = indgen(npts) + counter
			counter += npts

		endfor

		zone = congrid(zone, nx, ny)
		caldist = zonemap_distance(zone, cent)
		pts = where(caldist gt grid.max_radius, npts, complement=in_pts)
		if npts gt 0 then zone[pts] = -1

		return, zone

	endif
end