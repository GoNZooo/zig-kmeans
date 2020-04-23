const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const random = std.rand;
const DefaultPrng = random.DefaultPrng;
const warn = std.debug.warn;
const assert = std.debug.assert;

const kmeans = @import("./kmeans.zig");
const Point2 = kmeans.Point2;
const Point3 = kmeans.Point3;
const spng = @import("./spng.zig");

pub fn main() anyerror!void {
    var buf: [8]u8 = undefined;
    try std.crypto.randomBytes(buf[0..]);
    const seed = mem.readIntSliceLittle(u64, buf[0..8]);
    var allocator = &heap.ArenaAllocator.init(heap.page_allocator).allocator;

    var r = &DefaultPrng.init(seed).random;

    var p1 = Point2{ .x = -1, .y = 2 };
    var p2 = Point2{ .x = -1, .y = -1 };
    var p3 = Point2{ .x = 2, .y = 2 };
    var p4 = Point2{ .x = 2, .y = -1 };
    var p5 = Point2{ .x = -1, .y = 0.5 };
    var points = ([_]Point2{ p1, p2, p3, p4, p5 })[0..];

    const centroids = try kmeans.kmeans(
        allocator,
        r,
        Point2,
        kmeans.ClusteringInterface(Point2){
            .distanceToFn = Point2.distanceTo,
            .aggregateFn = Point2.aggregate,
            .divideAggregateFn = Point2.divideAggregate,
            .zero_element = Point2{ .x = 0.0, .y = 0.0 },
        },
        points,
        2,
    );
    for (centroids) |c, i| {
        warn("centroids[{}]: {}\n", .{ i, c });
    }
    for (points) |p, i| {
        warn("kmeans_points[{}]: {}\n", .{ i, p });
    }
}
