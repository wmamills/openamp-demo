# Summary of testing 2022/11/11-12 for qemu hang/crash/fail

## Configurations
tested with 3 different kernel
| Kernel | Description |
| ------ | -- |
| 6.0.0  |  openamp-staging-6.0 = v6.0 + Tanmay's zynqmp remoteproc & Arnaud's ept patch  uses zynqmp_defconfig made from Xilinx vendor config |
| 6.0.7  |  as above plus cherry pix of pinctrl fix (not really 6.0.7 but a preview)
| xil-5.15 | Xilinx vendors kernel as built by 2022.1_update3 |

I did two test runs that counted:
* 11-11 did 58  boots of each kernel (after that /tmp filled up and everything failed)
                xil-5.15 actually only did 57 runs
* 11-12 did 100 boots of each kernel (export TMP=~/big/tmp)

## Results

| kernel  | Fails/Total |
| ------  | ----------- |
| 6.0.0   |    32/158   |
| 6.0.7   |    0/158    |
| xil-5.15 |   1/157    |

The xil-5.15 error is obviously an outlier.
* I was actually watching at that time.
* That failure was very different.
* No initial PMU messages came out.
* It just said "Starting qemu" until the host pane killed it.

## Conclusions
* 6.0.0 definitely has issues
* 6.0.7 is much better
* there may be some other issue VERY occasionally
* keep and eye out for issues
* look at new versions of side load firmware or qemu binaries
