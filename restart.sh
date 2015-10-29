#!/bin/sh

pids=`ps aux | grep nginx | grep -v grep | awk '{print $2}'`
for i in $pids
do
    echo "kill process $i"
    kill -9 $i
done

if [ $? -ne 0 ]
then
    echo "stop openresty nginx not succeed!"
    exit 1
else
    echo "stop openresty nginx succeed!"
fi

echo "start openresty"

nginx -p `pwd` -c conf/nginx.conf

if [ $? -ne 0 ]
then
    echo "start openresty nginx failed"
    exit 1
else
    echo "start openresty nginx succeed"
fi

