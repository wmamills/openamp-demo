# Summary of testing 2024/07/18 for qemu boot hang

I was seeing occasional boot hangs but was not sure under what conditions.
I thought it happened when using the Xilinx qemu from the zephyr sdk but was
not sure that all hangs were from that setup.  So I formally tested my 
Xilinx qemu build of v2024.1 and the Xilinx qemu from the zephyr sdk 0.16.8.

## Configurations
tested with 3 different kernel
| Xilinx qemu | Description |
| ------      | --          |
| zsdk        |  Xilinx QEMU v2022.1 from Zephyr SDK 0.16.8 |
| mine        |  My build of Xilinx QEMU v2024.1            |

I started with "mine" and did multiple test runs.  There were no failures but
some test runs terminated early.  I found an issue with test-qemu that would
kill the host pane if you gave focus to the result pane.  After fixing that issue 
all test runs completed.  (The test runs would have also completed if I was
careful not to touch the tmux panes but fixing it makes it less fragile
and more user proof.)

Finally I switched to the zsdk configuration and did a sequence of 100 runs.

## Results

| kernel  | Fails/Total |
| ------  | ----------- |
| mine    |    0/308    |
| zsdk    |    13/100   |


## Conclusions
* zsdk config has issues and we definitely need to switch
