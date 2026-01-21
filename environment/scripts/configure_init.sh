#!/bin/zsh

#### This script should be only executed from the "scripts" folder of Kratos. ###

python_venv_path=<PYTHON_VENV_PATH>
kratos_name=$(pwd | rev | cut -d"/" -f2 | rev)

RED='\033[0;31m'
RESET='\033[0m'

if [ ! -z "$VIRTUAL_ENV" ]; then
    if [ ! -z "$1" ]; then
        echo "-- Found already existing kratos environment initialization, therefore no input cpp configuration names are allowed [ cpp_configuration_name = \"$1\" ]."
        exit
    fi
    python_venv_name=$(which python | rev | cut -d"/" -f3 | rev)

    python_venv_kratos_name=$(echo $python_venv_name | cut -d"_" -f1)
    if [ "$kratos_name" != "$python_venv_kratos_name" ]; then
        echo -e "-- ${RED}Error: Initialized python environment (\"$python_venv_kratos_name\") and the kratos folder (\"$kratos_name\") mismatch.${RESET}"
        exit
    fi

    # Set compiler
    compiler_type=$(echo $python_venv_name | rev | cut -d"_" -f2 | rev)
    export KRATOS_BUILD_TYPE=$(echo $python_venv_name | rev | cut -d"_" -f1 | rev)
    export KRATOS_CPP_CONFIG_NAME="${compiler_type}_${KRATOS_BUILD_TYPE}"
else
    cpp_configuration_name=$1
    if [ ! -d "$python_venv_path/${kratos_name}_${cpp_configuration_name}" ]; then
        # if the python environment not found, then create it
        python -m venv "$python_venv_path/${kratos_name}_${cpp_configuration_name}" --system-site-packages
    fi
    # activate the python environment
    source $python_venv_path/${kratos_name}_${cpp_configuration_name}/bin/activate

    # Set compiler
    compiler_type=$(echo $cpp_configuration_name | rev | cut -d"_" -f2 | rev)
    export KRATOS_BUILD_TYPE=$(echo $cpp_configuration_name | rev | cut -d"_" -f1 | rev)
    export KRATOS_CPP_CONFIG_NAME="${compiler_type}_${KRATOS_BUILD_TYPE}"
fi

export KRATOS_INSTALL_DIR=$(python -c 'import site; print(site.getsitepackages()[0])')

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