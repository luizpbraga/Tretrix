// Jogo inicia.
// Peça X é inicializada => Background é atualizado
// Background é printado;
// Acao é linda
// Background é limpo
// Acao é executada =>  A peça X se move => Background é atualizado : substitui o desenho anterior pelo novo
// Background é printado;

// TODO: FUNCAO PRA VERIFICAR AS REGRAS DE MOVIMENTO;;
// TODO: FUNCAO PRA APLICAR TAIS REGRAS DE MOMENTO;;
// TODO: FUNCAO PRA DELETAR O MOVIMENTO ANTERIOR;;
// TODO: FUNCAO PRA ANALiSAR A AçÃO
// TODO: APAGAR OU DESENHAR? ENUM ?
// TODO: COMO ELE VAI RODAR?
// TODO: READ KEYBOAD (RAW) inPUT
// TODO: CORES?
// INFO: ENUM + WHILE + Rand NUMBER + SWITCH = play
// INFO: solução para o problema do "apagamento": struct anônima na função init + destroy
// INFO: init ?

const std = @import("std");
const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut().writer();

const KeysMenu: [7][]const u8 = .{
    "+-------------+",
    "|\x1b[32mKeys\x1b[0m:        |",
    "|  h => Left; |",
    "|  l => Right;|",
    "|  j => End;  |",
    "|  q => Quit; |",
    "+-------------+",
};

/// Avaliable Actions
const Action = enum { Left, Right, Down, Jump, Rotate, Exit, Pause };
/// Draw or Erase de Shape
const BgShape = enum(u8) { Draw = '#', Erase = '.' };
// square dont rotate ;
const BarOrientation = enum { H, V };
const TeeOrientation = enum { U, D, L, R };
const KinkOrientation = enum { HL, HR, VL, VR };
const ElbowOrientation = enum { HRU, HLU, HRD, HLD, VRU, VLU, VRD, VLD };

