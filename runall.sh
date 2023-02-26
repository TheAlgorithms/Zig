#!/usr/bin/env bash

ZIG_TEST='zig build test'

# reference trace should be shown per compile error
StackTrace='-freference-trace'

## Test all algorithms

# Math
$ZIG_TEST -Dalgorithm=math/ceil $StackTrace
$ZIG_TEST -Dalgorithm=math/crt $StackTrace
$ZIG_TEST -Dalgorithm=math/primes $StackTrace
$ZIG_TEST -Dalgorithm=math/fibonacci $StackTrace
$ZIG_TEST -Dalgorithm=math/factorial $StackTrace
$ZIG_TEST -Dalgorithm=math/euclidianGCDivisor $StackTrace
$ZIG_TEST -Dalgorithm=math/gcd $StackTrace

# Data Structures
$ZIG_TEST -Dalgorithm=ds/linkedlist $StackTrace
$ZIG_TEST -Dalgorithm=ds/lrucache $StackTrace

# Dynamic Programming

## Sort
$ZIG_TEST -Dalgorithm=sort/quicksort $StackTrace
$ZIG_TEST -Dalgorithm=sort/bubblesort $StackTrace
$ZIG_TEST -Dalgorithm=sort/radixsort $StackTrace
$ZIG_TEST -Dalgorithm=sort/mergesort $StackTrace
$ZIG_TEST -Dalgorithm=sort/insertsort $StackTrace

## Search
$ZIG_TEST -Dalgorithm=search/bSearchTree $StackTrace
$ZIG_TEST -Dalgorithm=search/rb $StackTrace

# Concurrency && Parallelism

## Threads
$ZIG_TEST -Dalgorithm="threads/threadpool" $StackTrace

## Add more...