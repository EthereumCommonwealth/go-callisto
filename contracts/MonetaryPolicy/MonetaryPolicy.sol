// SPDX-License-Identifier: GPL-3.0-only
// author: Upaut (CallistoDAO)

pragma solidity ^0.8.16;

contract MonetaryPolicy {

    uint256 public MinerReward; // Miner reward per block
    uint256 public TreasuryReward; // Treasury reward per block  
    uint256 public StakeReward; // ColdStacking contract reward per block
    uint256 public ReserveReward; // Reserved, in case we need some additional reward type per block

    address public TreasuryAddress = 0x74682Fc32007aF0b6118F259cBe7bCCC21641600; // Treasury contract address.
    address public StakeAddress = 0x08A7c8be47773546DC5E173d67B0c38AfFfa4b84;    // ColdStaking contract address.
    address public ReserveAddress = 0x0000000000000000000000000000000000000000;  // Reserved address.

    address public GovernanceDAO = 0x810059e1406dEDAFd1BdCa4E0137CbA306c0Ce36;   // DAO voting address.
    address public CallistoNetwork = 0xA9389DB4610175CaC4Fad32670A5189A89f874B5; // Second party (Dexaran) voting address.

    uint256 public TimeVoice = 45 days; // Time required for the second voter to cast their vote. After this period proposal CAN be accepted/declined based on the decision of the first voter.
    uint256 public TimeEnd = 60 days;   // Lifetime of a proposal.

    struct Data {
        uint256 timeVoice;    // Deadline for the second voter. After this period the vote will be accepted/declined based on the decision of the first voter.
        uint256 timeEnd;      // Deadline for this proposal.
        bool governanceDAO;   // DAO vote.
        bool callistoNetwork; // Second party (Dexaran) vote.
    }

    mapping(bytes32 => Data) public proposals; // Temporary storage for active proposals indexed by hashes.

    event Proposal(address indexed owner, bytes32 indexed hash, bool indexed voice); // New proposal event.

    modifier onlyGovernanceDAO() {
        require(msg.sender == GovernanceDAO, "Only GovernanceDAO");
        _;
    }

    modifier onlyTreasuryRecipients() {
        require((msg.sender == CallistoNetwork) || (msg.sender == GovernanceDAO), "Only treasury recipient");
        _;
    }


    // sets rewards per block (all values must be updated in 1 TX)
    function setRewards(uint256 _minerReward, uint256 _treasuryReward, uint256 _stakeReward, uint256 _reserveReward, bool _voice) external onlyTreasuryRecipients {
        bytes4 _selector = this.setRewards.selector;
        bytes32 _hash = keccak256(abi.encodePacked(_selector, _minerReward, _treasuryReward, _stakeReward, _reserveReward)); // proposal hash
        if(_consensus(_hash, _voice)){ // proposal accepted
            MinerReward = _minerReward;
            TreasuryReward = _treasuryReward;
            StakeReward = _stakeReward;
            ReserveReward = _reserveReward;            
        }
        emit Proposal(msg.sender, _hash, _voice); // proposal event for logging
    }

    // function sets new Treasury Address
    function setTreasuryAddress(address _treasuryAddress, bool _voice) external onlyTreasuryRecipients {
        bytes4 _selector = this.setTreasuryAddress.selector;
        bytes32 _hash = keccak256(abi.encodePacked(_selector, _treasuryAddress)); // proposal hash
        if(_consensus(_hash, _voice)){ // proposal accepted
            TreasuryAddress = _treasuryAddress;
        }
        emit Proposal(msg.sender, _hash, _voice); // proposal event for logging
    }

    // function sets new ColdStacking address
    function setStakeAddress(address _stakeAddress) external onlyGovernanceDAO {
        StakeAddress = _stakeAddress;
    }

    // function sets new "reserved for future" address
    function setReserveAddress(address _reserveAddress) external onlyGovernanceDAO {
        ReserveAddress = _reserveAddress;
    }

    // Updates time limits for future proposals
    function setPeriods(uint256 _timeVoice, uint256 _timeEnd, bool _voice) external onlyTreasuryRecipients {
        require((_timeVoice > 0) && (_timeEnd > _timeVoice));
        bytes4 _selector = this.setPeriods.selector;
        bytes32 _hash = keccak256(abi.encodePacked(_selector, _timeVoice, _timeEnd)); // proposal hash
        if(_consensus(_hash, _voice)){ // proposal accepted
            TimeVoice = _timeVoice;
            TimeEnd = _timeEnd;
        }
        emit Proposal(msg.sender, _hash, _voice); // proposal event for logging
    }

    // Updates GovernanceDAO or Second party (Dexaran) owner address. Sender must be current owner and can change only it's own address.
    function setNewOwners(address _newOwner) external onlyTreasuryRecipients {
        require((_newOwner != GovernanceDAO) && (_newOwner != CallistoNetwork));
        (GovernanceDAO, CallistoNetwork) = msg.sender == GovernanceDAO ? (_newOwner, CallistoNetwork) : (GovernanceDAO, _newOwner);
    }

    // Updates GovernanceDAO or Second party (Dexaran) owner address. Owners can update address of each other if other party did not decline such proposal.
    function resetOwner(address _owner, address _newOwner, bool _voice) external onlyTreasuryRecipients {
        require((_owner == GovernanceDAO) || (_owner == CallistoNetwork));
        require((_newOwner != GovernanceDAO) && (_newOwner != CallistoNetwork));

        bytes4 _selector = this.resetOwner.selector;
        bytes32 _hash = keccak256(abi.encodePacked(_selector, _owner, _newOwner)); // proposal hash
        if(_consensus(_hash, _voice)){ // proposal accepted
            (GovernanceDAO, CallistoNetwork) = _owner == GovernanceDAO ? (_newOwner, CallistoNetwork) : (GovernanceDAO, _newOwner);
        }
        emit Proposal(msg.sender, _hash, _voice); // proposal event for logging
    }

    // This function calculates consensus, returns true if the proposal is accepted.
    function _consensus(bytes32 _hash, bool _voice) private returns (bool) {
        if (proposals[_hash].timeEnd < block.timestamp){ // proposal expired or never existed before, let's create it
            delete proposals[_hash];
            if (!_voice) return (false); // do nothing if we are declining proposal
            proposals[_hash].timeVoice = block.timestamp + TimeVoice; // time limit for second voter
            proposals[_hash].timeEnd = block.timestamp + TimeEnd; // proposal time limit
            (proposals[_hash].governanceDAO, proposals[_hash].callistoNetwork) = msg.sender == GovernanceDAO ? (true, false) : (false, true);
        } else if (proposals[_hash].timeVoice < block.timestamp) { // time limit for second voter expired, first voter can accept proposal without second party
            delete proposals[_hash];
            return (true);
        } else { // still waiting for second voter
            if (!_voice) { // proposal declined
                delete proposals[_hash];
            } else {
                (proposals[_hash].governanceDAO, proposals[_hash].callistoNetwork) = msg.sender == GovernanceDAO ? (true, proposals[_hash].callistoNetwork) : (proposals[_hash].governanceDAO, true); // votes
                if ((proposals[_hash].governanceDAO) && (proposals[_hash].callistoNetwork)) { // proposal accepted by both parties
                    delete proposals[_hash]; // clean up
                    return (true);
                }
            }
        }

        return (false);
    }
}
