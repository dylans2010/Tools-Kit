import Foundation

final class WritingAnalyticsEngine {
    static let shared = WritingAnalyticsEngine()

    private init() {}

    func stripHTML(_ text: String) -> String {
        return text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    func computeStats(text: String) -> WritingStats {
        let cleanText = stripHTML(text)
        let words = cleanText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let sentences = cleanText.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let paragraphs = cleanText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        let wordCount = words.count
        let charCount = cleanText.count
        let sentenceCount = max(1, sentences.count)
        let paragraphCount = max(1, paragraphs.count)

        let avgWordsPerSentence = Double(wordCount) / Double(sentenceCount)
        let avgWordsPerParagraph = Double(wordCount) / Double(paragraphCount)

        var totalSyllables = 0
        var complexWordCount = 0
        for word in words {
            let s = countSyllables(word)
            totalSyllables += s
            if s >= 3 { complexWordCount += 1 }
        }

        let avgSyllablesPerWord = wordCount > 0 ? Double(totalSyllables) / Double(wordCount) : 0
        let readabilityScore = 206.835 - (1.015 * avgWordsPerSentence) - (84.6 * avgSyllablesPerWord)
        let clampedScore = max(0, min(100, readabilityScore))

        let uniqueWords = Set(words.map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }).filter { !$0.isEmpty }
        let vocabularyRichness = wordCount > 0 ? (Double(uniqueWords.count) / Double(wordCount)) * 100 : 0

        return WritingStats(
            wordCount: wordCount,
            charCount: charCount,
            sentenceCount: sentenceCount,
            paragraphCount: paragraphCount,
            avgWordsPerSentence: avgWordsPerSentence,
            avgWordsPerParagraph: avgWordsPerParagraph,
            readabilityScore: clampedScore,
            complexWordCount: complexWordCount,
            uniqueWordCount: uniqueWords.count,
            vocabularyRichness: vocabularyRichness
        )
    }

    func countSyllables(_ word: String) -> Int {
        let w = word.lowercased().filter { $0.isLetter }
        if w.count <= 3 { return 1 }

        let vowels = CharacterSet(charactersIn: "aeiouy")
        var count = 0
        var lastWasVowel = false

        for char in w {
            let isVowel = String(char).rangeOfCharacter(from: vowels) != nil
            if isVowel && !lastWasVowel {
                count += 1
            }
            lastWasVowel = isVowel
        }

        if w.hasSuffix("e") {
            count -= 1
        }
        if w.hasSuffix("le") && w.count > 2 {
            let secondToLast = w[w.index(w.endIndex, offsetBy: -2)]
            if String(secondToLast).rangeOfCharacter(from: vowels) == nil {
                count += 1
            }
        }

        return max(1, count)
    }

    func analyzeTone(text: String) -> ToneAnalysis {
        let cleanText = stripHTML(text).lowercased()
        let words = cleanText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let totalWords = words.count

        let positiveSet: Set = ["good", "great", "excellent", "amazing", "wonderful", "fantastic", "love", "happy", "joy"]
        let negativeSet: Set = ["bad", "terrible", "awful", "hate", "sad", "angry", "frustrated", "disappointed"]
        let analyticalSet: Set = ["analyze", "examine", "study", "research", "investigate", "data", "evidence"]
        let confidentSet: Set = ["definitely", "certainly", "absolutely", "clearly", "obviously", "undoubtedly"]
        let tentativeSet: Set = ["maybe", "perhaps", "possibly", "might", "could", "seems", "appears"]

        var counts = [String: Int]()
        counts["positive"] = 0
        counts["negative"] = 0
        counts["analytical"] = 0
        counts["confident"] = 0
        counts["tentative"] = 0

        for word in words {
            let w = word.trimmingCharacters(in: .punctuationCharacters)
            if positiveSet.contains(w) { counts["positive"]! += 1 }
            if negativeSet.contains(w) { counts["negative"]! += 1 }
            if analyticalSet.contains(w) { counts["analytical"]! += 1 }
            if confidentSet.contains(w) { counts["confident"]! += 1 }
            if tentativeSet.contains(w) { counts["tentative"]! += 1 }
        }

        let emotionalWords = counts.values.reduce(0, +)
        let neutral = totalWords > 0 ? Double(max(0, totalWords - emotionalWords)) / Double(totalWords) * 100 : 100.0

        func pct(_ key: String) -> Double {
            return emotionalWords > 0 ? Double(counts[key]!) / Double(emotionalWords) * 100 : 0
        }

        let posPct = pct("positive")
        let negPct = pct("negative")
        let anaPct = pct("analytical")
        let conPct = pct("confident")
        let tenPct = pct("tentative")

        var primary = "neutral"
        var maxPct = neutral

        if posPct > maxPct { primary = "positive"; maxPct = posPct }
        if negPct > maxPct { primary = "negative"; maxPct = negPct }
        if anaPct > maxPct { primary = "analytical"; maxPct = anaPct }
        if conPct > maxPct { primary = "confident"; maxPct = conPct }
        if tenPct > maxPct { primary = "tentative"; maxPct = tenPct }

        return ToneAnalysis(
            primary: primary.capitalized,
            confidence: maxPct,
            positive: posPct,
            negative: negPct,
            neutral: neutral,
            analytical: anaPct,
            confident: conPct,
            tentative: tenPct
        )
    }

