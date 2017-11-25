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
