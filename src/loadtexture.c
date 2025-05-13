#define STB_IMAGE_IMPLEMENTATION
#include "../include/stb_image.h"
#include "../include/types.h"

#ifndef NULL
#define NULL ((void*)0)
#endif

Texture loadPNG(char* path){
	printf("Loading image : %s\n", path);
	Texture t;
	t.pixels = stbi_load(path, &t.width, &t.height, NULL, 4);
	return t;
}