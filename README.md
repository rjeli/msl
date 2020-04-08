# macOS subsystem for Linux

##⚠️ under construction, come back soon :)

Seamlessly run Linux CLI applications under macOS.

MSL is a script that installs Debian under the bhyve hypervisor, mounts your Debian home directory into your host macOS home directory, and installs shell hooks so you can switch between the two OSes easily.

### Why not Docker for Mac, Vagrant, Virtualbox, ...?

MSL and Docker for Mac both use bhyve, which uses Hypervisor.framework, so they're similar underneath. However, the primary goal of MSL is to remove any extra steps between your macOS and Linux shell. No `docker run -it -exec -a --detach -mount type=bind,src=dst that-one-image bash`... or even `vagrant ssh`, just `cd ~/deb`.
