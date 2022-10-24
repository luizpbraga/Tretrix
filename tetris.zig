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
// INFO: ENUM + WHILE + Rand NUMBER + SWITCH = play
// INFO: solução para o problema do "apagamento": struct anônima na função init + destroy
// INFO: init ?
// Limites do quadrado:
// Se a[i,j] é a localizacao do primeiro '#' no Background:
// se 0<=i<=17 e 0<=j<=7
// a[i+2,j] != '#'
// a[i,j-1] != '#'
// a[i,j+2] != '#'
//
const std = @import("std");
const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut().writer();

const KeysMenu: [7][]const u8 = .{
    "+-------------+",
    "|Keys:        |",
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
    const rowMax: usize = 19;
    const colMax: usize = 9;

    lines: [21][10]u8 = .{".".* ** 10} ** 20 ++ .{"#".* ** 10},

    // Print in stdout the Background
    // clear and sleep may be removed in the feature
    fn print(self: Background) !void {
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
            try stdout.print("{d} {s}||{s}||{s}\n", .{
                n,
                if (n < 10) " " else "",
                line,
                if (n < 7) KeysMenu[n] else " ",
            });
        try stdout.print("+==============================+\n", .{});
        //std.time.sleep(1e8); // talvez remover
    }

    fn checkLine(self: *Background) void {
        var row: usize = 0;
        while (row <= Background.rowMax) : (row += 1)
            if (std.mem.eql(u8, &self.lines[row], "#" ** 10)) {
                var row_: usize = row;
                while (row_ != 0) : (row_ -= 1)
                    self.lines[row_] = self.lines[row_ - 1];
            };
    }

    fn clear(_: Background) !void {
        const exec = try std.ChildProcess.exec(.{
            .allocator = std.heap.page_allocator,
            .argv = &[_][]const u8{"clear"},
        });
        try stdout.print("{s}", .{exec.stdout});
    }
};

//const Piece = struct {
//  bar: Bar,
//  tee: Tee,
//  kink: Kink,
//  elbow: Elbow,
//  square: Square,
//};

