const std = @import("std");
const Color = @import("types.zig").Color;

pub const Theme = struct {
    is_dark: bool,
    background: Color,
    surface: Color,
    primary: Color,
    secondary: Color,
    accent: Color,
    text_primary: Color,
    text_secondary: Color,
    border: Color,
    hover: Color,
    active: Color,

    pub const LIGHT = Theme{
        .is_dark = false,
        .background = .{ .r = 240, .g = 240, .b = 240 },
        .surface = .{ .r = 255, .g = 255, .b = 255 },
        .primary = .{ .r = 0, .g = 122, .b = 255 },
        .secondary = .{ .r = 88, .g = 86, .b = 214 },
        .accent = .{ .r = 138, .g = 43, .b = 226 },
        .text_primary = .{ .r = 0, .g = 0, .b = 0 },
        .text_secondary = .{ .r = 60, .g = 60, .b = 67 },
        .border = .{ .r = 198, .g = 198, .b = 200 },
        .hover = .{ .r = 220, .g = 220, .b = 220 },
        .active = .{ .r = 200, .g = 200, .b = 200 },
    };

    pub const DARK = Theme{
        .is_dark = true,
        .background = .{ .r = 30, .g = 30, .b = 30 },
        .surface = .{ .r = 45, .g = 45, .b = 45 },
        .primary = .{ .r = 10, .g = 132, .b = 255 },
        .secondary = .{ .r = 98, .g = 96, .b = 224 },
        .accent = .{ .r = 138, .g = 43, .b = 226 },
        .text_primary = .{ .r = 255, .g = 255, .b = 255 },
        .text_secondary = .{ .r = 174, .g = 174, .b = 178 },
        .border = .{ .r = 70, .g = 70, .b = 70 },
        .hover = .{ .r = 60, .g = 60, .b = 60 },
        .active = .{ .r = 80, .g = 80, .b = 80 },
    };

    pub fn toggle(self: *Theme) void {
        if (self.is_dark) {
            self.* = LIGHT;
        } else {
            self.* = DARK;
        }
    }
};