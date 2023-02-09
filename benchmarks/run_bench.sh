#!/bin/bash
readme="\
See ./local_wsl2.log for benchmarks result from test run on WSL2 of my local PC.\
It shows amqprs has better performance than lapin.\
\
But, benchmark result from default GitHub-hosted runner machine shows lapin has \
better performance than amqprs.\
\
There are various factors to investigate \
    1. CPU and Memory \
    2. underlying system libraries \
    3. Network IO \
    4. Environment setup\
\
"

echo $readme
set -x
export RUSTFLAGS="$RUSTFLAGS -A dead_code -A unused_variables"
CARGO_OPTS="-p benchmarks"

# check environments
uname -a
lsb_release -a
rustc -V
cargo -V
cc -v # gcc linker for libc
lscpu

# check dependencies
cargo tree -i tokio -e all
cargo tree -i amqprs -e all
cargo tree -i lapin -e all

# build "bench" profile first, might allow cooldown of system before test begins
cargo bench --no-run
profile_exe=$(cargo bench --no-run 2>&1 | grep basic_pub | sed -E 's/.+basic_pub.+\((.+)\)/\1/')
echo $profile_exe
sleep 3

# run separately, otherwise there is runtime conflict/error
sleep 3
cargo bench ${CARGO_OPTS} -- amqprs
sleep 3
cargo bench ${CARGO_OPTS} -- lapin

# run strace profile
strace -c $profile_exe --bench --profile-time 10 amqprs
strace -c $profile_exe --bench --profile-time 10 lapin
