spawn, 'mkdir mosaic'

spawn, 'swarp -d > listfiles/stack.swarp'

channel = ['I1', 'I2']
;channel = ['I1']

openw, lun_swarp_note, 'swarp-note.txt', /get_lun

for i_ch = 0, n_elements(channel) - 1 do begin

readcol, 'listfiles/exptimelist_'+channel[i_ch]+'.txt', explist, format = 'a'
readcol, 'listfiles/cbcdlist_'+channel[i_ch]+'.txt', cbcdlist, format = 'a'
readcol, 'listfiles/unclist_'+channel[i_ch]+'.txt', unclist, format = 'a'
readcol, 'listfiles/exptime_'+channel[i_ch]+'.txt', exptime, format = 'f'

cghistoplot, exptime

expclass = [-1.]
pixelscale_orig = [0.]
expclass[0] = exptime[0]
pixelscale_orig[0] = sxpar(headfits(unclist[0]), 'PXSCAL2')


openw, lun, 'pixel-scale-check.txt', /get_lun
for i = 0LL, n_elements(exptime) - 1 do begin	
	unc = mrdfits(unclist[i],0,h, /sil)
	writefits, repstr(unclist[i],'.fits','.2.fits'), unc^2., h
	
	printf, lun, sxpar(h, 'PXSCAL2'), exptime[i]
	
	ind_exp = where(exptime[i] eq expclass)
	if ind_exp[0] eq -1 then begin
		print, exptime[i], sxpar(headfits(cbcdlist[i]), 'EXPTIME'), sxpar(headfits(cbcdlist[i]), 'HDRFRAME')
		expclass = [expclass, exptime[i]]
		pixelscale_orig = [pixelscale_orig, sxpar(headfits(unclist[i]), 'PXSCAL2')]
;		print, expclass
	endif
endfor
free_lun, lun


print, '---------------------------------'
print, 'exptime list:	', expclass
print, '---------------------------------'

;cc_pause

for i = 0LL, n_elements(expclass) - 1 do begin
	
	pixel_factor = (pixelscale_orig[i] / 0.6)^2.
	
	ind_exp = where(expclass[i] eq exptime)

;	median the images with same exposure time with bg subtracted by SExtractor
	forprint, repstr(cbcdlist[ind_exp],'cbcd.masked.fits','cbcd.masked.bgsexsub.fits'), textout = 'listfiles/'+channel[i_ch]+'-cbcd-'+strtrim(expclass[i], 2)+'s-bgsexsub-list.txt', /nocomment	
	spawn, 'swarp @'+'listfiles/'+channel[i_ch]+'-cbcd-'+strtrim(expclass[i], 2)+'s-bgsexsub-list.txt -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/rough-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'-median-bgsexsub-0.6.fits, -WEIGHT_TYPE NONE, -COMBINE_TYPE MEDIAN, -SUBTRACT_BACK N, -PIXELSCALE_TYPE MANUAL, -PIXEL_SCALE 0.6
	printf, lun_swarp_note, 'swarp @'+'listfiles/'+channel[i_ch]+'-cbcd-'+strtrim(expclass[i], 2)+'s-bgsexsub-list.txt -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/rough-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'-median-bgsexsub-0.6.fits, -WEIGHT_TYPE NONE, -COMBINE_TYPE MEDIAN, -SUBTRACT_BACK N, -PIXELSCALE_TYPE MANUAL, -PIXEL_SCALE 0.6
	
	
	bigfitsname = 'mosaic/rough-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'-median-bgsexsub-0.6.fits'
	image_stack_head = headfits(bigfitsname)
	size_x = sxpar( image_stack_head ,'NAXIS1')
	size_y = sxpar( image_stack_head ,'NAXIS2')
	img_stack = fltarr(size_x,size_y)
	
	for i_rows = 0LL, (size_y - 1LL - 1LL)/2LL do begin
		i_rows_image = 2LL*i_rows
		if i_rows mod 2000 eq 1 then print, (size_y - 1LL - 1LL)/2LL - 1 - i_rows, ' <===== loading fits ', systime()
		image_i_rows = mrdfits(bigfitsname,0, ROWS = [i_rows_image, i_rows_image + 1], /sil)
		img_stack[*,i_rows_image:i_rows_image+1] = image_i_rows
	endfor
	
;	img_stack[where(img_stack eq 0)] = alog(-1)
	writefits, 'mosaic/rough-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'-median-bgsexsub-MJysr.fits', img_stack * pixel_factor, image_stack_head

