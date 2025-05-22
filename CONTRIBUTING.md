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
│   └── threads
│       └── ThreadPool.zig
├── dataStructures
│   ├── doublyLinkedList.zig
│   ├── linkedList.zig
│   ├── lruCache.zig
│   ├── stack.zig
│   └── trie.zig
├── dynamicProgramming
│   ├── coinChange.zig
│   ├── editDistance.zig
│   ├── knapsack.zig
│   └── longestIncreasingSubsequence.zig
├── machine_learning
│   └── k_means_clustering.zig
├── math
│   ├── ceil.zig
│   ├── chineseRemainderTheorem.zig
│   ├── euclidianGreatestCommonDivisor.zig
│   ├── factorial.zig
│   ├── fibonacciRecursion.zig
│   ├── gcd.zig
│   └── primes.zig
├── runall.sh
├── search
│   ├── binarySearchTree.zig
│   └── redBlackTrees.zig
├── sort
│   ├── bubbleSort.zig
│   ├── insertionSort.zig
│   ├── mergeSort.zig
│   ├── quickSort.zig
│   └── radixSort.zig
└── web
    ├── http
    │   ├── client.zig
    │   └── server.zig
    └── tls
        └── X25519+Kyber768Draft00.zig
```

To add a new algorithm you only need to categorize and pass the exact location of the new file.

e.g.:
```zig
// build.zig
// new algorithm
if (std.mem.eql(u8, op, "category/algorithm-name"))
    buildAlgorithm(b, .{
        .optimize = optimize,
        .target = target,
        .name = "algorithm-src.zig",
        .category = "category",
    });
```
to test add:

```zig
# runall.zig
try runTest(allocator, "category/algorithm-name");
```

**Note:** Do not change or modify the files (`build.zig` & `runall.zig`) without first suggesting it to the maintainers (open/issue proposal).