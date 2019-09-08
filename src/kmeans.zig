const std = @import("std");
const mem = std.mem;
const math = std.math;
const assert = std.debug.assert;

const Allocator = mem.Allocator;
const Random = std.rand.Random;

const ClusteringError = error{NoPointsForCentroid};

pub fn ClusteringInterface(comptime T: type) type {
    return struct {
        /// Takes a point `p1` and a point `p2` and calculates the distance between them.
        distanceToFn: fn (p1: T, p2: T) f32,

        /// Defines how to add one point to another. Modifies `aggregate_p`.
        aggregateFn: fn (aggregate_p: *T, added_p: T) void,

        /// Divides the aggregate point by the number of points in the set.
        divideAggregateFn: fn (p: *T, number_of_points: usize) void,

        /// Represents the empty element, useful as a starting aggregate element.
        zero_element: T,
    };
}

pub fn kmeans(
    allocator: *mem.Allocator,
    random: *Random,
    comptime T: type,
    comptime clusteringInterface: ClusteringInterface(T),
    data: []T,
    number_of_clusters: usize,
) ![]T {
    const centroids = try randomData(allocator, random, T, data, number_of_clusters);
    try calculateClusters(T, clusteringInterface, data, centroids);

    return centroids;
}

pub const Point2 = struct {
    const Self = @This();

    x: f32,
    y: f32,
    closest_centroid: ?*Self = null,

    pub fn distanceTo(self: Self, other: Self) f32 {
        const x_diff = self.x - other.x;
        const y_diff = self.y - other.y;
        const x_square = x_diff * x_diff;
        const y_square = y_diff * y_diff;

        return math.sqrt(x_square + y_square);
    }

    pub fn aggregate(p1: *Self, p2: Self) void {
        p1.x += p2.x;
        p1.y += p2.y;
    }

    pub fn divideAggregate(p: *Self, number_of_points: usize) void {
        p.x /= @intToFloat(f32, number_of_points);
        p.y /= @intToFloat(f32, number_of_points);
    }
};

pub const Point3 = struct {
    const Self = @This();

    x: f32,
    y: f32,
    z: f32,
    closest_centroid: ?*Self = null,

    pub fn distanceTo(self: Self, other: Self) f32 {
        const x_diff = self.x - other.x;
        const y_diff = self.y - other.y;
        const z_diff = self.z - other.z;
        const x_square = x_diff * x_diff;
        const y_square = y_diff * y_diff;
        const z_square = z_diff * z_diff;

        return math.sqrt(x_square + y_square + z_square);
    }

    pub fn aggregate(p1: *Self, p2: Self) void {
        p1.x += p2.x;
        p1.y += p2.y;
        p1.z += p2.z;
    }

    pub fn divideAggregate(p: *Self, number_of_points: usize) void {
        p.x /= @intToFloat(f32, number_of_points);
        p.y /= @intToFloat(f32, number_of_points);
        p.z /= @intToFloat(f32, number_of_points);
    }
};

fn randomData(
    allocator: *Allocator,
    random: *Random,
    comptime T: type,
    points: []const T,
    n: usize,
) ![]T {
    if (n > points.len) {
        return error.NotEnoughPoints;
    } else if (n == points.len) {
        var random_points = try allocator.alloc(T, n);
        mem.copy(T, random_points, points);

        return random_points;
    } else {
        var random_points = try allocator.alloc(T, n);
        errdefer allocator.free(random_points);
        var new_indices = try allocator.alloc(?usize, n);
        defer allocator.free(new_indices);

        for (random_points) |v, i| {
            new_indices[i] = null;
        }
        var new_points: usize = 0;

        while (new_points < n) {
            const random_index = random.uintLessThan(usize, points.len);
            for (new_indices) |new_index| {
                if (new_index) |ni| {
                    if (random_index == ni) {
                        break;
                    }
                } else {
                    random_points[new_points] = points[random_index];
                    new_indices[new_points] = random_index;
                    new_points += 1;
                    break;
                }
            }
        }

        return random_points;
    }
}

fn calculateClusters(
    comptime T: type,
    comptime clusteringInterface: ClusteringInterface(T),
    points: []T,
    centroids: []T,
) !void {
    var centroid_positions_changed = true;

    while (centroid_positions_changed) {
        for (points) |*p| {
            p.closest_centroid = closestPtr(T, p.*, centroids, clusteringInterface.distanceToFn);
        }

        centroid_positions_changed = false;
        for (centroids) |*c| {
            const centroid_mean = try centroidMean(T, clusteringInterface, c.*, points);
            if (c.x != centroid_mean.x or c.y != centroid_mean.y) {
                centroid_positions_changed = true;
                c.x = centroid_mean.x;
                c.y = centroid_mean.y;
            }
        }
    }
}

fn closestPtr(
    comptime T: type,
    p1: T,
    points: []T,
    comptime distanceToFn: fn (p1: T, p2: T) f32,
) *T {
    var closest_point_index: usize = 0;
    for (points) |p, i| {
        if (distanceToFn(p1, p) < distanceToFn(p1, points[closest_point_index])) {
            closest_point_index = i;
        }
    }

    return &points[closest_point_index];
}

fn centroidMean(
    comptime T: type,
    comptime clusteringInterface: ClusteringInterface(T),
    centroid: T,
    points: []const T,
) !T {
    if (points.len == 0) {
        return error.NoPointsForCentroid;
    }

    var aggregate_point = clusteringInterface.zero_element;
    for (points) |p| {
        if (p.closest_centroid == &centroid) {
            clusteringInterface.aggregateFn(&aggregate_point, p);
        }
    }
    clusteringInterface.divideAggregateFn(&aggregate_point, points.len);

    return aggregate_point;
}
