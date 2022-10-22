// Jogo inicia.
// Peça X é inicializada => Background é atualizado
// Background é printado;
// Acao é linda
// Background é limpado
// Acao é executada =>  A peça X se move => Background é atualizado : substitui o desenho anterior pelo novo
// Background é printado;

// TODO: FUNCAO PRA VERIFICAR AS REGRAS DE MOVIMENTO;;
// TODO: FUNCAO PRA APLICAR TAIS REGRAS DE MOMENTO;;
// TODO: FUNCAO PRA DELETAR O MOVIMENTO ANTERIOR;;
// TODO: FUNCAO PRA ANALiSAR A AçÃO
// TODO: APAGAR OU DESENHAR? ENUM ?
// TODO: COMO ELE VAI RODAR?
// INFO: ENUM + WHILE + RANGENUMBER + SWITCH = play
// INFO: solucao para o problema do "apagamento": struct anonima na  funcao init + destroy
const std = @import("std");
const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut().writer();

/// Avaliable Actions
const Action = enum { Left, Right, Down, JumpToEnd, Rotate, Exit, Pause };
/// Draw or Erase de Shape
const BgShape = enum(u8) { Draw = '#', Erase = '.' };
// square dont rotate ;
const BarOrientation = enum { H, V };
const TeeOrientation = enum { U, D, L, R };
const KinkOrientation = enum { HL, HR, VL, VR };
const ElbowOrientation = enum { HRU, HLU, HRD, HLD, VRU, VLU, VRD, VLD };

const Background = struct {
    const rowMax: usize = 19;
    const colMax: usize = 9;

    lines: [21][10]u8 = .{".".* ** 10} ** 20 ++ .{"#".* ** 10},

    // Print in stdout the Background
    // clear and sleep may be removed in the feature
    fn printBg(self: Background) !void {
        try self.clear(); // talvez remover
        try stdout.print(
            \\+------------------------------+  
            \\| TRETRIX:                     |
            \\| A cmd-line-Zig Tetris Game   | 
            \\+------------------------------+ 
            \\+==============================+
            \\
        , .{});
        for (self.lines) |line, n|
            try stdout.print("{d}       {s}||{s}||\n", .{ n, if (n < 10) " " else "", line });
        try stdout.print("+==============================+\n", .{});
        std.time.sleep(0.5e9); // talvez remover
    }

    fn clear(_: Background) !void {
        const exec = try std.ChildProcess.exec(.{
            .allocator = std.heap.page_allocator,
            .argv = &[_][]const u8{"clear"},
        });
        try stdout.print("{s}", .{exec.stdout});
    }
};

const Piece = struct {
    bar: Bar,
    tee: Tee,
    kink: Kink,
    elbow: Elbow,
    square: Square,
};

// SQUARE
const Square = struct {
    row: usize = 0,
    col: usize = 4,
    char: u8 = '#',

    /// Inicializar o SQUARE no Background: row e col são modificados.
    /// Essa função NUNCA modifica o valor de 'CHAR'.
    /// Função ``destroy`` deve ser chamado após o uso
    fn init(self: *Square, config: struct { row: usize = 0, col: usize = 4, char: u8 = '#' }) void {
        self.col = config.col;
        self.row = config.row;
        bg.lines[self.row][self.col] = config.char;
        bg.lines[self.row][self.col + 1] = config.char;
        bg.lines[self.row + 1][self.col] = config.char;
        bg.lines[self.row + 1][self.col + 1] = config.char;
    }

    fn destroy(self: *Square) void {
        self.init(.{
            .row = self.row,
            .col = self.col,
            .char = '.',
        }); // se nao passar self.row ele usa 0 sempre!
    }
};

// BAR
const Bar = struct {
    col: usize = 3,
    row: usize = 0,
    char: u8 = '#',
    orientation: BarOrientation = .H,

    fn init(self: Bar) void {
        const range = [_]usize{ 0, 1, 2, 3 };
        switch (self.orientation) { // #
            .V => { // #
                for (range) |i| // #
                    bg.lines[self.row + i][self.col] = self.char; // #
            },
            .H => { // ####
                for (range) |i|
                    bg.lines[self.row][self.col + i] = self.char;
            },
        }
    }
};

// TEE
const Tee = struct {
    row: usize = 0,
    col: usize = 4,
    char: u8 = '#',
    orientation: TeeOrientation = .D,

    fn init(self: Tee) void {
        switch (self.orientation) {
            .U => {
                bg.lines[self.row][self.col + 1] = self.char;
                bg.lines[self.row + 1][self.col] = self.char;
                bg.lines[self.row + 1][self.col + 1] = self.char;
                bg.lines[self.row + 1][self.col + 2] = self.char;
            },
            .D => {
                bg.lines[self.row][self.col] = self.char;
                bg.lines[self.row][self.col + 1] = self.char;
                bg.lines[self.row][self.col + 2] = self.char;
                bg.lines[self.row + 1][self.col + 1] = self.char;
            },
            .L => {
                bg.lines[self.row][self.col + 1] = self.char;
                bg.lines[self.row + 1][self.col] = self.char;
                bg.lines[self.row + 1][self.col + 1] = self.char;
                bg.lines[self.row + 2][self.col + 1] = self.char;
            },
            .R => {
                bg.lines[self.row][self.col] = self.char;
                bg.lines[self.row + 1][self.col] = self.char;
                bg.lines[self.row + 1][self.col + 1] = self.char;
                bg.lines[self.row + 2][self.col] = self.char;
            },
        }
    }
};

