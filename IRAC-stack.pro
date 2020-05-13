;Maybe you would like to change the center of swarp file

spawn, 'du -a ../PBCD-data > listall.txt'

;	prepare some file list
;	make sure the maic file, munc file and mcov file have the same order
;
readcol, 'listall.txt', size, namelist, format = 'i,a'

openw, lun_ch1_maic, 'maiclist-ch1.txt', /get_lun
openw, lun_ch1_mcov, 'mcovlist-ch1.txt', /get_lun
openw, lun_ch1_munc, 'munclist-ch1.txt', /get_lun

openw, lun_ch2_maic, 'maiclist-ch2.txt', /get_lun
openw, lun_ch2_mcov, 'mcovlist-ch2.txt', /get_lun
openw, lun_ch2_munc, 'munclist-ch2.txt', /get_lun

for i = 0LL, n_elements(namelist) - 1 do begin
	
	checkfits = STRSPLIT(namelist[i], '.', /EXTRACT)  
	if checkfits[n_elements(checkfits)-1] ne 'fits' then continue
	checkchannel = STRSPLIT(namelist[i], '/', /EXTRACT)  
	if n_elements(checkchannel) lt 3 then continue

	if checkchannel[n_elements(checkchannel)-3] eq 'ch1' then begin
		checktype = STRSPLIT(namelist[i], '_', /EXTRACT)  
		if checktype[n_elements(checktype)-1] eq 'maic.fits' then printf, lun_ch1_maic, namelist[i], format = '(a)'
		if checktype[n_elements(checktype)-1] eq 'mcov.fits' then printf, lun_ch1_mcov, namelist[i], format = '(a)'
		if checktype[n_elements(checktype)-1] eq 'munc.fits' then printf, lun_ch1_munc, namelist[i], format = '(a)'
	endif

	if checkchannel[n_elements(checkchannel)-3] eq 'ch2' then begin
		checktype = STRSPLIT(namelist[i], '_', /EXTRACT)  
		if checktype[n_elements(checktype)-1] eq 'maic.fits' then printf, lun_ch2_maic, namelist[i], format = '(a)'
		if checktype[n_elements(checktype)-1] eq 'mcov.fits' then printf, lun_ch2_mcov, namelist[i], format = '(a)'
		if checktype[n_elements(checktype)-1] eq 'munc.fits' then printf, lun_ch2_munc, namelist[i], format = '(a)'
	endif
;cc_pause
endfor

free_lun, lun_ch1_maic
free_lun, lun_ch1_mcov
free_lun, lun_ch1_munc
free_lun, lun_ch2_maic
free_lun, lun_ch2_mcov
free_lun, lun_ch2_munc


iracband = ['ch1', 'ch2']

for i_band = 0, n_elements(iracband) - 1 do begin

readcol, 'maiclist-'+iracband[i_band]+'.txt', maiclist, format = 'a'
readcol, 'munclist-'+iracband[i_band]+'.txt', munclist, format = 'a'
readcol, 'mcovlist-'+iracband[i_band]+'.txt', mcovlist, format = 'a'



openw, lun_maic_bgsub, 'maic_bgsub-'+iracband[i_band]+'.txt', /get_lun
openw, lun_exp, 'exptime-'+iracband[i_band]+'.txt', /get_lun
openw, lun_weight, 'weight-'+iracband[i_band]+'.txt', /get_lun
openw, lun_munc2, 'munc2-'+iracband[i_band]+'.txt', /get_lun

for i = 0LL, n_elements(maiclist) - 1 do begin

	print,  n_elements(maiclist) - 1 - i
	maic = mrdfits(maiclist[i],0,h_maic, /sil)
	mcov = mrdfits(mcovlist[i],0,h_mcov, /sil)
	munc = mrdfits(munclist[i],0,h_munc, /sil)

;0	remove the pixels with only 1 coverage:

	ind_cov = where(mcov lt 1.5)
	
	maic[ind_cov] = alog(-1)
	mcov[ind_cov] = 0
	munc[ind_cov] = alog(-1)

;	writefits, repstr(namelist[i],'.fits','_sub.fits'), img-median([l_hist[ind_max]]), h

;1, several maps:

;	exptime for coverage:

	exptime = mcov * sxpar(h_maic, 'EXPTIME')	

