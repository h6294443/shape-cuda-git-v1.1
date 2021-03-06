/*****************************************************************************************
                                                                              calc_fits.c

As the name implies, this routine calculates the fits to each data frame for the current
set of model parameters.  For example, for each delay-Doppler frame it calls routine
posvis to create the model plane-of-sky image and then routine pos2deldop to create the
model delay-Doppler image from this POS image.

calc_fits also performs some of the screen and file output required by the "write" action;
in particular, it carries out tasks that require information associated with plane-of-sky
renderings, since such information is quickly overwritten if the "pos_scope" parameter is
set to "global" (i.e., if all frames and lightcurve points share the same memory for their
"pos" structures).

Modified 2015 June 10 by CM:
    Implement smearing for the "fit" and "write" actions

Modified 2014 February 14 by CM:
    Add "ilaw" argument to the apply_photo routine

Modified 2013 July 28 by CM:
    For the "write" action, output ppm POS images when the "write_highlight" parameter is
        turned on

Modified 2013 July 7 by CM:
    For the "write" action for lightcurve points and plane-of-sky frames, display the
        body-fixed longitude and latitude of the phase-angle bisector

Modified 2013 June 25 by CM:
    Allow POS images written for optical data to be annotated with principal-axis shafts
        and the angular momentum vector
    For POS images (sky renderings), display the name of the image file and the maximum
        pixel value in the plot_surface routine (called by the write_pos routine) rather
        than here

Modified 2013 April 24 by CM:
    Implement the "listpos_deldop" "listpos_opt" and "listpos_path" parameters
    Adjust names of output images so they are in alphanumeric order if > 100 per dataset

Modified 2012 April 2 by CM:
    Correct instantaneous maximum breadth calculation for Doppler scaling factor

Modified 2011 August 14 by CM:
    Display sidereal spin vector at each epoch, even for a PA rotator, if
        any spin impulses are used

Modified 2010 September 1 by CM:
    Initialize variables to avoid compilation warnings

Modified 2010 July 29 by CM:
    Fix bug introduced in calc_lghtcrv: rotation phases weren't being
        displayed for the "write" action
    For the "write" action for lightcurve datasets, include shadowed
        regions in projected area (and geometric albedo calculation)
        and display percentage of projected area that's shadowed

Modified 2010 June 15 by CM:
    Revise arguments to pos2deldop and pos2doppler routines

Modified 2010 May 28 by CM:
    Fix bug introduced with preceding change: in calc_lghtcrv, only
        deallocate memory for the "write" action (since it wasn't
        allocated in the first place for other actions)

Modified 2010 May 24 by CM:
    For the "write" action for lightcurves, output the projected area and
        (for absolute photometry) geometric albedo

Modified 2010 April 12 by CM:
    For the "write" action, include overflow region when computing
        cross sections

Modified 2009 July 29 by CM:
    For the "write" action, fix bug: output ppm images rather than pgm
        images if the "plot_angmom" parameter is turned on
    For the "write" action, pass an argument to the "write_pos" routine
        explicitly telling it whether or not to produce a colored image

Modified 2009 April 3 by CM:
    Initialize the "posbnd_logfactor" parameter and later set it for
        models that extend beyond the POS frame
    Add "badposet" and "badposet_logfactor" parameters: initialize them
        here and then use the new "checkposet" routine to adjust them for
        plane-of-sky fit images that are too small to "contain" the
        target
    Add "badradar" and "badradar_logfactor" parameters: initialize them
        here and then use the "pos2deldop" and "pos2doppler" routines
        (which are now int rather than void) to adjust them for models that
        are too wide in delay-Doppler space for the routines to handle
    Add "warn_badradar" argument to pos2deldop and pos2doppler routines
    For the "write" action, display each plane-of-sky fit frame's linear
        dimensions, the linear dimensions of the rectangular subset that
        contains the target, and the linear COM offsets

Modified 2008 December 12 by CM:
    For the "write" action for NPA rotators, list Euler angles (giving
        the body-fixed axes' orientations in ecliptic coordinates) and
        spin vector components (in body-fixed coordinates) for each
        observation epoch
    For the "write" action for NPA rotators, ensure that maximum breadth
        is nonnegative

Modified 2007 August 10 by CM:
    Eliminated unused variables and cleaned up a printf format
    For POS model frames (sky renderings) associated with lightcurve points
        and with plane-of-sky data frames, don't display the maximum pixel
        value unless the "optposmax" parameter is nonzero

Modified 2007 August 4 by CM:
    Add comp matrix for POS frames
    Add orbit_offset and body arguments to posvis routine and remove
        facet argument
    Add orbit_xoff, orbit_yoff, orbit_dopoff and body parameters to
        pos2deldop and pos2doppler routines
    Add body argument to apply_photo routine

Modified 2007 January 17 by CM:
    For the "write" action, display instantaneous folded zero-crossing
        bandwidth for Doppler and delay-Doppler frames

Modified 2007 January 11 by CM:
    In calc_lghtcrv for the "write" action, count lightcurve points
        from 0 rather than 1, as is already done for lightcurve POS images
        (and for Doppler, delay-Doppler, and plane-of-sky frames)

Modified 2007 January 6 by CM:
    In calc_lghtcrv for the "write" action, save rotation phase for each
        calculated lightcurve point so they can be output by routine chi2,
        and use cubic spline interpolation to obtain rotation phase at
        each observation epoch.  Also display range of rotation phases
        if only one calculated point per lightcurve is displayed in full

Modified 2006 October 1 by CM:
    In calc_lghtcrv, model lightcurve points are now intensities
        (relative to the solar intensity) rather than magnitudes
    In calc_lghtcrv and calc_poset, apply_photo routine has been revised
        to account for the POS pixel area and the 1 AU Sun-target distance

Modified 2006 September 1 by CM and MCN:
    When "exclude_seen" parameter is used, add check that facet number
        pos->f[i][j] is nonnegative
    For the "write" action, don't display cross sections and albedos
        for uncalibrated (delay-)Doppler frames

Modified 2006 June 21 by CM:
    In calc_deldop, changed delres to del_per_pixel and dopres to
        dop_per_pixel
    In calc_doppler, changed dopres to dop_per_bin
    For POS renderings and plane-of-sky fit frames, changed res to
        km_per_pixel

Modified 2006 June 18 by CM:
    Allow each delay-Doppler frame within a dataset to have different
        dimensions after vignetting
    Allow each Doppler frame within a dataset to have different
        dimensions after vignetting
    Allow plane-of-sky frames to be rectangular rather than square,
        and no longer require an odd number of pixels per side
    Eliminate range datasets

Modified 2006 March 10 by CM:
    Add "speckle" argument to pos2deldop and pos2doppler routines

Modified 2005 October 6 by CM:
    For lightcurve datasets, replace SUNMAG constant by "sun_appmag"
        parameter, so that absolute photometry with filters other than
        V band can be used

Modified 2005 July 25 by CM:
    For "write" action, display the model radar cross section and albedo
        for each delay-Doppler and Doppler frame

Modified 2005 July 22 by CM:
    Created five separate routines for writing POS frames as images
        so that they can be called separately if the "mark_unseen"
        parameter is turned on for the "write" action (since in this
        case we must first process all datasets to see which model
        facets were "seen" and only then can write the POS images)

Modified 2005 July 14 by CM:
    Fix bug in computing LE-to-COM delay and distance, LE-to-TE
        delay and distance, and instantantaneous bandwidth and breadth

Modified 2005 July 13 by CM:
    For "write" action for lightcurve points and plane-of-sky frames,
        display the body-fixed longitude and latitude of the
        Sun-to-asteroid line

Modified 2005 July 5 by CM:
    Remove the "dir" argument from pos2deldop and pos2doppler and add
        the "set" argument

Modified 2005 July 3 by CM:
    For "write" action for lightcurve datasets, implement the
        "lcrv_writeall" parameter, which produces screen display for
        every model lightcurve point rather than just the one point
        which falls closest to the midpoint of the observations.

Modified 2005 June 25 by CM:
    For "write" action for delay-Doppler frames, display the delay and
        distance between the leading edge and the center of mass and
        between the leading edge and the trailing edge;
        for delay-Doppler and Doppler frames, display the instantaneous
        zero-crossing bandwidth and maximum breadth.  All of the above
        are obtained from the model's delay-Doppler limits as
        determined PRIOR to convolution with the delay and Doppler
        response functions.

Modified 2005 June 22 by CM:
    Keep track of which model facets have been "seen" (i.e., are visible
        from Earth, are unshadowed, and have sufficiently low scattering
        and incidence angles) in at least one data frame or lightcurve
        point

Modified 2005 April 23 by CM:
    For the "write" action, list whether or not epochs have been corrected
        for one-way light travel time

Modified 2005 March 1 by CM:
    Adjust arguments to the revised "resampim" routine to permit rotation
        of resampled plane-of-sky frames
    Initialize the "posbnd" parameter (flag indicating that the model
        extends beyond the model POS frame) to 0 here rather than in
        bestfit.c so that it can used for actions other than "fit"
    Fix bug in calc_poset which was incorrectly flagging the model as
        being too small for the model POS frame

Modified 2005 February 21 by CM:
    Use the new "poset_resample" parameter to allow interpolation methods
        other than bilinear for constructing plane-of-sky fit images for
        plane-of-sky data frames
    Add the new "image_rebin" argument to function resampim to handle
        plane-of-sky fit frames which have much coarser resolution
        than the model POS frames from which they are constructed
        (i.e., which are greatly undersampled)
    For "write" action, display maximum pixel value for model POS images
        for plane-of-sky frames and calculated lightcurve images
        (in case someone wants to use the "optposmax" parameter to
        truncate the image brightness)

Modified 2005 February 6 by CM:
    For "write" action, display rotation phase
    For "write" action, fix bug in computing the angular body-fixed
        coordinates of the line of sight for lightcurve datasets

Modified 2005 January 25 by CM:
    Take care of unused and uninitialized variables

Modified 2005 January 24 by CM:
    Add "calc_poset" routine to handle POS datasets
    For "write" action, display the angular body-fixed coordinates of
        the line of sight
    For "write" action, display calendar dates in addition to Julian dates
    For "write" action, display the date for range datasets

Modified 2004 December 19 by CM:
    For "write" action, display the projected area for each Doppler and
        delay-Doppler frame

Modified 2004 May 3 by CM:
    For "write" action, display the (delay-)Doppler corrections for each
        frame

Modified 2004 April 9 by CM:
    For "write" action, display the solar azimuth angles (N->E in the POS)

Modified 2004 March 27 by CM:
    Eliminate output of range (rng) plane-of-sky images for
        delay-Doppler frames
    For "write" action, display the epoch, solar phase angle and
        apparent spin vector direction at the midpoint of lightcurve
        datasets
    For "write" action, if "plot_spinvec" parameter is turned on, 
        POS pgm images include an arrow indicating the target's
        intrinsic spin vector.
    For "write" action, if "plot_subradar" parameter is turned on, 
        POS pgm images for (delay-)Doppler datasets include an X
        indicating the target's subradar point.
    For "write" action, if "plot_com" parameter is turned on, 
        POS pgm images for (delay-)Doppler datasets include a cross
        indicating the target's projected COM.
    For "write" action, if "plot_pa" parameter vector has any
        component(s) turned on, POS ppm images for (delay-)Doppler
        datasets include colored cylindrical shaft(s) indicating the
        positive end of the corresponding principal axis/axes.

Modified 2004 Feb 29 by CM:
    Add comments for lightcurves
    Remove "sdev" argument to routine gamma_trans
    Compute lightcurve magnitudes rather than negative magnitudes
    Eliminate the "curve_mm" lightcurve output file, since it nearly
        duplicates the "fit.mm" file (except that the cal factor
        isn't included)
    Move the lightcurve calculations to the new "calc_lghtcrv" routine
    Eliminate the unused dat argument to calc_deldop, calc_doppler,
        and calc_range
    Eliminate "type" argument to the "apply_photo" routine, and
        add the "phase" (solar phase angle) argument
    Label lightcurve POS images as 0 through (ncalc-1) rather than
        1 through ncalc, similar to (delay-)Doppler pgm images

Modified 2003 July 30 by CM:
    Add three parameters for rotating/flipping output pgm files
        for delay-Doppler images (fit, data, residuals)

Modified 2003 May 16 by CM:
    Add listres parameter for producing output files containing
        residual matrices

Modified 2003 May 13 by CM:
    Don't resample and recenter residual pgm images if dd_scaling = none
    Correct a bug in normalizing file output for Doppler fits

Modified 2003 May 10 by CM:
    Add scalefitobs parameter so that user can choose whether to scale
        the data and fit pgm images separately (default), to the maximum
        value of the two taken together, to the maximum fit value, or to
        the maximum data value

Modified 2003 May 7 by CM:
    Add sinc2width argument to pos2deldop and pos2doppler

Modified 2003 April 29 by CM:
    Don't truncate residuals to integer values before making pgm images
    Add nsinc2 argument to pos2deldop and pos2doppler

Modified 2003 April 28 by CM:
    Display two angles for the spin vector, not just one

Modified 2003 April 24 by CM:
    Move "delcom" from delay-Doppler datasets to individual frames

Modified 2003 April 23 by CM:
    Removed "deldopoffs" call from calc_deldop and "dopoffs" call from
        calc_deldop, since these calls are now included in realize_delcor
 *****************************************************************************************/
