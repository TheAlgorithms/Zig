# Algorithms-Zig

All Algorithms implemented in Zig

## TODO

- **Data Structures**
- **Graph**
- **Math**
- **Sort**
- **Search**
- **Dynamic Programming**


## How to build

**Require:** [Zig v0.10 or higher](https://ziglang.org/download)

```bash
## Math
$> zig build test -Dalgorithm=math/crt  # chinese remainder theorem
$> zig build test -Dalgorithm=math/ceil

## Dynamic Programming
$> zig build test -Dalgorithm=dp/fibonacci

## Data Structures
$> zig build test -Dalgorithm=ds/linkedlist
```