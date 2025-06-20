// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DecentralizedVotingSystem {
    
    struct Proposal {
        uint id;
        string title;
        string description;
        uint voteCount;
        uint deadline;
        bool executed;
        address proposer;
    }
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    
    address public admin;
    uint public proposalCount;
    mapping(uint => Proposal) public proposals;
    mapping(address => Voter) public voters;
    
    event ProposalCreated(uint indexed proposalId, string title, address indexed proposer, uint deadline);
    event VoteCast(address indexed voter, uint indexed proposalId);
    event VoterRegistered(address indexed voter);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyRegisteredVoter() {
        require(voters[msg.sender].isRegistered, "You must be registered to vote");
        _;
    }
    
    modifier proposalExists(uint _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    // Core Function 1: Create Proposal
    function createProposal(
        string memory _title, 
        string memory _description, 
        uint _votingDurationInHours
    ) external onlyRegisteredVoter {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_votingDurationInHours > 0, "Voting duration must be greater than 0");
        
        proposalCount++;
        uint deadline = block.timestamp + (_votingDurationInHours * 1 hours);
        
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            title: _title,
            description: _description,
            voteCount: 0,
            deadline: deadline,
            executed: false,
            proposer: msg.sender
        });
        
        emit ProposalCreated(proposalCount, _title, msg.sender, deadline);
    }
    
    // Core Function 2: Cast Vote
    function castVote(uint _proposalId) external onlyRegisteredVoter proposalExists(_proposalId) {
        require(!voters[msg.sender].hasVoted, "You have already voted");
        
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        require(!proposal.executed, "Proposal has been executed");
        
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        proposal.voteCount++;
        
        emit VoteCast(msg.sender, _proposalId);
    }
    
    // Core Function 3: Register Voter
    function registerVoter(address _voter) external onlyAdmin {
        require(!voters[_voter].isRegistered, "Voter is already registered");
        require(_voter != address(0), "Invalid address");
        
        voters[_voter].isRegistered = true;
        voters[_voter].hasVoted = false;
        voters[_voter].votedProposalId = 0;
        
        emit VoterRegistered(_voter);
    }
    
    // Utility Functions
    function getProposal(uint _proposalId) external view proposalExists(_proposalId) 
        returns (
            uint id,
            string memory title,
            string memory description,
            uint voteCount,
            uint deadline,
            bool executed,
            address proposer
        ) 
    {
        Proposal memory proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.title,
            proposal.description,
            proposal.voteCount,
            proposal.deadline,
            proposal.executed,
            proposal.proposer
        );
    }
    
    function isVotingActive(uint _proposalId) external view proposalExists(_proposalId) returns (bool) {
        return block.timestamp < proposals[_proposalId].deadline && !proposals[_proposalId].executed;
    }
    
    function getVoterInfo(address _voter) external view returns (bool isRegistered, bool hasVoted, uint votedProposalId) {
        Voter memory voter = voters[_voter];
        return (voter.isRegistered, voter.hasVoted, voter.votedProposalId);
    }
    
    function getAllProposals() external view returns (Proposal[] memory) {
        Proposal[] memory allProposals = new Proposal[](proposalCount);
        for (uint i = 1; i <= proposalCount; i++) {
            allProposals[i - 1] = proposals[i];
        }
        return allProposals;
    }
}
