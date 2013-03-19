#!/bin/bash

if [ $# == 0 ]; then
  echo "Usage: testexec.bash <test> <tests>"
  exit $?
fi

test=$1
shift
TESTS=$*

if [ -x ./common.bash ]; then
  . ./common.bash $test
elif [ -x ../common.bash ]; then
  . ../common.bash $test
else
  echo "Could not find common.bash"
  exit $?
fi

function run_test() {
	printf "  Executing ($1)..."
	P=$OUT/$1.run.out
	run_v3c "" -test -expect=expect.txt $2 $TESTS > $P
	check_red $P
}

run_test "int"
run_test "int-ra" -ra
if [ -n "$RA_PARTIAL" ]; then
    run_test "int-ra-partial" "-ra -ra-partial"
fi

printf "  Compiling (jvm)..."
mkdir -p $OUT/jvm
P=$OUT/test.execute.comp.jvm
run_v3c "" -set-exec=false -jvm.script=false -verbose=1 -multiple -target=jvm-test -output=$OUT/jvm -jvm.rt-path=../../rt/jvm/bin $TESTS > $P
check_red $P

if [ -z "$HOST_JAVA" ]; then
	printf "  Running   (jvm)...${YELLOW}skipped${NORM}\n" 
else
	printf "  Running   (jvm)..." 
	P=$OUT/test.execute.run.jvm
	$HOST_JAVA -cp ../../rt/jvm/bin:$OUT/jvm V3S_Tester $TESTS > $P
	check_red $P
fi

function do_native_test() {
	target=$1
	testtarget=$2
	extra="$3"
	mkdir -p $OUT/$target
	C=$OUT/$target/test.compile.out
	R=$OUT/$target/test.run.out

	if [ -z "$extra" ]; then
		printf "  Compiling ($target)..."
	else
		printf "  Compiling ($target $extra)..."
	fi
	run_v3c "" $extra -multiple -set-exec=false -target=$testtarget -output=$OUT/$target $TESTS &> $C
	check_red $C

	run_native $test $target $TESTS
}

do_native_test x86-darwin x86-darwin-test ""
if [ -n "$RA_PARTIAL" ]; then
    do_native_test x86-darwin x86-darwin-test "-ra-partial"
fi

do_native_test x86-linux x86-linux-test ""
if [ -n "$RA_PARTIAL" ]; then
    do_native_test x86-linux x86-linux-test "-ra-partial"
fi
