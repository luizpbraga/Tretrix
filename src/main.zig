const std = @import("std");
const print = std.debug.print;
const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut().writer();

const Color = enum {
    const X = "\x1b[";
    const E = "\x1b[0;1m";
    Red,
    Green,
    White,
    Purple,
    Blue,
};

const KeysMenu = [_][]const u8{
    "+-------------------+",
    "| " ++ bg.paint("Keys", .Green) ++ "              |",
    "|  h     => Left;   |",
    "|  l     => Right;  |",
    "|  j     => Jump;   |",
    "|  Space => Rotate; |",
    "|  q     => Quit;   |",
    "+-------------------+",
};

const BackGround = struct {
    const Self = @This();
    const MAXROW: usize = 19;
    const MAXCOL: usize = 9;

    it: [21][10]u8 = .{".".* ** 10} ** 20 ++ .{"#".* ** 10},

    // Print in stdout the Background
    // clear and sleep may be removed in the feature
    fn print(self: *const Self) !void {
        try self.clear(); // talvez remover
        try stdout.print(
            \\+------------------------------------+  
            \\|    {s}:                        |
            \\|    {s}      | 
            \\+------------------------------------+ 
            \\
        , .{
            bg.paint("TRETRIX", .Purple),
            bg.paint("A cmd-line-Zig Tetris Game", .Blue),
        });
        for (self.it) |line, n| if (n != 20)
            try stdout.print("{d} {s}||{s}||{s}\n", .{
                n,
                if (n < 10) " " else "",
                line,
                if (n < 8) KeysMenu[n] else " ",
            });
        try stdout.print("+^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^+\n", .{});
    }

    fn checkLine(self: *Self) void {
        var row: usize = 0;
        while (row <= BackGround.MAXROW) : (row += 1)
            if (std.mem.eql(u8, &self.it[row], "#" ** 10)) {
                var row_: usize = row;
                while (row_ != 0) : (row_ -= 1)
                    self.it[row_] = self.it[row_ - 1];
            };
    }

    fn clear(_: *const Self) !void {
        const exec = try std.ChildProcess.exec(.{
            .allocator = std.heap.page_allocator,
            .argv = &[_][]const u8{"clear"},
        });
        try stdout.print("{s}", .{exec.stdout});
    }

    fn paint(_: *const Self, comptime w: []const u8, comptime c: Color) []const u8 {
        return Color.X ++ switch (c) {
            .Red => "31;1m",
            .Green => "32;1m",
            .White => "33;1m",
            .Purple => "34;1m",
            .Blue => "36;1m",
        } ++ w ++ Color.E;
    }
};

const Action = enum { Left, Right, Jump, Down, Rotate, Quit };

const Shape = enum { Square, Bar, Tee, ElbowL, ElbowR, KinkL, KinkR };

const Orientation = enum { H1, V1, H2, V2 };