// KINK
const Kink = struct {
    row: usize = 0,
    col: usize = 4,
    char: u8 = '#',
    orientation: KinkOrientation = .VL,

    fn init(self: Kink) void {
        switch (self.orientation) {
            .VL => {
                // #
                // ##
                //  #
                bg.lines[self.row][self.col] = self.char;
                bg.lines[self.row + 1][self.col] = self.char;
                bg.lines[self.row + 1][self.col + 1] = self.char;
                bg.lines[self.row + 2][self.col + 1] = self.char;
            },
            .VR => {
                //  #
                // ##
                // #
                bg.lines[self.row][self.col + 1] = self.char;
                bg.lines[self.row + 1][self.col] = self.char;
                bg.lines[self.row + 1][self.col + 1] = self.char;
                bg.lines[self.row + 2][self.col] = self.char;
            },
            .HL => {
                // ##
                //  ##
                bg.lines[self.row][self.col] = self.char;
                bg.lines[self.row][self.col + 1] = self.char;
                bg.lines[self.row + 1][self.col + 1] = self.char;
                bg.lines[self.row + 1][self.col + 2] = self.char;
            },
            .HR => {
                //  ##
                // ##
                bg.lines[self.row][self.col + 1] = self.char;
                bg.lines[self.row][self.col + 2] = self.char;
                bg.lines[self.row + 1][self.col] = self.char;
                bg.lines[self.row + 1][self.col + 1] = self.char;
            },
        }
        bg.lines[self.row + 1][self.col + 1] = self.char;
    }
};

const Elbow = struct {
    col: usize = 3,
    row: usize = 0,
    char: u8 = '#',
    orientation: ElbowOrientation = .HLD,

    fn init(self: Elbow) void {
        //const range = [_]usize{ 0, 1, 2 };
        switch (self.orientation) {
            // diferem na segunda coluna
            .VRD => {
                bg.lines[self.row][self.col] = self.char;
                bg.lines[self.row + 1][self.col] = self.char;
                bg.lines[self.row + 2][self.col] = self.char;
                bg.lines[self.row + 2][self.col + 1] = self.char; // !
            },
            .VRU => {
                bg.lines[self.row][self.col] = self.char;
                bg.lines[self.row][self.col + 1] = self.char; // !
                bg.lines[self.row + 1][self.col] = self.char;
                bg.lines[self.row + 2][self.col] = self.char;
            },
            // diferem na primeira coluna
            .VLD => {
                bg.lines[self.row][self.col + 1] = self.char;
                bg.lines[self.row + 1][self.col + 1] = self.char;
                bg.lines[self.row + 2][self.col] = self.char; // !
                bg.lines[self.row + 2][self.col + 1] = self.char;
            },
            .VLU => {
                bg.lines[self.row][self.col] = self.char; // !
                bg.lines[self.row][self.col + 1] = self.char;
                bg.lines[self.row + 1][self.col + 1] = self.char;
                bg.lines[self.row + 2][self.col + 1] = self.char;
            },
            // diferem na primeira linha
            .HLU => {
                bg.lines[self.row][self.col] = self.char; // !
                bg.lines[self.row + 1][self.col] = self.char;
                bg.lines[self.row + 1][self.col + 1] = self.char;
                bg.lines[self.row + 1][self.col + 2] = self.char;
            },
            .HRU => {
                bg.lines[self.row][self.col + 2] = self.char; // !
                bg.lines[self.row + 1][self.col] = self.char;
                bg.lines[self.row + 1][self.col + 1] = self.char;
                bg.lines[self.row + 1][self.col + 2] = self.char;
            },
            // diferem na ultima linha
            .HLD => {
                bg.lines[self.row][self.col] = self.char;
                bg.lines[self.row][self.col + 1] = self.char;
                bg.lines[self.row][self.col + 2] = self.char;
                bg.lines[self.row + 1][self.col] = self.char; // !
            },
            .HRD => {
                bg.lines[self.row][self.col] = self.char;
                bg.lines[self.row][self.col + 1] = self.char;
                bg.lines[self.row][self.col + 2] = self.char;
                bg.lines[self.row + 1][self.col + 2] = self.char; // !
            },
        }
    }
};

// Global Background
var bg = Background{};

pub fn main() !void {
    var kink = Kink{};
    _ = kink;
    var tee = Tee{};
    _ = tee;
    var bar = Bar{};
    _ = bar;
    var square = Square{};
    var elbow = Elbow{ .orientation = .VLU };
    _ = elbow;

    //var piece = Piece{
    //    .bar = bar,
    //    .tee = tee,
    //    .kink = kink,
    //    .elbow = elbow,
    //    .square = square,
    //};

    // apenas o quadrado funciona:
    var row: usize = 0;
    while (row < Background.rowMax) : (row += 1) {
        //piece.square.row = i;
        square.init(.{ .row = row });
        defer square.destroy();
        try bg.printBg();
    }
}
