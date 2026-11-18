// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal interface of the SPACE ID Agent ID registry (ERC-721, soulbound).
///         Registry on BNB Chain mainnet: 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F
interface IAgentIDRegistry {
    function balanceOf(address owner) external view returns (uint256);
}

/// @title AgentProof — Proof-of-Agent reputation registry for Agent ID holders
/// @notice AgentProof is an on-chain reputation layer for the AI-agent economy.
///         Only wallets that hold a Binance Agent ID (a soulbound ".ai" name issued
///         through the SPACE ID Agent ID registry) can use it:
///
///           1. register an agent card (a URI pointing to the agent's public
///              capability card / profile),
///           2. check in once per day to build a public proof-of-presence streak,
///           3. endorse other registered agents for a skill tag, building a
///              peer-to-peer trust graph between verified agents.
///
///         Reputation points are a non-transferable on-chain score only. They are
///         NOT a token, cannot be transferred or withdrawn, and have no monetary
///         value. This contract is non-payable by design: it can never receive,
///         hold, or move user funds.
///
/// @dev Owner permissions (disclosed, intentionally minimal):
///        - setPaused(bool): pause/unpause state-changing functions in an emergency.
///        - transferOwnership(address): hand ownership to another address.
///      The owner CANNOT mint or move points arbitrarily, cannot touch user data
///      other than through the public functions above, and cannot withdraw funds
///      (the contract holds none and has no payable entry points).
contract AgentProof {
    // ------------------------------------------------------------------ config

    /// @notice The Agent ID registry this contract gates on (immutable).
    IAgentIDRegistry public immutable agentIdRegistry;

    /// @notice Contract owner (see permission disclosure in the contract docstring).
    address public owner;

    /// @notice Emergency pause for state-changing functions.
    bool public paused;

    uint256 public constant CHECKIN_BASE_POINTS = 10;
    uint256 public constant STREAK_BONUS_CAP = 20;
    uint256 public constant ENDORSEMENT_POINTS = 5;

    // ------------------------------------------------------------------- state

    struct Profile {
        bool registered;
        uint64 registeredAt;
        uint64 lastCheckInDay; // day index = block.timestamp / 1 days
        uint32 currentStreak;
        uint32 bestStreak;
        uint32 totalCheckIns;
        uint256 points;
        string cardURI;
    }

    mapping(address => Profile) private _profiles;

    /// @notice endorser => agent => tag => already endorsed (one endorsement per pair+tag)
    mapping(address => mapping(address => mapping(bytes32 => bool))) public hasEndorsed;

    /// @notice agent => tag => number of endorsements received for that tag
    mapping(address => mapping(bytes32 => uint256)) public endorsementCountByTag;

    /// @notice agent => total endorsements received across all tags
    mapping(address => uint256) public totalEndorsementsReceived;

    uint256 public totalAgents;
    uint256 public totalCheckIns;
    uint256 public totalEndorsements;

    // ------------------------------------------------------------------ events

    event Registered(address indexed agent, string cardURI);
    event CardUpdated(address indexed agent, string cardURI);
    event CheckedIn(address indexed agent, uint64 day, uint32 streak, uint256 points);
    event Endorsed(address indexed endorser, address indexed agent, bytes32 indexed tag);
    event PausedSet(bool paused);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --------------------------------------------------------------- modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, "AgentProof: not owner");
        _;
    }

    modifier notPaused() {
        require(!paused, "AgentProof: paused");
        _;
    }

    modifier onlyAgentIdHolder() {
        require(agentIdRegistry.balanceOf(msg.sender) > 0, "AgentProof: no Agent ID");
        _;
    }

    // -------------------------------------------------------------- constructor

    constructor(address agentIdRegistry_) {
        require(agentIdRegistry_ != address(0), "AgentProof: zero registry");
        agentIdRegistry = IAgentIDRegistry(agentIdRegistry_);
        owner = msg.sender;
    }

    // ------------------------------------------------------------- core logic

    /// @notice True if `account` currently holds an Agent ID.
    function hasAgentID(address account) external view returns (bool) {
        return agentIdRegistry.balanceOf(account) > 0;
    }

    /// @notice Register (or update) your agent card. Agent ID holders only.
    /// @param cardURI URI of the agent's public capability card (web page or IPFS JSON).
    function register(string calldata cardURI) external onlyAgentIdHolder notPaused {
        Profile storage p = _profiles[msg.sender];
        if (!p.registered) {
            p.registered = true;
            p.registeredAt = uint64(block.timestamp);
            totalAgents += 1;
            emit Registered(msg.sender, cardURI);
        } else {
            emit CardUpdated(msg.sender, cardURI);
        }
        p.cardURI = cardURI;
    }

    /// @notice Daily check-in. Builds your streak and earns reputation points.
    ///         First check-in auto-registers the agent (empty card URI).
    ///         Points = 10 base + streak bonus (streak length, capped at +20).
    function checkIn() external onlyAgentIdHolder notPaused {
        Profile storage p = _profiles[msg.sender];
        if (!p.registered) {
            p.registered = true;
            p.registeredAt = uint64(block.timestamp);
            totalAgents += 1;
            emit Registered(msg.sender, "");
        }

        uint64 today = uint64(block.timestamp / 1 days);
        require(p.lastCheckInDay < today, "AgentProof: already checked in today");

        if (p.lastCheckInDay == today - 1) {
            p.currentStreak += 1;
        } else {
            p.currentStreak = 1;
        }
        if (p.currentStreak > p.bestStreak) {
            p.bestStreak = p.currentStreak;
        }
        p.lastCheckInDay = today;
        p.totalCheckIns += 1;
        totalCheckIns += 1;

        uint256 bonus = p.currentStreak;
        if (bonus > STREAK_BONUS_CAP) bonus = STREAK_BONUS_CAP;
        uint256 earned = CHECKIN_BASE_POINTS + bonus;
        p.points += earned;

        emit CheckedIn(msg.sender, today, p.currentStreak, p.points);
    }

    /// @notice Endorse another registered agent for a skill tag.
    ///         One endorsement per (endorser, agent, tag). No self-endorsements.
    ///         The endorsed agent earns +5 reputation points.
    /// @param agent The registered agent being endorsed (must still hold an Agent ID).
    /// @param tag   Skill tag as bytes32, e.g. keccak256("trading").
    function endorse(address agent, bytes32 tag) external onlyAgentIdHolder notPaused {
        require(agent != msg.sender, "AgentProof: self endorsement");
        require(tag != bytes32(0), "AgentProof: empty tag");
        require(_profiles[agent].registered, "AgentProof: agent not registered");
        require(agentIdRegistry.balanceOf(agent) > 0, "AgentProof: target has no Agent ID");
        require(!hasEndorsed[msg.sender][agent][tag], "AgentProof: already endorsed");

        hasEndorsed[msg.sender][agent][tag] = true;
        endorsementCountByTag[agent][tag] += 1;
        totalEndorsementsReceived[agent] += 1;
        totalEndorsements += 1;
        _profiles[agent].points += ENDORSEMENT_POINTS;

        emit Endorsed(msg.sender, agent, tag);
    }

    // ------------------------------------------------------------------- views

    function getProfile(address agent)
        external
        view
        returns (
            bool registered,
            uint64 registeredAt,
            uint64 lastCheckInDay,
            uint32 currentStreak,
            uint32 bestStreak,
            uint32 totalCheckInsCount,
            uint256 points,
            string memory cardURI
        )
    {
        Profile storage p = _profiles[agent];
        return (
            p.registered,
            p.registeredAt,
            p.lastCheckInDay,
            p.currentStreak,
            p.bestStreak,
            p.totalCheckIns,
            p.points,
            p.cardURI
        );
    }

    /// @notice True if `account` has already checked in for the current UTC day.
    function checkedInToday(address account) external view returns (bool) {
        return _profiles[account].registered
            && _profiles[account].lastCheckInDay == uint64(block.timestamp / 1 days);
    }

    // ------------------------------------------------------------ owner (admin)

    /// @notice Pause or unpause state-changing functions (emergency only).
    function setPaused(bool paused_) external onlyOwner {
        paused = paused_;
        emit PausedSet(paused_);
    }

    /// @notice Transfer contract ownership to a new address.
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "AgentProof: zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
