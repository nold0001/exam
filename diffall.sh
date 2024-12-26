#!/bin/bash

################################################################################
# diffall.sh - File Comparison Utility.                     2024-11-02(Fri)    #
#                                                                              #
#       Usage : diffall.sh [OPTION]                                            #
#                                                                              #
#           OPTION:                                                            #
#               -h      this message                                           #
#               -s      compare source files (*.cpp)                           #
#               -i      compare header files (*.cpp)                           #
#               -d      compare using 'diff' command                           #
#               -v      compare using 'vimdiff' command                        #
#                                                                              #
#           Ex of usage : diffall.sh                                           #
#                       : diffall.sh -s                                        #
#                       : diffall.sh -s -d                                     #
################################################################################

################################################################################
# linux & QNX source directories
################################################################################
LINUX_SRC_HOME=~/connectwide_feature_camera_241021/qnx-cluster/nativeservice/companion/ccameraservice.backup.241120
QNX_SRC_HOME=~/connectwide_feature_camera_241021/qnx-cluster/nativeservice/companion/ccameraservice

LEFT_SRC_HOME=${LINUX_SRC_HOME}
RIGHT_SRC_HOME=${QNX_SRC_HOME}

################################################################################
# pattern for checking numeric chars
################################################################################
pattern_number="^[0-9]+$"

################################################################################
# define variable for OPTION & COMMAND
################################################################################
ABBR_QUIT=q             # quit
ABBR_EXIT=x             # exit
ABBR_HELP=h             # help
ABBR_SOURCE_FILE=s      # source (*.cpp)
ABBR_HEADER_FILE=i      # include (*.h)
ABBR_COMMAND_DIFF=d     # diff command
ABBR_COMMAND_VIMDIFF=v  # vimdiff command
ABBR_BASE_SRC_TOGGLE=t  # toggle base source (Linux <--> QNX)
ABBR_VIEW_ALL=a         # view all sources
ABBR_VIEW_NOT_ALL=n     # view "src/" or "include/" sources only
ABBR_REFRESH_MENU=r     # re-scan

################################################################################
# set the comparison target (s=*.cpp or i=*.h)
################################################################################
RUN_TARGET=${ABBR_SOURCE_FILE}

################################################################################
# set the method for displaying (d=diff, v=vimdiff)
################################################################################
RUN_OPTION=${ABBR_COMMAND_DIFF}

################################################################################
# set the method for displaying (d=diff, v=vimdiff)
################################################################################
VIEW_OPTION=${ABBR_VIEW_NOT_ALL}

################################################################################
# display usage
################################################################################
echo_usage()
{
    echo ""
    echo "Usage : `basename $0` [OPTION]"
    echo "        OPTION"
    echo "               -${ABBR_HELP} : this message"
    echo "               -${ABBR_SOURCE_FILE} : compare source files (*.cpp)"
    echo "               -${ABBR_HEADER_FILE} : compare header files (*.h)"
    echo "               -${ABBR_COMMAND_DIFF} : compare using 'diff' command"
    echo "               -${ABBR_COMMAND_VIMDIFF} : compare using 'vi -d' command"
    echo "               -${ABBR_VIEW_NOT_ALL} : view sources not-all"
    echo "               -${ABBR_VIEW_ALL} : view sources all"
    echo ""
}

################################################################################
# display help message
################################################################################
show_help()
{
    echo "               '${ABBR_HELP}' : this message"
    echo "               '${ABBR_SOURCE_FILE}' : compare source files (*.cpp)"
    echo "               '${ABBR_HEADER_FILE}' : compare header files (*.h)"
    echo "               '${ABBR_COMMAND_DIFF}' : compare using 'diff' command"
    echo "               '${ABBR_COMMAND_VIMDIFF}' : compare using 'vi -d' command"
    echo "               '${ABBR_VIEW_NOT_ALL}' : view sources not-all"
    echo "               '${ABBR_VIEW_ALL}' : view sources all"
    echo "               '${ABBR_BASE_SRC_TOGGLE}' : toggle base source (Linux <--> QNX)"
    echo "               '${ABBR_REFRESH_MENU}' : re-scan files"
    echo "               '${ABBR_QUIT}' : quit"
}

