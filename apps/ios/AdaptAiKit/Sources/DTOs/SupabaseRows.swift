import Foundation



// MARK: - Medical ID

public struct MedicalIDRow: Codable, Identifiable, Sendable {
    public let id: String
    public let userId: String
    public var fullName: String
    public var dateOfBirth: String?
    public var bloodType: String?
    public var weight: Double?
    public var height: Double?
    public var allergies: [String]
    public var conditions: [String]
    public var currentMedications: [String]
    public var doctorName: String?
    public var doctorPhone: String?
    public var insuranceProvider: String?
    public var insuranceNumber: String?
    public var organDonor: Bool
    public var notes: String?
    public var photoUrl: String?
    public var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fullName = "full_name"
        case dateOfBirth = "date_of_birth"
        case bloodType = "blood_type"
        case weight, height, allergies, conditions
        case currentMedications = "current_medications"
        case doctorName = "doctor_name"
        case doctorPhone = "doctor_phone"
        case insuranceProvider = "insurance_provider"
        case insuranceNumber = "insurance_number"
        case organDonor = "organ_donor"
        case notes
        case photoUrl = "photo_url"
        case updatedAt = "updated_at"
    }

    public init(id: String, userId: String, fullName: String, dateOfBirth: String? = nil,
                bloodType: String? = nil, weight: Double? = nil, height: Double? = nil,
                allergies: [String] = [], conditions: [String] = [], currentMedications: [String] = [],
                doctorName: String? = nil, doctorPhone: String? = nil,
                insuranceProvider: String? = nil, insuranceNumber: String? = nil,
                organDonor: Bool = false, notes: String? = nil, photoUrl: String? = nil,
                updatedAt: String? = nil) {
        self.id = id
        self.userId = userId
        self.fullName = fullName
        self.dateOfBirth = dateOfBirth
        self.bloodType = bloodType
        self.weight = weight
        self.height = height
        self.allergies = allergies
        self.conditions = conditions
        self.currentMedications = currentMedications
        self.doctorName = doctorName
        self.doctorPhone = doctorPhone
        self.insuranceProvider = insuranceProvider
        self.insuranceNumber = insuranceNumber
        self.organDonor = organDonor
        self.notes = notes
        self.photoUrl = photoUrl
        self.updatedAt = updatedAt
    }
}

public struct MedicalIDUpdate: Codable, Sendable {
    public var fullName: String?
    public var dateOfBirth: String?
    public var bloodType: String?
    public var weight: Double?
    public var height: Double?
    public var allergies: [String]?
    public var conditions: [String]?
    public var currentMedications: [String]?
    public var doctorName: String?
    public var doctorPhone: String?
    public var insuranceProvider: String?
    public var insuranceNumber: String?
    public var organDonor: Bool?
    public var notes: String?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case dateOfBirth = "date_of_birth"
        case bloodType = "blood_type"
        case weight, height, allergies, conditions
        case currentMedications = "current_medications"
        case doctorName = "doctor_name"
        case doctorPhone = "doctor_phone"
        case insuranceProvider = "insurance_provider"
        case insuranceNumber = "insurance_number"
        case organDonor = "organ_donor"
        case notes
    }

    public init(fullName: String? = nil, dateOfBirth: String? = nil, bloodType: String? = nil,
                weight: Double? = nil, height: Double? = nil, allergies: [String]? = nil,
                conditions: [String]? = nil, currentMedications: [String]? = nil,
                doctorName: String? = nil, doctorPhone: String? = nil,
                insuranceProvider: String? = nil, insuranceNumber: String? = nil,
                organDonor: Bool? = nil, notes: String? = nil) {
        self.fullName = fullName
        self.dateOfBirth = dateOfBirth
        self.bloodType = bloodType
        self.weight = weight
        self.height = height
        self.allergies = allergies
        self.conditions = conditions
        self.currentMedications = currentMedications
        self.doctorName = doctorName
        self.doctorPhone = doctorPhone
        self.insuranceProvider = insuranceProvider
        self.insuranceNumber = insuranceNumber
        self.organDonor = organDonor
        self.notes = notes
    }
}
