const std = @import("std");
const Element = @import("../ui_element.zig").Element;
const types = @import("../types.zig");
const Renderer = @import("../renderer.zig").Renderer;
const Theme = @import("../theme.zig").Theme;

pub const TextInputConfig = struct {
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    placeholder: []const u8 = "",
    id: []const u8,
    background_color: ?types.Color = null,
    text_color: ?types.Color = null,
    border_color: ?types.Color = null,
    border_width: u32 = 1,
    max_length: usize = 256,
};

pub const TextInput = struct {
    element: Element,
    text: std.ArrayList(u8),
    placeholder: []const u8,
    text_color: types.Color,
    placeholder_color: types.Color,
    is_focused: bool = false,
    cursor_position: usize = 0,
    max_length: usize,
    theme: ?*const Theme = null,

    pub fn create(allocator: std.mem.Allocator, config: TextInputConfig) !TextInput {
        var element = Element.init(
            allocator,
            config.id,
            .text_input,
            .{ .x = config.x, .y = config.y, .width = config.width, .height = config.height }
        );

        element.background_color = config.background_color orelse types.Color{ .r = 45, .g = 45, .b = 45 }; // Dark surface
        element.border_color = config.border_color orelse types.Color{ .r = 70, .g = 70, .b = 70 }; // Dark border
        element.border_width = config.border_width;
        element.render_fn = render;
        element.handle_event_fn = handle_event;

        return TextInput{
            .element = element,
            .text = std.ArrayList(u8).init(allocator),
            .placeholder = config.placeholder,
            .text_color = config.text_color orelse types.Color{ .r = 255, .g = 255, .b = 255 }, // White text for dark theme
            .placeholder_color = types.Color{ .r = 174, .g = 174, .b = 178 }, // Light gray for placeholder
            .max_length = config.max_length,
        };
    }

    pub fn deinit(self: *TextInput) void {
        self.text.deinit();
        self.element.deinit();
    }

    pub fn set_theme(self: *TextInput, theme: *const Theme) void {
        self.theme = theme;
        self.element.background_color = theme.surface;
        self.element.border_color = theme.border;
        self.text_color = theme.text_primary;
        self.placeholder_color = theme.text_secondary;
    }

    fn render(element: *Element, renderer: *anyopaque) void {
        const zinc_renderer = @as(*Renderer, @ptrCast(@alignCast(renderer)));
        const text_input = @as(*TextInput, @fieldParentPtr("element", element));

        zinc_renderer.fill_rect(element.rect, element.background_color);

        var border_color = element.border_color;
        if (text_input.is_focused) {
            border_color = if (text_input.theme) |theme| theme.accent else types.Color{ .r = 138, .g = 43, .b = 226 };
        }

        if (element.border_width > 0) {
            zinc_renderer.draw_rect(element.rect, border_color);
        }

        const display_text = if (text_input.text.items.len > 0) text_input.text.items else text_input.placeholder;
        const text_color = if (text_input.text.items.len > 0) text_input.text_color else text_input.placeholder_color;

        if (display_text.len > 0) {
            const text_y = element.rect.y + @divFloor(@as(i32, @intCast(element.rect.height)) - zinc_renderer.get_text_size(display_text).y, 2);
            zinc_renderer.render_text(display_text, element.rect.x + 8, text_y, text_color);
        }

        if (text_input.is_focused) {
            const cursor_x = element.rect.x + 8 + if (text_input.text.items.len > 0) zinc_renderer.get_text_size(text_input.text.items).x else 0;
            const cursor_rect = types.Rect{
                .x = cursor_x,
                .y = element.rect.y + 4,
                .width = 2,
                .height = element.rect.height - 8,
            };
            zinc_renderer.fill_rect(cursor_rect, text_input.text_color);
        }
    }

    fn handle_event(element: *Element, event: *anyopaque) bool {
        _ = event;
        const text_input = @as(*TextInput, @fieldParentPtr("element", element));
        _ = text_input;

        // Keyboard and mouse event handling would be implemented here
        // This would handle text input, cursor movement, selection, etc.
        return false;
    }

    pub fn set_focus(self: *TextInput, focused: bool) void {
        self.is_focused = focused;
    }

    pub fn append_char(self: *TextInput, char: u8) !void {
        if (self.text.items.len < self.max_length) {
            try self.text.append(char);
            self.cursor_position = self.text.items.len;

            if (self.element.event_bus) |bus| {
                bus.emit_text_change(self.element.id, self.text.items, "");
            }
        }
    }

    pub fn backspace(self: *TextInput) void {
        if (self.text.items.len > 0) {
            const old_text = self.element.allocator.dupe(u8, self.text.items) catch return;
            defer self.element.allocator.free(old_text);

            _ = self.text.pop();
            self.cursor_position = self.text.items.len;

            if (self.element.event_bus) |bus| {
                bus.emit_text_change(self.element.id, self.text.items, old_text);
            }
        }
    }

    pub fn set_text(self: *TextInput, text: []const u8) !void {
        self.text.clearRetainingCapacity();
        try self.text.appendSlice(text);
        self.cursor_position = self.text.items.len;

        if (self.element.event_bus) |bus| {
            bus.emit_text_change(self.element.id, self.text.items, "");
        }
    }

    pub fn get_text(self: *TextInput) []const u8 {
        return self.text.items;
    }

    pub fn clear(self: *TextInput) void {
        const old_text = self.element.allocator.dupe(u8, self.text.items) catch return;
        defer self.element.allocator.free(old_text);

        self.text.clearRetainingCapacity();
        self.cursor_position = 0;

        if (self.element.event_bus) |bus| {
            bus.emit_text_change(self.element.id, "", old_text);
        }
    }
};