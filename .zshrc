#!/usr/bin/zsh

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

_smash_permute () {
    local n_items=${#@}

    if [ $n_items -eq 1 ]; then
        echo "$@"
        return
    fi

    local i=1
    local result=''

    for item in $@; do
        # echo '--' $item

        # echo 'vv'
        local args1="${@:1:$((i - 1))}"
        local args2="${@:$((i + 1)):$((n_items - i))}"
        local args=''

        # echo $args1
        # echo $args2

        if [[ ! -z $args1 ]] && [[ ! -z $args2 ]]; then
            args="$args1 $args2"
        else
            args="$args1$args2"
        fi
        # echo "'$args'"
        # sleep 1
        if [ ! -z $args ]; then
            # echo ">> $args"

            local _result=$(eval "_smash_permute $args")
            read -A _result_array <<< "$_result"

            for _item in ${_result_array[@]}; do
                if [ ! -z $result ]; then
                    result="$result $item|$_item"
                else
                    result="$item|$_item"
                fi
            done

            # echo '!!' $_result '!!'
            # echo "<< $args"
        fi
        # echo '^^'

        i=$((i + 1))
    done

    echo $result
}

smashp () {
    local _path="$1"

    local folder=$(echo $_path | rev | cut -d '/' -f2- | rev)

    if [[ $_path == */* ]]; then
        folder="$folder/"
    else
        folder=""
    fi

    local file=$(echo $_path | rev | cut -d '/' -f1 | rev)
    local extension=$(echo $file | rev | cut -d '.' -f1 | rev)
    local file=$(echo $file | rev | cut -d '.' -f2- | rev)

    # echo $folder $file $extension

    # local file_components=$(echo $file | sed -E 's/-(\w+=\w+)/ \1/g')

    read -A file_components <<< "$(echo $file | sed -E 's/-(\w+=\w+)/ \1/g')"

    # items="${file_components[@]:1}"
    
    # echo $items

    permutations=$(_smash_permute "${file_components[@]:1}")

    read -A permutations_array <<< "$permutations"

    for permutation in ${permutations_array[@]:1}; do
        # echo "$folder${file_components[@]:0:1}-$(echo $permutation | sed 's/|/-/g').$extension"
        ln $_path "$folder${file_components[@]:0:1}-$(echo $permutation | sed 's/|/-/g').$extension"
    done

    # for component in ${file_components[@]}; do
    #     echo $component
    # done

    # echo $file_components
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

        folder=$(echo $smashaed | rev | cut -d '/' -f2- | rev)

        if [[ $smashaed == */* ]]; then
            folder="$folder/"
        else
            folder=''
        fi

        filename=$(echo $smashaed | rev | cut -d '/' -f1 | rev)

        smashaed="${folder}_${filename}"

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
        #_name="${name:1}" # discard the first character which should be underscore
        _name="$(echo $name | sed 's#/_#/#')"
        mv $name $_name

        smashp "$_name"

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

    local _dir=$(echo $_path | rev | cut -d '/' -f2- | rev)

    # echo $_pos $_i

    if [ -z $_dir ]; then
        local _script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    else
        local _script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/$_dir
    fi

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

                    smashd $_path $((_i + 1)) $_new_file $_dir

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

    local _dir=$(echo $_path | rev | cut -d '/' -f2- | rev)
    
    if [ -z $_nested ]; then
        _is_first_line_after_header=''
    else
        _is_first_line_after_header='1'
    fi

    if [ -z $_dir ]; then
        _script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    else
        _script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/$_dir
    fi

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
