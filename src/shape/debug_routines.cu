
extern "C" {
#include "../shape/head.h"
#include "../shape/shape-cuda.h"
}
__device__ float bf_sum_oovs=0.0;
__device__ int dbg_ndop1, dbg_ndel1, dbg_xlim0, dbg_xlim1, dbg_ylim0, dbg_ylim1;
__device__ float zsum=0.0, cosa_sum=0.0;

__global__ void bf_deldop_dbg2_krnl(struct par_t *dpar, struct dat_t *ddat,
		int s, int f) {
	/* Single-threaded kernel */
	int idel, idop, i;

	if (threadIdx.x == 0) {
		int ndel = ddat->set[s].desc.deldop.frame[f].ndel;
		int ndop = ddat->set[s].desc.deldop.frame[f].ndop;
		int initial = ndel*ndop - 11;
		for (idel=1; idel<=ndel; idel++)
			for (idop=1; idop<=ndop; idop++)
				bf_sum_oovs += ddat->set[s].desc.deldop.frame[f].oneovervar[idel][idop];
	}
}
__global__ void dbg_print_fit_krnl1(struct dat_t *ddat, int s, int f){
	/* Single-threaded debug kernel */
	if (threadIdx.x == 0) {
		switch (ddat->set[s].type) {
		case DELAY:
			dbg_ndel1 = ddat->set[s].desc.deldop.frame[f].ndel;
			dbg_ndop1 = ddat->set[s].desc.deldop.frame[f].ndop;
			dbg_xlim0 = ddat->set[s].desc.deldop.frame[f].pos.xlim[0];
			dbg_xlim1 = ddat->set[s].desc.deldop.frame[f].pos.xlim[1];
			dbg_ylim0 = ddat->set[s].desc.deldop.frame[f].pos.ylim[0];
			dbg_ylim1 = ddat->set[s].desc.deldop.frame[f].pos.ylim[1];
			break;
		case DOPPLER:
			dbg_ndop1 = ddat->set[s].desc.doppler.frame[f].ndop;
			dbg_xlim0 = ddat->set[s].desc.doppler.frame[f].pos.xlim[0];
			dbg_xlim1 = ddat->set[s].desc.doppler.frame[f].pos.xlim[1];
			dbg_ylim0 = ddat->set[s].desc.doppler.frame[f].pos.ylim[0];
			dbg_ylim1 = ddat->set[s].desc.doppler.frame[f].pos.ylim[1];
			break;
		}
	}
}
__global__ void dbg_print_fit_krnl2(struct dat_t *ddat, double *fit, int s, int f) {
	/* ndop-threaded kernel */
	int idop = blockIdx.x * blockDim.x + threadIdx.x + 1;

	if (idop <= dbg_ndop1) {
		fit[idop] = ddat->set[s].desc.doppler.frame[f].fit_s[idop];
	}
}
__global__ void dbg_print_lc_fit_krnl(struct dat_t *ddat, double *fit, int s, int n) {
	/* ndop-threaded kernel */
	int i = blockIdx.x * blockDim.x + threadIdx.x + 1;

	if (i <= n) {
		fit[i] = ddat->set[s].desc.lghtcrv.fit[i];
	}
}
__global__ void dbg_print_fac_krnl(struct pos_t **pos, int **ff, int f, int size, int xspan) {
	/* ndop-threaded kernel */
	int offset = blockIdx.x * blockDim.x + threadIdx.x;
	int n = pos[f]->n;
	int i = offset % xspan - n;
	int j = offset / xspan - n;

	if ((i>=-n) && (i<=n) && (j>=-n) && (j<=n)) {
		ff[i][j] = pos[f]->f[i][j];
	}
}
__global__ void dbg_print_fac2_krnl(struct pos_t **pos, int *fac, int f, int size, int xspan) {
	/* ndop-threaded kernel */
	int offset = blockIdx.x * blockDim.x + threadIdx.x;
	int n = pos[f]->n;
	int i = offset % xspan - n;
	int j = offset / xspan - n;

	if ((i>=-n) && (i<=n) && (j>=-n) && (j<=n)) {
		fac[offset] = pos[f]->f[i][j];
	}
}
__global__ void dbg_print_poz_krnl(struct dat_t *ddat, float *zz, int s, int f, int size) {
	/* ndop-threaded kernel */
	int offset = blockIdx.x * blockDim.x + threadIdx.x;

	if (offset < size) {
		if (ddat->set[s].type == DELAY)
			zz[offset] = ddat->set[s].desc.deldop.frame[f].pos.z_s[offset];
		if (ddat->set[s].type == DOPPLER)
			zz[offset] = ddat->set[s].desc.doppler.frame[f].pos.z_s[offset];
		if (ddat->set[s].type == LGHTCRV)
			zz[offset] = ddat->set[s].desc.lghtcrv.rend[f].pos.z_s[offset];
	}
}
__global__ void dbg_print_poz_af_krnl(struct dat_t *ddat, float *zz0, float *zz1,
		float *zz2, float *zz3, int s, int size) {
	/* ndop-threaded kernel */
	int offset = blockIdx.x * blockDim.x + threadIdx.x;

	if (offset < size) {
		if (ddat->set[s].type == DELAY) {
			zz0[offset] = ddat->set[s].desc.deldop.frame[0].pos.z_s[offset];
			zz1[offset] = ddat->set[s].desc.deldop.frame[1].pos.z_s[offset];
			zz2[offset] = ddat->set[s].desc.deldop.frame[2].pos.z_s[offset];
			zz3[offset] = ddat->set[s].desc.deldop.frame[3].pos.z_s[offset];
		}
		if (ddat->set[s].type == DOPPLER) {
			zz0[offset] = ddat->set[s].desc.doppler.frame[0].pos.z_s[offset];
			zz1[offset] = ddat->set[s].desc.doppler.frame[1].pos.z_s[offset];
			zz2[offset] = ddat->set[s].desc.doppler.frame[2].pos.z_s[offset];
			zz3[offset] = ddat->set[s].desc.doppler.frame[3].pos.z_s[offset];
		}
	}
}
__global__ void dbg_print_cose_krnl(struct dat_t *ddat, float *cose, int s, int f, int size) {
	/* ndop-threaded kernel */
	int offset = blockIdx.x * blockDim.x + threadIdx.x;

	if (offset < size) {
		if (ddat->set[s].type == DELAY)
			cose[offset] = ddat->set[s].desc.deldop.frame[f].pos.cose_s[offset];
		if (ddat->set[s].type == DOPPLER)
			cose[offset] = ddat->set[s].desc.doppler.frame[f].pos.cose_s[offset];
	}
}
__global__ void dbg_print_cos_af_krnl(struct dat_t *ddat, float *cos0, float *cos1,
		float *cos2, float *cos3, int s, int size) {
	/* ndop-threaded kernel */
	int offset = blockIdx.x * blockDim.x + threadIdx.x;

	if (offset < size) {
		if (ddat->set[s].type == DELAY) {
			cos0[offset] = ddat->set[s].desc.deldop.frame[0].pos.cose_s[offset];
			cos1[offset] = ddat->set[s].desc.deldop.frame[1].pos.cose_s[offset];
			cos2[offset] = ddat->set[s].desc.deldop.frame[2].pos.cose_s[offset];
			cos3[offset] = ddat->set[s].desc.deldop.frame[3].pos.cose_s[offset];
		}
		if (ddat->set[s].type == DOPPLER) {
			cos0[offset] = ddat->set[s].desc.doppler.frame[0].pos.cose_s[offset];
			cos1[offset] = ddat->set[s].desc.doppler.frame[1].pos.cose_s[offset];
			cos2[offset] = ddat->set[s].desc.doppler.frame[2].pos.cose_s[offset];
			cos3[offset] = ddat->set[s].desc.doppler.frame[3].pos.cose_s[offset];
		}
	}
}
__global__ void dbg_print_fit_deldop_krnl2(struct dat_t *ddat, double *fit, int s, int f){
	/* ndel*ndop-threaded kernel */
	int offset = blockIdx.x * blockDim.x + threadIdx.x;

	if (offset < (dbg_ndop1*dbg_ndel1))
		fit[offset] = ddat->set[s].desc.deldop.frame[f].fit_s[offset];
}
__global__ void dbg_print_RandC_krnl(struct mod_t *dmod) {
	/* Single-threaded kernel */
	if (threadIdx.x == 0) {
		printf("C = %f\n", dmod->photo.radar[0].RC.C.val);
		printf("R = %f\n", dmod->photo.radar[0].RC.R.val);
	}
}
__global__ void dbg_copy_lghtcrv_arrays_krnl(struct dat_t *ddat, int set, int n,
		double *fit, double *obs, double *oneovervar) {
	/* n-threaded kernel */
	int i = blockIdx.x * blockDim.x + threadIdx.x + 1;

	if ((i>0) && (i<=n)) {
		fit[i] = ddat->set[set].desc.lghtcrv.fit[i];
		obs[i] = ddat->set[set].desc.lghtcrv.obs[i];
		oneovervar[i] = ddat->set[set].desc.lghtcrv.oneovervar[i];
	}
}
__global__ void dbg_copy_lghtcrv_xyy2_krnl(struct dat_t *ddat, int set, int ncalc,
		double *x, double *y, double *y2) {
	/* n-threaded kernel */
	int i = blockIdx.x * blockDim.x + threadIdx.x + 1;

	if ((i>0) && (i<=ncalc)) {
		x[i] = ddat->set[set].desc.lghtcrv.x[i];
		y[i] = ddat->set[set].desc.lghtcrv.y[i];
		y2[i] = ddat->set[set].desc.lghtcrv.y2[i];
	}
}
__global__ void dbg_copy_lghtcrv_pos_arrays_krnl(struct dat_t *ddat, int set,
		int npixels, float *b, float *cosi, float *cose, int i) {
	/* npixels-threaded debug kernel */
	int offset = blockIdx.x * blockDim.x + threadIdx.x;

	if (offset < npixels) {
		b[offset] = ddat->set[set].desc.lghtcrv.rend[i].pos.b_s[offset];
		cosi[offset] = ddat->set[set].desc.lghtcrv.rend[i].pos.cosi_s[offset];
		cose[offset] = ddat->set[set].desc.lghtcrv.rend[i].pos.cose_s[offset];
	}
}
__global__ void dbg_copy_lghtcrv_pos_arrays2_krnl(struct pos_t **pos, int f,
		int npixels, float *b, float *cosi, float *cose) {
	/* npixels-threaded debug kernel */
	int offset = blockIdx.x * blockDim.x + threadIdx.x;

	if (offset < npixels) {
		b[offset] = pos[f]->b_s[offset];
		cosi[offset] = pos[f]->cosi_s[offset];
		cose[offset] = pos[f]->cose_s[offset];
	}
}
__global__ void dbg_copy_lghtcrv_pos_bd_krnl(struct pos_t **pos, int f,
		int npixels, double *bd) {
	/* npixels-threaded debug kernel */
	int offset = blockIdx.x * blockDim.x + threadIdx.x;

	if (offset < npixels) {
		bd[offset] = pos[f]->b_d[offset];
	}
}
__global__ void dbg_copy_lghtcrv_pos_arrays_full_krnl(struct pos_t **pos, int f,
		int npixels, float *b, float *cosi, float *cose, float *zz) {
	/* npixels-threaded debug kernel */
	int offset = blockIdx.x * blockDim.x + threadIdx.x;

	if (offset < npixels) {
		b[offset] = pos[f]->b_s[offset];
		cosi[offset] = pos[f]->cosi_s[offset];
		cose[offset] = pos[f]->cose_s[offset];
		zz[offset] = pos[f]->z_s[offset];
	}
}
__global__ void dbg_sum_up_pos_krnl(struct dat_t *ddat, int s, int f) {
	/* Single-threaded kernel */
	int n, size, i = 0;
	if (threadIdx.x == 0) {
		cosa_sum = zsum = 0.0;
		switch (ddat->set[s].type) {
		case DELAY:
			n = ddat->set[s].desc.deldop.frame[f].pos.n;
			size = (2*n + 1) * (2*n + 1);
			for (i=0; i<size; i++) {
				if (ddat->set[s].desc.deldop.frame[f].pos.z_s[i] > 0.0)
					zsum += ddat->set[s].desc.deldop.frame[f].pos.z_s[i];
				cosa_sum += ddat->set[s].desc.deldop.frame[f].pos.cose_s[i];
			}
			printf("sum of z_s for Deldop frame #%i is %3.3f\n", f, zsum);
			printf("sum of cosa_s for Deldop frame #%i is %g\n", f, cosa_sum);
			break;
		case DOPPLER:
			n = ddat->set[s].desc.doppler.frame[f].pos.n;
			size = (2*n + 1) * (2*n + 1);
			for (i=0; i<size; i++) {
				if (ddat->set[s].desc.doppler.frame[f].pos.z_s[i] > 0.0)
					zsum += ddat->set[s].desc.doppler.frame[f].pos.z_s[i];
				cosa_sum += ddat->set[s].desc.doppler.frame[f].pos.cose_s[i];
			}
			printf("sum of z_s for Doppler frame #%i is %3.3f\n", f, zsum);
			printf("sum of cosa_s for Doppler frame #%i is %g\n", f, cosa_sum);
			break;
		}
	}
}
__global__ void dbg_copy_facet_normals_krnl(struct mod_t *dmod, int nf, float3 *dnormals)
{
	/* nf-threaded kernel */
	int f = blockIdx.x * blockDim.x + threadIdx.x;

	if (f<nf) {
		dnormals[f].x = __double2float_rn(dmod->shape.comp[0].real.f[f].n[0]);
		dnormals[f].y = __double2float_rn(dmod->shape.comp[0].real.f[f].n[1]);
		dnormals[f].z = __double2float_rn(dmod->shape.comp[0].real.f[f].n[2]);
	}
}

