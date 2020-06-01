
spawn, 'sex -d > listfiles/bg.sex'
spawn, 'mkdir blank'
spawn, 'ls blank > listfiles/default.param'
spawn, 'rm -rf blank'

channel = ['I1', 'I2']
channel = ['I1']

for i_ch = 0, n_elements(channel) - 1 do begin
	readcol, 'listfiles/cbcdlist_'+channel[i_ch]+'.txt', cbcdlist, format = 'a'
	
	for i = 0, n_elements(cbcdlist) - 1 do begin
		cbcd = mrdfits(cbcdlist[i],0,h,/sil)
		
;		binsize = 0.001
;		min_hist = median(cbcd[where(cbcd eq cbcd)]) - 5 * stddev(cbcd[where(cbcd eq cbcd)])
;		max_hist = median(cbcd[where(cbcd eq cbcd)]) + 5 * stddev(cbcd[where(cbcd eq cbcd)])
;		hist_counts = histogram( cbcd[where(cbcd eq cbcd)], binsize = binsize, min = min_hist, max = max_hist, locations = l_hist)
;		max_hist = max(hist_counts, ind_max)
;    
;		plot, l_hist, hist_counts, ps = 10, xrange = [median([l_hist[ind_max]])-0.05,median([l_hist[ind_max]])+0.05]
;		oplot, [median([l_hist[ind_max]]),median([l_hist[ind_max]])], [0,10000000]
;		print, cbcdlist[i]

;		spawn, 'sextractor '+cbcdlist[i]+' -c bg.sex -CATALOG_TYPE NONE -DETECT_THRESH 1 -ANALYSIS_THRESH 1 -PIXEL_SCALE 0.6 -SEEING_FWHM 2. -BACK_SIZE 64 -CHECKIMAGE_TYPE -BACKGROUND -CHECKIMAGE_NAME bgsub.fits -FILTER_NAME /usr/share/sextractor/default.conv'
		spawn, 'sex '+cbcdlist[i]+' -c listfiles/bg.sex -PARAMETERS_NAME listfiles/default.param -CATALOG_TYPE NONE -DETECT_THRESH 1 -ANALYSIS_THRESH 1 -PIXEL_SCALE 0.6 -SEEING_FWHM 2. -BACK_SIZE 64 -CHECKIMAGE_TYPE -BACKGROUND -CHECKIMAGE_NAME bgsub.fits -FILTER_NAME /usr/local/astromatic/sex/share/sextractor/default.conv'

		bgsub = mrdfits('bgsub.fits',/sil)
		ind_nan = where(cbcd ne cbcd)
		bgsub[ind_nan] = alog(-1)

		writefits, repstr(cbcdlist[i],'cbcd.masked.fits','cbcd.masked.bgsexsub.fits'), bgsub, h
		writefits, repstr(cbcdlist[i],'cbcd.masked.fits','cbcd.masked.bgsub.fits'), cbcd - median(cbcd[where(cbcd eq cbcd)], /EVEN), h

	endfor
endfor

spawn, 'rm bgsub.fits'

end