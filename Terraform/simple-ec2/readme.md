# simple-ec2

Return the Public IP of the instance:

```bash
aws ec2 describe-instances --query 'Reservations[].Instances[?Tags[?Key==`Name`] | [?Value==`simple-ec2`]].NetworkInterfaces[0].Association.PublicIp' --region eu-west-1 --output text
```