# Useful Tools
## AWS
Tools for using AWS
#### awless - https://github.com/wallix/awless

Useful for displaying AWS resources on the cli. You can cache resources and query them offlne. Simplified AWS commands. It uses ~/.aws/credentials

**Installation (MacOS)**
```buildoutcfg
brew tap wallix/awless; brew install awless
```

**View resources**
```buildoutcfg
awless ls instances
awless ls instances --filter name=eddy-awless-test
awless ls -h

awless ls keypairs
awless ls subnets
awless ls securitygroups
```

**List resources from local cache**
```buildoutcfg
awless ls instances --local
```

**Create instance**
```buildoutcfg
awless create instance distro=amazonlinux:amzn2 type=t2.nano keypair=eddy-scratch@intapp.com name=eddy-awless-test subnet=subnet-02724e4b securitygroup=sg-10e7026c
```

**Connect to the instance**
```buildoutcfg
awless ssh eddy-awless-test -i /Users/eddys/Box\ Sync/DevOps\ \(Private\)/AWS/eddy-scratch\@intapp.com.pem
```

**Delete instances**
```buildoutcfg
awless delete instance ids=@eddy-awless-test
```