__host__ void dbg_print_fit(struct dat_t *ddat, int s, int f, char *filename_fit) {
	/* Debug function that prints all Doppler frame fit values to csv */

	int idop, nThreads, ndop, xlim[2], ylim[2];
	FILE *fp_fit;
	double *fit;
	dim3 BLK,THD;

	printf("\n %sfile created",filename_fit);

	/* Launch 1st debug kernel to get ndop and xlim/ylim	 */
	dbg_print_fit_krnl1<<<1,1>>>(ddat, s, f);
	checkErrorAfterKernelLaunch("dbg_print_fit_krnl1");
	deviceSyncAfterKernelLaunch("dbg_print_fit_krnl2");
	gpuErrchk(cudaMemcpyFromSymbol(&xlim[0], dbg_xlim0, sizeof(int),
			0, cudaMemcpyDeviceToHost));
	gpuErrchk(cudaMemcpyFromSymbol(&xlim[1], dbg_xlim1, sizeof(int),
			0, cudaMemcpyDeviceToHost));
	gpuErrchk(cudaMemcpyFromSymbol(&ylim[0], dbg_ylim0, sizeof(int),
			0, cudaMemcpyDeviceToHost));
	gpuErrchk(cudaMemcpyFromSymbol(&ylim[1], dbg_ylim1, sizeof(int),
			0, cudaMemcpyDeviceToHost));
	gpuErrchk(cudaMemcpyFromSymbol(&ndop, dbg_ndop1, sizeof(int),
			0, cudaMemcpyDeviceToHost));

	nThreads = (xlim[1] - xlim[0] + 1) * (ylim[1] - ylim[0] + 1);
	cudaCalloc((void**)&fit, sizeof(double), ndop);
	fit -= 1;
	int maxThreads = 128;
	BLK.x = floor((maxThreads - 1 + ndop)/maxThreads);
	THD.x = maxThreads; // Thread block dimensions

	dbg_print_fit_krnl2<<<BLK,THD>>>(ddat, fit, s, f);
	checkErrorAfterKernelLaunch("dbg_print_fit_krnl_2");
	deviceSyncAfterKernelLaunch("dbg_print_fit_krnl_2");

	fp_fit = fopen(filename_fit, "w+");
	fprintf(fp_fit, "idop , ");
	for (idop=1; idop<=ndop; idop++)
		fprintf(fp_fit,	"\n%i , %g", idop, fit[idop]);
	fprintf(fp_fit, "\nxlim0 , %i", xlim[0]);
	fprintf(fp_fit, "\nxlim1 , %i", xlim[1]);
	fprintf(fp_fit, "\nylim0 , %i", ylim[0]);
	fprintf(fp_fit, "\nylim1 , %i", ylim[1]);
	fprintf(fp_fit, "\nthreads , %i", nThreads);
	fclose(fp_fit);
	//cudaFree(fit);
}
__host__ void dbg_print_fit_host(struct dat_t *ddat, int s, int f) {
	/* Debug function that prints all Doppler frame fit values to csv */

	int idop, nThreads;
	FILE *fp_fit;
	char *filename_fit;
	filename_fit = "CPU_doppler_fit.csv";
	nThreads = (ddat->set[s].desc.doppler.frame[f].pos.xlim[1]-
			ddat->set[s].desc.doppler.frame[f].pos.xlim[0]+1)*
					(ddat->set[s].desc.doppler.frame[f].pos.ylim[1]-
							ddat->set[s].desc.doppler.frame[f].pos.ylim[0]+1);

	printf("\n %sfile created",filename_fit);
	fp_fit = fopen(filename_fit, "w+");

	fprintf(fp_fit, "idel , ");

	for (idop=1; idop<=ddat->set[s].desc.doppler.frame[f].ndop; idop++)
		fprintf(fp_fit,	"\n%i , %g", idop, ddat->set[s].desc.doppler.frame[f].fit[idop]);

	fprintf(fp_fit, "\nxlim0 , %i", ddat->set[s].desc.doppler.frame[f].pos.xlim[0]);
	fprintf(fp_fit, "\nxlim1 , %i", ddat->set[s].desc.doppler.frame[f].pos.xlim[1]);
	fprintf(fp_fit, "\nylim0 , %i", ddat->set[s].desc.doppler.frame[f].pos.ylim[0]);
	fprintf(fp_fit, "\nylim1 , %i", ddat->set[s].desc.doppler.frame[f].pos.ylim[1]);
	fprintf(fp_fit, "\nthreads , %i", nThreads);
	fclose(fp_fit);
}
__host__ void dbg_print_deldop_fit(struct dat_t *ddat, int s, int f, char *filename_fit) {
	/* Debug function that prints all Doppler frame fit values to csv */

	int idop, ndop, idel, ndel, nbins, nThreads, offset, xlim[2], ylim[2];
	FILE *fp_fit;
//	char *filename_fit;
	double *fit_dd;
	dim3 BLK,THD;

//	filename_fit = "deldop_fit_cuda.csv";
	printf("\n %sfile created",filename_fit);

	/* Launch 1st debug kernel to get ndop and xlim/ylim	 */
	dbg_print_fit_krnl1<<<1,1>>>(ddat, s, f);
	checkErrorAfterKernelLaunch("dbg_print_fit_krnl1");
	deviceSyncAfterKernelLaunch("dbg_print_fit_krnl2");
	gpuErrchk(cudaMemcpyFromSymbol(&xlim[0], dbg_xlim0, sizeof(int),
			0, cudaMemcpyDeviceToHost));
	gpuErrchk(cudaMemcpyFromSymbol(&xlim[1], dbg_xlim1, sizeof(int),
			0, cudaMemcpyDeviceToHost));
	gpuErrchk(cudaMemcpyFromSymbol(&ylim[0], dbg_ylim0, sizeof(int),
			0, cudaMemcpyDeviceToHost));
	gpuErrchk(cudaMemcpyFromSymbol(&ylim[1], dbg_ylim1, sizeof(int),
			0, cudaMemcpyDeviceToHost));
	gpuErrchk(cudaMemcpyFromSymbol(&ndop, dbg_ndop1, sizeof(int),
			0, cudaMemcpyDeviceToHost));
	gpuErrchk(cudaMemcpyFromSymbol(&ndel, dbg_ndel1, sizeof(int),
				0, cudaMemcpyDeviceToHost));

	nThreads = (xlim[1] - xlim[0] + 1) * (ylim[1] - ylim[0] + 1);
	nbins = ndop * ndel;
	cudaCalloc((void**)&fit_dd, sizeof(double), nbins);

	BLK.x = floor((maxThreadsPerBlock - 1 + nbins)/maxThreadsPerBlock);
	THD.x = maxThreadsPerBlock; // Thread block dimensions

	dbg_print_fit_deldop_krnl2<<<BLK,THD>>>(ddat, fit_dd, s, f);
	checkErrorAfterKernelLaunch("dbg_print_fit_deldop_krnl_2");
	deviceSyncAfterKernelLaunch("dbg_print_fit_deldop_krnl_2");

	fp_fit = fopen(filename_fit, "w+");

	/* Print top corner idop/idel label */
	fprintf(fp_fit, "idop/idel , ");

	/* Print top row idel values */
	for (idel=1; idel<=ndel; idel++)
		fprintf(fp_fit, "%i , ", idel);

	/* Print first entry in every row (except 1st): idop */
	for (idop=1; idop<=ndop; idop++) {
		fprintf(fp_fit,	"\n%i , ", idop);

		/* Write the rest of the row values: fit[idel][idop] */
		for (idel=1; idel<=ndel; idel++) {
			offset = (idop-1)*ndel + (idel-1);
			fprintf(fp_fit, " %g , ", fit_dd[offset]);
		}

	}
	fprintf(fp_fit, "\nxlim0 , %i", xlim[0]);
	fprintf(fp_fit, "\nxlim1 , %i", xlim[1]);
	fprintf(fp_fit, "\nylim0 , %i", ylim[0]);
	fprintf(fp_fit, "\nylim1 , %i", ylim[1]);
	fprintf(fp_fit, "\nthreads , %i", nThreads);
	fclose(fp_fit);
	//cudaFree(fit_dd);
}
__host__ void dbg_print_deldop_fit_host(struct dat_t *ddat, int s, int f) {
	/* Debug function that prints all Delay-Doppler frame fit values to csv */

	int idop, ndop, idel, ndel, nThreads, xlim[2], ylim[2];
	FILE *fp_fit;
	char *filename_fit;

	filename_fit = "CPU_deldop_fit.csv";
	printf("\n %sfile created",filename_fit);

	for (idop=0;idop<2;idop++){
		xlim[idop] = ddat->set[s].desc.deldop.frame[f].pos.xlim[idop];
		ylim[idop] = ddat->set[s].desc.deldop.frame[f].pos.ylim[idop];}

	ndel = ddat->set[s].desc.deldop.frame[f].ndel;
	ndop = ddat->set[s].desc.deldop.frame[f].ndop;
	nThreads = (xlim[1] - xlim[0] + 1) * (ylim[1] - ylim[0] + 1);
	fp_fit = fopen(filename_fit, "w+");

	/* Print top corner idop/idel label */
	fprintf(fp_fit, "idop/idel , ");

	/* Print top row idel values */
	for (idel=1; idel<=ndel; idel++)
		fprintf(fp_fit, "%i , ", idel);

	/* Print first entry in every row (except 1st): idop */
	for (idop=1; idop<=ndop; idop++) {
		fprintf(fp_fit,	"\n%i , ", idop);

		/* Write the rest of the row values: fit[idel][idop] */
		for (idel=1; idel<=ndel; idel++)
			fprintf(fp_fit, " %g , ", ddat->set[s].desc.deldop.frame[f].fit[idel][idop]);
	}
	fprintf(fp_fit, "\nxlim0 , %i", xlim[0]);
	fprintf(fp_fit, "\nxlim1 , %i", xlim[1]);
	fprintf(fp_fit, "\nylim0 , %i", ylim[0]);
	fprintf(fp_fit, "\nylim1 , %i", ylim[1]);
	fprintf(fp_fit, "\nthreads , %i", nThreads);
	fclose(fp_fit);
}
__host__ void dbg_print_RandC(struct mod_t *dmod) {
	/* Debug function that retrieves and prints the following:
	 * 	dmod->photo.radar[0].RC.C.val
	 * 	dmod->photo.radar[0].RC.R.val	 */

	/* Just call kernel */
	dbg_print_RandC_krnl<<<1,1>>>(dmod);
	checkErrorAfterKernelLaunch("dbg_print_RandC_krnl");
	deviceSyncAfterKernelLaunch("dbg_print_RandC_krnl");
}
__host__ void dbg_print_RandC_host(struct mod_t *dmod) {
	/* Same as the __host__function, but intended for the CPU code version */
	printf("C = %f\n", dmod->photo.radar[0].RC.C.val);
	printf("R = %f\n", dmod->photo.radar[0].RC.R.val);
}
__host__ void dbg_print_array(float *data, int x, int y) {
	/* Debug function that prints all elements in data to a csv in x col * y rows */

	int n, i, j;
	float *host;
	FILE *fp_fit;
	char *filename_fit;
	double *fit;
	dim3 BLK,THD;

	filename_fit = "dbg_array_cuda.csv";
	printf("\n %sfile created",filename_fit);
	printf("\n\nFilename: %s",filename_fit);

	n = x*y;
	host = (float *) malloc(n*sizeof(float));
	gpuErrchk(cudaMemcpy(host, data, n*sizeof(float), cudaMemcpyDeviceToHost));

	fp_fit = fopen(filename_fit, "w+");
	/* Print top corner idop/idel label */
	fprintf(fp_fit, "i/j , ");

	/* Print top row idel values */
	for (i=0; i<x; i++)
		fprintf(fp_fit, "%i , ", i);

	/* Print first entry in every row (except 1st): idop */
	for (j=1; j<y; j++) {
		fprintf(fp_fit,	"\n%i , ", j);

		/* Write the rest of the row values: fit[idel][idop] */
		for (i=0; i<x; i++)
			fprintf(fp_fit, " %g , ", host[j*x + i]);
	}
	fclose(fp_fit);
	free(host);
}
__host__ void dbg_print_array1D(float *data, int size) {
	/* Debug function that prints all elements in data to a csv */

	int i;
	float *host;
	FILE *fp_fit;
	char *filename_fit;
	double *fit;
	dim3 BLK,THD;

	filename_fit = "dbg_array1D_cuda.csv";
	printf("\n %sfile created",filename_fit);
	printf("\n\nFilename: %s",filename_fit);

	host = (float *) malloc(size*sizeof(float));
	gpuErrchk(cudaMemcpy(host, data, size*sizeof(float), cudaMemcpyDeviceToHost));

	fp_fit = fopen(filename_fit, "w+");
	/* Print top corner idop/idel label */
	fprintf(fp_fit, "i , \n");

	/* Print top row idel values */
	for (i=0; i<size; i++)
		fprintf(fp_fit, "%i , ", i);

	/* Go to second row */
	fprintf(fp_fit, "\n , ");

	/* Write the rest of the row values: fit[idel][idop] */
	for (i=0; i<size; i++)
		fprintf(fp_fit, " %g , ", host[i]);

	fclose(fp_fit);
	free(host);
}
__host__ void dbg_print_lghtcrv_arrays(struct dat_t *ddat, int set, int n,
		char *filename) {
	/* Debug function that will print lghtcrv->fit, lghtcrv->obs, and
	 * lghtcrv->oneovervar for any given lightcurve in a specified dataset and
	 * frame	 */
	/* Each array starts at 1 and ends on n */

	double *fit, *obs, *oneovervar;
	FILE *fp;
	dim3 BLK,THD;
	int i, thd = 64;

	cudaCalloc((void**)&fit, sizeof(double), n);
	cudaCalloc((void**)&obs, sizeof(double), n);
	cudaCalloc((void**)&oneovervar, sizeof(double), n);
	fit -= 1;
	obs -= 1;
	oneovervar -= 1;

	BLK.x = floor((thd-1+n)/thd);
	THD.x = thd;
	dbg_copy_lghtcrv_arrays_krnl<<<BLK,THD>>>(ddat, set, n, fit, obs,
			oneovervar);
	checkErrorAfterKernelLaunch("dbg_copy_lghtcrv_arrays_krnl");
	deviceSyncAfterKernelLaunch("dbg_copy_lghtcrv_arrays_krnl");

	printf("\n\nFilename: %s",filename);
	fp = fopen(filename, "w+");

	/* Print top corner idop/idel label */
	fprintf(fp, "set %i , GPU fit, GPU obs, GPU oneovervar\n", set);

	/* Print row */
	for (i=1; i<=n; i++)
		fprintf(fp, "%i , %g, %g, %g\n", i,	fit[i],	obs[i],	oneovervar[i]);

	fclose(fp);
}
__host__ void dbg_print_lghtcrv_arrays_host(struct lghtcrv_t *lghtcrv, int set, int n, char *filename) {
	/* Debug function that prints the three lightcurve arrays fit, obs,
	 * and oneovervar to a single csv file*/

	int i;
	FILE *fp;

	printf("\n\nFilename: %s",filename);
	fp = fopen(filename, "w+");

	/* Print top corner idop/idel label */
	fprintf(fp, "set %i , CPU fit, CPU obs, CPU oneovervar\n", set);

	/* Print row */
	for (i=1; i<=n; i++)
		fprintf(fp, "%i , %g, %g, %g\n", i,
				lghtcrv->fit[i],
				lghtcrv->obs[i],
				lghtcrv->oneovervar[i]);

	fclose(fp);
}
__host__ void dbg_print_lghtcrv_xyy2(struct dat_t *ddat, int set, int ncalc,
		char *filename) {
	/* This debug function prints to a csv file 'filename' these arrays:
	 * lghtcrv->x[lghtcrv->ncalc]
	 * lghtcrv->y[lghtcrv->ncalc]
	 * lghtcrv->y2[lghtcrv->ncalc]
	 * lghtcrv->fit[lghtcrv->n]
	 *
	 * where the lghtcrv is specified by 'set' in 'ddat'	 */
	double *x, *y, *y2;
	FILE *fp;
	dim3 BLK,THD;
	int i, thd = 64;

	cudaCalloc((void**)&x, sizeof(double), ncalc);
	cudaCalloc((void**)&y, sizeof(double), ncalc);
	cudaCalloc((void**)&y2, sizeof(double), ncalc);
	x -= 1;	y -= 1;	y2 -= 1;

	BLK.x = floor((thd-1+ncalc)/thd);
	THD.x = thd;
	dbg_copy_lghtcrv_xyy2_krnl<<<BLK,THD>>>(ddat, set, ncalc, x, y, y2);
	checkErrorAfterKernelLaunch("dbg_copy_lghtcrv_xyy2_krnl");
	deviceSyncAfterKernelLaunch("dbg_copy_lghtcrv_xyy2_krnl");
	printf("\n\nFilename: %s",filename);
	fp = fopen(filename, "w+");

	/* Print top corner idop/idel label */
	fprintf(fp, "set %i , GPU x, GPU y, GPU y2\n", set);

	/* Print row */
	for (i=1; i<=ncalc; i++)
		fprintf(fp, "%i , %g, %g, %g\n", i,	x[i],	y[i],	y2[i]);

	fclose(fp);
}
__host__ void dbg_print_lghtcrv_xyy2_host(struct lghtcrv_t *lghtcrv, int set, int ncalc, char *filename) {
	/* This debug function prints to a csv file 'filename' these arrays:
		 * lghtcrv->x[lghtcrv->ncalc]
		 * lghtcrv->y[lghtcrv->ncalc]
		 * lghtcrv->y2[lghtcrv->ncalc]
		 *
		 * where the lghtcrv is specified by 'set' in 'ddat'	 */

	int i;
	FILE *fp;

	printf("\n\nFilename: %s",filename);
	fp = fopen(filename, "w+");

	/* Print top corner idop/idel label */
	fprintf(fp, "set %i , CPU x, CPU y, CPU y2\n", set);

	/* Print row */
	for (i=1; i<=ncalc; i++)
		fprintf(fp, "%i , %g, %g, %g\n", i,
				lghtcrv->x[i],
				lghtcrv->y[i],
				lghtcrv->y2[i]);

	fclose(fp);
}
__host__ void dbg_print_lghtcrv_pos_arrays(struct dat_t *ddat, int set, int f, int npixels, int n) {
	/* This debug function prints the GPU arrays:
	 *  - pos->cosi_s
	 *  - pos->cose_s
	 *  - pos->b_s,
	 *
	 *  all of length nPixels in the lghtcrv specified by 'set' in 'ddat' */
	float *b, *cosi, *cose;
	FILE *fp_b, *fp_cosi, *fp_cose;
	dim3 BLK,THD;
	char *filename;
	int i, j, pxa, thd = 256;

	cudaCalloc((void**)&b, sizeof(float), npixels);
	cudaCalloc((void**)&cosi, sizeof(float), npixels);
	cudaCalloc((void**)&cose, sizeof(float), npixels);

	BLK.x = floor((thd-1+npixels)/thd);	THD.x = thd;
	dbg_copy_lghtcrv_pos_arrays_krnl<<<BLK,THD>>>(ddat, set, npixels, b, cosi, cose, f);
	checkErrorAfterKernelLaunch("dbg_copy_lghtcrv_pos_arrays_krnl");
	deviceSyncAfterKernelLaunch("dbg_copy_lghtcrv_pos_arrays_krnl");

	filename = "dbg_lghtcrv_pos_b.csv";
	fp_b = fopen(filename, "w+");
	filename = "dbg_lghtcrv_pos_cosi_s.csv";
	fp_cosi = fopen(filename, "w+");
	filename = "dbg_lghtcrv_pos_cose_s.csv";
	fp_cose = fopen(filename, "w+");

	/* Print top corner set label */
	fprintf(fp_cosi,"s%i i%i , ", set,f);
	fprintf(fp_cose,"s%i i%i , ", set,f);
	fprintf(fp_b, 	"s%i i%i , ", set,f);

	/* Print i values along top of table */
	for (i=-n; i<=n; i++) {
		fprintf(fp_cosi, "%i, ", i);
		fprintf(fp_cose, "%i, ", i);
		fprintf(fp_b, "%i, ", i);
	}
	fprintf(fp_cosi, "\n");
	fprintf(fp_cose, "\n");
	fprintf(fp_b, "\n");

	for (j=-n; j<=n; j++) {
		fprintf(fp_b, "%i, ", j);	/* j-entry on far left */
		fprintf(fp_cosi, "%i, ", j);
		fprintf(fp_cose, "%i, ", j);

		for (i=-n; i<=n; i++) {
			pxa = (j+n)*(2*n+1) + (i+n);
			fprintf(fp_b, "%g, ", b[pxa]);
			fprintf(fp_cosi, "%g, ", cosi[pxa]);
			fprintf(fp_cose, "%g, ", cose[pxa]);
		}
		fprintf(fp_b, "\n");
		fprintf(fp_cosi, "\n");
		fprintf(fp_cose, "\n");
	}

	fclose(fp_b);
	fclose(fp_cosi);
	fclose(fp_cose);
}
__host__ void dbg_print_pos_arrays2(struct pos_t **pos, int f, int npixels, int n) {
	/* This debug function prints the GPU arrays:
	 *  - pos->cosi_s
	 *  - pos->cose_s
	 *  - pos->b_s,
	 *
	 *  all of length nPixels in the lghtcrv specified by 'set' in 'ddat' */
	float *b, *cosi, *cose;
	FILE *fp_b, *fp_cosi, *fp_cose;
	dim3 BLK,THD;
	char *filename;
	int i, j, pxa, thd = 256;

	cudaCalloc((void**)&b, sizeof(float), npixels);
	cudaCalloc((void**)&cosi, sizeof(float), npixels);
	cudaCalloc((void**)&cose, sizeof(float), npixels);

	BLK.x = floor((thd-1+npixels)/thd);	THD.x = thd;
	dbg_copy_lghtcrv_pos_arrays2_krnl<<<BLK,THD>>>(pos, f, npixels, b, cosi, cose);
	checkErrorAfterKernelLaunch("dbg_copy_lghtcrv_pos_arrays_krnl");
	deviceSyncAfterKernelLaunch("dbg_copy_lghtcrv_pos_arrays_krnl");

	filename = "dbg_pos_b.csv";
	fp_b = fopen(filename, "w+");
	filename = "dbg_pos_cosi_s.csv";
	fp_cosi = fopen(filename, "w+");
	filename = "dbg_pos_cose_s.csv";
	fp_cose = fopen(filename, "w+");

	/* Print top corner set label */
	fprintf(fp_cosi,"i%i , ", f);
	fprintf(fp_cose,"i%i , ", f);
	fprintf(fp_b, 	"i%i , ", f);

	/* Print i values along top of table */
	for (i=-n; i<=n; i++) {
		fprintf(fp_cosi, "%i, ", i);
		fprintf(fp_cose, "%i, ", i);
		fprintf(fp_b, "%i, ", i);
	}
	fprintf(fp_cosi, "\n");
	fprintf(fp_cose, "\n");
	fprintf(fp_b, "\n");

	for (j=-n; j<=n; j++) {
		fprintf(fp_b, "%i, ", j);	/* j-entry on far left */
		fprintf(fp_cosi, "%i, ", j);
		fprintf(fp_cose, "%i, ", j);

		for (i=-n; i<=n; i++) {
			pxa = (j+n)*(2*n+1) + (i+n);
			fprintf(fp_b, "%g, ", b[pxa]);
			fprintf(fp_cosi, "%g, ", cosi[pxa]);
			fprintf(fp_cose, "%g, ", cose[pxa]);
		}
		fprintf(fp_b, "\n");
		fprintf(fp_cosi, "\n");
		fprintf(fp_cose, "\n");
	}

	fclose(fp_b);
	fclose(fp_cosi);
	fclose(fp_cose);
}
__host__ void dbg_print_pos_bd(struct pos_t **pos, int f, int npixels, int n) {
	/* This debug function prints the GPU arrays:
	 *  - pos->b_d, currently used only experimentally in light curves
	 *
	 *  all of length nPixels in the lghtcrv specified by 'set' in 'ddat' */
	double *bd;
	FILE *fp_b;
	dim3 BLK,THD;
	char *filename;
	int i, j, pxa;
	THD.x = maxThreadsPerBlock;

	cudaCalloc((void**)&bd, sizeof(double), npixels);

	BLK.x = floor((THD.x - 1 + npixels ) / THD.x);
	dbg_copy_lghtcrv_pos_bd_krnl<<<BLK,THD>>>(pos, f, npixels, bd);
	checkErrorAfterKernelLaunch("dbg_copy_lghtcrv_pos_bd_krnl");
	deviceSyncAfterKernelLaunch("dbg_copy_lghtcrv_pos_bd_krnl");

	filename = "dbg_pos_bd.csv";
	fp_b = fopen(filename, "w+");

	fprintf(fp_b, 	"i%i , ", f);

	/* Print i values along top of table */
	for (i=-n; i<=n; i++)
		fprintf(fp_b, "%i, ", i);
	fprintf(fp_b, "\n");

	for (j=-n; j<=n; j++) {
		fprintf(fp_b, "%i, ", j);	/* j-entry on far left */

		for (i=-n; i<=n; i++) {
			pxa = (j+n)*(2*n+1) + (i+n);
			fprintf(fp_b, "%g, ", bd[pxa]);
		}
		fprintf(fp_b, "\n");
	}
	fclose(fp_b);
	cudaFree(bd);
}
__host__ void dbg_print_lghtcrv_pos_arrays_host(struct lghtcrv_t *lghtcrv,
		int f, int set) {
	/* This debug function prints the CPU arrays:
	 *  - pos->cosi
	 *  - pos->cose
	 *  - pos->b,
	 *
	 *  all of length nPixels in the lghtcrv specified by 'set' in 'ddat' */
	int i, j, n;
	FILE *fp_cosi, *fp_cose, *fp_b;
	struct pos_t *pos;
	char *fn;
	pos = &lghtcrv->rend[f].pos;
	n = pos->n;

	fn = "dbg_lghtcrv_pos_cosi_CPU.csv";
	fp_cosi = fopen(fn, "w+");
	fn = "dbg_lghtcrv_pos_cose_CPU.csv";
	fp_cose = fopen(fn, "w+");
	fn = "dbg_lghtcrv_pos_b_CPU.csv";
	fp_b = fopen(fn, "w+");

	/* Print top corner set label */
	fprintf(fp_cosi, "set %i , ", set);
	fprintf(fp_cose, "set %i , ", set);
	fprintf(fp_b, "set %i , ", set);

	/* Print i values along top of table */
	for (i=-n; i<=n; i++) {
		fprintf(fp_cosi, "%i, ", i);
		fprintf(fp_cose, "%i, ", i);
		fprintf(fp_b, "%i, ", i);
	}
	fprintf(fp_cosi, "\n");
	fprintf(fp_cose, "\n");
	fprintf(fp_b, "\n");

	for (j=-n; j<=n; j++) {
		fprintf(fp_b, "%i, ", j);	/* j-entry on far left */
		fprintf(fp_cosi, "%i, ", j);
		fprintf(fp_cose, "%i, ", j);

		for (i=-n; i<=n; i++) {
			fprintf(fp_b, "%g, ", pos->b[i][j]);
			fprintf(fp_cosi, "%g, ", pos->cosi[i][j]);
			fprintf(fp_cose, "%g, ", pos->cose[i][j]);
		}
		fprintf(fp_b, "\n");
		fprintf(fp_cosi, "\n");
		fprintf(fp_cose, "\n");
	}

	fclose(fp_b);
	fclose(fp_cosi);
	fclose(fp_cose);
}
__host__ void dbg_print_pos_arrays2_host(struct pos_t *pos) {
	/* This debug function prints the CPU arrays:
	 *  - pos->cosi
	 *  - pos->cose
	 *  - pos->b,
	 *
	 *  all of length nPixels in the lghtcrv specified by 'set' in 'ddat' */
	int i, j, n;
	FILE *fp_cosi, *fp_cose, *fp_b;
	char *fn;
	n = pos->n;

	fn = "dbg_pos_cosi_CPU.csv";
	fp_cosi = fopen(fn, "w+");
	fn = "dbg_pos_cose_CPU.csv";
	fp_cose = fopen(fn, "w+");
	fn = "dbg_pos_b_CPU.csv";
	fp_b = fopen(fn, "w+");

	/* Print top corner set label */
	fprintf(fp_cosi, "set , ");
	fprintf(fp_cose, "set , ");
	fprintf(fp_b, "set , ");

	/* Print i values along top of table */
	for (i=-n; i<=n; i++) {
		fprintf(fp_cosi, "%i, ", i);
		fprintf(fp_cose, "%i, ", i);
		fprintf(fp_b, "%i, ", i);
	}
	fprintf(fp_cosi, "\n");
	fprintf(fp_cose, "\n");
	fprintf(fp_b, "\n");

	for (j=-n; j<=n; j++) {
		fprintf(fp_b, "%i, ", j);	/* j-entry on far left */
		fprintf(fp_cosi, "%i, ", j);
		fprintf(fp_cose, "%i, ", j);

		for (i=-n; i<=n; i++) {
			fprintf(fp_b, "%g, ", pos->b[i][j]);
			fprintf(fp_cosi, "%g, ", pos->cosi[i][j]);
			fprintf(fp_cose, "%g, ", pos->cose[i][j]);
		}
		fprintf(fp_b, "\n");
		fprintf(fp_cosi, "\n");
		fprintf(fp_cose, "\n");
	}

	fclose(fp_b);
	fclose(fp_cosi);
	fclose(fp_cose);
}

