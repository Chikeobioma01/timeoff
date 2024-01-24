# -------------------------------------------------------------------
# Minimal dockerfile from alpine base
#
# Instructions:
# =============
# 1. Create an empty directory and copy this file into it.
#
# 2. Create image with: 
#	docker build --tag timeoff:latest .
#
# 3. Run with: 
#	docker run -d -p 3000:3000 --name alpine_timeoff timeoff
#
# 4. Login to running container (to update config (vi config/app.json):
#	docker exec -ti --user root alpine_timeoff /bin/sh
# --------------------------------------------------------------------
#FROM alpine:latest as dependencies
#
#RUN apk add --no-cache \
#    nodejs npm
#
#COPY package.json  .
#RUN npm install -g npm
#RUN  apk add  gdb
#
#FROM alpine:latest
#
#LABEL org.label-schema.schema-version="1.0"
#LABEL org.label-schema.docker.cmd="docker run -d -p 3000:3000 --name alpine_timeoff"
#
#RUN apk add --no-cache \
#    nodejs npm \
#    vim
#
#RUN adduser --system app --home /app
#RUN  apk add  gdb
#USER app
#WORKDIR /app
#COPY . /app
#COPY --from=dependencies node_modules ./node_modules
#
#CMD npm start
#
#EXPOSE 3000

# Use an official Node.js runtime as a base image
FROM node:13.0.0

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install application dependencies
RUN npm install

# Copy the application code to the container
COPY . .

# Expose the port the app runs on
EXPOSE 3000

# Define the command to run the application
CMD ["npm", "start"]
