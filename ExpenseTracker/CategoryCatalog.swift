import Foundation

enum TrackingPeriod: String, Codable, CaseIterable {
    case monthly
    case yearly
}

struct Category: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let tracking: TrackingPeriod
    let subcategories: [String]

    init(name: String, icon: String, tracking: TrackingPeriod, subcategories: [String]) {
        self.id = name
        self.name = name
        self.icon = icon
        self.tracking = tracking
        self.subcategories = subcategories
    }
}

enum CategoryCatalog {
    static let all: [Category] = [
        .init(name: "Groceries", icon: "cart", tracking: .monthly, subcategories: ["Supermarket", "Snacks", "Household"]),
        .init(name: "Eating Out", icon: "fork.knife", tracking: .monthly, subcategories: ["Lunch", "Dinner", "Coffee"]),
        .init(name: "Transport", icon: "bus", tracking: .monthly, subcategories: ["Train", "Taxi", "Fuel"]),
        .init(name: "Self Care", icon: "heart", tracking: .monthly, subcategories: ["Skincare", "Haircut", "Gym"]),

        .init(name: "Shopping", icon: "bag", tracking: .yearly, subcategories: ["Clothes", "Shoes", "Other"]),
        .init(name: "Gifts", icon: "gift", tracking: .yearly, subcategories: ["Birthday", "Occasion"]),
        .init(name: "Trips", icon: "airplane", tracking: .yearly, subcategories: ["Flight", "Hotel", "Food"]),
        .init(name: "Electronics", icon: "desktopcomputer", tracking: .yearly, subcategories: ["Accessories", "Gadgets"])
    ]

    static func byId(_ id: String) -> Category? {
        all.first { $0.id == id }
    }
}
