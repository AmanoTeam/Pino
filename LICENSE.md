## License

### GCC

The GCC compiler and its runtime libraries are licensed under the [GNU General Public License version 3](https://www.gnu.org/licenses/gpl-3.0.html#license-text), with additional permissions provided by the [GCC Runtime Library Exception](https://www.gnu.org/licenses/gcc-exception-3.1.en.html).

### Termux Packages

This project includes an APT-like command-line tool that allows you to install and use libraries from the Termux Packages repository during cross-compilation. However, this does not grant any special permission to embed these libraries in your own projects.

Each package in the Termux Packages repository is distributed under its own license. You can find the relevant licenses by browsing the package list [here](https://github.com/termux/termux-packages/tree/master/packages).

### Pino

#### GCC Modifications

All patches located in the [patches](https://github.com/AmanoTeam/Pino/tree/master/patches) directory are licensed under the same terms as GCC, namely the [GNU General Public License version 3](https://www.gnu.org/licenses/gpl-3.0.html#license-text).

#### Android NDK

This project uses libraries and header files from the Android Native Development Kit (NDK) to provide a cross-compilation environment. These components are licensed under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).

#### Submodules

The repositories located in the [submodules](https://github.com/AmanoTeam/Pino/tree/master/submodules) directory contain third-party software used in the Pino build workflow. Each submodule is governed by its own license. Please refer to the respective repositories for complete licensing information.

#### Other Files

All other files in this repository, unless otherwise stated, are licensed under the [GNU Lesser General Public License v3.0](https://www.gnu.org/licenses/lgpl-3.0-standalone.html).