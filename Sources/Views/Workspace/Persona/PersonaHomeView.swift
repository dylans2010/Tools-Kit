import SwiftUI
import Aurora

struct PersonaHomeView: View {
    @ObservedObject private var manager = PersonaManager.shared
    @State private var query = ""
    @AppStorage("persona.welcome_shown") private var hasShownWelcome = false
    @State private var activeModal: PersonaHomeModal?
    @State private var chatThreads: [PersonaChatThread] = []
    @State private var activeThreadID: UUID?
    @State private var agentModeEnabled = false
    @State private var pendingAction: PersonaAgentFramework.PersonaActionPreview?
    @State private var pendingIntent: PersonaAgentFramework.PersonaIntent?
    @State private var clarificationMissingField: String?

    // Expanded Preset Prompts (500+)
    private let allPrompts = [
        "Summarize my recent meetings", "What are my top priorities today?", "Draft an email to my team about the project",
        "How many habits have I completed this week?", "Show me my upcoming deadlines", "Analyze my latest spreadsheet",
        "Create a slide deck outline for a sales pitch", "What did we decide in the last collaboration session?",
        "Find knowledge gaps in my notebooks", "How is my streak for 'Morning Run'?", "Review my recent mail for urgent tasks",
        "Suggest a better schedule for tomorrow", "What are the key points from my latest article?",
        "Compare my tasks from last week vs this week", "Draft a project proposal based on my notes",
        "Explain the current status of the 'Marketing' space", "Summarize all unread emails",
        "What are my habits for today?", "How many slides are in my 'Product Launch' deck?",
        "Give me a briefing for my 2 PM meeting", "What tasks are overdue?", "List all notebooks related to 'AI'",
        "Help me brainstorm ideas for a new blog post", "Summarize the 'Research' folder in my notebook",
        "Who are the members of the 'Design' collaboration space?", "Calculate the average value in my 'Budget' sheet",
        "Suggest 3 new habits based on my goals", "Create a task for 'Follow up with Client'",
        "Show me my activity feed for the 'Development' space", "What articles did I read yesterday?",
        "Draft a summary of my weekly accomplishments", "Find all tasks with high priority",
        "What is the description of the 'Alpha' collaboration space?", "How many mail accounts are connected?",
        "Show me the content of my 'Ideas' page", "What is my longest habit streak?",
        "Create a meeting agenda for tomorrow's sync", "Summarize the recent changes in 'Source Code' space",
        "What are the tags in my 'Project X' notebook?", "How many tasks are completed today?",
        "Draft a reply to the last email from 'John'", "What are the upcoming events for this weekend?",
        "List all slide decks I modified this week", "Analyze the trends in my 'Sales' spreadsheet",
        "Give me a summary of the 'Habit Coaching' insights", "What is the status of my 'Fitness' goal?",
        "Show me the most recent collaboration messages", "Draft an article based on my 'Brainstorm' notes",
        "What are the key takeaways from the 'Vision' meeting?", "How many spreadsheets do I have?",
        "Summarize the 'Meeting Notes' folder", "What tasks are assigned to me in 'Team Alpha'?",
        "List all articles in the 'Tech' collection", "How many habits have a 100% completion rate?",
        "Show me my schedule for next Monday", "Draft a welcome message for new space members",
        "What is the total row count of my 'Inventory' sheet?", "Create a 'Weekly Review' task",
        "Summarize the 'Competitor Analysis' slide deck", "What are the recent interactions with Persona?",
        "Help me organize my 'Drafts' folder", "What is the theme of my 'Presentation 1'?",
        "Draft a follow-up email for the 'Partnership' meeting", "How many tasks are due in the next 3 days?",
        "Summarize the 'Project Requirements' document", "What are my most active habits?",
        "List all members in the 'Workspace Admins' space", "Calculate the sum of 'Expenses' in my sheet",
        "Suggest a topic for my next presentation", "Show me my top 5 most used notebook tags",
        "What is the description of the 'Personal' notebook?", "How many unread messages in collaboration spaces?",
        "Draft a summary of the 'User Feedback' articles", "What are my commitments for this week?",
        "Summarize the 'Onboarding' slide deck", "How many habits did I miss yesterday?",
        "List all calendar events at 'Office'", "Draft a response to the 'Budget Approval' request",
        "What are the main goals of the 'Expansion' space?", "How many columns in the 'Performance' sheet?",
        "Create a task list for 'Event Planning'", "Summarize the 'Marketing Strategy' notes",
        "What is my current completion rate for 'Reading'?", "List all tasks with 'Urgent' tag",
        "Show me the latest commit in 'Main Project'", "Draft an intro for the 'Annual Report'",
        "What are the action items from 'Sync #4'?", "How many articles are in my 'Reference' library?",
        "Summarize the 'Q3 Goals' notebook page", "What is the start time of my next event?",
        "List all spreadsheets related to 'Finance'", "Draft a project update for 'Stakeholders'",
        "What are my habits for the 'Health' category?", "How many slides have images in my deck?",
        "Summarize the 'Product Roadmap' space", "What is the due date of 'Finalize Design'?",
        "List all notebook folders in 'Workspace'", "Draft a 'Thank You' note for the team",
        "What are the highlights from the 'Innovation' workshop?", "How many collaboration spaces am I in?",
        // Additional 400+ prompts to reach 500+
        "Track my focus time for today", "Summarize the last 5 articles I saved", "Check if I have any overlapping meetings",
        "Who sent me the most emails this week?", "List tasks I finished yesterday", "How many notes did I take in June?",
        "Analyze the cost column in 'Project Budget'", "Create a summary of the 'Design System' slides", "What is the next item on my habit list?",
        "Find all spreadsheets shared with 'Sarah'", "Draft a follow-up for the 'Sprint Planning' meeting", "Show me tasks tagged with 'Review'",
        "What is the total count of unread articles?", "Summarize the 'Backend' collaboration channel", "List all notebooks created this year",
        "What is the status of my 'Learning Swift' habit?", "Show me my calendar for the next 48 hours", "Draft a feedback email for the 'Beta Test'",
        "How many slides are in the 'Investor Pitch'?", "Summarize recent activity in the 'Product' space", "What are my top 3 most productive habits?",
        "Find emails related to 'Contract'", "List all tasks in 'Waiting' status", "How many rows are in the 'User Logs' sheet?",
        "Create a slide outline for 'Technical Architecture'", "What were the conclusions of 'Project Kickoff'?", "Summarize my 'Reading List' notebook",
        "Show me all habits with a streak over 7 days", "Draft a memo about 'Office Reopening'", "What is the newest article in 'AI News'?",
        "List collaboration spaces with 'High' risk level", "Calculate the average of 'Response Time' in my sheet", "Find notes mentioning 'Architecture'",
        "What is the theme of 'Keynote 2024'?", "Draft a summary for the 'Executive Summary' slide", "How many tasks are in my 'Inbox'?",
        "Summarize the 'Frontend' notes", "Show me my schedule for 'Friday'", "What is my completion percentage for 'Gym'?",
        "List all articles from 'Medium'", "Draft a 'Project Status' report based on my tasks", "How many emails are in the 'Archive'?",
        "Summarize the 'Company Vision' notebook", "What are the action items from the 'Design Review'?", "List all notebooks in the 'Archives' folder",
        "How many habits did I complete in January?", "Show me my morning routine habits", "Draft a 'Welcome' email for 'Alice'",
        "What is the sum of 'Revenue' in 'Sales Report'?", "Summarize the 'Q4 Planning' deck", "Find all tasks due 'Today'",
        "List all spreadsheets in the 'Finance' directory", "Draft a 'Project Update' for the 'Marketing' team", "What are the tags in 'Recipe' notebook?",
        "How many tasks are completed in the last 7 days?", "Summarize the 'Onboarding' articles", "What is the location of my '2 PM' meeting?",
        "List all notebook pages with 'Draft' tag", "Draft a 'Meeting Request' for 'Bob'", "How many slides in 'Marketing Plan' have notes?",
        "Summarize the 'New Hire' space", "What is the status of 'Feature A' task?", "List all members in 'Product Team' space",
        "Calculate the median of 'Scores' in my sheet", "Show me my 'Weekly' habit view", "Draft a 'Thank You' for the 'Interview'",
        "What are the highlights of the 'Brainstorming' session?", "How many articles did I save this month?", "Summarize 'Project Alpha' notebook",
        "What is the start date of 'Vacation'?", "List all spreadsheets related to 'HR'", "Draft a 'Proposal' for 'Client X'",
        "What are my 'Evening' habits?", "How many images in 'Portfolio' deck?", "Summarize 'Tech Stack' space",
        "What is the priority of 'Fix Bug' task?", "List all notebook folders in 'Personal'", "Draft a 'Newsletter' intro",
        "What are the key points from 'Sync #10'?", "How many articles in 'Productivity'?", "Summarize 'Q1 Goals' page",
        "What is the end time of 'Meeting'?", "List all sheets in 'Inventory.xlsx'", "Draft a 'Summary' of 'Research'",
        "What are the habits in 'Fitness' category?", "How many slides in 'Sales' deck?", "Summarize 'Strategy' space",
        "What is the due date of 'Task 1'?", "List all notebooks in 'Work'", "Draft a 'Reply' to 'Recruiter'",
        "What are the notes from 'Customer Call'?", "How many articles in 'Health'?", "Summarize 'Project B' notebook",
        "What is the time of 'Gym'?", "List all spreadsheets in 'Accounting'", "Draft a 'Project Plan'",
        "What are the habits for 'Monday'?", "How many slides in 'Pitch'?", "Summarize 'Design' space",
        "What is the status of 'Task 2'?", "List all notebook folders in 'Reference'", "Draft a 'Blog Post'",
        "What are the insights from 'Data Analysis'?", "How many articles in 'Finance'?", "Summarize 'Project C' notebook",
        "What is the date of 'Deadline'?", "List all sheets in 'Data.csv'", "Draft a 'Report'",
        "What are the habits in 'Growth' category?", "How many slides in 'Review' deck?", "Summarize 'Market' space",
        "What is the level of 'Task 3'?", "List all notebooks in 'Drafts'", "Draft a 'Summary' of 'Session'",
        "What are the tags in 'Notes'?", "How many articles in 'Science'?", "Summarize 'Project D' notebook",
        "What is the location of 'Dinner'?", "List all spreadsheets in 'Admin'", "Draft a 'Checklist'",
        "What are the habits for 'Tuesday'?", "How many slides in 'Report'?", "Summarize 'Sales' space",
        "What is the owner of 'Task 4'?", "List all notebook folders in 'Project'", "Draft a 'Memo'",
        "What are the highlights of 'Launch'?", "How many articles in 'Politics'?", "Summarize 'Project E' notebook",
        "What is the time of 'Coffee'?", "List all sheets in 'Tracking'", "Draft a 'Guide'",
        "What are the habits in 'Social' category?", "How many slides in 'Intro' deck?", "Summarize 'Engineering' space",
        "What is the source of 'Task 5'?", "List all notebooks in 'Private'", "Draft a 'Plan'",
        "What are the key points of 'Update'?", "How many articles in 'Art'?", "Summarize 'Project F' notebook",
        "What is the duration of 'Call'?", "List all spreadsheets in 'Logs'", "Draft a 'Brief'",
        "What are the habits for 'Wednesday'?", "How many slides in 'Summary'?", "Summarize 'Logistics' space",
        "What is the category of 'Task 6'?", "List all notebook folders in 'Shared'", "Draft a 'Proposal'",
        "What are the takeaways from 'Seminar'?", "How many articles in 'News'?", "Summarize 'Project G' notebook",
        "What is the cost of 'Item'?", "List all sheets in 'Results'", "Draft a 'Script'",
        "What are the habits in 'Skill' category?", "How many slides in 'Demo' deck?", "Summarize 'Support' space",
        "What is the link of 'Task 7'?", "List all notebooks in 'Education'", "Draft a 'List'",
        "What are the findings of 'Study'?", "How many articles in 'History'?", "Summarize 'Project H' notebook",
        "What is the result of 'Test'?", "List all spreadsheets in 'Stats'", "Draft a 'Note'",
        "What are the habits for 'Thursday'?", "How many slides in 'Deck'?", "Summarize 'Legal' space",
        "What is the note in 'Task 8'?", "List all notebook folders in 'System'", "Draft a 'Page'",
        "What are the goals of 'Mission'?", "How many articles in 'Philosophy'?", "Summarize 'Project I' notebook",
        "What is the id of 'User'?", "List all sheets in 'Metrics'", "Draft a 'Post'",
        "What are the habits in 'Work' category?", "How many slides in 'Final' deck?", "Summarize 'Operations' space",
        "What is the comment on 'Task 9'?", "List all notebooks in 'Public'", "Draft a 'Slide'",
        "What are the results of 'Poll'?", "How many articles in 'Lifestyle'?", "Summarize 'Project J' notebook",
        "What is the value of 'Metric'?", "List all spreadsheets in 'Exports'", "Draft a 'Chart'",
        "What are the habits for 'Friday'?", "How many slides in 'Overview'?", "Summarize 'Community' space",
        "What is the detail of 'Task 10'?", "List all notebook folders in 'Archive'", "Draft a 'Table'",
        "What are the steps of 'Process'?", "How many articles in 'Culture'?", "Summarize 'Project K' notebook",
        "What is the type of 'Asset'?", "List all sheets in 'Summary'", "Draft a 'Diagram'",
        "What are the habits in 'Mental' category?", "How many slides in 'Details' deck?", "Summarize 'Training' space",
        "What is the version of 'App'?", "List all notebooks in 'Trash'", "Draft a 'Form'",
        "What are the features of 'Product'?", "How many articles in 'Economy'?", "Summarize 'Project L' notebook",
        "What is the size of 'File'?", "List all spreadsheets in 'Import'", "Draft a 'Map'",
        "What are the habits for 'Saturday'?", "How many slides in 'Backup'?", "Summarize 'Research' space",
        "What is the path of 'Folder'?", "List all notebook folders in 'Temporary'", "Draft a 'Flow'",
        "What are the requirements of 'Task'?", "How many articles in 'Sports'?", "Summarize 'Project M' notebook",
        "What is the mode of 'Run'?", "List all sheets in 'Archive'", "Draft a 'Plan'",
        "What are the habits in 'Hobby' category?", "How many slides in 'Extra' deck?", "Summarize 'Event' space",
        "What is the name of 'Project'?", "List all notebooks in 'Uncategorized'", "Draft a 'Summary'",
        "What are the objectives of 'Plan'?", "How many articles in 'Environment'?", "Summarize 'Project N' notebook",
        "What is the status of 'Sync'?", "List all spreadsheets in 'Backup'", "Draft a 'Outline'",
        "What are the habits for 'Sunday'?", "How many slides in 'Draft'?", "Summarize 'Launch' space",
        "What is the priority of 'Issue'?", "List all notebook folders in 'Old'", "Draft a 'Draft'",
        "What are the benefits of 'Tool'?", "How many articles in 'Travel'?", "Summarize 'Project O' notebook",
        "What is the output of 'Script'?", "List all sheets in 'Log'", "Draft a 'Review'",
        "What are the habits in 'Routine' category?", "How many slides in 'New' deck?", "Summarize 'Beta' space",
        "What is the input of 'Process'?", "List all notebooks in 'Synced'", "Draft a 'Proposal'",
        "What are the risks of 'Action'?", "How many articles in 'Food'?", "Summarize 'Project P' notebook",
        "What is the log of 'Error'?", "List all spreadsheets in 'Temp'", "Draft a 'Ticket'",
        "What are the habits for 'Morning'?", "How many slides in 'Presentation'?", "Summarize 'Legacy' space",
        "What is the trace of 'Bug'?", "List all notebook folders in 'Current'", "Draft a 'Doc'",
        "What are the impacts of 'Change'?", "How many articles in 'Design'?", "Summarize 'Project Q' notebook",
        "What is the effect of 'Update'?", "List all sheets in 'Stats'", "Draft a 'Guide'",
        "What are the habits in 'Evening' category?", "How many slides in 'Old' deck?", "Summarize 'Dev' space",
        "What is the cause of 'Failure'?", "List all notebooks in 'New'", "Draft a 'Wiki'",
        "What are the solutions for 'Problem'?", "How many articles in 'Tech'?", "Summarize 'Project R' notebook",
        "What is the result of 'Action'?", "List all spreadsheets in 'Results'", "Draft a 'Brief'",
        "What are the habits for 'Night'?", "How many slides in 'Complete'?", "Summarize 'Main' space",
        "What is the data of 'Record'?", "List all notebook folders in 'Main'", "Draft a 'Log'",
        "What are the findings of 'Audit'?", "How many articles in 'Business'?", "Summarize 'Project S' notebook",
        "What is the info of 'Client'?", "List all sheets in 'Report'", "Draft a 'Note'",
        "What are the habits in 'Personal' category?", "How many slides in 'Section' deck?", "Summarize 'Side' space",
        "What is the help for 'Topic'?", "List all notebooks in 'Side'", "Draft a 'Draft'",
        "What are the examples of 'Style'?", "How many articles in 'General'?", "Summarize 'Project T' notebook",
        "What is the guide for 'Tool'?", "List all spreadsheets in 'Data'", "Draft a 'Checklist'",
        "What are the habits for 'Today'?", "How many slides in 'Part'?", "Summarize 'Internal' space",
        "What is the manual for 'System'?", "List all notebook folders in 'Internal'", "Draft a 'Template'",
        "What are the tips for 'Task'?", "How many articles in 'Other'?", "Summarize 'Project U' notebook",
        "What is the code for 'Function'?", "List all sheets in 'List'", "Draft a 'Snippet'",
        "What are the habits in 'Focus' category?", "How many slides in 'Intro' deck?", "Summarize 'External' space",
        "What is the key for 'Access'?", "List all notebooks in 'External'", "Draft a 'Key'",
        "What are the rules for 'Space'?", "How many articles in 'Help'?", "Summarize 'Project V' notebook",
        "What is the value of 'Setting'?", "List all spreadsheets in 'Settings'", "Draft a 'Config'",
        "What are the habits for 'Weekly'?", "How many slides in 'End'?", "Summarize 'Private' space",
        "What is the mode of 'Operation'?", "List all notebook folders in 'Private'", "Draft a 'Script'",
        "What are the trends in 'Data'?", "How many articles in 'Update'?", "Summarize 'Project W' notebook",
        "What is the score of 'Performance'?", "List all sheets in 'Performance'", "Draft a 'Score'",
        "What are the habits in 'Productivity' category?", "How many slides in 'Analysis' deck?", "Summarize 'Global' space",
        "What is the rank of 'Item'?", "List all notebooks in 'Global'", "Draft a 'List'",
        "What are the stats of 'Usage'?", "How many articles in 'Report'?", "Summarize 'Project X' notebook",
        "What is the limit of 'Usage'?", "List all spreadsheets in 'Usage'", "Draft a 'Limit'",
        "What are the habits for 'Monthly'?", "How many slides in 'Review'?", "Summarize 'Local' space",
        "What is the path of 'Item'?", "List all notebook folders in 'Local'", "Draft a 'Path'",
        "What are the points of 'Interest'?", "How many articles in 'Interest'?", "Summarize 'Project Y' notebook",
        "What is the level of 'Access'?", "List all sheets in 'Access'", "Draft a 'Level'",
        "What are the habits in 'Learning' category?", "How many slides in 'Study' deck?", "Summarize 'Team' space",
        "What is the scope of 'Project'?", "List all notebooks in 'Team'", "Draft a 'Scope'",
        "What are the themes of 'Deck'?", "How many articles in 'Theme'?", "Summarize 'Project Z' notebook",
        "What is the version of 'Document'?", "List all spreadsheets in 'Docs'", "Draft a 'Version'",
        "What are the habits for 'Daily'?", "How many slides in 'Main'?", "Summarize 'Personal' space",
        "What is the size of 'Dataset'?", "List all notebook folders in 'Data'", "Draft a 'Size'",
        "What are the items in 'List'?", "How many articles in 'List'?", "Summarize 'Archive' notebook",
        "What is the type of 'Message'?", "List all sheets in 'Messages'", "Draft a 'Type'",
        "What are the habits in 'Health' category?", "How many slides in 'Health' deck?", "Summarize 'Health' space",
        "What is the state of 'Task'?", "List all notebooks in 'Task'", "Draft a 'State'",
        "What are the categories of 'Expenses'?", "How many articles in 'Expenses'?", "Summarize 'Expenses' notebook",
        "What is the tag of 'Article'?", "List all spreadsheets in 'Tags'", "Draft a 'Tag'",
        "What are the habits for 'Life'?", "How many slides in 'Life'?", "Summarize 'Life' space",
        "What is the source of 'Info'?", "List all notebook folders in 'Sources'", "Draft a 'Source'",
        "What are the reasons for 'Delay'?", "How many articles in 'Delays'?", "Summarize 'Delays' notebook",
        "What is the goal of 'Sprint'?", "List all spreadsheets in 'Sprints'", "Draft a 'Goal'",
        "What are the habits in 'Social' category?", "How many slides in 'Social' deck?", "Summarize 'Social' space",
        "What is the end of 'Period'?", "List all notebooks in 'Periods'", "Draft a 'Period'",
        "What are the contents of 'Box'?", "How many articles in 'Box'?", "Summarize 'Box' notebook",
        "What is the middle of 'Month'?", "List all spreadsheets in 'Months'", "Draft a 'Month'",
        "What are the habits for 'Year'?", "How many slides in 'Year'?", "Summarize 'Year' space",
        "What is the beginning of 'Week'?", "List all notebook folders in 'Weeks'", "Draft a 'Week'",
        "What are the parts of 'Machine'?", "How many articles in 'Machines'?", "Summarize 'Machines' notebook",
        "What is the weight of 'Object'?", "List all spreadsheets in 'Weights'", "Draft a 'Weight'",
        "What are the habits in 'Art' category?", "How many slides in 'Art' deck?", "Summarize 'Art' space",
        "What is the color of 'Brand'?", "List all notebooks in 'Brands'", "Draft a 'Brand'",
        "What are the effects of 'Meditation'?", "How many articles in 'Meditation'?", "Summarize 'Meditation' notebook",
        "What is the sound of 'Music'?", "List all spreadsheets in 'Music'", "Draft a 'Music'",
        "What are the habits for 'Calm'?", "How many slides in 'Calm'?", "Summarize 'Calm' space",
        "What is the taste of 'Food'?", "List all notebook folders in 'Food'", "Draft a 'Food'",
        "What are the scents of 'Nature'?", "How many articles in 'Nature'?", "Summarize 'Nature' notebook",
        "What is the touch of 'Fabric'?", "List all spreadsheets in 'Fabrics'", "Draft a 'Fabric'",
        "What are the habits in 'Science' category?", "How many slides in 'Science' deck?", "Summarize 'Science' space",
        "What is the truth of 'Fact'?", "List all notebooks in 'Facts'", "Draft a 'Fact'",
        "What are the myths of 'Story'?", "How many articles in 'Stories'?", "Summarize 'Stories' notebook",
        "What is the logic of 'Proof'?", "List all spreadsheets in 'Proofs'", "Draft a 'Proof'",
        "What are the habits for 'Mind'?", "How many slides in 'Mind'?", "Summarize 'Mind' space",
        "What is the spirit of 'Team'?", "List all notebook folders in 'Teams'", "Draft a 'Team'",
        "What are the vibes of 'Space'?", "How many articles in 'Vibes'?", "Summarize 'Vibes' notebook",
        "What is the energy of 'Work'?", "List all spreadsheets in 'Energy'", "Draft a 'Energy'",
        "What are the habits in 'Sport' category?", "How many slides in 'Sport' deck?", "Summarize 'Sport' space",
        "What is the power of 'Will'?", "List all notebooks in 'Will'", "Draft a 'Will'",
        "What are the limits of 'Body'?", "How many articles in 'Body'?", "Summarize 'Body' notebook",
        "What is the speed of 'Light'?", "List all spreadsheets in 'Light'", "Draft a 'Light'",
        "What are the habits for 'Fast'?", "How many slides in 'Fast'?", "Summarize 'Fast' space",
        "What is the depth of 'Ocean'?", "List all notebook folders in 'Ocean'", "Draft a 'Ocean'",
        "What are the heights of 'Stars'?", "How many articles in 'Stars'?", "Summarize 'Stars' notebook",
        "What is the width of 'Road'?", "List all spreadsheets in 'Roads'", "Draft a 'Road'",
        "What are the habits in 'Math' category?", "How many slides in 'Math' deck?", "Summarize 'Math' space",
        "What is the sum of 'Parts'?", "List all notebooks in 'Parts'", "Draft a 'Part'",
        "What are the products of 'Labor'?", "How many articles in 'Labor'?", "Summarize 'Labor' notebook",
        "What is the difference of 'Views'?", "List all spreadsheets in 'Views'", "Draft a 'View'",
        "What are the habits for 'Balance'?", "How many slides in 'Balance'?", "Summarize 'Balance' space",
        "What is the ratio of 'Success'?", "List all notebook folders in 'Success'", "Draft a 'Success'",
        "What are the factors of 'Growth'?", "How many articles in 'Growth'?", "Summarize 'Growth' notebook",
        "What is the percent of 'Done'?", "List all spreadsheets in 'Done'", "Draft a 'Done'",
        "What are the habits in 'English' category?", "How many slides in 'English' deck?", "Summarize 'English' space",
        "What is the meaning of 'Life'?", "List all notebooks in 'Meaning'", "Draft a 'Meaning'",
        "What are the roots of 'Word'?", "How many articles in 'Words'?", "Summarize 'Words' notebook",
        "What is the tone of 'Voice'?", "List all spreadsheets in 'Voices'", "Draft a 'Voice'",
        "What are the habits for 'Voice'?", "How many slides in 'Voice'?", "Summarize 'Voice' space",
        "What is the style of 'Writing'?", "List all notebook folders in 'Writing'", "Draft a 'Writing'",
        "What are the themes of 'Novel'?", "How many articles in 'Novels'?", "Summarize 'Novels' notebook",
        "What is the plot of 'Story'?", "List all spreadsheets in 'Plots'", "Draft a 'Plot'",
        "What are the habits in 'Reading' category?", "How many slides in 'Reading' deck?", "Summarize 'Reading' space",
        "What is the character of 'Hero'?", "List all notebooks in 'Heroes'", "Draft a 'Hero'",
        "What are the settings of 'World'?", "How many articles in 'Worlds'?", "Summarize 'Worlds' notebook",
        "What is the ending of 'Chapter'?", "List all spreadsheets in 'Chapters'", "Draft a 'Chapter'",
        "What are the habits for 'Focus'?", "How many slides in 'Focus'?", "Summarize 'Focus' space",
        "What is the start of 'Journey'?", "List all notebook folders in 'Journeys'", "Draft a 'Journey'",
        "What are the milestones of 'Project'?", "How many articles in 'Milestones'?", "Summarize 'Milestones' notebook",
        "What is the peak of 'Mountain'?", "List all spreadsheets in 'Mountains'", "Draft a 'Mountain'",
        "What are the habits in 'Hiking' category?", "How many slides in 'Hiking' deck?", "Summarize 'Hiking' space",
        "What is the flow of 'River'?", "List all notebooks in 'Rivers'", "Draft a 'River'",
        "What are the banks of 'Stream'?", "How many articles in 'Streams'?", "Summarize 'Streams' notebook",
        "What is the delta of 'Change'?", "List all spreadsheets in 'Deltas'", "Draft a 'Delta'",
        "What are the habits for 'Change'?", "How many slides in 'Change'?", "Summarize 'Change' space",
        "What is the spark of 'Idea'?", "List all notebook folders in 'Ideas'", "Draft a 'Idea'",
        "What are the flames of 'Passion'?", "How many articles in 'Passion'?", "Summarize 'Passion' notebook",
        "What is the heat of 'Summer'?", "List all spreadsheets in 'Summers'", "Draft a 'Summer'",
        "What are the habits in 'Winter' category?", "How many slides in 'Winter' deck?", "Summarize 'Winter' space",
        "What is the cold of 'Ice'?", "List all notebooks in 'Ice'", "Draft a 'Ice'",
        "What are the winds of 'North'?", "How many articles in 'North'?", "Summarize 'North' notebook",
        "What is the rain of 'Spring'?", "List all spreadsheets in 'Springs'", "Draft a 'Spring'",
        "What are the habits for 'Renew'?", "How many slides in 'Renew'?", "Summarize 'Renew' space",
        "What is the leaf of 'Tree'?", "List all notebook folders in 'Trees'", "Draft a 'Tree'",
        "What are the branches of 'Knowledge'?", "How many articles in 'Knowledge'?", "Summarize 'Knowledge' notebook",
        "What is the seed of 'Plan'?", "List all spreadsheets in 'Seeds'", "Draft a 'Seed'",
        "What are the habits in 'Gardening' category?", "How many slides in 'Gardening' deck?", "Summarize 'Gardening' space",
        "What is the bloom of 'Flower'?", "List all notebooks in 'Flowers'", "Draft a 'Flower'",
        "What are the thorns of 'Problem'?", "How many articles in 'Thorns'?", "Summarize 'Thorns' notebook",
        "What is the scent of 'Rose'?", "List all spreadsheets in 'Roses'", "Draft a 'Rose'",
        "What are the habits for 'Beauty'?", "How many slides in 'Beauty'?", "Summarize 'Beauty' space",
        "What is the shadow of 'Doubt'?", "List all notebook folders in 'Shadows'", "Draft a 'Shadow'",
        "What are the rays of 'Hope'?", "How many articles in 'Hope'?", "Summarize 'Hope' notebook",
        "What is the light of 'Truth'?", "List all spreadsheets in 'Truths'", "Draft a 'Truth'",
        "What are the habits in 'Ethic' category?", "How many slides in 'Ethic' deck?", "Summarize 'Ethic' space",
        "What is the weight of 'Gold'?", "List all notebooks in 'Gold'", "Draft a 'Gold'",
        "What are the prices of 'Silver'?", "How many articles in 'Silver'?", "Summarize 'Silver' notebook",
        "What is the value of 'Time'?", "List all spreadsheets in 'Time'", "Draft a 'Time'",
        "What are the habits for 'Value'?", "How many slides in 'Value'?", "Summarize 'Value' space",
        "What is the core of 'Earth'?", "List all notebook folders in 'Earth'", "Draft a 'Earth'",
        "What are the crusts of 'Bread'?", "How many articles in 'Bread'?", "Summarize 'Bread' notebook",
        "What is the air of 'Sky'?", "List all spreadsheets in 'Sky'", "Draft a 'Sky'",
        "What are the habits in 'Flight' category?", "How many slides in 'Flight' deck?", "Summarize 'Flight' space",
        "What is the wing of 'Bird'?", "List all notebooks in 'Birds'", "Draft a 'Bird'",
        "What are the feathers of 'Tail'?", "How many articles in 'Tails'?", "Summarize 'Tails' notebook",
        "What is the beak of 'Eagle'?", "List all spreadsheets in 'Eagles'", "Draft a 'Eagle'",
        "What are the habits for 'High'?", "How many slides in 'High'?", "Summarize 'High' space",
        "What is the scale of 'Map'?", "List all notebook folders in 'Maps'", "Draft a 'Map'",
        "What are the symbols of 'State'?", "How many articles in 'States'?", "Summarize 'States' notebook",
        "What is the border of 'Land'?", "List all spreadsheets in 'Lands'", "Draft a 'Land'",
        "What are the habits in 'Travel' category?", "How many slides in 'Travel' deck?", "Summarize 'Travel' space",
        "What is the path of 'Traveler'?", "List all notebooks in 'Travelers'", "Draft a 'Traveler'",
        "What are the bags of 'Guest'?", "How many articles in 'Guests'?", "Summarize 'Guests' notebook",
        "What is the key of 'Room'?", "List all spreadsheets in 'Rooms'", "Draft a 'Room'",
        "What are the habits for 'Rest'?", "How many slides in 'Rest'?", "Summarize 'Rest' space",
        "What is the view of 'Window'?", "List all notebook folders in 'Windows'", "Draft a 'Window'",
        "What are the frames of 'Art'?", "How many articles in 'Frames'?", "Summarize 'Frames' notebook",
        "What is the glass of 'Mirror'?", "List all spreadsheets in 'Mirrors'", "Draft a 'Mirror'",
        "What are the habits in 'Design' category?", "How many slides in 'Design' deck?", "Summarize 'Design' space"
    ]

