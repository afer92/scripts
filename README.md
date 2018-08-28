# scripts
Scripts - The good, the bad and the ugly (wooohooohooh dah dah dah ...)

Some useful scripts worth publishing ... even if ugly ...

PRs more than welcome to improve my scripting style ...

# 1. ssh_wait.sh

This script uses nc (ncat) to test that the ssh service (port is open) before (optionally) trying to connect.

#### Examples
- ssh_wait.sh mymachine
- ssh_wait.sh me@mymachine
- ssh_wait.sh -l me mymachine
- [-c: connect when ready] ssh_wait.sh -c -l me mymachine 
- ssh_wait.sh -c -l me mymachine uptime



