#
# Arguments parser from colors manager
# require: errors.lib.sh
# require: colors.lib.sh
#

USAGE=$(cat <<- ENDDATA
Usage: ${0} [theme] [install] [ARGS...]
  ARGS:
    --color|-c index #color 
                        - set custom theme color by index

    --hue|-H value      - change all colors position in the spectrum
    --saturation|-S value
                        - change all colors color saturation ("purity")
    --value|-V value    - change all colors brightness.
                          The value can be an absolute, relative, positive 
                          number, negative number, or expressed as a percentage
                          example: 10, +10, -23, +12%, -34%

    --relative-value|-R - change 8..15 colors intensity relatively base colors.
                          This function forcibly changes the color relative to 
                          the main one. The change value can be set in the 
                          BRIGHTNEST variable, default: 10.
                          Color '0' is excluded in modifier list

    --no-relative-value|-D
                        - disable relatively base colors

    --black|-b value    - сhanging color 0 (black) by increasing the percentage
                          of background intensity by a given value.
                          This function using original black color

    --backgroun|-bg value
                        - сhanging background by increasing the percentage
                          of color 0 (black) intensity by a given value.
                          This function using original black color

    --font|-f "font"    - set base font, example "Noto Sans 11"
                          (replace GTK_FONT_NAME from config file)
                    
    --config|-C "path"  - use external config from path
                          default use config.GTK_THEME_NAME if exists  

    --color-black-base|-B
                        - generate new color scheme from 'black' color

    --image|-I "path"   - generate new color scheme from image

    --setwal [top-fade height (px)]
                        - set background wallpaper (feh use)
                          picture must be specified in the --image parameter

    --light             - gtk application prefer light theme
    --dark              - gtk application prefer dark theme
    
    --cls|-             - theme preview without extended configs
    --short             - short preview color scheme
    --purge             - clear cache

    --help|-h           - print this usage
    --list|-l           - show a list of available schemes 

Order of applying modifiers:
    - get theme from image (if given)
    - load color scheme (if given)
    - apply value
    - set special colors value
    - load preselected config or default
    - aplly dark/light theme mode
    - apply black-color modifier (if given)
    - apply custom colors values
    - apply brightnest of relative value (always)

Available schemes:
    \033[33m$(echo $(ls `dirname "$0"`/schemes))\033[0m
ENDDATA
)


declare -A _colors=()

while [ -n "$1" ]; do
    case "${1}" in
    install)
        INSTALL=yes
        ;;

    --color|-c)
        [[ ! $(at "${2}" ${COLOR_KEYS[@]}) ]] && \
            fatal "Invalid parameter '${2}' from ${1} argument"

        [[ ! $(isrgb ${3}) ]] && \
            fatal "Invalid color '${3}' from ${1} argument"
        
        _colors[${2}]="${3}"
        shift; shift
        ;;

    --hue|-H)
        parse_value "${2}" >/dev/null
        RGB_HUE="${2}"
        shift
        ;;

    --saturation|-S)
        parse_value "${2}" >/dev/null
        RGB_SATURATION="${2}"
        shift
        ;;

    --value|-V)
        parse_value "${2}" >/dev/null
        RGB_VALUE="${2}"
        shift
        ;;

    --relative-value|-R)
        RELATIVE_VALUE=true
        ;;

    --no-relative-value|-D)
        NO_RELATIVE_VALUE=true
        ;;

    --black|-b)
        parse_value "${2}" >/dev/null
        _BLACK_VALUE="${2}"
        shift
        ;;

    --background|-bg)
        parse_value "${2}" >/dev/null
        _BACKGROUND_VALUE="${2}"
        shift
        ;;

    --font|-f)
        [[ ! ${2} || ${2:0:1} == "-" ]] && \
            fatal "Invalid parameter '${2}' from ${1} argument"

        _GTK_FONT_NAME="${2}"
        shift
        ;;

    --config|-C)
        CONFIG="${2}"
        shift
        ;;

    --color-black-base|-B)
        [[ ! $(isrgb ${2}) ]] && \
            fatal "Invalid color '${2}' from ${1} argument"

        COLOR_BLACK_BASE="${2}"
        shift
        ;;
    --image|-I)
        IMAGE="${2}"
        shift
        ;;

    --setwal)
        [[ $(isint ${2}) ]] && \
            VAL=${2} &&shift

        SET_WALLPAPER=${VAL:-80}
        ;;

    --light)
        GTK_APPLICATION_PREFER_DARK_THEME=0
        ;;
    --dark)
        GTK_APPLICATION_PREFER_DARK_THEME=1
        ;;

    --cls|-)
        CLEAN_THEME_PREVIEW=true
        ;;
    --short)
        export SHORT_PREVIEW=true
        ;;
    --purge)
        rm -rf "$CACHE"/config.*
        rm -rf "$CACHE"/theme.*
        exit 0
        ;;
    --help|-h)
        echo -e "$USAGE"
        exit 0
        ;;
    --list|-l)
        echo -e "${AVAILABLE[@]}"
        exit 0
        ;;
    *)
        [[ ${1:0:1} == "-" ]] && \
            fatal "Invalid parametr '$1'!!!"

        NAME="${1}"
        ;;
    esac
    shift
done
