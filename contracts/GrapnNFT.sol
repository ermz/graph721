pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//Is used for safeTransferFrom. To check if recipient address can handle ERC721 tokens
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

//Making my own ERC721.sol file, by working backwards from using the IERC721.sol file
contract GraphNFT is IERC721, Ownable {
	mapping(address => uint256) ownerNFTokenCount;
	mapping(uint256 => address) ownerOfToken;
	mapping(uint256 => address) approvalForToken;
	//ex. of logic is as follows
	//owner => operator1 => true/false
	//owner => operator2 => true/false
	mapping(address => mapping(address => bool)) operatorApprovals;

	modifier onlyTokenOwner(uint _tokenId) public {
		require(ownerOfToken[_tokenId] == msg.sender);
		_;
	}

	function balanceOf(address _owner) external view returns (uint256) {
		return ownerNFTokenCount[_owner];
	}

	function ownerOf(uint _tokenId) external view returns (address) {
		return ownerOfToken[_tokenId];
	}

	function transfer(address _owner, address _newOwner, uint _tokenId) private {
		//The or in this case checks that whoever transferring is either or owner or has been approved by owner
		//The last or section checks if owner has approved, this operator for all its tokens
		//I'm using ownable on the transferFrom and safeTranferFrom functions, not the most effective way though
		require(ownerOfToken[_owner] == msg.sender || approvalForToken[_tokenId] == msg.sender || operatorApprovals[_owner][msg.sender] == true);
		require(_newOwner != address(0));
		ownerNFTokenCount[_owner] -= 1;
		ownerNFTokenCount[_newOwner] += 1;
		ownerOfToken[_tokenId] = _newOwner;
	}

	function transferFrom(address _owner, address _newOwner, uint _tokenId) external payable onlyOwner() {
		transfer(_owner, _newOwner, _tokenId);
	}

	function safeTransferFrom(address _owner, address _newOwner, uint _tokenId, bytes _data) external payable onlyOwner() {
		transfer(_owner, _newOwner, _tokenId);
		if(isContract(_newOwner)) {
			// Call on onERC721Received from IERC721Receiver.sol file
			// Instead of 0x150b7a02, it might be IERC721.onERC721Received.selector
			require(IERC721Receiver(_newOwner).onERC721Received(msg.sender, _newOwner, _tokenId, _data) == 0x150b7a02);
		}
	}

	//Same function as above without _data parameter, changes to require as needed
	function safeTransferFrom(address _owner, address _newOwner, uint _tokenId) external payable onlyOwner() {
		transfer(_owner, _newOwner, _tokenId);
		if(isContract(_newOwner)) {
			// Call on onERC721Received from IERC721Receiver.sol file
			// Instead of 0x150b7a02, it might be IERC721.onERC721Received.selector
			require(IERC721Receiver(_newOwner).onERC721Received(msg.sender, _newOwner, _tokenId, '') == 0x150b7a02);
		}
	}

	function approve(address _approved, uint256 _tokenId) external onlyTokenOwner(_tokenId) {
		approvalForToken[_tokenId] = _approved;
	}

	function getApproved(uint256 _tokenId) external view returns(address) {
		approvalForToken[_tokenId];
	}

	function setApprovalForAll(address _operator, bool _approved) external {
		//owner is msg.sender in this instance
		require(msg.sender != _operator);
		operatorApprovals[msg.sender][_operator] = _approved;
	}

	function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
		operatorApprovals[_owner][_operator];
	}

	function isContract(address _newOwner) private view returns (bool) {
		uint256 size;
		assembly {size := extcodesize(_newOwner) }
		return (size > 0);
	}
}