;	conv factor map, to correct the MJy/sr unit into electron per second:
;	electron = maic * conv_factor
;
;	FLUXCONV in unit of MJy/sr per DN/s
;	maic / FLUXCONV in unit of DN/s, GAIN in unit of e/DN
;	electron = GAIN * maic / FLUXCONV 
;	conv_factor = GAIN / FLUXCONV, change the unit of MJy/sr into electron/s

	conv_factor = sxpar(h_maic, 'GAIN') / sxpar(h_maic, 'FLUXCONV')
	
;	weight map:

	weight = exptime * conv_factor

;	build some maps

	writefits, repstr(maiclist[i],'maic.fits','Weight.fits'), weight, h_maic
	writefits, repstr(maiclist[i],'maic.fits','EXP.fits'), exptime, h_maic
	writefits, repstr(maiclist[i],'maic.fits','munc2.fits'), munc^2, h_maic

;2, background subtraction
	
	ind_nan=where(maic eq maic)
	if ind_nan[0] eq -1 then begin
		print, maiclist[i]
		continue
	endif

	binsize = 0.001
	min_hist = median(maic[where(maic eq maic)]) - 5 * stddev(maic[where(maic eq maic)])
	max_hist = median(maic[where(maic eq maic)]) + 5 * stddev(maic[where(maic eq maic)])
	hist_counts = histogram( maic[where(maic eq maic)], binsize = binsize, min = min_hist, max = max_hist, locations = l_hist)
	max_hist = max(hist_counts, ind_max)

	plot, l_hist, hist_counts, ps = 10, xrange = [median([l_hist[ind_max]])-0.05,median([l_hist[ind_max]])+0.05]
	oplot, [median([l_hist[ind_max]]),median([l_hist[ind_max]])], [0,100000]


	writefits, repstr(maiclist[i],'maic.fits','maic.bgsub.fits'), maic-median([l_hist[ind_max]]), h_maic

	printf, lun_maic_bgsub, repstr(maiclist[i],'maic.fits','maic.bgsub.fits'), format = '(a)'
	printf, lun_weight, repstr(maiclist[i],'maic.fits','Weight.fits'), format = '(a)'
	printf, lun_exp, repstr(maiclist[i],'maic.fits','EXP.fits'), format = '(a)'
	printf, lun_munc2, repstr(maiclist[i],'maic.fits','munc2.fits'), format = '(a)'

endfor

free_lun, lun_maic_bgsub
free_lun, lun_exp
free_lun, lun_munc2
free_lun, lun_weight

;3 swarp config

spawn, 'swarp -d > stack.swarp'
spawn, 'swarp @exptime.txt -c stack.swarp -IMAGEOUT_NAME total-exptime.fits, -WEIGHTOUT_NAME test-exptime.weight.fits, -COMBINE_TYPE SUM, -SUBTRACT_BACK N
spawn, 'swarp @maic_bgsub.txt -c stack.swarp -IMAGEOUT_NAME rough-MJysr.fits, -WEIGHTOUT_NAME rough-MJysr.weight.fits -WEIGHT_IMAGE @weight.txt, -WEIGHT_TYPE MAP_WEIGHT, -COMBINE_TYPE WEIGHTED, -SUBTRACT_BACK N
spawn, 'swarp @munc2.txt -c stack.swarp -IMAGEOUT_NAME rough-munc2.fits, -WEIGHTOUT_NAME rough-munc2.weight.fits -WEIGHT_IMAGE @weight.txt, -WEIGHT_TYPE MAP_WEIGHT, -COMBINE_TYPE WEIGHTED, -SUBTRACT_BACK N

;4 save

img_stack = mrdfits('rough-'+iracband[i_band]+'-MJysr.fits',0,h)
img_stack[where(img_stack eq 0)] = alog(-1)
writefits, 'stack-exptime-weighted-'+iracband[i_band]+'-MJy_sr.fits', img_stack, h

img_stack = mrdfits('rough-munc2-'+iracband[i_band]+'.fits',0,h)
img_stack[where(img_stack eq 0)] = alog(-1)
writefits, 'stack-exptime-weighted-'+iracband[i_band]+'-MJy_sr-unc.fits', sqrt(img_stack), h



endfor









































end