extern "C" {
#include "head.h"
}

__host__ void calc_deldop_cuda_af(struct par_t *dpar, struct mod_t *dmod,
		struct dat_t *ddat, int s, int c);
__host__ void calc_doppler_cuda_af(struct par_t *dpar, struct mod_t *dmod,
		struct dat_t *ddat, int s, int c);
//__host__ void calc_poset_cuda( struct par_t *par, struct mod_t *mod, int s);
//__host__ void calc_lghtcrv_cuda(struct par_t *par, struct mod_t *mod, struct
//		lghtcrv_t *lghtcrv, int s);

__device__ int cfaf_nframes, cfaf_nviews, cfaf_v0_index, cfaf_exclude_seen;
__device__ unsigned char cfaf_type;

__global__ void cf_init_devpar_af_krnl(struct par_t *dpar, struct mod_t
		*dmod, struct dat_t *ddat, int c, int *nf_nsets) {
	/* Single-threaded kernel */
	if (threadIdx.x == 0) {
		dpar->posbnd = 0;
		dpar->badposet = 0;
		dpar->badradar = 0;
		dpar->posbnd_logfactor = 0.0;
		dpar->badposet_logfactor = 0.0;
		dpar->badradar_logfactor = 0.0;
		nf_nsets[0] = dmod->shape.comp[c].real.nf;
		nf_nsets[1] = ddat->nsets;
	}
}
__global__ void cf_init_seen_flags_af_krnl(struct mod_t *dmod, int c,
		int *nf_nsets) {
	/* nf-threaded kernel */
	int f = blockIdx.x * blockDim.x + threadIdx.x;

	if (f < nf_nsets[0])
		dmod->shape.comp[c].real.f[f].seen = 0;
}
__global__ void cf_get_set_type_af_krnl(struct dat_t *ddat, int s) {
	/* Single-threaded kernel */
	if (threadIdx.x == 0)
		cfaf_type = ddat->set[s].type;
}
//__global__ void cf_set_final_pars_af_krnl(struct par_t *dpar, struct
//		dat_t *ddat) {
//	/* Single-threaded kernel */
//	if (threadIdx.x == 0) {
//		dpar->posbnd_logfactor /= ddat->dof;
//		dpar->badposet_logfactor /= ddat->dof_poset;
//		dpar->badradar_logfactor /= (ddat->dof_deldop + ddat->dof_doppler);
//	}
//}

__host__ void calc_fits_cuda_af(struct par_t *dpar, struct mod_t *dmod,
		struct dat_t *ddat)
{
	int s, *nf_nsets, c=0;
	unsigned char type;
	dim3 BLK,THD;
	cudaCalloc1((void**)&nf_nsets, sizeof(int), 2);

	/* Initialize flags that indicate the model extends beyond POS frame, that
	 * plane-of-sky fit images are too small to "contain" the target, and that
	 * model is too wide in (delay-)Doppler space to create (delay-)Doppler fit
	 * frames.  Note that this also gets mod->shape.nf and nsets            */

	cf_init_devpar_af_krnl<<<1,1>>>(dpar, dmod, ddat, c, nf_nsets);
	checkErrorAfterKernelLaunch("cf_init_devpar_af_krnl");
	deviceSyncAfterKernelLaunch("cf_init_devpar_af_krn");

	/* Initialize the flags that indicate whether or not each facet of each
	 * model component is ever visible and unshadowed from Earth
	 * Note:  Single component only for now.  */
	//for (c=0; c<mod->shape.ncomp; c++)
	BLK.x = floor((maxThreadsPerBlock - 1 + nf_nsets[0])/maxThreadsPerBlock);
	THD.x = maxThreadsPerBlock;
	cf_init_seen_flags_af_krnl<<<BLK,THD>>>(dmod, c, nf_nsets);
	checkErrorAfterKernelLaunch("cf_init_seen_flags_af_krnl");
	deviceSyncAfterKernelLaunch("cf_init_seen_flags_af_krnl");

