#!/bin/zsh

#### This script should be only executed from the "scripts" folder of Kratos. ###

. ./configure_init.sh $1

echo "===== Compiling kratos using \"$CC\" and \"$CXX\" in \"$KRATOS_BUILD_TYPE\"."

# activate intel mkl
. /opt/intel/oneapi/setvars.sh intel64

# Function to add apps
add_app () {
    export KRATOS_APPLICATIONS="${KRATOS_APPLICATIONS}$1;"
}

# Set variables
export KRATOS_SOURCE="${KRATOS_SOURCE:-"$( cd "$(dirname "$0")" ; pwd -P )"/..}"
export KRATOS_BUILD="${KRATOS_SOURCE}/build"
export KRATOS_APP_DIR="${KRATOS_SOURCE}/applications"
export KRATOS_INSTALL_PYTHON_USING_LINKS=ON

# Set basic configuration
export PYTHON_EXECUTABLE=${PYTHON_EXECUTABLE:-"python"}

# Set applications to compile
export KRATOS_APPLICATIONS=
# add_app ${KRATOS_APP_DIR}/StructuralMechanicsApplication
# add_app ${KRATOS_APP_DIR}/ConstitutiveLawsApplication
# add_app ${KRATOS_APP_DIR}/LinearSolversApplication
# add_app ${KRATOS_APP_DIR}/OptimizationApplication
# add_app ${KRATOS_APP_DIR}/MeshMovingApplication
# add_app ${KRATOS_APP_DIR}/MedApplication
# add_app ${KRATOS_APP_DIR}/HDF5Application
# add_app ${KRATOS_APP_DIR}/MetisApplication
# add_app ${KRATOS_APP_DIR}/TrilinosApplication
# add_app ${KRATOS_APP_DIR}/ShapeOptimizationApplication
# add_app ${KRATOS_APP_DIR}/SystemIdentificationApplication

# Clean
clear
rm -rf "${KRATOS_BUILD}/${KRATOS_CPP_CONFIG_NAME}/cmake_install.cmake"
rm -rf "${KRATOS_BUILD}/${KRATOS_CPP_CONFIG_NAME}/CMakeCache.txt"
rm -rf "${KRATOS_BUILD}/${KRATOS_CPP_CONFIG_NAME}/CMakeFiles"

# Configure
cmake -H"${KRATOS_SOURCE}" -B"${KRATOS_BUILD}/${KRATOS_CPP_CONFIG_NAME}"   \
-DCMAKE_INSTALL_PREFIX="${KRATOS_INSTALL_DIR}"                             \
-DCMAKE_EXPORT_COMPILE_COMMANDS=ON                                         \
-DUSE_MPI=ON                                                               \
-DCMAKE_CXX_COMPILER_LAUNCHER=ccache                                       \
-DKRATOS_GENERATE_PYTHON_STUBS=ON                                          \
-DKRATOS_USE_FUTURE=OFF                                                    \
-DUSE_EIGEN_SUITESPARSE=ON                                                 \
# -DCMAKE_UNITY_BUILD=ON                                                     \
# -DUSE_EIGEN_MKL=ON                                                         \
# -DKRATOS_BUILD_BENCHMARK=ON                                                \

# Buid
cmake --build "${KRATOS_BUILD}/${KRATOS_CPP_CONFIG_NAME}" --target install -j10

# link the cpp tests
ln -sf ${KRATOS_INSTALL_DIR}/test "${KRATOS_BUILD}/${KRATOS_CPP_CONFIG_NAME}/test"