################################################################################
# display menu
################################################################################
display_menu()
{
    echo        ""
    echo        "┌───────────────────────────────────────────────────────────────────────────────────"
    echo        "│"

    if [ ${LEFT_SRC_HOME} == ${LINUX_SRC_HOME} ]; then
        echo -e     "│  **** \e[7m LINUX Sources \e[0m :  ${LINUX_SRC_HOME}/"
        echo        "│  ****   QNX  Sources  :  ${QNX_SRC_HOME}/"
    else
        echo        "│  ****  LINUX Sources  :  ${LINUX_SRC_HOME}/"
        echo -e     "│  **** \e[7m  QNX  Sources \e[0m :  ${QNX_SRC_HOME}/"
    fi

    echo        "│"
    echo        "├───────────────────────────────────────────────────────────────────────────────────"

    echo        "│"
    if [ ${#LEFT_SRCS[@]} -le 0 ]; then
        echo        "│       File not found !!!"
    else
        for SRC in "${!LEFT_SRCS[@]}"
        do
            tmp=`expr ${SRC} + 1`
            num=`printf "%2d" ${tmp}`
            echo "│  ${num}. ${LEFT_SRCS[SRC]}"
            if [ `expr ${num} % 10` -eq 0 ]; then
                echo        "│"
            fi
        done
    fi
    echo        "│"
    echo        "└───────────────────────────────────────────────────────────────────────────────────"
}

################################################################################
# get source list in Left(linux or QNX) ccameraservice (*.cpp or *.h)
################################################################################
get_srcs_list()
{
    if [ ${VIEW_OPTION} == ${ABBR_VIEW_NOT_ALL} ]; then
        echo "equal"
        TARGET_DIR_SRC=.    ### src
        TARGET_DIR_INCLUDE=.    ### include
    else
        echo "not equal"
        TARGET_DIR_SRC=.
        TARGET_DIR_INCLUDE=.
    fi
    LEFT_SRCS_2=""
    case ${RUN_TARGET} in
        ${ABBR_SOURCE_FILE})    # 's'
            ################################################################################
            # search sources except "src/drm" and "./src/drm" directoris
            LEFT_SRCS_2=`cd ${LEFT_SRC_HOME} && find ${TARGET_DIR_SRC} ! \( \( -path src/drm -o -path ./src/drm \) -prune \) -name "*.cpp" 2> /dev/null && cd - > /dev/null`
            ;;
        ${ABBR_HEADER_FILE})    # 'i'
            LEFT_SRCS_2=`cd ${LEFT_SRC_HOME} && find ${TARGET_DIR_INCLUDE} ! \( \( -path include/drm -o -path ./include/drm \) -prune \) -name "*.h" 2> /dev/null && cd - > /dev/null`
            ;;
    esac

    LEFT_SRCS=(${LEFT_SRCS_2//,,,,,/})
}

################################################################################
# run command to display the differences
################################################################################
run_diff()
{
    LEFT_PATH=${LEFT_SRC_HOME}/$1
    RIGHT_PATH=${RIGHT_SRC_HOME}/$1

    case ${RUN_OPTION} in
        ${ABBR_COMMAND_DIFF})       # 'd'
            ### diff.sh ${LEFT_PATH} ${RIGHT_PATH}
            /usr/bin/diff --color=always ${LEFT_PATH} ${RIGHT_PATH} | less -R
            ### /usr/bin/diff --color ${LEFT_PATH} ${RIGHT_PATH} | less -R
            ;;
        ${ABBR_COMMAND_VIMDIFF})    # 'v'
            ### vimdiff.sh ${LEFT_PATH} ${RIGHT_PATH}
            vi -n -R -d -c "colorscheme slate" ${LEFT_PATH} ${RIGHT_PATH}
            ;;
    esac
}

################################################################################
# start main

################################################################################
# check executing options
################################################################################
set -- $(getopt shdvhan "$@")
while [ -n "$1" ]
do
    case "$1" in
        -${ABBR_HELP})              # '-h'
            echo_usage
            exit
            ;;
        -${ABBR_SOURCE_FILE})       # '-s'
            RUN_TARGET=${ABBR_SOURCE_FILE}
            ;;
        -${ABBR_HEADER_FILE})       # '-i'
            RUN_TARGET=${ABBR_HEADER_FILE}
            ;;
        -${ABBR_COMMAND_DIFF})      # '-d'
            RUN_OPTION=${ABBR_COMMAND_DIFF}
            ;;
        -${ABBR_VIEW_ALL})          # '-a'
            VIEW_OPTION=${ABBR_VIEW_ALL}
            ;;
        -${ABBR_VIEW_NOT_ALL})      # '-n'
            VIEW_OPTION=${ABBR_VIEW_NOT_ALL}
            ;;
        --)
            ;;
        *)
            echo "'$1' is unknown option."
            exit
            ;;
    esac
    shift 1
