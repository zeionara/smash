#!/bin/bash

add_suffix () {
    _extension="$(echo $1 | rev | cut -d '.' -f1 | rev)"
    _filename="$(echo $1 | rev | cut -d '.' -f2- | rev)"

    echo "$_filename-$2.$_extension"
}

smashd () {
    _path="$1"
    _pos=${2:-0}
    _i=0

    echo $_pos $_i

    _script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

    if [ -z "$3" ]; then
        _output="$(add_suffix $_path 'expanded')"
    else
        _output="$3"
    fi

    if [[ -f "$_output" ]] && [[ -z "$3" ]]; then
        rm "$_output"
    fi

    while read line; do
        if [ $_i -ge $_pos ]; then
            _pathh="$_script_dir/$line"

            if [[ ! -z $line ]] && [[ -d "$_pathh" ]]; then
                for _file in $_pathh/*.sh; do
                    _file=${_file##*/}
                    _suffix="$line=${_file%.*}"

                    _new_file="$(add_suffix $_output $_suffix)"

                    head "$_output" -n $_i > $_new_file
                    echo "$_file" >> $_new_file

                    smashd $_path $((_i + 1)) $_new_file

                    # echo $_new_file
                done

                return
            else
                echo $line >> $_output
                echo $line
            fi
        fi

        _i=$((_i + 1))
    done < $_path

    if [ $_i -eq $(cat $_path | wc -l) ]; then
        echo $_output
    fi
}

smash () (
    _path="$1"
    _nested="$2"
    
    if [ -z $_nested ]; then
        _is_first_line_after_header=''
    else
        _is_first_line_after_header='1'
    fi

    _script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

    if [ ! -f "$_path" ]; then
        echo File $_path does not exist
        return
    fi

    run () {
        while read line; do
            _path="$_script_dir/$line.sh"

            if [ -f "$_path" ]; then
                smash "$_path" 1
            else
                if [[ $line != \#!* ]] || [[ -z $_nested ]]; then
                    if [[ ! -z $line ]] || [[ -z $_is_first_line_after_header ]]; then
                        echo $line

                        if [[ ! -z $_is_first_line_after_header ]]; then
                            _is_first_line_after_header=''
                        fi
                    fi
                fi
            fi
        done < $_path
    }

    if [ -z $_nested ]; then
        # _extension="$(echo $_path | rev | cut -d '.' -f1 | rev)"
        # _filename="$(echo $_path | rev | cut -d '.' -f2- | rev)"

        # run > "$_filename-updated.$_extension"

        run > "$(add_suffix $_path 'expanded')"
    else
        run
    fi
)
