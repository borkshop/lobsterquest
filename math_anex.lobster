// more missing math methods.

// def power_of_two(n):
//     return n > 0 and ~(n - 1) & n == n

def mod(n, m):
    // if power_of_two(m): return n & m
    return (n % m + m) % m
