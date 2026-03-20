import Foundation

/// Extracts a single primary date/time from natural phrases. Deterministic; English patterns only.
struct DateParser {
    private let calendar: Calendar
    private let referenceDate: Date

    init(calendar: Calendar = .current, referenceDate: Date = .now) {
        self.calendar = calendar
        self.referenceDate = referenceDate
    }

    /// First matching date and the substring range to remove when building a title.
    func firstMatch(in text: String) -> (date: Date, range: Range<String.Index>)? {
        typealias MatchHandler = (NSTextCheckingResult, String) -> Date?
        let candidates: [(String, MatchHandler)] = [
            (#"(?i)next\s+(sunday|monday|tuesday|wednesday|thursday|friday|saturday)\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.)"#, { self.parseNextWeekdayAt($0, $1) }),
            (#"(?i)today\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.)"#, { self.parseTodayAt($0, $1) }),
            (#"(?i)tomorrow\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.)"#, { self.parseTomorrowAt($0, $1) }),
            (#"(?i)in\s+(\d+)\s+hours?"#, { self.parseInHours($0, $1) }),
            (#"(?i)in\s+(\d+)\s+minutes?"#, { self.parseInMinutes($0, $1) }),
            (#"(?i)\bat\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.)"#, { self.parseAtTime($0, $1) }),
        ]

        for (pattern, handler) in candidates {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let ns = text as NSString
            let full = NSRange(location: 0, length: ns.length)
            guard let m = regex.firstMatch(in: text, options: [], range: full) else { continue }
            guard let range = Range(m.range, in: text), let date = handler(m, text) else { continue }
            return (date, range)
        }
        return nil
    }

    // MARK: - Handlers

    private func parseInMinutes(_ match: NSTextCheckingResult, _ string: String) -> Date? {
        guard match.numberOfRanges >= 2,
              let r = Range(match.range(at: 1), in: string),
              let n = Int(string[r]), n > 0
        else { return nil }
        return calendar.date(byAdding: .minute, value: n, to: referenceDate)
    }

    private func parseInHours(_ match: NSTextCheckingResult, _ string: String) -> Date? {
        guard match.numberOfRanges >= 2,
              let r = Range(match.range(at: 1), in: string),
              let n = Int(string[r]), n > 0
        else { return nil }
        return calendar.date(byAdding: .hour, value: n, to: referenceDate)
    }

    private func parseTodayAt(_ match: NSTextCheckingResult, _ string: String) -> Date? {
        let day = calendar.startOfDay(for: referenceDate)
        return extractTime(on: day, match: match, string: string, hourGroup: 1, minuteGroup: 2, ampmGroup: 3)
    }

    private func parseTomorrowAt(_ match: NSTextCheckingResult, _ string: String) -> Date? {
        guard let start = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: referenceDate)) else {
            return nil
        }
        return extractTime(on: start, match: match, string: string, hourGroup: 1, minuteGroup: 2, ampmGroup: 3)
    }

    private func parseNextWeekdayAt(_ match: NSTextCheckingResult, _ string: String) -> Date? {
        guard match.numberOfRanges >= 5,
              let nameRange = Range(match.range(at: 1), in: string)
        else { return nil }
        let name = String(string[nameRange]).lowercased()
        guard let targetWeekday = weekdayValue(name) else { return nil }
        guard let dayStart = nextOccurrence(ofWeekday: targetWeekday, after: referenceDate) else { return nil }
        return extractTime(on: dayStart, match: match, string: string, hourGroup: 2, minuteGroup: 3, ampmGroup: 4)
    }

    private func parseAtTime(_ match: NSTextCheckingResult, _ string: String) -> Date? {
        let dayStart = calendar.startOfDay(for: referenceDate)
        guard let withTime = extractTime(on: dayStart, match: match, string: string, hourGroup: 1, minuteGroup: 2, ampmGroup: 3)
        else { return nil }
        if withTime <= referenceDate {
            return calendar.date(byAdding: .day, value: 1, to: withTime)
        }
        return withTime
    }

    // MARK: - Time helpers

    private func extractTime(
        on day: Date,
        match: NSTextCheckingResult,
        string: String,
        hourGroup: Int,
        minuteGroup: Int,
        ampmGroup: Int
    ) -> Date? {
        guard match.numberOfRanges > hourGroup,
              let hr = Range(match.range(at: hourGroup), in: string),
              let hour = Int(string[hr]), hour >= 1, hour <= 12
        else { return nil }

        var minute = 0
        if match.numberOfRanges > minuteGroup, match.range(at: minuteGroup).location != NSNotFound,
           let mr = Range(match.range(at: minuteGroup), in: string),
           let m = Int(string[mr]) {
            minute = m
        }

        guard match.numberOfRanges > ampmGroup, match.range(at: ampmGroup).location != NSNotFound,
              let ar = Range(match.range(at: ampmGroup), in: string)
        else { return nil }

        let ampm = String(string[ar]).lowercased().replacingOccurrences(of: ".", with: "")
        let isPM = ampm == "pm" || ampm == "p"
        let isAM = ampm == "am" || ampm == "a"
        guard isPM || isAM else { return nil }

        var h24 = hour
        if isPM, hour < 12 { h24 = hour + 12 }
        if isAM, hour == 12 { h24 = 0 }

        var comps = calendar.dateComponents([.year, .month, .day], from: day)
        comps.hour = h24
        comps.minute = minute
        return calendar.date(from: comps)
    }

    private func weekdayValue(_ name: String) -> Int? {
        switch name {
        case "sunday": return 1
        case "monday": return 2
        case "tuesday": return 3
        case "wednesday": return 4
        case "thursday": return 5
        case "friday": return 6
        case "saturday": return 7
        default: return nil
        }
    }

    /// Next occurrence of `weekday` (1=Sunday … 7=Saturday). Same weekday as today advances one week.
    private func nextOccurrence(ofWeekday target: Int, after ref: Date) -> Date? {
        let todayWd = calendar.component(.weekday, from: ref)
        var add = (target - todayWd + 7) % 7
        if add == 0 { add = 7 }
        let start = calendar.startOfDay(for: ref)
        return calendar.date(byAdding: .day, value: add, to: start)
    }
}
