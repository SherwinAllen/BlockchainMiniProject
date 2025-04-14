const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CredentialVerifier", function () {
  let credentialVerifier;
  let owner;
  let institution;
  let student;
  let institutionAdmin;

  beforeEach(async function () {
    [owner, institution, student, institutionAdmin] = await ethers.getSigners();
    
    const CredentialVerifier = await ethers.getContractFactory("CredentialVerifier");
    credentialVerifier = await CredentialVerifier.deploy();
  });

  describe("Institution Management", function () {
    it("Should register a new institution", async function () {
      await credentialVerifier.registerInstitution(
        institution.address,
        "Test University",
        "https://testuniversity.edu",
        institutionAdmin.address
      );

      const registeredInstitution = await credentialVerifier.institutions(institution.address);
      expect(registeredInstitution.name).to.equal("Test University");
      expect(registeredInstitution.website).to.equal("https://testuniversity.edu");
      expect(registeredInstitution.isActive).to.equal(true);
      expect(registeredInstitution.admin).to.equal(institutionAdmin.address);
    });

    it("Should deactivate an institution", async function () {
      await credentialVerifier.registerInstitution(
        institution.address,
        "Test University",
        "https://testuniversity.edu",
        institutionAdmin.address
      );

      await credentialVerifier.deactivateInstitution(institution.address);
      
      const registeredInstitution = await credentialVerifier.institutions(institution.address);
      expect(registeredInstitution.isActive).to.equal(false);
    });

    it("Should reactivate an institution", async function () {
      await credentialVerifier.registerInstitution(
        institution.address,
        "Test University",
        "https://testuniversity.edu",
        institutionAdmin.address
      );

      await credentialVerifier.deactivateInstitution(institution.address);
      await credentialVerifier.reactivateInstitution(institution.address);
      
      const registeredInstitution = await credentialVerifier.institutions(institution.address);
      expect(registeredInstitution.isActive).to.equal(true);
    });
  });

  describe("Credential Management", function () {
    beforeEach(async function () {
      await credentialVerifier.registerInstitution(
        institution.address,
        "Test University",
        "https://testuniversity.edu",
        institutionAdmin.address
      );
    });

    it("Should issue a new credential", async function () {
      await credentialVerifier.connect(institution).issueCredential(
        "CRED123",
        "John Doe",
        "Bachelor of Science",
        "2023-05-15",
        "Graduated with honors"
      );

      const credentialId = ethers.solidityPackedKeccak256(
        ["string", "address"],
        ["CRED123", institution.address]
      );

      const credential = await credentialVerifier.credentials(credentialId);
      expect(credential.studentName).to.equal("John Doe");
      expect(credential.credentialName).to.equal("Bachelor of Science");
      expect(credential.isRevoked).to.equal(false);
    });

    it("Should revoke a credential", async function () {
      const tx = await credentialVerifier.connect(institution).issueCredential(
        "CRED123",
        "John Doe",
        "Bachelor of Science",
        "2023-05-15",
        "Graduated with honors"
      );

      const receipt = await tx.wait();
      const event = receipt.logs.find(log => {
        try {
          const parsedLog = credentialVerifier.interface.parseLog({
            topics: log.topics,
            data: log.data
          });
          return parsedLog && parsedLog.name === "CredentialIssued";
        } catch (e) {
          return false;
        }
      });
      
      const parsedLog = credentialVerifier.interface.parseLog({
        topics: event.topics,
        data: event.data
      });
      
      const credentialId = parsedLog.args[0];

      await credentialVerifier.connect(institution).revokeCredential(credentialId);
      
      const credential = await credentialVerifier.credentials(credentialId);
      expect(credential.isRevoked).to.equal(true);
    });

    it("Should verify a credential", async function () {
      const tx = await credentialVerifier.connect(institution).issueCredential(
        "CRED123",
        "John Doe",
        "Bachelor of Science",
        "2023-05-15",
        "Graduated with honors"
      );

      const receipt = await tx.wait();
      const event = receipt.logs.find(log => {
        try {
          const parsedLog = credentialVerifier.interface.parseLog({
            topics: log.topics,
            data: log.data
          });
          return parsedLog && parsedLog.name === "CredentialIssued";
        } catch (e) {
          return false;
        }
      });
      
      const parsedLog = credentialVerifier.interface.parseLog({
        topics: event.topics,
        data: event.data
      });
      
      const credentialId = parsedLog.args[0];

      const [studentName, credentialName, issueDate, institutionName, isValid] = 
        await credentialVerifier.verifyCredential(credentialId);
      
      expect(studentName).to.equal("John Doe");
      expect(credentialName).to.equal("Bachelor of Science");
      expect(institutionName).to.equal("Test University");
      expect(isValid).to.equal(true);
    });
  });
});