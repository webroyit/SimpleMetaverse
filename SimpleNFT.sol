// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";    // Keep track of how many NFTS
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleNFT is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  // For NFT metadata
  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 0 ether;
  uint256 public maxSupply = 12;
  uint256 public maxMintAmountPerTx = 5;

  bool public paused = false;
  bool public revealed = false;

  // `struct` is a custom data type
  struct Building {
    string name;
    int8 w;
    int8 h;
    int8 d;
    int8 x;
    int8 y;
    int8 z;
  }

  Building[] public buildings;

  constructor() ERC721("HVerse", "HVS") {
    // Make it easy to verify the contract on etherscan
    setHiddenMetadataUri("ipfs://__CID__/hidden.json");

    buildings.push(Building("ZERO", 0, 0, 0, 0, 0, 0));
    buildings.push(Building("House", 1, 3, 2, 2, 0, 3));
    buildings.push(Building("Bob House", 2, 5, 4, 10, 0, 6));
    buildings.push(Building("Gallery", 1, 6, 2, 10, 0, 0));
    buildings.push(Building("House", 1, 1, 2, 7, 0, -7));
    buildings.push(Building("Cool House", 2, 3, 1, -9, 0, -9));
    buildings.push(Building("House", 1, 3, 3, -4, 0, 2));
    buildings.push(Building("Joe House", 2, 5, 2, -2, 0, 5));
    buildings.push(Building("House", 2, 6, 1, -10, 0, 0));
    buildings.push(Building("Ghost House", 4, 1, 4, 5, 0, 0));
  }

  // Check requirements before minting
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  // Return list of building
  function getBuilding() public view returns (Building[] memory) {
    return buildings;
  }

  // Return number of NFTs minted
  function totalSupply() public view returns (uint256) {
    return supply.current();
  }
  
  // For users to mint
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    _mintLoop(msg.sender, _mintAmount);
  }
  
  // For contract owners to mint
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  // Return an array of Tokens Ids that user own
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  // Hide or unhide metadata
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}