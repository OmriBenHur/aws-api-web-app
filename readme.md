prerequisites:

have git installed on your local machine.

have terraform installed on your local machine.

sign up to tmdb.com(https://www.themoviedb.org/) and create an api key.

next, create an aws secrets manager secret, under secret name enter "web-app/api-key", under secret value enter the value of the tmdb api key, notice the region your'e creating the secret in. (note that the secret key name corresponds to the import in the userdata.sh file, if you change it you will also have to change it in the userdata.sh file) 


next, in the terraform var file, input your aws access key and secret key and your prefered region.
(note that the default is us-west-2, and it corresponds to the us-west-2 declaration in the userdata file, if you change it you will also have to change it in the userdata file.)


and the arn for the secret you previuosly created under "secret_arn".

thats it! 
cd into your pulled terraform directory, 
terraform init,
terraform apply,
and the application is availale.
you can interact with it through the alb dns record (a record).

project architecture:


![AWS web app architecture  - AWS (2019) horizontal framework (1)](https://user-images.githubusercontent.com/110596448/198708202-e63ae2cd-8fdf-41f4-aff8-1c377c436d94.png)
