const std = @import("std");
const ArrayList = std.ArrayList;
const types = @import("types.zig");
const EventBus = @import("event_bus.zig").EventBus;

pub const Element = struct {
    id: []const u8,
    element_type: types.ElementType,
    rect: types.Rect,
    visible: bool = true,
    enabled: bool = true,
    background_color: types.Color = types.Color.TRANSPARENT,
    border_color: types.Color = types.Color.TRANSPARENT,
    border_width: u32 = 0,
    parent: ?*Element = null,
    children: ArrayList(*Element),
    event_bus: ?*EventBus = null,
    render_fn: ?*const fn (self: *Element, renderer: *anyopaque) void = null,
    handle_event_fn: ?*const fn (self: *Element, event: *anyopaque) bool = null,
    update_fn: ?*const fn (self: *Element) void = null,

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, id: []const u8, element_type: types.ElementType, rect: types.Rect) Element {
        return Element{
            .id = id,
            .element_type = element_type,
            .rect = rect,
            .children = ArrayList(*Element).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Element) void {
        self.children.deinit();
    }

    pub fn add_child(self: *Element, child: *Element) !void {
        try self.children.append(child);
        child.parent = self;
        child.event_bus = self.event_bus;
    }

    pub fn remove_child(self: *Element, child: *Element) bool {
        for (self.children.items, 0..) |existing_child, i| {
            if (existing_child == child) {
                _ = self.children.orderedRemove(i);
                child.parent = null;
                return true;
            }
        }
        return false;
    }

    pub fn render(self: *Element, renderer: *anyopaque) void {
        if (!self.visible) return;

        if (self.render_fn) |render_func| {
            render_func(self, renderer);
        }

        for (self.children.items) |child| {
            child.render(renderer);
        }
    }

    pub fn handle_event(self: *Element, event: *anyopaque) bool {
        if (!self.enabled) return false;

        if (self.handle_event_fn) |handle_func| {
            if (handle_func(self, event)) return true;
        }

        for (self.children.items) |child| {
            if (child.handle_event(event)) return true;
        }

        return false;
    }

    pub fn update(self: *Element) void {
        if (self.update_fn) |update_func| {
            update_func(self);
        }

        for (self.children.items) |child| {
            child.update();
        }
    }

    pub fn contains_point(self: *Element, x: i32, y: i32) bool {
        return x >= self.rect.x and x < self.rect.x + @as(i32, @intCast(self.rect.width)) and
            y >= self.rect.y and y < self.rect.y + @as(i32, @intCast(self.rect.height));
    }

    pub fn set_position(self: *Element, x: i32, y: i32) void {
        self.rect.x = x;
        self.rect.y = y;
    }

    pub fn set_size(self: *Element, width: u32, height: u32) void {
        self.rect.width = width;
        self.rect.height = height;
    }
};