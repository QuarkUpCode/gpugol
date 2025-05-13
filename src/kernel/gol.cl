

int get_index(int3 pos, int2 gamesize){
	return (gamesize.x * gamesize.y * pos.z) + (gamesize.x * pos.y) + pos.x;
}

void update_cell(int3 pos, int2 gamesize, __global uchar* buffer){
	
	uchar neighbours = 0;
	
	neighbours += (uchar)((buffer[get_index((int3){(pos.x + (-1)) % gamesize.x, (pos.y + (-1)) % gamesize.y, pos.z}, gamesize)]) == 255);
	neighbours += (uchar)((buffer[get_index((int3){(pos.x + (0)) % gamesize.x, (pos.y + (-1)) % gamesize.y, pos.z}, gamesize)]) == 255);
	neighbours += (uchar)((buffer[get_index((int3){(pos.x + (+1)) % gamesize.x, (pos.y + (-1)) % gamesize.y, pos.z}, gamesize)]) == 255);

	neighbours += (uchar)((buffer[get_index((int3){(pos.x + (-1)) % gamesize.x, (pos.y + (0)) % gamesize.y, pos.z}, gamesize)]) == 255);
	neighbours += (uchar)((buffer[get_index((int3){(pos.x + (+1)) % gamesize.x, (pos.y + (0)) % gamesize.y, pos.z}, gamesize)]) == 255);

	neighbours += (uchar)((buffer[get_index((int3){(pos.x + (-1)) % gamesize.x, (pos.y + (+1)) % gamesize.y, pos.z}, gamesize)]) == 255);
	neighbours += (uchar)((buffer[get_index((int3){(pos.x + (0)) % gamesize.x, (pos.y + (+1)) % gamesize.y, pos.z}, gamesize)]) == 255);
	neighbours += (uchar)((buffer[get_index((int3){(pos.x + (+1)) % gamesize.x, (pos.y + (+1)) % gamesize.y, pos.z}, gamesize)]) == 255);

	uchar self = (buffer[get_index((int3){(pos.x + (0)) % gamesize.x, (pos.y + (0)) % gamesize.y, pos.z}, gamesize)]);
	uchar nextstate = self;

	if(self == 255){
		if(neighbours<2) nextstate = 0;
		if(neighbours==2 || neighbours==3) nextstate = 255;
		if(neighbours>3) nextstate = 0;
	}
	else{
		if(neighbours==3) nextstate = 255;
		else nextstate = 0;
	}

	buffer[get_index((int3){(pos.x + (0)) % gamesize.x, (pos.y + (0)) % gamesize.y, pos.z}, gamesize)] = nextstate;
}


__kernel void seed_grids(int gamenb, int2 gamesize, __global uchar* buffer){
	
	int id = get_global_id(0);
	int x = id%gamesize.x;
	int y = (id/gamesize.x)%gamesize.y;
	int gameid = id/(gamesize.x * gamesize.y);

	if(gameid >= gamenb) return;
	int v = 0;

	// if(x == 14 && y == 13) v = 255;
	// if(x == 12 && y == 14) v = 255;
	// if(x == 14 && y == 14) v = 255;
	// if(x == 14 && y == 15) v = 255;
	// if(x == 15 && y == 15) v = 255;

	//meh; good enough idk what i did but eh; good enough (>>4 % 17 ???)
	v = 255 * (((((id * x+1) * (id * x+1) >> 4) ^ 0x34) % 17) < 4);

	buffer[get_index((int3){x, y, gameid}, gamesize)] = v;
}

__kernel void game_step(int gamenb, int2 gamesize, __global uchar* buffer){

	int id = get_global_id(0);
	int x = id%gamesize.x;
	int y = (id/gamesize.x)%gamesize.y;
	int gameid = id/(gamesize.x * gamesize.y);

	if(gameid >= gamenb) return;

	update_cell((int3){x, y, gameid}, gamesize, buffer);	

}

__kernel void render(int2 gamesize, int2 size, __global uchar* gamebuffer, __global uint* pixels){

	int id = get_global_id(0);
	int x = id%size.x;
	int y = id / size.x;

	float ratio = ((float)size.x / (float)size.y);

	float uc = ((float)(x - (size.x/2)) / (float)size.x) * ratio;
	float vc = ((float)(y - (size.y/2)) / (float)size.y);

	
	int gameid = 0;
	int scale = 1;

	uint color = 0xff123456;
	uchar cellr;
	uchar cellg;
	uchar cellb;

	if(uc >= -0.5f && uc < 0.5f){

		cellr = gamebuffer[get_index((int3){floor((uc+0.5)*gamesize.x)/scale, floor((vc+0.5)*gamesize.y)/scale, 0}, gamesize)];
		cellg = gamebuffer[get_index((int3){floor((uc+0.5)*gamesize.x)/scale, floor((vc+0.5)*gamesize.y)/scale, 1}, gamesize)];
		cellb = gamebuffer[get_index((int3){floor((uc+0.5)*gamesize.x)/scale, floor((vc+0.5)*gamesize.y)/scale, 2}, gamesize)];
		color = 0xff000000 | (cellr<<16) | (cellg<<8) | (cellb<<0);
		// color = 0xff000000 | (cellr<<16) | (cellr<<8) | (cellr<<0);

	}

	pixels[(y * size.x) + x] = color;

}