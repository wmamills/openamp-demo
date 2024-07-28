# Summary of testing 2024/07/23 verify stability in docker on AWS ec2

I wanted to make sure things were still stable when running in docker on 
x86_64 and arm64 Linux on Amazon EC2 machines.

## Configurations

All configurations were running openamp/demo-lite:2024-07-22
with RUNS=100 or 500 and WAIT=60

| config      | ec2 inst    | VCPUs  | RAM GB | host OS         |
| ------      | --          | --     | --     | --              |
| arm-01      | m7g.2xlarge | 8      |  32    | Ubuntu 22.04    |
| x86-01      | m7i.2xlarge | 8      |  32    | Ubuntu 22.04    |
| x86-02      | m7i.2xlarge | 8      |  32    | Ubuntu 24.04    |
| x86-03      | m7i.xlarge  | 4      |  16    | Ubuntu 22.04    |
| x86-desktop | i7-10700    | 16     |  32    | Ubuntu 22.04    |

## Results

| config      | Fails/Total |
| ------      | ----------- |
| arm-01      |    2/100    |
| x86-01      |    1/100    |
| x86-02      |    1/100    |
| x86-03      |    2/361 *  |
| x86-desktop |    3/500    |

Note: x86-03 had a different failure on test run 362.  The target seemed fine
but the host was stuck on the first of the scp steps.  It was stuck for more
than 5 hours until I manually killed it.

## Conclusions
* There is still a low level issue with qemu-zcu102
* The common failure mode is RCU lockup related to power control path
* Upgrading the zynqmp firmware might help
* Ubuntu 24.04 works as well as Ubuntu 22.04
* Arm works as well as x86
  * NOTE: the difference between 1 and 2 here is not statistically relevant for 
  this number of tests and fail rate. We would need to run at least 500 tests
  to differentiate.
* Retesting on my desktop for 500 runs did show errors overnight.  I had
previously run more than 300 test runs cleanly on this machine.  Overnight my
machine background jobs so the errors may show up when the machine is loaded.
* To test this theory I setup for 500 runs on a smaller ec2 machine.  The RCU
error rate was not drastically increased but a new error showed up once.