;	median the images with same exposure time with bg subtracted by pixel median value
	forprint, repstr(cbcdlist[ind_exp],'cbcd.masked.fits','cbcd.masked.bgsub.fits'), textout = 'listfiles/'+channel[i_ch]+'-cbcd-'+strtrim(expclass[i], 2)+'s-bgsub-list.txt', /nocomment	
	spawn, 'swarp @'+'listfiles/'+channel[i_ch]+'-cbcd-'+strtrim(expclass[i], 2)+'s-bgsub-list.txt -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/rough-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'-median-bgsub-0.6.fits, -WEIGHT_TYPE NONE, -COMBINE_TYPE MEDIAN, -SUBTRACT_BACK N, -PIXELSCALE_TYPE MANUAL, -PIXEL_SCALE 0.6
	printf, lun_swarp_note, 'swarp @'+'listfiles/'+channel[i_ch]+'-cbcd-'+strtrim(expclass[i], 2)+'s-bgsub-list.txt -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/rough-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'-median-bgsub-0.6.fits, -WEIGHT_TYPE NONE, -COMBINE_TYPE MEDIAN, -SUBTRACT_BACK N, -PIXELSCALE_TYPE MANUAL, -PIXEL_SCALE 0.6
	
	bigfitsname = 'mosaic/rough-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'-median-bgsub-0.6.fits'
	image_stack_head = headfits(bigfitsname)
	size_x = sxpar( image_stack_head ,'NAXIS1')
	size_y = sxpar( image_stack_head ,'NAXIS2')
	img_stack = fltarr(size_x,size_y)
	
	for i_rows = 0LL, (size_y - 1LL - 1LL)/2LL do begin
		i_rows_image = 2LL*i_rows
		if i_rows mod 2000 eq 1 then print, (size_y - 1LL - 1LL)/2LL - 1 - i_rows, ' <===== loading fits ', systime()
		image_i_rows = mrdfits(bigfitsname,0, ROWS = [i_rows_image, i_rows_image + 1], /sil)
		img_stack[*,i_rows_image:i_rows_image+1] = image_i_rows
	endfor
	
;	img_stack[where(img_stack eq 0)] = alog(-1)
	writefits, 'mosaic/rough-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'-median-bgsub-MJysr.fits', img_stack * pixel_factor, image_stack_head


;	sum the exposure time of images with same exposure time
	forprint, explist[ind_exp], textout = 'listfiles/'+channel[i_ch]+'-exp-'+strtrim(expclass[i], 2)+'s-list.txt', /nocomment	
	spawn, 'swarp @'+'listfiles/'+channel[i_ch]+'-exp-'+strtrim(expclass[i], 2)+'s-list.txt -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/total-exptime-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits, -COMBINE_TYPE SUM, -SUBTRACT_BACK N, -PIXELSCALE_TYPE MANUAL, -PIXEL_SCALE 0.6
	printf, lun_swarp_note, 'swarp @'+'listfiles/'+channel[i_ch]+'-exp-'+strtrim(expclass[i], 2)+'s-list.txt -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/total-exptime-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits, -COMBINE_TYPE SUM, -SUBTRACT_BACK N, -PIXELSCALE_TYPE MANUAL, -PIXEL_SCALE 0.6
	
;	average the uncertainty^2 map
	forprint, repstr(unclist[ind_exp],'.fits','.2.fits'), textout = 'listfiles/'+channel[i_ch]+'-unc2-'+strtrim(expclass[i], 2)+'s-list.txt', /nocomment	
	spawn, 'swarp @'+'listfiles/'+channel[i_ch]+'-unc2-'+strtrim(expclass[i], 2)+'s-list.txt -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/rough-unc2-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'s.fits, , -COMBINE_TYPE AVERAGE, -SUBTRACT_BACK N, -PIXELSCALE_TYPE MANUAL, -PIXEL_SCALE 0.6
	printf, lun_swarp_note, 'swarp @'+'listfiles/'+channel[i_ch]+'-unc2-'+strtrim(expclass[i], 2)+'s-list.txt -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/rough-unc2-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'s.fits, , -COMBINE_TYPE AVERAGE, -SUBTRACT_BACK N, -PIXELSCALE_TYPE MANUAL, -PIXEL_SCALE 0.6
	
endfor


openw, lun_channel_sexbg,'listfiles/'+channel[i_ch]+'-sexbg-final-stack.list',/get_lun 
openw, lun_channel_bg,'listfiles/'+channel[i_ch]+'-bg-final-stack.list',/get_lun 
openw, lun_channel_unc,'listfiles/'+channel[i_ch]+'-unc2-final-stack.list',/get_lun 
openw, lun_exp,'listfiles/'+channel[i_ch]+'-exptime.list',/get_lun 
	
openw, lun_channel_sexbg_weight,'listfiles/'+channel[i_ch]+'-sexbg-final-stack-weight.list',/get_lun 
openw, lun_channel_bg_weight,'listfiles/'+channel[i_ch]+'-bg-final-stack-weight.list',/get_lun 


for i = 0LL, n_elements(expclass) - 1 do begin

	printf, lun_channel_unc, 'mosaic/rough-unc2-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'s.fits'	
	printf, lun_channel_sexbg, 'mosaic/rough-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'-median-bgsexsub-MJysr.fits'
	printf, lun_channel_bg, 'mosaic/rough-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'-median-bgsub-MJysr.fits'
	
	pixel_factor = (pixelscale_orig[i] / 0.6)^2.
	
	exptime_map = mrdfits('mosaic/total-exptime-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits',0,h)
	writefits, 'mosaic/Exptime-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits', exptime_map * pixel_factor, h
	printf, lun_exp, 'mosaic/Exptime-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits', format = '(a)'

	readcol, 'listfiles/'+channel[i_ch]+'-cbcd-'+strtrim(expclass[i], 2)+'s-bgsexsub-list.txt', filelist, format = 'a', NUMLINE=1
