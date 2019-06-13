### JMespath Query
A standard AWS CLI parameter to query resources.

##### Cloudformation Exports

Stack to retrieve the "KmsKeyArn" output value. It will output as text, meaning you don't need to use `tr -d '"'` to clear up the double quotes from a JSON output. 
 
```bash
aws cloudformation describe-stacks \
                --stack-name eddy-key-stack \
                --query \'Stacks[].Outputs[?contains(OutputKey, `KmsKeyArn`) == `true`].OutputValue[]\' --output text
```