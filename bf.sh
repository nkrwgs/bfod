#!/bin/bash 
MACRO='./bf.macro'
TMP='./bf0'

search () {
	me=$(ps -o 'pgid,pid,cmd' -e | grep $$ | grep -v grep | sed -e 's/ *\([0-9][0-9]*\).*/\1/')
	dc=$(ps -o 'pid,cmd' -e | grep 'dc' | grep -v grep | sed -e 's/ *\([0-9][0-9]*\).*/\1/')
}

check () {
    if [ -e /proc/${dc}/cmdline ]; then
        read cmd < /proc/${dc}/cmdline
        if [ ${#cmd} -ne '2' ];then
            exit
	fi
    else
	exit
    fi 
}

readchar () {
    (
    stty -echo
    read -n1 c 
    d=$(printf "%d" \'${c})
    stty echo
    echo "${d} lp:m" 
    ) < /dev/tty 
}

findloop () {
    l=1
    d=0
    j=0
    b=0
    v=0
    while read line
    do
	if expr "${line}" : '.J' > /dev/null
	then
	    if [ ${d} -eq 0 ]; then
		j=${l}
	    fi	
	    d=$((d+1))
	fi
	if expr "${line}" : '.B' > /dev/null
	then
	    d=$((d-1))
	    if [ ${d} -eq 0 ]; then
		b=${l}
		v=$((b-j))
		sed -i -e "${j}s/J/${v}/" ${TMP}
		sed -i -e "${b}s/B //" ${TMP}
	    fi	
	fi
	l=$((l+1))
    done < ${TMP}
    if [ ${v} -gt 0 ];then
	 findloop
    fi
}

findread () {
    need=0
    if grep 'lgx' ${TMP} > /dev/null    
    then
	need=1
    fi
}

c=0
cat - | \
sed -z \
    -e 's/[^]><.,+-[]//g' \
    -e 's/\(>>*\)/\1\n/g' \
    -e 's/\(<<*\)/\1\n/g' \
    -e 's/\(++*\)/\1\n/g' \
    -e 's/\(--*\)/\1\n/g' \
    -e 's/\(\.\)/\1\n/g' \
    -e 's/\(,\)/\1\n/g' \
    -e 's/\[/\[\n/g' \
    -e 's/]/]\n/g' \
    -e '$ a quit' | \
while read l
do
    if [[ ${l} =~ [-+\<\>] ]]; then
        echo "${#l} ${l:0:1}"  
    else
        echo "${l}"  
    fi | \
    sed -e "s/]/LB lbxR ${c} 0 0/" \
        -e "s/\[/LJ ljxR ${c} 0 0/" \
        -e "s/\([0-9][0-9]*\) +/L\1 laxR ${c} 0 0/" \
        -e "s/\([0-9][0-9]*\) -/L\1 lsxR ${c} 0 0/" \
        -e "s/\([0-9][0-9]*\) >/L\1 lrxR ${c} 0 0/g" \
        -e "s/\([0-9][0-9]*\) </L\1 llxR ${c} 0 0/g" \
        -e "s/\\./LlcxR ${c} 0 0/" \
        -e "s/,/LlgxR ${c} 0 0/" \
        -e "s/quit/LqR ${c} 0 0/" \
        -e 's/L/[/' \
        -e 's/R/]/'
    c=$((c+1))
done > ${TMP}

findloop
findread
search
cat ${MACRO}
echo "0 1"
cat ${TMP}
echo -n "lxxq"
if [ ${need} -eq '0' ];then
    exit
fi
while true;
do
    readchar
    check
done
