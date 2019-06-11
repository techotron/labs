# jq

### Filters

Filter array and return element based on key. This example command will return the `Roles` element where the `RoleName` == my-role-name
```bash
aws iam list-roles | jq '.Roles[] | select(.RoleName == "my-role-name")'
```