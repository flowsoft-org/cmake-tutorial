#!/bin/bash

# Copyright (c) 2022 IAR Systems AB
#
# Test CMake with the IAR Build Tools
#
# See LICENSE for detailed license information
#

# Environment variables that can be set for this script
#
# IAR_TOOL_ROOT
#   Top-level location in which the IAR toolchains are installed
#   MINGW64: with the full path (e.g.,) `/c/IAR_Systems/`
#   Default: /opt/iarsystems
#
# IAR_LMS2_SERVER_IP
#   If defined, automatic license setup will be performed
#
# MSYSTEM
#   Only required for Windows hosts (e.g., MINGW64 or CYGWIN)
#   Set by default by MINGW64 (and MINGW32)
#   CygWin users: must manually export the variable to CYGWIN
#   (e.g., export MSYSTEM=CYGWIN)
#

BUILD_CFGS=(Debug RelWithDebInfo Release MinSizeRel)

if ! ((${#IAR_TOOL_ROOT[@]})); then
  IAR_TOOL_ROOT=/opt/iarsystems
fi

if [ ! -z "$MSYSTEM" ]; then
  EXT=.exe;
fi

function lms2-setup() {
  if [ ! -z $IAR_LMS2_SERVER_IP ]; then
    LLM=$(dirname ${p})/../../common/bin/LightLicenseManager;
    if [ -f $LLM ]; then
      HAS_SETUP=$(${LLM} | grep setup);
      if [ ! -z $HAS_SETUP ]; then
        SETUP_CMD=setup;
      else
        SETUP_CMD="";
      fi
      $LLM $SETUP_CMD -s $IAR_LMS2_SERVER_IP;
    fi
  fi
}

function find_icc() {
  if [ -z "$MSYSTEM" ]; then
    export CC="${p}";
    export CXX="${p}";
  else
    export CC=$(cygpath -m "${p}");
    export CXX=$CC;
  fi
  export TOOLKIT_DIR=$(dirname $(dirname $CC))
  echo "Using  CC: $CC";
  echo "Using CXX: $CXX";
}

function find_ilink() {
  if [ -z "$MSYSTEM" ]; then
    export ASM=$(dirname ${p})/iasm${a};
  else
    export ASM=$(cygpath -m $(dirname ${p})/iasm${a}${EXT});
  fi
  echo "Using ASM: $ASM";
}

function find_xlink() {
  if [ ! -z "$MSYSTEM" ]; then
    export ASM=$(cygpath -m $(dirname ${p})/a${a}${EXT});
  else
    export ASM=$(dirname ${p})/a${a};
  fi
  echo "Using ASM_COMPILER: $ASM";
}

function cmake_configure() {
  rm -rf _builds;
  # If no CMAKE_MAKE_PROGRAM is set, defaults to ninja
  if [ -z "$CMAKE_MAKE_PROGRAM" ]; then
    if [ -z "$MSYSTEM" ]; then
      export CMAKE_MAKE_PROGRAM=$(which ninja);
    else
      export CMAKE_MAKE_PROGRAM=$(cygpath -m $(which ninja));
    fi
  fi
  if [ ! -f $CMAKE_MAKE_PROGRAM ]; then
    echo "FATAL ERROR: CMAKE_MAKE_PROGRAM not found ($CMAKE_MAKE_PROGRAM). No ninja executable found either.";
    exit 1;
  fi
  cmake -B _builds -G "Ninja Multi-Config" \
    -DTARGET_ARCH=${a} \
    -DTOOLKIT_DIR=${TOOLKIT_DIR};
  if [ $? -ne 0 ]; then
    echo "FAIL: CMake configuration phase.";
    exit 1;
  fi
}

function check_output() {
    if [ -f _builds/${cfg}/test-c.${OUTPUT_FORMAT,,} ]; then
      echo "+${cfg}:C   ${OUTPUT_FORMAT} built successfully.";
    else
      echo "-${cfg}:C   ${OUTPUT_FORMAT} not built.";
    fi
    if [ -f _builds/${cfg}/test-cxx.${OUTPUT_FORMAT,,} ]; then
      echo "+${cfg}:CXX ${OUTPUT_FORMAT} built successfully.";
    else
      echo "-${cfg}:CXX ${OUTPUT_FORMAT} not built.";
    fi
    if [ -f _builds/${cfg}/test-asm.${OUTPUT_FORMAT,,} ]; then
      echo "+${cfg}:ASM ${OUTPUT_FORMAT} built successfully.";
    else
      echo "-${cfg}:ASM ${OUTPUT_FORMAT} not built.";
    fi
}

function cmake_build() {
  for cfg in ${BUILD_CFGS[@]}; do
    echo "===== Build configuration: [${cfg}]";
    cmake --build _builds --config ${cfg} --verbose;
    if [ $? -ne 0 ]; then
      echo "FAIL: CMake building phase (${cfg}).";
      exit 1;
    fi
    check_output;
  done
}


echo "----------- ilink tools";
ILINK_TOOL=(arm riscv rh850 rl78 rx stm8);
OUTPUT_FORMAT=ELF;
for r in ${IAR_TOOL_ROOT[@]}; do
  for a in ${ILINK_TOOL[@]}; do
    for b in $(find ${r} -path "*/${a}/bin"); do
      for p in $(find ${b} -executable -name icc${a}${EXT}); do
        find_icc;
        find_ilink;
        lms2-setup;
        cmake_configure;
        cmake_build;
      done
    done
  done
done

echo "----------- xlink tools";
XLINK_TOOL=(8051 430 avr);
OUTPUT_FORMAT=BIN;
for r in ${IAR_TOOL_ROOT[@]}; do
  for a in ${XLINK_TOOL[@]}; do
    for b in $(find ${r} -path "*/${a}/bin"); do
      for p in $(find ${b} -executable -name icc${a}${EXT}); do
        find_icc;
        find_xlink;
        lms2-setup;
        cmake_configure;
        cmake_build;
      done
    done
  done
done
