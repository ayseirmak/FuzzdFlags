#!/bin/bash
cd ~

# install packages
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt-get update

sudo apt install -y cmake
sudo apt-get install -y m4
sudo apt install -y ninja-build
sudo apt install -y fdupes
sudo apt install -y python3
sudo apt install -y python3-pip

sudo apt-get -y install autoconf 
sudo apt-get install -qq -yy libgmp-dev 
sudo apt-get -y install libgnomecanvas2-dev
sudo apt-get -y install graphviz
sudo apt-get install -qq -yy libgtksourceview2.0-dev
sudo apt-get -y install libexporter-lite-perl libfile-which-perl libgetopt-tabular-perl   
sudo apt-get -y install libregexp-common-perl flex build-essential zlib1g-dev
sudo apt-get -y install libterm-readkey-perl

## install compilers
sudo apt-get -y install gcc-11 g++-11 cpp-11
sudo apt-get -y install gcc-10 g++-10 cpp-10

## set gcov
sudo apt-get -y install lld-10 llvm-10 llvm-10-dev clang-10 clang++-10
sudo apt-get -y install clang-format-10
sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-10 100 --slave /usr/bin/clang++ clag++ /usr/bin/clang++-10

sudo apt-get -y install lld-11 llvm-11 llvm-11-dev clang-11 clang++-11
sudo apt-get -y install clang-format-11
sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-11 110 --slave /usr/bin/clang++ clag++ /usr/bin/clang++-11

sudo apt-get install -y lld-12 llvm-12 llvm-12-dev clang-12 clang++-12 
sudo apt-get -y install  clang-format-12
sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-12 120 --slave /usr/bin/clang++ clag++ /usr/bin/clang++-12

## Set gcov
sudo rm /usr/bin/cpp /usr/bin/gcc /usr/bin/g++  /usr/bin/gcov  /usr/bin/c++
sudo rm /usr/local/bin/cpp /usr/local/bin/gcc /usr/local/bin/g++ /usr/local/bin/gcov  /usr/local/bin/c++
sudo ln -s /usr/bin/cpp-11 /usr/bin/cpp
sudo ln -s /usr/bin/gcc-11 /usr/bin/gcc
sudo ln -s /usr/bin/g++-11 /usr/bin/g++
sudo ln -s /usr/bin/g++-11 /usr/bin/c++
sudo ln -s /usr/bin/gcov-11 /usr/bin/gcov

# For Cmake
sudo apt-get install libssl-dev