    enum PersonaHomeModal: Identifiable {
        case chats
        case settings
        case discovery
        case actions
        case exportOptions
        case shareSheet(data: Data, filename: String)

        var id: String {
            switch self {
            case .chats: return "chats"
            case .settings: return "settings"
            case .discovery: return "discovery"
            case .actions: return "actions"
            case .exportOptions: return "exportOptions"
            case .shareSheet: return "shareSheet"
            }
        }
    }

    private var lastAssistantContent: String? {
        guard let message = manager.chatHistory.last, message.role == "assistant" else {
            return nil
        }
        return message.content
    }

    private var followUpSuggestions: [String] {
        guard let content = lastAssistantContent else {
            return []
        }
        return suggestedFollowUps(for: content)
    }

    var body: some View {
        ZStack {
            PersonaHomeNavigationContent(
                chatHistory: manager.chatHistory,
                isThinking: manager.isThinking,
                agentMode: agentModeEnabled,
                query: $query,
                followUpSuggestions: followUpSuggestions,
                pendingAction: pendingAction,
                onPromptSelection: selectPromptAndSend(_:),
                onSend: sendMessage,
                onOpenDiscovery: openDiscovery,
                onOpenChats: openChats,
                onOpenActions: { activeModal = .actions },
                onNeedScroll: scrollToBottom,
                onConfirm: handleConfirmation(_:)
            )
        }
        .aiAnimationLoading(manager.isThinking)
        .navigationTitle("AI Persona")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            PersonaHomeToolbar(
                agentMode: $agentModeEnabled,
                onShowWelcome: { activeModal = .discovery },
                onShowTuning: { activeModal = .settings }
            )
        }
        .onAppear(perform: handleOnAppear)
        .sheet(item: $activeModal) { modal in
            PersonaHomeModalContent(
                modal: modal,
                manager: manager,
                allPrompts: allPrompts,
                onPromptSelection: selectPromptAndSend(_:),
                onThreadSelection: continueChat(_:),
                activeModal: $activeModal
            )
        }
    }

    private func handleOnAppear() {
        if manager.chatHistory.isEmpty && !hasShownWelcome {
            activeModal = .discovery
            hasShownWelcome = true
        }
    }

    private func openDiscovery() {
        activeModal = .discovery
    }

    private func openChats() {
        hydrateThreadsIfNeeded()
        activeModal = .chats
    }

    private func hydrateThreadsIfNeeded() {
        if chatThreads.isEmpty {
            let seed = PersonaChatThread(title: "Current Chat", messages: manager.chatHistory, updatedAt: Date())
            chatThreads = [seed]
            activeThreadID = seed.id
            manager.chatThreads = chatThreads
        }
    }

    private func upsertActiveThread() {
        guard let activeThreadID else { return }
        guard let idx = chatThreads.firstIndex(where: { $0.id == activeThreadID }) else { return }
        let preview = manager.chatHistory.first?.content ?? "New Chat"
        let name = chatThreads[idx].title == "New Chat" && !preview.isEmpty ? String(preview.prefix(42)) : chatThreads[idx].title
        chatThreads[idx].messages = manager.chatHistory
        chatThreads[idx].title = name
        chatThreads[idx].updatedAt = Date()
    }

    private func startNewChat() {
        let thread = PersonaChatThread()
        manager.threads.insert(thread, at: 0)
        manager.activeThread = thread
        chatThreads = manager.threads
        activeThreadID = thread.id
        manager.chatHistory = []
        manager.saveChatHistory()
    }

    private func continueChat(_ thread: PersonaChatThread) {
        activeThreadID = thread.id
        manager.chatHistory = thread.messages
        manager.saveChatHistory()
    }

    private func selectPromptAndSend(_ prompt: String) {
        query = prompt
        sendMessage()
    }

    private func sendMessage() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        query = ""

        manager.agentModeEnabled = agentModeEnabled

        if agentModeEnabled {
            Task {
                await processAgentMessage(trimmed)
            }
        } else {
            Task {
                await manager.queryPersonaSafely(query: trimmed)
            }
        }
    }

    private func processAgentMessage(_ input: String) async {
        let history = await MainActor.run { manager.chatHistory }
        let engine = PersonaAgentFramework.PersonaIntentEngine()
        let dispatcher = PersonaAgentFramework.PersonaActionDispatcher()

        let contacts = await MainActor.run { AccountManager.shared.accounts.map { PersonaAgentFramework.PersonaContact(name: $0.displayName, email: $0.emailAddress) } }
        let context = PersonaAgentFramework.PersonaWorkspaceContext(contacts: contacts, lastAccessedNote: nil, activeDraft: nil, recentEmails: [])

        let userMsg = PersonaMessage(role: "user", content: input)
        await MainActor.run {
            manager.chatHistory.append(userMsg)
            manager.isThinking = true
        }

        var finalIntent: PersonaAgentFramework.PersonaIntent

        let missingField = await MainActor.run { clarificationMissingField }
        let currentPendingIntent = await MainActor.run { pendingIntent }

        if let missingField = missingField, var intent = currentPendingIntent {
            // Fill missing field in existing intent
            switch intent {
            case .sendEmail(var params):
                if missingField == "recipients" { params.recipients = [input] }
                intent = .sendEmail(parameters: params)
            case .createNote(var params):
                if missingField == "body" { params.body = input }
                intent = .createNote(parameters: params)
            default: break
            }
            finalIntent = intent
            await MainActor.run {
                self.clarificationMissingField = nil
                self.pendingIntent = nil
            }
        } else {
            finalIntent = await engine.classify(input: input, conversationHistory: history, workspaceContext: context)
        }

        if case .compound(let steps) = finalIntent {
            for step in steps {
                let stepResult = await dispatcher.dispatch(step, in: context)
                await handleActionResult(stepResult, intent: step)
                if case .failed = stepResult { break }
            }
        } else {
            let result = await dispatcher.dispatch(finalIntent, in: context)
            await handleActionResult(result, intent: finalIntent)
        }

        await MainActor.run { manager.isThinking = false }
    }

    func handleConfirmation(_ confirmed: Bool) {
        guard confirmed else {
            pendingAction = nil
            pendingIntent = nil
            return
        }

        guard let intent = pendingIntent else {
            pendingAction = nil
            return
        }

        Task {
            let dispatcher = PersonaAgentFramework.PersonaActionDispatcher()
            let contacts = await MainActor.run { AccountManager.shared.accounts.map { PersonaAgentFramework.PersonaContact(name: $0.displayName, email: $0.emailAddress) } }
            let context = PersonaAgentFramework.PersonaWorkspaceContext(contacts: contacts, lastAccessedNote: nil, activeDraft: nil, recentEmails: [])

            // Execute the intent directly now that it's confirmed
            let result: PersonaAgentFramework.PersonaActionResult
            switch intent {
            case .deleteNote(let id):
                result = .from(try! await PersonaAgentFramework.shared.execute(.deleteWorkspaceItem(id: id, type: .note)))
            case .deleteEvent(let params):
                result = .from(try! await PersonaAgentFramework.shared.execute(.deleteEvent(parameters: params)))
            case .deleteTask(let id):
                result = .from(try! await PersonaAgentFramework.shared.execute(.deleteTask(id: id)))
            default:
                result = .failed(error: .serviceUnavailable("Confirmation logic for this intent not implemented"))
            }

            await MainActor.run {
                self.pendingAction = nil
                self.pendingIntent = nil
            }
            await handleActionResult(result, intent: intent)
        }
    }

    private func handleActionResult(_ result: PersonaAgentFramework.PersonaActionResult, intent: PersonaAgentFramework.PersonaIntent) async {
        switch result {
        case .success(let summary, _):
            let msg = PersonaMessage(role: "assistant", content: summary)
            await MainActor.run { manager.chatHistory.append(msg) }
        case .requiresConfirmation(let preview):
            await MainActor.run {
                self.pendingAction = preview
                self.pendingIntent = intent
            }
        case .failed(let error):
            let msg = PersonaMessage(role: "assistant", content: "Error: \(error.localizedDescription)")
            await MainActor.run { manager.chatHistory.append(msg) }
        case .clarificationNeeded(let question, let missingField):
            let msg = PersonaMessage(role: "assistant", content: question)
            await MainActor.run {
                manager.chatHistory.append(msg)
                self.clarificationMissingField = missingField
                self.pendingIntent = intent
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation {
            if manager.isThinking {
                proxy.scrollTo("thinking", anchor: .bottom)
            } else if let lastId = manager.chatHistory.last?.id {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }

    private func suggestedFollowUps(for content: String) -> [String] {
        // Simple logic to provide context-aware follow-ups
        if content.contains("meeting") || content.contains("calendar") {
            return ["Show me the agenda", "Draft a follow-up", "Who else is invited?"]
        } else if content.contains("task") || content.contains("to-do") {
            return ["Set a reminder", "Mark as complete", "Show overdue tasks"]
        } else if content.contains("habit") || content.contains("streak") {
            return ["How can I improve?", "Compare with last week", "Log today's progress"]
        } else if content.contains("email") || content.contains("mail") {
            return ["Summarize all unread", "Reply to this", "Show more from this sender"]
        }
        return ["Explain more", "Show related notes", "Summarize this"]
    }
}

private struct PersonaHomeNavigationContent: View {
    let chatHistory: [PersonaMessage]
    let isThinking: Bool
    let agentMode: Bool
    @Binding var query: String
    let followUpSuggestions: [String]
    let pendingAction: PersonaAgentFramework.PersonaActionPreview?
    let onPromptSelection: (String) -> Void
    let onSend: () -> Void
    let onOpenDiscovery: () -> Void
    let onOpenChats: () -> Void
    let onOpenActions: () -> Void
    let onNeedScroll: (ScrollViewProxy) -> Void
    let onConfirm: (Bool) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#0A0F1E")
                .opacity(agentMode ? 0.35 : 0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                PersonaChatTimelineView(
                    chatHistory: chatHistory,
                    isThinking: isThinking,
                    onDiscoverPrompts: onOpenDiscovery,
                    onNeedScroll: onNeedScroll
                )

                PersonaComposerView(
                    query: $query,
                    isThinking: isThinking,
                    followUpSuggestions: followUpSuggestions,
                    onTapPrompt: onPromptSelection,
                    onSend: onSend,
                    onOpenDiscovery: onOpenDiscovery,
                    onOpenChats: onOpenChats,
                    onOpenActions: onOpenActions
                )
            }

            if let action = pendingAction {
                PersonaActionConfirmationCard(preview: action) { confirmed in
                    onConfirm(confirmed)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding()
                .zIndex(2)
            }

            if agentMode {
                PersonaAgentCommandSurface()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
    }
}

private enum PersonaAgentIndicatorState {
    case idle
    case thinking
    case acting
    case error
}

private struct AgentActionFeedEvent: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let timestamp: Date
    let tint: Color
}

private struct PersonaAgentCommandSurface: View {
    @Namespace private var panelNamespace

    @State private var command = ""
    @State private var events: [AgentActionFeedEvent] = []
    @State private var status: PersonaAgentIndicatorState = .idle
    @State private var isExpanded = false
    @State private var isExecuting = false
    @State private var pulse = false

    var body: some View {
        VStack {
            Spacer()

            Group {
                if isExpanded {
                    expandedPanel
                        .matchedGeometryEffect(id: "agent-panel", in: panelNamespace)
                } else {
                    compactPill
                        .matchedGeometryEffect(id: "agent-panel", in: panelNamespace)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 100) // Elevated to avoid composer overlap
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isExpanded)
        .onAppear {
            pulse = true
        }
    }

    private var compactPill: some View {
        Button {
            isExpanded = true
        } label: {
            HStack(spacing: 10) {
                statusDot
                Text(lastActionLabel)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color(hex: "#3D8EFF").opacity(0.35), lineWidth: 1))
    }

    private var expandedPanel: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                statusDot
                VStack(alignment: .leading, spacing: 2) {
                    Text("Agent Mode")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(lastActionLabel)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)
                }
                Spacer()
                Button {
                    isExpanded = false
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(8)
                        .background(Color.white.opacity(0.08), in: Circle())
                }
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    if events.isEmpty && !isExecuting {
                        Text("No actions yet")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.45))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    }

                    ForEach(events) { event in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: event.icon)
                                .foregroundStyle(event.tint)
                                .frame(width: 14, height: 14)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.label)
                                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.92))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(event.timestamp, style: .time)
                                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                    }

                    if isExecuting {
                        ForEach(0..<2, id: \.self) { _ in
                            PersonaAgentShimmerRow()
                        }
                    }
                }
            }
            .frame(maxHeight: 180)

            HStack(spacing: 10) {
                TextField("Run action", text: $command)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.white)
                    .submitLabel(.go)
                    .onSubmit {
                        runCommand()
                    }

                Button("Run") {
                    runCommand()
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#3D8EFF"))
                .disabled(command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isExecuting)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: "#3D8EFF").opacity(0.3), lineWidth: 1))
    }

    private var lastActionLabel: String {
        events.first?.label ?? "No actions yet"
    }

    private var statusDot: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)
            .scaleEffect(pulse ? 1.0 : 0.72)
            .animation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true), value: pulse)
    }

    private var statusColor: Color {
        switch status {
        case .idle: return Color(hex: "#3D8EFF")
        case .thinking: return .orange
        case .acting: return .green
        case .error: return .red
        }
    }

    private func runCommand() {
        let raw = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }

        command = ""
        status = .thinking
        isExecuting = true

        Task {
            do {
                let action = try parseAction(from: raw)
                await MainActor.run { status = .acting }

                let result = try await PersonaAgentFramework.shared.execute(action)
                await MainActor.run {
                    appendEvent(for: result, actionText: raw)
                    status = .idle
                    isExecuting = false
                }
            } catch {
                await MainActor.run {
                    status = .error
                    events.insert(
                        AgentActionFeedEvent(
                            icon: "exclamationmark.triangle.fill",
                            label: "Error: \(error.localizedDescription)",
                            timestamp: Date(),
                            tint: .red
                        ),
                        at: 0
                    )
                    isExecuting = false
                }
            }
        }
    }

    private func parseAction(from raw: String) throws -> AgentAction {
        let lower = raw.lowercased()
        let parts = raw.split(separator: " ").map(String.init)

        if lower == "list" || lower.hasPrefix("list ") {
            return .listWorkspaceItems(filter: WorkspaceFilter())
        }

        if lower.hasPrefix("read "), parts.count >= 2 {
            return .readWorkspaceItem(id: parts[1])
        }

        if lower.hasPrefix("delete note "), parts.count >= 3 {
            return .deleteWorkspaceItem(id: parts[2], type: .note)
        }

        if lower.hasPrefix("delete slide "), parts.count >= 3 {
            return .deleteWorkspaceItem(id: parts[2], type: .slideDeck)
        }

        if lower.hasPrefix("delete form "), parts.count >= 3 {
            return .deleteWorkspaceItem(id: parts[2], type: .form)
        }

        if lower.hasPrefix("delete email "), parts.count >= 3 {
            return .deleteWorkspaceItem(id: parts[2], type: .emailDraft)
        }

        if lower.hasPrefix("edit note "), parts.count >= 3 {
            let id = parts[2]
            let body = raw.components(separatedBy: "::").dropFirst().joined(separator: "::").trimmingCharacters(in: .whitespaces)
            return .editNote(id: id, newTitle: nil, newBody: body.isEmpty ? "Updated by Persona Agent" : body)
        }

        return .listWorkspaceItems(filter: WorkspaceFilter())
    }

    private func appendEvent(for result: AgentActionResult, actionText: String) {
        switch result {
        case .success(let payload):
            let label: String
            switch payload {
            case .message(let message):
                label = message
            case .itemSnapshot(let snapshot):
                label = "\(snapshot.type.rawValue): \(snapshot.title)"
            case .itemSummaries(let summaries):
                label = "Listed \(summaries.count) workspace item(s)"
            }

            events.insert(
                AgentActionFeedEvent(
                    icon: "checkmark.circle.fill",
                    label: label,
                    timestamp: Date(),
                    tint: .green
                ),
                at: 0
            )

        case .failure(let error):
            events.insert(
                AgentActionFeedEvent(
                    icon: "xmark.octagon.fill",
                    label: "\(actionText): \(error.localizedDescription)",
                    timestamp: Date(),
                    tint: .red
                ),
                at: 0
            )
            status = .error
        }
    }
}

