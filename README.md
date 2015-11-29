# Cloud

### Requirements
- [`.DvgFiles`](https://github.com/dantevg/DvgApps#how-to-install-dvgfiles) installation (for client)
- Wireless modem

### Installation
##### Client
1. Download the client program from pastebin: [`2Ni5n1M8`](http://pastebin.com/2Ni5n1M8). It will install at the first run.

##### Server
1. Setup a computer with a wireless modem and a disk drive with disk. All data will be stored on that disk.
2. Create a folder named `cloud` on the disk.
3. Download the server program from pastebin: [`qEN1Lff6`](http://pastebin.com/qEN1Lff6).
4. Create a `startup` file containing the following code:

```lua
rednet.open("side") --replace with modem side
shell.run("server") --replace with program name
```

### Functions
The program works as if you were in a folder. The following commands are supported: \*added in 1.2
- Type file name to run
- Type `ls` to lit files
- Type `edit` to edit a file.
- Type `exit` to exit the program.
- Type `rm` to remove a file.*
