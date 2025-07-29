const std = @import("std");
const ArrayList = std.ArrayList;
const Element = @import("ui_element.zig").Element;
const EventBus = @import("event_bus.zig").EventBus;
const Theme = @import("theme.zig").Theme;
const types = @import("types.zig");
const Renderer = @import("renderer.zig").Renderer;
const Button = @import("ui_elements/button.zig").Button;
const TextInput = @import("ui_elements/text_input.zig").TextInput;
const sdl = @import("sdl_core.zig").sdl;
const sdl_core = @import("sdl_core.zig");

pub const Application = struct {
    allocator: std.mem.Allocator,
    event_bus: EventBus,
    theme: Theme,
    elements: ArrayList(*Element),
    properties: types.WindowProperties,
    running: bool = false,
    window: ?*sdl.SDL_Window = null,
    sdl_renderer: ?*sdl.SDL_Renderer = null,
    font: ?*sdl.TTF_Font = null,
    renderer: ?Renderer = null,
    focused_element: ?*Element = null,
    mouse_x: i32 = 0,
    mouse_y: i32 = 0,

    pub fn init(allocator: std.mem.Allocator, properties: types.WindowProperties) !Application {
        return Application{
            .allocator = allocator,
            .event_bus = EventBus.init(allocator),
            .theme = if (properties.dark_mode) Theme.DARK else Theme.LIGHT,
            .elements = ArrayList(*Element).init(allocator),
            .properties = properties,
        };
    }

    pub fn deinit(self: *Application) void {
        if (self.font) |font| {
            sdl.TTF_CloseFont(font);
        }
        if (self.sdl_renderer) |renderer| {
            sdl.SDL_DestroyRenderer(renderer);
        }
        if (self.window) |window| {
            sdl.SDL_DestroyWindow(window);
        }
        sdl.TTF_Quit();
        sdl.SDL_Quit();

        self.event_bus.deinit();
        self.elements.deinit();
    }

    pub fn add_element(self: *Application, element: *Element) !void {
        try self.elements.append(element);
        element.event_bus = &self.event_bus;
    }

    pub fn remove_element(self: *Application, element: *Element) bool {
        for (self.elements.items, 0..) |existing_element, i| {
            if (existing_element == element) {
                _ = self.elements.orderedRemove(i);
                element.event_bus = null;
                return true;
            }
        }
        return false;
    }

    pub fn run(self: *Application) !void {
        try self.init_sdl();
        self.running = true;

        var quit = false;
        while (!quit and self.running) {
            var event: sdl.SDL_Event = undefined;
            while (sdl.SDL_PollEvent(&event) != 0) {
                switch (event.type) {
                    sdl.SDL_QUIT => quit = true,
                    sdl.SDL_MOUSEBUTTONDOWN => {
                        self.handle_mouse_button_down(event.button.x, event.button.y, event.button.button);
                    },
                    sdl.SDL_MOUSEBUTTONUP => {
                        self.handle_mouse_button_up(event.button.x, event.button.y, event.button.button);
                    },
                    sdl.SDL_MOUSEMOTION => {
                        self.handle_mouse_motion(event.motion.x, event.motion.y);
                    },
                    sdl.SDL_KEYDOWN => {
                        self.handle_key_down(event.key.keysym.sym);
                    },
                    sdl.SDL_TEXTINPUT => {
                        const text_slice = std.mem.sliceTo(&event.text.text, 0);
                        self.handle_text_input(text_slice);
                    },
                    else => {},
                }
            }

            for (self.elements.items) |element| {
                element.update();
            }

            if (self.renderer) |*renderer| {
                renderer.set_draw_color(self.theme.background);
                renderer.clear();

                for (self.elements.items) |element| {
                    element.render(renderer);
                }

                renderer.present();
            }

            sdl.SDL_Delay(16);
        }
    }

    fn init_sdl(self: *Application) !void {
        if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
            sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        if (sdl.TTF_Init() != 0) {
            sdl.SDL_Log("Unable to initialize SDL_ttf: %s", sdl.TTF_GetError());
            return error.SDLTTFInitializationFailed;
        }

        self.window = sdl.SDL_CreateWindow(
            self.properties.title.ptr,
            sdl.SDL_WINDOWPOS_UNDEFINED,
            sdl.SDL_WINDOWPOS_UNDEFINED,
            @intCast(self.properties.width),
            @intCast(self.properties.height),
            sdl.SDL_WINDOW_SHOWN,
        ) orelse {
            sdl.SDL_Log("Unable to create window: %s", sdl.SDL_GetError());
            return error.SDLWindowCreationFailed;
        };

        self.sdl_renderer = sdl.SDL_CreateRenderer(self.window, -1, sdl.SDL_RENDERER_ACCELERATED) orelse {
            sdl.SDL_Log("Unable to create renderer: %s", sdl.SDL_GetError());
            return error.SDLRendererCreationFailed;
        };

        const font_path = try sdl_core.setup_font();
        self.font = sdl.TTF_OpenFont(font_path.?.ptr, 16) orelse {
            sdl.SDL_Log("Unable to load font: %s", sdl.TTF_GetError());
            return error.SDLFontLoadFailed;
        };

        self.renderer = Renderer.init(self.sdl_renderer.?, self.font.?);

        sdl.SDL_StartTextInput();
    }

    fn handle_mouse_button_down(self: *Application, x: i32, y: i32, button: u8) void {
        self.mouse_x = x;
        self.mouse_y = y;

        if (button == sdl.SDL_BUTTON_LEFT) {
            if (self.focused_element) |focused| {
                self.clear_element_focus(focused);
            }

            for (self.elements.items) |element| {
                if (self.handle_element_mouse_down(element, x, y)) {
                    break;
                }
            }
        }
    }

    fn handle_mouse_button_up(self: *Application, x: i32, y: i32, button: u8) void {
        if (button == sdl.SDL_BUTTON_LEFT) {
            for (self.elements.items) |element| {
                self.handle_element_mouse_up(element, x, y);
            }
        }
    }

    fn handle_mouse_motion(self: *Application, x: i32, y: i32) void {
        self.mouse_x = x;
        self.mouse_y = y;

        for (self.elements.items) |element| {
            self.handle_element_mouse_motion(element, x, y);
        }
    }

    fn handle_element_mouse_down(self: *Application, element: *Element, x: i32, y: i32) bool {
        if (element.contains_point(x, y)) {
            switch (element.element_type) {
                .button => {
                    const button = @as(*Button, @fieldParentPtr("element", element));
                    button.set_pressed(true);
                    return true;
                },
                .text_input => {
                    const text_input = @as(*TextInput, @fieldParentPtr("element", element));
                    text_input.set_focus(true);
                    text_input.set_theme(&self.theme);
                    self.focused_element = element;
                    return true;
                },
                else => {},
            }
        }

        for (element.children.items) |child| {
            if (self.handle_element_mouse_down(child, x, y)) {
                return true;
            }
        }

        return false;
    }

    fn handle_element_mouse_up(self: *Application, element: *Element, x: i32, y: i32) void {
        switch (element.element_type) {
            .button => {
                const button = @as(*Button, @fieldParentPtr("element", element));
                if (button.is_pressed and element.contains_point(x, y)) {
                    self.event_bus.emit_button_click(element.id, x, y);
                }
                button.set_pressed(false);
            },
            else => {},
        }

        for (element.children.items) |child| {
            self.handle_element_mouse_up(child, x, y);
        }
    }

    fn handle_element_mouse_motion(self: *Application, element: *Element, x: i32, y: i32) void {
        switch (element.element_type) {
            .button => {
                const button = @as(*Button, @fieldParentPtr("element", element));
                button.set_hover(element.contains_point(x, y));
            },
            else => {},
        }

        for (element.children.items) |child| {
            self.handle_element_mouse_motion(child, x, y);
        }
    }

    fn handle_key_down(self: *Application, key: i32) void {
        switch (key) {
            sdl.SDLK_BACKSPACE => {
                if (self.focused_element) |focused| {
                    if (focused.element_type == .text_input) {
                        const text_input = @as(*TextInput, @fieldParentPtr("element", focused));
                        text_input.backspace();
                    }
                }
            },
            sdl.SDLK_TAB => {
                self.cycle_focus();
            },
            else => {},
        }
    }

    fn handle_text_input(self: *Application, text: []const u8) void {
        if (self.focused_element) |focused| {
            if (focused.element_type == .text_input) {
                const text_input = @as(*TextInput, @fieldParentPtr("element", focused));
                for (text) |char| {
                    text_input.append_char(char) catch break;
                }
            }
        }
    }

    fn clear_element_focus(self: *Application, element: *Element) void {
        switch (element.element_type) {
            .text_input => {
                const text_input = @as(*TextInput, @fieldParentPtr("element", element));
                text_input.set_focus(false);
            },
            else => {},
        }

        for (element.children.items) |child| {
            self.clear_element_focus(child);
        }
    }

    fn cycle_focus(self: *Application) void {
        if (self.focused_element) |current| {
            self.clear_element_focus(current);
            self.focused_element = null;

            var found_current = false;
            for (self.elements.items) |element| {
                if (self.find_next_focusable(element, current, &found_current)) |next| {
                    self.focused_element = next;
                    break;
                }
            }
        }
    }

    fn find_next_focusable(self: *Application, element: *Element, current: *Element, found_current: *bool) ?*Element {
        if (element == current) {
            found_current.* = true;
            return null;
        }

        if (found_current.* and element.element_type == .text_input) {
            const text_input = @as(*TextInput, @fieldParentPtr("element", element));
            text_input.set_focus(true);
            text_input.set_theme(&self.theme);
            return element;
        }

        for (element.children.items) |child| {
            if (self.find_next_focusable(child, current, found_current)) |next| {
                return next;
            }
        }

        return null;
    }

    pub fn stop(self: *Application) void {
        self.running = false;
    }

    pub fn toggle_theme(self: *Application) void {
        self.theme.toggle();
        for (self.elements.items) |element| {
            self.update_element_theme(element);
        }
    }

    fn update_element_theme(self: *Application, element: *Element) void {
        switch (element.element_type) {
            .panel => {
                element.background_color = self.theme.surface;
            },
            .button => {
                element.background_color = self.theme.primary;
                element.border_color = self.theme.border;
            },
            .text_input => {
                element.background_color = self.theme.surface;
                element.border_color = self.theme.border;
                const text_input = @as(*TextInput, @fieldParentPtr("element", element));
                text_input.set_theme(&self.theme);
            },
            else => {},
        }

        for (element.children.items) |child| {
            self.update_element_theme(child);
        }
    }
};