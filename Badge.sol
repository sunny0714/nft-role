// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DaoBadge is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _badgeIdCounter;

    struct BadgeMeta {
        uint256 badgeId;
        uint256 limit;
        string uri;
        string name;
        string details;
    }

    struct Badge {
        bool exists;
        uint256 score;
        address[] doots;
        BadgeMeta meta;
    }

    // badge metas by id
    mapping(uint256 => BadgeMeta) public badgeMetas;
    // number of a badge minted
    mapping(uint256 => uint256) public counts;
    // badge score
    mapping(uint256 => Badge) public badges;


    constructor() ERC721("RaidBrood", "RBD") {
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function safeMintBadge(address to, uint256 badgeMetaId) public onlyOwner {
        // TODO: only owner or current holder
        require(to != msg.sender, "can not send to self");
        require(badgeMetas[badgeMetaId].limit >= counts[badgeMetaId], "at limit");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        counts[badgeMetaId]++;
        badges[tokenId].exists = true;
        badges[tokenId].meta = badgeMetas[badgeMetaId];
    }

    function safeMintBadgeAsBadgeOwner(address to, uint256 badgeId) public {
        // TODO: only owner or current holder
        require(to != msg.sender, "can not send to self");
        require(ownerOf(badgeId) == msg.sender, "not owner");
        BadgeMeta memory badgeMeta = badges[badgeId].meta;
        //uint256 memory badgeId = badges[badgeId]..badgeId;
        require(badgeMetas[badgeMeta.badgeId].limit >= counts[badgeMeta.badgeId], "at limit");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        counts[badgeMeta.badgeId]++;
        badges[tokenId].exists = true;
        badges[tokenId].meta = badgeMetas[badgeMeta.badgeId];
    }

    // badge id 0 is new
    function setBadge(
        uint256 _badgeId,
        uint256 _limit,
        string memory _uri,
        string memory _name,
        string memory _details
    ) public onlyOwner returns(uint256) {
        require(_badgeId == 0 || badgeMetas[_badgeId].badgeId == _badgeId, "not a valid badge");
        if(_badgeId == 0 ){
            _badgeIdCounter.increment(); // reserve 0
            uint256 badgeId = _badgeIdCounter.current();
            badgeMetas[badgeId] = BadgeMeta(badgeId, _limit, _uri, _name, _details);
            return badgeId;
        } else {

            badgeMetas[_badgeId] = BadgeMeta(_badgeId, _limit, _uri, _name, _details);
            return _badgeId;
        }
    }

    function doot(uint256 fromBadgeId, uint256 toBadgeId) public {
        require(ownerOf(fromBadgeId) == msg.sender, "not owner");
        require(ownerOf(toBadgeId) != msg.sender, "cant doot self");
        BadgeMeta memory fromBadgeMeta = badges[fromBadgeId].meta;
        BadgeMeta memory toBadgeMeta = badges[toBadgeId].meta;
        require(fromBadgeMeta.badgeId == toBadgeMeta.badgeId, "not the same badge");
        require(!hasDooted(ownerOf(fromBadgeId), toBadgeId), "already dooted");
        badges[toBadgeId].doots.push(ownerOf(fromBadgeId));
        badges[toBadgeId].score++;
    }

    function removeDoot(uint256 fromBadgeId, uint256 toBadgeId) public {
        require(ownerOf(fromBadgeId) == msg.sender, "not owner");
        BadgeMeta memory fromBadgeMeta = badges[fromBadgeId].meta;
        BadgeMeta memory toBadgeMeta = badges[toBadgeId].meta;
        require(fromBadgeMeta.badgeId == toBadgeMeta.badgeId, "not the same badge");

        require(hasDooted(ownerOf(fromBadgeId), toBadgeId), "not dooted");
        for (uint256 i = 0; i < badges[fromBadgeId].doots.length; i++) {
            if(badges[fromBadgeId].doots[i] == ownerOf(fromBadgeId)){
                delete badges[fromBadgeId].doots[i];
            }
        }
        badges[toBadgeId].score--;
    }

    //

    function hasDooted(address player, uint256 badgeId) public view returns(bool) {
        for (uint256 i = 0; i < badges[badgeId].doots.length; i++) {
            if(badges[badgeId].doots[i] == player){
                return true;
            }
        }
        return false;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override
    {
        if(badges[tokenId].score > 0){
            badges[tokenId].score = 0;
            delete badges[tokenId].doots;
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        if(badges[tokenId].exists == true){
            string memory base = _baseURI();
            return string(abi.encodePacked(base, badgeMetas[badges[tokenId].meta.badgeId].uri));
        } else {
            return super.tokenURI(tokenId);
        }
    }
}