FROM jenkins:2.0
MAINTAINER Dmitry Taviev <dmitry.taviev@applyit.lv>

USER root

#install docker for building & pushing images
RUN curl -sSL https://get.docker.com/ | sed 's/docker-engine/docker-engine=1.6.1-0~jessie/' | sh

#install various dependencies
RUN apt-get update && apt-get install -y \
		wget \
		php5-cli \
		jq \
		python2.7 && \
	apt-get autoclean && \
	curl -O https://bootstrap.pypa.io/get-pip.py && \
	python2.7 get-pip.py && \
	pip install awscli

#install composer for php projects
ENV COMPOSER_HOME /var/jenkins_home/.composer
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN mkdir /usr/share/jenkins/ref/.composer && \
	echo "{}" > /usr/share/jenkins/ref/.composer/composer.json && \
	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#install kubernetes client binary
RUN mkdir /root/.kube && \
	wget https://storage.googleapis.com/kubernetes-release/release/v1.2.2/bin/linux/amd64/kubectl -O /root/.kube/kubectl && \
	chmod +x /root/.kube/kubectl
ENV PATH /root/.kube:$PATH

#install jenkins plugins
COPY plugins.txt /usr/share/jenkins/ref/
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt

#import configs & credentials
COPY config.xml /usr/share/jenkins/ref/
COPY identity.key.enc /usr/share/jenkins/ref/
COPY secret.key /usr/share/jenkins/ref/
COPY secrets /usr/share/jenkins/ref/secrets/
COPY credentials.xml /usr/share/jenkins/ref/
COPY jobs /usr/share/jenkins/ref/jobs/
COPY hudson.tasks.Shell.xml /usr/share/jenkins/ref/
COPY scriptApproval.xml /usr/share/jenkins/ref/
COPY jenkins.plugins.slack.SlackNotifier.xml /usr/share/jenkins/ref/

#disable annoying jenkins notifications
RUN mkdir -p /usr/share/jenkins/ref/jenkins.security.RekeySecretAdminMonitor/ && \
	touch /usr/share/jenkins/ref/jenkins.security.RekeySecretAdminMonitor/needed && \
	echo "2.0" > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state

#volume for ssh credentials (bitbucket)
VOLUME /root/.ssh
#volume for connecting with host docker daemon
VOLUME /var/run/docker.sock
#volume for docker registry credentials (aws ec2)
VOLUME /root/.dockercfg
#volume for kubernetes config
VOLUME /root/.kube/config
#volume for aws credentials
VOLUME /root/.aws/credentials

#by Atis for angular frontend
RUN curl --silent --location https://rpm.nodesource.com/setup_7.x | bash -
RUN apt-get install -y nodejs && apt-get autoclean && npm install -g bower