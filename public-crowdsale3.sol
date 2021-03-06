pragma solidity ^0.4.18;




/**
 * @title NimbusToken Public Crowdsale
 * Thanks to OpenZeppelin
 * https://github.com/OpenZeppelin/zeppelin-solidity
 */




 /**
  * @title SafeMath --------------------------------------------------------------------------------------------------
  * @dev Math operations with safety checks that throw on error
  */
 library SafeMath {
   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     if (a == 0) {
       return 0;
     }
     uint256 c = a * b;
     assert(c / a == b);
     return c;
   }

   function div(uint256 a, uint256 b) internal pure returns (uint256) {
     // assert(b > 0); // Solidity automatically throws when dividing by 0
     uint256 c = a / b;
     // assert(a == b * c + a % b); // There is no case in which this doesn't hold
     return c;
   }

   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
     assert(b <= a);
     return a - b;
   }

   function add(uint256 a, uint256 b) internal pure returns (uint256) {
     uint256 c = a + b;
     assert(c >= a);
     return c;
   }
 }

 /**
  * @title Ownable
  * @dev The Ownable contract has an owner address, and provides basic authorization control
  * functions, this simplifies the implementation of "user permissions".
  */
 contract Ownable {
   address public owner;


   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
   function Ownable() public {
     owner = msg.sender;
   }


   /**
    * @dev Throws if called by any account other than the owner.
    */
   modifier onlyOwner() {
     require(msg.sender == owner);
     _;
   }


   /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
   function transferOwnership(address newOwner) public onlyOwner {
     require(newOwner != address(0));
     OwnershipTransferred(owner, newOwner);
     owner = newOwner;
   }

 }




/**
 * @title Token --------------------------------------------------------------------------------------------------
 * @dev API interface for interacting with the Nimbus Token contract
 */
interface Token {
  function transfer(address _to, uint256 _value) public returns (bool);
  function balanceOf(address _owner) public constant returns (uint256 balance);
}

contract Crowdsale is Ownable {

  using SafeMath for uint256;

  Token public nimtoken;

  uint256 public constant RATE = 900; // Number of tokens per Ether - rate on 2-09-2018 at 2.54.13 AM Pacific src: Coinbase.com
  uint256 public constant CAP = 75000; // Cap in Ether
  uint256 public constant START = 1518130242; // 02/08/2018 @ 10:50pm (UTC)
  uint256 public constant DAYS = 365; // 365 Days

  uint256 public constant initialTokens = 49000000 * 10**18; // Initial number of tokens available
  bool public initialized = false;
  uint256 public raisedAmount = 0;

  event BoughtTokens(address indexed to, uint256 value);

  modifier whenSaleIsActive() {
    // Check if sale is active
    assert(isActive());

    _;
  }

  function Crowdsale(address _tokenAddr) public {
      require(_tokenAddr != 0);
      nimtoken = Token(_tokenAddr);
  }

  function initialize() onlyOwner public {
      require(initialized == false); // Can only be initialized once
      require(tokensAvailable() == initialTokens); // Must have some tokens allocated
      initialized = true;
  }

  function isActive() public constant returns (bool) {
    return (
        initialized == true &&
        now >= START && // Must be after the START date
        now <= START.add(DAYS * 1 days) && // Must be before the end date
        goalReached() == false // Goal must not already be reached
    );
  }

  function goalReached() public constant returns (bool) {
    return (raisedAmount >= CAP * 1 ether);
  }

  function () public payable {
    buyTokens();
  }



  /** --------------------------------------------------------------------------------------------------
  * @dev function that sells available tokens
  */
  function buyTokens() public payable whenSaleIsActive {

    // Calculate tokens to sell
    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(RATE);

    BoughtTokens(msg.sender, tokens);

    // Increment raised amount
    raisedAmount = raisedAmount.add(msg.value);

    // Send tokens to buyer
    nimtoken.transfer(msg.sender, tokens);

    // Send money to owner
    owner.transfer(msg.value);
  }

  /** --------------------------------------------------------------------------------------------------
   * @dev returns the number of tokens allocated to this contract
   */
  function tokensAvailable() public constant returns (uint256) {
    return nimtoken.balanceOf(this);
  }

  /** --------------------------------------------------------------------------------------------------
   * @notice Terminate contract and refund to owner
   */
  function destroy() public onlyOwner {
    // Transfer tokens back to owner
    uint256 remaininbalance = nimtoken.balanceOf(this);
    assert(remaininbalance > 0);
    nimtoken.transfer(owner, remaininbalance);

    // There should be no ether in the contract but just in case
    selfdestruct(owner);
  }

}
