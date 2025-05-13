
__kernel void chromatic_aberation(int2 size, __global uint* pixels){

	int id = get_global_id(0);
	int x = id%size.x;
	int y = id / size.x;

	float ratio = ((float)size.x / (float)size.y);

	float uc = ((float)(x - (size.x/2)) / (float)size.x);
	float vc = ((float)(y - (size.y/2)) / (float)size.y);

	float r = 0.01 * sqrt(uc*uc + vc*vc);
	// float r = 0.;

	float2 dr = {r*cos(M_PI_F/2.f), r*sin(M_PI_F/2.f)};
	float2 dg = {r*cos((M_PI_F/2.f) + (2.f*M_PI_F/3.f)), r*sin((M_PI_F/2.f) + (2.f*M_PI_F/3.f))};
	float2 db = {r*cos((M_PI_F/2.f) - (2.f*M_PI_F/3.f)), r*sin((M_PI_F/2.f) - (2.f*M_PI_F/3.f))};
	
	float2 target_uv;

	float4 c;
	uint source;
	source = pixels[(int)(floor((vc+0.5f)*size.y)*size.x) + (int)floor((uc+0.5f)*size.x)];

	target_uv = (float2){uc+dr.x+0.5f, vc+dr.y+0.5f};
	if(target_uv.x < 0.) target_uv.x = 0.;
	if(target_uv.x >= 1.) target_uv.x = (float)size.x-1. / (float)size.x;
	if(target_uv.y < 0.) target_uv.y = 0.;
	if(target_uv.y >= 1.) target_uv.y = (float)size.x-1. / (float)size.x;

	source = pixels[(int)(floor((target_uv.y)*size.y)*size.x) + (int)floor((target_uv.x)*size.x)];
	c.x = (float)((source&0x00ff0000) >> 16) / 255.;


	target_uv = (float2){uc+dg.x+0.5f, vc+dg.y+0.5f};
	if(target_uv.x < 0.) target_uv.x = 0.;
	if(target_uv.x >= 1.) target_uv.x = (float)size.x-1. / (float)size.x;
	if(target_uv.y < 0.) target_uv.y = 0.;
	if(target_uv.y >= 1.) target_uv.y = (float)size.x-1. / (float)size.x;

	source = pixels[(int)(floor((target_uv.y)*size.y)*size.x) + (int)floor((target_uv.x)*size.x)];
	c.y = (float)((source&0x0000ff00) >> 8) / 255.;

	target_uv = (float2){uc+db.x+0.5f, vc+db.y+0.5f};
	if(target_uv.x < 0.) target_uv.x = 0.;
	if(target_uv.x >= 1.) target_uv.x = (float)size.x-1. / (float)size.x;
	if(target_uv.y < 0.) target_uv.y = 0.;
	if(target_uv.y >= 1.) target_uv.y = (float)size.x-1. / (float)size.x;

	source = pixels[(int)(floor((target_uv.y)*size.y)*size.x) + (int)floor((target_uv.x)*size.x)];
	c.z = (float)((source&0x000000ff) >> 0) / 255.;
	
	// source = pixels[id];
	c.w = (float)((source&0xff000000) >> 24) / 255.;
	
	char4 ci = {c.x*255, c.y*255, c.z*255, c.w*255};

	pixels[(y*size.x) + x] = (ci.w<<24) | (ci.x << 16) | (ci.y << 8) | (ci.z);

}