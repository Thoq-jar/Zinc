const std = @import("std");
pub const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

pub fn setup_font() !?[]const u8 {
    const font_paths = [_][]const u8{
        "/Library/Fonts/SF-Pro.ttf", // macOS
        "/Library/Fonts/SF-Pro-Italic.ttf", // macOS
        "/Library/Fonts/SourceCodePro-Regular.ttf", // macOS
        "/Library/Fonts/SourceCodePro-Bold.ttf", // macOS
        "/Library/Fonts/SourceCodePro-Italic.ttf", // macOS
        "/System/Library/Fonts/SFNS.ttf", // macOS
        "/System/Library/Fonts/SFNSItalic.ttf", // macOS
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", // Linux
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", // Linux
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf", // Linux
        "/usr/share/fonts/truetype/freefont/FreeSans.ttf", // Linux
        "/usr/share/fonts/truetype/ubuntu/Ubuntu-R.ttf", // Linux
        "/usr/share/fonts/adwaita-sans-fonts/AdwaitaSans-Regular.ttf",
        "C:\\Windows\\Fonts\\arial.ttf", // Windows
        "C:\\Windows\\Fonts\\segoeui.ttf", // Windows
        "C:\\Windows\\Fonts\\calibri.ttf", // Windows
        "C:\\Windows\\Fonts\\consola.ttf", // Windows
        "C:\\Windows\\Fonts\\times.ttf", // Windows
    };

    var font_path: ?[]const u8 = null;
    for (font_paths) |path| {
        if (std.fs.accessAbsolute(path, .{})) {
            font_path = path;
            break;
        } else |_| {
            continue;
        }
    }

    if (font_path == null) {
        std.debug.panic("Error: Could not find a suitable system font\n", .{});
        return error.FontNotFound;
    }

    return font_path;
}
