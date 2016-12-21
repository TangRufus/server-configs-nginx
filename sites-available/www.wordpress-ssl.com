# Choose between www and non-www, listen on the *wrong* one and redirect to
# the right one -- http://wiki.nginx.org/Pitfalls#Server_Name
#
server {
  listen [::]:80;
  listen 80;

  # listen on both http://www and http:// hosts
  server_name example.com www.example.com;

  # and redirect to the https://www host (declared below)
  # avoiding http:// -> http://www -> https://www chain.
  return 301 https://www.example.com$request_uri;
}

server {
  listen [::]:443 ssl http2;
  listen 443 ssl http2;

  # listen on the non-www host
  server_name example.com;

  # Path for ssl certificates
  ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

  include h5bp/directive-only/ssl.conf;
  include h5bp/directive-only/ssl-stapling.conf;

  # and redirect to the www host (declared below)
  return 301 https://www.example.com$request_uri;
}

server {

  # listen [::]:443 ssl http2 accept_filter=dataready;  # for FreeBSD
  # listen 443 ssl http2 accept_filter=dataready;  # for FreeBSD
  listen [::]:443 ssl http2;  # for Linux
  listen 443 ssl http2;  # for Linux
  # listen [::]:443 ssl http2;
  # listen 443 ssl http2;

  # The host name (https://asset) to respond to
  server_name asset.example.com;

  # Path for ssl certificates
  ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

  # Path for static files
  root /var/www/example.com;

  #Specify a charset
  charset utf-8;

  # Redirect to https://www host if not media files
  location ~* ^(?!(/wp-content/uploads/)) {
    return 301 https://www.example.com$request_uri;
  }

  # Include the basic h5bp and wordpress config set
  include wordpress/ssl-basic.conf;

  # Include CORS config
  include conf.d/cross-domain-fonts-secure-typist.conf;
}

server {

  # listen [::]:443 ssl http2 accept_filter=dataready;  # for FreeBSD
  # listen 443 ssl http2 accept_filter=dataready;  # for FreeBSD
  listen [::]:443 ssl http2 deferred;  # for Linux
  listen 443 ssl http2 deferred;  # for Linux
  # listen [::]:443 ssl http2;
  # listen 443 ssl http2;

  # The host name (https://www) to respond to
  server_name www.example.com;

  # Path for ssl certificates
  ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

  # Path for static files
  root /var/www/example.com;

  # Specify a charset
  charset utf-8;

  # Redirect media files to https://asset host
  rewrite /wp-content/uploads$ https://asset.example.com$request_uri permanent;

  # Include the basic h5bp and wordpress config set
  include wordpress/ssl-basic.conf;

  # Include CORS config
  include conf.d/cross-domain-fonts-secure-typist.conf;
}
