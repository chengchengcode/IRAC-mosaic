
spawn, 'mkdir listfiles'

spawn, 'du -a ../XMMLSS > listfiles/listall.txt'

;
;readcol, 'listall.txt', size, fitsname, format = 'i,a'
readcol, 'listfiles/listall.txt', size, namepath, bandid, aor, expid, decnum, pipeline, type, fits, format = 'i,a,a,a,a,a,a,a,a,a', delimiter='_.', /sil

channel = ['I1', 'I2']
channel = ['I1']

for i_ch = 0, n_elements(channel) - 1 do begin

ind_cbcd = where(bandid eq channel[i_ch] and type eq 'cbcd' and fits eq 'fits')
ind_cbunc = where(bandid eq channel[i_ch] and type eq 'cbunc' and fits eq 'fits')
ind_bunc = where(bandid eq channel[i_ch] and type eq 'bunc' and fits eq 'fits')
ind_mimsk = where(bandid eq channel[i_ch] and type eq 'bimsk' and fits eq 'fits')
ind_mrmsk = where(bandid eq channel[i_ch] and type eq 'brmsk' and fits eq 'fits')

openw, lun_cbcd, 'listfiles/cbcdlist_'+channel[i_ch]+'.txt', /get_lun
openw, lun_unc, 'listfiles/unclist_'+channel[i_ch]+'.txt', /get_lun
openw, lun_exp,  'listfiles/exptimelist_'+channel[i_ch]+'.txt',/get_lun

;openw, lun_mrmsk, 'mrmsklist_'+channel[i_ch]+'.txt', /get_lun
;openw, lun_mimsk, 'mimsklist_'+channel[i_ch]+'.txt', /get_lun

openw, lun_exptime,  'listfiles/exptime_'+channel[i_ch]+'.txt',/get_lun
openw, lun_expcheck, 'listfiles/exptime-notmatch_'+channel[i_ch]+'.txt',/get_lun

for i = 0LL, n_elements(ind_cbcd) - 1 do begin
	if i mod 500 eq 1 then print, n_elements(ind_cbcd) - 1 - i, '  <--- ', channel[i_ch], '	', systime()

	name_cbcd_i = '..'+namepath[ind_cbcd[i]]+'_'+bandid[ind_cbcd[i]]+'_'+aor[ind_cbcd[i]]+'_'+expid[ind_cbcd[i]]+'_'+decnum[ind_cbcd[i]]+'_'+pipeline[ind_cbcd[i]]+'_'+type[ind_cbcd[i]]+'.'+fits[ind_cbcd[i]]

	img = mrdfits(name_cbcd_i,0,h_bcd,/sil)

	if sxpar(h_bcd, 'EXPTIME') lt 15 then continue

	printf, lun_exptime, sxpar(h_bcd, 'EXPTIME')
	expmap = img-img+sxpar(h_bcd, 'EXPTIME')
		
;	if sxpar(h_bcd, 'EXPTIME') lt 2 then continue
	
	ind_find_cbunc = where(namepath[ind_cbcd[i]] eq namepath[ind_cbunc] and bandid[ind_cbcd[i]] eq bandid[ind_cbunc] and aor[ind_cbcd[i]] eq  aor[ind_cbunc] and expid[ind_cbcd[i]] eq expid[ind_cbunc])
	if ind_find_cbunc[0] eq -1 then	ind_find_cbunc = where(namepath[ind_cbcd[i]] eq namepath[ind_bunc] and bandid[ind_cbcd[i]] eq bandid[ind_bunc] and aor[ind_cbcd[i]] eq  aor[ind_bunc] and expid[ind_cbcd[i]] eq expid[ind_bunc])	
	if ind_find_cbunc[0] eq -1 then	begin
		printf, lun_expcheck, sxpar(h_bcd, 'EXPTIME'), i, '	unc', format = '(f,i)'		
		continue
	endif
	name_unc_i = '..'+namepath[ind_cbunc[ind_find_cbunc]] +'_'+ bandid[ind_cbunc[ind_find_cbunc]] +'_'+ aor[ind_cbunc[ind_find_cbunc]] +'_'+ expid[ind_cbunc[ind_find_cbunc]] +'_'+ decnum[ind_cbunc[ind_find_cbunc]] +'_'+ pipeline[ind_cbunc[ind_find_cbunc]] +'_'+ type[ind_cbunc[ind_find_cbunc]] +'.'+ fits[ind_cbunc[ind_find_cbunc]]
	unc = mrdfits(name_unc_i,0,h_unc,/sil)

	ind_find_mrmsk = where(namepath[ind_cbcd[i]] eq namepath[ind_mrmsk] and bandid[ind_cbcd[i]] eq bandid[ind_mrmsk] and aor[ind_cbcd[i]] eq  aor[ind_mrmsk] and expid[ind_cbcd[i]] eq expid[ind_mrmsk])
	if ind_find_mrmsk[0] ne -1 then begin
		name_mrmsk_i = '..'+namepath[ind_mrmsk[ind_find_mrmsk]] +'_'+ bandid[ind_mrmsk[ind_find_mrmsk]] +'_'+ aor[ind_mrmsk[ind_find_mrmsk]] +'_'+ expid[ind_mrmsk[ind_find_mrmsk]] +'_'+ decnum[ind_mrmsk[ind_find_mrmsk]] +'_'+ pipeline[ind_mrmsk[ind_find_mrmsk]] +'_'+ type[ind_mrmsk[ind_find_mrmsk]] +'.'+ fits[ind_mrmsk[ind_find_mrmsk]]
		rmsk = mrdfits(name_mrmsk_i,/sil)
