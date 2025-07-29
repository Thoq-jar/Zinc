const std = @import("std");
const Element = @import("../ui_element.zig").Element;
const types = @import("../types.zig");
const Renderer = @import("../renderer.zig").Renderer;

pub const LabelConfig = struct {
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    text: []const u8,
    id: []const u8,
    text_color: ?types.Color = null,
    background_color: ?types.Color = null,
    font_size: u32 = 16,
};

pub const Label = struct {
    element: Element,
    text: []const u8,
    text_color: types.Color,
    font_size: u32,

    pub fn create(allocator: std.mem.Allocator, config: LabelConfig) !Label {
        var element = Element.init(
            allocator,
            config.id,
            .label,
            .{ .x = config.x, .y = config.y, .width = config.width, .height = config.height }
        );

        element.background_color = config.background_color orelse types.Color.TRANSPARENT;
        element.render_fn = render;

        return Label{
            .element = element,
            .text = config.text,
            .text_color = config.text_color orelse types.Color{ .r = 255, .g = 255, .b = 255 },
            .font_size = config.font_size,
        };
    }

    pub fn deinit(self: *Label) void {
        self.element.deinit();
    }

    fn render(element: *Element, renderer: *anyopaque) void {
        const zinc_renderer = @as(*Renderer, @ptrCast(@alignCast(renderer)));
        const label = @as(*Label, @fieldParentPtr("element", element));

        if (element.background_color.a > 0) {
            zinc_renderer.fill_rect(element.rect, element.background_color);
        }

        if (label.text.len > 0) {
            const text_y = element.rect.y + @divFloor(@as(i32, @intCast(element.rect.height)) - zinc_renderer.get_text_size(label.text).y, 2);
            zinc_renderer.render_text(label.text, element.rect.x, text_y, label.text_color);
        }
    }

    pub fn set_text(self: *Label, text: []const u8) void {
        self.text = text;
    }

    pub fn set_text_color(self: *Label, color: types.Color) void {
        self.text_color = color;
    }
};