    func analyzeSentenceLength(text: String) -> SentenceLengthAnalysis {
        let cleanText = stripHTML(text)
        let sentences = cleanText.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        var short = 0, medium = 0, long = 0
        var totalWords = 0

        for s in sentences {
            let words = s.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            let count = words.count
            totalWords += count
            if count <= 10 { short += 1 }
            else if count <= 20 { medium += 1 }
            else { long += 1 }
        }

        let avg = sentences.isEmpty ? 0 : Double(totalWords) / Double(sentences.count)
        return SentenceLengthAnalysis(short: short, medium: medium, long: long, average: avg)
    }

    func analyzeWordComplexity(text: String) -> WordComplexity {
        let words = stripHTML(text).components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var simple = 0, moderate = 0, complex = 0
        var totalSyllables = 0

        for word in words {
            let w = word.trimmingCharacters(in: .punctuationCharacters)
            let len = w.count
            totalSyllables += countSyllables(w)
            if len <= 4 { simple += 1 }
            else if len <= 7 { moderate += 1 }
            else { complex += 1 }
        }

        let total = max(1, words.count)
        let score = ((Double(complex) + Double(moderate) * 0.5) / Double(total)) * 100
        let avgSyllables = Double(totalSyllables) / Double(total)

        return WordComplexity(simple: simple, moderate: moderate, complex: complex, averageSyllables: avgSyllables, complexityScore: score)
    }

    func computeWordFrequency(text: String) -> [WordFrequencyItem] {
        let words = stripHTML(text).lowercased().components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { $0.count > 3 }

        let total = words.count
        var freq = [String: Int]()
        for w in words {
            freq[w, default: 0] += 1
        }

        return freq.map { WordFrequencyItem(word: $0.key, count: $0.value, percentage: total > 0 ? (Double($0.value) / Double(total)) * 100 : 0) }
            .sorted { $0.count > $1.count }
            .prefix(10)
            .map { $0 }
    }

    func findOverusedWords(from frequency: [WordFrequencyItem], totalWords: Int) -> [OverusedWord] {
        return frequency.filter { $0.count > 5 && $0.percentage > 2.0 }.map {
            OverusedWord(word: $0.word, count: $0.count, percentage: $0.percentage, suggestions: synonyms(for: $0.word))
        }
    }

    func synonyms(for word: String) -> [String] {
        let map: [String: String] = [
            "good": "excellent,great,wonderful,fantastic,superb",
            "bad": "poor,terrible,awful,dreadful,horrible",
            "big": "large,huge,enormous,massive,gigantic",
            "small": "tiny,little,miniature,compact,petite",
            "fast": "quick,rapid,swift,speedy,hasty",
            "slow": "gradual,leisurely,sluggish,unhurried,deliberate",
            "happy": "joyful,cheerful,delighted,elated,content",
            "sad": "sorrowful,melancholy,dejected,gloomy,downcast"
        ]
        if let entry = map[word.lowercased()] {
            return entry.components(separatedBy: ",")
        }
        return ["No suggestions available"]
    }