	/* Calculate the fits for each dataset in turn - use multi-GPU later */
	for (s=0; s<nf_nsets[1]; s++) {

		/* Get data type */
		cf_get_set_type_af_krnl<<<1,1>>>(ddat, s);
		checkErrorAfterKernelLaunch("cf_init_seen_flags_krnl (calc_fits_cuda)");
		gpuErrchk(cudaMemcpyFromSymbol(&type, cfaf_type, sizeof(unsigned char),
				0, cudaMemcpyDeviceToHost));

		switch (type) {
		case DELAY:
			calc_deldop_cuda_af(dpar, dmod, ddat, s, c);
			break;
		case DOPPLER:
			calc_doppler_cuda_af(dpar, dmod, ddat, s, c);
			break;
		case POS:
			printf("Write calc_poset_cuda!");
//			calc_poset_cuda(dpar, dmod, s);
			break;
		case LGHTCRV:
			printf("Write calc_lghtcrv_cuda!");
//			calc_lghtcrv_cuda(dpar, dmod, s);
			break;
		default:
			printf("calc_fits_cuda.c: can't handle this type yet\n");
		}
	}
	/* Complete calculations of values that will be used during a fit to
	 * increase the objective function for models with bad properties   */
	cf_set_final_pars_krnl<<<1,1>>>(dpar, ddat);
	checkErrorAfterKernelLaunch("cf_set_final_pars_af_krnl");
}