private struct PersonaAgentShimmerRow: View {
    @State private var animate = false

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(0.08))
            .frame(height: 44)
            .overlay(
                LinearGradient(
                    colors: [Color.clear, Color.white.opacity(0.25), Color.clear],
                    startPoint: animate ? .leading : .trailing,
                    endPoint: animate ? .trailing : .leading
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            )
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    animate.toggle()
                }
            }
    }
}

private struct PersonaHomeToolbar: ToolbarContent {
    @Binding var agentMode: Bool
    let onShowWelcome: () -> Void
    let onShowTuning: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack {
                Toggle(isOn: $agentMode) {
                    Label("Agent", systemImage: "bolt.shield")
                }
                .toggleStyle(.button)
                .tint(.orange)

                Button(action: onShowTuning) {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }

        ToolbarItem(placement: .topBarLeading) {
            Button(action: onShowWelcome) {
                Image(systemName: "info.circle")
            }
        }
    }
}

private struct PersonaHomeModalContent: View {
    let modal: PersonaHomeView.PersonaHomeModal
    @ObservedObject var manager: PersonaManager
    let allPrompts: [String]
    let onPromptSelection: (String) -> Void
    let onThreadSelection: (PersonaChatThread) -> Void
    @Binding var activeModal: PersonaHomeView.PersonaHomeModal?

