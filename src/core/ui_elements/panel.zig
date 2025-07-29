const std = @import("std");
const Element = @import("../ui_element.zig").Element;
const types = @import("../types.zig");
const Renderer = @import("../renderer.zig").Renderer;

pub const PanelConfig = struct {
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    background_color: types.Color = types.Color.TRANSPARENT,
    border_color: types.Color = types.Color.TRANSPARENT,
    border_width: u32 = 0,
    id: []const u8 = "panel",
};

pub const Panel = struct {
    element: Element,

    pub fn create(allocator: std.mem.Allocator, config: PanelConfig) !Panel {
        var element = Element.init(
            allocator,
            config.id,
            .panel,
            .{ .x = config.x, .y = config.y, .width = config.width, .height = config.height }
        );

        element.background_color = config.background_color;
        element.border_color = config.border_color;
        element.border_width = config.border_width;
        element.render_fn = render;

        return Panel{
            .element = element,
        };
    }

    pub fn deinit(self: *Panel) void {
        self.element.deinit();
    }

    pub fn add_child(self: *Panel, child: *Element) !void {
        try self.element.add_child(child);
    }

    pub fn remove_child(self: *Panel, child: *Element) bool {
        return self.element.remove_child(child);
    }

    fn render(element: *Element, renderer: *anyopaque) void {
        const zinc_renderer = @as(*Renderer, @ptrCast(@alignCast(renderer)));

        if (element.background_color.a > 0) {
            zinc_renderer.fill_rect(element.rect, element.background_color);
        }

        if (element.border_width > 0 and element.border_color.a > 0) {
            for (0..element.border_width) |i| {
                const border_rect = types.Rect{
                    .x = element.rect.x - @as(i32, @intCast(i)),
                    .y = element.rect.y - @as(i32, @intCast(i)),
                    .width = element.rect.width + @as(u32, @intCast(i * 2)),
                    .height = element.rect.height + @as(u32, @intCast(i * 2)),
                };
                zinc_renderer.draw_rect(border_rect, element.border_color);
            }
        }
    }
};