const Piece = struct {
    const Self = @This();
    // Characteristics
    shape: Shape,
    action: Action = .Down,
    orientation: Orientation = .H1,
    // coordinates
    row: usize = 0,
    col: usize = 3,
    counter: usize = 1,

    /// Desenha a peça: NAO MODIFICA NADA
    fn draw(self: *const Self, conf: struct { char: u8 = '#' }) void {
        const char = conf.char;
        switch (self.shape) {
            .Square => {
                bg.it[self.row][self.col] = char;
                bg.it[self.row][self.col + 1] = char;
                bg.it[self.row + 1][self.col] = char;
                bg.it[self.row + 1][self.col + 1] = char;
            },
            .Bar => {
                const range = [_]usize{ 0, 1, 2, 3 };
                switch (self.orientation) { // #
                    .V1, .V2 => { // #
                        for (range) |i| // #
                            bg.it[self.row + i][self.col] = char; // #
                    },
                    .H1, .H2 => { // ####
                        for (range) |i|
                            bg.it[self.row][self.col + i] = char;
                    },
                }
            },
            .Tee => {
                const range = [_]usize{ 0, 1, 2 };
                switch (self.orientation) {
                    .H1 => {
                        bg.it[self.row][self.col + 1] = char;
                        for (range) |i| // #
                            bg.it[self.row + 1][self.col + i] = char;
                    },
                    .H2 => {
                        bg.it[self.row + 1][self.col + 1] = char;
                        for (range) |i| // #
                            bg.it[self.row][self.col + i] = char;
                    },
                    .V1 => {
                        bg.it[self.row + 1][self.col] = char;
                        for (range) |i| // #
                            bg.it[self.row + i][self.col + 1] = char;
                    },
                    .V2 => {
                        bg.it[self.row + 1][self.col + 1] = char;
                        for (range) |i| // #
                            bg.it[self.row + i][self.col] = char;
                    },
                }
            },
            .KinkL => {
                switch (self.orientation) {
                    .H1, .H2 => {
                        bg.it[self.row][self.col] = char;
                        bg.it[self.row][self.col + 1] = char;
                        bg.it[self.row + 1][self.col + 1] = char;
                        bg.it[self.row + 1][self.col + 2] = char;
                    },
                    .V1, .V2 => {
                        bg.it[self.row][self.col + 1] = char;
                        bg.it[self.row + 1][self.col] = char;
                        bg.it[self.row + 1][self.col + 1] = char;
                        bg.it[self.row + 2][self.col] = char;
                    },
                }
            },
            .KinkR => {
                switch (self.orientation) {
                    .H1, .H2 => {
                        bg.it[self.row][self.col + 1] = char;
                        bg.it[self.row][self.col + 2] = char;
                        bg.it[self.row + 1][self.col] = char;
                        bg.it[self.row + 1][self.col + 1] = char;
                    },
                    .V1, .V2 => {
                        //  #
                        bg.it[self.row][self.col] = char;
                        bg.it[self.row + 1][self.col] = char;
                        bg.it[self.row + 1][self.col + 1] = char;
                        bg.it[self.row + 2][self.col + 1] = char;
                    },
                }
            },
            .ElbowL => {},
            .ElbowR => {},
        }
    }

    /// Apaga a peça
    fn erase(self: *const Self) void {
        self.draw(.{ .char = '.' });
    }

    /// inicia a peça: REGRAS DO JOGO + FíSICA
    fn init(self: *Self) !bool {
        // ''FIM DO JOGO'';
        if (std.mem.count(u8, &bg.it[0], "#") != 0) {
            playable = false;
            return false;
        }

        // ATUALIZAR O BG COM A JOGADA ATUAL
        self.draw(.{});
        try bg.print();

        // PRINT INÚTIL DE INFORMAÇÕES
        try stdout.print("y:{d}, x:{d}, #{d}, {}, {}\n", .{
            self.row,
            self.col,
            self.counter,
            self.action,
            self.shape,
        });

        // contador global
        self.counter += 1;
        // Verificar se é possível inicializar as jogadas (conhecida a orientacao e a posição da peça)
        // i.e. fazer as peças nao se atravessarem ou
        // simplmente finalizar a jogada
        switch (self.shape) {
            // INFO: SQUARE
            .Square => if (bg.it[self.row + 2][self.col] == '#' or
                bg.it[self.row + 2][self.col + 1] == '#')
            {
                self.row = 0;
                self.col = 4;
                return false; // fim d jogada: return false
            },
            // INFO: BAR
            .Bar => switch (self.orientation) {
                .H1, .H2 => if (bg.it[self.row + 1][self.col + 0] == '#' or
                    bg.it[self.row + 1][self.col + 1] == '#' or
                    bg.it[self.row + 1][self.col + 2] == '#' or
                    bg.it[self.row + 1][self.col + 3] == '#')
                {
                    self.row = 0;
                    self.col = 3;
                    return false; // fim d jogada: return false
                },
                .V1, .V2 => if (bg.it[self.row + 4][self.col] == '#') {
                    self.row = 0;
                    self.col = 4;
                    return false; // fim d jogada: return false
                },
            },
            // TODO: TEE
            .Tee => switch (self.orientation) {
                .H1 => {},
                .H2 => {},
                .V1 => {},
                .V2 => {},
            },

            // TODO: KINKL
            .KinkL => switch (self.orientation) {
                .H1 => {},
                .H2 => {},
                .V1 => {},
                .V2 => {},
            },

            // TODO: KINKL
            .KinkR => switch (self.orientation) {
                .H1 => {},
                .H2 => {},
                .V1 => {},
                .V2 => {},
            },

            // TODO: ELBOWL
            // /////////////////////////////////
            .ElbowL => switch (self.orientation) {
                .H1 => {},
                .H2 => {},
                .V1 => {},
                .V2 => {},
            },

            // TODO: KINKR
            .ElbowR => switch (self.orientation) {
                .H1 => {},
                .H2 => {},
                .V1 => {},
                .V2 => {},
            },
        }

        // remover a jogada anterior
        self.erase();

        // se for possível continuar jogando entao ...
        return true;
    }
    /// Lê a Açao + Checagem das linhas
    /// Modifica as peças (dentro das regras do s movimentos)
    fn play(self: *Self) !bool {
        // Check Line
        bg.checkLine();

        // inicio do jogo: Se nao der pra jogar -> retorne falso
        if (!try self.init()) return false;
        // TODO: ler o keyboard direto do hardware
        var buf: [1]u8 = undefined;
        _ = try stdin.read(&buf);

        // TODO: limitar a leitura da acao baseada na posicao
        // da peça eg nao sobrescrecer
        self.action = if (buf.len > 0) switch (buf[0]) {
            'h' => .Left,
            'l' => .Right,
            'j' => .Jump,
            'q' => .Quit,
            ' ' => .Rotate,
            else => .Down,
        } else .Down;

        switch (self.action) {
            .Down => switch (self.shape) {
                .Square => if (self.row < 18) {
                    self.row += 1;
                },
                .Bar => if (self.row < 19) {
                    self.row += 1;
                },
                .Tee => {},
                .KinkL => {},
                .KinkR => {},
                .ElbowL => {},
                .ElbowR => {},
            },

            .Left => switch (self.shape) {
                .Square => {
                    if (self.col != 0 and (bg.it[self.row][self.col - 1] != '#' or
                        bg.it[self.row + 1][self.col - 1] != '#'))
                    {
                        self.col -= 1;
                    }
                },
                .Bar => {
                    if (self.col != 0) switch (self.orientation) {
                        .V1, .V2 => {
                            if (bg.it[self.row + 0][self.col - 1] != '#' or
                                bg.it[self.row + 1][self.col - 1] != '#' or
                                bg.it[self.row + 2][self.col - 1] != '#' or
                                bg.it[self.row + 3][self.col - 1] != '#')
                                self.col -= 1;
                        },
                        .H1, .H2 => {
                            if (bg.it[self.row][self.col - 1] != '#')
                                self.col -= 1;
                        },
                    };
                },
                // TODO:
                .Tee => {},
                .KinkL => {},
                .KinkR => {},
                .ElbowL => {},
                .ElbowR => {},
            },

            .Right => switch (self.shape) {
                .Square => {
                    if (self.col != 8 and (bg.it[self.row][self.col + 2] != '#' or
                        bg.it[self.row + 1][self.col + 2] != '#'))
                    {
                        self.col += 1;
                    }
                },
                .Bar => {
                    switch (self.orientation) {
                        .V1, .V2 => {
                            if (self.col != 9) {
                                if (bg.it[self.row + 0][self.col + 1] != '#' or
                                    bg.it[self.row + 1][self.col + 1] != '#' or
                                    bg.it[self.row + 2][self.col + 1] != '#' or
                                    bg.it[self.row + 3][self.col + 1] != '#')
                                    self.col += 1;
                            }
                        },
                        .H1, .H2 => {
                            if (self.col != 6) {
                                if (bg.it[self.row][self.col + 4] != '#')
                                    self.col += 1;
                            }
                        },
                    }
                },
                // TODO:
                .Tee => {},
                .KinkL => {},
                .KinkR => {},
                .ElbowL => {},
                .ElbowR => {},
            },

            .Rotate => switch (self.shape) {
                .Square => {},
                .Bar => {
                    self.orientation = @intToEnum(Orientation, @enumToInt(self.orientation) + 1);
                },
                .Tee => {},
                .KinkL => {},
                .KinkR => {},
                .ElbowL => {},
                .ElbowR => {},
            },

            .Jump => while (try self.init()) : (self.row += 1) {},

            .Quit => bg.it[0][4] = '#',
        }
        return try self.init();
    }
};

var bg = BackGround{};
var playable = true;

pub fn main() !void {
    var rand_init = std.rand.DefaultPrng.init(0);
    while (playable) {
        var rn = @mod(rand_init.random().int(usize), 2);
        var piece = Piece{ .shape = @intToEnum(Shape, rn) };
        while (try piece.play()) {}
    }
    try stdout.print("{s}", .{bg.paint("VC PERDEU! UAHSUAHS", .Red)});
}
