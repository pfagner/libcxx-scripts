#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
source "${SCRIPT_DIR}/config.sh"

# debug flags
EXTRA_C_FLAGS="-O0 -g"
EXTRA_CXX_FLAGS="-O0 -g"

# common flags
CMAKE_FLAGS=(
  "-DCMAKE_BUILD_TYPE=Debug"
  "-DCMAKE_CXX_COMPILER=clang++"
  "-DCMAKE_C_COMPILER=clang"
  "-DCMAKE_INSTALL_PREFIX=${OUT_DIR}"
  "-DLIBCXXABI_LIBCXX_INCLUDES=${LIBCXX_SRC}/include"
  "-DLLVM_ABI_BREAKING_CHECKS=WITH_ASSERTS"
)

if [ "${CROSS_COMPILING}" = "arm" ]; then
  # HACK: find cross compiling system include path
  DIR="/usr/arm-linux-gnueabihf/include"
  if [ -d "${DIR}" ]; then
    EXTRA_C_FLAGS="${EXTRA_C_FLAGS} -isystem ${DIR}"
    EXTRA_CXX_FLAGS="${EXTRA_CXX_FLAGS} -isystem ${DIR}"

    DIR="${DIR}/c++"
    if [ -d "${DIR}" ]; then
      VER="$(ls "${DIR}")"

      DIR="${DIR}/${VER}"
      if [ -d "${DIR}" ]; then
        EXTRA_CXX_FLAGS="${EXTRA_CXX_FLAGS} -isystem ${DIR}"
      fi

      DIR="${DIR}/arm-linux-gnueabihf"
      if [ -d "${DIR}" ]; then
        EXTRA_CXX_FLAGS="${EXTRA_CXX_FLAGS} -isystem ${DIR}"
      fi
    fi
  fi

  EXTRA_C_FLAGS="--target=arm-linux-gnueabihf ${EXTRA_C_FLAGS}"
  EXTRA_CXX_FLAGS="--target=arm-linux-gnueabihf ${EXTRA_CXX_FLAGS}"
  EXTRA_LD_FLAGS="-L${OUT_DIR}/lib"

  CMAKE_FLAGS+=(
    "-DCMAKE_SYSTEM_PROCESSOR=arm"
    "-DCMAKE_SYSTEM_NAME=Linux"
    "-DCMAKE_CROSSCOMPILING=True"
    "-DCMAKE_EXE_LINKER_FLAGS=${EXTRA_LD_FLAGS} -lgcc_s"
    "-DCMAKE_SHARED_LINKER_FLAGS=${EXTRA_LD_FLAGS} -lgcc_s"
    "-DCMAKE_MODULE_LINKER_FLAGS=${EXTRA_LD_FLAGS}"
  )
fi

if [ "${ENABLE_LIBUNWIND}" = "1" ]; then
  CMAKE_FLAGS+=(
    "-DLIBCXXABI_USE_LLVM_UNWINDER=1"
    "-DLIBCXXABI_LIBUNWIND_INCLUDES=${LIBUNWIND_SRC}/include"
    "-DLIBCXXABI_LIBUNWIND_SOURCES=${LIBUNWIND_SRC}/src"
    "-DLIBUNWIND_ENABLE_SHARED=1"
  )
fi

CMAKE_FLAGS+=(
  "-DCMAKE_C_FLAGS=${EXTRA_C_FLAGS}"
  "-DCMAKE_CXX_FLAGS=${EXTRA_CXX_FLAGS}"
)

mkdir -p "${LIBCXXABI_OBJ}"
cd "${LIBCXXABI_OBJ}"

cmake -G "Unix Makefiles" "${CMAKE_FLAGS[@]}" "${LIBCXXABI_SRC}"

make -j16

make install

echo done.
