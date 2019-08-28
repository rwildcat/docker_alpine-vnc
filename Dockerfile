# alpine-vnc - a basic, graphical alpine workstation
# includes xfce, vnc, ssh
# last update: aug/26/2019

FROM alpine:3.10

# init ash file (for non-login shells)
ENV ENV '$HOME/.ashrc'

# default screen size
ENV XRES 1280x800x24

# tzdata settings
ENV TZ_AREA America
ENV TZ_CITY Mexico_City

# update and install system software
RUN apk update \
	&& apk upgrade \
	#
	&& apk add setup-box sudo supervisor openssh-server openssh vim nano \
	&& apk add xvfb x11vnc 

#  do some xfce4 packages require manual installation? -- ?? slim, xfce4
RUN apk add xfce4-xkb-plugin xscreensaver leafpad 

# set up timezone
RUN apk add tzdata \
	&& cp /usr/share/zoneinfo/$TZ_AREA/$TZ_CITY /etc/localtime \
	&& echo "$TZ_AREA/$TZ_CITY" >  /etc/timezone \
	&& apk del tzdata

# patch setup-box to not ask for new user's passwd
# and setup a desktop + xfce4 workstation
RUN sed -i  's/adduser -h/adduser -D -h/' /sbin/setup-box \
	&& echo Y | setup-box -v -d xfce -u alpine

# del extra packages
# RUN apk del \
# 	&& xf86-video-ast xf86-video-ati xf86-video-chips \
# 	&& xf86-video-i128 xf86-video-i740 xf86-video-nouveau xf86-video-openchrome \
# 	&& xf86-video-qxl xf86-video-r128 xf86-video-rendition xf86-video-s3 xf86-video-s3virge \
# 	&& xf86-video-savage xf86-video-siliconmotion xf86-video-sis xf86-video-sunleo xf86-video-tdfx \
# 	&& xf86-video-vmware xf86-video-xgixp


# change root passwd and add users and groups 
# (user alpine alredy added by setup-box)
RUN	echo "root:alpine" | /usr/sbin/chpasswd \
#   && adduser -D alpine -s /bin/bash \
    && echo "alpine:alpine" | /usr/sbin/chpasswd \
    && echo "alpine    ALL=(ALL) ALL" >> /etc/sudoers 	

# setup sshd
RUN mkdir /run/sshd \
	&& ssh-keygen -A

# add my sys config files
ADD etc /etc

# customizations

# ash personal config file for non-login shell mode (as default in xfce terminal)
# read by ash per ENV=~/.ashrc (see above)
RUN echo "alias ll='ls -l'" > /home/alpine/.ashrc \
	&& echo "alias lla='ls -al'" >> /home/alpine/.ashrc \
	# ash personal config file for login shell mode
	&& cp /home/alpine/.ashrc /home/alpine/.profile 

# personal xfce4 config
ADD config/xfce4/terminal/terminalrc /home/alpine/.config/xfce4/terminal/terminalrc
ADD config/xscreensaver /home/alpine/.xscreensaver
ADD config/wallpapers/* /usr/share/backgrounds/xfce/

# set custom wallpaper :-)
ADD config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml  /home/alpine/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml

# RUN chown -R alpine:alpine /home/alpine/.config /home/alpine/.xscreensaver
RUN chown -R alpine:alpine /home/alpine/

# ports
EXPOSE 22 5900

# default command
CMD ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]
