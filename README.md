# In-World Owned-Parcel Avatar Sensor

This is a sensor for periodically sensing all of the avatars that are present on owned parcels in a region. It sends the results to a RL server via HTTP. 

The code for the scanner script in the prim is as follows (assuming that the repo is in the `sim-scanner-lsl` directory):

```
#include "sim-scanner-lsl/scanner.lsl"
```

The code for the transmitter script in the prim is: 

```
#include "sim-scanner-lsl/transmitter.lsl"
``

