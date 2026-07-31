/// Which segment of the "Tasks & Messages" screen's top segmented tab bar
/// is currently selected.
enum TasksMessagesTab { tasks, messages }

/// Which filter chip is selected above the "Tasks" tab's task list.
enum TaskFilter { all, overdue, dueToday, done }

/// Lifecycle state of a single task row; drives both its leading status
/// indicator and its trailing status pill.
enum TaskStatus { overdue, pending, done }

/// Urgency pill shown on a conversation row in the "Messages" tab.
enum MessagePriority { highPriority, routine, general }

/// Which side of the chat thread a message belongs to; drives bubble
/// alignment and color in the Message Details screen.
enum MessageDirection { incoming, outgoing }
