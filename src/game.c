

#include <SDL2/SDL.h>
#include <CL/cl.h>

#include "../include/config.h"
#include "../include/loadfile.h"
#include "../include/sdlmanager.h"


int mainloop(SDL_Window* window){

	cl_int CL_err = CL_SUCCESS;
	cl_uint numPlatforms = 0;
	CL_err = clGetPlatformIDs(0, NULL, &numPlatforms);
	
	if(!CL_err){
		printf("%u platform(s) found.\n", numPlatforms);
	}
	else{
		printf("Err %d\n", CL_err);
	}
	char* kernelSource_gol = loadfile("src/kernel/gol.cl");
	char* kernelSource_chromatic = loadfile("src/kernel/chromatic.cl");


	cl_platform_id platform;
	cl_device_id device;
	cl_context context;
	cl_command_queue queue;
	
	cl_program program_gol;
	cl_program program_chromatic;
	
	cl_kernel kernel_game_step;
	cl_kernel kernel_render;
	cl_kernel kernel_seed_grids;

	cl_kernel kernel_chromatic;
	
	cl_mem d_gamebuffer;
	cl_mem d_pixelBuffer;


	CL_err = clGetPlatformIDs(1, &platform, NULL);
	CL_err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 1, &device, NULL);

	context = clCreateContext(NULL, 1, &device, NULL, NULL, &CL_err);
	queue = clCreateCommandQueueWithProperties(context, device, NULL, &CL_err);

	d_gamebuffer = clCreateBuffer(context, CL_MEM_READ_WRITE, GAMENB * sizeof(uint8_t) * GAMESIZE_X * GAMESIZE_Y, NULL, &CL_err);
	d_pixelBuffer = clCreateBuffer(context, CL_MEM_READ_WRITE , WIDTH*HEIGHT*sizeof(uint32_t), NULL, &CL_err);


	program_gol = clCreateProgramWithSource(context, 1, &kernelSource_gol, NULL, &CL_err);
	program_chromatic = clCreateProgramWithSource(context, 1, &kernelSource_chromatic, NULL, &CL_err);
	
	printf("Building program\n");
	printf("Miaou %d\n", CL_err);
	CL_err = clBuildProgram(program_gol, 1, &device, NULL, NULL, NULL);
	printf("Miaou %d\n", CL_err);
	printf("Miaou %d\n", CL_err);
	CL_err = clBuildProgram(program_chromatic, 1, &device, NULL, NULL, NULL);
	printf("Miaou %d\n", CL_err);

	kernel_game_step = clCreateKernel(program_gol, "game_step", &CL_err);
	kernel_seed_grids = clCreateKernel(program_gol, "seed_grids", &CL_err);
	kernel_render = clCreateKernel(program_gol, "render", &CL_err);

	kernel_chromatic = clCreateKernel(program_chromatic, "chromatic_aberation", &CL_err);

	
	
	int gamenb = GAMENB;
	int gamesize[2] = {GAMESIZE_X, GAMESIZE_Y};
	int screensize[2] = {WIDTH, HEIGHT};
	
	size_t global_size;
	clSetKernelArg(kernel_seed_grids, 0, sizeof(int), &gamenb);
	clSetKernelArg(kernel_seed_grids, 1, sizeof(gamesize), &gamesize);
	clSetKernelArg(kernel_seed_grids, 2, sizeof(cl_mem), &d_gamebuffer);
	
	global_size = GAMESIZE_X*GAMESIZE_Y*GAMENB;
	CL_err = clEnqueueNDRangeKernel(queue, kernel_seed_grids, 1, NULL, &global_size, NULL, 0, NULL, NULL);
	
	clFinish(queue);
	
	

	char done = 0;

	char* keyboardState;

	uint32_t frameStart, frameTime;
	frameStart = 0;

	while(!done){

		done = m_handleInput(&keyboardState);
		
		
		clSetKernelArg(kernel_game_step, 0, sizeof(int), &gamenb);
		clSetKernelArg(kernel_game_step, 1, sizeof(gamesize), &gamesize);
		clSetKernelArg(kernel_game_step, 2, sizeof(cl_mem), &d_gamebuffer);

		global_size = GAMESIZE_X*GAMESIZE_Y*GAMENB;
		CL_err = clEnqueueNDRangeKernel(queue, kernel_game_step, 1, NULL, &global_size, NULL, 0, NULL, NULL);

		clFinish(queue);


		clSetKernelArg(kernel_render, 0, sizeof(gamesize), &gamesize);
		clSetKernelArg(kernel_render, 1, sizeof(screensize), &screensize);
		clSetKernelArg(kernel_render, 2, sizeof(cl_mem), &d_gamebuffer);
		clSetKernelArg(kernel_render, 3, sizeof(cl_mem), &d_pixelBuffer);

		global_size = WIDTH*HEIGHT;
		CL_err = clEnqueueNDRangeKernel(queue, kernel_render, 1, NULL, &global_size, NULL, 0, NULL, NULL);

		clFinish(queue);
		
		clSetKernelArg(kernel_chromatic, 0, sizeof(screensize), &screensize);
		clSetKernelArg(kernel_chromatic, 1, sizeof(cl_mem), &d_pixelBuffer);

		global_size = WIDTH*HEIGHT;
		CL_err = clEnqueueNDRangeKernel(queue, kernel_chromatic, 1, NULL, &global_size, NULL, 0, NULL, NULL);

		clFinish(queue);

		CL_err = clEnqueueReadBuffer(queue, d_pixelBuffer, CL_TRUE, 0, WIDTH*HEIGHT*sizeof(uint32_t), SDL_GetWindowSurface(window)->pixels, 0, NULL, NULL);

		clFinish(queue);


		m_endFrame(window, &frameStart, &frameTime);
		printf("Frame done in %dms\n", frameTime);
	}
}