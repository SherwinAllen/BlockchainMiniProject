// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title CredentialVerifier
 * @dev Manages academic credential verification on the blockchain.
 */
contract CredentialVerifier is Ownable {
    // Global counter for generating nonces.
    uint256 private credentialCounter = 0;

    // Structs
    struct Institution {
        string name;
        string website;
        bool isActive;
        address admin;
    }

    struct Credential {
        string studentName;
        string credentialName;
        string issueDate;
        string additionalDetails;
        bool isRevoked;
        address issuingInstitution;
        uint256 credentialId; // The random nonce used as the Credential Id.
    }

    // Mappings: Credentials are stored keyed by a final hash.
    mapping(address => Institution) public institutions;
    mapping(bytes32 => Credential) public credentials;
    mapping(address => bool) public institutionAdmins;

    // Events
    event InstitutionRegistered(address indexed institutionAddress, string name);
    event InstitutionDeactivated(address indexed institutionAddress);
    event InstitutionReactivated(address indexed institutionAddress);
    
    // Modified event: now emits all input parameters, and an additional Credential Id.
    event CredentialIssued(
        bytes32 indexed credentialHash,
        address indexed institution,
        string studentName,
        string credentialName,
        string issueDate,
        string additionalDetails,
        uint256 credentialId
    );
    event CredentialRevoked(bytes32 indexed credentialHash);

    // Modifiers
    modifier onlyActiveInstitution() {
        require(institutions[msg.sender].isActive, "Institution not active");
        _;
    }

    modifier onlyInstitutionAdmin() {
        require(institutionAdmins[msg.sender], "Not an institution admin");
        _;
    }

    // Constructor: Pass the deployer (msg.sender) to the Ownable constructor
    constructor() Ownable(msg.sender) {}

    // Institution Management Functions

    /**
     * @dev Register a new academic institution.
     */
    function registerInstitution(
        address institutionAddress,
        string memory name,
        string memory website,
        address adminAddress
    ) public onlyOwner {
        require(bytes(institutions[institutionAddress].name).length == 0, "Institution already registered");
        
        institutions[institutionAddress] = Institution({
            name: name,
            website: website,
            isActive: true,
            admin: adminAddress
        });

        institutionAdmins[adminAddress] = true;
        
        emit InstitutionRegistered(institutionAddress, name);
    }

    /**
     * @dev Deactivate an institution.
     */
    function deactivateInstitution(address institutionAddress) public onlyOwner {
        require(institutions[institutionAddress].isActive, "Institution already inactive");
        institutions[institutionAddress].isActive = false;
        emit InstitutionDeactivated(institutionAddress);
    }

    /**
     * @dev Reactivate an institution.
     */
    function reactivateInstitution(address institutionAddress) public onlyOwner {
        require(!institutions[institutionAddress].isActive, "Institution already active");
        institutions[institutionAddress].isActive = true;
        emit InstitutionReactivated(institutionAddress);
    }

    // Credential Management Functions

    /**
     * @dev Issue a new academic credential.
     * The final credential hash is computed as:
     *   finalHash = sha256(abi.encodePacked(studentName, credentialName, msg.sender, nonce))
     * An intermediate random nonce is generated using block.timestamp, msg.sender, and a contract counter.
     * The nonce is stored as the Credential Id and emitted along with all input parameters.
     *
     * @return finalHash The hash used as the key for storing the credential.
     * @return nonce The Credential Id (human-friendly value) equal to the generated nonce.
     */
    function issueCredential(
        string memory studentName,
        string memory credentialName,
        string memory issueDate,
        string memory additionalDetails
    ) public onlyActiveInstitution returns (bytes32 finalHash, uint256 nonce) {
        // Generate a pseudo-random nonce. (Note: Not cryptographically secure)
        nonce = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, credentialCounter))) % 100000000;
        credentialCounter++;  // Increment the counter for uniqueness

        // Compute the final hash based on the four parameters.
        finalHash = sha256(abi.encodePacked(studentName, credentialName, msg.sender, nonce));
        
        require(credentials[finalHash].issuingInstitution == address(0), "Credential already exists for this institution");
        
        credentials[finalHash] = Credential({
            studentName: studentName,
            credentialName: credentialName,
            issueDate: issueDate,
            additionalDetails: additionalDetails,
            isRevoked: false,
            issuingInstitution: msg.sender,
            credentialId: nonce
        });
        
        emit CredentialIssued(finalHash, msg.sender, studentName, credentialName, issueDate, additionalDetails, nonce);
        return (finalHash, nonce);
    }

    /**
     * @dev Revoke an issued credential.
     */
    function revokeCredential(bytes32 credentialHash) public {
        require(
            credentials[credentialHash].issuingInstitution == msg.sender ||
            msg.sender == owner() ||
            (institutions[credentials[credentialHash].issuingInstitution].admin == msg.sender),
            "Not authorized to revoke"
        );
        
        require(!credentials[credentialHash].isRevoked, "Credential already revoked");
        
        credentials[credentialHash].isRevoked = true;
        emit CredentialRevoked(credentialHash);
    }

    /**
     * @dev Verify a credential's validity.
     */
    function verifyCredential(bytes32 credentialHash) public view returns (
        string memory studentName,
        string memory credentialName,
        string memory issueDate,
        string memory institutionName,
        bool isValid
    ) {
        Credential memory cred = credentials[credentialHash];
        require(cred.issuingInstitution != address(0), "Credential does not exist");
        
        return (
            cred.studentName,
            cred.credentialName,
            cred.issueDate,
            institutions[cred.issuingInstitution].name,
            !cred.isRevoked && institutions[cred.issuingInstitution].isActive
        );
    }

    /**
     * @dev Get credential details.
     */
    function getCredentialDetails(bytes32 credentialHash) public view returns (
        string memory studentName,
        string memory credentialName,
        string memory issueDate,
        string memory additionalDetails,
        bool isRevoked,
        address issuingInstitution,
        uint256 credentialId
    ) {
        Credential memory cred = credentials[credentialHash];
        require(cred.issuingInstitution != address(0), "Credential does not exist");
        
        return (
            cred.studentName,
            cred.credentialName,
            cred.issueDate,
            cred.additionalDetails,
            cred.isRevoked,
            cred.issuingInstitution,
            cred.credentialId
        );
    }
}
