// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(uint256 currientBalance, uint256 numPlayers, uint256 raffleState);

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
// import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

/**
 * @title Sample Raffle Contract
 * @author gopak-Barvinok
 * @notice This contract is for creating an untemperable decentralized smart contract
 * @dev This implements Chainlink VRF v2 and Chainlink Keepers
*/



contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {

    enum RaffleState {OPEN, CALCULATING}

    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint256 private immutable i_entranceFee;
    uint256 immutable i_interval;
    uint256 private s_lastTimeStamp;
    uint64 private immutable i_subscriptionID;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2, 
        uint256 entranceFee, 
        bytes32 gasLane, 
        uint64 subscriptionId, 
        uint32 callbackGasLimit,
        uint256 interval) 
    VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionID = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_interval = interval;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    /**
     * @dev
     */
    function checkUpkeep(bytes memory) public view override returns(bool upkeepNeeded, bytes memory) {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(bytes calldata) public override {
        
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance, 
                s_players.length, 
                uint256(s_raffleState
            ));
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, 
            i_subscriptionID, 
            REQUEST_CONFIRMATIONS, 
            i_callbackGasLimit, 
            NUM_WORDS);
        emit RequestedRaffleWinner(requestId);        
    }

    function enterRaffle() public payable {
        if(msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__NotOpen();
        }
        // Добавляем обязательно payable
        s_players.push(payable(msg.sender)); 
        emit RaffleEnter(msg.sender);
    }

    function getEntranceFee() public view returns(uint256){
        return i_entranceFee;
    }

    function fulfillRandomWords(uint256 /* requestId */, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0); 
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if(!success){
            revert Raffle__TransferFailed();
        } 
        emit WinnerPicked(recentWinner);
    }

    function getPlayer(uint256 index) public view returns(address){
        return s_players[index];
    }

    function getRecentWinner() public view returns(address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns(uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns(uint256){
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns(uint256){
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns(uint256){
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns(uint256) {
        return i_interval;
    }
}