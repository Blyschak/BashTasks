#!/bin/bash

# the default precision is 2 digits after the deciminal point
DEFAULT_PREC=2

# regular expressions to validate input parametrs
FLOAT_REGEXP="^[+-]?[0-9]*\.?[0-9]*$"
INT_REGEXP=^[0-9]+

first=$1
second=$2
precision=$3
result=

# show usage message
Usage() {
    echo -e "Usage:\n$0 [float|int] [float|int] [precision (optional: default 2)]"
}

# expr wrapper to check for out of range error
# thats why it took so much time to calculate result
# we could use arithmetic expansion ( $((...)) ) but
# it doesn't handle integer overflow, so when we pass
# exptremly precise floats it could fail. So i used expr
# and wrapped it into a function to handle the overflow error
expr_wrapper() {
    arg1=$1; arg2=$3; oper=$2

    # prevent * interpretation
    [[ $oper == "*" ]] && oper='\\*'

    # calculate expression
    # errors redirect to /dev/null
    ret=$(expr $1 "$2" $3 2> /dev/null)
    
    if (( $? == 3 )); then
		# redirect to stderr error message
		echo Math error: Out of range >&2
		exit 2
    fi
    
    echo $ret
    
}

# check for two parametrs
if (( $# < 2 )); then
    Usage
    exit 1
fi

# validate input parametrs (regexpr - for floats or ints)
if ! [[ $first =~ $FLOAT_REGEXP ]] || ! [[ $second =~ $FLOAT_REGEXP ]]; then
    Usage
    exit 1
fi

# if precision wasn't set - set the default value
if ! [ $precision ] || ! [[ $precision =~ $INT_REGEXP ]]; then
    precision=$DEFAULT_PREC
fi

# change the IFS for a while to divide input strings by deciminal point
# save IFS
OLDIFS=$IFS; IFS='.'

read -r -a First <<< "$first"; read -r -a Second <<< "$second"

# set previous IFS value
IFS=$OLDIFS

# fill input strings with zeros to equalize number of digits
while (( ${#Second[1]} > ${#First[1]} )); do First[1]+='0'; done
while (( ${#First[1]} > ${#Second[1]} )); do Second[1]+='0'; done

# make integers without sign and use sed to easily
# delete trailing zeros from the front of strings
divided=$(echo ${First[0]#[+-]}${First[1]} | sed 's/^0*//')
divider=$(echo ${Second[0]#[+-]}${Second[1]} | sed 's/^0*//')

# check if divided and divider are empty string after sed
[[ -z $divided ]] && divided=0; [[ -z $divider ]] && divider=0

# check division by zero
if (( $divider == 0  )); then
    # redirect to stderr error message
    echo Math error: Division by 0 >&2
    exit 1
fi

# calculate and add sign of the result to result variable
(( ${First[0]%%[0-9]*}1*${Second[0]%%[0-9]*}1 < 0 )) &&  result+=- 

rest=$divided


# add each digit to reach given precision
for i in $(seq 0 $precision); do

    # epxr_wrapper to check for int overflow
    result+=$(expr_wrapper $rest / $divider) || exit $?

    # add deciminal point after whole part
    (( $i == 0 )) && result+=.

    # calculate the rest
    rest=$(( ( $rest - $divider*($rest/$divider) ) ))

    # check for overflow again
    rest=$(expr_wrapper $rest \* 10) || exit $?
    
done

# new line
echo $result