done

################################################################################
# get source list
################################################################################
get_srcs_list

################################################################################
# main loop
################################################################################
while true
do
    ################################################################################
    # display menu always
    display_menu

    ################################################################################
    # edit & display prompt string
    if [ ${#LEFT_SRCS[@]} -ge 1 ]; then
        strRange=", 1~${#LEFT_SRCS[@]}"
    else
        strRange=""
    fi
    echo -e -n "mode:${RUN_TARGET}${VIEW_OPTION}${RUN_OPTION}   Enter command or number (${ABBR_HELP},${ABBR_SOURCE_FILE},${ABBR_HEADER_FILE},${ABBR_COMMAND_DIFF},${ABBR_COMMAND_VIMDIFF},${ABBR_VIEW_NOT_ALL},${ABBR_VIEW_ALL},${ABBR_BASE_SRC_TOGGLE},${ABBR_REFRESH_MENU},${ABBR_QUIT}:quit${strRange}) > "

    ################################################################################
    # get user's selection
    read SELECT_NUMBER

    ################################################################################
    # action for menu selected by user
    case ${SELECT_NUMBER} in
        [${ABBR_QUIT}${ABBR_QUIT^^}${ABBR_EXIT}${ABBR_EXIT^^}]) # qQxX) quit
            break
            ;;
        [${ABBR_HELP}${ABBR_HELP^^}])                           # hH) display help
            show_help
            echo "press <Enter> key ..."
            read anykey
            continue
            ;;
        [${ABBR_SOURCE_FILE}${ABBR_SOURCE_FILE^^}])             # sS) select src (*.cpp)
            RUN_TARGET=${ABBR_SOURCE_FILE}
            get_srcs_list
            continue
            ;;
        [${ABBR_HEADER_FILE}${ABBR_HEADER_FILE^^}])             # iI) select include (*.h)
            RUN_TARGET=${ABBR_HEADER_FILE}
            get_srcs_list
            continue
            ;;
        [${ABBR_COMMAND_DIFF}${ABBR_COMMAND_DIFF^^}])           # dD) select diff-command
            RUN_OPTION=${ABBR_COMMAND_DIFF}
            continue
            ;;
        [${ABBR_COMMAND_VIMDIFF}${ABBR_COMMAND_VIMDIFF^^}])     # vV) select vimdiff-command
            RUN_OPTION=${ABBR_COMMAND_VIMDIFF}
            continue
            ;;
        [${ABBR_VIEW_ALL}${ABBR_VIEW_ALL^^}])                   # aA) select view-option all
            VIEW_OPTION=${ABBR_VIEW_ALL}
            get_srcs_list
            continue
            ;;
        [${ABBR_VIEW_NOT_ALL}${ABBR_VIEW_NOT_ALL^^}])           # nN) select view-option not-all
            VIEW_OPTION=${ABBR_VIEW_NOT_ALL}
            get_srcs_list
            continue
            ;;
        [${ABBR_BASE_SRC_TOGGLE}${ABBR_BASE_SRC_TOGGLE^^}])     # tT) toggle base source (linux <--> QNX)
            TMP_SRC_HOME=${LEFT_SRC_HOME}
            LEFT_SRC_HOME=${RIGHT_SRC_HOME}
            RIGHT_SRC_HOME=${TMP_SRC_HOME}
            get_srcs_list
            continue
            ;;
        [${ABBR_REFRESH_MENU}${ABBR_REFRESH_MENU^^}])           # rR) select re-scan source list
            get_srcs_list
            continue
            ;;
        "")         # re-display (no re-scan)
            continue
            ;;
        *)
            ;;
    esac

    ################################################################################
    # ignore non-numeric input
    if [[ ! ${SELECT_NUMBER} =~ ${pattern_number} ]]; then
        continue
    fi

    ################################################################################
    # execute if selected number is included in menu
    if [ ${SELECT_NUMBER} -ge 1 ] && [ ${SELECT_NUMBER} -le ${#LEFT_SRCS[@]} ]; then
        run_diff ${LEFT_SRCS[`expr ${SELECT_NUMBER}-1`]}
    fi
done

################################################################################
# display goodbye message
################################################################################
echo ""
echo "^^Done^^"
echo ""

################################################################################
# endof source
################################################################################

