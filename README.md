# Remote_attestation_TPM

This repository host the necessary archives to realize a continuous remote attestation in Raspberry Pi 4 with an Optiga TPM. This work is based on the project https://github.com/Infineon/remote-attestation-optiga-tpm , but with some modifications to move from an occasional remote attestation to a continuous remote attestation.

##Introduction

The TPM remote attestation consists of an updated list of executed programs (measurement list) including the name and measurement of the program itself. Then, the list is sent to a [remote server](https://github.com/ernesto418/Remote_attestation_server). The TPM is essential to guarantee the integrity of the measurement list.

Registration process the system will create a Sealed key. It is a key that can be only used if the state of our IoT node is correct. If not, the IoT node has to ask the server for a new authorization to use the key, authorization that will only be sent after a check of the measurement list by the server, and will only be valid while the status of our Raspberry pi does not change.

## Kernel building.

Install the RaspberryPi OS on the Raspberry Pi (32 bit or 64 bit). Connet the SDA card and run [kernel_64bit_installation.sh](https://github.com/ernesto418/Remote_attestation_TPM/blob/main/Kernel_building/kernel_64bit_installation.sh) or [kernel_installation.sh](https://github.com/ernesto418/Remote_attestation_TPM/blob/main/Kernel_building/kernel_installation.sh) giving the location of the SDA card:

```
kernel_64bit_installation.sh sda1 sda2
```

## Provisioning Raspberry Pi.

First we have to configurate some internal files of the Raspberry Pi and install the needed dependences:

```
git clone https://github.com/ernesto418/Remote_attestation_TPM
cd Remote_attestation_TPM/Provisioning_Raspberry_Pi_4 && sudo sh tools_installation.sh

```

This script will finish in a reboot.

When the Raspberry Pi start again:

```
cd Remote_attestation_TPM/Provisioning_Raspberry_Pi_4 && sudo sh key_providing.sh
```

## Server registration

The Raspberry Pi is ready to start a registration in the server (please, start the [Server](https://github.com/ernesto418/Remote_attestation_server) before continue this guide).
Move to ~/tools/remote_attestation_tool and edit the file config.cfg to set the correct IP address of Server. 

Then go to ~/tools/remote_attestation_tool/bin/measuring_attestations_v2.sh and modify the section  "My application" with the programs you want to allow to be used.

### Create references measurements:

1. To create measurements to be used as reference, the first step is to clean the measurement list, for that, reboot the Raspberry Pi.

2. When the Raspberrry pi start, execute all the programs you would like your IoT node use in the real application (Real application program).

3. Execute a the attestation (it will return several errors, but it has to be executed to include some needed programs in the reference measurement list):

```
./first_attestation.sh
```

### Send references measurements:

Send the Reference list to the server and create the sealed key:

```
./registering_measurements.sh
```

### Daily life:

Execute all the real application programs and then:

```
./first_attestation.sh
```
Now you should have passed the remote attestation, and you should have recieved an autorization for using the Sealed key while keeping unmodified the measurement list
You can test the sealed key with:

```
./test_SeK.sh
```

In the moment a new program is used or a program is modified and then used again, the sealed key will not be avaiable again. A new remote attestation should be passedwith:

```
./routine_attestation.sh
```

If the authorization form the server is not coming, tr to restart the ras