const Background = struct {
    const Self = @This();
    const MAXROW: usize = 19;
    const MAXCOL: usize = 9;

    it: [21][10]u8 = .{".".* ** 10} ** 20 ++ .{"#".* ** 10},

    // Print in stdout the Background
    // clear and sleep may be removed in the feature
    fn print(self: *const Self) !void {
        try self.clear(); // talvez remover
        try stdout.print(
            \\+------------------------------+  
            \\| TRETRIX:                     |
            \\| A cmd-line-Zig Tetris Game   | 
            \\+------------------------------+ 
            \\+^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^+
            \\
        , .{});
        for (self.it) |line, n| if (n != 20)
            try stdout.print("{d} {s}||{s}||{s}\n", .{
                n,
                if (n < 10) " " else "",
                line,
                if (n < 7) KeysMenu[n] else " ",
            });
        try stdout.print("+^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^+\n", .{});
        //std.time.sleep(1e8); // talvez remover
    }

    fn checkLine(self: *Self) void {
        var row: usize = 0;
        while (row <= Background.MAXROW) : (row += 1)
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
};

// TEE
const Tee = struct {
    row: usize = 0,
    col: usize = 4,
    char: u8 = '#',
    orientation: TeeOrientation = .D,

    fn new(self: Tee) void {
        switch (self.orientation) {
            .U => {
                bg.it[self.row][self.col + 1] = self.char;
                bg.it[self.row + 1][self.col] = self.char;
                bg.it[self.row + 1][self.col + 1] = self.char;
                bg.it[self.row + 1][self.col + 2] = self.char;
            },
            .D => {
                bg.it[self.row][self.col] = self.char;
                bg.it[self.row][self.col + 1] = self.char;
                bg.it[self.row][self.col + 2] = self.char;
                bg.it[self.row + 1][self.col + 1] = self.char;
            },
            .L => {
                bg.it[self.row][self.col + 1] = self.char;
                bg.it[self.row + 1][self.col] = self.char;
                bg.it[self.row + 1][self.col + 1] = self.char;
                bg.it[self.row + 2][self.col + 1] = self.char;
            },
            .R => {
                bg.it[self.row][self.col] = self.char;
                bg.it[self.row + 1][self.col] = self.char;
                bg.it[self.row + 1][self.col + 1] = self.char;
                bg.it[self.row + 2][self.col] = self.char;
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

    fn new(self: Kink) void {
        switch (self.orientation) {
            .VL => {
                // #
                // ##
                //  #
                bg.it[self.row][self.col] = self.char;
                bg.it[self.row + 1][self.col] = self.char;
                bg.it[self.row + 1][self.col + 1] = self.char;
                bg.it[self.row + 2][self.col + 1] = self.char;
            },
            .VR => {
                //  #
                // ##
                // #
                bg.it[self.row][self.col + 1] = self.char;
                bg.it[self.row + 1][self.col] = self.char;
                bg.it[self.row + 1][self.col + 1] = self.char;
                bg.it[self.row + 2][self.col] = self.char;
            },
            .HL => {
                // ##
                //  ##
                bg.it[self.row][self.col] = self.char;
                bg.it[self.row][self.col + 1] = self.char;
                bg.it[self.row + 1][self.col + 1] = self.char;
                bg.it[self.row + 1][self.col + 2] = self.char;
            },
            .HR => {
                //  ##
                // ##
                bg.it[self.row][self.col + 1] = self.char;
                bg.it[self.row][self.col + 2] = self.char;
                bg.it[self.row + 1][self.col] = self.char;
                bg.it[self.row + 1][self.col + 1] = self.char;
            },
        }
        bg.it[self.row + 1][self.col + 1] = self.char;
    }
};

const Elbow = struct {
    col: usize = 3,
    row: usize = 0,
    char: u8 = '#',
    orientation: ElbowOrientation = .HLD,

    fn new(self: Elbow) void {
        //const range = [_]usize{ 0, 1, 2 };
        switch (self.orientation) {
            // diferem na segunda coluna
            .VRD => {
                bg.it[self.row][self.col] = self.char;
                bg.it[self.row + 1][self.col] = self.char;
                bg.it[self.row + 2][self.col] = self.char;
                bg.it[self.row + 2][self.col + 1] = self.char; // !
            },
            .VRU => {
                bg.it[self.row][self.col] = self.char;
                bg.it[self.row][self.col + 1] = self.char; // !
                bg.it[self.row + 1][self.col] = self.char;
                bg.it[self.row + 2][self.col] = self.char;
            },
            // diferem na primeira coluna
            .VLD => {
                bg.it[self.row][self.col + 1] = self.char;
                bg.it[self.row + 1][self.col + 1] = self.char;
                bg.it[self.row + 2][self.col] = self.char; // !
                bg.it[self.row + 2][self.col + 1] = self.char;
            },
            .VLU => {
                bg.it[self.row][self.col] = self.char; // !
                bg.it[self.row][self.col + 1] = self.char;
                bg.it[self.row + 1][self.col + 1] = self.char;
                bg.it[self.row + 2][self.col + 1] = self.char;
            },
            // diferem na primeira linha
            .HLU => {
                bg.it[self.row][self.col] = self.char; // !
                bg.it[self.row + 1][self.col] = self.char;
                bg.it[self.row + 1][self.col + 1] = self.char;
                bg.it[self.row + 1][self.col + 2] = self.char;
            },
            .HRU => {
                bg.it[self.row][self.col + 2] = self.char; // !
                bg.it[self.row + 1][self.col] = self.char;
                bg.it[self.row + 1][self.col + 1] = self.char;
                bg.it[self.row + 1][self.col + 2] = self.char;
            },
            // diferem na ultima linha
            .HLD => {
                bg.it[self.row][self.col] = self.char;
                bg.it[self.row][self.col + 1] = self.char;
                bg.it[self.row][self.col + 2] = self.char;
                bg.it[self.row + 1][self.col] = self.char; // !
            },
            .HRD => {
                bg.it[self.row][self.col] = self.char;
                bg.it[self.row][self.col + 1] = self.char;
                bg.it[self.row][self.col + 2] = self.char;
                bg.it[self.row + 1][self.col + 2] = self.char; // !
            },
        }
    }
};
/////////////////////////////////
///%%%%%%/////%%%%/////%%%%%%////
///%%////%///%////%////%%////%///
///%%%%%%////%%%%%%////%%%%%%////
///%%/// %///%////%////%%////%///
///%%%%%%%///%////%////%%/////%//
/////////////////////////////////
// BAR
const Bar = struct {
    col: usize = 3,
    row: usize = 0,
    orientation: BarOrientation = .H,
    action: Action = .Down,
    counter: usize = 1,

    fn draw(self: Bar, char: u8) void {
        const range = [_]usize{ 0, 1, 2, 3 };
        switch (self.orientation) { // #
            .V => { // #
                for (range) |i| // #
                    bg.it[self.row + i][self.col] = char; // #
            },
            .H => { // ####
                for (range) |i|
                    bg.it[self.row][self.col + i] = char;
            },
        }
    }

    fn erase(self: Bar) void {
        self.draw('.');
    }

    fn init(self: *Bar) !bool {

        // ''fim do jogo'';
        if (counter != 1 and std.mem.count(u8, &bg.it[0], "#") != 0) {
            playing = false;
            return false;
        }

        // atualizar o BG com a jogada atual
        self.draw('#');
        try bg.print();

        // print inútil de informações
        std.debug.print("y:{d}, x:{d}, #{d}, {}, {}\n", .{
            self.row,
            self.col,
            counter,
            self.action,
            playing,
        });

        // contador global
        counter += 1;

        // TODO: mover isso pra fn play
        // nao atravesar as barras na horizontal
        // fim da jogada
        switch (self.orientation) {
            .V => if (bg.it[self.row + 4][self.col] == '#') {
                self.row = 0;
                self.col = 4;
                return false; // fim d jogada: return false
            },

            .H => if (bg.it[self.row + 1][self.col + 0] == '#' or
                bg.it[self.row + 1][self.col + 1] == '#' or
                bg.it[self.row + 1][self.col + 2] == '#' or
                bg.it[self.row + 1][self.col + 3] == '#')
            {
                self.row = 0;
                self.col = 3;
                return false; // fim d jogada: return false

            },
        }
        // remover a jogada anterior
        self.erase();

        return true;
    }

    fn play(self: *Bar) !bool {
        // Check Line
        //if (bg.it[self.row][0] == '#' and bg.it[self.row][9] == '#')
        // BUG:: ENtre peças nao funciona direito
        // BUG : NAO FUNCIONA CORRETAMENTE PRA 'BAR': DELETA COM 8;
        bg.checkLine();

        // inicio do jogo
        if (!try self.init()) return false;

        // TODO: ler o keyboard direto do hardware
        var buf: [1]u8 = undefined;
        _ = try stdin.read(&buf);
        // TODO: limitar a leitura da acao baseada na posicao da peça eg nao sobrescrecer
        self.action = if (buf.len > 0) switch (buf[0]) {
            'h' => .Left,
            'l' => .Right,
            'j' => .Jump,
            'q' => .Exit,
            ' ' => .Rotate,
            else => .Down,
        } else .Down;

        // BUG : problema com as diagonais
        switch (self.action) {
            .Left => if (self.col != 0) switch (self.orientation) {
                .V => {
                    if (bg.it[self.row + 0][self.col - 1] != '#' or
                        bg.it[self.row + 1][self.col - 1] != '#' or
                        bg.it[self.row + 2][self.col - 1] != '#' or
                        bg.it[self.row + 3][self.col - 1] != '#')
                        self.col -= 1;
                },
                .H => {
                    if (bg.it[self.row][self.col - 1] != '#')
                        self.col -= 1;
                },
            },

            .Right => switch (self.orientation) {
                .V => {
                    if (self.col != 9) {
                        if (bg.it[self.row + 0][self.col + 1] != '#' or
                            bg.it[self.row + 1][self.col + 1] != '#' or
                            bg.it[self.row + 2][self.col + 1] != '#' or
                            bg.it[self.row + 3][self.col + 1] != '#')
                            self.col += 1;
                    }
                },
                .H => {
                    if (self.col != 6) {
                        if (bg.it[self.row][self.col + 4] != '#')
                            self.col += 1;
                    }
                },
            },

            .Rotate => {
                self.orientation = if (self.orientation == .H) .V else .H;
            },
            // FIXO
            .Down => if (self.row < 19) {
                self.row += 1;
            },
            .Exit => bg.it[0][4] = '#',
            // BUG:: REcomeçar na linha 0 e nao na 1
            // BUG : NAO TROCA DE PEçA
            .Jump => while (try self.init()) : (self.row += 1) {},
            else => {},
        }

        return try self.init();
    }
};

const Square = struct {
    row: usize = 0,
    col: usize = 4,
    action: Action = .Down,

    // desenha: nao faz verificacoes nem print;
    fn draw(self: Square, char: u8) void {
        bg.it[self.row][self.col] = char;
        bg.it[self.row][self.col + 1] = char;
        bg.it[self.row + 1][self.col] = char;
        bg.it[self.row + 1][self.col + 1] = char;
    }

    fn erase(self: Square) void {
        self.draw('.');
    }

    // regras de inicializacao sao implementadas aqui
    // RETORNA FALSE se o jogo nao tiver mais possibilidades de continuar
    fn init(self: *Square) !bool {

        // ''fim do jogo'';
        if (counter >= 1 and std.mem.count(u8, &bg.it[0], "#") != 0) {
            playing = false;
            return playing;
        }

        // atualizar o BG com a jogada atual
        self.draw('#');
        try bg.print();

        // contador global
        counter += 1;

        // TODO: mover isso pra fn play
        // nao atravesar as caixas na horizontal
        // fim da jogada
        if (bg.it[self.row + 2][self.col] == '#' or
            bg.it[self.row + 2][self.col + 1] == '#')
        {
            self.row = 0;
            self.col = 4;
            // TODO: add novas peças e mudar pra return false;
            return false; // fim d jogada: return false
        }
        // remover a jogada anterior
        self.erase();

        return true;
    }

    fn play(self: *Square) !bool {
        // Check Line
        //if (bg.it[self.row][0] == '#' and bg.it[self.row][9] == '#')
        // BUG: : ENtre peças nao funciona direito
        bg.checkLine();

        //
        if (!try self.init()) return false;
        // print inútil de informações
        std.debug.print("box[{d},{d}]: #{d}, {}\n", .{
            self.row,
            self.col,
            counter,
            self.action,
        });

        // TODO: ler o keyboard direto do hardware
        var buf: [1]u8 = undefined;
        _ = try stdin.read(&buf);
        // TODO: limitar a leitura da acao baseada na posicao da peça eg nao sobrescrecer
        self.action = if (buf.len > 0) switch (buf[0]) {
            'h' => .Left,
            'l' => .Right,
            'j' => .Jump,
            'q' => .Exit,
            else => .Down,
        } else .Down;
        // BUG : problema com as diagonais
        switch (self.action) {
            .Left => if (self.col != 0 and (bg.it[self.row][self.col - 1] != '#' or
                bg.it[self.row + 1][self.col - 1] != '#'))
            {
                self.col -= 1;
            },
            .Right => if (self.col != 8 and (bg.it[self.row][self.col + 2] != '#' or
                bg.it[self.row + 1][self.col + 2] != '#'))
            {
                self.col += 1;
            },
            .Down => if (self.row < 18) {
                self.row += 1;
            },
            .Exit => bg.it[0][4] = '#',
            // BUG:: REcomeçar na linha 0 e nao na 1
            .Jump => while (try self.init()) : (self.row += 1) {},
            else => {},
        }

        return try self.init();
    }
};

// Global Background
var bg = Background{};
var playing = true;
var counter: usize = 1;
pub fn main() !void {
    var box = Square{};
    var bar = Bar{};
    var rand = std.rand.DefaultPrng.init(0);

    const Piece = enum {
        Square,
        Bar,
        //  Tee,
        //  Kink,
        //  Elbow,
    };

    while (playing) {
        var rn = @mod(rand.random().int(usize), 2);
        const piece = @intToEnum(Piece, rn);
        switch (piece) {
            .Square => while (try box.play()) {},
            .Bar => while (try bar.play()) {},
            // else => {},
        }
    }
    try stdout.print("\x1b[31;1mVC PERDEU!", .{});
}