    func generateImprovementSuggestions(stats: WritingStats, overused: [OverusedWord], tone: ToneAnalysis) -> [ImprovementSuggestion] {
        var suggestions = [ImprovementSuggestion]()

        if stats.avgWordsPerSentence > 25 {
            suggestions.append(ImprovementSuggestion(category: "Sentence Length", suggestion: "Consider breaking down long sentences to improve clarity.", impact: "High", icon: "✂️"))
        }
        if stats.readabilityScore < 50 {
            suggestions.append(ImprovementSuggestion(category: "Readability", suggestion: "Your writing might be difficult for some readers. Try using simpler words.", impact: "High", icon: "📖"))
        }
        if let first = overused.first {
            suggestions.append(ImprovementSuggestion(category: "Word Variety", suggestion: "You've used '\(first.word)' quite a bit. Try some synonyms to keep it fresh.", impact: "Medium", icon: "🔄"))
        }
        if stats.vocabularyRichness < 30 {
            suggestions.append(ImprovementSuggestion(category: "Vocabulary", suggestion: "The vocabulary variety is a bit low. Expanding your word choices could help.", impact: "Medium", icon: "📚"))
        }
        if tone.primary.lowercased() == "neutral" && tone.confidence < 20 {
            suggestions.append(ImprovementSuggestion(category: "Tone", suggestion: "Your writing's tone is very neutral. Adding more expressive language could engage readers more.", impact: "Low", icon: "🎭"))
        }

        return suggestions
    }

