uint ABGR_to_ARGB(uint c){
	uint a = (c&0xff000000) >> 24;
	uint b = (c&0x00ff0000) >> 16;
	uint g = (c&0x0000ff00) >> 8;
	uint r = (c&0x000000ff) >> 0;
	return ((a<<24) | (r<<16) | (g<<8) | b);
}

__kernel void load_background_texture(int2 texture_size, int2 size, __global uint* texture, __global uint* backBuffer){
	int id = get_global_id(0);
	int x = id%size.x;
	int y = id / size.x;

	float ratio = ((float)size.x / (float)size.y);

	float uc = ((float)(x - (size.x/2)) / (float)size.x) * ratio;
	float vc = ((float)(y - (size.y/2)) / (float)size.y);

	int2 target = {floor((uc+(0.5f*texture_size.x/texture_size.y))*texture_size.y), floor((vc+0.5f)*texture_size.y)};
	if(target.x < 0 || target.x >= texture_size.x || target.y < 0 || target.y >= texture_size.y){
		backBuffer[(y*size.x) + x] = 0xff000000;
		// backBuffer[(y*size.x) + x] = 0xffffffff;
		return;
	}

	uint source_abgr = texture[(target.y*texture_size.x) + target.x];

	backBuffer[(y*size.x) + x] = ABGR_to_ARGB(source_abgr);

}

int get_index(int3 pos, int2 gamesize){
	return (gamesize.x * gamesize.y * pos.z) + (gamesize.x * pos.y) + pos.x;
}

__kernel void chromatic_aberation(int gamenb, int2 gamesize, __global uchar* gamebuffer, int2 size, __global uint* pixels, __global uint* output){

	int id = get_global_id(0);
	int x = id%size.x;
	int y = id / size.x;

	float ratio = ((float)size.x / (float)size.y);

	float uc = ((float)(x - (size.x/2)) / (float)size.x);
	float vc = ((float)(y - (size.y/2)) / (float)size.y);

	float r = 0.1f * sqrt(uc*uc + vc*vc);
	// float r = 0.005;
	// float r = 0.05f;

	float3 mask;
	uchar cellr = 0;
	uchar cellg = 0;
	uchar cellb = 0;
	
	if(uc*ratio > -0.5f && uc*ratio < 0.5f){
		cellr = gamebuffer[get_index((int3){floor(((uc*ratio)+0.5f)*gamesize.x), floor((vc+0.5f)*gamesize.y), 0}, gamesize)];
		cellg = gamebuffer[get_index((int3){floor(((uc*ratio)+0.5f)*gamesize.x), floor((vc+0.5f)*gamesize.y), 1}, gamesize)];
		cellb = gamebuffer[get_index((int3){floor(((uc*ratio)+0.5f)*gamesize.x), floor((vc+0.5f)*gamesize.y), 2}, gamesize)];
	}
	
	mask.x = (cellr != 0) * 1.f;
	mask.y = (cellg != 0) * 1.f;
	mask.z = (cellb != 0) * 1.f;
	float3 dim = {1.f, 1.f, 1.f};
	// dim.x = 0.25f + (mask.x*(1.f-0.25f));
	// dim.y = 0.25f + (mask.y*(1.f-0.25f));
	// dim.z = 0.25f + (mask.z*(1.f-0.25f));

	float2 dr = {mask.x*r*cos(M_PI_F/2.f), mask.x*r*sin(M_PI_F/2.f)};
	float2 dg = {mask.y*r*cos((M_PI_F/2.f) + (2.f*M_PI_F/3.f)), mask.y*r*sin((M_PI_F/2.f) + (2.f*M_PI_F/3.f))};
	float2 db = {mask.z*r*cos((M_PI_F/2.f) - (2.f*M_PI_F/3.f)), mask.z*r*sin((M_PI_F/2.f) - (2.f*M_PI_F/3.f))};
	
	float2 target_uv = {0.f, 0.f};
	int2 target = {0, 0};

	float4 c;
	uint4 ci;
	
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
	
	source = pixels[(target.y*size.x) + target.x];
	c.x = ((float)((source&0x00ff0000) >> 16)) / 255.f;
	// ci.x = ((source&0x00ff0000) >> 16);

	// target_uv = (float2){uc+0.5f, vc+0.5f};
	target_uv = (float2){uc+dg.x+0.5f, vc+dg.y+0.5f};
	target = (int2){(int)floor(target_uv.x * size.x), (int)floor(target_uv.y * size.y)};
	if(target.x < 0) target.x = 0;
	if(target.x >= size.x) target.x = size.x - 1;
	if(target.y < 0) target.y = 0;
	if(target.y >= size.y) target.y = size.y - 1;

	source = pixels[(target.y*size.x) + target.x];
	c.y = ((float)((source&0x0000ff00) >> 8)) / 255.f;
	// ci.y = ((source&0x0000ff00) >> 8);

	// target_uv = (float2){uc+0.5f-0.01f, vc+0.5f-0.01f};
	target_uv = (float2){uc+db.x+0.5f, vc+db.y+0.5f};

	target = (int2){(int)floor(target_uv.x * size.x), (int)floor(target_uv.y * size.y)};
	if(target.x < 0) target.x = 0;
	if(target.x >= size.x) target.x = size.x - 1;
	if(target.y < 0) target.y = 0;
	if(target.y >= size.y) target.y = size.y - 1;
	
	source = pixels[(target.y*size.x) + target.x];
	c.z = ((float)((source&0x000000ff) >> 0)) / 255.f;
	// ci.z = ((source&0x000000ff) >> 0);
	
	c.w = (float)((source&0xff000000) >> 24) / 255.f;
	// ci.w = (source&0xff000000)>>24;


	ci = (uint4){floor(dim.x*c.x*255.f), floor(dim.y*c.y*255.f), floor(dim.z*c.z*255.f), floor(c.w*255.f)};

	output[(y*size.x) + x] = (ci.w<<24) | (ci.x << 16) | (ci.y << 8) | (ci.z);

}