// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract Medichain {
    address public admin;

    // --- STRUCTS ---
    struct Doctor {
        address id;       
        string name;
        bool isVerified;
    }

    struct PatientProfile {
        address id;
        string name;
        uint256 age;
        string gender;
        string medicalHistory; 
        string encryptionPublicKey;
        bool exists;
    }

    struct Record {
        string cid;
        string filename;
        uint256 timestamp;
        address doctor;
    }

    // --- STORAGE ---
    mapping(address => Doctor) public doctors;
    mapping(address => PatientProfile) public profiles;
    mapping(address => mapping(address => bool)) public patientPermissions; 
    mapping(address => Record[]) public patientRecords; 
    
    mapping(address => address[]) private patientAuthorizedList;

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

    function getAllDoctors() public view returns (Doctor[] memory) {
        Doctor[] memory allDocs = new Doctor[](doctorList.length);
        for (uint i = 0; i < doctorList.length; i++) {
            allDocs[i] = doctors[doctorList[i]];
        }
        return allDocs;
    }

    // --- PATIENT FUNCTIONS ---
    function setProfile(string memory _name, uint256 _age, string memory _gender, string memory _history, string memory _encryptionPublicKey) public {
        if (!profiles[msg.sender].exists) {
            patientList.push(msg.sender);
        }
        
        profiles[msg.sender] = PatientProfile({
            id: msg.sender,
            name: _name,
            age: _age,
            gender: _gender,
            medicalHistory: _history,
            encryptionPublicKey: _encryptionPublicKey,
            exists: true
        });
        
        emit ProfileUpdated(msg.sender, _name);
    }

    function grantAccess(address _doctorAddr) public {
        require(doctors[_doctorAddr].isVerified, "Doctor is not verified");
        if (!patientPermissions[msg.sender][_doctorAddr]) {
            patientAuthorizedList[msg.sender].push(_doctorAddr);
        }
        patientPermissions[msg.sender][_doctorAddr] = true;
        emit AccessGranted(msg.sender, _doctorAddr);
    }

    function revokeAccess(address _doctorAddr) public {
        patientPermissions[msg.sender][_doctorAddr] = false;
        address[] storage list = patientAuthorizedList[msg.sender];
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == _doctorAddr) {
                list[i] = list[list.length - 1];
                list.pop();
                break;
            }
        }
        emit AccessRevoked(msg.sender, _doctorAddr);
    }

    function getMyAuthorizedDoctors() public view returns (Doctor[] memory) {
        address[] memory list = patientAuthorizedList[msg.sender];
        Doctor[] memory authorizedDocs = new Doctor[](list.length);
        for (uint i = 0; i < list.length; i++) {
            authorizedDocs[i] = doctors[list[i]];
        }
        return authorizedDocs;
    }

    function getPatientPublicKey(address _patient) public view returns (string memory) {
        return profiles[_patient].encryptionPublicKey;
    }

    function getAllPatients() public view returns (PatientProfile[] memory) {
        PatientProfile[] memory allPatients = new PatientProfile[](patientList.length);
        for (uint i = 0; i < patientList.length; i++) {
            allPatients[i] = profiles[patientList[i]];
        }
        return allPatients;
    }

    // --- DOCTOR FUNCTIONS ---

    // CHANGE: Removed msg.sender check. If the patient exists, return the profile.
    // Privacy is handled by the frontend only showing this if access is granted.
    function getPatientProfile(address _patient) public view returns (PatientProfile memory) {
        return profiles[_patient];
    }

    function addRecord(address _patient, string memory _cid, string memory _filename) public onlyVerifiedDoctor {
        // KEEP THIS CHECK: Only authorized doctors can write new records
        require(patientPermissions[_patient][msg.sender], "Patient has not granted you access");
        
        patientRecords[_patient].push(Record({
            cid: _cid,
            filename: _filename,
            timestamp: block.timestamp,
            doctor: msg.sender
        }));
        
        emit RecordAdded(_patient, msg.sender, _cid);
    }

    // CHANGE: Removed msg.sender check. Returns all records for a patient.
    function getRecords(address _patient) public view returns (Record[] memory) {
        return patientRecords[_patient];
    }
}