const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_mod.addImport("zinc", lib_mod);

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "zinc",
        .root_module = lib_mod,
    });

    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "zinc",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    exe.linkLibC();

    // Use specific SDL2 library paths to avoid duplicates
    exe.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include/SDL2" });
    exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });

    // Link to specific library files instead of using linkSystemLibrary
    exe.addObjectFile(.{ .cwd_relative = "/opt/homebrew/lib/libSDL2.dylib" });
    exe.addObjectFile(.{ .cwd_relative = "/opt/homebrew/lib/libSDL2_ttf.dylib" });

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}