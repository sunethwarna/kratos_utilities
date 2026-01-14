#!/bin/bash

if [ ! -z "$BASH_VERSION" ]; then
    KRATOS_ENV_SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
elif [ ! -z "$ZSH_VERSION" ]; then
    KRATOS_ENV_SCRIPT_DIR=$(dirname $0)
else
    echo "Unsupported shell. Only supports bash and zsh [ shell = $BASH_VERSION ]"
fi

Help()
{
    echo "Initializes specified kratos environment in the current terminal."
    echo
    echo " Syntax: sh kratos_env.sh [options] [environment name] [[compiler] [build_mode] | [branch_name]]"
    echo "options:"
    echo "          -h, : Displays this help message."
    echo "          -s, : Displays summary of work trees."
    echo "          -c, : Add a new branch with [branch_name] and create the work tree with [environment name]"
    echo "          -a, : Add a new work tree with [environment name] for branch with [branch_name]"
    echo "          -u, : Update a  work tree with [environment name]"
    echo "          -r, : Remove [environment name] worktree."
    echo "input arguments:"
    echo "            compiler: gcc, clang, intel"
    echo "          build_mode: release, rel_with_deb_info, debug, full_debug"
    echo "    environment name: please see the below worktree information for available environment names"
    echo

    echo "Path information:"
    echo "      Kratos work tree master path       : $KRATOS_WORKTREE_MASTER_PATH"
    echo "      Kratos utilities path              : $KRATOS_ENV_SCRIPT_DIR"
    echo "      Kratos default configuration script: $KRATOS_CONFIGURATION_SCRIPT"
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
            build_type="N/A"
            if [ -f "$KRATOS_BASE_PATH/$worktree_name/.venv/.kratos_info" ]; then
                source "$KRATOS_BASE_PATH/$worktree_name/.venv/.kratos_info"
            fi
            printf "\t%30s" "${worktree_name} ($build_type)"
            printf "\t%s\n" ${worktree_branch:11}
            ;;

            "detached")
            worktree_branch="detached[$worktree_hash]"
            build_type="N/A"
            if [ -f "$KRATOS_BASE_PATH/$worktree_name/.venv/.kratos_info" ]; then
                source "$KRATOS_BASE_PATH/$worktree_name/.venv/.kratos_info"
            fi
            printf "\t%30s" "${worktree_name} ($build_type)"
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

CheckAndInitializeEnvironmentVariables()
{
    if [ ! -z "$BASH_VERSION" ]; then
        prompt_prefix="-p "
        shell_type="bash"
    elif [ ! -z "$ZSH_VERSION" ]; then
        prompt_prefix="?"
        shell_type="zsh"
    else
        echo "Unsupported shell. Only supports bash and zsh [ shell = $BASH_VERSION ]"
    fi
    # first check whether the source files exists with already set paths
    if [ ! -f $KRATOS_ENV_SCRIPT_DIR/kratos_environment_paths.sh ]; then
        DEFAULT_KRATOS_WORKTREE_MASTER_PATH="/software/kratos/master"
        read "${prompt_prefix}Specify the kratos master path ($DEFAULT_KRATOS_WORKTREE_MASTER_PATH): " KRATOS_WORKTREE_MASTER_PATH
        if [ -z $KRATOS_WORKTREE_MASTER_PATH ]; then
            KRATOS_WORKTREE_MASTER_PATH=$DEFAULT_KRATOS_WORKTREE_MASTER_PATH
            echo "--- Using default KRATOS_WORKTREE_MASTER_PATH = $KRATOS_WORKTREE_MASTER_PATH."
        else
            echo "--- Changed KRATOS_WORKTREE_MASTER_PATH to $KRATOS_WORKTREE_MASTER_PATH."
        fi

        DEFAULT_KRATOS_CONFIGURATION_SCRIPT="configure_zsh.sh"
        read "${prompt_prefix}Specify the kratos default configuration script name ($DEFAULT_KRATOS_CONFIGURATION_SCRIPT): " KRATOS_CONFIGURATION_SCRIPT
        if [ -z $KRATOS_CONFIGURATION_SCRIPT ]; then
            KRATOS_CONFIGURATION_SCRIPT=$DEFAULT_KRATOS_CONFIGURATION_SCRIPT
            echo "--- Using default KRATOS_CONFIGURATION_SCRIPT = $KRATOS_CONFIGURATION_SCRIPT."
        else
            echo "--- Changed KRATOS_CONFIGURATION_SCRIPT to $KRATOS_CONFIGURATION_SCRIPT."
        fi

        echo "#!/bin/$shell_type" >> $KRATOS_ENV_SCRIPT_DIR/kratos_environment_paths.sh
        echo "export KRATOS_WORKTREE_MASTER_PATH=\"$KRATOS_WORKTREE_MASTER_PATH\"" >> $KRATOS_ENV_SCRIPT_DIR/kratos_environment_paths.sh
        echo "export KRATOS_CONFIGURATION_SCRIPT=\"$KRATOS_CONFIGURATION_SCRIPT\"" >> $KRATOS_ENV_SCRIPT_DIR/kratos_environment_paths.sh
        echo "export KRATOS_SHELL_TYPE=\"$shell_type\"" >> $KRATOS_ENV_SCRIPT_DIR/kratos_environment_paths.sh
    fi
    source $KRATOS_ENV_SCRIPT_DIR/kratos_environment_paths.sh
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

CheckAndInitializeEnvironmentVariables
export KRATOS_BASE_PATH=$(dirname $KRATOS_WORKTREE_MASTER_PATH)

current_path=$(pwd)

KratosCompile()
{
    compiler=$1
    build_type=$2

    kratos_path=$(which python | xargs dirname | xargs dirname | xargs dirname)

    current_path=$(pwd)
    cd $kratos_path/scripts

    case "$build_type" in
        release)
            unbuffer sh configure.sh ${compiler}_Release 2>&1 | tee kratos.compile.log ;;
        debug)
            unbuffer sh configure.sh ${compiler}_Debug 2>&1 | tee kratos.compile.log ;;
        rel_with_deb_info)
            unbuffer sh configure.sh ${compiler}_RelWithDebInfo 2>&1 | tee kratos.compile.log ;;
        *)
            echo "Unsupported build_type=\"$build_type\". Only supports following build types:"
            printf "\trelease\n"
            printf "\tdebug\n"
            printf "\trel_with_deb_info\n"
            ;;
    esac

    cd $current_path
}

