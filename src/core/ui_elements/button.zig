const std = @import("std");
const Element = @import("../ui_element.zig").Element;
const types = @import("../types.zig");
const EventBus = @import("../event_bus.zig").EventBus;
const Renderer = @import("../renderer.zig").Renderer;

pub const ButtonConfig = struct {
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    text: []const u8,
    id: []const u8,
    background_color: ?types.Color = null,
    text_color: ?types.Color = null,
    border_color: ?types.Color = null,
    border_width: u32 = 1,
};

pub const Button = struct {
    element: Element,
    text: []const u8,
    is_hovered: bool = false,
    is_pressed: bool = false,
    text_color: types.Color,

    pub fn create(allocator: std.mem.Allocator, config: ButtonConfig) !Button {
        var element = Element.init(
            allocator,
            config.id,
            .button,
            .{ .x = config.x, .y = config.y, .width = config.width, .height = config.height }
        );

        element.background_color = config.background_color orelse types.Color{ .r = 100, .g = 100, .b = 100 };
        element.border_color = config.border_color orelse types.Color{ .r = 150, .g = 150, .b = 150 };
        element.border_width = config.border_width;
        element.render_fn = render;
        element.handle_event_fn = handle_event;

        return Button{
            .element = element,
            .text = config.text,
            .text_color = config.text_color orelse types.Color.WHITE,
        };
    }

    pub fn deinit(self: *Button) void {
        self.element.deinit();
    }

    pub fn set_hover(self: *Button, hovered: bool) void {
        self.is_hovered = hovered;
    }

    pub fn set_pressed(self: *Button, pressed: bool) void {
        self.is_pressed = pressed;
    }

    fn render(element: *Element, renderer: *anyopaque) void {
        const zinc_renderer = @as(*Renderer, @ptrCast(@alignCast(renderer)));
        const button = @as(*Button, @fieldParentPtr("element", element));

        var bg_color = element.background_color;
        if (button.is_pressed) {
            bg_color.r = @max(0, bg_color.r -| 30);
            bg_color.g = @max(0, bg_color.g -| 30);
            bg_color.b = @max(0, bg_color.b -| 30);
        } else if (button.is_hovered) {
            bg_color.r = @min(255, bg_color.r + 20);
            bg_color.g = @min(255, bg_color.g + 20);
            bg_color.b = @min(255, bg_color.b + 20);
        }

        zinc_renderer.fill_rect(element.rect, bg_color);

        if (element.border_width > 0) {
            zinc_renderer.draw_rect(element.rect, element.border_color);
        }

        zinc_renderer.render_text_centered(button.text, element.rect, button.text_color);
    }

    fn handle_event(element: *Element, event: *anyopaque) bool {
        _ = event;
        const button = @as(*Button, @fieldParentPtr("element", element));
        _ = button;
        return false;
    }

    pub fn set_text(self: *Button, text: []const u8) void {
        self.text = text;
    }

    pub fn on_click(self: *Button) void {
        if (self.element.event_bus) |bus| {
            bus.emit_button_click(self.element.id, 0, 0);
        }
    }
};