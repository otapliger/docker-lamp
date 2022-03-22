# otapliger/lamp

[otapliger/lamp](https://registry.hub.docker.com/u/otapliger/lamp/) is a fork of
[dgraziotin/lamp](https://registry.hub.docker.com/u/dgraziotin/lamp/), which is a LAMP image for Docker.

The differences are:

- it is based on [phusion/baseimage:bionic:1.0.0](http://phusion.github.io/baseimage-docker/)
- provides phpMyAdmin 5.1.3
- removes Vagrant support

## Usage

To create a custom image, run the following command from the root of the project folder (change `username` with your Docker Hub username):

`docker build -t username/lamp .`

If you wish, you can push your new image to the registry with the command:

`docker push username/lamp`

Otherwise, you are free to use otapliger/lamp as it is provided. Remember first
to pull it from the Docker Hub:

`docker pull otapliger/lamp`

### Running your LAMP docker image

You can start the image with the command (change `docker-lamp` with a name of your choice):

`docker run -it -p 80:80 -p 3306:3306 --name docker-lamp otapliger/lamp`

It will be accessible at http://localhost, and at http://localhost/phpmyadmin you should see a running phpMyAdmin instance.

### Loading your custom PHP application

Run the following command from the root of the project folder.

`docker run -it -p 80:80 -p 3306:3306 --name docker-lamp \
-v ${PWD}/app:/app \
otapliger/lamp`

The subfolder `app` should contain the root of your PHP application.

If you wish to mount a MySQL folder locally, so that MySQL files are saved on your machine, run the following command instead:

`docker run -it -p 80:80 -p 3306:3306 --name docker-lamp \
-v ${PWD}/mysql:/var/lib/mysql \
-v ${PWD}/app:/app \
otapliger/lamp`

The MySQL database will thus become persistent at each subsequent run of your image.

## Environment description

### Apache

Apache is pretty much standard in this image. Mod rewrite is enabled. It runs under the user `www-data` and the group `staff`.

### MySQL

The bundled MySQL server has two users, `root` and `admin`, plus an optional third user.

`root` comes with an empty password, and it is for local connections. The `root` user cannot remotely access the database (and the container).

`admin` has all root privileges. To get the password, check the logs.

Finally, an optional user can be created either when the environment variable `MYSQL_OPTIONAL_USER` is true or any of the `MYSQL_USER_*` variables is set.

The optional user is called `user`, and has `passw0rd` as password. It has full privileges on a database called `db`. The name, password, and database can be changed using the `MYSQL_USER_*` variables explained below.

## Environment variables

- `APACHE_ROOT` tells Apache which folder within the app volume to serve as root.

- `MYSQL_ADMIN_PASS` gives a custom password to `admin`.
- `MYSQL_OPTIONAL_USER` creates the optional user if set to true.
- `MYSQL_USER_NAME` changes the name of the optional user.
- `MYSQL_USER_PASS` changes the password of the optional user.
- `MYSQL_USER_DB` changes the database of the optional user.

- `PHP_UPLOAD_MAX_FILESIZE` sets PHP upload_max_filesize config value.
- `PHP_POST_MAX_SIZE` sets PHP post_max_size config value.

Set these variables using the `-e` flag when invoking `docker`:

`docker run -it -p 80:80 -p 3306:3306 --name docker-lamp \
-v ${PWD}/app:/app \
-e MYSQL_ADMIN_PASS="passw0rd" \
otapliger/lamp`

Please note that the MySQL variables will not work if an existing MySQL volume is supplied.
