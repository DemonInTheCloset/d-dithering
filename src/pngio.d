module pngio;

// Pixel Types
struct PixGS(ubyte depth)
{
    static if (depth == 8)
        alias Type = ubyte;
    else static if (depth == 16)
        alias Type = ushort;
    else
        static assert(0, "Unsupported bit depth %u".format(depth));

    static assert(Type.sizeof == depth / 8);
    Type value;
}

struct PixGSA(ubyte depth)
{
    static if (depth == 8)
        alias Type = ubyte;
    else static if (depth == 16)
        alias Type = ushort;
    else
        static assert(0, "Unsupported bit depth %u".format(depth));

    Type value;
    Type alpha;
}

struct PixTruecolor(ubyte depth)
{
    static if (depth == 8)
        alias Type = ubyte;
    else static if (depth == 16)
        alias Type = ushort;
    else
        static assert(0, "Unsupported bit depth %u".format(depth));

    static assert(Type.sizeof == depth / 8);
    Type red;
    Type green;
    Type blue;
}

struct PixTruecolorA(ubyte depth)
{
    static if (depth == 8)
        alias Type = ubyte;
    else static if (depth == 16)
        alias Type = ushort;
    else
        static assert(0, "Unsupported bit depth %u".format(depth));

    static assert(Type.sizeof == depth / 8);
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
struct RawStaticImage(PixType, uint Width, uint Height)
{
    PixType[Width * Height] pixels;
}

struct RawImage(PixType)
{
    immutable uint width;
    immutable uint height;
    PixType[] pixels;

    // A Raw Image cannot be resized, you have to know the size in advance
    @disable this();

    this(int w, int h)
    {
        width = w;
        height = h;
        pixels = new PixType[](w * h);
    }

    invariant
    {
        assert(pixels.length == width * height);
    }
}

// Image Aliases
alias RawStaticGSImage(ubyte depth, uint Width, uint Height)
    = RawStaticImage!(PixGS!depth, Width, Height);
alias RawStaticGSAImage(ubyte depth, uint Width, uint Height)
    = RawStaticImage!(PixGSA!depth, Width, Height);
alias RawStaticRGBImage(ubyte depth, uint Width, uint Height)
    = RawStaticImage!(PixRGB!depth, Width, Height);
alias RawStaticRGBAImage(ubyte depth, uint Width, uint Height)
    = RawStaticImage!(PixRGBA!depth, Width, Height);

alias RawGSImage(ubyte depth) = RawImage!(PixGS!depth);
alias RawGSAImage(ubyte depth) = RawImage!(PixGSA!depth);
alias RawRGBImage(ubyte depth) = RawImage!(PixRGB!depth);
alias RawRGBAImage(ubyte depth) = RawImage!(PixRGBA!depth);

// PNG Reading
immutable ubyte[8] validPNGHeader = [
    ubyte(0x89), ubyte(0x50), ubyte(0x4E), ubyte(0x47),
    ubyte(0x0D), ubyte(0x0A), ubyte(0x1A), ubyte(0x0A)
];

struct PNGHeader
{
    static assert(PNGHeader.sizeof == 8);
    ubyte[8] header;

    /// Checks the PNG Signature
    bool isvalid() pure nothrow
    {
        static foreach (ix, b; validPNGHeader)
        {
            if (b != this.header[ix])
            {
                return false;
            }
        }
        return true;
    }

