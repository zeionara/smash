#!/bin/bash

add_suffix () {
    _extension="$(echo $1 | rev | cut -d '.' -f1 | rev)"
    _filename="$(echo $1 | rev | cut -d '.' -f2- | rev)"

    echo "$_filename-$2.$_extension"
}

smashd () {
    local _path="$1"
    local _pos=${2:-0}
    local _i=0

    # echo $_pos $_i

    local _script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

    if [ -z "$3" ]; then
        local _output="$(add_suffix $_path 'expanded')"
    else
        local _output="$3"
    fi

    if [[ -f "$_output" ]] && [[ -z "$3" ]]; then
        rm "$_output"
    fi

    while read line; do
        if [ $_i -ge $_pos ]; then
            local _pathh="$_script_dir/$line"

            if [[ ! -z $line ]] && [[ -d "$_pathh" ]]; then
                local _line="$line"

                for _file in $_pathh/*.sh; do
                    local _file=${_file##*/}
                    local _name=${_file%.*}
                    local _suffix="$_line=$_name"

                    local _new_file="$(add_suffix $_output $_suffix)"

                    head "$_output" -n $_i > $_new_file
                    echo "$_line/$_name" >> $_new_file

                    smashd $_path $((_i + 1)) $_new_file

                    # echo $_new_file
                done

                return
            else
                echo $line >> $_output
                # echo $line
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

        _result="$(add_suffix $_path 'expanded')"
        run > "$_result"

        echo $_result
    else
        run
    fi
)
