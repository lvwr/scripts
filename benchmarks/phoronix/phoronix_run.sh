#!/bin/sh
# Make sure that the tested machine has ssh access to host machine (ssh-key set)
# Benchmarking results will be uploaded with no need of user intervetion.

date
date > phoronix_run.start
scp -P71 phoronix_run.start host:~/phx_logs/
scp -P71 phoronix_run.sh host:~/phx_logs/
sleep 3;
phoronix-test-suite batch-benchmark pts/gnupg pts/openssl pts/pybench pts/phpbench pts/iozone pts/postmark pts/build-linux-kernel pts/unpack-linux pts/apache >> phoronix.log
sleep 3;
date > phoronix_run.part1
uname -a > dmesg.1
dmesg | grep CFI >> dmesg.1
scp -P71 dmesg.1 host:~/phx_logs/
scp -P71 phoronix_run.part1 host:~/phx_logs/
scp -P71 phoronix.log host:~/phx_logs/
sleep 3;

phoronix-test-suite batch-benchmark pts/dbench >> phoronix.log
sleep 3;
date > phoronix_run.part2
uname -a > dmesg.2
dmesg | grep CFI >> dmesg.2
scp -P71 dmesg.2 host:~/phx_logs/
scp -P71 phoronix_run.part2 host:~/phx_logs/
scp -P71 phoronix.log host:~/phx_logs/
sleep 3;

phoronix-test-suite batch-benchmark pts/pgbench >> phoronix.log
sleep 3;
date > phoronix_run.end
uname -a > dmesg.end
dmesg | grep CFI >> dmesg.end
scp -P71 dmesg.end host:~/phx_logs/
scp -P71 phoronix_run.end host:~/phx_logs/
scp -P71 phoronix.log host:~/phx_logs/
date
