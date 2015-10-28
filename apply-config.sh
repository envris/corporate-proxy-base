#!/bin/bash

# Specify our prefixes
ENV_PREFIX='__'
CONF_PREFIX='@@'


# Build array of environment variables that fit the criteria
IFS=$'\n'
CONFIG_ARRAY=($(env | egrep '^'$ENV_PREFIX))

while test $# -gt 0; do
    case "$1" in
        -h|--help)
           echo "apply_config - substitute config-as-environment-variables into config files"
           echo " "
           echo "For each config file in the path, substitute ${CONF_PREFIX}CONF_ITEM placeholders with"
           echo "corresponding ${ENV_PREFIX}CONF_ITEM environment variables."
           echo " "
           echo "Usage: ./apply_config [options] [path or file]"
           echo " "
           echo "options:"
           echo "-h, --help              show help"
           echo "-r, --recursive         apply config recursively to child directories"
           echo "--dry-run               runs but does not edit files"
           exit 0
           ;;
        -r|--recursive)
            shift
            SEARCH_RECURSIVE=true
            echo "recursive param"
            ;;
        --dry-run)
            shift
            DRY_RUN=true
            ;;
        *)
            # Check if input file/directory exists
            if [ -e "$1" ]; then
                if [ "$SEARCH_RECURSIVE" = true ]; then
                    SEARCH_PATH=($(find $1 -type f))
                else
                    SEARCH_PATH=($(find $1 -maxdepth 1 -type f))
                fi
            else
                echo "${1} is an invalid file or directory"
                exit 1;
            fi
            break
            ;;
    esac
done

if [ -z $SEARCH_PATH ]; then
    echo "You must supply a valid file or directory"
    exit 1;
fi

if [ "$DRY_RUN" = true ]; then
    echo "Commencing dry-run..."
fi

# Iterate over each file
for file in ${SEARCH_PATH[@]}; do
    if [ ! -d $file ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "Parsing $file"
        fi
        cp $file $file.orig
        while read -r conf_item; do
            # Break apart k=v pair
            conf_var=`echo "$conf_item" | cut -d'=' -f 1`
            conf_val="`echo $conf_item | cut -d'=' -f2-`"

            # Strip padding '__'
            conf_var=`echo "${conf_var#${ENV_PREFIX}}"`

            if [ "$DRY_RUN" = true ]; then
                val_occurs=`cat $file | grep ${CONF_PREFIX}$conf_var | wc -l`
                if [ "$val_occurs" -gt "0" ]; then
                    # Display some useful information about the substitutions
                    # that are to be made. Could choose to format this differently
                    # in the form of Var: #occurances instead of per-line.

                    cat $file | grep ${CONF_PREFIX}$conf_var
                fi
            else
                # Replace @@${conf_var} instances with conf_val
                #sed -i.orig 's,'${CONF_PREFIX}$conf_var','$conf_val',g' $file
                cat $file | awk -v REPLACE_VAL="$conf_val" -v REPLACE_VAR="$CONF_PREFIX$conf_var" '{ gsub(REPLACE_VAR, REPLACE_VAL); print }' > ${file}.part
                mv ${file}.part $file
            fi
        done <<< "${CONFIG_ARRAY[*]}"
   fi
done
