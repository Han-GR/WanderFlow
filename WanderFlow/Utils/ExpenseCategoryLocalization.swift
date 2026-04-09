import Foundation

enum ExpenseCategoryLocalization {
    static func name(for rawValue: String) -> String {
        switch rawValue {
        case "餐饮":
            return NSLocalizedString("expense.category.food", comment: "")
        case "住宿":
            return NSLocalizedString("expense.category.stay", comment: "")
        case "交通":
            return NSLocalizedString("expense.category.transport", comment: "")
        case "门票":
            return NSLocalizedString("expense.category.ticket", comment: "")
        case "购物":
            return NSLocalizedString("expense.category.shopping", comment: "")
        case "其他":
            return NSLocalizedString("expense.category.other", comment: "")
        default:
            return rawValue
        }
    }
}

