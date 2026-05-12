import SwiftUI

struct PersonaHomeView: View {
    @ObservedObject private var manager = PersonaManager.shared
    @State private var query = ""
    @AppStorage("persona.welcome_shown") private var hasShownWelcome = false
    @State private var activeModal: PersonaHomeModal?
    @State private var shuffledPrompts: [String] = []
    @State private var showAgenticRuntime = false

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

    enum PersonaHomeModal: String, Identifiable, Sendable {
        case welcome
        case tuning
        case discovery

        var id: String { rawValue }
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
        PersonaHomeNavigationContent(
            chatHistory: manager.chatHistory,
            isThinking: manager.isThinking,
            query: $query,
            shuffledPrompts: shuffledPrompts,
            followUpSuggestions: followUpSuggestions,
            onPromptSelection: selectPromptAndSend(_:),
            onSend: sendMessage,
            onOpenDiscovery: openDiscovery,
            onNeedScroll: scrollToBottom
        )
        .navigationTitle("AI Persona")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            PersonaHomeToolbar(
                onShowWelcome: { activeModal = .welcome },
                onShowTuning: { activeModal = .tuning }
            )
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAgenticRuntime = true
                } label: {
                    Image(systemName: "cpu")
                }
                .accessibilityLabel("Agentic Runtime")
            }
        }
        .onAppear(perform: handleOnAppear)
        .sheet(item: $activeModal) { modal in
            PersonaHomeModalContent(
                modal: modal,
                manager: manager,
                allPrompts: allPrompts,
                onPromptSelection: selectPromptAndSend(_:)
            )
        }
        .sheet(isPresented: $showAgenticRuntime) {
            AgenticUIHomeView()
        }
    }

    private func handleOnAppear() {
        if manager.chatHistory.isEmpty && !hasShownWelcome {
            activeModal = .welcome
            hasShownWelcome = true
        }
        shufflePrompts()
    }

    private func openDiscovery() {
        activeModal = .discovery
    }

    private func selectPromptAndSend(_ prompt: String) {
        query = prompt
        sendMessage()
    }

    private func sendMessage() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        query = ""

        Task {
            await manager.queryPersonaSafely(query: trimmed)
        }
    }

    private func shufflePrompts() {
        shuffledPrompts = Array(allPrompts.shuffled().prefix(3))
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
    @Binding var query: String
    let shuffledPrompts: [String]
    let followUpSuggestions: [String]
    let onPromptSelection: (String) -> Void
    let onSend: () -> Void
    let onOpenDiscovery: () -> Void
    let onNeedScroll: (ScrollViewProxy) -> Void

    var body: some View {
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
                shuffledPrompts: shuffledPrompts,
                followUpSuggestions: followUpSuggestions,
                onTapPrompt: onPromptSelection,
                onSend: onSend,
                onOpenDiscovery: onOpenDiscovery
            )
        }
    }
}

private struct PersonaHomeToolbar: ToolbarContent, @unchecked Sendable {
    let onShowWelcome: () -> Void
    let onShowTuning: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: onShowTuning) {
                Image(systemName: "slider.horizontal.3")
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

    var body: some View {
        Group {
            switch modal {
            case .welcome:
                WelcomePersonaView()
            case .tuning:
                TuningSheetView(manager: manager)
                    .presentationDetents([.medium])
            case .discovery:
                PromptDiscoveryView(allPrompts: allPrompts, onSelect: onPromptSelection)
                    .presentationDetents([.medium])
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
            ScrollView {
                LazyVStack(spacing: 16) {
                    if chatHistory.isEmpty {
                        PersonaEmptyStateView(onDiscoverPrompts: onDiscoverPrompts)
                    } else {
                        ForEach(chatHistory) { message in
                            PersonaChatBubble(message: message).id(message.id)
                        }
                    }
                    if isThinking { ThinkingIndicator().id("thinking") }
                }
                .padding()
            }
            .onChange(of: chatHistory.count) { _ in onNeedScroll(proxy) }
            .onChange(of: isThinking) { thinking in if thinking { onNeedScroll(proxy) } }
        }
    }
}

private struct PersonaComposerView: View {
    @Binding var query: String
    let isThinking: Bool
    let shuffledPrompts: [String]
    let followUpSuggestions: [String]
    let onTapPrompt: (String) -> Void
    let onSend: () -> Void
    let onOpenDiscovery: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            if !followUpSuggestions.isEmpty {
                PersonaFollowUpsView(suggestions: followUpSuggestions, onSelect: onTapPrompt)
            }
            PersonaInputPanelView(query: $query, isThinking: isThinking, shuffledPrompts: shuffledPrompts, onTapPrompt: onTapPrompt, onSend: onSend, onOpenDiscovery: onOpenDiscovery)
        }
    }
}

private struct PersonaEmptyStateView: View {
    let onDiscoverPrompts: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(.top, 100)
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
                    .padding(12)
                    .background(PersonaMessageBubbleBackground(isUser: isUser))
                    .foregroundStyle(isUser ? Color.white : Color.primary)
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
                    .padding(.horizontal, 4)
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
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
        } else {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.secondary.opacity(0.15))
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
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
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
    let shuffledPrompts: [String]
    let onTapPrompt: (String) -> Void
    let onSend: () -> Void
    let onOpenDiscovery: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(shuffledPrompts, id: \.self) { prompt in
                    Button(action: { onTapPrompt(prompt) }) {
                        Text(prompt).font(.caption2).padding(.horizontal, 10).padding(.vertical, 6).background(Color.secondary.opacity(0.1)).cornerRadius(12).lineLimit(1)
                    }
                }
                Button(action: onOpenDiscovery) { Image(systemName: "plus.circle.fill").font(.system(size: 20)).foregroundStyle(.blue) }
            }
            .padding(.horizontal)

            HStack(spacing: 12) {
                TextField("Message Persona...", text: $query, axis: .vertical)
                    .padding(10)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(20)
                    .lineLimit(1...5)
                PersonaSendButton(
                    isDisabled: query.isEmpty || isThinking,
                    onSend: onSend
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .padding(.top, 8)
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
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                    .opacity(isDisabled ? 1 : 0)

                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
                    )
                    .opacity(isDisabled ? 0 : 1)
            }
        }
        .disabled(isDisabled)
    }
}

private struct PersonaMarkdownBubbleText: View {
    let markdown: String
    let isUser: Bool

    var body: some View {
        // Robust markdown parsing using AttributedString
        if let parsed = try? AttributedString(markdown: markdown, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(parsed)
        } else {
            // Fallback that cleans up obvious markdown markers if parsing fails
            Text(cleanMarkdown(markdown))
        }
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
                            .fill(Color.accentColor)
                            .frame(width: 7, height: 7)
                            .scaleEffect(animStep == index ? 1.2 : 0.8)
                            .opacity(animStep == index ? 1.0 : 0.4)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.secondary.opacity(0.15)))
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
            ScrollView {
                VStack(spacing: 30) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 80))
                        .symbolEffect(.pulse.byLayer, options: .nonRepeating)
                        .padding(.top, 40)

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
                    .padding(.horizontal, 30)

                    Spacer(minLength: 40)

                    Button {
                        dismiss()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
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
                .foregroundStyle(Color.accentColor)
                .frame(width: 35)

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