    func checkGrammarLocally(text: String) -> [GrammarIssue] {
        let cleanText = stripHTML(text)
        let words = cleanText.components(separatedBy: .whitespacesAndNewlines)
        var issues = [GrammarIssue]()

        let localDict: [String: (suggestion: String, type: String, message: String)] = [
            "teh": ("the", "Spelling", "Did you mean 'the'?"),
            "recieve": ("receive", "Spelling", "Remember: 'i' before 'e' except after 'c'."),
            "alot": ("a lot", "Grammar", "'A lot' should be two words."),
            "definately": ("definitely", "Spelling", "The correct spelling is 'definitely'."),
            "seperate": ("separate", "Spelling", "There's 'a rat' in 'separate'."),
            "there": ("their/they're", "Homophone", "Check if you mean 'their' (belonging to) or 'they're' (they are)."),
            "their": ("there/they're", "Homophone", "Check if you mean 'there' (place) or 'they're' (they are)."),
            "they're": ("there/their", "Homophone", "Check if you mean 'there' (place) or 'their' (belonging to)."),
            "your": ("you're", "Homophone", "Use 'you're' for 'you are'."),
            "you're": ("your", "Homophone", "Use 'your' for possession."),
            "its": ("it's", "Homophone", "Use 'it's' for 'it is'."),
            "it's": ("its", "Homophone", "Use 'its' for possession."),
            "loose": ("lose", "Homophone", "Did you mean 'lose' (to misplace)?"),
            "lose": ("loose", "Homophone", "Did you mean 'loose' (not tight)?"),
            "affect": ("effect", "Homophone", "Affect is usually a verb, effect a noun."),
            "effect": ("affect", "Homophone", "Effect is usually a noun, affect a verb."),
            "accept": ("except", "Homophone", "Accept means receive, except means exclude."),
            "except": ("accept", "Homophone", "Except means exclude, accept means receive."),
            "than": ("then", "Grammar", "Use 'than' for comparisons."),
            "then": ("than", "Grammar", "Use 'then' for time sequences."),
            "could of": ("could have", "Grammar", "Use 'could have' or 'could've'."),
            "would of": ("would have", "Grammar", "Use 'would have' or 'would've'."),
            "should of": ("should have", "Grammar", "Use 'should have' or 'should've'."),
            "suppose to": ("supposed to", "Grammar", "Use 'supposed to'."),
            "use to": ("used to", "Grammar", "Use 'used to'."),
            "i": ("I", "Capitalization", "Always capitalize the personal pronoun 'I'."),
            "wont": ("won't", "Contraction", "Add an apostrophe for 'will not'."),
            "dont": ("don't", "Contraction", "Add an apostrophe for 'do not'."),
            "cant": ("can't", "Contraction", "Add an apostrophe for 'cannot'."),
            "didnt": ("didn't", "Contraction", "Add an apostrophe for 'did not'."),
            "isnt": ("isn't", "Contraction", "Add an apostrophe for 'is not'."),
            "arent": ("aren't", "Contraction", "Add an apostrophe for 'are not'."),
            "wasnt": ("wasn't", "Contraction", "Add an apostrophe for 'was not'."),
            "werent": ("weren't", "Contraction", "Add an apostrophe for 'were not'."),
            "havent": ("haven't", "Contraction", "Add an apostrophe for 'have not'."),
            "hasnt": ("hasn't", "Contraction", "Add an apostrophe for 'has not'."),
            "hadnt": ("hadn't", "Contraction", "Add an apostrophe for 'had not'."),
            "shouldnt": ("shouldn't", "Contraction", "Add an apostrophe for 'should not'."),
            "wouldnt": ("wouldnt", "Contraction", "Add an apostrophe for 'would not'."),
            "couldnt": ("couldnt", "Contraction", "Add an apostrophe for 'could not'."),
            "weather": ("whether", "Homophone", "Weather refers to the climate."),
            "whether": ("weather", "Homophone", "Whether expresses a doubt."),
            "principal": ("principle", "Homophone", "Principal is a person or main, principle is a rule."),
            "principle": ("principal", "Homophone", "Principle is a rule, principal is a person or main."),
            "stationary": ("stationery", "Homophone", "Stationary means not moving."),
            "stationery": ("stationary", "Homophone", "Stationery refers to writing materials."),
            "compliment": ("complement", "Homophone", "Compliment is praise."),
            "complement": ("compliment", "Homophone", "Complement means to complete."),
            "advise": ("advice", "Homophone", "Advise is a verb, advice is a noun."),
            "advice": ("advise", "Homophone", "Advice is a noun, advise is a verb."),
            "allowed": ("aloud", "Homophone", "Allowed means permitted."),
            "aloud": ("allowed", "Homophone", "Aloud means out loud."),
            "board": ("bored", "Homophone", "Board is a piece of wood or a group."),
            "bored": ("board", "Homophone", "Bored means uninterested."),
            "brake": ("break", "Homophone", "Brake slows a vehicle."),
            "break": ("brake", "Homophone", "Break means to smash or a pause."),
            "capital": ("capitol", "Homophone", "Capital is a city or wealth."),
            "capitol": ("capital", "Homophone", "Capitol is a building."),
            "cent": ("scent", "Homophone", "Cent is money."),
            "scent": ("cent", "Homophone", "Scent is a smell."),
            "choose": ("chose", "Grammar", "Choose is present tense, chose is past."),
            "chose": ("choose", "Grammar", "Chose is past tense, choose is present."),
            "coarse": ("course", "Homophone", "Coarse means rough."),
            "course": ("coarse", "Homophone", "Course is a path or class."),
            "complementary": ("complimentary", "Homophone", "Complementary means completing."),
            "complimentary": ("complementary", "Homophone", "Complimentary means free or praising."),
            "council": ("counsel", "Homophone", "Council is a group."),
            "counsel": ("council", "Homophone", "Counsel is advice."),
            "desert": ("dessert", "Homophone", "Desert is dry land."),
            "dessert": ("desert", "Homophone", "Dessert is a sweet treat."),
            "dual": ("duel", "Homophone", "Dual means two."),
            "duel": ("dual", "Homophone", "Duel is a fight."),
            "elicit": ("illicit", "Homophone", "Elicit means to draw out."),
            "illicit": ("elicit", "Homophone", "Illicit means illegal."),
            "forth": ("fourth", "Homophone", "Forth means forward."),
            "fourth": ("forth", "Homophone", "Fourth is the number 4."),
            "heard": ("herd", "Homophone", "Heard is past of hear."),
            "herd": ("heard", "Homophone", "Herd is a group of animals."),
            "hire": ("higher", "Homophone", "Hire means to employ."),
            "higher": ("hire", "Homophone", "Higher means more elevated."),
            "hole": ("whole", "Homophone", "Hole is an opening."),
            "whole": ("hole", "Homophone", "Whole means entire."),
            "knight": ("night", "Homophone", "Knight is a warrior."),
            "night": ("knight", "Homophone", "Night is after sunset."),
            "knot": ("not", "Homophone", "Knot is tied string."),
            "not": ("knot", "Homophone", "Not is a negation."),
            "know": ("no", "Homophone", "Know means to understand."),
            "no": ("know", "Homophone", "No is a refusal."),
            "lead": ("led", "Homophone", "Led is past of lead (verb)."),
            "led": ("lead", "Homophone", "Lead (verb) is present tense."),
            "mail": ("male", "Homophone", "Mail is letters."),
            "male": ("mail", "Homophone", "Male is a gender."),
            "meat": ("meet", "Homophone", "Meat is animal flesh."),
            "meet": ("meat", "Homophone", "Meet means to encounter."),
            "one": ("won", "Homophone", "One is the number 1."),
            "won": ("one", "Homophone", "Won is past of win."),
            "passed": ("past", "Homophone", "Passed is past of pass."),
            "past": ("passed", "Homophone", "Past is previous time."),
            "peace": ("piece", "Homophone", "Peace means tranquility."),
            "piece": ("peace", "Homophone", "Piece is a part."),
            "plain": ("plane", "Homophone", "Plain is simple or a field."),
            "plane": ("plain", "Homophone", "Plane is an aircraft."),
            "poor": ("pour", "Homophone", "Poor means having little money."),
            "pour": ("poor", "Homophone", "Pour means to flow."),
            "rain": ("reign", "Homophone", "Rain is water from clouds."),
            "reign": ("rain", "Homophone", "Reign is to rule."),
            "right": ("write", "Homophone", "Right is correct or a direction."),
            "write": ("right", "Homophone", "Write means to compose text."),
            "road": ("rode", "Homophone", "Road is a path."),
            "rode": ("road", "Homophone", "Rode is past of ride."),
            "role": ("roll", "Homophone", "Role is a part played."),
            "roll": ("role", "Homophone", "Roll is to rotate or bread."),
            "sail": ("sale", "Homophone", "Sail is for a boat."),
            "sale": ("sail", "Homophone", "Sale is selling something."),
            "scene": ("seen", "Homophone", "Scene is a place or view."),
            "seen": ("scene", "Homophone", "Seen is past participle of see."),
            "sight": ("site", "Homophone", "Sight is vision."),
            "site": ("sight", "Homophone", "Site is a location."),
            "some": ("sum", "Homophone", "Some is an amount."),
            "sum": ("some", "Homophone", "Sum is the total."),
            "tail": ("tale", "Homophone", "Tail is on an animal."),
            "tale": ("tail", "Homophone", "Tale is a story."),
            "weak": ("week", "Homophone", "Weak means not strong."),
            "week": ("weak", "Homophone", "Week is seven days.")
        ]

        var currentOffset = 0
        for word in words {
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
            if let entry = localDict[cleanWord] {
                let start = max(0, cleanText.index(cleanText.startIndex, offsetBy: currentOffset).utf16Offset(in: cleanText) - 30)
                let end = min(cleanText.count, currentOffset + word.count + 30)
                let range = cleanText.index(cleanText.startIndex, offsetBy: start)..<cleanText.index(cleanText.startIndex, offsetBy: end)
                let context = String(cleanText[range])

                issues.append(GrammarIssue(
                    word: word,
                    suggestion: entry.suggestion,
                    severity: entry.type == "Spelling" ? "high" : "medium",
                    type: entry.type,
                    message: entry.message,
                    context: "...\(context)..."
                ))
            }
            currentOffset += word.count + 1
        }

        return issues
    }