__host__ void dbg_print_pos_z_host(struct pos_t *pos, char *fn) {
	/* This debug function prints the CPU arrays:
	 *	 - pos->z
	 *
	 *  all of length nPixels in the lghtcrv specified by 'set' in 'ddat' */
	int i, j, n;
	FILE *fp_z;
	n = pos->n;
	fp_z = fopen(fn, "w+");

	/* Print top corner set label */
	fprintf(fp_z, "s?f?, ");

	/* Print i values along top of table */
	for (i=-n; i<=n; i++)
		fprintf(fp_z, "%i, ", i);
	fprintf(fp_z, "\n");

	for (j=-n; j<=n; j++) {
		fprintf(fp_z, "%i, ", j);	/* j-entry on far left */
		for (i=-n; i<=n; i++)
			fprintf(fp_z, "%g, ", pos->z[i][j]);
		fprintf(fp_z, "\n");
	}
	fclose(fp_z);
}
__host__ void dbg_print_array1D_dbl(double *data, int size, int offset,
		char *filename) {
	/* Debug function that prints all elements in data to a csv */

	int i;
	FILE *fp_fit;

	printf("\n\nFilename: %s",filename);
	fp_fit = fopen(filename, "w+");

	/* Print top corner idop/idel label */
	fprintf(fp_fit, "i , \n");

	/* Print row */
	for (i=offset; i<=size; i++)
		fprintf(fp_fit, "%i , %g, \n", i, data[i]);

	fclose(fp_fit);
}
__host__ void dbg_sum_up_pos(struct dat_t *ddat, int s, int f) {
	/* Function sums up pos->z and pos->cosa */

	dbg_sum_up_pos_krnl<<<1,1>>>(ddat, s, f);
	checkErrorAfterKernelLaunch("dbg_sum_up_pos_krnl in debug_routines.cu");
}
__host__ void dbg_sum_up_pos_host(struct dat_t *ddat, int s, int f) {
	/* Same but for host operation this time */
	int x, y, n, size;
	double zsum_host=0.0, cosa_sum_host=0.0;

	switch (ddat->set[s].type) {
	case DELAY:
		n = ddat->set[s].desc.deldop.frame[f].pos.n;
		size = (2*n + 1) * (2*n + 1);
		for (x=-n; x<=n; x++)
			for (y=-n; y<=n; y++) {
				if (ddat->set[s].desc.deldop.frame[f].pos.z[x][y] > 0.0)
					zsum_host += ddat->set[s].desc.deldop.frame[f].pos.z[x][y];
				cosa_sum_host += ddat->set[s].desc.deldop.frame[f].pos.cose[x][y];
			}
		printf("sum of z for Deldop frame #%i is %3.3f\n", f, zsum_host);
		printf("sum of cose for Deldop frame #%i is %g\n", f, cosa_sum_host);
		break;
	case DOPPLER:
		n = ddat->set[s].desc.doppler.frame[f].pos.n;
		size = (2*n + 1) * (2*n + 1);
		for (x=-n; x<=n; x++)
			for (y=-n; y<=n; y++) {
				if (ddat->set[s].desc.doppler.frame[f].pos.z[x][y] > 0.0)
					zsum_host += ddat->set[s].desc.doppler.frame[f].pos.z[x][y];
				cosa_sum_host += ddat->set[s].desc.doppler.frame[f].pos.cose[x][y];
			}
		printf("sum of z for Doppler frame #%i is %3.3f\n", f, zsum_host);
		printf("sum of cose for Doppler frame #%i is %g\n", f, cosa_sum_host);
		break;
	}
}
__host__ void dbg_check_array_for_content(float *in, int size) {
	/* This debug function sums up the contents of the input array of size
	 * size and counts how many elements are not zero	 */
	int i, count = 0;
	float sum = 0.0, percent;

	for (i=0; i<size; i++) {
		sum += in[i];
		if (in[i] != 0)	count++;
	}
	percent = ((float)count/(float)size) * 100;
	printf("\nInput array sums up to %g and contains %i elements != 0.", sum, count);
	printf("\n(about %2.2f percent of the total elements)", percent);

	fflush( stdout);
}
__host__ void dbg_print_array1(float *in, int size) {
	/* This debug function prints each array value */
	int i;

	for (i=0; i<size; i++) {
		printf("\narray[%i]=%g", i, in[i]);
	}
}
__host__ void dbg_print_pos_z(struct dat_t *ddat, int set, int frm, int n, char *filename) {
	/* This debug function prints out each pos->z value from z_s */
	/* Debug function that prints all Doppler frame fit values to csv */

	int nThreads, i, j, offset, nx;
	FILE *fp_z;
	float *zz;
	dim3 BLK,THD;

	nx = 2*n + 1;
	printf("\n Debug file %s written",filename);

	nThreads = (2*n+1)*(2*n+1);
	cudaMallocManaged((void**)&zz, sizeof(float)*nThreads, cudaMemAttachHost);

	BLK.x = floor((maxThreadsPerBlock - 1 + nThreads)/maxThreadsPerBlock);
	THD.x = maxThreadsPerBlock; // Thread block dimensions

	dbg_print_poz_krnl<<<BLK,THD>>>(ddat, zz, set, frm, nThreads);
	checkErrorAfterKernelLaunch("dbg_print_fit_deldop_krnl_2");
	deviceSyncAfterKernelLaunch("dbg_print_fit_deldop_krnl_2");

	fp_z = fopen(filename, "w+");

	/* Print top corner label */
	fprintf(fp_z, "zz , ");

	/* Print top row pos->z index values */
	for (int i=-n; i<=n; i++)
		fprintf(fp_z, "%i , ", i);

	/* Print first entry in every row (except 1st): j */
	for (j=-n; j<=n; j++) {
		fprintf(fp_z,	"\n%i , ", j);

		/* Write the rest of the row values: fit[idel][idop] */
		for (i=-n; i<=n; i++) {
			offset = (j+n)*(2*n+1) + (i+n);
			fprintf(fp_z, " %g , ", zz[offset]);
		}

	}

	fclose(fp_z);
	cudaFree(zz);

}
__host__ void dbg_print_pos_z_af(struct dat_t *ddat, int set, int n) {
	/* This debug function prints out each pos->z value from z_s */
	/* Debug function that prints all Doppler frame fit values to csv */

	int nThreads, i, j, offset, nx;
	FILE *fp_z0, *fp_z1, *fp_z2, *fp_z3;
	char *filename_z0, *filename_z1, *filename_z2, *filename_z3;
	float *zz0, *zz1, *zz2, *zz3;
	dim3 BLK,THD;

	nx = 2*n + 1;
	filename_z0 = "dbg_zz0_cuda.csv";
	filename_z1 = "dbg_zz1_cuda.csv";
	filename_z2 = "dbg_zz2_cuda.csv";
	filename_z3 = "dbg_zz3_cuda.csv";
	printf("\n %sfile created",filename_z0);
	printf("\n\nFilename: %s",filename_z0);

	nThreads = (2*n+1)*(2*n+1);
	cudaCalloc((void**)&zz0, sizeof(float), nThreads);
	cudaCalloc((void**)&zz1, sizeof(float), nThreads);
	cudaCalloc((void**)&zz2, sizeof(float), nThreads);
	cudaCalloc((void**)&zz3, sizeof(float), nThreads);

	BLK.x = floor((maxThreadsPerBlock - 1 + nThreads)/maxThreadsPerBlock);
	THD.x = maxThreadsPerBlock; // Thread block dimensions

	dbg_print_poz_af_krnl<<<BLK,THD>>>(ddat, zz0, zz1, zz2, zz3, set, nThreads);
	checkErrorAfterKernelLaunch("dbg_print_fit_deldop_krnl_2");
	deviceSyncAfterKernelLaunch("dbg_print_fit_deldop_krnl_2");

	fp_z0 = fopen(filename_z0, "w+");
	fp_z1 = fopen(filename_z1, "w+");
	fp_z2 = fopen(filename_z2, "w+");
	fp_z3 = fopen(filename_z3, "w+");

	/* Print top corner label */
	fprintf(fp_z0, "zz0 , ");
	fprintf(fp_z1, "zz1 , ");
	fprintf(fp_z2, "zz2 , ");
	fprintf(fp_z3, "zz3 , ");

	/* Print top row pos->z index values */
	for (int i=0; i<nx; i++) {
		fprintf(fp_z0, "%i , ", i);
		fprintf(fp_z1, "%i , ", i);
		fprintf(fp_z2, "%i , ", i);
		fprintf(fp_z3, "%i , ", i);
	}


	/* Print first entry in every row (except 1st): j */
	for (j=0; j<nx; j++) {
		fprintf(fp_z0,	"\n%i , ", j);
		fprintf(fp_z1,	"\n%i , ", j);
		fprintf(fp_z2,	"\n%i , ", j);
		fprintf(fp_z3,	"\n%i , ", j);

		/* Write the rest of the row values: fit[idel][idop] */
		for (i=0; i<nx; i++) {
			offset = j*nx + i;
			fprintf(fp_z0, " %g , ", zz0[offset]);
			fprintf(fp_z1, " %g , ", zz1[offset]);
			fprintf(fp_z2, " %g , ", zz2[offset]);
			fprintf(fp_z3, " %g , ", zz3[offset]);
		}

	}

	fclose(fp_z0);
	fclose(fp_z1);
	fclose(fp_z2);
	fclose(fp_z3);
	cudaFree(zz0);
	cudaFree(zz1);
	cudaFree(zz2);
	cudaFree(zz3);

}
__host__ void dbg_print_pos_cose_s(struct dat_t *ddat, int set, int frm, int n, char *filename_z) {
	/* This debug function prints out each pos->z value from z_s */
	/* Debug function that prints all Doppler frame fit values to csv */

	int nThreads, i, j, offset, nx;
	FILE *fp_z;
	float *cose;
	dim3 BLK,THD;

	nx = 2*n + 1;
	printf("\n Debug file %s written",filename_z);

	nThreads = (2*n+1)*(2*n+1);
	cudaMallocManaged((void**)&cose, sizeof(float)*nThreads, cudaMemAttachHost);

	BLK.x = floor((maxThreadsPerBlock - 1 + nThreads)/maxThreadsPerBlock);
	THD.x = maxThreadsPerBlock; // Thread block dimensions

	dbg_print_cose_krnl<<<BLK,THD>>>(ddat, cose, set, frm, nThreads);
	checkErrorAfterKernelLaunch("dbg_print_pos_cose_s_krnl");
	deviceSyncAfterKernelLaunch("dbg_print_pos_cose_s_krnl");

	fp_z = fopen(filename_z, "w+");

	/* Print top corner label */
	fprintf(fp_z, "cose_s , ");

	/* Print top row pos->z index values */
	for (int i=0; i<nx; i++)
		fprintf(fp_z, "%i , ", i);

	/* Print first entry in every row (except 1st): j */
	for (j=0; j<nx; j++) {
		fprintf(fp_z,	"\n%i , ", j);

		/* Write the rest of the row values: fit[idel][idop] */
		for (i=0; i<nx; i++) {
			offset = j*nx + i;
			fprintf(fp_z, " %g , ", cose[offset]);
		}

	}

	fclose(fp_z);
	cudaFree(cose);

}
__host__ void dbg_print_cose_af(struct dat_t *ddat, int set, int n) {
	/* This debug function prints out each pos->z value from z_s */
	/* Debug function that prints all Doppler frame fit values to csv */

	int nThreads, i, j, offset, nx;
	FILE *fp_cos0, *fp_cos1, *fp_cos2, *fp_cos3;
	char *filename_cos0, *filename_cos1, *filename_cos2, *filename_cos3;
	float *cos0, *cos1, *cos2, *cos3;
	dim3 BLK,THD;

	nx = 2*n + 1;
	filename_cos0 = "dbg_cos0_cuda.csv";
	filename_cos1 = "dbg_cos1_cuda.csv";
	filename_cos2 = "dbg_cos2_cuda.csv";
	filename_cos3 = "dbg_cos3_cuda.csv";
	printf("\n %sfile created",filename_cos0);

	nThreads = (2*n+1)*(2*n+1);
	cudaCalloc((void**)&cos0, sizeof(float), nThreads);
	cudaCalloc((void**)&cos1, sizeof(float), nThreads);
	cudaCalloc((void**)&cos2, sizeof(float), nThreads);
	cudaCalloc((void**)&cos3, sizeof(float), nThreads);

	BLK.x = floor((maxThreadsPerBlock - 1 + nThreads)/maxThreadsPerBlock);
	THD.x = maxThreadsPerBlock; // Thread block dimensions

	dbg_print_cos_af_krnl<<<BLK,THD>>>(ddat, cos0, cos1, cos2, cos3, set, nThreads);
	checkErrorAfterKernelLaunch("dbg_print_fit_deldop_krnl_2");
	deviceSyncAfterKernelLaunch("dbg_print_fit_deldop_krnl_2");

	fp_cos0 = fopen(filename_cos0, "w+");
	fp_cos1 = fopen(filename_cos1, "w+");
	fp_cos2 = fopen(filename_cos2, "w+");
	fp_cos3 = fopen(filename_cos3, "w+");

	/* Print top corner label */
	fprintf(fp_cos0, "cos0 , ");
	fprintf(fp_cos1, "cos1 , ");
	fprintf(fp_cos2, "cos2 , ");
	fprintf(fp_cos3, "cos3 , ");

	/* Print top row pos->z index values */
	for (int i=0; i<nx; i++) {
		fprintf(fp_cos0, "%i , ", i);
		fprintf(fp_cos1, "%i , ", i);
		fprintf(fp_cos2, "%i , ", i);
		fprintf(fp_cos3, "%i , ", i);
	}


	/* Print first entry in every row (except 1st): j */
	for (j=0; j<nx; j++) {
		fprintf(fp_cos0,	"\n%i , ", j);
		fprintf(fp_cos1,	"\n%i , ", j);
		fprintf(fp_cos2,	"\n%i , ", j);
		fprintf(fp_cos3,	"\n%i , ", j);

		/* Write the rest of the row values: fit[idel][idop] */
		for (i=0; i<nx; i++) {
			offset = j*nx + i;
			fprintf(fp_cos0, " %g , ", cos0[offset]);
			fprintf(fp_cos1, " %g , ", cos1[offset]);
			fprintf(fp_cos2, " %g , ", cos2[offset]);
			fprintf(fp_cos3, " %g , ", cos3[offset]);
		}

	}

	fclose(fp_cos0);
	fclose(fp_cos1);
	fclose(fp_cos2);
	fclose(fp_cos3);
	cudaFree(cos0);
	cudaFree(cos1);
	cudaFree(cos2);
	cudaFree(cos3);

}
__host__ void dbg_print_pos_arrays_full(struct pos_t **pos, int f, int npixels, int n) {
	/* This debug function prints the GPU arrays:
	 *  - pos->cosi_s
	 *  - pos->cose_s
	 *  - pos->b_s,
	 *
	 *  all of length nPixels in the lghtcrv specified by 'set' in 'ddat' */
	float *b, *cosi, *cose, *zz;
	FILE *fp_b, *fp_cosi, *fp_cose, *fp_z;
	dim3 BLK,THD;
	char *filename;
	int i, j, pxa, thd = 256;

	cudaCalloc((void**)&b, sizeof(float), npixels);
	cudaCalloc((void**)&cosi, sizeof(float), npixels);
	cudaCalloc((void**)&cose, sizeof(float), npixels);
	cudaCalloc((void**)&zz, sizeof(float), npixels);

	BLK.x = floor((thd-1+npixels)/thd);	THD.x = thd;
	dbg_copy_lghtcrv_pos_arrays_full_krnl<<<BLK,THD>>>(pos, f, npixels, b, cosi, cose, zz);
	checkErrorAfterKernelLaunch("dbg_copy_lghtcrv_pos_arrays_krnl");
	deviceSyncAfterKernelLaunch("dbg_copy_lghtcrv_pos_arrays_krnl");

	filename = "STR2_pos-b_s.csv";
	fp_b = fopen(filename, "w+");
	filename = "STR2_pos-cosi_s.csv";
	fp_cosi = fopen(filename, "w+");
	filename = "STR2_pos-cose_s.csv";
	fp_cose = fopen(filename, "w+");
	filename = "STR2_pos-z_s.csv";
	fp_z = fopen(filename, "w+");

	/* Print top corner set label */
	fprintf(fp_cosi,"i%i , ", f);
	fprintf(fp_cose,"i%i , ", f);
	fprintf(fp_b, 	"i%i , ", f);
	fprintf(fp_z,   "i%i , ", f);

	/* Print i values along top of table */
	for (i=-n; i<=n; i++) {
		fprintf(fp_cosi, "%i, ", i);
		fprintf(fp_cose, "%i, ", i);
		fprintf(fp_b, "%i, ", i);
		fprintf(fp_z, "%i, ", i);
	}
	fprintf(fp_cosi, "\n");
	fprintf(fp_cose, "\n");
	fprintf(fp_b, "\n");
	fprintf(fp_z, "\n");

	for (j=-n; j<=n; j++) {
		fprintf(fp_b, "%i, ", j);	/* j-entry on far left */
		fprintf(fp_cosi, "%i, ", j);
		fprintf(fp_cose, "%i, ", j);
		fprintf(fp_z, "%i, ", j);

		for (i=-n; i<=n; i++) {
			pxa = (j+n)*(2*n+1) + (i+n);
			fprintf(fp_b, "%g, ", b[pxa]);
			fprintf(fp_cosi, "%g, ", cosi[pxa]);
			fprintf(fp_cose, "%g, ", cose[pxa]);
			fprintf(fp_z, "%g, ", zz[pxa]);
		}
		fprintf(fp_b, "\n");
		fprintf(fp_cosi, "\n");
		fprintf(fp_cose, "\n");
		fprintf(fp_z, "\n");
	}

	fclose(fp_b);
	fclose(fp_cosi);
	fclose(fp_cose);
	fclose(fp_z);
	cudaFree(zz);
	cudaFree(cosi);
	cudaFree(cose);
	cudaFree(b);
}
__host__ void dbg_print_pos_arrays_full_host(struct pos_t *pos) {
	/* This debug function prints the CPU arrays:
	 *  - pos->cosi
	 *  - pos->cose
	 *  - pos->b,
	 *
	 *  all of length nPixels in the lghtcrv specified by 'set' in 'ddat' */
	int i, j, n;
	FILE *fp_cosi, *fp_cose, *fp_b, *fp_z;
	char *fn;
	n = pos->n;

	fn = "CPU_pos-cosi.csv";
	fp_cosi = fopen(fn, "w+");
	fn = "CPU_pos-cose.csv";
	fp_cose = fopen(fn, "w+");
	fn = "CPU_pos-b.csv";
	fp_b = fopen(fn, "w+");
	fn = "CPU_pos-z.csv";
	fp_z = fopen(fn, "w+");

	/* Print top corner set label */
	fprintf(fp_cosi, "set , ");
	fprintf(fp_cose, "set , ");
	fprintf(fp_b, "set , ");
	fprintf(fp_z, "set , ");

	/* Print i values along top of table */
	for (i=-n; i<=n; i++) {
		fprintf(fp_cosi, "%i, ", i);
		fprintf(fp_cose, "%i, ", i);
		fprintf(fp_b, "%i, ", i);
		fprintf(fp_z, "%i, ", i);
	}
	fprintf(fp_cosi, "\n");
	fprintf(fp_cose, "\n");
	fprintf(fp_b, "\n");
	fprintf(fp_z, "\n");

	for (j=-n; j<=n; j++) {
		fprintf(fp_b, "%i, ", j);	/* j-entry on far left */
		fprintf(fp_cosi, "%i, ", j);
		fprintf(fp_cose, "%i, ", j);
		fprintf(fp_z, "%i, ", j);

		for (i=-n; i<=n; i++) {
			fprintf(fp_b, "%g, ", pos->b[i][j]);
			fprintf(fp_z, "%g, ", pos->z[i][j]);
			fprintf(fp_cosi, "%g, ", pos->cosi[i][j]);
			fprintf(fp_cose, "%g, ", pos->cose[i][j]);
		}
		fprintf(fp_b, "\n");
		fprintf(fp_z, "\n");
		fprintf(fp_cosi, "\n");
		fprintf(fp_cose, "\n");
	}

	fclose(fp_b);
	fclose(fp_z);
	fclose(fp_cosi);
	fclose(fp_cose);
}
__host__ void dbg_print_facet_normals_host(struct mod_t *mod, char *fn) {
	/* This debug function prints all facet normals in a given model */
	int nf;
	FILE *fp_n;
	nf = mod->shape.comp[0].real.nf;
	fp_n = fopen(fn, "w+");

	/* Print top row */
	fprintf(fp_n, ", value, \n");

	for (int f=0; f<nf; f++) {
		fprintf(fp_n, "%i, %g, \n", f, mod->shape.comp[0].real.f[f].n[0]);
		fprintf(fp_n, "%i, %g, \n", f, mod->shape.comp[0].real.f[f].n[1]);
		fprintf(fp_n, "%i, %g, \n", f, mod->shape.comp[0].real.f[f].n[2]);
	}
	fclose(fp_n);
}
__host__ void dbg_print_facet_normals(struct mod_t *dmod, int nf, char *fn) {
	/* This debug function prints all facet normals in a given model */
	FILE *fp_n;
	float3 *dnormals, *hnormals;
	dim3 BLK,THD;
	fp_n = fopen(fn, "w+");

	/* Allocate memory */
	gpuErrchk(cudaMalloc((void**)&dnormals, sizeof(float3) * nf));
	hnormals = (float3 *) malloc(nf*sizeof(float3));

	THD.x = maxThreadsPerBlock;
	BLK.x = floor((THD.x - 1 + nf)/THD.x);
	dbg_copy_facet_normals_krnl<<<BLK,THD>>>(dmod, nf, dnormals);
	checkErrorAfterKernelLaunch("copy_facet_normals_krnl");
	gpuErrchk(cudaMemcpy(hnormals, dnormals, sizeof(float3)*nf, cudaMemcpyDeviceToHost));

	/* Print top row */
	fprintf(fp_n, ", value, \n");

	for (int f=0; f<nf; f++) {
		fprintf(fp_n, "%i, %g, \n", f, hnormals[f].x);
		fprintf(fp_n, "%i, %g, \n", f, hnormals[f].y);
		fprintf(fp_n, "%i, %g, \n", f, hnormals[f].z);
	}
	fclose(fp_n);
}
__host__ void dbg_print_posfacets(struct pos_t **pos, int f, int n, char *filename) {

	/* This debug function prints out pos->f[i][j] for the entire POS */
	int nThreads, i, j, offset, nx, msz1, msz2, pxa;
	FILE *fp_f;
	int **ff, *fac;
	dim3 BLK,THD;
	THD.x = maxThreadsPerBlock;

	nx = 2*n + 1;
	printf("\n Debug file %s written",filename);
	msz1 = sizeof(int*)*nx;
	msz2 = sizeof(int)*nx;
	nThreads = (2*n+1)*(2*n+1);

	cudaMallocManaged((void**)&ff, msz1, cudaMemAttachGlobal);
	ff -= n;
	for (i=-n; i<=n; i++){
		cudaMallocManaged((void**)&ff[i], msz2, cudaMemAttachGlobal);
		ff[i] -= n;
	}
	cudaCalloc((void**)&fac, sizeof(int), nThreads);

	BLK.x = floor((THD.x - 1 + nThreads)/THD.x);

	dbg_print_fac2_krnl<<<BLK,THD>>>(pos, fac, f, nThreads, nx);
	checkErrorAfterKernelLaunch("dbg_print_fac_krnl");
	deviceSyncAfterKernelLaunch("dbg_print_fac_krnl");

	fp_f = fopen(filename, "w+");

	/* Print top corner label */
	fprintf(fp_f, "ff , ");

	/* Print top row pos->z index values */
	for (int i=-n; i<=n; i++)
		fprintf(fp_f, "%i , ", i);

	/* Print first entry in every row (except 1st): j */
	for (j=-n; j<=n; j++) {
		fprintf(fp_f,	"\n%i , ", j);

		/* Write the rest of the row values: fit[idel][idop] */
		for (i=-n; i<=n; i++) {
			pxa = (j+n)*(2*n+1) + (i+n);
			fprintf(fp_f, " %i , ", fac[pxa]);
		}
	}

	fclose(fp_f);
	cudaFree(ff);
}
__host__ void dbg_print_posfacets_host(struct pos_t *pos, char *fn)
{
	/* This debug function prints out pos->f[i][j] for the entire POS */
	int i, j, n;
	FILE *fp_f;
	n = pos->n;
	fp_f = fopen(fn, "w+");

	/* Print top corner set label */
	fprintf(fp_f, "s?f?, ");

	/* Print i values along top of table */
	for (i=-n; i<=n; i++)
		fprintf(fp_f, "%i, ", i);
	fprintf(fp_f, "\n");

	for (j=-n; j<=n; j++) {
		fprintf(fp_f, "%i, ", j);	/* j-entry on far left */
		for (i=-n; i<=n; i++)
			fprintf(fp_f, "%i, ", pos->f[i][j]);
		fprintf(fp_f, "\n");
	}
	fclose(fp_f);
}
__host__ void dbg_print_lc_fit(struct dat_t *ddat, int s, char *filename_fit, int n) {
	/* Debug function that prints all Doppler frame fit values to csv */

	int i;
	FILE *fp_fit;
	double *fit;
	dim3 BLK,THD;

	cudaCalloc((void**)&fit, sizeof(double), n);
	fit -= 1;
	THD.x = maxThreadsPerBlock;
	BLK.x = floor((THD.x - 1 + n)/THD.x);

	dbg_print_lc_fit_krnl<<<BLK,THD>>>(ddat, fit, s, n);
	checkErrorAfterKernelLaunch("dbg_print_lc_fit_krnl");
	deviceSyncAfterKernelLaunch("dbg_print_lc_fit_krnl");

	fp_fit = fopen(filename_fit, "w+");
	fprintf(fp_fit, "i , ");
	for (i=1; i<=n; i++)
		fprintf(fp_fit,	"\n%i , %g", i, fit[i]);
	fclose(fp_fit);
	//cudaFree(fit);
}
__host__ void dbg_print_lc_fit_host(struct lghtcrv_t *lghtcrv, char *filename_fit, int n) {
	/* Debug function that prints all Doppler frame fit values to csv */

	int i;
	FILE *fp_fit;
	double *fit;
	dim3 BLK,THD;


	fp_fit = fopen(filename_fit, "w+");
	fprintf(fp_fit, "i , ");
	for (i=1; i<=n; i++)
		fprintf(fp_fit,	"\n%i , %g", i, lghtcrv->fit[i]);
	fclose(fp_fit);
	//cudaFree(fit);
}
