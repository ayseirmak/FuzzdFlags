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


static const std::vector<std::string> flagList = {
 "-march=x86-64",
 "-march=x86-64-v3",
 "-march=x86-64-v4",
 "-march=skylake-avx512",  
 "-march=znver4", 
 "-march=native",
 "-mavx",
 "-mavx2",
 "-mavx512f",
 "-mavx512vl",
 "-mfma", 
 "-mbmi2",    
 "-msha",      
 "-maes",
 "-mno-avx2", 
 "-mno-sse4.2",
 "-fno-finite-loops",
 "-fexcess-precision=fast",
 "-fno-use-init-array",
 "-faligned-allocation",
 "-fassume-unique-vtables",
 "-faccess-control",
 "-ftrapping-math",
 "-fexcess-precision=standard",
 "-fno-addrsig",
 "-fno-honor-nans",
 "-fno-unroll-loops",
 "-fstrict-return",
 "-fstack-protector-strong",
 "-fuse-init-array",
 "-fno-honor-infinities",
 "-Oz",
 "-fsigned-zeros",
 "-fno-unsafe-math-optimizations",
 "-funsafe-math-optimizations",
 "-fjump-tables",
 "-O3",
 "-fno-strict-overflow",
 "-fno-associative-math",
 "-ffp-exception-behavior=ignore",
 "-freroll-loops",
 "-fno-strict-aliasing",
 "-funroll-loops",
 "-ffinite-math-only",
 "-fprotect-parens",
 "-ftls-model=local-exec",
 "-ffp-eval-method=source",
 "-fblocks",
 "-fdenormal-fp-math=positive-zero",
 "-fdenormal-fp-math=preserve-sign",
 "-fno-jump-tables",
 "-femulated-tls",
 "-fstrict-overflow",
 "-fstrict-enums",
 "-ffast-math",
 "-fno-trapping-math",
 "-ffp-exception-behavior=strict",
 "-malign-double",
 "-fno-finite-math-only",
 "-fforce-emit-vtables",
 "-fno-keep-static-consts",
 "-fstrict-vtable-pointers",
 "-funsigned-bitfields",
 "-ffp-model=precise",
 "-fno-unsigned-char",
 "-ftrapv",
 "-fno-unique-section-names",
 "-fno-sized-deallocation",
 "-fno-assume-sane-operator-new",
 "-fno-signed-char",
 "-flax-vector-conversions",
 "-funique-section-names",
 "-fsized-deallocation",
 "-fno-rounding-math",
 "-fassociative-math",
 "-fsignaling-math",
 "-fno-strict-return",
 "-fno-blocks",
 "-ftls-model=global-dynamic",
 "-fno-assume-unique-vtables",
 "-fstack-size-section",
 "-fwrapv",
 "-fast",
 "-ffp-model=strict",
 "-flax-vector-conversions=integer",
 "-fstack-protector-all",
 "-Os",
 "-fno-asm-blocks",
 "-fno-math-errno",
 "-fno-approx-func",
 "-fwritable-strings",
 "-fno-protect-parens",
 "-ftls-model=local-dynamic",
 "-fno-fixed-point",
 "-ffp-contract=off",
 "-fno-align-functions",
 "-fstrict-aliasing",
 "-fno-stack-protector",
 "-flax-vector-conversions=none",
 "-falign-functions",
 "-fno-strict-float-cast-overflow",
 "-fvectorize",
 "-faddrsig",
 "-ffp-eval-method=double",
 "-fapprox-func",
 "-fno-strict-enums",
 "-ffp-exception-behavior=maytrap",
 "-fhonor-nans",
 "-ftls-model=initial-exec",
 "-ffinite-loops",
 "-fkeep-static-consts",
 "-fstrict-float-cast-overflow",
 "-ffp-contract=fast",
 "-fno-fast-math",
 "-fno-reciprocal-math",
 "-funsigned-char",
 "-frounding-math",
 "-fno-reroll-loops",
 "-fhonor-infinities",
 "-fdenormal-fp-math=ieee",
 "-ffixed-point",
 "-fno-signaling-math",
 "-fno-split-stack",
 "-fno-lax-vector-conversions",
 "-fno-keep-persistent-storage-variables",
 "-fkeep-persistent-storage-variables",
 "-fstack-protector",
 "-fassume-sane-operator-new",
 "-Ofast",
 "-fsplit-stack",
 "-ffp-eval-method=extended",
 "-O2",
 "-ffp-contract=on",
 "-fno-asm",
 "-fno-wrapv",
 "-fno-vectorize",
 "-fsigned-char",
 "-ffunction-sections",
 "-fno-stack-size-section",
 "-fno-signed-zeros",
 "-O1",
 "-funwind-tables",
 "-fsigned-bitfields",
 "-fno-access-control",
 "-fno-strict-vtable-pointers",
 "-fno-unwind-tables",
 "-fno-function-sections",
 "-freciprocal-math",
 "-fmath-errno",
 "-fno-aligned-allocation",
 "-faligned-new",
 "-ffp-model=fast",
};

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
    baseFlags += " -lm"
    return baseFlags;
}

// Bayt -> Flags Mapping Fuction

std::string decodeByteToFlags(uint8_t b) {
    if (b < flagList.size())
        return flagList[b];
    return "";
}

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
    for (size_t i = 2; i < data.size(); i++) {
        std::string flagSet = decodeByteToFlags(data[i]);
        if (!flagSet.empty()) {
            flags += flagSet + " ";
        }
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
