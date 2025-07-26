# Pino

A GCC cross-compiler targeting Android.

## What is this?

This version of GCC uses the patchset from the [TUR](https://github.com/termux-user-repository/tur/tree/master/tur/gcc-15) port of GCC for Android, with additional patches to improve cross-compilation and enable its usage in Gradle projects as a replacement for Clang.

## Usage

### Gradle projects

Using Pino in Gradle projects is a bit tricky. Both CMake and ndk-build are heavily tied to the NDK's internal structure, which makes it difficult to completely replace Clang with GCC without risking breaking something in the build process.

For this to work, you will need to have both Pino (GCC) and Google's NDK (Clang) installed.

First, ensure that the NDK (Clang) is already installed. If you are using ndk-build or CMake with Gradle and have built your project at least once on your machine, it is very likely that the NDK is already installed. If you're unsure, go to the root directory of your project and run `./gradlew clean`:

```
$ ./gradlew clean
Starting a Gradle Daemon (subsequent builds will be faster)

> Configure project :
Checking the license for package NDK (Side by side) 25.1.8937393 in /home/runner/sdk/licenses
License for package NDK (Side by side) 25.1.8937393 accepted.
Preparing "Install NDK (Side by side) 25.1.8937393 v.25.1.8937393".
"Install NDK (Side by side) 25.1.8937393 v.25.1.8937393" ready.
Installing NDK (Side by side) 25.1.8937393 in /home/runner/sdk/ndk/25.1.8937393
"Install NDK (Side by side) 25.1.8937393 v.25.1.8937393" complete.
"Install NDK (Side by side) 25.1.8937393 v.25.1.8937393" finished.

> Task :externalNativeBuildCleanDebug
> Task :externalNativeBuildCleanRelease
> Task :clean UP-TO-DATE

BUILD SUCCESSFUL in 44s
3 actionable tasks: 2 executed, 1 up-to-date
```

If you see messages like `Install NDK [...]` after running the above command, then Gradle just installed the NDK for you. If you don't see any messages like this, then either the NDK is already installed or the project you are trying to compile is not using the NDK at all.

> [!NOTE]  
> It might happen that the project is not using the NDK directly, but instead through some other build system that is not CMake or ndk-build. In that case, you will need to figure out how to use Pino with those third-party setups on your own.

#### Patching the NDK

Pino provides a utility tool named `ndk-patch` that can be used to patch the NDK so that Gradle picks up our GCC toolchain instead of Clang. Running it will output something like this:

```
$ ./pino/bin/ndk-patch
- Symlinking /home/runner/pino/bin/clang to /usr/local/lib/android/sdk/ndk/25.1.8937393/toolchains/llvm/prebuilt/linux-x86_64/bin/clang
- Symlinking /home/runner/pino/bin/clang++ to /usr/local/lib/android/sdk/ndk/25.1.8937393/toolchains/llvm/prebuilt/linux-x86_64/bin/clang++
- Removing /usr/local/lib/android/sdk/ndk/25.1.8937393/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so
- Removing /usr/local/lib/android/sdk/ndk/25.1.8937393/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/i686-linux-android/libc++_shared.so
- Removing /usr/local/lib/android/sdk/ndk/25.1.8937393/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/arm-linux-androideabi/libc++_shared.so
- Removing /usr/local/lib/android/sdk/ndk/25.1.8937393/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/x86_64-linux-android/libc++_shared.so
+ Done
```

Essentially, it overrides the NDK's `clang`/`clang++` commands with alternatives that call `gcc`/`g++` instead. It also deletes the NDK's built-in libc++ shared libraries to prevent the Android Gradle plugin from automatically bundling them into the APK when using `-ANDROID_STL=c++_shared`.

#### Building the project

After patching the NDK, you are almost ready to go and compile the project. Just run `./gradlew clean` before compiling it to make sure compiled objects from previous builds (Clang) don't interfere with the new build.

Changing the build workflow further (i.e., Gradle, CMake, ndk-build) is usually not required unless your project relies on features that are not available on GCC (e.g., using Clang-specific compiler/linker flags or features), which might cause build errors.

#### Limitations

- Static linking of NDK libraries not available for now
  - Any NDK library you link your software with will end up using the shared version instead. Setting flag switches like `ANDROID_STL=c++_static` will also have no effect.

### CMake

The Clang NDK provides a single, unified CMake toolchain for cross-compilation, typically located at `<ndk_prefix>/build/cmake/android.toolchain.cmake`. However, we are following a different approach: instead of using a unified toolchain for all targets, we provide a separate toolchain for each architecture/API level supported by the NDK. These toolchains can be found in `<pino_prefix>/usr/local/share/pino/cmake`:

```bash
$ ls <pino_prefix>/usr/local/share/pino/cmake
aarch64-unknown-linux-android.cmake
aarch64-unknown-linux-android21.cmake
aarch64-unknown-linux-android22.cmake
...
arm-unknown-linux-androideabi.cmake
arm-unknown-linux-androideabi21.cmake
arm-unknown-linux-androideabi22.cmake
...
i686-unknown-linux-android.cmake
i686-unknown-linux-android21.cmake
i686-unknown-linux-android22.cmake
...
riscv64-unknown-linux-android.cmake
riscv64-unknown-linux-android35.cmake
...
x86_64-unknown-linux-android.cmake
x86_64-unknown-linux-android21.cmake
x86_64-unknown-linux-android22.cmake
```

So, instead of configuring your project like this...

```
$ cmake \
    -DCMAKE_TOOLCHAIN_FILE='<ndk_prefix>/build/cmake/android.toolchain.cmake' \
    -DANDROID_ABI='armeabi-v7a' \
    -DANDROID_PLATFORM='android-24' \
    ...
```

...do this instead:

```
$ cmake \
    -DCMAKE_TOOLCHAIN_FILE='<pino_prefix>/usr/local/share/pino/cmake/arm-unknown-linux-androideabi24.cmake' \
    ...
```

### Autotools

For convenience, Pino also provides helper scripts that can be used to set up an environment suitable for cross-compiling projects based on Autotools and similar tools. These scripts can be found in `<pino_prefix>/usr/local/share/pino/autotools`:

```bash
$ ls <pino_prefix>/usr/local/share/pino/autotools
aarch64-unknown-linux-android.sh
aarch64-unknown-linux-android21.sh
aarch64-unknown-linux-android22.sh
...
arm-unknown-linux-androideabi.sh
arm-unknown-linux-androideabi21.sh
arm-unknown-linux-androideabi22.sh
...
i686-unknown-linux-android.sh
i686-unknown-linux-android21.sh
i686-unknown-linux-android22.sh
...
riscv64-unknown-linux-android.sh
riscv64-unknown-linux-android35.sh
...
x86_64-unknown-linux-android.sh
x86_64-unknown-linux-android21.sh
x86_64-unknown-linux-android22.sh
```

They are meant to be `source`d by you whenever you want to cross-compile a project:

```bash
# Set up the environment for cross-compilation
$ source <pino_prefix>/usr/local/share/pino/autotools/aarch64-unknown-linux-android21.sh

# Configure & build the project
$ ./configure --host="${CROSS_COMPILE_TRIPLET}"
$ make
```

## Termux packages

Pino includes a portable APT-like package manager that works with APT repositories. You can use it to install additional third-party libraries from the Termux repository and use them during cross-compilation.

You can install packages to a specific system root using the corresponding `<triplet><api_level>-nz` command inside the `<pino_prefix>/bin` directory:

```bash
# Install zlib and zstd
$ aarch64-unknown-linux-android21-nz \
    --install 'zlib;zstd'
```

There is also an `apt` script wrapper around `nz` that allows you to install packages using the familiar `apt install` syntax:

```bash
# Install zlib and zstd
$ aarch64-unknown-linux-android21-apt install \
    zlib \
    zstd
```

To enable Pino to use libraries from nz's system root during the build, set the `PINO_NZ` environment variable:

```bash
$ export PINO_NZ=1
```

#### Limitations

- No auto-bundling of shared libraries
  - At least for now, the GCC wrapper only takes care of copying/bundling shared libraries into the APK when those libraries are part of the GCC support library. If you build an APK and link C/C++ code with third-party libraries installed from the Termux repository or another APT repository, you will have to manually copy them to the APK, as Pino won't be doing that for you. Alternatively, you can avoid copying the shared libraries by installing the static variants of those libraries and having GCC link with them instead.
- Outdated libraries on Android 5 and 6
  - Since Termux has dropped support for Android 5 and 6, you will only get up-to-date packages when targeting Android 7 or newer.

## Releases

The current release is based on GCC 15 and supports cross-compiling software to all major Android architectures (`arm`, `arm64`, `x86`, and `x86_64`). There is also experimental support for the `riscv64` architecture.

Additionally, it supports cross-compiling to architectures whose support has been dropped in the official NDK: `armv5`, `mips`, and `mips64`.

You can obtain releases from the [releases](https://github.com/AmanoTeam/Pino/releases) page.
