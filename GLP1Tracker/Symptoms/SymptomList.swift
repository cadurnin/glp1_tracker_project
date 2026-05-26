import Foundation

enum SymptomCategory: String {
    case common, lessCommon, rare, situational
}

enum WarningLevel: String {
    case none, caution, stopDrug
}

struct Symptom: Identifiable {
    let id: String
    let name: String
    let category: SymptomCategory
    let tracksSeverity: Bool
    let warningLevel: WarningLevel
    let warningMessage: String?
}

enum SymptomList {
    static let all: [Symptom] = [
        // MARK: Common
        Symptom(id: "nausea",                 name: "Nausea",                              category: .common,      tracksSeverity: true,  warningLevel: .none,     warningMessage: nil),
        Symptom(id: "vomiting",               name: "Vomiting",                            category: .common,      tracksSeverity: true,  warningLevel: .caution,  warningMessage: "Persistent vomiting may lead to dehydration. Ensure you are staying hydrated."),
        Symptom(id: "diarrhea",               name: "Diarrhea",                            category: .common,      tracksSeverity: true,  warningLevel: .none,     warningMessage: nil),
        Symptom(id: "constipation",           name: "Constipation",                        category: .common,      tracksSeverity: true,  warningLevel: .none,     warningMessage: nil),
        Symptom(id: "indigestion",            name: "Indigestion / Heartburn",             category: .common,      tracksSeverity: true,  warningLevel: .none,     warningMessage: nil),
        Symptom(id: "abdominal_pain_general", name: "Abdominal Pain (general)",            category: .common,      tracksSeverity: true,  warningLevel: .none,     warningMessage: nil),
        Symptom(id: "fatigue",                name: "Fatigue",                             category: .common,      tracksSeverity: true,  warningLevel: .none,     warningMessage: nil),
        Symptom(id: "headache",               name: "Headache",                            category: .common,      tracksSeverity: true,  warningLevel: .none,     warningMessage: nil),
        Symptom(id: "appetite_loss",          name: "Appetite Loss",                       category: .common,      tracksSeverity: true,  warningLevel: .none,     warningMessage: nil),
        Symptom(id: "bloating",               name: "Bloating",                            category: .common,      tracksSeverity: true,  warningLevel: .none,     warningMessage: nil),

        // MARK: Less Common
        Symptom(id: "dark_urine",             name: "Dark Urine",                          category: .lessCommon,  tracksSeverity: true,  warningLevel: .caution,  warningMessage: "Dark urine may indicate dehydration or kidney stress. Monitor closely and increase fluid intake."),
        Symptom(id: "infrequent_urination",   name: "Infrequent Urination",                category: .lessCommon,  tracksSeverity: true,  warningLevel: .caution,  warningMessage: "Reduced urination combined with vomiting or diarrhea may indicate dehydration."),
        Symptom(id: "dizziness",              name: "Dizziness",                           category: .lessCommon,  tracksSeverity: true,  warningLevel: .caution,  warningMessage: "Dizziness may indicate dehydration or low blood sugar. Rest and hydrate."),
        Symptom(id: "acid_reflux",            name: "Acid Reflux",                         category: .lessCommon,  tracksSeverity: true,  warningLevel: .none,     warningMessage: nil),
        Symptom(id: "brain_fog",              name: "Brain Fog",                           category: .lessCommon,  tracksSeverity: true,  warningLevel: .none,     warningMessage: nil),
        Symptom(id: "upper_stomach_pain",     name: "Severe Upper Stomach Pain",           category: .lessCommon,  tracksSeverity: false, warningLevel: .stopDrug, warningMessage: "⚠️ Severe upper stomach pain may indicate acute gallbladder disease. Stop taking your medication and contact your doctor immediately."),
        Symptom(id: "jaundice",               name: "Yellowing of Skin or Eyes (Jaundice)",category: .lessCommon,  tracksSeverity: false, warningLevel: .stopDrug, warningMessage: "⚠️ Jaundice is a serious symptom. Stop taking your medication and seek medical care immediately."),

        // MARK: Rare / Severe
        Symptom(id: "abdominal_pain_radiating", name: "Severe Abdominal Pain Radiating to Back",               category: .rare, tracksSeverity: false, warningLevel: .stopDrug, warningMessage: "🚨 This may indicate acute pancreatitis. Stop taking your medication immediately and go to the emergency room."),
        Symptom(id: "absolute_constipation",    name: "Absolute Constipation (cannot pass stool or gas for days)", category: .rare, tracksSeverity: false, warningLevel: .stopDrug, warningMessage: "🚨 This may indicate a bowel obstruction. Stop taking your medication immediately and seek emergency medical care."),
        Symptom(id: "extreme_bloating",         name: "Extreme Abdominal Bloating or Distension",              category: .rare, tracksSeverity: false, warningLevel: .stopDrug, warningMessage: "🚨 Severe bloating may indicate a serious gastrointestinal complication. Stop taking your medication and seek medical care."),
        Symptom(id: "neck_lump",                name: "New Lump or Swelling in Neck",                          category: .rare, tracksSeverity: false, warningLevel: .stopDrug, warningMessage: "🚨 A new neck lump may indicate a thyroid reaction (FDA Boxed Warning). Stop taking your medication and contact your doctor immediately."),
        Symptom(id: "hoarseness",               name: "Persistent Hoarseness",                                 category: .rare, tracksSeverity: false, warningLevel: .stopDrug, warningMessage: "🚨 Persistent hoarseness combined with neck changes may indicate a thyroid reaction. Contact your doctor."),
        Symptom(id: "trouble_swallowing",       name: "Trouble Swallowing",                                    category: .rare, tracksSeverity: false, warningLevel: .stopDrug, warningMessage: "🚨 Difficulty swallowing may indicate a thyroid reaction (FDA Boxed Warning). Stop taking your medication and contact your doctor."),
        Symptom(id: "shortness_of_breath",      name: "Shortness of Breath",                                   category: .rare, tracksSeverity: false, warningLevel: .stopDrug, warningMessage: "🚨 Shortness of breath requires immediate medical evaluation. Stop taking your medication and seek emergency care if severe."),
        Symptom(id: "rapid_heart_rate",         name: "Noticeably Rapid Heart Rate",                           category: .rare, tracksSeverity: false, warningLevel: .caution,  warningMessage: "⚠️ A significantly elevated heart rate beyond your usual GLP-1 increase (2–4 bpm) should be evaluated by a doctor."),
        Symptom(id: "mood_changes",             name: "Significant Mood Changes",                              category: .rare, tracksSeverity: false, warningLevel: .caution,  warningMessage: "⚠️ Mood changes have been reported with GLP-1 medications. Discuss with your doctor if persistent."),

        // MARK: Situational
        Symptom(id: "hypoglycemia_symptoms",    name: "Dizziness + Sweating + Confusion (together)",           category: .situational, tracksSeverity: true,  warningLevel: .stopDrug, warningMessage: "🚨 These symptoms together may indicate hypoglycemia (low blood sugar). Eat fast-acting sugar immediately and contact your doctor."),
        Symptom(id: "vision_changes",           name: "Any Sudden Vision Changes",                             category: .situational, tracksSeverity: false, warningLevel: .stopDrug, warningMessage: "🚨 Sudden vision changes may indicate diabetic retinopathy complications. Contact your doctor immediately."),
        Symptom(id: "hair_loss",                name: "Hair Loss",                                             category: .situational, tracksSeverity: true,  warningLevel: .none,     warningMessage: nil),
        Symptom(id: "injection_site_reaction",  name: "Injection Site Reaction (redness, swelling)",           category: .situational, tracksSeverity: true,  warningLevel: .caution,  warningMessage: "Monitor injection site reactions. Rotate injection sites and consult your doctor if reactions worsen."),
    ]

    static func symptom(for id: String) -> Symptom? {
        all.first { $0.id == id }
    }
}
