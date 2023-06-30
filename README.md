# TensorflowDeployWithCpp
Using c++ load tensorflow2.0 saved_model and do inference.

###	1. 参考google官方教程：
从源代码构建 https://tensorflow.google.cn/install/source

* a) 安装python和相关依赖 	
```
sudo apt install python-dev python-pip  # or python3-dev python3-pip
pip install -U --user pip six numpy wheel setuptools mock 'future>=0.17.1'
pip install -U --user keras_applications --no-deps
pip install -U --user keras_preprocessing --no-deps
```
可以在安装的时候使用清华源：-i https://pypi.tuna.tsinghua.edu.cn/simple

### 2. 环境准备：

* a) 准备对应版本的 bazel 和 gcc/g++ (我使用GCC 7.5, 也是没有问题的)
经过测试的构建配置    
Linux CPU    

    |版本|Python版本|编译器|构建工具|build日期|
    |---|----|---|---|---|
    |tensorflow-2.6.0|3.6-3.9|GCC 7.3.1|Bazel 3.7.2|2023/06/29|
    |tensorflow-2.1.0|2.7、3.5-3.7|GCC 7.3.1|Bazel 0.27.1|-|
    |tensorflow-2.0.0|2.7、3.3-3.7|GCC 7.3.1|Bazel 0.26.1|-|

* b)	切换apt-get为阿里源:         
https://www.cnblogs.com/hcl1991/p/7894958.html
https://blog.csdn.net/rihongliu/article/details/83657761
可以把阿里源添加在之前的源的上面，不然可能找不到 gcc-7

* c) 安装git gcc 等必要程序

``` bash
sudo apt-get install git
sudo apt-get install gcc-7
```

如果安装了多个gcc版本可以使用：进行切换

```bash
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 50 
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 70 
```

* d) 安装bazel

- [bazel-3.7.2-installer-linux-x86_64.sh](https://github.com/bazelbuild/bazel/releases/download/3.7.2/bazel-3.7.2-installer-linux-x86_64.sh)
- [bazel-3.7.2-windows-x86_64.exe](https://github.com/bazelbuild/bazel/releases/download/3.7.2/bazel-3.7.2-windows-x86_64.exe)

```bash
sudo ./bazel-0.27.1-installer-linux-x86_64.sh
bazel version

Extracting Bazel installation...
WARNING: --batch mode is deprecated. Please instead explicitly shut down your Bazel server using the command "bazel shutdown".
Build label: 0.27.1
Build target: bazel-out/k8-opt/bin/src/main/java/com/google/devtools/build/lib/bazel/BazelServer_deploy.jar
Build time: Tue Jul 2 17:49:35 2019 (1562089775)
Build timestamp: 1562089775
Build timestamp as int: 1562089775
```

如果是windows需要安装

1. msys2 & bazel 配置好环境变量

```powershell
$Env:BAZEL_VC="C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\"
$Env:BAZEL_VC_FULL_VERSION="14.29.30133"
```

有一些依赖下载需要代理：在powershell设置代理：

```powershell
$env:all_proxy="socks5://127.0.0.1:10808"
```

* e) 下载tensorflow git源码，并切换为2.1分支

``` bash
git clone git@github.com:tensorflow/tensorflow.git
git 分支查看与切换
git branch -a
git checkout -b r2.1 remotes/origin/r2.1
```

* f) 编译tensorflow2.1

``` bash
./configure  #均使用默认值，一路回车，配置完成后编译，编译命令如下：
#bazel build -c opt --config=cuda --copt=-march=native tensorflow:libtensorflow_cc.so
#bazel build --config=opt tensorflow:libtensorflow_cc.so
bazel build --config=opt //tensorflow:libtensorflow_cc.so
```

[注意]，编译期间要下载很多相关依赖，建议在国内早上时间相对快速一些。

编译成功以后产生包含如下内容的信息
Target //tensorflow:libtensorflow_cc.so up-to-date:
  bazel-bin/tensorflow/libtensorflow_cc.so

编译期间根据硬件不同可能产生如下错误：
bazel build -c opt //tensorflow/tools/pip_package:build_pip_package
C++ compilation of rule ‘//tensorflow/core/kernels:broadcast_to_op’ failed(Exit 4)

后来查询得知是编译过程中swap空间不足引起的，采用以下方法可以正常编译：

```bash
bazel build -c opt //tensorflow/tools/pip_package:build_pip_package --local_resources 2048,.5,1.0
```

增加 `--local_resources 2048,.5,1.0` 使得bazel同一时刻产生不超过一个编译器进程。

> 原因是编译过程中swap空间不足引起的

