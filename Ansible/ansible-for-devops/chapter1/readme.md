ansible -i inventory example -m ping -u ec2-user --private-key ~/.ssh/$SANDBOX_PRIVATE_KEY.pem
