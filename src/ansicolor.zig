const Color = enum {
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    default
};

const ColorType = enum {
    foreground,
    background
};

const Style = enum {
    reset,
    bold,
    dim,
    italic,
    underline,
    blinking,
    inverse,
    hidden,
    stiketrough,
    double_underline,
};

pub fn setStyle(comptime style: Style, comptime fg: ?Color, comptime bg: ?Color) []const u8 {
    //var str = "\x1b["; 
    return "\x1b[" ++ switch (style) {
        .reset => "0",
        .bold => "1",
        .dim => "2",
        .italic => "3",
        .underline => "4",
        .blinking => "5",
        .inverse => "7",
        .hidden => "8",
        .stiketrough => "9",
        .double_underline => "21",
    } ++ (if (fg) |fg_real| ";" ++ switch (fg_real) {
        .black => "30",
        .red => "31",
        .green => "32",
        .yellow => "33",
        .blue => "34",
        .magenta => "35",
        .cyan => "36",
        .white => "37",
        .default => "39",
    } else "") ++ (if (bg) |bg_real| ";" ++ switch (bg_real) {
        .black => "40",
        .red => "41",
        .green => "42",
        .yellow => "43",
        .blue => "44",
        .magenta => "45",
        .cyan => "46",
        .white => "47",
        .default => "49",
    } else "") ++ "m";
}

pub fn removeStyle(comptime style: Style) []const u8 {
    return "\x1b[" ++ switch (style) {
        .reset => "0",
        .bold => "22",
        .dim => "22",
        .italic => "23",
        .underline => "24",
        .blinking => "25",
        .inverse => "27",
        .hidden => "28",
        .stiketrough => "29",
        .double_underline => "24",
    } ++ "m";
}