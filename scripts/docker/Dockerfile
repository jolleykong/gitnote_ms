FROM centos:7.8.2003

ARG RELEASE_VERSION="2.6.1"

# ------------------------------------------------------------------------------
# - Import the RPM GPG keys for repositories
# - Base install of required packages
# - Install supervisord (used to run more than a single process)
# - Install supervisor-stdout to allow output of services started by
#  supervisord to be easily inspected with "docker logs".
# ------------------------------------------------------------------------------
RUN  yum -y install \
	#	epel-release \
	#	https://centos7.iuscommunity.org/ius-release.rpm \
	#&& yum -y install \
		openssh-clients \
		openssh-server \
		openssl \
		sudo \
		glibc-common \
		tree \
		libaio \
		numactl \
		man \
		iproute \
		net-tools \
		wget \
		which \
		zsh \
	&& yum clean all 
	#&& rm -rf /etc/ld.so.cache \
	#&& rm -rf /sbin/sln \
	#&& rm -rf /{root,tmp,var/cache/{ldconfig,yum}}/* \
	#&& > /etc/sysconfig/i18n

# ------------------------------------------------------------------------------
# Copy files into place
# ------------------------------------------------------------------------------
ADD  authorized_keys  /root/.ssh/
ADD  mysql_onekey_3.2.1.sh /root/
ADD  oh-my-zsh /root/.oh-my-zsh
ADD  zshrc /root/.zshrc

# ------------------------------------------------------------------------------
# Provisioning
# - UTC Timezone
# - Networking
# - Configure SSH defaults for non-root public key authentication
# - Enable the wheel sudoers group
# - Replace placeholders with values in systemd service unit template
# - Set permissions
# ------------------------------------------------------------------------------
RUN ln -sf \
		/usr/share/zoneinfo/Asia/Shanghai \
		/etc/localtime \
	&& echo 'export LANG=en_US.UTF-8' >>/etc/profile \
	&& echo "NETWORKING=yes" \
		> /etc/sysconfig/network \
	&& echo "root:123qwe"|chpasswd \
	&& chown -R root:root /root/.ssh \
	&& chmod 700 /root/.ssh \
	&& chmod 600 /root/.ssh/authorized_keys \
	&& mkdir /var/run/sshd \
        && ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key \
        && ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key \
	&& chsh -s /usr/bin/zsh root \
	#&& ssh-keygen -t rsa -f /root/.ssh/rsa \
	#&& ssh-keygen -t dsa -f /root/.ssh/dsa \ 
	&& /bin/sed -i 's/.*session.*required.*pam_loginuid.so.*/session optional pam_loginuid.so/g' /etc/pam.d/sshd \
	&& /bin/echo -e "LANG=\"en_US.UTF-8\"" > /etc/default/local \
	#&& chown -R root:root /root/.ssh \
	#&& chmod 700 /root/.ssh \
	#&& chmod 600 /root/.ssh/* \
	&& groupadd -g 2000 mysql \
        && useradd -g mysql -u 2000 -s /sbin/nologin -d /usr/local/mysql -MN mysql \
	&& mkdir /data \
	&& chown -R mysql:mysql /data 

EXPOSE 22

# ------------------------------------------------------------------------------
# Set default environment variables
# ------------------------------------------------------------------------------
ENV 	ENABLE_SSHD_BOOTSTRAP="true" \
	ENABLE_SSHD_WRAPPER="true" \
	ENABLE_SUPERVISOR_STDOUT="false" \
	SSH_AUTHORIZED_KEYS="" \
	SSH_CHROOT_DIRECTORY="%h" \
	SSH_INHERIT_ENVIRONMENT="false" \
	SSH_PASSWORD_AUTHENTICATION="false" \
	SSH_SUDO="ALL=(ALL) ALL" \
	SSH_TIMEZONE="Asia/Shanghai" \
	SSH_USER="kk" \
	SSH_USER="app-admin" \
	SSH_USER_FORCE_SFTP="false" \
	SSH_USER_HOME="/home/%u" \
	SSH_USER_ID="500:500" \
	SSH_USER_PASSWORD="kk" \
	SSH_USER_PASSWORD_HASHED="false" \
	SSH_USER_PRIVATE_KEY="" \
	SSH_USER_SHELL="/bin/bash" \
	SYSTEM_TIMEZONE="UTC" \
	LC_ALL="en_US.UTF-8" \
	LANGUAGE="en_US.UTF-8" \
	LANG="en_US.UTF-8"

# ------------------------------------------------------------------------------
# Set image metadata
# ------------------------------------------------------------------------------
LABEL \
	maintainer="James Deathe <james.deathe@gmail.com>" \
	install="docker run \
--rm \
--privileged \
--volume /:/media/root \
jdeathe/centos-ssh:${RELEASE_VERSION} \
/usr/sbin/scmi install \
--chroot=/media/root \
--name=\${NAME} \
--tag=${RELEASE_VERSION} \
--setopt='--volume {{NAME}}.config-ssh:/etc/ssh'" \
	uninstall="docker run \
--rm \
--privileged \
--volume /:/media/root \
jdeathe/centos-ssh:${RELEASE_VERSION} \
/usr/sbin/scmi uninstall \
--chroot=/media/root \
--name=\${NAME} \
--tag=${RELEASE_VERSION} \
--setopt='--volume {{NAME}}.config-ssh:/etc/ssh'" \
	org.deathe.name="centos-ssh" \
	org.deathe.version="${RELEASE_VERSION}" \
	org.deathe.release="jdeathe/centos-ssh:${RELEASE_VERSION}" \
	org.deathe.license="MIT" \
	org.deathe.vendor="jdeathe" \
	org.deathe.url="https://github.com/jdeathe/centos-ssh" \
	org.deathe.description="OpenSSH 7.4 / Supervisor 4.0 / EPEL/IUS/SCL Repositories - CentOS-7 7.6.1810 x86_64."

#HEALTHCHECK \
#	--interval=1s \
#	--timeout=1s \
#	--retries=5 \
#	CMD ["/usr/bin/healthcheck"]

CMD /usr/sbin/sshd -D
#CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]
