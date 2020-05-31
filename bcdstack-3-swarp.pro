spawn, 'mkdir mosaic'

spawn, 'swarp -d > listfiles/stack.swarp'

channel = ['I1', 'I2']

for i_ch = 0, n_elements(channel) - 1 do begin

readcol, 'listfiles/exptimelist_'+channel[i_ch]+'.txt', explist, format = 'a'
readcol, 'listfiles/cbcdlist_'+channel[i_ch]+'.txt', cbcdlist, format = 'a'
readcol, 'listfiles/unclist_'+channel[i_ch]+'.txt', unclist, format = 'a'
readcol, 'listfiles/exptime_'+channel[i_ch]+'.txt', exptime, format = 'f'

cghistoplot, exptime

expclass = [-1.]

expclass[0] = exptime[0]

for i = 0LL, n_elements(exptime) - 1 do begin
	
	unc = mrdfits(unclist[i],0,h, /sil)
	writefits, repstr(unclist[i],'.fits','.2.fits'), unc^2., h

	ind_exp = where(exptime[i] eq expclass)
	if ind_exp[0] eq -1 then begin
		print, exptime[i], sxpar(headfits(cbcdlist[i]), 'EXPTIME'), sxpar(headfits(cbcdlist[i]), 'HDRFRAME')
		expclass = [expclass, exptime[i]]
;		print, expclass
	endif
endfor

print, '---------------------------------'
print, 'exptime list:	', expclass
print, '---------------------------------'

;cc_pause

for i = 0LL, n_elements(expclass) - 1 do begin
	
	ind_exp = where(expclass[i] eq exptime)
	
	forprint, repstr(cbcdlist[ind_exp],'cbcd.masked.fits','cbcd.masked.bgsexsub.fits'), textout = 'listfiles/'+channel[i_ch]+'-cbcd-'+strtrim(expclass[i], 2)+'s-bgsexsub-list.txt', /nocomment	
	spawn, 'swarp @'+'listfiles/'+channel[i_ch]+'-cbcd-'+strtrim(expclass[i], 2)+'s-bgsexsub-list.txt -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/rough-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'-median-bgsexsub-MJysr.fits, -WEIGHT_TYPE NONE, -COMBINE_TYPE MEDIAN, -SUBTRACT_BACK N, -PIXELSCALE_TYPE MANUAL, -PIXEL_SCALE 0.6

	forprint, repstr(cbcdlist[ind_exp],'cbcd.masked.fits','cbcd.masked.bgsub.fits'), textout = 'listfiles/'+channel[i_ch]+'-cbcd-'+strtrim(expclass[i], 2)+'s-bgsub-list.txt', /nocomment	
	spawn, 'swarp @'+'listfiles/'+channel[i_ch]+'-cbcd-'+strtrim(expclass[i], 2)+'s-bgsub-list.txt -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/rough-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'-median-bgsub-MJysr.fits, -WEIGHT_TYPE NONE, -COMBINE_TYPE MEDIAN, -SUBTRACT_BACK N, -PIXELSCALE_TYPE MANUAL, -PIXEL_SCALE 0.6

	forprint, explist[ind_exp], textout = 'listfiles/'+channel[i_ch]+'-exp-'+strtrim(expclass[i], 2)+'s-list.txt', /nocomment	
	spawn, 'swarp @'+'listfiles/'+channel[i_ch]+'-exp-'+strtrim(expclass[i], 2)+'s-list.txt -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/total-exptime-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits, -COMBINE_TYPE SUM, -SUBTRACT_BACK N, -PIXELSCALE_TYPE MANUAL, -PIXEL_SCALE 0.6

	forprint, repstr(unclist[ind_exp],'.fits','.2.fits'), textout = 'listfiles/'+channel[i_ch]+'-unc2-'+strtrim(expclass[i], 2)+'s-list.txt', /nocomment	
	spawn, 'swarp @'+'listfiles/'+channel[i_ch]+'-unc2-'+strtrim(expclass[i], 2)+'s-list.txt -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/rough-unc2-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'s.fits, , -COMBINE_TYPE AVERAGE, -SUBTRACT_BACK N, -PIXELSCALE_TYPE MANUAL, -PIXEL_SCALE 0.6
	
endfor


