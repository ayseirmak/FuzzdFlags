set(CLANG_OPTIONS_MAIN ClangOptions.cpp)

set(LLVM_LINK_COMPONENTS
  Support
)

add_clang_executable(clang-options
  EXCLUDE_FROM_ALL
  ${CLANG_OPTIONS_MAIN}
  ClangOptions.cpp
  )

target_link_libraries(clang-options
  PRIVATE
  clangBasic
  clangFrontend
)
# Needed by LLVM's CMake checks because this file defines multiple targets.
set(LLVM_OPTIONAL_SOURCES
  ClangOptions.cpp
  )
