const StopCondition = struct {
    n_iterations: ?usize = 1000,
    epsilon_from_root: ?f32 = 1e-15,
};

fn shouldStop(x: f32, n_iterations: usize, stop_condition: StopCondition, func: fn (f32) f32) bool {
    if (stop_condition.n_iterations) |n_iterations_to_stop| {
        if (n_iterations_to_stop <= n_iterations) {
            return true;
        }
    }
    if (stop_condition.epsilon_from_root) |epsilon_from_root| {
        if (@abs(func(x)) <= epsilon_from_root) {
            return true;
        }
    }
    return false;
}

fn newtonRaphsonMethod(x: f32, stop_condition: StopCondition, func: fn (f32) f32, derivative: fn (f32) f32) f32 {
    var n_iterations: usize = 0;
    var guess = x;
    while (!shouldStop(guess, n_iterations, stop_condition, func)) : (n_iterations += 1) {
        guess -= func(guess) / derivative(guess);
    }
    return guess;
}

const std = @import("std");
const expectApproxEqAbs = std.testing.expectApproxEqAbs;

test "NewtonRaphsonMethod" {
    try expectApproxEqAbs(
        1.4142135623730951,
        newtonRaphsonMethod(
            1,
            .{
                .epsilon_from_root = 0.0001,
                .n_iterations = 10,
            },
            (struct {
                fn func(x: f32) f32 {
                    return x * x - 2;
                }
            }).func,
            (struct {
                fn derivative(x: f32) f32 {
                    return 2 * x;
                }
            }).derivative,
        ),
        0.0001,
    );

    try expectApproxEqAbs(
        2,
        newtonRaphsonMethod(
            1,
            .{
                .epsilon_from_root = 0.000001,
                .n_iterations = 100,
            },
            (struct {
                fn func(x: f32) f32 {
                    return x * x - 4;
                }
            }).func,
            (struct {
                fn derivative(x: f32) f32 {
                    return 2 * x;
                }
            }).derivative,
        ),
        0.0001,
    );
}