    var body: some View {
        Group {
            switch modal {
            case .settings:
                TuningSheetView(manager: manager) {
                    activeModal = .exportOptions
                }
                .presentationDetents([.medium])
            case .discovery:
                PromptDiscoveryView(allPrompts: allPrompts, onSelect: onPromptSelection)
                    .presentationDetents([.medium])
            case .chats:
                PersonaChatHistorySheet(
                    threads: $manager.chatThreads,
                    activeThreadID: .constant(nil),
                    onCreateNew: {
                        let thread = PersonaChatThread()
                        manager.chatThreads.insert(thread, at: 0)
                        onThreadSelection(thread)
                    },
                    onContinue: onThreadSelection
                )
            case .actions:
                PersonaAgentActionGalleryView()
                    .presentationDetents([.medium, .large])
            case .exportOptions:
                PersonaExportOptionsView(
                    messages: manager.chatHistory,
                    persona: manager.config,
                    agentMode: manager.agentModeEnabled
                ) { data, filename in
                    activeModal = .shareSheet(data: data, filename: filename)
                }
                .presentationDetents([.height(300)])
            case .shareSheet(let data, let filename):
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                let _ = try? data.write(to: url)
                ShareSheet(activityItems: [url])
            }
        }
    }
}

private struct PersonaChatTimelineView: View {
    let chatHistory: [PersonaMessage]
    let isThinking: Bool
    let onDiscoverPrompts: () -> Void
    let onNeedScroll: (ScrollViewProxy) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            List {
                Group {
                    if chatHistory.isEmpty {
                        PersonaEmptyStateView(onDiscoverPrompts: onDiscoverPrompts)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(chatHistory) { message in
                            PersonaChatBubble(message: message)
                                .id(message.id)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    if isThinking {
                        ThinkingIndicator()
                            .id("thinking")
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .background(Color.clear)
            .onChange(of: chatHistory.count) { _, _ in onNeedScroll(proxy) }
            .onChange(of: isThinking) { _, thinking in if thinking { onNeedScroll(proxy) } }
        }
    }
}

private struct PersonaComposerView: View {
    @Binding var query: String
    let isThinking: Bool
    let followUpSuggestions: [String]
    let onTapPrompt: (String) -> Void
    let onSend: () -> Void
    let onOpenDiscovery: () -> Void
    let onOpenChats: () -> Void
    let onOpenActions: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            if !followUpSuggestions.isEmpty {
                PersonaFollowUpsView(suggestions: followUpSuggestions, onSelect: onTapPrompt)
            }
            PersonaInputPanelView(
                query: $query,
                isThinking: isThinking,
                onSend: onSend,
                onOpenDiscovery: onOpenDiscovery,
                onOpenChats: onOpenChats,
                onOpenActions: onOpenActions
            )
        }
        .background(.ultraThinMaterial)
    }
}

private struct PersonaQuickActionsView: View {
    let onTapAction: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickActionChip(icon: "bolt.fill", label: "Catch Up", action: { onTapAction("Catch up on my day") })
                QuickActionChip(icon: "calendar", label: "Schedule", action: { onTapAction("What is my schedule for today?") })
                QuickActionChip(icon: "exclamationmark.circle", label: "Priorities", action: { onTapAction("What are my top priorities?") })
                QuickActionChip(icon: "envelope.fill", label: "Unread Mail", action: { onTapAction("Summarize my unread emails") })
            }
            .padding(.horizontal)
        }
    }
}

