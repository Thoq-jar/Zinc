const std = @import("std");

pub const WindowProperties = struct {
    title: []const u8,
    width: u32,
    height: u32,
    dark_mode: bool = true,
};

pub const Rect = struct {
    x: i32,
    y: i32,
    width: u32,
    height: u32,
};

pub const Point = struct {
    x: i32,
    y: i32,
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255,

    pub const BLACK = Color{ .r = 0, .g = 0, .b = 0 };
    pub const WHITE = Color{ .r = 255, .g = 255, .b = 255 };
    pub const RED = Color{ .r = 255, .g = 0, .b = 0 };
    pub const GREEN = Color{ .r = 0, .g = 255, .b = 0 };
    pub const BLUE = Color{ .r = 0, .g = 0, .b = 255 };
    pub const TRANSPARENT = Color{ .r = 0, .g = 0, .b = 0, .a = 0 };
};

pub const ElementType = enum {
    panel,
    button,
    label,
    text_input,
    slider,
    checkbox,
};