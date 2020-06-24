FROM centos:latest

RUN yum install httpd -y
RUN yum install php -y
COPY *.html /var/www/html
CMD /usr/sbin/httpd -DFOREGROUND && /bin/bash
COPY index.html /var/www/html/
EXPOSE 80 

