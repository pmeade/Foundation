pragma solidity ^0.4.0;
 import "./Foundation.sol";
 
 contract Kingdom {

    struct Ballot {
        mapping (address => bool) Voted;
        mapping (address => uint) Kings;
        address[] KingsArr;
        uint Weight;
        uint Budget;
    }

    address public King;
    Ballot public InProgressBallot;

    mapping (address => bool) Citizens;
    mapping (address => bool) Immigrants;
    
    mapping (address => uint) Balances;
    mapping (address => uint) LockedFunds;

    Foundation public FoundationAddress;

    uint public Supply;
    string public Name;
    uint public Budget;

    uint public RegimeStartBlock;
    uint public RegimePeriod;
    uint constant MinimumPeriod = 10000;
     
     modifier isKing() { 
        require(msg.sender == King);
        _;
     }
     
     modifier isNotKing() {
        require(msg.sender != King);
        _;
     }
     
     modifier isCitizen() {
         require(Citizens[msg.sender] == true);
         _;
     }
     
     modifier isImmigrant() {
         require(Immigrants[msg.sender] == true);
         _;
     }
     
     modifier hasBalance() {
         require(Balances[msg.sender] > 0);
         _;
     }
     
     function Found(address _foundationAddress, string _name, uint _initialSupply, uint _regimePeriod) public returns (bool success){
         // Store the address of the foundation we are using
         FoundationAddress = Foundation(_foundationAddress);
         
         // Validate options
         if (_regimePeriod < MinimumPeriod){
             return false;
         }
         
         // Burn the foundation coins
         if (!FoundationAddress.BurnCoins(_initialSupply)){
             return false;
         }
         
         // Create the initial money supply
         Supply = _initialSupply;
         
         // Set the legal and economic parameters of this Kingdom
         RegimePeriod = _regimePeriod;
         RegimeStartBlock = block.number;
         Name = _name;
         Budget = _initialSupply;
         
         // Founder is the first King
         King = msg.sender;
         
         // Set up the first Ballot
         delete InProgressBallot;
         
         return true;
     }
     
     // If you were a citizen during this regime you can vote on the next regime, but you lock all your funds when you do
     function Delegate(address _king, uint _budget) isCitizen() public returns (bool success) {
         // Make sure they have not Voted
         if (InProgressBallot.Voted[msg.sender]){
             return false;
         }
         
         // Lock the voters funds until after the election
         LockedFunds[msg.sender] = Balances[msg.sender];
         
         // If this is a new candidate then stuff them in the list
         if (InProgressBallot.Kings[_king] == 0){
             InProgressBallot.KingsArr.push(_king);
         }
         
         // Record the vote
         InProgressBallot.Kings[_king] += Balances[msg.sender];
         InProgressBallot.Budget += Balances[msg.sender] * _budget;
         InProgressBallot.Weight += Balances[msg.sender];
         InProgressBallot.Voted[msg.sender] = true;
         
         
         return true;
     }
     
     function UnlockFunds() public returns (bool success) {
         // You can only unlock funds when an election is over and you have not voted in the next one
         if (InProgressBallot.Voted[msg.sender] == true){
             return false;
         }
         
         if (LockedFunds[msg.sender] == 0) {
             return false;
         }
         
         // Restore the funds
         Balances[msg.sender] += LockedFunds[msg.sender];
         LockedFunds[msg.sender] = 0;
         
         // In case they lost their citizenship, it is now restored
         Citizens[msg.sender] = true;
         
         return true;
     }
     
     // Anyone not the king can send funds to whomever they wish
     function SendCoins(address _recipient, uint _amount) public isNotKing() returns (bool success){
         // Make sure the funds exist
         if (Balances[msg.sender] < _amount) {
             return false;
         }
         
         // Transfer the funds
         Balances[_recipient] += _amount;
         Balances[msg.sender] -= _amount;
         
         // If the recpient isn't a citizen they automatically become an imigrant
         if (Citizens[_recipient] == false){
             Immigrants[_recipient] = true;
         }
         
         // If the sender used up all their funds they lose their citizenship for now
         if (Balances[msg.sender] == 0){
             Citizens[msg.sender] = false;
         }
     }
     
     // The king can only send money to citizens.
     function GovernmentSpend(address _recipient, uint _amount) public isKing() returns (bool success) {
         require(Citizens[_recipient] == true);
         require(King != _recipient);
         require(_amount <= Budget);
         
         Balances[_recipient] += _amount;
         Budget -= _amount;
         
         return true;
     }
     
     // At the end of the regime, anyone may call for a regime change
     function RegimeChange() public returns (bool success) {
         // Is it time yet?
         if (RegimeStartBlock + RegimePeriod > block.number) {
             return false;
         }
         
         // Count the voters
         address winner = King;
         uint winningVotes = 0;
         for (uint i = 0; i < InProgressBallot.KingsArr.length; ++i) {
             address pot = InProgressBallot.KingsArr[i];
             if (InProgressBallot.Kings[pot] > winningVotes){
                 winner = pot;
                 winningVotes = InProgressBallot.Kings[pot];
             }
         }
         
         // Crown the king
         King = winner;
         
         // Remove any remaining funds from circulation
         Supply -= Budget;
         
         // Calculate the new Budget.
         Budget = InProgressBallot.Budget / InProgressBallot.Weight;
         
         // Start the Regime
         RegimeStartBlock = block.number;
         
         // Reset the Ballot
         delete InProgressBallot;
         
         return true;
     }
     
     // Let anyone convert fundation coins to Kingdom coins
     function Mint(uint _amount) public returns (bool success) {
      
        // Make sure there are funds
        if (_amount == 0) {
            return false;
        }
        
        // Burn the foundation coins
        if (!FoundationAddress.BurnCoins(_amount)){
            return false;
        }
        
        // Add these coins to the Supply
        Supply += _amount;
        
        // You are now a citizen
        Citizens[msg.sender] = true;
     }
 }