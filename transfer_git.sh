#!/bin/bash

set -e

SSH="ssh -i daala.pem -o StrictHostKeyChecking=no"

if [ -z $DAALA_ROOT ]; then
  echo "Please set DAALA_ROOT to the location of your libvpx git clone"
  exit 1
fi

echo Building...
pushd $DAALA_ROOT
./autogen.sh; ./configure --enable-static --disable-shared --disable-player --disable-dump-images --enable-logging --enable-dump-recons ; make -j4
popd

echo Testing server...
$SSH ec2-user@$1 "echo Available"

echo "Checking for other users..."
if $SSH ec2-user@$1 "pgrep encoder"
then
  echo "The server is already running encoder_example processes. Killing."
  $SSH ec2-user@$1 "killall -9 lt-encoder_example"
fi

echo Cleaning server...
$SSH ec2-user@$1 "rm -rf *.png"

#echo Importing ssh keys...

#ssh-keyscan -H $1 >> ~/.ssh/known_hosts

echo Uploading tools...

rsync -r -e "$SSH" ./ ec2-user@$1:/home/ec2-user/rd_tool/

rsync -r -e "$SSH" ../daalatool/ ec2-user@$1:/home/ec2-user/daalatool

echo Uploading local build...

rsync -r -e "$SSH" $DAALA_ROOT/ ec2-user@$1:/home/ec2-user/daala/
