# proxmox-balance
Simplistic script to rebalance your proxmox cluster using my "second worst first" algorithm.

## Second Worst First
If the server is loaded then find the second worst offending VM and move it to another server where the load is less than half as bad.

Reasoning:
You can't move the worst offender as this will mostly just overload another node.  If you are moving the second worst then it should be responsible for less than 50% of the load and so adding it to another node where the load is <50% of here will result in a load lower than here.

Cons: 
Need to check other contraints like memory too before you do the move suggested.
Script is quite brittle as it uses test searches of command output rather than the API.
