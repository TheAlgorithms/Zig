# The Algorithms: Zig

This project aims at showcasing common algorithms implemented in `Zig`, with an accent on idiomatic code and genericity. 

## Project structure

Every project is managed by the `build.zig` file.

```bash
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
├── README.md
├── build.zig
├── concurrency
│   └── threads
│       └── ThreadPool.zig
├── dataStructures
│   ├── linkedList.zig
│   └── lruCache.zig
├── math
│   ├── ceil.zig
│   ├── chineseRemainderTheorem.zig
│   ├── euclidianGreatestCommonDivisor.zig
│   ├── factorial.zig
│   ├── fibonacciRecursion.zig
│   ├── gcd.zig
│   └── primes.zig
├── runall.sh
├── search
│   ├── binarySearchTree.zig
│   └── redBlackTrees.zig
├── sort
│   ├── bubbleSort.zig
│   ├── insertionSort.zig
│   ├── mergeSort.zig
│   ├── quickSort.zig
│   └── radixSort.zig
```

To add a new algorithm you only need to categorize and pass the exact location of the new file.

e.g.:
```zig
 // build.zig
 // new algorithm
    if (std.mem.eql(u8, op, "category/algorithm-name"))
        build_algorithm(b, mode, target, "algorithm-src.zig", "foldername");
```
to test add:

```bash
# runall.sh
$ZIG_TEST -Dalgorithm="category/algorithm-name" $StackTrace
```

**Note:** Do not change or modify the files (`build.zig` & `runall.sh`) without first suggesting it to the maintainers (open/issue proposal).