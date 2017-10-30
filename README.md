# draws

[Sinatra](http://www.sinatrarb.com/) web application for accessing and reading [AWS Resources](//missing_link) using [aws-sdk for ruby](//github.com/aws/aws-sdk-ruby).

This application aims to provide a better User Experience in terms of Overview, Accessibility etc. for AWS Resources like VPCs, Subnets, Instances etc.

AWS Resources are pulled using the `/reload` endpoint and stored in a sqlite database for caching purposes. 

## Configuration & Application startup

> You need to configure :credentials and a :region to make API calls. It is recommended that you provide these via your environment. This makes it easier to rotate credentials and it keeps your secrets out of source control.

https://github.com/aws/aws-sdk-ruby#configuration

    ruby app.rb -p 3000

Visit http://localhost:3000 or http://localhost:3000/reload if you want to refresh the AWS Resources cache.

## Features
  
* Reload AWS resources: flush db and pull AWS Resources into cache
    `get '/reload'`

* VPCs List
    `get '/'`

* VPCs & Subnets including Instances Show
    `get '/vpcs/:vid'`

* Instances List
    `get '/instances'`

* Instance Show
    `get 'instances/:iid'`

_to be defined_

    get  '/regions/:rid/instances/:iid'
    get  '/regions/:rid/vpc/:vid/instances/:iid'
    get  '/regions/:rid/vpc/:vid/subnets/:sid/instances/:iid'

_to be defined if possible?_

    namespace '/regions/:rid/
      get  '/instances/:iid/:attribute'
      post '/instances/:iid/:rpc_name'

_to be defined if needed?_

    namespace '/admin'

## Deployment

Deployment instructions using various platforms.

### Dokku

Dokku Dockerfile Deployment

1. Local

    a. `git remote add dokku dokku@<dokku-server>:draws`

    b. `git push dokku master`

2. Remote dokku server

    a. Automatically retrieve and install Lets Encrypt certificates
    `dokku letsencrypt draws`

    b. HTTP Basic Auth over TLS (Lets Encrypt) for Security
    `dokku http-auth:on draws <your-name> <your-secure-password>`

    c. AWS Credentials
    `dokku config:set draws AWS_ACCESS_KEY_ID=XXX AWS_SECRET_ACCESS_KEY=XXX`

    d. Optional: AWS Region (default: 'eu-central-1')
    `dokku config:set draws AWS_REGION=<aws-region>`

3. Open in browser

    http://draws.dokku-server.tld

## Development environment

### Start

    # using sinatra/reloader?
    ruby app.rb -p 3000 -o 0.0.0.0

    # alternatively
    shotgun app.rb -p 3000 -o 0.0.0.0 

### Load sample data

    cat sample_data/schema.sql | sqlite3 cache-db.sqlite
    cat sample_data/dump.sql | sqlite3 cache-db.sqlite

## Maintainer

[bro](https://github.com/rbojan)
