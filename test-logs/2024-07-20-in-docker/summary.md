# Summary of testing 2024/07/20 verify stability in docker

I wanted to make sure things were still stable when running in docker on 
x86_64 and arm64 Linux.

## Configurations

| configuration   | Description |
| ------          | --          |
| demo-lite x86   | openamp/demo-lite:2024-07-20 on my x86 based desktop |
| demo-lite arm64 | openamp/demo-lite:2024-07-20 on my ec2 m7g.2xlarge |


## Results

| kernel          | Fails/Total |
| ------          | ----------- |
| demo-lite x86   |    0/100    |
| demo-lite arm64 |    0/100    |


## Conclusions
* Looks good
