# vanet-blockchain
**1. Create project blockchain**

Step 1: Initialize project based on npm
```
$ npm init
```

Step 2: install truffle version 5.4.11
```
$ npm install truffle@5.4.11 --save-dev
```

Step 3: Address vulnerabilities
```
$ npm audit fix
```

Step 4: Initialize truffle project
```
$ npx truffle init
```

**2. Deploy code into Ganache**

a. Config network address

```
networkds: {
      ganache :{
        host: "127.0.0.1",     // Localhost (default: none)
        port: 7545,            // Standard Ethereum port (default: none)
        network_id: "*",       // Any network (default: none)
      },
}
```

b. Create file 2_deploy_contract.js
```
var ChainList = artifacts.require("ChainList");

module.exports = function(deployer) {

  deployer.deploy(ChainList);

}
```