openw, lun_channel_sexbg,'listfiles/'+channel[i_ch]+'-sexbg-final-stack.list',/get_lun 
openw, lun_channel_bg,'listfiles/'+channel[i_ch]+'-bg-final-stack.list',/get_lun 
openw, lun_channel_unc,'listfiles/'+channel[i_ch]+'-unc2-final-stack.list',/get_lun 
openw, lun_exp,'listfiles/'+channel[i_ch]+'-exptime.list',/get_lun 

openw, lun_channel_sexbg_final,'listfiles/'+channel[i_ch]+'-sexbg-final-stack-weight.list',/get_lun 
openw, lun_channel_bg_final,'listfiles/'+channel[i_ch]+'-bg-final-stack-weight.list',/get_lun 


for i = 0LL, n_elements(expclass) - 1 do begin
	exptime_map = mrdfits('mosaic/total-exptime-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits',0,h)
	writefits, 'mosaic/Exptime-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits', exptime_map * 4, h

	readcol, 'listfiles/'+channel[i_ch]+'-cbcd-'+strtrim(expclass[i], 2)+'s-bgsexsub-list.txt', filelist, format = 'a', NUMLINE=1
	fluxconv_factor = sxpar(headfits(filelist[0]), 'FLUXCONV') * 4	; surface brightness should not change by the pixel split
	writefits, 'mosaic/bgsexsub-weight-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits', exptime_map * 4 * fluxconv_factor, h
	printf, lun_channel_sexbg_final, 'mosaic/bgsexsub-weight-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits', format = '(a)'

	readcol, 'listfiles/'+channel[i_ch]+'-cbcd-'+strtrim(expclass[i], 2)+'s-bgsub-list.txt', filelist, format = 'a', NUMLINE=1
	fluxconv_factor = sxpar(headfits(filelist[0]), 'FLUXCONV') * 4	; surface brightness should not change by the pixel split
	writefits, 'mosaic/bgsub-weight-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits', exptime_map * 4 * fluxconv_factor, h
	printf, lun_channel_bg_final, 'mosaic/bgsub-weight-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits', format = '(a)'

	printf, lun_exp, 'mosaic/Exptime-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'.fits', format = '(a)'
	printf, lun_channel_unc, 'mosaic/'+'unc2-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'s.fits'	
	printf, lun_channel_sexbg, 'mosaic/rough-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'-median-bgsexsub-MJysr.fits'
	printf, lun_channel_bg, 'mosaic/rough-'+channel[i_ch]+'-'+strtrim(expclass[i], 2)+'-median-bgsub-MJysr.fits'
endfor


free_lun, lun_channel_sexbg
free_lun, lun_channel_bg
free_lun, lun_channel_unc
free_lun, lun_exp

free_lun, lun_channel_sexbg_final
free_lun, lun_channel_bg_final




for i_ch = 0, n_elements(channel) - 1 do spawn, 'swarp @'+'listfiles/'+channel[i_ch]+'-sexbg-final-stack.list -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/'+channel[i_ch]+'-sexbgsub-MJysr.fits, -WEIGHT_IMAGE @'+'listfiles/'+channel[i_ch]+'-sexbg-final-stack-weight.list, -WEIGHT_TYPE MAP_WEIGHT, -COMBINE_TYPE WEIGHTED, -SUBTRACT_BACK N
for i_ch = 0, n_elements(channel) - 1 do spawn, 'swarp @'+'listfiles/'+channel[i_ch]+'-bg-final-stack.list -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/'+channel[i_ch]+'-medianbgsub-MJysr.fits, -WEIGHT_IMAGE @'+'listfiles/'+channel[i_ch]+'-bg-final-stack-weight.list, -WEIGHT_TYPE MAP_WEIGHT, -COMBINE_TYPE WEIGHTED, -SUBTRACT_BACK N
for i_ch = 0, n_elements(channel) - 1 do spawn, 'swarp @'+'listfiles/'+channel[i_ch]+'-unc2-final-stack.list -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/'+channel[i_ch]+'-unc2-MJysr.fits, -WEIGHT_IMAGE @'+'listfiles/'+channel[i_ch]+'-bg-final-stack-weight.list, -WEIGHT_TYPE MAP_WEIGHT, -COMBINE_TYPE WEIGHTED, -SUBTRACT_BACK N
for i_ch = 0, n_elements(channel) - 1 do spawn, 'swarp @'+'listfiles/'+channel[i_ch]+'-exptime.list -c listfiles/stack.swarp -IMAGEOUT_NAME mosaic/'+channel[i_ch]+'-EXPTIME-s.fits, -COMBINE_TYPE SUM, -SUBTRACT_BACK N























endfor


end