__global__ void cf_get_frames_af_krnl(struct dat_t *ddat, int s) {
	/* Single-threaded kernel */
	if (threadIdx.x == 0) {
		switch(ddat->set[s].type) {
		case DELAY:
			cfaf_nframes = ddat->set[s].desc.deldop.nframes;
			break;
		case DOPPLER:
			cfaf_nframes = ddat->set[s].desc.doppler.nframes;
			break;
		case POS:
			cfaf_nframes = ddat->set[s].desc.poset.nframes;
			break;
		case LGHTCRV:
			cfaf_nframes = ddat->set[s].desc.lghtcrv.ncalc;
			break;
		}
	}
}
__global__ void cf_set_shortcuts_deldop_af_krnl(
		struct dat_t *ddat,
		struct deldopfrm_t **frame,
		struct deldopview_t **view0,
		struct pos_t **pos,
		float *overflow,
		int *ndel,
		int *ndop,
		int s,
		int nframes) {
	/* nframes-threaded kernel */
	int frm = threadIdx.x;
	if (frm < nframes) {
		if (threadIdx.x==0) {
			cfaf_nviews	 = ddat->set[s].desc.deldop.nviews;
			cfaf_v0_index  = ddat->set[s].desc.deldop.v0;
			overflow[0] = 0.0; // cf_overflow_o2_store = 0.0;
			overflow[1] = 0.0; // cf_overflow_m2_store = 0.0;
			overflow[2] = 0.0; // cf_overflow_xsec_store = 0.0;
			overflow[3] = 0.0; // cf_overflow_dopmean_store = 0.0;
			overflow[4] = 0.0; // cf_overflow_delmean_store = 0.0;
		}
		frame[frm] = &ddat->set[s].desc.deldop.frame[frm];
		ndop[frm]  = frame[frm]->ndop;
		ndel[frm]  = frame[frm]->ndel;
		view0[frm] = &frame[frm]->view[ddat->set[s].desc.deldop.v0];
		pos[frm]   = &frame[frm]->pos;
	}
}
__global__ void cf_set_shortcuts_doppler_af_krnl(struct dat_t *ddat, int s,
		int nframes,
		struct dopfrm_t **frame,
		int *ndop,
		struct dopview_t **view0,
		struct pos_t **pos,
		float *overflow,
		int4 *xylim) {
	/* nframes-threaded kernel */
	int frm = threadIdx.x;

	if (frm < nframes) {

		if (threadIdx.x == 0) {
			cfaf_nviews	 = ddat->set[s].desc.doppler.nviews;
			cfaf_v0_index  = ddat->set[s].desc.doppler.v0;
			overflow[0] = 0.0; // cf_overflow_o2_store = 0.0;
			overflow[1] = 0.0; // cf_overflow_m2_store = 0.0;
			overflow[2] = 0.0; // cf_overflow_xsec_store = 0.0;
			overflow[3] = 0.0; // cf_overflow_dopmean_store = 0.0;
		}
		frame[frm] = &ddat->set[s].desc.doppler.frame[frm];
		view0[frm] = &frame[frm]->view[ddat->set[s].desc.doppler.v0];
		ndop[frm]  = frame[frm]->ndop;
		pos[frm]   = &frame[frm]->pos;
	}
}
__global__ void cf_set_pos_ae_deldop_af_krnl(struct pos_t **pos, struct deldopfrm_t
		**frame, int *pos_n, int nframes, int v) {
	/* nframes*9-threaded kernel */
	int offset = threadIdx.x;
	int i = offset % 3;
	int j = offset / 3;
	int frm = blockIdx.x;

	if ((offset < 9) && (frm < nframes)) {
			pos[frm]->ae[i][j] = frame[frm]->view[v].ae[i][j];
			pos[frm]->oe[i][j] = frame[frm]->view[v].oe[i][j];

		/* Single-thread task */
		if (offset == 0) {
			pos[frm]->bistatic = 0;
			pos_n[frm] = pos[frm]->n;
		}
	}
}
__global__ void cf_set_pos_ae_doppler_af_krnl(struct pos_t **pos, struct dopfrm_t
		**frame, int *pos_n, int nframes, int v) {
	/* nframes*9-threaded kernel */
	int offset = threadIdx.x;
	int i = offset % 3;
	int j = offset / 3;
	int frm = blockIdx.x;

	if ((offset < 9) && (frm < nframes)) {
		pos[frm]->ae[i][j] = frame[frm]->view[v].ae[i][j];
		pos[frm]->oe[i][j] = frame[frm]->view[v].oe[i][j];

		/* frm-level-thread task */
		if (offset == 0) {
			pos[frm]->bistatic = 0;
			pos_n[frm] = pos[frm]->n;
		}
	}
}
__global__ void cf_posclr_af_krnl(struct pos_t **pos, int n, int nx, int frame_size,
		int nframes)
{
	/* (nframes * npixels)-threaded kernel where npixels is the number of pixels
	 * in the full POS image, so (2*pos->n + 1)^2 */
	int total_offset = blockIdx.x * blockDim.x + threadIdx.x;
	int frm = total_offset / frame_size;
	int offset = total_offset % frame_size;	// local offset within one frame
	int i = (offset % nx) - n;
	int j = (offset / nx) - n;

	if ((offset < frame_size) && (total_offset < nframes*frame_size) &&
			(frm < nframes)) {
		/* For each POS pixel, zero out the optical brightness (b) and
		 * cos(scattering angle), reset the z coordinate (distance from COM towards
		 * Earth) to a dummy value, and reset the body, component, and facet onto
		 * which the pixel center projects to  dummy values                  */
		pos[frm]->body[i][j] = pos[frm]->comp[i][j] = pos[frm]->f[i][j] = -1;
		pos[frm]->b_s[offset] = pos[frm]->cose_s[offset] = 0.0;
		pos[frm]->z_s[offset] = -HUGENUMBER;

		/* In the x direction, reset the model's leftmost and rightmost
		 * pixel number to dummy values, and similarly for the y direction   */
		pos[frm]->xlim[0] = pos[frm]->ylim[0] =  n;
		pos[frm]->xlim[1] = pos[frm]->ylim[1] = -n;

		/* For a bistatic situation (lightcurve or plane-of-sky dataset), zero out
		 * cos(incidence angle) and reset the distance towards the sun, the body,
		 * component, and facet numbers as viewed from the sun, and the model's
		 * maximum projected extent as viewed from the sun to dummy values    */
		if (pos[frm]->bistatic) {
			pos[frm]->bodyill[i][j] = pos[frm]->compill[i][j] = pos[frm]->fill[i][j] = -1;
			pos[frm]->cosill_s[offset] = 0.0;
			pos[frm]->zill_s[offset] = 0.0;

			pos[frm]->xlim2[0] = pos[frm]->ylim2[0] =  n;
			pos[frm]->xlim2[1] = pos[frm]->ylim2[1] = -n;
		}
	}
}
__global__ void cf_set_posbnd_deldop_af_krnl(struct par_t *dpar,
		struct deldopfrm_t **frame,
		struct pos_t **pos,
		int nframes) {
	/* nframes-threaded kernel */
	int frm = threadIdx.x;
	if (frm<nframes) {
		if (frm==0)
			dpar->posbnd = 1;
		dpar->posbnd_logfactor += frame[frm]->dof * pos[frm]->posbnd_logfactor;
	}
}
__global__ void cf_set_posbnd_doppler_af_krnl(struct par_t *dpar,
		struct dopfrm_t **frame,
		struct pos_t **pos,
		int nframes) {
	/* nframes-threaded kernel */
	int frm = threadIdx.x;
	if (frm<nframes) {
		if (frm==0)
			dpar->posbnd = 1;
		dpar->posbnd_logfactor += frame[frm]->dof * pos[frm]->posbnd_logfactor;
	}
}
__global__ void cf_get_exclude_seen_af_krnl(struct par_t *dpar,
		struct pos_t **pos,
		int4 *xylim,
		int nframes) {
	/* nframes-threaded kernel */
	int frm = threadIdx.x;
	if (frm < nframes) {
		if (threadIdx.x == 0)
			cfaf_exclude_seen = dpar->exclude_seen;
		xylim[frm].w = pos[frm]->xlim[0];
		xylim[frm].x = pos[frm]->xlim[1];
		xylim[frm].y = pos[frm]->ylim[0];
		xylim[frm].z = pos[frm]->ylim[1];
	}
}
__global__ void cf_get_global_frmsz_krnl(int *global_lim, int4 *xylim,
		int nframes) {
	/* nframes-threaded kernel */
	int frm = threadIdx.x;
	if (frm < nframes) {
		/* Initialize global_lim 	 */
		for (int i=0; i<4; i++)
			global_lim[i] = 0;

		/* Now calculate minimum for all frames */
		atomicMin(&global_lim[0], xylim[frm].w);
		atomicMax(&global_lim[1], xylim[frm].x);
		atomicMin(&global_lim[2], xylim[frm].y);
		atomicMax(&global_lim[3], xylim[frm].z);
	}
}
__global__ void cf_mark_pixels_seen_af_krnl(
		struct par_t *dpar,
		struct mod_t *dmod,
		struct pos_t **pos,
		int *global_lim,
		int frame_size,
		int xspan,
		int nframes,
		int c) {
	/* nframes*npixels-threaded kernel */
	int total_offset = blockIdx.x * blockDim.x + threadIdx.x;
	int frm = total_offset / frame_size;
	int offset = total_offset % frame_size;
	int k = (offset % xspan) + global_lim[0]; // cf_xlim0;
	int l = (offset / xspan) + global_lim[2]; // cf_ylim0;
	int facetnum;
	c = 0;

	if ((offset < frame_size) && (frm < nframes)) {
		if ((pos[frm]->cose_s[offset] > dpar->mincosine_seen)
				&& (pos[frm]->f[k][l] >= 0)) {
			facetnum = pos[frm]->f[k][l];
			//c = cf_pos->comp[k][l];
			dmod->shape.comp[c].real.f[facetnum].seen = 1;
		}
	}
}
__global__ void cf_set_badradar_deldop_af_krnl(
		struct par_t *dpar,
		struct dat_t *ddat,
		struct deldopfrm_t **frame,
		int s,
		int nframes) {

	/* nframes-threaded kernel */
	int frm = threadIdx.x;
	if (frm < nframes) {
		if (threadIdx.x == 0)
			dpar->badradar = 1;
		dpar->badradar_logfactor += frame[frm]->dof *
				frame[frm]->badradar_logfactor / ddat->set[s].desc.deldop.nviews;
	}
}
__global__ void cf_set_badradar_doppler_af_krnl(
		struct par_t *dpar,
		struct dat_t *ddat,
		struct dopfrm_t **frame,
		int s,
		int nframes) {

	/* nframes-threaded kernel */
	int frm = threadIdx.x;
	if (frm < nframes) {
		if (threadIdx.x == 0)
			dpar->badradar = 1;
		dpar->badradar_logfactor +=frame[frm]->dof *
				frame[frm]->badradar_logfactor / ddat->set[s].desc.doppler.nviews;
	}
}
__global__ void cf_add_fit_store_af_krnl1(
		struct dat_t *ddat,
		float **fit_store,
		int frame_size,
		int s,
		int nframes) {
	/* (nframes*ndel*ndop)-threaded kernel */
	int total_offset = blockIdx.x * blockDim.x + threadIdx.x;
	int frm = total_offset / frame_size;
	int offset = total_offset % frame_size;

	if ((offset < frame_size) && (frm < nframes)) {
		switch (cfaf_type) {
		case DELAY:
			fit_store[frm][offset] += ddat->set[s].desc.deldop.frame[frm].fit_s[offset];
			break;
		case DOPPLER:
			fit_store[frm][offset] += ddat->set[s].desc.doppler.frame[frm].fit_s[offset];
			break;
		}
	}
}
__global__ void cf_add_fit_store_deldop_af_krnl2(
		struct deldopfrm_t **frame,
		float *overflow,
		int nframes) {
	/* nframes-threaded kernel */
	int frm = threadIdx.x;

	if (frm < nframes) {
		/* 	overflow[0] - overflow_o2_store
		 * 	overflow[1] - overflow_m2_store
		 * 	overflow[2] - overflow_xsec_store
		 * 	overflow[3] - overflow_dopmean_store
		 * 	overflow[4] - overflow_delmean_store
		 */
		atomicAdd(&overflow[0], (float)frame[frm]->overflow_o2);
		atomicAdd(&overflow[1], (float)frame[frm]->overflow_m2);
		atomicAdd(&overflow[2], (float)frame[frm]->overflow_xsec);
		atomicAdd(&overflow[3], (float)frame[frm]->overflow_delmean);
		atomicAdd(&overflow[4], (float)frame[frm]->overflow_dopmean);
	}
}
__global__ void cf_add_fit_store_doppler_af_krnl2(
		struct dopfrm_t **frame,
		float *overflow,
		int nframes) {
	/* nframes-threaded kernel */
	int frm = threadIdx.x;

	if (frm < nframes) {
		/* 	overflow[0] - overflow_o2_store
		 * 	overflow[1] - overflow_m2_store
		 * 	overflow[2] - overflow_xsec_store
		 * 	overflow[3] - overflow_dopmean_store
		 */
		atomicAdd(&overflow[0], (float)frame[frm]->overflow_o2);
		atomicAdd(&overflow[1], (float)frame[frm]->overflow_m2);
		atomicAdd(&overflow[2], (float)frame[frm]->overflow_xsec);
		atomicAdd(&overflow[3], (float)frame[frm]->overflow_dopmean);
	}
}
__global__ void cf_finish_fit_store_af_krnl(
		struct dat_t *ddat,
		float **fit_store,
		int s,
		int nThreads,
		int frame_size) {
	/* (nframes*ndel*ndop)-threaded kernel for Delay Doppler,
	 * (nframes*ndop)-threaded kernel for Doppler */
	int total_offset = blockIdx.x * blockDim.x + threadIdx.x;
	int frm = total_offset / frame_size;
	int offset = total_offset % frame_size;

	if (offset < nThreads)
		switch (cfaf_type) {
		case DELAY:
			ddat->set[s].desc.deldop.frame[frm].fit_s[offset] = fit_store[frm][offset];
			break;
		case DOPPLER:
			ddat->set[s].desc.doppler.frame[frm].fit_s[offset] = fit_store[frm][offset];
			break;
		}
}
__global__ void cf_finish_fit_deldop_af_krnl2(
		struct deldopfrm_t **frame,
		float *overflow,
		int nframes) {
	/* nframes-threaded Kernel */
	int frm = threadIdx.x;
	if (frm < nframes) {
		/*	overflow[0] = overflow_o2_store
		 * 	overflow[1] = overflow_m2_store
		 * 	overflow[2] = overflow_xsec_store
		 * 	overflow[3] = overflow_dopmean_store
		 * 	overflow[4] = overflow_delmean_store		 */

		frame[frm]->overflow_o2 	 = overflow[0] / cfaf_nviews;
		frame[frm]->overflow_m2 	 = overflow[1] / cfaf_nviews;
		frame[frm]->overflow_xsec 	 = overflow[2] / cfaf_nviews;
		frame[frm]->overflow_dopmean = overflow[3] / cfaf_nviews;
		frame[frm]->overflow_delmean = overflow[4] / cfaf_nviews;
	}
}
__global__ void cf_finish_fit_doppler_af_krnl2(
		struct dopfrm_t **frame,
		float *overflow,
		int nframes) {
	/* nframes-threaded Kernel */
	int frm = threadIdx.x;
	if (frm < nframes) {
		/*	overflow[0] = overflow_o2_store
		 * 	overflow[1] = overflow_m2_store
		 * 	overflow[2] = overflow_xsec_store
		 * 	overflow[3] = overflow_dopmean_store */

		frame[frm]->overflow_o2 	 = overflow[0] / cfaf_nviews;
		frame[frm]->overflow_m2 	 = overflow[1] / cfaf_nviews;
		frame[frm]->overflow_xsec 	 = overflow[2] / cfaf_nviews;
		frame[frm]->overflow_dopmean = overflow[3] / cfaf_nviews;
	}
}
__global__ void cf_gamma_trans_deldop_af_krnl(
		struct par_t *dpar,
		struct dat_t *ddat,
		int s,
		int nframes,
		int frame_size) {

	/* Multi-threaded kernel */
	int total_offset = blockIdx.x * blockDim.x + threadIdx.x;
	int frm = total_offset / frame_size;
	int offset = total_offset % frame_size;

	/* Each thread uses this value, so put it in shared memory */
	__shared__ float dd_gamma;
	dd_gamma = (float)dpar->dd_gamma;

	if ((offset < frame_size) && (frm < nframes) && (dd_gamma != 0)) {
		/*  Carry out a gamma transformation on the fit image if requested  */
		dev_gamma_trans_f(&ddat->set[s].desc.deldop.frame[frm].fit_s[offset],
				dd_gamma);
	}
}

