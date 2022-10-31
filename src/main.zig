const std = @import("std");
const fs = std.fs;
const os = std.os;
const mem = std.mem;
const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut().writer();
const print = std.debug.print;

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

    it: [21][10]u8 = .{" ".* ** 10} ** 20 ++ .{"#".* ** 10},

    // Print the Background in stdOut
    fn print(self: *const Self) !void {
        try self.clear();
        // Menu
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

    /// Check ir a line is full of "#"; If TRUE then delete it
    fn checkLine(self: *Self) void {
        var row: usize = 0;
        while (row <= BackGround.MAXROW) : (row += 1)
            if (std.mem.eql(u8, &self.it[row], "#" ** 10)) {
                var row_: usize = row;
                while (row_ != 0) : (row_ -= 1)
                    self.it[row_] = self.it[row_ - 1];
            };
    }

    /// bash clear cmd
    fn clear(_: *const Self) !void {
        const exec = try std.ChildProcess.exec(.{
            .allocator = std.heap.page_allocator,
            .argv = &[_][]const u8{"clear"},
        });
        try stdout.print("{s}", .{exec.stdout});
    }

    //
    fn paint(_: *const Self, comptime w: []const u8, comptime c: Color) []const u8 {
        return Color.X ++ switch (c) {
            .Red => "31;1m",
            .Green => "32;1m",
            .White => "33;1m",
            .Purple => "34;1m",
            .Blue => "36;1m",
        } ++ w ++ Color.E;
    }

    /// Read the User input
    fn read(_: *const Self) ![1]u8 {
        var tty = try fs.cwd().openFile("/dev/tty", .{});
        defer tty.close();

        // https://zig.news/lhp/want-to-create-a-tui-application-the-basics-of-uncooked-terminal-io-17gm \
        // thanks Leon
        const original = try os.tcgetattr(tty.handle);
        var raw = original;

        raw.lflag &= ~@as(
            os.linux.tcflag_t,
            os.linux.ECHO | os.linux.ICANON | os.linux.ISIG | os.linux.IEXTEN,
        );
        raw.iflag &= ~@as(
            os.linux.tcflag_t,
            os.linux.IXON | os.linux.ICRNL | os.linux.BRKINT | os.linux.INPCK | os.linux.ISTRIP,
        );
        raw.cc[os.system.V.TIME] = 0;
        raw.cc[os.system.V.MIN] = 1;

        //try os.tcsetattr(tty.handle, .FLUSH, raw);
        try os.tcsetattr(tty.handle, .NOW, raw);
        var buf: [1]u8 = undefined;
        _ = try tty.read(&buf);
        //try os.tcsetattr(tty.handle, .FLUSH, original);
        try os.tcsetattr(tty.handle, .NOW, original);
        return buf;
    }
};
// ADD PAUSE
const Action = enum { Left, Right, Jump, Down, Rotate, Quit };

const Shape = enum { Square, Bar, Tee, ElbowL, ElbowR, KinkL, KinkR };

