#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <file-or-directory>"
    exit 1
fi

check_path() {
    if [ -f "$1" ]; then
        echo "$1 is a file"
    elif [ -d "$1" ]; then
        echo "$1 is a directory"
    else
        echo "$1 does not exist"
        exit 1
    fi
}

check_path "$1"
