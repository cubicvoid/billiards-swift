# BilliardSearch
Utilities for finding and analyzing periodic billiard paths over triangles.

## Installing

This code was developed and tested using swift-4.1-RELEASE on Ubuntu 16.04.
It requires libgmp and libbsd.

### Clone the repository

`git clone https://github.com/faec/BilliardSearch.git`

### Connect the system modules

`BilliardSearch` depends on `libgmp` and (on Linux) `libbsd`, so you should
install these first and (if needed) edit `Modules/module.modulemap` so that
the CGmp module points to `gmp.h` on your system. If you get a build error such
as `error: header '/usr/local/include/gmp.h' not found` then the header file
path in `Modules/module.modulemap` is not correct.

### Build

Once the modules are set up, you can build:

```
swift build -Xlinker -L/usr/local/lib [-c release]
```

### Run

This repo has a lot of experimental utilities and options, and is alpha
software. But if you want to try it out you might do something like this:

```
.build/release/BilliardSearch \
  --apexCount 100 --gridDensity 5000000000 \
  --maxFanCount 20 \
  --maxFlipCount 8 \
  --unsafeMath
```

This will generate 100 random triangles, and try to find periodic billiard
paths for each of them. It will write its results to `Data/`.

### Run interactively

The scripts `BilliardSearch/repl-debug` and `BilliardSearch/repl-release`
will let you use `BilliardLib` in an interactive Swift repl using the
specified build configuration. They assume that the library is successfully
built as described above.

By default the swift repl is unhelpfully verbose. You can turn off a lot of the debug cruft by entering `:settings set print-decls false` at the repl prompt.
