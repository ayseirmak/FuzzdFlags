#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <memory>

#include "clang/Basic/Version.h"
#include "clang/Driver/Driver.h"
#include "clang/Driver/Compilation.h"
#include "clang/Frontend/TextDiagnosticPrinter.h"
#include "llvm/TargetParser/Host.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Option/Option.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/VirtualFileSystem.h"

// -----------------------------------------------------------------------------
// 1) Helpers to get environment variables with fallback defaults
// -----------------------------------------------------------------------------

// Reads string from ENV. If not set, returns defaultVal.
static std::string getEnvOrDefault(const char* varName, const char* defaultVal) {
    const char* val = std::getenv(varName);
    return (val ? std::string(val) : std::string(defaultVal));
}

// Reads int from ENV. If not set, returns defaultVal.
static uint16_t getEnvOrDefaultInt(const char* varName, uint16_t defaultVal) {
    const char* val = std::getenv(varName);
    if (!val) return defaultVal;
    return static_cast<uint16_t>(std::stoi(val));
}

// ─────────────────────────────────────────────────────────────────────────────
// 1.  ENUM TABLES  (exactly‑one‑of‑each)
// ─────────────────────────────────────────────────────────────────────────────
static const std::vector<std::vector<const char*>> ENUM_TABLE = {
    /*0 OptLevel*/     {"-O0","-O1","-O2","-O3","-Os","-Oz","-Og","-Ofast"},
    /*1 CodeModel*/    {"","-fPIC","-fPIE","-mcmodel=large"},
    /*2 LTO*/          {"","-flto","-flto=thin"},
    /*3 ISA base*/     {"-march=x86-64","-march=x86-64-v2","-march=x86-64-v3","-march=x86-64-v4",
                        "-march=skylake-avx512","-march=znver4","-march=native"},
    /*4 FastMath*/     {"","-ffast-math","-fno-fast-math"},
    /*5 Vectoriser*/   {"","-fno-vectorize","-fno-slp-vectorize"},
    /*6 SplitStack*/   {"","-fsplit-stack","-fno-split-stack"},
    /*7 TLS‑model*/    {"","-ftls-model=local-exec","-ftls-model=global-dynamic","-ftls-model=initial-exec"}
};

// ─────────────────────────────────────────────────────────────────────────────
// 2.  BIT FLAG TABLE  (independent on/off)
//    Exactly 64 entries (8 bytes). Add/remove flags as desired.
// ─────────────────────────────────────────────────────────────────────────────
static const std::vector<const char*> BIT_FLAGS = {
 /* 0*/"-mavx2",            /* 1*/"-mavx512f",           /* 2*/"-mavx512vl",          /* 3*/"-mfma",
 /* 4*/"-mbmi2",            /* 5*/"-maes",               /* 6*/"-msha",              /* 7*/"-mno-avx2",
 /* 8*/"-mno-sse4.2",       /* 9*/"-ffinite-loops",      /*10*/"-ftrapv",            /*11*/"-fstack-protector-strong",
 /*12*/"-fno-strict-aliasing",/*13*/"-funsigned-char",  /*14*/"-ffp-exception-behavior=strict",/*15*/"-fhonor-nans",
 /*16*/"-ffp-contract=off", /*17*/"-ffp-contract=fast", /*18*/"-fno-vectorize",    /*19*/"-fvectorize",
 /*20*/"-fno-unsafe-math-optimizations", /*21*/"-funsafe-math-optimizations", /*22*/"-flax-vector-conversions", /*23*/"-fno-lax-vector-conversions",
 /*24*/"-fdenormal-fp-math=ieee", /*25*/"-fdenormal-fp-math=preserve-sign", /*26*/"-fno-finite-math-only", /*27*/"-ffast-math",
 /*28*/"-fno-fast-math",    /*29*/"-fno-trapping-math", /*30*/"-ftrapping-math",   /*31*/"-freciprocal-math",
 /*32*/"-fno-reciprocal-math",/*33*/"-fno-math-errno",  /*34*/"-fmath-errno",      /*35*/"-fno-signed-zeros",
 /*36*/"-fsigned-zeros",    /*37*/"-fno-wrapv",          /*38*/"-fwrapv",           /*39*/"-fno-strict-overflow",
 /*40*/"-fstrict-overflow", /*41*/"-fno-strict-return", /*42*/"-fstrict-return",  /*43*/"-funroll-loops",
 /*44*/"-fno-unroll-loops", /*45*/"-ffunction-sections",/*46*/"-fno-function-sections",/*47*/"-falign-functions",
 /*48*/"-fno-align-functions",/*49*/"-fstack-size-section",/*50*/"-fno-stack-size-section",/*51*/"-fstack-protector",
 /*52*/"-fno-stack-protector",/*53*/"-fno-split-stack", /*54*/"-fsigned-bitfields",/*55*/"-funsigned-bitfields",
 /*56*/"-fkeep-static-consts",/*57*/"-fno-keep-static-consts",/*58*/"-faddrsig",       /*59*/"-fno-addrsig",
 /*60*/"-fuse-init-array",  /*61*/"-fno-use-init-array",/*62*/"-fjump-tables",    /*63*/"-fno-jump-tables"};

