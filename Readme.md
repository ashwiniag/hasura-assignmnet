
## Context 

This document describes the high-level design of a project aimed at deploying a Go application on a Kubernetes environment using AWS cloud and Terraform. The project consists of two main scripts - a provisioning script and a secrets management script. The provisioning script automates the deployment of the application's Docker image and the provisioning of necessary AWS resources. The secrets management bash script enables users to securely manage and deploy their secrets.
The application serves the environment variable passed to it with prefix `HASURA_`. The project also includes a Terraform directory structure and a diagram of the architecture. There is room for improvement in the project.

## Goals   
The goal of the project is to achieve the requirement provided in Hasura_SRE_assignment.pdf and a production ready solution
- Deploys the project in a Kubernetes environment.     
- Provisions architecture on AWS cloud, using Terraform.   
- Provides simple bash script to deploy the stack. 
- Provides bash script to take inputs (Key/Value), encrypts the Value and updates the file and deploys latest.  
      
## Non-goals   
- Doesn't change the scope of the application.         
- Doesn't do any Integration tests. 
      
    
## Glossary  
  
 - Directory structure:  
 
 Based on its deployment frequencies and atomicity.
 
```
.
├── env-echo // Go application
├── provision
│   ├── infra // tf. files for basic aws infra like vpc, subnets etc 
│   ├── resources // tf files for nodes, ssm for being curious whats happening, did for self.
│   └── services_k8s // .tf files for application and nginx controller 
├── templates // .tf files which will be used via Makefile.  
└── tfstate_setup // Configures s3+dynamodeb backend to store terraform statefiles and takes care of state locks

```

  
  ## Details       
 ### API   
#### Scope of the application written in Go 
  
Implements simple HTTP server that returns all environment variables with value as prefix "HASURA_" to key, in JSON format when accessed on port 8080.    
    
#### Endpoints   
- `/`: Serves the main application content i.e displays environment varibles in json format.    

Endpoint is accessible on port `8000`    
 
### Artefacts  
  
Docker image is build locally and uploads in AWS ECR.   
    
### Architecture diagram ![Diagram](https://github.com/ashwiniag/hasura-assignment/blob/main/hasura-architecture.png?raw=true)    
    
    
### Provisioning: How to use the scripts to implement. 

*Task1*  
- `provisioning_script.sh`: A simple bash scripts that helps automate the deployment of a Docker image to Amazon ECR and the provisioning of necessary AWS resources such as VPC, subnets, and a managed EKS cluster.
To use the script, export your AWS profile `export AWS_PROFILE=<>` and run it with either "apply" or "delete" as an argument. 

*Task2*      
- `encrypts_and_updates_secrets.sh`: Bash script that allows users to securely manage and deploy their secrets. It accepts a key/value pair and a service name as input, and performs the following actions:
    - Encrypts the value using the provided key.
    - Checks if the key already exists. If it does, the script updates the existing value. If not, it adds the key/value pair to the secrets store. Either way it encrypts Value. 
    - Deploys the latest version of the secrets store.
    - The script check the yaml file in directory provision/services_k8s/encrypted_env-echo_secrets.yaml
    
    
### Testing:  
 
get lb name (local testing)  
```

kubectl get svc -n default -o json | jq '.items[].status.loadBalancer.ingress[0].hostname' | head -n 1

 ``` 

Endpoints:  

- Application serves at: http:< lb >/  

  
###  Room for improvements There is scope of improvements. 

- The bash provision script should be modified for more control and interactive, like displaying plans and then allowing the user to decide whether to apply changes. 
- Incorporating creations of ECR repo to have the statefiles accountability, even if it is just one time creation. 
- Currently for the sake of the scope of task-2 and demonstrated example, where we have a separate kubernetes secrets yaml file. This yaml file' values isn't passed to the application deployed, this could be incorporated. 
For now, it decrypts the file, checks the file based on Key and updates/adds, encrypts the file and deploys the yaml file. 
 

TODOs:
Task-1:
To create a Helm chart for deploying application.

Task-2:
To git pull for latest file and git commit to new branch.
Needs clarification as requirement provided and example given are bit ambigious. 
- The requirement demonstrated tells to take the key,value and update the file based on the key, i.e if exsist update the key and if new add it.
  So, the script takes care of the logic based on Key provided, so why do we need `--existing false` as argument? 