case "$1" in
    -h)
        Help
        ;;
    -s)
        Summary
        ;;
    -r)
        environment_name=$2
        CheckEnvironmentName
        if $is_valid_options; then
            cd $KRATOS_WORKTREE_MASTER_PATH
            git worktree remove $environment_name
            cd $current_path
        fi
        ;;
    -c)
        cd $KRATOS_WORKTREE_MASTER_PATH
        git checkout master
        git pull
        git checkout -b $3
        git checkout master
        git worktree add ../$2 $3
        python -m venv ../$2/.venv --system-site-packages
        cd $current_path
        ;;
    -a)
        cd $KRATOS_WORKTREE_MASTER_PATH
        git checkout master
        git pull
        git worktree add ../$2 $3
        python -m venv ../$2/.venv --system-site-packages
        cd $current_path
        ;;
    -u)
        environment_name=$2
        CheckEnvironmentName

        if $is_valid_options; then
            python -m venv $KRATOS_BASE_PATH/$environment_name/.venv --system-site-packages
        fi
        ;;
    *)
        environment_name=$1
        CheckEnvironmentName

        if $is_valid_options; then
            if [ ! -z "$VIRTUAL_ENV" ]; then
                echo "-- Found already existing kratos environment initialization."
                echo "-- Please use \"deactivate\" to deactivate existing environment and try again to load the new environment."
            else
                KRATOS_PATH=$KRATOS_BASE_PATH/$environment_name

                if [ ! -f "$KRATOS_PATH/.venv/bin/activate" ]; then
                    python -m venv $KRATOS_PATH/.venv --system-site-packages
                    echo "-- Created python venv at $KRATOS_PATH/.venv"
                fi
                source $KRATOS_PATH/.venv/bin/activate
                kratos_install_dir=$(python -c 'import site; print(site.getsitepackages()[0])')
                python_interpreter=$(which python)

                build_type="N/A"
                if [ -f "$KRATOS_PATH/.venv/.kratos_info" ]; then
                    source "$KRATOS_PATH/.venv/.kratos_info"
                fi

                if [ ! -f $KRATOS_PATH/scripts/configure.sh ]; then
                    echo "-- No default $KRATOS_PATH/scripts/configure.sh found. Copying the templated $KRATOS_ENV_SCRIPT_DIR/$KRATOS_CONFIGURATION_SCRIPT. file"
                    cp $KRATOS_ENV_SCRIPT_DIR/scripts/$KRATOS_CONFIGURATION_SCRIPT $KRATOS_PATH/scripts/configure.sh
                fi

                # now copy the rest of the default files if they are not found.
                cp -rvn $KRATOS_ENV_SCRIPT_DIR/defaults/. $KRATOS_PATH/.temp/

                find $KRATOS_PATH/.temp/ -type f -exec sed -i "s/<SHELL_TYPE>/${KRATOS_SHELL_TYPE}/g" {} +
                find $KRATOS_PATH/.temp/ -type f -exec sed -i "s@<KRATOS_LIBS_DIR>@${kratos_install_dir}/libs@g" {} +
                find $KRATOS_PATH/.temp/ -type f -exec sed -i "s@<PYTHON_INTERPRETER>@${python_interpreter}@g" {} +

                list_of_files_copied=$(cp -rvn $KRATOS_PATH/.temp/. $KRATOS_PATH/)
                if [ -d "$KRATOS_PATH/.temp" ]; then
                    rm -r $KRATOS_PATH/.temp
                fi
                if [ ! -z $list_of_files_copied ]; then
                    echo "-- Following files are copied..."
                    echo $list_of_files_copied
                fi

                alias kratos_compile='KratosCompile'
                alias kratos_paraview_output='python $KRATOS_PATH/applications/HDF5Application/python_scripts/create_xdmf_file.py'

                echo "Initialized kratos environment at $KRATOS_PATH successfully with $build_type."
                echo
                echo "Following commands are available:"
                echo "            kratos_compile: Compiles kratos with specified compiler (gcc|clang|intel) and with specified build type (release|debug|rel_with_deb_info)"
                echo "    kratos_paraview_output: Creates xdmf file using the given h5 files for paraview visualization"
                echo "                deactivate: Unloads kratos environment"
            fi
        fi
        ;;
esac