// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Importing DN404 token contract
import "./lib/DN404.sol";
// Importing DN404Mirror contract from external source
import "dn404/src/DN404Mirror.sol";
// Importing Ownable contract from solady library
import {Ownable} from "solady/src/auth/Ownable.sol";
// Importing LibString contract from solady library
import {LibString} from "solady/src/utils/LibString.sol";
// Importing SafeTransferLib contract from solady library
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
// Importing MerkleProofLib contract from solady library
import {MerkleProofLib} from "solady/src/utils/MerkleProofLib.sol";

contract NFTMintDN404 is DN404, ERC20Permit, Ownable{
	
    string private _name;
    string private _symbol;
    string private _baseURI;
    bytes32 private allowlistRoot;
    uint120 public publicPrice;
    uint120 public allowlistPrice;
    bool public live;
    uint256 public numMinted;
    uint256 public MAX_SUPPLY;

    error InvalidProof();
    error InvalidPrice();
    error ExceedsMaxMint();
    error TotalSupplyReached();
    error NotLive();

    modifier isValidMint(uint256 price, uint256 amount) {
        if (!live) {
            revert NotLive();
        }
        if (price * amount != msg.value) {
            revert InvalidPrice();
        }
        if (numMinted + amount > MAX_SUPPLY) {
            revert TotalSupplyReached();
        }
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 _MAX_SUPPLY,
        uint120 publicPrice_,
        uint96 initialTokenSupply,
        address initialSupplyOwner
    ) ERC20Permit("NFTMintDN404") {
        _initializeOwner(msg.sender);

        _name = name_;
        _symbol = symbol_;
        MAX_SUPPLY = _MAX_SUPPLY;
        publicPrice = publicPrice_;

        address mirror = address(new DN404Mirror(msg.sender));
        _initializeDN404(initialTokenSupply, initialSupplyOwner, mirror);
    }

    function mint(uint256 amount) public payable isValidMint(publicPrice, amount) {
        unchecked {
            ++numMinted;
        }
        _mint(msg.sender, amount);
    }

    function allowlistMint(uint256 amount, bytes32[] calldata proof)
        public
        payable
        isValidMint(allowlistPrice, amount)
    {
        if (
            !MerkleProofLib.verifyCalldata(
                proof, allowlistRoot, keccak256(abi.encodePacked(msg.sender))
            )
        ) {
            revert InvalidProof();
        }
        unchecked {
            ++numMinted;
        }
        _mint(msg.sender, amount);
    }

    function setBaseURI(string calldata baseURI_) public onlyOwner {
        _baseURI = baseURI_;
    }

    function setPrices(uint120 publicPrice_, uint120 allowlistPrice_) public onlyOwner {
        publicPrice = publicPrice_;
        allowlistPrice = allowlistPrice_;
    }

    function toggleLive() public onlyOwner {
        live = !live;
    }

    function withdraw() public onlyOwner {
        SafeTransferLib.safeTransferAllETH(msg.sender);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory result) {
        if (bytes(_baseURI).length != 0) {
            result = string(abi.encodePacked(_baseURI, LibString.toString(tokenId)));
        }
    }

    function setAllowlist(bytes32 allowlistRoot_) public onlyOwner {
        allowlistRoot = allowlistRoot_;
    }

    function setAllowlistPrice(uint120 allowlistPrice_) public onlyOwner {
        allowlistPrice = allowlistPrice_;
    }

    function nftTotalSupply() public view returns (uint256) {
        return _totalNFTSupply();
    }

    function nftbalanceOf(address owner) public view returns (uint256) {
        return _balanceOfNFT(owner);
    }

    function previewNextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    function getURI() public view returns(string memory) {
        return _baseURI;
    }
}