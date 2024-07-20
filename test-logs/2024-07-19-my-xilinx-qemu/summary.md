# Summary of testing 2024/07/19 for qemu boot hang

I wanted to make sure things were stable when using my build of Xilinx QEMU.

## Configurations
tested with 3 different kernel
| Xilinx qemu | Description |
| ------      | --          |
| early       |  First run did not have qemu pane logging and ssh timeout was 30 tries |
| later       |  I added qemu pane logging and set ssh timeout to 60 tries             |

I did get 1 fail on the early setup but q/o qemu logging I don't know what was
happening of the target side. It could be I was loading the computer with other
things that slowed down the qemu and the timeout happened.

I added qemu logging and increased the ssh timeout to 60 tries (each try is 
2 seconds).  200 runs of this later config ran clean.  Keeping lots of qemu
logs when nothing goes wrong is not that interesting so I delete all but the
first and last of each test-qemu invocation.  The timestamps between the qemu
logs is somewhat interesting so I wrote calc-deltas and recorded the results
for each qemu-test run.

## Results

| kernel  | Fails/Total |
| ------  | ----------- |
| early   |    1/100    |
| later   |    0/200    |


## Conclusions
* for now assume the fail was computer loading and a timeout that was too tight
* HOWEVER, keep and I out, we are better equipped to dive deeper if we see it again
