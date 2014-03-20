# TwitterURL

Save all URL mentioned in you twitter timeline for later check !. 

I was checking twitter timeline with very simple terminal application but
from time to time I lost a URL which might be very interesting.

## Setup configuration

you need to set up Config::Pit configuration file.

somewhere like ~/.pit/default.yaml
```
"stream2twitter": 
  "consumer_key": 'your-consumer_key'
  "consumer_secret": 'your-consumer_secret'
  "access_token": 'your-access_token'
  "access_token_secret": 'your-access_token_secret'
  "username": 'your_name'
  "sleep_sec": '300'
  "expand_url": [ "some_url_shorten_service" ]
  "ignore_name": [ "some_name2ignore" ]
  "ignore_url": [ "http://some_url2ignore" ]
```

## Setup storage

we need twitter_url table so start psql and execute create_twitter_url.sql.
```
createdb twitter_url
psql twitter_url
\i create_twitter_url.sql
```

I use PostgreSQL but I do not use any special PostgreSQL function
so you can change storage engine to MySQL or SQLite if you like.

## Setup web server

/etc/apache2/conf.d/plack.conf
```
FastCgiExternalServer /app/turl/url.psgi -socket /tmp/fastcgi.sock
```

/etc/apache2/mods-enabled/fastcgi.conf
```
<IfModule mod_fastcgi.c>
  AddHandler fastcgi-script .fcgi
  Alias /turl "/app/turl/url.psgi"
  FastCgiIpcDir /var/lib/apache2/fastcgi
</IfModule>
```
then startup application
% start_server -- plackup -s FCGI --listen /tmp/fastcgi.sock /app/turl/url.psgi

## Start checking timeline

% ./tl.pl !!!!!


