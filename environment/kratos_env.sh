#!/bin/zsh

export OMP_NUM_THREADS=30
export KRATOS_WORKTREE_MASTER_PATH="/software/kratos/master"
export PYTHON_VENV_PATH="/software/python_venv"
utilities_directory="/software/kratos/kratos_utilities/environment"

export KRATOS_BASE_PATH=$(dirname $KRATOS_WORKTREE_MASTER_PATH)

Help()
{
    echo "Initializes specified kratos environment in the current terminal."
    echo
    echo " Syntax: sh kratos_env.sh [options] [environment name] [[compiler] [build_mode] | [branch_name]]"
    echo "options:"
    echo "          -h, --help   : Displays this help message."
    echo "          -s, --summary: Displays summary of work trees."
    echo "          -c, --create : Add a new branch with [branch_name] and create the work tree with [environment name]"
    echo "          -a, --add    : Add a new work tree with [environment name] for branch with [branch_name]"
    echo "          -u, --update : Update a  work tree with [environment name]"
    echo "          -r, --remove : Remove [environment name] worktree."
    echo "input arguments:"
    echo "            compiler: gcc, clang, intel"
    echo "          build_mode: release, rel_with_deb_info, debug, full_debug"
    echo "    environment name: please see the below worktree information for available environment names"
    echo

    current_path=$(pwd)
    cd $KRATOS_WORKTREE_MASTER_PATH

    echo "Worktree information:"
    printf "\t%30s\t%s\n" "----------------" "------"
    printf "\t%30s\t%s\n" "environment name" "branch"
    printf "\t%30s\t%s\n" "----------------" "------"
    git worktree list --porcelain | while read -r worktree_line
    do
        item_0=$(echo $worktree_line | cut -d" " -f1)
        item_1=$(echo $worktree_line | cut -d" " -f2)

        case $item_0 in
            "worktree")
            worktree_name=$(echo $item_1 | rev | cut -d"/" -f1 | rev)
            ;;

            "branch")
            worktree_branch=$(echo $item_1)
            printf "\t%30s" $worktree_name
            printf "\t%s\n" ${worktree_branch:11}
            ;;

            "detached")
            worktree_branch="detached[$worktree_hash]"
            printf "\t%30s" $worktree_name
            printf "\t%s\n" $worktree_branch
            ;;

            "HEAD")
            worktree_hash=$(echo $item_1)
            ;;
        esac
    done
    cd $current_path

    echo
    echo "Once the environment is initialized successfully, then following commands can be accessed."
    echo
    echo "            kratos_compile: Compiles currently loaded kratos environment and re-initializes the environment"
    echo "      kratos_compile_clean: Cleans and compiles currently loaded kratos environment and re-initializes the environment"
    echo "    kratos_paraview_output: Creates xdmf file using the given h5 files for paraview visualization"
    echo "             kratos_unload: Unloads kratos environment"
}

GetCompiledApplicationsList()
{
    if [ -f "$KRATOS_BASE_PATH/$worktree_name/scripts/configure.sh" ]; then
        potential_compiled_applications=$(grep "add_app \${KRATOS_APP_DIR}" "$KRATOS_BASE_PATH/$worktree_name/scripts/configure.sh")
        while IFS= read -r line; do
            if [[ ${line:0:1} != "#" ]]; then
                printf "\t                      %s\n" ${line:26}
            fi
        done <<< "$potential_compiled_applications"
    fi
}

Summary()
{
    echo "Details of the available kratos environments:"

    current_path=$(pwd)
    cd $KRATOS_WORKTREE_MASTER_PATH

    git worktree list --porcelain | while read -r worktree_line
    do
        item_0=$(echo $worktree_line | cut -d" " -f1)
        item_1=$(echo $worktree_line | cut -d" " -f2)

        case $item_0 in
            "worktree")
            worktree_name=$(echo $item_1 | rev | cut -d"/" -f1 | rev)
            ;;

            "branch")
            worktree_branch=$(echo $item_1)
            printf "\t-------------------\n"
            printf "\tEnvironment name  :%s\n" $worktree_name
            printf "\t            branch:%s\n" ${worktree_branch:11}
            printf "\t              apps:\n"
            GetCompiledApplicationsList
            printf "\t-------------------\n"
            ;;

            "detached")
            worktree_branch="detached[$worktree_hash]"
            printf "\t-------------------\n"
            printf "\tEnvironment name  :%s\n" $worktree_name
            printf "\t            branch:%s\n" $worktree_branch
            printf "\t              apps:\n"
            GetCompiledApplicationsList
            printf "\t-------------------\n"
            ;;

            "HEAD")
            worktree_hash=$(echo $item_1)
            ;;
        esac
    done
    cd $current_path
}

