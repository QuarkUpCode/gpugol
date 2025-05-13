
__kernel void chromatic_aberation(int2 size, __global uint* pixels, __global uint* output){

	int id = get_global_id(0);
	int x = id%size.x;
	int y = id / size.x;

	float ratio = ((float)size.x / (float)size.y);

	float uc = ((float)(x - (size.x/2)) / (float)size.x);
	float vc = ((float)(y - (size.y/2)) / (float)size.y);

	float r = 0.01 * sqrt(uc*uc + vc*vc/(ratio*ratio));
	// float r = 0.005;
	// float r = 0.;

	float2 dr = {r*cos(M_PI_F/2.f), r*sin(M_PI_F/2.f)};
	float2 dg = {r*cos((M_PI_F/2.f) + (2.f*M_PI_F/3.f)), r*sin((M_PI_F/2.f) + (2.f*M_PI_F/3.f))};
	float2 db = {r*cos((M_PI_F/2.f) - (2.f*M_PI_F/3.f)), r*sin((M_PI_F/2.f) - (2.f*M_PI_F/3.f))};
	
	float2 target_uv = {0., 0.};
	int2 target = {0, 0};

	float4 c;
	char4 ci;
	
	uint source;

	source = pixels[(int)(floor((vc+0.5f)*size.y)*size.x) + (int)floor((uc+0.5f)*size.x)];
	source = pixels[id];

	// target_uv = (float2){uc+0.5f, vc+0.5f};
	target_uv = (float2){uc+dr.x+0.5f, vc+dr.y+0.5f};
	target = (int2){(int)floor(target_uv.x * size.x), (int)floor(target_uv.y * size.y)};
	if(target.x < 0) target.x = 0;
	if(target.x >= size.x) target.x = size.x - 1;
	if(target.y < 0) target.y = 0;
	if(target.y >= size.y) target.y = size.y - 1;
	
	// if(target_uv.x < 0.) target_uv.x = 0.;
	// if(target_uv.x >= 1.) target_uv.x = (float)size.x-1.f / (float)size.x;
	// if(target_uv.y < 0.) target_uv.y = 0.;
	// if(target_uv.y >= 1.) target_uv.y = (float)size.y-1.f / (float)size.y;

	source = pixels[(target.y*size.x) + target.x];
	c.x = ((float)((source&0x00ff0000) >> 16)) / 255.f;
	ci.x = ((source&0x00ff0000) >> 16);

	// target_uv = (float2){uc+0.5f, vc+0.5f};
	target_uv = (float2){uc+dg.x+0.5f, vc+dg.y+0.5f};
	target = (int2){(int)floor(target_uv.x * size.x), (int)floor(target_uv.y * size.y)};
	if(target.x < 0) target.x = 0;
	if(target.x >= size.x) target.x = size.x - 1;
	if(target.y < 0) target.y = 0;
	if(target.y >= size.y) target.y = size.y - 1;
	// if(target_uv.x < 0.) target_uv.x = 0.;
	// if(target_uv.x >= 1.) target_uv.x = (float)size.x-1.f / (float)size.x;
	// if(target_uv.y < 0.) target_uv.y = 0.;
	// if(target_uv.y >= 1.) target_uv.y = (float)size.y-1.f / (float)size.y;

	// source = pixels[(int)(floor(target_uv.y*size.y)*size.x) + (int)floor(target_uv.x*size.x)];
	source = pixels[(target.y*size.x) + target.x];
	c.y = ((float)((source&0x0000ff00) >> 8)) / 255.f;
	ci.y = ((source&0x0000ff00) >> 8);

	// target_uv = (float2){uc+0.5f-0.01f, vc+0.5f-0.01f};
	target_uv = (float2){uc+db.x+0.5f, vc+db.y+0.5f};

	target = (int2){(int)floor(target_uv.x * size.x), (int)floor(target_uv.y * size.y)};
	if(target.x < 0) target.x = 0;
	if(target.x >= size.x) target.x = size.x - 1;
	if(target.y < 0) target.y = 0;
	if(target.y >= size.y) target.y = size.y - 1;
	// if(target_uv.x < 0.) target_uv.x = 0.;
	// if(target_uv.x >= 1.) target_uv.x = (float)size.x-1.f / (float)size.x;
	// if(target_uv.y < 0.) target_uv.y = 0.;
	// if(target_uv.y >= 1.) target_uv.y = (float)size.y-1.f / (float)size.y;

	// source = pixels[(int)(floor(target_uv.y*size.y)*size.x) + (int)floor(target_uv.x*size.x)];
	source = pixels[(target.y*size.x) + target.x];
	c.z = ((float)((source&0x000000ff) >> 0)) / 255.f;
	ci.z = ((source&0x000000ff) >> 0);
	
	// source = pixels[id];
	c.w = (float)((source&0xff000000) >> 24) / 255.f;
	ci.w = (source&0xff000000)>>24;

	// c = (float4){0.9f, 0.9f, 0.9f, 0.9f};

	// ci = (char4){floor(c.x*255.), floor(c.y*255.), floor(c.z*255.), floor(c.w*255.)};

	// ci = (char4){255, 255, 255, 255};

	output[(y*size.x) + x] = (ci.w<<24) | (ci.x << 16) | (ci.y << 8) | (ci.z);

}