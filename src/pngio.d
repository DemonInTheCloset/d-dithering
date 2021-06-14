module pngio;

// Pixel Types
struct PixGS(ubyte depth) {
    static if (depth == 8)
        alias Type = ubyte;
    else static if (depth == 16)
        alias Type = ushort;
    else
        static assert(0, "Unsupported bit depth %u".format(depth));

    Type value;
}

struct PixGSA(ubyte depth) {
    static if (depth == 8)
        alias Type = ubyte;
    else static if (depth == 16)
        alias Type = ushort;
    else
        static assert(0, "Unsupported bit depth %u".format(depth));

    Type value;
    Type alpha;
}

struct PixTruecolor(ubyte depth) {
    static if (depth == 8)
        alias Type = ubyte;
    else static if (depth == 16)
        alias Type = ushort;
    else
        static assert(0, "Unsupported bit depth %u".format(depth));

    Type red;
    Type green;
    Type blue;
}

struct PixTruecolorA(ubyte depth) {
    static if (depth == 8)
        alias Type = ubyte;
    else static if (depth == 16)
        alias Type = ushort;
    else
        static assert(0, "Unsupported bit depth %u".format(depth));

    Type red;
    Type green;
    Type blue;
    Type alpha;
}

// Pixel Aliases
alias PixGS8 = PixGS!8;
alias PixGS16 = PixGS!16;

alias PixGSA8 = PixGS!8;
alias PixGSA16 = PixGS!16;

alias PixTruecolor8 = PixTruecolor!8;
alias PixTruecolor16 = PixTruecolor!16;
alias PixRGB = PixTruecolor;
alias PixRGB8 = PixRGB!8;
alias PixRGB16 = PixRGB!16;

alias PixTruecolorA8 = PixTruecolorA!8;
alias PixTruecolorA16 = PixTruecolorA!16;
alias PixRGBA = PixTruecolorA;
alias PixRGBA8 = PixRGBA!8;
alias PixRGBA16 = PixRGBA!16;

// Image Types
struct RawStaticImage(PixType, uint Width, uint Height) {
    PixType[Width * Height] pixels;
}

struct RawImage(PixType) {
    PixType[] pixels;
}

// Image Aliases
alias RawStaticGSImage(ubyte depth, uint Width, uint Height) = RawImage!(PixGS!depth, Width, Height);
alias RawStaticGSAImage(ubyte depth, uint Width, uint Height) = RawImage!(PixGSA!depth, Width, Height);
alias RawStaticRGBImage(ubyte depth, uint Width, uint Height) = RawImage!(PixRGB!depth, Width, Height);
alias RawStaticRGBAImage(ubyte depth, uint Width, uint Height) = RawImage!(PixRGBA!depth, Width, Height);