    unittest
    {
        PNGHeader header = PNGHeader(validPNGHeader);

        assert(header.isvalid());
        header.header[1] = 0;
        assert(!header.isvalid());
    }
}

unittest
{
}

// PNG enums
enum PNGBitDepth : byte { ONE=1, TWO=2, FOUR=4, EIGHT=8, SIXTEEN=16 };
enum PNGColorType : byte { INDEXED=3, GRAYSCALE=0, GRAYSCALEALPHA=4, TRUECOLOR=2, TRUECOLORALPHA=6 };
enum PNGCompression : byte { DEFLATE=0 };
enum PNGFilter : byte { NONE=0, SUB=1, UP=2, AVERAGE=3, PAETH=4 };
enum PNGInterlace : byte { NONE=0, ADAM7=1 };

// Chunks
bool nullCRC(in ubyte[4] crc) pure nothrow
{
    static foreach(ix; 0..4)
    {
        if (crc[ix] != 0)
        {
            return false;
        }
    }

    return true;
}

struct StaticPNGChunk(immutable(char)[4] Type, size_t Size)
{
    static assert(StaticPNGChunk.sizeof == Size + 12);

    align(1):
        private uint chunkLength = Size;
        immutable(char)[4] chunkType = Type;
        ubyte[Size] chunkData;
        private ubyte[4] chunkCRC;

    this(in ubyte[Size] data)
    {
        this.chunkData = data;
    }

    /// Calculates this chunks CRC
    private ubyte[4] calculateCRC() const pure nothrow
    {
        import std.digest.crc : crc32Of;
        ubyte[Size + 8] data = cast(const(ubyte)[])chunkType ~ chunkData ~ chunkCRC;

        return data.crc32Of;
    }

    /// Compute and fill Chunk CRC
    void fillCRC() nothrow
    {
        // CRC must be empty before calling this function
        assert(this.chunkCRC.nullCRC);

        this.chunkCRC = this.calculateCRC();
    }

    /// Validates chunck CRC
    bool validCRC() const pure nothrow
    {
        return this.calculateCRC.nullCRC;
    }
}

// Fixed size Chunks
alias PNGIHDR = StaticPNGChunk!("IHDR", 13);
alias PNGIEND = StaticPNGChunk!("IEND", 0);

PNGIHDR buildIHDR(uint width, uint height, PNGBitDepth bitDepth,
        PNGColorType colorType, PNGCompression compressionType,
        PNGFilter filterType, PNGInterlace interlaceType) pure nothrow
{
    import std.bitmanip : nativeToBigEndian;

    if (bitDepth == PNGBitDepth.SIXTEEN)
    {
        assert(colorType != PNGColorType.INDEXED);
    }
    else if (bitDepth != PNGBitDepth.EIGHT)
    {
        assert(colorType == PNGColorType.INDEXED
                || colorType == PNGColorType.GRAYSCALE);
    }

    ubyte[13] data = width.nativeToBigEndian ~ height.nativeToBigEndian
        ~ bitDepth.nativeToBigEndian ~ colorType.nativeToBigEndian
        ~ compressionType.nativeToBigEndian ~ filterType.nativeToBigEndian
        ~ interlaceType.nativeToBigEndian;

    PNGIHDR header = PNGIHDR(data);

    header.fillCRC;

    return header;
}

unittest
{
    immutable PNGIHDR chunk = buildIHDR(16, 16, PNGBitDepth.EIGHT,
            PNGColorType.TRUECOLOR, PNGCompression.DEFLATE,
            PNGFilter.NONE, PNGInterlace.NONE);

    assert(chunk.validCRC());
}

PNGIEND buildIEND() pure nothrow
{
    PNGIEND imgEnd;

    imgEnd.fillCRC();

    return imgEnd;
}

unittest
{
    immutable PNGIEND chunk = buildIEND();

    assert(chunk.validCRC());
}

struct DynamicPNGChunk(immutable(char)[4] Type)
{
    ubyte[] chunkData;
    private ubyte[4] chunkCRC;

    private ubyte[4] calculateCRC() const pure nothrow
    {
        import std.digest.crc : crc32Of;
        ubyte[] data = Type ~ chunkData ~ chunkCRC;

        return data.crc32Of;
    }

    void fillCRC() nothrow
    {
        assert(this.chunkCRC.nullCRC);
        this.chunkCRC = this.calculateCRC();
    }

    void validCRC() const pure nothrow
    {
        return this.calculateCRC.nullCRC;
    }
}

// Functions
