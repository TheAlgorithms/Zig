#!/usr/bin/env bash

ZIG_TEST='zig build test'

## Test all algorithms

# Math
$ZIG_TEST -Dalgorithm=math/ceil -freference-trace
$ZIG_TEST -Dalgorithm=math/crt -freference-trace
$ZIG_TEST -Dalgorithm=math/primes -freference-trace
$ZIG_TEST -Dalgorithm=math/euclidianGCDivisor -freference-trace
$ZIG_TEST -Dalgorithm=math/gcd -freference-trace

# Data Structures
$ZIG_TEST -Dalgorithm=ds/linkedlist -freference-trace

# Dynamic Programming
$ZIG_TEST -Dalgorithm=dp/fibonacci -freference-trace

## Sort
$ZIG_TEST -Dalgorithm=sort/quicksort -freference-trace
$ZIG_TEST -Dalgorithm=sort/bubblesort -freference-trace
$ZIG_TEST -Dalgorithm=sort/radixsort -freference-trace
$ZIG_TEST -Dalgorithm=sort/mergesort -freference-trace
$ZIG_TEST -Dalgorithm=sort/insertsort -freference-trace

## Search
$ZIG_TEST -Dalgorithm=search/bSearchTree -freference-trace
$ZIG_TEST -Dalgorithm=search/rb -freference-trace

## Add more...