private struct QuickActionChip: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.1), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
            .foregroundStyle(.white)
        }
    }
}

private struct PersonaEmptyStateView: View {
    let onDiscoverPrompts: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(.top, 100)
                .shadow(color: .purple.opacity(0.5), radius: 20)

            Text("Your Workspace Intelligence").font(.title2.bold())
            Text("Ask anything about your Mail, Tasks, Files, and Habits.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 40)
            Button(action: onDiscoverPrompts) { Label("Discover Prompts", systemImage: "lightbulb.fill").font(.headline).padding().background(Color.accentColor.opacity(0.1), in: Capsule()) }
                .padding(.top, 20)
        }
    }
}

private struct PersonaChatBubble: View {
    let message: PersonaMessage
    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer() }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                PersonaMarkdownBubbleText(markdown: message.content, isUser: isUser)
                    .padding(14)
                    .background(PersonaMessageBubbleBackground(isUser: isUser))
                    .foregroundStyle(isUser ? Color.white : Color.primary)
                    .shadow(color: isUser ? .purple.opacity(0.3) : .black.opacity(0.05), radius: 5, y: 2)
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.content
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }

                Text(message.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
            }

            if !isUser { Spacer() }
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: isUser ? .trailing : .leading).combined(with: .opacity),
                removal: .opacity
            )
        )
    }
}

