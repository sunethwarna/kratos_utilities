#!/bin/zsh

#### This script should be only executed from the "scripts" folder of Kratos. ###

cpp_configuration_name=$1

if [ ! -d "../.venv" ]; then
    # if the python environment not found, then create it
    python -m venv ../.venv --system-site-packages
fi

# activate the python environment
source ../.venv/bin/activate

# activate intel mkl
source /opt/intel/oneapi/setvars.sh intel64

# Function to add apps
add_app () {
    export KRATOS_APPLICATIONS="${KRATOS_APPLICATIONS}$1;"
}

kratos_install_dir=$(python -c 'import site; print(site.getsitepackages()[0])')

# Set compiler
export compiler_type=$(echo $cpp_configuration_name | rev | cut -d"_" -f2 | rev)
export KRATOS_BUILD_TYPE=$(echo $cpp_configuration_name | rev | cut -d"_" -f1 | rev)
export KRATOS_CPP_CONFIG_NAME="${compiler_type}_${KRATOS_BUILD_TYPE}"

case $compiler_type in
    "gcc")
        export CC=gcc
        export CXX=g++
        ;;
    "clang")
        export CC=clang
        export CXX=clang++
        ;;
    "intel")
        export CC=icx
        export CXX=icpx
        ;;
    *)
        echo "-- Unsupported compiler type provided in environment variable KRATOS_CPP_CONFIG_NAME. [ cpp_configuration_name = \"$cpp_configuration_name\" ]. Followings are the accepted compiler types:"
        printf "\tgcc\n"
        printf "\tclang\n"
        printf "\tintel\n"
        exit
        ;;
esac

echo "===== Compiling kratos using \"$compiler_type\" in \"$KRATOS_BUILD_TYPE\"."

# Set variables
export KRATOS_SOURCE="${KRATOS_SOURCE:-"$( cd "$(dirname "$0")" ; pwd -P )"/..}"
export KRATOS_BUILD="${KRATOS_SOURCE}/build"
export KRATOS_APP_DIR="${KRATOS_SOURCE}/applications"
export KRATOS_INSTALL_PYTHON_USING_LINKS=ON

# Set basic configuration
export PYTHON_EXECUTABLE=${PYTHON_EXECUTABLE:-"python"}

# Set applications to compile
export KRATOS_APPLICATIONS=
# add_app ${KRATOS_APP_DIR}/MedApplication
# add_app ${KRATOS_APP_DIR}/StructuralMechanicsApplication
# add_app ${KRATOS_APP_DIR}/ConstitutiveLawsApplication
# add_app ${KRATOS_APP_DIR}/HDF5Application
# add_app ${KRATOS_APP_DIR}/MetisApplication
# add_app ${KRATOS_APP_DIR}/TrilinosApplication
# add_app ${KRATOS_APP_DIR}/LinearSolversApplication
# add_app ${KRATOS_APP_DIR}/ShapeOptimizationApplication
# add_app ${KRATOS_APP_DIR}/OptimizationApplication
# add_app ${KRATOS_APP_DIR}/SystemIdentificationApplication
# add_app ${KRATOS_APP_DIR}/MeshMovingApplication

# Clean
clear
rm -rf "${KRATOS_BUILD}/${KRATOS_CPP_CONFIG_NAME}/cmake_install.cmake"
rm -rf "${KRATOS_BUILD}/${KRATOS_CPP_CONFIG_NAME}/CMakeCache.txt"
rm -rf "${KRATOS_BUILD}/${KRATOS_CPP_CONFIG_NAME}/CMakeFiles"

# Configure
cmake -H"${KRATOS_SOURCE}" -B"${KRATOS_BUILD}/${KRATOS_CPP_CONFIG_NAME}"   \
-DCMAKE_INSTALL_PREFIX="${kratos_install_dir}"                             \
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

# clear the .kratos_info file
if [ -f "../.venv/.kratos_info" ]; then
    rm "../.venv/.kratos_info"
fi

echo "#!/bin/zsh" >> "../.venv/.kratos_info"
echo "export build_type=\"$KRATOS_CPP_CONFIG_NAME\"" >> "../.venv/.kratos_info"
