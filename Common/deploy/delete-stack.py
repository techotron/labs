import boto3
import botocore
import sys
import time
import datetime

# Tag applied to CloudFormation stacks in AWS to indicate that they should not be deleted.
preventStackDeletionTag = 'DONOTDELETE'

# The default number of minutes for this script to wait for AWS to finish deleting a stack. This is used if the caller does not provide this parameter.
defaultDeletionTimeoutDurationMinutes = 15

# Status used when we cannot retreive the current stack status from AWS.
stackUnknownStatus = 'UNKNOWN'

def getStackStatus(client, stackName):  
    try:
        response = client.describe_stacks(StackName='%s' % (stackName))

        stacks = response['Stacks']

        if(len(stacks) == 1):
            stack = stacks[0]
            return stack['StackStatus']
        else:
            print('Multiple stacks found with name \'%s\'. Unsure which to check status of. Status check aborted.' % (stackName))
            return stackUnknownStatus

    except botocore.exceptions.ClientError:
        print('Stack with name \'%s\' does not exist. Could not check status.' % (stackName))
        return stackUnknownStatus

def checkIfSingleStackExists(client, stackName):
    try:
        response = client.describe_stacks(StackName='%s' % (stackName))
            
        stacks = response['Stacks']

        if(len(stacks) > 1):
            print('Multiple stacks found with name \'%s\'...' % (stackName))

            for stack in stacks:
                print('  Stack Name: ', stack['StackName'])
                print('  Stack Status: ', stack['StackStatus'])
                print()

            return False

    except botocore.exceptions.ClientError:        
        return False
    
    return True

def checkIfCanDelete(client, stackName):
    try:
        response = client.describe_stacks(StackName='%s' % (stackName))
        
        stacks = response['Stacks']

        if(len(stacks) == 0):
            print('Stack with name \'%s\' does not exist. Deletion check aborted.' % (stackName))
            return False

        if(len(stacks) > 1):
            print('Multiple stacks found with name \'%s\'. Unsure which to check. Deletion check aborted.' % (stackName))
            return False

        stack = stacks[0]
        status = getStackStatus(client, stackName)

        if (status.upper() != 'CREATE_COMPLETE'):
            print('Stack does not have a stable current status. Deletion via script is not advised.')
            print('Current stack status: %s' % (status))
            return False

        tags = stack['Tags']
        for tag in tags:
            value = tag.get(preventStackDeletionTag, 'TAGNOTFOUND')
            if (value.upper() == 'TRUE'):
                return False

    except botocore.exceptions.ClientError:
        print('Stack with name \'%s\' does not exist' % (stackName)) 
        return False   

    return True

def deleteStack(client, stackName, deletionTimeoutDurationMinutes):
    try:
        print('Requesting deletion of stack with name \'%s\'...' % (stackName))
        client.delete_stack(StackName='%s' % (stackName))

        status = getStackStatus(client, stackName)
        print('Current status of stack with name \'%s\': %s' % (stackName, status))
        
        if (status.upper() == 'DELETE_IN_PROGRESS'):
            print('Deletion of stack with name \'%s\' in progress. Please wait...' % (stackName))
            startTime = datetime.datetime.now()
            stackDeleteCompleted = False
            timeout = False            
            while(not stackDeleteCompleted and not timeout):
                time.sleep(5)
                stackExists = checkIfSingleStackExists(client, stackName)
                if (not stackExists):
                    print('Stack with name \'%s\' is now deleted.' % (stackName))
                    stackDeleteCompleted = True
                    break
                # TODO: Check the status here too. If it has reverted to 'CREATE_COMPLETE', we should give up trying to delete it and report an error.
                currentTime = datetime.datetime.now()
                elapsedTime = currentTime - startTime
                elapsedMinutesWithRemainder = divmod(elapsedTime.total_seconds(), 60)
                elapsedMinutes = elapsedMinutesWithRemainder[0]
                if (elapsedMinutes > deletionTimeoutDurationMinutes):
                    timeout = True
                    break
            if (timeout):
                print('Deletion is taking a long time.')
                print('See CloudFormation console in AWS for details.')
        elif (status.upper() != stackUnknownStatus):
            print('Deletion of stack with name \'%s\' was not started for some reason.' % (stackName))
            print('Current status of stack with name \'%s\': %s' % (stackName, status))
            print('See CloudFormation console in AWS for details.')
        else:
            print('Stack was deleted really quickly!')

    except botocore.exceptions.ClientError:
        print('ERROR: Could not delete stack with name \'%s\'.' % (stackName))

def printHelp():
    print('=============================================================================================')
    print(' Delete AWS Stack Script')
    print(' ------------------------')
    print(' Description:')
    print(' A script to delete specific stack instances from AWS.')
    print(' ------------------------')
    print(' Usage:')
    print(' delete-stack <AWS Stack Name> <AWS Region Name> <AWS Access Key ID> <AWS Secret Access Key> [Deletion Timeout Minutes]')
    print(' ------------------------')
    print(' Arguments:')
    print(' 1. AWS stack Name - The name of the stack in AWS that you want to delete.')
    print(' 2. AWS Region Name - The AWS region in which the stack can be found.')
    print(' 3. AWS Access Key ID - The Access Key ID of the user account the deletion should be performed under.')
    print(' 4. AWS Secret Access Key - The secret key of the user account the deletion should be performed under.')
    print(' 5. Deletion Timeout Minutes - [OPTIONAL] - The number of minutes the script should wait for AWS to complete its deletion. Default: %s minutes.' % (defaultDeletionTimeoutDurationMinutes))
    print('=============================================================================================')

def main():
    if len(sys.argv) < 5:
        print('Missing arguments!')
        printHelp()
        return

    inputStackName = sys.argv[1]
    inputRegionName = sys.argv[2]
    inputAccessKeyId = sys.argv[3]
    inputSecretAccessKey = sys.argv[4]

    inputDeletionTimeoutDurationMinutes = defaultDeletionTimeoutDurationMinutes

    if len(sys.argv) >= 6:
        try:
            inputDeletionTimeoutDurationMinutes = int(sys.argv[5])
        except ValueError:
            print("Timeout value provided is not a valid value.")
            print("Using default timeout value instead: %s minutes" % (defaultDeletionTimeoutDurationMinutes))

    client = boto3.client(
        'cloudformation',
        aws_access_key_id='%s' % (inputAccessKeyId),
        aws_secret_access_key='%s' % (inputSecretAccessKey),
        region_name='%s' % (inputRegionName)
    )

    stackExists = checkIfSingleStackExists(client, inputStackName)

    if stackExists:
        print('Stack with name \'%s\' exists.' % (inputStackName))
        canDelete = checkIfCanDelete(client, inputStackName)

        if (canDelete):
            print('Stack with name \'%s\' can be deleted.' % (inputStackName))
            deleteStack(client, inputStackName, inputDeletionTimeoutDurationMinutes)
            
            stackStillExists = checkIfSingleStackExists(client, inputStackName)

            if not stackStillExists:
                print('Stack with name \'%s\' deleted successfully.' % (inputStackName))
            else:
                print('Stack deletion not successful. Stack with name \'%s\' still exists.' % (inputStackName))
        else:
            print('Stack with name \'%s\' cannot be deleted.' % (inputStackName))
    else:
        print('Stack with name \'%s\' does not exist.' % (inputStackName))

main()