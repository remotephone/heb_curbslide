# heb_curbslide

This will check your local HEB for curbside pickup times and send an SNS notification when they are available.

# Disclaimer

HEB has been good to us. Don't you dare abuse their API or they'll put it behind authentication and every one of us will lose out on this. 

# Requirements

You will need
- An AWS Account
- IAM, Lambda, SNS, SimpleDB permissions
- Terraform 0.12 or greater
- A preconfigured SNS topic

Find you local HEB by going to https://www.heb.com/store-locations, Clicking Store Details, and finding the 3 digit number associated with the store. 

Replace the terraform vars with your local store number and SNS topic ARN. 

terraform plan
terraform apply
yes

badabing badaboom you're done. You'll get SNS notifications fanned out wherever you send them. 

# Thanks to

SimpleDB is an incredible service AWS does not seem to want to own up to supporting. There's an sdb.py script in this repo where I figured out how to interact with it and used [this](https://gliptak.github.io/post/simpledb-example/) as a reference.

This was made so much easier by https://curl.trillworks.com/. Go to the request you want in Chrome, Copy as CURL request, and paste in here. I removed cookies and other identifying information and badabing badaboom. 