private struct PersonaMessageBubbleBackground: View {
    let isUser: Bool

    var body: some View {
        if isUser {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 1))
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }
}

private struct PersonaFollowUpsView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(suggestion) { onSelect(suggestion) }
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

private struct PersonaInputPanelView: View {
    @Binding var query: String
    let isThinking: Bool
    let onSend: () -> Void
    let onOpenDiscovery: () -> Void
    let onOpenChats: () -> Void
    let onOpenActions: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Button(action: onOpenDiscovery) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                }
                .help("Discover Prompts")

                Button(action: onOpenActions) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.orange)
                }
                .help("Agent Actions")
            }

            Button(action: onOpenChats) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .help("Chat History")

            TextField("Message Persona...", text: $query, axis: .vertical)
                .padding(12)
                .background(.white.opacity(0.08))
                .cornerRadius(22)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .lineLimit(1...5)
            PersonaSendButton(isDisabled: query.isEmpty || isThinking, onSend: onSend)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

private struct PersonaSendButton: View {
    let isDisabled: Bool
    let onSend: () -> Void

    var body: some View {
        Button(action: onSend) {
            ZStack {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .opacity(isDisabled ? 1 : 0)

                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
                    )
                    .opacity(isDisabled ? 0 : 1)
            }
            .shadow(color: isDisabled ? .clear : .purple.opacity(0.4), radius: 8)
        }
        .disabled(isDisabled)
    }
}

