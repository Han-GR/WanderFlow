import Foundation

struct PasteTripParser {
    struct Draft: Identifiable {
        enum Kind {
            case itinerary
            case expense
        }
        
        var id: UUID = UUID()
        var kind: Kind
        
        var date: Date
        var hasTime: Bool
        var title: String
        
        var amount: Double?
        var currency: String
        var category: String
        
        var stayStartDate: Date?
        var nights: Int?
    }
    
    func parse(text: String) -> [Draft] {
        let normalized = normalize(text: text)
        let segments = splitSegments(normalized)
        
        var currentDay: Date? = nil
        var currentTime: DateComponents? = nil
        var pendingLodgingName: String? = nil
        
        var drafts: [Draft] = []
        
        for raw in segments {
            let seg = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if seg.isEmpty { continue }
            
            if let day = parseDay(from: seg) {
                currentDay = day
                currentTime = nil
                pendingLodgingName = nil
                continue
            }
            
            if currentDay == nil {
                currentDay = Calendar.current.startOfDay(for: Date())
            }
            
            if let time = parseTime(from: seg) {
                currentTime = time
            }
            
            let (amount, currency) = parseAmountAndCurrency(from: seg)
            let nights = parseNights(from: seg)
            let isLodgingHint = containsAny(seg, ["酒店", "住宿", "房费"])
            
            if isLodgingHint, amount == nil, nights == nil {
                pendingLodgingName = cleanedTitle(seg)
                continue
            }
            
            if let amount {
                let category = inferCategory(from: seg, nights: nights, lodgingHint: isLodgingHint)
                let note = inferExpenseTitle(from: seg, pendingLodgingName: pendingLodgingName, category: category)
                let hasTime = currentTime != nil
                let date = combine(day: currentDay!, time: currentTime)
                
                var draft = Draft(
                    kind: .expense,
                    date: date,
                    hasTime: hasTime,
                    title: note,
                    amount: amount,
                    currency: currency,
                    category: category,
                    stayStartDate: nil,
                    nights: nil
                )
                
                if category == "住宿", let n = nights, n > 0 {
                    draft.stayStartDate = currentDay
                    draft.nights = n
                }
                
                drafts.append(draft)
                pendingLodgingName = nil
                continue
            }
            
            if currentTime != nil {
                let title = inferItineraryTitle(from: seg)
                if !title.isEmpty {
                    let date = combine(day: currentDay!, time: currentTime)
                    drafts.append(
                        Draft(
                            kind: .itinerary,
                            date: date,
                            hasTime: true,
                            title: title,
                            amount: nil,
                            currency: "CNY",
                            category: "其他",
                            stayStartDate: nil,
                            nights: nil
                        )
                    )
                }
                pendingLodgingName = nil
                continue
            }
            
            if isLodgingHint {
                pendingLodgingName = cleanedTitle(seg)
            }
        }
        
        return drafts.sorted { $0.date < $1.date }
    }
    
    private func normalize(text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "。", with: "\n")
            .replacingOccurrences(of: "；", with: "\n")
            .replacingOccurrences(of: "，", with: " ")
    }
    
    private func splitSegments(_ text: String) -> [String] {
        text
            .split(separator: "\n")
            .map { String($0) }
            .flatMap { line in
                line.split(separator: "  ").map { String($0) }
            }
    }
    
    private func parseDay(from seg: String) -> Date? {
        let pattern = #"(\d{4})-(\d{2})-(\d{2})"#
        guard let match = seg.range(of: pattern, options: .regularExpression) else { return nil }
        let str = String(seg[match])
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.date(from: str).map { Calendar.current.startOfDay(for: $0) }
    }
    
    private func parseTime(from seg: String) -> DateComponents? {
        let pattern = #"(\d{1,2}):(\d{2})"#
        guard let range = seg.range(of: pattern, options: .regularExpression) else { return nil }
        let str = String(seg[range])
        let parts = str.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return DateComponents(hour: h, minute: m)
    }
    
    private func parseNights(from seg: String) -> Int? {
        let pattern = #"(\d+)\s*晚"#
        guard let range = seg.range(of: pattern, options: .regularExpression) else { return nil }
        let str = String(seg[range])
        let digits = str.filter(\.isNumber)
        return Int(digits)
    }
    
    private func parseAmountAndCurrency(from seg: String) -> (Double?, String) {
        let upper = seg.uppercased()
        let currency: String
        if upper.contains("USD") { currency = "USD" }
        else if upper.contains("EUR") { currency = "EUR" }
        else if upper.contains("JPY") { currency = "JPY" }
        else if upper.contains("CNY") { currency = "CNY" }
        else { currency = "CNY" }
        
        let pattern = #"(?<!:)(\d{1,9})(\.\d{1,2})?"#
        guard let range = seg.range(of: pattern, options: .regularExpression) else { return (nil, currency) }
        let str = String(seg[range])
        return (Double(str), currency)
    }
    
    private func combine(day: Date, time: DateComponents?) -> Date {
        guard let time else { return day }
        return Calendar.current.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: 0, of: day) ?? day
    }
    
    private func inferCategory(from seg: String, nights: Int?, lodgingHint: Bool) -> String {
        if lodgingHint || nights != nil { return "住宿" }
        if containsAny(seg, ["机票", "航班", "飞机", "票"]) { return "机票" }
        if containsAny(seg, ["饭", "餐", "吃", "早餐", "午餐", "晚餐"]) { return "餐饮" }
        if containsAny(seg, ["地铁", "出租", "打车", "公交", "高铁", "火车", "交通"]) { return "交通" }
        if containsAny(seg, ["门票", "票价"]) { return "门票" }
        return "其他"
    }
    
    private func inferExpenseTitle(from seg: String, pendingLodgingName: String?, category: String) -> String {
        if category == "住宿", let name = pendingLodgingName, !name.isEmpty {
            return name
        }
        let cleaned = cleanedTitle(seg)
        if cleaned.isEmpty { return category }
        return cleaned
    }
    
    private func inferItineraryTitle(from seg: String) -> String {
        let pattern = #"^\s*\d{1,2}:\d{2}\s*"#
        let stripped = seg.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        return cleanedTitle(stripped)
    }
    
    private func cleanedTitle(_ s: String) -> String {
        let removePatterns = [
            #"(\d{4})-(\d{2})-(\d{2})"#,
            #"(\d{1,2}):(\d{2})"#,
            #"(\d+)\s*晚"#,
            #"(?<!:)(\d{1,9})(\.\d{1,2})?"#,
            #"(CNY|USD|EUR|JPY)"#
        ]
        var out = s
        for p in removePatterns {
            out = out.replacingOccurrences(of: p, with: "", options: [.regularExpression, .caseInsensitive])
        }
        out = out.replacingOccurrences(of: "¥", with: "")
        out = out.replacingOccurrences(of: "元", with: "")
        out = out.replacingOccurrences(of: "费用", with: "")
        out = out.replacingOccurrences(of: "花费", with: "")
        out = out.replacingOccurrences(of: "饭钱", with: "")
        out = out.replacingOccurrences(of: "机票", with: "机票")
        out = out.trimmingCharacters(in: .whitespacesAndNewlines)
        out = out.replacingOccurrences(of: "  ", with: " ")
        return out
    }
    
    private func containsAny(_ s: String, _ keywords: [String]) -> Bool {
        for k in keywords where s.contains(k) { return true }
        return false
    }
}
