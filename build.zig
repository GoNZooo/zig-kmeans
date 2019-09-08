const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    b.setInstallPrefix("./");
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("kmeans", "src/main.zig");
    exe.addLibPath("deps/libspng/lul/Release");
    exe.addLibPath("deps/libspng/zlib-1.2.11/Release");
    exe.addIncludeDir("deps/libspng/zlib-1.2.11");
    exe.addIncludeDir("deps/libspng");
    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("zlib");
    exe.linkSystemLibrary("spng");
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