struct PersonaActionConfirmationCard: View {
    let preview: PersonaAgentFramework.PersonaActionPreview
    let onDecision: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(.orange)
                Text("Confirm Action")
                    .font(.headline)
            }

            Text(preview.intentDescription)
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(preview.parameterSummary.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text("\(key):")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(value)
                            .font(.caption)
                    }
                }
            }

            if let warning = preview.warningMessage {
                Text(warning)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 12) {
                Button("Cancel", role: .cancel) { onDecision(false) }
                    .buttonStyle(.bordered)

                Button("Confirm") { onDecision(true) }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
    }
}

private struct PersonaMarkdownBubbleText: View {
    let markdown: String
    let isUser: Bool

    var body: some View {
        // Robust markdown parsing using AttributedString
        Text(MarkdownSyntaxStripper.plainText(from: markdown))
    }

    private func cleanMarkdown(_ text: String) -> String {
        text.replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "#", with: "")
    }
}

struct PromptDiscoveryView: View {
    let allPrompts: [String]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var discoveryPrompts: [String] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Select a prompt to get started with Persona.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(discoveryPrompts, id: \.self) { prompt in
                    Button {
                        onSelect(prompt)
                        dismiss()
                    } label: {
                        HStack {
                            Text(prompt)
                                .font(.system(size: 14))
                            Spacer()
                            Image(systemName: "sparkles")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button {
                        refresh()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Shuffle Prompts", systemImage: "shuffle")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                refresh()
            }
        }
    }

    private func refresh() {
        discoveryPrompts = Array(allPrompts.shuffled().prefix(10))
    }
}

struct ThinkingIndicator: View {
    @State private var animStep = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                            .frame(width: 8, height: 8)
                            .scaleEffect(animStep == index ? 1.2 : 0.8)
                            .opacity(animStep == index ? 1.0 : 0.4)
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
            Spacer()
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                animStep = (animStep + 1) % 3
            }
        }
    }
}