    func checkGrammarWithAPI(text: String) async throws -> [GrammarIssue] {
        let cleanText = stripHTML(text)
        guard let url = URL(string: "https://api.languagetool.org/v2/check") else { throw NSError(domain: "Invalid URL", code: 0) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "text=\(cleanText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&language=en-US"
        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let matches = json?["matches"] as? [[String: Any]] ?? []

        return matches.compactMap { match in
            guard let message = match["message"] as? String,
                  let contextData = match["context"] as? [String: Any],
                  let contextText = contextData["text"] as? String,
                  let replacements = match["replacements"] as? [[String: Any]],
                  let firstReplacement = replacements.first?["value"] as? String,
                  let rule = match["rule"] as? [String: Any],
                  let issueType = rule["issueType"] as? String else { return nil }

            let severity = issueType == "typographical" ? "high" : "medium"
            let offset = contextData["offset"] as? Int ?? 0
            let length = contextData["length"] as? Int ?? 1
            let startIndex = contextText.index(contextText.startIndex, offsetBy: offset)
            let endIndex = contextText.index(startIndex, offsetBy: length)
            let word = String(contextText[startIndex..<endIndex])

            return GrammarIssue(
                word: word,
                suggestion: firstReplacement,
                severity: severity,
                type: issueType.capitalized,
                message: message,
                context: contextText
            )
        }
    }

    func searchMatches(in text: String, term: String) -> [SearchMatch] {
        guard !term.isEmpty else { return [] }
        let cleanText = stripHTML(text)
        var matches = [SearchMatch]()
        var index = 1

        var searchRange = cleanText.startIndex..<cleanText.endIndex
        while let range = cleanText.range(of: term, options: .caseInsensitive, range: searchRange) {
            let start = cleanText.distance(from: cleanText.startIndex, to: range.lowerBound)
            let contextStart = max(0, start - 40)
            let contextEnd = min(cleanText.count, start + term.count + 40)
            let contextRange = cleanText.index(cleanText.startIndex, offsetBy: contextStart)..<cleanText.index(cleanText.startIndex, offsetBy: contextEnd)
            let context = String(cleanText[contextRange])

            matches.append(SearchMatch(index: index, text: String(cleanText[range]), contextSnippet: "...\(context)..."))

            index += 1
            searchRange = range.upperBound..<cleanText.endIndex
        }

        return matches
    }

    func runLocalPlagiarismScan(text: String) -> PlagiarismResult {
        let cleanText = stripHTML(text)
        let sentences = cleanText.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { $0.count > 20 }
        let checkCount = min(3, sentences.count)

        var matches = [PlagiarismMatch]()
        for i in 0..<checkCount {
            let sentence = sentences[i]
            var hasher = Hasher()
            hasher.combine(sentence)
            let hash = hasher.finalize()

            // simulate ~30% chance
            if abs(hash) % 100 < 30 {
                let similarity = Double(15 + (abs(hash) % 31))
                matches.append(PlagiarismMatch(
                    text: sentence,
                    similarity: similarity,
                    source: "https://example-source-\(i+1).com/article",
                    matchType: "Web Match"
                ))
            }
        }

        let avgSimilarity = matches.isEmpty ? 0.0 : matches.reduce(0.0, { $0 + $1.similarity }) / Double(matches.count)
        let riskLevel: String
        if avgSimilarity < 15 { riskLevel = "low" }
        else if avgSimilarity < 35 { riskLevel = "medium" }
        else { riskLevel = "high" }

        return PlagiarismResult(
            overallScore: avgSimilarity,
            riskLevel: riskLevel,
            matches: matches,
            checkedSentences: checkCount,
            totalSentences: sentences.count
        )
    }

    func readabilityLevel(score: Double) -> (level: String, cefr: String, description: String) {
        switch score {
        case 90...100: return ("Very Easy", "A1", "Suitable for 5th grade readers.")
        case 80..<90: return ("Easy", "A2", "Suitable for 6th grade readers.")
        case 70..<80: return ("Fairly Easy", "B1", "Suitable for 7th grade readers.")
        case 60..<70: return ("Standard", "B2", "Suitable for 8th–9th grade readers.")
        case 50..<60: return ("Fairly Difficult", "C1", "Suitable for 10th–12th grade readers.")
        case 30..<50: return ("Difficult", "C2", "College level.")
        default: return ("Very Difficult", "C2+", "Post-graduate level.")
        }
    }
}
