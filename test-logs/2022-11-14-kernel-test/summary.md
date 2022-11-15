# Summary of testing 2022/11/11-14 for qemu hang/crash/fail

## Configurations
tested with 4 different kernel
The first 3 are exactly the same as in the 11/12 test

| Kernel | Description |
| ------ | -- |
| 6.0.0  |  openamp-staging-6.0 = v6.0 + Tanmay's zynqmp remoteproc & Arnaud's ept patch uses zynqmp_defconfig made from Xilinx vendor config |
| 6.0.7  |  as above plus cherry pix of pinctrl fix **(not really 6.0.7 but a preview)**
| xil-5.15 | Xilinx vendors kernel as built by 2022.1_update3 |
| oas-6.0.y | Really 6.0.7 (which includes pinctl fix) + Tanmay's and Arnaud's patches, as built by openamp-ci-builds (wmamills fork right now)

I did one test run:
* 11-14 did 120 boots of each kernel

## Results

| kernel  | Fails/Total |
| ------  | ----------- |
| 6.0.0   |    **33**/120   |
| 6.0.7   |    0/120    |
| xil-5.15 |   0/120    |
| oas-6.0.y |   **14**/120    |

Differences between oas-6.0.y and 6.0.7 (6.0+3 really)
* oas-6.0.y is being booted with the correct modules
  * 6.0.7 and xil-5.15 are being booted w/ no matching modules
  * **The kernels that boot well don't have modules!!**
* oas-6.0.y is actually using 6.0.7 as a base
  * lots of other code fixes have gone in between 6.0 and 6.0.7
  * the kernel called 6.0.7 is really 6.0+3
* oas-6.0.y is being built by OE w/ the calculated defconfig
  * 6.0.7 is being hand built w/ a copy of the xil-5.15 defconfig

## Conclusions
* Need to test all w/ no modules
* Need to test xil-5.15 w/ modules (and maybe 6.0.7)
* Need to test oas-6.0.y hand built w/ zynqmp_defconfig