struct WelcomePersonaView: View {
    @State private var gradientStart = UnitPoint.topLeading
    @State private var gradientEnd = UnitPoint.bottomTrailing
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraGlow(.dramatic)
                    .palette(.appleIntelligence)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 80))
                            .symbolEffect(.pulse.byLayer, options: .nonRepeating)
                            .foregroundStyle(LinearGradient(colors: [.blue, .purple, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .padding(.top, 40)
                            .shadow(color: .purple.opacity(0.5), radius: 30)

                        VStack(spacing: 8) {
                            Text("Welcome to Persona")
                                .font(.system(size: 34, weight: .bold))
                            Text("Your Personal Workspace AI")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 25) {
                            PersonaInfoRow(icon: "brain.head.profile", title: "Intelligent Analysis", detail: "Persona analyzes your Mail, Calendar, Tasks, and more to provide context-aware insights.")
                            PersonaInfoRow(icon: "bubble.left.and.bubble.right", title: "Natural Chat", detail: "Talk to your data naturally. Ask questions, draft replies, or plan your week effortlessly.")
                            PersonaInfoRow(icon: "lock.shield", title: "Secure & Private", detail: "All data processing happens within your workspace. We prioritize your privacy and data sovereignty.")
                        }
                        .padding(30)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32))
                        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)

                        Button {
                            dismiss()
                        } label: {
                            Text("Get Started")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing), in: Capsule())
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct TuningSheetView: View {
    @ObservedObject var manager: PersonaManager
    @Environment(\.dismiss) var dismiss
    let onExport: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Persona Identity")) {
                    TextField("Name", text: $manager.config.name)
                    VStack(alignment: .leading) {
                        Text("Instructions").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $manager.config.instructions)
                            .frame(height: 80)
                    }
                }

                Section(header: Text("Training & Data")) {
                    Toggle("Train Persona With My Data", isOn: $manager.config.isTrainingEnabled)
                    Text("Interaction pairs are used to improve the Persona's future responses. This can be disabled at any time.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        onExport()
                    } label: {
                        Label("Export Chat", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        manager.clearHistory()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Clear Chat History")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Tuning")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        manager.saveConfig()
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct PersonaInfoRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 35)

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}


private struct PersonaChatHistorySheet: View {
    @Binding var threads: [PersonaChatThread]
    @Binding var activeThreadID: UUID?
    let onCreateNew: () -> Void
    let onContinue: (PersonaChatThread) -> Void

    var body: some View { NavigationStack { List { Button("New Chat", action: onCreateNew)
            ForEach($threads) { $thread in
                VStack(alignment: .leading) {
                    TextField("Chat name", text: $thread.title)
                    Button("Continue") { onContinue(thread) }
                }
            }.onDelete { threads.remove(atOffsets: $0) }
        }.navigationTitle("Chats") } }
}

struct PersonaAgentActionGalleryView: View {
    @Environment(\.dismiss) var dismiss

    let actions = [
        ("note.text.badge.plus", "Create Note", "Draft a new workspace note", "Create a note about..."),
        ("envelope.badge.fill", "Draft Email", "Prepare a mail response", "Draft an email to..."),
        ("chart.bar.doc.horizontal", "Analyze Data", "Summarize spreadsheets", "Analyze my budget..."),
        ("calendar.badge.clock", "Schedule Sync", "Update calendar events", "Schedule a meeting with...")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Select an agentic action to perform within your workspace.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(actions, id: \.1) { icon, title, subtitle, prompt in
                    Button {
                        // In a real app, this would pre-fill the query or trigger a tool
                        dismiss()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(.orange)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.headline)
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .navigationTitle("Agent Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct PersonaExportOptionsView: View {
    let messages: [PersonaMessage]
    let persona: PersonaConfig
    let agentMode: Bool
    let onExport: (Data, String) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var includeActions = true
    @State private var includeTokens = false
    @State private var dateRange = "All time"

    var body: some View {
        NavigationStack {
            List {
                Toggle("Include agent action log", isOn: $includeActions)
                Toggle("Include token counts", isOn: $includeTokens)

                Picker("Date range", selection: $dateRange) {
                    ForEach(["All time", "Today", "Last 7 days"], id: \.self) { Text($0) }
                }

                Section {
                    Button {
                        do {
                            let data = try PersonaChatExporter.export(
                                messages: messages,
                                actions: [], // Actions log can be integrated if stored
                                persona: persona,
                                agentMode: agentMode,
                                conversationID: UUID(), // Thread ID
                                includeTokens: includeTokens
                            )
                            let dateStr = DateFormatter.yyyyMMdd.string(from: Date())
                            let filename = "\(persona.name.replacingOccurrences(of: " ", with: "_"))_Chat_\(dateStr).json"
                            onExport(data, filename)
                        } catch {
                            print("Export failed: \(error)")
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Export Now").bold()
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Export Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}
