// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract RockPaperScissors {
    uint256 public startTime = block.timestamp;
    uint256 constant public TIMEOUT = 5 minutes;
    
    address payable player1;
    address payable player2;

    bytes32 private hashOfPlayer1;
    bytes32 private hashOfPlayer2;

    enum Choice {None, Rock, Paper, Scissor}
    
    Choice public choiceOfPlayer1 = Choice.None;
    Choice public choiceOfPlayer2 = Choice.None;

    bool public gameEnded = true;

    mapping(address=>uint) public balances;

    // end the last game when it takes too long
    function endGame() public {
        require(gameEnded == false, "game has already ended");
        require(block.timestamp > startTime + TIMEOUT, "be patient");
        reset();
    }

    // reset when the game ends
    function reset() private{
        startTime = block.timestamp;
        player1 = payable(address(0x0));
        player2 = payable(address(0x0));
        hashOfPlayer1 = 0;
        hashOfPlayer2 = 0;
        choiceOfPlayer1 = Choice.None;
        choiceOfPlayer1 = Choice.None;
        gameEnded = true;
    }


    // join the game
    function join() public payable returns (uint) {
        require(player1 == address(0x0) || player2 == address(0x0), "wait until the last game ends");
        require(msg.value == 1 ether, "please stake 1 ether to join");
        if (player1 == address(0x0)) {
            player1 = payable(msg.sender);
            balances[player1] += 1 ether;
            startTime = block.timestamp;
            gameEnded = false;
            return 1;
        } else if (player2 == address(0x0)) {
            player2 = payable(msg.sender);
            balances[player2] += 1 ether;
            return 2;
        } else return 0;
    }

    // commit the choice (Rock / Paper / Scissor)
    function commit(bytes32 hash) public {
        require(player1 != address(0x0) && player2 != address(0x0), "wait for the other player");
        require((msg.sender == player1 && hashOfPlayer1 == 0) || (msg.sender == player2 && hashOfPlayer2 == 0), "cannot modify your choice");

        if(msg.sender == player1) {
            hashOfPlayer1 = hash;
        } else {
            hashOfPlayer2 = hash;
        }
    }

    // reveal the choice (Rock / Paper / Scissor)
    function reveal(Choice choice, uint nonce) public {
        require(msg.sender == player1 || msg.sender == player2, "not the current players");
        require(hashOfPlayer1 != 0 && hashOfPlayer2 != 0, "someone did not submit hash");
        require(choice != Choice.None, "have to choose either Rock/Paper/Scissor");
        
        if(msg.sender == player1) {
            if (hashOfPlayer1 == keccak256(abi.encode(choice, nonce))) {
                choiceOfPlayer1 = choice;
            }
        } else {
            if (hashOfPlayer2 == keccak256(abi.encode(choice, nonce))) {
                choiceOfPlayer2 = choice;
            }
        }
    }

    // claim the reward
    function claimReward() public {
        require(!gameEnded, "game has ended");
        require(choiceOfPlayer1 != Choice.None && choiceOfPlayer2 != Choice.None, "someone did not reveal their choice");

        // draw
        if (choiceOfPlayer1 == choiceOfPlayer2) {
            balances[player1] += 0 ether;
            balances[player2] += 0 ether;
        } else if (choiceOfPlayer1 == Choice.Rock) {
            if (choiceOfPlayer2 == Choice.Paper) {
                // player1: rock, player2: paper, player2 win
                balances[player1] -= 1 ether;
                balances[player2] += 1 ether;
            } else {
                // player1: rock, player2: scissor, player1 win
                balances[player1] += 1 ether;
                balances[player2] -= 1 ether;
            }
        } else if (choiceOfPlayer1 == Choice.Paper) {
            if (choiceOfPlayer2 == Choice.Scissor) {
                // player1: paper, player2: scissor, player2 win
                balances[player1] -= 1 ether;
                balances[player2] += 1 ether;
            } else {
                // player1: paper, player2: rock, player1 win
                balances[player1] += 1 ether;
                balances[player2] -= 1 ether;
            }
        } else if (choiceOfPlayer1 == Choice.Scissor) {
            if (choiceOfPlayer2 == Choice.Rock) {
                // player1: scissor, player2: rock, player2 win
                balances[player1] -= 1 ether;
                balances[player2] += 1 ether;
            } else {
                // player1: scissor, player2: paper, player1 win
                balances[player1] += 1 ether;
                balances[player2] -= 1 ether;
            }
        }

        reset();
    }

    // allow players to withdraw their money
    function withdraw() public payable{
        require(balances[msg.sender] > 0);

        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        bool transferred = payable(msg.sender).send(amount);
        if (transferred != true) {
            balances[msg.sender] = amount;
        }
    }

}
