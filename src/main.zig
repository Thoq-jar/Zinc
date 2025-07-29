const std = @import("std");
const zinc = @import("zinc");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var app = try zinc.Application.init(allocator, .{
        .title = "Zinc UI Demo",
        .width = 800,
        .height = 600,
        .dark_mode = true,
    });
    defer app.deinit();

    const button_click_handler = zinc.EventHandler{
        .callback = onButtonClick,
        .user_data = null,
    };

    const text_change_handler = zinc.EventHandler{
        .callback = onTextChange,
        .user_data = null,
    };

    try app.event_bus.subscribe("button_click", button_click_handler);
    try app.event_bus.subscribe("text_change", text_change_handler);

    var main_panel = try zinc.Panel.create(allocator, .{
        .x = 0, .y = 0, .width = 800, .height = 600,
        .background_color = if (app.theme.is_dark) .{ .r = 30, .g = 30, .b = 30, .a = 255 } else .{ .r = 240, .g = 240, .b = 240, .a = 255 },
    });
    defer main_panel.deinit();

    var button1 = try zinc.Button.create(allocator, .{
        .x = 50, .y = 50, .width = 150, .height = 40,
        .text = "Click Me!",
        .id = "btn1",
    });
    defer button1.deinit();

    var button2 = try zinc.Button.create(allocator, .{
        .x = 220, .y = 50, .width = 150, .height = 40,
        .text = "Toggle Theme",
        .id = "theme_btn",
    });
    defer button2.deinit();

    var input_field = try zinc.TextInput.create(allocator, .{
        .x = 50, .y = 120, .width = 320, .height = 30,
        .placeholder = "Enter text here...",
        .id = "input1",
    });
    defer input_field.deinit();

    var label = try zinc.Label.create(allocator, .{
        .x = 50, .y = 170, .width = 320, .height = 25,
        .text = "Hello, Zinc UI!",
        .id = "label1",
    });
    defer label.deinit();

    try main_panel.add_child(&button1.element);
    try main_panel.add_child(&button2.element);
    try main_panel.add_child(&input_field.element);
    try main_panel.add_child(&label.element);

    try app.add_element(&main_panel.element);

    try app.run();
}

fn onButtonClick(event: zinc.Event, user_data: ?*anyopaque) void {
    _ = user_data;
    const button_event = event.data.button_click;

    if (std.mem.eql(u8, button_event.button_id, "btn1")) {
        std.debug.print("Button 1 was clicked!\n", .{});
    } else if (std.mem.eql(u8, button_event.button_id, "theme_btn")) {
        std.debug.print("Theme toggle requested!\n", .{});
    }
}

fn onTextChange(event: zinc.Event, user_data: ?*anyopaque) void {
    _ = user_data;
    const text_event = event.data.text_change;
    std.debug.print("Text changed in {s}: {s}\n", .{ text_event.element_id, text_event.new_text });
}