/// H1 is the default orientation.
/// V1 = H1 rotated by pi/2
/// H2 = V1 rotated by pi/2
/// V2 = H1 rotated by pi/2
/// H1 = V2 rotated by pi/2
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
    // DRAW
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
                        bg.it[self.row][self.col] = char;
                        bg.it[self.row + 1][self.col] = char;
                        bg.it[self.row + 1][self.col + 1] = char;
                        bg.it[self.row + 2][self.col + 1] = char;
                    },
                }
            },
            // TODO
            .ElbowL => {},
            .ElbowR => {},
        }
    }

    /// Apaga a peça
    fn erase(self: *const Self) void {
        self.draw(.{ .char = ' ' });
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
        try stdout.print("y:{d}, x:{d}, #{d}, {}, {}:{}\n", .{
            self.row,
            self.col,
            self.counter,
            self.action,
            self.shape,
            @enumToInt(self.action),
        });

        // contador global
        self.counter += 1;

        // Verificar se é possível inicializar as jogadas (conhecida a orientacao e a posição da peça)
        // i.e. fazer as peças nao se atravessarem na inicializacao ou
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
                .H1, .H2 => {
                    if (bg.it[self.row + 1][self.col + 0] == '#' or
                        bg.it[self.row + 1][self.col + 1] == '#' or
                        bg.it[self.row + 1][self.col + 2] == '#' or
                        bg.it[self.row + 1][self.col + 3] == '#')
                    {
                        self.row = 0;
                        self.col = 3;
                        return false; // fim d jogada: return false
                    }
                },
                .V1, .V2 => {
                    if (bg.it[self.row + 4][self.col] == '#') {
                        self.row = 0;
                        self.col = 4;
                        return false; // fim d jogada: return false
                    }
                },
            },
            // TODO: TEE
            .Tee => switch (self.orientation) {
                .H1 => {
                    if (bg.it[self.row + 2][self.col + 0] == '#' or
                        bg.it[self.row + 2][self.col + 1] == '#' or
                        bg.it[self.row + 2][self.col + 2] == '#')
                    {
                        self.row = 0;
                        self.col = 3;
                        return false; // fim d jogada: return false
                    }
                },
                .H2 => {
                    if (bg.it[self.row + 1][self.col + 0] == '#' or
                        bg.it[self.row + 1][self.col + 2] == '#' or
                        bg.it[self.row + 2][self.col + 1] == '#')
                    {
                        self.row = 0;
                        self.col = 3;
                        return false; // fim d jogada: return false
                    }
                },
                .V1 => {
                    if (bg.it[self.row + 2][self.col + 0] == '#' or
                        bg.it[self.row + 3][self.col + 1] == '#')
                    {
                        self.row = 0;
                        self.col = 3;
                        return false; // fim d jogada: return false
                    }
                },
                .V2 => {
                    if (bg.it[self.row + 3][self.col + 0] == '#' or
                        bg.it[self.row + 2][self.col + 1] == '#')
                    {
                        self.row = 0;
                        self.col = 3;
                        return false; // fim d jogada: return false
                    }
                },
            },

            // TODO: KINKL
            .KinkL => switch (self.orientation) {
                .H1 => {},
                .H2 => {},
                .V1 => {},
                .V2 => {},
            },

            // TODO: KINKLR
            .KinkR => switch (self.orientation) {
                .H1 => {},
                .H2 => {},
                .V1 => {},
                .V2 => {},
            },
            // /////////////////////////////////
            // TODO: ELBOWL
            .ElbowL => switch (self.orientation) {
                .H1 => {},
                .H2 => {},
                .V1 => {},
                .V2 => {},
            },

            // TODO: ElbowR
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

        // INFO:
        // read the key
        var buf = try bg.read();

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

        // VERIFICAR SO O MOVIMENTO eH POSSIVEL
        // TODO PERNSAR MELHOR NISSO DAQUI DEPOIS
        switch (self.action) {
            .Down => switch (self.shape) {
                .Square, .Tee => {
                    if (self.row < 18) self.row += 1;
                },
                .Bar => {
                    if (self.row < 19) self.row += 1;
                },
                .KinkL => {},
                .KinkR => {},
                .ElbowL => {},
                .ElbowR => {},
            },

            .Left => switch (self.shape) {
                .Square => {
                    if (self.col != 0 and
                        (bg.it[self.row + 0][self.col - 1] != '#' or
                        bg.it[self.row + 1][self.col - 1] != '#')) self.col -= 1;
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
                .Tee => {
                    if (self.col != 0) switch (self.orientation) {
                        .H1 => {
                            if (bg.it[self.row + 1][self.col - 1] != '#') self.col -= 1;
                        },
                        .H2 => {
                            if (bg.it[self.row + 0][self.col - 1] != '#') self.col -= 1;
                        },
                        .V1 => {
                            if (bg.it[self.row + 1][self.col - 1] != '#') self.col -= 1;
                        },
                        .V2 => {
                            if (bg.it[self.row + 0][self.col - 1] != '#' or
                                bg.it[self.row + 1][self.col - 1] != '#' or
                                bg.it[self.row + 2][self.col - 1] != '#')
                                self.col -= 1;
                        },
                    };
                },
                .KinkL => {},
                .KinkR => {},
                .ElbowL => {},
                .ElbowR => {},
            },

            .Right => switch (self.shape) {
                .Square => {
                    if (self.col < 8 and (bg.it[self.row][self.col + 2] != '#' or
                        bg.it[self.row + 1][self.col + 2] != '#'))
                        self.col += 1;
                },
                .Bar => {
                    switch (self.orientation) {
                        .V1, .V2 => if (self.col < 9) {
                            if (bg.it[self.row + 0][self.col + 1] != '#' or
                                bg.it[self.row + 1][self.col + 1] != '#' or
                                bg.it[self.row + 2][self.col + 1] != '#' or
                                bg.it[self.row + 3][self.col + 1] != '#') self.col += 1;
                        },
                        .H1, .H2 => if (self.col < 6) {
                            if (bg.it[self.row][self.col + 4] != '#') self.col += 1;
                        },
                    }
                },
                // TODO:
                .Tee => {
                    switch (self.orientation) {
                        .H1 => if (self.col < 7) {
                            if (bg.it[self.row + 1][self.col + 2] != '#') self.col += 1;
                        },
                        .H2 => if (self.col < 7) {
                            if (bg.it[self.row + 0][self.col + 2] != '#') self.col += 1;
                        },

                        .V1 => if (self.col < 8) {
                            if (bg.it[self.row + 0][self.col + 1] != '#' or
                                bg.it[self.row + 1][self.col + 1] != '#' or
                                bg.it[self.row + 2][self.col + 1] != '#') self.col += 1;
                        },
                        .V2 => if (self.col < 8) {
                            if (bg.it[self.row + 1][self.col + 1] != '#') self.col += 1;
                        },
                    }
                },
                .KinkL => {},
                .KinkR => {},
                .ElbowL => {},
                .ElbowR => {},
            },

            // BUG: pieces bounds
            .Rotate => {
                var cur = @enumToInt(self.orientation);
                switch (self.shape) {
                    .Square => {},
                    .Bar, .Tee => {
                        self.orientation = if (cur < 3) @intToEnum(Orientation, cur + 1) else @intToEnum(Orientation, 0);
                    },
                    .KinkL => {},
                    .KinkR => {},
                    .ElbowL => {},
                    .ElbowR => {},
                }
            },

            .Jump => while (try self.init()) : (self.row += 1) {},
            .Quit => bg.it[0][4] = '#',
        }

        return try self.init();
    }
};

// GLOBAL
var bg = BackGround{};
var playable = true;

pub fn main() !void {
    var rand_init = std.rand.DefaultPrng.init(0);
    while (playable) {
        var rn = @mod(rand_init.random().int(usize), 3);
        var piece = Piece{ .shape = @intToEnum(Shape, rn) };
        while (try piece.play()) {}
    }

    try stdout.print("{s}", .{bg.paint("VC PERDEU! UAHSUAHS", .Red)});
}
