### JMespath Query
A standard AWS CLI parameter to query resources.

##### Cloudformation Exports

Command to retrieve the "KmsKeyArn" output value. It will output as text, meaning you don't need to use `tr -d '"'` to clear up the double quotes from a JSON output. 
 
```bash
aws cloudformation describe-stacks \
                --stack-name eddy-key-stack \
                --query 'Stacks[].Outputs[?contains(OutputKey, `KmsKeyArn`) == `true`].OutputValue[]' --output text
```

Command to get the ReturnCertExpiry using the equals operator:

```bash
 aws cloudformation describe-stacks \
                --stack-name sam-python \
                --query 'Stacks[].Outputs[?OutputKey == `ReturnCertExpiry`].OutputValue[]'
```

Command to return a service name ARN using the contains operator:

```bash
aws ecs list-services \
    --cluster my-ecs-cluster-name \
    --query 'serviceArns[?contains(@, `my-service-name`) == `true`]' \
    --output text
```

Command to return a specific element in the json response (example using subscription filter):

```bash
aws logs describe-subscription-filters \
    --log-group-name /my-log-group/log-group-name \
    --query 'subscriptionFilters[].filterName' \
    --output text
```

Return change sets where `ChangeSetName` contains the string `PR-123`:

```bash
aws cloudformation list-change-sets \
    --stack-name my-stack-name \
    --query 'Summaries[?contains(ChangeSetName, `PR-123`) == `true`].ChangeSetName'
```

Return resource based on tag query:

```bash
aws ec2 describe-vpcs --query 'Vpcs[?Tags[?Key==`Name`]|[?Value==`EDDYS_VPC`]].VpcId' --output text
```
