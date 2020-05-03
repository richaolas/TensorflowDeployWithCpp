#!/bin/bash -eu
# -*- coding: utf-8 -*-

HEADER_DIR=/tmp/tensorflow/include

if [ ! -e $HEADER_DIR ];
then
    mkdir -p $HEADER_DIR
fi

# copy bazel-bin/
# copy 
#花括号代表前面find查找出来的文件名，反斜杠分号代表语句结束 
pushd bazel-bin
find external        -follow -type f -name "*.h" -exec cp --parents {} $HEADER_DIR \;
find tensorflow      -follow -type f -name "*.h" -exec cp --parents {} $HEADER_DIR \;
find third_party     -follow -type f -name "*.h" -exec cp --parents {} $HEADER_DIR \;
popd

find third_party     -follow -type f -name "*" -exec cp --parents {} $HEADER_DIR \;
find tensorflow/core -follow -type f -name "*.h" -exec cp --parents {} $HEADER_DIR \;
find tensorflow/cc   -follow -type f -name "*.h" -exec cp --parents {} $HEADER_DIR \;
find tensorflow/c    -follow -type f -name "*.h" -exec cp --parents {} $HEADER_DIR \;



#find third_party/eigen3 -follow -type f -exec cp --parents {} $HEADER_DIR \;

#pushd bazel-genfiles
#find tensorflow -follow -type f -name "*.h" -exec cp --parents {} $HEADER_DIR \;
#popd

#pushd bazel-tensorflow/external/protobuf/src
#find google -follow -type f -name "*.h" -exec cp --parents {} $HEADER_DIR \;
#popd

#pushd bazel-tensorflow/external/eigen_archive
#find Eigen       -follow -type f -exec cp --parents {} $HEADER_DIR \;
#find unsupported -follow -type f -exec cp --parents {} $HEADER_DIR \;
#popd
