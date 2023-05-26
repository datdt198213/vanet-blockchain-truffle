App = {
    web3Provider: null,
    contracts: {},
    account: 0x0,
    loading: false,
  
    init() {
      return App.initWeb3();
    },
  
    async initWeb3() {
      if (typeof web3 !== undefined) {
        // reuse the provider of the web3 object injected by Metamask
        App.web3Provider = window.ethereum;
      } else {
        App.web3Provider = new Web3.providers.HttpProvider(
          "http://127.0.0.1:7545"
        );
      }
      web3 = new Web3(App.web3Provider);
      App.displayAccountInfo();
  
      return App.initContract();
    },
  
    async displayAccountInfo() {
      web3.eth
        .getCoinbase((err, account) => {
          if (err === null) {
            App.account = account;
            $("#account").text(`Address: ${account}`);
            return account;
          }
        })
        .then((account) => {
          web3.eth
            .getBalance(account, (err, balance) => {
              if (err === null) {
                $("#accountBalance").text(
                  "Balance: " + web3.utils.fromWei(balance, "ether") + " ETH"
                );
              }
            })
            .catch((err) => console.log(err));
        })
        .catch((err) => console.log(err));
    },
  
    async initContract() {
      $.getJSON("ChainList.json", (chainListArtifact) => {
        // get the contract artifact file and use it to instantiate a truffle contract abstraction
        App.contracts.ChainList = TruffleContract(chainListArtifact);
        // set the provider for our contracts
        App.contracts.ChainList.setProvider(App.web3Provider);
        // listen to event
        App.listenToEvents();
        // retrieve the article from the contract
        return App.reloadArticles();
      });
    },
  
    async reloadArticles() {
      if (App.loading) {
        return;
      }
  
      App.loading = true;
  
      App.displayAccountInfo();
  
      var chainListInstance;
  
      App.contracts.ChainList.deployed()
        .then((instance) => {
          chainListInstance = instance;
          console.log(chainListInstance);
          return chainListInstance.getAllArticles();
        })
        .then((articleIds) => {
          console.log(articleIds);
          $("#articlesRow").empty();
  
          for (var i = 0; i < articleIds.length; i++) {
            var articleId = articleIds[i];
            chainListInstance.articles(articleId.toNumber()).then((article) => {
              console.log(article);
              App.displayArticle(
                article.id,
                article.seller,
                article.buyer,
                article.name,
                article.desciption,
                article.price
              );
            });
          }
          App.loading = false;
        })
        .catch((err) => {
          console.log(err.message);
          App.loading = false;
        });
    },
  
    async displayArticle(id, seller, buyer, name, description, price) {
      var articlesRow = $("#articlesRow");
      console.log(buyer);
  
      var etherPrice = web3.utils.fromWei(price.toString(), "ether");
  
      var articleTemplate = $("#articleTemplate");
      articleTemplate.find(".panel-title").text(name);
      articleTemplate.find(".article-description").text(description);
      articleTemplate.find(".article-price").text(etherPrice + " ETH");
      articleTemplate.find(".btn-buy").attr("data-id", id);
      articleTemplate.find(".btn-buy").attr("data-value", etherPrice);
  
      // seller
      if (seller.toLowerCase() == App.account) {
        articleTemplate.find(".article-seller").text("Me");
        articleTemplate.find(".btn-buy").hide();
      } else {
        articleTemplate.find(".article-seller").text(seller);
        articleTemplate.find(".btn-buy").show();
      }
      if (buyer.toLowerCase() === App.account.toLowerCase()) {
        articleTemplate.find(".btn-buy").hide();
        articleTemplate.find(".article-buyer").text("Bought by me");
      } else if (
        buyer.toLowerCase() !==
        "0x0000000000000000000000000000000000000000".toLowerCase()
      ) {
        articleTemplate.find(".article-buyer").text("Bought by other");
      } else {
        articleTemplate.find(".article-buyer").text("");
      }
  
      // add this new article
      articlesRow.append(articleTemplate.html());
    },
  
    async sellArticle() {
      var _article_name = $("#article_name").val();
      var _description = $("#article_description").val();
      var _price = web3.utils.toWei(
        String(parseFloat($("#article_price").val() || 0)),
        "ether"
      );
  
      if (_article_name.trim() == "" || _price == 0) {
        return false;
      }
  
      var file = document.getElementById("file").files[0];
      if (file) {
        var reader = new FileReader();
        reader.onload = function (event) {
          var _fileHash = sha1(event.target.result);
  
          App.contracts.ChainList.deployed()
            .then((instance) => {
              return instance.sellArticle(
                _article_name,
                _description,
                _fileHash,
                _price,
                {
                  from: App.account,
                  gas: 500000,
                }
              );
            })
            .catch((err) => console.log(err));
        };
        reader.readAsArrayBuffer(file);
      }
    },
  
    // listen events triggerd by the contract
    async listenToEvents() {
      App.contracts.ChainList.deployed().then((instance) => {
        instance
          .getPastEvents("allEvents", {
            fromBlock: 0,
            toBlock: "latest",
          })
          .then((events) => {
            for (const key in events) {
              const evt = events[key];
              var buyer = evt.returnValues._buyer;
              var articleName = evt.returnValues._name;
              var seller = evt.returnValues._seller;
  
              if (evt.event === "LogSellArticle") {
                if (App.account.toLowerCase() === seller.toLowerCase()) {
                  $("#events").append(
                    '<li class="list-group-item">' +
                      "You sold " +
                      evt.returnValues._name +
                      "</li>"
                  );
                } else {
                  $("#events").append(
                    '<li class="list-group-item">' +
                      seller +
                      " sold " +
                      evt.returnValues._name +
                      "</li>"
                  );
                }
              }
  
              if (evt.event === "LogBuyArticle") {
                if (App.account.toLowerCase() === buyer.toLowerCase()) {
                  $("#events").append(
                    '<li class="list-group-item">' +
                      "You bought " +
                      articleName +
                      "</li>"
                  );
                } else {
                  $("#events").append(
                    '<li class="list-group-item">' +
                      buyer +
                      " bought " +
                      articleName +
                      "</li>"
                  );
                }
              }
            }
            App.reloadArticles();
          });
  
        instance.contract.events.LogSellArticle({}, (error, evt) => {
          App.reloadArticles();
        });
  
        instance.contract.events.LogBuyArticle({}, (error, evt) => {
          App.reloadArticles();
        });
      });
    },
  
    async buyArticle() {
      event.preventDefault();
  
      var _articleId = $(event.target).data("id");
      var _price = parseFloat($(event.target).data("value"));
  
      App.contracts.ChainList.deployed()
        .then((instance) => {
          return instance.buyArticle(_articleId, {
            from: App.account,
            value: web3.utils.toWei(String(_price), "ether"),
            gas: 500000,
          });
        })
        .catch((err) => console.log(err));
    },
  };
  
  $(function () {
    $(window).load(function () {
      App.init();
    });
  });