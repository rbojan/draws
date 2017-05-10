# draws

[Sinatra](http://www.sinatrarb.com/) web application for accessing and reading [AWS Resources](//missing_link) using [aws-sdk for ruby](//github.com/aws/aws-sdk-ruby).

This applications aims to provide a better User Experience in terms of Overview, Accessibility etc. for AWS Resources like VPCs, Subnets, Instances etc.

AWS Resources are pulled using the `/reload` endpoint and stored in a sqlite database for caching purposes. 

## Configuration & Application startup

> You need to configure :credentials and a :region to make API calls. It is recommended that you provide these via your environment. This makes it easier to rotate credentials and it keeps your secrets out of source control.

https://github.com/aws/aws-sdk-ruby#configuration


    ruby app.rb -p 3000

Visit http://localhost:3000 or http://localhost:3000/reload if you want to refresh the AWS Resources cache.


## Features

tl;dr
  
    # Reload AWS resources: Flush db and pull AWS Resources into cache
    get '/reload'

    # VPCs & Subnets including Instances Overview
    get '/vpcs'

    # Instances List (Overview)
    get '/instances'

    # Instance Show
    get 'instances/:iid'

    # tbd.
    get  '/regions/:rid/instances/:iid'
    get  '/regions/:rid/vpc/:vid/instances/:iid'
    get  '/regions/:rid/vpc/:vid/subnets/:sid/instances/:iid'

    # possible?
    namespace '/regions/:rid/
      get  '/instances/:iid/:attribute'
      post '/instances/:iid/:rpc_name'
    
    # tbd: needed?
    namespace '/admin'


## Development environment

    # using sinatra/reloader?
    ruby app.rb -p 3000 -o 0.0.0.0

    # alternatively
    shotgun app.rb -p 3000 -o 0.0.0.0 
