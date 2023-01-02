#!/usr/bin/env bash

ZIG_TEST='zig build test'

## Test all algorithms

$ZIG_TEST -Dalgorithm=math/ceil -freference-trace
$ZIG_TEST -Dalgorithm=math/crt -freference-trace
$ZIG_TEST -Dalgorithm=math/primes -freference-trace
$ZIG_TEST -Dalgorithm=math/euclidianGCDivisor -freference-trace
$ZIG_TEST -Dalgorithm=ds/linkedlist -freference-trace
$ZIG_TEST -Dalgorithm=dp/fibonacci -freference-trace
$ZIG_TEST -Dalgorithm=sort/quicksort -freference-trace

## Add more...