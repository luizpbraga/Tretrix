const std = @import("std");
const print = std.debug.print;

const BackGround = struct {
    const Self = @This();
    const MAXROW: usize = 19;
    const MAXCOL: usize = 9;
    // Bg Lines
    lines: [21][10]u8,

    fn print(_: Self) !void {}
    fn clear(_: Self) !void {}
    fn checkLines(_: *Self) !void {}
};

const Action = enum { L, R, D };

const Shape = enum { Square, Tee, Elbow, Bar, Kink };

const Orientation = enum { SO, TO, EO, BO, KO };

const SO = enum { O1 };
const BO = enum { O1, O2 };
const TO = enum { O1, O2, O3, O4 };
const KO = enum { O1, O2, O3, O4 };
const EO = enum { O1, O2, O3, O4, O5, O6, O7, O8 };

const Piece = struct {
    const Self = @This();

    // Characteristics
    shape: Shape,
    action: Action = .D,
    orientation: Orientation = .SO,
    // coordinates
    row: usize = 1,
    col: usize = 0,

    /// Desenha a peça: NAO MODIFICA NADA
    fn draw(_: Self, _: u8) void {}

    /// Apaga a peça
    fn erase(_: Self) void {}

    /// inicia a peça: REGRAS DO JOGO + FíSICA
    fn init(_: *Self) !bool {
        return true;
    }
    /// Le a Açao + Checagem das linhas
    /// Modifica as peças (dentro das regras do s movimentos)
    fn play(_: *Self) !bool {
        return true;
    }
};

pub fn main() !void {
    var piece = Piece{ .shape = .Square };
    _ = piece;
    print("{s}", .{""});
}