__host__ void calc_deldop_cuda_af(struct par_t *dpar, struct mod_t *dmod,
		struct dat_t *ddat, int s, int c)
{
	float orbit_offset[3] = {0.0, 0.0, 0.0};
	int nframes, nThreads, nviews, v0_index,  nx, exclude_seen, v, v2,
		xspan, yspan, frmsz;
	int *ndel, *ndop, *global_lim, *pos_n;
	int4 *xylim;
	float *overflow, **fit_store;
	struct deldopfrm_t **frame;
	struct deldopview_t **view0;
	struct pos_t **pos;
	dim3 BLK,THD;

	/* Get # of frames for this deldop */
	cf_get_frames_af_krnl<<<1,1>>>(ddat, s);
	checkErrorAfterKernelLaunch("cf_get_nframes_af_krnl");
	gpuErrchk(cudaMemcpyFromSymbol(&nframes, cfaf_nframes, sizeof(int),
			0, cudaMemcpyDeviceToHost));

	/* Allocate memory */
	cudaCalloc1((void**)&frame, 		sizeof(struct deldopfrm_t*), nframes);
	cudaCalloc1((void**)&view0, 		sizeof(struct deldopview_t*),nframes);
	cudaCalloc1((void**)&pos, 		sizeof(struct pos_t*), 		 nframes);
	cudaCalloc1((void**)&overflow, 	sizeof(float),				 	   5);
	cudaCalloc1((void**)&ndel, 		sizeof(int),				 nframes);
	cudaCalloc1((void**)&ndop, 		sizeof(int),				 nframes);
	cudaCalloc1((void**)&pos_n, 		sizeof(int),				 nframes);
	cudaCalloc1((void**)&global_lim, sizeof(int),				 nframes);
	cudaCalloc1((void**)&xylim, 		sizeof(int4),				 nframes);

//	for (f=0; f<nframes; f++) {
	/* Set frame, view0, and pos */
	THD.x = nframes;
	cf_set_shortcuts_deldop_af_krnl<<<1,THD>>>(ddat, frame, view0, pos,
			overflow, ndel, ndop, s, nframes);
	checkErrorAfterKernelLaunch("cf_set_shortcuts_deldop_af_krnl");
	deviceSyncAfterKernelLaunch("cf_set_shortcuts_deldop_af_krnl");
	gpuErrchk(cudaMemcpyFromSymbol(&nviews, cfaf_nviews, sizeof(int),
			0, cudaMemcpyDeviceToHost));
	gpuErrchk(cudaMemcpyFromSymbol(&v0_index, cfaf_v0_index, sizeof(int),
			0, cudaMemcpyDeviceToHost));
	/* Calculate size of each frame's fit array. This assumes all frames have
	 * the same number of doppler and delay bins.	 */
	frmsz = ndel[0]*ndop[0];

	/* If smearing is being modeled, initialize variables that
	 * will be used to sum results calculated for individual views.  */
	if (nviews > 1) {
		/* Allocate fit_store which is a double-pointer in the af version as
		 * each frame needs its own fit_store array */
		cudaCalloc1((void**)&fit_store, sizeof(float*), nframes);
		for (int i=0; i<nframes; i++)
			cudaCalloc1((void**)&fit_store[i], sizeof(float), frmsz);
	}
	/*  Loop over all views for this (smeared) frame, going in an order that
        ends with the view corresponding to the epoch listed for this frame
        in the obs file; this way we can use the calculated information for
        that view in the "write" action screen and disk output that follows   */

	for (v2=v0_index+1; v2<=v0_index+nviews; v2++) {
		v = v2 % nviews;

		/* Launch 9*nframes-threaded kernel to set pos->ae,pos->oe,pos->bistatic.*/
		THD.x = 9;
		BLK.x = nframes;
		cf_set_pos_ae_deldop_af_krnl<<<BLK,THD>>>(pos, frame, pos_n, nframes, v);
		checkErrorAfterKernelLaunch("cf_set_pos_ae_deldop_af_krnl");
		deviceSyncAfterKernelLaunch("cf_set_pos_ae_deldop_af_krnl");

		/* Configure & launch posclr_krnl to initialize POS view */
		nx = 2*pos_n[0]+1;
		nThreads = nframes * nx * nx;
		BLK.x = floor((maxThreadsPerBlock - 1 + nThreads) /
				maxThreadsPerBlock);
		THD.x = maxThreadsPerBlock; // Thread block dimensions
		cf_posclr_af_krnl<<<BLK,THD>>>(pos, pos_n[0], nx, (nx*nx), nframes);
		checkErrorAfterKernelLaunch("cf_posclr_af_krnl");

		/* Call posvis_cuda_2 to get facet number, scattering angle,
		 * distance toward Earth at center of each POS pixel; set flag
		 * posbnd if any model portion extends beyond POS frame limits.*/
		/* NOTE: Limited to single component for now */

		if (posvis_af(dpar,dmod,ddat,orbit_offset,s,nframes,0,0,0) &&
				v == v0_index) {
			/* Call single-threaded kernel to set dpar->posbnd and
			 * dpar->posbnd_logfactor */
			THD.x = nframes;
			cf_set_posbnd_deldop_af_krnl<<<BLK,THD>>>(dpar,frame,pos,nframes);
			checkErrorAfterKernelLaunch("cf_set_posbnd_deldop_af_krnl");
		}

		/* Launch nframes-threaded kernel to get dpar->exclude_seen */
		THD.x = nframes;
		cf_get_exclude_seen_af_krnl<<<1,THD>>>(dpar,pos,xylim,nframes);
		checkErrorAfterKernelLaunch("cf_get_exclude_seen_af_krnl");
		gpuErrchk(cudaMemcpyFromSymbol(&exclude_seen, cfaf_exclude_seen, sizeof(int),
				0, cudaMemcpyDeviceToHost));

		/* Get the largest pos->xlim and ylim values for all frames */
		cf_get_global_frmsz_krnl<<<1,THD>>>(global_lim, xylim, nframes);
		checkErrorAfterKernelLaunch("cf_get_global_frmsz_krnl");
		deviceSyncAfterKernelLaunch("cf_get_global_frmsz_krnl");

		/* Go through all POS pixels which are visible with low enough
		 * scattering angle and mark the facets which project onto their
		 * centers as having been "seen" at least once                   */
		if (s != exclude_seen && v == v0_index) {

			xspan = global_lim[1] - global_lim[0] + 1; // xlim1 - xlim0 + 1;
			yspan = global_lim[3] - global_lim[2] + 1; // ylim1 - ylim0 + 1;
			nThreads = nframes * xspan * yspan;

			/* Configure & launch posclr_af_krnl to initialize POS view */
			BLK.x = floor((maxThreadsPerBlock - 1 + nThreads) /
					maxThreadsPerBlock);
			THD.x = maxThreadsPerBlock; // Thread block dimensions
			cf_mark_pixels_seen_af_krnl<<<BLK,THD>>>(dpar, dmod, pos, global_lim,
					(xspan*yspan), xspan, nframes, c);
			checkErrorAfterKernelLaunch("cf_mark_pixels_seen_af_krnl");
		}

		/* Zero out the fit delay-Doppler image, then call pos2deldop to
		 * create the fit image by mapping power from the plane of the sky
		 * to delay-Doppler space.                             */
		deviceSyncAfterKernelLaunch("pre-clrvect_krnl sync in calc_fits_cuda_af.cu");
		nThreads = frmsz * nframes;
		BLK.x = floor((maxThreadsPerBlock-1 + nThreads)/maxThreadsPerBlock);
		THD.x = maxThreadsPerBlock; // Thread block dimensions
		clrvect_af_krnl<<<BLK,THD>>>(ddat, s, nframes, nThreads, frmsz);
		checkErrorAfterKernelLaunch("clrvect_af_krnl, calc_fits_cuda");

		if (pos2deldop_cuda_af(dpar,dmod,ddat,0.0,0.0,0.0,0, s,nframes,v)) {
			/* Call single-threaded kernel to set badradar flag and
			 * associated badradar_logfactor			 */
			THD.x = nframes;
			cf_set_badradar_deldop_af_krnl<<<1,THD>>>(dpar, ddat, frame, s,
					nframes);
			checkErrorAfterKernelLaunch("cf_set_badradar_deldop_af_krnl");
		}

		/* If smearing is being modeled, include delay-Doppler calculations
		 * from this view in the summed results for this frame  */
		if (nviews > 1) {
			/* Launch ndel*ndop-threaded kernel to add fit[i][j] to
			 * fit_store[i][j]*/
			/* frmsz and nThreads are still accurate from the clrvect call */
			BLK.x = floor((maxThreadsPerBlock-1 + nThreads)/maxThreadsPerBlock);
			THD.x = maxThreadsPerBlock;
			cf_add_fit_store_af_krnl1<<<BLK,THD>>>(ddat,fit_store,frmsz,s,nframes);
			checkErrorAfterKernelLaunch("cf_add_fit_store_af_krnl1");

			THD.x = nframes;
			cf_add_fit_store_deldop_af_krnl2<<<1,THD>>>(frame,overflow,nframes);
			checkErrorAfterKernelLaunch("cf_add_fit_store_deldop_af_krnl2");
		}
	} /* end views loop */

