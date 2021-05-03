pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract CryptoCoffee is ERC721Enumerable, ERC721URIStorage, Ownable {
    IERC20 private _token;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    constructor(IERC20 token) ERC721('Token', 'NFT') {
        _token = token;
    }
    receive() external payable {}
    event nftPriceSet(uint256 tokenId, uint256 amount);
    event SaleSuccessful(uint256 tokenId, uint256 price, address buyer);
    event nameChanged(uint256 tokenId, string oldName, string newName);
    struct NFT {
      address owner;
      uint256 price;
      bool onSale;
      string metadata;
      string asset;
      string hash;
    }
    mapping(string => bool) hashExists;
    mapping(uint256 => NFT) tokenIdToNft;
    mapping(uint256 => uint128) tokenIdToMintingCost;
    modifier onlySeller(uint256 _tokenId) {
        require(_exists(_tokenId));
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
         return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorage, ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    function buyRicheduToken() external payable {
        require(msg.value > 0);
        require(_token.balanceOf(address(this)) >= msg.value);
        _token.transfer(msg.sender, (10**18)*msg.value);
    }
    function sellRicheduToken(uint256 _amount) external {
        require(_amount > 0);
        require(_token.allowance(msg.sender, address(this)) >= (10**18)*_amount);
        _token.transferFrom(msg.sender, address(this), (10**18)*_amount);
        payable(msg.sender).transfer(_amount);
    }
    function mintNFT(string memory _name, string memory _hash, string memory _metadata, uint128 _mintingCost, uint256 userPays) external {
        require(hashExists[_hash] != true);
        require(_mintingCost == userPays);
        hashExists[_hash] = true;
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _metadata);
        NFT storage nft = tokenIdToNft[newTokenId];
        nft.metadata = _metadata;
        nft.asset = _name;
        nft.hash = _hash;
        tokenIdToMintingCost[newTokenId] = (10**18)*_mintingCost;
        _token.transferFrom(msg.sender, address(this), (10**18)*_mintingCost);
        tokenIdToNft[newTokenId].owner = payable(msg.sender);
        emit Transfer(address(this), msg.sender, newTokenId);
    }
    function setPricePutOnSale(uint _tokenId, uint128 _amount) external onlySeller(_tokenId) {
        NFT storage nft = tokenIdToNft[_tokenId];
        nft.owner = msg.sender;
        nft.price = (10**18)*_amount;
        nft.onSale = true;
        emit nftPriceSet(_tokenId, _amount);
    }
    function burnNFT(uint256 _tokenId) external onlySeller(_tokenId) {
        require(tokenIdToNft[_tokenId].onSale != true);
        delete hashExists[tokenIdToNft[_tokenId].hash];
        delete tokenIdToNft[_tokenId];
        uint256 mintingCost = tokenIdToMintingCost[_tokenId];
        uint256 backToUser = mintingCost - mintingCost/4;
        _token.transfer(msg.sender, backToUser);
        _burn(_tokenId);
    }
    function buyAtSale(uint256 _tokenId, uint256 userPays) external {
        NFT storage nft = tokenIdToNft[_tokenId];
        require(nft.onSale);
        require(nft.price == userPays);
        _removeSale(_tokenId);
        if (nft.price > 0) {
            _token.transferFrom(msg.sender, nft.owner, nft.price);
        }
        emit SaleSuccessful(_tokenId, nft.price, msg.sender);
        _transfer(tokenIdToNft[_tokenId].owner, msg.sender, _tokenId);
        emit Transfer(tokenIdToNft[_tokenId].owner, msg.sender, _tokenId);
        tokenIdToNft[_tokenId].owner = msg.sender;
    }
    function _removeSale(uint256 _tokenId) internal {
        delete tokenIdToNft[_tokenId].onSale;
    }
    function stopSale(uint256 _tokenId) external onlySeller(_tokenId) {
        delete tokenIdToNft[_tokenId].onSale;
    }
    function changeName(uint256 _tokenId, string memory _newName) external onlySeller(_tokenId) {
        emit nameChanged(_tokenId, tokenIdToNft[_tokenId].asset, _newName);
        tokenIdToNft[_tokenId].asset = _newName;
    }
    function giftNFT(address _giftTo, uint256 _tokenId) external onlySeller(_tokenId) {
        require(tokenIdToNft[_tokenId].onSale != true);
        safeTransferFrom(msg.sender, _giftTo, _tokenId);
        emit Transfer(msg.sender, _giftTo, _tokenId);
    }
    function owned_NFTs() external view returns (uint256[] memory) {
        uint256[] memory nftList = new uint256[](balanceOf(msg.sender));
        uint256 tokenIndex;
        for (tokenIndex = 0; tokenIndex < balanceOf(msg.sender); tokenIndex++) {
            nftList[tokenIndex] = tokenOfOwnerByIndex(msg.sender, tokenIndex);
            }
        return nftList;
    }
}