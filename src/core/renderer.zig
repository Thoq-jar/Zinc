const std = @import("std");
const sdl = @import("sdl_core.zig").sdl;
const types = @import("types.zig");

pub const Renderer = struct {
    sdl_renderer: *sdl.SDL_Renderer,
    font: *sdl.TTF_Font,

    pub fn init(sdl_renderer: *sdl.SDL_Renderer, font: *sdl.TTF_Font) Renderer {
        return Renderer{
            .sdl_renderer = sdl_renderer,
            .font = font,
        };
    }

    pub fn set_draw_color(self: *Renderer, color: types.Color) void {
        _ = sdl.SDL_SetRenderDrawColor(self.sdl_renderer, color.r, color.g, color.b, color.a);
    }

    pub fn clear(self: *Renderer) void {
        _ = sdl.SDL_RenderClear(self.sdl_renderer);
    }

    pub fn present(self: *Renderer) void {
        sdl.SDL_RenderPresent(self.sdl_renderer);
    }

    pub fn fill_rect(self: *Renderer, rect: types.Rect, color: types.Color) void {
        self.set_draw_color(color);
        const sdl_rect = sdl.SDL_Rect{
            .x = rect.x,
            .y = rect.y,
            .w = @intCast(rect.width),
            .h = @intCast(rect.height),
        };
        _ = sdl.SDL_RenderFillRect(self.sdl_renderer, &sdl_rect);
    }

    pub fn draw_rect(self: *Renderer, rect: types.Rect, color: types.Color) void {
        self.set_draw_color(color);
        const sdl_rect = sdl.SDL_Rect{
            .x = rect.x,
            .y = rect.y,
            .w = @intCast(rect.width),
            .h = @intCast(rect.height),
        };
        _ = sdl.SDL_RenderDrawRect(self.sdl_renderer, &sdl_rect);
    }

    pub fn render_text(self: *Renderer, text: []const u8, x: i32, y: i32, color: types.Color) void {
        if (text.len == 0) return;

        const sdl_color = sdl.SDL_Color{
            .r = color.r,
            .g = color.g,
            .b = color.b,
            .a = color.a,
        };

        const surface = sdl.TTF_RenderText_Blended(self.font, text.ptr, sdl_color) orelse return;
        defer sdl.SDL_FreeSurface(surface);

        const texture = sdl.SDL_CreateTextureFromSurface(self.sdl_renderer, surface) orelse return;
        defer sdl.SDL_DestroyTexture(texture);

        const text_rect = sdl.SDL_Rect{
            .x = x,
            .y = y,
            .w = surface.*.w,
            .h = surface.*.h,
        };
        _ = sdl.SDL_RenderCopy(self.sdl_renderer, texture, null, &text_rect);
    }

    pub fn render_text_centered(self: *Renderer, text: []const u8, rect: types.Rect, color: types.Color) void {
        if (text.len == 0) return;

        var w: c_int = undefined;
        var h: c_int = undefined;
        _ = sdl.TTF_SizeText(self.font, text.ptr, &w, &h);

        const text_x = rect.x + @divFloor(@as(i32, @intCast(rect.width)) - w, 2);
        const text_y = rect.y + @divFloor(@as(i32, @intCast(rect.height)) - h, 2);

        self.render_text(text, text_x, text_y, color);
    }

    pub fn get_text_size(self: *Renderer, text: []const u8) types.Point {
        var w: c_int = undefined;
        var h: c_int = undefined;
        _ = sdl.TTF_SizeText(self.font, text.ptr, &w, &h);
        return types.Point{ .x = w, .y = h };
    }
};