CheckEnvironmentName()
{
    arr_names=""
    current_path=$(pwd)
    cd $KRATOS_WORKTREE_MASTER_PATH
    data=$(git worktree list --porcelain | grep "worktree " | sed "s/worktree\ /_/g")
    cd $current_path

    temp_environment_name=""
    while IFS= read -r data_item; do
        name=$(echo $data_item | rev | cut -d"/" -f1 | rev)
        if [ "$name" = "$environment_name" ]; then
            temp_environment_name="$environment_name"
        fi
    done <<< "$data"

    is_valid_options=true
    if [ -z $temp_environment_name ]; then
        echo "-- Unsupported environment name=\"$environment_name\". Followings are the valid environment names: (use -h or --help to see full details)"
        while IFS= read -r data_item; do
            name=$(echo $data_item | rev | cut -d"/" -f1 | rev)
            printf "\t%s \n" $name
        done <<< "$data"
        is_valid_options=false
    fi
}

ConfigureVariables()
{
    case $compiler_type in
        "gcc")
            ;;
        "clang")
            ;;
        "intel")
            ;;
        *)
            echo "-- Unsupported compiler type=\"$compiler_type\" provided. Followings are the valid compiler types: (use -h or --help to see full details)"
            printf "\tgcc\n"
            printf "\tclang\n"
            printf "\tintel\n"
            is_valid_options=false
            ;;
    esac

    case $build_type in
        "release")
            export KRATOS_BUILD_TYPE="Release"
            ;;
        "rel_with_deb_info")
            export KRATOS_BUILD_TYPE="RelWithDebInfo"
            ;;
        "debug")
            export KRATOS_BUILD_TYPE="Debug"
            ;;
        "full_debug")
            export KRATOS_BUILD_TYPE="FullDebug"
            ;;
        *)
            echo "-- Unsupported build type=\"$build_type\" provided. Followings are the valid build types: (use -h or --help to see full details)"
            printf "\trelease\n"
            printf "\trel_with_deb_info\n"
            printf "\tdebug\n"
            printf "\tfull_debug\n"
            is_valid_options=false
            ;;
    esac

    export KRATOS_CPP_CONFIG_NAME=$(echo "${compiler_type}_${KRATOS_BUILD_TYPE}")
}

ReInitializeVirtualEnvironment()
{
    venv_name="$1"
    venv_path=$PYTHON_VENV_PATH/$venv_name
    if [ -d $venv_path ]; then
        rm -r $venv_path
    fi

    cur_dir=$(pwd)
    kratos_libs_path="$venv_path/lib"
    virtualenv $venv_path --system-site-packages
    source $PYTHON_VENV_PATH/$venv_name/bin/activate
    site_packages_dir=$(python -c 'import site; print(site.getsitepackages()[0])')
    deactivate
    echo "export LD_LIBRARY_PATH=$site_packages_dir/libs:\$LD_LIBRARY_PATH" >> $venv_path/bin/activate
}

