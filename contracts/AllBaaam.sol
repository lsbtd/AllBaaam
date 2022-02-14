// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract AllBaaam is ERC1155 {
    address public serviceAddress;
    address public rewardFeather;

    string public name;
    string public symbol;

    string pinataGateway = "https://allbaaam.mypinata.cloud/ipfs/";
    mapping(uint => string) metadataURIs;

    uint public constant FEATHER_TOKEN = 0;
    uint public constant TOTAL_FEATHER = 1000000000000;

    uint public TOTAL_OWLS = 0;
    uint public TOTAL_OWL_POWER = 0;

    uint public owlId = 1;
    struct OwlData {
        uint8 level;
        uint power;
        uint exp;
    }
    mapping(uint => OwlData) public owls;

    mapping(address => uint) public transferLock;

    constructor(string memory _name, string memory _symbol) ERC1155("") {
        serviceAddress = msg.sender;

        name = _name;
        symbol = _symbol;

        setURI(FEATHER_TOKEN, "QmTzCPCv82dMMCg33mWxD5HXW8ygLgG89iahefGz7GQ6fd");
        _mint(msg.sender, FEATHER_TOKEN, TOTAL_FEATHER, "");
    }

    modifier serviceAddressOnly() {
        require(serviceAddress == msg.sender, "Caller is not service address.");
        _;
    }

    function setURI(uint _tokenId, string memory _uri) public {
        metadataURIs[_tokenId] = _uri;
    }
    function uri(uint _tokenId) override public view returns (string memory) {
        return string(
            abi.encodePacked(pinataGateway, metadataURIs[_tokenId])
        );
    }

    function mintFeather(uint _amount) public serviceAddressOnly() {
        _mint(msg.sender, FEATHER_TOKEN, _amount, "");
    }

    function mintOwl(string[] memory _uris, uint[] memory _powers, uint[] memory _exps, uint _amount) public serviceAddressOnly() {
        setURI(owlId, _uris[0]);
        setURI(owlId + 1, _uris[1]);
        setURI(owlId + 2, _uris[2]);
        owls[owlId] = OwlData(1, _powers[0], _exps[0]);
        owls[owlId + 1] = OwlData(2, _powers[1], _exps[1]);
        owls[owlId + 2] = OwlData(3, _powers[2], _exps[2]);

        TOTAL_OWLS = TOTAL_OWLS + _amount;
        TOTAL_OWL_POWER = TOTAL_OWL_POWER + (_powers[0] * _amount);

        _mint(serviceAddress, owlId, _amount, "");
        owlId = owlId + 3;
    }

    function levelUp(uint _tokenId) public {
        require(balanceOf(msg.sender, _tokenId) >= 1, "Caller is not have Owl.");
        require(owls[_tokenId].level < 3, "Owl is max level.");
        require(balanceOf(msg.sender, FEATHER_TOKEN) >= owls[_tokenId].exp, "");

        _burn(msg.sender, FEATHER_TOKEN, owls[_tokenId].exp);
        _burn(msg.sender, _tokenId, 1);

        TOTAL_OWL_POWER = TOTAL_OWL_POWER - owls[_tokenId].power + owls[_tokenId + 1].power;

        _mint(msg.sender, _tokenId + 1, 1,"");
    }

    function getOwlPower(uint _tokenId) public view returns(uint) {
        return owls[_tokenId].power;
    }

    function getMyOwlPower() public view returns(uint) {
        uint myOwlPower = 0;
        uint amount = 0;

        for(uint i = 1; i < owlId; i++) {
            amount = balanceOf(msg.sender, i);
            myOwlPower = myOwlPower + (owls[i].power * amount);
        }

        return myOwlPower;
    }

    function getMyOwls() public view returns (uint[] memory) {
        uint[] memory myOwls = new uint[](owlId - 1);

        for(uint i = 1; i < owlId; i++) {
            myOwls[i - 1] = balanceOf(msg.sender, i);
        }

        return myOwls;
    }

    function setRewardFeather(address _rewardFeather) public serviceAddressOnly() {
        rewardFeather = _rewardFeather;
    }

    function setTransferLock(address _owner, uint _time) public {
        require(rewardFeather == msg.sender, "Caller is not RewardFeather.");

        transferLock[_owner] = _time;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        require(id == 0 || transferLock[from] < block.timestamp, "From address can't transfer for 24 hours after reward.");
        
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        require(transferLock[from] < block.timestamp, "From address can't transfer for 24 hours after reward.");
        
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}