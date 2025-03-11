# **Raffle Smart Contract - Blockchain Lottery System**

## **Overview**
The **Raffle** project is a decentralized smart contract-based lottery system built using **Solidity** and deployed using **Foundry**. This project integrates **Chainlink VRF (Verifiable Random Function)** and **Chainlink Automation** to ensure fair, tamper-proof random winner selection and automated execution of the raffle process.

By leveraging blockchain technology, this project provides a transparent, trustless, and efficient lottery system that eliminates the need for intermediaries.

---

## **Key Features**
- **Automated Execution:** Uses **Chainlink Automation** to trigger the draw function at predetermined intervals.
- **Fair Winner Selection:** Utilizes **Chainlink VRF** for provably random and tamper-proof randomness.
- **Decentralized & Transparent:** Built on Ethereum, ensuring open and verifiable operations.
- **Optimized Development Workflow:** Developed using **Foundry**, a powerful smart contract development framework.
- **Secure & Efficient Testing:** Comprehensive test suite with **Forge** for smart contract testing.
- **Configurable Deployment:** Dynamic network-based configurations for deployment flexibility.

---

## **Technologies & Tools Used**
### **1. Solidity (v0.8.19)**
The smart contract is written in **Solidity**, the leading language for Ethereum-based smart contracts. The contract implements security best practices, including reentrancy protection and gas optimization.

### **2. Chainlink VRF (Verifiable Random Function)**
Ensures a provably fair and tamper-proof randomness mechanism for selecting winners.

- Guarantees randomness cannot be manipulated by the contract owner or participants.
- Uses **Chainlink oracles** to fetch random numbers securely.

### **3. Chainlink Automation**
Automates the execution of the raffle at predetermined time intervals.

- Ensures that the contract runs autonomously without manual intervention.
- Uses **upkeep registration** to schedule and execute draws efficiently.

### **4. Foundry (Forge, Cast, Anvil)**
A modern, fast, and powerful development framework for Solidity.

- **Forge**: Smart contract compilation, testing, and fuzzing.
- **Cast**: CLI tool for interacting with smart contracts.
- **Anvil**: Local Ethereum node for simulation and testing.

### **5. OpenZeppelin Library**
- **OpenZeppelin**: Utilized for secure contract development (e.g., ERC20, Ownable, ReentrancyGuard).

---

## **Project Structure**
```
├── src/
│   ├── Raffle.sol               # Main Raffle contract
│   ├── VRFCoordinatorMock.sol    # Mock for testing Chainlink VRF
│   ├── AutomationMock.sol        # Mock for testing Chainlink Automation
│
├── script/
│   ├── DeployRaffle.s.sol        # Deployment script
│   ├── HelperConfig.s.sol        # Network configuration
│   ├── Interactions.s.sol        # Interaction script
│
├── test/
│   ├── RaffleTest.t.sol          # Unit and integration tests
│
├── foundry.toml                  # Foundry configuration
├── README.md                     # Project documentation
```

---

## **How It Works**
### **1. Entry Mechanism**
- Users enter the raffle by sending ETH to the contract.
- The contract records participants and their entries.

### **2. Chainlink Automation Execution**
- **CheckUpkeep** function verifies whether conditions for drawing the winner are met.
- If the interval has passed and there are participants, the upkeep triggers the draw.

### **3. Winner Selection (Chainlink VRF)**
- The contract requests a random number from **Chainlink VRF**.
- Once the VRF provides the number, the contract selects the winner.
- The winner receives the entire prize pool.

### **4. Resetting the Raffle**
- The contract resets for the next round.
- New entries are accepted, and the cycle repeats.

---

## **Installation & Setup**
### **Prerequisites**
- **Foundry**: Install via `curl -L https://foundry.paradigm.xyz | bash`
- **Ethereum Wallet** (MetaMask) with testnet ETH.

### **Deployment**
1. Install dependencies:
   ```sh
   forge install
   ```
2. Compile the contract:
   ```sh
   forge build
   ```
3. Run tests:
   ```sh
   forge test
   ```
4. Deploy on a testnet:
   ```sh
   forge script script/DeployRaffle.s.sol --rpc-url <TESTNET_RPC> --broadcast
   ```

---

## **Testing & Security**
### **1. Unit & Integration Testing**
- Uses **Forge** for unit tests in `test/RaffleTest.t.sol`.
- Simulated execution of **Chainlink VRF & Automation** with mocks.

### **2. Gas Optimization**
- Efficient storage usage with Solidity best practices.
- Optimized loops and calldata usage.

### **3. Security Measures**
- **Reentrancy Protection**: Uses `nonReentrant` from OpenZeppelin.
- **Access Control**: Ensures only valid automation calls can trigger functions.

---

## **Future Enhancements**
- **Multichain Deployment**: Expanding to Layer 2 solutions like **Arbitrum** or **Optimism**.
- **NFT Rewards**: Instead of ETH, the winner could receive an **ERC721 NFT**.
- **Decentralized Governance**: Implementing **DAO voting** to set ticket prices and draw intervals.

---

## **Author & Contributions**
Developed by **roudra323**, a blockchain developer specializing in smart contract development and Web3 solutions.

For contributions, feel free to submit a PR or open an issue on **GitHub**.
