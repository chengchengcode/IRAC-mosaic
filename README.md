# IRAC-mosaic
Stack Spitzer/IRAC image into a deeper mosaic

This is a note about how to stack the IRAC image together.

I start my real astronomy career from an IRAC survey named SEDS https://www.cfa.harvard.edu/SEDS/ . Jiasheng patiently helps and teach me to do crowd field photometry, collect data from each field, built the IRAC selected multi-wavelength catalogue, phot-z, absolute mag, stellar-mass etc. Most importantly, I start to understand the relation between signal and noise, model and data. Until now, Spitzer is still my favourite telescope. I feel honour when I joint one Spitzer proposal last year before it retired.

Motivations:

1, to have a deeper IRAC image in some deep fields like XMM-LSS, ELAIS-N1, DEEP2-3, E-COSMOS, with recently released data

2, to play with IRAC

IRAC image can be mosaic by mopex. In my case, I cannot run mopex. No idea why.

If each step of data reduction is understood clearly, I should be able to reproduce the results. It is not difficult to do it, so I make one pipeline to stack the image. The whole point of this note is to explain each step to future me, in case I forget.

I upload source code in case I lost it one day.

I use IDL to feel like working with IRAC data. IDL is used to build some file list and write some fits file with maic.fits, short for MosAIC, and the information from head file.

I use swarp to stack image in a way I can explain.

What I can understand about the image stacking is add the photons at the same position from several different fits together, then divided by exposure time at each position. So the several different fits images are kind of the photons that drop to the IR detector at different time. The stacking process is like to go back in time we haven't got the fits files, and drop the photons at the same time.

Spitzer/IRAC data are released as BCD level and PBCD level. The difference between BCD and PBCD is: BCD files are pipeline reduced and calibrated file for each pointing. Image size of each BCD file is 5’ X 5’, same as FoV of IRAC. PBCD files are the stack image of several BCD file in one observation run, include e.g., 3X3 pointing pattern, some dither pattern or other configurations, or one AOR. PBCD Image size is larger than BCD file. Each PBCD folder includes maic.fits, munc.fits, mcov.fits, as the science image, coverage map, uncertainty map.

BCD and PBCD images have excellent astrometry.

So I start from PBCD file.

Spitzer data can be downloaded from: https://sha.ipac.caltech.edu/applications/Spitzer/SHA/

input the ra, dec, Equ 2000, set the radius, 1.5deg at most, select IRAC data bands maybe only PBCD data, click Search.  Then you see a page with many data, select all, click Prepare Download, then wait a moment

wait

then download script, download data, unzip the files in a folder, then you can see some folders with the name like r46954240, r46954241, r46954242…

Mkdir another folder outside the data folder, cd this folder, put IRAC-stack.pro into it, run IRAC-stack.pro in IDL.

Most of the time, you will get the mosaic images include the science image with the pixel value unit of MJy/sr, exposure time map, and uncertainty map.

The end.

--------------------------------------------------

What happened in IDL code:

1, Prepare some file list like maiclist-ch1.txt, mcovlist-ch1.txt, munclist-ch1.txt to save the path to the maic.fits, mcov.fits, munc.fits they are mosaic, coverage, uncertainty file, file of one observation run. Context of .txt file looks like this:

../PBCD-data/r66742528/ch1/pbcd/SPITZER_I1_66742528_0000_1_E12631583_maic.bgsub.fits

../PBCD-data/r68206592/ch1/pbcd/SPITZER_I1_68206592_0000_1_E12695395_maic.bgsub.fits

../PBCD-data/r66749440/ch1/pbcd/SPITZER_I1_66749440_0000_1_E12631579_maic.bgsub.fits

../PBCD-data/r66760704/ch1/pbcd/SPITZER_I1_66760704_0000_1_E12636985_maic.bgsub.fits

../PBCD-data/r68213504/ch1/pbcd/SPITZER_I1_68213504_0000_1_E12695463_maic.bgsub.fits

