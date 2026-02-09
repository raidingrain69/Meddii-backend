// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract Medichain {
    address public admin;

    // --- STRUCTS ---
    struct Doctor {
        string name;
        bool isVerified;
    }

    struct Record {
        string cid;       // IPFS Hash (pointer to file)
        string filename;  // "X-Ray Knee"
        uint256 timestamp;
        address doctor;   // Who added it
    }

    // --- STORAGE ---
    mapping(address => Doctor) public doctors;
    mapping(address => mapping(address => bool)) public patientPermissions; // Patient -> Doctor -> Access?
    mapping(address => Record[]) public patientRecords; // Patient -> List of Records

    // --- EVENTS ---
    event DoctorVerified(address indexed doctorAddress, string name);
    event AccessGranted(address indexed patient, address indexed doctor);
    event AccessRevoked(address indexed patient, address indexed doctor);
    event RecordAdded(address indexed patient, address indexed doctor, string cid);

    constructor() {
        admin = msg.sender;
    }

    // --- MODIFIERS ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin can perform this action");
        _;
    }

    modifier onlyVerifiedDoctor() {
        require(doctors[msg.sender].isVerified, "You are not a verified doctor");
        _;
    }

    // --- ADMIN FUNCTIONS ---
    function verifyDoctor(address _doctorAddr, string memory _name) public onlyAdmin {
        doctors[_doctorAddr] = Doctor(_name, true);
        emit DoctorVerified(_doctorAddr, _name);
    }

    // --- PATIENT FUNCTIONS ---
    function grantAccess(address _doctorAddr) public {
        require(doctors[_doctorAddr].isVerified, "Doctor is not verified by system");
        patientPermissions[msg.sender][_doctorAddr] = true;
        emit AccessGranted(msg.sender, _doctorAddr);
    }

    function revokeAccess(address _doctorAddr) public {
        patientPermissions[msg.sender][_doctorAddr] = false;
        emit AccessRevoked(msg.sender, _doctorAddr);
    }

    // --- DOCTOR FUNCTIONS ---
    function addRecord(address _patient, string memory _cid, string memory _filename) public onlyVerifiedDoctor {
        // Check if patient granted access
        require(patientPermissions[_patient][msg.sender], "Patient has not granted you access");

        patientRecords[_patient].push(Record({
            cid: _cid,
            filename: _filename,
            timestamp: block.timestamp,
            doctor: msg.sender
        }));

        emit RecordAdded(_patient, msg.sender, _cid);
    }

    // --- VIEW FUNCTIONS ---
    function getRecords(address _patient) public view returns (Record[] memory) {
        return patientRecords[_patient];
    }
}