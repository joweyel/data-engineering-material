# How to create an IAM user in AWS

1. **Sign in to the AWS Management Console:** Open your web browser and navigate to the AWS Management Console (https://console.aws.amazon.com/). Sign in using your AWS account credentials.

2. **Navigate to the IAM Dashboard:** Once you’re signed in, click on "Services" at the top left of the navigation bar. In the drop-down menu, under "Security, Identity, & Compliance", click on "IAM".

3. **Create a new IAM user:** On the IAM dashboard, click on "Users" in the left navigation pane. Then, click on the "Add user" button.

4. **Set user details:**
    - In the "Set user details" section, enter the username for your new IAM user. In your case, it would be "mage-zoomcamp".
    - Select the "Programmatic access" checkbox. This type of access enables an access key ID and secret access key for the AWS API, CLI, SDK, and other development tools.

5. **Set permissions:** Click on "Next: Permissions". Here, you can attach existing policies directly, add user to a group, or copy permissions from an existing user. For your use case, you might want to create a custom policy that closely mirrors the permissions your service account had on GCP. To do this:

    - Click on "Attach existing policies directly", then "Create policy".
    - In the JSON tab, you can write a custom policy. For this the pre-scribed policy [here](https://docs.mage.ai/production/deploying-to-cloud/aws/terraform-apply-policy) is used. Once you’re done, click on "Review policy".
    - Name your policy, give it a description, and click "Create policy".
    - Now, you should be able to attach this policy to your user. Use the refresh button to update the list of policies if needed.

6. **Review:** Click on "Next: Tags" (optional step) and "Next: Review". Review the user and permissions, then click on "Create user".

7. **Success:** After clicking "Create user", you should see a success message. Important: This is the only time you will see the secret access key, so download the .csv file or copy the access key ID and secret access key now.

8. **Test the credentials:** You can test the new credentials using the AWS CLI. If you haven’t installed it yet, you can find instructions in the AWS documentation.

