# Voice Mentor

Voice Mentor is a voice-based coaching app that provides real-time feedback and personalized 12-week coaching plans.

- Users set personal goals, receive instant voice analysis, and track progress.
- The backend (Flask) processes audio, transcribes speech using OpenAI Whisper, and manages coaching logic.
- The frontend (SwiftUI) offers an intuitive interface for goal setting, progress tracking, and chat.
- Easy setup: configure environment variables, install dependencies, run the backend, and launch the iOS app in Xcode.

## Main Features

- **Goal-Based Coaching:** Set personal coaching goals that shape your experience and feedback.
- **Real-Time Voice Analysis:** Get instant feedback on your speech and communication style.
- **12-Week Personalized Plan:** Automatically generated coaching plan tailored to your goals.
- **Progress Tracking:** Visual dashboard to monitor your improvement over time.
- **Weekly Chat Sessions:** Dedicated chat interface for each week of your coaching journey.
- **Seamless iOS Experience:** Intuitive SwiftUI interface for easy navigation and interaction.

# Current Implementation (!FOR THE THIRD SPRINT!) - LangGraph Agent

MentorAI (the agent that I have added now) is designed to act as a personal mentor, adapting its onboarding and planning process to the user's main area of interest:

- **Career**: Professional growth, career goals, and obstacles.
- **Self-Growth**: Personal development, habits, and self-improvement.
- **Relationships**: Interpersonal issues, conflict resolution, and communication.
- **No Goal**: Exploration and self-discovery for users without a specific goal.

The agent collects relevant information through a conversational flow, then generates a tailored 12-week plan. Once the plan is ready, users gain access to the "MyCoach" section in the app.

---

## User Flows & Graph Structure

- **Each path collects different data** (e.g., for relationships, the agent asks about the person and the issue; for career, about the goal and obstacles).
- **Final node**: `generate_plan` creates a 12-week plan, after which the user is congratulated and prompted to access "MyCoach".

---

## API Endpoints

All endpoints require an `Authorization` header with a valid Firebase ID Token.

### Session Management

- **POST `/session`**
  - Create a new onboarding session.
  - **Response:** `{ "session_id": "...", "message": "Session created successfully" }`

### Chat & Onboarding

- **POST `/chat/{session_id}`**
  - Send a user message and progress through the onboarding graph.
  - **Request:** `{ "message": "..." }`
  - **Response:** `{ "reply": "...", "session_id": "..." }`

### State & Plan

- **GET `/goal/{session_id}`**
  - Get the user's main goal (career, self-growth, relationship, or no-goal reason).
  - **Response:** `{ "session_id": "...", "goal": "..." }`

- **GET `/topics/{session_id}`**
  - Get the generated 12-week plan topics.
  - **Response:** `{ "session_id": "...", "topics": { "week_1_topic": "...", ..., "week_12_topic": "..." } }`

- **GET `/state/{session_id}`**
  - Get the full internal state for a session (for debugging/integration).
  - **Response:** `{ "session_id": "...", "state": { ... } }`

---

## Session State Structure

The backend stores a detailed state for each session. Example (Python, Pydantic):

```python
class SessionState(BaseModel):
    session_id: str
    user_name: Optional[str]
    user_age: Optional[int]
    goal_type: Optional[Literal["career", "self_growth", "relationships", "no_goal"]]
    values: Optional[List[str]]
    career_now: Optional[str]
    career_goal: Optional[str]
    career_obstacles: Optional[List[str]]
    relation_people: Optional[str]
    relation_issues: Optional[str]
    self_growth_area: Optional[str]
    self_growth_field: Optional[str]
    no_goal_reason: Optional[str]
    seed_goals: Optional[List[str]]
    phase: Literal["incomplete", "plan_ready"] = "incomplete"
    created_at: datetime
    updated_at: datetime
    history: List[dict]  # [{'role': 'user'|'assistant', 'content': str}]
```

**Key fields:**
- `goal_type`: Branches the flow (`career`, `self_growth`, `relationships`, `no_goal`)
- `phase`: `"incomplete"` or `"plan_ready"` (used to unlock MyCoach)
- `plan`: Dict of 12 topics, generated at the end

---

## Unlocking MyCoach Section

After the 12-week plan is generated (`phase == "plan_ready"`), the user is congratulated and instructed to access the "MyCoach" section. In the frontend, this is managed as follows:

```swift
// Swift (MyCoachView.swift)
if onboardingManager.isOnboardingComplete {
    // Show MyCoach content (plan, topics, etc.)
} else {
    // Show onboarding prompt
    Text("To access your coach, please complete onboarding first.")
}
```

The `OnboardingManager` observes the session state and phase:

```swift
class OnboardingManager: ObservableObject {
    @Published var phase: String = "incomplete"
    var isOnboardingComplete: Bool { phase == "plan_ready" }
    // ...
}
```

---

## Example API Usage

**Create a session:**
```bash
curl -X POST https://<host>/session -H "Authorization: Bearer <token>"
```

**Send a chat message:**
```bash
curl -X POST https://<host>/chat/<session_id> \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"message": "I want to improve my career"}'
```

**Get the plan:**
```bash
curl https://<host>/topics/<session_id> -H "Authorization: Bearer <token>"
```

---

## Frontend Integration

- The onboarding flow is implemented in SwiftUI.
- The `OnboardingManager` handles session creation, chat, and state fetching.
- The "MyCoach" section is unlocked when the backend state `phase` is `"plan_ready"`.
- All API calls are authenticated with Firebase ID tokens.



**What is this agent for?**

This agent helps you make a simple 12-week plan for your personal growth. You just tell it what you want to work on (like career, self-growth, or relationships), and it builds a week-by-week plan for you. It's useful because sometimes it's hard to know where to start or what to do next, and this agent gives you a clear path. The main users are people who want to improve themselves but need a little structure and guidance, even if they don't have a coach.

---

**What does the agent actually do?**

- Asks you a few questions about your goals or what you want to work on.
- Based on your answers, it creates a 12-week plan, with a topic or focus for each week.
- You can see your plan in the app and follow it week by week.
- If you don't know your goal, it helps you figure it out.
- You interact with the agent by chatting, just like texting.

---

**How do you use it?**

- To use the agent, just open the app, start the onboarding, and answer the questions.
- When you finish, your 12-week plan appears in "MyCoach".
- Example: If you say you want to get better at public speaking, your plan might have topics like "Week 1: Practice short talks", "Week 2: Record yourself", and so on.
- The agent is built this way to make it easy for anyone to get a plan, even if they don't know where to start. The chat format feels natural, and the plan is always personalized for you.

---

**How does it work under the hood?**

- The backend is built with Python and uses FastAPI (or Flask, depending on the version) to handle requests.
- It uses a graph structure to decide what questions to ask and when to make the plan.
- The frontend is made with SwiftUI for iOS, so it's smooth and modern.
- All your data is kept safe, and you need to log in with your account.
- If something goes wrong, the app shows a friendly error message.

