# set the minimum required version of CMake to be 3.20
cmake_minimum_required(VERSION 3.20)

# set the project name
project(Tutorial)

# add the executable target
add_executable(tutorial)

# target sources
target_sources(tutorial PRIVATE tutorial.c)

# compiler options
target_compile_options(tutorial PRIVATE --cpu=cortex-m4)

# linker options
target_link_options(tutorial PRIVATE
  --cpu=cortex-m4
  --semihosting)

# TODO 1: Enable testing in CMake
enable_testing()

# TODO 2: Add a test named `tutorialTest` for `tutorial` (hint: use CSpyBat)
add_test(NAME tutorialTest
         COMMAND /opt/iar/cxarm/common/bin/CSpyBat
         # C-SPY drivers for the Arm simulator via command line interface
         /opt/iar/cxarm/arm/bin/libarmPROC.so
         /opt/iar/cxarm/arm/bin/libarmSIM2.so
         --plugin=/opt/iar/cxarm/arm/bin/libarmLibsupportUniversal.so
         # The target executable (built with debug information)
         --debug_file=$<TARGET_FILE:tutorial>
         # C-SPY driver options
         --backend
           --cpu=cortex-m4
           --semihosting)

# TODO 3: Set the `tutorialTest` test passing condition
set_tests_properties(tutorialTest PROPERTIES PASS_REGULAR_EXPRESSION "Hello world!")
