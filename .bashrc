#!/bin/bash

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
        _extension="$(echo $_path | rev | cut -d '.' -f1 | rev)"
        _filename="$(echo $_path | rev | cut -d '.' -f2- | rev)"

        run > "$_filename-updated.$_extension"
    else
        run
    fi
)