	/* If smearing is being modeled, compute mean values over all views for
	 * this frame and store them in the standard frame structure     */
	/* This kernel also carries out the gamma transformation on the fit
	 * image if the par->dd_gamma flag is not set  */
	if (nviews > 1) {
		/* Launch (nframes*ndel*ndop)-threaded kernel */
		nThreads = frmsz*nframes;
		BLK.x = floor((maxThreadsPerBlock-1 + nThreads)/maxThreadsPerBlock);
		THD.x = maxThreadsPerBlock;

		cf_finish_fit_store_af_krnl<<<BLK,THD>>>(ddat,fit_store,s,nThreads,frmsz);
		checkErrorAfterKernelLaunch("cf_finish_fit_af_store");

		THD.x = nframes;
		cf_finish_fit_deldop_af_krnl2<<<1,THD>>>(frame,overflow,nframes);
		checkErrorAfterKernelLaunch("cf_finish_fit_deldop_af_krnl2");

		THD.x = maxThreadsPerBlock;
		cf_gamma_trans_deldop_af_krnl<<<BLK,THD>>>(dpar, ddat, s, nframes, frmsz);
		checkErrorAfterKernelLaunch("cf_gamma_trans_krnl");
		cudaFree(fit_store);
	}
	//}  /* end loop over frames */
	/* De-allocate memory */
	cudaFree(frame);
	cudaFree(view0);
	cudaFree(pos);
	cudaFree(overflow);
	cudaFree(ndel);
	cudaFree(ndop);
	cudaFree(pos_n);
	cudaFree(global_lim);
	cudaFree(xylim);
}

__host__ void calc_doppler_cuda_af(struct par_t *dpar, struct mod_t *dmod,
		struct dat_t *ddat, int s, int c)
{
	float orbit_offset[3] = {0.0, 0.0, 0.0};
	float **fit_store, *overflow;
	int *ndop, *pos_n, *global_lim, v0_index, frmsz, nThreads, exclude_seen, nviews, nframes, nx, f, v, v2,
	xspan, yspan;
	dim3 BLK,THD;

	struct dopfrm_t **frame;
	struct dopview_t **view0;
	struct pos_t **pos;
	int4 *xylim;

	/* Get # of frames for this deldop */
	cf_get_frames_af_krnl<<<1,1>>>(ddat, s);
	checkErrorAfterKernelLaunch("cf_get_nframes_krnl (calc_deldop_cuda)");
	gpuErrchk(cudaMemcpyFromSymbol(&nframes, cfaf_nframes, sizeof(int),
			0, cudaMemcpyDeviceToHost));

	/* Allocate memory */
	cudaCalloc1((void**)&frame, 		sizeof(struct dopfrm_t*), nframes);
	cudaCalloc1((void**)&view0, 		sizeof(struct dopview_t*),nframes);
	cudaCalloc1((void**)&pos, 		sizeof(struct pos_t*), 	  nframes);
	cudaCalloc1((void**)&overflow, 	sizeof(float),			        4);
	cudaCalloc1((void**)&ndop, 		sizeof(int),		 	  nframes);
	cudaCalloc1((void**)&pos_n, 		sizeof(int),			  nframes);
	cudaCalloc1((void**)&global_lim, sizeof(int),			  nframes);
	cudaCalloc1((void**)&xylim, 		sizeof(int4),			  nframes);

//	for (f=0; f<nframes; f++) {
	/* Set frame, view0, and pos */
	THD.x = nframes;
	cf_set_shortcuts_doppler_af_krnl<<<1,THD>>>(ddat, s, nframes, frame,
			ndop, view0, pos, overflow, xylim);
	checkErrorAfterKernelLaunch("cf_set_shortcuts_doppler_af_krnl");
	deviceSyncAfterKernelLaunch("cf_set_shortcuts_doppler_af_krnl");
	gpuErrchk(cudaMemcpyFromSymbol(&nviews, cfaf_nviews, sizeof(int),
			0, cudaMemcpyDeviceToHost));
	gpuErrchk(cudaMemcpyFromSymbol(&v0_index, cfaf_v0_index, sizeof(int),
			0, cudaMemcpyDeviceToHost));

	/* Calculate size of each frame's fit array. This assumes all frames have
	 * the same number of doppler.	 */
	frmsz = ndop[0];

	/* If smearing is being modeled, initialize variables that
	 * will be used to sum results calculated for individual views.  */
	if (nviews > 1) {
		/* Allocate fit_store which is a double-pointer in the af version as
		 * each frame needs its own fit_store array */
		cudaCalloc1((void**)&fit_store, sizeof(float*), nframes);
		for (int i=0; i<nframes; i++)
			cudaCalloc1((void**)&fit_store[i], sizeof(float), frmsz);
	}

	/* Loop over all views for this (smeared) frame, going in an order that
	 * ends with the view corresponding to the epoch listed for this frame
	 * in the obs file; this way we can use the calculated information for
	 * that view in the "write" action screen and disk output that follows*/

	for (v2=v0_index+1; v2<=v0_index+nviews; v2++) {
		v = v2 % nviews;

		/* Launch 9*nframes-threaded kernel to set pos->ae,pos->oe,pos->bistatic.*/
		THD.x = 9;
		BLK.x = nframes;
		cf_set_pos_ae_doppler_af_krnl<<<BLK,THD>>>(pos,frame,pos_n,nframes,v);
		checkErrorAfterKernelLaunch("cf_set_pos_ae_doppler_af_krnl");
		deviceSyncAfterKernelLaunch("cf_set_pos_ae_doppler_af_krnl");

		/* Configure & launch posclr_krnl to initialize POS view */
		nx = 2*pos_n[0]+1;
		nThreads = nframes * nx * nx;
		BLK.x = floor((maxThreadsPerBlock-1 + nThreads)/maxThreadsPerBlock);
		THD.x = maxThreadsPerBlock;

		cf_posclr_af_krnl<<<BLK,THD>>>(pos, pos_n[0], nx, (nx*nx), nframes);
		checkErrorAfterKernelLaunch("cf_posclr_af_krnl");

		/* Call posvis_cuda_2 to get facet number, scattering angle,
		 * distance toward Earth at center of each POS pixel; set flag
		 * posbnd if any model portion extends beyond POS frame limits.*/
		/* NOTE: Limited to single component for now */

		if (posvis_af(dpar,dmod,ddat,orbit_offset,s,nframes,0,0,0) &&
				v == v0_index) {
			/* Call single-threaded kernel to set dpar->posbnd and
			 * dpar->posbnd_logfactor */
			THD.x = nframes;
			cf_set_posbnd_doppler_af_krnl<<<1,THD>>>(dpar,frame,pos,nframes);
			checkErrorAfterKernelLaunch("cf_set_posbnd_doppler_af_krnl");
		}

		/* Launch nframes-threaded kernel to get dpar->exclude_seen */
		THD.x = nframes;
		cf_get_exclude_seen_af_krnl<<<1,THD>>>(dpar,pos,xylim,nframes);
		checkErrorAfterKernelLaunch("cf_get_exclude_seen_af_krnl");
		gpuErrchk(cudaMemcpyFromSymbol(&exclude_seen, cfaf_exclude_seen, sizeof(int),
				0, cudaMemcpyDeviceToHost));

		/* Get the largest pos->xlim and ylim values for all frames */
		cf_get_global_frmsz_krnl<<<1,THD>>>(global_lim, xylim, nframes);
		checkErrorAfterKernelLaunch("cf_get_global_frmsz_krnl");
		deviceSyncAfterKernelLaunch("cf_get_global_frmsz_krnl");

		/* Go through all POS pixels visible with low enough scattering
		 * angle and mark the facets which project onto their centers as
		 * having been "seen" at least once                        */
		/* I'll launch a multi-threaded kernel here:
		 * (xlim1 - xlim0 + 1)^2 threads			 */
		if (s != exclude_seen && v == v0_index) {

			xspan = global_lim[1] - global_lim[0] + 1; // xlim1 - xlim0 + 1;
			yspan = global_lim[3] - global_lim[2] + 1; // ylim1 - ylim0 + 1;
			nThreads = nframes * xspan * yspan;

			/* Configure & launch posclr_af_krnl to initialize POS view */
			BLK.x = floor((maxThreadsPerBlock-1+nThreads)/maxThreadsPerBlock);
			THD.x = maxThreadsPerBlock;

			cf_mark_pixels_seen_af_krnl<<<BLK,THD>>>(dpar, dmod, pos, global_lim,
					(xspan*yspan), xspan, nframes, c);
			checkErrorAfterKernelLaunch("cf_mark_pixels_seen_af_krnl");
		}
		/* Zero out fit Doppler spectrum, then call pos2doppler to create
		 * the fit image by mapping power from the plane of the sky to
		 * Doppler space.                             */
		deviceSyncAfterKernelLaunch("pre-clrvect_krnl sync in calc_fits_cuda_af.cu");
		nThreads = frmsz * nframes;
		BLK.x = floor((maxThreadsPerBlock-1+nThreads)/maxThreadsPerBlock);
		THD.x = maxThreadsPerBlock;

		clrvect_af_krnl<<<BLK,THD>>>(ddat, s, nframes, nThreads, frmsz);
		checkErrorAfterKernelLaunch("clrvect_af_krnl");
		deviceSyncAfterKernelLaunch("clrvect_af_krnl");

		if (pos2doppler_cuda_af(dpar,dmod,ddat,0.0,0.0,0.0,0, s,nframes,v)) {
			/* nframes-threaded kernel to set badradar flag and calc. logfactor*/
			THD.x = nframes;
			cf_set_badradar_doppler_af_krnl<<<1,THD>>>(dpar,ddat,frame,s,nframes);
			checkErrorAfterKernelLaunch("cf_set_badradar_doppler_af_krnl");
		}

		/* If smearing is being modeled, include the Doppler calculations from
		 * this view in the summed results for this frame  */
		if (nviews > 1) {
			/* Launch ndop-threaded kernel to add fit[i][j] to fit_store[i][j]*/
			BLK.x = floor((maxThreadsPerBlock-1 + nThreads)/maxThreadsPerBlock);
			THD.x = maxThreadsPerBlock;
			cf_add_fit_store_af_krnl1<<<BLK,THD>>>(ddat,fit_store,frmsz,s,nframes);
			checkErrorAfterKernelLaunch("cf_add_fit_store_af_krnl1");

			THD.x = nframes;
			cf_add_fit_store_doppler_af_krnl2<<<1,THD>>>(frame,overflow,nframes);
			checkErrorAfterKernelLaunch("cf_add_fit_store_doppler_af_krnl2");
		}
	}

