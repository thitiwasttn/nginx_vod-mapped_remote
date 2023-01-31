FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Bangkok

# Prepare the server and install the required program
RUN apt update && \
apt upgrade -y && \
apt dist-upgrade && \
apt install curl -y && \
apt install nano -y && \
apt install iproute2 -y && \
apt install build-essential -y && \
apt install libssl-dev -y && \
apt install zlib1g-dev -y && \
apt install linux-generic -y && \
apt install libpcre3 -y && \
apt install libpcre3-dev -y && \
apt install ffmpeg -y && \
apt install libavcodec-dev -y && \
apt install libavformat-dev -y && \
apt install libswscale-dev -y

# Install Nginx and related modules
# We will start installing Nginx by building with modules as follows:

# Kaltura’s vod module is the main module using to create on-the-fly repackaging mp4 video
# Akamai token validation module for validate token in video url (for authentication)
# Secure token module for url token generation
# Start by create folders for files we’re about to download
RUN mkdir vod
WORKDIR /vod
RUN mkdir nginx nginx-vod-module nginx-akamai-token-validate-module nginx-secure-token-module

# The download and extract Nginx and module files
RUN curl -sL https://nginx.org/download/nginx-1.16.1.tar.gz | tar -C /vod/nginx --strip 1 -xz && \
curl -sL https://github.com/kaltura/nginx-vod-module/archive/9a152ae5373376ac5371f95d90b635208bb71598.tar.gz | tar -C /vod/nginx-vod-module --strip 1 -xz && \
curl -sL https://github.com/kaltura/nginx-akamai-token-validate-module/archive/1.1.tar.gz | tar -C /vod/nginx-akamai-token-validate-module --strip 1 -xz && \
curl -sL https://github.com/kaltura/nginx-secure-token-module/archive/1.4.tar.gz | tar -C /vod/nginx-secure-token-module --strip 1 -xz

# Run installation command: configure, make and make install
WORKDIR /vod/nginx
RUN ./configure --prefix=/usr/local/nginx \
	--add-module=../nginx-vod-module \
	--add-module=../nginx-akamai-token-validate-module \
	--add-module=../nginx-secure-token-module \
	--with-http_ssl_module \
	--with-file-aio \
	--with-threads \
	--with-cc-opt="-O3" && \
apt install make && make && make install && \
rm -rf /usr/local/nginx/html /usr/local/nginx/conf/*.default
# Then we start Nginx with command:
# RUN /usr/local/nginx/sbin/nginx

# backup original config
RUN mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak

# create videos dir
RUN mkdir videos

# copy config nginx
#COPY nginx.conf /usr/local/nginx/conf/

COPY nginx.conf /usr/local/nginx/conf/nginx.conf

EXPOSE 80

# start nginx when start container
CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]