../PBCD-data/r66760960/ch1/pbcd/SPITZER_I1_66760960_0000_1_E12631544_maic.bgsub.fits

../PBCD-data/r68205824/ch1/pbcd/SPITZER_I1_68205824_0000_1_E12695408_maic.bgsub.fits

../PBCD-data/r68203520/ch1/pbcd/SPITZER_I1_68203520_0000_1_E12695413_maic.bgsub.fits

../PBCD-data/r66755584/ch1/pbcd/SPITZER_I1_66755584_0000_1_E12631545_maic.bgsub.fits

../PBCD-data/r66766336/ch1/pbcd/SPITZER_I1_66766336_0000_1_E12631491_maic.bgsub.fits

../PBCD-data/r68199680/ch1/pbcd/SPITZER_I1_68199680_0000_1_E12695366_maic.bgsub.fits

../PBCD-data/r68197376/ch1/pbcd/SPITZER_I1_68197376_0000_1_E12695435_maic.bgsub.fits

../PBCD-data/r68209920/ch1/pbcd/SPITZER_I1_68209920_0000_1_E12695415_maic.bgsub.fits

../PBCD-data/r66748416/ch1/pbcd/SPITZER_I1_66748416_0000_1_E12631581_maic.bgsub.fits

../PBCD-data/r66737664/ch1/pbcd/SPITZER_I1_66737664_0000_1_E12631503_maic.bgsub.fits

../PBCD-data/r68212224/ch1/pbcd/SPITZER_I1_68212224_0000_1_E12695388_maic.bgsub.fits

../PBCD-data/r66743552/ch1/pbcd/SPITZER_I1_66743552_0000_1_E12631584_maic.bgsub.fits

../PBCD-data/r46954240/ch1/pbcd/SPITZER_I1_46954240_0000_2_E10985947_maic.bgsub.fits

../PBCD-data/r46959104/ch1/pbcd/SPITZER_I1_46959104_0000_2_E10986504_maic.bgsub.fits


The order of the fits name in the txt file should follow the same observation order, so we are looking at the maic, mcov for the same observation run.

Sometimes IDL may give a wrong order of the files in a different list. So here should have a check and re-order them.

Anyway, we need a file list for swarp code to stack, and this can be done in many ways.  Now assume we have some file list.

2, prepare the exposure and weight map of each maic.fits

I load the fits file like this:

           maic = mrdfits(maiclist[i],0,h_maic, /sil)
           mcov = mrdfits(mcovlist[i],0,h_mcov, /sil)
           munc = mrdfits(munclist[i],0,h_munc, /sil)

then the image is load into maic, mcov, munc as 2d array, h_maic, h_mcov, h_munc are the head file.
mcov have the coverage number for each pixel. Most of them are larger than 1. I remove the pixel with only one coverage:

           ind_cov = where(mcov lt 1.5)
           maic[ind_cov] = alog(-1)
           mcov[ind_cov] = 0     
           munc[ind_cov] = alog(-1)

the pixels with only 1 coverage have large uncertainty. The large uncertainty or hot pixels can be removed by median. I want to remove them by hand here.

EXPTIME in the head file is exposure time for one pointing. The exptime map for each maic image pixel is:

           exptime = mcov * sxpar(h_maic, 'EXPTIME') 

sxpar(h_maic, 'EXPTIME') is the way to extract the EXPTIME from head file h_maic.

maic.fits have the pixel unit as MJy/sr, which is a hugely interesting unit. I convert it into electrons by FLUXCONV and GAIN from the head file.

FLUXCONV in the unit of MJy/sr per DN/s to convert the pixel value unit to DN/s, so

maic / FLUXCONV in the unit of DN/s

GAIN in the unit of e/DN

electron/s = GAIN * maic / FLUXCONV

so we can define a conversion factor as conv_factor = GAIN / FLUXCONV

conv_factor can change the unit of MJy/sr into electron/s

           conv_factor = sxpar(h_maic, 'GAIN') / sxpar(h_maic, 'FLUXCONV')

