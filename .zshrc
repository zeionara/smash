#!/bin/bash

_smash_add_suffix () {
    _extension="$(echo $1 | rev | cut -d '.' -f1 | rev)"
    _filename="$(echo $1 | rev | cut -d '.' -f2- | rev)"

    echo "$_filename-$2.$_extension"
}

_smash_drop_duplicates () {
    args="$1"
    unique_args=''

    read -A args_array <<< "$args"

    for arg in ${args_array[@]}; do
        escaped_arg="$(echo $arg | sed -E 's/^-/\\-/g')"
        matches=$(echo $unique_args | grep "$escaped_arg")

        if [ -z $matches ]; then
            if [ -z $unique_args ]; then
                unique_args="$arg"
            else
                unique_args="$unique_args $arg"
            fi
        fi
    done

    echo $unique_args
}

smasha () {
    local _path="$1"

    if [[ -z $_path ]] || [[ ! -f $_path ]]; then
        echo File '"'$_path'"' does not exist or the path is empty
        return
    fi

    names=''

    for file in $(smashd $_path); do
        smashed=$(smash $file)
        # smashced=$(smashc $smashed 'sudo apt-get install')

        for arg in ${@:2}; do
            smashced=$(smashc $smashed "$arg")
            mv $smashced $smashed
        done

        # smashaed=$(echo $smashced | sed -E 's/\-(truncated|expanded)//g')
        smashaed=$(echo $smashed | sed 's/\-expanded//g')
        smashaed="_$smashaed"

        mv $smashed $smashaed

        if [ -z $names ]; then
            names="$smashaed"
        else
            names="$names $smashaed"
        fi
    done

    eval "rm $(_smash_add_suffix $_path '*')" 2> /dev/null

    read -A names_array <<< $names

    for name in ${names_array[@]}; do
        _name="${name:1}"
        mv $name $_name

        echo $_name
        echo
        cat $_name
        echo
        echo
    done
}

smashc () {
    local _path="$1"
    local prefix="$2"

    local args=''
    local output=$(_smash_add_suffix "$1" truncated)

    if [[ -z $_path ]] || [[ ! -f $_path ]]; then
        echo File '"'$_path'"' does not exist or the path is empty
        return
    fi

    if [ -z $prefix ]; then
        echo Prefix must be non-empty
        return
    fi

    if [ -f "$output" ]; then
        rm "$output"
    fi

    # i=0
    # first_prefix_match_i=''

    while read line; do
        if [[ $line == $prefix* ]]; then
            # if [ -z $first_prefix_match_i ]; then
            #     first_prefix_match_i=$i
            # fi

            new_args=$(echo $line | sed -e "s/$prefix *//")

            if [ -z $args ]; then
                args=$new_args
            else
                args="$args $new_args"
            fi
        fi

        # i=$((i + 1))
    done < "$_path"

    args=$(_smash_drop_duplicates "$args")

    # echo $first_prefix_match_i $args

    # i = 0
    first_prefix_match=''
    previous_line=''

    while read line; do
        if [[ $line == $prefix* ]]; then
            if [ -z $first_prefix_match ]; then
                first_prefix_match=1
                echo $prefix $args >> "$output"
            else
                continue
            fi
        else
            if [[ ! -z $line ]] || [[ ! -z $previous_line ]]; then
                echo $line >> "$output"
            fi
        fi

        previous_line="$line"
    done < "$_path"

    echo $output
}

smashd () {
    local _path="$1"
    local _pos=${2:-0}
    local _i=0

    # echo $_pos $_i

    local _script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

    if [ -z "$3" ]; then
        local _output="$(_smash_add_suffix $_path 'expanded')"
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

                    local _new_file="$(_smash_add_suffix $_output $_suffix)"

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
        echo "$_output"
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

        _result="$(_smash_add_suffix $_path 'expanded')"
        run > "$_result"

        echo $_result
    else
        run
    fi
)
