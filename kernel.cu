#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>

// nvcc kernel.cu -o print_capability

__global__ void addKernel(int *c, const int *a, const int *b)
{
//    int i = threadIdx.x;
//    c[i] = a[i] + b[i];
}

int main()
{
    cudaDeviceProp prp;
    cudaError_t cudaStatus;

    cudaStatus = cudaGetDeviceProperties(&prp, /*device=*/0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaGetDeviceProperties failed!");
        return 1;
    }

    printf("Compute Capability=%d.%d\r\n", prp.major, prp.minor);

    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;
    }

    return 0;
}
