import std.stdio;
import std.getopt;

void main(string[] args) {
    string src = "";
    string dst = "out.png";
    bool verbose = false;
    bool debugging = false;

    auto helpInfo = getopt(
            args,
            std.getopt.config.bundling,
            std.getopt.config.required,
            "input|i", "Path to input image", &src,
            "output|o", "Path to output image", &dst,
            "verbose|v", "Print more information", &verbose,
            "debug|d", "Print debug information", &debugging
            );

    if (helpInfo.helpWanted) {
        defaultGetoptPrinter("Some information", helpInfo.options);
    }

    if (debugging) {
        writefln("Input: %s\nOutput: %s\nVerbose: %s\nDebug: true", src, dst, verbose);
    }
}
