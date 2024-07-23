# Dynamic DNS with Docker and AWS Route 53

This project sets up a dynamic DNS service using Docker, AWS Route 53, and AWS CLI. The service periodically checks for any changes to your current IP address and if it detects one then it updates your DNS record with your current IP address using the AWS CLI. Realistically this can work with any provider who has API to update the records, I chose AWS because I am fairly familiar with it.

## Prerequisites
* You own a domain you can point the nameservers to.
* You have some sort of device (like Raspberry Pi or any random computer) in your desired network that can run this.

## Step 1 - Installing Docker
I'm using Raspberry Pi with Ubuntu server 24.04 so my examples here are according to that. You should use your distributions documentation.
```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo groupadd docker
sudo usermod -aG docker $USER
```
## Step 2 - Adding AWS Route 53 Hosted Zone
Log into [aws.amazon.com](https://aws.amazon.com) and Search `Route 53 -> Hosted Zones -> Create Hosted Zone`.

Set the following values:
![image](https://github.com/user-attachments/assets/0b79d2d6-20bc-4a57-b02e-1309a8917a4c)

After you created it take note of the nameservers and hosted zone id.
![image](https://github.com/user-attachments/assets/4bd125a0-3b05-4e2c-b932-a4400cdd7dfc)


## Step 3 - Adding AWS IAM Policy
Add IAM policy for CLI usage. For that

Search `IAM -> Policies -> Create Policy` name it something like `Route53DynamicDNSPolicy` and add (replace YOURHOSTEDZONEID with actual ID).
```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"route53:ChangeResourceRecordSets",
				"route53:ListHostedZones",
				"route53:ListResourceRecordSets"
			],
			"Resource": [
				"arn:aws:route53:::hostedzone/YOURHOSTEDZONEID"
			]
		}
	]
}
```
And attach it to user. For that go to
`IAM -> Users -> Create User` name it anything (like DDNS) and attach your policy to the created user.
Click on `User`, click `Security Credentials` and click `Create Access Key`.
Select `Command Line Interface (CLI)`, tick confirmation box and click `Create`.


Write down the `Access key` and `Secret Access key` for later use in step 6.

## Step 4 - Update your domain registrar nameservers
Go to your domain registrar and change the nameservers to the 4 that were listed in step 2.
This is different for everyone as everyone has their own registrar but it should look something like this:
![image](https://github.com/user-attachments/assets/551444fc-f281-4fc6-86fe-b3e045b1b2a5)

## Step 5 - Create Dummy DDNS record
Back in AWS Route 53 click:
`Route 53 -> Hosted Zones -> <your-hosted-zone> -> Create record`.
Name it `ddns.yourdomain.com` and set type to A. The value is not important at the moment as we are rewriting it automatically later on.
![image](https://github.com/user-attachments/assets/0ca417d4-f86b-47e8-8345-5ae4df4f36e8)

That should be mostly all from AWS side.

## Step 6 - Running the container
In your home server, do
```bash
cd /opt
git clone https://github.com/albertlaiuste/aws-ddns.git ddns
cd ddns/
```
Fill in the values for .env with values from step 2.
```bash
mv .env.example .env
nano .env # Ctrl+O to save, Ctrl+X to exit. Or use other editors, like vim.
```

And run the container
```bash
docker compose up -d
```

You can observe the service using
```
docker logs aws-ddns -f
```