如果是低版本的编译，可以在编译后面加上 --local_resources 2048,.5,1.0
> bazel build --config=opt --config=cuda //tensorflow:libtensorflow_cc.so --local_resources 2048,.5,1.0

如果是高版本的编译，可以加上 --local_ram_resources=200 --local_cpu_resources=10

> bazel build --config=opt --config=cuda //tensorflow:libtensorflow_cc.so --local_ram_resources=200 --local_cpu_resources=10

顺便说一句，编译TensorFlow c++还是痛苦的，会有很多坑。我编译了tf2.0和tf2.4都成功了，感受就是，其实报错的很大部分原因就是 要么网速不好，要么内存空间不足，一遍不过，再来一遍就过了。


* g) 生成库以后，拷贝到指定目录

为了方便这里拷贝了整个文件夹，如果只拷贝.h，可以使用 copy_header.sh 脚本
把生成的文件夹的内容bazel-bin(bazel-genfiles 亦可，因为这两个是软链接，指向同一个位置)拷贝到指定位置：

```
# 拷贝 so
sudo cp bazel-bin/tensorflow/*.so* /usr/local/lib/

# 拷贝 .h 等
sudo mkdir /usr/local/include/tf
# 应该只拷贝依赖，为了方便，全部拷贝过来
sudo cp -rf bazel-bin/* /usr/local/include/tf   
sudo cp -rf --parents  third_party/* /usr/local/include/tf    
sudo cp -rf --parents  tensorflow/c /usr/local/include/tf    
sudo cp -rf --parents  tensorflow/cc /usr/local/include/tf    
sudo cp -rf --parents  tensorflow/core /usr/local/include/tf   
```

### 3. 编译 sample 中的 label_image 测试程序

路径：tensorflow/examples/label_image
编译依赖 abseil-cpp，protocbuf, eigen3 当然这些也可以在编译 tensorflow 之前安装，不安装也不影响 tensorflow 编译，它会下载相关依赖
//参考这篇文章安装，依次安装bazel, protocbuf, eigen3，然后下载tensorflow源码，编译c++ api，将编译结果拷贝到搜索路径

* a) abseil-cpp

解决方案：下载源码，然后把该库加到搜索目录里面

``` bash
git clone https://github.com/abseil/abseil-cpp
sudo cp -r abseil-cpp /usr/local/include/
```

* b) eigen3

``` bash
sudo apt-get install libeigen3-dev
````

* c) protobuf，这里要注意版本匹配

在 tensorflow/workspace.bzl
中找到版本对应关系
    # 310ba5ee72661c081129eb878c1bbcec936b20f0 is based on 3.8.0 with a fix for protobuf.bzl.
    PROTOBUF_URLS = [
        "https://storage.googleapis.com/mirror.tensorflow.org/github.com/protocolbuffers/protobuf/archive/310ba5ee72661c081129eb878c1bbcec936b20f0.tar.gz",
        "https://github.com/protocolbuffers/protobuf/archive/310ba5ee72661c081129eb878c1bbcec936b20f0.tar.gz",
    ]

``` bash
wget  "https://github.com/protocolbuffers/protobuf/archive/310ba5ee72661c081129eb878c1bbcec936b20f0.tar.gz"
tar zxvf 310ba5ee72661c081129eb878c1bbcec936b20f0.tar.gz
cd protobuf-310ba5ee72661c081129eb878c1bbcec936b20f0

$ ./autogen.sh
$ ./configure
$ make
$ make check
$ sudo make install
$ sudo ldconfig # refresh shared library cache.
```
```
./autogen.sh: 4: autoreconf: not found
是在不同版本的 tslib 下执行 autogen.sh 产生。它们产生的原因一样,是因为没有安装automake 工具, (ubuntu 18.04)用下面的命令安装好就可以了。

sudo apt-get install autoconf automake libtool
```

* d) 编译

```
g++ -std=c++11 -o tfcpp_demo -I /usr/local/include/tf -I /usr/include/eigen3 -I /usr/local/include/abseil-cpp -L /usr/local/lib main.cc `pkg-config --cflags --libs protobuf` -ltensorflow_cc -ltensorflow_framework   
```
```
利用 label_image demo 程序进行推理：
outputs size: 1
2020-05-02 20:15:10.665496: I main.cc:262] basset (162): 0.717387
2020-05-02 20:15:10.665551: I main.cc:262] bloodhound (164): 0.0583763
2020-05-02 20:15:10.665563: I main.cc:262] beagle (163): 0.0121132
2020-05-02 20:15:10.665569: I main.cc:262] Sussex spaniel (221): 0.00703464
2020-05-02 20:15:10.665575: I main.cc:262] English foxhound (168): 0.00291532
```