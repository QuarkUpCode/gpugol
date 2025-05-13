#include <stdio.h>
#include <stdint.h>

#include <SDL2/SDL.h>

#include "../include/config.h"
#include "../include/initsdl.h"

#include "../include/game.h"

int main(int argc, char** argv){

	SDL_Window* window = initSDL("GPUGOL");

	mainloop(window);

}
