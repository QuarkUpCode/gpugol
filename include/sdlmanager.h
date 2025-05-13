#ifndef SDLMANAGER_H
#define SDLMANAGER_H

#include <stdint.h>
#include <SDL2/SDL.h>

char m_handleInput(char** keyboardState);

char m_getkey(char* keyboardState, char key);

void m_endFrame(SDL_Window* window, uint32_t* frameStart, uint32_t* frameTime);

#endif