static_assert(BIT_FLAGS.size() == 64, "BIT_FLAGS must have 64 entries");

// -----------------------------------------------------------------------------
// 3) Instead of a fixed string, build flags dynamically using environment vars
// -----------------------------------------------------------------------------
static std::string getFixedFlags() {
    // Base flags (minus the old -I /users/user42/llvmSS-include)
    // We'll keep -I/usr/include, but the second include dir will come from ENV.
    std::string baseFlags =
        "-c -fpermissive -w "
        "-Wno-implicit-function-declaration -Wno-return-type -Wno-builtin-redeclared "
        "-Wno-implicit-int -Wno-int-conversion "
        "-march=x86-64-v2 "
        "-I/usr/include";

    // Let INCLUDES_DIR override the second -I path
    //  fallback = "/users/user42/llvmSS-include"
    std::string includesDir = getEnvOrDefault("INCLUDES_DIR", "/users/user42/llvmSS-include");
    baseFlags += " -I" + includesDir;
    baseFlags += " -lm";
    return baseFlags;
}

// Bayt -> Flags Mapping Fuction

// Read Binary File
std::vector<uint8_t> readBinaryFile(const std::string &filename) {
    std::ifstream file(filename, std::ios::binary);
    if (!file) {
        std::cerr << "Error: Could not open binary file " << filename << std::endl;
        exit(1);
    }
    return std::vector<uint8_t>((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
}

std::string decodeFlagsFromBinarySub(const std::vector<uint8_t> &data) {
    std::string flags;
    // Skip first 2 bytes for file index, flags start from the 3rd byte
   for(size_t f=0;f<ENUM_TABLE.size();++f){
        size_t idxByte = f + 2;                 // skip first 2 bytes
        if(idxByte >= data.size()) break;
        const auto& tab = ENUM_TABLE[f];
        const char* opt = tab[data[idxByte] % tab.size()];
        if(opt && *opt){ flags += ' '; flags += opt; }
    }
	
    // 5.2 Bit‑flags start at data[10]
    for(size_t i=10;i<18 && i<data.size();++i){
        uint8_t b=data[i];
        for(int bit=0;bit<8;++bit){ if(b&(1u<<bit)) flags+=' '+std::string(BIT_FLAGS[((i-10)*8)+bit]); }
    }
    return flags;
}

// Binary Content to Clang Options
// Now we skip only the first 2 bytes (not 4) to decode flags
std::string decodeFlagsFromBinary(const std::vector<uint8_t> &data) {
    return getFixedFlags() + " " + decodeFlagsFromBinarySub(data);
}

// Only 2 bytes now! We mod by 2505 to map to test_0.c..test_2504.c
std::string generateTestFileName(const std::vector<uint8_t> &data) {
    std::string testFilesDir = getEnvOrDefault("CFILES_DIR", "/users/user42/llvmSS-reindex-cfiles");
    // If fewer than 2 bytes, fallback to "hello.c"
    if (data.size() < 2) {
        return testFilesDir + "/test_1.c";
    }

    // Build 16-bit integer from the first 2 bytes
    uint16_t rawValue = 0;
    rawValue |= static_cast<uint16_t>(data[0]) << 0;
    rawValue |= static_cast<uint16_t>(data[1]) << 8;

    // 2,505 .c files → mod 2,505
    uint16_t fileCount = getEnvOrDefaultInt("FILE_COUNT", 1705);    
    uint16_t fileIndex = rawValue % fileCount;

    // Construct filename (e.g. test_1234.c)
    char buffer[32];
    snprintf(buffer, sizeof(buffer), "/test_%u.c", fileIndex);
    return testFilesDir + std::string(buffer);
}

// Parse text file (same as before)
std::pair<std::string, std::string> parseTextFile(const std::string &filename) {
    std::ifstream infile(filename);
    if (!infile) {
        std::cerr << "Error: Could not open text file " << filename << std::endl;
        exit(1);
    }

    std::string sourceFile;
    std::string flags;
    if (!std::getline(infile, sourceFile)) {
        std::cerr << "Error: Text file " << filename << " is empty or missing source file path." << std::endl;
        exit(1);
    }
    if (!std::getline(infile, flags)) {
        // No flags line? Just leave it empty
        flags = "";
    }

    return std::make_pair(sourceFile, flags);
}

// Clang Compilation
int runClangCompilation(const std::string &sourceFile, const std::string &flags) {
    llvm::IntrusiveRefCntPtr<clang::DiagnosticOptions> diagOpts = new clang::DiagnosticOptions();
    llvm::IntrusiveRefCntPtr<clang::DiagnosticsEngine> diags = new clang::DiagnosticsEngine(
        new clang::DiagnosticIDs(),
        diagOpts,
        new clang::TextDiagnosticPrinter(llvm::errs(), diagOpts.get())
    );

    std::string compilerPath = getEnvOrDefault("INSTRUMENTED_CLANG_PATH", "/users/user42/build/bin/clang");    
    clang::driver::Driver driver(compilerPath, llvm::sys::getDefaultTargetTriple(), *diags);

    std::vector<std::string> args = { compilerPath, "-x", "c", sourceFile };

    // Split the flags string by spaces
    std::istringstream flagStream(flags);
    std::string flag;
    while (flagStream >> flag) {
        args.push_back(flag);
    }

    // Convert args to const char*
    std::vector<const char*> cArgs;
    for (const std::string &arg : args) {
        cArgs.push_back(arg.c_str());
    }

    clang::driver::Compilation* rawCompilation = driver.BuildCompilation(cArgs);
    if (!rawCompilation) {
        llvm::errs() << "Error: Failed to build the compilation job.\n";
        return 1;
    }

    std::unique_ptr<clang::driver::Compilation> compilation(rawCompilation);
    llvm::SmallVector<std::pair<int, const clang::driver::Command*>, 4> FailingCommands;
    int result = driver.ExecuteCompilation(*compilation, FailingCommands);

    if (result != 0) {
        llvm::errs() << "Compilation failed with error code " << result << ".\n";
        for (const auto &cmd : FailingCommands) {
            llvm::errs() << "Failed Command: " << cmd.second->getExecutable() << "\n";
        }
    }
    return result;
}

int main(int argc, char* argv[]) {
    if (argc == 2 && std::string(argv[1]) == "--version") {
        std::cout << "Clang version: " << clang::getClangFullVersion() << std::endl;
        return 0;
    }

    // Command-line parameters
    std::string fileBin;
    std::string fileTxt;
    bool checkerMode = false;

    // Parse arguments
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--filebin") {
            if (i + 1 < argc) {
                fileBin = argv[++i];
            } else {
                std::cerr << "Error: --filebin requires a file path.\n";
                return 1;
            }
        } else if (arg == "--filetxt") {
            if (i + 1 < argc) {
                fileTxt = argv[++i];
            } else {
                std::cerr << "Error: --filetxt requires a file path.\n";
                return 1;
            }
        } else if (arg == "--checker") {
            checkerMode = true;
        } 
        // Add more arguments as needed
    }

    // If no input provided, print usage
    if (fileBin.empty() && fileTxt.empty()) {
        std::cerr << "Usage: " << argv[0] << " --filebin <binary_input> [--checker]\n"
                  << "       " << argv[0] << " --filetxt <text_input> [--checker]\n"
                  << "       " << argv[0] << " --version\n";
        return 1;
    }

    // Determine which input to parse
    std::string sourceFile;
    std::string flags;
    std::string subflags;

    if (!fileBin.empty()) {
        // Read and decode from binary
        std::vector<uint8_t> data = readBinaryFile(fileBin);
        sourceFile = generateTestFileName(data);
        subflags = decodeFlagsFromBinarySub(data);   // uses 2 bytes
        flags = decodeFlagsFromBinary(data);       // skip 2 bytes for flags
    } else if (!fileTxt.empty()) {
        // Read from text
        auto parsed = parseTextFile(fileTxt);
        sourceFile = parsed.first;
        flags = parsed.second;
    }

    // Checker mode: only print file & flags, no compilation
    if (checkerMode) {
        std::cout << "[Checker] Source File: " << sourceFile << std::endl;
        std::cout << "[Checker] Fixed Flags: " << getFixedFlags() << std::endl;
        std::cout << "[Checker] Flags: " << subflags << std::endl;
        return 0;
    }

    // Compile
    std::cout << "Using Source File: " << sourceFile << std::endl;
    std::cout << "Using Flags: " << flags << std::endl;

    return runClangCompilation(sourceFile, flags);
}