InitalizePythonVirtualEnvironment()
{
    venv_name="$1"
    venv_path=$PYTHON_VENV_PATH/$venv_name
    if [ ! -d $venv_path ]; then
        ReInitializeVirtualEnvironment $venv_name
    fi
    source $PYTHON_VENV_PATH/$venv_name/bin/activate
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    Help
elif [ "$1" = "-s" ] || [ "$1" = "--summary" ]; then
    Summary
elif [ "$1" = "-r" ] || [ "$1" = "--remove" ]; then
    environment_name=$2
    CheckEnvironmentName
    if $is_valid_options
    then
        current_path=$(pwd)
        cd $KRATOS_WORKTREE_MASTER_PATH
        git worktree remove $environment_name
        cd $current_path
    fi
elif [ "$1" = "-c" ] || [ "$1" = "--create" ]; then
    current_path=$(pwd)
    cd $KRATOS_WORKTREE_MASTER_PATH
    git checkout master
    git pull
    git checkout -b $3
    git checkout master
    git worktree add ../$2 $3
    cd $current_path
elif [ "$1" = "-a" ] || [ "$1" = "--add" ]; then
    current_path=$(pwd)
    cd $KRATOS_WORKTREE_MASTER_PATH
    git checkout master
    git pull
    git worktree add ../$2 $3
    cd $current_path
elif [ "$1" = "-u" ] || [ "$1" = "--update" ]; then
    environment_name=$2
    compiler_type=$3
    build_type=$4

    CheckEnvironmentName

    ConfigureVariables

    if $is_valid_options
    then
        ReInitializeVirtualEnvironment ${environment_name}_${compiler_type}_${KRATOS_BUILD_TYPE}
    fi
else
    environment_name=$1
    compiler_type=$2
    build_type=$3

    CheckEnvironmentName

    ConfigureVariables

    if $is_valid_options
    then
        if [ ! -z "$VIRTUAL_ENV" ]; then
            echo "-- Found already existing kratos environment initialization."
            echo "-- Please use \"deactivate\" to deactivate existing environment and try again to load the new environment."
        else
            KRATOS_PATH=$KRATOS_BASE_PATH/$environment_name
            KRATOS_BINARY_PATH=${KRATOS_PATH}/bin/${compiler_type}_${KRATOS_BUILD_TYPE}
            KRATOS_LIBS_PATH=$KRATOS_BINARY_PATH/libs
            InitalizePythonVirtualEnvironment ${environment_name}_${compiler_type}_${KRATOS_BUILD_TYPE}

            if [ ! -f $KRATOS_PATH/scripts/configure.sh ]; then
                echo "-- No default $KRATOS_PATH/scripts/configure.sh found. Copying the templated $utilities_directory/configure.sh.orig. file"
                cp $utilities_directory/configure.sh.orig $KRATOS_PATH/scripts/configure.sh
                sed -i "s/<KRATOS_NAME>/$environment_name/g" $KRATOS_PATH/scripts/configure.sh
            fi

            if [ ! -f $KRATOS_PATH/.vscode/c_cpp_properties.json ]; then
                echo "-- No default $KRATOS_PATH/.vscode/c_cpp_properties.json found. Copying the templated $utilities_directory/c_cpp_properties.json.orig. file"
                mkdir -p $KRATOS_PATH/.vscode
                cp $utilities_directory/c_cpp_properties.json.orig $KRATOS_PATH/.vscode/c_cpp_properties.json
            fi

            if [ ! -f $KRATOS_PATH/.vscode/settings.json ]; then
                echo "-- No default $KRATOS_PATH/.vscode/settings.json found. Copying the templated $utilities_directory/settings.json.orig. file"
                mkdir -p $KRATOS_PATH/.vscode
                cp $utilities_directory/settings.json.orig $KRATOS_PATH/.vscode/settings.json
            fi

            if [ ! -f $KRATOS_PATH/.vscode/tasks.json ]; then
                echo "-- No default $KRATOS_PATH/.vscode/tasks.json found. Copying the templated $utilities_directory/tasks.json.orig. file"
                mkdir -p $KRATOS_PATH/.vscode
                cp $utilities_directory/tasks.json.orig $KRATOS_PATH/.vscode/tasks.json
            fi

            if [ ! -f $KRATOS_PATH/.vscode/launch.json ]; then
                echo "-- No default $KRATOS_PATH/.vscode/launch.json found. Copying the templated $utilities_directory/launch.json.orig. file"
                mkdir -p $KRATOS_PATH/.vscode
                cp $utilities_directory/launch.json.orig $KRATOS_PATH/.vscode/launch.json
            fi

            if [ ! -f $KRATOS_PATH/.vscode/cpp_test.py ]; then
                echo "-- No default $KRATOS_PATH/.vscode/cpp_test.py found. Copying the templated $utilities_directory/cpp_test.py file"
                mkdir -p $KRATOS_PATH/.vscode
                cp $utilities_directory/cpp_test.py $KRATOS_PATH/.vscode/cpp_test.py
            fi

            if [ ! -f $KRATOS_PATH/.clang-format ]; then
                echo "-- No default $KRATOS_PATH/.clang-format found. Copying the $utilities_directory/.clang-format. file"
                mkdir -p $KRATOS_PATH/.vscode
                cp $utilities_directory/.clang-format $KRATOS_PATH/.clang-format
            fi

            alias kratos_compile='current_path=$(pwd) && cd $KRATOS_PATH/scripts && unbuffer sh configure.sh 2>&1 | tee kratos.compile.log && cd $current_path || cd $current_path'
            alias kratos_compile_clean='current_path=$(pwd) && rm -rf $KRATOS_PATH/build/$KRATOS_CPP_CONFIG_NAME $KRATOS_PATH/bin/$KRATOS_CPP_CONFIG_NAME cd $current_path || cd $current_path'
            alias kratos_paraview_output='python $KRATOS_PATH/applications/HDF5Application/python_scripts/create_xdmf_file.py'

            echo "Initialized kratos environment at $KRATOS_PATH successfully using $CC compiler with $KRATOS_BUILD_TYPE build type."
            echo
            echo "Following commands are available:"
            echo "            kratos_compile: Compiles currently loaded kratos environment and re-initializes the environment"
            echo "      kratos_compile_clean: Cleans compiles currently loaded kratos environment and re-initializes the environment"
            echo "    kratos_paraview_output: Creates xdmf file using the given h5 files for paraview visualization"
            echo "                deactivate: Unloads kratos environment"
        fi
    fi
fi




