![0](https://user-images.githubusercontent.com/66811679/85506834-60220280-b5ae-11ea-8265-0524cb67a7e0.jpg)
## Devops-task-4:

1. Create a container image that has Linux and other basic configuration required to run Slave for Jenkins. ( example here we require kubectl to be configured )

2. When we launch the job it should automatically start a job on slave based on the label provided for a dynamic approach.

3. Create a job chain of job1 & job2 using the build pipeline plugin in Jenkins

4. Job1: Pull the Github repo automatically when some developers push the repo to Github and perform the following operations as:

1. Create the new image dynamically for the application and copy the application code into that corresponding docker image

2. Push that image to the docker hub (Public repository)

( Github code contain the application code and Dockerfile to create a new image )

5. Job2 ( Should be run on the dynamic slave of Jenkins configured with Kubernetes kubectl command): Launch the application on the top of Kubernetes cluster performing following operations:

1. If launching the first time then create a deployment of the pod using the image created in the previous job. Else if deployment already exists then do a rollout of the existing pod making zero downtime for the user.

2. If Application created the first time, then Expose the application. Else don’t expose it.

Let's Start:

For performing this task we require 3 VM

1 - Where Jenkins is running

2 - Where the docker engine is running

3 - Where k8s(Kubernetes) running

Abstract Idea:

We start Jenkins service from VM1 and then here we configure a cloud service that is linked with VM2 where our docker engine is running. We create an image for dynamic Kubernetes in VM2 which will help us to run our Kubernetes cluster on VM3.

Before proceeding to do this step in your VM2:

Open **/usr/lib/systemd/system/docker.service** file and add -H tcp://0.0.0.0:3456
(This command will help you to access the docker service of this VM from another machine[this process is called socket binding]).

![1](https://user-images.githubusercontent.com/66811679/85507787-27832880-b5b0-11ea-930b-21909f25cf8e.jpg)

and then reload and restart your docker services


```javascript
systemctl daemon-reload
systemctl restart docker
```

Now go to your VM1 and start your Jenkins service and install the "docker" plugin

```javascript
systemctl start jenkins
```

![3](https://user-images.githubusercontent.com/66811679/85508617-aaf14980-b5b1-11ea-90b6-7286d0da955d.png)

and then configure your cloud as I showed below:

```javascript
Jenkins->Manage Jenkins -> Manage nodes and clouds-> configure cloud-> add a new cloud-> docker
```

![4](https://user-images.githubusercontent.com/66811679/85509191-c446c580-b5b2-11ea-93af-f80d0205495f.png)

In the Yellow section type your VM2 IP where your docker engine is running...

And rest the column fill as I filled.

POST-COMMIT file for triggering:

```javascript
#!/bin/bash

echo "Auto Push Enabled"

git push


curl --user "admin:redhat" http://192.168.43.140:8080//job/Job1_image_build/build?token=devopss
```

GitHub Repo:

JOB1:

![4](https://user-images.githubusercontent.com/66811679/85510059-19370b80-b5b4-11ea-880a-d37d4bfee07e.PNG)
![6](https://user-images.githubusercontent.com/66811679/85510571-c6aa1f00-b5b4-11ea-868b-bcd926837f84.png)

Note:

1.In the Cloud column type, the name of the cloud is configured earlier.
2.In Registry Credential column give your docker hub credential.
3.Your image name always starts with your username.
JOB2(Prerequisites):

Before going to JOB2 we again need to perform some steps...

Create a cloud... Create a Kubernetes cluster in VM2 which will help you to contact minikube.

Creating a Kubernetes Image:

Dockerfile:
```javascript
FROM centos
RUN yum install java-11-openjdk.x86_64 -y
RUN yum install openssh-server -y
RUN yum install sudo -y
RUN echo "root:redhat" | chpasswd
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl

RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl
RUN mkdir /root/.kube
COPY client.key /root/.kube
COPY client.crt /root/.kube
COPY ca.crt /root/.kube
COPY config /root/.kube
RUN mkdir /root/devops
COPY deploy.yml /root/devops
RUN ssh-keygen -A
CMD ["/usr/sbin/sshd", "-D"]
```

For Running this file create a new directory<any_name>

Inside this directory add your client.key, client.crt, ca.crt file

I will get this file from **"C:\Users\<account_name>\.minikube" ** and **"C:\Users\<Account_name>\.minikube\profiles\minikube"**

and then create a config file in this directory( Code attached below):

```javascript
apiVersion: v1
kind: Config

clusters:
- cluster:
    server: https://192.168.43.91:8443     #Add Your Minikube IP here
    certificate-authority: ca.crt
  name: spcluster

contexts:
- context:
    cluster: chatpc
    user: vikas

users:
- name: vikas
  user:
    client-key: client.key
    client-certificate: client.crt
```
