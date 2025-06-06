# FuzzdFlags
![image](https://github.com/user-attachments/assets/6639b6bb-14f8-4140-bb85-064f742d8109)

### Fast LLVM-based instrumentation for afl-fuzz

1. Instrumented with use `afl-clang-fast/afl-clang-fast++` 
2. Instrumented with use `afl-clang-lto/afl-clang-lto++ `
     Requires a LLVM 12 or newer. 
      AR=llvm-ar RANLIB=llvm-ranlib AS=llvm-as. 
     Some targets might need `LD=afl-clang-lto` and others `LD=afl-ld-lto`.
3. Instrumented with `afl-clang-fast/afl-clang-fast++` &&  Different coverage method:
     **a. N-GRAM coverage**
    (https://github.com/AFLplusplus/AFLplusplus/blob/stable/instrumentation/README.llvm.md#7-afl-n-gram-branch-coverage)
    llvm should be build on the top of `AFL's QEMU mode`. 
    `AFL_LLVM_NGRAM_SIZE= Good values are 2, 4, or 8` 
    It is highly recommended to increase the `MAP_SIZE_POW2` definition in config.h to at least **18** and maybe up to **20** - better in big targets.
     **b. Context sensitive coverage** 
     (https://github.com/AFLplusplus/AFLplusplus/blob/stable/instrumentation/README.llvm.md#6-afl-context-sensitive-branch-coverage)
     `AFL_LLVM_CTX=1` 
     `MAP_SIZE_POW2` definition in config.h to at least 18 and maybe up to 20 
     If the context sensitive coverage introduces too many collisions and becoming detrimental 
     `AFL_LLVM_CALLER=1` 

| Scenario                                      | Settings                                                     |
|-----------------------------------------------|--------------------------------------------------------------|
| Small CLI utility, default pc-guard           | *(do nothing)* – 64 KiB is fine                              |
| Medium library (30 k edges), CTX = 1          | `MAP_SIZE_POW2=18` (256 KiB)<br>`AFL_MAP_SIZE=262144`         |
| Large project (≥ 3 M edges), Ngram = 4        | `MAP_SIZE_POW2=22` (4 MiB)<br>`AFL_MAP_SIZE=4194304`          |
| Monster (LLVM, Firefox) with Ngram = 8        | `MAP_SIZE_POW2=24` (16 MiB)<br>`AFL_MAP_SIZE=16777216`        |


For changing MAP_SIZE_POW_2 you can do either of two methods
    1. open AFLplusplus/include/config.h and change #define MAP_SIZE_POW2 16 to a bigger exponent  or pass MAP_SIZE_POW2=<n> once on the make distrib command line; then rebuild AFL++ and re-compile clang 
  
 ```
       cd ~/AFLplusplus
        make clean
        MAP_SIZE_POW2=24 make distrib 
        sudo make install or export PATH=$PWD:$PATH

        export AFL_MAP_SIZE=16777216        
        afl-fuzz -i seeds -o out -- ./clang-options --filebin @@
```
Estimate edge count. 
Build once, run with `AFL_DEBUG=1 ./target --version; note __afl_final_loc.`

> `MAP_SIZE_POW2` compile time env var read by AFL
> `AFL_MAP_SIZE` run time env var read by the AFL instrumentation of target
> `AFL_LLVM_NGRAM_SIZE` or `AFL_LLVM_CTX=1` or `AFL_LLVM_CALLER=1` compile-time env-var, read by the LLVM pass








