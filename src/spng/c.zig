const std = @import("std");
const mem = std.mem;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

const c = @cImport({
    @cInclude("spng.h");
});

pub const Context = c.struct_spng_ctx;

pub const Format = enum(u2) {
    RGBA8 = 1,
    RGBA16 = 2,
};

pub const DecodeFlags = packed struct {
    use_trns: u1 = 0,
    use_gama: u1 = 0,
    __padding_1__: u1 = 0,
    use_sbit: u1 = 0,
    __padding_rest__: u28 = 0,

    fn toInt(self: @This()) u8 {
        return mem.asBytes(&self)[0];
    }
};

test "`DecodeFlags.toInt`" {
    const flags0 = DecodeFlags{};
    const flags1 = DecodeFlags{ .use_trns = 1 };
    const flags2 = DecodeFlags{ .use_gama = 1 };
    const flags8 = DecodeFlags{ .use_sbit = 1 };
    const flags9 = DecodeFlags{ .use_trns = 1, .use_sbit = 1 };

    expectEqual(flags0.toInt(), 0);
    expectEqual(flags1.toInt(), 1);
    expectEqual(flags2.toInt(), 2);
    expectEqual(flags8.toInt(), 8);
    expectEqual(flags9.toInt(), 9);
}

pub fn newContext() ?*Context {
    return c.spng_ctx_new(0);
}

pub fn freeContext(context: *Context) void {
    return c.spng_ctx_free(context);
}

pub fn setPngBuffer(context: *Context, buffer: []u8) c_int {
    return c.spng_set_png_buffer(context, buffer.ptr, buffer.len);
}

pub fn decodedImageSize(context: *Context, format: Format, out_size: *usize) c_int {
    return c.spng_decoded_image_size(context, @enumToInt(format), out_size);
}

pub fn decodeImage(context: *Context, out: []u8, format: Format, flags: DecodeFlags) c_int {
    return c.spng_decode_image(
        context,
        out.ptr,
        out.len,
        @enumToInt(format),
        flags.toInt(),
    );
}
