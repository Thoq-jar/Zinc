const sdl = @import("sdl_core.zig").sdl;
const sdl_core = @import("sdl_core.zig");

pub const CoreUI = struct {
    pub var quit = false;

    pub fn init_backend(title: []const u8, width: u32, height: u32) !void {
        if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
            sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
            return error.SDLInitializationFailed;
        }
        defer sdl.SDL_Quit();

        if (sdl.TTF_Init() != 0) {
            sdl.SDL_Log("Unable to initialize SDL_ttf: %s", sdl.TTF_GetError());
            return error.SDLTTFInitializationFailed;
        }
        defer sdl.TTF_Quit();

        const window = sdl.SDL_CreateWindow(
            title.ptr,
            sdl.SDL_WINDOWPOS_UNDEFINED,
            sdl.SDL_WINDOWPOS_UNDEFINED,
            @intCast(width),
            @intCast(height),
            sdl.SDL_WINDOW_SHOWN,
        ) orelse {
            sdl.SDL_Log("Unable to create window: %s", sdl.SDL_GetError());
            return error.SDLWindowCreationFailed;
        };
        defer sdl.SDL_DestroyWindow(window);

        const renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED) orelse {
            sdl.SDL_Log("Unable to create renderer: %s", sdl.SDL_GetError());
            return error.SDLRendererCreationFailed;
        };
        defer sdl.SDL_DestroyRenderer(renderer);

        const font_path = try sdl_core.setup_font();
        const font = sdl.TTF_OpenFont(font_path.?.ptr, 24) orelse {
            sdl.SDL_Log("Unable to load font: %s", sdl.TTF_GetError());
            return error.SDLFontLoadFailed;
        };
        defer sdl.TTF_CloseFont(font);

        var event: sdl.SDL_Event = undefined;

        while (!quit) {
            while (sdl.SDL_PollEvent(&event) != 0) {
                switch (event.type) {
                    sdl.SDL_QUIT => quit = true,
                    else => {},
                }
            }

            _ = sdl.SDL_SetRenderDrawColor(renderer, 50, 50, 50, 255);
            _ = sdl.SDL_RenderClear(renderer);

            sdl.SDL_RenderPresent(renderer);

            sdl.SDL_Delay(16);
        }
    }
};