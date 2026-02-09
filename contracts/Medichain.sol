// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract Medichain {
    address public admin;

    // --- STRUCTS ---
    struct Doctor {
        address id;       // Added address inside struct for easy fetching
        string name;
        bool isVerified;
    }

    struct PatientProfile {
        address id;
        string name;
        uint256 age;
        string gender;
        string medicalHistory; // e.g. "Diabetic, Penicillin Allergy"
        bool exists;
    }

    struct Record {
        string cid;
        string filename;
        uint256 timestamp;
        address doctor;
    }

    // --- STORAGE ---
    // Mappings for fast lookups
    mapping(address => Doctor) public doctors;
    mapping(address => PatientProfile) public profiles;
    mapping(address => mapping(address => bool)) public patientPermissions; 
    mapping(address => Record[]) public patientRecords; 

    // Arrays for "List" views (Admin needs this!)
    address[] public doctorList;
    address[] public patientList;

    // --- EVENTS ---
    event DoctorVerified(address indexed doctorAddress, string name);
    event DoctorRevoked(address indexed doctorAddress);
    event ProfileUpdated(address indexed patient, string name);
    event AccessGranted(address indexed patient, address indexed doctor);
    event AccessRevoked(address indexed patient, address indexed doctor);
    event RecordAdded(address indexed patient, address indexed doctor, string cid);

    constructor() {
        admin = msg.sender;
    }

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
        if (!doctors[_doctorAddr].isVerified) {
            // Only add to list if new
            bool alreadyInList = false;
            for(uint i=0; i<doctorList.length; i++){
                if(doctorList[i] == _doctorAddr) alreadyInList = true;
            }
            if(!alreadyInList) doctorList.push(_doctorAddr);
        }
        doctors[_doctorAddr] = Doctor(_doctorAddr, _name, true);
        emit DoctorVerified(_doctorAddr, _name);
    }

    function revokeDoctor(address _doctorAddr) public onlyAdmin {
        doctors[_doctorAddr].isVerified = false;
        emit DoctorRevoked(_doctorAddr);
    }

    // Helper to get full list for Admin Dashboard
    function getAllDoctors() public view returns (Doctor[] memory) {
        Doctor[] memory allDocs = new Doctor[](doctorList.length);
        for (uint i = 0; i < doctorList.length; i++) {
            allDocs[i] = doctors[doctorList[i]];
        }
        return allDocs;
    }

    // --- PATIENT FUNCTIONS ---
    function setProfile(string memory _name, uint256 _age, string memory _gender, string memory _history) public {
        // If first time, add to patient list
        if (!profiles[msg.sender].exists) {
            patientList.push(msg.sender);
        }
        
        profiles[msg.sender] = PatientProfile({
            id: msg.sender,
            name: _name,
            age: _age,
            gender: _gender,
            medicalHistory: _history,
            exists: true
        });
        
        emit ProfileUpdated(msg.sender, _name);
    }

    function grantAccess(address _doctorAddr) public {
        require(doctors[_doctorAddr].isVerified, "Doctor is not verified");
        patientPermissions[msg.sender][_doctorAddr] = true;
        emit AccessGranted(msg.sender, _doctorAddr);
    }

    function revokeAccess(address _doctorAddr) public {
        patientPermissions[msg.sender][_doctorAddr] = false;
        emit AccessRevoked(msg.sender, _doctorAddr);
    }

    function getAllPatients() public view returns (PatientProfile[] memory) {
        PatientProfile[] memory allPatients = new PatientProfile[](patientList.length);
        for (uint i = 0; i < patientList.length; i++) {
            allPatients[i] = profiles[patientList[i]];
        }
        return allPatients;
    }

    // --- DOCTOR FUNCTIONS ---
    function getPatientProfile(address _patient) public view returns (PatientProfile memory) {
        require(patientPermissions[_patient][msg.sender], "No access to this patient");
        return profiles[_patient];
    }

    function addRecord(address _patient, string memory _cid, string memory _filename) public onlyVerifiedDoctor {
        require(patientPermissions[_patient][msg.sender], "Patient has not granted you access");
        patientRecords[_patient].push(Record({
            cid: _cid,
            filename: _filename,
            timestamp: block.timestamp,
            doctor: msg.sender
        }));
        emit RecordAdded(_patient, msg.sender, _cid);
    }

    function getRecords(address _patient) public view returns (Record[] memory) {
        // Allow patient to see their own, or doctor with permission
        if (msg.sender != _patient) {
             require(patientPermissions[_patient][msg.sender], "No access");
        }
        return patientRecords[_patient];
    }
}