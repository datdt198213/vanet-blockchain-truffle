// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;
import "./Ownable.sol";

contract ChainList is Ownable {
    // state variable
    struct Article {
        uint256 id;
        address seller;
        address buyer;
        string name;
        string desciption;
        string fileHash;
        uint256 price;
    }

    mapping(uint256 => Article) public articles;
    uint256 articlesCounter;

    event LogSellArticle(
        uint256 indexed _id,
        address indexed _seller,
        string _name,
        uint256 _price
    );

    event LogBuyArticle(
        uint256 indexed _id,
        address indexed _seller,
        address indexed _buyer,
        string _name,
        uint256 _price
    );

    //sell an article
    function sellArticle(
        string memory _name,
        string memory _desciption,
        string memory _fileHash,
        uint256 _price
    ) public {
        require(checkHash(_fileHash) == false);
        articlesCounter++;

        articles[articlesCounter] = Article(
            articlesCounter,
            msg.sender,
            address(0x0),
            _name,
            _desciption,
            _fileHash,
            _price
        );

        emit LogSellArticle(articlesCounter, msg.sender, _name, _price);
    }

    function buyArticle(uint256 _id) public payable {
        require(articlesCounter > 0);

        require(_id > 0 && _id <= articlesCounter);

        Article storage article = articles[_id];

        require(article.buyer == address(0x0));

        require(msg.sender != article.seller);

        require(msg.value == article.price);

        article.buyer = msg.sender;

        payable(article.seller).transfer(msg.value);

        emit LogBuyArticle(
            _id,
            article.seller,
            article.buyer,
            article.name,
            article.price
        );
    }

    function getNumberOfArticles() public view returns (uint256) {
        return articlesCounter;
    }

    function getAllArticles() public view returns (uint256[] memory) {
        uint256[] memory articlesIds = new uint256[](articlesCounter);

        uint256 numberOfArticlesForSale = 0;

        for (uint256 i = 1; i <= articlesCounter; i++) {
            articlesIds[numberOfArticlesForSale] = articles[i].id;
            numberOfArticlesForSale++;
        }

        // copy to smaller array
        uint256[] memory forSale = new uint256[](numberOfArticlesForSale);
        for (uint256 i = 0; i < numberOfArticlesForSale; i++) {
            forSale[i] = articlesIds[i];
        }

        return forSale;
    }

    function checkHash(string memory _fileHash) private view returns (bool) {
        for (uint256 i = 0; i <= articlesCounter; i++) {
            if (compareStrings(articles[i].fileHash, _fileHash)) {
                return true;
            }
        }

        return false;
    }

    function compareStrings(
        string memory a,
        string memory b
    ) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}
