
## Context 

      
## Goals   
The goal of the project is   
- Deploys the project in a Kubernetes environment.     
- Provisions architecture on AWS cloud, using Terraform.   
- Provides simple bash scripts to deploy the stack. 
- Provides the bash script to take inputs (Key/Value), encrypts the Value and updates the file and deploys latest.  
      
## Non-goals   
- Doesn't change the scope of the application.         
- Doesn't do any Integration tests for application given   
      
## Background   
    
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
  
Implements simple HTTP server that returns all environment variables with value as prefix "HASURA_" on key, in JSON format when accessed on port 8080.    
    
#### Endpoints   
- `/`: Serves the main application content i.e displays environment varibles in json format.    

Endpoint is accessible on port `8000`    
 
### Artefacts  
  
Docker image is build locally and upload in ECR.   
    
### Architecture diagram ![Diagram](https://github.com/ashwiniag/hasura-assignment/blob/main/hasura-architecture.png?raw=true)    
    
    
### Provisioning: How to use the scripts to implement. 

*Task1*  
- `provisioning_script.sh`: A simple bash scripts that helps automate the deployment of a Docker image to Amazon ECR and the provisioning of necessary AWS resources such as VPC, subnets, and a managed EKS cluster.
To use the script, export your AWS profile and run it with either "apply" or "delete" as an argument.
Before executing the script please `export AWS_PROFILE=<>`  

Note: <about helm>

*Task2*      
- `encrypts_and_updates_secrets.sh`: Bash script that allows users to securely manage and deploy their secrets. It accepts a key/value pair and a service name as input, and performs the following actions:
    - Encrypts the value using the provided key.
    - Checks if the key already exists. If it does, the script updates the existing value. If not, it adds the key/value pair to the secrets store.
    - Deploys the latest version of the secrets store.
    
Note: < about yaml encrypting or just values.>
    
### Testing:  
 
get lb name (local testing)  
```

kubectl get svc -n default -o json | jq '.items[].status.loadBalancer.ingress[0].hostname' | head -n 1

 ``` 

Endpoints:  

- Application serves: http:< lb >/  

Note:
  
###  Room for improvements There is scope of improvements as this the first draft. 


  

...to be continued in thinking brain encountered 5xx