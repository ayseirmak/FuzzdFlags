
#!/bin/bash
working_folder=$1
llvm_ver=$2

TMP_SOURCE_FOLDER=$(mktemp -d $working_folder/.sources_$2V.XXXXXXX.tmp)
cd $TMP_SOURCE_FOLDER

## Clone LLVM project
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
git checkout release/$llvm_ver.x

echo ">> Downloading LLVM source ($TMP_SOURCE_FOLDER)"
