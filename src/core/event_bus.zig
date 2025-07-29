const std = @import("std");
const ArrayList = std.ArrayList;

pub const EventType = enum {
    button_click,
    text_change,
    key_press,
    mouse_move,
    mouse_click,
    window_resize,
    custom,
};

pub const ButtonClickData = struct {
    button_id: []const u8,
    mouse_x: i32,
    mouse_y: i32,
};

pub const TextChangeData = struct {
    element_id: []const u8,
    new_text: []const u8,
    old_text: []const u8,
};

pub const KeyPressData = struct {
    key_code: u32,
    is_repeat: bool,
};

pub const MouseMoveData = struct {
    x: i32,
    y: i32,
    relative_x: i32,
    relative_y: i32,
};

pub const MouseClickData = struct {
    x: i32,
    y: i32,
    button: u8,
};

pub const WindowResizeData = struct {
    new_width: u32,
    new_height: u32,
};

pub const CustomEventData = struct {
    name: []const u8,
    data: ?*anyopaque,
};

pub const EventData = union(EventType) {
    button_click: ButtonClickData,
    text_change: TextChangeData,
    key_press: KeyPressData,
    mouse_move: MouseMoveData,
    mouse_click: MouseClickData,
    window_resize: WindowResizeData,
    custom: CustomEventData,
};

pub const Event = struct {
    event_type: EventType,
    data: EventData,
    timestamp: i64,
};

pub const EventHandler = struct {
    callback: *const fn (event: Event, user_data: ?*anyopaque) void,
    user_data: ?*anyopaque = null,
};

pub const EventBus = struct {
    allocator: std.mem.Allocator,
    handlers: std.StringHashMap(ArrayList(EventHandler)),

    pub fn init(allocator: std.mem.Allocator) EventBus {
        return EventBus{
            .allocator = allocator,
            .handlers = std.StringHashMap(ArrayList(EventHandler)).init(allocator),
        };
    }

    pub fn deinit(self: *EventBus) void {
        var iterator = self.handlers.iterator();
        while (iterator.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.handlers.deinit();
    }

    pub fn subscribe(self: *EventBus, event_name: []const u8, handler: EventHandler) !void {
        const result = try self.handlers.getOrPut(event_name);
        if (!result.found_existing) {
            result.value_ptr.* = ArrayList(EventHandler).init(self.allocator);
        }
        try result.value_ptr.append(handler);
    }

    pub fn unsubscribe(self: *EventBus, event_name: []const u8, handler: EventHandler) bool {
        if (self.handlers.getPtr(event_name)) |handlers_list| {
            for (handlers_list.items, 0..) |existing_handler, i| {
                if (existing_handler.callback == handler.callback and
                    existing_handler.user_data == handler.user_data) {
                    _ = handlers_list.orderedRemove(i);
                    return true;
                }
            }
        }
        return false;
    }

    pub fn emit(self: *EventBus, event_name: []const u8, event: Event) void {
        if (self.handlers.get(event_name)) |handlers_list| {
            for (handlers_list.items) |handler| {
                handler.callback(event, handler.user_data);
            }
        }
    }

    pub fn emit_button_click(self: *EventBus, button_id: []const u8, mouse_x: i32, mouse_y: i32) void {
        const event = Event{
            .event_type = .button_click,
            .data = .{ .button_click = .{ .button_id = button_id, .mouse_x = mouse_x, .mouse_y = mouse_y } },
            .timestamp = std.time.milliTimestamp(),
        };
        self.emit("button_click", event);
    }

    pub fn emit_text_change(self: *EventBus, element_id: []const u8, new_text: []const u8, old_text: []const u8) void {
        const event = Event{
            .event_type = .text_change,
            .data = .{ .text_change = .{ .element_id = element_id, .new_text = new_text, .old_text = old_text } },
            .timestamp = std.time.milliTimestamp(),
        };
        self.emit("text_change", event);
    }
};