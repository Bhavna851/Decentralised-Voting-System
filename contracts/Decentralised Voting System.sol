// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Decentralized Voting System
 * @dev A smart contract for creating and managing decentralized polls and elections
 * @author Blockchain Developer
 */
contract Project {
    
    // Struct to represent a candidate
    struct Candidate {
        string name;
        uint256 voteCount;
    }
    
    // Struct to represent a poll/election
    struct Poll {
        string title;
        address creator;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        Candidate[] candidates;
        mapping(address => bool) hasVoted;
        uint256 totalVotes;
    }
    
    // State variables
    address public admin;
    uint256 public pollCount;
    mapping(uint256 => Poll) public polls;
    mapping(address => bool) public registeredVoters;
    
    // Events
    event PollCreated(uint256 indexed pollId, string title, address indexed creator);
    event VoteCast(uint256 indexed pollId, address indexed voter, uint256 candidateIndex);
    event VoterRegistered(address indexed voter);
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyRegisteredVoter() {
        require(registeredVoters[msg.sender], "You must be a registered voter");
        _;
    }
    
    modifier pollExists(uint256 _pollId) {
        require(_pollId < pollCount, "Poll does not exist");
        _;
    }
    
    modifier pollActive(uint256 _pollId) {
        require(polls[_pollId].isActive, "Poll is not active");
        require(block.timestamp >= polls[_pollId].startTime, "Poll has not started yet");
        require(block.timestamp <= polls[_pollId].endTime, "Poll has ended");
        _;
    }
    
    // Constructor
    constructor() {
        admin = msg.sender;
        pollCount = 0;
    }
    
    /**
     * @dev Core Function 1: Create a new poll
     * @param _title Title of the poll
     * @param _candidateNames Array of candidate names
     * @param _durationInMinutes Duration of the poll in minutes
     */
    function createPoll(
        string memory _title,
        string[] memory _candidateNames,
        uint256 _durationInMinutes
    ) external {
        require(bytes(_title).length > 0, "Poll title cannot be empty");
        require(_candidateNames.length >= 2, "Must have at least 2 candidates");
        require(_durationInMinutes > 0, "Duration must be greater than 0");
        
        uint256 pollId = pollCount++;
        Poll storage newPoll = polls[pollId];
        
        newPoll.title = _title;
        newPoll.creator = msg.sender;
        newPoll.startTime = block.timestamp;
        newPoll.endTime = block.timestamp + (_durationInMinutes * 1 minutes);
        newPoll.isActive = true;
        newPoll.totalVotes = 0;
        
        // Add candidates
        for (uint256 i = 0; i < _candidateNames.length; i++) {
            newPoll.candidates.push(Candidate({
                name: _candidateNames[i],
                voteCount: 0
            }));
        }
        
        emit PollCreated(pollId, _title, msg.sender);
    }
    
    /**
     * @dev Core Function 2: Cast a vote in a poll
     * @param _pollId ID of the poll
     * @param _candidateIndex Index of the candidate to vote for
     */
    function vote(uint256 _pollId, uint256 _candidateIndex) 
        external 
        onlyRegisteredVoter
        pollExists(_pollId)
        pollActive(_pollId)
    {
        require(!polls[_pollId].hasVoted[msg.sender], "You have already voted in this poll");
        require(_candidateIndex < polls[_pollId].candidates.length, "Invalid candidate index");
        
        polls[_pollId].hasVoted[msg.sender] = true;
        polls[_pollId].candidates[_candidateIndex].voteCount++;
        polls[_pollId].totalVotes++;
        
        emit VoteCast(_pollId, msg.sender, _candidateIndex);
    }
    
    /**
     * @dev Core Function 3: Get poll results
     * @param _pollId ID of the poll
     * @return candidateNames Array of candidate names
     * @return voteCounts Array of vote counts for each candidate
     * @return totalVotes Total number of votes cast
     * @return winner Name of the winning candidate
     */
    function getPollResults(uint256 _pollId) 
        external 
        view 
        pollExists(_pollId)
        returns (
            string[] memory candidateNames,
            uint256[] memory voteCounts,
            uint256 totalVotes,
            string memory winner
        )
    {
        uint256 candidateCount = polls[_pollId].candidates.length;
        candidateNames = new string[](candidateCount);
        voteCounts = new uint256[](candidateCount);
        
        uint256 maxVotes = 0;
        uint256 winnerIndex = 0;
        
        for (uint256 i = 0; i < candidateCount; i++) {
            candidateNames[i] = polls[_pollId].candidates[i].name;
            voteCounts[i] = polls[_pollId].candidates[i].voteCount;
            
            if (voteCounts[i] > maxVotes) {
                maxVotes = voteCounts[i];
                winnerIndex = i;
            }
        }
        
        totalVotes = polls[_pollId].totalVotes;
        winner = totalVotes > 0 ? candidateNames[winnerIndex] : "No votes cast";
        
        return (candidateNames, voteCounts, totalVotes, winner);
    }
    
    // Additional helper functions
    
    /**
     * @dev Register a new voter (admin only)
     * @param _voter Address of the voter to register
     */
    function registerVoter(address _voter) external onlyAdmin {
        require(!registeredVoters[_voter], "Voter is already registered");
        registeredVoters[_voter] = true;
        emit VoterRegistered(_voter);
    }
    
    /**
     * @dev Get poll basic information
     * @param _pollId ID of the poll
     */
    function getPollInfo(uint256 _pollId) 
        external 
        view 
        pollExists(_pollId)
        returns (
            string memory title,
            address creator,
            uint256 startTime,
            uint256 endTime,
            bool isActive,
            uint256 candidateCount
        )
    {
        Poll storage poll = polls[_pollId];
        return (
            poll.title,
            poll.creator,
            poll.startTime,
            poll.endTime,
            poll.isActive && block.timestamp <= poll.endTime,
            poll.candidates.length
        );
    }
    
    /**
     * @dev Check if an address has voted in a specific poll
     * @param _pollId ID of the poll
     * @param _voter Address of the voter
     */
    function hasVotedInPoll(uint256 _pollId, address _voter) 
        external 
        view 
        pollExists(_pollId)
        returns (bool)
    {
        return polls[_pollId].hasVoted[_voter];
    }
}
