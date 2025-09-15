# capstone-app
End to End  CI/CD and Infrastructure for a microservice on Kubernetes
## Overview
This project provisions an **end-to-end CI/CD pipeline** using Jenkins, Terraform, Ansible, Docker, and Kubernetes (EKS).  
The pipeline automates:  
- Infrastructure provisioning (Terraform)  
- Configuration management (Ansible)  
- Microservice deployment (Kubernetes manifests)  
- Monitoring stack setup (Helm, Prometheus, Grafana)

## Prerequisites
Before starting, ensure you have:  
- **Terraform** installed locally  
- **AWS account** (EKS is a paid service, not covered in the free tier)  
- **SSH key** (e.g., `my-key.pem`)  
- **Docker Hub account** (for storing/pulling images)

## Steps
To use this repository, clone the repo to your local machine using the git clone command and then follow the steps below:
### 1. Bootstrap Jenkins Host (via Terraform)
- cd to the Terraform folder in your local directory
- run terraform init and terraform apply commands

This provisions:  
- Jenkins EC2 host  
- EKS cluster with node groups  
- Networking and IAM roles  

The Jenkins host will already include Jenkins, Docker, AWS CLI, and kubectl (installed through the user_data script in Terraform).

### 2. Access Jenkins Host
- SSH into the Jenkins host using your private key and public IP.  
- Retrieve the initial Jenkins admin password from: `/var/lib/jenkins/secrets/initialAdminPassword`.  

---

### 3. Set Up Jenkins
Log into Jenkins by visiting:  
**http://<jenkins-public-ip>:8080**  

Use the retrieved password.  

**Install the required plugins:**  
- Pipeline  
- GitHub  
- Docker Pipeline  
- Kubernetes CLI  
- Ansible  

**Configure credentials for:**  
- Docker Hub → environment variables `DOCKER_USER` and `DOCKER_PASS` (recommended to use a token instead of password, available in DockerHub settings)  
- GitHub → required only if the repository is private  
- AWS IAM → optional, since the Jenkins host already has an IAM role  

---

### 4. Run the Pipeline
- Create a new Jenkins Pipeline job and point it to your GitHub repository containing the Jenkinsfile.  
- Configure it to trigger automatically on push events.  

On the first push, the pipeline executes the following stages:  
1. Terraform → refresh/update infrastructure (infra already up)  
2. Ansible → configure Helm and monitoring tools on the Jenkins host  
3. Kubernetes manifests → deploy the microservice app  
4. Helm install → deploy the monitoring stack  

The application and monitoring stack are deployed on EKS nodes, not on the Jenkins server.

---

##  Accessing Services

### 1. Configure kubectl Context
On your Jenkins host (or your local machine if you have kubectl installed), set the local kubectl context to the **devops-cluster**:

`aws eks update-kubeconfig --region us-east-1 --name devops-cluster`

---

### 2. Access the Application Service
Retrieve the service details for your application namespace (**microservice** in this case):  

`kubectl get svc -n microservice`  

From the output, copy the **ELB hostname** and use it to access the application service.

---

### 3. Access Prometheus and Grafana
Retrieve the monitoring service details from the **monitoring** namespace:  

`kubectl get svc -n monitoring`  

From the output, use the **ELB hostname** and the appropriate port numbers to access:  
- **Grafana**  
- **Prometheus**  

For example:  
`http://492.us-east-1.elb.amazonaws.com:9090`

---

---

## ⚠️ Notes
- EC2 instances are provisioned as **t3.small** by default. For smoother execution, use **t3.medium** or larger instance types.  
- **EKS is a paid AWS service** and is **not included in the AWS Free Tier**.
