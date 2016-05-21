Haskell deployed using fully open source toolchain to iCE40
===========================================================

This is a simple demo for compiling of [Haskell](http://www.haskell.org)
code into FPGA configuration.

[_Field Programmable Gate Arrays_](https://en.wikipedia.org/wiki/Field-programmable_gate_array) (FPGAs) are
a cheap and fast tool for prototyping hardware descriptions that can be
later used for creating chips.

[_Haskell_](http://www.haskell.org) is a lazy functional programming language,
which lends itself readily to both very high level descriptions of software,
and very low level descriptions of hardware, due its solid mathematical underpinnings.

This demo uses fully open source toolchain:

  * [CλaSH](http://www.clash-lang.org/) for compiling Haskell into Verilog,
  * [Yosys](http://www.clifford.at/yosys/) [Verilog](https://en.wikipedia.org/wiki/Verilog) compiler to compile Verilog code into `.blif` format,
  * [Arachne Place-N-Route](https://github.com/cseed/arachne-pnr) to perform routing onto the _Lattice ICE40 H1K_ device,
  * [IceStorm](http://www.clifford.at/icestorm/) toolchain in order to generate FPGA bitstream and upload it
    into [Lattice IceStick](http://latticesemi.com/iCEstick) device.

_This project used as a *project template* for your own experiments
with Haskell and FPGAs._ In this case, please remove `README.md` file after cloning.

This one uses a single counter to show a binary stopwatch with a range of 2⁵ seconds.

Installing toolchain:
---------------------
1. First install the [IceStorm](http://www.clifford.at/icestorm/) toolchain:
    * IceStorm utilities themselves:

        ```bash
        git clone https://github.com/cliffordwolf/icestorm.git icestorm
        make -j4	-DPREFIX=$HOME/icestorm
        make		-DPREFIX=$HOME/icestorm install
        ```

        For Linux you also might want to enable write access through FTDI USB device:

        ```
        cat - <<EOF > /etc/udev/rules.d/53-lattice-ftdi.rules
        ACTION=="add", ATTR{idVendor}=="0403", ATTR{idProduct}=="6010", MODE:="666"
        EOF
        ```
    
    * [Arachne PNR](https://github.com/cseed/arachne-pnr) tool:

        ```bash
        git clone https://github.com/cseed/arachne-pnr.git arachne-pnr
        cd arachne-pnr
        make -j$(nproc) -DDEST_DIR=$HOME/icestorm -DICEBOX=$HOME/icestorm/share/icebox/
        make install
        ```
        
    * Yosys Verilog compiler:

        ```bash
        git clone https://github.com/cliffordwolf/yosys.git yosys
        cd yosys
        make -j$(nproc) -DPREFIX=$HOME/icestorm
        make            -DPREFIX=$HOME/icestorm install
        ```
        
2. [CλaSH](http://www.clash-lang.org/) compiler based on [GHC](https://www.haskell.org/ghc/):
    * To install GHC and Cabalon Linux:

        ```
        apt-get install ghc cabal-install
        ```
    * To install GHC on Windows it is recommended to either use `.msi` package of Haskell Platform or Stack installation utility.
    * From within this environment, use `cabal-install` to setup `clash-ghc` package:

        ```bash
        cabal install clash-ghc
        ```
        
Files in this repository:
----------------

* `Demo.hs` - contains Haskell code for the 32-second timer.

* `icestick.pcf` - assigns names to _Lattice iCE40 H1K_ pins on [iCEStick](http://latticesemi.com/iCEstick) board.

* `icoboard.pcf` - assigns names to _Lattice iCE40 H8K_ pins on [IcoBoard](http://www.icoboard.org).

Compilation steps:
------------------
While there will be Makefile, you might want to look through the build process step by step:

1. For simulation just compile it with `clash` as a Haskell program, and run:

    ```bash
    clash Demo.hs
    ```

2. For Verilog generation:

    * run interpreter: `clash --interactive Demo.hs`
    * enter `:verilog` in the interpreter to generate `.verilog` code

3. To compile Verilog into `.blif` netlist format:

    ```
    yosys -p "synth_ice40 -blif demo.blif" Verilog/Main/Demo_TopEntity.v
    ```

4. To route `.blif` netlist onto Lattice IceStick device:

    ```
    arachne-pnr -d 1k -p demo.pcf demo.blif -o demo.txt
    ```

5. To compile routed netlist into bitstream:

    ```
    icepack demo.txt demo.bin
    ```

6. To upload bitstream onto the FPGA: 

    ```
    iceprog demo.bin
    ```
    NOTE: If you forgot to add the relevant udev rule, you might need to use `sudo` here.

Or use `Makefile`:

```
make test
make upload
```

Future plans:
-------------
It would be nice to wrap Ice40 PLL configuration as a custom block:

* For Verilog code see: [iCEStick PLLs](https://www.reddit.com/r/yosys/comments/3yrq6d/are_plls_supported_on_the_icestick_hw/)

* Wrapping of custom blocks in CλaSH code is
  [described in this documentation](http://hackage.haskell.org/package/clash-prelude-0.7.5/docs/CLaSH-Tutorial.html#g:13).