// BAR
const Bar = struct {
    col: usize = 3,
    row: usize = 0,
    char: u8 = '#',
    orientation: BarOrientation = .H,

    fn new(self: Bar) void {
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

    fn new(self: Tee) void {
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

    fn new(self: Kink) void {
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

    fn new(self: Elbow) void {
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
// // SQUARE
// const Square = struct {
//     row: usize = 0,
//     col: usize = 4,
//     char: u8 = '#',
//     action: Action = .Down,
//     /// Inicializar o SQUARE no Background: ROW e COL são modificados.
//     /// Essa função NUNCA modifica o valor de 'CHAR'.
//     /// Função ``destroy`` deve ser chamado após o uso
//     fn new(
//         self: *Square,
//         config: struct {
//             row: usize = 0,
//             //col: usize = 4,
//             char: u8 = '#',
//         },
//     ) void {
//         // retornar ao 'centro'
//         if (self.row >= 19) self.col = 4;
//         //self.col = config.col;
//         self.row = config.row;
//         // nao desenhar quadrados da linha 19 >=
//         if (self.row >= Background.rowMax) return;

//         bg.lines[self.row][self.col] = config.char;
//         bg.lines[self.row][self.col + 1] = config.char;
//         bg.lines[self.row + 1][self.col] = config.char;
//         bg.lines[self.row + 1][self.col + 1] = config.char;
//     }

//     fn destroy(self: *Square) void {
//         // bounds
//         if (self.row <= 18 and
//             (bg.lines[self.row + 2][self.col] == '#' or
//             bg.lines[self.row + 2][self.col + 1] == '#')) return;
//         //
//         self.new(.{
//             .row = self.row,
//             //.col = self.col,
//             .char = '.',
//         }); // se nao passar self.row ele usa 0 sempre!
//     }

//     fn readAction(self: *Square) !void {
//         var buf: [1]u8 = undefined;
//         _ = try stdin.read(&buf);

//         // TODO: limitar a leitura da acao baseada na posicao da peça eg nao sobrescrecer
//         self.action = if (buf.len > 0) switch (buf[0]) {
//             'h' => .Left,
//             'l' => .Right,
//             else => .Down,
//         } else .Down;
//     }

//     fn moove(self: *Square) !void {
//         try self.readAction();
//         switch (self.action) {
//             .Left => if (self.col != 0) {
//                 self.col -= 1;
//             },
//             .Right => if (self.col != 8) {
//                 self.col += 1;
//             },
//             else => {},
//         }
//         self.new(.{});
//     }

//     fn init(self: *Square, config: struct {
//         row: usize = 0,
//         col: usize = 4,
//     }) !void {
//         try bg.print();
//         self.new(.{ .row = config.row, .col = config.col });
//         try bg.clear();
//         try bg.print();
//     }
// };

const Square = struct {
    row: usize = 0,
    col: usize = 4,
    action: Action = .Down,
    counter: usize = 1,
    // desenha: nao faz verificacoes nem print;
    fn draw(self: *Square, char: u8) void {
        bg.lines[self.row][self.col] = char;
        bg.lines[self.row][self.col + 1] = char;
        bg.lines[self.row + 1][self.col] = char;
        bg.lines[self.row + 1][self.col + 1] = char;
    }

    // regras de inicializacao sao implementadas aqui
    // RETORNA FALSE se o jogo nao tiver mais possibilidades de continuar
    fn init(self: *Square) !bool {

        // ''fim do jogo'';
        if (self.counter != 1 and std.mem.count(u8, &bg.lines[0], "#") != 0) {
            playing = false;
            return false;
        }

        // atualizar o BG com a jogada atual
        self.draw('#');
        try bg.print();
        std.debug.print("box[{d},{d}]: #{d}\n", .{
            self.row,
            self.col,
            self.counter,
        });
        self.counter += 1;

        // nao atravesar as ca ixas na horizontal
        if (bg.lines[self.row + 2][self.col] == '#' or
            bg.lines[self.row + 2][self.col + 1] == '#')
        {
            self.row = 0;
            self.col = 4;
            // TODO: add novas peças e mudar pra return false;
            return true; // fim d jogada: return false
        }
        // remover a jogada anterior
        self.erase();

        return true;
    }

    fn erase(self: *Square) void {
        self.draw('.');
    }

    fn play(self: *Square) !bool {
        bg.checkLine();
        if (!try self.init()) return false;

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

        // BUG: problema com as diagonais
        switch (self.action) {
            .Left => if (self.col != 0 and (bg.lines[self.row][self.col - 1] != '#' or
                bg.lines[self.row + 1][self.col - 1] != '#'))
            {
                self.col -= 1;
            },
            .Right => if (self.col != 8 and (bg.lines[self.row][self.col + 2] != '#' or
                bg.lines[self.row + 1][self.col + 2] != '#'))
            {
                self.col += 1;
            },
            .Down => if (self.row < 18) {
                self.row += 1;
            },
            .Exit => bg.lines[0][4] = '#',
            .Jump => {
                // BUG: REcomeçar na linha 0 e nao na 1
                {
                    while (bg.lines[self.row + 2][self.col] != '#') : (self.row += 1) {
                        _ = try self.init();
                    }
                }
            },
            else => {},
        }

        return try self.init();
    }
};

// Global Background
var bg = Background{};
var playing = true;

pub fn main() !void {
    var box = Square{};

    const Piece = enum {
        Square,
        Bar,
        Tee,
        Kink,
        Elbow,
    };

    while (playing) {
        const rand_shoice = 0;
        const piece = @intToEnum(Piece, rand_shoice);
        switch (piece) {
            .Square => while (try box.play()) {},
            else => {},
        }
    }

    try stdout.print("VC PERDEU!", .{});

    //var square = Square{};

    //// apenas o quadrado funciona:
    //var row: usize = 0;
    //while (true) : (row = 0) {
    //    l1: while (row <= Background.rowMax) : (row += 1) {
    //        //piece.square.row = i;
    //        square.new(.{ .row = row });
    //        try bg.print();
    //        square.destroy();
    //        // depois do 1o destroy
    //        if (bg.lines[row + 1][square.col] == '#') {
    //            // verificar a derota
    //            if (std.mem.count(u8, &bg.lines[0], "#") != 0) return;
    //            // comecar no 'centro'
    //            square.col = 4;
    //            break :l1;
    //        }
    //        try square.moove();
    //    }
    //}
}
