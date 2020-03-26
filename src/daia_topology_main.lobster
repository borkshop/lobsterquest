// For debugging purposes, this script prints out the adjacency
// matrices for Daia cubes of size 3x3x3 and 1x1x1.

import daia_topology

print "rubix cube topology"
for(new_daia_topology(3)) n, i:
    print(string(i) + ": " + string(n))

print ""
print "unit cube topology"

for(new_daia_topology(1)) n, i:
    print(string(i) + ": " + string(n))
