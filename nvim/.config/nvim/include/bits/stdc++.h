// bits/stdc++.h shim for clangd on macOS.
//
// GCC ships this header; Apple's clang does not, so clangd reports
// "file not found" on every competitive-programming file. Pointing clangd at
// GCC's real copy doesn't work either -- clang can't parse libstdc++ 15's
// internals. So this shim pulls in the standard headers using Apple's own
// libc++, which clangd parses cleanly.
//
// This is for the EDITOR only. Actual compilation still goes through
// g++-15, which uses GCC's real bits/stdc++.h.
#pragma once

// C library
#include <cassert>
#include <cctype>
#include <cerrno>
#include <cfloat>
#include <climits>
#include <cmath>
#include <csetjmp>
#include <csignal>
#include <cstdarg>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <cwchar>
#include <cwctype>

// Containers
#include <array>
#include <bitset>
#include <deque>
#include <forward_list>
#include <list>
#include <map>
#include <queue>
#include <set>
#include <stack>
#include <unordered_map>
#include <unordered_set>
#include <vector>

// Algorithms / numerics
#include <algorithm>
#include <bit>
#include <complex>
#include <functional>
#include <iterator>
#include <limits>
#include <numeric>
#include <random>
#include <ratio>
#include <valarray>

// Strings / streams
#include <fstream>
#include <iomanip>
#include <ios>
#include <iosfwd>
#include <iostream>
#include <istream>
#include <ostream>
#include <sstream>
#include <streambuf>
#include <string>
#include <string_view>

// Utilities
#include <chrono>
#include <exception>
#include <initializer_list>
#include <memory>
#include <new>
#include <optional>
#include <stdexcept>
#include <tuple>
#include <type_traits>
#include <typeinfo>
#include <utility>
#include <variant>

// Concurrency (rarely used in CP, but part of the real header)
#include <atomic>
#include <condition_variable>
#include <mutex>
#include <thread>