;		print, 'rmsk'
		ind_cosmicray = where(rmsk ne 0)
		if ind_cosmicray[0] ne -1 then begin
			img[ind_cosmicray] = alog(-1)
			unc[ind_cosmicray] = alog(-1)
			expmap[ind_cosmicray] = 0.
		endif
	endif
	
	ind_find_mimsk = where(namepath[ind_cbcd[i]] eq namepath[ind_mimsk] and bandid[ind_cbcd[i]] eq bandid[ind_mimsk] and aor[ind_cbcd[i]] eq  aor[ind_mimsk] and expid[ind_cbcd[i]] eq expid[ind_mimsk])
	if ind_find_mimsk[0] ne -1 then begin
		name_mimsk_i = '..'+namepath[ind_mimsk[ind_find_mimsk]] +'_'+ bandid[ind_mimsk[ind_find_mimsk]] +'_'+ aor[ind_mimsk[ind_find_mimsk]] +'_'+ expid[ind_mimsk[ind_find_mimsk]] +'_'+ decnum[ind_mimsk[ind_find_mimsk]] +'_'+ pipeline[ind_mimsk[ind_find_mimsk]] +'_'+ type[ind_mimsk[ind_find_mimsk]] +'.'+ fits[ind_mimsk[ind_find_mimsk]]
		imsk = mrdfits(name_mimsk_i,/sil)
;		print, 'imsk'
		ind_badpixel = where(imsk ne 0)
		if ind_badpixel[0] ne -1 then begin
			img[ind_badpixel] = alog(-1)
			unc[ind_badpixel] = 0.
			expmap[ind_badpixel] = 0.
		endif
	endif

;	print, namepath[ind_mrmsk[ind_find_mrmsk]] +'_'+ bandid[ind_mrmsk[ind_find_mrmsk]] +'_'+ aor[ind_mrmsk[ind_find_mrmsk]] +'_'+ expid[ind_mrmsk[ind_find_mrmsk]] +'_'+ decnum[ind_mrmsk[ind_find_mrmsk]] +'_'+ pipeline[ind_mrmsk[ind_find_mrmsk]] +'_'+ type[ind_mrmsk[ind_find_mrmsk]] +'.'+ fits[ind_mrmsk[ind_find_mrmsk]]
;	print, namepath[ind_cbunc[ind_find_cbunc]] +'_'+ bandid[ind_cbunc[ind_find_cbunc]] +'_'+ aor[ind_cbunc[ind_find_cbunc]] +'_'+ expid[ind_cbunc[ind_find_cbunc]] +'_'+ decnum[ind_cbunc[ind_find_cbunc]] +'_'+ pipeline[ind_cbunc[ind_find_cbunc]] +'_'+ type[ind_cbunc[ind_find_cbunc]] +'.'+ fits[ind_cbunc[ind_find_cbunc]]

	
;	print, name_cbcd_i
;	print, name_unc_i
;	print, name_mrmsk_i
;	print, name_mimsk_i

;	ra_cbcd = sxpar(h_bcd, 'CRVAL1')
;	ra_unc = sxpar(headfits(name_unc_i), 'CRVAL1')
;	ra_mrmsk = sxpar(headfits(name_mrmsk_i), 'CRVAL1')

;	cgoplot, ra_cbcd-ra_unc, ra_cbcd - ra_mrmsk, ps = 15


	writefits, repstr(name_cbcd_i,'cbcd.fits','cbcd.masked.fits'), img, h_bcd
	writefits, repstr(name_unc_i,'unc.fits','unc.masked.fits'), unc, h_bcd
	writefits, repstr(name_cbcd_i,'cbcd.fits','exptime.fits'), expmap, h_bcd

	printf, lun_cbcd, repstr(name_cbcd_i,'cbcd.fits','cbcd.masked.fits'), format = '(a)'
	printf, lun_unc, repstr(name_unc_i,'unc.fits','unc.masked.fits'), format = '(a)'
	printf, lun_exp, repstr(name_cbcd_i,'cbcd.fits','exptime.fits'), format = '(a)'

;	printf, lun_mrmsk, name_mrmsk_i, format = '(a)'
;	printf, lun_mimsk, name_mimsk_i, format = '(a)'


;cc_pause	

endfor

free_lun, lun_cbcd
free_lun, lun_unc
free_lun, lun_exptime
;free_lun, lun_mrmsk
;free_lun, lun_mimsk

free_lun, lun_expcheck
free_lun, lun_exp

endfor







end