I make the weight map like this:
           
weight = exptime * conv_factor

Then stack the maic image by this weight. I will explain why this is weight soon.

Now we can stack fits file. The basic idea of the stacking process is

1, make some blank large coordinate grid maps, large enough to cover all the RA, Dec of the downloaded PBCD fits files.

2, project the electrons from each fits into one large coordinate grid maps, and add the number of the electrons at the same position together. Then this large map includes all the electrons we received by IRAC. This is the total electron map.

The projection between pixels may need to derive carefully about the overlap area between pixels, to decide how many electrons from one pixel of PBCD fits should drop to another pixel of the mosaic image. A simple treatment is to derive the RA, Dec of the four corners of the PBCD pixel, then plot them in the mosaic image pixel grid, and convert RA, Dec into x, y, then derive the areas by coordinates. 

3, project the exposure time from each fits into another large coordinate grid, and add them together. This map shows the exposure time for each pixel. This is the total exposure map.

4, total electron map / total exposure map is the mosaic map in the unit of electron/s.

The value of one pixel in the large coordinate grid maps should come from the electrons from each fits file at the same RA, Dec. The stack looks like this:

Mosaic image in unit of electron/s = (pixel_1 * conv_factor_1 * exptime_1 + pixel_2 * conv_factor_2 * exptime_2 + pixel_3 * conv_factor_3 * exptime_3 + … + pixel_N * conv_factor_N * exptime_N) / (exptime_1 + exptime_2 + exptime_3 + … + exptime_N)

pixel_1 in the unit of MJy/sr, is the pixel value of the first fits file at the same RA, Dec as the pixel in the large coordinate grid maps; 

pixel_1 * conv_factor_1 in the unit of electron/s; 

pixel_1 * conv_factor_1 * exptime_1 in the unit of electron numbers.

Then we need a conv_factor to correct this map in the unit of MJy/sr again.

5, To convert the stacked image in the unit of electron/s map into a stacked image in the unit of MJy/sr:

Assume we have several fits files cover the same target at the same RA, Dec.

Assume each fits is flux calibrated. 

Assume the target have the flux as XXX MJy/sr.

Then each PBCD fits should have the same flux value in the unit of MJy/sr for this target, but different conv_factor, different exposure time, and then different number of electrons.

When we add the electron together, we are doing like:

XXX MJy/sr * conv_factor_1 * exptime_1 + XXX MJy/sr * conv_factor_2 * exptime_2 + XXX MJy/sr * conv_factor_3 * exptime_3 + … + XXX MJy/sr * conv_factor_N * exptime_N = electron_total

We also add exposure time together:

exptime_1 + exptime_2 +exptime_3 + … + exptime_N = exptime_total

So we can stack the fits file of this target follow the steps 1,2,3,4.

And now we should have one mosaic image for this target, in the unit of electron / s.

The flux of this target in the mosaic image is exectron_total / exptime_total.

We know this target have the flux of XXX MJy/sr in each PBCD images already. So we know the stack image should have a conv_factor_all to convert XXX MJy/sr into some value of electron/s:

XXX MJy/sr * conv_factor_all =  exectron_total / exptime_total     
= (XXX MJy/sr * conv_factor_1 * exptime_1 + XXX MJy/sr * conv_factor_2 * exptime_2 + XXX MJy/sr * conv_factor_3 * exptime_3 + … + XXX MJy/sr * conv_factor_N * exptime_N) / (exptime_1 + exptime_2 +exptime_3 + … + exptime_N)

Note this equation do not really have bussness with XXX MJy/sr, so the average conv_factor_all for the stacked image is

conv_factor_all = (conv_factor_1 * exptime_1 + conv_factor_2 * exptime_2 + conv_factor_3 * exptime_3 + … + conv_factor_N * exptime_N) / (exptime_1 + exptime_2 +exptime_3 + … + exptime_N)

