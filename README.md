# Pino

A GCC cross-compiler targeting Android.

## What is this?

This version of GCC uses the patchset from the [TUR](https://github.com/termux-user-repository/tur/tree/master/tur/gcc-15) port of GCC for Android, with additional patches to improve cross-compilation and enable its usage in Gradle projects as a replacement for Clang.

## Usage

### Gradle projects

Using Pino in Gradle projects is a bit tricky. Both CMake and ndk-build are heavily tied to the NDK's internal structure, which makes it difficult to completely replace Clang with GCC without risking breaking something in the build process.

For this to work, you will need to have both Pino (GCC) and Google's NDK (Clang) installed.

First, ensure that the Clang NDK is already installed. If you are using ndk-build or CMake with Gradle and have built your project at least once on your machine, it is very likely that the NDK is already installed. If you're unsure, go to the root directory of your project and run `./gradlew clean`:

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

### CMake

The Clang NDK provides a single, unified CMake toolchain for cross-compilation, typically located at `<ndk_prefix>/build/cmake/android.toolchain.cmake`. In contrast, Pino provides a separate toolchain for each architecture/API level supported by the NDK. These toolchains can be found in `<pino_prefix>/usr/local/share/pino/cmake`:

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

Essentially, these scripts handle the setup of `CC`, `CXX`, `LD`, and other environment variables so you don’t need to configure them manually.

## Termux packages

Pino includes a portable APT-like package manager that works with APT repositories. You can use it to install additional third-party libraries from the Termux repository for use during cross-compilation.

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

To enable Pino to use libraries from `nz`'s system root during the build, set the `PINO_NZ` environment variable:

```bash
# Enable using libraries from nz's system root
export PINO_NZ=1
```

To revert the change, set:

```bash
# Disable using libraries from nz's system root (default behavior)
export PINO_NZ=0
```

#### Limitations

- No auto-bundling of shared libraries
  - At least for now, the GCC wrapper only takes care of copying/bundling shared libraries into the APK when those libraries are part of the GCC support library. If you build an APK and link C/C++ code with third-party libraries installed from the Termux repository or another APT repository, you will have to manually copy them to the APK, as Pino won't be doing that for you. Alternatively, you can avoid copying the shared libraries by installing the static variants of those libraries and having GCC link with them instead.
- Outdated libraries on Android 5 and 6
  - Since Termux has dropped support for Android 5 and 6, you will only get up-to-date packages when targeting Android 7 or newer.

## ABIs

The NDK has its own page explaining its supported architectures and ABIs (see [Android ABIs](https://developer.android.com/ndk/guides/abis)), but since Pino differs from the Clang NDK in some aspects, this section covers the specifics of Pino and compares the behavior of both:

### `armeabi-v7a`

This refers to the ARMv7-A system architecture. Just like the Clang NDK, Pino uses `softfp` hardware floating-point and generates code in `Thumb-2` mode by default.

The Clang NDK defaults to using the `VFPv3-D32` floating-point unit along with the **ARM Advanced SIMD (Neon)** extension. Pino, however, defaults to using the `VFPv3-D16` floating-point unit and disables the Neon extension by default.

The reason for using `VFPv3-D16` instead of `VFPv3-D32` and disabling Neon is to support backward compatibility with older hardware. When first introduced in the NDK, the ARMv7-A target didn't require `VFPv3-D32` and `Neon`; they were completely optional features, so there might still be hardware around that doesn't support these instruction sets. Also, not everyone needs those fancy floating-point operations. If for some reason you do, enable it manually.

### `arm64-v8a`

This refers to the ARMv8 system architecture. Pino enables PAC (Pointer Authentication Code) and BTI (Branch Target Identification) by default for this architecture, while on the Clang NDK, these features are optional. Other than that, there are no differences between Pino and the Clang NDK.

### `x86`

This refers to the i386 system architecture. Just like the Clang NDK, GCC also assumes a 16-byte stack alignment before a function call. There are no additional differences between the ABI supported by Pino and the ABI supported by the Clang NDK.

### `x86_64`

This refers to the x64 system architecture. There are no additional differences between the ABI supported by Pino and the ABI supported by the Clang NDK.

### `riscv64`

This refers to the RISC-V system architecture. There is currently very little information about this ABI in the Android ecosystem, so I can't make a proper comparison. Pino emits code for the RV64GC architecture on the LP64D (hardfloat double) ABI by default.

### `armeabi`

This refers to the ARMv5TE system architecture. It uses `softfp` hardware floating-point and generates code in `Thumb-1` mode. The `VFPv2` floating-point unit is the default, without the Neon extension. This matches the Clang NDK.

This architecture is no longer supported by the Android NDK, but it is available in Pino for anyone interested.

For some time, it was the only supported architecture in the Android ecosystem. Devices manufactured with this specific CPU stopped being a thing around 2012. By 2015, most newer 32-bit ARM devices were using ARMv7-A instead.

### `mips`

This refers to the MIPS32r2 system architecture. It uses `hard` hardware floating-point and generates code targeting the 32-bit ABI by default, optionally supporting the o32 ABI as well. This matches the Clang NDK.

This architecture is no longer supported by the Android NDK, but it is available in Pino for anyone interested.

There were very few devices using this CPU. Android supported it until Android 8 (API level 27), but by Android 6 (API level 23), this architecture was already pretty much obsolete.

### `mips64`

This refers to the MIPS64r6 system architecture. It uses `hard` hardware floating-point and generates code targeting the 64-bit ABI by default. This matches the Clang NDK.

This architecture is no longer supported by the Android NDK, but it is available in Pino for anyone interested.

### Static vs dynamic linking

To match the behavior of the Clang NDK, Pino prefers static linking by default. However, this is entirely optional—you can switch to dynamic linking by setting the `PINO_STATIC` environment variable:

```bash
# Disable static linking (use dynamic linking)
export PINO_STATIC=0
```

To revert to the default static linking behavior, set:

```bash
# Enable static linking (default behavior)
export PINO_STATIC=1
```

Note that this setting only affects linking with the GCC support libraries (e.g., `libatomic`, `libstdc++`, `libgcc`, and others). Linking with the Bionic and Termux libraries will follow the standard GCC behavior, which uses dynamic linking.

`PINO_STATIC` works similarly to the Clang NDK's `ANDROID_STL`/`APP_STL`, but they are not quite the same. While `ANDROID_STL` and `APP_STL` only allow you to switch between static and shared runtimes for the libc++ library, `PINO_STATIC` lets you toggle between static and shared runtimes for all GCC support libraries. This means that you can even dynamically link with libraries that the Clang NDK would otherwise force you to statically link with.

## Releases

The current release is based on GCC 15 and supports cross-compiling software for all major Android architectures: `armv7`, `arm64`, `x86`, and `x86_64`. There is also experimental support for the `riscv64` architecture.

Additionally, it allows cross-compiling for architectures that have been deprecated in the Clang NDK, including `armv5`, `mips`, and `mips64`.

Pino supports targeting Android versions from 4.0.1 (API level 14) up to Android 15 (API level 35).

You can obtain releases from the [releases](https://github.com/AmanoTeam/Pino/releases) page.

## Licensing

### GCC

The GCC compiler and the runtime libraries are licensed under the [GNU General Public License version 3](https://www.gnu.org/licenses/gpl-3.0.html#license-text), but exceptions may apply. See the [GCC Runtime Library Exception](https://www.gnu.org/licenses/gcc-exception-3.1.en.html) for more information.

### Termux Packages

While Pino allows you to install and use libraries from the Termux Packages repository during cross-compilation, it does not grant you any special permission to embed them in your project. Each package from the Termux Packages repository has its own license. You can find the licenses by browsing the package list [here](https://github.com/termux/termux-packages/tree/master/packages).

### Pino

#### GCC modifications

The patches under the [patches](https://github.com/AmanoTeam/Pino/tree/master/patches) directory are licensed under the same terms as GCC, the [GNU General Public License version 3](https://www.gnu.org/licenses/gpl-3.0.html#license-text).

#### Android NDK

Pino uses library and header files from the Android NDK (Native Development Kit) to provide a cross-compilation environment, which are covered by the [Apache License version 2.0](https://www.apache.org/licenses/LICENSE-2.0).

#### Submodules

The "submodules" in the [submodules](https://github.com/AmanoTeam/Pino/tree/master/submodules) directory contain external software used by the Pino build workflow. Each has its own license. Please refer to the respective repositories for the full license details.

#### Other files

All other files in this repository, not otherwise mentioned, are licensed under the [GNU Lesser General Public License v3.0](https://www.gnu.org/licenses/lgpl-3.0-standalone.html).

## Disclaimer

This project is not officially affiliated with, nor endorsed by, Google. While it utilizes parts of the Android NDK (Native Development Kit) to provide a cross-compilation environment, it is an independent, non-commercial community-driven project.
