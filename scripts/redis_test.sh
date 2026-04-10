#!/bin/bash

URL="https://localhost"
N=10

bench() {
    total=0
    for i in $(seq 1 $N); do
        t=$(curl -sk -o /dev/null -w "%{time_total}" $URL)
        total=$(echo "$total + $t" | bc)
    done
    echo "scale=3; $total / $N" | bc
}

docker exec wordpress wp redis disable --allow-root > /dev/null 2>&1
echo -n "Sans Redis (moyenne $N req): "
bench

docker exec wordpress wp redis enable --allow-root > /dev/null 2>&1
echo -n "Avec Redis (moyenne $N req): "
bench
