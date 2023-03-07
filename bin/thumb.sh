#!/bin/bash

die() {
    printf "%s\n" "$@"
    exit 1
}

select_page() {
    local FILENAME=$1
    local PAGE=$2

    convert "$FILENAME[$PAGE]" miff:-
}

flatten() {
    convert                                  \
        miff:-                               \
            -background White                \
            -alpha remove                    \
            -alpha off                       \
            -colorspace Gray                 \
        miff:-
}

trim() {
    convert                                  \
        miff:-                               \
            -trim +repage                    \
        miff:-
}

thumbnail() {
    local WIDTH=$1
    local HEIGHT=$2
    local BORDER=$3

    local WIDTH_=$((WIDTH - 2 * BORDER))
    local HEIGHT_=$((HEIGHT - 2 * BORDER))

    convert                                  \
        miff:-                               \
            -resize "${WIDTH_}X${HEIGHT_}"   \
            -gravity Center                  \
            -extent "${WIDTH}X${HEIGHT}"     \
        miff:-
}

compress() {
    convert                                  \
        miff:-                               \
            +dither                          \
            -colors 16                       \
            -depth 8                         \
        miff:-
}

save() {
    convert miff:- "$1"
}

optimize() {
    local FILENAME=$1
    local EXT=${FILENAME##*.}
    local PREFIX=${FILENAME%.*}
    local TEMPFILE=$(mktemp -u -p . "${PREFIX}.XXX.${EXT}")

    optipng "$FILENAME" -o7 -out "$TEMPFILE" && mv "$TEMPFILE" "$FILENAME"
}

sha1() {
    sha1sum "$1" | cut -c1-7
}

find_input() {
    find . -name "*.pdf" -print -quit
}

while [[ $# -gt 1 ]]
do
    case "$1" in
        -i|--input)
            FILENAME="$2"
            ;;
        -n|--page)
            PAGE="$2"
            ;;
        -w|--width)
            WIDTH="$2"
            ;;
        -h|--height)
            HEIGHT="$2"
            ;;
        -b|--border)
            BORDER="$2"
            ;;
        *)
            die "Unknown option: $1"
            ;;
    esac
    shift
    shift
done

if [[ $# -gt 0 ]]; then
    die "Wrong option: $1"
fi

FILENAME=${FILENAME:-$(find_input)}
SHA1=$(sha1 "$FILENAME")
OUTPUT="$SHA1.png"

if [[ "$FILENAME" != "$SHA1.pdf" ]]; then
    cp "$FILENAME" "$SHA1.pdf"
fi

PAGE=${PAGE:-0}
WIDTH=${WIDTH:-90}
HEIGHT=${HEIGHT:-130}
BORDER=${BORDER:-$((HEIGHT/10))}

select_page "$FILENAME" "$PAGE"              \
    | flatten                                \
    | trim                                   \
    | thumbnail "$WIDTH" "$HEIGHT" "$BORDER" \
    | compress                               \
    | save "$OUTPUT"                         \
   && optimize "$OUTPUT"