;	fluxconv_factor = sxpar(headfits(filelist[0]), 'FLUXCONV') * pixel_factor	; surface brightness should not change by the pixel split
	fluxconv_factor = sxpar(headfits(filelist[0]), 'GAIN') / sxpar(headfits(filelist[0]), 'FLUXCONV')	; surface brightness should not change by the pixel split
	writefits, 'mosaic/bgsexsub-weight-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits', exptime_map * pixel_factor * fluxconv_factor, h	; exptime_map * pixel_factor is the real exposure time
	printf, lun_channel_sexbg_weight, 'mosaic/bgsexsub-weight-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits', format = '(a)'

	readcol, 'listfiles/'+channel[i_ch]+'-cbcd-'+strtrim(expclass[i], 2)+'s-bgsub-list.txt', filelist, format = 'a', NUMLINE=1
	fluxconv_factor = sxpar(headfits(filelist[0]), 'GAIN') / sxpar(headfits(filelist[0]), 'FLUXCONV')	; surface brightness should not change by the pixel split
	writefits, 'mosaic/bgsub-weight-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits', exptime_map * pixel_factor * fluxconv_factor, h	; exptime_map * pixel_factor is the real exposure time
	printf, lun_channel_bg_weight, 'mosaic/bgsub-weight-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits', format = '(a)'

endfor


free_lun, lun_channel_sexbg
free_lun, lun_channel_bg
free_lun, lun_channel_unc
free_lun, lun_exp

free_lun, lun_channel_sexbg_weight
free_lun, lun_channel_bg_weight

endfor


for i_ch = 0, n_elements(channel) - 1 do begin

	spawn, 'swarp @'+'listfiles/'+channel[i_ch]+'-sexbg-final-stack.list -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/'+channel[i_ch]+'-sexbgsub-MJysr.fits, -WEIGHT_IMAGE @'+'listfiles/'+channel[i_ch]+'-sexbg-final-stack-weight.list, -WEIGHT_TYPE MAP_WEIGHT, -COMBINE_TYPE WEIGHTED, -SUBTRACT_BACK N
	spawn, 'swarp @'+'listfiles/'+channel[i_ch]+'-bg-final-stack.list -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/'+channel[i_ch]+'-medianbgsub-MJysr.fits, -WEIGHT_IMAGE @'+'listfiles/'+channel[i_ch]+'-bg-final-stack-weight.list, -WEIGHT_TYPE MAP_WEIGHT, -COMBINE_TYPE WEIGHTED, -SUBTRACT_BACK N
	spawn, 'swarp @'+'listfiles/'+channel[i_ch]+'-unc2-final-stack.list -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/'+channel[i_ch]+'-unc2-MJysr.fits, -WEIGHT_IMAGE @'+'listfiles/'+channel[i_ch]+'-bg-final-stack-weight.list, -WEIGHT_TYPE MAP_WEIGHT, -COMBINE_TYPE WEIGHTED, -SUBTRACT_BACK N
	spawn, 'swarp @'+'listfiles/'+channel[i_ch]+'-exptime.list -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/'+channel[i_ch]+'-EXPTIME-s.fits, -COMBINE_TYPE SUM, -SUBTRACT_BACK N

	printf, lun_swarp_note, 'swarp @'+'listfiles/'+channel[i_ch]+'-sexbg-final-stack.list -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/'+channel[i_ch]+'-sexbgsub-MJysr.fits, -WEIGHT_IMAGE @'+'listfiles/'+channel[i_ch]+'-sexbg-final-stack-weight.list, -WEIGHT_TYPE MAP_WEIGHT, -COMBINE_TYPE WEIGHTED, -SUBTRACT_BACK N
	printf, lun_swarp_note, 'swarp @'+'listfiles/'+channel[i_ch]+'-bg-final-stack.list -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/'+channel[i_ch]+'-medianbgsub-MJysr.fits, -WEIGHT_IMAGE @'+'listfiles/'+channel[i_ch]+'-bg-final-stack-weight.list, -WEIGHT_TYPE MAP_WEIGHT, -COMBINE_TYPE WEIGHTED, -SUBTRACT_BACK N
	printf, lun_swarp_note, 'swarp @'+'listfiles/'+channel[i_ch]+'-unc2-final-stack.list -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/'+channel[i_ch]+'-unc2-MJysr.fits, -WEIGHT_IMAGE @'+'listfiles/'+channel[i_ch]+'-bg-final-stack-weight.list, -WEIGHT_TYPE MAP_WEIGHT, -COMBINE_TYPE WEIGHTED, -SUBTRACT_BACK N
	printf, lun_swarp_note, 'swarp @'+'listfiles/'+channel[i_ch]+'-exptime.list -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/'+channel[i_ch]+'-EXPTIME-s.fits, -COMBINE_TYPE SUM, -SUBTRACT_BACK N

endfor

free_lun, lun_swarp_note

end