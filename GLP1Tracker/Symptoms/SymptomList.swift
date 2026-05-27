import Foundation

enum SymptomCategory: String, CaseIterable {
    case common
    case lessCommon
    case rare
    case situational
}

enum WarningLevel {
    case normal
    case consultDoctor
    case stopDrug
}

struct Symptom: Identifiable {
    let id: String
    let name: String
    let category: SymptomCategory
    let warningLevel: WarningLevel
    let tracksSeverity: Bool
    let healthKitTypeId: String?

    init(id: String,
         name: String,
         category: SymptomCategory,
         warningLevel: WarningLevel = .normal,
         tracksSeverity: Bool = true,
         healthKitTypeId: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.warningLevel = warningLevel
        self.tracksSeverity = tracksSeverity
        self.healthKitTypeId = healthKitTypeId
    }
}

enum SymptomList {
    static let all: [Symptom] = [
        // Common
        Symptom(id: "nausea",            name: "Nausea",              category: .common,      healthKitTypeId: "HKCategoryTypeIdentifierNausea"),
        Symptom(id: "vomiting",          name: "Vomiting",            category: .common,      warningLevel: .consultDoctor, healthKitTypeId: "HKCategoryTypeIdentifierVomiting"),
        Symptom(id: "diarrhea",          name: "Diarrhea",            category: .common,      healthKitTypeId: "HKCategoryTypeIdentifierDiarrhea"),
        Symptom(id: "constipation",      name: "Constipation",        category: .common,      healthKitTypeId: "HKCategoryTypeIdentifierConstipation"),
        Symptom(id: "abdominal_pain",    name: "Abdominal Pain",      category: .common,      warningLevel: .consultDoctor, healthKitTypeId: "HKCategoryTypeIdentifierAbdominalCramps"),
        Symptom(id: "fatigue",           name: "Fatigue",             category: .common,      healthKitTypeId: "HKCategoryTypeIdentifierFatigue"),
        Symptom(id: "appetite_decreased",name: "Decreased Appetite",  category: .common,      tracksSeverity: false, healthKitTypeId: "HKCategoryTypeIdentifierAppetiteChanges"),
        Symptom(id: "headache",          name: "Headache",            category: .common,      healthKitTypeId: "HKCategoryTypeIdentifierHeadache"),

        // Less Common
        Symptom(id: "dizziness",         name: "Dizziness",           category: .lessCommon,  healthKitTypeId: "HKCategoryTypeIdentifierDizziness"),
        Symptom(id: "heartburn",         name: "Heartburn",           category: .lessCommon,  healthKitTypeId: "HKCategoryTypeIdentifierHeartburn"),
        Symptom(id: "indigestion",       name: "Indigestion",         category: .lessCommon,  healthKitTypeId: "HKCategoryTypeIdentifierBloating"),
        Symptom(id: "burping",           name: "Burping",             category: .lessCommon),
        Symptom(id: "bloating",          name: "Bloating",            category: .lessCommon,  healthKitTypeId: "HKCategoryTypeIdentifierBloating"),
        Symptom(id: "dry_mouth",         name: "Dry Mouth",           category: .lessCommon,  tracksSeverity: false),
        Symptom(id: "hair_loss",         name: "Hair Loss",           category: .lessCommon,  tracksSeverity: false),
        Symptom(id: "muscle_loss",       name: "Muscle Loss / Weakness", category: .lessCommon),
        Symptom(id: "mood_changes",      name: "Mood Changes",        category: .lessCommon),
        Symptom(id: "insomnia",          name: "Insomnia",            category: .lessCommon),
        Symptom(id: "palpitations",      name: "Heart Palpitations",  category: .lessCommon,  warningLevel: .consultDoctor, healthKitTypeId: "HKCategoryTypeIdentifierRapidPoundingOrFlutteringHeartbeat"),
        Symptom(id: "hot_flashes",       name: "Hot Flashes / Sweating", category: .lessCommon, healthKitTypeId: "HKCategoryTypeIdentifierHotFlashes"),

        // Rare / Severe
        Symptom(id: "low_blood_sugar",   name: "Low Blood Sugar",     category: .rare,        warningLevel: .consultDoctor),
        Symptom(id: "pancreatitis",      name: "Severe Abdominal Pain (Pancreatitis?)", category: .rare, warningLevel: .stopDrug),
        Symptom(id: "gallbladder",       name: "Gallbladder Issues",  category: .rare,        warningLevel: .stopDrug),
        Symptom(id: "kidney_injury",     name: "Possible Kidney Injury", category: .rare,     warningLevel: .stopDrug),
        Symptom(id: "thyroid_tumor",     name: "Neck Lump / Thyroid Concern", category: .rare, warningLevel: .stopDrug),
        Symptom(id: "allergic_reaction", name: "Allergic Reaction",   category: .rare,        warningLevel: .stopDrug),
        Symptom(id: "vision_changes",    name: "Vision Changes",      category: .rare,        warningLevel: .consultDoctor),

        // Situational
        Symptom(id: "injection_site",    name: "Injection Site Reaction", category: .situational, tracksSeverity: false),
        Symptom(id: "dark_urine",        name: "Dark Urine / Infrequent Urination", category: .situational, warningLevel: .consultDoctor),
        Symptom(id: "infrequent_urination", name: "Infrequent Urination", category: .situational, warningLevel: .consultDoctor),
    ]
}