	/* If smearing is being modeled, compute mean values over all views for
	 * this frame and store them in the standard frame structure     */
	/* This kernel also carries out the gamma transformation on the fit
	 * image if the par->dd_gamma flag is not set  */
	if (nviews > 1) {
		/* Launch (nframes*ndop)-threaded kernel */
		nThreads = frmsz*nframes;
		BLK.x = floor((maxThreadsPerBlock-1 + nThreads)/maxThreadsPerBlock);
		THD.x = maxThreadsPerBlock;

		cf_finish_fit_store_af_krnl<<<BLK,THD>>>(ddat,fit_store,s,nThreads,frmsz);
		checkErrorAfterKernelLaunch("cf_finish_fit_af_store");

		THD.x = nframes;
		cf_finish_fit_doppler_af_krnl2<<<1,THD>>>(frame,overflow,nframes);
		checkErrorAfterKernelLaunch("cf_finish_fit_deldop_af_krnl2");
		cudaFree(fit_store);
	}
	/* De-allocate memory */
	cudaFree(frame);
	cudaFree(view0);
	cudaFree(pos);
	cudaFree(overflow);
	cudaFree(ndop);
	cudaFree(pos_n);
	cudaFree(global_lim);
	cudaFree(xylim);
	//	}  /* end loop over frames */
}


