# Pino

A GCC cross-compiler targeting Android.

## What is this?

This is the [Termux User Repository](https://github.com/termux-user-repository/tur/tree/master/tur/gcc-15)'s GCC port for Android, with additional patches to improve cross-compilation and enable its usage in Gradle projects as a replacement for Clang.

## Usage

### Gradle projects

Using Pino in Gradle projects is a bit tricky. Both Gradle and CMake/ndk-build are heavily tied to the NDK's internal structure, which makes it difficult to completely replace Clang with GCC without risking breaking something in the build process.

For this to work, you will need to have both Pino (GCC) and Google's NDK (Clang) installed.

First, ensure that Google's NDK is already installed. If you are using ndk-build or CMake with Gradle and have built your project at least once on your machine, it is very likely that the NDK is already installed. If you're unsure, go to the root directory of your project and run `./gradlew clean`:

```
$ ./gradlew clean
Starting a Gradle Daemon (subsequent builds will be faster)

> Configure project :
Checking the license for package NDK (Side by side) 25.1.8937393 in /home/ubuntu/sdk/licenses
License for package NDK (Side by side) 25.1.8937393 accepted.
Preparing "Install NDK (Side by side) 25.1.8937393 v.25.1.8937393".
"Install NDK (Side by side) 25.1.8937393 v.25.1.8937393" ready.
Installing NDK (Side by side) 25.1.8937393 in /home/ubuntu/sdk/ndk/25.1.8937393
"Install NDK (Side by side) 25.1.8937393 v.25.1.8937393" complete.
"Install NDK (Side by side) 25.1.8937393 v.25.1.8937393" finished.

> Task :externalNativeBuildCleanDebug
> Task :externalNativeBuildCleanRelease
> Task :clean UP-TO-DATE

BUILD SUCCESSFUL in 44s
3 actionable tasks: 2 executed, 1 up-to-date
```

If you see messages like `Install NDK [...]` after running the above command, then Gradle just installed the NDK for you. If you don't see any messages like this, then either the NDK is already installed or the project you are trying to compile is not using the NDK at all. It is also possible that the project is not using the NDK directly, but instead through some other build system that is not CMake or ndk-build. In that case, you will need to figure out how to use Pino with those third-party setups on your own.

#### Patching the NDK

Pino provides a utility tool that can be used to patch the NDK so that Gradle uses GCC instead of Clang. Running it will output something like this:

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

Essentially, it overrides the NDK's `clang`/`clang++` commands with alternatives that call `gcc`/`g++` instead. It also deletes the NDK's libc++ shared libraries to prevent the Android Gradle plugin from automatically bundling them into the APK when using `-ANDROID_STL=c++_shared`.

#### Building the project

After patching the NDK, you are almost ready to go and compile the project. Just run `./gradlew clean` before compiling your project to make sure compiled objects from previous builds (Clang) don't interfere with the new build.

Changing the build workflow further (i.e., Gradle, CMake, ndk-build) is usually not required unless your project relies on features that are not available on GCC (e.g., using Clang-specific compiler/linker flags or features), which might cause build errors.



## Releases

The current release is based on GCC 15 and supports cross-compiling software to all major Android architectures (`arm`, `arm64`, `x86`, and `x86_64`).

You can obtain releases from the [releases](https://github.com/AmanoTeam/Pino/releases) page.