which is average of the conv_factor_i, weighted by exptime_i

6, we apply conv_factor_all to the stacked image in the unit of electron/s map:

Mosaic image in unit of MJy/sr * conv_factor_all =  Mosaic image in unit of electron/s

Or:

Mosaic image in unit of MJy/sr =

 (pixel_1 * conv_factor_1 * exptime_1 + pixel_2 * conv_factor_2 * exptime_2 + pixel_3 * conv_factor_3 * exptime_3 + … + pixel_N * conv_factor_N * exptime_N) / (conv_factor_1 * exptime_1 + conv_factor_2 * exptime_2 + conv_factor_3 * exptime_3 + … + conv_factor_N * exptime_N)

This is the stacking formula I use. The stacking process in the idea of the add the elections together is the average of the pixel value of each PBCD maic fits file, weighted by the conv_factor * exposure map. This is why I make the weight map like this:
           
weight = exptime * conv_factor

I save the weight into Weight.fits. I save exptime into exp.fits.

7, I propagate of uncertainty file munc.fits follow the above stacking formula. It is like the square of munc.fits then add together into large map then sqrt it.

8, optionally, we can subtract the background for each image.

For one pixel that received some electrons, sometimes it is not easy to tell how many electrons belong to the background.

Spitzer have some idea about the background properties, For IRAC ch1, it is about 0.1 – 0.5 MJy/sr: https://irsa.ipac.caltech.edu/data/SPITZER/docs/irac/iracinstrumenthandbook/10/

Here I use the peak position of the pixel value histogram in each image, or the mod value of the histogram. Surely you can have a better background estimation.

Then I save the background subtracted maic.fits into maic.bgsub.fits

Since any photometry should take care of the background, maybe it is OK to keep the background there.

IRAC photometry is not easy especially when the image is too deep. The target selection suffer from blending issue. The outliine of the IRAC deep image photometry is: fit the aim-target and the target nearby with PSF or other models, then subtract the other targets by best-fit-model, but leave the aim-target alone, aperture photometry it, then use mod pixel value around as background. It takes a little while to write code. This is what I learnt from IRAC SEDS data, deep to about 26 AB mag. I should write a note for IRAC deep image photometry.

9, We make some list file named as: exptime.txt, maic_bgsub.txt, munc2.txt to run swarp:

Make a swarp config file:

swarp -d > stack.swarp

Add the exposure time together. I use sum to add all the exposure time together.

swarp @exptime.txt -c stack.swarp -IMAGEOUT_NAME total-exptime.fits, -WEIGHTOUT_NAME test-exptime.weight.fits, -COMBINE_TYPE SUM, -SUBTRACT_BACK N

weighted average the fits file, I use weight map list @weight.txt to weight average the maic file:

swarp @maic_bgsub.txt -c stack.swarp -IMAGEOUT_NAME rough-MJysr.fits, -WEIGHTOUT_NAME rough-MJysr.weight.fits -WEIGHT_IMAGE @weight.txt, -WEIGHT_TYPE MAP_WEIGHT, -COMBINE_TYPE WEIGHTED, -SUBTRACT_BACK N

weighted average the uncertainty:

swarp @munc2.txt -c stack.swarp -IMAGEOUT_NAME rough-munc2.fits, -WEIGHTOUT_NAME rough-munc2.weight.fits -WEIGHT_IMAGE @weight.txt, -WEIGHT_TYPE MAP_WEIGHT, -COMBINE_TYPE WEIGHTED, -SUBTRACT_BACK N

remember sqrt(rough-munc2.fits) to get the uncertainty, or maybe swarp have some combine type to square, average, sqrt the munc fits files.

I set SUBTRACT_BACK as no so swarp should not help me subtract the background. I can set it as yes, then the background is gone. Several other options, such as start with BCD files, keep the backgrounds, estimate background from target removed image, averagely weighted by uncertainty map, median the images, sigma clip, weighted median, …, depends on how do you understand the data reduction.