//void calc_poset( struct par_t *par, struct mod_t *mod, struct poset_t *poset,
//		int s)
//{
//	const char *monthName[12] = {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
//			"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
//	double orbit_offset[3] = {0.0, 0.0, 0.0};
//
//	FILE *fpopt;
//	char tempstring[MAXLEN], name[MAXLEN];
//	int year, mon, day, hour, min, sec, f, c, i, j, k, l, nrow_fit, ncol_fit, n_pos,
//	facetnum, x, y, v, v2;
//	double w[3], spin_colat, spin_azim, xoff, yoff, resamp_fact, resamp_x0, resamp_y0,
//	xcom_fit, ycom_fit, resamp_xwidth, resamp_ywidth, resamp_angle, oa[3][3],
//	to_earth[3], to_earth_lat, to_earth_long, rotphase, sa[3][3], to_sun[3],
//	to_sun_lat, to_sun_long, pab[3], pab_lat, pab_long, intensityfactor,
//	phi, theta, psi, intspin_body[3], badposet_logfactor_view;
//	double **fit_store;
//	struct posetfrm_t *frame;
//	struct posetview_t *view0;
//	struct pos_t *pos;
//
//	for (f=0; f<poset->nframes; f++) {
//
//		frame = &poset->frame[f];
//		view0 = &frame->view[poset->v0];
//		pos = &frame->pos;
//
//		ncol_fit = frame->ncol;
//		nrow_fit = frame->nrow;
//
//		/*  If smearing is being modeled, initialize variables that
//        will be used to sum results calculated for individual views  */
//
//		if (poset->nviews > 1) {
//			fit_store = matrix( 1, ncol_fit, 1, nrow_fit);
//			for (i=1; i<=ncol_fit; i++)
//				for (j=1; j<=nrow_fit; j++)
//					fit_store[i][j] = 0.0;
//		}
//
//		/*  Loop over all views for this (smeared) frame, going in an order that
//        ends with the view corresponding to the epoch listed for this frame
//        in the obs file; this way we can use the calculated information for
//        that view in the "write" action screen and disk output that follows   */
//
//		for (v2=poset->v0+1; v2<=poset->v0+poset->nviews; v2++) {
//			v = v2 % poset->nviews;
//
//			for (i=0; i<=2; i++)
//				for (j=0; j<=2; j++) {
//					pos->ae[i][j] = frame->view[v].ae[i][j];
//					pos->oe[i][j] = frame->view[v].oe[i][j];
//					pos->se[i][j] = frame->view[v].se[i][j];
//				}
//			pos->bistatic = 1;
//
//			/*  Initialize the plane-of-sky view  */
//
//			posclr( pos);
//
//			/*  Call routine posvis to get the facet number, scattering angle,
//          incidence angle, and distance toward Earth at the center of
//          each POS pixel; set the posbnd parameter to 1 if any portion
//          of the model extends beyond the POS frame limits.              */
//
//			for (c=0; c<mod->shape.ncomp; c++)
//				if (posvis( &mod->shape.comp[c].real, orbit_offset, pos,
//						(int) par->pos_smooth, 0, 0, c) && v == poset->v0) {
//					par->posbnd = 1;
//					if (pos->bistatic)
//						par->posbnd_logfactor += 0.5 * frame->dof * pos->posbnd_logfactor;
//					else
//						par->posbnd_logfactor += frame->dof * pos->posbnd_logfactor;
//				}
//
//			/*  Now view the model from the source (sun) and get the facet number
//          and distance toward the source of each pixel in this projected view;
//          use this information to determine which POS pixels are shadowed       */
//
//			if (pos->bistatic) {
//				for (c=0; c<mod->shape.ncomp; c++)
//					if (posvis( &mod->shape.comp[c].real, orbit_offset, pos,
//							0, 1, 0, c)) {
//						par->posbnd = 1;
//						par->posbnd_logfactor += 0.5 * frame->dof * pos->posbnd_logfactor;
//					}
//
//				/*  Identify and mask out shadowed POS pixels  */
//
//				posmask( pos, par->mask_tol);
//			}
//
//			/*  Go through all POS pixels which are visible and unshadowed with
//          sufficiently low scattering and incidence angles, and mark the facets
//          which project onto their centers as having been "seen" at least once   */
//
//			if (s != par->exclude_seen && v == poset->v0) {
//				for (k=pos->xlim[0]; k<=pos->xlim[1]; k++)
//					for (l=pos->ylim[0]; l<=pos->ylim[1]; l++) {
//						if ((pos->cose[k][l] > par->mincosine_seen)
//								&& (pos->cosi[k][l] > par->mincosine_seen)
//								&& (pos->f[k][l] >= 0)) {
//							facetnum = pos->f[k][l];
//							c = pos->comp[k][l];
//							mod->shape.comp[c].real.f[facetnum].seen = 1;
//						}
//					}
//			}
//
//			/*  Compute the sky rendering  */
//
//			intensityfactor = pow( pos->km_per_pixel/AU, 2.0);
//			apply_photo( mod, poset->ioptlaw, frame->view[v].solar_phase,
//					intensityfactor, pos, 0);
//
//			/*  Resample the sky rendering to get the model plane-of-sky image    */
//			/*  (if using bicubic interpolation or cubic convolution, force       */
//			/*  all model pixel values to be nonnegative)                         */
//			/*                                                                    */
//			/*  Implement the x and y COM offsets, xoff and yoff, by first        */
//			/*  using them to compute xcom_fit and ycom_fit -- the COM position   */
//			/*  in the fit image, relative to the center of the fit image -- and  */
//			/*  then shifting the resampled region in the *opposite* direction    */
//			/*  by the appropriate proportional amount.  Then implement the       */
//			/*  "northangle" setting (clockwise heading of north) by rotating     */
//			/*  the resampling grid *counterclockwise* by northangle.             */
//
//			n_pos = pos->n;
//			xoff = frame->off[0].val;
//			yoff = frame->off[1].val;
//			xcom_fit = (frame->colcom_vig - (ncol_fit + 1)/2.0) + xoff;
//			ycom_fit = (frame->rowcom_vig - (nrow_fit + 1)/2.0) + yoff;
//			resamp_fact = frame->fit.km_per_pixel / pos->km_per_pixel;
//			resamp_x0 = -xcom_fit*resamp_fact;
//			resamp_y0 = -ycom_fit*resamp_fact;
//			resamp_xwidth = resamp_fact*(ncol_fit - 1);
//			resamp_ywidth = resamp_fact*(nrow_fit - 1);
//			resamp_angle = -frame->northangle;
//			resampim( frame->pos.b, -n_pos, n_pos, -n_pos, n_pos,
//					frame->fit.b, 1, ncol_fit, 1, nrow_fit,
//					resamp_x0, resamp_xwidth, resamp_y0, resamp_ywidth, resamp_angle,
//					(int) par->poset_resample, (int) par->image_rebin);
//			if (par->poset_resample == BICUBIC || par->poset_resample == CUBICCONV) {
//				for (k=1; k<=ncol_fit; k++)
//					for (l=1; l<=nrow_fit; l++)
//						frame->fit.b[k][l] = MAX( 0.0, frame->fit.b[k][l]);
//			}
//
//			/*  Set the badposet flag and increase badposet_logfactor if the model   */
//			/*  plane-of-sky image is too small to "contain" all of the sky          */
//			/*  rendering's nonzero pixels.                                          */
//
//			if (checkposet( pos->b, -n_pos, n_pos, -n_pos, n_pos,
//					resamp_x0, resamp_xwidth, resamp_y0, resamp_ywidth, resamp_angle,
//					&badposet_logfactor_view)) {
//				par->badposet = 1;
//				par->badposet_logfactor += frame->dof * badposet_logfactor_view
//						/ poset->nviews;
//			}
//
//			/*  If smearing is being modeled, include the plane-of-sky
//          calculations from this view in the summed results for this frame  */
//
//			if (poset->nviews > 1)
//				for (i=1; i<=ncol_fit; i++)
//					for (j=1; j<=nrow_fit; j++)
//						fit_store[i][j] += frame->fit.b[i][j];
//
//		}
//
//		/*  If smearing is being modeled, compute mean values over all views
//        for this frame and store them in the standard frame structure     */
//
//		if (poset->nviews > 1) {
//			for (i=1; i<=ncol_fit; i++)
//				for (j=1; j<=nrow_fit; j++)
//					frame->fit.b[i][j] = fit_store[i][j] / poset->nviews;
//			free_matrix( fit_store, 1, ncol_fit, 1, nrow_fit);
//		}
//
//
//	}  /* end loop over frames */
//}
//
//
//void calc_lghtcrv( struct par_t *par, struct mod_t *mod, struct lghtcrv_t *lghtcrv,
//		int s)
//{
//	const char *monthName[12] = {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
//			"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
//	double orbit_offset[3] = {0.0, 0.0, 0.0};
//
//	FILE *fpopt;
//	char tempstring[MAXLEN], name[MAXLEN];
//	int year, mon, day, hour, min, sec, n, ncalc, c, i, i_mid, j, k, l, facetnum,
//	n_cross360, n_projectedpixels, n_shadowedpixels, x, y, v;
//	double epoch_mid, epoch_diff_min, epoch_diff, w[3], spin_colat, spin_azim, oa[3][3],
//	rotphase, sa[3][3], to_sun[3], to_sun_lat, to_sun_long, pab[3], pab_lat,
//	pab_long, intensityfactor, phi, theta, psi, intspin_body[3], posbnd_logfactor,
//	projected_area, lambertdisk_intensity, interp;
//	double **to_earth, *to_earth_lat, *to_earth_long, *rotphase_unwrapped;
//	struct crvrend_t *rend;
//	struct pos_t *pos;
//
//	/*  Initialize variables to avoid compilation warning  */
//
//	i_mid = 0;
//	epoch_mid = epoch_diff = epoch_diff_min = 0.0;
//	n_cross360 = 0;
//	to_earth = NULL;
//	to_earth_lat = to_earth_long = rotphase_unwrapped = NULL;
//
//	/*  Initialize variables dealing with bad models  */
//
//	posbnd_logfactor = 0.0;
//
//	/*  Get n, the number of observed points for this lightcurve,
//      and ncalc, the number of epochs at which model lightcurve
//      brightnesses are to be computed                            */
//
//	n = lghtcrv->n;
//	ncalc = lghtcrv->ncalc;
//
//	/*  Calculate the model lightcurve values at each of the user-specified
//      epochs x[i], with i=1,2,...,ncalc; these may or may not be the same as the
//      epochs t[i] (i=1,2,...,n) at which actual lightcurve observations were made.  */
//
//	for (i=1; i<=ncalc; i++) {
//
//		rend = &lghtcrv->rend[i];
//		pos = &rend->pos;
//
//		for (j=0; j<=2; j++)
//			for (k=0; k<=2; k++) {
//				pos->ae[j][k] = rend->ae[j][k];
//				pos->oe[j][k] = rend->oe[j][k];
//				pos->se[j][k] = rend->se[j][k];
//			}
//		pos->bistatic = 1;
//
//		/*  Initialize the plane-of-sky view  */
//
//		posclr( pos);
//
//		/*  Call routine posvis to get the facet number, scattering angle,
//        incidence angle, and distance toward Earth at the center of
//        each POS pixel; set the posbnd parameter to 1 if any portion
//        of the model extends beyond the POS frame limits.              */
//
//		for (c=0; c<mod->shape.ncomp; c++)
//			if (posvis( &mod->shape.comp[c].real, orbit_offset, pos,
//					(int) par->pos_smooth, 0, 0, c)) {
//				par->posbnd = 1;
//				if (pos->bistatic)
//					posbnd_logfactor += 0.5 * pos->posbnd_logfactor;
//				else
//					posbnd_logfactor += pos->posbnd_logfactor;
//			}
//
//		/*  Now view the model from the source (sun) and get the facet number
//        and distance toward the source of each pixel in this projected view;
//        use this information to determine which POS pixels are shadowed       */
//
//		if (pos->bistatic) {
//			for (c=0; c<mod->shape.ncomp; c++)
//				if (posvis( &mod->shape.comp[c].real, orbit_offset, pos,
//						0, 1, 0, c)) {
//					par->posbnd = 1;
//					posbnd_logfactor += 0.5 * pos->posbnd_logfactor;
//				}
//
//			/*  Identify and mask out shadowed POS pixels  */
//
//			posmask( pos, par->mask_tol);
//		}
//
//		/*  Go through all POS pixels which are visible and unshadowed with
//        sufficiently low scattering and incidence angles, and mark the facets
//        which project onto their centers as having been "seen" at least once   */
//
//		if (s != par->exclude_seen) {
//			for (k=pos->xlim[0]; k<=pos->xlim[1]; k++)
//				for (l=pos->ylim[0]; l<=pos->ylim[1]; l++) {
//					if ((pos->cose[k][l] > par->mincosine_seen)
//							&& (pos->cosi[k][l] > par->mincosine_seen)
//							&& (pos->f[k][l] >= 0)) {
//						facetnum = pos->f[k][l];
//						c = pos->comp[k][l];
//						mod->shape.comp[c].real.f[facetnum].seen = 1;
//					}
//				}
//		}
//
//		/*  Compute the model brightness for this model lightcurve point  */
//
//		intensityfactor = pow( pos->km_per_pixel/AU, 2.0);
//		lghtcrv->y[i] = apply_photo( mod, lghtcrv->ioptlaw, lghtcrv->solar_phase[i],
//				intensityfactor, pos, 0);
//
//		/*  Finished with this calculated lightcurve point  */
//
//	}
//
//	/*  Now that we have calculated the model lightcurve brightnesses y at each
//      of the epochs x, we use cubic spline interpolation (Numerical Recipes
//      routines spline and splint) to get model lightcurve brightness fit[i]
//      at each OBSERVATION epoch t[i], with i=1,2,...,n.  This will allow us
//      (in routine chi2) to compare model to data (fit[i] to obs[i]) to get
//      chi-square.  Note that vector y2 contains the second derivatives of
//      the interpolating function at the calculation epochs x.
//
//      Smearing is handled by interpolating the brightness at the time t of
//      each individual view and then taking the mean of all views that
//      correspond to a given observed lightcurve point.                         */
//
//	spline( lghtcrv->x, lghtcrv->y, ncalc, 2.0e30, 2.0e30, lghtcrv->y2);
//	for (i=1; i<=n; i++) {
//		lghtcrv->fit[i] = 0.0;
//		for (v=0; v<lghtcrv->nviews; v++) {
//			splint( lghtcrv->x, lghtcrv->y, lghtcrv->y2, ncalc,
//					lghtcrv->t[i][v], &interp);
//			lghtcrv->fit[i] += interp;
//		}
//		lghtcrv->fit[i] /= lghtcrv->nviews;
//	}
//
//	/*  Deal with flags for model that extends beyond the POS frame  */
//
//	par->posbnd_logfactor += lghtcrv->dof * (posbnd_logfactor/ncalc);
//
//}
