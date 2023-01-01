## License

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
