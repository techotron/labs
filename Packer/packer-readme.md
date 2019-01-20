# Image Building
## Packer
Tool for building images on various platforms
#### packer - https://www.packer.io


**Installation (MacOS)**
```buildoutcfg
brew install packer
```

**Build Windows EC2 AMI**

Using the labs repo:
```buildoutcfg
packer build ./Packer/Windows/windows-vanilla-std/build_manifest.json
```
Running this requires the AWS credentials to be saved as environment variables on the machine packer is run from. It will start the instance, run the scripts (specified in the build_manifest.json) create an AMI and finally terminate the instance. 
